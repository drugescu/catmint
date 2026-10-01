# The catmint language

One entry per feature: what it is, the shortest example, and a file in
`catmint-gen/test_suite/` that compiles and runs. Every one of those is a
test, so nothing here is out of date without the suite going red. Run them
all with `./test.sh`.

For how to build and run a program, see `COMPILING.md`. For what the language
cannot do yet, see `ASSESSMENT.md`.

---

## The shape of a program

```
class Main from IO
  def main:
    out("hello\n")
  end
end
```

`Main.main` is the entry point. Code written outside any class is wrapped in
one for you. An unqualified call is a call on `self`, which is how `out`
works here.
→ `01_hello.cm`, `11_expr_stmt.cm`

## Values and types

`Int8`, `Int16`, `Int32`, `Int64` — `Int` is `Int32`. `Float32`, `Float64` —
`Float` is `Float64`, a double, and so is every float literal.
`String`, `Object`, `List`, `Integer`, and the built-in classes below.

```
Int n = 7
Int64 big = 9000000000
Float x = 2.5
Float32 f = 2.5          # rounded to a C float when stored
String s = "text"
```

Mixing widths promotes to the wider; assigning across them sign-extends or
truncates, as in C. Which means `Int64 x = a * b` with two `Int`s multiplies
in 32 bits and widens afterwards, exactly as C's `long x = a * b` does. The
compiler warns rather than changing the arithmetic; start from a 64-bit
operand. A literal too large for an `Int` is an `Int64`.

The two floats follow the same rules: mixing them computes at the wider, an
integer mixed with either becomes that float, and assigning across widths
extends or rounds implicitly. So `Float32` arithmetic stays `Float32` until a
`Float` operand joins it. `Float32` exists for C and for bulk data; `Float` is
the default.
→ `02_arith.cm`, `26_sized_ints.cm`, `14_io_float.cm`, `54_width_warning.cm`,
`59_float_literals.cm`, `60_float32.cm`

## Statements

One per line by convention, but **a newline does not end a statement** --
there is no separator, and an expression continues onto the next line for as
long as it can. A line that starts with `-`, `(`, `[` or `.` joins the line
above it:

```
Int c = a
- b            # this is c = a - b, not a statement of its own
```

Break a long expression where it cannot continue, or parenthesise it.
→ `bison -Wcounterexamples catmint-lex/catmint.y` prints every such case

## Variables

`Int a = 1` declares. `a = 2` on a name that exists assigns; on a new name it
declares. Declaring a variable of class type also constructs it.
→ `03_locals.cm`

## Operators

`+ - * / %`, `**`, `< <= > >= == !=`, `& | ^ << >>`, `!`, and short-circuit
`and` / `or`. `+` on a String concatenates, and converts a number for you.

**`%` binds as loosely as `+` and `-`, not as tightly as `*` and `/`.** This
is deliberate and will not change. `a + b % c` means `(a + b) % c`.
Parenthesise.
→ `02_arith.cm`, `32_shortcircuit.cm`

## Control flow

```
if n > 0:  ...  else  ...  end
if n > 0:  ...  elif n < 0:  ...  else  ...  end
while n > 0:  ...  end
for i in 10:  ...  end          # 0 to 9
for c in "abc":  ...  end       # one-character Strings
for item in someList:  ...  end

break                           # leave the innermost loop
continue                        # start its next iteration
```
`elif` chains a condition without nesting, and `else if` on a *single line*
is the same keyword. `else` and `if` on separate lines are still a nested if
and still need two `end`s. An end-terminated language cannot spell this the
way C does, which is why Python, Ruby, Lua and sh all have the extra keyword.
→ `04_if.cm`, `05_while.cm`, `09_for.cm`, `10_for_string.cm`, `15_list.cm`,
`44_elif.cm`, `45_break.cm`

## Classes

```
class Counter from Object
  Int value = 0

  constructor(Int start):
    value = start
  end

  def Int bump(Int by):
    value = value + by
    return value
  end
end
```

Single inheritance with `from`; methods are virtual. `new Counter(5)`
constructs, and so does declaring `Counter c` when the constructor takes
nothing. A method with no declared return type returns nothing.
→ `06_class.cm`, `07_inherit.cm`, `25_constructors.cm`, `22_method_forms.cm`

## Fields

`a.b` reads a field of any object and `a.b = v` writes one.
→ `24_fields.cm`

## Static methods

`static def Int square(Int n)` has no receiver and is called on the class:
`Geometry.square(7)`. It cannot use `self` or any field.
→ `34_static.cm`

## Return types

`def Int f` says what comes back. `def f` infers it from the `return`s:

```
def square(Int n):
  return n * n          # infers Int
end

def greet:
  out("hi")             # no `return` with a value: still Void
end
```

Only an explicit `return <expression>` counts, so a method that returns
nothing keeps meaning that. Two returns settle on the wider integer or on the
class they share; an `Int` and a `String` have no common type and are a
compile error asking for `def <type>`. A recursive method needs its type
written out, since its own body cannot supply it.
→ `47_inference.cm`

## Abstract methods

```
class Shape
  String label = "shape"
  abstract def Int area          # no body; a subclass supplies it
end
```

For a base class that has state and shared methods *and* one method each
subclass must write. A class with an abstract method left in it cannot be
`new`ed; declaring a variable of the type gives a null reference, the same as
declaring an interface does. An interface cannot cover this case, because an
interface has no fields and no bodies.
→ `46_abstract.cm`, `examples/mini.cm`

## Interfaces

```
interface Shape
  def Float area
end

class Circle does Shape
  ...
end
```

What a value can do, without saying what it is. A method taking a `Shape`
accepts any class that does one, related or not. Signatures only: no bodies,
no fields, and the return type is required.
→ `40_interfaces.cm`

## Asking a type

`expr is SomeType` gives 1 or 0, and knows about interfaces. Assigning a
general value to a more specific variable inserts a checked conversion.
→ `18_is.cm`, `40_interfaces.cm`

## Strings

`len`, `at`, `substr`, `concat`, `equals`, `toInt`, `toFloat`, `indexOf`,
`trim`, `upper`, `lower`, `split`, `replace`, and the statics `String.chr` (so
`String.chr(0)` is a one-character String holding a NUL) and `String.fromC`
(under "Calling C").
→ `28_strings.cm`, `23_escapes.cm`

## String interpolation

```
out("hello ${name}, ${n + 1} next\n")
```

Anything that can be written as an expression goes in the braces, including a
call or another string. `\$` is a literal dollar; single quotes do not
interpolate.
→ `37_interpolation.cm`

## Errors

```
try:
  risky()
catch e:
  out("failed: ${e}\n")
end
```

`throw <anything>` leaves through the nearest handler, and what is thrown
stays alive across the jump even when the frame it was made in is abandoned. The runtime's own
failures — a call on null, an index out of bounds — arrive the same way and
can be caught. Uncaught, a throw prints and exits 1. Built with `-g`, a runtime error says
which line it happened on.
→ `36_errors.cm`, `52_error_lines.cm`

## defer

`defer file.close()` runs where the enclosing **block** ends, on every path
out including a `return`. Several run in reverse order. The expression is
evaluated when the block ends, not where it is written, and a `throw` passing
through does not run it.
→ `38_defer.cm`

## Memory

Nothing to call. The compiler counts references: storing an object keeps it,
leaving the scope releases it, and anything an expression makes that nobody
names is released at the end of the method — or of the loop iteration, if it
was made in one. `retain()` and `release()` exist for what a scope cannot
express, such as an object held in a field. `IO.allocated()` is the live
object count, so "does this leak?" has an answer.
→ `31_memory.cm`

## Modules

```
using dict            # its classes, unqualified
using math as m       # its classes as m::Name
using namespace m     # ...and now unqualified too
```

Inclusion is recursive and each module is included once.
`catmintc --separate` compiles each module to its own object instead.
→ `12_modules.cm`, `17_namespaces.cm`, `13_separate.cm`

## Arrays

```
Bytes flags = new Bytes(1000000)    # one byte each
Ints counts = new Ints(64)          # 64 bits each
Floats xs = new Floats(3)           # doubles

flags.fill(1)
flags.set(7, 0)
out("${flags.get(7)} of ${flags.len()}\n")
```

`Bytes` also bridges to the rest of the world: `text.toBytes()`,
`b.toString()`, `b.slice(start, end)` (half-open, its own buffer), and
`File.readBytes(buffer)` / `File.writeBytes(buffer, count)`. A catmint String
carries its length rather than ending at a NUL, so binary data round-trips
through one.

Fixed length, numbers stored as numbers. This is the one thing `List` cannot
be: a `List` holds object references, so a million flags would be a million
allocations. Three concrete classes rather than one generic one, because
there are no generics. Out of bounds is a catchable error.
→ `43_arrays.cm`, `48_bytes.cm`

## Calling C

```
link "m"

extern class Libc
  def UInt64 strlen(String s)
  def Ptr malloc(UInt64 size)
  def Void free(Ptr block)
end

unsafe:
  out("${Libc.strlen("hello")}\n")
end
```

Declaring is safe; **calling needs `unsafe`**, because the declaration
asserts a match with a function the compiler cannot see. `unsafe def` makes a
whole method body one. Inside an unsafe region exactly two extra things are
possible -- calling out, and going through a `Ptr` -- and nothing else is
turned off.

`Ptr` is an opaque machine pointer: a value, not an object, so nothing counts
it and nothing frees it. It compares with `null` and converts to nothing.
Numbers, `Ptr`, `String`, the three arrays and extern structs may cross;
what a C function receives for the last three is an address. A `Float32`
crosses as a C `float`, a `Float` as a `double`. A String containing a NUL is
refused at run time, catchably, because C would read less than was passed;
a `Float` given where C takes an integer is a compile error.

`UInt8`, `UInt16`, `UInt32` and `UInt64` are C's unsigned types, for extern
declarations only. Read, each becomes the smallest catmint integer that holds
every value -- `Int` for the first two, `Int64` for `UInt32` -- and `UInt64`
an `Int64` holding the same bits. Anywhere else they are an error saying what
to write instead.

`link "name"` adds `-lname`, and `catmintc -l name -L dir` does the same from
the command line.

**Text back from C.** A function that returns `String` has the text copied out
of C's `char *` -- at most a megabyte, `NULL` becoming `null` -- so
`def String strerror(Int code)` is what it looks like. (Before this, declaring
that handed C's pointer back as if it were a catmint String, which it is not;
arrays are refused as returns for the same reason.) Or keep a `Ptr` and read it
yourself, in `unsafe`: `String.fromC(ptr, max)` copies up to the first NUL or
`max` bytes, whichever comes first, from a `Ptr` or from a `Bytes` (which is
never read past its own length). A copy, never an alias, so C cannot write into
a String. Leave a returned pointer a `Ptr` when someone has to free it.

**A NULL that is meant.** The word `null` written where C takes a `String` or a
buffer is C's `NULL` -- `dlopen(null, 2)`. A String *variable* that happens to
be null is still an error at run time, because that one is the accident.

**One C function under another name, and variadic ones.**
`def String strerror_text = strerror(Int code)` calls the C function
`strerror` as `strerror_text`, so one function can be declared twice with
different types. For a variadic C function a declaration says where the fixed
parameters end and what *this* declaration passes after them:

```
def Int fcntl_dup = fcntl(Int fd, Int cmd, ... Int minimum)
def Int snprintf_number = snprintf(Ptr buf, UInt64 size, String format, ... Float x, Int n)
```

The call is made as a variadic call, which matters: declared as an ordinary
function, `snprintf` printed `0.000|83734528` for `3.142|42` on Apple's arm64,
which passes variable arguments differently from fixed ones. C's default
promotions are applied (anything narrower than an `int` is widened). The
variable part takes `Int`, `Int64`, `Float` or `Ptr` only: a `Float32` is
promoted to a double by C, so it is declared `Float`, and a pointer whose
meaning only the callee knows goes through an explicit `Ptr`.
→ `49_ffi.cm`, `64_extern_struct.cm`, `65_extern_refusals.cm`,
`66_c_strings.cm`, `67_variadic.cm`

## C structs and unions

```
extern struct Rect @ 16         # @ asserts the size...
  Int32 x @ 0                   # ...and each offset; both are checked
  Int32 y @ 4
  Int32 w @ 8
  Int32 h @ 12
end

extern union Word @ 8
  UInt32 low
  UInt8 bytes[8]
  Float real
end

extern struct Window            # opaque: no fields, no size
end

Rect r                          # owned: zeroed bytes in a counted object
r.w = 640
unsafe:
  Rect v = Rect.at(somePtr)     # a view of bytes C owns
end
```

The layout is C's, computed by the compiler: each field at the next offset
aligned to its own size, a union's all at 0, the whole padded to its largest
alignment -- the same rule on every target catmint supports. Fields are
numbers, `Ptr`, other extern structs by value, and fixed arrays of those,
indexed as `s.bytes[i]` and bounds-checked. `@ n` is optional; a declaration
that disagrees with the computed layout is a compile error.

An **owned** struct -- declared, or made with `new` -- is a counted object
holding its bytes; C gets their address. A **view** is what an extern
function returning a struct gives back, or `S.at(ptr)` makes: the same kind
of object, over memory C owns, which catmint never frees. Making a view needs
`unsafe`, because that is the promise that the pointer is valid; after that
its fields read like any other. A null pointer gives `null`. A struct
parameter takes `null` too, for C's "none". A nested struct used whole is
copied, as C assigns structs; a `Ptr` parameter takes a struct's bytes, which
is how an out-parameter is written. Passing structs by value and callbacks are
not supported; a variadic function is called by instantiation, above.
→ `64_extern_struct.cm`, `65_extern_refusals.cm`

## finalize

```
class Buffer
  Ptr handle
  def Void finalize:
    unsafe: Libc.free(handle) end
  end
end
```

Runs when the last reference to an object goes. This is what lets a class own
something outside the language -- a C allocation, a handle -- and give it back
without anyone remembering to: the unsafe part stays inside the class and
nothing downstream writes `unsafe` at all. A subclass without one inherits it.
→ `50_finalize.cm`

## The standard library

Written in catmint, in `lib/`: `Vector`, `Dict` (a hash table keyed by
String), `Map` (keyed by anything that says how), `Random`, `Time`, `Text`,
`Entropy` (bytes from the operating system's generator, for anything that must
not be guessed; `IO.entropy()` is thirty-two bits and `Random` says it is not
for security),
and `sdl` -- windows, drawing, input and a clock, over SDL2.

`using sdl` gives `Sdl`, `Window` and `Renderer`, with no `unsafe` to write
and every handle released by `finalize`. Underneath is `sdl2.cmm`, SDL's whole
API as extern structs, functions and constants, generated from SDL's own
headers by `tools/bindgen.py` and never edited by hand. Nothing in either is
C. Needs SDL2 installed; on Homebrew build with `-L /opt/homebrew/lib`.

A `Map` key may be a String, an Int, or a class that `does Hashable` --
`def Int hash` and `def Int equalTo(Object other)`. String and Int are
answered for inside the Map, since a built-in class cannot be made to promise
a user interface. A key it cannot hash is a caught error, not a guess.
→ `16_stdlib.cm`, `19_dict_hash.cm`, `53_map.cm`, `20_random.cm`, `21_time.cm`, `70_entropy.cm`

## Built-in classes

| class | what it is |
|---|---|
| `IO` | `out`, `input`, `readLine`, `eof`, `err`, `exit`, `args`, `arg`, `ticks`, `epoch`, `sleep`, `allocated` |
| `String` | see above |
| `List` | a growable array of object references |
| `Bytes`, `Ints`, `Floats` | fixed-length arrays of numbers: `len`, `get`, `set`, `fill` |
| `Integer` | the box a number gets when it goes into a `List`; `get`, `getLong`. Values from -128 to 1024 are shared, so a list of small numbers allocates nothing |
| `File` | `open`, `readLine`, `readAll`, `write`, `eof`, `close`, and static `File.exists` / `File.remove` |
| `Math` | all static: `sqrt`, `pow`, `sin`, `floor`, `abs`, `min`, `max`, `pi`, … |
| `Process` | another program: `Process.run`, `Process.start`, `Process.wait`, and a pipe |
| `Worker` | a thread: see below |
| `Object` | `type`, `copy`, `abort`, `retain`, `release`, `refs` |

→ `27_files.cm`, `29_math.cm`, `30_args.cm`, `39_process.cm`

## Concurrency

Two kinds, both narrow on purpose.

**Another program.** `Process.run("make")` waits for one;
`Process.start` and `Process.wait` run several at once; an instance opens a
pipe. Nothing is shared, so nothing in the language changes. Those three hand
the string to `/bin/sh -c`, which is right for a script and wrong for anything
that puts a file name in it. `Process.runArgs(list)`, `Process.startArgs(list)`
and `p.openArgs(list)` take the program and each argument as a List of Strings
and `execvp` it directly, so nothing in an argument is ever parsed. `openArgs`
reads the program's output, standard error included, and gives it no input
(`/dev/null`), so it cannot wait on a terminal. Nothing the program has open
is lent to the child: it closes every descriptor above the three standard
ones before it runs, so a file or a socket held here is not held there. (The
shell forms do not do this.) An empty list, a non-String
item, or a String holding a NUL is a catchable error before anything starts; a
program that does not exist exits 127, as under a shell.
→ `39_process.cm`, `69_process_args.cm`

**A thread, for arithmetic only.** `Int h = spawn Sum.chunk(3)` runs a static
method on a thread; `Worker.wait(h)` collects what it returned. The method
must be static, take one number, return one, and do nothing but arithmetic —
and everything it calls must be the same. The compiler checks and says what
stopped it. That restriction is what keeps threads free for everyone else: a
worker provably cannot touch the memory the rest of the program is counting,
so no reference count has to be atomic.
→ `41_worker.cm`

---

## Longer examples

- `examples/tour.cm` — classes, inheritance, virtual dispatch, recursion.
- `examples/mini.cm` — an interpreter: tokenizer, recursive-descent parser,
  an AST of classes, a tree-walking evaluator, caught errors. Two hundred
  lines, which is the answer to "can something non-trivial be written in it".
- `examples/wordcount.cm` — a real program: a filename from the command line,
  a file read line by line, a hash table, usage and an exit status.
- `examples/rps-rts/` — a real-time rock-paper-scissors strategy game over
  SDL: an iso board, units, a simulation checked bit for bit against an
  independent port (`check.sh`), and input tests that drive it with real SDL
  events (`play.sh`).
- `bench/` — the same five problems in catmint, C and C++; `bench/run.sh`
  builds, checks they agree, and times them.
