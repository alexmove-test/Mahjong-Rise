# -*- coding: utf-8 -*-
"""Synthesized 20s soundtrack for the Mahjong Rise promo: pad, koto, bells, soft drums."""
from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np

SR = 44100
DUR = 20.0
BPM = 96.0
BEAT = 60.0 / BPM          # 0.625 s
BAR = BEAT * 4             # 2.5 s

N = int(SR * DUR)
T = np.arange(N, dtype=np.float64) / SR

NOTE = {
    "D2": 73.42, "G2": 98.00, "A2": 110.00, "B2": 123.47, "D3": 146.83,
    "Fs3": 185.00, "A3": 220.00, "B3": 246.94, "D4": 293.66, "E4": 329.63,
    "Fs4": 369.99, "G4": 392.00, "A4": 440.00, "B4": 493.88, "D5": 587.33,
    "E5": 659.25, "Fs5": 739.99, "A5": 880.00, "B5": 987.77, "D6": 1174.66,
}

# one chord per bar: D  D  Bm  G  D  A  Bm  D
CHORDS = [
    ("D4", "Fs4", "A4"),
    ("D4", "Fs4", "A4"),
    ("B3", "D4", "Fs4"),
    ("G4", "B4", "D5"),
    ("D4", "Fs4", "A4"),
    ("A3", "Cs4", "E4") if False else ("A3", "E4", "A4"),
    ("B3", "D4", "Fs4"),
    ("D4", "Fs4", "A4"),
]
BASS = ["D3", "D3", "B2", "G2", "D3", "A2", "B2", "D3"]


def _add(buf: np.ndarray, start: float, sig: np.ndarray) -> None:
    i0 = int(start * SR)
    if i0 >= N:
        return
    seg = sig[: max(0, N - i0)]
    buf[i0 : i0 + len(seg)] += seg


def _env(length: int, attack: float, decay: float, sustain: float = 0.0, release: float = 0.0) -> np.ndarray:
    t = np.arange(length) / SR
    e = np.ones(length)
    if attack > 0:
        e *= np.clip(t / attack, 0, 1)
    if sustain > 0:
        body = np.exp(-np.maximum(t - attack, 0) / decay) * (1 - sustain) + sustain
        tail = np.clip((t[-1] - t) / max(release, 1e-3), 0, 1) if release > 0 else 1.0
        return e * body * tail
    return e * np.exp(-np.maximum(t - attack, 0) / decay)


def _pluck(freq: float, dur: float, amp: float, decay: float, bright: float = 1.0) -> np.ndarray:
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = np.zeros(n)
    for k, ha in enumerate((1.0, 0.45 * bright, 0.22 * bright, 0.1 * bright, 0.05 * bright), start=1):
        # slight inharmonicity gives a plucked-string shimmer
        f = freq * k * (1 + 0.0008 * k * k)
        sig += ha * np.sin(2 * math.pi * f * t + 0.6 * k) * np.exp(-t / (decay / (1 + 0.55 * (k - 1))))
    sig *= np.clip(t / 0.004, 0, 1)
    return amp * sig


def _bell(freq: float, dur: float, amp: float, decay: float) -> np.ndarray:
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = (
        1.0 * np.sin(2 * math.pi * freq * t)
        + 0.5 * np.sin(2 * math.pi * freq * 2.76 * t)
        + 0.25 * np.sin(2 * math.pi * freq * 5.4 * t)
    )
    return amp * sig * np.exp(-t / decay) * np.clip(t / 0.006, 0, 1)


def _pad(freqs: tuple[str, ...], start: float, dur: float, amp: float) -> np.ndarray:
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = np.zeros(n)
    for i, name in enumerate(freqs):
        f = NOTE[name]
        for det in (-0.12, 0.0, 0.14):
            ph = 0.7 * i + 1.3 * det
            sig += np.sin(2 * math.pi * (f + det) * t + ph) * 0.5
            sig += 0.18 * np.sin(2 * math.pi * (f + det) * 2 * t + ph)
        sig += 0.12 * np.sin(2 * math.pi * f * 0.5 * t)
    vib = 1 + 0.02 * np.sin(2 * math.pi * 0.23 * t + start)
    env = np.clip(t / 0.9, 0, 1) * np.clip((dur - t) / 0.7, 0, 1)
    return amp * sig * env * vib / len(freqs)


def _noise_sweep(dur: float, amp: float, smooth: int, rising: bool = True) -> np.ndarray:
    n = int(dur * SR)
    rng = np.random.default_rng(7)
    x = rng.standard_normal(n)
    k = np.ones(smooth) / smooth
    x = np.convolve(x, k, mode="same")
    t = np.arange(n) / SR
    shape = (t / dur) ** 2 if rising else (1 - t / dur) ** 2
    env = shape * np.sin(math.pi * t / dur) ** 0.6
    return amp * x * env


def _shaker(amp: float) -> np.ndarray:
    n = int(0.09 * SR)
    rng = np.random.default_rng(21)
    x = rng.standard_normal(n)
    x = x - np.convolve(x, np.ones(9) / 9, mode="same")  # high-pass-ish
    t = np.arange(n) / SR
    return amp * x * np.exp(-t / 0.022)


def _kick(amp: float) -> np.ndarray:
    n = int(0.34 * SR)
    t = np.arange(n) / SR
    f = 105 * np.exp(-t / 0.05) + 46
    sig = np.sin(2 * math.pi * np.cumsum(f) / SR)
    return amp * sig * np.exp(-t / 0.13)


def _reverb_ir(seed: int, decay: float, dur: float = 2.2) -> np.ndarray:
    n = int(dur * SR)
    rng = np.random.default_rng(seed)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / SR / decay)
    ir = np.convolve(ir, np.ones(26) / 26, mode="same")  # damp highs
    pre = int(0.018 * SR)
    ir[:pre] *= np.linspace(0, 1, pre)
    return ir / np.sqrt(np.sum(ir**2))


def _convolve(x: np.ndarray, ir: np.ndarray) -> np.ndarray:
    n = len(x) + len(ir) - 1
    nfft = 1 << (n - 1).bit_length()
    y = np.fft.irfft(np.fft.rfft(x, nfft) * np.fft.rfft(ir, nfft), nfft)
    return y[: len(x)]


def build() -> np.ndarray:
    """Returns stereo float array shaped (N, 2)."""
    left = np.zeros(N)
    right = np.zeros(N)
    center = np.zeros(N)

    # ---- pads, one per bar with a small overlap
    for bar in range(8):
        start = bar * BAR
        amp = 0.075 if bar < 2 else 0.095 if bar < 6 else 0.11
        _add(center, start, _pad(CHORDS[bar], start, BAR + 0.9, amp))

    # ---- bass on bar starts, doubled on beat 3 from bar 4
    for bar in range(8):
        f = NOTE[BASS[bar]] / 2
        amp = 0.12 if bar >= 2 else 0.07
        _add(center, bar * BAR, _pluck(f, 1.6, amp, 0.5, bright=0.35))
        if bar >= 3:
            _add(center, bar * BAR + 2 * BEAT, _pluck(f, 1.0, amp * 0.6, 0.35, bright=0.3))

    # ---- koto arpeggio in eighths, enters at bar 2, thins out in the last bar
    arps = {
        1: ["D5", "A4", "Fs5", "A4", "D5", "B4", "A4", "Fs4"],
        2: ["B4", "Fs4", "D5", "Fs4", "B4", "D5", "Fs5", "D5"],
        3: ["D5", "B4", "G4", "B4", "D5", "E5", "D5", "B4"],
        4: ["A4", "Fs5", "D5", "Fs5", "A5", "Fs5", "D5", "A4"],
        5: ["E5", "A4", "Cs5" if False else "A5", "E5", "Fs5", "E5", "A4", "E5"],
        6: ["Fs5", "D5", "B4", "D5", "Fs5", "A5", "Fs5", "D5"],
        7: ["A5", "Fs5", "D5", "A4", "D5", "Fs5", "A5", "D6"],
    }
    for bar, seq in arps.items():
        for i, name in enumerate(seq):
            t0 = bar * BAR + i * BEAT / 2
            amp = 0.085 if i % 2 == 0 else 0.055
            if bar == 7:
                amp *= 0.7
            sig = _pluck(NOTE[name], 1.1, amp, 0.34)
            pan = 0.32 * math.sin(i * 0.9 + bar)
            _add(left, t0, sig * (1 - max(pan, 0)))
            _add(right, t0 + 0.006, sig * (1 + min(pan, 0)))

    # ---- bell melody from bar 4 (gameplay) to the end
    melody = [
        (3, ["A4", "B4", "D5", "B4"]),
        (4, ["Fs5", "E5", "D5", "A4"]),
        (5, ["B4", "D5", "E5", "Fs5"]),
        (6, ["A5", "Fs5", "E5", "D5"]),
        (7, ["Fs5", "A5", "D6", None]),
    ]
    for bar, seq in melody:
        for i, name in enumerate(seq):
            if name is None:
                continue
            t0 = bar * BAR + i * BEAT
            _add(center, t0, _bell(NOTE[name], 2.0, 0.085, 0.7))

    # ---- soft percussion: shaker eighths from bar 3, kick from bar 4
    for bar in range(3, 8):
        for i in range(8):
            t0 = bar * BAR + i * BEAT / 2
            amp = 0.05 if i % 2 == 0 else 0.028
            _add(right if i % 2 else left, t0, _shaker(amp))
    for bar in range(3, 8):
        for beat in (0, 2):
            _add(center, bar * BAR + beat * BEAT, _kick(0.13))
        if bar >= 5:
            _add(center, bar * BAR + 3.5 * BEAT, _kick(0.07))

    # ---- scene accents: whooshes on cuts, chime on logo, dings on matches
    for cut, up in ((3.75, True), (7.5, True), (13.125, True), (17.5, True)):
        sw = _noise_sweep(0.55, 0.055, 40, rising=up)
        _add(left, cut - 0.45, sw)
        _add(right, cut - 0.42, sw * 0.9)

    # logo reveal shimmer
    for i, name in enumerate(("D5", "Fs5", "A5", "D6")):
        _add(center, 3.9 + i * 0.075, _bell(NOTE[name], 2.4, 0.075 - i * 0.012, 1.1))

    # tile match dings
    for t0, notes in ((9.35, ("A5", "D6")), (10.6, ("B5", "Fs5")), (11.9, ("D6", "A5"))):
        for j, name in enumerate(notes):
            _add(center, t0 + j * 0.05, _bell(NOTE[name], 1.2, 0.075, 0.42))

    # courtyard upgrade pops
    for t0 in (13.4, 14.4, 15.4, 16.25):
        _add(center, t0, _pluck(NOTE["D5"], 0.9, 0.06, 0.3, bright=0.8))
        _add(center, t0 + 0.04, _bell(NOTE["A5"], 1.4, 0.05, 0.6))

    # final CTA sparkle cluster
    for i, name in enumerate(("D5", "A5", "Fs5", "D6", "A5")):
        _add(center, 17.55 + i * 0.09, _bell(NOTE[name], 2.6, 0.06, 1.3))

    left += center
    right += center

    wet_l = _convolve(left, _reverb_ir(11, 0.85))
    wet_r = _convolve(right, _reverb_ir(29, 0.9))
    left = left * 0.74 + wet_l * 0.3
    right = right * 0.74 + wet_r * 0.3

    stereo = np.stack([left, right], axis=1)
    stereo *= np.clip(T / 0.25, 0, 1)[:, None]
    stereo *= np.clip((DUR - T) / 0.9, 0, 1)[:, None]
    stereo = np.tanh(stereo * 1.25) / 1.25  # gentle glue
    peak = np.max(np.abs(stereo)) or 1.0
    return stereo / peak * 0.89


def write_wav(path: Path) -> Path:
    stereo = build()
    pcm = (stereo * 32767).astype(np.int16)
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(2)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(pcm.tobytes())
    return path


if __name__ == "__main__":
    out = write_wav(Path(__file__).with_name("build") / "music20.wav")
    print("wrote", out)
