#!/usr/bin/env python3
"""Emit the same random program twice: once in catmint, once in C.

The two must print identical output. Anything else is a bug in one of the
compilers, and since clang is the one with a few thousand more users, the
bug is almost certainly here.

This is Csmith's idea at a fraction of its size. What makes it work is that
every operation goes through a helper defined identically in both languages,
so nothing in the generated program depends on a behaviour the two do not
share:

  * `+`, `-` and `*` wrap two's complement in catmint, which is LLVM `add`
    with no `nsw`. Signed overflow is undefined in C, so the C helpers do
    the arithmetic in `uint32_t` and cast back, which is the same value and
    is defined.
  * `/` and `%` are undefined for a zero divisor, and for INT_MIN / -1, in
    both. The helpers return the numerator instead.
  * A shift by 32 or more is undefined in both, and catmint really does
    produce nonsense for it -- `1 << 33` gave 14330280. The helpers mask the
    amount to 0..31.

Everything else is emitted fully parenthesised, which also means the
deliberately loose `%` precedence never shows up as a false difference.

Usage: generate.py <seed> <out.cm> <out.c>
"""

import random
import sys

# Kept well inside 32 bits so that a literal is always an Int and never an
# Int64, which would change the width the whole expression is computed at.
CONST_MIN, CONST_MAX = -10000, 10000

BINARY = ["sadd", "ssub", "smul", "sdiv", "smod", "sand", "sor", "sxor",
          "sshl", "sshr"]
COMPARE = ["<", "<=", ">", ">=", "==", "!="]


class Program:
    def __init__(self, seed):
        self.rng = random.Random(seed)
        self.seed = seed
        self.vars = []
        self.helpers = []      # (name, [params]) of generated methods
        self.cm = []
        self.c = []

    # ---- expressions -----------------------------------------------------

    def const(self):
        return self.rng.randint(CONST_MIN, CONST_MAX)

    def expr(self, depth, scope):
        """A random Int expression. Identical text in both languages except
        for how a helper call is spelled, which `call` handles."""
        if depth <= 0 or self.rng.random() < 0.3:
            if scope and self.rng.random() < 0.6:
                # Chosen once, not once per language: drawing twice would
                # emit different variables to the two files and every
                # disagreement after that would be this generator's fault.
                name = self.rng.choice(scope)
                return name, name
            k = self.const()
            # A negative literal is written as a subtraction from zero: the
            # grammar has unary minus, but spelling it this way keeps the two
            # emitters identical and cannot be read as part of the line above.
            text = str(k) if k >= 0 else "(0 - %d)" % -k
            return text, text

        if self.rng.random() < 0.15 and self.helpers:
            name, params = self.rng.choice(self.helpers)
            args = [self.expr(depth - 1, scope) for _ in params]
            cm = "Helpers.%s(%s)" % (name, ", ".join(a[0] for a in args))
            c = "%s(%s)" % (name, ", ".join(a[1] for a in args))
            return cm, c

        op = self.rng.choice(BINARY)
        left = self.expr(depth - 1, scope)
        right = self.expr(depth - 1, scope)
        cm = "Safe.%s(%s, %s)" % (op, left[0], right[0])
        c = "%s(%s, %s)" % (op, left[1], right[1])
        return cm, c

    def condition(self, depth, scope):
        op = self.rng.choice(COMPARE)
        left = self.expr(depth, scope)
        right = self.expr(depth, scope)
        joiner = self.rng.choice(["", " and ", " or "])
        if not joiner:
            return ("(%s %s %s)" % (left[0], op, right[0]),
                    "(%s %s %s)" % (left[1], op, right[1]))
        op2 = self.rng.choice(COMPARE)
        l2 = self.expr(depth, scope)
        r2 = self.expr(depth, scope)
        c_join = " && " if joiner == " and " else " || "
        return ("((%s %s %s)%s(%s %s %s))" % (left[0], op, right[0], joiner,
                                              l2[0], op2, r2[0]),
                "((%s %s %s)%s(%s %s %s))" % (left[1], op, right[1], c_join,
                                              l2[1], op2, r2[1]))

    # ---- statements ------------------------------------------------------

    def statements(self, count, depth, scope, targets, indent, cm, c,
                   loop_id, in_loop=False):
        """`scope` is what may be read, `targets` what may be assigned to.

        They differ, and the difference is load-bearing. A `for` variable is
        readable but must never be assigned: catmint recomputes it from an
        internal counter each iteration, so a store to it is forgotten, while
        C's loop variable is the counter and a store to it changes how many
        times the loop runs. The same goes for a `while` counter, which this
        generator increments itself to guarantee the loop ends."""
        pad = "  " * indent
        for _ in range(count):
            kind = self.rng.random()
            target = self.rng.choice(targets)

            # `break` and `continue`, which mean the same in both languages
            # and terminate the rest of this block in both. Only inside a
            # loop: outside one catmint rejects them and C does too.
            if in_loop and self.rng.random() < 0.12:
                word = self.rng.choice(["break", "continue"])
                cm.append("%s%s" % (pad, word))
                c.append("%s%s;" % (pad, word))
                return

            if kind < 0.45 or depth <= 0:
                e = self.expr(2, scope)
                cm.append("%s%s = %s" % (pad, target, e[0]))
                c.append("%s%s = %s;" % (pad, target, e[1]))

            elif kind < 0.65:
                cond = self.condition(1, scope)
                cm.append("%sif %s:" % (pad, cond[0]))
                c.append("%sif %s {" % (pad, cond[1]))
                self.statements(self.rng.randint(1, 2), depth - 1, scope,
                                targets, indent + 1, cm, c, loop_id, in_loop)
                cm.append("%selse" % pad)
                c.append("%s} else {" % pad)
                self.statements(self.rng.randint(1, 2), depth - 1, scope,
                                targets, indent + 1, cm, c, loop_id, in_loop)
                cm.append("%send" % pad)
                c.append("%s}" % pad)

            elif kind < 0.85:
                # A counted loop. catmint's `for i in n:` runs 0..n-1.
                n = self.rng.randint(1, 6)
                var = "i%d" % loop_id[0]
                loop_id[0] += 1
                cm.append("%sfor %s in %d:" % (pad, var, n))
                c.append("%sfor (int32_t %s = 0; %s < %d; %s++) {"
                         % (pad, var, var, n, var))
                self.statements(self.rng.randint(1, 3), depth - 1,
                                scope + [var], targets, indent + 1, cm, c,
                                loop_id, in_loop=True)
                cm.append("%send" % pad)
                c.append("%s}" % pad)

            else:
                # A while whose counter this generator owns, so it always ends.
                var = "w%d" % loop_id[0]
                loop_id[0] += 1
                n = self.rng.randint(1, 5)
                cm.append("%sInt %s = 0" % (pad, var))
                c.append("%sint32_t %s = 0;" % (pad, var))
                cm.append("%swhile %s < %d:" % (pad, var, n))
                c.append("%swhile (%s < %d) {" % (pad, var, n))
                # The counter advances at the top of the body, not the
                # bottom. A `continue` emitted below would skip a bottom
                # increment and the loop would never end -- in both
                # languages, so it would hang rather than disagree.
                cm.append("%s  %s = %s + 1" % (pad, var, var))
                c.append("%s  %s = %s + 1;" % (pad, var, var))
                self.statements(self.rng.randint(1, 2), depth - 1,
                                scope + [var], targets, indent + 1, cm, c,
                                loop_id, in_loop=True)
                cm.append("%send" % pad)
                c.append("%s}" % pad)

    # ---- whole program ---------------------------------------------------

    def generate(self):
        rng = self.rng
        self.vars = ["v%d" % i for i in range(rng.randint(3, 6))]

        # A few user methods, defined before anything can call them.
        helper_bodies_cm, helper_bodies_c = [], []
        for h in range(rng.randint(1, 3)):
            name = "f%d" % h
            params = ["p%d" % i for i in range(rng.randint(1, 3))]
            scope = list(params)
            body_cm, body_c = [], []
            self.statements(rng.randint(1, 3), 1, scope, scope, 2, body_cm,
                            body_c, [1000 * (h + 1)])
            result = self.expr(2, scope)
            helper_bodies_cm.append(
                "  static def Int %s(%s):\n%s\n    return %s\n  end"
                % (name, ", ".join("Int " + p for p in params),
                   "\n".join(body_cm), result[0]))
            helper_bodies_c.append(
                "static int32_t %s(%s) {\n%s\n  return %s;\n}"
                % (name, ", ".join("int32_t " + p for p in params),
                   "\n".join(body_c), result[1]))
            self.helpers.append((name, params))

        body_cm, body_c = [], []
        self.statements(rng.randint(4, 9), 2, self.vars, self.vars, 2,
                        body_cm, body_c, [0])

        initial = [self.const() for _ in self.vars]
        decls_cm = "\n".join("    Int %s = %d" % (v, k)
                             for v, k in zip(self.vars, initial))
        decls_c = "\n".join("  int32_t %s = %d;" % (v, k)
                            for v, k in zip(self.vars, initial))
        prints_cm = "\n".join('    out("%s ${%s}\\n")' % (v, v)
                              for v in self.vars)
        prints_c = "\n".join('  printf("%s %%d\\n", %s);' % (v, v)
                             for v in self.vars)

        self.cm = CM_TEMPLATE % (self.seed, "\n\n".join(helper_bodies_cm),
                                 decls_cm, "\n".join(body_cm), prints_cm)
        self.c = C_TEMPLATE % (self.seed, "\n\n".join(helper_bodies_c),
                               decls_c, "\n".join(body_c), prints_c)


CM_TEMPLATE = '''# generated by difftest/generate.py, seed %d

class Safe from Object
  static def Int sadd(Int a, Int b):
    return a + b
  end
  static def Int ssub(Int a, Int b):
    return a - b
  end
  static def Int smul(Int a, Int b):
    return a * b
  end
  static def Int sdiv(Int a, Int b):
    if b == 0:
      return a
    end
    if b == (0 - 1):
      return 0 - a
    end
    return a / b
  end
  static def Int smod(Int a, Int b):
    if b == 0:
      return a
    end
    if b == (0 - 1):
      return 0
    end
    return a %% b
  end
  static def Int sand(Int a, Int b):
    return a & b
  end
  static def Int sor(Int a, Int b):
    return a | b
  end
  static def Int sxor(Int a, Int b):
    return a ^ b
  end
  static def Int sshl(Int a, Int b):
    return a << (b & 31)
  end
  static def Int sshr(Int a, Int b):
    return a >> (b & 31)
  end
end

class Helpers from Object
%s
end

class Main from IO
  def main:
%s
%s
%s
  end
end
'''

C_TEMPLATE = '''/* generated by difftest/generate.py, seed %d */
#include <stdint.h>
#include <stdio.h>

static int32_t sadd(int32_t a, int32_t b) {
  return (int32_t)((uint32_t)a + (uint32_t)b);
}
static int32_t ssub(int32_t a, int32_t b) {
  return (int32_t)((uint32_t)a - (uint32_t)b);
}
static int32_t smul(int32_t a, int32_t b) {
  return (int32_t)((uint32_t)a * (uint32_t)b);
}
static int32_t sdiv(int32_t a, int32_t b) {
  if (b == 0) return a;
  if (b == -1) return (int32_t)(0u - (uint32_t)a);
  return a / b;
}
static int32_t smod(int32_t a, int32_t b) {
  if (b == 0) return a;
  if (b == -1) return 0;
  return a %% b;
}
static int32_t sand(int32_t a, int32_t b) { return a & b; }
static int32_t sor(int32_t a, int32_t b) { return a | b; }
static int32_t sxor(int32_t a, int32_t b) { return a ^ b; }
static int32_t sshl(int32_t a, int32_t b) {
  return (int32_t)((uint32_t)a << (b & 31));
}
static int32_t sshr(int32_t a, int32_t b) { return a >> (b & 31); }

%s

int main(void) {
%s
%s
%s
  return 0;
}
'''


def main():
    if len(sys.argv) != 4:
        sys.stderr.write(__doc__)
        return 2
    p = Program(int(sys.argv[1]))
    p.generate()
    open(sys.argv[2], "w").write(p.cm)
    open(sys.argv[3], "w").write(p.c)
    return 0


if __name__ == "__main__":
    sys.exit(main())
