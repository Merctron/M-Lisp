%skeleton "lalr1.cc"
%require  "3.0"
%debug 
%defines 
%define api.namespace     { Mlisp        }
%define parser_class_name { Mlisp_Parser }

%code requires {

namespace Mlisp {
    class Mlisp_Driver;
    class Mlisp_Scanner;
}

// The following definitions are missing when %locations isn't used
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

%code {

#include <iostream>
#include <cstdlib>
#include <fstream>

/* include for all driver functions */
#include "mlisp_driver.hpp"

#undef yylex
#define yylex scanner.yylex

}

%{

#include <string>
#include <unordered_map>

/* NODE_TYPE enum */
enum NODE_TYPE {
    ADD_NODE,
    SUB_NODE,
    MUL_NODE,
    DIV_NODE,
    DEF_NODE,
    WORD_NODE,
    BOOL_NODE,
    NUMBER_NODE
};

/* AST struct */
struct TREE_NODE {
    enum NODE_TYPE type;
    union {
        int               intValue;
        std::string      *strValue;
        bool              boolValue;
        struct TREE_NODE *args[10];
    };
};

/* ENV struct */
struct ENV {
    std::unordered_map<std::string, TREE_NODE> envMap;
};

/* CLASS TYPES */
typedef struct TREE_NODE TREE_NODE;
typedef struct ENV ENV;

/* CLASS METHODS */
TREE_NODE * eval(TREE_NODE *node, ENV *env);

%}

// %define api.value.type variant
%define parse.assert

%token               END    0     "end of file"
%token               OPENPAR
%token               CLOSEPAR
%token               PLUS
%token               MINUS
%token               MUL
%token               DIV
%token               MOD
%token               GREATER
%token               LESS
%token               EQL
%token               DEF
%token <str_val>     WORD
%token               NEWLINE
%token <int_val>     NUMBER

%type  <node_val>    item
%type  <node_val>    expression

%union {
    int               int_val;
    std::string      *str_val;
    struct TREE_NODE *node_val;
}

%locations

%%

list_option : END | list END;

list
  : expression
    {
        TREE_NODE * node = eval($1, nullptr);

        switch (node->type) {
            case NUMBER_NODE:
                std::cout << node->intValue;
                break;
            case BOOL_NODE:
                std::cout << node->boolValue;
                break;
        }

        std::cout << std::endl;
    }
  | list expression
  ;

expression
  : OPENPAR PLUS expression expression CLOSEPAR
    {
        TREE_NODE * node = new TREE_NODE();
        node->type       = ADD_NODE;
        node->args[0]    = $3;
        node->args[1]    = $4; 
        $$               = node;
    }
  | OPENPAR MINUS expression expression CLOSEPAR
    {
        TREE_NODE * node = new TREE_NODE();
        node->type       = SUB_NODE;
        node->args[0]    = $3;
        node->args[1]    = $4; 
        $$               = node;
    }
  | OPENPAR MUL expression expression CLOSEPAR
    {
        TREE_NODE * node = new TREE_NODE();
        node->type       = MUL_NODE;
        node->args[0]    = $3;
        node->args[1]    = $4; 
        $$               = node;
    }
  | OPENPAR DIV expression expression CLOSEPAR
    {
        TREE_NODE * node = new TREE_NODE();
        node->type       = DIV_NODE;
        node->args[0]    = $3;
        node->args[1]    = $4; 
        $$               = node;
    }
  | OPENPAR MOD expression expression CLOSEPAR
    {
        driver.add_expression();
        TREE_NODE * nodeA = $3;
        TREE_NODE * nodeB = $4;
        std::cout << "MOD: " << nodeA->intValue % nodeB->intValue << std::endl;

        nodeA->intValue = nodeA->intValue % nodeB->intValue;
        $$ = nodeA;
    }
  | OPENPAR GREATER expression expression CLOSEPAR
    {
        driver.add_expression();
        TREE_NODE * nodeA = $3;
        TREE_NODE * nodeB = $4;
        std::cout << "GR8: " << (nodeA->intValue > nodeB->intValue) << std::endl;

        nodeA->boolValue = nodeA->intValue > nodeB->intValue;
        nodeA->type      = BOOL_NODE;
        $$ = nodeA;
    }
  | OPENPAR LESS expression expression CLOSEPAR
    {
        driver.add_expression();
        TREE_NODE * nodeA = $3;
        TREE_NODE * nodeB = $4;
        std::cout << "LES: " << (nodeA->intValue < nodeB->intValue) << std::endl;

        nodeA->boolValue = nodeA->intValue < nodeB->intValue;
        nodeA->type      = BOOL_NODE;
        $$ = nodeA;
    }
  | item    { $$ = $1;       }
  | NEWLINE { driver.prompt(); }
  ;

item
  : WORD    {
                driver.add_word(*$1);
                TREE_NODE * node = new TREE_NODE();
                node->intValue   = 1;
                node->type       = NUMBER_NODE;

                $$ = node;
            }
  | NUMBER  {
                TREE_NODE * node = new TREE_NODE();
                node->intValue   = $1;
                node->type       = NUMBER_NODE;

                $$ = node;
            }
  ;

%%

TREE_NODE * eval(TREE_NODE *node, ENV *env)
{
    switch (node->type) {
        case ADD_NODE:
        {
            TREE_NODE *argOne = eval(node->args[0], env);
            TREE_NODE *argTwo = eval(node->args[1], env);
            TREE_NODE *result = new TREE_NODE();
            result->type      = NUMBER_NODE;
            result->intValue  = argOne->intValue + argTwo->intValue;
            return result;
        }
        case SUB_NODE:
        {
            TREE_NODE *argOne = eval(node->args[0], env);
            TREE_NODE *argTwo = eval(node->args[1], env);
            TREE_NODE *result = new TREE_NODE();
            result->type      = NUMBER_NODE;
            result->intValue  = argOne->intValue - argTwo->intValue;
            return result;
        }
        case MUL_NODE:
        {
            TREE_NODE *argOne = eval(node->args[0], env);
            TREE_NODE *argTwo = eval(node->args[1], env);
            TREE_NODE *result = new TREE_NODE();
            result->type      = NUMBER_NODE;
            result->intValue  = argOne->intValue * argTwo->intValue;
            return result;
        }
        case DIV_NODE:
        {
            TREE_NODE *argOne = eval(node->args[0], env);
            TREE_NODE *argTwo = eval(node->args[1], env);
            TREE_NODE *result = new TREE_NODE();
            result->type      = NUMBER_NODE;
            result->intValue  = argOne->intValue / argTwo->intValue;
            return result;
        }
        case DEF_NODE:
            return node;
        case WORD_NODE:
            return node;
        case BOOL_NODE:
            return node;
        case NUMBER_NODE:
            return node;
    }
}

void 
Mlisp::Mlisp_Parser::error(const location_type &l,
                           const std::string   &err_message)
{
   std::cerr << "Error: " << err_message << " at " << l << "\n";
   driver.prompt();
}