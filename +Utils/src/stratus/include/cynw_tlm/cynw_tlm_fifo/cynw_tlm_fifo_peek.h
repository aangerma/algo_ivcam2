/*****************************************************************************

  The following code is derived, directly or indirectly, from the SystemC
  source code Copyright (c) 1996-2006 by all Contributors.
  All Rights reserved.

  The contents of this file are subject to the restrictions and limitations
  set forth in the SystemC Open Source License Version 2.4 (the "License");
  You may not use this file except in compliance with such restrictions and
  limitations. You may obtain instructions on how to receive a copy of the
  License at http://www.systemc.org/. Software distributed by Contributors
  under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
  ANY KIND, either express or implied. See the License for the specific
  language governing rights and limitations under the License.

 *****************************************************************************/

// ****************************************************************************
// ctos_tlm_fifo_peek.h
//
// This file contains the peek operators for tlm_fifo.
//
// 
// ****************************************************************************
#ifndef CYNW_TLM_FIFO_PEEK_HEADER
#define CYNW_TLM_FIFO_PEEK_HEADER

#ifndef CYNW_TLM_FIFO_HEADER
#include "cynw_tlm_fifo.h"
#endif


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw_tlm {

template < typename T, int SIZE, bool RESET_DATA>
inline
T
tlm_fifo<T,SIZE,RESET_DATA>::peek(tlm_tag<T> *) const 
{
    while (CONTROL::_is_empty()) {
	const_cast< tlm_fifo<T,SIZE,RESET_DATA> * >(this)->wait();
    }
    T data = m_buf[CONTROL::m_r_ind];
    return data;
}

template < typename T, int SIZE, bool RESET_DATA>
inline
bool
tlm_fifo<T,SIZE,RESET_DATA>::nb_peek(T &t) const 
{
    if (CONTROL::_is_empty()) {
	return false;
    }
    t = m_buf[CONTROL::m_r_ind];
    return true;
}

template< typename T, int SIZE , bool RESET_DATA>
inline
bool
tlm_fifo<T,SIZE,RESET_DATA>::nb_can_peek(tlm_tag<T> *) const
{
    return !CONTROL::_is_empty_nb_can();
}

} // namespace cynw_tlm

#endif
