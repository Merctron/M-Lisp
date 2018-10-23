#ifndef __MLISPSCANNER_HPP__
#define __MLISPSCANNER_HPP__ 1

#if ! defined(yyFlexLexerOnce)
#include <FlexLexer.h>
#endif

#include "mlisp_parser.tab.hh"
#include "location.hh"

namespace Mlisp {

class Mlisp_Scanner : public yyFlexLexer {

  private:
    /* yyval ptr */
    Mlisp_Parser::semantic_type *yylval = nullptr;

  public:
    // Constructors
    Mlisp_Scanner(std::istream *in)
    : yyFlexLexer(in) {};

    // Destructors
    virtual ~Mlisp_Scanner() {};

    // Get rid of override virtual function warning
    using FlexLexer::yylex;

    virtual
    int yylex(Mlisp_Parser::semantic_type * const lval, 
              Mlisp_Parser::location_type * location);
    // YY_DECL defined in mlisp.l
    // Method body created by flex in mlisp.yy.cc
};

} /* end namespace MC */

#endif /* END __MLISPSCANNER_HPP__ */