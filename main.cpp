#include <iostream>
#include <cstdlib>
#include <cstring>

#include "mlisp_driver.hpp"

int main(const int argc, const char **argv) {
   /** check for the right # of arguments **/
   Mlisp::Mlisp_Driver driver;
   driver.prompt();

   return(EXIT_SUCCESS);
}