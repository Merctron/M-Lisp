#include <iostream>
#include <cstdlib>
#include <cstring>
#include <streambuf>
#include <istream>
#include <string>
#include <sstream>

#include "mlisp_driver.hpp"


int main(int argc, char **argv) {
    /** check for the right # of arguments **/
    Mlisp::Mlisp_Driver driver;
    if (argc > 1) {
        std::string option(argv[1]);
        if (option == "--single-use") {
            std::string input(argv[2]);
            std::istringstream inStream(input);
            driver.parse(inStream);
            return(EXIT_SUCCESS);
        }
    }
    driver.prompt();
    return(EXIT_SUCCESS);
}