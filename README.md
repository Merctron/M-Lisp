# M(eta)-Lisp

A simple Lisp interpreter written in C++ and inspired by [this essay](http://www.michaelnielsen.org/ddi/lisp-as-the-maxwells-equations-of-software/). The goal is to create an interpreter for Lisp that is functional enough to implement Lisp within Lisp itself.

## Usage
### Requirements

* Linux:   Download and install Clang/LLVM (Or modify the makefile as appropriate if using a different compiler frontend), bison/flex.
* macOS:   Download and install bison/flex using homebrew and the Xcode command line tools.
* Windows: Download and install Clang/LLVM, MingGW-64, make, bison/flex, and add to path.

### Building

Simply run `make all` in the root directory of the project to build the interpreter.

### Running

We can run the built `mlisp` executable to launch a REPL:

```
$./mlisp
M-Lisp>(+ 1 1)
2
```

We can also use `--single-use` to read from `stdin` and execute directly:

```
$./mlisp.exe --single-use "(+ 1 (+ 1 1)) (+ 1 1)"
3
2
```

## Language

The full set of operator and keywords supported by M-Lisp can be found in its [language specification](language.md).





