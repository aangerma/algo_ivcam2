/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/
#ifndef cyn_immed_sig_h_INCLUDED
#define cyn_immed_sig_h_INCLUDED

#include "systemc.h"

#if defined STRATUS 
#pragma hls_ip_def
#endif	


namespace CYN {

//==============================================================================
// immediate_signal<T> - BLOCKING ASSIGNMENT VERSION OF sc_signal<T>
//
// This class implements a blocking assignment version of sc_signal<T>. Calls
// to its write method will result in an immediate update of the value rather
// than a deferred update through the update() method. Care should be taken
// when using this class as immediate value updates may cause race conditions
// to occur. The only recommended usage is for gating clocks. An sc_inout<T>
// port that is bound to an instance of immediate_signal<T> will perform
// immediate value updates when it is assigned values.
//==============================================================================
template<typename T>
class immediate_signal : public sc_signal<T> {
  public: // constructors and destructor:
  	immediate_signal() : sc_signal<T>() {}
	explicit immediate_signal( const char* name_ ) : sc_signal<T>(name_) {}
	virtual ~immediate_signal() {}

  public: // assignment operators:
    immediate_signal<T>& operator = ( const T& a )
        { write( a ); return *this; }
    immediate_signal<T>& operator = ( const sc_signal<T>& a )
        { write( a.read() ); return *this; }
    immediate_signal<T>& operator = ( const immediate_signal<T>& a )
        { write( a.read() ); return *this; }

  public: // immediate write support
    virtual inline void write( const T& value )
	{ 
		this->m_new_val = value; 
		if ( this->m_new_val != this->m_cur_val )
		{
			this->m_cur_val = this->m_new_val;
#if (defined(BDW_COWARE))
			this->m_value_changed_event->notify();
#else
			this->m_value_changed_event.notify();
#endif
			this->m_delta = sc_delta_count();
		}
    }
    inline void write_immediate( const T& value )
	{
		write(value);
	}

  private: // disabled
    immediate_signal(const immediate_signal<T>&);

};

//==============================================================================
// immediate_signal<bool> - bool SPECIALIZATION OF immediate_signal:
//
// This class implements a blocking assignment version of sc_signal<bool>. Calls
// to its write method will result in an immediate update of the value rather
// than a deferred update through the update() method. Care should be taken
// when using this class as immediate value updates may cause race conditions
// to occur. The only recommended usage is for gating clocks. An sc_inout<bool>
// port that is bound to an instance of immediate_signal<bool> will perform
// immediate value updates when it is assigned values.
//==============================================================================
template<>
class immediate_signal<bool> : public sc_signal<bool> {
  public: // constructors and destructor:
      typedef sc_signal<bool> base_type;
  	immediate_signal() : sc_signal<bool>() {}
	explicit immediate_signal( const char* name_ ) : sc_signal<bool>(name_) {}
	virtual ~immediate_signal() {}

  public: // assignment operators:
    immediate_signal<bool>& operator = ( const bool& a )
        { write( a ); return *this; }
    immediate_signal<bool>& operator = ( const sc_signal<bool>& a )
        { write( a.read() ); return *this; }
    immediate_signal<bool>& operator = ( const immediate_signal<bool>& a )
        { write( a.read() ); return *this; }

  public: // immediate write support
    virtual void write( const bool& value )
	{ 
	    m_new_val = value; 
	    if ( m_new_val != m_cur_val )
	    {
		m_cur_val = m_new_val;
#if (defined(BDW_COWARE))
		if ( m_value_changed_event != NULL )
		    m_value_changed_event->notify();
                if( m_cur_val ) {
		    if ( m_posedge_event != NULL ) m_posedge_event->notify();
                } else {
		    if ( m_negedge_event != NULL ) m_negedge_event->notify();
                }
#else
		((sc_event*)&base_type::value_changed_event())->notify();
		if( m_cur_val ) {
		    ((sc_event*)&base_type::posedge_event())->notify();
		} else {
		    ((sc_event*)&base_type::negedge_event())->notify();
		}
#endif
#if !defined(SYSTEMC_VERSION) || SYSTEMC_VERSION < 20110000
		m_delta = sc_delta_count();
#else
		m_change_stamp = simcontext()->change_stamp();
#endif
	    }
	}
    inline void write_immediate( const bool& value )
	{
		write(value);
	}

  private: // disabled
    immediate_signal(const immediate_signal<bool>&);

};

}; /* namespace CYN */

#endif /* cyn_immed_sig_h_INCLUDED */
