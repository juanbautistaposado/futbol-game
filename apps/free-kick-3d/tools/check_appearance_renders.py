"""Check 1280x720 real-GPU captures produced by preview_appearance.gd.

The forehead is a fixed, unobstructed skin region in the frozen studio pose.
These checks catch the previously clipped skin tones and facial toggles which
saved successfully but did not alter the face. Needs Pillow and NumPy.
"""
from pathlib import Path
import sys

import numpy as np
from PIL import Image


def frame(folder, name):
    image = np.asarray(Image.open(folder / (name + ".png")).convert("RGB"), dtype=float)
    assert image.shape == (720, 1280, 3), "Use the fixed preview_appearance.gd viewport"
    return image


def check(folder):
    skin = [frame(folder, f"skin-{i}")[330:350, 875:910] for i in range(1, 10)]
    clipped = float((skin[3].max(axis=2) >= 249).mean())
    assert clipped < .10, f"Medium skin is overexposed: {clipped:.1%} of forehead clipped"
    means = np.array([sample.mean(axis=(0, 1)) for sample in skin])
    luminance = means @ np.array([.2126, .7152, .0722])
    steps = -np.diff(luminance)
    assert np.all(steps > 4), f"Skin presets collapse into the same visible color: {steps}"
    assert np.all(steps < 40), f"Skin presets have abrupt jumps: {steps}"
    assert luminance[-1] > 30, "Darkest skin loses all facial detail"
    light, dark = [frame(folder, name) for name in ["skin-1", "skin-9"]]
    lip_difference = np.abs(light[435:445, 895:934] - dark[435:445, 895:934]).mean(axis=2)
    assert (lip_difference < 3).mean() < .15, "Lips/mouth edge keep the original complexion"
    clean, beard = [frame(folder, name) for name in ["clean", "beard"]]
    # Only facial pixels; changes in selected UI buttons must not satisfy this.
    brow_roi = np.s_[358:378, 855:950]
    beard_roi = np.s_[414:466, 860:944]
    beard_change = np.abs(clean[beard_roi] - beard[beard_roi]).mean()
    assert beard_change > 2, f"Beard toggle leaves face unchanged: {beard_change}"
    assert np.abs(clean[brow_roi] - beard[brow_roi]).mean() < .5, "Beard toggle also changes eyebrows"
    print("PASS: un-clipped skin, nine gradual tones, lips follow complexion, beard toggle preserves eyebrows")
    print("Forehead RGB:", means.round(1).tolist())
    print("Beard toggle difference:", round(beard_change, 2))


if __name__ == "__main__":
    check(Path(sys.argv[1]))
