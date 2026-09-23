# Roadmap

What is planned, in the order it is planned, and why each item is on the list.
`ASSESSMENT.md` says where the compiler stands today; this says where it is
going. An item leaves this file when it lands, and `LANGUAGE.md` gains an
entry for it.

The whole list is about 2,300 lines of compiler and 600 of test
infrastructure, against a 15,849-line compiler. It is deliberately not a
rewrite of anything.

---

## Phase 0 — verification, before the grammar is touched

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

## Phase 1 — ergonomics

Friction found by writing `examples/mini.cm`, which is a 200-line
interpreter and the evidence that the language can carry a real program.

- **`else if`** (~15 lines of grammar). An `if_tail` rule: `KW_END`,
  `KW_ELSE block KW_END`, or `KW_ELSE if_statement`. No dangling-else
  ambiguity, because every block is `end`-terminated. A tokenizer is a chain
  of these; `mini.cm` nests three deep and closes with three stacked `end`s.
- **`break` and `continue`** (~180 lines). A loop-context stack in
  `IRGenerator` holding the target block, the scope depth, the pool depth and
  the handler depth at loop entry; the statement unwinds down to those and
  branches. Pool closes are recorded on the pool the way `emitCleanupAndReturn`
  records a `return`'s, so a pool nothing used still takes its closes away
  with it. A `break` outside a loop is a semantic error.
- **Abstract methods on classes** (~90 lines). `mini.cm` is the argument: its
  `Node` base carries a dummy `eval` returning 0, so a typo in a subclass
  silently inherits the dummy rather than failing. An interface cannot cover
  this, because the base class has state and real methods too.
- **Return-type inference** (~110 lines). **Only from an explicit
  `return <expr>`**; a body with no such statement stays `Void`. That rule
  cannot change what any existing program means, because a method returning
  nothing today has no `return` with a value in it. The Python-style "last
  expression is the value" rule was considered and rejected for exactly that
  reason: `def f: out("x") end` would silently stop being `Void`.
- **Line numbers on semantic errors** (~120 lines, mechanical).
  `SemanticException` already prints `Line N` when handed a `TreeNode`;
  roughly twenty derived classes in `SemanticException.h` simply never pass
  one, which is why `Method 'nosuch' not found in class 'Main'` arrives with
  no idea where. Add the node parameter, pass it at each throw site.
- **Character literals: nothing to do.** Measured: `"0".at(0)` folds to a
  compile-time constant at `-O2` -- a 20,000,000-iteration loop containing it
  optimised away entirely. This is a `LANGUAGE.md` note, not a language
  feature.

## Phase 2 — the foreign function interface

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

## Phase 3 — harden Linux

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
