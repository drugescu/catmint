#!/usr/bin/env python3
"""Mutation-fuzz the parser and the semantic analyser.

    python3 fuzz/fuzz.py [--runs N] [--seed S] [--timeout SEC]

Takes the test suite as a corpus, mutates it, and feeds the result to
`catmint-parser`. When a mutant still parses, the resulting AST goes on to
`catmint-gen`, so the semantic analyser and the code generator are fuzzed
too -- that half is the more interesting one, being full of `dynamic_cast`
and assertions.

A syntax error is the expected outcome and is not a finding. What counts is
the compiler dying by a signal, or hanging.

This runs a process per input rather than linking libFuzzer in. libFuzzer
would be perhaps a hundred times faster, but the grammar file defines
`main`, so an in-process harness means renaming it out of the way and
building a second copy of the parser -- surgery on the most fragile part of
the build, for throughput this does not need. The input space here is small
and structured, and a few thousand mutants take a couple of minutes.

Findings are written to fuzz/failures/.
"""

import argparse
import os
import pathlib
import random
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
PARSER = ROOT / "catmint-lex" / "bin" / "catmint-parser"
GEN = ROOT / "catmint-gen" / "bin" / "catmint-gen"
FAILURES = ROOT / "fuzz" / "failures"

# Fragments worth splicing in: the tokens a mutant is unlikely to invent by
# flipping bytes, and exactly the ones that reach the interesting code.
TOKENS = [
    "class", "def", "end", "if", "else", "while", "for", "in", "return",
    "new", "self", "null", "try", "catch", "throw", "defer", "static",
    "interface", "does", "constructor", "using", "namespace", "spawn", "is",
    "Int", "Int64", "String", "List", "Object", "Float", "Bytes",
    ":", "(", ")", "[", "]", ",", ".", "::", "${", "}", '"', "'", "\\",
    "+", "-", "*", "/", "%", "**", "<<", ">>", "==", "!=", "and", "or",
]


def corpus():
    files = []
    for directory in ("catmint-gen/test_suite", "catmint-lex/test_suite",
                      "examples", "lib"):
        d = ROOT / directory
        if not d.is_dir():
            continue
        for path in sorted(d.iterdir()):
            if path.suffix in (".cm", ".cmm"):
                try:
                    files.append(path.read_text(errors="replace"))
                except OSError:
                    pass
    return files


def mutate(rng, text, pool):
    """One of a handful of edits, applied once or a few times."""
    for _ in range(rng.randint(1, 4)):
        if not text:
            text = rng.choice(pool)
        n = len(text)
        choice = rng.random()
        at = rng.randrange(n)

        if choice < 0.2:                                   # flip a byte
            text = text[:at] + chr(rng.randrange(32, 127)) + text[at + 1:]
        elif choice < 0.4:                                 # delete a span
            end = min(n, at + rng.randint(1, 40))
            text = text[:at] + text[end:]
        elif choice < 0.55:                                # duplicate a span
            end = min(n, at + rng.randint(1, 60))
            text = text[:at] + text[at:end] + text[at:]
        elif choice < 0.8:                                 # splice a token
            text = text[:at] + rng.choice(TOKENS) + text[at:]
        elif choice < 0.9:                                 # truncate
            text = text[:at]
        else:                                              # splice two files
            other = rng.choice(pool)
            cut = rng.randrange(len(other)) if other else 0
            text = text[:at] + other[cut:]
    return text


def died(result):
    """True when the process was killed by a signal rather than exiting."""
    return result.returncode < 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=2000)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--timeout", type=float, default=10.0)
    args = ap.parse_args()

    for tool in (PARSER, GEN):
        if not tool.exists():
            sys.stderr.write("fuzz: %s is missing; run make first\n" % tool)
            return 2

    pool = corpus()
    if not pool:
        sys.stderr.write("fuzz: no corpus found\n")
        return 2

    rng = random.Random(args.seed)
    findings = 0
    parsed = 0
    work = tempfile.mkdtemp()

    for run in range(args.runs):
        if run % 100 == 0:
            sys.stdout.write(".")
            sys.stdout.flush()
        text = mutate(rng, rng.choice(pool), pool)
        source = os.path.join(work, "case.cm")
        ast = os.path.join(work, "case.ast")
        with open(source, "w") as handle:
            handle.write(text)
        if os.path.exists(ast):
            os.unlink(ast)

        def record(stage, result):
            global_findings = FAILURES
            global_findings.mkdir(parents=True, exist_ok=True)
            name = global_findings / ("%s-seed%d-run%d.cm"
                                      % (stage, args.seed, run))
            name.write_text(text)
            sys.stdout.write("\n%s: %s on run %d -> %s\n"
                             % (stage, describe(result), run, name))

        def describe(result):
            if result is None:
                return "hang"
            return "killed by signal %d" % -result.returncode

        try:
            r = subprocess.run([str(PARSER), source, ast],
                               capture_output=True, timeout=args.timeout)
        except subprocess.TimeoutExpired:
            record("parser", None); findings += 1; continue
        if died(r):
            record("parser", r); findings += 1; continue

        # Only a mutant that parsed can reach the rest of the compiler.
        if r.returncode != 0 or not os.path.exists(ast) \
                or os.path.getsize(ast) == 0:
            continue
        parsed += 1

        try:
            g = subprocess.run([str(GEN), "case.ast", "case.sem"],
                               capture_output=True, timeout=args.timeout,
                               cwd=work)
        except subprocess.TimeoutExpired:
            record("codegen", None); findings += 1; continue
        if died(g):
            record("codegen", g); findings += 1; continue


    print("\n" + "-" * 60)
    print("%d mutants, %d of them parsed, %d findings"
          % (args.runs, parsed, findings))
    if findings:
        print("sources in %s" % FAILURES)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
