"""Generate the original, deterministic sound effects used by Tiros Libres 3D."""

from __future__ import annotations

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


def crowd(t: float, i: int) -> float:
    # Soft, nonverbal crowd murmur; a deterministic loop with a long fade at its seam.
    seam = min(1.0, t / 0.3, (6.0 - t) / 0.3)
    voices = sum(
        math.sin(2 * math.pi * (frequency * t + phase))
        for frequency, phase in [(87, 0.13), (113, 0.67), (159, 0.31), (197, 0.8)]
    )
    texture = noise() * 0.06
    return seam * (voices * 0.021 + texture) * (0.85 + 0.13 * math.sin(2 * math.pi * 0.37 * t))


def make_goal_cheer():
    """A short crowd roar and scattered claps, without the old musical tones."""
    rng = random.Random(20261001)
    voices = [
        (rng.uniform(95, 245), rng.uniform(-0.06, 0.24), rng.uniform(0.95, 1.55), rng.random())
        for _ in range(18)
    ]
    clap_times = sorted(rng.uniform(0.12, 1.48) for _ in range(74))
    clap_index = 0
    clap_body = 0.0
    low = 0.0
    high = 0.0

    def cheer(t: float, i: int) -> float:
        nonlocal clap_index, clap_body, low, high
        while clap_index < len(clap_times) and clap_times[clap_index] <= t:
            clap_body += rng.uniform(0.20, 0.50)
            clap_index += 1
        clap_body *= 0.9974

        white = rng.random() * 2.0 - 1.0
        low += 0.018 * (white - low)
        high += 0.23 * (white - high)
        mid_noise = high - low
        swell = min(1.0, t / 0.16) * min(1.0, (1.85 - t) / 0.42)

        # Slightly different pitches, timing and lengths blur the voices into a crowd.
        chant = 0.0
        for frequency, start, duration, phase in voices:
            age = t - start
            if age < 0 or age > duration:
                continue
            envelope = min(1.0, age / 0.10, (duration - age) / 0.25)
            wobble = 1.0 + 0.018 * math.sin(2 * math.pi * (2.4 + phase) * age)
            cycle = 2 * math.pi * (frequency * wobble * age + phase)
            chant += envelope * (math.sin(cycle) + 0.28 * math.sin(cycle * 2.0))
        chant *= 0.017

        applause = clap_body * (white - low) * 0.19
        roar = mid_noise * 0.32
        return swell * (chant + roar + applause)

    return cheer


if __name__ == "__main__":
    for name, seconds, generator in [
        ("kick", 0.24, impact),
        ("save", 0.32, glove),
        ("post", 0.75, woodwork),
        ("net", 0.58, net),
        ("crowd", 6.0, crowd),
        ("cheer", 1.85, make_goal_cheer()),
    ]:
        save(name, seconds, generator)
        print(OUT / f"{name}.wav")
