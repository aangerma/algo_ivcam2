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
// ctos_tlm_fifo_1t.h
//
// This file contains the synthesizable version of tlm_fifo_1t.
//
// 
// ****************************************************************************

#ifndef CYNW_TLM_FIFO_1T_HEADER
#define CYNW_TLM_FIFO_1T_HEADER

#include <systemc.h>
#if !defined(STRATUS)
#include <cassert>
#endif
#include "../cynw_tlm_interfaces/cynw_tlm_fifo_ifs.h"
#include "../cynw_tlm_utils/cynw_tlm_utils.h"
#include "../cynw_tlm_utils/cynw_tlm_fifo_internals.h"
#include "../cynw_tlm_utils/cynw_tlm_fifo_1t_control.h"
#if !defined(STRATUS) && defined(NC_SYSTEMC)
#include "../cynw_tlm_utils/cynw_tlm_fifo_trace.h"
#endif
# include <stratus_hls.h>


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw_tlm
{
// Class tlm_fifo_1t.
// 
// This is a synthesizable version of tlm_fifo_1t.
// To reset it, the producer must call reset_put() and the consumer must
// call reset_get(). This empties the fifo.
//
// The following functionalities are not provided:
// * event-returning methods of non-blocking interfaces
// * resize interface
// * debug interface
// * rendez-vous protocol (SIZE=0)
// * infinite size (SIZE<0)
template <class T, int SIZE, bool RESET_DATA=0>
class tlm_fifo_1t :
  public virtual tlm_fifo_get_if<T>,
  public virtual tlm_fifo_put_if<T>,
  public virtual tlm_fifo_status_if,
  public tlm_fifo_internals_if<T>,
  public tlm_fifo_1t_control<SIZE>
{
public:
  typedef tlm_fifo_1t_control<SIZE> CONTROL;

    // constructors
    explicit tlm_fifo_1t(sc_module_name nm = sc_gen_unique_name("tlm_fifo_1t"))
    :    tlm_fifo_1t_control<SIZE>(nm)
#if !defined(STRATUS) && defined(NC_SYSTEMC)
	, m_trace(this)
#endif
	{
#if !defined(STRATUS)
	    assert(SIZE >= 1);
#endif
	}

    // tlm get interface
  public:
    virtual T get( tlm_tag<T> *t = 0 );
    virtual bool nb_get( T& );
    virtual bool nb_can_get( tlm_tag<T> *t = 0 ) const;
    virtual void reset_get(tlm_tag<T> *t = 0);

    // not supported part of tlm get interface
  private:
    virtual const sc_event &ok_to_get( tlm_tag<T> *t = 0 ) const;

    // tlm peek interface
  public:
    virtual T peek( tlm_tag<T> *t = 0 ) const;
    bool nb_peek( T& ) const;
    virtual bool nb_can_peek( tlm_tag<T> *t = 0 ) const;

    // not supported part of tlm peek interface
  private:
    virtual const sc_event &ok_to_peek( tlm_tag<T> *t = 0 ) const;

    // tlm put interface 
  public:
    virtual void put( const T& );
    virtual bool nb_put( const T& );
    virtual bool nb_can_put( tlm_tag<T> *t = 0 ) const;
    virtual void reset_put(tlm_tag<T> *t = 0);

    // not supported part of tlm put interface
  private:
    virtual const sc_event& ok_to_put( tlm_tag<T> *t = 0 ) const;

    // resize if: Not supported.
  private:
    void nb_expand( unsigned int n = 1 );
    void nb_unbound( unsigned int n = 16 );
    bool nb_reduce( unsigned int n = 1 );
    bool nb_bound( unsigned int n );

    // tlm fifo status interface
  public:
    virtual bool is_full() const {return CONTROL::is_full();}
    virtual bool is_empty() const {return CONTROL::is_empty();}
    virtual int num_items() const {return CONTROL::num_items();}

    // debug interface: only size() is synthesizable.
  public:
    virtual void debug() const;
    virtual int used() const;
    virtual int size() const;

    // unsupported part of debug interface. 
  private:
    virtual bool nb_peek( T & , int n ) const;
    virtual bool nb_poke( const T & , int n = 0 );

    // Implementation
  private:
    T                       m_buf[SIZE];

#if !defined(STRATUS) && defined(NC_SYSTEMC)
    // Trace interface
  private:
    tlm_fifo_trace<T>	    m_trace;
#include "../cynw_tlm_utils/cynw_tlm_fifo_trace_apis.inc"
#endif

  public:
    // These APIs are NOT to be used in the synthesize.
    virtual const T	    &internal_datum(int index) const;
    
  private:
    // disabled
    tlm_fifo_1t( const tlm_fifo_1t& );
    tlm_fifo_1t& operator = ( const tlm_fifo_1t& );

    void not_supported() const;
};

/******************************************************************
// reset_put() 
//
// This function must be called by the producer process on reset.
******************************************************************/
template< typename T, int SIZE, bool RESET_DATA>
inline 
void
tlm_fifo_1t<T,SIZE,RESET_DATA>::reset_put(tlm_tag<T> *t) 
{
    CONTROL::_reset_w();
    if (RESET_DATA) {
	for (int i = 0; i < SIZE; ++i) {
        HLS_UNROLL_LOOP(ON, "CYNW_TLM_FIFO_UNROLL_RESET_DATA_LOOP_4");
	    m_buf[i] = T();
	}
    }
#if !defined(STRATUS) && defined(NC_SYSTEMC)
    m_trace.trace_reset_put();
#endif
}

/******************************************************************
// reset_get() 
//
// This function must be called by the consumer process on reset.
******************************************************************/
template< typename T, int SIZE, bool RESET_DATA>
inline 
void
tlm_fifo_1t<T,SIZE,RESET_DATA>::reset_get(tlm_tag<T> *t) 
{
    CONTROL::_reset_r();
#if !defined(STRATUS) && defined(NC_SYSTEMC)
    m_trace.trace_reset_get();
#endif
}

// *****************************************************************************
// This function returns the capacity of this fifo. It is synthesizable and can
// be called from any process.
// *****************************************************************************
template< typename T, int SIZE, bool RESET_DATA>
int
tlm_fifo_1t<T,SIZE,RESET_DATA>::size() const
{
    return SIZE;
}

// *****************************************************************************
// This function prints the internal state of this fifo to cout. It is not
// synthesizable.
// *****************************************************************************
template< typename T, int SIZE, bool RESET_DATA>
void
tlm_fifo_1t<T,SIZE,RESET_DATA>::debug() const
{
    return tlm_fifo_internals_if<T>::internal_debug();
}

// *****************************************************************************
// This is function of the debug interface returns the number of slots that
// where filled at the start of this delta cycle that have not been read out
// (during this delta cycle).
// *****************************************************************************
template< typename T, int SIZE, bool RESET_DATA>
int
tlm_fifo_1t<T,SIZE,RESET_DATA>::used() const
{
    return tlm_fifo_internals_if<T>::internal_used();
}

// *****************************************************************************
// This function returns the datum at the slot with given index.
// *****************************************************************************
template< typename T, int SIZE, bool RESET_DATA>
inline 
const T&
tlm_fifo_1t<T,SIZE,RESET_DATA>::internal_datum(int ind) const
{
    return m_buf[ind];
}

// *****************************************************************************
//  Unsupported APIs.
// *****************************************************************************
template< typename T, int SIZE, bool RESET_DATA>
bool
tlm_fifo_1t<T,SIZE,RESET_DATA>::nb_peek(T& val, int n) const
{
    not_supported();
    return false;
}

template< typename T, int SIZE, bool RESET_DATA>
bool
tlm_fifo_1t<T,SIZE,RESET_DATA>::nb_poke(const T& val, int n)
{
    not_supported();
    return false;
}

template< typename T, int SIZE, bool RESET_DATA>
const sc_event&
tlm_fifo_1t<T,SIZE,RESET_DATA>::ok_to_get( tlm_tag<T> *t ) const
{
    not_supported();
    return *(new sc_event);
}

template< typename T, int SIZE, bool RESET_DATA>
const sc_event&
tlm_fifo_1t<T,SIZE,RESET_DATA>::ok_to_peek( tlm_tag<T> *t ) const
{
    not_supported();
    return *(new sc_event);
}

template< typename T, int SIZE, bool RESET_DATA>
const sc_event&
tlm_fifo_1t<T,SIZE,RESET_DATA>::ok_to_put( tlm_tag<T> *t ) const
{
    not_supported();
    return *(new sc_event);
}

template< typename T, int SIZE, bool RESET_DATA>
void
tlm_fifo_1t<T,SIZE,RESET_DATA>::not_supported() const
{
#if !defined(STRATUS)
	::std::cout << "NOT SUPPORTED!!!" << ::std::endl;
#endif
}

} //  namespace cynw_tlm

#include "../cynw_tlm_fifo_1t/cynw_tlm_fifo_1t_put_get.h"
#include "../cynw_tlm_fifo_1t/cynw_tlm_fifo_1t_peek.h"

#endif
