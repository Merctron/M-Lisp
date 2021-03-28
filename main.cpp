#include <iostream>
#include <cstdlib>
#include <cstring>
#include <streambuf>
#include <istream>

#include "mlisp_driver.hpp"

struct membuf : std::streambuf
{
    membuf(char* begin, char* end) {
        this->setg(begin, begin, end);
    }
};

int main(int argc, char **argv) {
   /** check for the right # of arguments **/
   Mlisp::Mlisp_Driver driver;
   if (argc > 1) {
      driver.setSingleUse();
      membuf sbuf(argv[1], argv[1] + sizeof(argv[1]));
      std::istream in(&sbuf);
      driver.parse(in);
      return(EXIT_SUCCESS);
   }
   driver.prompt();

   return(EXIT_SUCCESS);
}