"""Genera efectos WAV originales para Noche de los Infectados.

Los sonidos son síntesis propia, sin samples ni material de terceros.
"""
from __future__ import annotations

import math
import os
import random
import struct
import wave

RATE = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
random.seed(407)


def osc(phase: float, shape: str) -> float:
    if shape == "square":
        return 1.0 if math.sin(phase) >= 0.0 else -1.0
    if shape == "saw":
        return 2.0 * ((phase / (2.0 * math.pi)) % 1.0) - 1.0
    if shape == "triangle":
        return 2.0 * abs(2.0 * ((phase / (2.0 * math.pi)) % 1.0) - 1.0) - 1.0
    return math.sin(phase)


def render(path: str, duration: float, tones: list[tuple[float, float]], *, shape="sine", noise=0.0, sweep=0.0, attack=0.015, release=0.12):
    frames = int(RATE * duration)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        data = bytearray()
        for i in range(frames):
            t = i / RATE
            n = t / max(duration, 0.001)
            env = min(1.0, t / attack) * min(1.0, (duration - t) / release)
            value = 0.0
            for frequency, amplitude in tones:
                phase = 2.0 * math.pi * (frequency * t + sweep * n * t * 0.5)
                value += osc(phase, shape) * amplitude
            if noise:
                value += random.uniform(-noise, noise)
            value = max(-0.92, min(0.92, value * env))
            data.extend(struct.pack("<h", int(value * 32767)))
        out.writeframes(data)


def write(path: str, spec: dict):
    render(os.path.join(ROOT, path), **spec)


CARD_SPECS = {
    "spawn": dict(duration=0.48, tones=[(330, .12), (495, .08), (660, .05)], sweep=180),
    "hover": dict(duration=0.18, tones=[(660, .10), (990, .045)], sweep=80),
    "select": dict(duration=0.34, tones=[(220, .15), (440, .10), (880, .05)], sweep=160),
    "apply": dict(duration=0.40, tones=[(392, .11), (523, .10), (784, .07)]),
    "max": dict(duration=0.70, tones=[(196, .13), (392, .10), (784, .06)], shape="saw", noise=.015, sweep=260),
    "disappear": dict(duration=0.28, tones=[(700, .08), (350, .06)], sweep=-300),
}

for event, spec in CARD_SPECS.items():
    write(f"audio/cards/card_{event}.wav", spec)
    write(f"audio/cards/default_upgrade_{event}.wav", spec)

UPGRADE_BASES = {
    "fury": (72, "saw", .025),
    "speed": (520, "sine", .008),
    "medkit": (880, "sine", 0.0),
    "heavy": (130, "square", .045),
    "survivor": (260, "triangle", .006),
}

for name, (base, shape, noise) in UPGRADE_BASES.items():
    write(f"audio/upgrades/{name}_hover.wav", dict(duration=.24, tones=[(base, .12), (base * 1.5, .05)], shape=shape, noise=noise, sweep=base * .4))
    write(f"audio/upgrades/{name}_select.wav", dict(duration=.46, tones=[(base, .16), (base * 2, .10), (base * 4, .045)], shape=shape, noise=noise, sweep=base * 1.8))
    write(f"audio/upgrades/{name}_apply.wav", dict(duration=.42, tones=[(base * 1.25, .13), (base * 2.5, .09), (base * 3.75, .04)], shape=shape, noise=noise))
    write(f"audio/upgrades/{name}_max.wav", dict(duration=.68, tones=[(base * .75, .15), (base * 1.5, .11), (base * 3, .08), (base * 6, .04)], shape=shape, noise=noise, sweep=base * 2.5))

RARITIES = {
    "common": (440, "metal", .0),
    "rara": (620, "sine", .008),
    "epica": (180, "saw", .018),
    "legendaria": (55, "saw", .035),
}

for name, (base, shape, noise) in RARITIES.items():
    for event in ("appear", "select", "apply", "max"):
        multiplier = {"appear": 1.0, "select": 1.25, "apply": 1.5, "max": 2.0}[event]
        tones = [(base * multiplier, .13), (base * multiplier * 2, .09), (base * multiplier * 4, .045)]
        if name == "common":
            tones = [(base * multiplier, .14)]
        write(f"audio/rarity/{name}_{event}.wav", dict(duration=.22 if event == "appear" else .48, tones=tones, shape="square" if shape == "metal" else shape, noise=noise, sweep=base * .9))

print("Generated original card audio in res://audio/cards, res://audio/upgrades and res://audio/rarity")
