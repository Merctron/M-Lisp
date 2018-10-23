%skeleton "lalr1.cc"
%require  "3.0"
%debug 
%defines 
%define api.namespace { Mlisp }
%define parser_class_name { Mlisp_Parser }

%code requires {
   namespace Mlisp {
      class Mlisp_Driver;
      class Mlisp_Scanner;
   }

// The following definitions is missing when %locations isn't used
# ifndef YY_NULLPTR
#  if defined __cplusplus && 201103L <= __cplusplus
#   define YY_NULLPTR nullptr
#  else
#   define YY_NULLPTR 0
#  endif
# endif

}

%parse-param { Mlisp_Scanner  &scanner  }
%parse-param { Mlisp_Driver   &driver   }

%code{
   #include <iostream>
   #include <cstdlib>
   #include <fstream>
   
   /* include for all driver functions */
   #include "Mlisp_driver.hpp"

#undef yylex
#define yylex scanner.yylex
}

%define api.value.type variant
%define parse.assert

%token               END    0     "end of file"
%token               OPENPAR
%token               CLOSEPAR
%token               UPPER
%token               LOWER
%token <std::string> WORD
%token               NEWLINE
%token               CHAR

%locations

%%

list_option : END | list END;

list
  : item
  | expression
  | list item
  | list expression
  ;

item
  : UPPER   { driver.add_upper();    }
  | LOWER   { driver.add_lower();    }
  | WORD    { driver.add_word( $1 ); }
  | NEWLINE { driver.add_newline();  }
  | CHAR    { driver.add_char();     }
  /*| OPENPAR  { driver.add_expression(); }
  | CLOSEPAR { driver.add_expression(); }*/
  ;

expression
  : OPENPAR CLOSEPAR {
    driver.add_expression();
  }
  ;

%%
void 
Mlisp::Mlisp_Parser::error( const location_type &l, const std::string &err_message )
{
   std::cerr << "Error: " << err_message << " at " << l << "\n";
}