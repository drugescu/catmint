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
              flex+bison                    semantic analysis      + runtime-<os>.bc
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
`__catmint_new` and must be linked against the runtime before running.

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

Both `catmint-lex` and `catmint-gen` relink when `libcatmint-ast.a` changes;
without that dependency a stale binary survives a change to a shared header
or to `ASTVisitor.cpp`, and the symptom is a fault in code that looks
correct.

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
committed `.ref`, and writes `<test>.errlog.txt` on mismatch. A class records
the path it was parsed from, so the `.ref` files contain the path as
`wtest.sh` spells it (`./test_suite/x.cm`); regenerate them by running the
parser the same way it does, not with a different prefix. The `.ast` files
are generated and are not committed. All 11 pass. `declarations.cm` and `dispatch_complex.cm` had failed since
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

A test may also carry `test_suite/<name>.check`, an executable script run with
the source file once the program's output has matched. It exists for what the
output cannot show: `35_debug.check` compiles the program again with `-g` and
asserts what is in the generated IR. A non-zero exit fails the test.

`catmint-gen/dbg.sh <file.cm>` parses and generates one program and prints just
the error, which is otherwise lost in the debug trace.

To compile and run a program end to end, `./catmintc --run examples/tour.cm`
from the repository root; `COMPILING.md` documents the four underlying stages.

Both tools are quiet unless given `--verbose`: the AST dump, the type table,
the symbol table and the grammar's running commentary all go to `std::cout`,
which is redirected to nowhere by default. Diagnostics go to `std::cerr` and
are never swallowed, so a failing build still says why.

`catmintc` runs LLVM's tools and nothing else: `llvm-link` with the prebuilt
runtime, `opt` and `llc` at `-O2` (`-O0` on its command line turns that off),
and lld to link. **No clang in a user's path.** Clang is for developers: it
builds the runtime from `runtime.c` and runs `--asan`, whose run-time library
ships with it; `catmintc --asan` without clang says so and stops. The module
names no target, so `opt -mtriple=<host>` supplies the host's triple and data
layout, and on Apple silicon `-mcpu=apple-m1`, which is what clang assumed;
`bench/run.sh` was unchanged or faster for the switch. The link line is
`link_executable` in `catmintc`, and it carries the hardening clang's driver
used to add: position-independent executables, and on Linux `-z relro -z now
-z noexecstack` -- `tools/linux/test.sh` checks the result with `readelf`.
The optimisation level is not a nicety: at `-O0` llc uses the fast
register allocator, which spills every value to the stack, and a counted loop
ran more than twice as slowly for it. Running LLVM's pass pipeline inside
`catmint-gen` as well was tried and made no measurable difference on top of
that, so the generator emits plain IR, which is also far easier to read when
working on it.

## The runtime ships prebuilt

`catmint-gen/runtime.c` is the object model and I/O library: `TObject`,
`TString`, `TIO`, `TList`, `TInteger`, `TFile`, `TMath`, the
`__catmint_rtti` type-info struct, `__catmint_new`, and the built-in methods.
Users never compile it. What ships is **`runtime-darwin.bc` and
`runtime-linux.bc`**, and `catmintc` links the one for the host
(`CATMINT_RUNTIME` overrides it, which is how the test suite links the one it
has just built).

- **Bitcode built by LLVM 16**, the oldest catmint supports: newer LLVM reads
  older bitcode by policy, so one file serves every LLVM from 16 on. Textual
  IR has no such promise, which is why the old `runtime.ll` written by LLVM 22
  could not be read by 18.
- **One per OS**, because the C library's headers are not neutral. Built on
  macOS the IR calls `\01_fputs` and `\01_fopen` (Darwin's aliases) and
  `__maskrune`; on Linux it calls glibc's `stdin`, `stderr` and
  `__ctype_b_loc`. The old claim that one `runtime.ll` served every host held
  only because `build-runtime.sh` quietly recompiled `runtime.c` wherever
  there was a C compiler. **Within one OS the file is valid on every
  architecture, but not identical across them**, and it was believed to be
  until a CI runner disagreed with the container it had been built in. Built
  by clang's own `-O2` it carried the builder's cost model (a loop unrolled by
  two on x86-64, not on aarch64), `align 16` on arrays x86-64 aligns and
  `align 8` where aarch64 does not, and `zext` where x86-64 has `sext`: plain
  `char` is unsigned on aarch64 Linux. See the next section.
- **Stamped.** `runtime.c` defines `__catmint_abi_<CATMINT_ABI>`; the
  generated `main` reads it volatile, so every program needs that exact
  symbol and a runtime from another agreement fails to link. **Bump
  `CATMINT_ABI` in `runtime.c` and `CatmintAbi` in `IRGenerator.h` together
  whenever a layout, an RTTI field or a slot changes.** Test 63 checks a
  renamed stamp is refused.

`build-runtime.sh` is a developer tool that nothing in `catmintc` calls. It
strips the triple, data layout, CPU, features and probe-stack, normalises the
module name, removes `!llvm.ident`, and assembles bitcode; it prefers LLVM 16
(`brew install llvm@16`). **The file must not depend on who packaged the
compiler.** `--check` byte-compares, and the ident ("Ubuntu clang version
16.0.6 (23ubuntu4)") made it fail on a CI runner whose clang-16 was the same
compiler under another build number; so the ident goes, and the choices a
packager makes by default are stated: a PIE and no stack protector on Linux,
`-fstack-protector` on macOS. That the two differ is inherited, not decided --
the macOS runtime has the protector on 160 functions and the Linux one on
none. A failing `--check` prints the disassembly diff, and as a GitHub
annotation when run there (readable without signing in, via the check-runs
annotations API -- the job log is not).

**The runtime ships as the front end's output, unoptimised, built on one
architecture per OS.** `-O2 -Xclang -disable-llvm-passes -fsigned-char`: the
optimiser is the `opt -O2 -mtriple=<host>` in `catmintc`, which sees the whole
program with the runtime inside it and optimises for the machine that runs it
(`bench/run.sh` is unchanged: within the noise on every benchmark). `-O0`
would add `optnone`, which is why it is not that. `-fsigned-char` removes the
one difference that could change behaviour; what remains is alignment hints,
the sync/async flavour of `uwtable`, `jmp_buf`'s type, and each target's
default function attributes, none of which changes what a function does.
`portability.sh` enforces exactly that: it normalises those and requires every
instruction and module flag to match, on macOS by building both Darwin
architectures by target, and on an aarch64 Linux host against the committed
x86-64 file. It says "not checked here" where it cannot. The canonical
builders are **x86-64 on Linux (the CI runner) and arm64 on macOS**;
`build-runtime.sh` refuses to write the committed file anywhere else, and
`--check` says it is skipping rather than failing. On a Mac that is a target
away; for Linux:
`PLATFORM=linux/amd64 tools/linux/run.sh catmint-gen/build-runtime.sh`
(emulated on Apple silicon, so slow). **If you change `runtime.c`, rebuild both
files and commit them**; `build-runtime.sh --check` fails when the committed file is not what
`runtime.c` builds to. `ctest.sh` builds a fresh runtime into its work
directory, so the suite tests the source being edited even before you do.

The layouts and the virtual table slot order in `runtime.c` are fixed by
agreement with `IRGenerator.cpp`; changing one without the other silently
miscompiles, which is what `42_builtin_slots.cm` exists to catch.

Two things in there are performance work rather than semantics, and both
have a benchmark behind them. A `String`'s characters live in the same
allocation as the String, so building one costs a single `malloc`;
`owns_inline_chars` is how `free` knows not to release them separately, and
`Object.copy` gives the copy its own buffer because the copy is only as long
as the RTTI says. And integers from -128 to 1024 are shared boxes with a
reference count of zero, so a `List` of flags or counts allocates nothing --
which is also why `Integer` has no setter: changing a shared box would
change that number for every holder.

## Errors

`try: ... catch e: ... end` and `throw <expression>`, on `setjmp` and
`longjmp`. This is what Lua does and it fits for the same reason: the
language has no destructors, so jumping over a frame skips no work that had
to happen, and the path where nothing is thrown costs one `setjmp` per try
rather than the frame descriptors a table-driven scheme needs.

The generated code allocates the jump buffer itself, because `setjmp` has to
be called from the frame it will return to; the runtime only keeps the stack
of them. Its size is fixed at 512 bytes by agreement with
`CATMINT_JMPBUF_BYTES` in `runtime.c`, which checks `sizeof(jmp_buf)` against
it at run time rather than being silently too small somewhere.

`__cm_throw` pops the innermost handler before jumping, so a throw from
inside a `catch` reaches the next handler out instead of looping back into
itself. **It also retains what is being thrown before unwinding**, because
`throw "a" + b` builds its String in the pool of the very frame the jump
abandons, as does `__cm_runtimeError` building its message -- so without the
retain the handler read memory that had gone. It survived by luck when throw
and catch were in one method and corrupted the heap when they were not, which
`lli` reported as a crash inside malloc, the same way `Object.free` once did.
That retain is given back by the **handler**, which opens a pool and puts the
caught object in it; doing it in `__cm_throw` instead handed the object to the
catching *method's* pool, which does not close until that method returns, so
a loop that threw piled them up.

**A throw gives back what the frames it abandoned were holding.** The jump
skips their scope-exit releases, so the pool carries a second kind of entry
alongside objects: the *address of a variable*. It is dropped when a pool
closes normally -- the scope releases as it always has -- and released when a
throw unwinds the pool. The try body and the handler each get a pool of their
own: the first so unwinding reaches the catching frame's own locals, which
live in a different pool from the frames below it, and the second so the
thrown object dies with the handler.

**`Object.copy` retains the copy's reference fields.** Two objects share them
after the `memcpy`, so each needs a holder, exactly as a `List`'s items do.
This only became necessary when freeing started following those fields:
before that nobody released them, so a shallow copy was harmless. Without it
the copy and the original each released the same object and the second read
memory that had gone -- a hard crash in `object_free`.

**String equality is `memcmp`, not `strncmp`.** A String carries its length
rather than ending at a NUL, so it can contain one -- `Bytes.toString()` and a
binary file read both produce such strings -- and `strncmp` stopped at the
first, which made `{0,1}` and `{0,2}` compare equal through both
`String.equals` and `==`.

**Return types are inferred in a pre-pass, before anything is checked.**
`inferReturnTypesEarly` runs to a fixed point over every method before the
classes are visited. Filling `auto` in during the ordinary pass made three
things depend on declaration order -- an argument's type, an override's
signature, an interface's conformance -- because a caller visited earlier than
its callee still saw `auto`, which the type table maps to Void; all three
worked if the declarations were reversed. The pre-pass is structural and
shallow: literals, `new`, arithmetic over those, and bare calls to methods
that declare their type. It gives no answer for anything needing the symbol
table, which is not an error -- the ordinary pass still settles those. It
reconciles disagreeing returns with `commonReturnType`, the same strict rule
the ordinary pass uses; using the general convertibility test there let a
method returning an `Int` and a `String` infer `String` and skip the check
entirely, which `47_inference.check` caught.

**`catmintc` records a module after its own imports.** Appending before
recursing gave `A B` where A imports B, so `--separate` compiled A before B
existed to import; `13_separate` masked it by importing both and listing the
dependency first. Two lists are needed: `MODULE_SEEN` marked on the way down
stops a cycle, `MODULE_ORDER` appended on the way back up gets the order
right. The append goes through a helper, because a shell variable is global
and the recursion clobbered `$name` before it could be recorded -- positional
parameters are the one thing each invocation keeps to itself.

**A reference parameter is borrowed.** The caller holds it for the whole call,
so the callee retains it only if it *assigns* to the parameter -- which
`AssignedNames` works out from the body, since `x = expr` is a
`LocalDefinition` with the type "auto". Counting them all unconditionally cost
a retain, a release, a slot registration and, through that, a whole temporary
pool in methods that allocate nothing: a method taking a String and returning
its length ran three times slower for it. `Local::Counted` is what records
this, and `releaseScopes` skips a slot that is not owned. The runtime's own checks go through `__cm_runtimeError`, which throws
a String when a handler is installed and prints and exits when none is, so a
null dispatch or an index out of bounds is catchable.

**A function containing a `try` has all its locals made volatile**, by a pass
over the finished function in `makeLocalsVolatile`. This is the C rule about
`volatile` locals across `setjmp`, applied by the compiler rather than left
to the programmer, and it is load-bearing: without it, at `-O2`, a variable
assigned inside the try reads back in the handler as whatever it was when
`setjmp` ran. Test 36 checks exactly that.

A `return` out of the middle of a try pops the handlers it is jumping over
(`popOpenHandlers`), or the next throw would jump into a frame that has gone.

## Memory

Every object is `{ rtti, int refs, fields... }`. `__catmint_new` starts the
count at 1; a static object -- a string literal, a class name -- is emitted
with a count of 0, and **0 means never free**. That is why the count lives in
the object rather than in a hidden allocation header: reading a header in
front of a compiler-emitted global would be reading memory the program does
not own.

**The compiler counts references.** It emits a retain on every store of a
reference -- into a local, a parameter, an attribute, a loop variable, a
handler's variable -- a release of whatever that slot held before, and a
release of every reference local when its scope ends. `List` does the same
for what it holds, in `runtime.c`. `self` is the one exception: it is not
counted, because the caller holds it for the whole call.

**Temporaries are handled by a pool.** An expression makes objects nothing
names -- the String `a + b` produces, the Integer boxing an Int produces -- so
every allocation also joins the open pool, and closing the pool releases
everything in it once. An object that was also stored has two references and
survives; one that was not has one, and goes. A method opens a pool, and so
does each iteration of a loop body, which is what keeps a long loop's memory
flat.

**A pool is emitted speculatively and removed again if nothing inside it
allocated.** `beginPool` emits the open and remembers the allocation counter;
`endPool` erases that open, and every close a `return` emitted for it, when
the counter has not moved. Without this a loop that only adds integers paid
two calls an iteration for a mechanism it never used, which measured as a
sevenfold slowdown. `noteAllocation` is what moves the counter, and it must
be called from **every** place the generator emits something that can put an
object in the pool: `constructObject`, the allocating coercions, string
concatenation, `substring`, and any call whose return type is a reference,
since the callee hands its result to this frame's pool on the way out.

**There is no `free`.** An unconditional "give it back now" cannot be offered
once the compiler is counting, because it would leave the counted references
pointing at freed memory -- which is exactly how it failed when it was still
there. `release` lets go of one reference and frees on the last; `retain`
takes one; `refs` reports the count, which is 2 for a freshly made object
held in a variable (the allocation's, still owed to the pool, and the
variable's). `IO.allocated()` is the live object count -- leaving out what only a pool is
holding, see below -- which is how test 31 proves a thousand-iteration loop
returns to where it started.

**Freeing follows a class's reference fields.** The run-time type information
carries a list of their byte offsets ending in -1, which the generator writes
because it is the only thing that knows the layout, and `object_free` walks
with the count held at 1 so that a field pointing back at the object cannot
re-enter and free it twice. Inherited fields need no special case: a
subclass's layout begins with its parent's, so `FieldIndex` already covers
both. Until this existed a class with a String field leaked that String on
every instance that went away -- not bytes at exit but a leak that grows.
Reference cycles are still never collected, which is what counting rather
than tracing costs.

The whole codegen suite runs clean under AddressSanitizer, which is the check
to repeat after touching any of this.

## State of code generation

Code generation is real: every class and method is emitted, objects have a
virtual table, and methods take `self`. `IRGenerator.cpp` is the whole of it.

For each class the generator emits an LLVM struct laid out as
`{ rtti, inherited fields..., own fields... }`, a `@N<Class>` name string, an
`@R<Class>` RTTI record containing the virtual table, and a `<Class>_init`
that chains to the parent initialiser and then runs the attribute initialisers.
Virtual table slots are the parent's followed by the class's new methods in
declaration order, with an override reusing the parent's slot. Built-in classes
are seeded to match the order already fixed in `runtime.c`, so `Object` holds
slots 0-2 and `IO` adds `input` and `out` at 3 and 4.

Dispatch loads the function pointer from the receiver's vtable, after a
`__cm_checkNull` -- except when the receiver is `self`, which is not checked
because a method is running, so the object it is running on exists. That
covers a bare call and a call written on `self`, which is most calls in
recursive code, and it took `fib(32)` from 0.018 s to 0.012 s. Static
dispatch calls the implementation directly.

`a.b` reads a field of any object and `a.b = v` writes one, both lowering to a
single GEP into the object's struct. Inherited fields need no special case,
because a subclass's layout begins with its parent's. `a.b` and `a.b(...)` are
told apart by the token after the name: with `(` the parser shifts into
`dispatch_expression`, otherwise it reduces `field_access`.

`new T(a, b)` allocates, runs the attribute initialisers and then the
constructor. A constructor is declared with `constructor(...):` and is sugar
for a method named `init`: `new` is therefore an ordinary call as far as the
type table, the argument checking and the generator are concerned. It gets no
virtual table slot, because a subclass's constructor takes its own arguments
and would otherwise share a slot with a function of a different type; it is
always called on a known class.

Declaring a variable of class type still constructs it, and runs the
constructor when that constructor takes no arguments. Declaring a variable of a
class whose constructor does take arguments leaves the object default-
initialised, as it was before constructors existed; use `new` there.

One detail that is easy to trip over, forced by the grammar:

- **`x = expr` is a `LocalDefinition` with the type `auto`, never an
  `Assignment`.** The generator treats it as assignment when the name already
  resolves, and as a declaration otherwise. Without that, `sum = sum + i`
  inside a loop body would bind a fresh `sum` that dies with the body's scope.

`for v in n:` counts from `0` to `n - 1`; `for c in str:` walks a string's
characters as one-character strings. Both lower to the same counted loop.
There is no list type in the runtime, so nothing else can be iterated.

Integers come in four widths: `Int8`, `Int16`, `Int32` and `Int64`. `Int` is
`Int32`, and the parser folds the longer spelling into it so only one name
reaches the type table. Mixing widths in an expression promotes both operands
to the wider of the two; assigning across widths sign-extends or truncates
implicitly, as C does, because the language has no cast expression for
numbers. A literal too large for an `Int` is an `Int64`; arithmetic on two
`Int`s stays 32 bits, so a 64-bit computation needs a 64-bit operand to start
from. Boxing goes through a 64-bit `Integer`, so no width loses anything on
the way into a container. `IO.epoch()` is an `Int64` and works past 2038.

Floats come in two widths, `Float` (a double) and `Float32` (a C `float`);
`Float64` is folded into `Float` by the parser, as `Int32` is into `Int`.
`TypeTable::floatWidth` is the float counterpart of `integerWidth`, and the
rules mirror the integer ones: two floats meet at the wider, an integer meets
a float at that float, and `coerce` extends or truncates between the widths
implicitly. **Every float literal is a double** -- `FloatConstant` stores one.
It stored a `float` until test 59, so every literal in every program was
rounded to seven digits before the generator saw it; printing at six digits
hid it, and a bit-for-bit comparison with an independent port of a game
found it. `Floats` still holds doubles.

Namespaces: `using math as m` declares that module's classes as `m::Name`.
A qualified name is joined into a single `IDENTIFIER` by the lexer, because
letting the grammar see `IDENTIFIER :: IDENTIFIER` where a type is named is
ambiguous with static dispatch (`Program::run.execute(...)`), which begins
identically; the dispatch rule splits it apart again. In symbols `::` becomes
`$`, which cannot appear in a catmint identifier, so nothing can collide.

`catmint-gen -g` emits debug information: a `DISubprogram` per generated
function, a `DILocation` per expression, and a store of the current line to
the runtime's `__cm_line`, which is what lets a failed bounds check or a call
on null say *where* and not only what. None of it is emitted without `-g`, so
an ordinary build pays nothing; `52_error_lines.check` asserts both halves of
that. It is line numbers and nothing else -- no types, no variables. Each class carries the file it was parsed
from, so a method spliced in from a module points at that module rather than
at the concatenated text. `catmintc -g` passes it through and then, on macOS,
runs `dsymutil`, because macOS leaves DWARF in the object file and records
only a debug map in the executable; compiling and linking in one command
would delete the object first, which is why `clang -g one.c -o one` also
produces an executable a debugger cannot read.

`interface Name ... end` declares a set of method signatures with no bodies,
and `class C from P does I, J` promises them. An interface has no instances,
no attributes and no parent of its own, and its methods must declare a return
type -- without one, `def f` and `def Int f` cannot be told apart until the
token after, and an interface is the one place where saying what comes back
is the point anyway.

How it dispatches: the RTTI gained a fourth field, `interfaces`, pointing at
a null-terminated array of `{ interface rtti, base slot }`. A class appends,
at the end of its own virtual table, one run of slots per interface it
implements, holding its implementations in the interface's declaration order.
A call through an interface asks `__cm_ifaceBase` for where that run starts
and adds the method's position within the interface; Object's own methods sit
at the same index in every class, so those still go straight to the slot. A
subclass repeats its parent's runs rather than sharing them, so a method it
overrides is the one the interface reaches -- that is what test 40's `Cube`
checks.

Because the RTTI grew a field, **the virtual table is now at index 5**, in
both `runtime.c` and the GEP in `emitCall`. It has moved twice: to 4 when
`interfaces` was added, and to 5 when `finalize` was. Metadata is emitted in three
passes -- built-ins, then interfaces, then classes -- because a class's
interface table points at the interfaces' metadata and an interface's points
at Object's, while `ClassOrder` only promises parents before children.

Assigning an object to an interface it does not visibly promise is allowed
and checked at run time by `__cm_cast`, which now also consults the interface
tables, as `__cm_isType` does; so does `expr is SomeInterface`.

`defer <expression>` runs the expression where the enclosing **block** ends,
on every path out of it, last registered first. It is emitted at those points
rather than recorded, so it costs nothing at run time and the runtime knows
nothing about it. Two consequences worth knowing, both documented for
programmers in `COMPILING.md`: the expression is evaluated when the block
ends, not where the `defer` is written, so it sees the final values; and a
`throw` passing through does not run it, because the jump leaves no
opportunity to. Deferred work runs before the scope's locals are released,
since a deferred call almost always uses one of them.

String interpolation is a source rewrite in the preprocessor: `"a ${e} b"`
becomes `("a " + (e) + " b")` before the lexer sees the line, so what is
inside the braces is ordinary catmint parsed by the ordinary grammar, and the
compiler gained no node, no token and no runtime support for it. It recurses,
so a string inside an interpolation interpolates too; `\$` is a dollar sign;
single-quoted strings are literal. A string with no `${` passes through
untouched, which is why no existing test changed.

`using namespace m` opens a namespace so its classes can be named without
the prefix. The preprocessor turns it into an `#open` directive, the lexer
records it, and `qualifyTypeName` resolves an unqualified name against the
classes declared so far -- a module is spliced in at its `using` line, so its
classes are always declared before the code that opens it. A class declared
globally always wins, and a name two opened namespaces both declare is an
error rather than a guess. It does not work under `--separate`, where the
module is never spliced in and there is nothing to resolve against.

`static def` declares a method with no receiver: it gets no virtual table
slot and is called on the class, `Geometry.square(7)`. A call whose receiver
is a bare name is a static call when that name is a class and *not* a
variable, so a variable shadowing a class name still wins. Inside a class a
static may be called unqualified, which is how one static calls another.
The built-ins that never used their receiver are static now -- every `Math`
method, `File.exists`, `File.remove` and `String.chr` -- so `Math` takes no
virtual table slots at all and exists only to name its functions.

`Bytes`, `Ints` and `Floats` are fixed-length runs of numbers stored as
numbers: `{ rtti, refs, int length, T *data }`, one allocation and an indexed
load per element. They are three concrete classes rather than one generic
one, because catmint has no generics and is not getting any; the same eight
lines three times is a smaller price than a type system that could say
"array of Int". They earn their place in the runtime by the same test `List`
did, stated in `lib/vector.cmm`: the language cannot express them, because
there is no way to reach raw memory. Growing is left to `List` and `Vector`,
which are expressible on top.

**A call goes straight to the implementation when nothing overrides it.**
`canCallDirectly` checks whether any class in the program overrides the
method below the receiver's static type; if none does, the virtual table is
skipped and the optimiser can inline through. It answers no when compiling a
module alone or a program that imports separately compiled ones, because an
override could be hiding there. This took `fib` to parity with C.

**The runtime is built at `-O2` but not optimised, and that is not about the
runtime's own speed.** At `-O0` clang marks every function `optnone noinline`,
so nothing in `runtime.c` could ever be inlined into a program that linked
against it -- not `String.len`, not an array element access, nothing. Changing
that one flag in `build-runtime.sh` took the sieve benchmark from 0.050 s to
0.014 s and string building from 0.302 s to 0.212 s. `-O2` with the LLVM
passes disabled keeps the attributes that allow inlining and leaves the
optimising to the single `opt` run over the linked program, for the host. The
emitted IR stays portable: generic LLVM intrinsics and generic vector types,
which every backend lowers. (A program built with `catmintc -O0` now gets an
unoptimised runtime too; that flag is for debugging.)

A chain of string concatenations is emitted as one `__cm_concatAll` rather
than a tree of `M6_String_concat` calls, so the result is allocated once and
the intermediates are never made. Every interpolated string is exactly that
shape, which is what makes the special case worth having.

`and` and `or` are short-circuiting and bind looser than every other
operator, so `p != null and p.value > 0` needs no parentheses and never
evaluates the right side when the left has settled the answer. `&` and `|`
remain the bitwise operators and still evaluate both sides.

`expr is Type` reuses `StaticDispatch` with the method name `is`, since that
node already carries both an object and a type name. No new AST node, so no
serializer work.

A built-in method's virtual table slot is fixed by `runtime.c`; its
declaration order in `TypeTable::addBuiltinClasses` is that slot order. A new
built-in method must be appended, never inserted, or every already-compiled
caller silently calls the wrong slot.

**Return-type inference.** `def f:` parses as the return type "auto", which
the type table maps to Void. The semantic pass now, after visiting the body,
collects its `return`s and gives the method the type of what they return,
writing it back onto the `Method` node so the generator sees it. **Only an
explicit `return <expression>` counts**: a body with no such statement stays
Void, which is what makes this safe to add to a language that already has
programs in it -- nothing written before it changes meaning. The Python rule,
where the last expression is the value, would have given
`def greet: out("hi") end` whatever `out` returns.

Two returns of different types go through `commonReturnType`, which is
deliberately **stricter** than `isEqualOrImplicitlyConvertibleTo`: that one
allows boxing in either direction, so a method returning an `Int` and a
`String` inferred `Int` and died at run time with "Expected an Integer, found
String" -- the exact error inference exists to move to compile time. The
narrow rule is: the same type, the wider of two integers, `Null` with any
reference, or a class and one of its ancestors. Anything else is a compile
error asking for `def <type>`. Inference does not cross a recursive call,
whose own type is not known while its body is being visited, and it needs no
help for separate compilation: the module's `.ast` carries the bodies, and
the importing unit runs the same analysis over them.

## The foreign function interface

`extern class Libc ... end` declares C functions: signatures only, the same
body-less form an interface uses, and every one is made static by the parser
because a C function has no receiver. The symbol is the method's own name --
mangling it would name something that does not exist. Nothing is emitted for
an extern class at all: no metadata, no initialiser, no bodies.

**Declaring is safe; calling needs `unsafe`.** That is Rust's split, and the
reason is the same: a declaration asserts a match with a function this
compiler cannot see. `unsafe: ... end` is an ordinary `Block` carrying a flag
rather than a node of its own, and `unsafe def` makes a whole body one. The
semantic pass counts the depth and refuses an extern call at zero.

What `unsafe` enables is **exactly two things**: calling an extern function,
and going through a `Ptr`. Everything else stays on inside it -- objects are
still null-checked, arrays still bounds-checked, references still counted.
That property is the point: it makes `grep -rn unsafe` an audit rather than a
gesture. This is Rust's *marking* without Rust's *proofs*, and it should not
be oversold: a `Ptr` outliving what it points at is undetectable here.

`Ptr` is a primitive, registered in the type table **with no Class behind
it**, which is what makes `isReferenceType` answer no -- nothing counts it,
nothing frees it, it never reaches the temporary pool. It meets `null` and
nothing else: no conversion to or from `Int` in either direction, because a
pointer reachable by arithmetic is one nobody can reason about.

Only what has an unambiguous machine representation may cross: the integers,
`Float` (as a `double`) and `Float32` (as a `float`) by value, `Ptr` as itself, `String` and the three arrays as the
address of their contents. `marshalToC` does that last part -- all four put
that pointer at the same offset, so one struct shape serves -- and keeps the
null check, because handing C a null where it wants a buffer is a fault with
no message. An `Object`, a `List` or a user class in an extern signature is a
compile error, since what would cross is the catmint object, type information
and reference count and all.

**C structs and unions.** `extern struct` and `extern union` are classes
with `Class::isCStruct()`, fields only (the `c_field` rule), and the
generator gives them their own shape: `{ rtti, refs, ptr view, [n x i8] }`.
An owned instance has a null `view` and its bytes inline; a view (an extern
function returning the struct type, or `S.at(ptr)`) has C's pointer there.
`dataPointer` picks between them with one select, so nothing else ever tells
them apart, and `Object.copy` is right for both without special handling.
The layout is `layoutCStruct`: C's natural-alignment rule, which is the same
on every target catmint supports; every `@ n` is checked there. Because a
view's pointer is a plain `ptr` field with no entry in the RTTI's list of
reference fields, `object_free` never touches C's memory.

The unsigned C types are rewritten **in the parser**: `cBoundaryType` turns
`UInt8`/`UInt16` into `Int` and `UInt32`/`UInt64` into `Int64` for everything
downstream, and keeps the C type as `Attribute::getCType` and
`Method::getCReturnType` for the generator's `lowerCType`, `loadCScalar` and
`storeCScalar`, which zero-extend and truncate at the real width. So the
semantic pass and `staticTypeOf` never see a `UInt`, and a `UInt` anywhere
else is refused by `refuseCBoundaryType`. Extern calls go through
`emitExternCall`, not `emitStaticCall`'s ordinary path, because what C
receives is decided by the C signature (`externFunctionType`).

**Bindings are generated, not written.** `tools/bindgen.py` reads a C
library's headers through clang -- declarations from the JSON AST, layouts
from `-fdump-record-layouts-complete`, constant values from clang evaluating
each one as an enumerator initialiser -- and writes a `.cmm` of extern
structs with every `@` asserted, one extern class of functions, and a class
of constants as static methods. `lib/sdl2.cmm` is its output for SDL2 and is
**never edited by hand**; the command is in its header. `lib/sdl.cmm` is the
hand-written safe layer on top. When the generator gets something wrong the
compile fails on an `@` assertion rather than corrupting memory, which is
the point of writing clang's offsets out. Two things it has already got wrong
and now handles: a typedef of a function pointer whose parameters mention a
struct is not that struct (only the typedef's own type counts), and a record
with a bitfield or an anonymous member becomes an array of integers of the
record's alignment, so records holding it still lay out right.
`tools/bindgen_test/run.sh` binds a test header against a C library built
from it; `test.sh` runs it and says "skipped: needs clang" rather than
nothing when it cannot.

The generator reads the **target's** scalar sizes from clang's predefined
macros (`__SIZEOF_LONG__`, `__CHAR_UNSIGNED__`), so `long` is `Int64` on Linux
and macOS and `Int` on Windows, and `--target` / `--clang-arg=` bind for a
machine that is not this one (the test binds its header for
`x86_64-pc-windows-msvc` and checks `b` lands at offset 4, not 8; use the `=`
form for a clang argument that starts with a dash). `--constants-match`
repeats, and the header reports how many names each pattern matched and says
so on stderr when one matched nothing -- `AUDIO_S16LSB` was missing from the
SDL bindings for exactly that reason, an unprefixed name under a `^SDL_`
pattern. `--string-returns REGEX` binds the named `char *` returns as `String`;
leave out anything that returns memory someone must free (`SDL_GetPrefPath`,
`SDL_GetClipboardText`). A variadic function is listed as refused, with
"takes a format string" added when clang's JSON carries a `FormatAttr`.

**The SDL library and the game run headless** in `test.sh`:
`SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software SDL_AUDIODRIVER=dummy` need
no window system, and the game's 17 input tests and `check.sh` pass under them.
`tools/sdl_test/run.sh` runs always (and says "skipped: SDL2 is not installed"),
the game's two suites with `--thorough`. SDL's `disk` audio driver
(`SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE=f.raw`) records what a program
queues, converted to signed 16-bit stereo at 44.1 kHz whatever was asked for.

**The C boundary's edges** (all in `emitExternCall` and `checkExternSignature`
unless said). *Text back*: an extern function declared to return `String`
gets `M6_String_fromC(ptr, 1 << 20)` called on its result -- before this the
raw `char *` came back typed as a String, which was type confusion inside
`unsafe`; `Bytes`/`Ints`/`Floats` returns are refused for the same reason.
`String.fromC` is `emitFromC`, routed from `emitStaticCall`; a `Bytes` source
goes to `M6_String_fromBytes`, which clamps `max` to the buffer's own length,
and a `Ptr` or `null` to `M6_String_fromC`; the semantic pass makes it need
`unsafe` (the same gate as an extern call) and refuses `Ints`, `Floats` and
structs as the source. *The literal `null`* where a parameter is a
`String` or an array is C's NULL, decided by the argument's static type being
`Null` -- not by its value, so a null-holding String variable still meets
`marshalToC`'s null check. *Aliases and variadics*: `Method` carries
`getCSymbol()` (the C name, defaulting to the method's own) and
`getFixedParams()` (minus one unless variadic); the grammar's `extern_method`
rules build them, `OP_ELLIPSIS` is the `...` token. `externFunctionType` gives
LLVM the fixed parameters and `isVarArg`; the call's extra arguments are the
declaration's remaining parameters, promoted to at least an `int`
(`c.promote`). **A variadic call must be made through a variadic function
type**: on Apple arm64 variable arguments go on the stack, and declaring
`snprintf` as an ordinary function printed `0.000|83734528` for `3.142|42`
(test 67 is the proof). `String` and arrays are refused in the variable part,
`Float32` too (C promotes it; declare `Float`).

*`Process` without a shell*: `runArgs`/`startArgs`/`openArgs` take a List and
`execvp`; `argv_from_list` validates it (null, empty, over 4096, non-String,
NUL) before anything starts. `openArgs` forks by hand, so its pipe is closed
with `fclose` and a `waitpid` on `TProcess::pid`, not `pclose` -- that is what
`process_close` decides, and why `object_free` and `finish` both call it.
`openArgs` is appended after `finish` in both `TypeTable.cpp` and `RProcess`,
and `RProcess` is now a 12-slot vtable (`catmint_rtti12_process`). **The child
closes the parent's other descriptors** (CWE-403: a socket or a document would
stay open in a program that could read it). `open_descriptors` snapshots them
*in the parent* and the child only calls `close`, because between `fork` and
`exec` only async-signal-safe functions are allowed -- SDL starts threads, and
one may have held the malloc lock at the fork and never release it in the
child. It asks each descriptor in turn (`fcntl(fd, F_GETFD)`) rather than
reading `/dev/fd`: `opendir`/`readdir` are `readdir$INODE64` on Intel Macs and
plain `readdir` on Apple silicon, two struct layouts, and the Darwin runtime is
one file for both. `portability.sh` caught that in the first version, which
had used them; this is what its architecture check is for. Test 69 counts the
descriptors a child sees with and without files open here (not an absolute
number: macOS's `ls` opens two for itself) and fails when the closing is
removed.
`String.chr(0)` was an empty String because `chr` built a C string; it uses
`new_string(1)` now.

**Callbacks.** `extern def Compare(Ptr left, Ptr right) Int` is a `Class` with
`isCallbackType()` (a flag of its own: `isCStruct()` is `cKind != 0`, so reusing
a kind would have made it look like a struct) holding one static method,
"call", for the signature; it is also `isExtern()`, which is what makes the
generator skip its initialiser, metadata and bodies. There is deliberately **no
`callback` keyword**: it is a field and parameter name throughout the generated
`sdl2.cmm` and the obvious name of a variable. A callback is passed by
*naming* the method, which the parser already reads as a field access on a
class name; `checkCallbackArgument` reinterprets it when the extern parameter is
a callback type, and `emitExternCall` never evaluates it. `callbackTrampoline`
writes, in IR, the function C calls: `__cm_callbackEnter` (aborts off the main
thread, answers 1 if an error is pending), a handler and `setjmp`, a pool, the
conversion of C's arguments (`UInt8/16` zero-extended to `i32`, `UInt32` to
`i64`, a struct pointer made a view), the call, and on a throw
`__cm_callbackFail` keeps the error. **Every extern call is followed by
`__cm_callbackRethrow`**, which throws what a callback kept; it is a load and a
branch. Note the consequence: that check also runs for extern calls *inside* a
callback body, so a body that makes one while an error is pending dies at it.
That is correct, and it once hid a missing skip in the test, which now counts
through a handle so that no comparator makes an extern call.
`gMainThread` is recorded by a C constructor in the runtime, so the generated
`main` needed no change and `CATMINT_ABI` did not move. `Handles` is a
static-only built-in class (`Math`'s shape; registered in `StringConstants.h`,
`TypeTable.cpp`, `IRGenerator.cpp`, `catmint.y`'s global type names and
`runtime.c`), a table of `{object, generation, next_free}`; a handle is
`0x4348 << 48 | generation << 24 | index + 1`, so a number that is not one
fails the magic check, and a dropped slot's generation moves on so a stale
handle cannot reach whatever reuses it. Two Ptrs cannot be compared with each
other (only with `null`), so tests observe handles through `get`, reference
counts and `allocated()`.

Three defects found while testing callbacks, **all fixed** (tests 73, 74, 75):

**A place inside C memory is an address, not a value.** `items.cells[2].value
= 42` compiled and wrote to a *copy* of the element: `cells[2]` was evaluated
whole, which copies a nested struct, and the store went to the copy. Silent,
which is the worst kind. The generator had three special cases (a field, a
field of a field, an array element) and no idea of "the bytes this expression
denotes". `cStructAddress(E)` is that idea: for a nested struct held by value
it is `cFieldAddress`, for an element of an array of structs it is
`cElementAddress` (the bounds-checked address, shared with get/set), and only
otherwise an object evaluated and its bytes found through `dataPointer`. A
field's address is then `cStructAddress(object) + offset` whatever the object
is, so writes reach the original, an array inside an element works
(`items.cells[0].tags[1]`), and a whole element is still a copy in and a copy
out. In the checker `cArrayContext` was set and then *cleared* by each array
access, so one inside another wiped the outer's and the outer was refused as an
array used whole; it is saved and restored.

**The symbol table never closed a scope.** `SymbolTable::Scope`'s destructor
was empty (the pop was commented out, "we should not destroy the symbol table
without outputting it"), so every name ever declared stayed visible to every
later block, method and class, and `contains` meant "was ever declared".
Scopes now have an `open` flag: the guard closes the innermost open one,
insert/lookup/contains see only open ones, and the table is still printed whole
at the end. Nothing in the suite had depended on the leak; a class scope
inserts inherited attributes explicitly. **With that, `x = expr` is an
assignment when every name is visible**: the checker no longer binds a new `x`
of the right-hand side's type (which made `a = o`, an Object into a variable
declared A, leave the checker believing `a` was an Object), it gives the
definition the variable's own type, and the generator's `coerce` does the
checking and the run-time downcast as it always did.

**`IO.allocated()` counts what something holds.** An object made in a method
sits on that method's pool until it returns, so `things = null` did not lower
the count there, and neither did the strings `out()` had just built;
measuring a leak meant a helper method and reading the count before printing.
`pool_held_objects` is a trial deletion (as a cycle collector does) that frees
nothing: it counts each pooled object down by its pool entries, and where that
reaches zero follows its references -- the RTTI's field offsets and a List's
items, exactly as `object_free` does -- counting each down by one. Everything
that reaches zero is what closing the pools would free; `allocated()` is
`gLiveObjects` minus that. A cycle never reaches zero, which is the point:
counting cannot free one and the number keeps saying so. It reads the pool and
the counts and writes nothing of the program's, and costs what the pools and
the freeable part hold, so it is for diagnostics.

Still true: `allocated()` read in an expression is of the objects then alive,
and a `finalize` that releases things is not simulated.

`link "SDL2"` names a library. The preprocessor removes the line, so there is
no grammar rule and no AST node; `catmintc` greps the sources for it, as it
already does for `using`, and turns each into a `-l`. `-l` and `-L` on the
command line work too, and `-lm` now starts that list rather than being
hardcoded, so `link "m"` does not make the linker warn.

**`finalize` is what makes the safe-wrapper pattern possible**, and the
wrapper is the reason the marking is worth having: a thin unsafe core inside
an ordinary class, so nothing downstream writes `unsafe`. Without it every
handle would leak or need releasing by hand. It is a **field in the RTTI, not
a virtual table slot** -- a slot would have had to go into `Object`, which
shifts every other built-in's numbering. The pointer is taken from the
finished virtual table, so inheritance and overriding are already worked out.
`object_free` calls it before anything is taken apart, with the count set to 1
for the duration so that a retain and release inside it -- an interpolated
string, a method call -- cannot re-enter and free twice.

`abstract def Int area` declares a method with no body that a subclass must
supply. It reuses the `interface_method` grammar rules, since a signature
with no body is exactly what those parse; the only difference is that this
one sits in a class next to fields and implemented methods. A class is
abstract when any entry in its finished virtual table still has no body,
which accounts for inheritance for free -- an override replaced the entry.
`new` on such a class is a semantic error naming the methods still missing;
*declaring* a variable of the type gives null, the same as an interface,
because both name what a value can do rather than what to build. The slot
still holds a real function, one that calls `__cm_runtimeError` and is
`unreachable` after it, because a separately compiled unit could have been
built against an older declaration. A body-less method is otherwise required
to return `Void`; an abstract one is the exception, which is the point of it.

`break` and `continue` leave the innermost loop and start its next
iteration. Neither takes a label. The branch is the easy part: what matters
is that they leave blocks the way a `return` leaves the function, and undo
the same four things on the way out -- the deferred expressions of every
block being left, the references its locals hold, the handler stack if a
`try` is being jumped out of, and every temporary pool opened inside the
loop. `LoopContext` records the depth of each of those at loop entry and
`emitLoopControl` unwinds down to it; a `continue` in a `for` goes to the
step block rather than the condition, or the counter would never advance,
and neither statement releases the `for` variable's own scope because the
end block does that for the ordinary exit and the break alike. Getting any
one of the four wrong leaks silently, which is why `45_break.cm` ends by
counting live objects.

`elif` chains a condition without nesting, and `else if` on a single line
lexes to the same token -- flex takes the longest match. `else` and `if` on
separate lines are still a nested if needing two `end`s, which is what every
program written before this does. The chain is right-recursive and each link
is an ordinary `IfStatement` with the rest as its else branch, so there is no
new AST node and neither the semantic pass nor the generator changed. The
three alternatives are told apart by the token after the block, so it adds no
conflict: the count stayed at 10 shift/reduce and 1 reduce/reduce.

`catmintc --asan` builds a program under AddressSanitizer. It instruments the
linked bitcode, which is the program *and* the runtime, since the runtime is
linked as IR rather than as an object -- so it covers reference counting,
where a release too many shows up as a use-after-free and as nothing at all
otherwise. All 45 tests are clean under it.

`spawn Class.method(n)` runs a static method on a thread and gives back a
handle; `Worker.wait(handle)` collects what it returned, and
`Worker.count()` says how many cores there are. The door is deliberately
narrow: the method must be static, take one number and return one, and the
semantic pass walks its body -- and transitively everything it calls --
refusing anything that makes an object, uses a string, reads a field,
throws, defers or dispatches on an object. That is `WorkerHazard` in
`SemanticAnalysis.cpp`, and it is what lets threads exist at all: a worker
provably never reaches a reference count, the temporary pool or the handler
stack, so none of those has to be locked and single-threaded programs pay
nothing. Widening the door means atomic counts on every assignment
everywhere; do not widen it casually.

`Process` is the other half of concurrency, and it is deliberately another
program rather than another thread: `Process.run(command)` waits for
one, `Process.start` and `Process.wait` begin several and collect them, and
an instance wraps a pipe with `open`, `readLine`, `write`, `eof` and
`finish`. Threads were considered and refused -- they would make every
reference count atomic, taxing every store in every program including the
single-threaded ones, and would need the temporary pool and the handler stack
to be per-thread, all to offer shared mutable memory to a language with no
ownership model. Processes share nothing, so none of that applies and the
feature is a hundred lines of `runtime.c`.

`File` and `Math` are built-in classes like `IO`, so they need no `using`.
`File` holds one `FILE *`; `open` answers 1 or 0 rather than aborting, and
`exists` and `remove` ignore the receiver because they are about a path.
`Math` has no state at all and exists because the language has no free
functions. `IO.args()` and `IO.arg(i)` reach the command line, which the
generated `main(argc, argv)` hands to `__cm_setArgs` before anything else
runs; `IO.err` writes to standard error and `IO.exit` sets the exit status.

The string primitives that need C live on `String`: `indexOf`, `trim`,
`upper`, `lower`, `split`, `replace`, `toFloat`, and `chr`, which is the one
string operation that cannot be written in catmint because there is no way to
build a character from a number. `chr`, like `File.exists`, ignores its
receiver; `lib/text.cmm` wraps it so a program writes `t.chr(65)` rather than
`"".chr(65)`, and adds the operations that are pure composition -- `join`,
`repeat`, `padLeft`, `padRight`, `startsWith`, `endsWith`, `words`.

A test may pass command-line arguments through `test_suite/<name>.args`, one
line, whitespace separated, alongside the existing `<name>.stdin`.

Not yet supported: slice vectors (they parse but have no deserializer, so they
abort in `ASTSerialization.cpp`), return-type inference (`auto` on a method
means `Void`), and lists and dictionaries.

`catmint-gen/ASTCodeGen.cpp.old` and `include/ASTCodeGen.h` are a superseded
earlier attempt, not built and not included by anything.

## Building on Linux

Verified, not assumed: a clean checkout builds and passes everything on
Ubuntu 24.04 against LLVM 18, in a container. Three things about that were
broken until it was tried, all of them invisible on macOS.

- **Every part of the build takes `LLVM_CONFIG`**, `catmint-ast` included.
  Its `GNUmakefile` used to hardcode the Homebrew path and fall back to a
  bare `llvm-config`, which distributions do not ship -- Ubuntu names it
  `llvm-config-18`.
- **`zlib1g-dev` and `libzstd-dev` are build dependencies on Debian and
  Ubuntu**, because `LLVMSupport` as they build it names `ZLIB::ZLIB` and
  `zstd::libzstd_shared` in its link interface. LLVMConfig.cmake defines
  those targets itself when the packages are there; when they are not, CMake
  fails inside `LLVMExports.cmake` with a message that never mentions a
  package. There is nothing to fix in our CMakeLists -- the failure happens
  inside `find_package(LLVM)` before any of our code runs, which was worth
  establishing, since the first guess was a missing `find_package(ZLIB)` and
  that turned out not to be it.
- ~~**The checked-in `runtime.ll` only reads on an LLVM close to the one that
  wrote it.**~~ **Replaced** by bitcode built with LLVM 16; see "The runtime
  ships prebuilt". Kept for the history: The IR text format is not stable across major versions;
  `captures(none)` replaced `nocapture` in LLVM 21. The file carries a stamp
  saying what wrote it and `build-runtime.sh` checks before falling back.

`./portability.sh` answers what can be answered without another machine:
object layouts agreeing on every target (asserted at compile time, nothing
runs), no target pinning in the checked-in runtime, and both it and a
generated program compiling for x86-64 and arm64, Linux and macOS.

**LeakSanitizer runs by default on Linux and not on macOS**, which is why
`./catmintc --asan` was quiet here and not there. It found two real things:
`emitProgramMain` allocated the `Main` object without `noteAllocation`, so
the pool erased itself and every program leaked one object at exit; and the
shallow freeing, which leaked a reference field on every instance that went
away. Both are fixed, all 51 tests are clean under ASan and LSan together,
and CI gates on it. **Run the suite on Linux after anything touching the
memory model** -- it is the only place a leak is visible at all.

## The sanitizer sweep

`./sanitize.sh` compiles and runs every code generation test under
AddressSanitizer, and on Linux under LeakSanitizer with it. Both CI jobs call
it; nothing is excused.

It is a script rather than a loop written out in the workflow, and that is the
point. The first version existed only inside `.github/workflows/ci.yml`, where
it could not be run locally, and it had two faults that only CI could show:

- **It ran from the repository root**, so a test's `.args` -- which `ctest.sh`
  reads relative to `catmint-gen` -- did not resolve. `33_wordcount` could not
  find its input, printed its usage and exited early without doing any work.
- **It captured a program's output without `|| true`.** An assignment from a
  command substitution *is* a simple command, so under `bash -e` the first
  test that exited non-zero ended the step. A test may exit non-zero on
  purpose, and a sanitizer finding always does, so the step died before
  anything could be reported: the failure was an exit code with no output.

Tests run in glob order, so the abort at `33_wordcount` meant 34 onwards never
ran at all -- the green tests above it were the only evidence there was.

**The macOS job had no sanitizer step**, which is why it stayed green through
a Linux failure. It has one now; LeakSanitizer does not exist on Darwin, so
that half checks only use-after-free and overflow.

**Check that this script can still fail.** Two `release()` calls on the same
object is a use-after-free it should report; if it does not, it is not
checking anything.

## Traps that have already cost time

Each of these produced a crash or a silent miscompile during development.

- **A built-in method's virtual table slot is fixed by `runtime.c`.** Its
  declaration order in `TypeTable::addBuiltinClasses` *is* that slot order.
  Append a new built-in method, never insert one: inserting renumbers the
  slots after it and every already-compiled caller then calls the wrong
  function. **Guarded now:** `42_builtin_slots.cm` calls every built-in
  method of every built-in class, so a renumbered slot is a failing test
  instead of a call to the wrong function.
- ~~**`Method` takes ownership of the `Attribute`s passed as its
  parameters.**~~ **Fixed.** `declare` and `declareStatic` in `TypeTable.cpp`
  allocate the parameters for each method, so no vector is ever shared. The
  double free that used to be possible cannot be written any more, and
  `addBuiltinClasses` went from 498 lines to 124.
- ~~**`TypeTable::isBuiltinClass` decides whether a class is checked as user
  code.**~~ **Fixed.** `Class::isBuiltin()` is set where the class is
  declared, and both `isBuiltinClass` and the generator's `collectClasses`
  read it. The two lists of names they each kept are gone. One list remains,
  `isGlobalTypeName` in the parser, and it has to: the built-ins are added by
  the type table long after the parser has finished.
- ~~**`TypeTable::getType(TreeNode *)` returns a freshly allocated `Type`
  for constants.**~~ **Fixed, and no longer true.** It returns the registered
  type, so every `Type` in the program is canonical and comparing by pointer
  is safe. The comparisons written by name still work and are still clearer.
- **`Builder.CreateGlobalString` takes the module from the current insert
  block.** Class metadata is emitted with no insert point set, so the module
  must be passed explicitly or it segfaults.
- ~~**Catching an exception by value slices it.**~~ **Fixed** in `main.cpp`,
  which catches by reference and exits non-zero. Kept here because it hid
  every code generation error for years and cost a day to find.
- **`%` binds less tightly than `/` and `*`, and this is settled.** It sits
  with `+` and `-` in `additive_expression`, so `a % b / c` means
  `a % (b / c)` and `a + b % c` means `(a + b) % c`. Every other C-like
  language puts `%` on one level with `*` and `/`. Catmint does not, and will
  not: changing it would silently change the meaning of every existing
  program that uses `%`, and the AST of `dispatch_logic_math.cm` with it.
  **Do not "fix" this.** Parenthesise instead, and say so in any code review
  and any documentation that touches arithmetic. It has caught three separate
  pieces of work so far -- a minute field in `lib/time.cmm`, and twice a
  benchmark -- so treat an unparenthesised `%` in a mixed expression as a bug
  in the program, not in the grammar.
- **The runtime and the program must be built by one toolchain.** ~~`catmintc`
  found `llvm-link` and `clang` through `LLVM_BIN`, while `build-runtime.sh`
  looked `clang` up on `PATH` by itself.~~ **Fixed:** `catmintc` exports
  `LLVM_BIN`, and `build-runtime.sh` derives its clang from `llvm-link` rather
  than from `PATH`. On a stock macOS shell the two used to disagree -- Apple
  clang's front end for the runtime, LLVM 22's back end for the program -- and
  Apple clang marks the two 4K-buffer functions `"probe-stack"="__chkstk_darwin"`,
  which LLVM 22's AArch64 back end refuses with `report_fatal_error`. Every
  program, `01_hello.cm` included, died with "Unsupported stack probing method"
  in a function nobody wrote. `strip_target` now removes `probe-stack`,
  `target-cpu` and `target-features`, so the checked-in `runtime.ll` no longer
  carries whichever clang produced it -- it used to say `"target-cpu"="apple-m1"`
  on all thirty functions while claiming to be portable.
- **`test.sh` puts the LLVM bin directory on `PATH` before it runs anything.**
  That is why the suite stayed green through the bug above: the harness
  repaired the environment the bug depended on. When something works under
  `./test.sh`, check it also works under a bare `./catmintc`.
- **A newline does not end a statement, and an expression continues across
  one.** `block : block expression | %empty` has no separator, so at every
  statement boundary bison must decide whether the next token continues the
  current expression or begins a new one, and it resolves every such case by
  shifting -- the longest expression wins. `Int c = a` followed by `- b` on
  the next line computes `a - b`; `twice` followed by `(x)` is a call. That
  accounts for all twelve shift/reduce conflicts, on `(`, `[`, `.`, `::`, `-`,
  `:` and IDENTIFIER, and `bison -Wcounterexamples` prints the derivations.
  Two of them came with `s.pad[i]`, subscripting a field: `a.b` followed by
  `[` on the next line now continues it. The only statement that begins
  with `[` is a bare list literal whose value is thrown away, so no program
  that means something changed meaning.
  Like the `%` precedence this is **settled, not open**: making newlines
  significant would change what existing programs mean. The one remaining
  reduce/reduce conflict is `type_name -> IDENTIFIER` against
  `rvalue_identifier_expression -> IDENTIFIER`, the declaration-versus-
  expression ambiguity, resolved in favour of the earlier rule.
- ~~**`wtest.sh` exited 0 with a test failing.**~~ **Fixed.** It printed its
  failures and exited 0, and `test.sh` trusted the status, so the parser
  suite printed nothing at all and the run still said "everything passed" --
  for as long as the float-literal fix had left `class_test.cm.ref` stale.
  `wtest.sh` now exits 1, and `test.sh` also requires the "All N tests
  passed" line. **When a section of `test.sh` prints nothing, it has not
  passed.**
- **String escapes are decoded in the lexer**, not by the AST's JSON round
  trip. They used to be decoded by accident, because JSON spells `\n` and
  `\t` the same way; a quote or a backslash then produced an AST file the
  compiler could not read back. The vendored rapidjson's escape table had also
  lost its backslash entry and wrote one raw, which is fixed in
  `catmint-ast/include/rapidjson/writer.h`.
- **A default initialiser must use the declared width.** `Int64 x` was
  being zeroed with an `i32` zero and then immediately with an `i64` one, to
  the same slot. Harmless for correctness, and it stopped LLVM vectorising a
  loop over `Int64`: the benchmark ran three times slower than C until the
  stray store went. Benchmarks find things tests cannot.
- **`ASTVisitor` walks into optional children.** A bare call has no object, a
  built-in method has no body, a return may carry nothing. `visit(Expression
  *)` returns true for null rather than falling through to its "unknown
  expression kind" assertion, which is what it used to do -- harmlessly,
  because every visitor in the tree overrode the nodes that have optional
  children, until one did not.
- **The grammar produces no `Assignment` node.** `x = expr` is always a
  `LocalDefinition` with the type `auto`; the generator decides between
  assignment and declaration by whether the name already resolves. This one
  is inherent: the parser cannot know which names exist.
- ~~**A comparison bound tighter than arithmetic**, so `a > b - c` was a
  syntax error.~~ **Fixed.** `PREC_REL` now sits below `and`/`or` and above
  the arithmetic operators. Unlike the `%` question this was safe to change:
  the affected expressions did not compile at all, so no program's meaning
  could move.
- ~~**A `Ptr` was counted wherever an LLVM `ptr` was.**~~ **Fixed.** A block's
  value and a method's result are kept alive by retaining them and handing
  them to the pool, and `emitBlock` and `emitCleanupAndReturn` asked whether
  the value was a reference by looking at its *LLVM* type -- which a `Ptr`
  shares. So `unsafe: h = SDL.CreateWindow(...) end`, whose value is a Ptr,
  retained and later released a pointer into memory C owns. `retain` adds one
  to the int at offset 8 only if it is positive; `release` takes one off
  whenever it is not zero, and frees at zero; a C struct with a pointer at
  offset 8 is negative half the time, so one program in two ended with a
  pointer decremented by one and `free` of an address that was never
  allocated, inside the library, after `main` had printed its last line. Tests
  49 and 50 hid it because the pointer was `malloc`'d scratch that nothing
  reads back. `yieldsPtr` now asks the catmint type; `57_ptr_uncounted` fills
  a C block with 0xFF (the negative case) and checks it is untouched. **Any new
  place that decides "is this value counted" must ask `isReferenceTypeName`,
  never `isPointerTy()`.** `Ptr == null` still compiles to `__cm_equals`,
  which is only safe because one side is null: two non-null Ptrs would have
  their first words read as type information.
- ~~**A class's initialiser was declared, then created again.**~~ **Fixed.**
  Constructing an attribute of class type calls `<Class>_init` before that
  class's own initialiser has been emitted, which declared it;
  `Function::Create` afterwards renamed the definition `<Class>_init.1` and
  left the declaration undefined, so a class with an attribute of a
  later-declared class did not link. `emitInitFunction` now reuses the
  declaration (`56_forward_attribute`).

## Documents

- `LANGUAGE.md` -- one brief entry per language feature, each pointing at the
  test that exercises it. The first thing to read, and the first thing to
  update when a feature changes.
- `COMPILING.md` -- how to build the compiler and a program, and the things
  about the language that surprise people.
- `ASSESSMENT.md` -- what works, what does not, what it would take, and the
  benchmarks against C and C++.

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
