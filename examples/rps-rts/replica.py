#!/usr/bin/env python3
"""An independent port of the prototype's simulation, for checking rps.cm.

Written from the update loop in rps-iso-rts.html, not from the catmint code:
same rules, same constants, same order of operations. `check.sh` runs both
for a range of frame counts and compares every unit's state bit for bit.

    replica.py FRAMES [--game] [--spawn STEP:KIND,...]
                           prints "team kind x y hp" per surviving unit, with
                           x and y scaled by 1e12 and hp by 1e9 as integers,
                           then the bases' health, the gold and who won

    --game       the prototype's game: two bases, 90 gold each, and the
                 opponent's AI; without it, the fixed skirmish and no AI
    --spawn      the player buys a unit of KIND (0 rock, 1 paper, 2 scissors)
                 at STEP, before that step's update -- where a key pressed in
                 rps's --play input lands

Math.random is replaced on both sides by the same seeded generator, the
linear congruential one lib/random.cmm implements, reimplemented here from
its definition, so the two follow one game.

A catmint Float and every float literal are IEEE doubles, the same as a
Python float, so the two agree bit for bit with no adjustment.
"""
import math
import sys

SPEED, UNIT_HP, DMG, HIT_EVERY = 1.7, 40.0, 8.0, 0.5
RANGE, AGGRO, BASE_HP = 0.85, 2.2, 150.0
COLS, ROWS = 14, 10
SEPARATION = 0.45
EDGE = 0.3
BEATS = {0: 2, 2: 1, 1: 0}            # rock beats scissors beats paper beats rock


class Entity:
    pass


def unit(team, kind, x, y):
    u = Entity()
    u.team, u.kind, u.x, u.y = team, kind, x, y
    u.hp, u.cd, u.target, u.base = UNIT_HP, 0.0, None, False
    return u


def base(team, x, y):
    b = Entity()
    b.team, b.x, b.y, b.hp, b.base, b.kind = team, x, y, BASE_HP, True, None
    return b


class Lcg:
    """The C standard's generator, as lib/random.cmm has it: a 32-bit signed
    state, wrapping, and the high bits kept."""

    def __init__(self, seed):
        self.state = seed if seed != 0 else 1

    def next(self):
        s = (self.state * 1103515245 + 12345) & 0xFFFFFFFF
        self.state = s - (1 << 32) if s >= (1 << 31) else s
        return (self.state >> 16) & 32767

    def chance(self):
        return self.next() / 32768.0


args = sys.argv[1:]
FRAMES = int(args[0])
GAME = "--game" in args
SPAWNS = {}
if "--spawn" in args:
    for item in args[args.index("--spawn") + 1].split(","):
        step, kind = item.split(":")
        SPAWNS.setdefault(int(step), []).append(int(kind))

rng = Lcg(7)
gold = [90.0, 90.0]
ai_timer = 0.0
over = 0
if GAME:
    units = []
else:
    units = [unit(0, 0, 3.2, 3.0), unit(0, 1, 3.4, 4.5), unit(0, 2, 3.2, 6.0), unit(0, 0, 2.6, 5.2),
             unit(1, 2, 10.8, 3.2), unit(1, 0, 10.6, 4.6), unit(1, 1, 10.8, 6.1), unit(1, 1, 11.4, 5.0)]
bases = [base(0, 1.5, 4.5), base(1, 12.5, 4.5)]
COST, INCOME, AI_EVERY = 30.0, 6.0, 3.5
COUNTER = {0: 1, 1: 2, 2: 0}           # rock is beaten by paper, and so on


def try_spawn(team, kind):
    """trySpawn(): the base's side of the board, a little random, and a first
    blow that comes a little late, three random draws in that order."""
    if over or gold[team] < COST:
        return
    gold[team] -= COST
    b = bases[team]
    direction = 1 if team == 0 else -1
    x = b.x + direction * (0.9 + rng.chance() * 0.4)
    y = b.y + (rng.chance() - 0.5) * 1.6
    u = unit(team, kind, x, y)
    u.cd = rng.chance() * 0.3
    units.append(u)


def ai_tick(dt):
    """aiTick() from the prototype, the draws in its order: the 0.7 only when
    the player has something to counter, then a kind only if not countering."""
    global ai_timer
    ai_timer += dt
    if ai_timer < AI_EVERY:
        return
    ai_timer = 0.0
    n = {0: 0, 1: 0, 2: 0}
    for u in units:
        if u.team == 0:
            n[u.kind] += 1
    top = 0
    for kind in (1, 2):                 # reduce((a, b) => n[a] >= n[b] ? a : b)
        top = top if n[top] >= n[kind] else kind
    if n[top] > 0 and rng.chance() < 0.7:
        pick = COUNTER[top]
    else:
        pick = int(rng.chance() * 3)
    try_spawn(1, pick)


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
    global units, over
    if over:
        return
    gold[0] += INCOME * dt
    gold[1] += INCOME * dt
    if GAME:
        ai_tick(dt)
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
            d = math.sqrt(dx * dx + dy * dy) or 0.001
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
    if bases[1].hp <= 0:
        over = 1
    elif bases[0].hp <= 0:
        over = 2


for step in range(FRAMES):
    for kind in SPAWNS.get(step, []):
        try_spawn(0, kind)
    update(1.0 / 60.0)
for u in units:
    print("%d %d %d %d %d" % (u.team, u.kind, int(u.x * 1e12),
                              int(u.y * 1e12), int(u.hp * 1e9)))
print("bases %d %d" % (int(bases[0].hp * 1e9), int(bases[1].hp * 1e9)))
print("gold %d %d" % (int(gold[0] * 1e9), int(gold[1] * 1e9)))
print("over %d" % over)
