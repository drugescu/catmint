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

`Int8`, `Int16`, `Int32`, `Int64` — `Int` is `Int32`. `Float` is a double.
`String`, `Object`, `List`, `Integer`, and the built-in classes below.

```
Int n = 7
Int64 big = 9000000000
Float x = 2.5
String s = "text"
```

Mixing widths promotes to the wider; assigning across them sign-extends or
truncates, as in C. A literal too large for an `Int` is an `Int64`.
→ `02_arith.cm`, `26_sized_ints.cm`, `14_io_float.cm`

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
while n > 0:  ...  end
for i in 10:  ...  end          # 0 to 9
for c in "abc":  ...  end       # one-character Strings
for item in someList:  ...  end
```
→ `04_if.cm`, `05_while.cm`, `09_for.cm`, `10_for_string.cm`, `15_list.cm`

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
`trim`, `upper`, `lower`, `split`, `replace`, and the static `String.chr`.
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

`throw <anything>` leaves through the nearest handler. The runtime's own
failures — a call on null, an index out of bounds — arrive the same way and
can be caught. Uncaught, a throw prints and exits 1.
→ `36_errors.cm`

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

## The standard library

Written in catmint, in `lib/`: `Vector`, `Dict` (a real hash table),
`Random`, `Time`, `Text`.
→ `16_stdlib.cm`, `19_dict_hash.cm`, `20_random.cm`, `21_time.cm`

## Built-in classes

| class | what it is |
|---|---|
| `IO` | `out`, `input`, `readLine`, `eof`, `err`, `exit`, `args`, `arg`, `ticks`, `epoch`, `sleep`, `allocated` |
| `String` | see above |
| `List` | a growable array of object references |
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
pipe. Nothing is shared, so nothing in the language changes.
→ `39_process.cm`

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
- `examples/wordcount.cm` — a real program: a filename from the command line,
  a file read line by line, a hash table, usage and an exit status.
- `bench/` — the same five problems in catmint, C and C++; `bench/run.sh`
  builds, checks they agree, and times them.
