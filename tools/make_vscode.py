#!/usr/bin/env python3
"""make_vscode.py [--check]

Writes editors/vscode/syntaxes/catmint.tmLanguage.json: the TextMate grammar VS Code
colours catmint with. The keywords are read from the lexer (catmint-lex/catmint.l)
by tools/make_keywords.py, so the grammar cannot drift from the language; the table
below says which kind of keyword each one is, and a keyword the lexer gains that is
not in the table stops this script, since what colour it should be is a decision.

With --check it writes nothing and exits 1 if the committed file is not what the lexer
now says -- test.sh runs that.

The rest of the extension (package.json, language-configuration.json) is written by
hand and lives beside the grammar; see editors/vscode/README.md.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import make_keywords  # noqa: E402

ROOT = os.path.dirname(HERE)
OUTPUT = os.path.join(ROOT, "editors", "vscode", "syntaxes", "catmint.tmLanguage.json")

# keyword -> TextMate scope
KINDS = {
    "keyword.control.catmint":
        "if elif else end while for in do break continue return try catch throw defer then",
    "storage.type.catmint":
        "class interface def constructor static abstract extern struct union var constexpr unsafe",
    "keyword.other.catmint": "using does from new spawn is",
    "keyword.operator.word.catmint": "and or",
    "constant.language.catmint": "null self",
}

# The classes the language has built in; any other capitalised name is a class of the
# program's own, and is coloured as a type as well.
BUILTIN_TYPES = ("Int Int8 Int16 Int32 Int64 UInt8 UInt16 UInt32 UInt64 Float Float32 "
                 "Float64 String Object List Bytes Ints Floats Integer File Math Process "
                 "Worker IO Ptr Void")


def alternation(words):
    return r"\b(" + "|".join(words) + r")\b"


def grammar():
    classified = {}
    for scope, words in KINDS.items():
        for w in words.split():
            classified[w] = scope
    lexer = make_keywords.keywords()
    missing = [w for w in lexer if w not in classified]
    if missing:
        raise SystemExit("make_vscode: the lexer has keywords this table does not "
                         "classify: %s" % ", ".join(missing))
    stale = [w for w in classified if w not in lexer]
    if stale:
        raise SystemExit("make_vscode: the table classifies words the lexer no longer "
                         "has: %s" % ", ".join(stale))

    patterns = [
        {"include": "#comment"},
        {"include": "#string"},
        {"include": "#number"},
        {"include": "#definition"},
    ]
    for scope in KINDS:
        words = [w for w in lexer if classified[w] == scope]
        patterns.append({"name": scope, "match": alternation(words)})
    patterns += [
        {"name": "support.type.catmint", "match": alternation(BUILTIN_TYPES.split())},
        {"name": "entity.name.type.catmint", "match": r"\b[A-Z][A-Za-z0-9_]*\b"},
        {"name": "entity.name.function.call.catmint", "match": r"\b[a-z_][A-Za-z0-9_]*(?=\()"},
        {"name": "keyword.operator.catmint", "match": r"==|!=|<=|>=|<<|>>|[-+*/%<>=&|^~!]"},
    ]
    interpolation = {
        "name": "meta.interpolation.catmint",
        "begin": r"\$\{",
        "end": r"\}",
        "beginCaptures": {"0": {"name": "punctuation.section.interpolation.begin.catmint"}},
        "endCaptures": {"0": {"name": "punctuation.section.interpolation.end.catmint"}},
        "patterns": [{"include": "$self"}],
    }
    escape = {"name": "constant.character.escape.catmint", "match": r"\\(.|\n)"}
    return {
        "$schema": "https://raw.githubusercontent.com/martinring/tmlanguage/master/tmlanguage.json",
        "name": "Catmint",
        "scopeName": "source.catmint",
        "patterns": patterns,
        "repository": {
            "comment": {"name": "comment.line.number-sign.catmint", "match": r"#.*$"},
            "string": {"patterns": [
                {"name": "string.quoted.double.catmint", "begin": '"', "end": '"',
                 "patterns": [escape, interpolation]},
                {"name": "string.quoted.single.catmint", "begin": "'", "end": "'",
                 "patterns": [escape]},
            ]},
            "number": {"name": "constant.numeric.catmint", "match": r"\b[0-9]+(\.[0-9]+)?\b"},
            "definition": {
                "match": r"\b(def)\s+(?:(static|abstract)\s+)?(?:([A-Z][A-Za-z0-9_]*)\s+)?([a-z_][A-Za-z0-9_]*)",
                "captures": {
                    "1": {"name": "storage.type.catmint"},
                    "2": {"name": "storage.modifier.catmint"},
                    "3": {"name": "entity.name.type.catmint"},
                    "4": {"name": "entity.name.function.catmint"},
                },
            },
        },
    }


def render():
    return json.dumps(grammar(), indent=2) + "\n"


def main():
    text = render()
    if "--check" in sys.argv[1:]:
        try:
            current = open(OUTPUT).read()
        except FileNotFoundError:
            current = None
        if current != text:
            raise SystemExit("make_vscode: editors/vscode/syntaxes/catmint.tmLanguage.json "
                             "is out of date with the lexer; run tools/make_vscode.py")
        print("vscode grammar matches the lexer")
    else:
        with open(OUTPUT, "w") as f:
            f.write(text)


if __name__ == "__main__":
    main()
