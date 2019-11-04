<img src="Product.png"
     alt="The catmint language logo"
     style="float: left; margin-right: 10px;"
     width="50%" height="50%"/>
# The Catmint Language
![Size](https://img.shields.io/github/languages/code-size/drugescu/catmint?color=green&label=Code%20Size)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-green.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CircleCI](https://circleci.com/gh/drugescu/catmint.svg?style=shield)](https://circleci.com/gh/drugescu/catmint)

Starter repo for a low-level/high-level hybrid programming language targetting LLVM, seeking ease-of-use and brevity of Python with C-level control over memory and STL-completeness.

As primary starting point, the LLVM class from UPB in Bucharest and its LCPL didactic language which already fits some amount of desired features on the part of the author. The point would be to slowly replace the code base as the language gets developed and to be usable in many of the author's usecases, as explained below, while serving as a base for continued development of an open source project for anyone to particiapte in.

Use cases: quick low level scripting (down to the bit), high-level AI and ML applications, Data Science, RAD, GUI, gaming, preferably cross-compilable x86_64 and arm64, Windows and Linux.

Should target no garbage collection, but an ingenous system of memory management similar to C++ smart pointers. The C++ auto feature should be taken up a notch to match the ease of use in Python but without losing too much of its speed. Explicit type declaration will be allowed, but type inference should be general enough.

Code should also be a lot more explanatory than c++ but concise like Python! The two requirements are seemingly at odds with each other but the author believes it possible. It's a perfect situation for developing a demo.

Careful design with pointers and templates should be done so as to exclude possible memory problems and compilation issues with incomprehensible messages.

## Prerequisites
* flex (used version 2.6.4)
* bison (used version 3.3.2)
* LLVM (currently using version 8.0)

## Preliminary Lexer Sample (WI_heavy_P)
```
# Comment

class Point from IO
  # var region
  int32 m = 3
  float f = 3.4
  String s = "Hello World!"

  # inferred, auto return type
  def show Int a, Int b:
    a + b
  end

  # empty method
  def t:
  end
end

class Line
  d = 20.1

  # Clearly defined int32 return type
  def int32 show_stuff Float a, Float b, Float c
    # return word need not be explicit
    a + (b-c) / 2
  end
end

# Will insert into a Main class and main method if they do not exist
t = t - 1
```
