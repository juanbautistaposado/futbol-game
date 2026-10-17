"""Generate original seamless 1 m clipped-canopy maps (numpy and Pillow).

R is centered leaf luminance, G is subtle chlorophyll variation, B is leaf
roughness. These are data textures, not copied photographic colour assets.
The dense, narrow curved leaves have no large cloudy noise baked into them.
"""
from pathlib import Path
import math
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
SUPERSAMPLE = 2
DRAW_SIZE = SIZE * SUPERSAMPLE
TILE_METRES = 1.0
rng = random.Random(74021)
height = Image.new('L', (DRAW_SIZE, DRAW_SIZE), 137)
hue = Image.new('L', (DRAW_SIZE, DRAW_SIZE), 128)
height_draw, hue_draw = ImageDraw.Draw(height), ImageDraw.Draw(hue)
for _ in range(125000):
    x, y = rng.uniform(0, DRAW_SIZE), rng.uniform(0, DRAW_SIZE)
    # A clipped leaf projects 7-24 mm onto the dense canopy. The broad
    # orientation mixture avoids an etched grid or repeated diagonal fibres.
    angle = rng.uniform(0, math.tau)
    length = rng.uniform(7, 24) * SUPERSAMPLE
    bend = rng.uniform(-2.6, 2.6) * SUPERSAMPLE
    dx, dy = math.cos(angle), math.sin(angle)
    mid = (x + dx * length * .55 - dy * bend, y + dy * length * .55 + dx * bend)
    tip = (x + dx * length, y + dy * length)
    points = [(x, y), mid, tip]
    raised = rng.randrange(145, 187)
    shadow = rng.randrange(119, 141)
    tint = rng.randrange(112, 147)
    width = rng.randrange(2, 5)
    for shift_x in (-DRAW_SIZE, 0, DRAW_SIZE):
        for shift_y in (-DRAW_SIZE, 0, DRAW_SIZE):
            px, py = x + shift_x, y + shift_y
            if not (-55 < px < DRAW_SIZE + 55 and -55 < py < DRAW_SIZE + 55):
                continue
            shifted = [(a + shift_x, b + shift_y) for a, b in points]
            height_draw.line([(a + 1, b + 1) for a, b in shifted], fill=shadow, width=width + 1)
            height_draw.line(shifted, fill=raised, width=width)
            # The central rib tapers before the tip rather than painting
            # high-contrast wire outlines around the whole leaf.
            height_draw.line([shifted[0], shifted[1]], fill=min(raised + 8, 196), width=1)
            hue_draw.line(shifted, fill=tint, width=width)
height = height.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
hue = hue.resize((SIZE, SIZE), Image.Resampling.LANCZOS)

def seamless_blur(source, radius):
    tile = Image.new('L', (SIZE * 3, SIZE * 3))
    for i in range(3):
        for j in range(3):
            tile.paste(source, (i * SIZE, j * SIZE))
    return tile.filter(ImageFilter.GaussianBlur(radius)).crop((SIZE, SIZE, SIZE * 2, SIZE * 2))

h = np.asarray(seamless_blur(height, .25)).astype(np.float32) / 255
g = np.asarray(seamless_blur(hue, .3)).astype(np.float32) / 255
# Normalize fine canopy detail around a neutral mipmapped average. This
# keeps the pitch brightness and stripe contrast identical far and near.
luminance = np.clip(.5 + (h - h.mean()) * 2.15, .24, .78)
chlorophyll = np.clip(.5 + (g - g.mean()) * 1.8, .35, .65)
roughness = np.clip(.76 + (chlorophyll - .5) * .14, .72, .80)
detail = np.stack((luminance, chlorophyll, roughness), axis=-1)
# Periodic finite differences encode millimetre leaf overlap, not clumps
# of soil or larger hills that would cause cloud-like surface lighting.
step = TILE_METRES / SIZE
dx = (np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)) * .0018 / (2 * step)
dz = (np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)) * .0018 / (2 * step)
normal = np.stack((-dx, -dz, np.ones_like(h)), axis=-1)
normal /= np.linalg.norm(normal, axis=-1, keepdims=True)
normal = normal * .5 + .5
output = Path(__file__).resolve().parents[1] / 'assets/turf'
output.mkdir(parents=True, exist_ok=True)
Image.fromarray(np.uint8(np.clip(detail, 0, 1) * 255)).save(output / 'surface_detail.png')
Image.fromarray(np.uint8(np.clip(normal, 0, 1) * 255)).save(output / 'surface_normal.png')
print('Generated original seamless 1 m clipped-canopy maps:', output)
print('Neutral data mean/std:', float(luminance.mean()), float(luminance.std()))
