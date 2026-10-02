#!/usr/bin/env python3
"""vscode_test.py -- check the VS Code grammar against editors/vscode/tests/sample.cm.

A small TextMate tokenizer (the rules VS Code applies: at each position the pattern that
matches earliest wins, the first listed on a tie; begin/end rules nest their own patterns;
captures colour parts of a match) applies the grammar to the sample, and the scopes it
finds are compared with sample.scopes, written by hand: one line for each coloured token,
"line text scope". It is not VS Code, whose regular-expression engine is Oniguruma, but
nothing here uses a feature the two read differently.

    tools/vscode_test.py        exit 1, with a diff, if they differ
"""
import difflib
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.join(ROOT, "editors", "vscode")


class Tokenizer:
    def __init__(self, grammar):
        self.g = grammar

    def flatten(self, pats):
        for p in pats:
            if "include" in p:
                ref = p["include"]
                if ref == "$self":
                    yield from self.flatten(self.g["patterns"])
                else:
                    target = self.g["repository"][ref.lstrip("#")]
                    if "patterns" in target and "match" not in target and "begin" not in target:
                        yield from self.flatten(target["patterns"])
                    else:
                        yield target
            else:
                yield p

    def run(self, text, pats, start, stop=None):
        """Tokens (start, text, scope) from `start`, up to the match of `stop` if given.
        Returns (tokens, end match or None, position after)."""
        toks = []
        pos = start
        pats = list(self.flatten(pats))
        while pos <= len(text):
            best = None
            for p in pats:
                m = re.compile(p["match"] if "match" in p else p["begin"]).search(text, pos)
                if m and (best is None or m.start() < best[0].start()):
                    best = (m, p)
            end = stop.search(text, pos) if stop else None
            if end and (best is None or end.start() <= best[0].start()):
                return toks, end, end.end()
            if best is None:
                break
            m, p = best
            if m.end() == m.start():
                pos = m.end() + 1
                continue
            if "match" in p:
                if "captures" in p:
                    for i, cap in sorted(p["captures"].items(), key=lambda kv: int(kv[0])):
                        if m.group(int(i)) and cap.get("name"):
                            toks.append((m.start(int(i)), m.group(int(i)), cap["name"]))
                elif p.get("name"):
                    toks.append((m.start(), m.group(0), p["name"]))
                pos = m.end()
            else:
                name = p.get("name")
                begin_name = (p.get("beginCaptures") or {}).get("0", {}).get("name") or name
                toks.append((m.start(), m.group(0), begin_name))
                inner, end_m, pos = self.run(text, p.get("patterns", []), m.end(), re.compile(p["end"]))
                # What the inner patterns colour is theirs; the text between is the rule's.
                at = m.end()
                for (st, tok, scope) in inner:
                    if st > at:
                        toks.append((at, text[at:st], name))
                    toks.append((st, tok, scope))
                    at = st + len(tok)
                stop_at = end_m.start() if end_m else len(text)
                if stop_at > at:
                    toks.append((at, text[at:stop_at], name))
                if end_m:
                    end_name = (p.get("endCaptures") or {}).get("0", {}).get("name") or name
                    toks.append((end_m.start(), end_m.group(0), end_name))
        return toks, None, len(text)


def tokens(grammar, source):
    out = []
    for n, line in enumerate(source.split("\n"), 1):
        toks, _, _ = Tokenizer(grammar).run(line, grammar["patterns"], 0)
        for (st, tok, scope) in toks:
            out.append((n, tok, scope))
    return out


def main():
    grammar = json.load(open(os.path.join(BASE, "syntaxes", "catmint.tmLanguage.json")))
    source = open(os.path.join(BASE, "tests", "sample.cm")).read().rstrip("\n")
    got = ["%d %s %s" % tok for tok in tokens(grammar, source)]
    want = open(os.path.join(BASE, "tests", "sample.scopes")).read().rstrip("\n").split("\n")
    if got != want:
        sys.stdout.write("\n".join(difflib.unified_diff(want, got, "sample.scopes", "found", lineterm="")) + "\n")
        raise SystemExit("vscode_test: the grammar does not colour the sample as sample.scopes says")
    print("vscode grammar colours the sample as expected (%d tokens)" % len(got))


if __name__ == "__main__":
    main()
