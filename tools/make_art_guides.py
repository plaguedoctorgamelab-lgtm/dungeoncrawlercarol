"""Draws fit-guide template PNGs for the image generator (pure Python, no dependencies).

Each guide is a #00FF00 canvas with the exact 2:1 isometric footprint and height lines the
game expects, at 4x game scale (a 128x64 tile = 512x256 here). Upload a guide alongside a
prompt and ask the generator to "draw the object inside these guide lines".

Usage: python tools/make_art_guides.py   ->  docs/art_guides/*.png
"""
import os
import struct
import zlib

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "docs", "art_guides")

GREEN = (0, 255, 0)
MAGENTA = (255, 0, 200)
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
YELLOW = (255, 230, 0)


class Canvas:
    def __init__(self, w, h, bg=GREEN):
        self.w, self.h = w, h
        self.px = [[bg for _ in range(w)] for _ in range(h)]

    def dot(self, x, y, c, r=1):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                xx, yy = int(round(x)) + dx, int(round(y)) + dy
                if 0 <= xx < self.w and 0 <= yy < self.h:
                    self.px[yy][xx] = c

    def line(self, x0, y0, x1, y1, c, r=2, dash=0):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) or 1
        for i in range(n + 1):
            if dash and (i // dash) % 2 == 1:
                continue
            t = i / n
            self.dot(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, c, r)

    def diamond(self, cx, cy, w, h, c, r=2, dash=0):
        top, right, bottom, left = (cx, cy - h / 2), (cx + w / 2, cy), (cx, cy + h / 2), (cx - w / 2, cy)
        for a, b in ((top, right), (right, bottom), (bottom, left), (left, top)):
            self.line(a[0], a[1], b[0], b[1], c, r, dash)

    def save(self, path):
        raw = b"".join(b"\x00" + bytes(v for p in row for v in p) for row in self.px)
        def chunk(t, d):
            return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
        data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 2, 0, 0, 0))
        data += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(data)


def box_guide(name, height):
    """Wireframe isometric box: 512x256 footprint at the bottom, vertical edges `height` tall."""
    w, foot = 512, 256
    c = Canvas(w, foot + height)
    cy = c.h - foot / 2  # footprint centre
    # Base diamond (solid) and top diamond (dashed), plus the 3 visible vertical edges.
    c.diamond(w / 2, cy, w - 4, foot - 4, MAGENTA, 2)
    c.diamond(w / 2, cy - height, w - 4, foot - 4, MAGENTA, 2, dash=10)
    for x, y in ((2, cy), (w - 2, cy), (w / 2, c.h - 2)):
        c.line(x, y, x, y - height, MAGENTA, 2, dash=10)
    # Bottom point marker (the anchor the game uses).
    c.dot(w / 2, c.h - 4, BLACK, 5)
    c.save(os.path.join(OUT, name))
    return c.w, c.h


def character_guide(name):
    """Character frame: tile diamond at the bottom, feet cross at its centre, head line on top."""
    w, h = 512, 640
    c = Canvas(w, h)
    cx, cy = w / 2, h - 128
    c.diamond(cx, cy, 508, 252, MAGENTA, 2)
    c.line(cx - 40, cy, cx + 40, cy, BLACK, 3)  # feet cross
    c.line(cx, cy - 40, cx, cy + 40, BLACK, 3)
    c.line(0, 24, w, 24, YELLOW, 2, dash=12)  # top of head / sword tip limit
    c.line(cx, 24, cx, cy - 40, WHITE, 1, dash=6)  # vertical centre line
    c.save(os.path.join(OUT, name))
    return w, h


def floor_guide(name):
    """A single floor tile diamond (512x256) for trap / floor decal art."""
    c = Canvas(512, 256)
    c.diamond(256, 128, 508, 252, MAGENTA, 2)
    c.save(os.path.join(OUT, name))
    return c.w, c.h


if __name__ == "__main__":
    for name, size in [
        ("guide_half_cover_512x512.png", box_guide("guide_half_cover_512x512.png", 256)),
        ("guide_full_cover_512x768.png", box_guide("guide_full_cover_512x768.png", 512)),
        ("guide_character_512x640.png", character_guide("guide_character_512x640.png")),
        ("guide_floor_trap_512x256.png", floor_guide("guide_floor_trap_512x256.png")),
    ]:
        print("wrote", name, size)
