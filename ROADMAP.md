# Roadmap

What is planned, in the order it is planned, and why each item is on the list.
`ASSESSMENT.md` says where the compiler stands today; this says where it is
going. An item leaves this file when it lands, and `LANGUAGE.md` gains an
entry for it.

The whole list is about 2,300 lines of compiler and 600 of test
infrastructure, against a 15,849-line compiler. It is deliberately not a
rewrite of anything.

---

## Phase 0 — verification, before the grammar is touched — **done**

All four landed, and `./test.sh --thorough` runs the three that are
repeatable. Findings are recorded below each item.

Everything in Phase 1 and Phase 2 edits the grammar or the code generator.
This phase builds the net first.

The reason is `break`. Look at what a `break` has to unwind before it
branches: the iteration's temporary pool, the deferred expressions of every
block it leaves, the scope releases for those blocks, and the `setjmp`
handler stack if it is leaving a `try`. Four mechanisms, and
`emitCleanupAndReturn` does all four only for the whole-function case. A
break path that forgets one leaks silently, and **no test here can currently
see it**: `31_memory.cm` counts live objects, but there is no loop with a
`break` in it to count.

| item | cost | what it catches |
|---|---|---|
| `bison -Wcounterexamples` | one command | the 10 shift/reduce and 1 reduce/reduce conflicts, as concrete inputs that parse two ways. Wanted *before* `else if` and `break` add rules |
| `-O0/1/2/3` and `--separate` sweep | ~40 lines of shell | optimiser-dependent bugs, the `makeLocalsVolatile` class. Behind `--thorough`, so the everyday suite stays fast |
| differential tester against C | ~250 lines of Python | **the one that finds miscompiles.** The same random program emitted twice, in catmint and in C, compiled and compared |
| libFuzzer harness on the parser | ~60 lines | crashes and leaks on malformed input |

The differential tester emits fully parenthesised arithmetic, so the
deliberate `%` precedence never shows up as a false difference. Once
`break` and `continue` exist it learns to emit them, and `31_memory.cm`
gains a loop that breaks out of, so the leak count covers that path.

**What it found.**

- The conflicts have **one** cause: `block : block expression` has no
  separator, so at every statement boundary bison decides whether the next
  token continues the expression or starts a new one, and resolves all ten by
  shifting. `Int c = a` then `- b` computes `a - b`; `twice` then `(x)` is a
  call. Confirmed by running both. Settled and documented, not fixed -- like
  the `%` precedence, changing it would silently change existing programs.
  One dead nonterminal (`new_dict`) was removed.
- **All 43 tests pass at -O0, -O1, -O2 and -O3**, and 36 of them also pass
  separately compiled. That guarantee did not exist before: the everyday run
  JITs one build.
- **200 random programs agree with C**, each checked at two optimisation
  levels. No disagreement found yet -- which is the expected result for
  arithmetic and control flow, and is the baseline the risky work will be
  measured against.
- **2,000 mutants found no crash** in the parser or in the semantic analyser.

The fuzzer runs a process per input rather than linking libFuzzer in, because
the grammar file defines `main` and an in-process harness would mean building
a second copy of the parser -- surgery on the most fragile part of the build
for throughput this does not need. `fuzz/fuzz.py --runs N` for a longer run.

## Phase 1 — ergonomics — **done**

All six items. `difftest/generate.py` learned `break` and `continue`;
`catmintc --asan` is new and all 47 tests are clean under it.

Friction found by writing `examples/mini.cm`, which is a 200-line
interpreter and the evidence that the language can carry a real program.

- ~~**`else if`**~~ **done: `elif`.** `else if` with one `end` turned out to
  be impossible in an end-terminated grammar -- after `KW_ELSE`, a lookahead
  of `KW_IF` cannot tell an empty `block` containing an if from a chained
  else-if, and the two differ only in how many `end`s arrive much later.
  Python, Ruby, Lua and sh all answer this with a dedicated keyword, so
  catmint has `elif`, plus `else if` on a *single line* as a lexer alias,
  which flex resolves by longest match. `else` and `if` on separate lines are
  unchanged. Right-recursive chain, each link an ordinary `IfStatement`, so no
  new AST node and no change to the semantic pass or the generator. Conflicts
  stayed at 10 and 1. `examples/mini.cm` lost three levels of nesting.
- ~~**`break` and `continue`**~~ **done.** `LoopContext` records the target
  block and the scope, pool and handler depths at loop entry;
  `emitLoopControl` unwinds down to them and branches. One AST node for both,
  since they are the same shape. A `break` outside a loop is a semantic error
  with a line number, and `defer break` was already a syntax error.
  `45_break.cm` covers break and continue in both loop kinds, nested, inside
  an `if`, inside a `try`, with a `defer` in the body, and ends by counting
  live objects -- which is what caught the one real problem, a measurement
  taken across `main`'s own pool.
  `difftest/generate.py` now emits both, and 250 random programs containing
  them agree with C. All 45 tests are clean under `catmintc --asan`, which is
  new: the documented manual ASan procedure is now a flag.
- ~~**Abstract methods on classes**~~ **done.** `abstract def` reuses the
  `interface_method` rules, since a body-less signature is what those already
  parse. A class is abstract when any entry in its finished virtual table has
  no body, which handles inheritance for free. `new` on one is a semantic
  error naming what is missing; *declaring* a variable of the type gives null,
  the same as an interface. `examples/mini.cm` lost its dummy `eval`.
- ~~**Return-type inference**~~ **done**, on the explicit-`return` rule; the
  whole suite stayed green, which is the evidence that nothing changed
  meaning. Reconciling two returns needed a **stricter** rule than the
  compiler's general convertibility test, which allows boxing in either
  direction: under it a method returning an `Int` and a `String` inferred
  `Int` and failed at run time, which is the error inference exists to
  prevent. `commonReturnType` allows only the same type, the wider of two
  integers, `Null` with a reference, or a class and its ancestor.
- ~~**Line numbers on semantic errors**~~ **done.** Six exception classes
  never passed a node. Five of the six most common errors -- unknown method,
  unknown variable, unknown type, field not found, bad override -- arrived
  with no line at all, and now all carry one.
- ~~**Character literals**~~ **nothing to do.** Measured: `"0".at(0)` folds to a
  compile-time constant at `-O2` -- a 20,000,000-iteration loop containing it
  optimised away entirely. This is a `LANGUAGE.md` note, not a language
  feature.

## Phase 2 — the foreign function interface — **done**

All seven pieces, in `49_ffi.cm` and `50_finalize.cm`. What the design
discussion below said would be built is what was built; three things are
worth recording that it did not anticipate.

**The RTTI gained a field and the virtual table moved from index 5.** As
predicted, `finalize` is a field rather than a slot, so nothing renumbered --
but the record's own layout changed, which `runtime.c` and the GEP in
`emitCall` both had to follow. All 50 tests, the `-O` sweep, the differential
tester and AddressSanitizer are what say it landed.

**A bare `return` is still not in the grammar.** `finalize` wanted one for an
early exit, and adding `| KW_RETURN` took the conflict count from 10
shift/reduce to **23** -- after the keyword, every token that could begin an
expression becomes a decision. They all resolve the same way, but thirteen
new places where a future rule can silently change the parse is a poor trade
for something `if`/`else` already expresses. The rule in `catmint.y` records
the measurement.

**A local declaration does not check its initialiser at all.** `Int n =
"hello"` compiles, and so does `Int n = someFloat`. Found while writing the
FFI's negative tests; older and wider than the FFI, so it is recorded in
`ASSESSMENT.md` rather than fixed here. Arguments *are* checked, which is the
boundary that matters for C.

## Phase 2 — the foreign function interface, as designed

The single thing that changes what the language can reach. Today nothing
outside `runtime.c` is callable, there is no `extern` of any kind, and
`catmintc` has no way to pass a library to the linker.

### The unsafe model

Rust is the reference, and what is copyable is the **marking discipline**,
not the borrow checker -- catmint has no lifetimes and is not growing any.

Rust's `unsafe` does not turn the compiler off; it enables five extra
abilities and leaves everything else checked. Catmint's enables exactly
**two**:

1. Calling an `extern` function.
2. Reading or writing through a `Ptr`.

Inside an `unsafe` block, objects are still null-checked, arrays are still
bounds-checked, references are still counted. That is the property worth
copying, because it makes `grep -rn unsafe` an audit rather than a gesture.

```
extern class SDL
  static def Int Init(Int flags)
  static def Ptr CreateWindow(String title, Int x, Int y, Int w, Int h, Int f)
  static def Void DestroyWindow(Ptr window)
end
link "SDL2"
```

Declaring is safe -- it is a signature. **Calling requires `unsafe`**, as in
Rust, because the declaration asserts a match with a C function the compiler
cannot see. The wrapper idiom then works unchanged: a thin unsafe core inside
a safe class, so nothing downstream writes `unsafe` at all.

```
class Window from Object
  Ptr handle

  constructor(String title, Int w, Int h):
    unsafe:
      handle = SDL.CreateWindow(title, 0, 0, w, h, 4)
    end
    if handle.isNull():
      throw "could not create window"
    end
  end

  def Void finalize:
    unsafe: SDL.DestroyWindow(handle) end
  end
end
```

Three rules hold it together:

- **`Ptr` is a value, not an object.** No RTTI, no reference count, no place
  in a `List`. Creating, passing and comparing one is safe; going through one
  is not. That is Rust's raw-pointer split. No implicit conversion to or from
  `Int` in either direction.
- **An extern signature is type-checked even though the C side is not.**
  Only `Int8`-`Int64`, `Float`, `Ptr`, `Void`, `Bytes`/`Ints`/`Floats`
  (passed as their data pointer) and `String` (in only, as a NUL-terminated
  `const char *`) may appear. An `Object`, a `List`, a user class or an
  interface there is a compile error rather than a crash.
- **`finalize`, because the wrapper above needs it.** `defer` covers a block
  scope, but an object holding a `Ptr` has no hook when its last reference
  goes, and freeing here is shallow. Without it every handle leaks or needs
  releasing by hand, and the safe-wrapper pattern -- the entire reason the
  marking is worth having -- does not exist. **Implement it as a `finalizer`
  field in the RTTI, not a vtable slot**: same shape as the `interfaces`
  field, and it renumbers nothing, which matters given how tightly the
  built-in slot order is pinned.

This is Rust's marking without Rust's proofs, and that should not be
oversold. A `Ptr` outliving what it points at is undetectable here. What the
language gains is that every such place is spelled `unsafe` and cannot be
reached by accident.

### The pieces

| piece | cost |
|---|---|
| `Ptr` value type | ~150 |
| `extern class`, mangling suppressed | ~120 |
| `unsafe` block and method flag | ~120 |
| `link` directive, `-l`/`-L` passthrough | ~40 |
| `finalize` through an RTTI field | ~60 |
| argument marshalling in `emitCall` | ~120 |
| `Bytes` to and from `String` and `File` | ~80 |

`catmintc` already greps `using` out of a source file, so `link "SDL2"` is
collected the same way and needs no new channel between the parser and the
driver. The `Bytes` bridge is on the existing list and FFI needs it: filling
a buffer from a file currently means reading a `String` and converting a
character at a time.

## Phase 3 — harden Linux — **done**

Not assumed: the whole suite was built and run on Linux, in a container, on a
different libc, object format and LLVM version (18 rather than 22). All 50
codegen tests and 11 parser tests pass there, at every `-O` level and
separately compiled, with the 50 differential seeds and 300 mutants alongside
them.

**Four things were wrong, and only Linux could show them.**

1. **`catmint-ast` ignored `LLVM_CONFIG`.** Its `GNUmakefile` hardcoded a
   Homebrew path and fell back to a bare `llvm-config`, which distributions
   do not ship -- Ubuntu names it `llvm-config-18`. The documented
   `make LLVM_CONFIG=...` therefore could not build the first of the three
   components, and the failure was a CMake error about `LLVMExports.cmake`
   that pointed nowhere near the cause.
2. **`zlib1g-dev` and `libzstd-dev` are undocumented build dependencies**
   on Debian and Ubuntu: `LLVMSupport` as they build it names `ZLIB::ZLIB`
   and `zstd::libzstd_shared` in its link interface, and CMake fails inside
   `LLVMExports.cmake` with a message that never mentions a package. The
   first guess was that our CMakeLists needed `find_package(ZLIB)`; testing
   it in a second container showed the build works without that and fails
   without the packages, so the fix is documentation, not code.
3. **The checked-in `runtime.ll` could not be read by LLVM 18.** The file
   whose entire purpose is to make a C compiler optional used
   `captures(none)`, which is LLVM 21 syntax, and older LLVM rejects it with
   "expected ')' at end of argument list" and no hint why. The IR text format
   is not stable across major versions, so the file now carries a stamp
   saying which LLVM wrote it, `build-runtime.sh` checks it can be read
   before falling back to it and says what to do when it cannot, and
   `portability.sh` reports the coupling instead of failing four times over.
4. **Every program leaked one object at exit.** `emitProgramMain` allocated
   the `Main` object without calling `noteAllocation`, so the pool around it
   erased itself as unused and never released it. Invisible on macOS, where
   LeakSanitizer does not run; obvious on Linux, where it does. Fixed, and it
   took the tests reporting leaks from 11 to 5.

`./portability.sh` is new and answers what can be answered without another
machine: that object layouts agree on every target (asserted at compile time,
so nothing runs), that the checked-in runtime is not pinned to one machine,
and that both it and a generated program compile for x86-64 and arm64, Linux
and macOS. `.github/workflows/ci.yml` replaces the CircleCI placeholder that
echoed "Hello, world" and built nothing.

## Phase 3 — harden Linux, as planned

Windows was considered and dropped: without FFI it buys a console
application, and with FFI the interesting part is the library binding, not
the platform. MSYS2/MinGW remains the cheap route if that changes; native
MSVC would cost the shell driver, the Makefiles and the flex/bison build, and
is only worth it if Windows becomes a first-class target.

- `.circleci/config.yml` currently echoes "Hello, world" and builds nothing.
  Replace it with CI that runs `test.sh`, ASan **and** UBSan, and the
  differential tester, on x86-64 Linux.
- **Whether any of this works on x86-64 is unverified.** The checked-in
  `runtime.ll` said `"target-cpu"="apple-m1"` on all thirty of its functions
  until commit `8e7ff21`. CI is how that claim stops being a guess.

## Phase 4 — leftovers — **done**

- ~~**Follow reference fields when freeing**~~ **done.** The run-time type
  information carries a list of reference-field byte offsets, ending in -1,
  which `object_free` walks with the count held at 1 so a field pointing back
  at the object cannot re-enter. Inherited fields come free, since a
  subclass's layout begins with its parent's. The vtable moved to index 6,
  the third time the record has grown.

  It was worth more than the exit-time leak that prompted it: the leak grows.
  Two hundred objects made and dropped in a loop left 400 behind before, and
  `examples/mini.cm` finishes with 70 objects alive where it used to hold
  131. **All 51 tests are now clean under AddressSanitizer and LeakSanitizer
  together on Linux**, down from 11 leaking, so CI gates on leaks rather than
  reporting them.
- ~~**A `Map` keyed by anything, not just String**~~ **done**, in
  `lib/map.cmm`, 164 lines of catmint and nothing in the compiler. A key is a
  String, an Int, or a class that `does Hashable`; the first two are answered
  for inside the Map, because a built-in class cannot be made to promise a
  user interface, and `is` is what lets it tell them apart at run time.
- ~~**Line numbers in runtime error messages under `-g`**~~ **done.**
  `setDebugLine` also stores to the runtime's `__cm_line`, and
  `__cm_runtimeError` puts it in the message. Nothing is emitted without
  `-g`, which `52_error_lines.check` asserts by grepping the IR both ways.

  Writing the test found something much worse than a missing line number: a
  **use-after-free on every throw whose value was computed**. What is thrown
  is usually built in the pool of the frame being abandoned -- `throw "a" +
  b`, or `__cm_runtimeError` building its message -- and the jump closed
  exactly those pools before the handler ran. It survived by luck when throw
  and catch were in one method, and corrupted the heap when they were not.
  `__cm_throw` now retains, unwinds, and hands the object to the handler's
  pool. `36_errors.cm` covers it.
- ~~**64-bit literal typing by context**~~ **considered and refused; a
  warning instead.** The flag on it was right, and the argument against
  turned out to be stronger than compatibility. Catmint's integer rules are
  documented as C's, and **C does exactly what catmint does now** -- `long x
  = a * b` with two `int`s is a 32-bit multiply. Widening would make the
  language differ from the reference its own differential tester compares it
  against, so the tester would have to be taught that catmint is no longer
  like C, which is a bad trade for closing one footgun.

  The footgun is closed by saying something instead: `Int64 x = a * b` with
  two `Int`s now warns, with the line, and the arithmetic is untouched. Only
  the operators that can carry past their width -- `+ - * ** <<` -- and only
  where the result is actually widened, so nothing in `lib/` or `examples/`
  warns, which `54_width_warning.check` asserts.

  Writing it found that **`catmintc` never showed warnings at all**: the
  compiler's standard error was kept in a log and printed only when the build
  failed, so a diagnostic from a successful compile was invisible.

## Phase 5 — C structs, a prebuilt runtime, LLVM-only builds — **done**

All five parts, with the design below built as written. A user's path is now
catmint-parser, catmint-gen, llvm-link, opt, llc and lld: `catmintc` was run
with an LLVM directory containing no clang, on macOS and in the Linux
container, and built working programs. SDL is in the standard library with no
C anywhere: `lib/sdl2.cmm` generated from SDL's headers, `lib/sdl.cmm` the
safe layer, and the game that found all this uses it with no `unsafe` of its
own. Worth recording:

- **Every one of SDL's 80 records laid out by catmint's rule matched clang**:
  the generated bindings assert each size and offset, and they compile. The
  layout rule was not tuned to make that happen.
- **One `runtime.ll` had never served every host.** Built on macOS it calls
  Darwin's `\01_fputs` and `__maskrune`; it only ever worked on Linux because
  `build-runtime.sh` quietly recompiled `runtime.c` there. Hence one bitcode
  file per OS, each built by LLVM 16 and read by 22.
- **The parser suite had been failing silently.** `wtest.sh` exited 0 with a
  test failing -- the float-literal fix had left one reference stale -- and
  `test.sh` printed an empty section and said "everything passed".
- **The portability check passed while checking nothing**, grepping a
  `runtime.ll` that had been deleted. It now fails on a missing runtime.
- **Swapping clang for opt, llc and lld cost nothing**: `bench/run.sh` was the
  same or faster, once llc was told the CPU clang had assumed (`apple-m1`).
- **The game's polygon fill, ported from the C shim to catmint, drew a
  byte-identical frame.**
- Still open: `String.chr(0)` gives an empty String rather than one holding
  a NUL. Found writing the NUL-refusal test; a runtime fix, which means
  rebuilding both runtimes, so it waits for the next runtime change.

## Phase 5 — as designed

Found by writing a real program against a real C library: an SDL2 game
(`examples/rps-rts`). Everything the FFI could not say had to be said in a C
shim instead, and the first attempt to put that binding in `lib/` made
`catmintc` compile a module's C source on every build. That was the wrong
answer, and it set the rule this phase is built on:

**A user of catmint needs LLVM and nothing else: no C source ships, and no C
compiler runs.** Clang, and the C in `runtime.c`, are for people working on
catmint. Anything a binding needs that the FFI cannot express is a gap in the
FFI, fixed once in the language, not worked around per library.

### What the shim was covering for

| C needs | example | answer here |
|---|---|---|
| a struct passed by pointer | `SDL_RenderFillRect(r, const SDL_Rect *)` | `extern struct` |
| a union C fills in | `SDL_PollEvent(SDL_Event *)` | `extern union` |
| an out-parameter | `SDL_GetRendererOutputSize(r, int *, int *)` | a one-field struct passed as `Ptr` |
| fields read through a C pointer | `surface->pixels` | a *view*: `SDL_Surface.at(p)` |
| a struct built for C | `SDL_PushEvent(SDL_Event *)` | `extern union` |
| unsigned types | `Uint8`, `Uint32` | `UInt8`..`UInt64`, at the boundary |
| macros, which are not symbols | `SDL_SaveBMP`, `SDL_WINDOWPOS_CENTERED` | call the real function; constants generated |

### A. Two toolchains

- **Users:** `catmint-parser`, `catmint-gen`, and LLVM's own tools:
  `llvm-link`, `opt`, `llc`, and `lld` (`ld64.lld` on macOS, `ld.lld` on
  Linux). `catmintc` never runs clang. It still needs what every native
  program links against -- libSystem through the macOS SDK, glibc's startup
  objects on Linux -- which belong to the operating system, not to a compiler.
- **Developers:** clang as well, to rebuild the runtime from `runtime.c`,
  to run the binding generator, and for `--asan`, whose run-time library ships
  with clang. `catmintc --asan` without clang says so and stops.

The link line has to carry what clang's driver used to add silently, and some
of that is security: **position-independent executables everywhere**
(`llc --relocation-model=pic`, `-pie` with `Scrt1.o` on Linux; arm64 macOS
requires it anyway), and on Linux `-z relro -z now -z noexecstack`. Dropping
the compiler driver must not drop the hardening it supplied.

### B. The runtime ships prebuilt, as bitcode, one file per operating system

`catmint-gen/runtime-darwin.bc` and `catmint-gen/runtime-linux.bc` replace
`runtime.ll`, and `catmintc` links whichever matches the host. Three reasons:

- **Bitcode, not text IR.** Textual IR changes between LLVM major versions --
  `captures(none)` is why LLVM 18 could not read the old `runtime.ll`. Newer
  LLVM reads older bitcode by policy, so a runtime written by the oldest LLVM
  we support is read by every newer one.
- **One per OS, not one.** The C library's headers are not neutral: the
  macOS-built IR calls `\01_fputs` and `\01_fopen` (Darwin's symbol aliases),
  `__maskrune` and `__tolower` (its ctype), and `stdin`/`stderr` are macros
  that name different globals on glibc. The old claim that one `runtime.ll`
  served every host held only because `build-runtime.sh` quietly recompiled
  `runtime.c` wherever there was a C compiler. ~~Within an OS the IR does not
  depend on the architecture, which `portability.sh` keeps checking.~~ **That
  was wrong, and CI found it**: the file differs between architectures (the
  optimiser's choices, alignment, and `char`'s signedness) and `portability.sh`
  only checked that it compiled for both. See Phase 6, "The runtime, per OS and
  per architecture".
- **An ABI stamp.** The runtime and the generator agree on object layouts and
  virtual table slots by convention, and a disagreement is a silent
  miscompile. The runtime now defines `__catmint_abi_N`, generated code lists
  it in `llvm.used`, and N changes whenever `runtime.c` and `IRGenerator.cpp`
  change what they agree on -- so a runtime from another compiler version
  fails to link instead of calling the wrong slot.

`build-runtime.sh` becomes a developer tool and nothing in the user's path
calls it. `test.sh` runs it, so the suite always tests the runtime being
edited. `build-runtime.sh --check` rebuilds into a temporary file and fails
if the result differs from the committed one: a binary nobody reads has to be
shown to come from the source everybody reads.

### C. C structs and unions

```
extern struct SDL_Rect @ 16
  Int32 x @ 0
  Int32 y @ 4
  Int32 w @ 8
  Int32 h @ 12
end

extern union SDL_Event @ 56
  UInt32 type @ 0
  SDL_KeyboardEvent key @ 0
  SDL_MouseButtonEvent button @ 0
  UInt8 padding[56] @ 0
end

extern struct SDL_Window            # opaque: no fields, no size
end
```

**Layout is the declaration's, computed by the compiler** with C's rule for
the targets catmint supports (natural alignment on LP64 -- the same on
x86-64 and arm64, Linux and macOS): each field at the next offset aligned to
its own alignment, the whole padded to the largest. A union puts every field
at 0. Fields may be the fixed-width numbers, `Float32`, `Float`, `Ptr`,
another extern struct or union by value, or a fixed array of any of those.
`@ n` after the name asserts the size and after a field asserts its offset;
both are checked at compile time, so a declaration that disagrees with the
real layout is an error, not corrupted memory. The generator below writes
every assertion from clang's own layout, so a disagreement between catmint's
rule and the C compiler's is caught where the binding is made.

**Two kinds of instance, one type.** An instance is a counted catmint object
whose payload is the C bytes:

- *owned* -- `new SDL_Rect()`, or declaring `SDL_Rect r` -- holds its bytes
  inline, zeroed; its fields are safe to read and write, and it is freed like
  any object. There is never a count inside the C bytes.
- a *view* -- what an extern function returning `SDL_Surface` gives back, or
  `SDL_Surface.at(somePtr)` -- points at memory C owns. Making one needs
  `unsafe`, because that is where the promise "this pointer is valid, and
  stays valid while I use it" is made; after that its fields read and write
  like any other. A view never frees what it points at. A null pointer gives
  `null`, not a view.

This is Rust's split between a `#[repr(C)]` value and `&*raw_pointer`, with
one difference forced by catmint having no stack values: the owned bytes live
in a counted object, and what C receives is a pointer into it.

**Using them.** `ev.key.keysym.sym` is one offset computed at compile time.
A nested struct used whole is copied, as C assigns structs: `SDL_Rect r =
box.rect`. An array field is indexed as `s.pad[i]`, bounds-checked. A
parameter of struct type in an extern function receives a pointer to the
bytes, and accepts `null`, because C APIs use NULL to mean "none". A `Ptr`
parameter accepts an extern struct or one of the three arrays, which is how an
out-parameter is written: declare a one-field struct, pass it, read the field.
Reading a union's fields is not `unsafe`, unlike Rust: a union here holds only
numbers and `Ptr`s, every bit pattern of which is a valid value, and a `Ptr`
read from one is still opaque until something else in `unsafe` uses it.

**C's integer types, at the boundary only.** `UInt8`, `UInt16`, `UInt32` and
`UInt64` may appear in extern declarations and nowhere else. A value read
from one becomes the smallest catmint integer that holds every value it can
have -- `UInt8` and `UInt16` an `Int`, `UInt32` an `Int64` -- and `UInt64` an
`Int64` holding the same bits. Full unsigned arithmetic is a type-system
project of its own; this is the part that stops `255` reading as `-1`.

**What the boundary refuses:**
- a `Float` passed where C takes an integer: a compile error in an extern
  call, where it is almost always a mistake, though ordinary catmint code still
  converts implicitly;
- a String containing a NUL, at run time and catchably -- C would see it
  truncated, and a path that is not the path it looks like is a classic hole;
- a struct passed or returned by value, a variadic function, a callback, a
  bitfield, `long double`, and alignment above 8. Each is refused with an error
  naming it rather than half supported. Callbacks in particular stay out:
  C calling catmint from its own thread would race the reference counts, the
  reason threads were refused.

### D. `tools/bindgen.py` -- bindings from the real headers

A developer tool, as Rust's `bindgen` is: it needs clang, the output is
committed, users never run it.

```
tools/bindgen.py SDL2/SDL.h --match '^SDL_' --from SDL2/ \
    --class SDL2 --constants SDL2C -I /opt/homebrew/include > lib/sdl2.cmm
```

It reads the declarations from clang's JSON AST, the layouts from
`-fdump-record-layouts-complete` (clang's own offsets, not a reimplementation),
and integer macros from `-dM -E`, whose values it has clang evaluate. It
writes `extern struct`/`extern union` with every size and offset asserted,
one `extern class` of functions, and a class of constants as static methods.
Whatever it cannot bind -- the cases the boundary refuses -- it lists in a
comment rather than dropping in silence. Its test binds a small header of its
own and checks, against a C library built from the same header, that catmint
reads and writes every field where C does.

### E. SDL in the standard library, with no C

`lib/sdl2.cmm` is generated (Rust's `sdl2-sys`); `lib/sdl.cmm` is the safe
layer written by hand on top of it (Rust's `sdl2`): `Sdl`, `Window`,
`Renderer`, input, and `finalize` releasing each handle. The game's
`sdl_shim.c` is deleted, its polygon fill becomes catmint, and its two test
suites (`check.sh`, `play.sh`) are what say the move changed nothing.

### Security, all in one place

1. **A wrong layout corrupts memory.** Checked: sizes and offsets asserted at
   compile time, and generated from the real headers.
2. **C memory must never be counted.** A view has no count inside C's bytes and
   never frees them; test 57 is what happens otherwise.
3. **Lifetime past the call.** A pointer into a catmint object is valid for the
   call it is passed to. A C API that keeps it needs the object kept alive by
   the program -- stored in a field -- and the documentation says so. A
   temporary dies when its statement's pool closes.
4. **A view is a promise.** `unsafe` is where it is made. A view outliving its
   C object is undetectable, as it is in Rust.
5. **Strings are input only** and refused if they contain a NUL; string
   literals are shared static objects, and C writing into one would change it
   everywhere.
6. **No silent Float-to-integer conversion at the boundary**, and sizes are
   `UInt64`, not a truncating `Int`.
7. **No callbacks**, so C never runs catmint code on a thread of its own.
8. **`unsafe` still means two things**: calling out, and turning a `Ptr` into
   something -- now including a view. `grep -rn unsafe` stays the audit.
9. **The prebuilt runtime is reproducible** (`build-runtime.sh --check`) and
   **stamped** against version skew.
10. **The executable keeps its hardening** (PIE, RELRO, a non-executable
    stack) without a compiler driver to supply it.
11. **Building runs nothing.** No C is compiled on a user's machine, so no
    stray `.c` beside a module is ever built, and no compiler flag from the
    environment can load a plugin into the build.

### Order, and what proves each step

| step | proved by |
|---|---|
| ABI stamp, per-OS bitcode runtime, developer-only rebuild | suite passes on the committed runtime; `--check` reproduces it; a stale runtime fails to link |
| `catmintc` on LLVM tools only | suite and examples with clang removed from `LLVM_BIN`; `bench/run.sh` unchanged; Linux in a container |
| `extern struct`/`union`, views, arrays, assertions | new codegen tests against libc (`memset`, `gmtime_r`, `frexp`), negative tests for every refusal |
| boundary types and checks | tests for `UInt8` 255, NUL refusal, the Float error |
| `tools/bindgen.py` | its own test header, bound and checked against a C build of it |
| SDL in `lib/`, shim deleted | the game's `check.sh` and `play.sh` unchanged |

### Considered and not done

- **Parsing C headers in the compiler**, as Zig and Swift do: a C front end
  in the user's path, which is the thing this phase removes.
- **Rust 2024's `unsafe extern`**, which moves the unsafety to the
  declaration and lets a pointer-free function be declared safe. Worth
  revisiting; it changes what existing programs must write, so not here.
- **Full unsigned arithmetic.** Only the boundary needs it now.

## Phase 6 — callbacks, Windows, and a GUI application, as designed

Not started. The order is the order they depend on each other: a GUI wants
text and textures, a Windows build wants to be tested by something real, and
callbacks are the one FFI feature everything after this phase would otherwise
work around. Phase 7 is the game, Phase 8 the compiler; both below.

### Found while checking this plan

Each of these was run, not assumed, and each changes something below.

1. **The shipped runtime is not neutral across architectures, and CI proved
   it.** `build-runtime.sh --check` passed in an arm64 Linux container and
   failed on GitHub's x86-64 runner: a global array is `align 16` where x86-64
   builds it and `align 8` where aarch64 does. Phase 5 said the file was
   "architecture-neutral within one OS"; `portability.sh` only checked that it
   *compiles* for both, which is a weaker thing. See "The runtime, per OS and
   per architecture" below.
2. **There is no way to read text C hands back.** `SDL_GetError`, `getenv`,
   `strerror` and `gai_strerror` return a `Ptr`, and a `Ptr` converts to
   nothing. `lib/sdl.cmm` throws "could not create window" without SDL's own
   reason because it cannot read it. Strings are input-only by design
   (Phase 5, rule 5); that rule is about C writing into one, and says nothing
   against copying one out.
3. **A literal `NULL` cannot be passed for an optional C string.** A `String`
   argument that is null is refused at run time, correctly for an accident
   and wrongly for `SDL_OpenAudioDevice(NULL, ...)`, where NULL means "the
   default". Found by passing it.
4. **`bindgen.py` took only `SDL_*` constants**, so `AUDIO_S16LSB` and the
   other unprefixed ones were never bound. The SDL command needs a second
   pattern, and the generator needs to say how many names a pattern matched
   so a missing prefix is visible.
5. **`bindgen.py` assumes LP64.** It maps `long` to `Int64`. On Windows `long`
   is 32 bits. Layouts come from clang and are right on any target; the
   scalar table is the part that is not.
6. **Non-blocking sockets need `fcntl` or `ioctl`, both variadic, which
   Phase 5 refuses.** On macOS there is no other way to set the flag (Linux
   has `SOCK_NONBLOCK`; macOS does not). Variadic functions on Apple's arm64
   ABI take their variable arguments on the stack, so declaring `fcntl` as if
   it had a fixed third parameter is wrong there, not merely untidy.
7. **`IO.entropy()` returns an `Int`: 32 bits.** Fine for seeding a game, not
   for a session token.
8. **`Process.run` and `Process.start` go through `/bin/sh -c`.** An editor
   that runs `catmintc <the file you opened>` is injectable by a file name
   such as `a;rm -rf ~`.
9. **The game's tests never ran in CI**, and need not be skipped there: with
   `SDL_VIDEODRIVER=dummy SDL_RENDER_DRIVER=software` all 17 input tests and
   `check.sh` pass with no window system. SDL's `disk` audio driver
   (`SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE=f.raw`) records what a program
   queues, converted to signed 16-bit stereo at 44.1 kHz whatever was asked
   for, so sound can be tested too.

Status: item 1 is fixed (below). Items 2 to 9 are fixed on the `ffi-edges`
branch, in section B, except the game's tests running on the *Windows* runner,
which waits for the Windows build.

### The runtime, per OS and per architecture

**Fixed on `master`**, and recorded here because the design claimed otherwise.

What was wrong. The Linux file had been built in an arm64 container and
checked there, and the first x86-64 build disagreed with it in 721 lines.
Taking the optimiser out of the comparison left about 75, and they fall into
three kinds:

- **Optimiser decisions**, which `clang -O2` bakes into the IR from its
  target's cost model: a loop unrolled by two on x86-64 and not on aarch64,
  and the rest of that 721.
- **ABI choices made by the front end**: arrays of 16 bytes or more are
  `align 16` on x86-64 and `align 8` on aarch64; `uwtable` is asynchronous on
  one and synchronous on the other; `jmp_buf` has a different shape; each
  target has its own default function attributes (`frame-pointer`,
  `min-legal-vector-width`).
- **One difference in meaning**: plain `char` is unsigned on aarch64 Linux and
  signed on x86-64, so five runtime functions (`toInt`, `toFloat` and the three
  `readLine`s) loaded a byte with `zext` where the macOS file and x86-64 have
  `sext`. In every use today the byte is compared with an ASCII character, so
  no behaviour changed; nothing guaranteed that it would stay so.

The fix, `17e2b2c`: the runtime ships as the front end's output with the
optimiser disabled (`-O2 -Xclang -disable-llvm-passes`, not `-O0`, which adds
`optnone`) and `-fsigned-char`, and the single `opt -O2 -mtriple=<host>` in
`catmintc`, which already runs over the whole linked program, does the
optimising for the machine that runs it. `bench/run.sh` is unchanged, within
noise on all five benchmarks. The committed file for each OS has a canonical
builder (x86-64 on Linux, which is the CI runner; arm64 on macOS), and
`build-runtime.sh` refuses to write it anywhere else.
`portability.sh` now checks the claim it used to merely assert: with alignment
hints, `uwtable` flavour, `jmp_buf`'s type and the target-default attributes
normalised away, every instruction and module flag must be identical between
architectures. On macOS it builds both by target; on an aarch64 Linux host it
compares against the committed x86-64 file; where it cannot check, it says so.
It was shown to fail by removing `-fsigned-char`.

How it was found, and what the first attempt got wrong: the check failed on
GitHub and could not be reproduced locally, since job logs need a sign-in. The
first fix (removing the compiler's `!llvm.ident` string, which a differently
packaged clang-16 would also have changed) was a real improvement and did not
fix it. The second change made `--check` print the diff as a GitHub annotation,
which the API serves without a sign-in, and the annotation named the line.
Worth keeping: **a check that can only fail somewhere you cannot see should
say why in a place you can**.

Still to do: an aarch64 Linux job in CI (`ubuntu-24.04-arm`), so the Linux file
is run, not only compared, on both architectures on every push; locally the
arm64 container does that today.

### A. Callbacks — **done**, on the `callbacks` branch

Built as designed below, with these departures, each for a reason found while
building it:

- **No `callback` keyword, no `extern callback`.** `callback` is a field and a
  parameter name all through the generated `sdl2.cmm` and the obvious name of a
  variable; reserving it would have broken those and invited more. The type is
  declared `extern def Compare(Ptr left, Ptr right) Int` (existing keywords,
  reads like a C typedef), and a method is passed by *naming* it,
  `Libc.qsort(buf, n, 8, Order.ascending)`, which the parser already reads as a
  field access on a class name. No new token, no new AST node, and the grammar's
  conflict count did not move (12 and 1). `&Order.ascending` was considered and
  would have added a conflict.
- **The foreign-thread kind stays deferred, as planned, and the generator
  steers around it.** `bindgen --foreign-thread REGEX` keeps a function-pointer
  type a `Ptr` when the library calls it from threads of its own, and says so;
  SDL's audio, timer, thread, event-filter, log and allocator types are listed
  that way. Without that, the generated bindings would have invited a program to
  pass a method that stops it the first time SDL calls it from SDL's thread.
- **Handles are guarded too.** `Handles.get` needs `unsafe` (it turns a Ptr into
  an object, though it validates what it is given), and every `Handles` call
  checks the thread, so the table cannot be reached from a foreign thread even
  by code that is not a callback.
- **Three things the work turned up were fixed afterwards** (tests 73 to 75,
  details in `CLAUDE.md`): a write through an element of an array of structs
  went to a copy and was lost silently; assigning an `Object` to a
  subclass-typed variable retyped it, because the symbol table never closed a
  scope and so could not tell an assignment from a declaration; and
  `allocated()` counted objects only a pool was holding. Fixing the second
  meant fixing the scoping underneath it.

What proved it, each with a mutation that made it fail: the skip after an error
(the method ran 6 times instead of 3 without it), the thread refusal, unsigned
widening (`4000000000` read as negative with a sign extension), and the table's
own reference. One test was wrong in a way worth recording: the first version
counted calls through `getenv`/`setenv` and passed with the skip *removed*,
because every extern call, including one inside a callback body, rethrows a
pending error, so the body died at its first one. The test now counts through a
handle, with no extern call in any comparator.


#### What rule 7 says, and what it should say

Phase 5, rule 7: *No callbacks, so C never runs catmint code on a thread of its
own.* The reason given with it: C calling catmint from its own thread would
race the reference counts, which is why threads were refused.

That reasoning is sound for a thread C made. It is not a reason to refuse a
callback that C makes on **the thread that called it**, which is every
callback in `qsort`, `bsearch`, and a GUI toolkit's event dispatch (GTK's main
loop calls your handler from inside `g_application_run`, which you called).
Such a call arrives with the program stopped at an ordinary call boundary,
the pool and handler stacks consistent, no other thread touching anything.
The rule bundled two cases and refused both. The hazards of the second are
different and smaller:

| callback runs | what could go wrong | what stops it |
|---|---|---|
| on a thread C created (audio, timers, thread pools) | races the counts, the pool, the handler stack | refused unless the body provably touches none of them |
| on the calling thread, inside the call | a `throw` leaving through C's frames; C holding a pointer to something catmint freed | catch at the boundary; hand C a handle, never an address |
| in a signal handler | catmint code running at an arbitrary instruction | the APIs that do it are refused by name |

#### How Rust does it, and what is taken from it

- **A function pointer is a type in the signature**, `Option<unsafe extern
  "C" fn(*mut c_void, c_int) -> c_int>`, and an `extern "C" fn` item is an
  ordinary function with the C calling convention. Making one is safe;
  calling one is `unsafe`. *Taken:* a callback type is declared once, from the
  C typedef (`bindgen` writes it), and a static method is checked against it.
- **The `void *userdata` pair.** C APIs take `(callback, userdata)`. The
  idiom is a generic trampoline, `extern "C" fn tramp<F: FnMut()>(data: *mut
  c_void)`, that casts `data` back to `&mut F`; the closure is boxed and the
  box owned by a safe wrapper. *Taken:* the trampoline, written by the
  compiler as LLVM IR with the C ABI (no C anywhere), and the wrapper that
  owns the state. *Not taken:* the raw pointer. Go's `cgo.Handle` is the
  better idea: C holds a small integer that indexes a table; a stale integer
  finds an empty slot and does nothing, where a stale pointer is a
  use-after-free. A catmint object cannot be handed to C by address in any
  case, since a reference count lives in its first words.
- **Panics must not cross C.** Unwinding a Rust panic through C frames was
  undefined, and since Rust 1.81 an `extern "C"` function that unwinds
  aborts; `extern "C-unwind"` opts in. Wrappers use `catch_unwind` at the
  boundary and `resume_unwind` after C returns. *Taken, exactly:* catmint's
  `throw` is `longjmp`, and a `longjmp` through C's frames skips whatever C
  needed to do on the way out (undefined by the C standard when it skips a
  `qsort`'s internals). The trampoline installs its own handler, records the
  error, returns a default value, and the extern call that started it rethrows
  once C has returned. After the first error the trampoline stops running the
  body, so C's remaining calls are no-ops rather than catmint code running in a
  state nobody has reasoned about.
- **`Send` and `'static`.** Rust refuses a closure that is not `Send` where C
  may run it on another thread, and one that borrows locals where C may keep it
  after the call. `Rc`, with its non-atomic count, is `!Send`; `Arc` is atomic.
  This is catmint's own choice (single-threaded counts), and Rust enforces it
  with types where catmint has none. *Taken:* the worker checker is the
  equivalent of `Send` (see "Considered": a detached kind), and a runtime
  thread test stands in for the types.
- **GUI toolkits.** gtk-rs asserts at run time that widgets are touched on the
  main thread, and its types are `!Send`. winit and egui avoid callbacks:
  `event_loop.run(|event, ...| ...)` calls your closure synchronously on the
  main thread. *Taken:* the run-time main-thread assertion.
- **The `sdl2` crate's audio** takes a callback type that must be `Send`, owned
  by the `AudioDevice`; closing the device, which joins SDL's audio thread,
  happens in `Drop` before the callback is freed. *Taken:* that order, which is what
  `finalize` already gives the wrappers in `lib/sdl.cmm` (renderer, then
  window, then SDL). Unregister, wait, then let go.

#### The design

One kind of callback now, the one with a safe story; the other designed and
deferred until something needs it.

**A synchronous callback.** Declared from the C typedef:

```
extern callback Compare(Ptr a, Ptr b) Int          # typedef int (*)(const void *, const void *)
extern class Libc
  def Void qsort(Ptr base, UInt64 count, UInt64 size, Compare order)
end
```

and passed by naming a static method, `Libc.qsort(buf, n, 4, callback
Sorter.order)`. (The spelling is not settled; nothing below depends on it.) The
compiler checks the method is static and that its parameters and result are
exactly the callback type's, under the boundary types of Phase 5. The body is
ordinary catmint: objects, strings, calls, everything.

For each use the compiler emits a function with the C signature. It converts
the arguments to the catmint types, opens a pool, runs the body inside its own
handler, and converts the result back. On entry it checks that it is on the
thread the program started on, and aborts with a message if it is not:
**the binding author's claim is verified, not trusted**, so a callback wrongly
declared synchronous that C then calls from a thread of its own fails cleanly
instead of racing. A thread test cannot see a signal handler; that case is
closed by refusing the APIs (rule 5 below).

**State goes through a handle.** `Handles.make(object)` returns a `Ptr` that is
an index into a table in the runtime, which holds a counted reference.
`Handles.get(ptr)` answers the object, or null if it was dropped;
`Handles.drop(ptr)` lets go. C stores and returns the `Ptr`; it never holds an
address inside anything catmint counts. A wrapper in `lib/` makes the handle in
its constructor, registers it, and in `finalize` unregisters with C first,
waits for C to confirm, and only then drops the handle.

**Deferred: a detached callback**, for C that calls from its own thread: SDL's
audio callback, `SDL_AddTimer`. Its body would be held to the worker
checker's rules (numbers and `Ptr` only; nothing counted is made, read or
reached) plus raw loads and stores through a `Ptr` (a small `Mem` class: `Mem.storeInt16(p,
offset, v)` and its kin, `unsafe`-only), since an audio callback has to write
samples. Nothing in Phases 6 or 7 needs it: SDL's `SDL_QueueAudio` is the push
model, timers are polled, sockets are polled. It is built when something
cannot go without it, and until then the thread test above is what a foreign
thread meets.

#### Does the GUI application need this?

Not the one chosen below. An immediate-mode toolkit drawn with SDL polls for
events and calls nothing back: `if ui.button("Run"):` is a condition, not a
handler. Callbacks matter for **native** toolkits (GTK4's signals, Win32's
`WndProc`), for `qsort`-style APIs, and for libraries that report progress or
results through one. They are in this phase because they are the feature the
FFI is missing, because they are cheap to do correctly now that `finalize`,
handles-by-index and the boundary types exist, and because the first
non-immediate toolkit, GTK4 on Linux, becomes a binding project instead of a
language project. They are not on the path to the editor.

#### Security, callbacks

1. **Only on the calling thread, and checked.** The trampoline compares thread
   identity on entry and aborts. Counts, pools and handler stacks are global
   and non-atomic; this is what keeps them that way.
2. **No `longjmp` through C.** The trampoline catches; the call that started it
   rethrows afterwards.
3. **No addresses to C.** Handles, as above; a dropped handle answers null.
4. **The signature is the typedef.** Wrong arity or a wrong boundary type is a
   compile error, and `bindgen` writes the callback types from the headers.
5. **Signal-style APIs are refused by name** (`signal`, `sigaction`,
   `sigaltstack`, `atexit`, `on_exit`, `pthread_atfork`), listed in the
   generated file's header like every other refusal.
6. **Not reentrant by accident.** A synchronous callback that calls the same
   extern function (SDL from inside an event watcher) is the library's
   contract, not ours; the runtime keeps an "inside a callback" depth so a
   `Handles.drop` of a handle that is in use is refused.
7. **Sanitizer-clean.** Every callback test runs under AddressSanitizer and
   LeakSanitizer in `sanitize.sh`: a throw out of a comparator must leave
   `IO.allocated()` where it started.

#### What proves it

- `qsort` over an `Ints`, with a catmint comparator, sorted and checked.
- A comparator that throws on its third call: the caller's `catch` sees the
  error, `qsort` ran no further, no object leaked.
- A callback type with the wrong arity or a wrong boundary type; a non-static
  method; a nonexistent one. Each refused, each naming the mismatch.
- A callback invoked from a C thread (needs a C test library, so, like the
  `bindgen` test, it says "skipped: needs clang" when clang is missing): the
  abort and its message.
- A stale handle: dropped, then used, gives null and no fault.
- `bindgen` on a header with a callback typedef: the type written, the
  function bound with it, `signal` listed as refused.

### B. Completing the FFI's edges — **done**, on the `ffi-edges` branch

The changes below were made as designed, with three departures worth stating,
and each has a test that was seen to fail without it.

- **`String.fromC(Ptr p, Int max)`**, `unsafe`. Copies up to the first NUL or
  `max` bytes into a new counted String; a copy, never an alias, so C still
  cannot write into a String. A null `Ptr` answers null; a negative `max` is a
  catchable error. *Departure:* a `Bytes` is accepted as the source too, read
  through its own entry that clamps `max` to the buffer's length, because the
  natural way to get C text into catmint is a buffer filled by a C call
  (`snprintf`, `recv`), and a bare `max` there is an over-read waiting to
  happen. `Ints`, `Floats` and structs are refused as the source. (Test 66.)
- **A function declared to return `String` has the copy made for it**, capped
  at a megabyte. *Departure, a fix:* this was not in the plan because the bug
  was not known. An extern function declared to return `String` used to hand
  C's `char *` back typed as a catmint String, which it is not (no run-time
  type information, no count, no length in front). That was type confusion
  inside `unsafe`, and arrays are refused as returns for the same reason.
  `bindgen` still leaves a `char *` return a `Ptr` unless the function is
  named by `--string-returns`, since who frees it is not in the header.
- **A literal `null` for a `String` or buffer parameter is C's `NULL`.** Only
  the literal, decided by the argument's static type: a `String` variable that
  holds null is still the error it was. (`dlopen(null, 2)` in test 66; the
  null variable's refusal is in the same test.)
- **Variadic functions, by instantiation, and C functions under another name.**
  `def Int fcntl_dup = fcntl(Int fd, Int cmd, ... Int minimum)`. The call is
  made through a variadic function type with C's default promotions applied.
  *Departure:* the alias (`name = symbol(...)`) is general, not only for
  variadics, because the same C function wants declaring twice anyway
  (`strerror` as a `Ptr` and as a `String`). The variable part takes `Int`,
  `Int64`, `Float` or `Ptr`; `String`, arrays and `Float32` are refused, each
  with the reason. *The ABI claim was checked, not assumed:* `snprintf`
  declared as an ordinary function prints `0.000|83734528` for `3.142|42` on
  this Apple arm64 machine; declared variadic it is right. (Test 67; the
  grammar's conflict count did not move, 12 and 1.)
- **`bindgen`** reads the target's scalar sizes from clang
  (`__SIZEOF_LONG__`, `__CHAR_UNSIGNED__`) instead of assuming LP64, and
  takes `--target` and `--clang-arg=` so it can bind for a machine it is not
  running on: the same test struct is 40 bytes with `long` as `Int64` here and
  32 bytes with `long` as `Int` for `x86_64-pc-windows-msvc`, both from clang.
  `--constants-match` repeats and the header counts what each pattern matched,
  and stderr says so when one matched nothing (the missing `AUDIO_*` constants).
  `--string-returns` binds the named `char *` returns as `String`. A variadic
  function's refusal now says what to do, and names the `printf` family when
  clang marks it with a format attribute. `lib/sdl2.cmm` was regenerated:
  18 `AUDIO_*` constants gained, nine static-text returns now `String`.
- **`Process.runArgs(List)`, `startArgs(List)` and `p.openArgs(List)`**: no
  shell. The program and each argument are separate Strings, validated first
  (null, empty, more than 4096, a non-String, a NUL), then `execvp`ed.
  `openArgs` reads standard output and error together and gives the child
  `/dev/null` for input, and closes every descriptor the parent has open
  before it runs the program (found by reviewing this feature, not in the plan:
  without it a child holds the parent's files and sockets). A test passes an
  argument holding every character a shell acts on, and the marker file it
  would have created is never created; another counts a child's descriptors
  with and without files open in the parent. (Tests 69 and 42.)
- **`Entropy.bytes(n)` and `Entropy.int64()`** in `lib/entropy.cmm`, over
  `getentropy`, 256 bytes at a time. Statistical properties are the test
  (every byte value appears in 16 KB, one failure in 10^28; bits balanced
  within six standard deviations); it fails when the call is removed. The
  Windows half (`BCryptGenRandom`) waits for the Windows build. (Test 70.)
- **`String.chr(0)`** is a one-character String holding a NUL; it was empty
  because `chr` built a C string. (Test 68; the only runtime change that is not
  the C boundary.)
- **SDL's own error text** reaches the safe layer's exceptions
  (`could not initialise SDL: no_such_driver not available`), now that
  `SDL_GetError` is a `String`. (`tools/sdl_test`.)
- **The game and SDL run headless in `test.sh`** on the dummy video, renderer
  and audio drivers: the library test always, the game's simulation check and
  17 input tests with `--thorough`; `build.sh` no longer assumes Homebrew's
  location, and the Linux image has `libsdl2-dev`.

Still open from this list: the optional-string rule is only for the literal
`null` and for `String`/buffer parameters, so a `Ptr` parameter was already
fine and a struct parameter already took `null`; nothing more is planned. The
callbacks of section A are the next piece of FFI work.

### C. Windows

The target is **x86-64 Windows through MSYS2's UCRT64 (MinGW-w64)**. That is
the "cheap route" Phase 3 named, and it is still the right one: `catmintc` is
a shell script and the build uses flex, bison and cmake, all of which MSYS2
provides; native MSVC would cost the driver, the Makefiles and the grammar
build. 32-bit Windows is out (a different calling convention, and callbacks
there are `stdcall`).

What has to change:

1. **`runtime-windows-x86_64.bc`**, built by MSYS2's clang for
   `x86_64-w64-windows-gnu`. `runtime.c` gains `#ifdef _WIN32` branches where
   POSIX shows through, all in code we ship prebuilt, so none reaches a user:
   - `Process`: `fork`, `waitpid`, `popen` and `pipe` become `CreateProcessW`,
     handles and `_popen`. The argument-vector form is the natural fit here,
     since Windows takes a command *line* and every program parses it
     differently; quoting is done once, in the runtime, by the documented
     `CommandLineToArgvW` rules.
   - `Worker`: `pthread_create` → winpthreads (which MinGW has) or
     `_beginthreadex`; the core count from `GetSystemInfo`.
   - `IO.entropy`: `BCryptGenRandom`.
   - Files opened in binary mode, so `File` reads what is on disk.
   - `try`/`catch`: `setjmp`/`longjmp` on Windows x64 walks SEH unwind data, so
     every function needs unwind tables (`uwtable`), which clang adds by
     default on this target. **To be verified first**, with a test that throws
     through five frames; `__builtin_setjmp` is the fallback.
2. **The link line in `catmintc`.** `ld.lld -m i386pep` with MinGW's
   `crt2.o`, `libmingw32`, `libmingwex`, `libucrt` and `libkernel32` from
   `$MINGW_PREFIX/lib`, and the hardening Windows has in place of PIE and RELRO:
   `--dynamicbase --high-entropy-va --nxcompat`, checked after the build with
   `objdump -p` the way `readelf` checks the Linux executable. An import
   library per `link "..."`.
3. **Per-OS library directories.** `catmintc` puts `lib/os/<os>/` ahead of
   `lib/` on the include path, so `using sockets` finds the right binding.
   Bindings generated from system headers differ by OS, and the layout
   assertions are what keep that honest: a Linux `sockaddr_in` compiled on
   macOS (which has a length byte at the front) is a compile error naming the
   field, not a corrupted packet.
4. **`bindgen` for the target**, as in B.

How it is verified, since there is no Windows machine here:

- **Cross-compile and run under Wine in the Linux container.** `catmintc
  --target x86_64-w64-windows-gnu` with `mingw-w64`'s headers and import
  libraries and `wine64` to run the result, for the fast loop.
- **GitHub's `windows-latest` with `msys2/setup-msys2`** runs `test.sh` as the
  ground truth, with the game's headless tests on the dummy drivers.
- What neither can show is a window on a screen. Everything visible is
  verified through the headless route (saved frames and pixel assertions), as
  on macOS today.

### D. Textures and text — **done**, on the `editor` branch

Both phases after this want them, so they are built here, in `lib/sdl.cmm`.

**As built:** `Texture` is made from a `Bytes` of pixels (no BMP loader was
needed), with `draw`, `tint` and `opacity`; `Font` builds its atlas in catmint
from the 95 printable ASCII glyphs of Unscii (public domain, 8 x 16;
`tools/make_font.py` turns `unscii-16.hex` into `lib/fontdata.cmm`), and draws a
character of several UTF-8 bytes as one `?`. `tools/sdl_test` checks glyphs at
two sizes, tint, opacity, the clip and the `?`, pixel for pixel. Latin-1 was
not done; the editor has not needed it. The design that follows is kept as it
was written.

- **`Texture`**: from a BMP file (`SDL_LoadBMP_RW`, in SDL itself, so no new
  library) or from a `Bytes` of pixels; `copy(source rect, destination rect)`,
  tint, opacity, blend mode, flip; `finalize` destroys it before its renderer
  (the same ownership chain: texture → renderer → window → SDL).
- **Text** from a bitmap font atlas shipped in the repository (an
  SIL-OFL or public-domain 8×16 font, with its licence beside it), drawn from
  a texture. No new system library, ASCII plus Latin-1, fixed pitch, which is
  what an editor wants. TrueType through SDL_ttf is the later, optional step;
  it is a binding and a new dependency (`sdl2_ttf` is not installed here),
  and it is the right way to get proportional and non-Latin text. Not first.
- **Headless**: textures render under the software renderer, so a saved frame
  has real pixels to assert on.

### E. The GUI toolkit, and the application — **built**, on the `editor` branch

**Status.** `examples/pad` exists and is tested (CLAUDE.md, "The editor"): the
text buffer, the editor core, highlighting from the lexer's own keywords, the
theme, the fuzzy palette (commands, open by path fragment, find, replace, go to
line, save as), safe save, F5 build with click-to-jump, dark and light, and
sizes by whole numbers. It is not built on a general toolkit as designed below:
the design's own argument was that rationing leaves very little (a label, a
list, one field, an editor), and all of that is drawn directly by `pad.cm`
because there is only one program to want it. A toolkit would be extracted when
a second program asks. **Measured, as the design said:** every theme colour's
contrast ratio (`77_theme`), idle CPU (`examples/pad/idle.py`, 0.09 s in 5
against 1.0 for a loop that polls), the palette's ranking for typed fragments
(`80_fuzzy`), the pixels of the syntax colours, the palette and the panel
(`examples/pad/tests`).

**What it does not do, and why.** *Run* the program it built: reading a child's
output without blocking the window needs a non-blocking read the language does
not have, so F5 builds and shows the compiler's messages. More than one file at
a time ("switch file" is Open). Block indentation of a multi-line selection.
Wrapping. Focus mode. Windows (6C was skipped). A 5 MB file is checked at the
buffer (`84_bigtext`: 150,000 lines opened, searched, edited in the middle and
undone in well under a second, and the memory comes back); scrolling it in the
window was not timed, though only the rows on screen are drawn.

**What building it found:** an FFI miscompile (a narrow unsigned argument
reached C with the register's other bits set: the whole window came out cyan);
that sdl2-compat cannot take a pushed text event and misreads a pushed wheel
event; that a string literal could not end in an escaped backslash (the lexer);
and that `Font` counted bytes where an editor needs characters. The first,
third and fourth are fixed and tested.

**The application is an editor for catmint programs**, `examples/pad`:
open, edit, save, run. Chosen because it is the canonical GUI program, so it
needs every part of a toolkit and so tests the toolkit properly; because it is
a different shape of program from the game (long-lived mutable state, large
strings, input-driven rather than simulation-driven); and because it leads
somewhere: Phase 8's parser can later put its own diagnostics in the same
error panel. Alternatives considered: a file manager, a paint program, a
music tracker (all fine, none as broad), and a chat client, which belongs to
Phase 7.

**The toolkit is immediate-mode**, as Dear ImGui and egui are, in
`lib/gui.cmm` over `lib/sdl.cmm`: widgets are calls that draw and report in
the same breath, so the whole application is one loop with no handlers and no
object graph to keep alive. egui's own README says the point plainly -- "you
never need to have any on-click handlers and callbacks that disrupts your code
flow" -- and lists what it gives up for it: it is "not a framework", does not
aim at a "native looking interface", and has weaker layout and higher CPU use
than a retained toolkit. All three are accepted here, and the third is answered
below.

```
ui.begin(sdl)
if ui.key("ctrl+p"):
  palette.open()
end
ui.text_edit(buffer)
ui.status(buffer.name, buffer.position())
ui.end()
```

#### Look and feel: minimal, and kept small by the rules below

The aim was a program that is nothing but its text, and the reading that
shaped it came from the editors people describe as calm and fast. What it
gave, and what each rule costs the toolkit (which is the point: every rule
removes a widget):

1. **Text is the interface.** iA Writer "avoids all distracting glitz in the
   user interface and puts all the beauty in the shape of the text"; Zed
   describes itself as "minimalist, distraction-free, yet modern with native
   UI", and Sublime as a "minimalist interface, focus mode, clean design" with
   "legendary speed and ultra-low memory use" -- the same stance, from three
   places. So: the window is the text and one status line. No toolbar,
   no icons, no menu bar, no tab strip, no scrollbar until the pointer is over
   it (then a 2 px thumb). *Removes:* toolbar, menu bar, popup menu, tooltip,
   icon set, and every dialog.
2. **A command palette instead of menus** (VS Code, Sublime, Zed, Raycast,
   Linear): one shortcut opens a box, you type, it narrows. Fuzzy matching;
   the best match first whatever its kind ("top result", as Retool's write-up
   of theirs recommends); the shortcut shown beside each command so the palette
   teaches the keyboard; recent items first when the box is empty. It does four
   jobs, which is the saving: **commands** (`Run`, `Save`, `Find`, `Go to
   line`), **open file** (type a path fragment; this is the file picker, so
   there is no file dialog to build), **switch file**, and **goto symbol**.
   *Removes:* file dialog, menu bar, tab strip (open files are a palette mode),
   modal dialog (confirmations are a line in the status bar).
3. **One status line, quiet** (Helix lets you place file name, position,
   selections and diagnostics left, centre or right; that is the whole of its
   chrome). Left: file name and a dot when modified. Right: `line:column`, and
   the build state while one runs. Dim until something needs attention.
4. **Colour is rationed.** Nord is "deliberately low-contrast" and Catppuccin
   asks for balance, "not too dull, not too bright"; both are a dark ground,
   muted hues and a single accent. The editor reuses the game's palette (slate
   ground, warm off-white text), one amber accent for the caret, selection and
   focus, a muted red for errors, and **at most four muted hues for syntax**
   (keywords, strings, comments, numbers). *Checkable, so checked:* a test
   computes the WCAG contrast ratio of every theme colour against its ground and
   fails below 7:1 for body text and 4.5:1 for dim text, in both the dark and
   the light theme. No bold or italic; weight is not available in a bitmap font
   and was never needed.
5. **Type does the work.** One monospace bitmap font, one size, scaled by whole
   numbers for high-DPI; line height 1.4; a two-character gutter on each side
   and line numbers in the dim colour, the current line's in the text colour.
   Hairlines (1 px) and no shadows, gradients or rounded corners; a hovered
   thing brightens rather than gaining a box; focus is an accent underline.
6. **Nothing to configure.** iA Writer "has no graphical settings or
   formatting features". The editor has `Ctrl +` and `Ctrl -` for size, one
   command to flip dark and light, and no preferences. *Removes:* a settings
   screen, a config file, and the bugs in both.
7. **Quiet when idle**, the answer to immediate mode's CPU cost: the loop
   blocks in `SDL_WaitEventTimeout` and redraws only on an event or the
   500 ms caret blink. Measured, not hoped: a test samples the process's CPU
   time over five idle seconds and bounds it.
8. **Focus mode, if it is cheap** (iA fades everything but the current few
   lines): draw the other lines in the dim colour. A toggle on the palette; it
   costs one condition in the draw loop, and is dropped if it costs more.

**What is left of the toolkit** after those rules: label, a text-only button
(the build panel's, and the palette's rows), a single-line text field (the
palette, find, go-to-line), the multi-line text editor, a scrolling list (the
palette's results and the build output), and a scroll area. Layout is a single
column with a fixed status line and one panel that appears at the bottom on
`F5` and goes on `Esc`. Rows, columns and fixed or flexible sizes in one pass
are still all it needs.

- **Input**: focus; mouse capture while dragging; text input events
  (`SDL_TEXTINPUT`, so a typed `é` arrives as text, not as a key); key repeat;
  the clipboard (`SDL_GetClipboardText`, whose result is malloc'd and must be
  freed -- read through `String.fromC`, then free); the window's pixel density.
- **The text buffer** is a gap buffer over `Bytes`, with line starts indexed
  separately, undo and redo as a log of edits, and a hard cap on file size
  (64 MB, refused beyond it, with a message).

**The editor**, `examples/pad`: line numbers, selection by mouse and keyboard,
find and replace (in the palette's single-line field), syntax highlighting from
the lexer's own keyword list (read from `catmint.l` by a tool at build time, so
the two cannot drift), and **F5**: save, run `catmintc` through
`Process.runArgs`, show its output in the bottom panel, and let a click on
`Line 62` in an error jump to that line.

Sources for the above: [iA Writer's principles](https://ia.net/topics/writer-for-ipad)
and [a close reading of its interface](https://dbushell.com/2011/05/28/simplicity-in-ui-design-ia-writer-for-mac/);
[Zed against Sublime](https://zed.dev/compare/sublime);
[Helix's configurable status line](https://docs.helix-editor.com/editor.html);
[egui's goals and non-goals](https://github.com/emilk/egui);
[Dear ImGui's immediate-mode model](https://www.mintlify.com/ocornut/imgui/core-concepts/immediate-mode);
[Retool on designing a command palette](https://retool.com/blog/designing-the-command-palette)
and [Command.ai on its history](https://command.ai/blog/command-palette-past-present-and-future);
[Catppuccin's stated principles](https://github.com/catppuccin/catppuccin/blob/main/README.md)
and [Nord's low-contrast palette](https://best-of-web.builder.io/library/nordtheme/nord).

**Security, the editor and the toolkit**

1. **No shell, ever.** `runArgs` only; a file named `a;rm -rf ~` is a file
   with a strange name.
2. **Clipboard text is copied out with a bound and freed.** The read has a
   cap, the buffer returned by SDL is released, and a NUL in pasted text is
   dropped rather than truncating the buffer.
3. **Files**: size cap; opened and saved by the path the user chose, written
   to a temporary and renamed so a crash mid-save cannot leave half a file.
4. **No network, no remote assets**; the font and any icon ship in the repo.

**What proves it, without a screen**

- **The text buffer alone**, no SDL: random edits applied to the gap buffer
  and to a slow, obviously correct model (a `List` of lines), compared after
  each; every edit undone returns the original text; 10⁵ random operations.
- **The toolkit through events**: scripted input in the game's `.play` format
  (keys, text, clicks, drags), then a saved frame and pixel assertions on the
  regions that matter, run under the dummy video driver on all three OSes.
  Pixel-exact comparison between operating systems is not promised, since text
  hinting and the renderer may differ; region and colour counts are.
- **The run command**: a test program with a deliberate error; F5; the panel
  contains the compiler's message and the click lands on the line.
- **The look, where it can be measured**: every theme colour clears its
  contrast ratio (computed, not eyeballed); an idle editor uses next to no CPU;
  the palette's first result for each of a set of typed fragments is the one
  expected, and typing a file fragment opens that file.
- **Large files**: a 5 MB file scrolls, searches and saves within a time bound
  generous enough not to flake; memory returns to the baseline after closing it
  (`IO.allocated()`).

### Order, and what proves each

| step | proved by |
|---|---|
| Runtime per OS and architecture; CI green | `--check` on x86-64 Linux, arm64 Linux, arm64 macOS; annotations on failure |
| FFI edges: `fromC`, literal `null`, variadic instantiation, `bindgen` fixes | codegen tests against libc (`getenv`, `fcntl`, `strerror`); refusal tests; `bindgen_test` extended |
| `Process.runArgs` | a file name with every shell metacharacter, run and echoed back |
| Callbacks (synchronous) | the list under "What proves it" |
| Windows runtime and link line | the suite under Wine, then `windows-latest` |
| Textures and text | headless frames with pixel assertions on the font and a sprite |
| Toolkit, then the text buffer, then the editor | the three bullet groups above |
| The game's tests in CI, on all three | `play.sh` and the new checks on the dummy drivers |

### Considered and not done

- **A native toolkit per OS** (Cocoa, Win32, GTK). Three APIs, three binding
  efforts and three behaviours for one application, to get native widgets.
  SDL-drawn is one codebase and already runs on all three. GTK4 stays possible
  on Linux once callbacks exist.
- **The detached callback** (C's own threads), as designed above: not until
  something needs it.
- **MSVC**, for the reason Phase 3 gave.
- **SDL_ttf first.** Right eventually, wrong first: a new system dependency
  before the toolkit is known to need it.
- **SDL_mixer.** It is a callback-driven library; Phase 7's sounds are
  synthesised in catmint and queued, which needs neither.

## Phase 7 — the game, grown up: randomness, input, textures, sound, paths, and the network — as designed

Not started. The game so far was built to find what the language lacked, and
did. Phase 7 is the reverse: it asks what a game needs and finds out whether
the language and its libraries now supply it. The order is the order each step
needs the one before: a bigger map needs a camera, which needs input; paths
need obstacles to path around; the network needs a game worth sharing.

### The constraint that is dropped, and the one it exposes

`check.sh` compares the game with `replica.py` bit for bit, which required
the game to use a random generator and a sine and cosine the Python port could
reproduce. **That requirement ends.** It did its job: it found the float-literal
bug, the numeric-width bugs and the downcast bug, and nothing else it could
find is left. Concretely:

- **`Math.sin` and `Math.cos` already are the platform's `libm`** (`runtime.c`
  calls `sin` and `cos`); there is nothing to write, only the reason to avoid
  them gone.
- **The random generator becomes a real one.** `lib/random.cmm` is the C
  standard's linear congruential generator, documented as unsuitable for
  anything but games and with weak low bits. It is replaced by **xoshiro256\*\***
  (or PCG, decided by which is shorter to get right in catmint): 64-bit state,
  statistically sound, fast. Integer arithmetic already wraps (the generator
  emits plain `add` and `mul`, not `nsw`), which a generator needs; `>>` is an
  arithmetic shift, so the logical shifts are done by masking. It stays
  seedable, because tests want a repeatable sequence; unseeded it takes OS
  entropy.
- **Entropy gets real too.** `IO.entropy()` is an `Int`, 32 bits. `getentropy`
  (macOS, Linux) and `BCryptGenRandom` (Windows) are bound through `bindgen`,
  and `Entropy.bytes(n)` reads from them. That is what seeds the generator and
  what a network session token comes from; the generator itself is never used
  for anything an attacker would want to guess.

**What it exposes: lockstep networking is out.** Lockstep, where every machine
simulates and only inputs cross the wire, needs every machine to compute the
same bits — across Windows, Linux and macOS, with three different `libm`s and
a generator nobody can reseed. A "real" sine and a "real" generator are
exactly what make it impossible, short of fixed-point arithmetic and a table
of sines, which is the opposite of the direction asked for. So the network
design is **host-authoritative**, below, and costs nothing the simulation was
going to give up anyway.

**What replaces `check.sh`**: invariants rather than an oracle. Units never
inside an obstacle; never outside the map; gold never negative; a unit's
health never above its maximum; the unit count equals spawns minus deaths; the
game ends exactly when a base falls. They run every step in a `--check` mode
and in the tests. For A\* there is an independent oracle, below, because that
is where one is worth having. `replica.py` and the current `check.sh` are kept
for the skirmish scenario until the simulation changes underneath them, then
retired, and their history says why.

### A. Keyboard, camera, and a map that does not fit

The board is 14 × 10 and fits the window. Paths and obstacles want more, so
the map grows, which makes the camera real.

- **The event model grows**: scancodes (the physical key, for movement) and
  keycodes (the character, for commands) both; modifier state; key repeat on
  and off; mouse wheel; window resize and focus loss; `SDL_TEXTINPUT` for text
  fields (used by the lobby and, in Phase 6, the editor).
- **Camera**: WASD and the arrows to scroll; the mouse at the window's edge to
  scroll; the wheel or `+` `-` to zoom; `Home` to jump to your base; clamped to
  the map.
- **Commands**: control groups (`Ctrl+1..9` assign, `1..9` recall, a double tap
  centres the camera on the group), `A` to attack-move, `S` to stop, `P` or
  Space to pause, `M` to mute. The existing `1 2 3` spawn keys move to `Q W E`,
  since digits are groups.
- **Bindings in one table**, so the help screen and the code agree.
- **Proved by** the `.play` format growing `mod`, `wheel` and `scancode`
  commands; tests that scroll to a corner and assert where the camera stopped;
  that a group assigned survives units dying; that a key typed while a text
  field has focus reaches the field and not the game.

### B. Textures

Built in Phase 6, used here. The flat-shaded solids stay as a `--flat` mode
and as the fallback when an asset is missing.

- **Assets** are BMP files in `examples/rps-rts/assets/`, generated by a
  script in `tools/` from a few lines of description (so the art has a source
  that is code, no external artist or licence): terrain tiles with variation,
  three unit sprites in two team colours and a few facings, bases, obstacles
  (rocks, trees, water), effects, UI icons. One atlas, one `Texture`.
- **Drawing**: sorted by depth as now, one `copy` per sprite, a shadow as a
  translucent ellipse, the health bar over it.
- **Proved by** headless frames with pixel assertions on a sprite's known
  pixel at a known position, and by the run with the atlas deleted falling
  back to flat shading without a crash.

### C. Sound

No callbacks needed: SDL's `SDL_QueueAudio` pushes samples, and the tests can
see them.

- **Synthesised in catmint at startup**, into `Bytes`/`Ints`: sine, square and
  noise with envelopes, shaped into select, order, spawn, three attack sounds
  (a thud, a swish, a snip), a base hit, and a win and a loss jingle. No audio
  files, so no licence question and nothing to download.
- **A mixer** that sums the active voices into 16-bit samples each frame and
  keeps about 100 ms queued ahead; `M` mutes, `[` `]` change the volume.
- **Honest limit**: with a push model a slow frame is an audible gap. The
  callback model fixes that and needs the detached callback of Phase 6, which
  is not built. If gaps are a problem in practice, that is the trigger to build
  it.
- **Proved by SDL's `disk` audio driver**, which records what was queued
  (checked: it converts to 16-bit stereo at 44.1 kHz whatever was requested).
  A test plays each sound and asserts the recording has the right length, is
  not silent, stays within range, and a pure test tone has the frequency it
  should (counted from zero crossings). `SDL_AUDIODRIVER=disk` runs on all
  three OSes, so CI can too.

### D. Pathfinding and collision

Units currently walk in a straight line and are pushed apart. With obstacles
that is not enough, and this is the part of the phase that is an algorithm.

- **The map** gains terrain: blocked cells (rock outcrops, trees, water, walls)
  from ASCII map files in `assets/maps/`, and a generated kind that mirrors
  one half onto the other for fairness and flood-fills to prove every base can
  reach the other. Bases' surroundings are always clear. The default map grows
  to 32 × 24.
- **A\* on the grid**, 8-way, with the rule that a diagonal step needs both of
  its neighbours free (no cutting a corner through a wall). Costs are integers,
  10 and 14, so there is no floating-point tie to break differently on another
  machine. The heuristic is octile distance, which is consistent, so the first
  path found is optimal. Ties break by insertion order, so a run is repeatable.
- **`lib/heap.cmm`**, a binary heap, because A\* is the first thing here that
  needs one. A library with its own test against sorting.
- **No allocation per search**: the cost and parent arrays are reused, with a
  generation stamp so they are not cleared between searches. A hundred units
  re-pathing on one order must not make the frame budget the place the pool
  gets exercised.
- **Smoothing**: after the search, shortcuts wherever a straight segment
  crosses only free cells (a grid ray walk that visits every cell the segment
  touches, not just the ones it samples). Without it iso movement looks like a
  staircase.
- **Collision**: a unit is a circle. Each step, after moving, push it out of
  any blocked cell it overlaps (circle against the cell's box), then the
  existing unit-to-unit separation. A unit's step is smaller than its radius,
  so it cannot tunnel through a wall in one tick; asserted, not assumed.
- **Orders and chasing**: a move order paths each unit to its slot (the ring
  of offsets the order already makes; a slot that falls in a wall snaps to the
  nearest free cell); an attack order re-paths when the target changes cell,
  not every frame; a unit in range of its target stops and attacks.
  Unreachable goals walk to the reachable cell nearest to them, the usual
  fallback. A unit that has made no progress for a second re-paths with the
  cells other units stand on made costly.
- **The opponent uses it too**: its units path to the player's base instead of
  walking at it.
- **A debug overlay** (`--paths`) draws each unit's path and the blocked cells.

**What proves it**, the part that matters, since there is no replica:

- **An independent oracle.** A test generates a few hundred random maps and
  start and goal pairs, runs the A\*, and writes the maps and the costs found
  to a file. A script in Python — a different language, a different algorithm,
  a plain Dijkstra — reads the maps, computes the optimal cost, and the two
  must agree. The maps are written out rather than regenerated, so the script
  needs none of catmint's random numbers.
- **Properties on every path**: each step is to a neighbouring free cell, no
  diagonal cuts a corner, it begins at the start and ends at the goal (or the
  nearest reachable cell when there is none), and a smoothed path is valid
  segment by segment and no longer than the raw one.
- **The heap against sorting**, on random input including duplicates and sorted
  and reverse-sorted runs.
- **Collision invariants over a long run**: a hundred units sent through a
  one-cell gap for two thousand steps, the check on every step that no unit's
  centre is inside a blocked cell or outside the map.
- **Time**: a hundred paths on the 32 × 24 map under a generous bound, reported
  and only failing when it is absurd, so it does not flake on a slow runner.
- **Play tests**: an order across a wall ends near the target; with `--paths`
  the overlay's pixels are where the route runs.

### E. The network

After A to D, because a networked game ought to be worth playing, and last of
them because it is the project's first untrusted input.

**Design: host-authoritative TCP.** One machine, the host, runs the simulation
and is the only one that does. A client sends *commands* for its own units and
receives *snapshots* of the world; it draws what it is told, interpolating
between two snapshots for smoothness. The bandwidth is nothing: sixty units at
about twenty bytes each, twenty times a second, is 24 kB/s. There is no way
for the machines to disagree, which is what lockstep spends most of its effort
preventing. Costs: the client sees its own orders a round trip late (local
selection and the cursor are immediate; orders are acknowledged by the
snapshot), and a host can cheat, which for a game between two friends is not
a threat model. TCP rather than UDP because at this rate head-of-line blocking
is invisible and a reliability layer on UDP is the larger project; revisit if
it is ever not.

**What the language needs first**, in order:

1. **Non-blocking sockets.** `connect` otherwise blocks for the system's
   timeout (over a minute) with the window frozen, and `fcntl`, the portable
   way to set the flag on macOS, is variadic. Phase 6's variadic
   instantiation provides it; `poll` then drives everything from the one game
   loop, since a `spawn`ed thread may only do arithmetic. (`send` and
   `recv` take `MSG_DONTWAIT` too.)
2. **Per-OS bindings** of the socket API under `lib/os/<os>/`, generated by
   `bindgen` from each system's headers: POSIX sockets on Linux and macOS,
   Winsock on Windows (`SOCKET` is a pointer-sized unsigned integer, errors
   come from `WSAGetLastError`, `closesocket` and `ioctlsocket` are their own
   names). The layout assertions are what make a binding generated for the
   wrong OS fail to compile, naming the field, instead of sending a corrupted
   address: macOS's `sockaddr_in` begins with a length byte that Linux's does
   not.
3. **`lib/net.cmm`**, the safe layer: `Listener` and `Connection` classes that
   own their descriptors (`finalize` closes them), a receive buffer that frames
   messages, a send queue that tolerates a full buffer, and errors that are
   caught and carry the OS's own text through `String.fromC`.

**The protocol**: binary, versioned, length-prefixed, big-endian, integers
only. Positions travel as 16-bit fixed point (the map is 32 × 24), not
floating point. A frame is a length, a type and a body; the types are
`Hello` (version, a name of at most 32 bytes), `Welcome` (which side you are,
the map, a session token from `Entropy`), `Start`, `Command` (move, attack,
spawn, stop; unit ids; a position or target), `Snapshot` (tick, both golds,
both bases' health, then each unit's id, team, kind, position, health and
order), `Ping` and `Pong`, `Bye` and `Error`. Unknown types are an error.

**The lobby** is the first thing in the game that is not the board: a title
screen, Host, Join with an address typed into a text field, Play against the
computer. It uses Phase 6's toolkit, which is why that comes first.

**Security** — the network is the first channel in the project where the other
end is not trusted, and the design is written for that:

1. **Every length is checked before anything is allocated.** A frame is at most
   64 kB; a count of units is at most 512; a name at most 32 bytes. A header
   promising more drops the connection.
2. **Decoding is bounds-checked and caught.** It reads through `Bytes`, whose
   out-of-bounds access is a catchable error; any error while decoding closes
   that connection and nothing else.
3. **The receive call's length comes from the buffer, never from the
   caller.** `recv(fd, buffer, n)` is the classic overflow site and the safe
   layer computes `n` from the `Bytes` it hands over.
4. **Commands are validated against the host's state**: the unit must exist
   and belong to the sender, the target and position must be on the map, the
   player must have the gold, and orders are rate-limited per connection.
5. **No objects are deserialised**, only numbers and a bounded string; a name
   is limited to printable ASCII, since it is drawn on screen.
6. **Timeouts**: no `Hello` in five seconds, or no traffic in thirty, closes
   the connection; a stalled peer cannot fill the send queue without limit.
7. **It listens only when asked.** The host button binds, and says what
   address and port it bound; nothing listens by default.
8. **It is not encrypted or authenticated**, and the documentation says so.
   TLS would be a binding to a TLS library and a certificate story; neither is
   this phase. The session token stops a stray connection joining a game, not
   an attacker on the path.
9. **Entropy is the operating system's**, not the game's generator.

**What proves it**

- **Two processes on the loopback**, listening on port 0 so the OS picks one
  and tests never collide: connect, handshake, a scripted game, and the client's
  view equal to the host's state at the same tick for every field on the wire.
- **The decoder under fuzz**: random bytes, mutated valid frames, truncations
  at every length, frames delivered one byte at a time. It must never crash,
  hang or allocate more than its cap. This joins the fuzzer already in
  `test.sh --thorough`.
- **Failure**: the client killed mid-game, the host killed mid-game, a
  connection that sends half a frame and stops; each ends in the intended
  state within a bound.
- **A slow link**: a small proxy (a test program) that delays and fragments
  traffic, and the game still agreeing at the end.
- **No leaks**: a thousand connections opened and closed, `IO.allocated()`
  back at its start, and the suite's sanitizer runs clean.
- **Windows**: the same tests under Wine and on `windows-latest`. Winsock has
  to be started (`WSAStartup`) before use and stopped after, which the safe
  layer's `Sdl`-style owner does.

### Order, and what proves each

| step | proved by |
|---|---|
| Real generator, entropy, and the oracle-free checks | the generator against known test vectors and a statistical sanity test; the simulation's invariants every step |
| Keyboard, camera, groups, bigger map | extended `.play` tests and pixel assertions headless |
| Textures | frames with a known sprite pixel; the fallback with no atlas |
| Sound | the `disk` driver's recording |
| Heap, A\*, smoothing, collision, orders | the Python oracle, the properties, the invariants over long runs, play tests |
| Variadic instantiation, socket bindings, `net` | the loopback tests |
| Protocol, host-authoritative play, lobby | the two-process game, fuzz, failure and leak tests |
| The game's whole suite in CI on three OSes | the dummy video and audio drivers |

### Considered and not done

- **Lockstep**, for the reason above.
- **UDP with reliability and rollback**, a larger project than this game
  warrants; TCP first, revisit with evidence.
- **Fixed-point mathematics to keep lockstep possible.** The direction asked
  for is the opposite one.
- **SDL_mixer and SDL_image.** New system libraries to avoid writing a
  synthesiser and reading BMPs; neither is worth a dependency yet.
- **NAT traversal, matchmaking, accounts.** Direct address on a LAN or a
  forwarded port.
- **A flow-field for large groups.** A\* per unit is fine at this scale; if the
  unit counts grow by an order of magnitude, a flow field to the goal is the
  step, not a faster A\*.

## Phase 8 — a catmint compiler written in catmint, as designed

Not started, and last on purpose. Phases 6 and 7 add capabilities; this one
asks whether the language can carry the program that defines it. It is the
largest program yet attempted in catmint, the first whose input is arbitrary
text rather than a game's events, and, if it gets as far as bootstrapping, the
one that removes the last piece of C++ from a user's path.

### Why it is a good test, and what it is not

The game tested the edges: the FFI, the runtime, the toolchain. A compiler
tests the middle at a size nothing else here reaches: strings and lookup
tables everywhere, a class per syntax-tree node, deep recursion, a very large
number of short-lived objects, and symbol tables that live for the whole run.
The reference-counting pools and the "no cycles are collected" rule meet their
first long-running, cyclic-by-nature workload (a tree with parent links, a
class that refers to its methods which refer to their class). And it has what
the game had to build by hand: **an oracle**. The C++ compiler already exists,
so every stage can be compared with it, stage by stage, on every program in
the repository.

It is not a rewrite for its own sake. The C++ front end works and is tested.
The value is in what the rewrite shows about catmint, and in the one outcome
that could not be got otherwise: a compiler a user needs no C++ toolchain, no
flex, no bison and no cmake to run.

### How big

Measured, not guessed: the grammar and lexer are about 2,200 lines, semantic
analysis and the type table about 2,400, the IR generator about 3,600, and the
AST node classes about 2,100 more. A catmint version is likely 40 to 60 per
cent longer where it lacks generics and a switch, so on the order of 12,000
lines in all, of which the parser is a fifth. That is a long project; it is
planned in stages that each produce something checkable, with a decision point
after the first.

### The stages, and the check for each

**Stage 0, the preprocessor and lexer.** Everything the parser does before the
grammar sees a token: `using` expansion with `-I` search and each module once,
`#line` directives so diagnostics name the right file, string interpolation
rewritten to concatenation (recursively, with `\$` and single-quoted
literals), `link "..."` removed and collected, `using namespace` as `#open`,
the lexer's qualified-name joining. *Check:* a `--expand` flag on the C++
parser (a few lines) prints the expanded text, and the catmint version's
output must be byte-identical on every program and module in the repository.

**Stage 1, the parser.** A hand-written recursive descent parser with
precedence climbing, producing the same JSON AST. It must reproduce what bison
does by default, because a conflict resolved by "shift" is behaviour:
a newline does not end a statement (so `Int c = a` followed by `- b` is
`a - b`), `%` binds like `+`, `x = expr` is a `LocalDefinition` with type
`auto`, `else` followed by `if` on one line is `elif`, `a.b` followed by `[`
continues. Each of the twelve conflicts becomes a sentence in the parser with
the reason beside it. *Check:* the AST JSON is byte-identical to
`catmint-parser`'s, on all 64 codegen programs, the 11 parser tests, the
library modules, the examples and the game: 86 files, and then on the
stage's own source. Error messages for malformed input are compared on the
parser tests' refusal cases. **This is the decision point**: if Stage 1
reads well and runs at a reasonable speed, continue; if the language fights
it, that is the finding, and the project ends there with the parser as a
useful tool (the editor's syntax highlighting and error panel can use it) and a
list of what the language lacked.

**Stage 2, semantic analysis.** The type table, the symbol table, the
inheritance checks, return-type inference to a fixed point, vtable slot
assignment (append-only for built-ins), the extern checks (boundary types,
`unsafe` depth, the worker-hazard walk), and the error messages. *Check:*
accept and reject agree with the C++ analysis on every program, including the
refusal tests (65 alone has eleven cases); the diagnostics are compared as
text; and the annotated AST, with types and slots filled in, is compared with
the C++ one serialised after analysis.

**Stage 3, code generation.** Textual LLVM IR emitted directly, since catmint
has no LLVM bindings and does not need them: the IR is text in a stable
format, the same class of thing `bindgen` already writes. Every construct the
C++ generator handles: classes, vtables and RTTI with the reference-field
offset list, interface tables, the reference-counting stores and pool
bracketing, try and `setjmp`, defer, unwinding for `break` and `continue`,
debug locations, extern calls with the boundary types, C structs. This is the
largest stage and the one with the most invariants that are easy to break
silently; the C++ generator's comments are the specification. *Check*, in
increasing strictness: every codegen test builds and prints its expected
output when compiled by the catmint compiler; the IR is compared with the C++
generator's modulo value numbering, where a difference is either a bug or
a decision to write down; the sanitizer sweep and the differential tester run
on programs it compiled; `bench/run.sh` is unchanged.

**Stage 4, self-hosting.** The C++ compiler builds the catmint compiler
(stage 1); that compiles itself (stage 2); stage 2 compiles itself again
(stage 3). Stage 2 and stage 3 must be identical, byte for byte, which is the
standard check that the compiler means the same thing to itself that it did to
its predecessor. Then the C++ compiler is the *oracle and the bootstrap seed*,
not something a user runs.

**Stage 5, the seed.** What a user needs to build catmint becomes LLVM's
tools and one file: the compiler's own IR, committed per OS and architecture
exactly as `runtime-<os>.bc` is, reproducible by the same kind of `--check`
and stamped against version skew. flex, bison and cmake become dependencies of
*developing* catmint, as clang already is. This is Phase 5's principle (nothing
the user needs but LLVM) applied to the compiler itself. It carries the same
two obligations as the runtime: a shipped binary seed must be reproducible from
source by anyone, and the ordinary build must still work from source.

### What it will probably need from the language

Predictions to test, not requirements, each with what would count as evidence:

- **A string builder.** Repeated `+` copies; emitting thousands of lines of IR
  wants an append buffer. `lib/text.cmm` has none yet. *Evidence:* the time to
  emit IR for the game's 1,600 lines.
- **A growable `Bytes`/`Ints`** for symbol numbering and output, as `List` is
  for objects; `Vector` exists and may be enough.
- **Enumerations.** Token kinds and node kinds as `Int` constants in a class
  work and read badly; a `switch` on them is a long `elif` chain, and an
  exhaustiveness check would catch a missed node kind. This is the likeliest
  real language request, and the thing to resist doing before it is clearly
  needed.
- **Casts.** Every `List` read is a downcast (`Entity e = item` throughout the
  game); a compiler's trees are all `Node` and all downcasts. Whether that is
  tolerable at this size is the test of the decision not to have generics.
- **Recursion depth.** A deeply nested expression is deep recursion; the stack
  is the process's. A limit with a message beats a segfault, and the C++
  parser's own behaviour is the one to match.
- **Cycles.** A node with a parent pointer is a reference cycle that counting
  never frees. For a compiler that runs once and exits, harmless; for the
  editor's long-running use of the parser, a leak per parse. The answer then is
  weak parent links (a handle or an index), not a collector.

### Considered and not done

- **Rewriting only the later stages** (semantic analysis or code generation)
  against the C++ parser. The AST JSON is a clean seam, but the parser is the
  cheap stage with the sharpest oracle, which is why it is first.
- **Using the LLVM C API through the FFI** instead of emitting text. The FFI
  could bind it; the result would be the C++ generator again with different
  spelling, a link-time dependency on LLVM's libraries, and no gain in what is
  being tested. Text is also what makes the IR comparable.
- **A new grammar while rewriting.** The point is a faithful port that proves
  the language, byte-identical on the existing programs; changing the syntax is
  a separate decision with its own cost to every program written so far.

## What is left

Phases 6, 7 and 8 above, in that order, and `String.chr(0)` (recorded under
Phase 5). Nothing else on any of the older lists. The last item -- a throw leaking what the
abandoned frame had stored -- is fixed: the pool now holds the *addresses* of
reference-holding variables as well as objects, and releases them when a
throw unwinds it. The ordinary path is untouched, because a slot entry is
dropped rather than released when a pool closes normally.

It cost less than the shadow stack this was going to need, and it made things
faster rather than slower, because it forced the question of why a **borrowed
reference was being counted at all**: a parameter is held by the caller for
the whole call, so the callee only needs its own reference if it assigns to
the parameter. Almost none do. A method taking a String and returning its
length now runs about twice as fast as before any of this work.

All 54 tests are clean under AddressSanitizer and LeakSanitizer on Linux,
with nothing excused in CI.

## What to cut if this is too much

The parser fuzzer, which finds crashes on input nobody will write, and the
Object-keyed `Map`, which is a library. **Not `finalize`**: without it the
FFI's safe-wrapper pattern does not exist, and that pattern is why the
`unsafe` marking is worth having at all.
