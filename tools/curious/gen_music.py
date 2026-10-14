"""gen_music.py OUT.wav: the Curious Door's music, an original piece made here (nothing sampled).

Golden, curious, a little mysterious: E major with the raised fourth (Lydian) for the wonder of it. A celesta
carries the tune over a harp, a soft choir ("aah"), bells far off, a shimmer of high sparkles and a warm low drone.
Intro, A, B, A' (the strings join the tune), 4/4 at 72 beats a minute, 32 bars (about 107 s), made to loop: its
last seconds (the reverb's tail) are laid over its first."""
import sys
import wave

import numpy as np
from scipy.signal import butter, fftconvolve, lfilter

SR = 44100
BPM = 72
BEAT = 60 / BPM
BAR = 4 * BEAT
BARS = 32
LENGTH = BARS * BAR
TAIL = 5.0
N = int((LENGTH + TAIL) * SR)
rng = np.random.default_rng(1414)

NOTES = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}


def hz(name):
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((NOTES[pitch] + 12 * (octave + 1) - 69) / 12)


# Chords: notes (the first is the root), one a bar
CHORDS = {
    "E9": ["E", "G#", "B", "F#"], "G#m7": ["G#", "B", "D#", "F#"], "C#m9": ["C#", "E", "G#", "D#"], "A#11": ["A", "C#", "E", "D#"],
    "E/G#": ["G#", "B", "E", "F#"], "F#m9": ["F#", "A", "C#", "G#"], "Asus2": ["A", "B", "E", "C#"], "Bsus": ["B", "E", "F#", "A"],
    "B": ["B", "D#", "F#", "A"], "A": ["A", "C#", "E", "B"], "C#m": ["C#", "E", "G#", "B"], "G#m": ["G#", "B", "D#", "F#"],
}
INTRO = ["E9", "A#11", "E9", "Bsus"]
A_CHORDS = ["E9", "G#m7", "C#m9", "A#11", "E/G#", "F#m9", "Asus2", "Bsus"]
B_CHORDS = ["A", "B", "G#m", "C#m", "F#m9", "G#m7", "A#11", "B"]
OUTRO = ["E9", "A#11", "Asus2", "Bsus"]
# The tune: (note, beats) per bar; "-" rests
A_TUNE = [[("B4", 1), ("E5", 1), ("F#5", 1), ("G#5", 1)], [("B5", 2), ("G#5", 1), ("F#5", 1)],
          [("E5", 1.5), ("D#5", 0.5), ("C#5", 1), ("G#5", 1)], [("A#5", 3), ("-", 1)],
          [("G#5", 1), ("B5", 1), ("E6", 1), ("D#6", 1)], [("C#6", 2), ("A5", 1), ("G#5", 1)],
          [("F#5", 1), ("E5", 1), ("C#5", 1), ("E5", 1)], [("F#5", 4)]]
B_TUNE = [[("C#6", 1), ("B5", 1), ("A5", 1), ("E5", 1)], [("D#5", 2), ("F#5", 2)],
          [("G#5", 1), ("B5", 1), ("D#6", 2)], [("C#6", 3), ("-", 1)],
          [("A5", 1), ("G#5", 1), ("F#5", 1), ("C#5", 1)], [("D#5", 1), ("F#5", 1), ("B5", 2)],
          [("A#5", 1), ("B5", 1), ("C#6", 1), ("E6", 1)], [("D#6", 2), ("F#6", 2)]]

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


def celesta(f, length=2.6):
    n = int(length * SR)
    t = np.arange(n) / SR
    return (np.sin(2 * np.pi * f * t) * env(n, 0.002, 1.1) + 0.42 * np.sin(2 * np.pi * 2.01 * f * t) * env(n, 0.002, 0.4)
            + 0.2 * np.sin(2 * np.pi * 3.98 * f * t) * env(n, 0.001, 0.16) + 0.1 * np.sin(2 * np.pi * 8.1 * f * t) * env(n, 0.001, 0.05))


HARPS = {}


def harp(f, length=2.4):
    key = (round(f, 3), length)
    if key in HARPS:
        return HARPS[key]
    n = int(length * SR)
    period = max(int(SR / f), 2)
    buf = rng.uniform(-1, 1, period)
    out = np.empty(n)
    for i in range(n):
        out[i] = buf[i % period]
        buf[i % period] = 0.5 * (buf[i % period] + buf[(i + 1) % period]) * 0.997
    b, a = butter(2, min(5000 / (SR / 2), 0.99))
    HARPS[key] = lfilter(b, a, out) * env(n, 0.002, 1.5)
    return HARPS[key]


def choir(freqs, length):
    """A soft choir on "aah": sawtooths with a slow vibrato through the vowel's formants."""
    n = int(length * SR)
    t = np.arange(n) / SR
    src = np.zeros(n)
    for f in freqs:
        for detune in (-0.006, 0.0, 0.007):
            vib = 1 + 0.004 * np.sin(2 * np.pi * (5.1 + rng.uniform(-0.4, 0.4)) * t + rng.uniform(0, 6))
            phase = np.cumsum(f * (1 + detune) * vib) / SR + rng.uniform()
            src += 2 * (phase % 1.0) - 1
    out = np.zeros(n)
    for centre, width, gain in ((700, 130, 1.0), (1150, 160, 0.6), (2650, 300, 0.25)):
        b, a = butter(2, [(centre - width) / (SR / 2), (centre + width) / (SR / 2)], btype="band")
        out += lfilter(b, a, src) * gain
    fade = np.clip(np.minimum(t / 1.2, (length - t) / 1.2), 0, 1)
    return out / (3 * len(freqs)) * fade


def strings(freqs, length):
    n = int(length * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for f in freqs:
        for detune in (-0.003, 0.0, 0.004):
            vib = 1 + 0.003 * np.sin(2 * np.pi * 5.6 * t + rng.uniform(0, 6))
            phase = np.cumsum(f * (1 + detune) * vib) / SR + rng.uniform()
            out += 2 * (phase % 1.0) - 1
    b, a = butter(2, 2200 / (SR / 2))
    fade = np.clip(np.minimum(t / 0.35, (length - t) / 0.5), 0, 1)
    return lfilter(b, a, out) / (3 * len(freqs)) * fade


def bell(f, length=6.0):
    n = int(length * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for ratio, gain, tau in ((0.5, 0.5, 3.5), (1.0, 1.0, 2.6), (1.19, 0.45, 1.8), (1.5, 0.35, 1.5), (2.0, 0.3, 1.2), (2.76, 0.18, 0.8)):
        out += gain * np.sin(2 * np.pi * f * ratio * t) * np.exp(-t / tau)
    return out * np.minimum(t / 0.003, 1)


def twinkle(f, length=0.9):
    n = int(length * SR)
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * f * t) * env(n, 0.001, 0.22) * (1 + 0.3 * np.sin(2 * np.pi * 23 * t))


def drone(f, length):
    n = int(length * SR)
    t = np.arange(n) / SR
    out = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t + 0.3) + 0.15 * np.sin(2 * np.pi * 3 * f * t)
    fade = np.clip(np.minimum(t / 2.0, (length - t) / 2.0), 0, 1)
    return out * fade * (0.8 + 0.2 * np.sin(2 * np.pi * t / 7.3))


def tune_bar(notes, start, gain, octave_up=False, with_strings=False):
    at = start
    for pitch, beats in notes:
        if pitch != "-":
            f = hz(pitch) * (2 if octave_up else 1)
            add(celesta(f), at, gain, -0.2)
            if with_strings:
                add(strings([f / 2], beats * BEAT + 0.4), at, 0.07, 0.25)
        at += beats * BEAT


def harp_bar(chord, start, gain, pattern):
    notes = [hz(chord[0] + "3"), hz(chord[1] + "3"), hz(chord[2] + "4"), hz(chord[3] + "4"), hz(chord[1] + "4"), hz(chord[2] + "5")]
    for k, step in enumerate(pattern):
        add(harp(notes[step % len(notes)]), start + k * BEAT / 2, gain, 0.35 - 0.1 * (step % 3))


form = [("I", INTRO), ("A", A_CHORDS), ("B", B_CHORDS), ("A2", A_CHORDS), ("O", OUTRO)]
bar = 0
for section, chords in form:
    for k, name in enumerate(chords):
        start = bar * BAR
        chord = CHORDS[name]
        add(drone(hz(chord[0] + "2"), BAR + 2.0), start, 0.08, 0.0)
        add(choir([hz(chord[0] + "3"), hz(chord[1] + "4"), hz(chord[2] + "4")], BAR + 1.2), start, 0.16 if section in ("B", "A2") else 0.11, -0.05)
        if section == "I":
            harp_bar(chord, start, 0.07, [0, 2, 3, 5, 4, 3, 2, 1])
            if k == 0:
                add(bell(hz("E4")), start, 0.07, -0.4)
        elif section == "O":
            harp_bar(chord, start, 0.06, [0, 2, 3, 5, 3, 2])
            if k == 2:
                add(bell(hz("B3")), start, 0.06, 0.4)
        else:
            harp_bar(chord, start, 0.06, [0, 2, 3, 4, 5, 4, 3, 2])
            tune = A_TUNE if section in ("A", "A2") else B_TUNE
            tune_bar(tune[k], start, 0.2 if section != "B" else 0.17, octave_up=False, with_strings=(section == "A2"))
            if section == "B":
                add(strings([hz(chord[1] + "4"), hz(chord[2] + "4")], BAR + 0.3), start, 0.05, 0.3)
            if k in (0, 4):
                add(bell(hz(chord[0] + "4")), start, 0.05, -0.35 if k == 0 else 0.35)
        bar += 1

# The shimmer: high sparkles here and there, in the chord of their bar
all_chords = [c for _, cs in form for c in cs]
for i in range(int(LENGTH * 2.2)):
    at = rng.uniform(0, LENGTH)
    chord = CHORDS[all_chords[min(int(at / BAR), len(all_chords) - 1)]]
    f = hz(chord[rng.integers(0, 4)] + str(rng.integers(6, 8)))
    add(twinkle(f), at, rng.uniform(0.012, 0.03), rng.uniform(-0.8, 0.8))

# A big soft hall: decorrelated noise tails, stereo
def reverb(x, seconds, seed):
    r = np.random.default_rng(seed)
    n = int(seconds * SR)
    ir = r.standard_normal(n) * np.exp(-np.arange(n) / SR / (seconds / 5))
    b, a = butter(1, 6000 / (SR / 2))
    ir = lfilter(b, a, ir)
    ir /= np.sqrt(np.sum(ir ** 2))
    return fftconvolve(x, ir)[: len(x)]


out_l = left * 0.7 + reverb(left, 4.2, 11) * 0.65
out_r = right * 0.7 + reverb(right, 4.2, 12) * 0.65

# Made to loop: the tail laid over the start
loop = int(LENGTH * SR)
tail = N - loop
out_l[:tail] += out_l[loop:]
out_r[:tail] += out_r[loop:]
out = np.stack([out_l[:loop], out_r[:loop]], axis=1)
out = out / np.max(np.abs(out)) * 0.85
pcm = (out * 32767).astype("<i2")
with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print("seconds", round(LENGTH, 2))
