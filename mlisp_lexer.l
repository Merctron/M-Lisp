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

"("           {
                  return token::OPENPAR;
              }

")"           {
                  return token::CLOSEPAR;
              }

"+"           {
                  return token::PLUS;
              }

"-"           {
                  return token::MINUS;
              }

"*"           {
                  return token::MUL;
              }

"/"           {
                  return token::DIV;
              }

"def"         {
                  return token::DEF;
              }

"lambda"      {
                  return token::LAMBDA;
              }

"atom"        {
                  return token::ATOM;
}

0|[1-9][0-9]* {
                  yylval->int_val = atoi(yytext);
                  return(token::NUMBER);
              }

[a-zA-Z]+     {
                  /**
                  * Section 10.1.5.1 of the 3.0.2 Bison Manual says the 
                  * following should work:
                  * yylval.build( yytext );
                  * but it doesn't.
                  * ref: http://goo.gl/KLn0w2
                  */
                  // yylval->build<std::string>(yytext);
                  yylval->str_val = new std::string(yytext);
                  return(token::WORD);
              }

\n            {
                  // Update line number
                  return(token::NEWLINE);
              }

[ \t]         {
                  /* Discard spaces, tabs, and new lines */
              }

[;].*[\n]     {

              }

%%