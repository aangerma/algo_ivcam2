
#pragma once


#ifndef STRATUS
#include <iostream>
#endif

namespace cynw {
namespace axi3 {

	static bool print_flag = 0;

	static void print_version () {
#ifndef STRATUS
	  if(!print_flag) {
	   std::cout<<"\t-- Stratus AXI3 Transactors"<<std::endl;
	   std::cout<<"\t-- Copyright Cadence Design Systems, Inc. All rights reserved. "<<std::endl;
	   print_flag = 1;
	  }
#endif
	}

}; // namespace axi3
}; // namespace cynw
