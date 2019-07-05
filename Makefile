CC    ?= clang
CXX   ?= clang++

EXE = mlisp

CDEBUG = -g -Wall

CXXDEBUG = -g -Wall

CSTD   = -std=c99
CXXSTD = -std=c++14

CFLAGS   = -Wno-deprecated-register -O0  $(CDEBUG) $(CSTD) 
CXXFLAGS = -Wno-deprecated-register -O0  $(CXXDEBUG) $(CXXSTD)


CPPOBJ = main mlisp_driver
SOBJ   = parser lexer

FILES = $(addsuffix .cpp, $(CPPOBJ))

OBJS  = $(addsuffix .o, $(CPPOBJ))

CLEANLIST =  $(addsuffix .o, $(OBJ)) $(OBJS) \
				 mlisp_parser.tab.cc mlisp_parser.tab.hh \
				 location.hh position.hh \
				 stack.hh mlisp_parser.output parser.o \
				 lexer.o mlisp_lexer.yy.cc $(EXE)\

.PHONY: all
all: wc

wc: $(FILES)
	make $(SOBJ)
	make $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(EXE) $(OBJS) parser.o lexer.o $(LIBS)

parser: mlisp_parser.yy
	bison -d -v mlisp_parser.yy
	$(CXX) $(CXXFLAGS) -c -o parser.o mlisp_parser.tab.cc

lexer: mlisp_lexer.l
	flex --outfile=mlisp_lexer.yy.cc  $<
	$(CXX)  $(CXXFLAGS) -c mlisp_lexer.yy.cc -o lexer.o

.PHONY: test
test:
	test/test0.pl

.PHONY: clean
clean:
	rm -rf $(CLEANLIST)

