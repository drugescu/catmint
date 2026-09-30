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

## Phase 5 — C structs, a prebuilt runtime, LLVM-only builds, as designed

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
  `runtime.c` wherever there was a C compiler. Within an OS the IR does not
  depend on the architecture, which `portability.sh` keeps checking.
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

## What is left

Phase 5, above. Nothing else on any of these lists. The last item -- a throw leaking what the
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
