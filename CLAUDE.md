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

`catmintc` compiles the linked bitcode at `-O2`, and `-O0` on its command
line turns that off. This is not a nicety: at `-O0` clang uses the fast
register allocator, which spills every value to the stack, and a counted loop
ran more than twice as slowly for it. Running LLVM's pass pipeline inside
`catmint-gen` as well was tried and made no measurable difference on top of
that, so the generator emits plain IR, which is also far easier to read when
working on it.

## The runtime, and why it needs a build step

`catmint-gen/runtime.c` is the object model and I/O library: `TObject`,
`TString`, `TIO`, `TList`, `TInteger`, `TFile`, `TMath`, the
`__catmint_rtti` type-info struct, `__catmint_new`, and the built-in methods. `build-runtime.sh` compiles it for the host into
`runtime.host.ll`, which is what programs link against.

`runtime.c` is the source of truth and `runtime.ll` is a checked-in copy of
what it compiles to, with the target triple, the data layout and the build
path stripped, so that one copy serves every 64-bit host -- the runtime uses
only pointers, `int`, `long long` and `double`, whose layouts agree
everywhere this compiler runs.

`build-runtime.sh` keeps the two honest. With a C compiler it compiles the
`.c` fresh, and refreshes the checked-in `.ll` whenever `runtime.c` is newer,
so the copy in the repository never falls behind the source that a
contributor with a compiler is editing. Without a C compiler it uses the
`.ll` as it stands and warns if it looks stale. **If you change `runtime.c`,
commit the regenerated `runtime.ll` with it** -- running the test suite will
have regenerated it for you.

That staleness is not a theoretical worry: the original `runtime.ll` was
committed without its source, built for x86_64 Linux, and drifted far enough
from the object model that using it would have been a silent miscompile
rather than a link error. Hence the refresh-on-build.

A C compiler is still needed to produce a *native executable*, because
`catmintc` ends by calling clang; what the checked-in IR removes is the need
for one to have a usable runtime, which is enough to run programs under
`lli`.

The layouts and the virtual table slot order in `runtime.c` are fixed by
agreement with `IRGenerator.cpp`; changing one without the other silently
miscompiles.

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
itself. The runtime's own checks go through `__cm_runtimeError`, which throws
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
variable's). `IO.allocated()` is the live object count, which is how test 31
proves a thousand-iteration loop returns to where it started.

Freeing is shallow: it returns what a built-in owns -- a String's characters,
a List's items, a File's handle -- but does not follow a user class's fields.
A structure held in fields is taken apart by assigning over them, which
releases what was there.

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
are seeded to match the order already fixed in `runtime.ll`, so `Object` holds
slots 0-2 and `IO` adds `input` and `out` at 3 and 4.

Dispatch loads the function pointer from the receiver's vtable, after a
`__cm_checkNull`. Static dispatch calls the implementation directly.

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

Namespaces: `using math as m` declares that module's classes as `m::Name`.
A qualified name is joined into a single `IDENTIFIER` by the lexer, because
letting the grammar see `IDENTIFIER :: IDENTIFIER` where a type is named is
ambiguous with static dispatch (`Program::run.execute(...)`), which begins
identically; the dispatch rule splits it apart again. In symbols `::` becomes
`$`, which cannot appear in a catmint identifier, so nothing can collide.

`catmint-gen -g` emits debug information: a `DISubprogram` per generated
function and a `DILocation` per expression, which is line numbers and nothing
else -- no types, no variables. Each class carries the file it was parsed
from, so a method spliced in from a module points at that module rather than
at the concatenated text. `catmintc -g` passes it through and then, on macOS,
runs `dsymutil`, because macOS leaves DWARF in the object file and records
only a debug map in the executable; compiling and linking in one command
would delete the object first, which is why `clang -g one.c -o one` also
produces an executable a debugger cannot read.

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

`Process` is the whole of catmint's concurrency, and it is deliberately
another program rather than another thread: `Process.run(command)` waits for
one, `Process.spawn` and `Process.wait` start several and collect them, and
an instance wraps a pipe with `start`, `readLine`, `write`, `eof` and
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
- **String escapes are decoded in the lexer**, not by the AST's JSON round
  trip. They used to be decoded by accident, because JSON spells `\n` and
  `\t` the same way; a quote or a backslash then produced an AST file the
  compiler could not read back. The vendored rapidjson's escape table had also
  lost its backslash entry and wrote one raw, which is fixed in
  `catmint-ast/include/rapidjson/writer.h`.
- **`ASTVisitor` walks into optional children.** A bare call has no object, a
  built-in method has no body, a return may carry nothing. `visit(Expression
  *)` returns true for null rather than falling through to its "unknown
  expression kind" assertion, which is what it used to do -- harmlessly,
  because every visitor in the tree overrode the nodes that have optional
  children, until one did not.
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
