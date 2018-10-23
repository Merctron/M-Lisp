#include <cctype>
#include <fstream>
#include <cassert>
#include <iostream>

#include "mlisp_driver.hpp"

Mlisp::Mlisp_Driver::~Mlisp_Driver() {
   delete(scanner);
   scanner = nullptr;
   delete(parser);
   parser = nullptr;
}

void Mlisp::Mlisp_Driver::parse( const char * const filename ) {
   assert( filename != nullptr );
   std::ifstream in_file( filename );
   if( ! in_file.good() ) {
       exit( EXIT_FAILURE );
   }
   parse_helper( in_file );
   return;
}

void Mlisp::Mlisp_Driver::parse( std::istream &stream ) {
   if( ! stream.good()  && stream.eof() )
   {
       return;
   }
   //else
   parse_helper( stream ); 
   return;
}


void Mlisp::Mlisp_Driver::parse_helper( std::istream &stream ) {
   
   delete(scanner);
   try
   {
      scanner = new Mlisp::Mlisp_Scanner( &stream );
   }
   catch( std::bad_alloc &ba )
   {
      std::cerr << "Failed to allocate scanner: (" <<
         ba.what() << "), exiting!!\n";
      exit( EXIT_FAILURE );
   }
   
   delete(parser); 
   try
   {
      parser = new Mlisp::Mlisp_Parser( (*scanner) /* scanner */, 
                                  (*this) /* driver */ );
   }
   catch( std::bad_alloc &ba )
   {
      std::cerr << "Failed to allocate parser: (" << 
         ba.what() << "), exiting!!\n";
      exit( EXIT_FAILURE );
   }
   const int accept( 0 );
   if( parser->parse() != accept )
   {
      std::cerr << "Parse failed!!\n";
   }
   return;
}

void Mlisp::Mlisp_Driver::add_expression() { 
   std::cout << "An expression was detected" << std::endl;
}

void Mlisp::Mlisp_Driver::add_upper() { 
   uppercase++; 
   chars++; 
   words++; 
}

void Mlisp::Mlisp_Driver::add_lower() { 
   lowercase++; 
   chars++; 
   words++; 
}

void Mlisp::Mlisp_Driver::add_word(const std::string &word) {
   words++; 
   chars += word.length();
   for(const char &c : word ){
      if( islower( c ) )
      { 
         lowercase++; 
      }
      else if ( isupper( c ) ) 
      { 
         uppercase++; 
      }
   }
}

void Mlisp::Mlisp_Driver::add_newline() { 
   lines++; 
   chars++; 
}

void Mlisp::Mlisp_Driver::add_char() { 
   chars++; 
}


std::ostream& Mlisp::Mlisp_Driver::print(std::ostream &stream) {
   stream << red  << "Results: " << norm << "\n";
   stream << blue << "Uppercase: " << norm << uppercase << "\n";
   stream << blue << "Lowercase: " << norm << lowercase << "\n";
   stream << blue << "Lines: " << norm << lines << "\n";
   stream << blue << "Words: " << norm << words << "\n";
   stream << blue << "Characters: " << norm << chars << "\n";
   return(stream);
}