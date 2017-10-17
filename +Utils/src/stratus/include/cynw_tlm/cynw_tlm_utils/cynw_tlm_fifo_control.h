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
// ctos_tlm_fifo_control.h
//
// This file contains the control portion of tlm_fifo. It is synthesizable.
//
// 
// ****************************************************************************

#ifndef CYNW_TLM_FIFO_CONTROL_HEADER
#define CYNW_TLM_FIFO_CONTROL_HEADER

#include <systemc.h>
#if !defined(STRATUS)
#include <cassert>
#endif
#include "cynw_tlm_utils.h"
#include "cynw_tlm_fifo_internals.h"
# include <stratus_hls.h>


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw_tlm
{
// *****************************************************************************
// Class tlm_fifo_control
// 
// This class implements the control logic of tlm_fifo, and tlm_fifo_reg.  It is
// respondible for updating the read and write pointers.
// *****************************************************************************
template <int SIZE=1>
class tlm_fifo_control :
  public virtual tlm_fifo_status_if,
  public virtual tlm_fifo_internals_control_if,
  public sc_module
{
  protected:
    // constructors
    explicit tlm_fifo_control(const sc_module_name& name)
	: sc_module(name),
          m_r_ind_prev("m_r_ind_prev"),
          m_w_ind_prev("m_w_ind_prev"),
          m_r_top_prev("m_r_top_prev"),
          m_w_top_prev("m_w_top_prev")
	{
#if !defined(STRATUS)
	    assert(SIZE >= 1);
#endif
	    SC_METHOD(update_nb_can_signals);
	    sensitive << m_r_ind_prev << m_r_top_prev;
	    sensitive << m_w_ind_prev << m_w_top_prev;
	}

    // tlm fifo status interface
  public:
    virtual bool is_full() const;
    virtual bool is_empty() const;
    virtual int num_items() const;

    // Implementation
  protected:
    typedef sc_uint< CYNW_GET_NUM_BITS(SIZE-1) > Index;

    Index                   m_r_ind;
    Index                   m_w_ind;

    bool                    m_r_top;
    bool                    m_w_top;

  public:
    sc_signal<Index>        m_r_ind_prev;
    sc_signal<Index>        m_w_ind_prev;
                            
    sc_signal<bool>         m_r_top_prev;
    sc_signal<bool>         m_w_top_prev;

  private:
    sc_signal<Index>        m_r_ind_prev_nb_can;
    sc_signal<Index>        m_w_ind_prev_nb_can;
                            
    sc_signal<bool>         m_r_top_prev_nb_can;
    sc_signal<bool>         m_w_top_prev_nb_can;

    void		    update_nb_can_signals();
			    SC_HAS_PROCESS(tlm_fifo_control);

    // Implementation of ctos_tlm_internal_control_if.
  public:
    virtual int		    internal_extended_read_index(bool now) const;
    virtual int		    internal_extended_write_index(bool now) const;
    virtual int		    internal_size() const;
    
  protected:
    //
    // use nb_can_get() and nb_can_put() rather than the following two
    // private functions
    //
    void _reset_r();
    void _reset_w();
    void _incr_r();
    void _incr_w();
    bool _is_empty() const;
    bool _is_full() const;
    bool _is_empty_nb_can() const;
    bool _is_full_nb_can() const;

  private:
    // disabled
    tlm_fifo_control( const tlm_fifo_control& );
    tlm_fifo_control& operator = ( const tlm_fifo_control& );
};

// *****************************************************************************
// This function returns true if this fifo is full at the beginning of this
// clock cycle. This function is synthesizable and can be called from any
// process.
// *****************************************************************************
template<int SIZE>
bool
tlm_fifo_control<SIZE>::is_full() const
{
    unsigned int r_ind = m_r_ind_prev.read();
    unsigned int w_ind = m_w_ind_prev.read();
    bool r_top = m_r_top_prev.read();
    bool w_top = m_w_top_prev.read();
    return r_ind == w_ind && r_top != w_top;
}

// *****************************************************************************
// This function returns true if this fifo is empty at the beginning of this
// clock cycle. This function is synthesizable and can be called from any
// process.
// *****************************************************************************
template<int SIZE>
bool
tlm_fifo_control<SIZE>::is_empty() const
{
    unsigned int r_ind = m_r_ind_prev.read();
    unsigned int w_ind = m_w_ind_prev.read();
    bool r_top = m_r_top_prev.read();
    bool w_top = m_w_top_prev.read();
    return r_ind == w_ind && r_top == w_top;
}

// *****************************************************************************
// This function returns the number of filled slots at the beginning of this
// clock cycle. This function is synthesizable and can be called from any
// process.
// *****************************************************************************
template<int SIZE>
int
tlm_fifo_control<SIZE>::num_items() const
{
    unsigned int r_ind = m_r_ind_prev.read();
    unsigned int w_ind = m_w_ind_prev.read();
    bool r_top = m_r_top_prev.read();
    bool w_top = m_w_top_prev.read();
    if (r_top == w_top) {
	return w_ind - r_ind;
    } else {
	return w_ind - r_ind + SIZE;
    }
}

// *****************************************************************************
// _reset_w() 
//
// This function resets the state of the producer process. It must be called
// by the producer process on reset.
// *****************************************************************************
template<int SIZE>
inline 
void
tlm_fifo_control<SIZE>::_reset_w() 
{
    m_w_ind = 0;
    m_w_top = false;
    m_w_ind_prev = 0;
    m_w_top_prev = false;
}

// *****************************************************************************
// _reset_r() 
//
// This function resets the state of the consumer process. It must be called
// by the producer process on reset.
// *****************************************************************************
template<int SIZE>
inline 
void
tlm_fifo_control<SIZE>::_reset_r()
{
    m_r_ind = 0;
    m_r_top = false;
    m_r_ind_prev = 0;
    m_r_top_prev = false;
}

// *****************************************************************************
// This function returns true if this fifo is empty. This is a protected
// function that can be called only from the getter process.
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_control<SIZE>::_is_empty() const
{
    return m_r_ind == m_w_ind_prev.read() 
	   && m_r_top == m_w_top_prev.read();
}

// *****************************************************************************
// This function returns true if this fifo is full. This is a protected
// function that can be called only from the putter process.
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_control<SIZE>::_is_full() const
{
    return m_w_ind == m_r_ind_prev.read() 
	   && m_w_top != m_r_top_prev.read();
}

// *****************************************************************************
// This function incrementes the read pointer. It can be called by the
// consumer process only.
// *****************************************************************************
template<int SIZE>
inline 
void
tlm_fifo_control<SIZE>::_incr_r()
{
    if (m_r_ind == Index(SIZE-1)) {
	m_r_ind = 0;
	m_r_top = !m_r_top;
    } else {
	m_r_ind += 1;
    }
    m_r_ind_prev = m_r_ind;
    m_r_top_prev = m_r_top;
}

// *****************************************************************************
// This function increments the write pointer. It can be called by the
// producer process only.
// *****************************************************************************
template<int SIZE>
inline 
void
tlm_fifo_control<SIZE>::_incr_w()
{
    if (m_w_ind == Index(SIZE-1)) {
	m_w_ind = 0;
	m_w_top = !m_w_top;
    } else {
	m_w_ind += 1;
    }
    m_w_ind_prev = m_w_ind;
    m_w_top_prev = m_w_top;
}

// *****************************************************************************
// This function returns the "extended value" of the read index at this time
// if now=true and otherwise at the beginning of this delta cycle. 
//
// The exetnded read/write index is the value of the read/write index, as though
// these indices are modified module (2*SIZE). To obetain the slot index take
// module SIZE. This is a convenient way to distinguish between a full and 
// empty fifo. For an empty fifo the extended indices are the same. For a full
// fifo their difference is SIZE. 
// *****************************************************************************
template<int SIZE>
int
tlm_fifo_control<SIZE>::internal_extended_read_index(bool now) const
{
    if (now) {
	return m_r_ind + (m_r_top ? SIZE : 0);
    } else {
	return m_r_ind_prev.read() + (m_r_top_prev.read() ? SIZE : 0);
    }
}

// *****************************************************************************
// This function returns the "extended value" of the write index at this time
// if now=true and otherwise at the beginning of this delta cycle. 
// *****************************************************************************
template<int SIZE>
int
tlm_fifo_control<SIZE>::internal_extended_write_index(bool now) const
{
    if (now) {
	return m_w_ind + (m_w_top ? SIZE : 0);
    } else {
	return m_w_ind_prev.read() + (m_w_top_prev.read() ? SIZE : 0);
    }
}

// *****************************************************************************
// This function returns the size of the fifo.
// *****************************************************************************
template<int SIZE>
int
tlm_fifo_control<SIZE>::internal_size() const
{
    return SIZE;
}

// *****************************************************************************
// This combinational process updates the state of the duplicate control
// signals.
// *****************************************************************************
template<int SIZE>
void
tlm_fifo_control<SIZE>::update_nb_can_signals()
{
    m_r_ind_prev_nb_can.write(m_r_ind_prev.read());
    m_r_top_prev_nb_can.write(m_r_top_prev.read());
    m_w_ind_prev_nb_can.write(m_w_ind_prev.read());
    m_w_top_prev_nb_can.write(m_w_top_prev.read());
}

// *****************************************************************************
// This function returns true if the fifo is empty. It may be called from the
// consumer process only. 
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_control<SIZE>::_is_empty_nb_can() const
{
    return m_r_ind == m_w_ind_prev_nb_can.read() 
	   && m_r_top == m_w_top_prev_nb_can.read();
}

// *****************************************************************************
// This function returns true if the fifo is full. It may be called from the
// producer process only. 
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_control<SIZE>::_is_full_nb_can() const
{
    return m_w_ind == m_r_ind_prev_nb_can.read() 
	   && m_w_top != m_r_top_prev_nb_can.read();
}

} //  namespace cynw_tlm

#endif
