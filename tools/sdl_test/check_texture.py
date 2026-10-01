#!/usr/bin/env python3
"""check_texture.py FRAME.bmp lib/fontdata.cmm

Checks the frame texture.cm drew, pixel for pixel: the texture's four colours,
its tinted half-transparent copy, the glyphs at one size and at two, a
character with no glyph, and the clip. The expected glyph bitmaps are read from
the same fontdata.cmm the font was built from, so what is checked is the path
from data to screen -- atlas, tint, scale, clip -- not the data itself, which
make_font.py takes from Unscii."""
import re
import struct
import sys

frame, fontdata = sys.argv[1], sys.argv[2]
data = open(frame, "rb").read()
offset = struct.unpack_from("<I", data, 10)[0]
width, height = struct.unpack_from("<ii", data, 18)
bpp = struct.unpack_from("<H", data, 28)[0]
row = (width * bpp // 8 + 3) & ~3


def pixel(x, y):
    yy = height - 1 - y if height > 0 else y
    o = offset + yy * row + x * (bpp // 8)
    return data[o + 2], data[o + 1], data[o]


hexes = re.findall(r'"([0-9A-F]{32})"', open(fontdata).read())
assert len(hexes) == 95, "fontdata.cmm should hold 95 glyphs, has %d" % len(hexes)


def glyph(code):
    """The 16 rows of the glyph for a character code, as lists of 0 and 1."""
    h = hexes[code - 32]
    return [[(int(h[2 * y:2 * y + 2], 16) >> (7 - x)) & 1 for x in range(8)]
            for y in range(16)]


failures = []


def expect(what, got, want):
    if got != want:
        failures.append("%s: got %s, wanted %s" % (what, got, want))


def block(x0, y0, w, h):
    return {pixel(x, y) for x in range(x0, x0 + w) for y in range(y0, y0 + h)}


def glyph_cell(label, code, x0, y0, scale, colour, background=(0, 0, 0)):
    mask = glyph(code)
    wrong = 0
    for y in range(16 * scale):
        for x in range(8 * scale):
            want = colour if mask[y // scale][x // scale] else background
            if pixel(x0 + x, y0 + y) != want:
                wrong += 1
    expect("%s, pixels differing" % label, wrong, 0)


# The texture, scaled 8x: one colour in each 8 x 8 quarter.
expect("red quarter", block(10, 10, 8, 8), {(255, 0, 0)})
expect("green quarter", block(18, 10, 8, 8), {(0, 255, 0)})
expect("blue quarter", block(10, 18, 8, 8), {(0, 0, 255)})
expect("white quarter", block(18, 18, 8, 8), {(255, 255, 255)})
# Its right-hand column (green over white) tinted red at half opacity over black:
# green*red = black, white*red = red, each at ~half. Top half black, bottom red/2.
top = block(30, 10, 8, 8)
bottom = block(30, 18, 8, 8)
expect("tinted, over green", top, {(0, 0, 0)})
(r, g, b), = bottom if len(bottom) == 1 else [(-1, -1, -1)]
expect("tinted, over white: red about half, no green or blue",
       (120 <= r <= 136, g, b), (True, 0, 0))
expect("outside the texture", pixel(5, 5), (0, 0, 0))

glyph_cell("H at scale 1", 72, 50, 10, 1, (255, 255, 0))
glyph_cell("H at scale 2", 72, 50, 40, 2, (0, 255, 255))
glyph_cell("a character with no glyph is a ?", 63, 80, 10, 1, (255, 255, 255))
glyph_cell("a two-byte character is one ?", 63, 100, 10, 1, (255, 255, 255))
glyph_cell("the H after it is in the next cell", 72, 108, 10, 1, (255, 255, 255))

# Clip: "HHHH" from x=40 clipped at x<60 shows 1.5 glyphs of the first three
# cells' pixels and nothing from 60 on.
mask = glyph(72)
wrong = 0
for y in range(16):
    for x in range(40, 80):
        cell, within = divmod(x - 40, 8)
        inside = x < 60
        want = (255, 255, 255) if inside and mask[y][within] else (0, 0, 0)
        if pixel(x, 80 + y) != want:
            wrong += 1
expect("clipped text, pixels differing", wrong, 0)

if failures:
    print("\n".join(failures))
    sys.exit(1)
print("textures and text draw exactly the glyphs")
