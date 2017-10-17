/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/
#if !defined(cynw_simple_fifo_h_included)
#define cynw_simple_fifo_h_included

#if defined STRATUS 
#pragma hls_ip_def
#endif	

#include "cynthhl.h"



//==============================================================================
// cynw_simple_fifo - A SIMPLE FIFO CLASS THAT USES A FLATTENNED ARRAY
// 
//  This class implements a fifo that is designed to be used within a single
//  module. It does not have ports, all access is to the class itself. The
//  storage for the class is an array of 2**AW locations, that is flattened
//  for synthesis. The template arguments are:
//        D  - the data type of elements in the fifo
//        AW - the log base 2 of the fifo size.
//        
// NOTES:
//   (1) The fifo interface is non-blocking, so a wait() must be done between 
//       successive calls to nb_pop() or nb_push(). However, temporaly 
//       simulatenous calls may be made to nb_pop() and nb_push().
//
//   (2) There is a peek capability, via the nb_peek() method.
//   (2) The push and pop interfaces have individual resets, push_reset() and 
//       pop_reset() respectively. The pop_reset() method  should be called 
//       during the reset sequence of the process using the nb_pop() method, 
//       and the push_reset() should be called during the reset sequence of the
//       process using the nb_push() method.
//
//   (3) The get and put pointers have AW+1 bits, this provides an easy way
//       of determining full and empty:
//           empty - get pointer is equal to put pointer
//           full  - the low order AW bits of the two pointers are the same
//                   but the high order bit differs
//==============================================================================
template<typename D, unsigned int AW>
class cynw_simple_fifo
{
  public:
  	cynw_simple_fifo(const char* name_p="fifo") :
		m_pop_i((std::string(name_p)+"_pop_i").c_str()),
		m_push_i((std::string(name_p)+"_push_i").c_str())
	{
		CYN_FLATTEN(m_storage);
	}

	inline bool is_empty()
	{
		return m_pop_i.read() == m_push_i.read();
	}

	inline bool is_full()
	{
		bool         result;
		result = ( m_pop_i.read() ^ m_push_i.read() ) == (1<<AW);
		return result;
	}

	inline void nb_peek( D& data )
	{
		sc_uint<AW+1> pop_i;   // next pop binary pointer.
#		if !defined(STRATUS_HLS)
			assert( !is_empty() );
#		endif
		pop_i = m_pop_i.read();
		data = m_storage[pop_i(AW-1,0)];
	}

	inline void nb_pop( D& data )
	{
		sc_uint<AW+1> pop_i;   // next pop binary pointer.

#		if !defined(STRATUS_HLS)
			assert( !is_empty() );
#		endif
		pop_i = m_pop_i.read();
		data = m_storage[pop_i(AW-1,0)];
		m_pop_i = pop_i + 1;
	}

	inline void nb_push( const D& data )
	{
		sc_uint<AW+1> push_i;   // push binary pointer.

#		if !defined(STRATUS_HLS)
			assert( !is_full() );
#		endif
		push_i = m_push_i.read();
		m_storage[push_i(AW-1,0)] = data;
		m_push_i = push_i + 1;
	}

	inline void pop_reset()
	{
		m_pop_i = 0;
	}

	inline void push_reset()
	{
		m_push_i = 0;
	}


	sc_signal<sc_uint<AW+1> > m_pop_i;          // binary coded pop pointer.
	sc_signal<sc_uint<AW+1> > m_push_i;         // binary coded push pointer.
	D                         m_storage[1<<AW]; // fifo_storage.
};

#endif // !defined(cynw_simple_fifo_h_included)
