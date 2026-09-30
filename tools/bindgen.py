#!/usr/bin/env python3
"""bindgen.py -- catmint bindings generated from C headers.

A developer's tool, as Rust's bindgen is: it needs clang, what it writes is
committed, and nobody who uses the bindings ever runs it.

    tools/bindgen.py SDL2/SDL.h --match '^SDL_' --from '/SDL2/' \\
        --class SDL2 --constants SDL2C --link SDL2 \\
        -I /opt/homebrew/include > lib/sdl2.cmm

Everything it knows comes from clang itself, not from a reimplementation:

  - declarations, from the JSON AST (-Xclang -ast-dump=json);
  - layouts, from -fdump-record-layouts-complete: clang's own offsets and
    sizes, written out as `@` assertions that the catmint compiler checks
    against its own layout rule, so the two cannot disagree in silence;
  - the value of every integer macro and enumerator, which clang evaluates
    as an enumerator initialiser -- nothing is compiled and run.

It writes an `extern struct` or `extern union` for each record, an opaque one
for each record known only by pointer, one `extern class` of functions, and
a class of constants as static methods. What it cannot bind -- a variadic
function, a struct passed by value, a bitfield, `long double` -- it lists in
a comment with the reason, rather than leaving out in silence. A record it
can size but not describe field by field becomes an array of integers of the
record's alignment, so records holding it still lay out correctly.
"""

import argparse
import json
import os
import re
import shlex
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
LEXER = os.path.join(HERE, "..", "catmint-lex", "catmint.l")

# C types as clang spells them, fully desugared, to catmint's C-boundary types.
SCALARS = {
    "char": "Int8", "signed char": "Int8", "unsigned char": "UInt8",
    "_Bool": "UInt8", "bool": "UInt8",
    "short": "Int16", "short int": "Int16", "signed short": "Int16",
    "unsigned short": "UInt16", "unsigned short int": "UInt16",
    "int": "Int", "signed int": "Int", "signed": "Int",
    "unsigned int": "UInt32", "unsigned": "UInt32",
    "long": "Int64", "long int": "Int64", "long long": "Int64",
    "long long int": "Int64", "signed long": "Int64",
    "unsigned long": "UInt64", "unsigned long int": "UInt64",
    "unsigned long long": "UInt64", "unsigned long long int": "UInt64",
    "float": "Float32", "double": "Float",
}


class Unbindable(Exception):
    """Why a declaration cannot be bound, said in a way a person can act on."""


def catmint_keywords():
    with open(LEXER) as f:
        return set(re.findall(r'^"([A-Za-z_]+)"', f.read(), re.M))


def run(cmd, check=True):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if check and result.returncode != 0:
        sys.stderr.write(result.stderr)
        raise SystemExit("bindgen: failed: " + " ".join(cmd[:4]) + " ...")
    return result


def json_documents(text):
    """clang prints one JSON document per matching declaration under
    -ast-dump-filter, one after another."""
    decoder = json.JSONDecoder()
    at = 0
    while True:
        while at < len(text) and text[at] in " \t\r\n":
            at += 1
        if at >= len(text):
            return
        doc, at = decoder.raw_decode(text, at)
        yield doc


class Locations:
    """Clang's JSON writes a location's file and line only when they change
    from the last location it printed, in the order it printed them. Walking
    every node in that same order recovers each declaration's full position,
    which is what names an anonymous record: "(unnamed at file:line:col)"."""

    def __init__(self):
        self.file = None
        self.line = None

    def update(self, loc):
        if not isinstance(loc, dict):
            return None
        if "spellingLoc" in loc or "expansionLoc" in loc:
            self.update(loc.get("spellingLoc"))
            return self.update(loc.get("expansionLoc"))
        if "file" in loc:
            self.file = loc["file"]
        if "line" in loc:
            self.line = loc["line"]
        if "col" in loc:
            return (self.file, self.line, loc["col"])
        return None

    def walk(self, node, visit):
        if isinstance(node, dict):
            where = None
            for key, value in node.items():
                if key == "loc":
                    where = self.update(value)
                elif key == "range" and isinstance(value, dict):
                    self.update(value.get("begin"))
                    self.update(value.get("end"))
            if "kind" in node:
                visit(node, where)
            for child in node.get("inner", []):
                self.walk(child, visit)


class Header:
    def __init__(self, args):
        self.args = args
        self.clang = args.clang
        self.work = tempfile.mkdtemp(prefix="bindgen.")
        self.tu = os.path.join(self.work, "tu.c")
        # A file that exists is included by its path; anything else is looked
        # up on the include path, as <SDL2/SDL.h> is.
        if os.path.exists(args.header):
            self.include_line = '#include "%s"\n' % os.path.abspath(args.header)
        else:
            self.include_line = "#include <%s>\n" % args.header
        with open(self.tu, "w") as f:
            f.write(self.include_line)
        self.flags = ["-x", "c", "-w"] + ["-I" + d for d in args.include] + \
                     ["-D" + d for d in args.define]
        self.match = re.compile(args.match)
        self.constants_match = re.compile(args.constants_match or args.match)
        self.origin = re.compile(args.origin) if args.origin else None
        self.keywords = catmint_keywords()

        self.records = {}        # key -> record dict
        self.record_by_id = {}   # clang node id -> key
        self.typedefs = {}       # name -> {"type": desugared type, "record": key}
        self.enums = []          # (name, file) of enumerators
        self.functions = []      # FunctionDecl nodes, with their file
        self.skipped = []        # (name, reason)

    # ---- reading ---------------------------------------------------------
    def from_here(self, where):
        return where is not None and (self.origin is None or
                                      (where[0] and self.origin.search(where[0])))

    def read_ast(self):
        out = run([self.clang, "-fsyntax-only", "-Xclang", "-ast-dump=json"] +
                  self.flags + [self.tu]).stdout
        ast = json.loads(out)
        locations = Locations()
        locations.walk(ast, self.visit)

    def visit(self, node, where):
        kind = node["kind"]
        if kind == "RecordDecl":
            self.read_record(node, where)
        elif kind == "TypedefDecl":
            self.read_typedef(node)
        elif kind == "EnumConstantDecl":
            if self.from_here(where):
                self.enums.append(node["name"])
        elif kind == "FunctionDecl":
            node["_where"] = where
            self.functions.append(node)

    def read_record(self, node, where):
        name = node.get("name")
        key = ("struct", name) if name else ("unnamed",) + tuple(where or ())
        record = self.records.setdefault(key, {
            "key": key, "tag": name, "union": node.get("tagUsed") == "union",
            "complete": False, "fields": [], "where": where, "problems": []})
        self.record_by_id[node["id"]] = key
        if node.get("previousDecl"):
            self.record_by_id[node["previousDecl"]] = key
        if not node.get("completeDefinition"):
            return
        record["complete"] = True
        record["where"] = where
        record["fields"] = []
        for child in node.get("inner", []):
            if child.get("kind") == "FieldDecl":
                if child.get("isBitfield"):
                    record["problems"].append("has bitfields")
                if not child.get("name"):
                    record["problems"].append("has an anonymous member")
                record["fields"].append({"name": child.get("name"),
                                         "type": child.get("type", {})})
            elif child.get("kind") == "RecordDecl" and not child.get("name"):
                pass  # an anonymous member's own record; its field says so

    def read_typedef(self, node):
        # A typedef names a record only when the record is its type itself,
        # reached through sugar (ElaboratedType, a typedef of a typedef) --
        # not when a record appears somewhere inside it, as in a function
        # pointer taking `struct SDL_AudioCVT *`.
        record = None
        n = (node.get("inner") or [None])[0]
        while isinstance(n, dict):
            kind = n.get("kind")
            if kind == "RecordType" and "decl" in n:
                record = n["decl"].get("id")
                break
            if kind not in ("ElaboratedType", "TypedefType", "ParenType"):
                break
            n = (n.get("inner") or [None])[0]
        t = node.get("type", {})
        self.typedefs[node["name"]] = {
            "type": t.get("desugaredQualType", t.get("qualType", "")),
            "record_id": record}

    def read_layouts(self):
        out = run([self.clang, "-fsyntax-only", "-Xclang",
                   "-fdump-record-layouts-complete"] + self.flags + [self.tu]).stdout
        layouts = {}
        current = None
        for line in out.splitlines():
            if "|" not in line:
                continue
            left, _, right = line.partition("|")
            if right.startswith(" [sizeof="):
                if current is not None:
                    m = re.search(r"sizeof=(\d+), align=(\d+)", right)
                    current["size"], current["align"] = int(m.group(1)), int(m.group(2))
                    current = None
                continue
            indent = len(right) - len(right.lstrip(" "))
            text = right.strip()
            if indent == 1:
                # A header: "struct SDL_Rect", "union (unnamed at f:12:9)".
                m = re.match(r"(struct|union) (.*)$", text)
                if not m:
                    current = None
                    continue
                name = m.group(2)
                u = re.match(r"\(unnamed at (.*):(\d+):(\d+)\)$", name)
                if u:
                    key = ("unnamed", u.group(1), int(u.group(2)), int(u.group(3)))
                elif "(" in name or ":" in name:
                    current = None  # a record nested in another; not its own
                    continue
                else:
                    key = ("struct", name)
                current = {"fields": [], "size": None, "align": None}
                layouts[key] = current
            elif indent == 3 and current is not None:
                offset = left.strip()
                if ":" in offset:
                    current["bitfield"] = True
                    continue
                current["fields"].append((int(offset), text.split()[-1]))
        self.layouts = layouts

    def read_constant_names(self):
        out = run([self.clang, "-E", "-dM"] + self.flags + [self.tu]).stdout
        macros = []
        for line in out.splitlines():
            m = re.match(r"#define ([A-Za-z_][A-Za-z0-9_]*) (.+)$", line)
            if m and self.constants_match.search(m.group(1)):
                if '"' in m.group(2) or "'" in m.group(2):
                    continue
                macros.append(m.group(1))
        names = [n for n in self.enums if self.constants_match.search(n)]
        seen = set(names)
        return names + [m for m in macros if m not in seen]

    def evaluate(self, names):
        """Each name as an enumerator's initialiser: clang evaluates it and
        writes the result into the AST. Whatever is not an integer constant
        -- a string, a type, a function-like macro -- is an error on its own
        line, dropped, and tried again without it."""
        names = list(names)
        dropped = set()
        for _ in range(50):
            body = self.include_line + "".join(
                "enum { __bg_%d = (long long)(%s) };\n" % (i, n)
                for i, n in enumerate(names))
            path = os.path.join(self.work, "values.c")
            with open(path, "w") as f:
                f.write(body)
            result = run([self.clang, "-fsyntax-only", "-ferror-limit=0",
                          "-Xclang", "-ast-dump=json", "-Xclang",
                          "-ast-dump-filter=__bg_"] + self.flags + [path], check=False)
            bad_lines = {int(m.group(1)) for m in
                         re.finditer(r"values\.c:(\d+):\d+: error", result.stderr)}
            if not bad_lines:
                values = {}
                for doc in json_documents(result.stdout):
                    if doc.get("kind") != "EnumConstantDecl":
                        continue
                    index = int(doc["name"][len("__bg_"):])
                    found = []

                    def find(n):
                        if isinstance(n, dict):
                            if n.get("kind") == "ConstantExpr" and "value" in n:
                                found.append(int(n["value"]))
                            for child in n.get("inner", []):
                                find(child)
                    find(doc)
                    if found:
                        values[names[index]] = found[0]
                return values, dropped
            keep = []
            for i, n in enumerate(names):
                if i + 2 in bad_lines:   # the include is line 1
                    dropped.add(n)
                else:
                    keep.append(n)
            names = keep
        raise SystemExit("bindgen: could not evaluate the constants")

    # ---- mapping ---------------------------------------------------------
    @staticmethod
    def clean(t):
        t = re.sub(r"\b(const|volatile|restrict|__restrict)\b", "", t)
        return re.sub(r"\s+", " ", t).strip()

    def record_name(self, key):
        record = self.records.get(key)
        if not record:
            return None
        if record["tag"]:
            return record["tag"]
        for name, td in self.typedefs.items():
            if td["record_id"] is not None and self.record_by_id.get(td["record_id"]) == key:
                return name
        return None

    def resolve(self, t, depth=0):
        """A type string to ('scalar', C type) | ('record', key) | ('enum',)
        | ('pointer', pointee string) | ('array', element, n) | ('void',)."""
        t = self.clean(t)
        if depth > 20:
            raise Unbindable("a type that does not resolve: " + t)
        if t == "void":
            return ("void",)
        if "(*)" in t or "(^)" in t or re.search(r"\)\s*\(", t):
            return ("pointer", "function")
        m = re.match(r"^(.*)\[(\d+)\]$", t)
        if m:
            if re.search(r"\[\d+\]$", m.group(1)):
                raise Unbindable("has a multi-dimensional array")
            return ("array", m.group(1), int(m.group(2)))
        if t.endswith("*"):
            return ("pointer", t[:-1].strip())
        if t in SCALARS:
            return ("scalar", SCALARS[t])
        if t == "long double":
            raise Unbindable("uses long double")
        m = re.match(r"^(struct|union) (.+)$", t)
        if m:
            inner = m.group(2)
            u = re.match(r"^\(unnamed (?:struct|union) at (.*):(\d+):(\d+)\)$", inner)
            if u:
                return ("record", ("unnamed", u.group(1), int(u.group(2)), int(u.group(3))))
            if inner in self.typedefs and ("struct", inner) not in self.records:
                return self.resolve(inner, depth + 1)
            return ("record", ("struct", inner))
        if t.startswith("enum "):
            return ("enum",)
        if t in self.typedefs:
            td = self.typedefs[t]
            if td["record_id"] is not None and td["record_id"] in self.record_by_id:
                return ("record", self.record_by_id[td["record_id"]])
            if td["type"] and td["type"] != t:
                return self.resolve(td["type"], depth + 1)
            return ("enum",)  # a typedef of an anonymous enum
        raise Unbindable("uses a type it cannot name: " + t)

    def field_type(self, t, needed):
        kind = self.resolve(t.get("desugaredQualType", t.get("qualType", "")))
        if kind[0] == "scalar":
            return kind[1], 0
        if kind[0] == "enum":
            return "Int", 0
        if kind[0] == "pointer":
            return "Ptr", 0
        if kind[0] == "record":
            name = self.record_name(kind[1])
            if not name:
                raise Unbindable("holds an anonymous struct or union")
            needed.add(kind[1])
            return name, 0
        if kind[0] == "array":
            element = self.field_type({"qualType": kind[1]}, needed)
            return element[0], kind[2]
        raise Unbindable("holds a field it cannot describe")

    def param_type(self, t, returning=False):
        kind = self.resolve(t)
        if kind[0] == "void":
            if returning:
                return "Void"
            raise Unbindable("takes void")
        if kind[0] == "scalar":
            return kind[1]
        if kind[0] == "enum":
            return "Int"
        if kind[0] == "record":
            raise Unbindable("passes a struct by value")
        if kind[0] == "array":
            return "Ptr"
        pointee = kind[1]
        if pointee == "function":
            return "Ptr"
        pointee = self.clean(pointee)
        if pointee == "char" and not returning and "const" in t:
            return "String"
        try:
            target = self.resolve(pointee)
        except Unbindable:
            return "Ptr"
        if target[0] == "record":
            name = self.record_name(target[1])
            if name and self.bindable_record(target[1]):
                return name
        return "Ptr"

    def bindable_record(self, key):
        record = self.records.get(key)
        return record is not None and key in self.bound

    # ---- choosing and writing --------------------------------------------
    def choose(self):
        self.bound = {}   # key -> "full" | "blob" | "opaque"
        wanted = []
        for key, record in self.records.items():
            name = self.record_name(key)
            if not name or not self.match.search(name):
                continue
            if record["complete"] and not self.from_here(record["where"]):
                continue
            wanted.append(key)
        queue = list(wanted)
        self.field_types = {}
        while queue:
            key = queue.pop()
            if key in self.bound:
                continue
            record = self.records[key]
            if not record["complete"]:
                self.bound[key] = "opaque"
                continue
            layout = self.layouts.get(key)
            if not layout or layout.get("size") is None:
                self.bound[key] = "opaque"
                continue
            needed = set()
            try:
                if record["problems"]:
                    raise Unbindable(record["problems"][0])
                if layout.get("bitfield"):
                    raise Unbindable("has bitfields")
                fields = []
                for field in record["fields"]:
                    ctype, count = self.field_type(field["type"], needed)
                    fields.append((field["name"], ctype, count))
                self.field_types[key] = fields
                self.bound[key] = "full"
            except Unbindable as why:
                self.bound[key] = "blob"
                self.skipped.append((self.record_name(key) + " (fields)", str(why)))
                needed = set()
            queue.extend(k for k in needed if k not in self.bound)

    def ident(self, name):
        return name + "_" if name in self.keywords else name

    def emit_record(self, key, out):
        name = self.record_name(key)
        record = self.records[key]
        word = "union" if record["union"] else "struct"
        kind = self.bound[key]
        if kind == "opaque":
            out.append("extern %s %s\nend\n" % (word, name))
            return
        layout = self.layouts[key]
        out.append("extern %s %s @ %d" % (word, name, layout["size"]))
        if kind == "blob":
            align = layout["align"]
            element = {1: "UInt8", 2: "UInt16", 4: "UInt32", 8: "UInt64"}.get(align, "UInt8")
            unit = {"UInt8": 1, "UInt16": 2, "UInt32": 4, "UInt64": 8}[element]
            out.append("  %s bytes_[%d] @ 0" % (element, layout["size"] // unit))
        else:
            offsets = dict((n, o) for o, n in layout["fields"])
            for field_name, ctype, count in self.field_types[key]:
                dim = "[%d]" % count if count else ""
                out.append("  %s %s%s @ %d" % (ctype, self.ident(field_name), dim,
                                               offsets[field_name]))
        out.append("end\n")

    def functions_text(self):
        lines = []
        seen = set()
        for fn in self.functions:
            name = fn["name"]
            if name in seen or not self.match.search(name):
                continue
            if not self.from_here(fn.get("_where")):
                continue
            seen.add(name)
            try:
                if fn.get("variadic"):
                    raise Unbindable("is variadic")
                if fn.get("storageClass") == "static" or fn.get("inline"):
                    raise Unbindable("is inline, so there is no symbol to call")
                qual = fn["type"].get("desugaredQualType", fn["type"]["qualType"])
                ret = self.param_type(qual[:qual.index("(")].strip(), returning=True)
                params = []
                for i, p in enumerate(c for c in fn.get("inner", [])
                                      if c.get("kind") == "ParmVarDecl"):
                    t = p["type"]
                    ptype = self.param_type(t.get("desugaredQualType", t.get("qualType")))
                    params.append("%s %s" % (ptype, self.ident(p.get("name") or "arg%d" % i)))
                lines.append("  def %s %s(%s)" % (ret, name, ", ".join(params)))
            except Unbindable as why:
                self.skipped.append((name, str(why)))
        return lines

    def write(self):
        self.read_ast()
        self.read_layouts()
        self.choose()
        functions = self.functions_text()
        values, dropped = self.evaluate(self.read_constant_names())
        version = run([self.clang, "--version"]).stdout.splitlines()[0]

        out = []
        out.append("# Generated by tools/bindgen.py from %s -- do not edit;" % self.args.header)
        out.append("# regenerate it instead:")
        out.append("#   tools/bindgen.py " + " ".join(shlex.quote(a) for a in sys.argv[1:]))
        out.append("# Layouts and constants as %s reported them." % version)
        out.append("#")
        out.append("# %d records, %d functions, %d constants." %
                   (len(self.bound), len(functions), len(values)))
        if self.skipped:
            out.append("# Not bound, with the reason:")
            for name, why in sorted(self.skipped):
                out.append("#   %s -- %s" % (name, why))
        out.append("")
        for lib in self.args.link:
            out.append('link "%s"' % lib)
        out.append("")
        for key in sorted(self.bound, key=lambda k: self.record_name(k)):
            self.emit_record(key, out)
        out.append("extern class %s" % self.args.cls)
        out.extend(functions)
        out.append("end\n")
        if values and self.args.constants:
            out.append("class %s" % self.args.constants)
            for name in sorted(values):
                v = values[name]
                if v >= 2 ** 63:
                    v -= 2 ** 64
                ctype = "Int" if -2 ** 31 <= v < 2 ** 31 else "Int64"
                literal = str(v) if v >= 0 else "0 - %d" % -v
                out.append("  static def %s %s:\n    return %s\n  end\n" %
                           (ctype, self.ident(name), literal))
            out.append("end")
        return "\n".join(out) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("header", help="a header, <on the include path> or a file")
    parser.add_argument("--match", required=True,
                        help="regex a record's or function's name must match")
    parser.add_argument("--constants-match", default=None,
                        help="regex for macro and enumerator names (default: --match)")
    parser.add_argument("--from", dest="origin", default=None,
                        help="regex the declaring file's path must match")
    parser.add_argument("--class", dest="cls", required=True,
                        help="the extern class the functions go in")
    parser.add_argument("--constants", default=None,
                        help="the class the constants go in (none: no constants)")
    parser.add_argument("--link", action="append", default=[],
                        help="a library for `link \"...\"` (repeatable)")
    parser.add_argument("-I", dest="include", action="append", default=[])
    parser.add_argument("-D", dest="define", action="append", default=[])
    parser.add_argument("--clang", default=os.path.join(
        os.environ.get("LLVM_BIN", "/opt/homebrew/opt/llvm@22/bin"), "clang"))
    args = parser.parse_args()
    sys.stdout.write(Header(args).write())


if __name__ == "__main__":
    main()
