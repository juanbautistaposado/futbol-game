"""Generate the original, deterministic sound effects used by Tiros Libres 3D."""

from __future__ import annotations

import argparse
import math
import random
import struct
import wave
from pathlib import Path


RATE = 44_100
OUT = Path(__file__).resolve().parents[1] / "audio"
RNG = random.Random(20260928)


def save(name: str, seconds: float, sample) -> None:
    OUT.mkdir(exist_ok=True)
    frames = bytearray()
    count = round(seconds * RATE)
    for i in range(count):
        value = math.tanh(sample(i / RATE, i) * 1.3) * 0.82
        frames.extend(struct.pack("<h", round(max(-1.0, min(1.0, value)) * 32767)))
    with wave.open(str(OUT / f"{name}.wav"), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(frames)


def noise() -> float:
    return RNG.random() * 2.0 - 1.0


def impact(t: float, i: int) -> float:
    thud = math.sin(2 * math.pi * (117 * t - 95 * t * t)) * math.exp(-24 * t)
    slap = noise() * math.exp(-56 * t)
    leather = math.sin(2 * math.pi * 215 * t) * math.exp(-42 * t)
    return 0.74 * thud + 0.36 * slap + 0.20 * leather


def glove(t: float, i: int) -> float:
    thud = math.sin(2 * math.pi * 85 * t) * math.exp(-17 * t)
    rub = noise() * math.exp(-15 * t) * (0.7 + 0.3 * math.sin(2 * math.pi * 27 * t))
    return 0.52 * thud + 0.23 * rub


def woodwork(t: float, i: int) -> float:
    ping = sum(
        amplitude * math.sin(2 * math.pi * frequency * t) * math.exp(-decay * t)
        for amplitude, frequency, decay in [(0.40, 710, 6.5), (0.23, 1138, 8), (0.16, 1697, 11)]
    )
    return ping + noise() * 0.28 * math.exp(-100 * t)


def net(t: float, i: int) -> float:
    swell = min(1.0, t * 30) * math.exp(-7 * t)
    mesh = noise() * (0.24 + 0.08 * math.sin(2 * math.pi * 43 * t)) * swell
    return mesh + 0.08 * math.sin(2 * math.pi * 120 * t) * math.exp(-18 * t)


def result_note(t: float, start: float, frequency: float, duration: float) -> float:
    """A plucked, rounded tone: each harmonic decays independently."""
    age = t - start
    if age < 0 or age >= duration:
        return 0.0
    envelope = min(1.0, age / 0.004) * min(1.0, (duration - age) / 0.065)
    phase = 2 * math.pi * frequency * age
    body = math.sin(phase) * math.exp(-7.5 * age)
    wood = 0.28 * math.sin(phase * 2) * math.exp(-24 * age)
    sparkle = 0.13 * math.sin(phase * 4) * math.exp(-38 * age)
    # Quiet detuned partial adds body without a sustained electronic buzz.
    warmth = 0.08 * math.sin(phase * 1.003) * math.exp(-12 * age)
    return (body + wood + sparkle + warmth) * envelope * 0.29


def goal_dry(t: float) -> float:
    # A quick G-major flourish with a low foundation and a brighter final note.
    return (
        0.36 * result_note(t, 0.0, 196.0, 0.28)
        + 0.70 * result_note(t, 0.0, 392.0, 0.26)
        + 0.80 * result_note(t, 0.065, 493.88, 0.28)
        + result_note(t, 0.13, 587.33, 0.38)
        + 0.26 * result_note(t, 0.15, 783.99, 0.30)
    )


def goal(t: float, i: int) -> float:
    # Short early reflections give the flourish space, without a long tail.
    return (goal_dry(t) + 0.16 * goal_dry(t - 0.029)
            + 0.09 * goal_dry(t - 0.053) + 0.04 * goal_dry(t - 0.070))


def miss_dry(t: float) -> float:
    # A muted descending knock: brief and softer than the goal flourish.
    age = t - 0.045
    drop = 0.0
    if 0 <= age < 0.28:
        phase = 2 * math.pi * (230 * age - 95 * age * age)
        envelope = min(1.0, age / 0.005) * min(1.0, (0.28 - age) / 0.055)
        drop = 0.23 * math.sin(phase) * math.exp(-13 * age) * envelope
    return 0.60 * result_note(t, 0.0, 349.23, 0.15) + drop


def miss(t: float, i: int) -> float:
    return miss_dry(t) + 0.10 * miss_dry(t - 0.035) + 0.05 * miss_dry(t - 0.055)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--results-only", action="store_true", help="Generate only goal/miss cues")
    args = parser.parse_args()
    sounds = [("goal", 0.58, goal), ("miss", 0.38, miss)]
    if not args.results_only:
        sounds = [
            ("kick", 0.24, impact),
            ("save", 0.32, glove),
            ("post", 0.75, woodwork),
            ("net", 0.58, net),
        ] + sounds
    for name, seconds, generator in sounds:
        save(name, seconds, generator)
        print(OUT / f"{name}.wav")
