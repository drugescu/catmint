#!/usr/bin/env python3
"""An independent port of the prototype's simulation, for checking rps.cm.

Written from the update loop in rps-iso-rts.html, not from the catmint code:
same rules, same constants, same order of operations. `check.sh` runs both
for a range of frame counts and compares every unit's state bit for bit.

    replica.py FRAMES      prints "team kind x y hp" per surviving unit, with
                           x and y scaled by 1e12 and hp by 1e9 as integers

Every Float literal in the catmint source is a float32 widened to a double --
FloatConstant stores a `float` -- so 3.2 arrives as 3.2000000476837158 and
1e12 as 999999995904. `f32` reproduces that; when literals become doubles,
delete it and this file gets simpler. Values built from literals at run time
(1.0 / 60.0, 1.0 / 3.0) are ordinary double arithmetic and are left alone.
"""
import math
import struct
import sys

f32 = lambda v: struct.unpack('f', struct.pack('f', v))[0]

SPEED, UNIT_HP, DMG, HIT_EVERY = f32(1.7), 40.0, 8.0, 0.5
RANGE, AGGRO, BASE_HP = f32(0.85), f32(2.2), 150.0
COLS, ROWS = 14, 10
SEPARATION = f32(0.45)
EDGE = f32(0.3)
BEATS = {0: 2, 2: 1, 1: 0}            # rock beats scissors beats paper beats rock


class Entity:
    pass


def unit(team, kind, x, y):
    u = Entity()
    u.team, u.kind, u.x, u.y = team, kind, f32(x), f32(y)
    u.hp, u.cd, u.target, u.base = UNIT_HP, 0.0, None, False
    return u


def base(team, x, y):
    b = Entity()
    b.team, b.x, b.y, b.hp, b.base, b.kind = team, x, y, BASE_HP, True, None
    return b


units = [unit(0, 0, 3.2, 3.0), unit(0, 1, 3.4, 4.5), unit(0, 2, 3.2, 6.0), unit(0, 0, 2.6, 5.2),
         unit(1, 2, 10.8, 3.2), unit(1, 0, 10.6, 4.6), unit(1, 1, 10.8, 6.1), unit(1, 1, 11.4, 5.0)]
bases = [base(0, 1.5, 4.5), base(1, 12.5, 4.5)]


def alive(e):
    return e is not None and e.hp > 0


def nearest(u, max_d):
    best, bd = None, max_d
    for e in units + bases:
        if e.team == u.team or not alive(e):
            continue
        dx, dy = u.x - e.x, u.y - e.y
        d = math.sqrt(dx * dx + dy * dy)
        if d < bd:
            bd, best = d, e
    return best


def hit(a, b):
    m = 1.0
    if not b.base:
        if BEATS[a.kind] == b.kind:
            m = 3.0
        elif BEATS[b.kind] == a.kind:
            m = 1.0 / 3.0
    b.hp -= DMG * m


def clamp(v, lo, hi):
    return lo if v < lo else hi if v > hi else v


def update(dt):
    global units
    for u in units:
        u.cd = max(0.0, u.cd - dt)
        if u.target and not alive(u.target):
            u.target = None
        if not u.target:
            u.target = nearest(u, 1e9 if u.team == 1 else AGGRO)
        if not u.target:
            continue
        dx, dy = u.target.x - u.x, u.target.y - u.y
        d = math.sqrt(dx * dx + dy * dy)
        if d > RANGE:
            s = min(SPEED * dt, d - RANGE)
            u.x += dx / d * s
            u.y += dy / d * s
        elif u.cd == 0.0:
            hit(u, u.target)
            u.cd = HIT_EVERY
    n = len(units)
    for i in range(n):
        for j in range(i + 1, n):
            a, b = units[i], units[j]
            dx, dy = b.x - a.x, b.y - a.y
            d = math.sqrt(dx * dx + dy * dy) or f32(0.001)
            if d < SEPARATION:
                p = (SEPARATION - d) / 2
                nx, ny = dx / d * p, dy / d * p
                a.x -= nx
                a.y -= ny
                b.x += nx
                b.y += ny
    for u in units:
        u.x = clamp(u.x, EDGE, COLS - EDGE)
        u.y = clamp(u.y, EDGE, ROWS - EDGE)
    for u in units:
        if u.hp <= 0:
            u.target = None
    units = [u for u in units if u.hp > 0]


for _ in range(int(sys.argv[1])):
    update(1.0 / 60.0)
for u in units:
    print("%d %d %d %d %d" % (u.team, u.kind, int(u.x * f32(1e12)),
                              int(u.y * f32(1e12)), int(u.hp * f32(1e9))))
