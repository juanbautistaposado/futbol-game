"""Check actual UV coverage at facial landmarks of both imported PLAYER roles.

Run with Python, Pillow and NumPy. This reads GLB triangles and generated PNGs,
independently of the generator's classification. The old mask failed moustache
coverage (mean 0.431) and had no eyebrow mask; both controls kept visible hair.
"""
import json
from pathlib import Path
import struct

import numpy as np
from PIL import Image

from build_meshy_appearance_mask import accessor


ASSETS = Path(__file__).resolve().parents[1] / "assets/footballer"


def samples(path):
    raw = path.read_bytes()
    length = struct.unpack_from("<I", raw, 12)[0]
    data = json.loads(raw[20:20 + length])
    buffer = raw[28 + length:]
    positions, uvs = [], []
    for primitive in data["meshes"][0]["primitives"]:
        if data["materials"][primitive["material"]]["name"] != "MeshyPlayer":
            continue
        attrs = primitive["attributes"]
        triangles = accessor(data, buffer, primitive["indices"]).reshape(-1, 3)
        # Sample several interior points: the narrow lip landmark only contains
        # six triangle centroids, which is too sparse to check its full UV area.
        weights = np.array([[1/3, 1/3, 1/3], [.5, .25, .25], [.25, .5, .25], [.25, .25, .5]])
        positions.append(np.einsum("sk,tkd->tsd", weights, accessor(data, buffer, attrs["POSITION"])[triangles]).reshape(-1, 3))
        uvs.append(np.einsum("sk,tkd->tsd", weights, accessor(data, buffer, attrs["TEXCOORD_0"])[triangles]).reshape(-1, 2))
    return np.concatenate(positions), np.concatenate(uvs)


def read_uv(path, uv):
    texture = np.asarray(Image.open(path).convert("RGBA"), dtype=float) / 255
    height, width, _ = texture.shape
    indices = np.clip((uv * (width, height)).astype(int), (0, 0), (width - 1, height - 1))
    return texture[indices[:, 1], indices[:, 0]]


def check(role):
    points, uv = samples(ASSETS / (role + ".glb"))
    x, y, z = points.T
    appearance = read_uv(ASSETS / "meshy_appearance_mask.png", uv)
    face = read_uv(ASSETS / "meshy_facial_mask.png", uv)
    lower_lid = (abs(x) > .025) & (abs(x) < .045) & (y > 1.7535) & (y < 1.7565) & (z > .075)
    assert lower_lid.sum() > 20
    lid_skin = float(appearance[lower_lid, 0].mean())
    assert lid_skin > .90, f"Lower eyelid keeps the original skin pigment: skin coverage {lid_skin:.1%} in {role}"
    iris = (abs(x) > .026) & (abs(x) < .035) & (y > 1.762) & (y < 1.765) & (z > .075)
    assert iris.sum() > 10
    assert appearance[iris, 0].mean() < .10, "Skin recoloring damages the iris"
    landmarks = {
        "moustache": ((abs(x) < .025) & (y > 1.700) & (y < 1.712) & (z > .079), appearance[:, 3], .93),
        "chin_beard": ((abs(x) < .047) & (y > 1.648) & (y < 1.678) & (z > .032), appearance[:, 3], .93),
        "eyebrows": ((abs(x) > .025) & (abs(x) < .050) & (y > 1.775) & (y < 1.782) & (z > .074), face[:, 0], .90),
    }
    results = {"lower_lid_skin": round(lid_skin, 4)}
    for name, (region, coverage, minimum) in landmarks.items():
        assert region.sum() > 20, f"Missing anatomical samples: {role}/{name}"
        mean = float(coverage[region].mean())
        results[name] = round(mean, 4)
        assert mean > minimum, f"Residual {name} when disabled: UV coverage {mean:.1%} in {role}"
    protected = {
        "eyes": (abs(x) > .025) & (abs(x) < .040) & (y > 1.759) & (y < 1.762) & (z > .075),
        "lips": (abs(x) < .016) & (y > 1.688) & (y < 1.692) & (z > .075),
    }
    for name, region in protected.items():
        assert region.sum() > 10, f"Missing protected feature: {role}/{name}"
        erased = np.maximum(appearance[:, 3], face[:, 0])[region].mean()
        results[name + "_erased"] = round(float(erased), 4)
        assert erased < .05, f"Facial-hair removal damages {name}: {erased:.1%} in {role}"
    print(role, results)


if __name__ == "__main__":
    for model in ["meshy_striker", "meshy_keeper"]:
        check(model)
    print("PASS: moustache/beard/eyebrow removal covers actual model UVs and preserves eyes/lips")
