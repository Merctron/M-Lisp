# M(eta)-Lisp

A simple Lisp interpreter written in C++ and inspired by [this essay](http://www.michaelnielsen.org/ddi/lisp-as-the-maxwells-equations-of-software/). The goal is to create an interpreter for Lisp that is functional enough to implement Lisp within Lisp itself.

## Building

### Requirements
* Linux:   Download and install Clang/LLVM (Or modify the makefile as appropraite if using a different compiler frontend), bison/flex.
* macOS:   Download and install bison/flex using homebrew and the Xcode command line tools.
* Windows: Download and install Clang/LLVM, MingGW-64, make, bison/flex, and add to path.

Simply run `make all` in the root directory of the project to build the C++ interpreter.





