#!/usr/bin/env python3
"""check_ttf.py FRAME.bmp CELL_W CELL_H -- the frame ttf.cm saved: "Hi g" drawn in white at
(10, 10) in cells of CELL_W x CELL_H. There must be ink in the cells of H, i and g; none in the
space between them; none anywhere outside the four cells; and the g, which has a descender,
must have ink in the bottom sixth of its cell, where H has none."""
import struct
import sys

path, cw, ch = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
data = open(path, "rb").read()
offset = struct.unpack_from("<I", data, 10)[0]
width, height = struct.unpack_from("<ii", data, 18)
bpp = struct.unpack_from("<H", data, 28)[0]
row = (width * bpp // 8 + 3) & ~3


def ink(x, y):
    yy = height - 1 - y if height > 0 else y
    o = offset + yy * row + x * (bpp // 8)
    return data[o] + data[o + 1] + data[o + 2] > 0


def count(x0, y0, x1, y1):
    return sum(1 for x in range(x0, x1) for y in range(y0, y1) if ink(x, y))


def cell(i, top=0, bottom=None):
    return count(10 + i * cw, 10 + top, 10 + (i + 1) * cw, 10 + (ch if bottom is None else bottom))


problems = []
for i, name in ((0, "H"), (1, "i"), (3, "g")):
    if cell(i) == 0:
        problems.append("no ink in the cell of %s" % name)
if cell(2) != 0:
    problems.append("ink in the cell of the space")
total = count(0, 0, width, height)
inside = count(10, 10, 10 + 4 * cw, 10 + ch)
if total != inside:
    problems.append("%d pixels of ink outside the four cells" % (total - inside))
low = ch - ch // 6
if cell(0, low) != 0:
    problems.append("H has ink in the bottom sixth of its cell")
if cell(3, low) == 0:
    problems.append("g has no descender in the bottom sixth of its cell")
if problems:
    print("; ".join(problems))
    sys.exit(1)
print("TrueType text is in its cells (H %d, i %d, g %d pixels)" % (cell(0), cell(1), cell(3)))
