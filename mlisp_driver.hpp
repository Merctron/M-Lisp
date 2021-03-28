#ifndef __MLISPDRIVER_HPP__
#define __MLISPDRIVER_HPP__ 1

#include <string>
#include <cstddef>
#include <istream>

#include "mlisp_scanner.hpp"
#include "mlisp_parser.tab.hh"

namespace Mlisp {

class Mlisp_Driver{
public:
   Mlisp_Driver() = default;

   virtual ~Mlisp_Driver();
   
   /** 
    * parse - parse from a file
    * @param filename - valid string with input file
    */
   void parse(const char * const filename);
   /** 
    * parse - parse from a c++ input stream
    * @param is - std::istream&, valid input stream
    */
   void parse(std::istream &iss);

   void add_expression();
   void add_word( const std::string &word );
   void prompt();
   void setSingleUse();

   std::ostream& print(std::ostream &stream);
private:

   void parse_helper( std::istream &stream );

   Mlisp::Mlisp_Parser  *parser  = nullptr;
   Mlisp::Mlisp_Scanner *scanner = nullptr;
   bool d_isSingleUse = false;
   
   const std::string red   = "\033[1;31m";
   const std::string blue  = "\033[1;36m";
   const std::string norm  = "\033[0m";
};

} /* end namespace Mlisp */
#endif /* END __MLISPDRIVER_HPP__ */