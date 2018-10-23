%{
/* C++ string header, for string ops below */
#include <string>

/* Implementation of yyFlexScanner */ 
#include "mlisp_scanner.hpp"
#undef  YY_DECL
#define YY_DECL int Mlisp::Mlisp_Scanner::yylex(Mlisp::Mlisp_Parser::semantic_type * const lval, Mlisp::Mlisp_Parser::location_type *loc)

/* typedef to make the returns for the tokens shorter */
using token = Mlisp::Mlisp_Parser::token;

/* define yyterminate as this instead of NULL */
#define yyterminate() return( token::END )

/* msvc2010 requires that we exclude this header file. */
#define YY_NO_UNISTD_H

/* update location on matching */
#define YY_USER_ACTION loc->step(); loc->columns(yyleng);

%}

%option debug
%option nodefault
%option yyclass="Mlisp::Mlisp_Scanner"
%option noyywrap
%option c++

%%
%{          /** Code executed at the beginning of yylex **/
            yylval = lval;
%}

"(" {
  return token::OPENPAR;
}

")" {
  return token::CLOSEPAR;
}

[a-z]       {
               return( token::LOWER );
            }

[A-Z]       {
               return( token::UPPER );
            }

[a-zA-Z]+   {
               /**
                * Section 10.1.5.1 of the 3.0.2 Bison Manual says the 
                * following should work:
                * yylval.build( yytext );
                * but it doesn't.
                * ref: http://goo.gl/KLn0w2
                */
               yylval->build< std::string >( yytext );
               return( token::WORD );
            }

\n          {
               // Update line number
               loc->lines();
               return( token::NEWLINE );
            }

.           {
               return( token::CHAR );
            }
%%