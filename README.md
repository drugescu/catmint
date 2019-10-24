<img src="Product.png"
     alt="The catmint language logo"
     style="float: left; margin-right: 10px;"
     width="50%" height="50%"/>
# The Catmint Language 
![Size](https://img.shields.io/github/languages/code-size/drugescu/catmint?color=green&label=Code%20Size)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-green.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CircleCI](https://circleci.com/gh/drugescu/catmint.svg?style=shield)](https://circleci.com/gh/drugescu/catmint)

Starter repo for a low-level/high-level hybrid programming language targetting LLVM, seeking ease-of-use and brevity of Python with C-level control over memory and STL-completeness. 

Use cases: quick low level scripting, high-level AI and ML applications, Data Science, RAD, GUI, gaming, preferably cross-compilable x86_64 and arm64, Windows and Linux.

## Prerequisites
* flex
* bison
* LLVM

## Preliminary Lexer Sample
```
class Point from IO
	# Var region
     int32 m = 3
     float f = 3.4
     String s = "Hello World!"
     
     constructor :
       self.m = self.f = self.s = "0"
     end
     
     Main int32 a, Point b :
        a + b.mod
     end
end

# 3
-a*(3/20)+null
a = 3.0
```
