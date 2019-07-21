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
    SET_NODE,
    WORD_NODE,
    ATOM_NODE,
    CALL_NODE,
    LIST_NODE,
    LAMBDA_NODE,
    QUOTE_NODE,
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

/* DEF struct */
struct DEF {
    std::string         *name;
    struct TREE_NODE    *expr;
};

/* NON_ATOM struct */
struct NON_ATOM {
    union {
        std::string     *strValue;
        struct ARG_LIST *argList;
    };
    union {
        struct TREE_NODE *expr;
        struct EXPR_LIST *exprList;
    };
};

/* AST struct */
struct TREE_NODE {
    enum NODE_TYPE type;
    union {
        int               intValue;
        std::string      *strValue;
        struct NON_ATOM  *nonAtom; 
        struct EXPR_LIST *list;
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
typedef struct ENV       ENV;

/* CLASS DATA */
ENV k_GLOBAL_ENV;

/* CLASS METHODS */
void        printNode(TREE_NODE *node);
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
%token               DEF
%token               SET
%token               LAMBDA
%token               QUOTE
%token               ATOM
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
        TREE_NODE * node = eval($1, &k_GLOBAL_ENV);

        if (node) {
            printNode(node);
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
  | OPENPAR SET WORD expression CLOSEPAR
    {
        TREE_NODE *node         = new TREE_NODE();
        node->type              = SET_NODE;
        node->nonAtom           = new NON_ATOM();
        node->nonAtom->strValue = $3;
        node->nonAtom->expr     = $4;
        $$                      = node;
    }
  | OPENPAR LAMBDA OPENPAR arguments CLOSEPAR expression CLOSEPAR
    {
        TREE_NODE *node         = new TREE_NODE();
        node->type              = LAMBDA_NODE;
        node->nonAtom           = new NON_ATOM();
        node->nonAtom->argList  = $4;
        node->nonAtom->expr     = $6;
        $$                      = node;
    }
  | OPENPAR QUOTE expression CLOSEPAR
    {
        TREE_NODE *node         = new TREE_NODE();
        node->type              = QUOTE_NODE;
        node->nonAtom           = new NON_ATOM();
        node->nonAtom->expr     = $3;
        $$                      = node;
    }
  | OPENPAR ATOM expression CLOSEPAR
    {
        TREE_NODE *node         = new TREE_NODE();
        node->type              = ATOM_NODE;
        node->nonAtom           = new NON_ATOM();
        node->nonAtom->expr     = $3;
        $$                      = node;
    }
  | OPENPAR WORD expressions CLOSEPAR
    {
        TREE_NODE *node         = new TREE_NODE();
        node->type              = CALL_NODE;
        node->nonAtom           = new NON_ATOM();
        node->nonAtom->strValue = $2;
        node->nonAtom->exprList = $3;
        $$                      = node;
    }
  | OPENPAR expressions CLOSEPAR
    {
        TREE_NODE *node         = new TREE_NODE();
        node->type              = LIST_NODE;
        node->list              = $2;
        $$                      = node;
    }
  | OPENPAR PLUS expression expression CLOSEPAR
    {
        TREE_NODE *node = new TREE_NODE();
        node->type      = ADD_NODE;

        node->nonAtom           = new NON_ATOM();
        node->nonAtom->exprList = new EXPR_LIST();
        node->nonAtom->exprList->expressions.push_back($3);
        node->nonAtom->exprList->expressions.push_back($4);
        $$ = node;
    }
  | OPENPAR MINUS expression expression CLOSEPAR
    {
        TREE_NODE * node = new TREE_NODE();
        node->type       = SUB_NODE;

        node->nonAtom           = new NON_ATOM();
        node->nonAtom->exprList = new EXPR_LIST();
        node->nonAtom->exprList->expressions.push_back($3);
        node->nonAtom->exprList->expressions.push_back($4);
        $$ = node;
    }
  | OPENPAR MUL expression expression CLOSEPAR
    {
        TREE_NODE * node = new TREE_NODE();
        node->type       = MUL_NODE;

        node->nonAtom           = new NON_ATOM();
        node->nonAtom->exprList = new EXPR_LIST();
        node->nonAtom->exprList->expressions.push_back($3);
        node->nonAtom->exprList->expressions.push_back($4);
        $$ = node;
    }
  | OPENPAR DIV expression expression CLOSEPAR
    {
        TREE_NODE * node = new TREE_NODE();
        node->type       = DIV_NODE;

        node->nonAtom           = new NON_ATOM();
        node->nonAtom->exprList = new EXPR_LIST();
        node->nonAtom->exprList->expressions.push_back($3);
        node->nonAtom->exprList->expressions.push_back($4);
        $$ = node;
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
        argList->arguments.emplace_back($1);
        $$ = argList;
    }
  | arguments WORD
    {
        ARG_LIST * argList = $1;
        argList->arguments.emplace_back($2);
        $$ = argList;
    }
  ;

%%

void printNode(TREE_NODE *node)
{
    switch (node->type) {
        case LAMBDA_NODE:
        {
            std::cout << "(lambda (";
            for (size_t i = 0;
                 i < node->nonAtom->argList->arguments.size(); i++) {
                std::cout << node->nonAtom->argList->arguments[i];
                if (i < node->nonAtom->argList->arguments.size() - 1) {
                    std::cout << " ";
                }
            }
            std::cout << ") ";
            printNode(node->nonAtom->expr);
            std::cout << ")";
            break;
        }
        case LIST_NODE:
        {
            std::cout << "(";
            for (size_t i = 0;
                 i < node->list->expressions.size(); i++) {
                printNode(node->list->expressions[i]);
                if (i < node->list->expressions.size() - 1) {
                    std::cout << " ";
                }
            }
            std::cout << ")";
            break;
        }
        case CALL_NODE:
        {
            std::cout << "(" << *(node->nonAtom->strValue) << " ";
            for (size_t i = 0;
                 i < node->nonAtom->exprList->expressions.size(); i++) {
                printNode(node->nonAtom->exprList->expressions[i]);
                if (i < node->nonAtom->exprList->expressions.size() - 1) {
                    std::cout << " ";
                }
            }
            std::cout << ")";
            break;
        }
        case ADD_NODE:
        {
            std::cout << "(+ ";
            printNode(node->nonAtom->exprList->expressions[0]);
            std::cout << " ";
            printNode(node->nonAtom->exprList->expressions[1]);
            std::cout << ")";
            break;
        }
        case SUB_NODE:
        {
            std::cout << "(- ";
            printNode(node->nonAtom->exprList->expressions[0]);
            std::cout << " ";
            printNode(node->nonAtom->exprList->expressions[1]);
            std::cout << ")";
            break;
        }
        case MUL_NODE:
        {
            std::cout << "(* ";
            printNode(node->nonAtom->exprList->expressions[0]);
            std::cout << " ";
            printNode(node->nonAtom->exprList->expressions[1]);
            std::cout << ")";
            break;
        }
        case DIV_NODE:
        {
            std::cout << "(/ ";
            printNode(node->nonAtom->exprList->expressions[0]);
            std::cout << " ";
            printNode(node->nonAtom->exprList->expressions[1]);
            std::cout << ")";
            break;
        }
        case DEF_NODE:
        {
            std::cout << "(def " << *(node->nonAtom->strValue) << " ";
            printNode(node->nonAtom->expr);
            std::cout << ")";
            break;
        }
        case SET_NODE:
        {
            std::cout << "(set " << *(node->nonAtom->strValue) << " ";
            printNode(node->nonAtom->expr);
            std::cout << ")";
            break;
        }
        case WORD_NODE:
        {
            std::cout << *(node->strValue);
            break;
        }
        case NUMBER_NODE:
        {
            std::cout << node->intValue;
            break;
        }
        case ATOM_NODE:
        {
            std::cout << "(atom ";
            printNode(node->nonAtom->expr);
            std::cout << ")";
            break;
        }
        case QUOTE_NODE:
        {
            std::cout << "(quote ";
            printNode(node->nonAtom->expr);
            std::cout << ")";
            break;
        }
    }
}

TREE_NODE * eval(TREE_NODE *node, ENV *env)
{
    switch (node->type) {
        case LAMBDA_NODE:
        {
            return nullptr;
        }
        case LIST_NODE:
        {
            return nullptr;
        }
        case CALL_NODE:
        {
            // First evaluate all arguments to final state
            for (size_t i = 0;
                 i < node->nonAtom->exprList->expressions.size(); i++) {
                node->nonAtom->exprList->expressions[i] =
                                eval(node->nonAtom->exprList->expressions[i], env);
            }

            // Find lambda declaration in the environment
            ENV       *newEnv = new ENV();
            TREE_NODE *lambda;
            if (env) {
                newEnv->definitions.insert(env->definitions.begin(), env->definitions.end());
                lambda = env->definitions.find(*(node->nonAtom->strValue))->second;
            }
            else {
                newEnv->definitions.insert(k_GLOBAL_ENV.definitions.begin(),
                                           k_GLOBAL_ENV.definitions.end());
                lambda = k_GLOBAL_ENV.definitions.find(*(node->nonAtom->strValue))->second;
            }

            // Map arguments to expression in a new environment
            for (size_t i = 0;
                 i < node->nonAtom->exprList->expressions.size(); i++) {
                newEnv->definitions.insert({ *(lambda->nonAtom->argList->arguments[i]),
                                               node->nonAtom->exprList->expressions[i] });
            }

            // return the evaluation of the lambda
            return eval(lambda->nonAtom->expr, newEnv);
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
        {
            env->definitions.insert({
                *(node->nonAtom->strValue),
                node->nonAtom->expr
            });
            return nullptr;
        }
        case SET_NODE:
        {
            if (env->definitions.count(*(node->nonAtom->strValue))) {
                env->definitions[*(node->nonAtom->strValue)] =
                    node->nonAtom->expr;
            }
            else {
                if (k_GLOBAL_ENV.definitions.count(*(node->nonAtom->strValue))) {
                    k_GLOBAL_ENV.definitions[*(node->nonAtom->strValue)] =
                        node->nonAtom->expr;
                }
            }
            return nullptr;
        }
        case WORD_NODE:
        {
            if (env) {
                return env->definitions.find(*(node->strValue))->second;
            }
            return k_GLOBAL_ENV.definitions.find(*(node->strValue))->second;
        }
        case NUMBER_NODE:
        {
            return node;
        }
        case ATOM_NODE:
        {
            TREE_NODE *evalNode = eval(node->nonAtom->expr, env);
            TREE_NODE *newNode  = new TREE_NODE();
            newNode->type       = NUMBER_NODE;
            newNode->intValue   = 0;
            if (evalNode) {
                if (evalNode->type == NUMBER_NODE) {
                    newNode->intValue = 1;
                }
            }
            return newNode;
        }
        case QUOTE_NODE:
        {
            return node->nonAtom->expr;
        }
    }

    return nullptr;
}

void 
Mlisp::Mlisp_Parser::error(const location_type &l,
                           const std::string   &err_message)
{
   std::cerr << "Error: " << err_message << " at " << l << "\n";
   driver.prompt();
}