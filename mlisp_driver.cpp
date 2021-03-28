#include <cctype>
#include <fstream>
#include <cassert>
#include <iostream>
#include <string>
#include <sstream>

#include "mlisp_driver.hpp"

Mlisp::Mlisp_Driver::~Mlisp_Driver() {
    delete(scanner);
    scanner = nullptr;
    delete(parser);
    parser = nullptr;
}

void Mlisp::Mlisp_Driver::parse(std::istream &stream) {
    if (!stream.good() && stream.eof()) {
       return;
    }

    parse_helper(stream); 
    return;
}

void Mlisp::Mlisp_Driver::setSingleUse() {
    d_isSingleUse = true;
}


void Mlisp::Mlisp_Driver::parse_helper(std::istream &stream) {
    if (scanner == nullptr) {
        try {
            scanner = new Mlisp::Mlisp_Scanner(&stream);
        }
        catch (std::bad_alloc &ba) {
            std::cerr << "Failed to allocate scanner: (" << ba.what()
                    << "), exiting!!\n";
            exit(EXIT_FAILURE);
        }
    }

    if (parser == nullptr) {
        try {
            parser = new Mlisp::Mlisp_Parser((*scanner), 
                                             (*this));
        }
        catch (std::bad_alloc &ba) {
        std::cerr << "Failed to allocate parser: (" << ba.what()
                    << "), exiting!!\n";
        exit(EXIT_FAILURE);
        }
    }

    const int accept(0);
    if (parser->parse() != accept) {
        std::cerr << "Parse failed!!\n";
    }

    return;
}

void Mlisp::Mlisp_Driver::add_expression() { 
    std::cout << "An expression was detected" << std::endl;
}

void Mlisp::Mlisp_Driver::add_word(const std::string &word) {
    std::cout << "Detected word: " << word << std::endl;
}

void Mlisp::Mlisp_Driver::prompt() {
    while (true) {
        std::cout << "M-Lisp>";
        std::string input;
        std::getline(std::cin, input);
        std::istringstream inStream(input);
        parse(inStream);
    }
}