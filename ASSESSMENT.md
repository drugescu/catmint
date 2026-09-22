# Where catmint stands

An assessment of what the language can compile today, what it cannot, and what
it would take to write or port something substantial. Everything below was
checked against the compiler rather than read off the source; where a claim is
a measurement, the measurement is given.

## The short version

Catmint is a working compiler. It takes source, produces a native executable,
and the generated code runs at the speed of unoptimised C. The object model is
real: single inheritance, virtual dispatch through a vtable, `self`, attributes
laid out in a struct. There is a standard library written in the language
itself, and modules can be compiled separately and linked.

It is not yet a language you can write a large program in, and the reasons are
not subtle ones about type theory. They are that **you cannot read a field of
another object, you cannot open a file, you cannot see the command line, you
cannot recover from an error, and memory is never freed.** Each of those is a
day or two of work. None of them is hard. But until they exist, the set of
programs you can write is "reads stdin, computes, writes stdout, and finishes
before it runs out of memory".

## What works

Verified by the two test suites, 11 parser tests and 23 end-to-end tests that
compile a program, run it and diff its output.

**Language.** Classes with single inheritance and method overriding. Virtual
dispatch through the runtime's vtable, so an inherited method calling an
overridden one resolves correctly at run time. `self`, attributes, methods with
any number of parameters, with or without a declared return type. Recursion,
verified to 10,000 frames deep. `if`/`else`, `while`, `for` over an integer
count, a string's characters or a list. `return`. Arithmetic, comparison,
bitwise and shift operators, `**`, string concatenation and comparison.
String escapes. The `is` type test.

**Types.** `Int` (32-bit), `Float` (double), `String`, `Object`, `List`,
`Integer`. An `Int` stored where object references live is boxed automatically
and unboxed on the way out, and assigning a base-typed value to a more specific
variable inserts a run-time-checked downcast. That combination is what makes
containers usable without generics or cast syntax.

**Modules.** `using math as m`, referenced as `m::Vector`. Inclusion is
recursive, each module once, cycles terminate, diagnostics name the file you
wrote. Two modules may define the same class name under different namespaces,
and a genuine collision is an error rather than a silent overwrite.
`catmintc --separate` compiles each module to its own object and links them,
with vtable slot numbering agreeing by construction because both sides run the
same algorithm over the same declarations.

**Standard library, written in catmint.** `Vector` (size, push, indexOf,
contains, reversed), `Dict` (a real hash table: djb2, sixteen buckets,
collision chains), `Random` (seedable, reproducible), `Time` (dates from a
timestamp, formatting, monotonic milliseconds). The runtime contributes only
what the language cannot produce itself: an entropy source and three clock
readings.

**Performance.** The same program in catmint and in C, 3 million loop
iterations plus `fib(27)`, best of five runs on this machine:

| build | time |
|---|---|
| catmint | 0.013 s |
| C at `-O0` | 0.010 s |
| C at `-O2` | 0.011 s |

Catmint is in the same place as unoptimised C, which is the expected result:
`Int` is an unboxed `i32`, dispatch is one indirect call, and the output is
native code. No LLVM optimisation passes are run, so there is headroom here for
free.

## What is missing

Ranked by how much each one blocks a real program, not by how interesting it is.

### Blocking

**1. No field access on another object.** `p.x` is a syntax error, for both
reading and writing. Every piece of state has to be reached through a method,
so a plain data record needs a getter and a setter per field. This is the
single most limiting thing in the language and it is visible in the standard
library: `DictEntry` has `fill`, `key`, `value` and `setValue` where three
field accesses would do.

**2. No file I/O.** The runtime reads standard input and writes standard
output. There is no way to open, read or write a file. Any program whose job
involves a file on disk cannot be written.

**3. No command-line arguments.** `argv` never reaches the program. Every
program is either interactive or hard-coded.

**4. No error handling.** The only failure mechanism is `abort()`, which calls
`exit(1)`. There are no exceptions, no error returns, no way for a library to
report a problem that a caller can act on. `Dict.get` returns `null` for a
missing key, which is the only recoverable failure in the whole system, and it
is ambiguous with a stored null.

**5. Memory is never freed.** The runtime has six allocation sites and zero
calls to `free`. Every object, every string concatenation, every substring and
every list growth leaks. A batch program that finishes quickly is fine; a
server, a game loop or anything processing a large input is not. This is also
the largest gap against the project's own stated goal, which is smart-pointer
style management rather than garbage collection.

### Severe, but you can work around them

**6. No constructor arguments and no `new`.** An object is created by declaring
a variable, then initialised by calling a method on it. Two steps where one
would do, and no way to enforce that the second happens.

**7. No static or class methods.** Everything needs an instance, including
things that are conceptually free functions.

**8. The string library is too thin to do text processing.** There is `len`,
`at`, `substr`, `concat`, `equals` and `toInt`. There is no `split`, no
`indexOf`, no `trim`, no case conversion. Worse, **there is no way to turn a
character code back into a string**, so case conversion cannot be written in
catmint at all, even the long way. Writing a word-frequency counter meant
cutting words out one character at a time, and lowercasing them was not
possible.

**9. No math library.** `Float` arithmetic works and floats print, but there is
no `sqrt`, no trigonometry, no `pow` for floats.

**10. `Int` is 32 bits and it is the only integer type.** No 64-bit integer, no
unsigned, no byte or character type. `IO.epoch()` therefore stops working in
2038.

**11. No short-circuit `and`/`or`.** The bitwise `&` and `|` work as boolean
operators but always evaluate both sides, so the common guard
`if p != null and p.f() > 0:` cannot be written safely.

**12. No return-type inference.** `def f:` means "returns nothing". A method
that returns a value must say so.

### Rough edges

**13. `%` binds less tightly than `/` and `*`.** It sits with `+` and `-`, so
`a % b / c` means `a % (b / c)`. This caught me twice while writing the
standard library, once silently producing a wrong minute in a date. Fixing it
changes the meaning of existing programs, so it needs a deliberate decision.

**14. No generics.** Containers hold `Object`. The automatic boxing and the
checked downcast hide this well in practice, but the check is at run time.

**15. Single inheritance, no interfaces, no abstract methods.**

**16. No debug information in the generated IR.** No line numbers reach the
executable, so a debugger shows nothing useful and a crash gives no location.

**17. The compiler prints a large debug trace on every run.** There is no quiet
mode; `catmintc` hides it, but working on the compiler means reading past
hundreds of lines.

**18. Scopes are never popped in the symbol table**, so a name declared inside
a block stays visible after it. Harmless today because the code generator keeps
its own scopes, but the two can drift.

**19. The grammar has 10 shift/reduce and 4 reduce/reduce conflicts.** They
resolve the way the tests expect, but each one is a place where a future rule
can silently change the parse.

## Can a larger project be written or ported?

**A self-contained batch program, yes.** As a test I wrote a word-frequency
counter: read lines from standard input, split them into words a character at a
time, count them in the hash-table `Dict`, keep insertion order in a `Vector`,
print the counts. It compiles and runs correctly. Nothing about it felt like
fighting the compiler except the missing string functions.

Extrapolating from that, a program of one to three thousand lines that computes
something from standard input is realistic today: an interpreter, a solver, a
compiler for a toy language, a text-processing tool, a simulation that prints
results.

**Anything else, no, and the reasons are the five blockers above.** A program
that reads a configuration file, takes a flag, retries on failure or runs for
hours cannot be written at all, rather than being merely awkward.

**Porting** specifically is harder than writing fresh, because a port brings
its source language's idioms. Code that uses a hash map of structs, closures,
exceptions, or generic containers has no direct expression here and has to be
redesigned rather than translated.

## What I would do next

In this order. The first four are what turn "a working compiler" into "a
language you can write programs in", and none is a research problem.

1. **Field access, `a.b` for read and write.** Grammar, a new AST node or a
   reuse of `Dispatch`, and a GEP in the generator. This removes more friction
   than anything else on the list and makes the standard library half its size.
2. **File I/O and command-line arguments.** Perhaps six runtime primitives:
   open, read a line, write, close, argument count, argument at an index. A
   `File` class in the standard library on top, as `Time` sits on the clock
   readings.
3. **Free memory.** Reference counting fits the project's stated goal better
   than tracing collection, and the object header already has a spare word next
   to the RTTI pointer. Start by freeing the obvious temporaries from string
   concatenation and substring, which is where the allocation volume is.
4. **Fill out the string library, including `chr`.** `split`, `indexOf`,
   `trim`, `toUpper`, `toLower`. Most can be written in catmint once a
   character code can become a string.
5. **Error handling.** Even without exceptions, a convention plus runtime
   support for reporting rather than aborting would let libraries be honest
   about failure.

Two small things worth doing at any point, because they are nearly free: run
LLVM's optimisation passes on the generated module, and put line numbers in the
debug info.

## How to check any of this yourself

```sh
cd catmint-lex && ./wtest.sh     # 11 parser tests
cd catmint-gen && ./ctest.sh     # 23 end-to-end tests
./catmintc --run -I lib examples/tour.cm
```

Every claim in the "what works" section corresponds to a test in
`catmint-gen/test_suite/`. The claims in "what is missing" were each checked by
writing the smallest program that would need the feature and observing the
compiler reject it.
