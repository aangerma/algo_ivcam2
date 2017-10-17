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
// ctos_tlm_fifo_1t_control.h
//
// This file contains the control portion of tlm_fifo_1t. It is synthesizable.
//
// 
// ****************************************************************************

#ifndef CYNW_TLM_FIFO_1T_CONTROL_HEADER
#define CYNW_TLM_FIFO_1T_CONTROL_HEADER

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
// Class tlm_fifo_1t_control
// 
// This class implements the control logic of fifo_1t, and fifo_reg_1t. 
// It is respondible for updating the read and write pointers.
// *****************************************************************************
template <int SIZE=1>
class tlm_fifo_1t_control :
  public virtual tlm_fifo_status_if,
  public virtual tlm_fifo_internals_control_if,
  public sc_module
{
  protected:
    // constructors
    explicit tlm_fifo_1t_control(const sc_module_name& name)
	: sc_module(name),
          m_r_ind_prev("m_r_ind_prev"),
          m_w_ind_prev("m_w_ind_prev"),
          m_r_top_prev("m_r_top_prev"),
          m_w_top_prev("m_w_top_prev"),
          m_r_clk_prev("m_r_clk_prev"),
          m_w_clk_prev("m_w_clk_prev")
	{
#if !defined(STRATUS)
	    assert(SIZE >= 1);
#endif
	    SC_METHOD(update_nb_can_signals);
	    sensitive << m_r_ind_prev << m_r_top_prev << m_r_clk_prev;
	    sensitive << m_w_ind_prev << m_w_top_prev << m_w_clk_prev;
	}

    // tlm fifo status interface
  public:
    virtual bool is_full() const;
    virtual bool is_empty() const;
    virtual int num_items() const;

    // Implementation
  public:
    typedef sc_uint< CYNW_GET_NUM_BITS(SIZE-1) > Index;

    sc_signal<Index>        m_r_ind_prev;
    sc_signal<Index>        m_w_ind_prev;
                            
    sc_signal<bool>         m_r_top_prev;
    sc_signal<bool>         m_w_top_prev;

    sc_signal<bool>         m_r_clk_prev;
    sc_signal<bool>         m_w_clk_prev;

  private:
    bool                    m_r_clk;
    bool                    m_w_clk;

  private:
    sc_signal<Index>        m_r_ind_prev_nb_can;
    sc_signal<Index>        m_w_ind_prev_nb_can;
                            
    sc_signal<bool>         m_r_top_prev_nb_can;
    sc_signal<bool>         m_w_top_prev_nb_can;

    sc_signal<bool>         m_r_clk_prev_nb_can;
    sc_signal<bool>         m_w_clk_prev_nb_can;

    void		    update_nb_can_signals();
			    SC_HAS_PROCESS(tlm_fifo_1t_control);

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
    bool _is_busy_r() const;
    bool _is_busy_w() const;
    bool _is_empty() const;
    bool _is_full() const;
    bool _is_empty_nb_can() const;
    bool _is_full_nb_can() const;
    bool _is_busy_r_nb_can() const;
    bool _is_busy_w_nb_can() const;

  private:
    // disabled
    tlm_fifo_1t_control( const tlm_fifo_1t_control& );
    tlm_fifo_1t_control& operator = ( const tlm_fifo_1t_control& );
};

// *****************************************************************************
// This function returns true if this fifo is full at the beginning of this
// clock cycle. This function is synthesizable and can be called from any
// process.
// *****************************************************************************
template<int SIZE>
bool
tlm_fifo_1t_control<SIZE>::is_full() const
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
tlm_fifo_1t_control<SIZE>::is_empty() const
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
tlm_fifo_1t_control<SIZE>::num_items() const
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
tlm_fifo_1t_control<SIZE>::_reset_w() 
{
    m_w_clk = false;
    m_w_ind_prev = 0;
    m_w_top_prev = false;
    m_w_clk_prev = false;
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
tlm_fifo_1t_control<SIZE>::_reset_r()
{
    m_r_clk = false;
    m_r_ind_prev = 0;
    m_r_top_prev = false;
    m_r_clk_prev = false;
}

// *****************************************************************************
// This function returns true if this fifo is empty. This is a protected
// function that can be called only from the getter process.
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_1t_control<SIZE>::_is_empty() const
{
    return m_r_ind_prev.read() == m_w_ind_prev.read() 
	   && m_r_top_prev.read() == m_w_top_prev.read();
}

// *****************************************************************************
// This function returns true if this fifo is full. This is a protected
// function that can be called only from the putter process.
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_1t_control<SIZE>::_is_full() const
{
    return m_w_ind_prev.read() == m_r_ind_prev.read() 
	   && m_w_top_prev.read() != m_r_top_prev.read();
}

// *****************************************************************************
// This function returns true if the consumer has already executed a transaction
// at this time step.
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_1t_control<SIZE>::_is_busy_r() const
{
    return m_r_clk != m_r_clk_prev.read();
}

// *****************************************************************************
// This function returns true if the producer has already executed a transaction
// at this time step.
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_1t_control<SIZE>::_is_busy_w() const
{
    return m_w_clk != m_w_clk_prev.read();
}

// *****************************************************************************
// This function incrementes the read pointer. It can be called by the
// consumer process only.
// *****************************************************************************
template<int SIZE>
inline 
void
tlm_fifo_1t_control<SIZE>::_incr_r()
{
    // Toggle m_r_clk, m_r_clk_prev.
    m_r_clk = !m_r_clk;
    m_r_clk_prev = m_r_clk;

    // Update m_r_ind_prev and m_r_top_prev.
    if (m_r_ind_prev.read() == Index(SIZE-1)) {
	m_r_ind_prev = 0;
	m_r_top_prev = !m_r_top_prev.read();
    } else {
	m_r_ind_prev = m_r_ind_prev.read() + 1;
    }
}

// *****************************************************************************
// This function increments the write pointer. It can be called by the
// producer process only.
// *****************************************************************************
template<int SIZE>
inline 
void
tlm_fifo_1t_control<SIZE>::_incr_w()
{
    // Toggle m_w_clk, m_w_clk_prev.
    m_w_clk = !m_w_clk;
    m_w_clk_prev = m_w_clk;

    // Update m_w_ind_prev and m_w_top_prev.
    if (m_w_ind_prev.read() == Index(SIZE-1)) {
	m_w_ind_prev = 0;
	m_w_top_prev = !m_w_top_prev.read();
    } else {
	m_w_ind_prev = m_w_ind_prev.read() + 1;
    }
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
tlm_fifo_1t_control<SIZE>::internal_extended_read_index(bool now) const
{
    if (now) {
	return m_r_ind_prev.get_new_value() + (m_r_top_prev.get_new_value() ? SIZE : 0);
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
tlm_fifo_1t_control<SIZE>::internal_extended_write_index(bool now) const
{
    if (now) {
	return m_w_ind_prev.get_new_value() + (m_w_top_prev.get_new_value() ? SIZE : 0);
    } else {
	return m_w_ind_prev.read() + (m_w_top_prev.read() ? SIZE : 0);
    }
}

// *****************************************************************************
// This function returns the size of the fifo.
// *****************************************************************************
template<int SIZE>
int
tlm_fifo_1t_control<SIZE>::internal_size() const
{
    return SIZE;
}

// *****************************************************************************
// This combinational process updates the state of the duplicate control
// signals.
// *****************************************************************************
template<int SIZE>
void
tlm_fifo_1t_control<SIZE>::update_nb_can_signals()
{
    m_r_ind_prev_nb_can.write(m_r_ind_prev.read());
    m_r_top_prev_nb_can.write(m_r_top_prev.read());
    m_w_ind_prev_nb_can.write(m_w_ind_prev.read());
    m_w_top_prev_nb_can.write(m_w_top_prev.read());
    m_r_clk_prev_nb_can.write(m_r_clk_prev.read());
    m_w_clk_prev_nb_can.write(m_w_clk_prev.read());
}

// *****************************************************************************
// This function returns true if the fifo is empty. It may be called from the
// consumer process only. 
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_1t_control<SIZE>::_is_empty_nb_can() const
{
    return m_r_ind_prev_nb_can.read() == m_w_ind_prev_nb_can.read() 
	   && m_r_top_prev_nb_can.read() == m_w_top_prev_nb_can.read();
}

// *****************************************************************************
// This function returns true if the fifo is full. It may be called from the
// producer process only. 
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_1t_control<SIZE>::_is_full_nb_can() const
{
    return m_w_ind_prev_nb_can.read() == m_r_ind_prev_nb_can.read() 
	   && m_w_top_prev_nb_can.read() != m_r_top_prev_nb_can.read();
}

// *****************************************************************************
// This function returns true if the consumer has already executed a transaction
// at this time step.
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_1t_control<SIZE>::_is_busy_r_nb_can() const
{
    return m_r_clk != m_r_clk_prev_nb_can.read();
}

// *****************************************************************************
// This function returns true if the producer has already executed a transaction
// at this time step.
// *****************************************************************************
template<int SIZE>
inline 
bool
tlm_fifo_1t_control<SIZE>::_is_busy_w_nb_can() const
{
    return m_w_clk != m_w_clk_prev_nb_can.read();
}

} //  namespace cynw_tlm

#endif
