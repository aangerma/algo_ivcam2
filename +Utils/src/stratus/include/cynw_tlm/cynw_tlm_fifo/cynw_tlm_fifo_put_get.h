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
// ctos_tlm_fifo_put_get.h
//
// This file contains the put/get interfaces for tlm_fifo.
//
// 
// ****************************************************************************

#ifndef CYNW_TLM_FIFO_PUT_GET_IF_HEADER
#define CYNW_TLM_FIFO_PUT_GET_IF_HEADER

#ifndef CYNW_TLM_FIFO_HEADER
#include "cynw_tlm_fifo.h"
#endif


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw_tlm {

/******************************************************************
//
// get interface
//
******************************************************************/

template <typename T, int SIZE, bool RESET_DATA>
inline
T 
tlm_fifo<T,SIZE,RESET_DATA>::get(tlm_tag<T> *)
{
    #if defined(STRATUS)
    if(HLS_INITIATION_INTERVAL == 0) {
    #endif
      while (CONTROL::_is_empty()) {
	wait();
      }
    #if defined(STRATUS)
    } else {
      do {
        wait();
      } while (CONTROL::_is_empty()) ;
    }
    #endif
    T data = m_buf[CONTROL::m_r_ind];
    CONTROL::_incr_r();
#if !defined(STRATUS) && defined(NC_SYSTEMC)
    m_trace.trace_get(data);
#endif
    return data;
}

// non-blocking read

template <typename T, int SIZE, bool RESET_DATA>
inline
bool
tlm_fifo<T,SIZE,RESET_DATA>::nb_get(T& val_)
{
    if (CONTROL::_is_empty()) {
	return false;
    }
    val_ = m_buf[CONTROL::m_r_ind];
    CONTROL::_incr_r();
#if !defined(STRATUS) && defined(NC_SYSTEMC)
    m_trace.trace_get(val_);
#endif
    return true;
}

template <typename T, int SIZE, bool RESET_DATA> 
inline 
bool
tlm_fifo<T,SIZE,RESET_DATA>::nb_can_get(tlm_tag<T> *) const 
{
    return !CONTROL::_is_empty_nb_can();
}


/******************************************************************
//
// put interface
//
******************************************************************/

template <typename T, int SIZE, bool RESET_DATA>
inline
void
tlm_fifo<T,SIZE,RESET_DATA>::put(const T& val_)
{
    T val(val_);
    #if defined(STRATUS)
    if(HLS_INITIATION_INTERVAL == 0) {
    #endif
      while (CONTROL::_is_full()) {
	wait();
      }
    #if defined(STRATUS)
    } else {
      do {
        wait();
      } while (CONTROL::_is_full()) ;
    }
    #endif
    m_buf[CONTROL::m_w_ind] = val;
    CONTROL::_incr_w();
#if !defined(STRATUS) && defined(NC_SYSTEMC)
    m_trace.trace_put(val);
#endif
}

template <typename T, int SIZE, bool RESET_DATA>
inline
bool
tlm_fifo<T,SIZE,RESET_DATA>::nb_put(const T& val_)
{
    if (CONTROL::_is_full()) {
	return false;
    }
    m_buf[CONTROL::m_w_ind] = val_;
    CONTROL::_incr_w();
#if !defined(STRATUS) && defined(NC_SYSTEMC)
    m_trace.trace_put(val_);
#endif
    return true;
}

template < typename T, int SIZE, bool RESET_DATA> 
inline 
bool
tlm_fifo<T,SIZE,RESET_DATA>::nb_can_put(tlm_tag<T> *) const 
{
    return !CONTROL::_is_full_nb_can();
}
} // namespace cynw_tlm

#endif

