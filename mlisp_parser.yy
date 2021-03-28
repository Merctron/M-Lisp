%skeleton "lalr1.cc"
%require  "3.0"
%debug 
%defines 
%define api.namespace    { Mlisp        }
%define api.parser.class { Mlisp_Parser }

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
#include <functional>

/* NODE_TYPE enum */
enum NODE_TYPE {
    PROC_NODE,
    LIST_NODE,
    BOOL_NODE,
    STRING_NODE,
    NUMBER_NODE,
    LAMBDA_NODE
};

/* TREE_NODE struct */
struct TREE_NODE
{
    NODE_TYPE type;
    union {
        bool                                     boolValue;
        int                                      intValue;
        std::string                             *strValue;
        std::vector<struct TREE_NODE *>         *list;
        struct LAMBDA                           *lambda;
    };
};

struct LAMBDA
{
    struct TREE_NODE                *expr;
    std::vector<struct TREE_NODE *> *vars;
};

/* CLASS TYPES */
typedef struct TREE_NODE TREE_NODE;
typedef struct LAMBDA    LAMBDA;
typedef struct ENV       ENV;
typedef std::function<TREE_NODE *(TREE_NODE *)> FUNC;

/* ENV struct */
struct ENV {
    std::unordered_map<std::string, FUNC> definitions;
    ENV(ENV * oldEnv=nullptr) {
        if (!oldEnv) {
            definitions.insert({
                "+",
                [](TREE_NODE * list)->TREE_NODE* {
                    TREE_NODE * result = new TREE_NODE();
                    result->type = NUMBER_NODE;
                    std::vector<struct TREE_NODE *> ops = *(list->list);
                    result->intValue = ops[0]->intValue + ops[1]->intValue;
                    return result;
                }
            });
            definitions.insert({
                "-",
                [](TREE_NODE * list)->TREE_NODE* {
                    TREE_NODE * result = new TREE_NODE();
                    result->type = NUMBER_NODE;
                    std::vector<struct TREE_NODE *> ops = *(list->list);
                    result->intValue = ops[0]->intValue - ops[1]->intValue;
                    return result;
                }
            });
            definitions.insert({
                "*",
                [](TREE_NODE * list)->TREE_NODE* {
                    TREE_NODE * result = new TREE_NODE();
                    result->type = NUMBER_NODE;
                    std::vector<struct TREE_NODE *> ops = *(list->list);
                    result->intValue = ops[0]->intValue * ops[1]->intValue;
                    return result;
                }
            });
            definitions.insert({
                "/",
                [](TREE_NODE * list)->TREE_NODE* {
                    TREE_NODE * result = new TREE_NODE();
                    result->type = NUMBER_NODE;
                    std::vector<struct TREE_NODE *> ops = *(list->list);
                    result->intValue = ops[0]->intValue / ops[1]->intValue;
                    return result;
                }
            });
            definitions.insert({
                "<",
                [](TREE_NODE * list)->TREE_NODE* {
                    TREE_NODE * result = new TREE_NODE();
                    result->type = BOOL_NODE;
                    std::vector<struct TREE_NODE *> ops = *(list->list);
                    result->boolValue = ops[0]->intValue < ops[1]->intValue;
                    return result;
                }
            });
            definitions.insert({
                ">",
                [](TREE_NODE * list)->TREE_NODE* {
                    TREE_NODE * result = new TREE_NODE();
                    result->type = BOOL_NODE;
                    std::vector<struct TREE_NODE *> ops = *(list->list);
                    result->boolValue = ops[0]->intValue > ops[1]->intValue;
                    return result;
                }
            });
            definitions.insert({
                "<=",
                [](TREE_NODE * list)->TREE_NODE* {
                    TREE_NODE * result = new TREE_NODE();
                    result->type = BOOL_NODE;
                    std::vector<struct TREE_NODE *> ops = *(list->list);
                    result->boolValue = ops[0]->intValue <= ops[1]->intValue;
                    return result;
                }
            });
            definitions.insert({
                ">=",
                [](TREE_NODE * list)->TREE_NODE* {
                    TREE_NODE * result = new TREE_NODE();
                    result->type = BOOL_NODE;
                    std::vector<struct TREE_NODE *> ops = *(list->list);
                    result->boolValue = ops[0]->intValue >= ops[1]->intValue;
                    return result;
                }
            });
            definitions.insert({
                "=",
                [](TREE_NODE * list)->TREE_NODE* {
                    TREE_NODE * result = new TREE_NODE();
                    result->type = BOOL_NODE;
                    std::vector<struct TREE_NODE *> ops = *(list->list);
                    result->boolValue = ops[0]->intValue == ops[1]->intValue;
                    return result;
                }
            });
        }
        else {
            definitions.insert(oldEnv->definitions.begin(), oldEnv->definitions.end());
        }
    }
};

/* CLASS DATA */
ENV k_GLOBAL_ENV;

/* CLASS METHODS */
void        printNode(TREE_NODE *node);
TREE_NODE * eval(TREE_NODE *node, ENV *env);
TREE_NODE * processReserved(TREE_NODE *node, ENV *env);

%}

// %define api.value.type variant
%define parse.assert

%token               END    0     "end of file"
%token               OPENPAR
%token               CLOSEPAR
%token <str_val>     STRING
%token               SEP
%token <int_val>     NUMBER

%type  <node_val>    item
%type  <node_val>    expression
%type  <node_val>    expressions

%union {
    int               int_val;
    std::string      *str_val;
    struct TREE_NODE *node_val;
}

%start program

%locations

%%

program : END | lists END;

lists
  : expression
    {
        TREE_NODE * node = eval($1, &k_GLOBAL_ENV);
        if (node) {
            printNode(node);
            std::cout << std::endl;
        }
    }
  | lists expression
    {
        TREE_NODE * node = eval($2, &k_GLOBAL_ENV);
        if (node) {
            printNode(node);
            std::cout << std::endl;
        }
    }
  ;

expression
  : OPENPAR expressions CLOSEPAR
    {
        $$ = $2;
    }
  | item        {
        $$ = $1;
    }
  ;

item
  : STRING    
    {
        TREE_NODE * node = new TREE_NODE();
        node->strValue   = $1;
        node->type       = STRING_NODE;
        $$               = node;
    }
  | NUMBER  
    {
        TREE_NODE * node = new TREE_NODE();
        node->intValue   = $1;
        node->type       = NUMBER_NODE;
        $$               = node;
    }
  ;

expressions
  : expression 
    {
        TREE_NODE * list = new TREE_NODE();
        list->type = LIST_NODE;
        list->list = new std::vector<struct TREE_NODE *>();
        list->list->push_back($1);
        $$ = list;
    }
  | expressions expression
    {
        TREE_NODE * list = $1;
        list->list->push_back($2);
        $$ = list;
    }
  ;

%%

void printNode(TREE_NODE *node)
{
    switch (node->type) {
        case LIST_NODE:
        {
            std::cout << "(";
            std::vector<struct TREE_NODE *> &list = *(node->list);
            for (int i = 0; i < list.size(); i++) {
                printNode(list[i]);
                if (i < list.size() - 1) {
                    std::cout << " ";
                }
            }
            std::cout << ")";
            break;
        }
        case BOOL_NODE:
        {
            std::cout << node->boolValue;
            break;
        }
        case STRING_NODE:
        {
            std::cout << *(node->strValue);
            break;
        }
        case NUMBER_NODE:
        {
            std::cout << node->intValue;
            break;
        }
        case PROC_NODE:
        {
            break;
        }
        case LAMBDA_NODE:
        {
            break;
        }
    }
}

TREE_NODE * eval(TREE_NODE *node, ENV *env)
{
    switch (node->type) {
        case LIST_NODE:
        {
            std::vector<struct TREE_NODE *> &list = *(node->list);
            TREE_NODE * expr = list[0];
            if (expr->type == STRING_NODE) {
                TREE_NODE * procNode = processReserved(node, env);
                if (procNode) {
                    if (procNode->type == PROC_NODE) {
                        return nullptr;
                    }
                    else {
                        return procNode;
                    }
                }

                TREE_NODE * evalList = new TREE_NODE();
                evalList->type = LIST_NODE;
                evalList->list = new std::vector<struct TREE_NODE *>();
                for (int i = 1; i < list.size(); i++) {
                    evalList->list->push_back(eval(list[i], env));
                }
                
                return env->definitions.find(*expr->strValue)->second(evalList);
            }
            break;
        }
        case BOOL_NODE:
        {
            return node;
        }
        case STRING_NODE:
        {
            TREE_NODE * result = env->definitions.find(*node->strValue)->second(nullptr);
            if (result) {
                return result;
            }
            return node;
        }
        case NUMBER_NODE:
        {
            return node;
        }
        case PROC_NODE:
        {
            break;
        }
        case LAMBDA_NODE:
        {
            break;
        }
    }

    return nullptr;
}

TREE_NODE * processReserved(TREE_NODE *node, ENV *env) {
    std::vector<struct TREE_NODE *> &list = *(node->list);
    std::string &id = *(list[0]->strValue);

    if (id == "atom" && list.size() == 2) {
        TREE_NODE * result = new TREE_NODE();
        result->type      = BOOL_NODE;
        result->boolValue = false;

        TREE_NODE * isAtom = eval(list[1], env);
        if (isAtom) {
            if (isAtom->type == NUMBER_NODE ||
                isAtom->type == STRING_NODE ||
                isAtom->type == BOOL_NODE) {
                result->boolValue = true;
            }
        }
        return result;
    }
    else if (id == "quote" && list.size() == 2) {
        return list[1];
    }
    else if (id == "set" && list.size() == 3) {
        if (env->definitions.count(*(list[1]->strValue))) {
            TREE_NODE * capture = list[2];
            env->definitions[*(list[1]->strValue)] =
                [=](TREE_NODE * in)->TREE_NODE* { return capture; };
        }

        TREE_NODE * result = new TREE_NODE();
        result->type       = PROC_NODE;
        return result;
    }
    else if (id == "def" && list.size() == 3) {
        std::string &varName = *(list[1]->strValue);
        TREE_NODE * capture  = list[2];

        env->definitions.insert({
            varName,
            [=](TREE_NODE * input)->TREE_NODE* {
                TREE_NODE * interim = eval(capture, env);
                if (interim->type == LAMBDA_NODE) {
                    LAMBDA * lambda = interim->lambda;
                    ENV * newEnv = new ENV(env);

                    std::vector<struct TREE_NODE *> &varsList = *(lambda->vars);
                    std::vector<struct TREE_NODE *> &argsList = *(input->list);
                    for (int i = 0; i < varsList.size(); i++) {
                        TREE_NODE * argument = argsList[i];
                        newEnv->definitions.insert({
                            *(varsList[i]->strValue),
                            [=](TREE_NODE * in)->TREE_NODE* { return argument; } 
                        });
                    }

                    return eval(lambda->expr, newEnv);
                }
                return interim;
            }
        });

        TREE_NODE * result = new TREE_NODE();
        result->type       = PROC_NODE;
        return result;
    }
    else if (id == "lambda" && list.size() == 3) {
        TREE_NODE * result   = new TREE_NODE();
        result->type         = LAMBDA_NODE;
        result->lambda       = new LAMBDA();
        result->lambda->expr = list[2];
        result->lambda->vars = list[1]->list;

        return result;
    }
    else if (id == "car" && list.size() == 2) {
        TREE_NODE * interim = eval(list[1], env);
        if (interim->type == LIST_NODE) {
            std::vector<struct TREE_NODE *> &interimList = *(interim->list);
            return interimList[0];
        }
    }
    else if (id == "cdr" && list.size() == 2) {
        TREE_NODE * interim = eval(list[1], env);
        if (interim->type == LIST_NODE) {
            std::vector<struct TREE_NODE *> &interimList = *(interim->list);
            TREE_NODE * result = new TREE_NODE();
            result->type = LIST_NODE;
            result->list = new std::vector<struct TREE_NODE *>(interimList.begin() + 1,
                                                               interimList.end());
            return result;
        }
    }
    else if (id == "if" && list.size() == 4) {
        TREE_NODE * cond = eval(list[1], env);
        if (cond->type == BOOL_NODE) {
            if (cond->boolValue) {
                return eval(list[2], env);
            }
            else {
                return eval(list[3], env);
            }
        }
    }
    else if (id == "null" && list.size() == 2) {
        TREE_NODE * interim = eval(list[1], env);
        TREE_NODE * result = new TREE_NODE();
        result->type = BOOL_NODE;
        result->boolValue = false;
        if (interim->type == LIST_NODE && interim->list->size() == 0) {
            result->boolValue = true;
        }
        return result;
    }
    else if (id == "eq" && list.size() == 3) {
        TREE_NODE * interimOne = eval(list[1], env);
        TREE_NODE * interimTwo = eval(list[2], env);


        TREE_NODE * result = new TREE_NODE();
        result->type = BOOL_NODE;
        result->boolValue = false;

        if (interimOne->type == interimTwo->type) {
            switch (interimOne->type) {
                case LIST_NODE:
                {
                    result->boolValue = interimOne->list->size() == 0 &&
                                        interimTwo->list->size() == 0;
                    break;
                }
                case STRING_NODE:
                {
                    result->boolValue = *(interimOne->strValue) ==
                                        *(interimTwo->strValue);
                    break;
                }
                case NUMBER_NODE:
                {
                    result->boolValue = interimOne->intValue ==
                                        interimTwo->intValue;
                    break;
                }
                case BOOL_NODE:
                {
                    result->boolValue = interimOne->boolValue ==
                                        interimTwo->boolValue;
                    break;
                }
                case PROC_NODE:
                case LAMBDA_NODE:
                    break;
            }
        }
        return result;
    }
    else if (id == "begin") {
        TREE_NODE * result = nullptr;
        for (int i = 1; i < list.size(); i++) {
            result = eval(list[i], env);
        }
        return result;
    }
    else if (id == "cons" && list.size() == 3) {
        TREE_NODE * interimOne = eval(list[1], env);
        TREE_NODE * interimTwo = eval(list[2], env);

        interimTwo->list->insert(interimTwo->list->begin(), interimOne);
        return interimTwo;
    }
    else if (id == "cond") {
        for (int i = 1; i < list.size(); i++) {
            std::vector<struct TREE_NODE *> &condList = *(list[i]->list);
            TREE_NODE * cond = eval(condList[0], env);
            if (cond->type == BOOL_NODE && cond->boolValue == true) {
                return eval(condList[1], env);
            }
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