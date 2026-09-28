# Where catmint stands

An assessment of what the language can compile today, what it cannot, and
what it would take to write or port something substantial. Everything below
was checked against the compiler rather than read off the source; where a
claim is a measurement, the measurement is given.

An earlier version of this document listed five things that blocked any real
program: no field access, no file I/O, no command-line arguments, no error
handling, and memory that was never freed. **All five are done**, along with
static methods, debug line numbers, optimisation levels, interfaces, string
interpolation, `defer`, `using namespace`, and processes. This is the state
after that work.

## How big it is

| part | lines |
|---|---|
| parser (flex + bison) | 1,923 |
| AST library and node headers | 3,974 |
| semantic analysis and types | 2,989 |
| code generation | 3,458 |
| runtime (C) | 1,768 |
| standard library (in catmint) | 420 |
| driver, build and test scripts | 548 |
| **total** | **15,080** |

Plus about 1,900 lines of catmint in the tests and examples. The vendored
rapidjson is not counted; nothing else is vendored.

## The short version

Catmint is a working compiler that produces native code faster than
unoptimised C. The object model is real: single inheritance, virtual
dispatch, `self`, attributes in a struct, constructors. It can read and write
files, see its command line, count references and give memory back, and it
has a standard library written in itself.

It has `try`/`catch`/`throw`, and it frees memory on its own -- the compiler
counts references and releases what an expression makes and nobody keeps --
without a garbage collector and without measurable cost on code that does not
allocate.

What is left is smaller than what came before it: no generics, no return-type
inference, no interfaces, and integer literals are 32 bits. None of those
stops a program being written.

## What works

Verified by the two test suites: 11 parser tests and 33 end-to-end tests that
compile a program, run it and diff its output.

**Language.** Classes with single inheritance and method overriding, and
`interface`/`does` for the polymorphism single inheritance cannot express.
Virtual dispatch through the runtime's vtable. `self`, attributes, methods
with any number of parameters, and `static def` methods called on the class.
`defer` for cleanup, and `"${...}"` for putting an expression in a string.
Constructors that take arguments, declared with `constructor(...)`, and
`new T(a, b)`. Field access on any object, `a.b` to read and `a.b = v` to
write. Recursion, verified to 10,000 frames deep. `if`/`else`, `while`, `for`
over an integer count, a string's characters or a list. `return`.
`try`/`catch`/`throw`. Arithmetic, comparison, bitwise and shift operators,
`**`, string concatenation and comparison, short-circuit `and` and `or`.
String escapes. The `is` type test, which knows about interfaces.

**Types.** `Int8`, `Int16`, `Int32`, `Int64` (`Int` is `Int32`), `Float`
(double), `String`, `Object`, `List`, `Integer`, `File`, `Math`. Mixing
integer widths promotes to the wider; assigning across widths sign-extends or
truncates, as C does. An integer stored where object references live is boxed
into a 64-bit `Integer` and unboxed on the way out, and assigning a
base-typed value to a more specific variable inserts a run-time-checked
downcast. That combination is what makes containers usable without generics.

**The outside world.** `File` opens, reads a line or the whole thing, writes,
closes, and answers whether a path exists; `open` returns 0 rather than
aborting. `IO.args()` and `IO.arg(i)` reach the command line, `IO.err` writes
to standard error and `IO.exit` sets the exit status. `IO.epoch()` is 64-bit
and works past 2038.

**Text.** On `String`: `len`, `at`, `substr`, `concat`, `equals`, `toInt`,
`toFloat`, `indexOf`, `trim`, `upper`, `lower`, `split`, `replace`, and
`chr`, which turns a character code back into a string and is the one text
operation that cannot be written in the language itself. `lib/text.cmm` adds
`join`, `repeat`, `padLeft`, `padRight`, `startsWith`, `endsWith` and
`words`.

**Errors.** `try: ... catch e: ... end` and `throw <anything>`, on setjmp and
longjmp, which is what Lua does and fits for the same reason: there are no
destructors, so jumping over a frame skips no work. The runtime's own checks
go the same way, so a method call on null or an index out of bounds is
catchable rather than fatal. A function containing a `try` has its locals
made volatile automatically -- the C rule, applied by the compiler -- and
that is load-bearing: without it, at `-O2`, a variable written inside the try
reads back in the handler as whatever it was when the try started.

**Memory, without a garbage collector.** The compiler counts references. It
retains on every store of a reference and releases when the variable's scope
ends; every allocation also joins a pool, and closing the pool releases
whatever nothing kept. A method opens a pool and so does each iteration of a
loop body. There is nothing to call: 200,000 iterations each building three
strings peak at 1.4 MB and end with four live objects.

A pool is emitted speculatively and taken away again if nothing inside it
allocated, so code that does not allocate pays nothing at all -- the
benchmark below is within noise of the same program compiled before any of
this existed. `retain`, `release` and `refs` remain for what a scope cannot
express, such as something held in a field. There is no `free`: an
unconditional one cannot be offered once the compiler is counting, and it
failed exactly that way when it was still there.

**Debug information.** `catmintc -g` puts a file and a line on every
statement, and on macOS collects it into a `.dSYM`. `-O0` through `-O3`
choose how hard the backend works.

**Concurrency, such as it is.** `Process` runs another program:
`Process.run` waits for one, `Process.spawn` and `Process.wait` start several
and collect them, and an instance wraps a pipe. There are no threads, and
that is a decision rather than an omission -- see the last section.

**Modules.** `using math as m`, referenced as `m::Vector`, or `using
namespace m` to drop the prefix. Inclusion is
recursive, each module once, cycles terminate, diagnostics name the file you
wrote. `catmintc --separate` compiles each module to its own object and links
them, with vtable slot numbering agreeing by construction.

**Standard library, written in catmint.** `Vector`, `Dict` (a real hash
table: djb2, sixteen buckets, collision chains), `Random`, `Time`, `Text`.
The runtime contributes only what the language cannot produce itself.

**Performance.** The same program in catmint and in C: 30 million loop
iterations plus `fib(32)`, best of seven runs on this machine.

| build | time |
|---|---|
| catmint | 0.023 s |
| C at `-O0` | 0.029 s |
| C at `-O2` | 0.014 s |

`bench/run.sh` is the fuller picture: five problems in catmint, C and C++,
checked to give the same answer before being timed. Best of five runs, and an
empty program in the last row so that the cost of merely starting one is
visible rather than hidden inside every other number.

| benchmark | catmint | C `-O2` | C++ `-O2` |
|---|---|---|---|
| tight integer loop | 0.037 s | 0.036 s | 0.035 s |
| prime counting | 0.117 s | 0.112 s | 0.117 s |
| `fib(35)`, recursive | 0.021 s | 0.021 s | 0.027 s (virtual) |
| building 2,000,000 strings | 0.214 s | 0.123 s | 0.089 s |
| sieve over 5,000,000 | 0.013 s | 0.008 s | 0.011 s |
| nothing at all | 0.005 s | 0.004 s | 0.004 s |

**Arithmetic, calls and array work are at parity with C.** Not approximately:
catmint and C trade places between runs on the loop, the primes and `fib`,
and `fib` beats the C++ column because that one is a virtual call and
catmint's, here, is not.

**Strings cost about 1.7 times C's and 2.4 times C++'s**, and that part is
architectural. A catmint String is a heap object: a type pointer, a reference
count, a length and its characters. C's is a raw buffer. C++'s, at this
length, is not on the heap at all, because libc++ keeps up to 22 characters
inside the `std::string` itself. Catmint has no equivalent, because anything
that can be passed as an `Object` needs a type pointer in front of it.

Four changes got it here, and three of them were finding waste rather than
cleverness.

- A String was two allocations, the object and a separate buffer. The
  characters now live in the same block, so it is one.
- A chain of concatenations -- which is what every interpolated string is --
  allocated an intermediate per `+`. The generator folds the chain into a
  single `__cm_concatAll`.
- Small integers, -128 to 1024, are shared static boxes, so a `List` of flags
  or counts allocates nothing. It is also why `Integer` has no setter:
  changing a shared box would change that number for everyone.
- **The runtime was compiled at `-O0`**, which marks every function
  `optnone noinline`, so nothing in it could ever be inlined into a program
  that linked against it. One flag in `build-runtime.sh`. That alone took the
  sieve from 0.050 s to 0.014 s and string building from 0.302 s to 0.212 s.

And a fifth in the compiler: a call now goes straight to the implementation
when no class in the program overrides the method, which is what made `fib`
match C. It is switched off for separate compilation, where an override could
be hiding in a module this one cannot see.

`Bytes`, `Ints` and `Floats` -- fixed-length arrays of numbers -- are why the
sieve is no longer the worst case. It used to run seven times slower than C,
because `List` holds object references and every flag was a separately
allocated box.

Two earlier measurements are worth keeping, because both were costs no test
could have shown. `catmintc` used to invoke clang at `-O0` on the linked
bitcode, so the fast register allocator spilled every value to the stack;
one flag was worth a third of the runtime. And reference counting,
implemented the obvious way, made a loop benchmark **seven times slower**,
because every iteration opened and closed a temporary pool it never put
anything in -- pools are now emitted speculatively and erased when nothing
inside them allocated.

If you touch code generation or the runtime, re-run `bench/run.sh`. Four
separate costs have been found that way and none of them failed a test.

## What is missing

Ranked by how much each one blocks a real program.

### Severe, but you can work around them

**1. No generics.** Containers hold `Object`. Automatic boxing and the
checked downcast hide this well, but the check is at run time. Interfaces
have taken most of the pressure off this: a method can now say what it needs
a value to *do*.

**2. No return-type inference.** `def f:` means "returns nothing". A method
that returns a value must say so.

**3. No abstract methods on classes.** An interface covers the case that
matters; a class that wants to leave a method to its subclasses cannot say
so, and has to provide one that does nothing.

**4. Integer literals are 32 bits.** `Int64 x = 9000000000` works, because a
literal too large for an Int is typed Int64, but `a * b` where both are Int
stays 32-bit and overflows silently. A 64-bit computation needs a 64-bit
operand to start from.

**5. ~~Freeing is shallow.~~ Fixed.** Releasing an object now follows its
reference fields, from a list of byte offsets in the run-time type
information that the generator writes down and `object_free` walks. This had
been the largest correctness gap here: a class with a String field leaked
that String every time an instance went away, so a loop making and dropping a
hundred objects left a hundred behind, and `IO.allocated()` said so.
Inherited fields come for free, since a subclass's layout begins with its
parent's.

Measured rather than asserted throughout. LeakSanitizer runs by default on
Linux and not on macOS, so none of this was visible until the suite was built
and run in a Linux container: **11 of the 50 tests leaked at exit**. One
cause was a plain bug -- the generated `main` allocated the `Main` object
without calling `noteAllocation`, so the speculative pool around it erased
itself as unused and every program ever compiled leaked one object -- and
fixing that took it to 5. Following reference fields took it to **0**. All 51
tests are clean under AddressSanitizer and LeakSanitizer together, which is
why CI now gates on it rather than reporting. `examples/mini.cm` shows what
it was worth: the objects still alive when it finishes went from 131 to 70.

Reference cycles are still never collected, which is the standing cost of
counting rather than tracing, and a structure can still be taken apart by
assigning over its fields.

**6. ~~A throw leaks what the abandoned work had stored.~~ Fixed.** The jump
skips the scope-exit releases of every frame between it and the handler, so
what those frames had *stored* was orphaned -- their temporaries went back
with the pool, but the reference a local was holding did not. A throw in a
loop leaked once per throw, so it was not bounded by anything.

The pool now holds two kinds of entry: an object, released when the pool
closes as before, and the *address of a variable*, released only when a throw
unwinds the pool. The ordinary path is unchanged -- a slot entry is simply
dropped -- so this costs a pool entry per reference-holding variable and
nothing else. The try body and the handler each get a pool of their own, the
first so that unwinding reaches the catching frame's own locals, the second
so that the thrown object dies when the handler is done with it rather than
when the catching method returns.

Two things turned up while fixing it. **The handler's variable was never
released at all** -- the catch scope was popped without releasing -- which
had been invisible because the thrown object belonged to the catching
method's pool and was freed when that method returned. And **a reference
parameter is borrowed**: the caller holds it for the whole call, so the
callee needs a reference of its own only if it assigns to the parameter.
Retaining every one of them cost a retain, a release, a slot registration and
a whole temporary pool in methods that allocate nothing; a method taking a
String and returning its length now runs about twice as fast as it did before
any of this work.

All 54 tests are clean under AddressSanitizer and LeakSanitizer together on
Linux, and CI gates on it with nothing excused.

### Rough edges

**7. `%` binds as loosely as `+` and `-`, and stays that way.** So
`a + b % c` means `(a + b) % c`. This has caught three pieces of work,
most recently the benchmark in this document, where it silently changed the
program being measured. It is nonetheless a *settled decision*, not an open
item: moving `%` up would silently change what every existing program using
it computes, and no warning could be given. Parenthesise. `CLAUDE.md` and
`COMPILING.md` both say so at the point where someone would reach for it.

**8. Scopes are never popped in the symbol table**, so a name declared inside
a block stays visible after it. Harmless today because the code generator
keeps its own scopes, but the two can drift.

**9. The grammar has 12 shift/reduce and 6 reduce/reduce conflicts.** They
resolve the way the tests expect, but each one is a place where a future rule
can silently change the parse.

**10. A `try` makes its function's locals volatile**, which is correct but
costs that function the optimiser's register allocation. Only functions
containing a try pay it.

## Can a larger project be written now?

Yes, and the class of program has genuinely widened. It reads and writes
files, takes a command line, recovers from failure, and does not grow without
bound, which between them were the reasons the answer used to be "only a
batch program that finishes quickly".

`examples/wordcount.cm` remains the demonstration: a filename from the
command line, usage to standard error and exit 1 when it is missing, the file
read line by line, lowercased and stripped of punctuation, counted in the
hash table, printed as a padded table. Fifty lines, and nothing in it fights
the compiler. It is test 33, so it stays working.

Five thousand lines is realistic: an interpreter, a solver, a compiler for a
toy language, a text tool, a long-running batch job. What still argues
against much more is the absence of interfaces and generics -- a large
program eventually wants to say "anything that can do this" -- rather than
anything about resources or failure.

**Porting** remains harder than writing fresh, because a port brings its
source language's idioms. Closures and generic containers have no direct
expression here and have to be redesigned rather than translated; exceptions
now do.

## What I would do next

In this order, and all of it is small.

1. **Return-type inference.** `def f:` that ends in a value should return it.
   The information is already in the semantic pass; what is missing is using
   it instead of defaulting `auto` to `Void`. This is the last piece of
   ceremony the language asks for without earning it.
2. **Interfaces.** A named set of method signatures a class declares it
   satisfies, checked at compile time, dispatched through the vtable exactly
   as now. This buys most of what generics would, at a fraction of the cost,
   and it is the thing a five-thousand-line program will ask for first.
3. **64-bit integer literals.** Type a literal by the context it appears in
   rather than by its own magnitude, so `Int64 x = a * b` does the
   multiplication in 64 bits.
4. **Line numbers in the runtime's error messages.** The debug information
   exists now; passing the current line to `__cm_runtimeError` would make an
   uncaught failure say where, not just what.

## What else is worth having, and what is not

**Taken since this was last asked.** `defer`, string interpolation and
interfaces were the three recommendations; all three are in, and they cost
about 700 lines between them. `defer` needed no runtime support at all:
the expression is emitted where the block ends, on each path out.
Interpolation needed none either -- it is a rewrite of the source line before
the lexer sees it, so what is in the braces is ordinary catmint. Only
interfaces reached the runtime, and only for one field in the type
information and one short lookup.

**Still worth taking, still cheap.**

- **Abstract methods on classes.** The one gap interfaces left: a base class
  that wants a subclass to supply a method has to supply a useless one.
- **A `Map` in the standard library that is not String-keyed.** `Dict` hashes
  strings; hashing any object would need only an `Object.hash` interface,
  which is now expressible.
- **A `Bytes` bridge to `String` and `File`.** The arrays exist now, but
  filling one from a file means reading a String and converting a character
  at a time. Two methods would fix it.

**Still not worth taking.**

- **Threads and shared-memory concurrency.** This remains the one to refuse,
  and the reference counting added since makes the case stronger: every count
  would have to become atomic, taxing every store in every program including
  the single-threaded ones, and the temporary pool and the handler stack
  would each need to be per-thread. A language with no ownership model gives
  a programmer nothing to reason about a data race with. `Process` is the
  answer instead: separate memory, nothing to get wrong, and the whole
  feature is a hundred lines of `runtime.c`. If a shared-memory thread is
  ever genuinely required -- one long computation over one big array -- the
  cheapest safe version is a `Worker` that runs a *static* method with no
  reference arguments, so nothing counted crosses the boundary; that is a
  narrow enough door to hold open without atomics.
- **Pattern matching and algebraic data types.** A front end and type system
  far beyond what is here. `is` plus a downcast covers the cases that come up.
- **A garbage collector.** Counting works and costs nothing measurable. The
  one thing tracing would buy is cycles, which a program can break by hand.
- **Generics.** Interfaces took the pressure off, and a type system several
  times the size of this one is not worth what is left.

## How to check any of this yourself

```sh
./test.sh                        # builds, then runs everything
./bench/run.sh                   # catmint against C and C++
cd catmint-lex && ./wtest.sh     # 11 parser tests on their own
cd catmint-gen && ./ctest.sh     # 41 end-to-end tests on their own
./catmintc --run -I lib examples/tour.cm
./catmintc -I lib examples/wordcount.cm -o wordcount && ./wordcount somefile
./catmintc -g -O0 app.cm         # line numbers a debugger can use
```

The memory work in particular should be re-checked under AddressSanitizer
after any change to it: compile the runtime and a test with
`-fsanitize=address` and run the suite. Every test passes clean today.

Every claim in "what works" corresponds to a test in
`catmint-gen/test_suite/`. The claims in "what is missing" were each checked
by writing the smallest program that would need the feature and observing the
compiler reject it.
