# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Catmint is a compiler front-end targeting LLVM, for a hybrid low/high-level language
(Python-like brevity, C-level memory control, no GC). It is a work in progress derived
from LCPL, a didactic language from a UPB Bucharest LLVM course; the intent is to replace
the inherited LCPL code incrementally. Many identifiers still carry `lcpl` names.

## Pipeline

Three components, built in order, each depending on the previous:

```
.cm source ─► catmint-lex ─► .ast (JSON) ─► catmint-gen ─► .ll ─► llvm-link ─► lli / clang
              flex+bison                    semantic analysis      + runtime.ll
              → AST objects                 + IR generation
```

1. **catmint-ast** — static library `libcatmint-ast.a`. The AST node classes
   (one header per node in `include/`), an `ASTVisitor` base, and JSON
   serialization via a vendored rapidjson. This is the contract between the
   other two stages: the parser writes a `.ast` JSON file, the generator reads
   it back. Both stages link this library.
2. **catmint-lex** — `bin/catmint-parser`. `catmint.l` (flex) and `catmint.y`
   (bison) build AST objects directly in the grammar actions, then serialize.
   The grammar also does two source-level transforms: it expands `using <module>`
   directives, and it synthesizes a `Main` class and `main` method around any
   top-level statements.

   Module expansion lives in `main()` in `catmint.y`. It is recursive, includes
   each module at most once (so diamonds do not duplicate classes and cycles
   terminate), searches the importing file's directory then any `-I` directory
   then the working directory, and emits `#line` directives so diagnostics name
   the file the programmer wrote. The expanded text is fed to flex with
   `yy_scan_string`, so there is no temporary file. `using` is a real keyword:
   a malformed directive is a syntax error rather than being silently parsed as
   a variable declaration.
3. **catmint-gen** — `bin/catmint-gen`. Deserializes the `.ast`, runs
   `PrintAnalysis` (debug dump), then `SemanticAnalysis` (builds `TypeTable`
   and `SymbolTable`, checks the inheritance graph and features, annotates node
   types via `TypeVisitor`), then `IRGenerator` emits a `.ll` file.

The emitted IR is not self-contained: it declares `M2_IO_out`, `M2_IO_in` and
`__catmint_new` and must be linked against `runtime.ll` before running.

## Build

Requires flex, bison 3.x, cmake, and LLVM 16+ (LLVM 22 is what this is verified
against). On macOS the Homebrew LLVM and bison are keg-only, so put them on PATH:

```sh
export PATH=/opt/homebrew/opt/llvm@22/bin:/opt/homebrew/opt/bison/bin:$PATH
```

Build in dependency order; `catmint-lex` and `catmint-gen` both invoke the
`catmint-ast` build first via their `ast` target:

```sh
cd catmint-ast && make -f GNUmakefile build   # -> build/libcatmint-ast.a
cd catmint-lex && make                        # -> bin/catmint-parser
cd catmint-gen && make                        # -> bin/catmint-gen
```

Both Makefiles locate LLVM through `llvm-config` and accept an override:
`make LLVM_CONFIG=/path/to/llvm-config`. They deliberately strip `-std=`,
`-fno-exceptions` and `-fno-rtti` out of `llvm-config --cxxflags`, because the
parser uses try/catch and the AST relies on `dynamic_cast`. The whole project
is C++17; do not lower it, LLVM 16+ headers need it.

### Two build modes

By default `using` is expanded textually and the program is one translation
unit. `catmintc --separate` instead compiles each module on its own:
`catmint-parser --no-expand [--module]` then `catmint-gen [--module]
[--import <module.ast>]...`, with `llvm-link` merging the objects.

An imported class is treated exactly like a built-in: its layout and vtable
are still computed (a subclass or call site needs them) but nothing is
defined, so `@R<Class>` and `@N<Class>` are declared external and the methods
are `declare`d. The interface format is just the module's `.ast`; both sides
run the same vtable algorithm over the same declarations, so slot numbers
agree by construction. A disagreement there would be a silent miscompile, not
a link error, so that property is what the `13_separate` test guards.

`catmint-ast/Makefile` is CMake-generated output that is committed to the repo.
Do not edit it or invoke it directly; use `GNUmakefile`, which wraps the CMake
build into `catmint-ast/build/`.

## Test

```sh
cd catmint-lex && ./wtest.sh   # parser: AST output vs committed .ref files
cd catmint-gen && ./ctest.sh   # codegen: program stdout vs .expected files
```

`wtest.sh` runs every `test_suite/*.cm`, diffs the produced `.ast` against the
committed `.ref`, and writes `<test>.errlog.txt` on mismatch. All 11 pass. `declarations.cm` and `dispatch_complex.cm` had failed since
2020; both now parse. `declarations.cm.ref` was regenerated because the
committed one predated the `new_list` rule, so it still described an empty list
literal as a single node. Everything else in it, including the `a[i]` and
`a[i] = v` desugaring the test exists to check, matches the old reference
exactly.

`ctest.sh` is the end-to-end suite: it compiles and runs each
`catmint-gen/test_suite/*.cm` and diffs stdout against the matching
`.expected`, optionally feeding `<name>.stdin`. All of these pass; any failure
is a real regression. Run one with `./ctest.sh test_suite/05_while.cm`, and add
a case by dropping in the two files.

`catmint-gen/dbg.sh <file.cm>` parses and generates one program and prints just
the error, which is otherwise lost in the debug trace.

To compile and run a program end to end, `./catmintc --run examples/tour.cm`
from the repository root; `COMPILING.md` documents the four underlying stages.

## The runtime, and why it needs a build step

`catmint-gen/runtime.c` is the object model and I/O library: `TObject`,
`TString`, `TIO`, the `__catmint_rtti` type-info struct, `__catmint_new`, and
the built-in methods. `build-runtime.sh` compiles it for the host into
`runtime.host.ll`, which is what programs link against.

The original `runtime.ll` was committed without its source and built for
x86_64 Linux. `runtime.c` was reconstructed from it and verified to be a
drop-in replacement: identical function and global sets, and the whole
codegen suite passes against either. The old `.ll` and the
`make-host-runtime.sh` that patched its target triple and glibc-only
`__isoc99_scanf` are kept as a fallback for a machine without a C compiler,
and `build-runtime.sh` picks whichever is available.

The layouts and the virtual table slot order in `runtime.c` are fixed by
agreement with `IRGenerator.cpp`; changing one without the other silently
miscompiles.

## State of code generation

Code generation is real: every class and method is emitted, objects have a
virtual table, and methods take `self`. `IRGenerator.cpp` is the whole of it.

For each class the generator emits an LLVM struct laid out as
`{ rtti, inherited fields..., own fields... }`, a `@N<Class>` name string, an
`@R<Class>` RTTI record containing the virtual table, and a `<Class>_init`
that chains to the parent initialiser and then runs the attribute initialisers.
Virtual table slots are the parent's followed by the class's new methods in
declaration order, with an override reusing the parent's slot. Built-in classes
are seeded to match the order already fixed in `runtime.ll`, so `Object` holds
slots 0-2 and `IO` adds `input` and `out` at 3 and 4.

Dispatch loads the function pointer from the receiver's vtable, after a
`__cm_checkNull`. Static dispatch calls the implementation directly.

Two details that are easy to trip over, both forced by the grammar:

- **There is no `new`.** Declaring a variable of class type constructs it, so
  `Counter c` allocates and initialises. `NewObject` exists in the AST and the
  generator handles it, but no grammar rule produces one.
- **`x = expr` is a `LocalDefinition` with the type `auto`, never an
  `Assignment`.** The generator treats it as assignment when the name already
  resolves, and as a declaration otherwise. Without that, `sum = sum + i`
  inside a loop body would bind a fresh `sum` that dies with the body's scope.

`for v in n:` counts from `0` to `n - 1`; `for c in str:` walks a string's
characters as one-character strings. Both lower to the same counted loop.
There is no list type in the runtime, so nothing else can be iterated.

Namespaces: `using math as m` declares that module's classes as `m::Name`.
A qualified name is joined into a single `IDENTIFIER` by the lexer, because
letting the grammar see `IDENTIFIER :: IDENTIFIER` where a type is named is
ambiguous with static dispatch (`Program::run.execute(...)`), which begins
identically; the dispatch rule splits it apart again. In symbols `::` becomes
`$`, which cannot appear in a catmint identifier, so nothing can collide.

`expr is Type` reuses `StaticDispatch` with the method name `is`, since that
node already carries both an object and a type name. No new AST node, so no
serializer work.

A built-in method's virtual table slot is fixed by `runtime.c`; its
declaration order in `TypeTable::addBuiltinClasses` is that slot order. A new
built-in method must be appended, never inserted, or every already-compiled
caller silently calls the wrong slot.

Not yet supported: slice vectors (they parse but have no deserializer, so they
abort in `ASTSerialization.cpp`), return-type inference (`auto` on a method
means `Void`), and lists and dictionaries.

`catmint-gen/ASTCodeGen.cpp.old` and `include/ASTCodeGen.h` are a superseded
earlier attempt, not built and not included by anything.

## Traps that have already cost time

Each of these produced a crash or a silent miscompile during development.

- **A built-in method's virtual table slot is fixed by `runtime.c`.** Its
  declaration order in `TypeTable::addBuiltinClasses` *is* that slot order.
  Append a new built-in method, never insert one: inserting renumbers the
  slots after it and every already-compiled caller then calls the wrong
  function, with no error anywhere.
- **`Method` takes ownership of the `Attribute`s passed as its parameters.**
  Reusing one `builtinMethodsParams` vector across two methods hands the same
  object to two owners and double-frees it. Clear the vector and allocate
  fresh parameters for every method.
- **`TypeTable::isBuiltinClass` decides whether a class is checked as user
  code.** A new built-in that is missing from it goes down the user path,
  where its body-less methods are rejected with a confusing type error.
- **`TypeTable::getType(TreeNode *)` returns a freshly allocated `Type` for
  constants.** Compare types by `getName()`, never by pointer, or the
  comparison silently fails for literals.
- **`Builder.CreateGlobalString` takes the module from the current insert
  block.** Class metadata is emitted with no insert point set, so the module
  must be passed explicitly or it segfaults.
- **Catching an exception by value slices it.** `main.cpp` did this and every
  code generation error printed a useless generic message for years. Catch by
  reference and exit non-zero.
- **The grammar produces no `Assignment` node.** `x = expr` is always a
  `LocalDefinition` with the type `auto`; the generator decides between
  assignment and declaration by whether the name already resolves.

## Conventions

- Method mangling is `M<len><Class>_<method>`, e.g. `M2_IO_out`, `M4_Main_main`.
- Runtime type-info globals are `R<Class>` (`RString`, `RIO`); class-name string
  globals are `N<Class>`.
- Semantic errors are thrown as `SemanticException` and caught in `main.cpp`.
- `.cm` is a program, `.cmm` a module, `.ast` the serialized JSON AST.

## Branches

`master` is the only live branch and is well ahead of the other two, both of
which branched before code generation existed:

- `origin/unary` — one unmerged 2019 commit adding `++`/`--` (lexer tokens,
  grammar rules, `UnaryOperator` serialization). Real but stranded work against
  a much older grammar; porting it forward is a manual reapply, not a merge.
- `origin/set-up-semaphore` — Semaphore CI config churn only, never landed.

`.circleci/config.yml` is a placeholder that echoes "Hello, world" and builds
nothing.
