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

## Phase 4 — leftovers

- **Follow reference fields when freeing** (~80 lines). Promoted to the top
  of this list by Phase 3, which measured what it costs: 5 of the 50 tests
  leak at exit, every byte of it a reference held in a user class's field,
  because the run-time type information does not say which fields are
  references. The generator already knows; it would emit a list of offsets
  and `object_free` would walk it. Another change to the RTTI layout, which
  has been done twice now without incident. It is also what would let
  LeakSanitizer become a gate on Linux rather than a report.
- **A `Map` keyed by anything, not just String** (~130 lines of `.cmm`).
  Needs only an `Object.hash` interface, which `interface` made expressible.
  Pure library; writable whenever someone needs it.
- **Line numbers in runtime error messages under `-g`** (~50 lines). The
  debug information exists; a current-line global updated at statement
  boundaries, and only under `-g`, so no program pays for it.
- **64-bit literal typing by context** (~80 lines). Last, and flagged: this
  is the one item that changes what an existing program *computes*, since
  `a * b` assigned to an `Int64` wraps at 32 bits today and would stop.

## What to cut if this is too much

The parser fuzzer, which finds crashes on input nobody will write, and the
Object-keyed `Map`, which is a library. **Not `finalize`**: without it the
FFI's safe-wrapper pattern does not exist, and that pattern is why the
`unsafe` marking is worth having at all.
