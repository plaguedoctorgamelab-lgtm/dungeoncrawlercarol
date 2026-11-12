"""Chiptune synthesizer for Dungeon Crawler Carol.

Generates every sound effect and music track the game uses as 16-bit mono WAV files,
using only the Python standard library (no numpy, no downloads, no third-party audio).
Everything is original and procedurally composed, so there are no licensing concerns.

Usage (from the project root):
    python tools/synth_audio.py
Writes:
    assets/audio/sfx/*.wav     ~25 one-shot effects
    assets/audio/music/*.wav   6 loops (title, 4 realms, boss) + victory/defeat jingles
"""
import math
import os
import random
import struct
import wave

RATE = 22050
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")


# ---------------------------------------------------------------- primitives

def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def buf(seconds):
    return [0.0] * int(seconds * RATE)


def osc(kind, phase, duty=0.5):
    p = phase % 1.0
    if kind == "square":
        return 1.0 if p < duty else -1.0
    if kind == "tri":
        return 4.0 * p - 1.0 if p < 0.5 else 3.0 - 4.0 * p
    if kind == "saw":
        return 2.0 * p - 1.0
    if kind == "sine":
        return math.sin(2 * math.pi * p)
    raise ValueError(kind)


def tone(out, start, dur, f0, f1=None, kind="square", vol=0.3, duty=0.5,
         attack=0.004, release=0.04, vibrato=0.0, vib_rate=6.0, curve=1.0):
    """Adds a pitched note (with optional slide f0->f1 and vibrato) into `out`."""
    f1 = f0 if f1 is None else f1
    n0 = int(start * RATE)
    n = int(dur * RATE)
    phase = 0.0
    for i in range(n):
        t = i / RATE
        k = (i / max(1, n - 1)) ** curve
        f = f0 + (f1 - f0) * k
        if vibrato:
            f *= 1.0 + vibrato * math.sin(2 * math.pi * vib_rate * t)
        phase += f / RATE
        env = min(1.0, t / attack) if attack > 0 else 1.0
        tail = (n - i) / RATE
        if tail < release:
            env *= tail / release
        j = n0 + i
        if j < len(out):
            out[j] += osc(kind, phase, duty) * vol * env


def noise(out, start, dur, vol=0.3, decay=8.0, lowpass=1.0, rng=None, attack=0.002):
    """White noise with exponential decay and a one-pole low-pass (lowpass in 0..1)."""
    rng = rng or random.Random(7)
    n0 = int(start * RATE)
    n = int(dur * RATE)
    y = 0.0
    for i in range(n):
        t = i / RATE
        x = rng.uniform(-1.0, 1.0)
        y += lowpass * (x - y)
        env = math.exp(-decay * t) * min(1.0, t / attack)
        tail = (n - i) / RATE
        if tail < 0.01:
            env *= tail / 0.01
        j = n0 + i
        if j < len(out):
            out[j] += y * vol * env


def sweep_noise(out, start, dur, vol, lp0, lp1, rise=0.3, rng=None):
    """A 'whoosh': noise whose brightness sweeps lp0->lp1 with a swell then fade."""
    rng = rng or random.Random(11)
    n0 = int(start * RATE)
    n = int(dur * RATE)
    y = 0.0
    for i in range(n):
        k = i / max(1, n - 1)
        lp = lp0 + (lp1 - lp0) * k
        y += lp * (rng.uniform(-1, 1) - y)
        env = (k / rise) if k < rise else (1.0 - (k - rise) / (1.0 - rise))
        j = n0 + i
        if j < len(out):
            out[j] += y * vol * max(0.0, env)


def kick(out, start, vol=0.7):
    tone(out, start, 0.14, 150, 40, kind="sine", vol=vol, release=0.06, curve=0.5)


def snare(out, start, vol=0.35, rng=None):
    noise(out, start, 0.12, vol=vol, decay=22, lowpass=0.7, rng=rng)
    tone(out, start, 0.05, 220, 180, kind="tri", vol=vol * 0.5)


def hat(out, start, vol=0.12, rng=None):
    noise(out, start, 0.035, vol=vol, decay=80, lowpass=1.0, rng=rng)


def write(path, samples, gain=1.0):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    peak = max(0.001, max(abs(s) for s in samples))
    norm = min(gain, 0.92 / peak)
    frames = bytearray()
    for s in samples:
        v = math.tanh(s * norm * 1.1) / math.tanh(1.1)
        frames += struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32000))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))
    return len(samples) / RATE


# ---------------------------------------------------------------- sound effects

def make_sfx():
    fx = {}

    o = buf(0.09); noise(o, 0, 0.08, 0.5, decay=40, lowpass=0.25); tone(o, 0, 0.05, 110, 70, "tri", 0.3)
    fx["step"] = o

    o = buf(0.22); sweep_noise(o, 0, 0.2, 0.6, 0.15, 0.9, rise=0.35); tone(o, 0.02, 0.14, 500, 1400, "square", 0.08, duty=0.25)
    fx["swing"] = o

    o = buf(0.26); tone(o, 0, 0.09, 700, 1500, "square", 0.25, duty=0.3); tone(o, 0.09, 0.15, 1500, 650, "square", 0.25, duty=0.3, vibrato=0.04, vib_rate=30)
    fx["squeak"] = o

    o = buf(0.2); noise(o, 0, 0.16, 0.6, decay=25, lowpass=0.6); tone(o, 0, 0.12, 180, 60, "square", 0.35, duty=0.4)
    fx["hit"] = o

    o = buf(0.24); tone(o, 0, 0.22, 900, 250, "sine", 0.35, curve=0.6); sweep_noise(o, 0, 0.2, 0.2, 0.6, 0.1)
    fx["miss"] = o

    o = buf(0.32); sweep_noise(o, 0, 0.3, 0.55, 0.5, 0.15, rise=0.1); tone(o, 0, 0.25, 900, 500, "sine", 0.15, vibrato=0.05, vib_rate=40)
    fx["shoot_water"] = o

    o = buf(0.08); tone(o, 0, 0.03, 1600, 900, "square", 0.35, duty=0.2); noise(o, 0, 0.05, 0.4, decay=70, lowpass=0.9)
    fx["shoot_nail"] = o

    o = buf(0.2); tone(o, 0, 0.16, 520, 260, "square", 0.3, duty=0.25); noise(o, 0, 0.06, 0.2, decay=50)
    fx["enemy_shoot"] = o

    o = buf(0.2); sweep_noise(o, 0, 0.17, 0.5, 0.1, 0.5, rise=0.4); tone(o, 0.03, 0.12, 200, 120, "saw", 0.12)
    fx["enemy_swing"] = o

    o = buf(0.55)
    for i, m in enumerate([72, 67, 63, 58, 51]):
        tone(o, i * 0.08, 0.1, midi_hz(m), midi_hz(m - 2), "square", 0.25, duty=0.5)
    noise(o, 0, 0.3, 0.25, decay=10, lowpass=0.4)
    fx["enemy_death"] = o

    o = buf(0.3); tone(o, 0, 0.26, 330, 150, "square", 0.32, duty=0.4, vibrato=0.08, vib_rate=25); noise(o, 0, 0.1, 0.35, decay=30, lowpass=0.5)
    fx["carol_hurt"] = o

    o = buf(0.6)
    r = random.Random(3)
    for i in range(9):
        f = r.uniform(500, 900) + i * 90
        tone(o, i * 0.055, 0.05, f, f * 1.5, "sine", 0.22)
    tone(o, 0.48, 0.1, midi_hz(84), None, "square", 0.15, duty=0.25)
    fx["drink"] = o

    o = buf(0.24); sweep_noise(o, 0, 0.22, 0.45, 0.1, 1.0, rise=0.6); tone(o, 0, 0.18, 300, 1200, "tri", 0.25, curve=0.7)
    fx["dash"] = o

    o = buf(0.2); tone(o, 0, 0.08, 160, 90, "square", 0.35, duty=0.5); sweep_noise(o, 0.03, 0.15, 0.35, 0.2, 0.6)
    fx["shove"] = o

    o = buf(0.35); noise(o, 0, 0.32, 0.8, decay=12, lowpass=0.3); kick(o, 0, 0.8); tone(o, 0, 0.2, 90, 45, "square", 0.25)
    fx["slam"] = o

    o = buf(0.3); tone(o, 0, 0.25, 1800, 1750, "square", 0.15, duty=0.1, release=0.2); tone(o, 0.01, 0.22, 2420, 2400, "square", 0.12, duty=0.1, release=0.2); noise(o, 0, 0.05, 0.3, decay=60)
    fx["spikes"] = o

    o = buf(0.32)
    for i, m in enumerate([72, 76, 79, 84]):
        tone(o, i * 0.06, 0.09, midi_hz(m), None, "square", 0.22, duty=0.25)
    fx["pickup"] = o

    o = buf(0.04); tone(o, 0, 0.03, 1100, 900, "square", 0.25, duty=0.25, release=0.01)
    fx["ui_click"] = o

    o = buf(0.26); tone(o, 0, 0.1, midi_hz(76), None, "tri", 0.4); tone(o, 0.1, 0.14, midi_hz(83), None, "tri", 0.4)
    fx["turn_player"] = o

    o = buf(0.26); tone(o, 0, 0.1, midi_hz(64), None, "square", 0.2, duty=0.25); tone(o, 0.1, 0.14, midi_hz(59), None, "square", 0.2, duty=0.25)
    fx["turn_enemy"] = o

    o = buf(1.4)
    for m in [36, 43, 46]:
        tone(o, 0, 1.3, midi_hz(m), midi_hz(m) * 0.97, "saw", 0.16, attack=0.3, release=0.4, vibrato=0.01)
    noise(o, 0, 1.3, 0.25, decay=1.5, lowpass=0.05)
    kick(o, 0.0, 0.8); kick(o, 0.6, 0.8)
    fx["boss_intro"] = o

    o = buf(0.7); tone(o, 0, 0.65, 200, 900, "saw", 0.2, vibrato=0.06, vib_rate=14, curve=1.6); tone(o, 0, 0.65, 100, 450, "square", 0.12, duty=0.3, curve=1.6)
    fx["boss_charge"] = o

    o = buf(0.8); noise(o, 0, 0.5, 0.6, decay=6, lowpass=0.8)
    for i, m in enumerate([96, 91, 100, 93, 98]):
        tone(o, 0.05 + i * 0.07, 0.25, midi_hz(m), None, "sine", 0.18, release=0.2)
    fx["cage_break"] = o

    for name, o in fx.items():
        write(os.path.join(SFX_DIR, name + ".wav"), o)
    return list(fx)


# ---------------------------------------------------------------- music

SCALES = {
    "major": [0, 2, 4, 5, 7, 9, 11],
    "minor": [0, 2, 3, 5, 7, 8, 10],
    "dorian": [0, 2, 3, 5, 7, 9, 10],
    "mixo": [0, 2, 4, 5, 7, 9, 10],
    "phrygian": [0, 1, 3, 5, 7, 8, 10],
}

# key root (MIDI), scale, bpm, chord degrees per bar (16 bars), lead timbre, seed, swing
TRACKS = {
    "title": (57, "minor", 150, [0, 5, 3, 4, 0, 5, 6, 4, 0, 5, 3, 4, 5, 3, 4, 4], ("square", 0.5), 1),
    "earth": (55, "mixo", 132, [0, 0, 6, 3, 0, 0, 6, 4, 3, 3, 0, 4, 3, 6, 4, 4], ("square", 0.25), 2),
    "air": (62, "major", 140, [0, 3, 4, 3, 5, 3, 4, 4, 0, 3, 4, 5, 3, 4, 0, 4], ("tri", 0.5), 3),
    "fire": (52, "phrygian", 156, [0, 1, 0, 6, 0, 1, 5, 4, 0, 1, 0, 6, 5, 4, 1, 4], ("saw", 0.5), 4),
    "water": (50, "dorian", 118, [0, 3, 0, 4, 5, 3, 6, 4, 0, 3, 0, 4, 5, 6, 3, 4], ("square", 0.125), 5),
    "boss": (45, "minor", 164, [0, 0, 5, 5, 3, 3, 4, 4, 0, 0, 5, 5, 6, 6, 4, 4], ("saw", 0.5), 6),
}

RHYTHMS = [
    [1, 0, 1, 0, 1, 1, 0, 1],
    [1, 0, 0, 1, 0, 0, 1, 0],
    [1, 1, 0, 1, 1, 0, 1, 0],
    [1, 0, 1, 1, 0, 1, 1, 0],
    [1, 0, 0, 0, 1, 0, 1, 1],
]


def chord_tones(root, scale, degree):
    s = SCALES[scale]
    return [root + s[(degree + k) % 7] + 12 * ((degree + k) // 7) for k in (0, 2, 4)]


def make_track(name, root, scale, bpm, prog, lead, seed):
    rng = random.Random(seed)
    beat = 60.0 / bpm
    bars = len(prog)
    length = bars * 4 * beat
    out = buf(length + 0.05)
    nrng = random.Random(seed * 13)
    lead_kind, lead_duty = lead
    # A motif per 4-bar phrase, varied on repeats.
    motifs = []
    for _ in range(2):
        motif = []
        for b in range(4):
            rhythm = rng.choice(RHYTHMS)
            notes = [rng.choice([0, 1, 2, 2, 3, 4, 4, 5]) for _ in range(8)]
            motif.append((rhythm, notes))
        motifs.append(motif)
    for bar in range(bars):
        t0 = bar * 4 * beat
        deg = prog[bar]
        ct = chord_tones(root, scale, deg)
        # Bass: root / octave eighths (triangle).
        for e in range(8):
            m = ct[0] - 12 + (12 if e % 4 == 2 else 0)
            tone(out, t0 + e * beat / 2, beat / 2 * 0.9, midi_hz(m), None, "tri", 0.34, release=0.02)
        # Arpeggio: 16ths over chord tones (quiet thin square).
        for s16 in range(16):
            m = ct[s16 % 3] + 12
            tone(out, t0 + s16 * beat / 4, beat / 4 * 0.8, midi_hz(m), None, "square", 0.05, duty=0.125, release=0.01)
        # Lead melody (skip some bars to breathe).
        phrase = motifs[(bar // 4) % 2]
        rhythm, notes = phrase[bar % 4]
        if bar % 8 != 7:
            s = SCALES[scale]
            for e in range(8):
                if not rhythm[e]:
                    continue
                step = notes[e] + deg
                m = root + 12 + s[step % 7] + 12 * (step // 7)
                if bar >= 8 and rng.random() < 0.15:
                    m += 12
                dur = beat / 2 * (1.8 if e < 7 and not rhythm[e + 1] else 0.9)
                tone(out, t0 + e * beat / 2, dur, midi_hz(m), None, lead_kind, 0.17, duty=lead_duty,
                     release=0.05, vibrato=0.006, vib_rate=5.5)
        # Drums.
        for b in range(4):
            tb = t0 + b * beat
            if b in (0, 2):
                kick(out, tb, 0.55)
            else:
                snare(out, tb, 0.3, rng=nrng)
            hat(out, tb + beat / 2, 0.1, rng=nrng)
            hat(out, tb, 0.06, rng=nrng)
        if name == "boss" and bar % 2 == 1:
            kick(out, t0 + 3.5 * beat, 0.45)
    return out[: int(length * RATE)]


def make_jingles():
    o = buf(2.6)
    seq = [(72, 0.12), (76, 0.12), (79, 0.12), (84, 0.36), (79, 0.12), (84, 0.9)]
    t = 0.0
    for m, d in seq:
        tone(o, t, d, midi_hz(m), None, "square", 0.22, duty=0.5, release=0.05, vibrato=0.01)
        tone(o, t, d, midi_hz(m - 12), None, "tri", 0.25)
        t += d
    for m in [60, 64, 67, 72]:
        tone(o, t - 0.9, 1.2, midi_hz(m), None, "square", 0.06, duty=0.25, release=0.4)
    kick(o, 0, 0.5); kick(o, 0.36, 0.5); snare(o, 0.72, 0.3); kick(o, t - 0.9, 0.6)
    write(os.path.join(MUSIC_DIR, "victory.wav"), o)

    o = buf(2.4)
    t = 0.0
    for m, d in [(67, 0.3), (66, 0.3), (65, 0.3), (64, 1.2)]:
        tone(o, t, d, midi_hz(m), midi_hz(m) * (0.94 if d > 1 else 1.0), "square", 0.2, duty=0.5, vibrato=0.02)
        tone(o, t, d, midi_hz(m - 24), None, "tri", 0.3)
        t += d
    write(os.path.join(MUSIC_DIR, "defeat.wav"), o)


def main():
    names = make_sfx()
    print("sfx:", len(names), ", ".join(names))
    for name, (root, scale, bpm, prog, lead, seed) in TRACKS.items():
        secs = write(os.path.join(MUSIC_DIR, name + ".wav"), make_track(name, root, scale, bpm, prog, lead, seed), gain=1.0)
        print("music: %s %.1fs" % (name, secs))
    make_jingles()
    print("jingles: victory, defeat")


if __name__ == "__main__":
    main()
