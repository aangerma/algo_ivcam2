
/*****************************************************************************

  The following code is derived, directly or indirectly, from the SystemC
  source code Copyright (c) 1996-2004 by all Contributors.
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

//
// Note to the LRM writer : These interfaces are channel specific interfaces
// useful in the context of ctos_tlm_fifo.
//

#ifndef CYNW_TLM_FIFO_IFS_HEADER
#define CYNW_TLM_FIFO_IFS_HEADER

// 
// Fifo specific interfaces
//

#include "cynw_tlm_peek_ifs.h"


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw_tlm
{

// Fifo Debug Interface

template< typename T >
class tlm_fifo_debug_if : public virtual sc_interface
{
public:
  virtual int used() const = 0;
  virtual int size() const = 0;
  virtual void debug() const = 0;

  //
  // non blocking peek and poke - no notification
  //
  // n is index of data :
  // 0 <= n < size(), where 0 is most recently written, and size() - 1
  // is oldest ie the one about to be read.
  //

    //  virtual bool nb_peek( T & , int n ) const = 0;
    //  virtual bool nb_poke( const T & , int n = 0 ) = 0;

};

// fifo interfaces = extended + debug

template < typename T >
class tlm_fifo_put_if :
  public virtual tlm_put_if<T> ,
  public virtual tlm_fifo_debug_if<T> {};

template < typename T >
class tlm_fifo_get_if :
  public virtual tlm_get_peek_if<T> ,
  public virtual tlm_fifo_debug_if<T> {};

class tlm_fifo_config_size_if : public virtual sc_interface
{
public:
  virtual void nb_expand( unsigned int n = 1 ) = 0;
  virtual void nb_unbound( unsigned int n = 16 ) = 0;

  virtual bool nb_reduce( unsigned int n = 1 ) = 0;
  virtual bool nb_bound( unsigned int n ) = 0;

};

// Fifo status Interface: These APIs reflect the state of the fifo
// at the beginning of the current delta cycle. If all processes
// accessing the fifo are synchronous and have the same clock event,
// this means the state of the fifo at the beginning of this
class tlm_fifo_status_if : public virtual sc_interface
{
public:
  virtual bool is_full() const = 0;
  virtual bool is_empty() const = 0;
  virtual int num_items() const = 0;
};

} // namespace cynw_tlm 
#endif

