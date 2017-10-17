/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/

#ifndef CYNW_COMM_UTIL_H
#define CYNW_COMM_UTIL_H

#include <systemc.h>
#include <cynthhl.h>
#include <esc.h>

// Inline function to check if the current process is an SC_CTHREAD or not.

inline bool cynw_is_cthread() {
    return (sc_get_curr_process_kind() == SC_CTHREAD_PROC_);
}

//
// CYNW_P2P_ASYNC_RESET
//
// This macro provides a temporary mechanism to cause synchronous SC_METHODs
// in a cynw_p2p metaport to use an async reset.  
//
// To enable async reset for all cynw_p2p ports in a design, add the following to
// hls_cc_options or to the options for a hls_config:
//
//   -DCYNW_P2P_ASYNC_RESET=1
//
// This setting will affect all subclasses of cynw_clk_rst that use the rst_active()
// function to sense the value of reset.
//
#ifndef CYNW_P2P_ASYNC_RESET
#define CYNW_P2P_ASYNC_RESET 0
#endif

#if defined STRATUS  &&  ! defined CYN_DONT_SUPPRESS_MSGS
#pragma cyn_suppress_msgs NOTE
#endif	// STRATUS  &&  CYN_DONT_SUPPRESS_MSGS

#if defined STRATUS 
#pragma hls_ip_def
#endif	

////////////////////////////////////////////////////////////
//
// Option values
//
// Options for cynw_p2p_out:
//
//   CYNW_II1_BEH	    Allows behavioral models to run with initiation interval 1.
//   CYNW_AUTO_VLD	    Compute the vld bit for put() calls based on data_was_valid()
//                          of inputs bound with stall_prop().
//
// Options for cynw_p2p_in:
//
//   CYNW_ASYNC_BUSY_PROP     Propagate busy from output ports asynchronously.
//   CYNW_SYNC_BUSY_PROP      Propagate busy from output ports synchronously.
//   CYNW_NO_RESET_STALL_PROP Propagate busy from output port directly with no reset.
//   CYNW_USE_INPUT_REG	      Always keep an input register for storing values during stalls.
//   CYNW_REG_INPUTS	      Register data and vld before use.
//   CYNW_II1_OPTIM	      Optimize for II=1 pipelines.
//
////////////////////////////////////////////////////////////

#define CYNW_II1_BEH		  0x0001
#define CYNW_AUTO_VLD		  0x0002
#define CYNW_ASYNC_BUSY_PROP	  0x0200
#define CYNW_SYNC_BUSY_PROP	  0x0400
#define CYNW_NO_RESET_BUSY_PROP   0x0800
#define CYNW_USE_STALL_REG	  0x1000
#define CYNW_REG_INPUTS		  0x2000
#define CYNW_II1_OPTIM		  0x4000
#define CYNW_AUTO_ASYNC_BUSY_PROP 0x8000

namespace cynw
{

////////////////////////////////////////////////////////////
//
// macro: CYNW_DO_CHECKING
//
// summary:
//
//   The CYNW_DO_CHECKING is true in behavioral
//   sims, and FALSE in stratus_hls and bdw_extract.
//
////////////////////////////////////////////////////////////
#if !defined(BDW_EXTRACT) && !defined(STRATUS_HLS)
#define CYNW_DO_CHECKING 1
#else
#define CYNW_DO_CHECKING 0
#endif

////////////////////////////////////////////////////////////
//
// macro: CYNW_BEH_SIM
//
// summary:
//
//   CYNW_BEH_SIM is true when compiling for behavioral
//   sims, and FALSE in other cases.
//
////////////////////////////////////////////////////////////
#if !defined(BDW_EXTRACT) && !defined(STRATUS_HLS) && !defined(STRATUS_VLG)
#define CYNW_BEH_SIM 1
#else
#define CYNW_BEH_SIM 0
#endif

//
// Values to be used with set_state() 
//
#define CYNW_SET_USE_STALL_REG	  1
#define CYNW_SET_DATA_WAS_VALID	  2
#define CYNW_SET_VALUE_WAS_READ	  3
#define CYNW_SET_BLOCKING	  4

////////////////////////////////////////////////////////////
//
// class: cynw_setting<T>
//
// summary: 
//
//   Provides a synthesizable mechanism for conditionally referencing
//   a value stored elsewhere that does not use port binding.
//
// kind: 
//
//   general purpose class
//
// template parameters: 
//
//   T : The data type of the setting.
//
// details:
//
//  The cynw_setting<T> class can be used to store a value, or a reference
//  to a value stored elsewhere.   If a cynw_setting<T> object is bound to
//  another cynw_setting<T> object, then values are retrieved by reference
//  to the remote object.  If no binding is done, then the local value 
//  stored in the object is returned as the value.
//
//  This class is useful for applications where a setting might either be
//  made directly relative to an instantiating object, or relative to 
//  some other object.  
//
//  The implementation of the class differs between gcc and stratus_hls.  In
//  gcc, pointers between objects are stored and traversed.  In stratus_hls,
//  the CYN_BIND directive is used to re-map identifiers.  The latter produces
//  a better synthesis result while maintaining the same semantics.
//
//  Bindings amongst cynw_settings<T> objects can be continued in an arbitrary
//  length chain, with the final object in the chain being unlinked.  
//
// example:
//
//  // Definition of a class that has a local setting.
//  class L {
//    public:
//      cynw_setting<bool> myval;
//  };
//
//  // Definition of a class that will get its setting remotely.
//  class R {
//    public:
//      cynw_setting<bool> myval;
//  };
//
//  // Instantiate an L with a local value of 'true'
//  L l( true );
//
//  // Bind 'r' to 'l'.
//  R r;
//  r(l);
//
//  // Both 'r' and 'l' will return the same value().
//  assert( r.value() == l.value() );
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_setting
{
  public:
    typedef cynw_setting<T>   this_type;

    cynw_setting() 
      : m_remote(0),
        m_local(0)
    {}

    cynw_setting( T iv ) 
      : m_remote(0), 
        m_local(iv)
    {}

    T value() 
    {
#if !defined STRATUS_HLS && !defined STRATUS_VLG
      if (m_remote)  {
	return m_remote->value();
      }
#endif
      return m_local;
    }

    void set_value( T v )
    {
      m_local = v;
      m_remote = 0;
    }

    void bind( this_type& r )
    {
#ifdef STRATUS_HLS
      CYN_BIND( m_local, r.m_local );
#else
      m_remote = &r;
#endif
    }

    void operator () ( this_type& other )
    {
      bind(other);
    }

    void operator = ( T v )
    {
      set_value(v);
    }

    operator T () 
    {
      return value();
    }

    this_type* m_remote;
    T m_local;
};
  
////////////////////////////////////////////////////////////
//
// class: cynw_clk_rst 
//
// summary: 
//
//   Adds clk and rst ports to the module that instantiates it
//   and provides standard binding functions for them.
//
// kind: 
//
//   base class
//
// template parameters: 
//
//   none.
//
// details:
//
//   This utility class is intended to be used as a base class for an sc_module
//   subclass that is an inline module.  It adds clk and rst ports, and has
//   binding functions for binding to the clk and rst ports on parent modules.
//
//   Note that though this class contains ports, it is not an sc_module.
//
//   By default, reset polarity is taken to be active low.  However, a
//   different polarity can be specified in the clk_rst() binding functions.
//
// example:
//
//   // Definition of inline module.
//   class mymod
//     : public sc_module,
//       public cynw_clk_rst  // Adds clk and rst ports and binding funcs.
//   {
//     public:
//       sc_in<bool> pin;
//       sc_out<bool> pout;
//
//       mymod( const char* name=0 ) : sc_module(name)
//       {
//         // Create a method sensitive to the clk and rst.
//         SC_METHOD(m);
//         sensitive << clk.pos();
//         sensitive << rst;
//       }
//
//       // Synchronous SC_METHOD that reads rst.
//       //
//       // Note that rst_active() is used rather than a direct read of
//       // the rst port because the instantiator can specify a polarity
//       // for rst in the binding function.
//       // The default polarity is active low.
//       // 
//       void m() 
//       {
//         if ( rst_active() ) {
//           pout = 0;
//         } else {
//           pout = !pin.read();
//         }
//       }
//
//       ...
//   };
//
//   // Module that instantiates an inline module using cynw_clk_rst.
//   SC_MODULE(M) 
//   {
//     sc_in_clk clk;
//     sc_in<bool> rst;
//
//     mymod mm;
//
//     SC_CTOR(M) 
//     {
//       // Bind outer module's clk and rst signals to mymod's clk and rst.
//       mm.clk_rst( clk, rst );
//     }
//   }
//
//   There are other binding functions provided for cynw_clk_rst.  They 
//   could be used in SC_CTOR(M) above as alternatives as follows:
//
//     // This form works when 'this' has members names 'clk' and 'rst':
//     mm.clk_rst(this);  
//
//     // This form works when binding a cynw_clk_rst to a module that is
//     // itself derived from cynw_clk_rst:
//     mm.clk_rst(*this);
//
//     // This form works when rst is active high:
//     mm.clk_rst( clk, rst, true );
//
//     // This form makes the reset async
//     mm.clk_rst_async( clk, rst );
//
//     // This form make reset both sync and async.
//     mm.clk_rst_sync_async( clk, srst, arst );
//
//     // This form is the same as clk_rst() but includes 'sync' in the name to be more clear.
//     mm.clk_rst_sync( clk, rst );
//
////////////////////////////////////////////////////////////
class cynw_clk_rst
{
  public:
    enum reset_kind 
    {
		async_reset,
		sync_reset,
		sync_async_reset_p,
		sync_async_reset_s,
#if CYNW_P2P_ASYNC_RESET
		default_reset = async_reset,
#else
		default_reset = sync_reset,
#endif
    };

    sc_in_clk clk;
    sc_in<bool> rst;
      
    cynw_setting< sc_in<bool>* > rst2_port_p;
    cynw_setting< sc_signal<bool>* > rst2_sig_p;

    cynw_setting<reset_kind> m_kind;
    cynw_setting<bool> m_rst_active_high;
    cynw_setting<bool> m_arst_active_high;

    cynw_clk_rst( const char* basename=0 )
      : clk( HLS_CAT_NAMES(basename,"clk")),
        rst( HLS_CAT_NAMES(basename,"rst")),
	rst2_port_p(0),
        rst2_sig_p(0),
	m_kind(default_reset),
	m_rst_active_high(false),
	m_arst_active_high(false)
    {
      HLS_SUPPRESS_MSG_SYM( 847, rst );
    }

    //
    // Binding function for binding to objects containing
    // objects named clk and rst.  M will ordinarily
    // be an sc_module subclass.
    //
    // If this function is called with an M that does not contain a 
    // clk and rst member, a compiler error will result.
    //
    template <class CYN_M>
    void clk_rst( CYN_M* mod, bool rah=false )
    {
      clk(mod->clk);
      rst(mod->rst);
      m_rst_active_high = rah;
      m_arst_active_high = rah;
#ifndef STRATUS_VLG
      m_kind = default_reset;
      rst2_port_p = 0;
      rst2_sig_p = 0;
#endif
    }

    //
    // Binding function giving explicit clk and rst references as ports.
    //
    void clk_rst( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false )
    {
      clk(b_clk);
      rst(b_rst);
      m_rst_active_high = rah;
      m_arst_active_high = rah;
      m_kind = default_reset;
    }

	void clk_rst_sync( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_rst);
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = sync_reset;
	}
	void clk_rst_async( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_rst);
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = async_reset;
	}
	void clk_rst_sync_async( sc_in_clk& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_srst);
	  rst2_port_p = &b_arst;
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = sync_async_reset_p;
	}
	void clk_rst_sync_async( sc_in_clk& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool srah, bool arah )
	{
	  clk(b_clk);
	  rst(b_srst);
	  rst2_port_p = &b_arst;
	  m_rst_active_high = srah;
	  m_arst_active_high = arah;
	  m_kind = sync_async_reset_p;
	}
	void clk_rst_sync( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_rst);
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = sync_reset;
	}
	void clk_rst_async( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_rst);
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = async_reset;
	}
	void clk_rst_sync( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_rst);
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = sync_reset;
	}
	void clk_rst_async( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_rst);
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = async_reset;
	}
	void clk_rst_sync_async( sc_in_clk& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_srst);
	  rst2_sig_p = &b_arst;
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = sync_async_reset_s;
	}
	void clk_rst_sync_async( sc_in_clk& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool srah, bool arah )
	{
	  clk(b_clk);
	  rst(b_srst);
	  rst2_sig_p = &b_arst;
	  m_rst_active_high = srah;
	  m_arst_active_high = arah;
	  m_kind = sync_async_reset_s;
	}
	void clk_rst_sync( sc_signal<bool>& b_clk, sc_in<bool>& b_rst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_rst);
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = sync_reset;
	}
	void clk_rst_async( sc_signal<bool>& b_clk, sc_in<bool>& b_rst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_rst);
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = async_reset;
	}
	void clk_rst_sync_async( sc_signal<bool>& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_srst);
	  rst2_port_p = &b_arst;
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = sync_async_reset_p;
	}
	void clk_rst_sync_async( sc_signal<bool>& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool srah, bool arah )
	{
	  clk(b_clk);
	  rst(b_srst);
	  rst2_port_p = &b_arst;
	  m_rst_active_high = srah;
	  m_arst_active_high = arah;
	  m_kind = sync_async_reset_p;
	}
	void clk_rst_sync( sc_signal<bool>& b_clk, sc_signal<bool>& b_rst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_rst);
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = sync_reset;
	}
	void clk_rst_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_rst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_rst);
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = async_reset;
	}
	void clk_rst_sync_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool rah=false )
	{
	  clk(b_clk);
	  rst(b_srst);
	  rst2_sig_p = &b_arst;
	  m_rst_active_high = rah;
	  m_arst_active_high = rah;
	  m_kind = sync_async_reset_s;
	}
	void clk_rst_sync_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool srah, bool arah )
	{
	  clk(b_clk);
	  rst(b_srst);
	  rst2_sig_p = &b_arst;
	  m_rst_active_high = srah;
	  m_arst_active_high = arah;
	  m_kind = sync_async_reset_s;
	}

    void clk_rst( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false )
    {
      clk(b_clk);
      rst(b_rst);
      m_rst_active_high = rah;
      m_arst_active_high = rah;
      m_kind = default_reset;
    }

    //
    // Binding function giving a real clock and a real reset signal.
    //
    void clk_rst( sc_clock& b_clk, sc_signal<bool>& b_rst, bool rah=false )
    {
      clk(b_clk);
      rst(b_rst);
      m_rst_active_high = rah;
      m_arst_active_high = rah;
      m_kind = default_reset;
    }

    //
    // Binding function giving a clock port and a reset signal.
    //
    void clk_rst( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false )
    {
      clk(b_clk);
      rst(b_rst);
      m_rst_active_high = rah;
      m_arst_active_high = rah;
      m_kind = default_reset;
    }

    //
    // Binding function giving a signal being used as a clock and a clock port.
    //
    void clk_rst( sc_signal<bool>& b_clk, sc_in<bool>& b_rst, bool rah=false )
    {
      clk(b_clk);
      rst(b_rst);
      m_rst_active_high = rah;
      m_arst_active_high = rah;
      warn_about_sc_signal_clk();
      m_kind = default_reset;
    }

    //
    // Binding function giving a signal being used as a clock and a reset signal
    //
    void clk_rst( sc_signal<bool>& b_clk, sc_signal<bool>& b_rst, bool rah=false )
    {
      clk(b_clk);
      rst(b_rst);
      m_rst_active_high = rah;
      m_arst_active_high = rah;
      warn_about_sc_signal_clk();
      m_kind = default_reset;
    }

    //
    // Binding function to daisy chain onto another cynw_clk_rst.
    // A pointer to this 'parent' module is kept and used when 
    // finding the reset polarity since that can be set in the parent
    // after this call is made.
    //
    void clk_rst( cynw_clk_rst& cr )
    {
      clk(cr.clk);
      rst(cr.rst);
#ifndef STRATUS_VLG
      m_rst_active_high( cr.m_rst_active_high );
      m_arst_active_high( cr.m_arst_active_high );
      m_kind(cr.m_kind);
      rst2_port_p(cr.rst2_port_p);
      rst2_sig_p(cr.rst2_sig_p);
#endif
    }

    // 
    // Function returns true if the rst signal is at its active polarity.
    //
    bool rst_active()
    {
		bool srah = m_rst_active_high.value();
		bool arah = m_arst_active_high.value();
		switch (m_kind.value()) 
		{
			case sync_reset:
			default:
				if (srah)
					CYN_SYNC( rst, 1, "reset" );
				else
					CYN_SYNC( rst, 0, "reset" );
				return ( rst.read() == srah );
			case async_reset:
				if (arah)
					CYN_ASYNC( rst, 1, "reset" );
				else
					CYN_ASYNC( rst, 0, "reset" );
				return ( rst.read() == arah );
			case sync_async_reset_p:
				if (srah) {
					CYN_SYNC( rst, 1, "reset" );
				} else {
					CYN_SYNC( rst, 0, "reset" );
				}
				if (arah) {
					CYN_ASYNC( *(rst2_port_p.value()), 1, "reset" );
				} else {
					CYN_ASYNC( *(rst2_port_p.value()), 0, "reset" );
				}
				return ( rst.read() == srah ) || ((rst2_port_p.value())->read() == arah);
			case sync_async_reset_s:
				if (srah) {
					CYN_SYNC( rst, 1, "reset" );
				} else {
					CYN_SYNC( rst, 0, "reset" );
				}
				if (arah) {
					CYN_ASYNC( *(rst2_sig_p.value()), 1, "reset" );
				} else {
					CYN_ASYNC( *(rst2_sig_p.value()), 0, "reset" );
				}
				return ( rst.read() == srah ) || ((rst2_sig_p.value())->read() == arah);
		}
    }
    //
    // Binding an sc_signal to a clock is supported, but may cause problems
    // with Verilog co-simulations, so emit a warning in a behavioral simulation.
    //
    void warn_about_sc_signal_clk()
    {
#ifndef STRATUS
      static bool reported_msg = false;
      if ( !reported_msg ) 
      {
	esc_report_error( esc_warning, "\n\t: cynw_clk_rst: "
				       "A clock is being bound to an sc_signal<>.\n\t  "
				       "This  may cause simulation mismatches in Verilog co-simulations.\n");
	reported_msg = true;
      }
#endif
    }
};

////////////////////////////////////////////////////////////
//
// class: cynw_clk_rst_facade
//
// summary: 
//
//   An empty class that contains the same binding functions as cynw_clk_rst.
//
// kind: 
//
//   base class
//
// template parameters:
//
//   none
//
// details:
//
//   This class is useful for subclasses that must offer the same API as one that
//   actually needs a clk and rst.
//
// example:
//
//   //
//   // Definition of inline module.
//   // This module does not need a clk and rst, but is intended to be
//   // plug replacible with one that does.
//   //
//   class mymod_tlm
//     : public sc_module,
//       public cynw_clk_rst_facade
//   {
//     public:
//       HLS_INLINE_MODULE;
//       ...
//   };
//
//   // Module that instantiates an inline module using cynw_clk_rst.
//   SC_MODULE(M) 
//   {
//     sc_in_clk clk;
//     sc_in<bool> rst;
//
//     mymod_tlm mm;
//
//     SC_CTOR(M) 
//     {
//       // This binding function does nothing, but it allows mymod_tlm
//       // to be used in the same places as an equivalent pin-level 
//       // implementation that does require clk and rst.
//       mm.clk_rst( clk, rst );
//     }
//   }
////////////////////////////////////////////////////////////
class cynw_clk_rst_facade
{
  public:
    cynw_clk_rst_facade( const char* basename=0 )
    {}

    template <class CYN_M> void clk_rst( CYN_M* mod, bool rah=false ) {}
    void clk_rst( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false ) {}
    void clk_rst( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false ) {}
    void clk_rst( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false ) {}
    void clk_rst( sc_signal<bool>& b_clk, sc_in<bool>& b_rst, bool rah=false ) {}
    void clk_rst( sc_signal<bool>& b_clk, sc_signal<bool>& b_rst, bool rah=false ) {}
	void clk_rst_sync( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false ) {}
	void clk_rst_async( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false ) {}
	void clk_rst_sync_async( sc_in_clk& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool rah=false ) {}
	void clk_rst_sync_async( sc_in_clk& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool srah, bool arah ) {}

	void clk_rst_sync( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false ) {}
	void clk_rst_async( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false ) {}

	void clk_rst_sync( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false ) {}
	void clk_rst_async( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false ) {}
	void clk_rst_sync_async( sc_in_clk& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool rah=false ) {}
	void clk_rst_sync_async( sc_in_clk& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool srah, bool arah ) {}

	void clk_rst_sync( sc_signal<bool>& b_clk, sc_in<bool>& b_rst, bool rah=false ) {}
	void clk_rst_async( sc_signal<bool>& b_clk, sc_in<bool>& b_rst, bool rah=false ) {}
	void clk_rst_sync_async( sc_signal<bool>& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool rah=false ) {}
	void clk_rst_sync_async( sc_signal<bool>& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool srah, bool arah ) {}

	void clk_rst_sync( sc_signal<bool>& b_clk, sc_signal<bool>& b_rst, bool rah=false ) {}
	void clk_rst_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_rst, bool rah=false ) {}
	void clk_rst_sync_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool rah=false ) {}
	void clk_rst_sync_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool srah, bool arah ) {}
    void clk_rst( cynw_clk_rst& cr ) {}
    bool rst_active() {return false;}
};

////////////////////////////////////////////////////////////
// macro: CYNW_CLK_RST_FUNCS
//
// summary:
//   
//   If a class derives from cynw_clk_rst, and also from a
//   base class that derives from cynw_clk_rst_facade, calls
//   to individual functions will be ambiguous.  This macro
//   adds local versions of the functions in the cynw_clk_rst
//   interface that are directed at the cynw_clk_rst base class.
////////////////////////////////////////////////////////////
#define CYNW_CLK_RST_FUNCS_P( pre, obj ) \
    template <class CYN_M> void pre##clk_rst( CYN_M* mod, bool rah=false ) \
      { obj cynw_clk_rst::clk_rst(mod,rah); } \
    void pre##clk_rst( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false ) \
      { obj cynw_clk_rst::clk_rst(b_clk,b_rst,rah); } \
    void pre##clk_rst( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false ) \
      { obj cynw_clk_rst::clk_rst(b_clk,b_rst,rah); } \
    void pre##clk_rst( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false ) \
      { obj cynw_clk_rst::clk_rst(b_clk,b_rst,rah); } \
    void pre##clk_rst( sc_signal<bool>& b_clk, sc_in<bool>& b_rst, bool rah=false ) \
      { obj cynw_clk_rst::clk_rst(b_clk,b_rst,rah); } \
    void pre##clk_rst( sc_signal<bool>& b_clk, sc_signal<bool>& b_rst, bool rah=false ) \
      { obj cynw_clk_rst::clk_rst(b_clk,b_rst,rah); } \
    void pre##clk_rst( cynw_clk_rst& cr ) \
      { obj cynw_clk_rst::clk_rst(cr); } \
	void pre##clk_rst_sync( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false ) \
	  { obj cynw_clk_rst::clk_rst_sync(b_clk,b_rst,rah); } \
	void pre##clk_rst_async( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false ) \
	  { obj cynw_clk_rst::clk_rst_async(b_clk,b_rst,rah); } \
	void pre##clk_rst_sync_async( sc_in_clk& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_sync_async(b_clk,b_srst,b_arst,rah); } \
	void pre##clk_rst_sync_async( sc_in_clk& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool srah, bool arah )  \
	  { obj cynw_clk_rst::clk_rst_sync_async(b_clk,b_srst,b_arst,srah,arah); } \
	void pre##clk_rst_sync( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_sync(b_clk,b_rst,rah); } \
	void pre##clk_rst_async( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_async(b_clk,b_rst,rah); } \
	void pre##clk_rst_sync( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_sync(b_clk,b_rst,rah); } \
	void pre##clk_rst_async( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_async(b_clk,b_rst,rah); } \
	void pre##clk_rst_sync_async( sc_in_clk& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_sync_async(b_clk,b_srst,b_arst,rah); } \
	void pre##clk_rst_sync_async( sc_in_clk& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool srah, bool arah )  \
	  { obj cynw_clk_rst::clk_rst_sync_async(b_clk,b_srst,b_arst,srah,arah); } \
	void pre##clk_rst_sync( sc_signal<bool>& b_clk, sc_in<bool>& b_rst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_sync(b_clk,b_rst,rah); } \
	void pre##clk_rst_async( sc_signal<bool>& b_clk, sc_in<bool>& b_rst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_async(b_clk,b_rst,rah); } \
	void pre##clk_rst_sync_async( sc_signal<bool>& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_sync_async(b_clk,b_srst,b_arst,rah); } \
	void pre##clk_rst_sync_async( sc_signal<bool>& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool srah, bool arah )  \
	  { obj cynw_clk_rst::clk_rst_sync_async(b_clk,b_srst,b_arst,srah,arah); } \
	void pre##clk_rst_sync( sc_signal<bool>& b_clk, sc_signal<bool>& b_rst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_sync(b_clk,b_rst,rah); } \
	void pre##clk_rst_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_rst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_async(b_clk,b_rst,rah); } \
	void pre##clk_rst_sync_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool rah=false )  \
	  { obj cynw_clk_rst::clk_rst_sync_async(b_clk,b_srst,b_arst,rah); } \
	void pre##clk_rst_sync_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool srah, bool arah )  \
	  { obj cynw_clk_rst::clk_rst_sync_async(b_clk,b_srst,b_arst,srah,arah); } \
    bool pre##rst_active() \
      { return obj cynw_clk_rst::rst_active(); } 
 
#define CYNW_CLK_RST_FUNCS \
	CYNW_CLK_RST_FUNCS_P(,this->)

#define CYNW_CLK_RST_FACADE_FUNCS_P( pre, obj ) \
    template <class CYN_M> void pre##clk_rst( CYN_M* mod, bool rah=false ) {} \
    void pre##clk_rst( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false ) {} \
    void pre##clk_rst( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false ) {} \
    void pre##clk_rst( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false ) {} \
	void pre##clk_rst_sync( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false ) {} \
	void pre##clk_rst_async( sc_in_clk& b_clk, sc_in<bool>& b_rst, bool rah=false ) {} \
	void pre##clk_rst_sync_async( sc_in_clk& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool rah=false ) {} \
	void pre##clk_rst_sync_async( sc_in_clk& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool srah, bool arah ) {} \
	void pre##clk_rst_sync( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false ) {} \
	void pre##clk_rst_async( sc_in_clk& b_clk, sc_out<bool>& b_rst, bool rah=false ) {} \
	void pre##clk_rst_sync( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false ) {} \
	void pre##clk_rst_async( sc_in_clk& b_clk, sc_signal<bool>& b_rst, bool rah=false ) {} \
	void pre##clk_rst_sync_async( sc_in_clk& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool rah=false ) {} \
	void pre##clk_rst_sync_async( sc_in_clk& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool srah, bool arah ) {} \
	void pre##clk_rst_sync( sc_signal<bool>& b_clk, sc_in<bool>& b_rst, bool rah=false ) {} \
	void pre##clk_rst_async( sc_signal<bool>& b_clk, sc_in<bool>& b_rst, bool rah=false ) {} \
	void pre##clk_rst_sync_async( sc_signal<bool>& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool rah=false ) {} \
	void pre##clk_rst_sync_async( sc_signal<bool>& b_clk, sc_in<bool>& b_srst, sc_in<bool>& b_arst, bool srah, bool arah ) {} \
	void pre##clk_rst_sync( sc_signal<bool>& b_clk, sc_signal<bool>& b_rst, bool rah=false ) {} \
	void pre##clk_rst_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_rst, bool rah=false ) {} \
	void pre##clk_rst_sync_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool rah=false ) {} \
	void pre##clk_rst_sync_async( sc_signal<bool>& b_clk, sc_signal<bool>& b_srst, sc_signal<bool>& b_arst, bool srah, bool arah ) {} \
    void pre##clk_rst( cynw_clk_rst& cr ) {} \
    bool pre##rst_active() { return false; } 

#define CYNW_CLK_RST_FACADE_FUNCS \
  CYNW_CLK_RST_FACADE_FUNCS_P(,this->) 

////////////////////////////////////////////////////////////
//
// struct: cynw_dual_clk_rst / cynw_dual_clk_rst_facacde
//
// summary: 
//
//   Convenience structs that contain two cynw_clk_rst or cynw_clk_rst_facade
//   classes as members.
//
// kind: 
//
//   struct
//
// template parameters:
//
//   none.
//
// details:
//
//   Intended to be used by clock-domain-crossing interfaces that need to connect
//   some elements to a writer-side clock, and some elements to a reader-side clock.
//
//	 The member cynw_clk_rst (cynw_clk_rst_facade) are named:
//
//		w_clk : Writer-side clock and reset.
//		r_clk : Reader-side clock and reset.
//
// example:
//
//   // Clock domain crossing fifo class.
//   class cdc_fifo : public cynw_dual_clk_rst
//   { 
//		MEM m_mem; // Dual port memory.
//		cdc_fifo() {
//			// Connect the clocks on a DP mem.
//			m_mem.clkA( w_clk.clk );
//			m_mem.clkB( r_clk.clk );
//
//			// method on writer side.
//			SC_METHOD( incr_w_addr );
//			sensitive << w_clk.clk.pos();
//			sensitive << w_clk.rst.neg();
//
//			// method on reader side.
//			SC_METHOD( incr_w_addr );
//			sensitive << r_clk.clk.pos();
//			sensitive << r_clk.rst.neg();
//
//			...
//
//	// Binding in the instantiating class.
//	SC_MODULE(dut) {
//		sc_in_clk clkA;
//		sc_in<bool> rstA;
//		sc_in_clk clkB;
//		sc_in<bool> rstB;
//
//		cdc_fifo m_fifo;
//		...
//		SC_CTOR(dut) {
//			m_fifo.w_clk_rst( clkA, rstA );
//			m_fifo.r_clk_rst( clkB, rstB );
//
//
////////////////////////////////////////////////////////////
struct cynw_dual_clk_rst
{ 
    cynw_dual_clk_rst( const char* basename=0 )
		: w_clk( HLS_CAT_NAMES(basename,"w_clk"))
		, r_clk( HLS_CAT_NAMES(basename,"r_clk"))
	{}
    cynw_clk_rst w_clk;
    cynw_clk_rst r_clk;

	
	CYNW_CLK_RST_FUNCS_P(w_,w_clk.)
	CYNW_CLK_RST_FUNCS_P(r_,r_clk.)
};

struct cynw_dual_clk_rst_facade
{ 
    cynw_dual_clk_rst_facade( const char* basename=0 ) {}

    cynw_clk_rst_facade w_clk;
    cynw_clk_rst_facade r_clk;

	CYNW_CLK_RST_FACADE_FUNCS_P(w_,w_clk.)
	CYNW_CLK_RST_FACADE_FUNCS_P(r_,r_clk.)
};

////////////////////////////////////////////////////////////
//
// function: cynw_assert_during_stall() 
//
// summary:
//
//   Specifies a signal that is to be forced to a specific value
//   during a pipeline stall.
//
// details:
//
//   The cynw_assert_during_stall() function causes the given signal
//   to be forced to the given value when the accessing thread
//   enters a stall condition.  Either a signal or an sc_out<> port
//   can be specified.   Such a signal can be used to ensure
//   an I/O protocol or an interface to a component instance behaves
//   properly during a stall.
//
//   The cynw_assert_during_stall() function should be called from the 
//   thread that will stall.  The call should occur in the reset
//   section of the thread before the first wait.
//
// example:
//
//   SC_MODULE(M) {
//     sc_in_clk clk;
//     sc_in<bool> rst;
//
//     // This output port will be forced high during a stall.
//     sc_out<busy> busy;
//
//     SC_CTOR() {
//	 SC_CTHREAD( thread, clk.pos();
//	 watching( rst.delayed() == 0);
//     }
//
//   void thread() {
//    
//      // Call the cynw_assert_during_stall() function from the reset 
//      // section of the thread containing the pipeline.
//      cynw_assert_during_stall( busy );
//
//	while (1) {
//	   CYN_INITIATE(CONSERVATIVE,1,"");
//	   ...
//	}
//   }
//
////////////////////////////////////////////////////////////
template <typename T>
inline void cynw_assert_during_stall( T& sig, int value=1, void* context=0, void* goes_with=0 )
{
  sig = 0;
  HLS_SET_STALL_VALUE( sig, 1, 1, context, goes_with );
  HLS_SET_OUTPUT_DELAY( sig, HLS_CLOCK_PERIOD - (HLS_FU_CLOCK_PERIOD/2) ); 
  HLS_SUPPRESS_MSG_SYM( 2588, sig );
}

////////////////////////////////////////////////////////////
//
// class: cynw_one_shot_in_if 
//
// summary: 
//
//   Interface used by a caller that will initiate one-shot pulses.
//
// kind: 
//
//   sc_interface
//
// template parameters:
//
//   none.
//
// details:
//
//   Should be inherited by classes that implement the interface.
//
// example:
//
//   // Channels implementing the interface:
//   class cynw_one_shot : public cynw_one_shot_in_if
//   { ...
//
//   // Ports onto the interface:
//   sc_port< cyn_one_shot_in_if> p;
//
////////////////////////////////////////////////////////////
class cynw_one_shot_in_if 
  : public virtual sc_interface
{
  public:
    virtual void trig()=0;  // Trigger a pulse.
    virtual void reset()=0; // Reset.
};

////////////////////////////////////////////////////////////
//
// class: cynw_one_shot
//
// summary: 
//
//   Generates a one-cycle pulse without requiring the caller 
//   to wait.
//
// kind:
//   
//   inline module
//
// template parameters:
//   
//   none
//
// details:
//
//   Many interface protocols require a single-cycle pulse to be generated.
//   For example a 'vld' output from an output interace may be required to be
//   high for only one cycle.  This can present complications in a
//   synthesizable model since a wait() needs to be added to the behavior to
//   implement the pulse.  This wait can increase the initiation interval of
//   both behavioral and unpipelined RTL models unnecessarily.
//
//   By designing interfaces using cynw_one_shot, the requirement for a call to
//   wait() in the calling CTHREAD can be avoided.  cynw_one_shot is an
//   inline module with embedded SC_METHODs that will guarantee a one-cycle
//   pulse.
//
//   By default, the 'active' pulse is 1, but the 'active_high' constructor
//   parameter can change this to active low.
//
// example:
//
//   SC_MODULE(M) 
//   {
//     sc_in_clk clk;
//     sc_in<bool> rst;
//
//     // Input and output ports.
//     sc_in<bool> ivld;
//     sc_in< sc_uint<8> > din;
//     sc_out<bool> ovld;
//     sc_out< sc_uint<8> > dout;
//
//     // Instantiate a one-shot
//     cynw_one_shot pulse;
//
//     SC_CTOR(M) 
//     {
//       SC_CTHREAD(t,clk.pos());
//       watching(rst.delayed()==1);
//       ...
//
//       // Bind the one-shot's output to the module's ovld port.
//		 pulse.active( ovld );
//
//       // Bind the one-shot's clk and rst to the module's.
//       pulse.clk_rst(this);
//     }
//     void t()
//     {
//       // Reset the one-shot.
//       pulse.reset();
//       
//       while (1) {
//
//         // Pipeline at II=1.
//         HLS_PIPELINE_LOOP( CONSERVATIVE, 1, "pipe" );
//         
//         // Read an input.
//         sc_uint<8> d;
//         bool is_vld;
//         { HLS_DEFINE_PROTOCOL("read");
//           wait(1);
//           is_vld = ivld.read();
//           d = din.read();
//         }
//
//         // If a valid input was received, compute a value and output.
//         if (is_vld) {
//           // Compute a value. 
//           d = f(d); 
//
//           // Write an output and send a one-cycle vld pulse
//           // using the one-shot.
//           dout = d;
//           pulse.trig();
//         }
//       }
//     }
//   };
//
//   In this example, because the only wait() in the behavioral
//   model is in the "read" HLS_DEFINE_PROTOCOL block, and since the 
//   cynw_one_shot does not perform a wait, the behavioral model
//   will execute at II=1.  This makes testbench integration simpler
//   for pipelined designs with no handshaking.
//
//   Note that the pulse.trig() function is called conditionally,
//   only if there was valid input data.  Each call will cause a
//   one-cycle pulse on ovld, such that if an invalid input is
//   read, ovld will be deasserted, while if several valid values
//   are processed in a row, ovld will remain asserted.
//
////////////////////////////////////////////////////////////
class cynw_one_shot
  : public sc_module,
    public cynw_clk_rst,
    public cynw_one_shot_in_if
{
 public:
    SC_HAS_PROCESS(cynw_one_shot);

    cynw_one_shot(  sc_module_name in_name = sc_module_name(sc_gen_unique_name("cynw_one_shot")), bool active_high=true ) 
      : sc_module(in_name),
        active("active"),
        m_trig_req("m_trig_req"),
        m_prev_trig_req("m_prev_trig_req"),
        m_next_trig_req("m_next_trig_req"),
        m_next_trig_req_reg("m_next_trig_req_reg"),
	m_active_high(active_high),
	m_is_async(false)
    {
      SC_METHOD(gen_active);
      sensitive << m_trig_req;
      sensitive << m_prev_trig_req;

      SC_METHOD(gen_prev_trig_reg);
      sensitive << clk.pos();
#if CYNW_P2P_ASYNC_RESET
      sensitive << rst.neg();
#endif
      dont_initialize();

      SC_METHOD(gen_next_trig_req_reg);
      sensitive << clk.pos();
#if CYNW_P2P_ASYNC_RESET
      sensitive << rst.neg();
#endif
      dont_initialize();

      SC_METHOD(gen_next_trig_reg);
      sensitive << m_trig_req;

      end_module(); 
    }

    //
    // Output port
    //
    sc_out<bool> active;

    // 
    // cynw_one_shot_in_if
    //
    void trig()
    {
      if (m_is_async)
	m_trig_req = m_next_trig_req_reg;
      else
	m_trig_req = m_next_trig_req;
    }

    void reset()
    {
      HLS_DEFINE_PROTOCOL("cynw_one_shot_reset");
      m_trig_req = 0;
      if (m_is_async)
	cynw_assert_during_stall( m_stalling, 1 );
    }

    //
    // Make trig() operate asynchronously with the given max_delay.
    //
    void set_async( double max_delay )
    {
      #ifdef STRATUS_HLS
      HLS_SET_OUTPUT_OPTIONS( m_trig_req, ASYNC_HOLD );
      HLS_SET_OUTPUT_DELAY( m_trig_req, HLS_CLOCK_PERIOD-max_delay );
      m_is_async = true;
      #endif
    }

  //protected:

    //
    // Internal signals.
    //
    sc_signal<bool> m_trig_req;
    sc_signal<bool> m_prev_trig_req;
    sc_signal<bool> m_next_trig_req;
    sc_signal<bool> m_next_trig_req_reg;
    sc_signal<bool> m_stalling;
    bool m_active_high;
    bool m_is_async;

    // 
    // Asynchronous SC_METHOD.
    //
    void gen_active()
    {
      if (m_active_high) 
	active = (!m_is_async || !m_stalling.read()) && ( m_trig_req.read() != m_prev_trig_req.read() );
      else
	active = (m_is_async && m_stalling.read()) || ( m_trig_req.read() == m_prev_trig_req.read() );
    }

    // 
    // Synchronous SC_METHOD.
    //
    void gen_prev_trig_reg()
    {
      if ( rst_active() ) {
	HLS_SET_IS_RESET_BLOCK("gen_prev_trig_reg");
        m_prev_trig_req = 0;
      } else {
        m_prev_trig_req = m_trig_req.read();
      }
    }

    // 
    // Synchronous SC_METHOD.
    //
    void gen_next_trig_req_reg()
    {
      if ( rst_active() ) {
	HLS_SET_IS_RESET_BLOCK("gen_next_trig_req_reg");
        m_next_trig_req_reg = 1;
      } else {
        m_next_trig_req_reg = m_next_trig_req.read();
      }
    }

    // 
    // Asynchronous SC_METHOD.
    //
    void gen_next_trig_reg()
    {
      m_next_trig_req = !m_trig_req.read();
    }

};



////////////////////////////////////////////////////////////
//
// cynw_stall_prop classes
//
////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
// 
// Forward declarations
//
////////////////////////////////////////////////////////////

class cynw_stall_prop_in;
class cynw_stall_prop_out;

////////////////////////////////////////////////////////////
//
// class: cynw_stall_prop_out
//
// kind:
//
//  base class
//
// summary: 
//
//  Used as a base class for output metaports that must bind to
//  a cynw_stall_prop.
//
// template parameters:
//
//  none.
//
// details:
//
//  The cynw_stall_prop_out class provides the elements required
//  for an output metaport to bind to a cynw_stall_prop object.
//  These elements are:
//
//    sc_signal<bool> m_out_busy;
//
//      A signal written by the derived metaport class to indicate
//      that the downstream module is busy.  This is used by the stall
//      manager to offer a passthrough of the downstream stall to other
//      metaports in the module.
//
//    cynw_setting<bool> m_data_was_valid;
//
//      A setting that may optionally be bound to a similar setting in an
//      input port.  If no binding is made, it is always true.  See doc
//      for cynw_setting<T> for details on how this object works.
//
//  Each of these items is a protected data item that is also accessible
//  to the friend class cynw_stall_prop.
//
//  A class derived from cynw_stall_prop_out can be bound to a cynw_stall_prop
//  object, but this binding is optional.  The derived metaport class is 
//  expected to operate either with or without binding to a stall manager.
//
// example:
//
//   // Output metaport derived from cynw_stall_prop_out:
//   class my_if_out : public cynw_stall_prop_out
//   {
//     public:
//       HLS_METAPORT;
//       //...
//
//   // Binding of output metaport to stall mgr.
//   SC_MODULE(M) 
//   {
//     cynw_stall_prop stall;
//     my_if_in inp;
//     my_if_out outp;
//
//     SC_CTOR(M) 
//     {
//       // Bind input and output to stall mgr.
//       stall( inp, outp );
//     }
//
//
// example:
//
////////////////////////////////////////////////////////////
class cynw_stall_prop_out
{
  public:
    cynw_stall_prop_out( const char* name=0, unsigned options=0 )
      : m_options_stall(options),
	m_n_inputs_b(0),
	m_n_inputs_v(0)
    {}

    //
    // Pushes the given busy_val on all inputs to which we are bound.
    // This function should be called from a method in the subclass
    // that is sensitive to the busy state.
    //
    void update_out_busy( bool busy_val )
    {
      if (m_n_inputs_b > 0) *in0 = busy_val;
      if (m_n_inputs_b > 1) *in1 = busy_val;
      if (m_n_inputs_b > 2) *in2 = busy_val;
      if (m_n_inputs_b > 3) *in3 = busy_val;
      if (m_n_inputs_b > 4) *in4 = busy_val;
      if (m_n_inputs_b > 5) *in5 = busy_val;
      if (m_n_inputs_b > 6) *in6 = busy_val;
      if (m_n_inputs_b > 7) *in7 = busy_val;
    }

    //
    // Returns the AND of the data_was_valid setting for all bound inputs.
    //
    bool data_was_valid()
    {
      switch (m_n_inputs_v) 
      {
	default:
	case 0: return true;
	case 1: return *iv0;
	case 2: return *iv0 && *iv1;
	case 3: return *iv0 && *iv1 && *iv2;
	case 4: return *iv0 && *iv1 && *iv2 && *iv3;
	case 5: return *iv0 && *iv1 && *iv2 && *iv3 && *iv4;
	case 6: return *iv0 && *iv1 && *iv2 && *iv3 && *iv4 && *iv5;
	case 7: return *iv0 && *iv1 && *iv2 && *iv3 && *iv4 && *iv5 && *iv6;
	case 8: return *iv0 && *iv1 && *iv2 && *iv3 && *iv4 && *iv5 && *iv6 && *iv7;
      }
    }
    void set_option( unsigned o )
    {
      m_options_stall |= o;
    }
    void clear_option( unsigned o )
    {
      m_options_stall &= ~o;
    }
  protected:
  public:
    friend class cynw_stall_prop_in;

    unsigned m_options_stall;
    int m_n_inputs_b;
    int m_n_inputs_v;
    sc_signal<bool> *in0, *in1, *in2, *in3, *in4, *in5, *in6, *in7;
    bool *iv0, *iv1, *iv2, *iv3, *iv4, *iv5, *iv6, *iv7;
};

////////////////////////////////////////////////////////////
//
// class: cyn_stall_mgr_in
//
// kind:
//
//  base class
//
// summary: 
//
//  Used as a base class for input metaports that must bind to
//  a cynw_stall_prop.
//
// template parameters:
//
//  none.
//
// details:
//  
//  The cynw_stall_prop_in class provides the elements required
//  for an input metaport to bind to a cynw_stall_prop object.
//  These elements are:
//
//    sc_signal<bool> m_busy_in:
//
//      This signal can be monitored by the subclass as an indication
//      that the a stall is in effect downstream.  Depending on how
//      this signal is bound, this may be a direct passthrough of the
//      downstream stall, or it may be an indication that accessing
//      CTHREAD is currently in a stall.
//
//    bool m_data_was_valid:
//
//      A variable that the derived class must set to 1 after reading
//      a valid input value, and set to 0 after reading an invalid
//      input value.  The latest setting for m_data_was_valid is
//      accessible via the data_was_valid() member function.
//
//  Each of these items is a protected data item that is also accessible
//  to the friend class cynw_stall_prop.
//
//  A class derived from cynw_stall_prop_in can be bound to a cynw_stall_prop
//  object, but this binding is optional.  The derived metaport class is 
//  expected to operate either with or without binding to a stall manager.
//
// example:
//
//   // Input metaport derived from cynw_stall_prop_in:
//   class my_if_in : public cynw_stall_prop_in
//   {
//     public:
//       HLS_METAPORT;
//       //...
//
//   // Binding of input metaport to stall mgr.
//   SC_MODULE(M) 
//   {
//     cynw_stall_prop stall;
//     my_if_in inp;
//
//     SC_CTOR(M) 
//     {
//       // Bind input to stall mgr.
//       stall( inp );
//     }
//
//
////////////////////////////////////////////////////////////
class cynw_stall_prop_in
{
  public:
    cynw_stall_prop_in( const char* name=0, unsigned options=0 ) 
      : m_busy_in(HLS_CAT_NAMES(name,"m_busy_in")),
        m_data_was_valid(false),
	m_n_outputs_b(0),
	m_n_outputs_v(0),
	m_options_stall(options)
    {}

    bool data_was_valid()
    {
      return m_data_was_valid;
    }

    //
    // Bind a single output metaport for stall propagation.
    //
    template <class CYN_P> 
    void stall_prop1( CYN_P& out, bool sync_only=false )
    {
      sc_signal<bool>* target;
      if ( ((m_options_stall & (CYNW_SYNC_BUSY_PROP)) == 0) && !sync_only ) 
      {
	// Record busy signal to update only if async busy prop is requested.
	switch (m_n_outputs_b) 
	{
	  default:
	  case 0: target = &ob0; break;
	  case 1: target = &ob1; break;
	  case 2: target = &ob2; break;
	  case 3: target = &ob3; break;
	  case 4: target = &ob4; break;
	  case 5: target = &ob5; break;
	  case 6: target = &ob6; break;
	  case 7: target = &ob7; break;
	}
	switch (out.m_n_inputs_b) 
	{
	  case 0: out.in0 = target; break;
	  case 1: out.in1 = target; break;
	  case 2: out.in2 = target; break;
	  case 3: out.in3 = target; break;
	  case 4: out.in4 = target; break;
	  case 5: out.in5 = target; break;
	  case 6: out.in6 = target; break;
	  case 7: out.in7 = target; break;
	  default: break;
	}
	out.m_n_inputs_b++;
	m_n_outputs_b++;
      } 
      switch (out.m_n_inputs_v) 
      {
	case 0: out.iv0 = &m_data_was_valid; break;
	case 1: out.iv1 = &m_data_was_valid; break;
	case 2: out.iv2 = &m_data_was_valid; break;
	case 3: out.iv3 = &m_data_was_valid; break;
	case 4: out.iv4 = &m_data_was_valid; break;
	case 5: out.iv5 = &m_data_was_valid; break;
	case 6: out.iv6 = &m_data_was_valid; break;
	case 7: out.iv7 = &m_data_was_valid; break;
	default: break;
      }
      out.m_n_inputs_v++;
      m_n_outputs_v++;
    }

    //
    // Binding functions for several numbers of output ports.
    //
    template <class CYN_P0> 
    void stall_prop( CYN_P0& o0 )
    {
      stall_prop1(o0);
    }
    template <class CYN_P0, class CYN_P1> 
    void stall_prop( CYN_P0& o0, CYN_P1& o1 )
    {
      stall_prop1(o0);
      stall_prop1(o1);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2> 
    void stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2 )
    {
      stall_prop1(o0);
      stall_prop1(o1);
      stall_prop1(o2);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3> 
    void stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3 )
    {
      stall_prop1(o0);
      stall_prop1(o1);
      stall_prop1(o2);
      stall_prop1(o3);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4> 
    void stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4 )
    {
      stall_prop1(o0);
      stall_prop1(o1);
      stall_prop1(o2);
      stall_prop1(o3);
      stall_prop1(o4);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5> 
    void stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4, CYN_P5& o5 )
    {
      stall_prop1(o0);
      stall_prop1(o1);
      stall_prop1(o2);
      stall_prop1(o3);
      stall_prop1(o4);
      stall_prop1(o5);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5, class CYN_P6> 
    void stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4, CYN_P5& o5, CYN_P6& o6 )
    {
      stall_prop1(o0);
      stall_prop1(o1);
      stall_prop1(o2);
      stall_prop1(o3);
      stall_prop1(o4);
      stall_prop1(o5);
      stall_prop1(o6);
    }

    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5, class CYN_P6, class CYN_P7> 
    void stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4, CYN_P5& o5, CYN_P6& o6, CYN_P7& o7 )
    {
      stall_prop1(o0);
      stall_prop1(o1);
      stall_prop1(o2);
      stall_prop1(o3);
      stall_prop1(o4);
      stall_prop1(o5);
      stall_prop1(o6);
      stall_prop1(o7);
    }
    template <class CYN_P0> 
    void sync_stall_prop( CYN_P0& o0 )
    {
      stall_prop1(o0,true);
    }
    template <class CYN_P0, class CYN_P1> 
    void sync_stall_prop( CYN_P0& o0, CYN_P1& o1 )
    {
      stall_prop1(o0,true);
      stall_prop1(o1,true);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2> 
    void sync_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2 )
    {
      stall_prop1(o0,true);
      stall_prop1(o1,true);
      stall_prop1(o2,true);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3> 
    void sync_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3 )
    {
      stall_prop1(o0,true);
      stall_prop1(o1,true);
      stall_prop1(o2,true);
      stall_prop1(o3,true);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4> 
    void sync_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4 )
    {
      stall_prop1(o0,true);
      stall_prop1(o1,true);
      stall_prop1(o2,true);
      stall_prop1(o3,true);
      stall_prop1(o4,true);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5> 
    void sync_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4, CYN_P5& o5 )
    {
      stall_prop1(o0,true);
      stall_prop1(o1,true);
      stall_prop1(o2,true);
      stall_prop1(o3,true);
      stall_prop1(o4,true);
      stall_prop1(o5,true);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5, class CYN_P6> 
    void sync_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4, CYN_P5& o5, CYN_P6& o6 )
    {
      stall_prop1(o0,true);
      stall_prop1(o1,true);
      stall_prop1(o2,true);
      stall_prop1(o3,true);
      stall_prop1(o4,true);
      stall_prop1(o5,true);
      stall_prop1(o6,true);
    }

    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5, class CYN_P6, class CYN_P7> 
    void sync_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4, CYN_P5& o5, CYN_P6& o6, CYN_P7& o7 )
    {
      stall_prop1(o0,true);
      stall_prop1(o1,true);
      stall_prop1(o2,true);
      stall_prop1(o3,true);
      stall_prop1(o4,true);
      stall_prop1(o5,true);
      stall_prop1(o6,true);
      stall_prop1(o7,true);
    }
    template <class CYN_P0> 
    void async_stall_prop( CYN_P0& o0 )
    {
      stall_prop1(o0,false);
    }
    template <class CYN_P0, class CYN_P1> 
    void async_stall_prop( CYN_P0& o0, CYN_P1& o1 )
    {
      stall_prop1(o0,false);
      stall_prop1(o1,false);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2> 
    void async_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2 )
    {
      stall_prop1(o0,false);
      stall_prop1(o1,false);
      stall_prop1(o2,false);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3> 
    void async_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3 )
    {
      stall_prop1(o0,false);
      stall_prop1(o1,false);
      stall_prop1(o2,false);
      stall_prop1(o3,false);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4> 
    void async_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4 )
    {
      stall_prop1(o0,false);
      stall_prop1(o1,false);
      stall_prop1(o2,false);
      stall_prop1(o3,false);
      stall_prop1(o4,false);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5> 
    void async_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4, CYN_P5& o5 )
    {
      stall_prop1(o0,false);
      stall_prop1(o1,false);
      stall_prop1(o2,false);
      stall_prop1(o3,false);
      stall_prop1(o4,false);
      stall_prop1(o5,false);
    }
    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5, class CYN_P6> 
    void async_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4, CYN_P5& o5, CYN_P6& o6 )
    {
      stall_prop1(o0,false);
      stall_prop1(o1,false);
      stall_prop1(o2,false);
      stall_prop1(o3,false);
      stall_prop1(o4,false);
      stall_prop1(o5,false);
      stall_prop1(o6,false);
    }

    template <class CYN_P0, class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5, class CYN_P6, class CYN_P7> 
    void async_stall_prop( CYN_P0& o0, CYN_P1& o1, CYN_P2& o2, CYN_P3& o3, CYN_P4& o4, CYN_P5& o5, CYN_P6& o6, CYN_P7& o7 )
    {
      stall_prop1(o0,false);
      stall_prop1(o1,false);
      stall_prop1(o2,false);
      stall_prop1(o3,false);
      stall_prop1(o4,false);
      stall_prop1(o5,false);
      stall_prop1(o6,false);
      stall_prop1(o7,false);
    }
    void set_option( unsigned o )
    {
      m_options_stall |= o;
    }
    void clear_option( unsigned o )
    {
      m_options_stall &= ~o;
    }
  public:
    friend class cynw_stall_prop;


    sc_signal<bool> m_busy_in;
    bool m_data_was_valid;
    
    int m_n_outputs_b;
    int m_n_outputs_v;
    unsigned m_options_stall;

    sc_signal<bool> ob0, ob1, ob2, ob3, ob4, ob5, ob6, ob7;
};


//==============================================================================
// cynw_sync<LEVEL> - synchronized boolean class
// 
// This class and its in, in_fast, and out classes synchronize a boolean 
// signal across a clock domain crossing. 
//
// There are currently two overloads of the LEVEL template argument:
//    CYN::PIN - implements a PIN level version that actually implements a
//               synchronization using a pair of flip-flops.
//    CYN::TLM - implements a TLM level version that just provides an
//               sc_in<bool> instance with no additional synchronization
//               storage or logic.
// In both versions the in class acts like an sc_in<bool> instance. It should
// be bound to the cynw_sync<LEVEL> instance, and values are
// written to it using the put() method of the out class. The out class
// should also be bound to the cynw_sync<LEVEL> instance:
//
// +-----------------------+
// | cynw_sync<LEVEL>::out |
// +-----------------------+
//             |
//             V
// +-----------------------+
// |   cynw_sync<LEVEL>    |
// +-----------------------+
//             |
//             V
// +-----------------------+
// | cynw_sync<LEVEL>::in  |
// +-----------------------+
//
// There are two forms of the input port, in, and 
// in_fast:
//    in_fast  - if the input value is true immediately make it available as
//               the value of this object instance. If the input value is false
//               cascade it through the two flip flops, resulting in a one clock
//               delay.
//    in       - always cascade the input value through two flip flops, 
//               resulting in a one clock delay regardless of the input value.
// The in_fast port allows a faster response to a true value if the input is
// meta-stable. The in value guarantees that other signal values set at 
// same time as the sync value is set will be valid when sampled, since the
// values will settle during the extra clock required to pass the sync value
// through to a design.
//
//==============================================================================

template<typename LEVEL=CYN::PIN> class cynw_sync;

//------------------------------------------------------------------------------
// cynw_sync_in_base - base for synchronsized boolean input class
// 
// This acts like an sc_in<bool>, using its contained instance.
//------------------------------------------------------------------------------
class cynw_sync_in_base 
{
    HLS_METAPORT;
  	typedef cynw_sync_in_base this_type;
  public:
    cynw_sync_in_base(const char* name_p="base") : m_input("input") {}
    void operator () ( sc_in<bool>& port ) { m_input( port ); }
    void operator () ( const sc_signal_in_if<bool>& iface ) {m_input( iface );}
	operator bool () const { return m_input.read(); }
	bool read() const { return m_input.read(); }
    
    sc_in<bool> m_input;

  private:
  	const this_type& operator = ( const this_type& );
  	cynw_sync_in_base( const this_type& );
};

//------------------------------------------------------------------------------
// cynw_sync_in_pin<CYN_FAST> - pin level synchronisized boolean input class
// 
// The CYN_FAST template argument is a boolean value:
//    true  - if the input value is true immediately make it available as
//            the value of this object instance. If the input value is false
//            cascade it through the two flip flops, resulting in a one clock
//            delay.
//    false - always cascade the input value through two flip flops, 
//            resulting in a one clock delay regardless of the input value.
//------------------------------------------------------------------------------
template<bool CYN_FAST>
SC_MODULE(cynw_sync_in_pin) ,
	public cynw_clk_rst,
	public cynw_sync_in_base
{
	HLS_EXPOSE_PORTS( OFF, clk, rst );
  	typedef cynw_sync_in_pin this_type;

  public:
	SC_CTOR(cynw_sync_in_pin) : 
		m_flip_flop0("flip_flop0"),
		m_flip_flop1("flip_flop1")
	{
		SC_METHOD(synch);
		sensitive << clk.pos();
		dont_initialize();
	}

	bool get() const { return m_flip_flop1.read(); }

	operator bool () const { return m_flip_flop1.read(); }

	void operator () ( const cynw_sync<CYN::PIN>& sync );
	void operator () ( sc_in<bool>& port ) { this->m_input( port ); }
	void operator () ( const sc_signal_in_if<bool>& iface ) 
		{ this->m_input( iface ); }
	

	bool read() const { return m_flip_flop1.read(); }

	void synch()
	{
		bool input;
		if ( this->rst.read() == false )  // in reset.
		{
			m_flip_flop0 = 0;
			m_flip_flop1 = 0;
		}
		else if ( CYN_FAST )
		{
			input = this->m_input.read();
			if ( input )   // valid signal.
			{
				m_flip_flop1 = true;
				m_flip_flop0 = true;
			}
			else           // can't tell, cascade it.
			{
				m_flip_flop1 = m_flip_flop0;
				m_flip_flop0 = input;
			}
		}
		else
		{
			input = this->m_input.read();
			m_flip_flop1 = m_flip_flop0;
			m_flip_flop0 = input;
		}
	}

	void wait_until( bool level )
	{
		{
			HLS_DEFINE_PROTOCOL("wait_until");
			do { wait(); } while ( m_flip_flop1.read() != level );
		}
	}

	sc_signal<bool> m_flip_flop0; // initial sample of m_input.
	sc_signal<bool> m_flip_flop1; // sample of m_input one clock later.

  private:
  	const this_type& operator = ( const this_type& );
  	cynw_sync_in_pin( const this_type& );
};

//------------------------------------------------------------------------------
// cynw_sync_out_pin - pin level synchronsized boolean output class
// 
//------------------------------------------------------------------------------
class cynw_sync_out_pin
{
	HLS_METAPORT;
  public:
  	typedef cynw_sync_out_pin this_type;
	cynw_sync_out_pin(const char* name_p="base") : m_sync_output("sync_output") 
	{}
	void operator () ( cynw_sync<CYN::PIN>& sync );
	void operator () ( sc_out<bool>& port ) { m_sync_output( port ); }
	void operator () ( sc_signal_out_if<bool>& iface ) 
	    { m_sync_output( iface ); }
	inline void put( bool value ) 
	{
		HLS_DEFINE_PROTOCOL("cynw_sync_put");
		m_sync_output = value;
	}
	
  public:
	sc_out<bool> m_sync_output;

  private:
  	const this_type& operator = ( const this_type& );
  	cynw_sync_out_pin( const this_type& );
};


//------------------------------------------------------------------------------
// cynw_sync_in_tlm - tlm level synchronsized boolean input class
// 
//------------------------------------------------------------------------------
SC_MODULE(cynw_sync_in_tlm) ,
	public cynw_sync_in_base
{
  public:
  	typedef cynw_sync_in_tlm this_type;
	SC_CTOR(cynw_sync_in_tlm) 
	{
	}

	void clk_rst( sc_in<bool>& clk, sc_in<bool>& rst ) {}
	void clk_rst( sc_in<bool>& clk, const sc_signal_in_if<bool>& rst ) {}

	//operator bool () const { return this->m_input.read(); }

	void operator () ( const cynw_sync<CYN::TLM>& sync );
	void operator () ( sc_in<bool>& port ) { this->m_input( port ); }
	void operator () ( const sc_signal_in_if<bool>& iface ) 
		{ this->m_input( iface ); }
	

	void wait_until( bool level )
	{
		{
			HLS_DEFINE_PROTOCOL("wait_until");
			do { wait(); } while ( this->m_input.read() != level );
		}
	}

  private:
  	const this_type& operator = ( const this_type& );
  	cynw_sync_in_tlm( const this_type& );
};

//------------------------------------------------------------------------------
// cynw_sync_out_tlm - tlm level synchronsized boolean output class
// 
//------------------------------------------------------------------------------
class cynw_sync_out_tlm
{
  	typedef cynw_sync_out_tlm this_type;
	HLS_METAPORT;
  public:
	cynw_sync_out_tlm(const char* name_p="base") : m_sync_output("sync_output") 
	{}
	void operator () ( cynw_sync<CYN::TLM>& sync );
	void operator () ( sc_out<bool>& port ) { m_sync_output( port ); }
	void operator () ( sc_signal_out_if<bool>& iface ) 
	{ 
		m_sync_output( iface );
	}
	inline void put( bool value ) 
	{
		m_sync_output = value;
	}
	
  public:
	sc_out<bool> m_sync_output;

  private:
  	const this_type& operator = ( const this_type& );
  	cynw_sync_out_tlm( const this_type& );
};

//------------------------------------------------------------------------------
// cynw_sync<CYN::PIN> - pin level specialization - boolean signal synchronizer
//------------------------------------------------------------------------------
template<>
class cynw_sync<CYN::PIN>
{
  public:
  	typedef cynw_sync_in_base                    base_in;
	typedef sc_out<bool>                         base_out;
  	typedef cynw_sync_in_pin<false>              in;
	typedef sc_export<sc_signal_in_if<bool> >    in_export;
  	typedef cynw_sync_in_pin<true>               in_fast;
  	typedef cynw_sync_out_pin                    out;
	typedef sc_export<sc_signal_out_if<bool> >   out_export;

  public:
  	cynw_sync(const char* name_p=sc_gen_unique_name("sync")) 
		: m_sync_signal(name_p) {}
	operator sc_signal<bool>& () { return m_sync_signal; }

  public:
  	sc_signal<bool> m_sync_signal;
};

template<bool CYN_FAST>
inline 
void cynw_sync_in_pin<CYN_FAST>::operator () ( const cynw_sync<CYN::PIN>& sync )
	{ this->m_input(sync.m_sync_signal); }
inline void cynw_sync_out_pin::operator () ( cynw_sync<CYN::PIN>& sync )
	{ m_sync_output(sync.m_sync_signal); }

//------------------------------------------------------------------------------
// cynw_sync<CYN::TLM> - tlm level specialization - boolean signal synchronizer
//------------------------------------------------------------------------------
template<>
class cynw_sync<CYN::TLM>
{
  	typedef cynw_sync<CYN::TLM> this_type;
  public:
  	typedef cynw_sync_in_base                  base_in;
	typedef sc_out<bool>                       base_out;
  	typedef cynw_sync_in_tlm                   in;
	typedef sc_export<sc_signal_in_if<bool> >  in_export;
  	typedef cynw_sync_in_tlm                   in_fast;
  	typedef cynw_sync_out_tlm                  out;
	typedef sc_export<sc_signal_out_if<bool> > out_export;
  public:
  	cynw_sync(const char* name_p=sc_gen_unique_name("sync")) 
		: m_sync_signal(name_p) {}
	operator sc_signal<bool>& () { return m_sync_signal; }
  public:
  	sc_signal<bool> m_sync_signal;
  private:
  	cynw_sync( const this_type& );
  	const this_type& operator = ( const this_type& );
};

inline void cynw_sync_in_tlm::operator () ( const cynw_sync<CYN::TLM>& sync )
	{ m_input(sync.m_sync_signal); }
inline void cynw_sync_out_tlm::operator () ( cynw_sync<CYN::TLM>& sync )
	{ m_sync_output(sync.m_sync_signal); }

} // namespace cynw

//------------------------------------------------------------------------------
// Utilities for getting and putting 1D and 2D arrays of data from and to
// word-level streaming interfaces.
//
// All I/O is constrained to occur adjacent to each other by constraining
// all I/O operations in the same HLS_DEFINE_PROTOCOL block.
//
// For 2D arrays, a third argument specifies whether the data is transmitted
// in row-major (true) or column-major (false) order.  The default is row-major.
//
// The cynw_put_block() functions accept a reference to an interface as the
// first parameter.  The interface must support a function with the following
// signature:
//
//    void iface.put( DT& )
//
// where DT is the type of the members of the input block array.
//
// Similarly, the interface specified in the first parameter to cynw_get_block
// must contain a function with the following signature:
//
//    DT iface.get()
//
// The functions are:
//
//    cynw_get_block( <iface>, <1D_array> )
//    cynw_get_block( <iface>, <2D_array>, <row_major>=true )
//    cynw_put_block( <iface>, <1D_array> )
//    cynw_put_block( <iface>, <2D_array>, <row_major>=true )
//
//------------------------------------------------------------------------------

template <typename CYN_IFACE, typename T, int CYN_X>
inline void cynw_get_block( CYN_IFACE& iface, T (&vec)[CYN_X] )
{
	HLS_DEFINE_PROTOCOL("cynw_get_block");
	for ( int x=0; x < CYN_X; x++ ) {
		HLS_UNROLL_LOOP(ALL);
		vec[x] = iface.get();
	}
}

template <typename CYN_IFACE, typename T, int CYN_Y, int CYN_X>
inline void cynw_get_block( CYN_IFACE& iface, T (&matrix)[CYN_Y][CYN_X], bool row_major=true )
{
	if (row_major) {
		HLS_DEFINE_PROTOCOL("cynw_get_block");
		for ( int y=0; y < CYN_Y; y++ ) {
			HLS_UNROLL_LOOP(ALL);
			for ( int x=0; x < CYN_X; x++ ) {
				matrix[y][x] = iface.get();
			}
		}
	} else {
		HLS_DEFINE_PROTOCOL("cynw_get_block");
		for ( int x=0; x < CYN_X; x++ ) {
			HLS_UNROLL_LOOP(ALL);
			for ( int y=0; y < CYN_Y; y++ ) {
				matrix[y][x] = iface.get();
			}
		}
	}
}

template <typename CYN_IFACE, typename T, int CYN_X>
inline void cynw_put_block( CYN_IFACE& iface, T (&vec)[CYN_X] )
{
	HLS_DEFINE_PROTOCOL("cynw_put_block");
	for ( int x=0; x < CYN_X; x++ ) {
		HLS_UNROLL_LOOP(ALL);
		iface.put( vec[x] );
	}
}

template <typename CYN_IFACE, typename T, int CYN_Y, int CYN_X>
inline void cynw_put_block( CYN_IFACE& iface, T (&matrix)[CYN_Y][CYN_X], bool row_major=true )
{
	HLS_DEFINE_PROTOCOL("cynw_put_block");
	if (row_major) {
		for ( int y=0; y < CYN_Y; y++ ) {
			HLS_UNROLL_LOOP(ALL);
			for ( int x=0; x < CYN_X; x++ ) {
				iface.put( matrix[y][x] );
			}
		}
	} else {
		for ( int x=0; x < CYN_X; x++ ) {
			HLS_UNROLL_LOOP(ALL);
			for ( int y=0; y < CYN_Y; y++ ) {
				iface.put( matrix[y][x] );
			}
		}
	}
}



//------------------------------------------------------------------------------
// Utilities for getting and putting rows and columns from 2D arrays.
//
//
//    cynw_get_row( <matrix>, <row_num>, <row> )
//
//	  Extracts the given row number from matrix into row.
//
//	  Example:  
//	  
//	     sc_uint<N> matrix[3][4];
//		 sc_uint<N> row[4];
//		 cynw_get_row( matrix, 2, row );
//
//		 This will fill the 'row' array with the following values:
//		 
//			matrix[2][0], matrix[2][1], matrix[2][2], matrix[2][3].
//	  
//
//    cynw_get_col( <matrix>, <col_num>, <col> )
//
//	  Extracts the given column number from matrix into col.
//
//	  Example:  
//	  
//	     sc_uint<N> matrix[3][4];
//		 sc_uint<N> col[3];
//		 cynw_get_row( matrix, 2, col );
//
//		 This will fill the 'col' array with the following values:
//		 
//			matrix[0][2], matrix[1][2], matrix[2][2]
//	  
//    cynw_put_row( <matrix>, <row_num>, <row> )
//
//	  Copies the values in row into the given row number of matrix.
//
//	  Example:  
//	  
//	     sc_uint<N> matrix[3][4];
//		 sc_uint<N> row[4];
//		 cynw_put_row( matrix, 2, row );
//
//		 This will fill the following indexes in matrix with the values from row.
//		 
//			matrix[2][0], matrix[2][1], matrix[2][2], matrix[2][3].
//	  
//
//    cynw_put_col( <matrix>, <col_num>, <col> )
//
//	  Copies the values in col into the given column number of matrix.
//
//	  Example:  
//	  
//	     sc_uint<N> matrix[3][4];
//		 sc_uint<N> col[3];
//		 cynw_put_row( matrix, 2, col );
//
//		 This will fill the following indexes in matrix with the values from col.
//		 
//			matrix[0][2], matrix[1][2], matrix[2][2]
//	  
//  
//------------------------------------------------------------------------------

template <typename T, int CYN_Y, int CYN_X>
inline void cynw_get_row( T	(&matrix)[CYN_Y][CYN_X], 
						  sc_uint<  cyn_log::log2<CYN_Y>::value > y,
						  T (&row)[CYN_X] )
{
	for ( int x=0; x < CYN_X; x++ ) {
		HLS_UNROLL_LOOP(ALL);
		row[x] = matrix[y][x];
	}
}

template <typename T, int CYN_Y, int CYN_X>
inline void cynw_get_col( T	(&matrix)[CYN_Y][CYN_X], 
						  sc_uint<  cyn_log::log2<CYN_X>::value > x,
						  T (&col)[CYN_Y] )
{
	for ( int y=0; y < CYN_Y; y++ ) {
		HLS_UNROLL_LOOP(ALL);
		col[y] = matrix[y][x];
	}
}

template <typename T, int CYN_Y, int CYN_X>
inline void cynw_put_row( T	(&matrix)[CYN_Y][CYN_X], 
						  sc_uint<  cyn_log::log2<CYN_Y>::value > y,
						  T (&row)[CYN_X] )
{
	for ( int x=0; x < CYN_X; x++ ) {
		HLS_UNROLL_LOOP(ALL);
		matrix[y][x] = row[x];
	}
}

template <typename T, int CYN_Y, int CYN_X>
inline void cynw_put_col( T	(&matrix)[CYN_Y][CYN_X], 
						  sc_uint<  cyn_log::log2<CYN_X>::value > x,
						  T (&col)[CYN_Y] )
{
	for ( int y=0; y < CYN_Y; y++ ) {
		HLS_UNROLL_LOOP(ALL);
		matrix[y][x] = col[y];
	}
}

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif

//------------------------------------------------------------------------------
// cynw_hier_bind_detector
//
// Used to mark metaports that are bound hierarchically to a child port.
// This indication can be used to avoid creating threads that can cause
// problems in hierarchically bound ports.
//
// Designed to be used as follows:
//
//  // Derive metaport class from cynw_hier_bind_detector.
//  class my_metaport
//    : public cynw_hier_bind_detector, ...
//
//  // In bind functions that may accept the metaport as an argument,
//  // call cynw_mark_hierarchical_binding(&p) to mark it if it is one.
//  template <class C>
//  void bind( C& c )
//  {
//    cynw_mark_hierarchical_binding( &c );
//    busy(c.busy);
//    ...
//
//  // In the metaport class, in a before_end_of_elaboration() function,
//  // detect whether a hierarhical binding was done to the metaport.
//  void before_end_of_elaboration()
//  {
//     if (!is_hierarchically_bound()) {
//        // Create threads and methods.
//     }
//  }
//  
//------------------------------------------------------------------------------
class cynw_hier_bind_detector
{
  public:
    cynw_hier_bind_detector() : m_is_hier(false)
    {}
    bool is_hierarchically_bound() { return m_is_hier; }
    void set_is_hierarchicall_bound( bool v ) { m_is_hier=v; }
  protected:
    bool m_is_hier;
};

static inline void cynw_mark_hierarchical_binding( void* p )
{
}

static inline void cynw_mark_hierarchical_binding( cynw_hier_bind_detector* p )
{
  p->set_is_hierarchicall_bound(true);
}

#ifndef CYNW_NO_WAIT_EVENT_CTHREAD
#define CYNW_NO_WAIT_EVENT_CTHREAD 1
#endif

//------------------------------------------------------------------------------
// void cynw_wait_while_cond( cond, event )
//
// Macro used to implement a blocking wait until the given condition becomes true in
// a TLM model in a way that is consistent with the execution environment of
// the model, and the global options selected by the user.
//
// Parameters:
//   
//   cond : An expression that evaluates to 'true' when waiting should be terminated.
//
//   event: An expression returning an event suitable for use with ::wait(event).
//
// If cynw_wait_while_cond() is called from an SC_THREAD, or if CYNW_NO_WAIT_EVENT_CTHREAD 
// is either unset, or set to 1, a wait loop of the following form will be used:
// 
//   while (cond) wait();
//
// Otherwise, a wait loop of the following form will be used:
//
//   while (cond) wait(event);
//
// The former (and default) form is preferred in TLM models for 2 reasons:
//
// 1. The SC_CTHREAD can be reset() when the reset_signal_is() condition occurs because
//    all waits will be waits on clocks.
//
// 2. In SystemC 2.2, waiting on arbitrary events in an SC_CTHREAD has been deprecated,
//    and will resut in a warning message being emitted.
//
// Example:
// 
//  To implement a blocking get() on a tlm_fifo input:
//
//    cynw_wait_while_cond( port->nb_can_get(), port->ok_to_get() );
//
//------------------------------------------------------------------------------
#if !defined(STRATUS) && defined(CYNW_NO_WAIT_EVENT_CTHREAD) && CYNW_NO_WAIT_EVENT_CTHREAD
#define cynw_wait_while_cond( cond, event ) \
  if ( cynw_is_cthread() ) { \
    while ( (cond) ) ::wait(); \
  } else { \
    while ( (cond) ) ::wait( (event) ); \
  }
#else
#define cynw_wait_while_cond( cond, event ) \
  while ( (cond) ) ::wait( (event) )
#endif
  
//------------------------------------------------------------------------------
// void cynw_poll_for_cond( cond, event )
//
// Macro used to implement a conditional wait for an event in a TLM model in a
// way that is consistent with the execution environment of the model, and the
// global options selected by the user.
//
// Parameters:
//   
//   cond : An expression that evaluates to 'true' when waiting should be terminated.
//
//   event: An expression returning an event suitable for use with ::wait(event).
//
// If cynw_poll_for_cond() is called from an SC_THREAD, or if CYNW_NO_WAIT_EVENT_CTHREAD 
// is either unset, or set to 0, a wait loop of the following form will be used:
// 
//   if (cond) wait(event);
//
// Otherwise, a wait loop of the following form will be used:
//
//   if (cond) wait();
//
//------------------------------------------------------------------------------
#if !defined(STRATUS) && defined(CYNW_NO_WAIT_EVENT_CTHREAD) && CYNW_NO_WAIT_EVENT_CTHREAD
#define cynw_poll_for_cond( cond, event ) \
  if ( cynw_is_cthread() ) { \
    if ( (cond) ) ::wait(); \
  } else { \
    if ( (cond) ) ::wait( (event) ); \
  }
#else
#define cynw_poll_for_cond( cond, event ) \
  if ( (cond) ) ::wait( (event) )
#endif
  
//------------------------------------------------------------------------------
// void cynw_wait_if_cond( cond, event )
//
// Macro used to conditionally wait if a particular condition is true.
// The call to ::wait() is only done if the current thread is an SC_CTHREAD.
//
// Parameters:
//   
//   cond : An expression that evaluates to 'true' when a wait should be done.
//
//------------------------------------------------------------------------------
#if !defined(STRATUS)
#define cynw_wait_if_cond( cond ) \
  if ( cynw_is_cthread() ) { \
    if ( (cond) ) { \
      ::wait(); \
    } \
  }
#else
#define cynw_wait_if_cond( cond )
#endif
  
//------------------------------------------------------------------------------
// void cynw_void
//
// A type that's suitable for use as a datatype with modular interfaces like
// cynw_p2p for cases where there is no data, but only triggering required.
// For example:
//
//
//  SC_MODULE(M) {
//    cynw_p2p< cynw_void >::in start;  // Signals that processing should start.
//    cynw_p2p< cynw_void >::out done;  // Used to signal that processing is done.
//    ...
//    SC_CTOR(M) {  
//      SC_CTHREAD(t);
//      ...
//    }
//	void t() {
//		{ HLS_DEFINE_PROTOCOL("reset");
//          start.reset();
//		  done.reset();
//        }
//        while (1) {
//           // Wait to start.
//           start.get();
// 
//           process();
//   
//           // Signal we're done.
//           done.put();
//        }
//    }

class cynw_void {};

inline bool operator == ( const cynw_void& left, const cynw_void& right )
{
    return true;
}

inline ostream& operator << ( ostream& os, const cynw_void& target )
{
    return os;
}

inline void sc_trace( sc_trace_file* tf, const cynw_void& target,
                      const std::string& comment )
{
}

#ifndef CYNW_SC_WRAP_TEMPLATE
#define CYNW_SC_WRAP_TEMPLATE 1

template <typename T>
struct cynw_sc_wrap
{
	typedef T spec;
	typedef T sc;
};

#endif


#if defined(__GNUC__) && BDW_USE_SCV
//------------------------------------------------------------------------------
// cynw_scv_token_tx_stream<T> - SCV transaction stream for token oriented interfaces.
//
// The template arguments are:
//    T  - The data type of the token carried on the stream.
//
// Stores an scv_tr_stream, and a generator for values carried on the stream.
//
// This stream supports two scenarios:
//  1. The writer of the stream knows the value at the start of the transaction.
//  2. The reader knows the value at the end of the transaction.
//
// The begin_put_tx()/end_put_tx() funcs serve #1, and begin_get_tx()/end_get_tx() serve #2.
// The 'put_get' constructor parameter is used to label the transaction generator.
// 
// Keeps a pet transaction rather than using one stored in the callers space.
// This is useful and practical because overlapping transactions are not supported.
//------------------------------------------------------------------------------
template< typename T >
struct cynw_scv_token_tx_stream
{
	typedef T							   data_type;
	typedef cynw_scv_logging<data_type>    data_log_type;

	cynw_scv_token_tx_stream( const char* name, bool pg_in, scv_tr_db* db )
	{
		if ( db != 0 ) {
			m_stream = new scv_tr_stream( name, "cynw_token", db );
			m_gen = new scv_tr_generator<>( pg_in ? "put" : "get", *m_stream );
		} else {
			m_stream = 0;
			m_gen = 0;
		}
	}

	~cynw_scv_token_tx_stream()
	{
		delete m_stream;
		delete m_gen;
	}

	// Returns 'true' if a valid database was used to construct the object.
	bool enabled()
	{
		return (m_stream != 0);
	}

	// Terminate any open transaction.
	void terminate_tx()
	{
		if (is_active()) {
			m_gen->end_transaction(m_tx);
		}
	}

	// Begin a transaction from the writer's side.
	void begin_put_tx( const data_type& data )
	{
		if (enabled()) {
			terminate_tx();
			m_tx = m_gen->begin_transaction();
			m_tx.record_attribute( "data", data_log_type::attrib_value(data) );
		}
	}

	// Begin a transaction from the reader's side.
	void begin_get_tx()
	{
		if (enabled()) {
			terminate_tx();
			m_tx = m_gen->begin_transaction();
		}
	}

	// Write the end of a put transaction.
	void end_put_tx()
	{
		if (enabled()) {
			m_gen->end_transaction( m_tx );
		}
	}

	// Write the end of a get transaction.
	void end_get_tx( const data_type& data )
	{
		if (enabled()) {
			// Log the data as an attribute and end the transaction.
			m_tx.record_attribute( "data", data_log_type::attrib_value(data) );
			m_gen->end_transaction( m_tx );
		}
	}

	// Generate a zero-length transaction.
	void gen_tx( const data_type& data )
	{
		if (enabled()) {
			terminate_tx();
			scv_tr_handle tx = m_gen->begin_transaction();
			tx.record_attribute( "data", data_log_type::attrib_value(data) );
			m_gen->end_transaction( tx );
		}
	}

	// Returns true if the current transaction is valid and active.
	bool is_active()
	{
		return ( enabled() && m_tx.is_valid() && m_tx.is_active() );
	}

	scv_tr_stream* m_stream;
	scv_tr_generator<>* m_gen;
	scv_tr_handle m_tx;
};
#else

//------------------------------------------------------------------------------
//
// Stub versions of SCV token logging classes for use when either SCV is not aviablable,
// or when processing with a Cynthesizer application.
//
//------------------------------------------------------------------------------
template< typename T >
struct cynw_scv_token_tx_stream
{
	typedef T							   data_type;

	cynw_scv_token_tx_stream( const char* name, bool pg_in, scv_tr_db* db ) {}
	~cynw_scv_token_tx_stream() {}
	bool enabled() { return false; }
	bool is_active() { return false; }
	void terminate_tx() {}
	void begin_put_tx( const data_type& data ) {}
	void begin_get_tx() {}
	void end_put_tx() {}
	void end_get_tx( const data_type& data ) {}
	void gen_tx( const data_type& data ) {}


};
#endif

#if defined(__GNUC__) && BDW_USE_SCV
//------------------------------------------------------------------------------
// cynw_scv_tx_stream - Wrapper for a transaction stream
//
// Supports transaction streams with the following attributes:
//  - Non-overlapping
//  - One or more named generators.
//  - May or may not be related to a parent stream.
//
// When constructed, a set of generator names is specified.  When generating
// transaction, a generator index is given which corresponds to the order of 
// generator names specified.  If there is a hierachical relationship to another
// cynw_scv_tx_stream, this is also specified in a constructor parameters.
//
// Attributes can be recorded at any time and with a arbitrary type, so long as
// the type conforms to the requirements of cynw_scv_logging<> as described in
// esc_scv.h.
//
// Scalar, 1D array, and 2D array attributes are supported.
//------------------------------------------------------------------------------
struct cynw_scv_tx_stream
{
	// Constructor for multiple generators with no parent.
	cynw_scv_tx_stream( const char* name, scv_tr_db* db, int ngen, const char* gen_name, ... ) 
	{
		va_list ap;
		va_start( ap, gen_name );
		init( name, db, 0, ngen, gen_name, ap );
		va_end( ap );
	}

	// Constructor for one generator with no parent.
	cynw_scv_tx_stream( const char* name, scv_tr_db* db, const char* gen_name )
	{
		init( name, db, 0, 1, gen_name );
	}

	// Constructor for multiple generators with a parent.
	cynw_scv_tx_stream( const char* name, scv_tr_db* db, cynw_scv_tx_stream* parent, int ngen, const char* gen_name, ... ) 
	{
		va_list ap;
		va_start( ap, gen_name );
		init( name, db, parent, ngen, gen_name, ap );
		va_end( ap );
	}

	// Constructor for one generator with a parent.
	cynw_scv_tx_stream( const char* name, scv_tr_db* db, cynw_scv_tx_stream* parent, const char* gen_name )
	{
		init( name, db, parent, 1, gen_name );
	}

	~cynw_scv_tx_stream() 
	{
		for ( std::vector< scv_tr_generator<>* >::iterator git = m_gens.begin(); git != m_gens.end(); git++ ) 
			delete (*git);
	}

	void init( const char* name, scv_tr_db* db,  cynw_scv_tx_stream* parent, int ngen, const char* gen_name, ... )
	{
		m_parent = parent;
		m_relation = 0;

		if ( db != 0 ) {
			m_stream = new scv_tr_stream( name, "cynw_token", db );
			if (m_parent)
				m_relation = db->create_relation("child");

			// Allocate generators.
			va_list ap;
			va_start( ap, gen_name );
			m_gens.push_back( new scv_tr_generator<>( gen_name, *m_stream ) );
			for (int igen=1; igen < ngen; igen++) {
				gen_name = va_arg(ap,const char*);
				m_gens.push_back( new scv_tr_generator<>( gen_name, *m_stream ) );
			}
			va_end( ap );
		} else {
			m_stream = 0;
		}


	}
	
	// Returns 'true' if a valid database was used to construct the object.
	bool enabled()
	{
		return (m_stream != 0);
	}

	// Terminate any open transaction.
	void terminate_tx()
	{
		if (is_active()) {
			m_tx.end_transaction();
		}
	}

	// Returns true if the current transaction is valid and active.
	bool is_active()
	{
		
		return ( enabled() && m_tx.is_valid() && m_tx.is_active() );
	}

	void begin_tx( int igen=0 )
	{
		if (enabled()) {
			terminate_tx();
			if (m_parent && m_parent->is_active())
				m_tx = m_gens[igen]->begin_transaction( m_relation, m_parent->m_tx );
			else
				m_tx = m_gens[igen]->begin_transaction();
		}
	}
	void end_tx() 
	{
		terminate_tx();
	}
	template <typename T> void record_attrib( const char* name, const T& a )
	{
		if (is_active()) {
			cynw_scv_logging<T>::record_attrib( m_tx, name, a );
		}
	}
	template <typename T, int CYN_N> void record_attrib( const char* name, T (&a)[CYN_N] )
	{
		if (is_active()) {
			cynw_scv_logging<T>::record_attrib( m_tx, name, a );
		}
	}

	template <typename T, int CYN_NC, int CYN_NR> void record_attrib( const char* name, T (&a)[CYN_NR][CYN_NC] )
	{
		if (is_active()) {
			cynw_scv_logging<T>::record_attrib( m_tx, name, a );
		}
	}

	scv_tr_stream* m_stream;
	std::vector< scv_tr_generator<>* > m_gens;
	scv_tr_handle m_tx;
	cynw_scv_tx_stream* m_parent;
	scv_tr_relation_handle_t m_relation;
};
#else

//------------------------------------------------------------------------------
//
// Stub versions of SCV token logging classes for use when either SCV is not aviablable,
// or when processing with a Cynthesizer application.
//
//------------------------------------------------------------------------------
struct cynw_scv_tx_stream
{
	cynw_scv_tx_stream( const char* name, scv_tr_db* db, int ngen, const char* gen_name, ... )  {}
	cynw_scv_tx_stream( const char* name, scv_tr_db* db, const char* gen_name ) {}
	cynw_scv_tx_stream( const char* name, scv_tr_db* db, cynw_scv_tx_stream* parent, int ngen, const char* gen_name, ... )  {}
	cynw_scv_tx_stream( const char* name, scv_tr_db* db, cynw_scv_tx_stream* parent, const char* gen_name )  {}
	~cynw_scv_tx_stream()  {}
	bool enabled() {return false;}
	void terminate_tx() {}
	bool is_active() {return false;}
	void begin_tx( int igen=0 ) {}
	void end_tx()  {}
	template <typename T> void record_attrib( const char* name, const T& a ) {}
	template <typename T, int CYN_N> void record_attrib( const char* name, const T a[CYN_N] ) {}
	template <typename T, int CYN_NC, int CYN_NR> void record_attrib( const char* name, const T a[CYN_NR][CYN_NC] ) {}
};
#endif
#endif
