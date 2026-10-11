"""gen_music.py OUT.wav: the Halloween Mode's ambience, an original piece made here (nothing sampled).

A slow waltz in D minor on a music box, a harp and soft strings, over a cozy autumn night: wind, a fire crackling,
crows now and then, an owl, a far bell, a wolf far away. 64 bars at 84 beats a minute (about 137 s), made to loop:
its last seconds (the reverb's tail, the wind) are laid over its first."""
import sys

import numpy as np
from scipy.signal import butter, fftconvolve, lfilter

SR = 44100
BPM = 84
BEAT = 60 / BPM
BAR = 3 * BEAT
BARS = 64
LENGTH = BARS * BAR
TAIL = 4.0
N = int((LENGTH + TAIL) * SR)
rng = np.random.default_rng(1031)

NOTES = {"C": 0, "C#": 1, "D": 2, "Eb": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "Ab": 8, "A": 9, "Bb": 10, "B": 11}


def hz(name):
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((NOTES[pitch] + 12 * (octave + 1) - 69) / 12)


CHORDS = {"Dm": ["D", "F", "A"], "Gm": ["G", "Bb", "D"], "Bb": ["Bb", "D", "F"], "A7": ["A", "C#", "E", "G"],
          "F": ["F", "A", "C"], "C": ["C", "E", "G"]}
A_CHORDS = ["Dm", "Dm", "Gm", "Gm", "Bb", "A7", "Dm", "A7", "Dm", "Dm", "Gm", "Gm", "Bb", "Gm", "A7", "Dm"]
B_CHORDS = ["F", "C", "Dm", "A7", "Bb", "F", "Gm", "A7", "F", "C", "Dm", "Bb", "Gm", "A7", "Dm", "A7"]
A_TUNE = [[("A4", 1), ("D5", 1), ("F5", 1)], [("E5", 2), ("D5", 1)], [("D5", 1), ("G5", 1), ("Bb5", 1)], [("A5", 3)],
          [("F5", 1), ("D5", 1), ("Bb4", 1)], [("C#5", 2), ("E5", 1)], [("D5", 1), ("F5", 1), ("A5", 1)], [("G5", 1), ("E5", 1), ("C#5", 1)],
          [("A4", 1), ("D5", 1), ("F5", 1)], [("E5", 1), ("F5", 1), ("D5", 1)], [("Bb4", 1), ("D5", 1), ("G5", 1)], [("F5", 2), ("E5", 1)],
          [("D5", 1), ("F5", 1), ("Bb5", 1)], [("A5", 1), ("G5", 1), ("Bb4", 1)], [("C#5", 1), ("E5", 1), ("G5", 1)], [("D5", 3)]]
B_TUNE = [[("C5", 1), ("F5", 1), ("A5", 1)], [("G5", 2), ("E5", 1)], [("F5", 1), ("D5", 1), ("A4", 1)], [("C#5", 2), ("A4", 1)],
          [("Bb4", 1), ("D5", 1), ("F5", 1)], [("A5", 1), ("G5", 1), ("F5", 1)], [("G5", 1), ("Bb5", 1), ("D5", 1)], [("E5", 3)],
          [("A5", 1), ("C6", 1), ("A5", 1)], [("G5", 1), ("E5", 1), ("C5", 1)], [("D5", 1), ("F5", 1), ("A5", 1)], [("Bb5", 2), ("A5", 1)],
          [("G5", 1), ("F5", 1), ("E5", 1)], [("C#5", 1), ("E5", 1), ("A5", 1)], [("D6", 2), ("A5", 1)], [("C#5", 1), ("E5", 1), ("A4", 1)]]

left = np.zeros(N)
right = np.zeros(N)


def add(signal, start, gain=1.0, pan=0.0):
    i = int(start * SR)
    if i >= N:
        return
    signal = signal[: N - i] * gain
    left[i:i + len(signal)] += signal * np.sqrt(0.5 * (1 - pan))
    right[i:i + len(signal)] += signal * np.sqrt(0.5 * (1 + pan))


def env(n, attack, tau):
    t = np.arange(n) / SR
    return np.minimum(t / attack, 1.0) * np.exp(-t / tau)


def music_box(f, length=2.4):
    n = int(length * SR)
    t = np.arange(n) / SR
    tone = (np.sin(2 * np.pi * f * t) * env(n, 0.003, 0.9) + 0.35 * np.sin(2 * np.pi * 2 * f * t) * env(n, 0.002, 0.35)
            + 0.18 * np.sin(2 * np.pi * 4.07 * f * t) * env(n, 0.001, 0.18) + 0.08 * np.sin(2 * np.pi * 5.98 * f * t) * env(n, 0.001, 0.1))
    return tone


HARPS = {}


def harp(f, length=2.0):
    key = (round(f, 3), length)
    if key in HARPS:
        return HARPS[key]
    n = int(length * SR)
    period = max(int(SR / f), 2)
    buf = rng.uniform(-1, 1, period)
    out = np.empty(n)
    for i in range(n):
        out[i] = buf[i % period]
        buf[i % period] = 0.5 * (buf[i % period] + buf[(i + 1) % period]) * 0.996
    b, a = butter(2, min(4000 / (SR / 2), 0.99))
    HARPS[key] = lfilter(b, a, out) * env(n, 0.002, 1.2)
    return HARPS[key]


def bass(f, length=1.6):
    n = int(length * SR)
    t = np.arange(n) / SR
    return (np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * 2 * f * t)) * env(n, 0.01, 0.45)


def pad(freqs, length):
    n = int(length * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for f in freqs:
        for detune in (-0.004, 0.0, 0.005):
            phase = (f * (1 + detune) * t + rng.uniform()) % 1.0
            out += 2 * phase - 1
    b, a = butter(2, 900 / (SR / 2))
    out = lfilter(b, a, out) / (3 * len(freqs))
    fade = np.minimum(1.0, np.minimum(t / 0.8, (length - t) / 0.8))
    return out * np.clip(fade, 0, 1)


# The waltz: A, B, A (music box an octave up, sparser), B (strings carry the tune)
form = [("A", 0), ("B", 0), ("A", 1), ("B", 1)]
bar = 0
for section, turn in form:
    chords, tune = (A_CHORDS, A_TUNE) if section == "A" else (B_CHORDS, B_TUNE)
    for k in range(16):
        start = bar * BAR
        chord = CHORDS[chords[k]]
        root = chord[0] + "2"
        add(bass(hz(root)), start, 0.30, -0.1)
        for beat in (1, 2):
            for i, pitch in enumerate(chord[:3]):
                add(harp(hz(pitch + "4")), start + beat * BEAT + i * 0.012, 0.08, 0.35)
        add(pad([hz(p + "3") for p in chord[:3]], BAR + 0.6), start, 0.10 if turn == 0 else 0.16, 0.0)
        at = start
        for pitch, beats in tune[k]:
            f = hz(pitch) * (2 if (section == "A" and turn == 1) else 1)
            if not (section == "A" and turn == 1 and beats == 1 and rng.uniform() < 0.25):
                add(music_box(f), at, 0.22, -0.25)
            if section == "B" and turn == 1:
                add(pad([f], beats * BEAT + 0.3), at, 0.10, 0.15)
            at += beats * BEAT
        bar += 1

# A room: a soft reverb (decorrelated noise tails, stereo)
def reverb(x, seconds, seed):
    r = np.random.default_rng(seed)
    n = int(seconds * SR)
    ir = r.standard_normal(n) * np.exp(-np.arange(n) / SR / (seconds / 5))
    b, a = butter(1, 5000 / (SR / 2))
    ir = lfilter(b, a, ir)
    ir /= np.sqrt(np.sum(ir ** 2))
    return fftconvolve(x, ir)[: len(x)]


left_wet, right_wet = reverb(left, 2.8, 1), reverb(right, 2.8, 2)
music_l = left * 0.75 + left_wet * 0.55
music_r = right * 0.75 + right_wet * 0.55

# The night outside: wind, the fire, crows, an owl, a bell, a wolf
amb_l = np.zeros(N)
amb_r = np.zeros(N)


def amb(signal, start, gain, pan):
    i = int(start * SR)
    signal = signal[: N - i] * gain
    amb_l[i:i + len(signal)] += signal * np.sqrt(0.5 * (1 - pan))
    amb_r[i:i + len(signal)] += signal * np.sqrt(0.5 * (1 + pan))


t = np.arange(N) / SR
for channel, seed in ((amb_l, 7), (amb_r, 8)):
    noise = np.random.default_rng(seed).standard_normal(N)
    b, a = butter(2, [180 / (SR / 2), 700 / (SR / 2)], btype="band")
    wind = lfilter(b, a, noise)
    swell = 0.55 + 0.45 * np.sin(2 * np.pi * t / 23 + seed) * np.sin(2 * np.pi * t / 9.7 + seed * 2)
    channel += wind * swell * 0.05

crackle = np.zeros(N)
for i in rng.choice(N, size=int(LENGTH * 14), replace=False):
    width = rng.integers(20, 160)
    crackle[i:i + width] += rng.uniform(-1, 1, min(width, N - i)) * np.exp(-np.arange(min(width, N - i)) / (width / 4)) * rng.uniform(0.2, 1)
b, a = butter(2, 1500 / (SR / 2), btype="high")
crackle = lfilter(b, a, crackle)
rumble = lfilter(*butter(2, 120 / (SR / 2)), rng.standard_normal(N)) * 0.6
amb(crackle * 0.05 + rumble * 0.02, 0, 1.0, 0.45)


def caw(length=0.32):
    n = int(length * SR)
    tt = np.arange(n) / SR
    f0 = 640 - 160 * tt / length
    phase = np.cumsum(f0) / SR
    saw = 2 * (phase % 1.0) - 1 + 0.3 * rng.standard_normal(n)
    out = np.zeros(n)
    for centre, width in ((1150, 300), (2400, 500)):
        b, a = butter(2, [(centre - width) / (SR / 2), (centre + width) / (SR / 2)], btype="band")
        out += lfilter(b, a, saw)
    return out * np.sin(np.pi * tt / length) ** 0.6


def hoot(length=0.55, f=370):
    n = int(length * SR)
    tt = np.arange(n) / SR
    return np.sin(2 * np.pi * (f - 25 * tt / length) * tt) * np.sin(np.pi * tt / length) ** 1.5


def bell(f=196, length=7.0):
    n = int(length * SR)
    tt = np.arange(n) / SR
    out = np.zeros(n)
    for ratio, gain, tau in ((0.5, 0.6, 4.0), (1.0, 1.0, 3.0), (1.19, 0.5, 2.0), (1.5, 0.4, 1.8), (2.0, 0.35, 1.4), (2.74, 0.2, 0.9)):
        out += gain * np.sin(2 * np.pi * f * ratio * tt) * np.exp(-tt / tau)
    return out * np.minimum(tt / 0.004, 1)


def howl(length=3.6):
    n = int(length * SR)
    tt = np.arange(n) / SR
    glide = 420 + 260 * np.sin(np.pi * np.minimum(tt / (length * 0.45), 1) / 2) - 140 * np.maximum(0, tt - length * 0.6) / (length * 0.4)
    f = glide * (1 + 0.012 * np.sin(2 * np.pi * 5.5 * tt))
    tone = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.3 * np.sin(4 * np.pi * np.cumsum(f) / SR)
    return tone * np.sin(np.pi * tt / length) ** 1.2


for at, pan in ((9.0, -0.7), (51.5, 0.6), (98.0, -0.4)):
    for k in range(rng.integers(2, 4)):
        amb(caw(), at + k * 0.45, 0.10, pan)
for at in (30.0, 116.0):
    amb(hoot(0.45), at, 0.08, 0.5)
    amb(hoot(0.35), at + 0.8, 0.07, 0.5)
    amb(hoot(0.6), at + 1.3, 0.08, 0.5)
for at in (4.0, 68.5):
    amb(bell(), at, 0.06, -0.2)
amb(howl(), 80.0, 0.035, 0.8)

amb_l_wet, amb_r_wet = reverb(amb_l, 3.5, 3), reverb(amb_r, 3.5, 4)
out_l = music_l + amb_l * 0.8 + amb_l_wet * 0.5
out_r = music_r + amb_r * 0.8 + amb_r_wet * 0.5

# Made to loop: the tail laid over the start
loop = int(LENGTH * SR)
tail = N - loop
out_l[:tail] += out_l[loop:]
out_r[:tail] += out_r[loop:]
out = np.stack([out_l[:loop], out_r[:loop]], axis=1)
out = out / np.max(np.abs(out)) * 0.85

pcm = (out * 32767).astype("<i2")
import wave

with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("seconds", round(LENGTH, 2))
