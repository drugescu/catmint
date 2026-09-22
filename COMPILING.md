# Compiling and running a catmint program

Written for someone who has just cloned this repository and wants to get a
program running, then understand what the compiler did with it.

## 1. Install the toolchain

You need flex, bison 3.x, cmake and LLVM 16 or newer. The system bison on macOS
is 2.3, which is too old for this grammar, and Homebrew's LLVM and bison are
keg-only, so they have to be put on `PATH` explicitly.

```sh
brew install bison flex cmake llvm
export PATH=/opt/homebrew/opt/llvm@22/bin:/opt/homebrew/opt/bison/bin:$PATH
```

On Linux the distribution packages are usually already on `PATH`:

```sh
sudo apt install flex bison cmake llvm clang
```

Both makefiles find LLVM through `llvm-config`. If yours lives somewhere
unusual, pass it in: `make LLVM_CONFIG=/path/to/llvm-config`.

## 2. Build the compiler

Three components, built in dependency order. The second and third build the
first automatically, so in practice you run all three and let make sort it out.

```sh
cd catmint-ast && make -f GNUmakefile build   # libcatmint-ast.a: AST + JSON serialization
cd ../catmint-lex && make                     # bin/catmint-parser: flex + bison front end
cd ../catmint-gen && make                     # bin/catmint-gen: semantic analysis + LLVM IR
```

## 3. Compile a program

```sh
./catmintc --run examples/tour.cm
```

That prints:

```
Cat says meow
Dog says woof
Animal says ...
fib(10) = 55
sum of squares 1..4 = 30
```

`catmintc` writes a native executable named after the source file. Use `-o` to
choose a different name, and drop `--run` to build without running.

## 4. What the four stages actually do

`catmintc` is a shell script over four steps. Running them by hand is the best
way to see where a problem is.

```sh
# 1. Source to AST. The parser builds AST objects in its grammar actions and
#    serializes them as JSON.
catmint-lex/bin/catmint-parser examples/tour.cm /tmp/tour.ast

# 2. AST to LLVM IR. Semantic analysis builds the type and symbol tables and
#    annotates the tree; the generator then lowers it. Note it writes the .ll
#    next to its input, so run it from the directory you want the output in.
cd /tmp && /path/to/catmint-gen/bin/catmint-gen tour.ast tour.sem

# 3. Link with the runtime, which supplies the object model and I/O.
cd /path/to/catmint-gen
./build-runtime.sh                                  # runtime.c -> runtime.host.ll
llvm-link /tmp/tour.ast.ll runtime.host.ll -o /tmp/tour.bc

# 4. Native executable.
clang /tmp/tour.bc -o /tmp/tour && /tmp/tour
```

Step 3 needs explaining. The runtime is `catmint-gen/runtime.c`, and
`build-runtime.sh` compiles it for whatever host you are on. The repository
also still carries the original `runtime.ll`, which was committed without its
source and built for x86_64 Linux; `runtime.c` was reconstructed from it and
verified to behave identically. `build-runtime.sh` uses the C source when it
is there and falls back to patching the old IR when it is not.

## 5. The language, as far as the compiler currently supports it

```
class Counter from IO        # 'from' names the parent; Object is the default
  Int value = 0              # attribute with an initialiser

  def Int bump(Int by):      # 'def <ReturnType> <name>(<params>):' ... 'end'
    value = value + by
    return value
  end

  def Int get:               # no parameters, so no parentheses
    return value
  end
end

class Main from IO
  def main:                  # no return type means it returns nothing
    Counter c                # declaring a variable of class type constructs it
    c.bump(5)
    out("value = ")
    out(c.get())             # an Int argument to 'out' is converted to a String
    out("\n")
  end
end
```

Things worth knowing, because they are not obvious:

- **A declaration constructs.** There is no `new` in the grammar, so `Counter c`
  is how you get an object. It allocates, zeroes and runs the initialisers.
- **`Main.main` is the entry point.** If your file has statements outside any
  class, the parser wraps them in a `Main` class and a `main` method for you.
- **An unqualified call is a call on `self`**, which is how `fib` recurses and
  how `out` works inside a class that inherits `IO`.
- **`out` accepts an `Int`** and converts it with the runtime's integer-to-string
  helper. There is no other way to print a number.
- **A method without a declared return type returns nothing.** Write
  `def Int square(Int n):` when you want a value back. Return-type inference is
  not implemented, and `auto` is currently just a spelling of `Void`.
- **`x = expr` on a name that already exists assigns to it**; on a new name it
  declares it. The grammar produces the same node for both.
- **`for v in n:` counts**, giving `v` the values `0` to `n - 1`, and
  **`for c in someString:`** walks the characters, giving `c` a one-character
  `String` each time. There is no list type in the runtime, so nothing else can
  be iterated yet. The loop variable is scoped to the loop.

Built-in methods, from `Object`, `IO` and `String` respectively: `abort()`,
`type()`, `copy()`; `input()`, `out(String)`, `readLine()`, `eof()`;
`len()`, `toInt()`.

There are three ways to read input, because they answer different questions.
`input()` reads one whitespace-delimited word, `readLine()` reads the rest of
the line without its newline, and `eof()` says whether input is exhausted so a
loop can stop:

```
while !eof():
  String line = readLine()
  out(line)
  out("\n")
end
```

`out` accepts a `Float` as well as an `Int`, printing it with `%g`.

## 5a. Splitting a program across files

A `.cmm` file is a module: a class library with no top-level code. A program
pulls one in with `using`, naming the file without its extension.

```
# shapes.cmm
class Shape from IO
  def Int area:
    return 0
  end
end
```

```
# app.cm
using shapes

class Main from IO
  def main:
    Shape s
    out(s.area())
  end
end
```

```sh
./catmintc --run -I . app.cm
```

Modules are searched for in the directory of the file that imports them, then
in each `-I` directory, then in the working directory. Inclusion is textual but
careful: it is recursive, so a module may itself `using` others; each module is
spliced in at most once, so a diamond does not duplicate class definitions and
a cycle terminates; and line directives keep error messages pointing at the
file and line you wrote.

### Separate compilation

By default `using` splices modules in textually, so the whole program is one
translation unit. Pass `--separate` to compile each module on its own instead:

```sh
./catmintc --run --separate -I . app.cm
```

Each module becomes its own LLVM module, defining only its own classes, and
the objects are linked at the end. A unit that imports a module sees only its
declarations: external `@R<Class>` metadata and `declare`d methods.

The interface between units is the module's own `.ast` file. There is no
separate header format, and no need for one: both sides run the same layout
and virtual-table algorithm over the same declarations, so the slot numbers
agree by construction. This matters, because a disagreement would be a silent
miscompile rather than a link error.

Under the hood the driver runs, for each module deepest-first:

```sh
catmint-parser --no-expand --module shapes.cmm shapes.ast
catmint-gen     --module                       shapes.ast shapes.sem
catmint-parser --no-expand --module square.cmm square.ast
catmint-gen     --module --import shapes.ast   square.ast square.sem
catmint-parser --no-expand                     app.cm     app.ast
catmint-gen     --import shapes.ast --import square.ast app.ast app.sem
llvm-link shapes.ast.ll square.ast.ll app.ast.ll runtime.host.ll -o app.bc
```

`--module` says this is a library: no `Main` is required and no entry point is
emitted. `--no-expand` stops the parser splicing the module in, since it is
being compiled on its own.

What is still missing is namespacing. All classes share one global namespace,
so two modules cannot both define a `Point`, in either mode.

## 5b. Lists, and the standard library

The runtime provides exactly one container, `List`: a growable array of object
references. Everything richer is written in catmint on top of it, in `lib/`.

```
List xs
xs.append(10)
xs.append(20)
Int first = xs.get(0)     # unboxed on the way out
for item in xs:
  Int n = item
  out(n)
end
List part = xs.slice(0, 1)
```

Because there are no generics, a `List` holds `Object`. Two conversions make
that usable and the compiler inserts both. An `Int` stored into a list is
boxed into an `Integer`, and taken back out into an `Int` it is unboxed. A
value assigned from an `Object` to a variable of a more specific type gets a
checked downcast, which aborts at run time if the object is not of that type.
That is deliberately a run-time check: it means containers work without cast
syntax, which the grammar does not have.

`==` on two object references asks the runtime, which compares strings and
boxed integers by value and everything else by identity.

`lib/vector.cmm` and `lib/dict.cmm` are the standard library, written in
catmint:

```sh
./catmintc --run -I lib myprogram.cm
```

`Vector` adds `size`, `push`, `indexOf`, `contains` and `reversed` over a
`List`. `Dict` is a String-keyed hash table with `put`, `get`, `has`, `size`
and `keyList`, using djb2 over `String.at` and sixteen buckets of collision
chains. `Random` is a seedable generator with `next`, `below` and `between`.

None of the three needs the runtime. `Random` borrows exactly one primitive,
`IO.entropy()`, for an unpredictable seed, because that is the only part a
language cannot produce by itself. The algorithm stays in catmint so that
`seed(42)` gives the same sequence every run and can be tested.

## 5c. Namespaces

Two modules may both define a `Point`. Import them under aliases and say which
one you mean:

```
using geo2d as flat
using geo3d as space

flat::Point a
space::Point b
```

`using math as m` puts everything `math.cmm` declares into namespace `m`.
Inside a namespaced module an unqualified class name means that module's own
class; the built-in names stay global. Importing without `as` leaves the
module's classes global, as before. Defining one name twice in the same
namespace is an error rather than a silent overwrite.

## 5d. Asking an object its type

`expr is Type` gives `1` when the object is of that type or inherits from it,
and `0` otherwise, including for `null`. Unlike an assignment's implicit
downcast it never aborts, which is what makes it useful as a guard:

```
for item in things:
  if item is Integer:
    Int n = item
    out(n)
  end
end
```

This split is the point. A growable array needs raw memory, so it belongs in
the runtime. A dictionary does not, so it belongs in the language, where it
costs the compiler nothing.

## 6. Tests

```sh
cd catmint-lex && ./wtest.sh   # parser: AST output against committed references
cd catmint-gen && ./ctest.sh   # code generation: program output against .expected
```

The code generation suite compiles and runs each `test_suite/*.cm` and diffs the
program's stdout against the matching `.expected`. Run one test with
`./ctest.sh test_suite/05_while.cm`. Add a case by dropping in the two files.

Both suites should be fully green. If the parser suite regresses, compare the
produced `.ast` against the committed `.ref`; the diff is usually a grammar
change altering the shape of a node.

When a program fails to compile, `catmint-gen/dbg.sh <file.cm>` runs just the
parse and generate steps and shows the error, which is otherwise buried in a
very chatty debug trace.

## 7. How code generation works

Worth reading before changing `catmint-gen/IRGenerator.cpp`.

The object model is fixed by `runtime.ll` and the generator has to match it
exactly. Every object begins with a pointer to its run-time type information:

```
__catmint_rtti = { TString *name; int size; __catmint_rtti *parent; void *vtable[]; }
TObject        = { __catmint_rtti *rtti; }
TString        = { __catmint_rtti *rtti; int length; char *chars; }
```

`__catmint_new(rtti)` allocates `rtti->size` bytes, zeroes them and stores the
rtti pointer, so each generated class publishes an accurate size.

For each class the generator emits an LLVM struct laid out as
`{ rtti, inherited fields..., own fields... }`, a `@N<Class>` name string, a
`@R<Class>` RTTI record holding the virtual table, and a `<Class>_init` that
chains to the parent's initialiser and then runs the attribute initialisers.

Virtual table slots are the parent's slots followed by the class's new methods
in declaration order; an override reuses the parent's slot. The built-in
classes are seeded to match the order already baked into `runtime.ll`, which is
why `Object` occupies slots 0 to 2 and `IO` adds `input` and `out` at 3 and 4.

Methods are named `M<length><Class>_<method>`, take `self` as their first
parameter, and are called by loading the function pointer out of the receiver's
vtable. Built-in methods are the exception: their runtime names predate the
catmint spellings, so `type`, `len` and `input` map explicitly to
`M6_Object_typeName`, `M6_String_length` and `M2_IO_in`.

## 8. What is still missing

- Indexing and list/dictionary literals parse -- `a[i]` desugars to `a.get(i)`
  and `a[i] = v` to `a.set(i, v)` -- but there is no list type below the
  parser, so such a program cannot be compiled or run yet. Slice vectors
  (`a[1:2]`) are not deserialized at all and abort in `ASTSerialization.cpp`.
- Return-type inference, as described above.
- Lists and dictionaries parse but have no representation in the runtime.
- Attribute assignment through another object, as in `c.name = "x"`, has no
  grammar rule.
