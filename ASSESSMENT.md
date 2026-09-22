# Where catmint stands

An assessment of what the language can compile today, what it cannot, and
what it would take to write or port something substantial. Everything below
was checked against the compiler rather than read off the source; where a
claim is a measurement, the measurement is given.

An earlier version of this document listed five things that blocked any real
program: no field access, no file I/O, no command-line arguments, no error
handling, and memory that was never freed. Four of the five are now done.
This is the state after that work.

## The short version

Catmint is a working compiler that produces native code faster than
unoptimised C. The object model is real: single inheritance, virtual
dispatch, `self`, attributes in a struct, constructors. It can read and write
files, see its command line, count references and give memory back, and it
has a standard library written in itself.

What is left is smaller and more specific than what came before it: there is
no way for a library to report a failure that a caller can act on, no
generics, no return-type inference, and nothing frees the temporaries an
expression creates. None of those stops a program being written; they make
some programs uglier than they should be.

## What works

Verified by the two test suites: 11 parser tests and 33 end-to-end tests that
compile a program, run it and diff its output.

**Language.** Classes with single inheritance and method overriding. Virtual
dispatch through the runtime's vtable. `self`, attributes, methods with any
number of parameters. Constructors that take arguments, declared with
`constructor(...)`, and `new T(a, b)`. Field access on any object, `a.b` to
read and `a.b = v` to write. Recursion, verified to 10,000 frames deep.
`if`/`else`, `while`, `for` over an integer count, a string's characters or a
list. `return`. Arithmetic, comparison, bitwise and shift operators, `**`,
string concatenation and comparison, short-circuit `and` and `or`. String
escapes. The `is` type test.

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

**Memory.** Every object carries a reference count. `new` starts it at one;
`retain` and `release` move it and free at zero; `free` gives the object back
now. A static object -- a string literal, a class name -- has a count of
zero, which means free leaves it alone, so freeing a literal is a no-op
rather than heap corruption. `IO.allocated()` reports live objects, which is
how the test suite proves a thousand-iteration loop returns to where it
started. Freeing a built-in returns what it owns: a String's characters, a
List's array, a File's handle.

**Modules.** `using math as m`, referenced as `m::Vector`. Inclusion is
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
| catmint | 0.025 s |
| C at `-O0` | 0.030 s |
| C at `-O2` | 0.014 s |

Catmint now beats unoptimised C and is within a factor of two of optimised C.
The remaining gap is virtual dispatch: `fib` calls itself through the vtable
about two million times, and each call is a null check, two loads and an
indirect branch that the optimiser cannot see through. The loop half of the
benchmark is at parity.

That table used to read 0.039 s, and the fix was not in the compiler at all:
`catmintc` was invoking clang at `-O0` on the linked bitcode, so the fast
register allocator spilled every value to the stack. Running LLVM's pass
pipeline inside `catmint-gen` as well was tried and measured, and made no
further difference, so it was removed again.

## What is missing

Ranked by how much each one blocks a real program.

### Blocking

**1. No error handling.** The only failure mechanisms are `abort()` and
`IO.exit`, both of which end the program. There are no exceptions, no error
returns, no way for a library to report a problem that a caller can act on.
`File.open` returning 0 and `Dict.get` returning null are the whole of it,
and the second is ambiguous with a stored null. Any program that has to
recover from a bad input rather than die on it is awkward to write.

**2. Nothing frees a temporary.** Reference counting is manual and the
compiler inserts nothing, so `a + b` allocates a String that the program
never names and therefore can never free. A batch program is fine; a loop
that builds strings for hours is not. Test 31 measures this and expects it:
the named objects come back, the unnamed ones do not.

### Severe, but you can work around them

**3. No static or class methods.** Everything needs an instance, including
things that are conceptually free functions. `Math`, `File.exists` and
`String.chr` all work by ignoring their receiver, which is a convention, not
a feature.

**4. No generics.** Containers hold `Object`. Automatic boxing and the
checked downcast hide this well, but the check is at run time.

**5. No return-type inference.** `def f:` means "returns nothing". A method
that returns a value must say so.

**6. Single inheritance, no interfaces, no abstract methods.**

**7. Integer literals are 32 bits.** `Int64 x = 9000000000` works, because a
literal too large for an Int is typed Int64, but `a * b` where both are Int
stays 32-bit and overflows silently. A 64-bit computation needs a 64-bit
operand to start from.

### Rough edges

**8. `%` binds as loosely as `+` and `-`, and stays that way.** So
`a + b % c` means `(a + b) % c`. This has caught three pieces of work,
most recently the benchmark in this document, where it silently changed the
program being measured. It is nonetheless a *settled decision*, not an open
item: moving `%` up would silently change what every existing program using
it computes, and no warning could be given. Parenthesise. The compiler's own
documentation, `CLAUDE.md` and `COMPILING.md`, both say so at the point where
someone would reach for it.

**9. No debug information in the generated IR.** No line numbers reach the
executable, so a debugger shows nothing useful and a crash gives no location.

**10. Scopes are never popped in the symbol table**, so a name declared
inside a block stays visible after it. Harmless today because the code
generator keeps its own scopes, but the two can drift.

**11. The grammar has 12 shift/reduce and 5 reduce/reduce conflicts.** They
resolve the way the tests expect, but each one is a place where a future rule
can silently change the parse.

**12. Freeing is shallow.** `free` on an object does not follow its fields.
That is the right default for a language with no ownership annotations, but
it means freeing a tree is the programmer's loop to write.

## Can a larger project be written or ported?

**Yes, for a program that reads input, computes, and writes output.**
`examples/wordcount.cm` is the demonstration: it takes a filename on the
command line, reports usage to standard error and exits 1 if it is missing,
reads the file line by line, lowercases and strips punctuation, counts words
in the hash table, keeps insertion order in a List, prints a padded table,
and closes the file. Fifty lines, and nothing in it fights the compiler. It
is also test 33, so it stays working.

Extrapolating from that, a program of one to five thousand lines is realistic
today: an interpreter, a solver, a compiler for a toy language, a
text-processing tool, a build script, a simulation. What still argues against
going much further is error handling -- a large program spends a lot of its
code on what to do when something is wrong, and catmint's answer is still to
stop.

**Porting** specifically remains harder than writing fresh, because a port
brings its source language's idioms. Closures, exceptions and generic
containers have no direct expression here and have to be redesigned rather
than translated.

## What I would do next

In this order.

1. **Error handling.** The smallest thing that would work: a `Result`-shaped
   convention in the standard library plus a runtime call that reports
   instead of aborting, so a library can say what went wrong and a caller can
   decide. Exceptions would be better and are a much larger change --
   unwinding through the generated code is not a weekend.
2. **Release temporaries automatically.** The generator knows which values in
   a statement are unnamed; emitting a `release` for each at the end of the
   statement closes the one remaining leak and turns manual counting into
   something a long-running program can rely on. This is the step that makes
   the memory story complete, and it is the one piece of the memory work that
   was deliberately not attempted, because getting it wrong is a
   use-after-free rather than a leak.
3. **Return-type inference.** `def f:` that ends in a value should return
   it. The information is already in the semantic pass; what is missing is
   using it instead of defaulting `auto` to `Void`.
4. **Line numbers in the debug info.** Every AST node already carries one.
   Emitting `DILocation` for each statement turns a crash from a bare address
   into a file and a line, which is worth more than it costs.
5. **Static methods.** `Math`, `File.exists` and `String.chr` all pretend,
   and a program that wants a free function has to allocate an object to hold
   it.

## How to check any of this yourself

```sh
cd catmint-lex && ./wtest.sh     # 11 parser tests
cd catmint-gen && ./ctest.sh     # 33 end-to-end tests
./catmintc --run -I lib examples/tour.cm
./catmintc -I lib examples/wordcount.cm -o wordcount && ./wordcount somefile
```

Every claim in "what works" corresponds to a test in
`catmint-gen/test_suite/`. The claims in "what is missing" were each checked
by writing the smallest program that would need the feature and observing the
compiler reject it.
