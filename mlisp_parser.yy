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
#include <vector>

/* NODE_TYPE enum */
enum NODE_TYPE {
    ADD_NODE,
    SUB_NODE,
    MUL_NODE,
    DIV_NODE,
    DEF_NODE,
    WORD_NODE,
    BOOL_NODE,
    CALL_NODE,
    NUMBER_NODE
};

/* ARG_LIST struct */
struct ARG_LIST {
    std::vector<std::string *> arguments;
};

/* EXPR_LIST struct */
struct EXPR_LIST {
    std::vector<struct TREE_NODE *> expressions;
};

/* LAMBDA struct */
struct LAMBDA {
    struct ARG_LIST     *args;
    struct TREE_NODE    *expr;
};

/* DEF struct */
struct DEF {
    std::string         *name;
    struct TREE_NODE    *expr;
};

struct NON_ATOM {
    std::string *strValue;
    union {
        struct TREE_NODE *expr;
        struct EXPR_LIST *exprList;
        struct ARG_LIST  *argList;
    };
};

/* AST struct */
struct TREE_NODE {
    enum NODE_TYPE type;
    union {
        int              intValue;
        std::string     *strValue;
        struct NON_ATOM *nonAtom; 
    };
};

/* ENV struct */
struct ENV {
    std::unordered_map<std::string, struct TREE_NODE *> definitions;
};

/* CLASS TYPES */
typedef struct TREE_NODE TREE_NODE;
typedef struct ARG_LIST  ARG_LIST;
typedef struct EXPR_LIST EXPR_LIST;
typedef struct LAMBDA    LAMBDA;
typedef struct ENV       ENV;

/* CLASS DATA */
ENV k_GLOBAL_ENV;

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
%type  <exps_val>    expressions
%type  <args_val>    arguments

%union {
    int               int_val;
    std::string      *str_val;
    struct TREE_NODE *node_val;
    struct EXPR_LIST *exps_val;
    struct ARG_LIST  *args_val;
}

%locations

%%

list_option : END | list END;

list
  : expression
    {
        TREE_NODE * node = eval($1, nullptr);

        if (node) {
            switch (node->type) {
                case NUMBER_NODE:
                    std::cout << node->intValue;
                    break;
            }

            std::cout << std::endl;
        }

    }
  | list expression
  ;

expression
  : OPENPAR DEF WORD expression CLOSEPAR
    {
        TREE_NODE *node         = new TREE_NODE();
        node->type              = DEF_NODE;
        node->nonAtom           = new NON_ATOM();
        node->nonAtom->strValue = $3;
        node->nonAtom->expr     = $4;
        $$                      = node;
    }
  | OPENPAR PLUS expression expression CLOSEPAR
    {
        TREE_NODE *node = new TREE_NODE();
        node->type      = ADD_NODE;

        node->nonAtom            = new NON_ATOM();
        node->nonAtom->exprList = new EXPR_LIST();
        node->nonAtom->exprList->expressions.push_back($3);
        node->nonAtom->exprList->expressions.push_back($4);
        $$ = node;
    }
  | OPENPAR MINUS expression expression CLOSEPAR
    {
        TREE_NODE * node = new TREE_NODE();
        node->type       = SUB_NODE;

        node->nonAtom            = new NON_ATOM();
        node->nonAtom->exprList = new EXPR_LIST();
        node->nonAtom->exprList->expressions.push_back($3);
        node->nonAtom->exprList->expressions.push_back($4);
        $$ = node;
    }
  | OPENPAR MUL expression expression CLOSEPAR
    {
        TREE_NODE * node = new TREE_NODE();
        node->type       = MUL_NODE;

        node->nonAtom            = new NON_ATOM();
        node->nonAtom->exprList = new EXPR_LIST();
        node->nonAtom->exprList->expressions.push_back($3);
        node->nonAtom->exprList->expressions.push_back($4);
        $$ = node;
    }
  | OPENPAR DIV expression expression CLOSEPAR
    {
        TREE_NODE * node = new TREE_NODE();
        node->type       = DIV_NODE;

        node->nonAtom            = new NON_ATOM();
        node->nonAtom->exprList = new EXPR_LIST();
        node->nonAtom->exprList->expressions.push_back($3);
        node->nonAtom->exprList->expressions.push_back($4);
        $$ = node;
    }
  | OPENPAR WORD expressions CLOSEPAR
    {

        $$ = nullptr;
    }
  | item    { $$ = $1;       }
  | NEWLINE { driver.prompt(); }
  ;

item
  : WORD    
    {
        // driver.add_word(*$1);
        TREE_NODE * node = new TREE_NODE();
        node->strValue   = $1;
        node->type       = WORD_NODE;

        $$ = node;
    }
  | NUMBER  
    {
        TREE_NODE * node = new TREE_NODE();
        node->intValue   = $1;
        node->type       = NUMBER_NODE;

        $$ = node;
    }
  ;

expressions
  : expression 
    {
        EXPR_LIST * exprList = new EXPR_LIST();
        exprList->expressions.push_back($1);
        $$ = exprList;
    }
  | expressions expression
    {
        EXPR_LIST * exprList = $1;
        exprList->expressions.push_back($2);
        $$ = exprList;
    }
  ;

arguments
  : WORD 
    {
        ARG_LIST * argList = new ARG_LIST();
        argList->arguments.emplace_back(*$1);
        $$ = argList;
    }
  | arguments WORD
    {
        ARG_LIST * argList = $1;
        argList->arguments.emplace_back(*$2);
        $$ = argList;
    }
  ;

%%

TREE_NODE * eval(TREE_NODE *node, ENV *env)
{
    switch (node->type) {
        case CALL_NODE:
        {
            // // First evaluate all arguments to final state
            // for (int i = 0; i < node->expressions->expressions->size(); i++) {
            //     node->expressions->expressions[i] = eval(node->expressions->expressions[i]);
            // }

            // // Find lambda declaration in the environment
            // LAMBDA * lambda = environment.lambdas.at(*(node->lambdaName));

            // // Map lambda arguments to those passed in
        }
        case ADD_NODE:
        {
            TREE_NODE *argOne = eval(node->nonAtom->exprList->expressions[0], env);
            TREE_NODE *argTwo = eval(node->nonAtom->exprList->expressions[1], env);
            TREE_NODE *result = new TREE_NODE();
            result->type      = NUMBER_NODE;
            result->intValue  = argOne->intValue + argTwo->intValue;
            return result;
        }
        case SUB_NODE:
        {
            TREE_NODE *argOne = eval(node->nonAtom->exprList->expressions[0], env);
            TREE_NODE *argTwo = eval(node->nonAtom->exprList->expressions[1], env);
            TREE_NODE *result = new TREE_NODE();
            result->type      = NUMBER_NODE;
            result->intValue  = argOne->intValue - argTwo->intValue;
            return result;
        }
        case MUL_NODE:
        {
            TREE_NODE *argOne = eval(node->nonAtom->exprList->expressions[0], env);
            TREE_NODE *argTwo = eval(node->nonAtom->exprList->expressions[1], env);
            TREE_NODE *result = new TREE_NODE();
            result->type      = NUMBER_NODE;
            result->intValue  = argOne->intValue * argTwo->intValue;
            return result;
        }
        case DIV_NODE:
        {
            TREE_NODE *argOne = eval(node->nonAtom->exprList->expressions[0], env);
            TREE_NODE *argTwo = eval(node->nonAtom->exprList->expressions[1], env);
            TREE_NODE *result = new TREE_NODE();
            result->type      = NUMBER_NODE;
            result->intValue  = argOne->intValue / argTwo->intValue;
            return result;
        }
        case DEF_NODE:
            if (env) {
                env->definitions.insert({ *(node->nonAtom->strValue), 
                                                node->nonAtom->expr });
                return nullptr;
            }
            k_GLOBAL_ENV.definitions.insert({ *(node->nonAtom->strValue), 
                                                node->nonAtom->expr });
            return nullptr;
        case WORD_NODE:
            if (env) {
                return env->definitions.find(*(node->strValue))->second;
            }
            return k_GLOBAL_ENV.definitions.find(*(node->strValue))->second;
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