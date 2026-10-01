#!/usr/bin/env python3
"""pixels.py FRAME.bmp X0 Y0 X1 Y1 R G B [N] - count pixels of colour (R, G, B)
in the half-open rectangle [X0, X1) x [Y0, Y1) of a BMP saved by `rps --shot`.
Prints the count. N, if given, is ignored: play.sh passes the whole spec."""
import struct
import sys

path = sys.argv[1]
x0, y0, x1, y1, r, g, b = (int(v) for v in sys.argv[2:9])
data = open(path, "rb").read()
offset = struct.unpack_from("<I", data, 10)[0]
width, height = struct.unpack_from("<ii", data, 18)
bpp = struct.unpack_from("<H", data, 28)[0]
row = (width * bpp // 8 + 3) & ~3


def pixel(x, y):
    yy = height - 1 - y if height > 0 else y
    o = offset + yy * row + x * (bpp // 8)
    return data[o + 2], data[o + 1], data[o]


print(sum(1 for x in range(x0, x1) for y in range(y0, y1) if pixel(x, y) == (r, g, b)))
