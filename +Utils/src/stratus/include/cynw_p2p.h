/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/

#ifndef CYNW_P2P_H
#define CYNW_P2P_H
#include <systemc.h>
#include <cynthhl.h>
#include <esc.h>


#include "cynw_comm_util.h"

#if defined STRATUS  &&  ! defined CYN_DONT_SUPPRESS_MSGS
#pragma cyn_suppress_msgs NOTE
#endif	// STRATUS  &&  CYN_DONT_SUPPRESS_MSGS

#if defined STRATUS 
#pragma hls_ip_def
#endif	

//
// If CYN_NO_OSCI_TLM is defined, use sc_fifo.  
// Otherwise, use tlm_fifo.
//

#ifndef CYN_USE_TLM_FIFO_DEFINED
#define CYN_USE_TLM_FIFO_DEFINED 1

#ifdef CYN_NO_OSCI_TLM

#define CYN_USE_FIFO_CHAN     sc_fifo
#define CYN_USE_FIFO_IN(T)    sc_fifo_in<T>
#define CYN_USE_FIFO_IN_IF    sc_fifo_in_if
#define CYN_USE_FIFO_OUT(T)   sc_fifo_out<T>
#define CYN_USE_FIFO_OUT_IF   sc_fifo_out_if
#define CYN_USE_FIFO_GET      read
#define CYN_USE_FIFO_PUT      write
#define CYN_USE_FIFO_NB_GET   nb_read
#define CYN_USE_FIFO_NB_PUT   nb_write
#define CYN_USE_FIFO_CAN_GET  num_available
#define CYN_USE_FIFO_CAN_PUT  num_free
#define CYN_USE_FIFO_OK_TO_GET  data_written_event
#define CYN_USE_FIFO_OK_TO_PUT  data_read_event

#else

#include <tlm.h>

#define CYN_USE_FIFO_CHAN     tlm::tlm_fifo
#define CYN_USE_FIFO_IN(T)    sc_port< tlm::tlm_fifo_get_if<T> >
#define CYN_USE_FIFO_IN_IF    tlm::tlm_fifo_get_if
#define CYN_USE_FIFO_OUT(T)   sc_port< tlm::tlm_fifo_put_if<T> >
#define CYN_USE_FIFO_OUT_IF   tlm::tlm_fifo_put_if
#define CYN_USE_FIFO_GET      get
#define CYN_USE_FIFO_PUT      put
#define CYN_USE_FIFO_NB_GET   nb_get
#define CYN_USE_FIFO_NB_PUT   nb_put
#define CYN_USE_FIFO_CAN_GET  nb_can_get
#define CYN_USE_FIFO_CAN_PUT  nb_can_put
#define CYN_USE_FIFO_OK_TO_GET  ok_to_get
#define CYN_USE_FIFO_OK_TO_PUT  ok_to_put

#endif

#endif

#ifndef CYNW_P2P_DEFAULT_TLM_FIFO_DEPTH
#define CYNW_P2P_DEFAULT_TLM_FIFO_DEPTH 16
#endif

#if CYNW_P2P_NO_STALL_UNPIPELINED
#define CYNW_P2P_STALL_LOOPS(str)
#else
#define CYNW_P2P_STALL_LOOPS(str) HLS_DEFINE_STALL_LOOP(HLS::ALL,str)
#endif
//
// cynw_wait_can_get() and cynw_poll() were deprecated in the 3.3.4 release.
// These functions have been renamed cynw_wait_all_can_get() and cynw_poll_all().
// The following macros provide backwards compatibility with the old names.
//
#define cynw_wait_can_get cynw_wait_all_can_get
#define cynw_poll cynw_poll_all

// Flags to mark warnings that have been emitted.
#define CYN_P2P_OVERLAP_WARNING        0x0001
#define CYN_P2P_NO_BINDING_WARNING     0x0002
#define CYN_P2P_NO_RESET_IN_WARNING    0x0004
#define CYN_P2P_NO_RESET_OUT_WARNING   0x0008
#define CYN_P2P_NO_WAIT_AFTER_RESET_WARNING   0x0010
#define CYN_P2P_RESET_POLARITY_WARNING 0x0020
#define CYN_P2P_MULTIPLE_NB_GET_WARNING 0x0040

// Convenience macros to check and set a warning flag.
#if CYNW_DO_CHECKING
#define CYNW_P2P_WAS_WARNING_DONE(flag) \
  ((m_warnings & flag) != 0)
#define CYNW_P2P_SET_WARNING_DONE(flag) \
  m_warnings |= flag
#else
#define CYNW_P2P_WAS_WARNING_DONE(flag)
#define CYNW_P2P_SET_WARNING_DONE(flag)
#endif

namespace cynw
{

////////////////////////////////////////////////////////////
//
// p2p classes
//
////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
//
// Forward declarations
//
////////////////////////////////////////////////////////////

template <class T, typename CYN_L=CYN::PIN> class cynw_p2p_in;
template <class T, typename CYN_L=CYN::PIN> class cynw_p2p_out;

////////////////////////////////////////////////////////////
//
// class: cynw_p2p_in_if<T>
//
// kind:
//
//   sc_interface
//
// summary: 
//
// template parameters:
//
//   T : The data type carried on the interface.
//
// details:
//
//   Functions:
//
//     T get( bool wait_until_valid=true )
//
//       Returns a value read from the input.  If the wait_until_valid
//       parameter is true, blocks until a valid value is available.  If it is
//       false, will wait a predictable amount of time as defined by the
//       implementer, and may return invalid data.
//
//     T poll( bool placeholder=false )
//
//	 Same as get(false).
//	 If placeholder if true, does not actually request a value.  However,
//	 it still waits for a cycle.
//
//     bool data_was_valid()
//
//       Returns true if the last value read was valid, false if it was
//       not.  This function can be used in conjunction with get(false)
//       to determine whether or not the value returned from get() is valid.
//
//    void reset()
//
//       Resets signals written by other functions in the interface in 
//       signal-level implementations.
//
//    bool nb_get(T& val)
//	
//	 Get the value currently available on the input.  Never waits.
//
//    bool nb_can_get()
//
//       Get the value currently available on the input, or if latch_value()
//       has been called, the value present at the time it was called. Never
//       waits. 
//
//    sc_event& ok_to_get() 
//
//       Returns true only if a valid value is currently available for return
//       from nb_get().
//
//    void get_start( bool busy_val=false )
//
//	 Starts the get() process.  Useful mainly when multiple interfaces must
//	 be operated in parallel, and the protocol must be broken into pieces.
//	 If the optional parameter busy_val is set to 'true', then busy is
//	 asserted rather than deasserted, which will prevent a real request
//	 from being made.
//
//    void get_end()
//
//	 Ends the get() process by asserting busy.  Useful mainly when multiple
//	 interfaces must be operated in parallel, and the protocol must be
//	 broken into pieces.
//
//    void latch_value( bool do_latch=true )
//
//	 Stores the value currently available on the inputs for return from
//	 nb_get().  This low-level function is useful when writing utility
//	 functions that wait for a value to be available on one or more inputs.
//	 It guarantees that the value present on the inputs at the time
//	 latch_value() is called will be returned from a subsequent call to
//	 nb_get(), regardless of whether clock cycles occur between the two
//	 calls.  The do_latch parameter indicates that a value should actually
//	 be stored.  This makes it possible to avoid embedding the call to 
//	 latch_value() in a conditional, and to instead pass the condition as
//	 a parameter.
//
// example:
//
//   // Channels implementing the interface:
//   class cynw_my_p2p_in : public cynw_p2p_in_if
//   { ...
//
//   // Ports onto the interface:
//   sc_port< cyn_p2p_in_if> p;
//   
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p_in_if : 
  public virtual sc_interface
{
  public:
    virtual T get( bool wait_until_valid=true )=0;
    virtual T poll( bool placeholder=false )=0;
    virtual bool data_was_valid()=0;
    virtual void reset()=0;
    virtual bool nb_get(T& val)=0;
    virtual bool nb_can_get()=0;
    virtual const sc_event& ok_to_get() const=0;
    virtual void get_start( bool busy_val=false )=0;
    virtual void get_end()=0;
    virtual void latch_value( bool do_latch=true )=0;
    virtual void set_state( unsigned which, unsigned value )=0;
};

////////////////////////////////////////////////////////////
//
// class: cynw_p2p_out_if
//
// kind: 
//
//   sc_interface
//
// summary: 
//
// template parameters:
//
//   T : The data type carried on the interface.
//
// details:
//
//   Functions:
//
//    void put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )
//
//      Writes the given value over the interface.
//      The data_is_valid parameter's meaning is implementation-defined,
//      but the following semantics are standard for the interface:
//
//       default (CYNW_AUTO_VLD): 
//           Determine whether the data is valid automatically.
//           This is enabled by binding the output metaport to 
//           an input metaport using its stall_port() function.
//
//       0 : Data is not valid, but an output protocol should be executed
//           anyway.
//
//       other non-zero: Data is valid.
//
//    void reset()
//
//       Resets signals written by other functions in the interface in 
//       signal-level implementations.
//
//    void nb_put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )
//	 
//	 Puts a value to the output with the given valid status.  Never waits.
//	 This function is appropriate to call only when nb_can_put() has
//	 already determined that it is safe.
//
//    bool nb_can_put()
//	
//	 Returns true only if it is safe to do an nb_can_put().
//
//    sc_event& ok_to_put()
//	
//       Returns an event that will be triggered when nb_can_put() status changes.
//
// example:
//
//   // Channels implementing the interface:
//   class cynw_my_p2p_out : public cynw_p2p_out_if
//   { ...
//
//   // Ports onto the interface:
//   sc_port< cyn_p2p_out_if> p;
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p_out_if : 
  public virtual sc_interface
{
  public:
    virtual void put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )=0;
    virtual void reset()=0;
    virtual void nb_put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )=0;
    virtual bool nb_can_put()=0;
    virtual const sc_event& ok_to_put() const=0;
    virtual void set_state( unsigned which, unsigned value )=0;
};

////////////////////////////////////////////////////////////
//
// class: cynw_p2p_base_in<T,PIN>
//
// kind: 
//
//   metaport
//
// summary: 
//
//   Input metaport for the cynw_p2p protocol at the PIN level.
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//   cynw_p2p_base_in is an input metaport for the cynw_p2p protocol.  This
//   simple version is suitable for use in testbenches, hierarchical modules,
//   and synthesizable module.  It is synthesizable, but does not support 
//   binding to an output metaport for stall propagation.
//   
//   The functions in the cynw_p2p_in_if<T> interface are implemented as follows:
//
//    T get( bool wait_until_valid=true )
//
//      If wait_until_valid is true,
//
//        Returns the value of the data input after a clock edge when vld
//        is true.  Deasserts busy before waiting, and re-asserts it after
//        a valid value has been read.
//
//        If called from a pipelined loop, a hard stall will be inferred.
//
//      If wait_until_valid is false,
//
//        Deasserts busy, waits for 1 cycle, re-asserts busy, and returns
//        the value of the data input.  The caller can discover whether the
//        vld input was asserted when the data was read by calling data_was_valid().
//      
//    T poll( bool placeholder=false )
//	
//	Same as get(false).
//	If placeholder if true, does not actually request a value.  However,
//	it still waits for a cycle.
//
//    bool data_was_valid()
//
//        Returns true if vld was asserted when the last value was read by get(),
//        and false if it wasn't.
//
//    void reset()
//
//        Asserts busy.  Should be called from the top of the accessing CTHREAD.
//
// example:
//
//   Instantiating a metaport:
//
//     SC_MODULE(M) 
//     {
//       // Use the type name directly.
//       cynw_p2_base_in<T,PIN> din1;
//
//       // Get this type indirectly via typedefs in cynw_p2p<T>.
//       cynw_p2p<T,PIN>::base_in din2;
//
//       // Get this type indirectly as the default input port for the channel.
//       // Also uses the default L parameter of PIN.
//       cynw_p2p<T>::in din3;
//
//
//   Using the metaport to make a hierarchical connection.
//
//     typedef sc_uint<8> DT;
//
//     SC_MODULE(P) 
//     {
//       // Instantiate a submodule that has a cynw_p2p<T>::base_in 
//       submod sub1;
//
//       // Instantiate a metaport for a hierarchical connection.
//       cynw_p2p<DT>::base_in sub1_din;
//
//       SC_CTOR(P) 
//       {
//         // Bind sub1's input to the hierarchical port.
//         sub1.din( sub1_din );
//       }
//
//   Reading from an input metaport in a testbench
//
//     SC_MODULE(tb) 
//     {
//       cynw_p2p<DT>::in din;
//
//       SC_CTOR(tb) 
//       {
//         SC_CTHREAD( sink, clk.pos() );
//         ...
//       }
//       void sink() 
//       {
//         while (1) 
//         {
//           // Read values as they become available.
//           DT val = din.get();
//           compare_result(val);
//           ...
//         }
//       }
//   
////////////////////////////////////////////////////////////
template <class T, typename CYN_L>
class cynw_p2p_base_in
   : public cynw_clk_rst_facade
{
  public:
    HLS_METAPORT;

    typedef cynw_p2p_base_in<T,CYN_L>   this_type;
    typedef T                         data_type;
    typedef this_type                 metaport;
    typedef CYN_L		      p2p_level;

    cynw_p2p_base_in( 
	const char* name=sc_gen_unique_name("p2p_in"),
	unsigned options=0,
	double input_delay=HLS_CALC_TIMING ) 
      : busy( HLS_CAT_NAMES(name,"busy") ),
        vld( HLS_CAT_NAMES(name,"vld") ),
        data( HLS_CAT_NAMES(name,"data") ),
	m_data_was_valid_d(false), 
        m_options_base(options),
	m_use_beh_latched(false),
	m_value_was_read(false),
	m_input_delay(input_delay),
	m_warnings(0),
        m_name(sc_string(::sc_core::sc_get_curr_simcontext()->hierarchy_curr()->name()) + sc_string(".") + sc_string(name)),
        m_stream_name(sc_string("sc_main.") + m_name),
	m_tx_stream(0)
    {
      
      // Specify an for vld and data if a positive value is given.
      if (input_delay == 0.0)
	m_input_delay = HLS_CALC_TIMING;
      HLS_SET_INPUT_DELAY( vld, m_input_delay, "" );
      HLS_SET_INPUT_DELAY( data, m_input_delay, "" );
      HLS_SUPPRESS_MSG_SYM( 847, data );
      HLS_SUPPRESS_MSG_SYM( 847, vld );
    }

    //
    // Interface ports
    //
    sc_out<bool> busy;
    sc_in<bool> vld;
    sc_in< typename cynw_sc_wrap<T>::sc > data;
    
    //
    // Binding functions
    //
    template <class CYN_C>
    void bind( CYN_C& c )
    {
      cynw_mark_hierarchical_binding( &c );
      busy(c.busy);
      vld(c.vld);
      data(c.data);
    }

    template <class CYN_C>
    void operator()( CYN_C& c )
    {
      bind(c);
    }

    //
    // cynw_p2p_in_if
    //
    T get( bool wait_until_valid=true )
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_get");

      warning_check( CYN_P2P_NO_RESET_IN_WARNING );

      get_start();
      if (wait_until_valid) 
      {
        m_data_was_valid_d = true;
	do { 
	  CYNW_P2P_STALL_LOOPS("put");
	  wait();
	} while (!vld.read());
      } else {
        wait();
        m_data_was_valid_d = nb_can_get();
      }
      get_end();

      T val;
      nb_get(val);

      return val;
    }

    T poll( bool placeholder=false )
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_poll");
      HLS_REMOVE_CONTROL(ON,"");

      get_start(placeholder);
      wait();

      latch_value(!placeholder);

      T rslt;
      m_use_beh_latched = true;
      nb_get(rslt);

      return rslt;
    }

    bool data_was_valid()
    {
      return m_data_was_valid_d.value();
    }

    void reset()
    {
      CYNW_P2P_SET_WARNING_DONE(CYN_P2P_NO_RESET_IN_WARNING);

      HLS_DEFINE_PROTOCOL("cynw_p2p_in_reset");
      busy = 1;

      m_data_was_valid_d = false;
      m_value_was_read = false;
    }

    bool nb_get( T& val )
    {
      bool good_value;

      if (m_use_beh_latched) {
	val = m_beh_latched_value;
	good_value = m_data_was_valid_d;
      } else {
	val = data.read();
	good_value = vld.read();
      }

      m_value_was_read = good_value;

      // If a value was obtained, log the value with the end of the transaction.
      // If not, terminate the transaction with no data.
      if (good_value)
	tx_stream()->end_get_tx( val );
      else
	tx_stream()->terminate_tx();

      return good_value;
    }

    bool nb_can_get()
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_nb_can_get");
      return ((vld.read() || m_use_beh_latched) && !m_value_was_read);
    }

    const sc_event& ok_to_get() const
    {
      return vld.value_changed_event();
    }


    void get_start( bool busy_val=false )
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_get_start");
      busy = busy_val;
      if (!busy_val)
      {
	tx_stream()->begin_get_tx();
	m_use_beh_latched = false;
	m_data_was_valid_d = false;
	m_value_was_read = false;
      }
    }

    void get_end()
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_get_end");
      busy = 1;
    }

    // Convenience operators for assigning from.
    operator T() { return this_type::get(); }

    // Sets a value to be returned from nb_get().
    void latch_value( bool do_latch=true )
    {
      HLS_DEFINE_PROTOCOL("latch_value");

      if (do_latch) {
	HLS_REMOVE_CONTROL(ON);
	nb_get( m_beh_latched_value );
      }
      m_data_was_valid_d = (m_data_was_valid_d | (do_latch && nb_can_get()));
      m_use_beh_latched = true;
      m_value_was_read = false;
    }

    void set_state( unsigned which, unsigned value )
    {
      switch (which) {
	case CYNW_SET_DATA_WAS_VALID  :
	  m_data_was_valid_d = value;
	  break;
	case CYNW_SET_VALUE_WAS_READ  :
	  m_value_was_read = value;
	  break;
	default:
	  break;
      }
    }

    void set_option( unsigned o )
    {
      m_options_base |= o;
    }
    void clear_option( unsigned o )
    {
      m_options_base &= ~o;
    }

    cynw_scv_token_tx_stream<T>* tx_stream()
    {
#if !STRATUS
      if (m_tx_stream == 0) {
        esc_enable_scv_logging();
        m_tx_stream = new cynw_scv_token_tx_stream<T>( m_stream_name.c_str(), false, esc_get_scv_tr_db() );
      }
      return m_tx_stream;
#else
      return 0;
#endif
    }

  public:
    cynw_setting<bool> m_data_was_valid_d;
    unsigned m_options_base;
    T m_beh_latched_value;
    bool m_use_beh_latched;
    bool m_value_was_read;
    double m_input_delay;
    unsigned m_warnings;
    sc_string m_name;
    sc_string m_stream_name;
    cynw_scv_token_tx_stream<T>* m_tx_stream;

    void warning_check( unsigned code )
    {
#if CYNW_DO_CHECKING
      if ( CYNW_P2P_WAS_WARNING_DONE(code) )
	return;

      //
      // CYN_P2P_NO_RESET_IN_WARNING
      //
      // Generate a warning if the port is read or written without having been first
      // reset.
      //
      if (code & CYN_P2P_NO_RESET_IN_WARNING)
      {
	esc_report_error( esc_warning, "\n\t%s: cynw_p2p_in: "
	                               "Port is read, but reset() has not been called",
				       m_name.c_str() );
      }

      CYNW_P2P_SET_WARNING_DONE(CYN_P2P_NO_RESET_IN_WARNING);
#endif
    }
};

////////////////////////////////////////////////////////////
//
// class: cynw_p2p_base_in<T,TLM>
//
// kind:
//   
//   metaport 
//
// summary: 
//
//   TLM implementation of cynw_p2p_base_in. 
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: this class is selected
//       when L=TLM.
//
// details:
//
//   This version of cynw_p2p is either an sc_fifo_in<T>, or a tlm_fifo_in<T>.
//   tlm_fifo_in<T> will be used unless CYN_NO_OSCI_TLM is defined.
//   It implements the cynw_p2p_in_if<T> as follows:
//
//    T get( bool wait_until_valid=true )
//
//      Reads from the fifo.  Behaves the same
//      way regardless of the value of wait_until_valid.
//      
//    bool data_was_valid()
//
//      Always returns true.
//
//    void reset()
//
//      Does nothing.
//
// example:
//
//   Instantiating a metaport:
//
//     SC_MODULE(M) 
//     {
//       // Use the type name directly.
//       cynw_p2_base_in<T,TLM> din1;
//
//       // Get this type indirectly via typedefs in cynw_p2p<T>
//       cynw_p2p<T,TLM>::base_in din2;
//
//
//   This class is plug-replacible with cynw_p2p_base_in<T,PIN>, and can be
//   used in all the same contexts, so the examples shown for
//   cynw_p2p_base_in<PIN> are all applicable.
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p_base_in<T,CYN::TLM>
  : public cynw_clk_rst_facade,
    public CYN_USE_FIFO_IN(T)
{
  public:
    HLS_METAPORT;

    typedef cynw_p2p_base_in<T,CYN::TLM>  this_type;
    typedef T                               data_type;
    typedef CYN_USE_FIFO_IN(T)              base_type;
    typedef this_type                       metaport;
    typedef CYN::TLM			  p2p_level;

    cynw_p2p_base_in( 
	const char* name=sc_gen_unique_name("p2p_in"),
	unsigned options=0,
	double input_delay=HLS_CALC_TIMING ) 
      : base_type(name),
        m_options_base(options),
	m_data_was_valid(false),
	m_use_beh_latched(false),
	m_last_poll_time(-1.0),
        m_stream_name(sc_string("sc_main.") + sc_string(this->name())),
	m_tx_stream(0),
	m_warnings(0)
    {}
    
    //
    // cynw_p2p_in_if
    //
    T get( bool wait_until_valid=true )
    {
      warning_check( CYN_P2P_NO_RESET_IN_WARNING );

      get_start();
      m_data_was_valid = true;
      cynw_wait_while_cond( !nb_can_get(), ok_to_get() );
      T val;
      nb_get( val );
      return val;
    }

    T poll( bool placeholder=false )
    {
      if (!placeholder) 
      {
	get_start();

	// We will wait if we've already called poll() at the same time.
	// This allows us to have poll() return without blocking without causing 
	// an infinite loop.
	cynw_wait_if_cond( last_poll_was_now() );
	set_last_poll();
      }
      T rslt;
      if (nb_can_get())
	nb_get(rslt);

      return rslt;
    }

    bool data_was_valid()
    {
      return m_data_was_valid;
    }

    void reset()
    {
      CYNW_P2P_SET_WARNING_DONE(CYN_P2P_NO_RESET_IN_WARNING);

      // Make sure the fifo is empty.  If we're reset after the sim has been running
      // for a while, we need to get it back to its original state by emptying it.
      m_use_beh_latched = false;
      while ( nb_can_get() ) {
	T val;
	nb_get(val);
      }
      clear_last_poll();
    }
    
    bool nb_get( T& val )
    {
      bool good;

      clear_last_poll();
      if ( m_use_beh_latched ) 
      {
	// Avoid repeating the get if we have a value latched.
	val = m_beh_latched_value;
	good = m_data_was_valid;
      } else {
	m_data_was_valid = (*this)->CYN_USE_FIFO_CAN_GET();
	good = (*this)->CYN_USE_FIFO_NB_GET(val);
      }
      if (tx_stream()->is_active()) {
	if (good)
	  tx_stream()->end_get_tx(val);
	else
	  tx_stream()->terminate_tx();
      } else if (good) {
	tx_stream()->gen_tx(val);
      }

      return good;
    }

    bool nb_can_get()
    {
      if ( m_use_beh_latched ) 
      {
	return m_data_was_valid;
      } else {
	return (*this)->CYN_USE_FIFO_CAN_GET();
      }
    }

    const sc_event& ok_to_get() const
    {
      return (*this)->CYN_USE_FIFO_OK_TO_GET();
    }

    void get_start( bool busy_val=false )
    {
      if (!busy_val)
      {
	// If a new value is being requested, clear data set in latch_value()
	m_data_was_valid = false;
	m_use_beh_latched = false;
	tx_stream()->begin_get_tx();
      }
    }

    void get_end()
    {
    }

    void latch_value( bool do_latch=true )
    {
      m_data_was_valid = nb_can_get();
      if ( m_data_was_valid && do_latch && !m_use_beh_latched )
      {
	m_use_beh_latched = true;
	(*this)->CYN_USE_FIFO_NB_GET(m_beh_latched_value);
      }
    }

    void set_state( unsigned which, unsigned value )
    {
      switch (which) {
	case CYNW_SET_USE_STALL_REG   :
	  break;
	case CYNW_SET_DATA_WAS_VALID  :
	  m_data_was_valid = value;
	  break;
	default:
	  break;
      }
    }

    void set_use_stall_reg( bool usr ) 
    {
    }
    
    // Convenience operators for assigning from.
    operator T() { return this_type::get(); }

    void set_option( unsigned o )
    {
      m_options_base |= o;
    }
    void clear_option( unsigned o )
    {
      m_options_base &= ~o;
    }

    // Accessors used in implementing checks for repeat polling of inputs
    // with no time elapsing.
    double last_poll_time()
    {
      return m_last_poll_time;
    }
    void set_last_poll()
    {
      m_last_poll_time = sc_time_stamp().to_double();
    }
    void clear_last_poll()
    {
      m_last_poll_time = -1.0;
    }
    bool last_poll_was_now()
    {
      return (last_poll_time() == sc_time_stamp().to_double());
    }
  protected:
    unsigned m_options_base;
    bool m_data_was_valid;
    bool m_use_beh_latched;
    T m_beh_latched_value;
    double m_last_poll_time;

    cynw_scv_token_tx_stream<T>* tx_stream()
    {
#if !STRATUS
      if (m_tx_stream == 0) {
        esc_enable_scv_logging();
        m_tx_stream = new cynw_scv_token_tx_stream<T>( m_stream_name.c_str(), false, esc_get_scv_tr_db() );
      }
      return m_tx_stream;
#else
      return 0;
#endif
    }

    void warning_check( unsigned code )
    {
#if CYNW_DO_CHECKING
      if ( CYNW_P2P_WAS_WARNING_DONE(code) )
	return;

      //
      // CYN_P2P_NO_RESET_IN_WARNING
      //
      // Generate a warning if the port is read or written without having been first
      // reset.
      //
      if (code & CYN_P2P_NO_RESET_IN_WARNING)
      {
	esc_report_error( esc_warning, "\n\t%s: cynw_p2p_in: "
	                               "Port is read, but reset() has not been called",
				       base_type::name() );
      }

      CYNW_P2P_SET_WARNING_DONE(CYN_P2P_NO_RESET_IN_WARNING);
#endif
    }
    sc_string m_stream_name;
    cynw_scv_token_tx_stream<T>* m_tx_stream;
    unsigned m_warnings;
};

////////////////////////////////////////////////////////////
//
// class:  cynw_p2p_in<T,PIN>
//
// kind: 
//
//   metaport
//
// summary: 
//
//   Input metaport for the cynw_p2p protocol at the PIN level
//   with full stall support.
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//   This input metaport should ordinarily be used in preference to 
//   the cynw_p2p_base_in metaport in pipelined synthesizable modules.  It
//   can also be used in testbenches, hierarchical modules, and non-pipelined
//   synthesizable modules, but it is slightly more complex to connect.
//
//   This class supports stall propagation between itself and one or more
//   output metaports.  When bound to output metaports using the stall_prop()
//   function, the following features become available:
//
//   - The stall signal from a downstream module is passed through from
//     a sibling output metaport and used to generate the upstream busy
//     signal.
//
//   - The valid status of the last input read is made available to a 
//     sibling output metaport for simple implementation of soft stall
//     semantics.
//
//   Connection of cynw_p2p_in to an output metaport is optional.  If no such
//   binding is made, then upstream modules will be stalled whenever the design
//   is not reading the interface, including when the design is stalling.
//
//   The cynw_p2p_in_if<T> is implemented as follows:
//
//    T get( bool wait_until_valid=true )
//
//      If wait_until_valid is true,
//
//        Returns the value of the data input after a clock edge when vld
//        is true.  busy is deasserted during this time.  A hard stall 
//        will be inferred from this call.
//
//      If wait_until_valid is false,
//
//        Waits for 1 cycle, asserts busy, and returns the value of the data
//        input.  busy is deasserted for this cycle, unless it is forced high
//        by a stall propagated from a downstream module via a stall_prop() 
//        connection.
//
//        The caller can discover whether the vld input was asserted when the
//        data was read by calling data_was_valid().
//
//        This form can be used to implement soft stall semantics.
//
//    T poll( bool placeholder=false )
//
//	Same as get(false).
//	If placeholder if true, does not actually request a value.  However,
//	it still waits for a cycle.
//      
//    bool data_was_valid()
//
//        Returns true if vld was asserted when the last value was read by get(),
//        and false if it wasn't.  Any output metaport bound via stall_prop()
//        can also access this value, and will do so by default to validate output
//        values.
//
//    void reset()
//
//        Asserts busy.  Should be called from the top of the accessing CTHREAD.
//
//   Hierarchical modules that need to pass through a cynw_p2p_in to
//   a parent parent module should use a a cynw_p2p_base_in, which is
//   accessible via typedefs in the cynw_p2p class member.  For example,
//   cynw_p2p<T>::base_in.
//
//   This implementation of cynw_p2p_in does not require a clk or rst
//   from a parent module.  However, it is derived from cynw_clk_rst_facade, so
//   it can be bound using the clk_rst() member functions.  Even though such a
//   binding is not required for correct operation, it is recommended that it
//   be done to support future versions of the class that do require clk and
//   rst bindings.
//
// example:
//
//   Instantiating:
//
//     typedef sc_uint<8> DT;
//
//     SC_MODULE(M) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> rst;
//
//       
//       cynw_p2p<DT,PIN>::in din;
//       cynw_p2p<DT,PIN>::out dout;
//
//       SC_CTOR(M) 
//       {
//         // Bind the input and the output for stall propagation.
//         din.stall_prop(dout);
//
//         // Bind clk and rst to the cynw_p2p_in.
//         din.clk_rst( clk, rst );
//       }
//     }
//
//   Instantiating without a stall propagation binding.
//
//     SC_MODULE(M) 
//     {
//       cynw_p2p<DT,PIN>::in din;
//       cynw_p2p<DT,PIN>::out dout;
//
//       SC_CTOR(M) 
//       {
//         // Bind clk and rst to the cynw_p2p_in.
//         // As noted above, this binding is not a requirement for this
//         // class but is supported and provides compatibility with future
//         // versions of the class that may require clk and rst.
//         din.clk_rst( clk, rst );
//       }
//     }
//
//   Binding to a parent module's metaport:
//
//     // Submodule definition.
//     SC_MODULE(M) 
//     {
//       cynw_p2p<DT>::in din;
//       ...
//     };
//
//     // Parent module definition.
//     SC_MODULE(P) 
//     {
//       // Hiearchical port declaration.
//       cynw_p2p<DT>::base_in din;
//
//       // Submodule declaration.
//       M m;
//
//       SC_CTOR(P) 
//       {
//         // Binding of parent port to submodule port.
//         m.din(din);
//         ...
//
//   Performing a blocking read in a pipelined application:
//
//     SC_MODULE(M) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> rst;
//
//       
//       cynw_p2p<DT,PIN>::in din;
//       cynw_p2p<DT,PIN>::out dout;
//
//       SC_CTOR(M) 
//       {
//         // Bind both the input to the output for stall propagation.
//         din.stall_prop(dout);
//
//         // Bind clk and rst.
//         din.clk_rst( clk, rst );
//         dout.clk_rst( clk, rst );
//
//         SC_CTHREAD( t, clk.pos() );
//         reset_signal_is( rst, 0 );
//       }
//
//       void t()
//       {
//         din.reset();
//         dout.reset();
//
//         while (1) 
//         {
//           HLS_PIPELINE_LOOP( 1, "pipe" );
//
//           // Read, waiting for data to be available.
//           // This call infers a hard input stall.
//           DT ival = din.get();
//
//           // Process the value.
//           DT oval = f(ival);
//
//           // Write the value.  Because a blocking read was performed
//           // at the input, the vld bit will always be set when this
//           // value is written.  This would also be true if there was
//           // no stall_prop() connection.
//           // This call infers a hard stall.
//           dout.put( oval );
//         }
//       }
//     };
//
//   Input and output ports doing implicit soft stall using a stall_prop() connection.
//
//     SC_MODULE(M) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> rst;
//
//       
//       cynw_p2p<DT,PIN>::in din;
//       cynw_p2p<DT,PIN>::out dout;
//
//       SC_CTOR(M) 
//       {
//         // Bind the input to the output for stall propagation.
//         din.stall_prop(dout);
//
//         // Bind clk and rst.
//         din.clk_rst( clk, rst );
//         dout.clk_rst( clk, rst );
//
//         SC_CTHREAD( t, clk.pos() );
//         reset_signal_is( rst, 0 );
//       }
//
//       void t()
//       {
//         din.reset();
//         dout.reset();
//
//         while (1) 
//         {
//           HLS_PIPELINE_LOOP(1,"pipe");
//
//           // Read, waiting for only one cycle.
//           // Data may or may not be valid.
//           DT ival = din.get(false);
//
//           // Process the value.
//           DT oval = f(ival);
//
//           // Write the value.
//           // Because of the stall_prop() connection, the output metaport will
//           // access the input metaport's data_was_valid() function to determine
//           // whether the value being written is valid, and set the vld output
//           // appropriately.
//           dout.put( oval );
//         }
//       }
//     };
//
//   Performing a blocking read in an unpipelined application:
//
//     In this example, we omit the stall_prop() connection because the design
//     is not pipelined.  Having such a connection would be harmless, but is
//     not necessary.
//
//     SC_MODULE(M) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> rst;
//
//       cynw_p2p<DT,PIN>::in din;
//       cynw_p2p<DT,PIN>::out dout;
//
//       SC_CTOR(M) 
//       {
//         // Bind clk and rst.
//         din.clk_rst( clk, rst );
//         dout.clk_rst( clk, rst );
//
//         SC_CTHREAD( t, clk.pos() );
//         reset_signal_is( rst, 0 );
//       }
//
//       void t()
//       {
//         din.reset();
//         dout.reset();
//
//         while (1) 
//         {
//           // Read, waiting for data to be available.
//           DT ival = din.get();
//
//           // Process the value.
//           DT oval = f(ival);
//
//           // Write the value.
//           dout.put( oval );
//         }
//       }
//     };
//
//
////////////////////////////////////////////////////////////
template <class T, typename CYN_L>
class cynw_p2p_in :
  public sc_module,
  public cynw_p2p_base_in<T,CYN_L>,
  public cynw_stall_prop_in,
  public cynw_clk_rst,
  public cynw_hier_bind_detector
{
  public:
    SC_HAS_PROCESS(cynw_p2p_in);

    HLS_EXPOSE_PORTS( OFF, clk, rst );

    typedef cynw_p2p_in<T,CYN_L>  this_type;
    typedef T                           data_type;
    typedef cynw_p2p_base_in<T,CYN_L>     base_type;
    typedef cynw_stall_prop_in           stall_type;
    typedef base_type                   metaport;
    typedef CYN_L		  p2p_level;

    cynw_p2p_in( 
	sc_module_name in_name=sc_module_name(sc_gen_unique_name("p2p_in")),
	unsigned options=0,
	double input_delay=HLS_CALC_TIMING ) 
      : sc_module(in_name),
	base_type(in_name,options,input_delay),
        stall_type(in_name,options),
	m_skip_read(false),
	m_use_stall_reg(false),
	m_use_stall_reg_ip(false),
	m_warnings(0),
	m_last_reset_time(-1.0),
	m_double_read_check(false),
        m_stream_name(sc_string("sc_main.") + sc_string(this->name())),
	m_tx_stream(0)
    {
      if (input_delay == 0.0)
      {
	// An input delay of 0 implies registered inputs.
	set_option( CYNW_REG_INPUTS );
	base_type::m_input_delay = HLS_CALC_TIMING;
      }
      // Specify an for vld and data.
      HLS_SET_INPUT_DELAY( this->vld, base_type::m_input_delay, "" );
      HLS_SET_INPUT_DELAY( this->data, base_type::m_input_delay, "" );

      // If m_use_stall_reg_ip is ever set to 1, it is treated as being
      // a constant 1.  This is used to indicate whether any of the get() calls
      // might require a stall reg to be managed by the methods.
      CYN_CONSTANT_SET_VALUE(m_use_stall_reg_ip, 1);
      CYN_ASSUME_VALUE(m_use_stall_reg_ip,0);
      CYN_ASSUME_VALUE(m_data_is_invalid,0);
      CYN_ASSUME_VALUE(m_force_hold,0);

      SC_METHOD(gen_busy);
      sensitive << m_busy_in;
      sensitive << base_type::vld;
      sensitive << m_vld_reg;
      sensitive << m_stall_reg_full;
      sensitive << m_busy_req_0;
      sensitive << m_unvalidated_req;

      SC_METHOD(gen_unvalidated_req);
      sensitive << clk.pos();
      dont_initialize();

      SC_METHOD(gen_local_busy);
      sensitive << ob0;
      sensitive << ob1;
      sensitive << ob2;
      sensitive << ob3;
      sensitive << ob4;
      sensitive << ob5;
      sensitive << ob6;
      sensitive << ob7;

#ifdef STRATUS_HLS
      // These methods are only used in designs using pipeline stalls.
      // They cannot affect behavioral designs.
      SC_METHOD(gen_do_stall_reg);
      sensitive << clk.pos();
      dont_initialize();

      SC_METHOD(gen_do_stall_reg_full);
      sensitive << clk.pos();
      dont_initialize();
#endif

#ifndef STRATUS_HLS
      // This method is only needed if CYNW_REG_INPUTS is set.
      if ( base_type::m_options_base & CYNW_REG_INPUTS )
#endif
      {
	SC_METHOD(gen_do_reg_data);
	sensitive << clk.pos();
        dont_initialize();

	SC_METHOD(gen_do_reg_vld);
	sensitive << clk.pos();
        dont_initialize();
      }

    }

    //
    // Binding functions
    //
    template <class CYN_C>
    void bind( CYN_C& c )
    {
      cynw_mark_hierarchical_binding( &c );
      busy(c.busy);
      vld(c.vld);
      data(c.data);
    }

    template <class CYN_C>
    void operator()( CYN_C& c )
    {
      bind(c);
    }

    //
    // cynw_p2p_in_if
    //
    T get( bool wait_until_valid=true )
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_get");

      warning_check( CYN_P2P_NO_RESET_IN_WARNING );
      warning_check( CYN_P2P_NO_WAIT_AFTER_RESET_WARNING );
      warning_check( CYN_P2P_RESET_POLARITY_WARNING );

      if (m_skip_read) 
      {
	wait();
      } else {
        get_start();
	if (wait_until_valid) 
	{
	  //
	  // Stall waiting for a valid input.
	  // busy is left deasserted while we are waiting.
	  //
	  m_data_was_valid = true;
    
	  HLS_SET_STALL_VALUE( m_stalling, 1, 0 );
	  do { 
	    CYNW_P2P_STALL_LOOPS("get");
	    wait();
	  } while (m_data_is_invalid.read());
	} else {
	  //
	  // Wait for only one cycle and sample vld.
	  // The value we read is not valid if we are asserting busy.
	  // Callers can find out whether the data was valid by calling
	  // data_was_valid().
	  //
	  wait();
	  m_data_was_valid = nb_can_get();
	}
	get_end();
      }

      T rslt;
      nb_get(rslt);

      return rslt;
    }

    T poll( bool placeholder=false )
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_poll");
      HLS_REMOVE_CONTROL(ON,"");

      get_start(placeholder);
      wait();

      m_data_was_valid = (placeholder && m_data_was_valid) || (!placeholder && nb_can_get());

      get_end();

      T rslt;
      nb_get(rslt);

      return rslt;
    }

    void reset()
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_reset");

      //
      // If the CYNW_NO_RESET_BUSY_PROP option is set, start with a busy_req of 0.
      // This allows the path from output busy to input busy to be a wire for II=1 
      // designs.
      //
      if ( (m_options_stall & CYNW_NO_RESET_BUSY_PROP) == 0) 
      {
	m_busy_req_0 = 1;
      }

      if ( !CYNW_BEH_SIM && ((base_type::m_options_base & CYNW_AUTO_ASYNC_BUSY_PROP) != 0)) {
	m_force_hold = 0;
      }
      
      CYNW_P2P_SET_WARNING_DONE(CYN_P2P_NO_RESET_IN_WARNING);
#if CYNW_DO_CHECKING
      m_last_reset_time = sc_time_stamp().to_double();
      m_double_read_check = false;
#endif

      warning_check( CYN_P2P_NO_BINDING_WARNING );

      base_type::m_use_beh_latched = false;
      base_type::m_value_was_read = false;
      m_data_was_valid = false;

      //
      // The m_stalling signal will be driven to 1 asynchronously during hard stalls.
      //
      cynw_assert_during_stall( m_stalling, 1, 0, &m_busy_req_0 );
    }

    bool nb_get( T& val )
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_nb_get");
      HLS_SET_INPUT_DELAY( base_type::data, base_type::m_input_delay, "" );

      warning_check( CYN_P2P_NO_RESET_IN_WARNING );

      if ( base_type::m_use_beh_latched ) 
      {
	// If there's been a value latched behaviorally, return that.
	val = base_type::m_beh_latched_value;
      } 
      else if ( m_use_stall_reg ) 
      {
	// If the stall_reg is in use, read the value from it if it contains a value.
	HLS_REMOVE_CONTROL(ON,"");
	if (m_stall_reg_full.read())
	  val = m_stall_reg.read();
	else
	  val = use_data();
      } 
      else 
      {
	val = use_data();
      }
      bool good_value = nb_can_get();

      // If a value was obtained, log the value with the end of the transaction.
      // If not, terminate the transaction with no data.
      if (good_value)
	tx_stream()->end_get_tx( val );
      else
	tx_stream()->terminate_tx();

      if ( (m_options_stall & CYNW_AUTO_ASYNC_BUSY_PROP) != 0) {
	// With auto async busy, once a value has been read.
	if (good_value) {
	  m_force_hold = 0;
	  
	  #if CYNW_DO_CHECKING
	  // This makes the CYNW_AUTO_ASYNC_BUSY_PROP option incompatible
	  // with designs that call nb_get() more than once between active
	  // polls, expecting to get the same value back. If CYNW_AUTO_ASYNC_BUSY_PROP is 
	  // used, nb_get() should only be called once for each good value.
	  // Detect this condition in BEH sims and warn.
	  if (m_double_read_check) {
	      esc_report_error( esc_warning, "\n\t%s: cynw_p2p_in: %s: "
					     "Multiple nb_get() calls for a single request on the same input.\n\t",
					     name(), ::esc_realtime() );

	    m_double_read_check = false;
	  } else {
	    m_double_read_check = true;
	  }
	  #endif
	}
      }

      base_type::m_value_was_read = good_value;

      return good_value;
    }

#define CYNW_P2P_IN_NB_CAN_GET(p) (((p).m_data_was_valid || (p).m_data_is_valid.read()) && !(p).m_value_was_read)

    bool nb_can_get()
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_nb_can_get");
      bool rslt = CYNW_P2P_IN_NB_CAN_GET(*this);
      return rslt;
    }

    const sc_event& ok_to_get() const
    {
      return m_data_is_valid.value_changed_event();
    }

    void get_start( bool busy_val=false )
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_get_start");
      HLS_SUPPRESS_MSG_SYM( 513, m_busy_req_0 );
      HLS_SUPPRESS_MSG_SYM( 408, m_beh_latched_value );
      HLS_SUPPRESS_MSG_SYM( 408, m_stall_reg );
      if ( !CYNW_BEH_SIM && ((base_type::m_options_base & CYNW_AUTO_ASYNC_BUSY_PROP) != 0)) {
	m_busy_req_0 = 0; // Always request.  Rely on forced busy to avoid requests.
      } else {
	m_busy_req_0 = busy_val;
      }

      if (!busy_val) 
      {
	base_type::m_use_beh_latched = false;
	m_data_was_valid = false;
	base_type::m_value_was_read = false;
	#if CYNW_DO_CHECKING
	m_double_read_check = false;
	#endif
	tx_stream()->begin_get_tx();
      }
      //
      // When the m_use_stall_reg var is set to 0, the m_stall_reg will 
      // not be accessed by nb_get().  This will prevent instantiation of
      // the register in the RTL when it is unneeded.  A register may be
      // needed if we're called from a pipeline (because the output may stall),
      // and it should not be needed if there is a bind to an output port
      // to propagate the busy bit.
      //
      set_use_stall_reg(   (base_type::m_options_base & CYNW_USE_STALL_REG)
			|| ((HLS_INITIATION_INTERVAL > 0) && (m_n_outputs_b == 0)) ); 
    }
    
    void get_end()
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_get_end");
      m_busy_req_0 = 1;
    }

    void set_use_stall_reg( bool usr )
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_in_set_use_stall_reg");

      if ( !CYNW_BEH_SIM && ((base_type::m_options_base & CYNW_AUTO_ASYNC_BUSY_PROP) != 0)) {
	// If we always assert busy with a stall, never use a stall reg.
	usr = false;
      } 
      // The m_use_stall_reg_ip bit is for reading in methods.  Makes it
      // easier for Cynthesizer to optimize if these are separate.
      m_use_stall_reg = usr;
      m_use_stall_reg_ip = usr;
      HLS_SET_OUTPUT_OPTIONS( m_use_stall_reg_ip, ASYNC_NO_HOLD );
      HLS_SUPPRESS_MSG_SYM( 1433, m_use_stall_reg_ip );
      HLS_SUPPRESS_MSG_SYM( 2588, m_use_stall_reg_ip );
    }

    bool data_was_valid()
    {
      return stall_type::data_was_valid();
    }

    // Sets a value to be returned from nb_get().
    void latch_value( bool do_latch=true )
    {
      HLS_DEFINE_PROTOCOL("latch_value");
      stall_type::m_data_was_valid |= (do_latch && m_data_is_valid.read());
      if ( !CYNW_BEH_SIM && ((base_type::m_options_base & CYNW_AUTO_ASYNC_BUSY_PROP) != 0)) {
	HLS_SET_OUTPUT_OPTIONS( m_force_hold, ASYNC_HOLD );
	if (do_latch) 
	  m_force_hold = 1;
      } else {
	base_type::m_use_beh_latched = false; // Never get from m_beh_latched_value.
	if (do_latch) {
	  HLS_REMOVE_CONTROL(ON);
	  nb_get( base_type::m_beh_latched_value );
	  #if CYNW_DO_CHECKING
	  m_double_read_check = false;
	  #endif
	}
	base_type::m_use_beh_latched = true;
      }
      base_type::m_value_was_read = false;
    }

    void set_state( unsigned which, unsigned value )
    {
      switch (which) {
	case CYNW_SET_USE_STALL_REG   :
	  set_use_stall_reg( value );
	  break;
	case CYNW_SET_DATA_WAS_VALID  :
	  m_data_was_valid = value;
	  break;
	case CYNW_SET_VALUE_WAS_READ  :
	  base_type::m_value_was_read = value;
	  break;
	default:
	  break;
      }
    }

    // Convenience operators for assigning from.
    operator T() { return this_type::get(); }

    void set_option( unsigned o )
    {
      base_type::set_option(o);
      stall_type::set_option(o);
    }
    void clear_option( unsigned o )
    {
      base_type::clear_option(o);
      stall_type::clear_option(o);
    }

    CYNW_CLK_RST_FUNCS

  public:
    sc_signal<bool> m_busy_req_0;	 /* One-shot request from FSM. */
    sc_signal<bool> m_data_is_valid;	 /* true when valid data is present during a request. */
    sc_signal<bool> m_data_is_invalid;	 /* inverse of m_data_is_valid.  Hides NOT from accessing thread. */
    sc_signal<bool> m_unvalidated_req;   /* true when a request has been made but not validated. */
    sc_signal<bool> m_unacked_value;	 /* busy asserted to latch upstream, but value has been processed. Active low.*/
    sc_signal<bool> m_stall_reg_full;		 /* true when a value was latched during a stall. */
    sc_signal<bool> m_stalling;		 /* Set to 1 during a hard stall in RTL model only. */
    sc_signal<bool> m_force_hold;	 /* Async signal asserted to force upstream to hold value. */
    sc_signal< typename cynw_sc_wrap<T>::sc > m_stall_reg;		 /* Used to store values when stalls occur during blocking reads. */
    sc_signal< typename cynw_sc_wrap<T>::sc > m_data_reg;		 /* Used to store data values for CYNW_REG_INPUTS. */
    sc_signal<bool> m_vld_reg;		 /* Used to store vld values for CYNW_REG_INPUTS. */
    sc_signal<bool> m_busy_internal;	 /* Internal signal following the value of busy. */
    bool m_skip_read;			 /* true when reads should be avoided because we're generating a stall. */
    bool m_use_stall_reg;		 /* true when a stall register might be needed. */
    bool m_use_stall_reg_ip;		 /* follows m_use_stall_reg.  Used inter-process. */
    unsigned m_warnings;
    double m_last_reset_time;
    bool m_double_read_check;		 

    // Returns either m_vld_reg or vld depending on the CYNW_REG_INPUTS option.
    bool use_vld()
    {
      if ( base_type::m_options_base & CYNW_REG_INPUTS ) {
	return m_vld_reg.read();
      } else {
	return base_type::vld.read();
      }
    }

    // Returns either m_data_reg or data depending on the CYNW_REG_INPUTS option.
    T use_data()
    {
      if ( base_type::m_options_base & CYNW_REG_INPUTS ) {
	return m_data_reg.read();
      } else {
	return base_type::data.read();
      }
    }

    //
    // Asynchronous SC_METHOD.
    //
    // The busy output is asserted when either the client is requesting
    // busy, indicating that it is not ready to read, or when there is
    // a busy being asserted from downstream.  Busy is also set after
    // a value has been latched during a stall, unless CYNW_NO_RESET_BUSY_PROP is set.
    //
    void gen_busy()
    {
      if ( is_hierarchically_bound() ) 
	return;

      // For FPGAs, we will combine the logic here into one LUT to avoid timing problems using DPOPT_INLINE.
      {HLS_DPOPT_REGION( FPGA_ONLY,"gen_busy","gen_busy");

      bool busy_req_1;

      if ( !CYNW_BEH_SIM && (base_type::m_options_base & CYNW_II1_OPTIM) ) {

	// Eliminate the path from 'vld' for II=1 pipes since we
	// will always be requesting a value, and deadlock can't occur.
	// This eliminated the async path from vld to busy.
	//
	busy_req_1 = m_busy_req_0.read() && m_unvalidated_req.read();

      } else {

	// If there's an unvalidated_req, re-assert it until a new value is actually
	// asserted, at which point we raise busy to cause the writer to hold it until
	// we can come back and read it again.  This can prevent deadlock in unpipelined,
	// or II>1 designs with soft stall.  Note that it forms an async path from vld to busy.
	// If this is not acceptable, consider using CYNW_II1_OPTIM.
	//
	busy_req_1 = m_busy_req_0.read() && (m_unvalidated_req.read() || use_vld());
      }
      
      if ( !CYNW_BEH_SIM && ((base_type::m_options_base & CYNW_AUTO_ASYNC_BUSY_PROP) != 0) ) {
	// Busy is asynchronously asserted during stalls, and when m_force_hold has been procedurally asserted,
	// in addition to the normal logic.  The m_force_hold async signal will be asserted after a valid
	// value has been written, and deasserted when its read with nb_get().  We assert busy when 
	// its set to force the upstream writer to hold its value.  This causes some issues to need to
	// be handled:
	//  1. The upstream writer must use a 'write before wait' version of the p2p protocol in order to 
	//     avoid deadlock.
	//  2. We must avoid including m_force_hold in the logic for m_data_is_value, because that
	//     signal is also used  to calculate whether a value should be read, and we would cause
	//     an async loop.  For this reason, the reader will think it has a value, but the writer
	//     will not have been acked.  To resole this, we use the m_unacked_value FF to identify 
	//     cycles when busy should be deasserted to ack, but where it should not be interepreted
	//     as another valid value.
	//  3. This approach naturally creates longer async paths, and potentially async paths across
	//     multiple modules and threads, so it should be used with care.  the best practice is to
	//     use  a HLS_DEFINE_PROTOCOL block to keep calls to cynw_poll*()/cynw_wait*() functions in the same
	//     clock cycle as nb_get() calls.
	bool force_ack = m_unacked_value.read() || m_force_hold.read(); // Been read, but not acked.  Active low.
	bool new_busy =  (busy_req_1 || m_busy_in.read() || m_stalling.read()) && force_ack;
	m_busy_internal = new_busy;
	base_type::busy = new_busy || m_force_hold.read(); // Don't include in data_is_valid to avoid an async loop.
	bool div =   (use_vld() && !new_busy && m_unacked_value.read());	// Valid value during a request.
	m_data_is_valid = div;
	m_data_is_invalid = !div;
      } else if ( (m_options_stall & CYNW_NO_RESET_BUSY_PROP) == 0) 
      {
	// This is the default logic for busy and data_is_valid.
	// It will take into account the potential presence of a stall register in cases
	// where the stall register has not been optimized away for other reasons.
	bool new_busy =  busy_req_1 || m_busy_in.read() 
		      || (m_use_stall_reg_ip && m_stall_reg_full.read());
	m_busy_internal = new_busy;
	base_type::busy = new_busy;
	bool div =   (use_vld() && !new_busy)	// Valid value during a request.
		  || (m_use_stall_reg_ip && m_stall_reg_full.read());	// Value latched during a stall.
	m_data_is_valid = div;
	m_data_is_invalid = !div;
      } else {
	// This logic for busy and data_is_valid can be used to simplify async logic in straightforward 
	// pipelinened applications.
	bool new_busy = busy_req_1 || m_busy_in.read();
	m_busy_internal = new_busy;
	base_type::busy = new_busy;
	bool div = (use_vld() && !new_busy);
	m_data_is_valid = div;
	m_data_is_invalid = !div;
      }
      }
    }

    //
    // Synchronous SC_METHOD
    //
    // m_unvalidated_req is asserted (low) when a request busy=0 request has
    // been made but has not been acknowledged with a vld.
    //
    void gen_unvalidated_req()
    {
      if (rst_active())
      {
	HLS_SET_IS_RESET_BLOCK("gen_unvalidated_req");
	if ( is_hierarchically_bound() ) return;
	if ( !CYNW_BEH_SIM && ((base_type::m_options_base & CYNW_AUTO_ASYNC_BUSY_PROP) != 0) ) {
	  m_unacked_value = 1; 
	}
	m_unvalidated_req = 1;
      } else {
	if ( is_hierarchically_bound() ) return;
	if ( !CYNW_BEH_SIM && ((base_type::m_options_base & CYNW_AUTO_ASYNC_BUSY_PROP) != 0) ) {
	  m_unacked_value = ( !base_type::busy.read() || !m_data_is_valid.read() ); // Active low.
	}
	if ( !m_busy_req_0.read() )
	  m_unvalidated_req = use_vld(); // Active low.
      }
    }

    // 
    // Synchronous SC_METHOD
    //
    // Latches values during stalls.
    // This register will be optimized away if not used.  It will only be used
    // during hard inputs stalls without async stall propagation.
    //
    void gen_do_stall_reg()
    {
      rst_active();  // Sample to get side effects.

      // Stall register.  Avoid resetting.
      if ( m_data_is_valid.read() && m_stalling.read() && !m_stall_reg_full.read() ) 
      {
	HLS_REMOVE_CONTROL(OFF,"");
	if ( is_hierarchically_bound() ) return;
	m_stall_reg.write( use_data() );
      }
    }
    
    // 
    // Synchronous SC_METHOD
    //
    // m_stall_reg_full is set when there is valid data during a stall.  Note that
    // since m_stall_reg_full will cause m_data_is_valid to be asserted, it's "sticky"
    // and will remain asserted for the remainder of the stall.
    //
    void gen_do_stall_reg_full()
    {
      // Indicator that stall register is full.
      if (rst_active())
      {
	HLS_SET_IS_RESET_BLOCK("gen_do_stall_reg_full");
	if ( is_hierarchically_bound() ) return;
	m_stall_reg_full = 0;
      } else {
	if ( is_hierarchically_bound() ) return;
	m_stall_reg_full = m_data_is_valid.read() && m_stalling.read();
      }
    }
    
    // 
    // Synchronous SC_METHOD
    //
    // Latches data input to implement CYNW_REG_INPUTS.
    // Don't latch values when when we're not requesting one.
    //
    void gen_do_reg_data()
    {
      rst_active();  // Sample to get side effects.  Don't infer reset.

      if (!m_busy_internal.read())
      {
	HLS_REMOVE_CONTROL(OFF,"");
	if ( is_hierarchically_bound() ) return;
	m_data_reg = base_type::data.read();
      }
    }

    // 
    // Synchronous SC_METHOD
    //
    // Latches vld input to implement CYNW_REG_INPUTS.
    // Don't latch values when when we're not requesting one.
    //
    void gen_do_reg_vld()
    {
      if ( rst_active() )
      {
	HLS_SET_IS_RESET_BLOCK("gen_do_reg_vld");
	if ( is_hierarchically_bound() ) return;
	m_vld_reg = 0;
      } else {
	if ( is_hierarchically_bound() ) return;
	if (!m_busy_internal.read())
	  m_vld_reg = base_type::vld.read();
      }
    }

    //
    // From cynw_stall_prop
    //

    //
    // Asynchronous SC_METHOD.
    //
    // Generate a composite of downstream busy and internally generated busy.
    // The busy from all bound output ports is ORed together.
    //
    void gen_local_busy()
    {
      if ( is_hierarchically_bound() ) 
	return;

      switch (m_n_outputs_b) 
      {
	default:
	case 0:	m_busy_in = 0; break;
	case 1: m_busy_in =    ob0.read(); break;
	case 2: m_busy_in =    ob0.read() || ob1.read(); break;
	case 3: m_busy_in =    ob0.read() || ob1.read() || ob2.read(); break;
	case 4: m_busy_in =    ob0.read() || ob1.read() || ob2.read()
			    || ob3.read(); break;
	case 5: m_busy_in =    ob0.read() || ob1.read() || ob2.read()
			    ||  ob3.read() || ob4.read(); break;
	case 6: m_busy_in =    ob0.read() || ob1.read() || ob2.read()
			    || ob3.read() || ob4.read() || ob5.read(); break;
	case 7: m_busy_in =    ob0.read() || ob1.read() || ob2.read()
			    || ob3.read() || ob4.read() || ob5.read() 
			    || ob6.read(); break;
	case 8: m_busy_in =    ob0.read() || ob1.read() || ob2.read()
			    || ob3.read() || ob4.read() || ob5.read() 
			    || ob6.read() || ob7.read(); break;
      }
    }

    void warning_check( unsigned code )
    {
#if CYNW_DO_CHECKING
      if ( CYNW_P2P_WAS_WARNING_DONE(code) )
	return;

      //
      // CYN_P2P_NO_BINDING_WARNING
      //
      // Generate a warning if async busy prop has been requested but no stall_prop()
      // bindings have been made.
      //
      if (   (code & CYN_P2P_NO_BINDING_WARNING)
	  && ((m_options_stall & CYNW_NO_RESET_BUSY_PROP) != 0)
	  && (m_n_outputs_b == 0) )
      {
	esc_report_error( esc_warning, "\n\t%s: cynw_p2p_in: "
				       "Asynchronous busy propagation was requested, "
				       "but no stall_prop() bindings have been made",
				       name() );
      }

      //
      // CYN_P2P_NO_RESET_IN_WARNING
      //
      // Generate a warning if the port is read or written without having been first
      // reset.
      //
      if (code & CYN_P2P_NO_RESET_IN_WARNING)
      {
	esc_report_error( esc_warning, "\n\t%s: cynw_p2p_in: "
	                               "Port is read, but reset() has not been called",
				       name() );
      }

      //
      // CYN_P2P_NO_WAIT_AFTER_RESET_WARNING
      //
      // Generate a warning if the first get() call occurs at the same time as 
      // the reset call.  This implies there is no wait() between reset() and get().
      //
      if (  (code & CYN_P2P_NO_WAIT_AFTER_RESET_WARNING)
	  && (m_last_reset_time >= 0)
	  && (m_last_reset_time == sc_time_stamp().to_double()) )
      {
	esc_report_error( esc_warning, "\n\t%s: cynw_p2p_in: "
	                               "There was no wait() between the reset() call and the first get() call.\n\t"
				       "This can lead to simulation mismatches and inefficient hardware",
				       name() );
      }

      //
      // CYN_P2P_RESET_POLARITY_WARNING
      //
      // Generate a warning if the reset polarity for the cynw_clk_rst base class
      // doesn't match its current condition.  If reset() is called immediately at
      // the top of a CTHREAD, this should catch mismatches between the CTHREAD's
      // watching() value, and the polarity given to clk_rst().
      //
      if ( (code & CYN_P2P_RESET_POLARITY_WARNING) && (sc_time_stamp().to_double() > 0) )
      {
	if ( rst_active() )
	{
	  esc_report_error( esc_warning, "\n\t%s: cynw_p2p_in: "
					 "Potential reset polarity mismatch between the reset_signal_is() statement for the\n\t"
					 "SC_CTHREAD, and the reset polarity specified in the third parameter to the clk_rst() call for this metaport (which is %d)",
					 name(), (int)m_rst_active_high );
	}
      }
      
      CYNW_P2P_SET_WARNING_DONE(code);
#endif
    }

    cynw_scv_token_tx_stream<T>* tx_stream()
    {
#if !STRATUS
      if (m_tx_stream == 0) {
        esc_enable_scv_logging();
        m_tx_stream = new cynw_scv_token_tx_stream<T>( m_stream_name.c_str(), false, esc_get_scv_tr_db() );
      }
      return m_tx_stream;
#else
      return 0;
#endif
    }

    sc_string m_stream_name;
    cynw_scv_token_tx_stream<T>* m_tx_stream;

};

// 
// Macros for building vectors where each bit in the vector comes from 
// the value of a boolean member function called on each of several objects.
//
// For example:
//   sc_uint<2> ready = CYNW_CALL_VEC_2(p1,p2,data_was_valid);
//
// is the same as:
//   sc_uint<2> ready = ((sc_uint<1>)p1.data_was_valid(),(sc_uint<1>)p2.data_was_valid()):
// 
// This form is used frequently in multiple I/O functions, and using the macros
// is more compact and less error prone.
//
#define CYNW_CALL_VEC_2(p2,p1,func) \
   ((sc_uint<1>)p2.func(),(sc_uint<1>)p1.func());
#define CYNW_CALL_VEC_3(p3,p2,p1,func) \
   ((sc_uint<1>)p3.func(),(sc_uint<1>)p2.func(),(sc_uint<1>)p1.func());
#define CYNW_CALL_VEC_4(p4,p3,p2,p1,func) \
   ((sc_uint<1>)p4.func(),(sc_uint<1>)p3.func(),(sc_uint<1>)p2.func(),(sc_uint<1>)p1.func());
#define CYNW_CALL_VEC_5(p5,p4,p3,p2,p1,func) \
   ((sc_uint<1>)p5.func(),(sc_uint<1>)p4.func(),(sc_uint<1>)p3.func(),(sc_uint<1>)p2.func(),(sc_uint<1>)p1.func());
#define CYNW_CALL_VEC_6(p6,p5,p4,p3,p2,p1,func) \
   ((sc_uint<1>)p6.func(),(sc_uint<1>)p5.func(),(sc_uint<1>)p4.func(),(sc_uint<1>)p3.func(),(sc_uint<1>)p2.func(),(sc_uint<1>)p1.func());
#define CYNW_CALL_VEC_7(p7,p6,p5,p4,p3,p2,p1,func) \
   ((sc_uint<1>)p7.func(),(sc_uint<1>)p6.func(),(sc_uint<1>)p5.func(),(sc_uint<1>)p4.func(),(sc_uint<1>)p3.func(),(sc_uint<1>)p2.func(),(sc_uint<1>)p1.func());
#define CYNW_CALL_VEC_8(p8,p7,p6,p5,p4,p3,p2,p1,func) \
   ((sc_uint<1>)p8.func(),(sc_uint<1>)p7.func(),(sc_uint<1>)p6.func(),(sc_uint<1>)p5.func(),(sc_uint<1>)p4.func(),(sc_uint<1>)p3.func(),(sc_uint<1>)p2.func(),(sc_uint<1>)p1.func());

//
// Macro for calling the same function on a set of params.
// The function has no param, and no return value.
//
#define CYNW_CALL_FUNC_2(p2,p1,func) \
   p2.func();p1.func();
#define CYNW_CALL_FUNC_3(p3,p2,p1,func) \
   p3.func();p2.func();p1.func();
#define CYNW_CALL_FUNC_4(p4,p3,p2,p1,func) \
   p4.func();p3.func();p2.func();p1.func();
#define CYNW_CALL_FUNC_5(p5,p4,p3,p2,p1,func) \
   p5.func();p4.func();p3.func();p2.func();p1.func();
#define CYNW_CALL_FUNC_6(p6,p5,p4,p3,p2,p1,func) \
   p6.func();p5.func();p4.func();p3.func();p2.func();p1.func();
#define CYNW_CALL_FUNC_7(p7,p6,p5,p4,p3,p2,p1,func) \
   p7.func();p6.func();p5.func();p4.func();p3.func();p2.func();p1.func();
#define CYNW_CALL_FUNC_8(p8,p7,p6,p5,p4,p3,p2,p1,func) \
   p8.func();p7.func();p6.func();p5.func();p4.func();p3.func();p2.func();p1.func();

////////////////////////////////////////////////////////////
//
// function: cynw_wait_all_can_get_beh()
//
// summary: 
//
//  Behavioral (not pipelinable) functions to wait for multiple inputs
//  to be ready.
//
// details:
//
//   This function implements a purely behavioral, non-stallable
//   function to wait for a value to be ready on multiple inputs.
//   It it useful in testbenches and behavioral models.
//
//   This function will assert busy on any interface that has 
//   received a value when not all other interfaces have yet
//   received values. 
//
////////////////////////////////////////////////////////////

#define CWCG_START(i) \
  p##i.get_start( got[i-1] );

#define CWCG_END(i) \
    { \
      sc_uint<1> new_valid = (!got[i-1] && p##i.nb_can_get()); \
      got[i-1] |= new_valid; \
      p##i.latch_value( new_valid ); \
    }

template <class CYN_C1, class CYN_C2>
void cynw_wait_all_can_get_beh( CYN_C1& p1, CYN_C2& p2 )
{
  HLS_DEFINE_PROTOCOL("cynw_nb_can_get_beh");
  sc_uint<2> got = 0;
  p1.set_state( CYNW_SET_USE_STALL_REG, true);
  p2.set_state( CYNW_SET_USE_STALL_REG, true);
  do 
  { 
    CWCG_START(1);
    CWCG_START(2);
    wait();
    CWCG_END(1);
    CWCG_END(2);
  } while ( got != 3 );
  p1.get_end();
  p2.get_end();
}

template <class CYN_C1, class CYN_C2, class CYN_C3>
void cynw_wait_all_can_get_beh( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get_beh");
  sc_uint<3> got = 0;
  p1.set_state( CYNW_SET_USE_STALL_REG, true);
  p2.set_state( CYNW_SET_USE_STALL_REG, true);
  p3.set_state( CYNW_SET_USE_STALL_REG, true);
  do 
  { 
    CWCG_START(1);
    CWCG_START(2);
    CWCG_START(3);
    wait();
    CWCG_END(1);
    CWCG_END(2);
    CWCG_END(3);
  } while ( got != 7 );
  p1.get_end();
  p2.get_end();
  p3.get_end();
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4>
void cynw_wait_all_can_get_beh( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get_beh");
  sc_uint<4> got = 0;
  p1.set_state( CYNW_SET_USE_STALL_REG, true);
  p2.set_state( CYNW_SET_USE_STALL_REG, true);
  p3.set_state( CYNW_SET_USE_STALL_REG, true);
  p4.set_state( CYNW_SET_USE_STALL_REG, true);
  do 
  { 
    CWCG_START(1);
    CWCG_START(2);
    CWCG_START(3);
    CWCG_START(4);
    wait();
    CWCG_END(1);
    CWCG_END(2);
    CWCG_END(3);
    CWCG_END(4);
  } while ( got != 15 );
  p1.get_end();
  p2.get_end();
  p3.get_end();
  p4.get_end();
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5>
void cynw_wait_all_can_get_beh( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get_beh");
  sc_uint<5> got = 0;
  p1.set_state( CYNW_SET_USE_STALL_REG, true);
  p2.set_state( CYNW_SET_USE_STALL_REG, true);
  p3.set_state( CYNW_SET_USE_STALL_REG, true);
  p4.set_state( CYNW_SET_USE_STALL_REG, true);
  p5.set_state( CYNW_SET_USE_STALL_REG, true);
  do 
  { 
    CWCG_START(1);
    CWCG_START(2);
    CWCG_START(3);
    CWCG_START(4);
    CWCG_START(5);
    wait();
    CWCG_END(1);
    CWCG_END(2);
    CWCG_END(3);
    CWCG_END(4);
    CWCG_END(5);
  } while ( got != 31 );
  p1.get_end();
  p2.get_end();
  p3.get_end();
  p4.get_end();
  p5.get_end();
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5, class CYN_C6>
void cynw_wait_all_can_get_beh( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5, CYN_C6& p6 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get_beh");
  sc_uint<6> got = 0;
  p1.set_state( CYNW_SET_USE_STALL_REG, true);
  p2.set_state( CYNW_SET_USE_STALL_REG, true);
  p3.set_state( CYNW_SET_USE_STALL_REG, true);
  p4.set_state( CYNW_SET_USE_STALL_REG, true);
  p5.set_state( CYNW_SET_USE_STALL_REG, true);
  p6.set_state( CYNW_SET_USE_STALL_REG, true);
  do 
  { 
    CWCG_START(1);
    CWCG_START(2);
    CWCG_START(3);
    CWCG_START(4);
    CWCG_START(5);
    CWCG_START(6);
    wait();
    CWCG_END(1);
    CWCG_END(2);
    CWCG_END(3);
    CWCG_END(4);
    CWCG_END(5);
    CWCG_END(6);
  } while ( got != 63 );
  p1.get_end();
  p2.get_end();
  p3.get_end();
  p4.get_end();
  p5.get_end();
  p6.get_end();
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5, class CYN_C6, class CYN_C7>
void cynw_wait_all_can_get_beh( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5, CYN_C6& p6, CYN_C7& p7 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get_beh");
  sc_uint<7> got = 0;
  p1.set_state( CYNW_SET_USE_STALL_REG, true);
  p2.set_state( CYNW_SET_USE_STALL_REG, true);
  p3.set_state( CYNW_SET_USE_STALL_REG, true);
  p4.set_state( CYNW_SET_USE_STALL_REG, true);
  p5.set_state( CYNW_SET_USE_STALL_REG, true);
  p6.set_state( CYNW_SET_USE_STALL_REG, true);
  p7.set_state( CYNW_SET_USE_STALL_REG, true);
  do 
  { 
    CWCG_START(1);
    CWCG_START(2);
    CWCG_START(3);
    CWCG_START(4);
    CWCG_START(5);
    CWCG_START(6);
    CWCG_START(7);
    wait();
    CWCG_END(1);
    CWCG_END(2);
    CWCG_END(3);
    CWCG_END(4);
    CWCG_END(5);
    CWCG_END(6);
    CWCG_END(7);
  } while ( got != 127 );
  p1.get_end();
  p2.get_end();
  p3.get_end();
  p4.get_end();
  p5.get_end();
  p6.get_end();
  p7.get_end();
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5, class CYN_C6, class CYN_C7, class CYN_C8>
void cynw_wait_all_can_get_beh( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5, CYN_C6& p6, CYN_C7& p7, CYN_C8& p8 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get_beh");
  sc_uint<8> got = 0;
  p1.set_state( CYNW_SET_USE_STALL_REG, true);
  p2.set_state( CYNW_SET_USE_STALL_REG, true);
  p3.set_state( CYNW_SET_USE_STALL_REG, true);
  p4.set_state( CYNW_SET_USE_STALL_REG, true);
  p5.set_state( CYNW_SET_USE_STALL_REG, true);
  p6.set_state( CYNW_SET_USE_STALL_REG, true);
  p7.set_state( CYNW_SET_USE_STALL_REG, true);
  p8.set_state( CYNW_SET_USE_STALL_REG, true);
  do 
  { 
    CWCG_START(1);
    CWCG_START(2);
    CWCG_START(3);
    CWCG_START(4);
    CWCG_START(5);
    CWCG_START(6);
    CWCG_START(7);
    CWCG_START(8);
    wait();
    CWCG_END(1);
    CWCG_END(2);
    CWCG_END(3);
    CWCG_END(4);
    CWCG_END(5);
    CWCG_END(6);
    CWCG_END(7);
    CWCG_END(8);
  } while ( got != 255 );
  p1.get_end();
  p2.get_end();
  p3.get_end();
  p4.get_end();
  p5.get_end();
  p6.get_end();
  p7.get_end();
  p8.get_end();
}

////////////////////////////////////////////////////////////
//
// function: cynw_wait_all_can_get()
//
// summary: 
//
//  Waits for several interfaces to respond true to nb_can_get().
//
// details:
//
//   The cynw_wait_all_can_get() function is designed to be used 
//   to wait for several interfaces to have values available.
//   The valid value for each input metaport can then be retrieved
//   with a call to nb_get().
//
//   Overloads of cynw_wait_all_can_get() are available for from 1
//   to 8 input metaports.
//
// example:
//
//  In this example, cynw_wait_all_can_get() blocks until a valid value
//  is available on both din1 and din2.  The value is retrieved from
//  each metaport with nb_get(), values are computed for two outputs,
//  and a value is written to each of two output metaports.
//
//   while (1)
//   {
//       cynw_wait_all_can_get( din1, din2 );
//       din1.nb_get(d1);
//       din2.nb_get(d2);
//
//       q1 = d1 + d2;
//       q2 = d1 - d2;
//
//       cynw_wait_can_put( dout1, dout2 );
//       dout1.nb_put( q1 );
//       dout2.nb_put( q2 );
//   }
//
////////////////////////////////////////////////////////////


#define CWCGP_START(i) \
  p##i.get_start(); \
  p##i.set_state( CYNW_SET_USE_STALL_REG, true); \
  p##i.set_state( CYNW_SET_BLOCKING, true)

#define CWCGP_END(i) \
  p##i.set_state( CYNW_SET_DATA_WAS_VALID, 1 ); \
  p##i.get_end(); \
  p##i.latch_value()

template <class CYN_T1>
void cynw_wait_all_can_get_pin( CYN_T1& p1 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get");
  CWCGP_START(1);
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_all_can_get");
    wait();
  } while ( !p1.nb_can_get() );
  CWCGP_END(1);
}

template <class CYN_T1, class CYN_T2>
void cynw_wait_all_can_get_pin( CYN_T1& p1, CYN_T2& p2 )
{
#if STRATUS_HLS
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get");
  CWCGP_START(1);
  CWCGP_START(2);
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_all_can_get");
    wait();
  } while ( !p1.nb_can_get() || !p2.nb_can_get() );
  CWCGP_END(1);
  CWCGP_END(2);
#else 
  cynw_wait_all_can_get_beh( p1, p2 );
#endif
}

template <class CYN_T1, class CYN_T2, class CYN_T3>
void cynw_wait_all_can_get_pin( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 )
{
#if STRATUS_HLS
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get");
  CWCGP_START(1);
  CWCGP_START(2);
  CWCGP_START(3);
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_all_can_get");
    wait();
  } while ( !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() );
  CWCGP_END(1);
  CWCGP_END(2);
  CWCGP_END(3);
#else 
  cynw_wait_all_can_get_beh( p1, p2, p3 );
#endif
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4>
void cynw_wait_all_can_get_pin( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 )
{
#if STRATUS_HLS
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get");
  CWCGP_START(1);
  CWCGP_START(2);
  CWCGP_START(3);
  CWCGP_START(4);
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_all_can_get");
    wait();
  } while ( !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get() );
  CWCGP_END(1);
  CWCGP_END(2);
  CWCGP_END(3);
  CWCGP_END(4);
#else 
  cynw_wait_all_can_get_beh( p1, p2, p3, p4 );
#endif
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5>
void cynw_wait_all_can_get_pin( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 )
{
#if STRATUS_HLS
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get");
  CWCGP_START(1);
  CWCGP_START(2);
  CWCGP_START(3);
  CWCGP_START(4);
  CWCGP_START(5);
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_all_can_get");
    wait();
  } while (   !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get() 
	|| !p5.nb_can_get() );
  CWCGP_END(1);
  CWCGP_END(2);
  CWCGP_END(3);
  CWCGP_END(4);
  CWCGP_END(5);
#else 
  cynw_wait_all_can_get_beh( p1, p2, p3, p4, p5 );
#endif
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6>
void cynw_wait_all_can_get_pin( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 )
{
#if STRATUS_HLS
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get");
  CWCGP_START(1);
  CWCGP_START(2);
  CWCGP_START(3);
  CWCGP_START(4);
  CWCGP_START(5);
  CWCGP_START(6);
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_all_can_get");
    wait();
  } while (   !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get() 
	|| !p5.nb_can_get() || !p6.nb_can_get() );
  CWCGP_END(1);
  CWCGP_END(2);
  CWCGP_END(3);
  CWCGP_END(4);
  CWCGP_END(5);
  CWCGP_END(6);
#else 
  cynw_wait_all_can_get_beh( p1, p2, p3, p4, p5, p6 );
#endif
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7>
void cynw_wait_all_can_get_pin( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 )
{
#if STRATUS_HLS
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get");
  CWCGP_START(1);
  CWCGP_START(2);
  CWCGP_START(3);
  CWCGP_START(4);
  CWCGP_START(5);
  CWCGP_START(6);
  CWCGP_START(7);
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_all_can_get");
    wait();
  } while (   !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get() 
	|| !p5.nb_can_get() || !p6.nb_can_get() || !p7.nb_can_get() );
  CWCGP_END(1);
  CWCGP_END(2);
  CWCGP_END(3);
  CWCGP_END(4);
  CWCGP_END(5);
  CWCGP_END(6);
  CWCGP_END(7);
#else 
  cynw_wait_all_can_get_beh( p1, p2, p3, p4, p5, p6, p7 );
#endif
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8>
void cynw_wait_all_can_get_pin( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 )
{
#if STRATUS_HLS
  HLS_DEFINE_PROTOCOL("cynw_wait_all_can_get");
  CWCGP_START(1);
  CWCGP_START(2);
  CWCGP_START(3);
  CWCGP_START(4);
  CWCGP_START(5);
  CWCGP_START(6);
  CWCGP_START(7);
  CWCGP_START(8);
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_all_can_get");
    wait();
  } while (   !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get() 
	|| !p5.nb_can_get() || !p6.nb_can_get() || !p7.nb_can_get() || !p8.nb_can_get() );
  CWCGP_END(1);
  CWCGP_END(2);
  CWCGP_END(3);
  CWCGP_END(4);
  CWCGP_END(5);
  CWCGP_END(6);
  CWCGP_END(7);
  CWCGP_END(8);
#else 
  cynw_wait_all_can_get_beh( p1, p2, p3, p4, p5, p6, p7, p8 );
#endif
}

template <class CYN_T1>
void cynw_wait_all_can_get( cynw_p2p_in<CYN_T1,CYN::PIN>& p1 )
{
  cynw_wait_all_can_get_pin( p1 );
}

//
// Overloads of cynw_wait_all_can_get() for cynw_p2p_base_in<>.
//
template <class CYN_T1>
void cynw_wait_all_can_get( cynw_p2p_base_in<CYN_T1,CYN::PIN>& p1 )
{
  cynw_wait_all_can_get_pin( p1 );
}


//
// cynw_wait_any_can_get()
//
// This function waits until a value is available on at least one of the inputs
// it's given.  There are separate TLM and PIN versions, each of which is used
// in the same way.
// 
// After cynw_wait_any_can_get() returns, the following functions can be called 
// on the metaports:
//
//    bool nb_can_get()   : Returns true if a value is available to be read.
//    bool nb_get(val&)   : Gets an available value, unblocks the channel, and returns 
//                          true if a value was available.
//
// Note that nb_get(), not get(), must be used to retrieve the first value
// after cynw_wait_any_can_get().  After the first value is retrieved with
// nb_get(), get() may be used, or another call to cynw_wait_any_can_get() can
// be made. Also note that using nb_get() to check status has the side-effect
// of unblocking the channel.
//

// 
// The PIN version of cynw_wait_any_can_get() will always take at least one clock
// cycle to execute.
//

#define CWACG_CPP_START(i) \
  p##i.set_state( CYNW_SET_USE_STALL_REG, true); \
  p##i.get_start( ready[i-1] )

#define CWACG_CPP_END(i) \
  p##i.latch_value( !ready[i-1] && new_ready[i-1] ); \
  p##i.get_end()

template <class CYN_C1>
sc_uint<1> cynw_wait_any_can_get_pin( CYN_C1& p1 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_any_can_get_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<1> ready = p1.nb_can_get();
  CWACG_CPP_START(1);
  p1.set_state( CYNW_SET_BLOCKING, true);

  // Wait until a value becomes available.
  do {
    CYNW_P2P_STALL_LOOPS("cynw_wait_any_can_get");
    wait();
  } while ( !p1.nb_can_get() );

  sc_uint<1> new_ready = p1.nb_can_get();

  // Finish the protocol.
  CWACG_CPP_END(1);

  return new_ready;
}

template <class CYN_C1, class CYN_C2>
sc_uint<2> cynw_wait_any_can_get_pin( CYN_C1& p1, CYN_C2& p2 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_any_can_get_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<2> ready = CYNW_CALL_VEC_2( p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  p1.set_state( CYNW_SET_BLOCKING, true);
  p2.set_state( CYNW_SET_BLOCKING, true);

  // Wait until a value becomes available.
  do {
    CYNW_P2P_STALL_LOOPS("cynw_wait_any_can_get");
    wait();
  } while ( !p2.nb_can_get() && !p1.nb_can_get() );

  sc_uint<2> new_ready = CYNW_CALL_VEC_2( p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3>
sc_uint<3> cynw_wait_any_can_get_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_any_can_get_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<3> ready = CYNW_CALL_VEC_3( p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);
  p1.set_state( CYNW_SET_BLOCKING, true);
  p2.set_state( CYNW_SET_BLOCKING, true);
  p3.set_state( CYNW_SET_BLOCKING, true);

  // Wait until a value becomes available.
  do {
    CYNW_P2P_STALL_LOOPS("cynw_wait_any_can_get");
    wait();
  } while ( !p3.nb_can_get() && !p2.nb_can_get() && !p1.nb_can_get() );

  sc_uint<3> new_ready = CYNW_CALL_VEC_3( p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4>
sc_uint<4> cynw_wait_any_can_get_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_any_can_get_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<4> ready = CYNW_CALL_VEC_4( p4,p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);
  CWACG_CPP_START(4);
  p1.set_state( CYNW_SET_BLOCKING, true);
  p2.set_state( CYNW_SET_BLOCKING, true);
  p3.set_state( CYNW_SET_BLOCKING, true);
  p4.set_state( CYNW_SET_BLOCKING, true);

  // Wait until a value becomes available.
  do {
    CYNW_P2P_STALL_LOOPS("cynw_wait_any_can_get");
    wait();
  } while ( !p4.nb_can_get() && !p3.nb_can_get() && !p2.nb_can_get() && !p1.nb_can_get() );

  sc_uint<4> new_ready = CYNW_CALL_VEC_4( p4,p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);
  CWACG_CPP_END(4);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5>
sc_uint<5> cynw_wait_any_can_get_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_any_can_get_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<5> ready = CYNW_CALL_VEC_5( p5,p4,p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);
  CWACG_CPP_START(4);
  CWACG_CPP_START(5);
  p1.set_state( CYNW_SET_BLOCKING, true);
  p2.set_state( CYNW_SET_BLOCKING, true);
  p3.set_state( CYNW_SET_BLOCKING, true);
  p4.set_state( CYNW_SET_BLOCKING, true);
  p5.set_state( CYNW_SET_BLOCKING, true);

  // Wait until a value becomes available.
  do {
    CYNW_P2P_STALL_LOOPS("cynw_wait_any_can_get");
    wait();
  } while ( !p5.nb_can_get() && !p4.nb_can_get() && !p3.nb_can_get() && !p2.nb_can_get() && !p1.nb_can_get() );

  sc_uint<5> new_ready = CYNW_CALL_VEC_5( p5,p4,p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);
  CWACG_CPP_END(4);
  CWACG_CPP_END(5);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5, class CYN_C6>
sc_uint<6> cynw_wait_any_can_get_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5, CYN_C6& p6 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_any_can_get_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<6> ready = CYNW_CALL_VEC_6( p6,p5,p4,p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);
  CWACG_CPP_START(4);
  CWACG_CPP_START(5);
  CWACG_CPP_START(6);
  p1.set_state( CYNW_SET_BLOCKING, true);
  p2.set_state( CYNW_SET_BLOCKING, true);
  p3.set_state( CYNW_SET_BLOCKING, true);
  p4.set_state( CYNW_SET_BLOCKING, true);
  p5.set_state( CYNW_SET_BLOCKING, true);
  p6.set_state( CYNW_SET_BLOCKING, true);

  // Wait until a value becomes available.
  do {
    CYNW_P2P_STALL_LOOPS("cynw_wait_any_can_get");
    wait();
  } while ( !p6.nb_can_get() && !p5.nb_can_get() && !p4.nb_can_get() && !p3.nb_can_get() && !p2.nb_can_get() && !p1.nb_can_get() );

  sc_uint<6> new_ready = CYNW_CALL_VEC_6( p6,p5,p4,p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);
  CWACG_CPP_END(4);
  CWACG_CPP_END(5);
  CWACG_CPP_END(6);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5, class CYN_C6, class CYN_C7>
sc_uint<7> cynw_wait_any_can_get_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5, CYN_C6& p6, CYN_C7& p7 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_any_can_get_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<7> ready = CYNW_CALL_VEC_7( p7,p6,p5,p4,p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);
  CWACG_CPP_START(4);
  CWACG_CPP_START(5);
  CWACG_CPP_START(6);
  CWACG_CPP_START(7);
  p1.set_state( CYNW_SET_BLOCKING, true);
  p2.set_state( CYNW_SET_BLOCKING, true);
  p3.set_state( CYNW_SET_BLOCKING, true);
  p4.set_state( CYNW_SET_BLOCKING, true);
  p5.set_state( CYNW_SET_BLOCKING, true);
  p6.set_state( CYNW_SET_BLOCKING, true);
  p7.set_state( CYNW_SET_BLOCKING, true);

  // Wait until a value becomes available.
  do {
    CYNW_P2P_STALL_LOOPS("cynw_wait_any_can_get");
    wait();
  } while ( !p7.nb_can_get() && !p6.nb_can_get() && !p5.nb_can_get() && !p4.nb_can_get() && !p3.nb_can_get() && !p2.nb_can_get() && !p1.nb_can_get() );

  sc_uint<7> new_ready = CYNW_CALL_VEC_7( p7,p6,p5,p4,p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);
  CWACG_CPP_END(4);
  CWACG_CPP_END(5);
  CWACG_CPP_END(6);
  CWACG_CPP_END(7);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5, class CYN_C6, class CYN_C7, class CYN_C8>
sc_uint<8> cynw_wait_any_can_get_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5, CYN_C6& p6, CYN_C7& p7, CYN_C8& p8 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_any_can_get_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<8> ready = CYNW_CALL_VEC_8( p8,p7,p6,p5,p4,p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);
  CWACG_CPP_START(4);
  CWACG_CPP_START(5);
  CWACG_CPP_START(6);
  CWACG_CPP_START(7);
  CWACG_CPP_START(8);
  p1.set_state( CYNW_SET_BLOCKING, true);
  p2.set_state( CYNW_SET_BLOCKING, true);
  p3.set_state( CYNW_SET_BLOCKING, true);
  p4.set_state( CYNW_SET_BLOCKING, true);
  p5.set_state( CYNW_SET_BLOCKING, true);
  p6.set_state( CYNW_SET_BLOCKING, true);
  p7.set_state( CYNW_SET_BLOCKING, true);
  p8.set_state( CYNW_SET_BLOCKING, true);

  // Wait until a value becomes available.
  do {
    CYNW_P2P_STALL_LOOPS("cynw_wait_any_can_get");
    wait();
  } while ( !p8.nb_can_get() && !p7.nb_can_get() && !p6.nb_can_get() && !p5.nb_can_get() && !p4.nb_can_get() && !p3.nb_can_get() && !p2.nb_can_get() && !p1.nb_can_get() );

  sc_uint<8> new_ready = CYNW_CALL_VEC_8( p8,p7,p6,p5,p4,p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);
  CWACG_CPP_END(4);
  CWACG_CPP_END(5);
  CWACG_CPP_END(6);
  CWACG_CPP_END(7);
  CWACG_CPP_END(8);

  return new_ready;
}

template <class CYN_T1>
sc_uint<1> cynw_wait_any_can_get( cynw_p2p_in<CYN_T1,CYN::PIN>& p1 )
{
  return cynw_wait_any_can_get_pin( p1 );
}


//
// Overloads of cynw_wait_any_can_get() for cynw_p2p_base_in<>.
//
template <class CYN_T1>
sc_uint<1> cynw_wait_any_can_get( cynw_p2p_base_in<CYN_T1,CYN::PIN>& p1 )
{
  return cynw_wait_any_can_get_pin( p1 );
}

//
// The TLM version of wait_for_any_can_get() may return immediately if there are values
// available, but will block until at least one value is present.
//
template <class CYN_T1>
sc_uint<1> cynw_wait_any_can_get_tlm( CYN_T1& p1 )
{
  cynw_wait_while_cond ( !p1.nb_can_get() , 
			 p1.ok_to_get() );

  return p1.nb_can_get();
}

template <class CYN_T1, class CYN_T2>
sc_uint<2> cynw_wait_any_can_get_tlm( CYN_T1& p1, CYN_T2& p2 )
{
  cynw_wait_while_cond ( !p1.nb_can_get() && !p2.nb_can_get() ,
			 p1.ok_to_get() | p2.ok_to_get() );

  return CYNW_CALL_VEC_2( p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3>
sc_uint<3> cynw_wait_any_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 )
{
  cynw_wait_while_cond ( !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() ,
			 p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() );

  return CYNW_CALL_VEC_3( p3,p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4>
sc_uint<4> cynw_wait_any_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 )
{
  cynw_wait_while_cond ( !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() && !p4.nb_can_get() ,
			 p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() );

  return CYNW_CALL_VEC_4( p4,p3,p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5>
sc_uint<5> cynw_wait_any_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 )
{
  cynw_wait_while_cond (   !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() && !p4.nb_can_get() 
			&& !p5.nb_can_get() ,
			   p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			 | p5.ok_to_get() );

  return CYNW_CALL_VEC_5( p5,p4,p3,p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6>
sc_uint<6> cynw_wait_any_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 )
{
  cynw_wait_while_cond (   !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() && !p4.nb_can_get() 
			&& !p5.nb_can_get() && !p6.nb_can_get() ,
			   p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			 | p5.ok_to_get() | p6.ok_to_get() );

  return CYNW_CALL_VEC_6( p6,p5,p4,p3,p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7>
sc_uint<7> cynw_wait_any_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 )
{
  cynw_wait_while_cond (   !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() && !p4.nb_can_get() 
			&& !p5.nb_can_get() && !p6.nb_can_get() && !p7.nb_can_get() ,
			   p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			 | p5.ok_to_get() | p6.ok_to_get() | p7.ok_to_get() );

  return CYNW_CALL_VEC_7( p7,p6,p5,p4,p3,p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8>
sc_uint<8> cynw_wait_any_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 )
{
  cynw_wait_while_cond (   !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() && !p4.nb_can_get() 
			&& !p5.nb_can_get() && !p6.nb_can_get() && !p7.nb_can_get() && !p8.nb_can_get() ,
			   p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			 | p5.ok_to_get() | p6.ok_to_get() | p7.ok_to_get() | p8.ok_to_get() );

  return CYNW_CALL_VEC_8( p8,p7,p6,p5,p4,p3,p2,p1, nb_can_get );
}

template <class CYN_T1>
sc_uint<1> cynw_wait_any_can_get( cynw_p2p_base_in<CYN_T1,CYN::TLM>& p1 )
{
  return cynw_wait_any_can_get_tlm( p1 );
}

////////////////////////////////////////////////////////////
//
// function: cynw_poll_all()
//
// summary: 
//
//  Polls all the given interfaces to see if they have a value.
//  Always waits for one cycle.
//
// details:
//
//  The cynw_poll_all() functions can be used to implement a non-blocking
//  or "soft stalled" interface to several inputs in parallel.  Each time
//  cynw_poll_all() is called, all of the interfaces given are polled to
//  see if they have a value.  cynw_poll_all() always waits for exactly
//  one clock cycle.
//
//  The return value from cynw_poll_all() is true if all inputs have a valid
//  value available.  The value for each input metaport can be retrieved
//  with a call to nb_get().  nb_get() can be called several times on the
//  same metaport in between calls to cynw_poll_all() with 'reset' set to true.
//  Repeated calls will not unblock the associated channel.  This allows
//  a soft-stall application to call nb_get() on both valid and invalid
//  inputs without additional conditions.
//
//  If the final parameter to cynw_poll_all() (named 'restart')
//  indicates whether the call constitutes an 'initial' request for 
//  values on all inputs.  If 'restart' is true, 'busy' is deasserted for
//  all inputs to request a value.  If 'restart' is false, 'busy' is only
//  deasserted for inputs that do not already have a value as indicated
//  by data_was_valid().  
//
//  cynw_poll_all() supports from 1 to 8 input metaport arguments.
//
// examples:
//
//  A typical application for cynw_poll_all() is implementation of a soft stall 
//  interface on multiple input ports that are read in parallel  For example:
//
//    bool restart = true;
//    while (1)
//    {
//        bool vld = restart = cynw_poll_all( din1, din2, restart );
//        din1.nb_get(d1);
//        din2.nb_get(d2);
//
//        q1 = d1 + d2;
//        q2 = d1 - d2;
//
//        cynw_wait_can_put( dout1, dout2 );
//        dout1.nb_put( q1, vld );
//        dout2.nb_put( q2, vld );
//    }
//
//  In this example, then 'restart' is true, a request is made on
//  both din1 and din2 by deasserting busy.  The return value from
//  cynw_poll_all() indicates whether a value is available on both inputs.
//  Note that the return value from cynw_poll_all() is used both as the second 
//  parameter to nb_put(), indicating whether outputs are valid, and as the 
//  last parameter to cynw_poll_all().  If restart is false, indicating that all values
//  are not yet valid, then cynw_poll_all() will only request a value on
//  the inputs that do not yet have a valid value.  The busy signal
//  will be asserted for all other inputs, stalling them while waiting
//  for all inputs to become valid.
//
//  When all inputs finally become available, restart and vld will be true, the
//  output values will be marked as valid, and a new request will be
//  made on all inputs.
//
//  In another kind of application, a valid output can be generated when
//  only a subset of inputs is available:
//
//
//  while (1) {
//    cynw_poll_all( din1, din2, true );
//    din1.nb_get(d1);
//    din2.nb_get(d2);
//
//    bool vld = true;
//    if ( din1.data_was_valid() && din2.data_was_valid() ) {
//      q = d1 + d2;
//    } else if ( din1.data_was_valid() ) {
//      q = d1 * 2;
//    } else if ( din2.data_was_valid() ) {
//      q = d2 * 2;
//    } else  {
//      vld = false;
//    }
//  }
//
//  dout.put( q, vld );
//
//  Here, a valid output is generated in all cases except the one
//  in which no input was valid.  Note that the 'restart' parameter
//  is always true so that a new request is made each time cynw_poll_all()
//  is called.
//
////////////////////////////////////////////////////////////

// 
// Macros uses in cynw_poll_all_pin
//

#define CYNW_CPP_START(i) \
  p##i.set_state( CYNW_SET_VALUE_WAS_READ, false); \
  p##i.get_start( ready[i-1] )

#define CYNW_CPP_END(i) \
  if (!ready[i-1] && new_ready[i-1]) \
    p##i.latch_value(); \
  p##i.get_end()


//
// pin-level version for both cynw_p2p_in and cynw_p2p_base_in.
//
template <class CYN_P1>
bool cynw_poll_all_pin( CYN_P1& p1, bool first )
{
  HLS_DEFINE_PROTOCOL("cyn_poll_all");
  sc_uint<1> ready;
  if (first) 
     ready = 0;
   else
     ready = p1.data_was_valid();

  CYNW_CPP_START(1);
  wait();

  sc_uint<2> new_ready = p1.nb_can_get();
  bool done = (new_ready == 1);
  
  // Latch the newly available values.
  CYNW_CPP_END(1);

  return done;
}

template <class CYN_P1, class CYN_P2>
bool cynw_poll_all_pin( CYN_P1& p1, CYN_P2& p2, bool first )
{
  HLS_DEFINE_PROTOCOL("cyn_poll_all");
  HLS_REMOVE_CONTROL(ON,"cynw_poll_all");


  // Either assemble the ready vector from data_was_valid() settings, 
  // or, if this is the "first" call after all were valid, reset ready.
  sc_uint<2> ready;
  if (first) 
     ready = 0;
   else
     ready = CYNW_CALL_VEC_2( p2,p1, data_was_valid );
  CYNW_CPP_START(1);
  CYNW_CPP_START(2);
  wait();
  
  sc_uint<2> new_ready = CYNW_CALL_VEC_2( p2,p1, nb_can_get );
  bool done = (new_ready == 3);
  
  // Latch the newly available values.
  CYNW_CPP_END(1);
  CYNW_CPP_END(2);

  return done;
}
template <class CYN_P1, class CYN_P2, class CYN_P3>
bool cynw_poll_all_pin( CYN_P1& p1, CYN_P2& p2, CYN_P3& p3, bool first )
{
  HLS_DEFINE_PROTOCOL("cyn_poll_all");
  HLS_REMOVE_CONTROL(ON,"cynw_poll_all");

  // Either assemble the ready vector from data_was_valid() settings, 
  // or, if this is the "first" call after all were valid, reset ready.
  sc_uint<3> ready;
  if (first) 
     ready = 0;
   else
     ready = CYNW_CALL_VEC_3( p3,p2,p1, data_was_valid );

  // Start the read, asserting busy for interfaces that are already ready.
  CYNW_CPP_START(1);
  CYNW_CPP_START(2);
  CYNW_CPP_START(3);
  wait();
  
  sc_uint<3> new_ready = CYNW_CALL_VEC_3( p3,p2,p1, nb_can_get );
  bool done = (new_ready == 7);
    
  // Latch the newly available values.
  CYNW_CPP_END(1);
  CYNW_CPP_END(2);
  CYNW_CPP_END(3);

  return done;
}

template <class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4>
bool cynw_poll_all_pin( CYN_P1& p1, CYN_P2& p2, CYN_P3& p3, CYN_P4& p4, bool first )
{
  HLS_DEFINE_PROTOCOL("cyn_poll_all");
  HLS_REMOVE_CONTROL(ON,"cynw_poll_all");

  // Either assemble the ready vector from data_was_valid() settings, 
  // or, if this is the "first" call after all were valid, reset ready.
  sc_uint<4> ready;
  if (first) 
     ready = 0;
   else
     ready = CYNW_CALL_VEC_4( p4,p3,p2,p1, data_was_valid );

  // Start the read, asserting busy for interfaces that are already ready.
  CYNW_CPP_START(1);
  CYNW_CPP_START(2);
  CYNW_CPP_START(3);
  CYNW_CPP_START(4);
  wait();
  
  sc_uint<4> new_ready = CYNW_CALL_VEC_4( p4,p3,p2,p1, nb_can_get );
  bool done = (new_ready == 15);

  // Latch the newly available values.
  CYNW_CPP_END(1);
  CYNW_CPP_END(2);
  CYNW_CPP_END(3);
  CYNW_CPP_END(4);

  return done;
}

template <class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5>
bool cynw_poll_all_pin( CYN_P1& p1, CYN_P2& p2, CYN_P3& p3, CYN_P4& p4, CYN_P5& p5, bool first )
{
  HLS_DEFINE_PROTOCOL("cyn_poll_all");
  HLS_REMOVE_CONTROL(ON,"cynw_poll_all");

  // Either assemble the ready vector from data_was_valid() settings, 
  // or, if this is the "first" call after all were valid, reset ready.
  sc_uint<5> ready;
  if (first) 
     ready = 0;
   else
     ready = CYNW_CALL_VEC_5( p5,p4,p3,p2,p1, data_was_valid );

  // Start the read, asserting busy for interfaces that are already ready.
  CYNW_CPP_START(1);
  CYNW_CPP_START(2);
  CYNW_CPP_START(3);
  CYNW_CPP_START(4);
  CYNW_CPP_START(5);
  wait();
  
  sc_uint<5> new_ready = CYNW_CALL_VEC_5( p5,p4,p3,p2,p1, nb_can_get );
  bool done = (new_ready == 31);

  // Latch the newly available values.
  CYNW_CPP_END(1);
  CYNW_CPP_END(2);
  CYNW_CPP_END(3);
  CYNW_CPP_END(4);
  CYNW_CPP_END(5);

  return done;
}

template <class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5, class CYN_P6>
bool cynw_poll_all_pin( CYN_P1& p1, CYN_P2& p2, CYN_P3& p3, CYN_P4& p4, CYN_P5& p5, CYN_P6& p6, bool first )
{
  HLS_DEFINE_PROTOCOL("cyn_poll_all");
  HLS_REMOVE_CONTROL(ON,"cynw_poll_all");

  // Either assemble the ready vector from data_was_valid() settings, 
  // or, if this is the "first" call after all were valid, reset ready.
  sc_uint<6> ready;
  if (first) 
     ready = 0;
   else
     ready = CYNW_CALL_VEC_6( p6,p5,p4,p3,p2,p1, data_was_valid );

  // Start the read, asserting busy for interfaces that are already ready.
  CYNW_CPP_START(1);
  CYNW_CPP_START(2);
  CYNW_CPP_START(3);
  CYNW_CPP_START(4);
  CYNW_CPP_START(5);
  CYNW_CPP_START(6);
  wait();
  
  sc_uint<6> new_ready = CYNW_CALL_VEC_6( p6,p5,p4,p3,p2,p1, nb_can_get );
  bool done = (new_ready == 63);

  // Latch the newly available values.
  CYNW_CPP_END(1);
  CYNW_CPP_END(2);
  CYNW_CPP_END(3);
  CYNW_CPP_END(4);
  CYNW_CPP_END(5);
  CYNW_CPP_END(6);

  return done;
}

template <class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5, class CYN_P6, class CYN_P7>
bool cynw_poll_all_pin( CYN_P1& p1, CYN_P2& p2, CYN_P3& p3, CYN_P4& p4, CYN_P5& p5, CYN_P6& p6, CYN_P7& p7, bool first )
{
  HLS_DEFINE_PROTOCOL("cyn_poll_all");
  HLS_REMOVE_CONTROL(ON,"cynw_poll_all");

  // Either assemble the ready vector from data_was_valid() settings, 
  // or, if this is the "first" call after all were valid, reset ready.
  sc_uint<7> ready;
  if (first) 
     ready = 0;
   else
     ready = CYNW_CALL_VEC_7( p7,p6,p5,p4,p3,p2,p1, data_was_valid );

  // Start the read, asserting busy for interfaces that are already ready.
  CYNW_CPP_START(1);
  CYNW_CPP_START(2);
  CYNW_CPP_START(3);
  CYNW_CPP_START(4);
  CYNW_CPP_START(5);
  CYNW_CPP_START(6);
  CYNW_CPP_START(7);
  wait();
  
  sc_uint<7> new_ready = CYNW_CALL_VEC_7( p7,p6,p5,p4,p3,p2,p1, nb_can_get );
  bool done = (new_ready == 127);

  // Latch the newly available values.
  CYNW_CPP_END(1);
  CYNW_CPP_END(2);
  CYNW_CPP_END(3);
  CYNW_CPP_END(4);
  CYNW_CPP_END(5);
  CYNW_CPP_END(6);
  CYNW_CPP_END(7);

  return done;
}

template <class CYN_P1, class CYN_P2, class CYN_P3, class CYN_P4, class CYN_P5, class CYN_P6, class CYN_P7, class CYN_P8>
bool cynw_poll_all_pin( CYN_P1& p1, CYN_P2& p2, CYN_P3& p3, CYN_P4& p4, CYN_P5& p5, CYN_P6& p6, CYN_P7& p7, CYN_P8& p8, bool first )
{
  HLS_DEFINE_PROTOCOL("cyn_poll_all");
  HLS_REMOVE_CONTROL(ON,"cynw_poll_all");

  // Either assemble the ready vector from data_was_valid() settings, 
  // or, if this is the "first" call after all were valid, reset ready.
  sc_uint<8> ready;
  if (first) 
     ready = 0;
   else
     ready = CYNW_CALL_VEC_8( p8,p7,p6,p5,p4,p3,p2,p1, data_was_valid );

  // Start the read, asserting busy for interfaces that are already ready.
  CYNW_CPP_START(1);
  CYNW_CPP_START(2);
  CYNW_CPP_START(3);
  CYNW_CPP_START(4);
  CYNW_CPP_START(5);
  CYNW_CPP_START(6);
  CYNW_CPP_START(7);
  CYNW_CPP_START(8);
  wait();
  
  sc_uint<8> new_ready = CYNW_CALL_VEC_8( p8,p7,p6,p5,p4,p3,p2,p1, nb_can_get );
  bool done = (new_ready == 255);

  // Latch the newly available values.
  CYNW_CPP_END(1);
  CYNW_CPP_END(2);
  CYNW_CPP_END(3);
  CYNW_CPP_END(4);
  CYNW_CPP_END(5);
  CYNW_CPP_END(6);
  CYNW_CPP_END(7);
  CYNW_CPP_END(8);

  return done;
}

//
// PIN versions of cynw_poll_all.
// Both cynw_p2p_in and cynw_p2p_base_in call cynw_poll_all_pin().
//
template <class CYN_T1>
bool cynw_poll_all( cynw_p2p_in<CYN_T1,CYN::PIN>& p1 , bool first )
{
  return cynw_poll_all_pin( p1, first );
}

template <class CYN_T1>
bool cynw_poll_all( cynw_p2p_base_in<CYN_T1,CYN::PIN>& p1 , bool first )
{
  return cynw_poll_all_pin( p1, first );
}

//
// TLM versions of cynw_poll_all().
//
// Waits for one of the input metaports to have a valid value.
// Returns true if all have a valid value.
//
// When called from an SC_CTHREAD, unless at least one value is
// already available, waits for one to become available.  Waiting
// will always take at least a clock cycle when called from an
// SC_CTHREAD.
//
template <class CYN_T1>
bool cynw_poll_all_tlm( CYN_T1& p1 , bool first )
{
  p1.get_start(!first);

  cynw_poll_for_cond ( !p1.nb_can_get(),
		        p1.ok_to_get() );

  p1.latch_value();

  return p1.nb_can_get();
}

template <class CYN_T1, class CYN_T2>
bool cynw_poll_all_tlm( CYN_T1& p1, CYN_T2& p2 , bool first )
{
  p1.get_start(!first);
  p2.get_start(!first);

  cynw_poll_for_cond ( !p1.nb_can_get() || !p2.nb_can_get() ,
		        p1.ok_to_get() | p2.ok_to_get() );

  p1.latch_value();
  p2.latch_value();

  return ( p1.nb_can_get() && p2.nb_can_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3>
bool cynw_poll_all_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 , bool first )
{
  p1.get_start(!first);
  p2.get_start(!first);
  p3.get_start(!first);

  cynw_poll_for_cond ( !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get(),
		        p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() );

  p1.latch_value();
  p2.latch_value();
  p3.latch_value();

  return ( p1.nb_can_get() && p2.nb_can_get() && p3.nb_can_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4>
bool cynw_poll_all_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 , bool first )
{
  p1.get_start(!first);
  p2.get_start(!first);
  p3.get_start(!first);
  p4.get_start(!first);

  cynw_poll_for_cond ( !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get(),
		        p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() );

  p1.latch_value();
  p2.latch_value();
  p3.latch_value();
  p4.latch_value();

  return ( p1.nb_can_get() && p2.nb_can_get() && p3.nb_can_get() && p4.nb_can_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5>
bool cynw_poll_all_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 , bool first )
{
  p1.get_start(!first);
  p2.get_start(!first);
  p3.get_start(!first);
  p4.get_start(!first);
  p5.get_start(!first);

  cynw_poll_for_cond (	 !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get()
		      || !p5.nb_can_get() ,
		         p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
		       | p5.ok_to_get() );

  p1.latch_value();
  p2.latch_value();
  p3.latch_value();
  p4.latch_value();
  p5.latch_value();

  return ( p1.nb_can_get() && p2.nb_can_get() && p3.nb_can_get() && p4.nb_can_get() 
	    && p5.nb_can_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6>
bool cynw_poll_all_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 , bool first )
{
  p1.get_start(!first);
  p2.get_start(!first);
  p3.get_start(!first);
  p4.get_start(!first);
  p5.get_start(!first);
  p6.get_start(!first);

  cynw_poll_for_cond (	 !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get()
		      || !p5.nb_can_get() || !p6.nb_can_get() ,
		         p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
		       | p5.ok_to_get() | p6.ok_to_get() );

  p1.latch_value();
  p2.latch_value();
  p3.latch_value();
  p4.latch_value();
  p5.latch_value();
  p6.latch_value();

  return ( p1.nb_can_get() && p2.nb_can_get() && p3.nb_can_get() && p4.nb_can_get() 
	    && p5.nb_can_get() && p6.nb_can_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7>
bool cynw_poll_all_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 , bool first )
{
  p1.get_start(!first);
  p2.get_start(!first);
  p3.get_start(!first);
  p4.get_start(!first);
  p5.get_start(!first);
  p6.get_start(!first);
  p7.get_start(!first);

  cynw_poll_for_cond (   !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get()
		      || !p5.nb_can_get() || !p6.nb_can_get() || !p7.nb_can_get() ,
		        p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
		      | p5.ok_to_get() | p6.ok_to_get() | p7.ok_to_get() );

  p1.latch_value();
  p2.latch_value();
  p3.latch_value();
  p4.latch_value();
  p5.latch_value();
  p6.latch_value();
  p7.latch_value();

  return ( p1.nb_can_get() && p2.nb_can_get() && p3.nb_can_get() && p4.nb_can_get() 
	    && p5.nb_can_get() && p6.nb_can_get() && p7.nb_can_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8>
bool cynw_poll_all_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 , bool first )
{
  p1.get_start(!first);
  p2.get_start(!first);
  p3.get_start(!first);
  p4.get_start(!first);
  p5.get_start(!first);
  p6.get_start(!first);
  p7.get_start(!first);
  p8.get_start(!first);

  cynw_poll_for_cond (   !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get()
		      || !p5.nb_can_get() || !p6.nb_can_get() || !p7.nb_can_get() || !p8.nb_can_get() ,
		        p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
		      | p5.ok_to_get() | p6.ok_to_get() | p7.ok_to_get() | p8.ok_to_get() );

  p1.latch_value();
  p2.latch_value();
  p3.latch_value();
  p4.latch_value();
  p5.latch_value();
  p6.latch_value();
  p7.latch_value();
  p8.latch_value();

  return ( p1.nb_can_get() && p2.nb_can_get() && p3.nb_can_get() && p4.nb_can_get() 
	    && p5.nb_can_get() && p6.nb_can_get() && p7.nb_can_get() && p8.nb_can_get() );
}

template <class CYN_T1>
bool cynw_poll_all( cynw_p2p_base_in<CYN_T1,CYN::TLM>& p1 , bool first )
{
  return cynw_poll_all_tlm( p1, first );
}

template <class CYN_T1, class CYN_T2>
bool cynw_poll_all( cynw_p2p_base_in<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_in<CYN_T2,CYN::TLM>& p2 , bool first )
{
  return cynw_poll_all_tlm( p1, p2, first );
}

template <class CYN_T1, class CYN_T2, class CYN_T3>
bool cynw_poll_all( cynw_p2p_base_in<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_in<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_in<CYN_T3,CYN::TLM>& p3 , bool first )
{
  return cynw_poll_all_tlm( p1, p2, p3, first );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4>
bool cynw_poll_all( cynw_p2p_base_in<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_in<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_in<CYN_T3,CYN::TLM>& p3, cynw_p2p_base_in<CYN_T4,CYN::TLM>& p4 , bool first )
{
  return cynw_poll_all_tlm( p1, p2, p3, p4, first );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5>
bool cynw_poll_all( cynw_p2p_base_in<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_in<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_in<CYN_T3,CYN::TLM>& p3, cynw_p2p_base_in<CYN_T4,CYN::TLM>& p4, cynw_p2p_base_in<CYN_T5,CYN::TLM>& p5 , bool first )
{
  return cynw_poll_all_tlm( p1, p2, p3, p4, p5, first );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6>
bool cynw_poll_all( cynw_p2p_base_in<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_in<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_in<CYN_T3,CYN::TLM>& p3, cynw_p2p_base_in<CYN_T4,CYN::TLM>& p4, cynw_p2p_base_in<CYN_T5,CYN::TLM>& p5, cynw_p2p_base_in<CYN_T6,CYN::TLM>& p6 , bool first )
{
  return cynw_poll_all_tlm( p1, p2, p3, p4, p5, p6, first );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7>
bool cynw_poll_all( cynw_p2p_base_in<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_in<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_in<CYN_T3,CYN::TLM>& p3, cynw_p2p_base_in<CYN_T4,CYN::TLM>& p4, cynw_p2p_base_in<CYN_T5,CYN::TLM>& p5, cynw_p2p_base_in<CYN_T6,CYN::TLM>& p6, cynw_p2p_base_in<CYN_T7,CYN::TLM>& p7 , bool first )
{
  return cynw_poll_all_tlm( p1, p2, p3, p4, p5, p6, p7, first );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8>
bool cynw_poll_all( cynw_p2p_base_in<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_in<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_in<CYN_T3,CYN::TLM>& p3, cynw_p2p_base_in<CYN_T4,CYN::TLM>& p4, cynw_p2p_base_in<CYN_T5,CYN::TLM>& p5, cynw_p2p_base_in<CYN_T6,CYN::TLM>& p6, cynw_p2p_base_in<CYN_T7,CYN::TLM>& p7, cynw_p2p_base_in<CYN_T8,CYN::TLM>& p8 , bool first )
{
  return cynw_poll_all_tlm( p1, p2, p3, p4, p5, p6, p7, p8, first );
}

//
// cynw_poll_any()
//
// This function checks to see if any of several cynw_p2p inputs have data that's
// ready to be read.  The function returns a bit vector that has one bit set for
// each input that can be read with nb_get().  The PIN version of cynw_poll_any()
// always waits for one cycle.
//
// Unlike cynw_poll_all(), any of the inputs that have a value available can
// have it retrieved with nb_get().  Any input that has a value available but
// that is not read with nb_get() will remain blocked.  Repeated calls to
// cynw_poll_any() will show a value still being available for un-gotten
// inputs.
// 

template <class CYN_C1>
sc_uint<1> cynw_poll_any_pin( CYN_C1& p1 )
{
  HLS_DEFINE_PROTOCOL("cynw_poll_any_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<1> ready = p1.nb_can_get();
  CWACG_CPP_START(1);

  wait();

  sc_uint<1> new_ready = p1.nb_can_get();

  // Finish the protocol.
  CWACG_CPP_END(1);

  return new_ready;
}

template <class CYN_C1, class CYN_C2>
sc_uint<2> cynw_poll_any_pin( CYN_C1& p1, CYN_C2& p2 )
{
  HLS_DEFINE_PROTOCOL("cynw_poll_any_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<2> ready = CYNW_CALL_VEC_2( p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);

  wait();

  sc_uint<2> new_ready = CYNW_CALL_VEC_2( p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3>
sc_uint<3> cynw_poll_any_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3 )
{
  HLS_DEFINE_PROTOCOL("cynw_poll_any_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<3> ready = CYNW_CALL_VEC_3( p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);

  wait();

  sc_uint<3> new_ready = CYNW_CALL_VEC_3( p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4>
sc_uint<4> cynw_poll_any_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4 )
{
  HLS_DEFINE_PROTOCOL("cynw_poll_any_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<4> ready = CYNW_CALL_VEC_4( p4,p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);
  CWACG_CPP_START(4);

  wait();

  sc_uint<4> new_ready = CYNW_CALL_VEC_4( p4,p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);
  CWACG_CPP_END(4);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5>
sc_uint<5> cynw_poll_any_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5 )
{
  HLS_DEFINE_PROTOCOL("cynw_poll_any_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<5> ready = CYNW_CALL_VEC_5( p5,p4,p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);
  CWACG_CPP_START(4);
  CWACG_CPP_START(5);

  wait();

  sc_uint<5> new_ready = CYNW_CALL_VEC_5( p5,p4,p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);
  CWACG_CPP_END(4);
  CWACG_CPP_END(5);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5, class CYN_C6>
sc_uint<6> cynw_poll_any_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5, CYN_C6& p6 )
{
  HLS_DEFINE_PROTOCOL("cynw_poll_any_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<6> ready = CYNW_CALL_VEC_6( p6,p5,p4,p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);
  CWACG_CPP_START(4);
  CWACG_CPP_START(5);
  CWACG_CPP_START(6);

  wait();

  sc_uint<6> new_ready = CYNW_CALL_VEC_6( p6,p5,p4,p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);
  CWACG_CPP_END(4);
  CWACG_CPP_END(5);
  CWACG_CPP_END(6);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5, class CYN_C6, class CYN_C7>
sc_uint<7> cynw_poll_any_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5, CYN_C6& p6, CYN_C7& p7 )
{
  HLS_DEFINE_PROTOCOL("cynw_poll_any_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<7> ready = CYNW_CALL_VEC_7( p7,p6,p5,p4,p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);
  CWACG_CPP_START(4);
  CWACG_CPP_START(5);
  CWACG_CPP_START(6);
  CWACG_CPP_START(7);

  wait();

  sc_uint<7> new_ready = CYNW_CALL_VEC_7( p7,p6,p5,p4,p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);
  CWACG_CPP_END(4);
  CWACG_CPP_END(5);
  CWACG_CPP_END(6);
  CWACG_CPP_END(7);

  return new_ready;
}

template <class CYN_C1, class CYN_C2, class CYN_C3, class CYN_C4, class CYN_C5, class CYN_C6, class CYN_C7, class CYN_C8>
sc_uint<8> cynw_poll_any_pin( CYN_C1& p1, CYN_C2& p2, CYN_C3& p3, CYN_C4& p4, CYN_C5& p5, CYN_C6& p6, CYN_C7& p7, CYN_C8& p8 )
{
  HLS_DEFINE_PROTOCOL("cynw_poll_any_pin");

  // Initiate a read on all channels that don't currently have an unread value.
  sc_uint<8> ready = CYNW_CALL_VEC_8( p8,p7,p6,p5,p4,p3,p2,p1, nb_can_get );
  CWACG_CPP_START(1);
  CWACG_CPP_START(2);
  CWACG_CPP_START(3);
  CWACG_CPP_START(4);
  CWACG_CPP_START(5);
  CWACG_CPP_START(6);
  CWACG_CPP_START(7);
  CWACG_CPP_START(8);

  wait();

  sc_uint<8> new_ready = CYNW_CALL_VEC_8( p8,p7,p6,p5,p4,p3,p2,p1, nb_can_get );

  // Finish the protocol.
  CWACG_CPP_END(1);
  CWACG_CPP_END(2);
  CWACG_CPP_END(3);
  CWACG_CPP_END(4);
  CWACG_CPP_END(5);
  CWACG_CPP_END(6);
  CWACG_CPP_END(7);
  CWACG_CPP_END(8);

  return new_ready;
}

template <class CYN_T1>
sc_uint<1> cynw_poll_any( cynw_p2p_in<CYN_T1,CYN::PIN>& p1 )
{
  return cynw_poll_any_pin( p1 );
}


//
// Overloads of cynw_poll_any() for cynw_p2p_base_in<>.
//
template <class CYN_T1>
sc_uint<1> cynw_poll_any( cynw_p2p_base_in<CYN_T1,CYN::PIN>& p1 )
{
  return cynw_poll_any_pin( p1 );
}

//
// The TLM version of wait_for_any_can_get() may return immediately if there are values
// available, but will block until at least one value is present.
//
template <class CYN_T1>
sc_uint<1> cynw_poll_any_tlm( CYN_T1& p1 )
{
  cynw_wait_if_cond( p1.last_poll_was_now() );
  p1.set_last_poll();

  cynw_wait_while_cond ( !p1.nb_can_get() , 
			  p1.ok_to_get() );

  return p1.nb_can_get();
}

template <class CYN_T1, class CYN_T2>
sc_uint<2> cynw_poll_any_tlm( CYN_T1& p1, CYN_T2& p2 )
{
  cynw_wait_if_cond( p1.last_poll_was_now() && p2.last_poll_was_now() );
  CYNW_CALL_FUNC_2( p1, p2, set_last_poll );

  cynw_wait_while_cond ( !p1.nb_can_get() && !p2.nb_can_get() ,
			  p1.ok_to_get() | p2.ok_to_get() );

  return CYNW_CALL_VEC_2( p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3>
sc_uint<3> cynw_poll_any_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 )
{
  cynw_wait_if_cond( p1.last_poll_was_now() && p2.last_poll_was_now() && p3.last_poll_was_now() );
  CYNW_CALL_FUNC_3( p1, p2, p3, set_last_poll );

  cynw_wait_while_cond ( !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() ,
			  p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() );

  return CYNW_CALL_VEC_3( p3,p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4>
sc_uint<4> cynw_poll_any_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 )
{
  cynw_wait_if_cond( p1.last_poll_was_now() && p2.last_poll_was_now() && p3.last_poll_was_now() && p4.last_poll_was_now() );
  CYNW_CALL_FUNC_4( p1, p2, p3, p4, set_last_poll );

  cynw_wait_while_cond ( !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() && !p4.nb_can_get() ,
			  p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() );

  return CYNW_CALL_VEC_4( p4,p3,p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5>
sc_uint<5> cynw_poll_any_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 )
{
  cynw_wait_if_cond( p1.last_poll_was_now() && p2.last_poll_was_now() && p3.last_poll_was_now() && p4.last_poll_was_now()
		     && p5.last_poll_was_now());
  CYNW_CALL_FUNC_5( p1, p2, p3, p4, p5, set_last_poll );

  cynw_wait_while_cond (   !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() && !p4.nb_can_get() 
			&& !p5.nb_can_get() ,
			    p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			  | p5.ok_to_get() );

  return CYNW_CALL_VEC_5( p5,p4,p3,p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6>
sc_uint<6> cynw_poll_any_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 )
{
  cynw_wait_if_cond( p1.last_poll_was_now() && p2.last_poll_was_now() && p3.last_poll_was_now() && p4.last_poll_was_now()
		     && p5.last_poll_was_now() && p6.last_poll_was_now());
  CYNW_CALL_FUNC_6( p1, p2, p3, p4, p5, p6, set_last_poll );

  cynw_wait_while_cond (   !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() && !p4.nb_can_get() 
			&& !p5.nb_can_get() && !p6.nb_can_get() ,
			    p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			  | p5.ok_to_get() | p6.ok_to_get() );

  return CYNW_CALL_VEC_6( p6,p5,p4,p3,p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7>
sc_uint<7> cynw_poll_any_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 )
{
  cynw_wait_if_cond( p1.last_poll_was_now() && p2.last_poll_was_now() && p3.last_poll_was_now() && p4.last_poll_was_now()
		     && p5.last_poll_was_now() && p6.last_poll_was_now() && p7.last_poll_was_now());
  CYNW_CALL_FUNC_7( p1, p2, p3, p4, p5, p6, p7, set_last_poll );

  cynw_wait_while_cond (   !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() && !p4.nb_can_get() 
			&& !p5.nb_can_get() && !p6.nb_can_get() && !p7.nb_can_get() ,
			    p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			  | p5.ok_to_get() | p6.ok_to_get() | p7.ok_to_get() );

  return CYNW_CALL_VEC_7( p7,p6,p5,p4,p3,p2,p1, nb_can_get );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8>
sc_uint<8> cynw_poll_any_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 )
{
  cynw_wait_if_cond( p1.last_poll_was_now() && p2.last_poll_was_now() && p3.last_poll_was_now() && p4.last_poll_was_now()
		     && p5.last_poll_was_now() && p6.last_poll_was_now() && p7.last_poll_was_now() && p8.last_poll_was_now());
  CYNW_CALL_FUNC_8( p1, p2, p3, p4, p5, p6, p7, p8, set_last_poll );

  cynw_wait_while_cond (   !p1.nb_can_get() && !p2.nb_can_get() && !p3.nb_can_get() && !p4.nb_can_get() 
			&& !p5.nb_can_get() && !p6.nb_can_get() && !p7.nb_can_get() && !p8.nb_can_get() ,
			    p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			  | p5.ok_to_get() | p6.ok_to_get() | p7.ok_to_get() | p8.ok_to_get() );

  return CYNW_CALL_VEC_8( p8,p7,p6,p5,p4,p3,p2,p1, nb_can_get );
}

template <class CYN_T1>
sc_uint<1> cynw_poll_any( cynw_p2p_base_in<CYN_T1,CYN::TLM>& p1 )
{
  return cynw_poll_any_tlm( p1 );
}


////////////////////////////////////////////////////////////
//
// class: cynw_p2p_in<T,TLM>
//
// kind: 
//
//   metaport
//
// summary: 
//
//   TLM implementation of cynw_p2p_in
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: This class is selected
//       when L=TLM.
//
// details:
//
//   This class is essentially the same as the cynw_p2p_base_in<T,TLM> 
//   class except that it derives from the cynw_stall_prop_in classes so that it 
//   can be plug compatible with a cynw_p2p_in<T,PIN> class.
//
// example:
//
//   Instantiating a metaport:
//
//     SC_MODULE(M) 
//     {
//       // Use the type name directly.
//       cynw_p2_in<T,TLM> din1;
//
//       // Get this type indirectly via typedefs in cynw_p2p<T>.
//       cynw_p2p<T,TLM>::in din2;
//
//       sc_in_clk clk;
//       sc_in<bool> rst;
//       
//
//       SC_CTOR(M) {
//         // Bindings to clk, rst, and stall which are empty, but 
//         // provide source code compatibility with cynw_p2p_in<T,PIN>
//         din1.clk_rst( clk, rst );
//         stall( din1 );
//
//         SC_CTHREAD(t,clk.pos());
//         ...
//       }
//       void t() 
//       {
//         // This reset() function does nothing, but provides compatibility
//         // with the PIN implementation.
//         din1.reset();
//         while (1) 
//         {
//           ...
//         }
//       }
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p_in<T,CYN::TLM> :
  public cynw_p2p_base_in<T,CYN::TLM>,
  public cynw_stall_prop_in
{
  public:
    typedef cynw_p2p_in<T,CYN::TLM>           this_type;
    typedef T                                 data_type;
    typedef cynw_p2p_base_in<T,CYN::TLM>    base_type;
    typedef cynw_stall_prop_in                 stall_type;
    typedef base_type                         metaport;
    typedef CYN::TLM			    p2p_level;

    cynw_p2p_in( 
	const char* name=sc_gen_unique_name("p2p_in"),
	unsigned options=0,
	double input_delay=HLS_CALC_TIMING ) 
      : base_type(name),
        stall_type(name,options),
	m_skip_read(false)
    {}
    
    // Get from the upstream fifo.
    // If we're in a stall, since there's no way to use backpressure
    // to stall the upstream module, just refuse to 'get' instead.
    T get( bool wait_until_valid=true )
    {
      if (m_skip_read)
      {
	T rslt;
	if (wait_until_valid)
	{
	  esc_report_error( esc_warning, "\n\t%s: get(true) called on cynw_p2p<T,TLM>::in while generating a stall."
	                                 "\n\tNo values are read while generating a stall, so this creates deadlock."
					 "\t\tReturning an invalid value.",
					 this->name() );
	}
	return rslt;
      } else {
	return base_type::get( wait_until_valid );
      }
    }

    // To disambiguate w.r.t. stall_type and base_type.
    bool data_was_valid()
    {
      return base_type::data_was_valid();
    }

    void set_option( unsigned o )
    {
      base_type::set_option(o);
      stall_type::set_option(o);
    }
    void clear_option( unsigned o )
    {
      base_type::clear_option(o);
      stall_type::clear_option(o);
    }
  protected:
    bool m_skip_read;
};

////////////////////////////////////////////////////////////
//
// function: cynw_wait_all_can_get()
//
// summary: 
//
//  TLM versions of cynw_wait_all_can_get().
//
// details:
//
//   This version does not insert a wait(), but rather uses
//   the ok_to_get() event for each port.
//
////////////////////////////////////////////////////////////

template <class CYN_T1>
void cynw_wait_all_can_get_tlm( CYN_T1& p1 )
{
  cynw_wait_while_cond ( !p1.nb_can_get() , 
			  p1.ok_to_get() );
}

template <class CYN_T1, class CYN_T2>
void cynw_wait_all_can_get_tlm( CYN_T1& p1, CYN_T2& p2 )
{
  cynw_wait_while_cond ( !p1.nb_can_get() || !p2.nb_can_get() ,
			  p1.ok_to_get() | p2.ok_to_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3>
void cynw_wait_all_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 )
{
  cynw_wait_while_cond ( !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() ,
			  p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4>
void cynw_wait_all_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 )
{
  cynw_wait_while_cond ( !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get() ,
			  p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5>
void cynw_wait_all_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 )
{
  cynw_wait_while_cond (   !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get() 
			|| !p5.nb_can_get() ,
			    p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			  | p5.ok_to_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6>
void cynw_wait_all_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 )
{
  cynw_wait_while_cond (   !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get() 
			|| !p5.nb_can_get() || !p6.nb_can_get() ,
			    p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			  | p5.ok_to_get() | p6.ok_to_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7>
void cynw_wait_all_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 )
{
  cynw_wait_while_cond (   !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get() 
			|| !p5.nb_can_get() || !p6.nb_can_get() || !p7.nb_can_get() ,
			    p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			  | p5.ok_to_get() | p6.ok_to_get() | p7.ok_to_get() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8>
void cynw_wait_all_can_get_tlm( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 )
{
  cynw_wait_while_cond (   !p1.nb_can_get() || !p2.nb_can_get() || !p3.nb_can_get() || !p4.nb_can_get() 
			|| !p5.nb_can_get() || !p6.nb_can_get() || !p7.nb_can_get() || !p8.nb_can_get() ,
			    p1.ok_to_get() | p2.ok_to_get() | p3.ok_to_get() | p4.ok_to_get() 
			  | p5.ok_to_get() | p6.ok_to_get() | p7.ok_to_get() | p8.ok_to_get() );
}
template <class CYN_T1>
void cynw_wait_all_can_get( cynw_p2p_base_in<CYN_T1,CYN::TLM>& p1 )
{
  cynw_wait_all_can_get_tlm( p1 );
}

////////////////////////////////////////////////////////////
//
// class: cynw_p2p_base_out<T,PIN>
//
// kind: 
//
//   metaport
//
// summary: 
//
//   Output metaport for the cynw_p2p protocol at the PIN level.
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//   cynw_p2p_base_out is an output metaport for the cynw_p2p protocol.  This
//   simple version is suitable for use in testbenches, hierarchical modules
//   and synthesizable modules.  It is synthesizable, but does not support stall
//   propagation directly to input metaports, and so may not be suitable for some 
//   pipelined applications.
//   
//   The functions in the cynw_p2p_in_if<T> interface are implemented as follows:
//
//    void put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )
//
//      Writes 'val' to the data output, and asserts the vld output unless the
//      data_is_valid parameter is 0.  (The default value of CYNW_AUTO_VLD is
//      interpreted as 'true'.)  Waits until a clock edge is seen while busy is
//      deasserted before returning.  Always waits at least one cycle.
//
//      If called from a pipelined loop, a hard stall is inferred.
//
//    void reset()
//
//      Deasserts the vld output.
//
// example:
//
//   Instantiating a metaport:
//
//     SC_MODULE(M) 
//     {
//       // Use the type name directly.
//       cynw_p2_base_out<T,PIN> dout1;
//
//       // Get this type indirectly via typedefs in cynw_p2p<T>
//       cynw_p2p<T,PIN>::base_out dout;
//
//       // Get this type indirectly and use the default L parameter of PIN.
//       cynw_p2p<T>::out dout;
//
//
//   Using the metaport to make a hierarchical connection.
//
//     typedef sc_uint<8> DT;
//
//     SC_MODULE(P) 
//     {
//       // Instantiate a submodule that has a cynw_p2p<T>::base_out 
//       submod sub1;
//
//       // Instantiate a metaport for a hierarchical connection.
//       cynw_p2p<DT>::base_out sub1_dout;
//
//       SC_CTOR(P) 
//       {
//         // Bind sub1's output to the hierarchical port.
//         sub1.dout( sub1_dout );
//       }
//
//   Writing to output metaport in a testbench
//
//     SC_MODULE(tb) 
//     {
//       cynw_p2p<DT>::out dout;
//
//       SC_CTOR(tb) 
//       {
//         SC_CTHREAD( source, clk.pos() );
//         ...
//       }
//       void source() 
//       {
//         DT vals[256];
//         get_vals_from_file(vals);
//
//         for ( int i=0; i < 256; i++ )
//         {
//           // Write the values from an array.
//           // Since calls to put() will wait for at least one cycle,
//           // it is unnecessary to add additional waits to the loop.
//           dout.put( vals[i] );
//         }
//       }
//
//   
////////////////////////////////////////////////////////////
template <class T, typename CYN_L>
class cynw_p2p_base_out 
   : public cynw_clk_rst_facade 
{
  public:
    HLS_METAPORT;

    typedef cynw_p2p_base_out<T,CYN_L>  this_type;
    typedef T                         data_type;
    typedef this_type                 metaport;

    cynw_p2p_base_out( 
	const char* name=sc_gen_unique_name("p2p_out"),
	unsigned options=0,
	double input_delay=HLS_CALC_TIMING ) 
      : busy( HLS_CAT_NAMES(name,"busy") ),
        vld( HLS_CAT_NAMES(name,"vld") ),
        data( HLS_CAT_NAMES(name,"data") ),
	m_options_base(options),
	m_input_delay(input_delay),
        m_name(sc_string(::sc_core::sc_get_curr_simcontext()->hierarchy_curr()->name()) + sc_string(".") + sc_string(name)),
        m_stream_name(sc_string("sc_main.") + m_name),
	m_tx_stream(0),
	m_parent_report(false),
	m_is_async(false),
	m_async_delay( HLS_CALC_TIMING ),
	m_warnings(0)
    {
        // Specify an input delay for busy.
        HLS_SET_INPUT_DELAY( busy, m_input_delay, "" );
	HLS_SUPPRESS_MSG_SYM( 847, busy );
    }

    //
    // Interface ports
    //
    sc_in<bool> busy;
    sc_out<bool> vld;
    sc_out< typename cynw_sc_wrap<T>::sc > data;
    
    //
    // Binding functions
    //
    template <class CYN_C>
    void bind( CYN_C& c )
    {
      cynw_mark_hierarchical_binding( &c );
      busy(c.busy);
      vld(c.vld);
      data(c.data);
    }

    template <class CYN_C>
    void operator()( CYN_C& c )
    {
      bind(c);
    }

    //
    // Makes put() and nb_put() operate asynchronously.
    //
    void set_async( double max_delay=HLS_CALC_TIMING )
    {
      m_is_async = true;
      m_async_delay = max_delay;
    }

    //
    // cynw_p2p_out_if
    //
    // This version will always wait at least once, 
    // so its useful in testbenche source threads where there are no 
    // other waits.
    //
    void put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_out_put");

      warning_check( CYN_P2P_NO_RESET_OUT_WARNING );
                        
      m_parent_report = true;
      if (data_is_valid) 
	tx_stream()->begin_put_tx(val);

      if (m_is_async) 
      {
	do { 
	  CYNW_P2P_STALL_LOOPS("put");
	  wait();
	} while (busy.read());
      }

      nb_put(val,data_is_valid);

      if (!m_is_async)
      {
	do { 
	  CYNW_P2P_STALL_LOOPS("put");
	  wait();
	} while (busy.read());
      } else {
	wait();
      }
      vld.write(0);

      if (data_is_valid)
	tx_stream()->end_put_tx();
      m_parent_report = false;
    }

    void reset()
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_out_reset");
      CYNW_P2P_SET_WARNING_DONE(CYN_P2P_NO_RESET_OUT_WARNING);
      vld = 0;
    }

    void nb_put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_out_nb_put");

      // Set the output delay for async.
      if ( m_is_async) {
	HLS_SET_OUTPUT_OPTIONS( data, ASYNC_NO_HOLD );
	HLS_SET_OUTPUT_DELAY( data, HLS_CLOCK_PERIOD-m_async_delay );
	HLS_SET_OUTPUT_OPTIONS( vld, ASYNC_HOLD );
	HLS_SET_OUTPUT_DELAY( vld, HLS_CLOCK_PERIOD-m_async_delay );
      }

      bool use_vld = (bool)data_is_valid;
      vld.write( use_vld );
      data.write( val );
      
      if (use_vld && !m_parent_report)
	tx_stream()->gen_tx(val);
    }

    bool nb_can_put()
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_out_nb_can_put");
      return !busy.read();
    }

    const sc_event& ok_to_put() const
    {
      return busy.value_changed_event();
    }

    void set_state( unsigned which, unsigned value )
    {
    }

    // Convenience operators for assigning to.
    void operator = ( const T& val ) { this_type::put(val); }

    void set_option( unsigned o )
    {
      m_options_base |= o;
    }
    void clear_option( unsigned o )
    {
      m_options_base &= ~o;
    }

    cynw_scv_token_tx_stream<T>* tx_stream()
    {
#if !STRATUS
      if (m_tx_stream == 0) {
        esc_enable_scv_logging();
        m_tx_stream = new cynw_scv_token_tx_stream<T>( m_stream_name.c_str(), true, esc_get_scv_tr_db() );
      }
      return m_tx_stream;
#else
      return 0;
#endif
    }
  public:
    unsigned m_options_base;
    double m_input_delay;
    sc_string m_name;
    sc_string m_stream_name;
    cynw_scv_token_tx_stream<T>* m_tx_stream;
    bool m_parent_report;
    bool m_is_async;
    double m_async_delay;
    unsigned m_warnings;

    void warning_check( unsigned code )
    {
#if CYNW_DO_CHECKING
      if ( CYNW_P2P_WAS_WARNING_DONE(code) )
	return;

      //
      // CYN_P2P_NO_RESET_IN_WARNING
      //
      // Generate a warning if the port is read or written without having been first
      // reset.
      //
      if (code & CYN_P2P_NO_RESET_OUT_WARNING)
      {
	esc_report_error( esc_warning, "\n\t%s: cynw_p2p_out: "
	                               "Port is written, but reset() has not been called",
				       m_name.c_str() );
      }

      CYNW_P2P_SET_WARNING_DONE(code);
#endif
    }
};

////////////////////////////////////////////////////////////
//
// class: cynw_p2p_base_out<T,TLM>
//
// kind: 
//
//   metaport
//
// summary: 
//
//   TLM implementation of cynw_p2p_base_out
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: TLM or PIN.  This class is
//       selected when L=TLM.
//
// details:
//
//   This version of cynw_p2p is either an sc_fifo_out<T>, or
//   a tlm_fifo_out<T>.
//   tlm_fifo_out<T> will be used unless CYN_NO_OSCI_TLM is defined.
//   It implements the cynw_p2p_out_if<T> as follows:
//
//    void put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )
//
//      Writes to the fifo.  Behaves the same
//      way regardless of the value of data_is_valid.
//      
//    void reset()
//
//      Does nothing.
//
// example:
//
//   Instantiating a metaport:
//
//     SC_MODULE(M) 
//     {
//       // Use the type name directly.
//       cynw_p2_base_out<T,TLM> dout1;
//
//       // Get this type indirectly via typedefs in cynw_p2p<T>
//       cynw_p2p<T,TLM>::base_out dout2;
//
//
//   This class is plug-replacible with cynw_p2p_base_out<T,PIN>, and can be
//   used in all the same contexts, so the examples shown for
//   cynw_p2p_base_out<PIN> are all applicable.
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p_base_out<T,CYN::TLM> :
  public cynw_clk_rst_facade,
  public CYN_USE_FIFO_OUT(T)
{
  public:
    HLS_METAPORT;

    typedef cynw_p2p_base_out<T,CYN::TLM> this_type;
    typedef T                               data_type;
    typedef CYN_USE_FIFO_OUT(T)             base_type;
    typedef this_type                       metaport;

    cynw_p2p_base_out( 
	const char* name=sc_gen_unique_name("p2p_out"),
	unsigned options=0,
	double input_delay=HLS_CALC_TIMING ) 
      : base_type(name),
        m_options_base(options),
        m_stream_name(sc_string("sc_main.") + sc_string(this->name())),
	m_tx_stream(0),
	m_parent_report(false),
	m_warnings(0)
    {}

    void put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )
    {
      warning_check( CYN_P2P_NO_RESET_OUT_WARNING );

      if (data_is_valid) 
      {
	m_parent_report = true;
	if (data_is_valid) 
	  tx_stream()->begin_put_tx(val);

	cynw_wait_while_cond( !nb_can_put(), ok_to_put() );
	nb_put( val, data_is_valid );

	if (data_is_valid) 
	  tx_stream()->end_put_tx();
	m_parent_report = false;
      }
    }

    void reset()
    {
      CYNW_P2P_SET_WARNING_DONE(CYN_P2P_NO_RESET_OUT_WARNING);
    }

    void set_async( double max_delay=HLS_CALC_TIMING )
    {}

    void nb_put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )
    {
      if (data_is_valid) 
      {
	if (!m_parent_report)
	  tx_stream()->end_put_tx();

	(*(CYN_USE_FIFO_OUT(T)*)this)->CYN_USE_FIFO_NB_PUT(val);
      }
    }

    bool nb_can_put()
    {
      return (*(CYN_USE_FIFO_OUT(T)*)this)->CYN_USE_FIFO_CAN_PUT();
    }

    const sc_event& ok_to_put() const
    {
      return (*(CYN_USE_FIFO_OUT(T)*)this)->CYN_USE_FIFO_OK_TO_PUT();
    }

    void set_state( unsigned which, unsigned value )
    {
    }

    // Convenience operators for assigning to.
    void operator = ( const T& val ) { this_type::put(val); }

    void set_option( unsigned o )
    {
      m_options_base |= o;
    }
    void clear_option( unsigned o )
    {
      m_options_base &= ~o;
    }
  protected:
    unsigned m_options_base;

    cynw_scv_token_tx_stream<T>* tx_stream()
    {
#if !STRATUS
      if (m_tx_stream == 0) {
        esc_enable_scv_logging();
        m_tx_stream = new cynw_scv_token_tx_stream<T>( m_stream_name.c_str(), true, esc_get_scv_tr_db() );
      }
      return m_tx_stream;
#else
      return 0;
#endif
    }

    void warning_check( unsigned code )
    {
#if CYNW_DO_CHECKING
      if ( CYNW_P2P_WAS_WARNING_DONE(code) )
	return;

      //
      // CYN_P2P_NO_RESET_IN_WARNING
      //
      // Generate a warning if the port is read or written without having been first
      // reset.
      //
      if (code & CYN_P2P_NO_RESET_OUT_WARNING)
      {
	esc_report_error( esc_warning, "\n\t%s: cynw_p2p_out: "
	                               "Port is written, but reset() has not been called",
				       base_type::name() );
      }

      CYNW_P2P_SET_WARNING_DONE(code);
#endif
    }

    sc_string m_stream_name;
    cynw_scv_token_tx_stream<T>* m_tx_stream;
    bool m_parent_report;
    unsigned m_warnings;
};

////////////////////////////////////////////////////////////
//
// class: cynw_p2p_out<T,PIN>
//
// kind: 
//
//   metaport
//
// summary: 
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//   This output metaport should ordinarily be used in preference to 
//   the cynw_p2p_base_out metaport in pipelined synthesizable modules.  It
//   can also be used in testbenches, hierarchical modules, and non-pipelined
//   synthesizable modules, but it is slightly more complex to connect.
//
//   This class supports stall propagation between itself and one or more
//   input metaports.  When bound to input metaports using the stall_prop()
//   function, the following features become available:
//
//   - The metaport's busy input is made available to a sibling input metaport
//     through the stall_port() connection as an indication that the downstream 
//     module is generating a stall.  The input metaport can use this
//     to generate a passthrough stall to the upstream module.
//
//   - The valid status of the last input read is queried through the 
//     stall_port() connection to a sibling input metaport for simple 
//     implementation of soft stall semantics.
//
//   Connection of cynw_p2p_in to an input metaport is optional.  If no such
//   binding is made, then upstream modules will be stalled whenever the design
//   is not reading the interface, including when the design is stalling.
//
//   The cynw_p2p_out_if<T> is implemented as follows:
//
//    void put( const T& value=T(), int data_is_valid=CYNW_AUTO_VLD )
//
//      The vld output will be written as follows:
//
//        If data_is_valid is left at the default value of CYNW_AUTO_VLD:
//
//          If the metaport is bound via stall_prop() to an input metaport the
//          data_was_valid() function on the input metaport will be called to
//          find the value written to the vld output.  This form can be used to
//          automate soft stall semantics.
//
//        If data_is_valid is 0:
//         
//          The vld output is written with 0.  This form can be used to explicitly
//          request the writing of a data value with vld deasserted.
//
//        If data_is_valid is any other non-zero value:
//         
//          The vld output is written with 1.
//
//      If vld is asserted, it will remain asserted until a clock edge is 
//      observed when busy is deasserted.  vld will then be deasserted unless
//      another call to put() occurs on the following cycle.
//
//      If the busy input it deasserted when put() is called, wait() will not
//      be called.  This fact better supports behavioral models for II=1 pipelines
//      because it makes it possible for the behavioral model to run with an 
//      initiation interval of 1.
//
//      The value will be held steady on the data output until a clock edge has
//      been seen with busy deasserted.
//
//      If called from a pipelined loop, a hard stall will be inferred.
//
//    void reset()
//
//      Sets the vld output to 0.
//
//   Hierarchical modules that need to pass through a cynw_p2p_in to
//   a parent parent module should use a a cynw_p2p_base_out, which is
//   accessible via a member typedef in cynw_p2p<T>.  For example: 
//   cynw_p2p<T>::base_out.
//
//   This implementation of cynw_p2p_out requires clock and reset
//   signals from the parent module.  Any of the binding functions from the
//   cynw_clk_rst class can be used.
//
// example:
//
//   Instantiating:
//
//     typedef sc_uint<8> DT;
//
//     SC_MODULE(M) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> rst;
//
//       
//       cynw_p2p<DT,PIN>::in din;
//       cynw_p2p<DT,PIN>::out dout;
//
//       SC_CTOR(M) 
//       {
//         // Bind the input and output for stall propagation.
//         din.stall_prop(dout);
//
//         // Bind clk and rst to the cynw_p2p_out.
//         dout.clk_rst( clk, rst );
//       }
//     }
//
//   Instantiating without a stall_prop() connection.
//
//     SC_MODULE(M) 
//     {
//       cynw_p2p<DT,PIN>::in din;
//       cynw_p2p<DT,PIN>::out dout;
//
//       SC_CTOR(M) 
//       {
//         // Bind clk and rst to the cynw_p2p_out.
//         dout.clk_rst( clk, rst );
//       }
//     }
//
//   Binding to a parent module's simple port:
//
//     // Submodule definition.
//     SC_MODULE(M) 
//     {
//       cynw_p2p<DT>::out dout;
//       ...
//     };
//
//     // Parent module definition.
//     SC_MODULE(P) 
//     {
//       // Hiearchical port declaration.
//       cynw_p2p<DT>::base_out dout;
//
//       // Submodule declaration.
//       M m;
//
//       SC_CTOR(P) 
//       {
//         // Binding of parent port to submodule port.
//         m.dout(dout);
//         ...
//
//   Performing a write in an unpipelined application:
//
//     SC_MODULE(M) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> rst;
//
//       cynw_p2p<DT,PIN>::in din;
//       cynw_p2p<DT,PIN>::out dout;
//
//       SC_CTOR(M) 
//       {
//         // Bind clk and rst.
//         din.clk_rst( clk, rst );
//         dout.clk_rst( clk, rst );
//
//         SC_CTHREAD( t, clk.pos() );
//         reset_signal_is( rst, 0 );
//       }
//
//       void t()
//       {
//         din.reset();
//         dout.reset();
//
//         while (1) 
//         {
//           // Read, waiting for data to be available.
//           DT ival = din.get();
//
//           // Process the value.
//           DT oval = f(ival);
//
//           // Write the value.
//           dout.put( oval );
//         }
//       }
//     };
//
//   Using a stall_prop() connection between an input and output metaport and 
//   implement an implicit soft stall.
//
//     SC_MODULE(M) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> rst;
//
//       
//       cynw_p2p<DT,PIN>::in din;
//       cynw_p2p<DT,PIN>::out dout;
//
//       SC_CTOR(M) 
//       {
//         // Bind the input and output for stall propagation.
//         din.stall_prop(dout);
//
//         // Bind clk and rst.
//         din.clk_rst( clk, rst );
//         dout.clk_rst( clk, rst );
//
//         SC_CTHREAD( t, clk.pos() );
//         reset_signal_is( rst, 0 );
//       }
//
//       void t()
//       {
//         din.reset();
//         dout.reset();
//
//         while (1) 
//         {
//           HLS_PIPELINE_LOOP(1,"pipe");
//
//           // Read, waiting for only one cycle.
//           // Data may or may not be valid.
//           DT ival = din.get(false);
//
//           // Process the value.
//           DT oval = f(ival);
//
//           // Write the value.
//           // Because of the stall_prop() connection, the output metaport will
//           // access the input metaport's data_was_valid() function to determine
//           // whether the value being written is valid, and set the vld output
//           // appropriately.
//           dout.put( oval );
//         }
//       }
//     };
//
//     An equivalent version of the pipelined loop that uses a more explicit
//     form for soft stalling:
//
//         while (1) 
//         {
//           HLS_PIPELINE_LOOP(1,"pipe");
//
//           // Read, waiting for only one cycle.
//           // Store validity in a variable.
//           DT ival = din.get(false);
//           bool was_valid = din.data_was_valid();
//
//           // Process the value.
//           DT oval = f(ival);
//
//           // Write the value, explicitly giving the valid value
//           dout.put( oval, was_valid );
//
//
////////////////////////////////////////////////////////////
template <class T, typename CYN_L>
class cynw_p2p_out
  : public sc_module,
    public cynw_p2p_base_out<T,CYN_L>,
    public cynw_clk_rst,
    public cynw_stall_prop_out,
    public cynw_hier_bind_detector
{
  public:
    SC_HAS_PROCESS(cynw_p2p_out);

    HLS_EXPOSE_PORTS( OFF, clk, rst );

    typedef cynw_p2p_out<T,CYN_L>         this_type;
    typedef T                                   data_type;
    typedef cynw_p2p_base_out<T,CYN_L>            base_type;
    typedef cynw_stall_prop_out                  stall_type;
    typedef base_type                           metaport;

    cynw_p2p_out( 
	sc_module_name in_name = sc_module_name(sc_gen_unique_name("p2p_out")),
	unsigned options=0,
	double input_delay=HLS_CALC_TIMING ) 
      : sc_module(in_name),
        base_type(in_name,options,input_delay),
        stall_type(in_name,options),
        m_req((const char*)in_name),
	m_warnings(0),
	m_last_put_time(0.0),
        m_stream_name(sc_string("sc_main.") + sc_string(this->name())),
	m_tx_stream(0)
    {
      m_req.clk_rst(*this);
      m_req.active(m_req_active);

      // Specify an input delay for busy.
      HLS_SET_INPUT_DELAY( base_type::busy, base_type::m_input_delay, "" );

      SC_METHOD(gen_vld);
      sensitive << m_unacked_req;
      sensitive << m_req_active;

      SC_METHOD(gen_unacked_req);
      sensitive << clk.pos();
      dont_initialize();
    
      SC_METHOD(gen_stalling);
      sensitive << base_type::busy;
      sensitive << base_type::vld;

      SC_METHOD(gen_out_busy);
      sensitive << base_type::busy;

      CYN_ASSUME_VALUE(m_stalling,0);
    }

    //
    // Binding functions
    //
    template <class CYN_C>
    void bind( CYN_C& c )
    {
      cynw_mark_hierarchical_binding( &c );
      busy(c.busy);
      vld(c.vld);
      data(c.data);
    }

    template <class CYN_C>
    void operator()( CYN_C& c )
    {
      bind(c);
    }

    //
    // Makes put() and nb_put() operate asynchronously.
    //
    void set_async( double max_delay=HLS_CALC_TIMING )
    {
      base_type::set_async( max_delay );
      m_req.set_async( max_delay );
    }

    //
    // cynw_p2p_out_if
    //
    void put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )
    {

      HLS_DEFINE_PROTOCOL("cynw_p2p_out_put");
      
      warning_check( CYN_P2P_NO_RESET_OUT_WARNING );
      warning_check( CYN_P2P_RESET_POLARITY_WARNING );

      bool ii1_beh = (((base_type::m_options_base & CYNW_II1_BEH) != 0 ) && (HLS_INITIATION_INTERVAL == 0) );
      bool wait_before_put = ii1_beh || base_type::m_is_async;

      this->m_parent_report = true;
      if (data_is_valid) 
	tx_stream()->begin_put_tx(val);

      if ( wait_before_put )
      {
	if ( ii1_beh )
	{
	  // II=1 behavior has been requested for the behavioral model.
	  // That requires us to use a form of wait loop that will not
	  // always cause a wait() to occur.
	  // Do not use this form in pipelined code for synthesis since it will 
	  // not infer a stall, and since it will make the output register 
	  // unsharable.

	  warning_check( CYN_P2P_OVERLAP_WARNING );
	  while (m_stalling.read()) {wait();}
	} else {
	  // Do a synthesizable stall before the put for the async case.
	  do { 
	    CYNW_P2P_STALL_LOOPS("put");
	    wait();
	  } while (m_stalling.read());
	}
      }

      nb_put(val,data_is_valid);

      if ( !wait_before_put )
      {
	// Enable sharing of the data output register.
	HLS_SET_OUTPUT_OPTIONS( base_type::data, SYNC_STALL_NO_HOLD );

	// Do a synthesizable stall after the put for the sync case.
	do { 
	  CYNW_P2P_STALL_LOOPS("put");
	  wait();
	} while (m_stalling.read());
      }

      if (data_is_valid)
	tx_stream()->end_put_tx();
      this->m_parent_report = false;
    }

    void reset()
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_out_reset");
      CYNW_P2P_SET_WARNING_DONE(CYN_P2P_NO_RESET_OUT_WARNING);

      m_req.reset();
    }

    void nb_put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD )
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_out_nb_put");
      warning_check( CYN_P2P_NO_RESET_OUT_WARNING );
      HLS_SUPPRESS_MSG_SYM( 1433, data );
      HLS_SUPPRESS_MSG_SYM( 1435, data );

      // Set the output delay for async.
      if ( base_type::m_is_async) {
	HLS_SET_OUTPUT_OPTIONS( base_type::data, ASYNC_NO_HOLD );
	HLS_SET_OUTPUT_DELAY( base_type::data, HLS_CLOCK_PERIOD-base_type::m_async_delay );
      }

      bool use_vld = (data_is_valid==CYNW_AUTO_VLD) 
                        ? stall_type::data_was_valid()
                        : (bool)data_is_valid;
                        
      if (use_vld) {
	base_type::data.write( val );
	m_req.trig();
      }
      
      if (use_vld && !this->m_parent_report)
	tx_stream()->gen_tx(val);
    }

    bool nb_can_put()
    {
      HLS_DEFINE_PROTOCOL("cynw_p2p_out_nb_can_put");
      return !m_stalling.read();
    }

    const sc_event& ok_to_put() const
    {
      return m_stalling.value_changed_event();
    }

    void set_state( unsigned which, unsigned value )
    {
    }

    // Convenience operators for assigning to.
    void operator = ( const T& val ) { this_type::put(val); }

    CYNW_CLK_RST_FUNCS

    cynw_one_shot m_req;
    sc_signal<bool> m_unacked_req;
    sc_signal<bool> m_req_active;
    sc_signal<bool> m_stalling;
    unsigned m_warnings;
    double m_last_put_time;
  protected:

    // 
    // Asynchronous SC_METHOD
    //
    void gen_vld()
    {
      if ( is_hierarchically_bound() ) 
	return;

      base_type::vld.write( m_unacked_req.read() || m_req_active.read() );
    }

    //
    // Synchronous SC_METHOD
    //
    void gen_unacked_req()
    {
      if ( rst_active() )
      {
	HLS_SET_IS_RESET_BLOCK("gen_unacked_req");
	if ( is_hierarchically_bound() ) return; 
        m_unacked_req = 0;
      } else {
	if ( is_hierarchically_bound() ) return; 
        m_unacked_req = m_stalling.read();
      }
    }

    // 
    // Asynchronous SC_METHOD
    //
    void gen_stalling()
    {
      if ( is_hierarchically_bound() ) 
	return;

      m_stalling = base_type::busy.read() && base_type::vld.read();
    }

    // 
    // Asynchronous SC_METHOD
    //
    // Required by cynw_stall_prop_out base class.
    //
    void gen_out_busy()
    {
      if ( is_hierarchically_bound() ) 
	return;

      update_out_busy( base_type::busy.read() );
    }

    void warning_check( unsigned code )
    {
#if CYNW_DO_CHECKING
      if ( CYNW_P2P_WAS_WARNING_DONE(code) )
	return;

      //
      // CYN_P2P_OVERLAP_WARNING
      //
      // This option is dangerous to use when more than one put call is made
      // in the same loop. We test for this by issuing a warning if its called
      // more than once at the same simulation time.
      //
      if (code & CYN_P2P_OVERLAP_WARNING)
      {
	if (sc_time_stamp().to_double() <= m_last_put_time)
	{
	  esc_report_error( esc_warning, "\n\t%s: put() called twice in the same timestep when CYNW_II1_BEH is set.\n"
					 "\tThis will cause output values to be lost!",
					 name() );
	}
	m_last_put_time = sc_time_stamp().to_double();
      }
      //
      // CYN_P2P_NO_RESET_OUT_WARNING
      //
      // Generate a warning if the port is read or written without having been first
      // reset.
      //
      if (code & CYN_P2P_NO_RESET_OUT_WARNING)
      {
	esc_report_error( esc_warning, "\n\t%s: cynw_p2p_out: "
	                               "Port is written, but reset() has not been called",
				       name() );
      }

      //
      // CYN_P2P_RESET_POLARITY_WARNING
      //
      // Generate a warning if the reset polarity for the cynw_clk_rst base class
      // doesn't match its current condition.  If reset() is called immediately at
      // the top of a CTHREAD, this should catch mismatches between the CTHREAD's
      // watching() value, and the polarity given to clk_rst().
      //
      if ( (code & CYN_P2P_RESET_POLARITY_WARNING) && (sc_time_stamp().to_double() > 0) )
      {
	if ( rst_active() )
	{
	  esc_report_error( esc_warning, "\n\t%s: cynw_p2p_out: "
					 "Potential reset polarity mismatch between the reset_signal_is() statement for the\n\t"
					 "SC_CTHREAD, and the reset polarity specified in the third parameter to the clk_rst() call for this metaport (which is %d)",
					 name(), (int)m_rst_active_high );
	}
      }
      
      CYNW_P2P_SET_WARNING_DONE(code);
#endif
    }

    cynw_scv_token_tx_stream<T>* tx_stream()
    {
#if !STRATUS
      if (m_tx_stream == 0) {
        esc_enable_scv_logging();
        m_tx_stream = new cynw_scv_token_tx_stream<T>( m_stream_name.c_str(), true, esc_get_scv_tr_db() );
      }
      return m_tx_stream;
#else
      return 0;
#endif
    }

    sc_string m_stream_name;
    cynw_scv_token_tx_stream<T>* m_tx_stream;
};

////////////////////////////////////////////////////////////
//
// function: cynw_wait_can_put()
//
// summary: 
//
//  Waits for several interfaces to respond true to nb_can_put().
//
// details:
//
//   CYN_The cynw_wait_can_put() function is designed to be used 
//   to wait for several interfaces to have values available.
//   CYN_The functions below implement cynw_wait_can_put() on 
//   various numbers of cynw_p2p_in<CYN_T,PIN> metaports.
//
////////////////////////////////////////////////////////////

template <class CYN_T1>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::PIN>& p1 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while ( p1.m_stalling.read() );
}

template <class CYN_T1, class CYN_T2>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_out<CYN_T2,CYN::PIN>& p2 )
{
  HLS_DEFINE_PROTOCOL("cynw_nb_can_put");
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while ( p1.m_stalling.read() || p2.m_stalling.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_out<CYN_T3,CYN::PIN>& p3 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while ( p1.m_stalling.read() || p2.m_stalling.read() || p3.m_stalling.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_out<CYN_T3,CYN::PIN>& p3, cynw_p2p_out<CYN_T4,CYN::PIN>& p4 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while ( p1.m_stalling.read() || p2.m_stalling.read() || p3.m_stalling.read() || p4.m_stalling.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_out<CYN_T3,CYN::PIN>& p3, cynw_p2p_out<CYN_T4,CYN::PIN>& p4, cynw_p2p_out<CYN_T5,CYN::PIN>& p5 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while (   p1.m_stalling.read() || p2.m_stalling.read() || p3.m_stalling.read() || p4.m_stalling.read() 
	|| p5.m_stalling.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_out<CYN_T3,CYN::PIN>& p3, cynw_p2p_out<CYN_T4,CYN::PIN>& p4, cynw_p2p_out<CYN_T5,CYN::PIN>& p5, cynw_p2p_out<CYN_T6,CYN::PIN>& p6 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while (   p1.m_stalling.read() || p2.m_stalling.read() || p3.m_stalling.read() || p4.m_stalling.read() 
	|| p5.m_stalling.read() || p6.m_stalling.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_out<CYN_T3,CYN::PIN>& p3, cynw_p2p_out<CYN_T4,CYN::PIN>& p4, cynw_p2p_out<CYN_T5,CYN::PIN>& p5, cynw_p2p_out<CYN_T6,CYN::PIN>& p6, cynw_p2p_out<CYN_T7,CYN::PIN>& p7 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while (   p1.m_stalling.read() || p2.m_stalling.read() || p3.m_stalling.read() || p4.m_stalling.read() 
	|| p5.m_stalling.read() || p6.m_stalling.read() || p7.m_stalling.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_out<CYN_T3,CYN::PIN>& p3, cynw_p2p_out<CYN_T4,CYN::PIN>& p4, cynw_p2p_out<CYN_T5,CYN::PIN>& p5, cynw_p2p_out<CYN_T6,CYN::PIN>& p6, cynw_p2p_out<CYN_T7,CYN::PIN>& p7, cynw_p2p_out<CYN_T8,CYN::PIN>& p8 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while (   p1.m_stalling.read() || p2.m_stalling.read() || p3.m_stalling.read() || p4.m_stalling.read() 
	|| p5.m_stalling.read() || p6.m_stalling.read() || p7.m_stalling.read() || p8.m_stalling.read() );
}

//
// Overloads of cynw_wait_can_put() for cynw_p2p_base_out
//

template <class CYN_T1>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::PIN>& p1 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  HLS_SET_INPUT_DELAY( p1.busy, p1.m_input_delay, "" );
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while ( p1.busy.read() );
}

template <class CYN_T1, class CYN_T2>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_base_out<CYN_T2,CYN::PIN>& p2 )
{
  HLS_DEFINE_PROTOCOL("cynw_nb_can_put");
  HLS_SET_INPUT_DELAY( p1.busy, p1.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p2.busy, p2.m_input_delay, "" );
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while ( p1.busy.read() || p2.busy.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_base_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_base_out<CYN_T3,CYN::PIN>& p3 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  HLS_SET_INPUT_DELAY( p1.busy, p1.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p2.busy, p2.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p3.busy, p3.m_input_delay, "" );
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while ( p1.busy.read() || p2.busy.read() || p3.busy.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_base_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_base_out<CYN_T3,CYN::PIN>& p3, cynw_p2p_base_out<CYN_T4,CYN::PIN>& p4 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  HLS_SET_INPUT_DELAY( p1.busy, p1.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p2.busy, p2.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p3.busy, p3.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p4.busy, p4.m_input_delay, "" );
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while ( p1.busy.read() || p2.busy.read() || p3.busy.read() || p4.busy.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_base_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_base_out<CYN_T3,CYN::PIN>& p3, cynw_p2p_base_out<CYN_T4,CYN::PIN>& p4, cynw_p2p_base_out<CYN_T5,CYN::PIN>& p5 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  HLS_SET_INPUT_DELAY( p1.busy, p1.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p2.busy, p2.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p3.busy, p3.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p4.busy, p4.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p5.busy, p5.m_input_delay, "" );
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while (   p1.busy.read() || p2.busy.read() || p3.busy.read() || p4.busy.read() 
	|| p5.busy.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_base_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_base_out<CYN_T3,CYN::PIN>& p3, cynw_p2p_base_out<CYN_T4,CYN::PIN>& p4, cynw_p2p_base_out<CYN_T5,CYN::PIN>& p5, cynw_p2p_base_out<CYN_T6,CYN::PIN>& p6 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  HLS_SET_INPUT_DELAY( p1.busy, p1.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p2.busy, p2.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p3.busy, p3.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p4.busy, p4.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p5.busy, p5.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p6.busy, p6.m_input_delay, "" );
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while (   p1.busy.read() || p2.busy.read() || p3.busy.read() || p4.busy.read() 
	|| p5.busy.read() || p6.busy.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_base_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_base_out<CYN_T3,CYN::PIN>& p3, cynw_p2p_base_out<CYN_T4,CYN::PIN>& p4, cynw_p2p_base_out<CYN_T5,CYN::PIN>& p5, cynw_p2p_base_out<CYN_T6,CYN::PIN>& p6, cynw_p2p_base_out<CYN_T7,CYN::PIN>& p7 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  HLS_SET_INPUT_DELAY( p1.busy, p1.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p2.busy, p2.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p3.busy, p3.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p4.busy, p4.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p5.busy, p5.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p6.busy, p6.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p7.busy, p7.m_input_delay, "" );
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while (   p1.busy.read() || p2.busy.read() || p3.busy.read() || p4.busy.read() 
	|| p5.busy.read() || p6.busy.read() || p7.busy.read() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::PIN>& p1, cynw_p2p_base_out<CYN_T2,CYN::PIN>& p2, cynw_p2p_base_out<CYN_T3,CYN::PIN>& p3, cynw_p2p_base_out<CYN_T4,CYN::PIN>& p4, cynw_p2p_base_out<CYN_T5,CYN::PIN>& p5, cynw_p2p_base_out<CYN_T6,CYN::PIN>& p6, cynw_p2p_base_out<CYN_T7,CYN::PIN>& p7, cynw_p2p_base_out<CYN_T8,CYN::PIN>& p8 )
{
  HLS_DEFINE_PROTOCOL("cynw_wait_can_put");
  HLS_SET_INPUT_DELAY( p1.busy, p1.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p2.busy, p2.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p3.busy, p3.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p4.busy, p4.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p5.busy, p5.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p6.busy, p6.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p7.busy, p7.m_input_delay, "" );
  HLS_SET_INPUT_DELAY( p8.busy, p8.m_input_delay, "" );
  do 
  { 
    CYNW_P2P_STALL_LOOPS("cynw_wait_can_put");
    wait();
  } while (   p1.busy.read() || p2.busy.read() || p3.busy.read() || p4.busy.read() 
	|| p5.busy.read() || p6.busy.read() || p7.busy.read() || p8.busy.read() );
}

////////////////////////////////////////////////////////////
//
// class: cynw_p2p_out<T,TLM>
//
// kind: 
//
//   metaport
//
// summary: 
//
//   TLM implementation of cynw_p2p_out
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: TLM or PIN.  This class is
//       selected when L=TLM.
//
// details:
//
//   This class is identical to the cynw_p2p_base_out<T,TLM> class except
//   that it derives from the cynw_clk_rst_facade and cynw_stall_prop_out
//   classes so that it can be plug compatible with a
//   cynw_p2p_out<T,PIN> class.
//
// example:
//
//   Instantiating a metaport:
//
//     SC_MODULE(M) 
//     {
//       // Use the type name directly.
//       cynw_p2_out<T,TLM> dout1;
//
//       // Get this type indirectly via typedefs in cynw_p2p<T>.
//       cynw_p2p<T,TLM>::out dout2;
//
//       sc_in_clk clk;
//       sc_in<bool> rst;
//       
//
//       SC_CTOR(M) {
//         // Bindings to clk, rst, and stall which are empty, but 
//         // provide source code compatibility with cynw_p2p_out<T,PIN>
//         dout1.clk_rst( clk, rst );
//         stall( dout1 );
//
//         SC_CTHREAD(t,clk.pos());
//         ...
//       }
//       void t() 
//       {
//         // This reset() function does nothing, but provides compatibility
//         // with the PIN implementation.
//         dout.reset();
//         while (1) 
//         {
//           ...
//         }
//       }
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p_out<T,CYN::TLM> :
  public cynw_p2p_base_out<T,CYN::TLM>,
  public cynw_stall_prop_out
{
  public:
    typedef cynw_p2p_out<T,CYN::TLM> this_type;
    typedef cynw_p2p_base_out<T,CYN::TLM>   base_type;
    typedef T                                 data_type;
    typedef cynw_stall_prop_out                stall_type;
    typedef base_type                         metaport;

    cynw_p2p_out( 
	const char* name=sc_gen_unique_name("p2p_out"),
	unsigned options=0,
	double input_delay=HLS_CALC_TIMING ) 
      : base_type(name),
        stall_type(name)
    {}

    // Convenience operators for assigning to.
    void operator = ( const T& val ) { base_type::put(val); }

  protected:
};

////////////////////////////////////////////////////////////
//
// function: cynw_wait_can_put()
//
// summary: 
//
//  TLM versions of cynw_wait_can_put().
//
// details:
//
//   This version does not insert a wait(), but rather uses
//   the ok_to_put() event for each port.
//
////////////////////////////////////////////////////////////

template <class CYN_T1>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::TLM>& p1 )
{
  cynw_wait_while_cond( !p1.nb_can_put(), p1.ok_to_put() ) ;
}

template <class CYN_T1, class CYN_T2>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_out<CYN_T2,CYN::TLM>& p2 )
{
  cynw_wait_while_cond ( 
    !p1.nb_can_put() || !p2.nb_can_put() ,
    p1.ok_to_put() | p2.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_out<CYN_T3,CYN::TLM>& p3 )
{
  cynw_wait_while_cond ( !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() ,
			 p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_out<CYN_T3,CYN::TLM>& p3, cynw_p2p_out<CYN_T4,CYN::TLM>& p4 )
{
  cynw_wait_while_cond ( !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() || !p4.nb_can_put() ,
			 p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() | p4.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_out<CYN_T3,CYN::TLM>& p3, cynw_p2p_out<CYN_T4,CYN::TLM>& p4, cynw_p2p_out<CYN_T5,CYN::TLM>& p5 )
{
  cynw_wait_while_cond (   !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() || !p4.nb_can_put() 
			|| !p5.nb_can_put() ,
			   p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() | p4.ok_to_put() 
			 | p5.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_out<CYN_T3,CYN::TLM>& p3, cynw_p2p_out<CYN_T4,CYN::TLM>& p4, cynw_p2p_out<CYN_T5,CYN::TLM>& p5, cynw_p2p_out<CYN_T6,CYN::TLM>& p6 )
{
  cynw_wait_while_cond (   !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() || !p4.nb_can_put() 
			|| !p5.nb_can_put() || !p6.nb_can_put() ,
			   p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() | p4.ok_to_put() 
			 | p5.ok_to_put() | p6.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_out<CYN_T3,CYN::TLM>& p3, cynw_p2p_out<CYN_T4,CYN::TLM>& p4, cynw_p2p_out<CYN_T5,CYN::TLM>& p5, cynw_p2p_out<CYN_T6,CYN::TLM>& p6, cynw_p2p_out<CYN_T7,CYN::TLM>& p7 )
{
  cynw_wait_while_cond (   !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() || !p4.nb_can_put() 
			|| !p5.nb_can_put() || !p6.nb_can_put() || !p7.nb_can_put() ,
			   p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() | p4.ok_to_put() 
			 | p5.ok_to_put() | p6.ok_to_put() | p7.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8>
void cynw_wait_can_put( cynw_p2p_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_out<CYN_T3,CYN::TLM>& p3, cynw_p2p_out<CYN_T4,CYN::TLM>& p4, cynw_p2p_out<CYN_T5,CYN::TLM>& p5, cynw_p2p_out<CYN_T6,CYN::TLM>& p6, cynw_p2p_out<CYN_T7,CYN::TLM>& p7, cynw_p2p_out<CYN_T8,CYN::TLM>& p8 )
{
  cynw_wait_while_cond (   !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() || !p4.nb_can_put() 
			|| !p5.nb_can_put() || !p6.nb_can_put() || !p7.nb_can_put() || !p8.nb_can_put() ,
			   p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() | p4.ok_to_put() 
			 | p5.ok_to_put() | p6.ok_to_put() | p7.ok_to_put() | p8.ok_to_put() );
}

template <class CYN_T1>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::TLM>& p1 )
{
  cynw_wait_while_cond ( !p1.nb_can_put() , 
			 p1.ok_to_put() );
}

template <class CYN_T1, class CYN_T2>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_out<CYN_T2,CYN::TLM>& p2 )
{
  cynw_wait_while_cond ( !p1.nb_can_put() || !p2.nb_can_put() ,
			 p1.ok_to_put() | p2.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_out<CYN_T3,CYN::TLM>& p3 )
{
  cynw_wait_while_cond ( !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() ,
			 p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_out<CYN_T3,CYN::TLM>& p3, cynw_p2p_base_out<CYN_T4,CYN::TLM>& p4 )
{
  cynw_wait_while_cond ( !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() || !p4.nb_can_put() ,
			 p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() | p4.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_out<CYN_T3,CYN::TLM>& p3, cynw_p2p_base_out<CYN_T4,CYN::TLM>& p4, cynw_p2p_base_out<CYN_T5,CYN::TLM>& p5 )
{
  cynw_wait_while_cond (   !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() || !p4.nb_can_put() 
			|| !p5.nb_can_put() ,
			   p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() | p4.ok_to_put() 
			 | p5.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_out<CYN_T3,CYN::TLM>& p3, cynw_p2p_base_out<CYN_T4,CYN::TLM>& p4, cynw_p2p_base_out<CYN_T5,CYN::TLM>& p5, cynw_p2p_base_out<CYN_T6,CYN::TLM>& p6 )
{
  cynw_wait_while_cond (   !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() || !p4.nb_can_put() 
			|| !p5.nb_can_put() || !p6.nb_can_put() ,
			   p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() | p4.ok_to_put() 
			 | p5.ok_to_put() | p6.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_out<CYN_T3,CYN::TLM>& p3, cynw_p2p_base_out<CYN_T4,CYN::TLM>& p4, cynw_p2p_base_out<CYN_T5,CYN::TLM>& p5, cynw_p2p_base_out<CYN_T6,CYN::TLM>& p6, cynw_p2p_base_out<CYN_T7,CYN::TLM>& p7 )
{
  cynw_wait_while_cond (   !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() || !p4.nb_can_put() 
			|| !p5.nb_can_put() || !p6.nb_can_put() || !p7.nb_can_put() ,
			   p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() | p4.ok_to_put() 
			 | p5.ok_to_put() | p6.ok_to_put() | p7.ok_to_put() );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8>
void cynw_wait_can_put( cynw_p2p_base_out<CYN_T1,CYN::TLM>& p1, cynw_p2p_base_out<CYN_T2,CYN::TLM>& p2, cynw_p2p_base_out<CYN_T3,CYN::TLM>& p3, cynw_p2p_base_out<CYN_T4,CYN::TLM>& p4, cynw_p2p_base_out<CYN_T5,CYN::TLM>& p5, cynw_p2p_base_out<CYN_T6,CYN::TLM>& p6, cynw_p2p_base_out<CYN_T7,CYN::TLM>& p7, cynw_p2p_base_out<CYN_T8,CYN::TLM>& p8 )
{
  cynw_wait_while_cond (   !p1.nb_can_put() || !p2.nb_can_put() || !p3.nb_can_put() || !p4.nb_can_put() 
			|| !p5.nb_can_put() || !p6.nb_can_put() || !p7.nb_can_put() || !p8.nb_can_put() ,
			   p1.ok_to_put() | p2.ok_to_put() | p3.ok_to_put() | p4.ok_to_put() 
			 | p5.ok_to_put() | p6.ok_to_put() | p7.ok_to_put() | p8.ok_to_put() );
}


////////////////////////////////////////////////////////////
//
// PIN/TLM redirectors for parallel functions.
//
// The cynw_p2p parallel access API's can support both the basic
// cynw_p2p metaport classes, and other classes that implement
// the cynw_p2p interfaces.  The algorithms for the parallel functions
// are different for TLM and PIN, so different functions must be called
// depending on whether TLM or PIN metaports are passed in.  Because
// a mix of metaport types is supported in the same call, a dispatch
// mechanism is required to cause the TLM functions to be called for
// set of TLM metaports, and the PIN functions to be called for sets
// of PIN metaports.  
// 
// To participate in this mechanism, a class must do the following:
//
// 1. Implement the cynw_p2p interface (either cynw_p2p_in_if or cynw_p2p_out_if)
//    that is required for the function.
//
// 2. Have a member typedef that identifies its level as either TLM or PIN.
//    The typedef name is "p2p_level".  For example":
//
//	template <class L=CYN::PIN>
//	class my_metaport {
//	  HLS_METAPORT;
//	  typedef L  p2p_level; 
//	  ...
//	};
//
//	template <>
//	class my_metaport<CYN::TLM> {
//	  HLS_METAPORT;
//	  typedef CYN::TLM  p2p_level; 
//	  ...
//	};
// 
////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
//
// 2-input PIN/TLM redirectors for parallel functions.
//
////////////////////////////////////////////////////////////

template <typename CYN_T1, typename CYN_L1, 
	  typename CYN_T2, typename CYN_L2>
struct cynw_p2p_parallel_2
{
  static void	    wait_all_can_get( CYN_T1& p1, CYN_T2& p2 ) {}
  static sc_uint<2> wait_any_can_get( CYN_T1& p1, CYN_T2& p2 ) { return 0; }
  static bool	    poll_all(	      CYN_T1& p1, CYN_T2& p2, bool first ) { return false; }
  static sc_uint<2> poll_any_pin(     CYN_T1& p1, CYN_T2& p2 ) { return 0; } 
};

//
// 2-input PIN redirector.
//
template <typename CYN_T1, typename CYN_T2>
struct cynw_p2p_parallel_2< CYN_T1, CYN::PIN, 
			    CYN_T2, CYN::PIN>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2 ) {
    cynw_wait_all_can_get_pin( p1, p2 );
  }
  static sc_uint<2> wait_any_can_get( CYN_T1& p1, CYN_T2& p2 ) {
    return cynw_wait_any_can_get_pin( p1, p2 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, bool first ) {
    return cynw_poll_all_pin( p1, p2, first );
  }
  static sc_uint<2> poll_any( CYN_T1& p1, CYN_T2& p2 ) {
    return cynw_poll_any_pin( p1, p2 );
  }
  static sc_uint<2> poll_any( CYN_T1 (&p)[2]  ) {
    return cynw_poll_any_pin( p[0], p[1] );
  }
};

//
// 2-input TLM redirector.
//
template <typename CYN_T1, typename CYN_T2>
struct cynw_p2p_parallel_2< CYN_T1, CYN::TLM, 
			    CYN_T2, CYN::TLM>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2 ) {
    cynw_wait_all_can_get_tlm( p1, p2 );
  }
  static sc_uint<2> wait_any_can_get( CYN_T1& p1, CYN_T2& p2 ) {
    return cynw_wait_any_can_get_tlm( p1, p2 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, bool first ) {
    return cynw_poll_all_tlm( p1, p2, first );
  }
  static sc_uint<2> poll_any( CYN_T1& p1, CYN_T2& p2 ) {
    return cynw_poll_any_tlm( p1, p2 );
  }
};

//
// 2-input parallel function overloads.
//
template <typename CYN_T1, typename CYN_T2>
inline void cynw_wait_all_can_get( CYN_T1& p1, CYN_T2& p2 ) {
  cynw_p2p_parallel_2< CYN_T1, typename CYN_T1::p2p_level, 
		       CYN_T2, typename CYN_T2::p2p_level>
		       ::wait_all_can_get( p1, p2 );
}

template <typename CYN_T1, typename CYN_T2>
inline sc_uint<2> cynw_wait_any_can_get( CYN_T1& p1, CYN_T2& p2 ) {
  return cynw_p2p_parallel_2< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level>
			      ::wait_any_can_get( p1, p2 );
}

template <typename CYN_T1, typename CYN_T2>
inline bool cynw_poll_all( CYN_T1& p1, CYN_T2& p2, bool first ) {
  return cynw_p2p_parallel_2< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level>
			      ::poll_all( p1, p2, first );
}

template <typename CYN_T1, typename CYN_T2>
inline sc_uint<2> cynw_poll_any( CYN_T1& p1, CYN_T2& p2 ) {
  return cynw_p2p_parallel_2< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level>
			      ::poll_any( p1, p2 );
}

////////////////////////////////////////////////////////////
//
// 3-input PIN/TLM redirectors for parallel functions.
//
////////////////////////////////////////////////////////////

template <typename CYN_T1, typename CYN_L1, 
	  typename CYN_T2, typename CYN_L2,
	  typename CYN_T3, typename CYN_L3>
struct cynw_p2p_parallel_3
{
  static void	    wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) {}
  static sc_uint<3> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) { return 0; }
  static bool	    poll_all(	      CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, bool first ) { return 0; }
  static sc_uint<3> poll_any_pin(     CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) { return 0; } 
};

//
// 3-input PIN redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3>
struct cynw_p2p_parallel_3< CYN_T1, CYN::PIN, 
			    CYN_T2, CYN::PIN,
			    CYN_T3, CYN::PIN>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) {
    cynw_wait_all_can_get_pin( p1, p2, p3 );
  }
  static sc_uint<3> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) {
    return cynw_wait_any_can_get_pin( p1, p2, p3 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, bool first ) {
    return cynw_poll_all_pin( p1, p2, p3, first );
  }
  static sc_uint<3> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) {
    return cynw_poll_any_pin( p1, p2, p3 );
  }
};

//
// 3-input TLM redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3>
struct cynw_p2p_parallel_3< CYN_T1, CYN::TLM, 
			    CYN_T2, CYN::TLM,
			    CYN_T3, CYN::TLM>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) {
    cynw_wait_all_can_get_tlm( p1, p2, p3 );
  }
  static sc_uint<3> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) {
    return cynw_wait_any_can_get_tlm( p1, p2, p3 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, bool first ) {
    return cynw_poll_all_tlm( p1, p2, p3, first );
  }
  static sc_uint<3> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) {
    return cynw_poll_any_tlm( p1, p2, p3 );
  }
};

//
// 3-input parallel function overloads.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3>
inline void cynw_wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) {
  cynw_p2p_parallel_3< CYN_T1, typename CYN_T1::p2p_level, 
		       CYN_T2, typename CYN_T2::p2p_level,
		       CYN_T3, typename CYN_T3::p2p_level>
		       ::wait_all_can_get( p1, p2, p3 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3>
inline sc_uint<3> cynw_wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) {
  return cynw_p2p_parallel_3< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level>
			      ::wait_any_can_get( p1, p2, p3 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3>
inline bool cynw_poll_all( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, bool first ) {
  return cynw_p2p_parallel_3< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level>
			      ::poll_all( p1, p2, p3, first );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3>
inline sc_uint<3> cynw_poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3 ) {
  return cynw_p2p_parallel_3< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level>
			      ::poll_any( p1, p2, p3 );
}

////////////////////////////////////////////////////////////
//
// 4-input PIN/TLM redirectors for parallel functions.
//
////////////////////////////////////////////////////////////

template <typename CYN_T1, typename CYN_L1, 
	  typename CYN_T2, typename CYN_L2,
	  typename CYN_T3, typename CYN_L3,
	  typename CYN_T4, typename CYN_L4>
struct cynw_p2p_parallel_4
{
  static void	    wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) {}
  static sc_uint<4> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) { return 0; }
  static bool	    poll_all(	      CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, bool first ) { return 0; }
  static sc_uint<4> poll_any_pin(     CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) { return 0; } 
};

//
// 4-input PIN redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4>
struct cynw_p2p_parallel_4< CYN_T1, CYN::PIN, 
			    CYN_T2, CYN::PIN,
			    CYN_T3, CYN::PIN,
			    CYN_T4, CYN::PIN>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) {
    cynw_wait_all_can_get_pin( p1, p2, p3, p4 );
  }
  static sc_uint<4> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) {
    return cynw_wait_any_can_get_pin( p1, p2, p3, p4 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, bool first ) {
    return cynw_poll_all_pin( p1, p2, p3, p4, first );
  }
  static sc_uint<4> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) {
    return cynw_poll_any_pin( p1, p2, p3, p4 );
  }
};

//
// 4-input TLM redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4>
struct cynw_p2p_parallel_4< CYN_T1, CYN::TLM, 
			    CYN_T2, CYN::TLM,
			    CYN_T3, CYN::TLM,
			    CYN_T4, CYN::TLM>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) {
    cynw_wait_all_can_get_tlm( p1, p2, p3, p4 );
  }
  static sc_uint<4> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) {
    return cynw_wait_any_can_get_tlm( p1, p2, p3, p4 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, bool first ) {
    return cynw_poll_all_tlm( p1, p2, p3, p4, first );
  }
  static sc_uint<4> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) {
    return cynw_poll_any_tlm( p1, p2, p3, p4 );
  }
};

//
// 4-input parallel function overloads.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4>
inline void cynw_wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) {
  cynw_p2p_parallel_4< CYN_T1, typename CYN_T1::p2p_level, 
		       CYN_T2, typename CYN_T2::p2p_level,
		       CYN_T3, typename CYN_T3::p2p_level,
		       CYN_T4, typename CYN_T4::p2p_level>
		       ::wait_all_can_get( p1, p2, p3, p4 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4>
inline sc_uint<4> cynw_wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) {
  return cynw_p2p_parallel_4< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level>
			      ::wait_any_can_get( p1, p2, p3, p4 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4>
inline bool cynw_poll_all( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, bool first ) {
  return cynw_p2p_parallel_4< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level>
			      ::poll_all( p1, p2, p3, p4, first );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4>
inline sc_uint<4> cynw_poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4 ) {
  return cynw_p2p_parallel_4< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level>
			      ::poll_any( p1, p2, p3, p4 );
}

////////////////////////////////////////////////////////////
//
// 5-input PIN/TLM redirectors for parallel functions.
//
////////////////////////////////////////////////////////////

template <typename CYN_T1, typename CYN_L1, 
	  typename CYN_T2, typename CYN_L2,
	  typename CYN_T3, typename CYN_L3,
	  typename CYN_T4, typename CYN_L4,
	  typename CYN_T5, typename CYN_L5>
struct cynw_p2p_parallel_5
{
  static void	    wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) {}
  static sc_uint<5> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) { return 0; }
  static bool	    poll_all(	      CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, bool first ) { return 0; }
  static sc_uint<5> poll_any_pin(     CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) { return 0; } 
};

//
// 5-input PIN redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5>
struct cynw_p2p_parallel_5< CYN_T1, CYN::PIN, 
			    CYN_T2, CYN::PIN,
			    CYN_T3, CYN::PIN,
			    CYN_T4, CYN::PIN,
			    CYN_T5, CYN::PIN>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) {
    cynw_wait_all_can_get_pin( p1, p2, p3, p4, p5 );
  }
  static sc_uint<5> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) {
    return cynw_wait_any_can_get_pin( p1, p2, p3, p4, p5 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, bool first ) {
    return cynw_poll_all_pin( p1, p2, p3, p4, p5, first );
  }
  static sc_uint<5> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) {
    return cynw_poll_any_pin( p1, p2, p3, p4, p5 );
  }
};

//
// 5-input TLM redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5>
struct cynw_p2p_parallel_5< CYN_T1, CYN::TLM, 
			    CYN_T2, CYN::TLM,
			    CYN_T3, CYN::TLM,
			    CYN_T4, CYN::TLM,
			    CYN_T5, CYN::TLM>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) {
    cynw_wait_all_can_get_tlm( p1, p2, p3, p4, p5 );
  }
  static sc_uint<5> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) {
    return cynw_wait_any_can_get_tlm( p1, p2, p3, p4, p5 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, bool first ) {
    return cynw_poll_all_tlm( p1, p2, p3, p4, p5, first );
  }
  static sc_uint<5> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) {
    return cynw_poll_any_tlm( p1, p2, p3, p4, p5 );
  }
};

//
// 5-input parallel function overloads.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5>
inline void cynw_wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) {
  cynw_p2p_parallel_5< CYN_T1, typename CYN_T1::p2p_level, 
		       CYN_T2, typename CYN_T2::p2p_level,
		       CYN_T3, typename CYN_T3::p2p_level,
		       CYN_T4, typename CYN_T4::p2p_level,
		       CYN_T5, typename CYN_T5::p2p_level>
		       ::wait_all_can_get( p1, p2, p3, p4, p5 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5>
inline sc_uint<5> cynw_wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) {
  return cynw_p2p_parallel_5< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level>
			      ::wait_any_can_get( p1, p2, p3, p4, p5 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5>
inline bool cynw_poll_all( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, bool first ) {
  return cynw_p2p_parallel_5< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level>
			      ::poll_all( p1, p2, p3, p4, p5, first );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5>
inline sc_uint<5> cynw_poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5 ) {
  return cynw_p2p_parallel_5< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level>
			      ::poll_any( p1, p2, p3, p4, p5 );
}

////////////////////////////////////////////////////////////
//
// 6-input PIN/TLM redirectors for parallel functions.
//
////////////////////////////////////////////////////////////

template <typename CYN_T1, typename CYN_L1, 
	  typename CYN_T2, typename CYN_L2,
	  typename CYN_T3, typename CYN_L3,
	  typename CYN_T4, typename CYN_L4,
	  typename CYN_T5, typename CYN_L5,
	  typename CYN_T6, typename CYN_L6>
struct cynw_p2p_parallel_6
{
  static void	    wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) {}
  static sc_uint<6> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) { return 0; }
  static bool	    poll_all(	      CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, bool first ) { return 0; }
  static sc_uint<6> poll_any_pin(     CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) { return 0; } 
};

//
// 6-input PIN redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6>
struct cynw_p2p_parallel_6< CYN_T1, CYN::PIN, 
			    CYN_T2, CYN::PIN,
			    CYN_T3, CYN::PIN,
			    CYN_T4, CYN::PIN,
			    CYN_T5, CYN::PIN,
			    CYN_T6, CYN::PIN>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) {
    cynw_wait_all_can_get_pin( p1, p2, p3, p4, p5, p6 );
  }
  static sc_uint<6> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) {
    return cynw_wait_any_can_get_pin( p1, p2, p3, p4, p5, p6 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, bool first ) {
    return cynw_poll_all_pin( p1, p2, p3, p4, p5, p6, first );
  }
  static sc_uint<6> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) {
    return cynw_poll_any_pin( p1, p2, p3, p4, p5, p6 );
  }
};

//
// 6-input TLM redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6>
struct cynw_p2p_parallel_6< CYN_T1, CYN::TLM, 
			    CYN_T2, CYN::TLM,
			    CYN_T3, CYN::TLM,
			    CYN_T4, CYN::TLM,
			    CYN_T5, CYN::TLM,
			    CYN_T6, CYN::TLM>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) {
    cynw_wait_all_can_get_tlm( p1, p2, p3, p4, p5, p6 );
  }
  static sc_uint<6> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) {
    return cynw_wait_any_can_get_tlm( p1, p2, p3, p4, p5, p6 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, bool first ) {
    return cynw_poll_all_tlm( p1, p2, p3, p4, p5, p6, first );
  }
  static sc_uint<6> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) {
    return cynw_poll_any_tlm( p1, p2, p3, p4, p5, p6 );
  }
};

//
// 6-input parallel function overloads.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6>
inline void cynw_wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) {
  cynw_p2p_parallel_6< CYN_T1, typename CYN_T1::p2p_level, 
		       CYN_T2, typename CYN_T2::p2p_level,
		       CYN_T3, typename CYN_T3::p2p_level,
		       CYN_T4, typename CYN_T4::p2p_level,
		       CYN_T5, typename CYN_T5::p2p_level,
		       CYN_T6, typename CYN_T6::p2p_level>
		       ::wait_all_can_get( p1, p2, p3, p4, p5, p6 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6>
inline sc_uint<6> cynw_wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) {
  return cynw_p2p_parallel_6< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level,
			      CYN_T6, typename CYN_T6::p2p_level>
			      ::wait_any_can_get( p1, p2, p3, p4, p5, p6 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6>
inline bool cynw_poll_all( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, bool first ) {
  return cynw_p2p_parallel_6< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level,
			      CYN_T6, typename CYN_T6::p2p_level>
			      ::poll_all( p1, p2, p3, p4, p5, p6, first );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6>
inline sc_uint<6> cynw_poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6 ) {
  return cynw_p2p_parallel_6< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level,
			      CYN_T6, typename CYN_T6::p2p_level>
			      ::poll_any( p1, p2, p3, p4, p5, p6 );
}

////////////////////////////////////////////////////////////
//
// 7-input PIN/TLM redirectors for parallel functions.
//
////////////////////////////////////////////////////////////

template <typename CYN_T1, typename CYN_L1, 
	  typename CYN_T2, typename CYN_L2,
	  typename CYN_T3, typename CYN_L3,
	  typename CYN_T4, typename CYN_L4,
	  typename CYN_T5, typename CYN_L5,
	  typename CYN_T6, typename CYN_L6, 
	  typename CYN_T7, typename CYN_L7>
struct cynw_p2p_parallel_7
{
  static void	    wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) {}
  static sc_uint<7> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) { return 0; }
  static bool	    poll_all(	      CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, bool first ) { return 0; }
  static sc_uint<7> poll_any_pin(     CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) { return 0; } 
};

//
// 7-input PIN redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7>
struct cynw_p2p_parallel_7< CYN_T1, CYN::PIN, 
			    CYN_T2, CYN::PIN,
			    CYN_T3, CYN::PIN,
			    CYN_T4, CYN::PIN,
			    CYN_T5, CYN::PIN,
			    CYN_T6, CYN::PIN,
			    CYN_T7, CYN::PIN>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) {
    cynw_wait_all_can_get_pin( p1, p2, p3, p4, p5, p6, p7 );
  }
  static sc_uint<7> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) {
    return cynw_wait_any_can_get_pin( p1, p2, p3, p4, p5, p6, p7 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, bool first ) {
    return cynw_poll_all_pin( p1, p2, p3, p4, p5, p6, p7, first );
  }
  static sc_uint<7> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) {
    return cynw_poll_any_pin( p1, p2, p3, p4, p5, p6, p7 );
  }
};

//
// 7-input TLM redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7>
struct cynw_p2p_parallel_7< CYN_T1, CYN::TLM, 
			    CYN_T2, CYN::TLM,
			    CYN_T3, CYN::TLM,
			    CYN_T4, CYN::TLM,
			    CYN_T5, CYN::TLM,
			    CYN_T6, CYN::TLM,
			    CYN_T7, CYN::TLM>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) {
    cynw_wait_all_can_get_tlm( p1, p2, p3, p4, p5, p6, p7 );
  }
  static sc_uint<7> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) {
    return cynw_wait_any_can_get_tlm( p1, p2, p3, p4, p5, p6, p7 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, bool first ) {
    return cynw_poll_all_tlm( p1, p2, p3, p4, p5, p6, p7, first );
  }
  static sc_uint<7> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) {
    return cynw_poll_any_tlm( p1, p2, p3, p4, p5, p6, p7 );
  }
};

//
// 7-input parallel function overloads.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7>
inline void cynw_wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) {
  cynw_p2p_parallel_7< CYN_T1, typename CYN_T1::p2p_level, 
		       CYN_T2, typename CYN_T2::p2p_level,
		       CYN_T3, typename CYN_T3::p2p_level,
		       CYN_T4, typename CYN_T4::p2p_level,
		       CYN_T5, typename CYN_T5::p2p_level,
		       CYN_T6, typename CYN_T6::p2p_level,
		       CYN_T7, typename CYN_T7::p2p_level>
		       ::wait_all_can_get( p1, p2, p3, p4, p5, p6, p7 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7>
inline sc_uint<7> cynw_wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) {
  return cynw_p2p_parallel_7< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level,
			      CYN_T6, typename CYN_T6::p2p_level, 
			      CYN_T7, typename CYN_T7::p2p_level>
			      ::wait_any_can_get( p1, p2, p3, p4, p5, p6, p7 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7>
inline bool cynw_poll_all( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, bool first ) {
  return cynw_p2p_parallel_7< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level,
			      CYN_T6, typename CYN_T6::p2p_level, 
			      CYN_T7, typename CYN_T7::p2p_level>
			      ::poll_all( p1, p2, p3, p4, p5, p6, p7, first );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7>
inline sc_uint<7> cynw_poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7 ) {
  return cynw_p2p_parallel_7< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level,
			      CYN_T6, typename CYN_T6::p2p_level,
			      CYN_T7, typename CYN_T7::p2p_level>
			      ::poll_any( p1, p2, p3, p4, p5, p6, p7 );
}

////////////////////////////////////////////////////////////
//
// 8-input PIN/TLM redirectors for parallel functions.
//
////////////////////////////////////////////////////////////

template <typename CYN_T1, typename CYN_L1, 
	  typename CYN_T2, typename CYN_L2,
	  typename CYN_T3, typename CYN_L3,
	  typename CYN_T4, typename CYN_L4,
	  typename CYN_T5, typename CYN_L5,
	  typename CYN_T6, typename CYN_L6, 
	  typename CYN_T7, typename CYN_L7, 
	  typename CYN_T8, typename CYN_L8>
struct cynw_p2p_parallel_8
{
  static void	    wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) {}
  static sc_uint<8> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) { return 0;}
  static bool	    poll_all(	      CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8, bool first ) { return true; }
  static sc_uint<8> poll_any_pin(     CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) {return 0;} 
};

//
// 8-input PIN redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7, typename CYN_T8>
struct cynw_p2p_parallel_8< CYN_T1, CYN::PIN, 
			    CYN_T2, CYN::PIN,
			    CYN_T3, CYN::PIN,
			    CYN_T4, CYN::PIN,
			    CYN_T5, CYN::PIN,
			    CYN_T6, CYN::PIN,
			    CYN_T7, CYN::PIN,
			    CYN_T8, CYN::PIN>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) {
    cynw_wait_all_can_get_pin( p1, p2, p3, p4, p5, p6, p7, p8 );
  }
  static sc_uint<8> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) {
    return cynw_wait_any_can_get_pin( p1, p2, p3, p4, p5, p6, p7, p8 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8, bool first ) {
    return cynw_poll_all_pin( p1, p2, p3, p4, p5, p6, p7, p8, first );
  }
  static sc_uint<8> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) {
    return cynw_poll_any_pin( p1, p2, p3, p4, p5, p6, p7, p8 );
  }
};

//
// 8-input TLM redirector.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7, typename CYN_T8>
struct cynw_p2p_parallel_8< CYN_T1, CYN::TLM, 
			    CYN_T2, CYN::TLM,
			    CYN_T3, CYN::TLM,
			    CYN_T4, CYN::TLM,
			    CYN_T5, CYN::TLM,
			    CYN_T6, CYN::TLM,
			    CYN_T7, CYN::TLM, 
			    CYN_T8, CYN::TLM>
{
  static void wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) {
    cynw_wait_all_can_get_tlm( p1, p2, p3, p4, p5, p6, p7, p8 );
  }
  static sc_uint<8> wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) {
    return cynw_wait_any_can_get_tlm( p1, p2, p3, p4, p5, p6, p7, p8 );
  }
  static bool poll_all(	CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8, bool first ) {
    return cynw_poll_all_tlm( p1, p2, p3, p4, p5, p6, p7, p8, first );
  }
  static sc_uint<8> poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) {
    return cynw_poll_any_tlm( p1, p2, p3, p4, p5, p6, p7, p8 );
  }
};

//
// 8-input parallel function overloads.
//
template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7, typename CYN_T8>
inline void cynw_wait_all_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) {
  cynw_p2p_parallel_8< CYN_T1, typename CYN_T1::p2p_level, 
		       CYN_T2, typename CYN_T2::p2p_level,
		       CYN_T3, typename CYN_T3::p2p_level,
		       CYN_T4, typename CYN_T4::p2p_level,
		       CYN_T5, typename CYN_T5::p2p_level,
		       CYN_T6, typename CYN_T6::p2p_level,
		       CYN_T7, typename CYN_T7::p2p_level,
		       CYN_T8, typename CYN_T8::p2p_level>
		       ::wait_all_can_get( p1, p2, p3, p4, p5, p6, p7, p8 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7, typename CYN_T8>
inline sc_uint<8> cynw_wait_any_can_get( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) {
  return cynw_p2p_parallel_8< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level,
			      CYN_T6, typename CYN_T6::p2p_level, 
			      CYN_T7, typename CYN_T7::p2p_level,
			      CYN_T8, typename CYN_T8::p2p_level>
			      ::wait_any_can_get( p1, p2, p3, p4, p5, p6, p7, p8 );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7, typename CYN_T8>
inline bool cynw_poll_all( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8, bool first ) {
  return cynw_p2p_parallel_8< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level,
			      CYN_T6, typename CYN_T6::p2p_level, 
			      CYN_T7, typename CYN_T7::p2p_level,
			      CYN_T8, typename CYN_T8::p2p_level>
			      ::poll_all( p1, p2, p3, p4, p5, p6, p7, p8, first );
}

template <typename CYN_T1, typename CYN_T2, typename CYN_T3, typename CYN_T4, typename CYN_T5, typename CYN_T6, typename CYN_T7, typename CYN_T8>
inline sc_uint<8> cynw_poll_any( CYN_T1& p1, CYN_T2& p2, CYN_T3& p3, CYN_T4& p4, CYN_T5& p5, CYN_T6& p6, CYN_T7& p7, CYN_T8& p8 ) {
  return cynw_p2p_parallel_8< CYN_T1, typename CYN_T1::p2p_level, 
			      CYN_T2, typename CYN_T2::p2p_level,
			      CYN_T3, typename CYN_T3::p2p_level,
			      CYN_T4, typename CYN_T4::p2p_level,
			      CYN_T5, typename CYN_T5::p2p_level,
			      CYN_T6, typename CYN_T6::p2p_level,
			      CYN_T7, typename CYN_T7::p2p_level,
			      CYN_T8, typename CYN_T8::p2p_level>
			      ::poll_any( p1, p2, p3, p4, p5, p6, p7, p8 );
}

////////////////////////////////////////////////////////////
//
// Array versions of cynw_wait_all_can_get, cynw_wait_any_can_get,
// cynw_poll_any, cynw_poll_all, and cynw_wait_can_put.
//
// Array size is limited to the number of inputs supported by explicit functions.
////////////////////////////////////////////////////////////

template <typename T, int N>
static void cynw_wait_all_can_get( T (&ifaces)[N] )
{
  int i0=0; int i1=1; int i2=2; int i3=3; int i4=4; int i5=5; int i6=6; int i7=7;
  switch (N) {
    case 1: 
      cynw_wait_all_can_get( 
	ifaces[i0] 
      );
      break;
    case 2: 
      cynw_wait_all_can_get( 
	ifaces[i0],
	ifaces[i1] 
      );
      break;
    case 3: 
      cynw_wait_all_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2]
      );
      break;
    case 4: 
      cynw_wait_all_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3]
      );
      break;
    case 5: 
      cynw_wait_all_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4]
      );
      break;
    case 6: 
      cynw_wait_all_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5]
      );
      break;
    case 7: 
      cynw_wait_all_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5],
	ifaces[i6]
      );
      break;
    case 8: 
      cynw_wait_all_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5],
	ifaces[i6],
	ifaces[i7]
      );
      break;
    default:
      esc_report_error( esc_error, "\n\tThe cynw_wait_all_can_get() function only accepts arrays with up to 8 members\n");
      break;
  }
}

template <typename T, int N>
static sc_uint<N> cynw_wait_any_can_get( T (&ifaces)[N] )
{
  int i0=0; int i1=1; int i2=2; int i3=3; int i4=4; int i5=5; int i6=6; int i7=7;
  switch (N) {
    case 1: 
      return cynw_wait_any_can_get( 
	ifaces[i0] 
      );
    case 2: 
      return cynw_wait_any_can_get( 
	ifaces[i0],
	ifaces[i1] 
      );
    case 3: 
      return cynw_wait_any_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2]
      );
    case 4: 
      return cynw_wait_any_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3]
      );
    case 5: 
      return cynw_wait_any_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4]
      );
    case 6: 
      return cynw_wait_any_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5]
      );
    case 7: 
      return cynw_wait_any_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5],
	ifaces[i6]
      );
    case 8: 
      return cynw_wait_any_can_get( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5],
	ifaces[i6],
	ifaces[i7]
      );
    default:
      esc_report_error( esc_error, "\n\tThe cynw_wait_any_can_get() function only accepts arrays with up to 8 members\n");
      return 0;
  }
}

template <typename T, int N>
static bool cynw_poll_all( T (&ifaces)[N], bool first )
{
  int i0=0; int i1=1; int i2=2; int i3=3; int i4=4; int i5=5; int i6=6; int i7=7;
  switch (N) {
    case 1: 
      return cynw_poll_all( 
	ifaces[i0],
	first
      );
    case 2: 
      return cynw_poll_all( 
	ifaces[i0],
	ifaces[i1],
	first
      );
    case 3: 
      return cynw_poll_all( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	first
      );
    case 4: 
      return cynw_poll_all( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	first
      );
    case 5: 
      return cynw_poll_all( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	first
      );
    case 6: 
      return cynw_poll_all( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5],
	first
      );
    case 7: 
      return cynw_poll_all( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5],
	ifaces[i6],
	first
      );
    case 8: 
      return cynw_poll_all( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5],
	ifaces[i6],
	ifaces[i7],
	first
      );
    default:
      esc_report_error( esc_error, "\n\tThe cynw_poll_all() function only accepts arrays with up to 8 members\n");
      return 0;
  }
}

template <typename T, int N>
static sc_uint<N> cynw_poll_any( T (&ifaces)[N] )
{
  int i0=0; int i1=1; int i2=2; int i3=3; int i4=4; int i5=5; int i6=6; int i7=7;
  switch (N) {
    case 1: 
      return cynw_poll_any( 
	ifaces[i0] 
      );
    case 2: 
      return cynw_poll_any( 
	ifaces[i0],
	ifaces[i1] 
      );
    case 3: 
      return cynw_poll_any( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2]
      );
    case 4: 
      return cynw_poll_any( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3]
      );
    case 5: 
      return cynw_poll_any( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4]
      );
    case 6: 
      return cynw_poll_any( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5]
      );
    case 7: 
      return cynw_poll_any( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5],
	ifaces[i6]
      );
    case 8: 
      return cynw_poll_any( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5],
	ifaces[i6],
	ifaces[i7]
      );
    default:
      esc_report_error( esc_error, "\n\tThe cynw_poll_any() function only accepts arrays with up to 8 members\n");
      return 0;
  }
}

template <typename T, int N>
static void cynw_wait_can_put( T (&ifaces)[N] )
{
  int i0=0; int i1=1; int i2=2; int i3=3; int i4=4; int i5=5; int i6=6; int i7=7;
  switch (N) {
    case 1: 
      cynw_wait_can_put( 
	ifaces[i0] 
      );
      break;
    case 2: 
      cynw_wait_can_put( 
	ifaces[i0],
	ifaces[i1] 
      );
      break;
    case 3: 
      cynw_wait_can_put( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2]
      );
      break;
    case 4: 
      cynw_wait_can_put( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3]
      );
      break;
    case 5: 
      cynw_wait_can_put( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4]
      );
      break;
    case 6: 
      cynw_wait_can_put( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5]
      );
      break;
    case 7: 
      cynw_wait_can_put( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5],
	ifaces[i6]
      );
      break;
    case 8: 
      cynw_wait_can_put( 
	ifaces[i0],
	ifaces[i1],
	ifaces[i2],
	ifaces[i3],
	ifaces[i4],
	ifaces[i5],
	ifaces[i6],
	ifaces[i7]
      );
      break;
    default:
      esc_report_error( esc_error, "\n\tThe cynw_wait_can_put() function only accepts arrays with up to 8 members\n");
      break;
  }
}

////////////////////////////////////////////////////////////
// 
// macros : 
//
//   CYNW_P2P_DIRECT_PROXY_FUNCS
//   CYNW_P2P_IN_DIRECT_PROXY_FUNCS
//   CYNW_P2P_OUT_DIRECT_PROXY_FUNCS 
//
// summary : 
//
//  Provides versions of the cynw_p2p_in and cynw_p2p_out 
//  interface functions, proxying them to member metaports
//  named input (which is a cynw_p2p_out) and output which
//  is a cynw_p2p_in).
// 
//  The reset() functionis not provided since it clashes with 
//  between cynw_p2p_in and cynw_p2_out.  Instead, reset_in()
//  and reset_out() are provided.
//
////////////////////////////////////////////////////////////
#define CYNW_P2P_IN_DIRECT_PROXY_FUNCS \
    T get( bool wait_until_valid=true ) \
    { \
      return output.get(wait_until_valid); \
    } \
    T poll( bool placeholder=false ) \
    { \
      return output.poll(placeholder); \
    } \
    bool data_was_valid() \
    { \
      return output.data_was_valid(); \
    } \
    void reset_in() \
    { \
      output.reset(); \
    } \
    bool nb_get( T& val ) \
    { \
      return output.nb_get(val); \
    } \
    bool nb_can_get() \
    { \
      return output.nb_can_get(); \
    } \
    const sc_event& ok_to_get() const \
    { \
      return output.ok_to_get(); \
    } \
    void get_start( bool busy_val=false ) \
    { \
      output.get_start(busy_val); \
    } \
    void get_end() \
    { \
      output.get_end(); \
    } \
    void set_state_in( unsigned which, unsigned value ) \
    { \
      output.set_state( which, value ); \
    } \
    void latch_value( bool do_latch=true ) \
    { \
      output.latch_value( do_latch ); \
    } \
    operator T() { return output.get(); }


#define CYNW_P2P_OUT_DIRECT_PROXY_FUNCS \
    void put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD ) \
    { \
      input.put( val, data_is_valid ); \
    } \
    void reset_out() \
    { \
      input.reset(); \
    } \
    void nb_put( const T& val=T(), int data_is_valid=CYNW_AUTO_VLD ) \
    { \
      input.nb_put( val, data_is_valid ); \
    } \
    bool nb_can_put() \
    { \
      return input.nb_can_put(); \
    } \
    void set_state_out( unsigned which, unsigned value ) \
    { \
      input.set_state( which, value ); \
    } \
    const sc_event& ok_to_put() const \
    { \
      return input.ok_to_put(); \
    } \
    void operator = ( const T& val ) { input.put(val); }

#define CYNW_P2P_DIRECT_PROXY_FUNCS \
    CYNW_P2P_IN_DIRECT_PROXY_FUNCS \
    CYNW_P2P_OUT_DIRECT_PROXY_FUNCS 


////////////////////////////////////////////////////////////
//
// struct: cynw_p2p_signals<T>
//
// kind: 
//
//   struct
//
// summary: 
//   Defines the signals used in a pin-level implementation of 
//   cynw_p2p.
//
// template parameters:
//
//   T : The data type carried on the interface.
//
template <class T>
struct cynw_p2p_signals
{
  sc_signal<bool>       busy;
  sc_signal<bool>       vld;
  sc_signal< typename cynw_sc_wrap<T>::sc >          data;

  cynw_p2p_signals( const char* name=0 )
      : busy(HLS_CAT_NAMES(name,"busy")),
        vld(HLS_CAT_NAMES(name,"vld")),
        data(HLS_CAT_NAMES(name,"data"))
    {}

};

////////////////////////////////////////////////////////////
//
// struct: cynw_p2p_export_in<T>
//
// kind: 
//
//   struct
//
// summary: 
//   Exports as an input interface the signals used in a pin-level 
//   implementation of cynw_p2p.
//
// template parameters:
//
//   T : The data type carried on the interface.
//
template <typename T, typename L=CYN::PIN>
struct cynw_p2p_export_in
{
  sc_export<sc_signal_out_if<bool> > busy;
  sc_export<sc_signal_in_if<T> >     data;
  sc_export<sc_signal_in_if<bool> >  vld;

  HLS_METAPORT;
  cynw_p2p_export_in( const char* name=sc_gen_unique_name("cynw_p2p_export_in") )
      : busy(HLS_CAT_NAMES(name,"busy")),
        data(HLS_CAT_NAMES(name,"data")),
        vld(HLS_CAT_NAMES(name,"vld"))
    {}

  template <class CYN_C>
  void bind( CYN_C& c )
  {
      busy(c.busy);
      data(c.data);
      vld(c.vld);
  }

  template <class CYN_C>
  inline void operator () ( CYN_C& c )
  {
      bind(c);
  }
};

#ifndef CYN_NO_OSCI_TLM
template <typename T>
class cynw_p2p_export_in<T,CYN::TLM> 
  : public sc_export< tlm::tlm_fifo_get_if<T> >
{
  public: 
    typedef sc_export< tlm::tlm_fifo_get_if<T> > base_type;

    cynw_p2p_export_in( const char* name=sc_gen_unique_name("cynw_p2p_export_in") )
      : base_type(name)
    {}
};
#endif

////////////////////////////////////////////////////////////
//
// struct: cynw_p2p_export_out<T,L>
//
// kind: 
//
//   struct
//
// summary: 
//   Exports as an output interface the signals used in a pin-level 
//   implementation of cynw_p2p.
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
template <typename T, typename L=CYN::PIN>
struct cynw_p2p_export_out
{
  sc_export<sc_signal_in_if<bool>  >  busy;
  sc_export<sc_signal_out_if<T>    >  data;
  sc_export<sc_signal_out_if<bool> >  vld;

  HLS_METAPORT;
  cynw_p2p_export_out( const char* name=0 )
      : busy(HLS_CAT_NAMES(name,"busy")),
        data(HLS_CAT_NAMES(name,"data")),
        vld(HLS_CAT_NAMES(name,"vld"))
    {}

  template <class CYN_C>
  void bind( CYN_C& c )
  {
      busy(c.busy);
      data(c.data);
      vld(c.vld);
  }

  template <class CYN_C>
  inline void operator () ( CYN_C& c )
  {
      bind(c);
  }

};

#ifndef CYN_NO_OSCI_TLM
template <typename T>
class cynw_p2p_export_out<T,CYN::TLM> 
  : public sc_export< tlm::tlm_fifo_put_if<T> >
{
  public: 
    typedef sc_export< tlm::tlm_fifo_put_if<T> > base_type;

    cynw_p2p_export_out( const char* name=sc_gen_unique_name("cynw_p2p_export_out") )
      : base_type(name)
    {}
};
#endif

////////////////////////////////////////////////////////////
//
// class: cynw_p2p<T,PIN>
//
// kind: 
//
//   channel
//
// summary: 
//  PIN level implementation of the cynw_p2p channel.
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//   The cynw_p2p channel implements a stallable streaming
//   data protocol.  Words of data whose type is specified by
//   the T template parameter are transfered from a writing 
//   thread to a reading thread at rates up to once per clock 
//   cycle.  The protocol has two handshake signals:
//
//     vld : asserted (active high) when the writer is driving
//           valid data.
//
//     busy : asserted (active high) when the reader is not ready
//            to read new inputs.
//
//   The protocol is intended to support stallable pipelined modules
//   with no separate stall input signal.  The busy signal acts as 
//   a downstream stall mechanism.
//
//   Details of the protocol are:
//
//     For the writer
//
//       - The writer must assert vld each time a new data value is written.
//
//       - The writer must continue to assert vld and data until a clock edge
//         is seen while busy is low.
//
//       - After busy has been seen deasserted, the writer must either deassert
//         vld, or assert a new data value.  - The writer may assert vld while
//         busy is asserted, but only if any previously written value has been
//         acknowledged with a !busy, and only if the writer continues to assert
//         vld and the data value until it is acknowledged by !busy.
//
//     For the reader
//
//        - The reader will assume that a data input is only valid when vld is
//          high at a clock edge.
//
//        - The reader must have deasserted busy before latching the data input
//          so that busy is deasserted at the clock edge where it reads the data
//          input.
//
//        - If the reader is not prepared to read a data value, it must assert
//          busy.
//
//        - The reader may assert busy while vld is deasserted provided that it
//          deasserts busy if it subsequently becomes unprepared to read the data
//          input.
//
//  A cynw_p2p channel can be bound to cynw_p2p_in and
//  cynw_p2p_out metaports, or the member signals can be connected to
//  an arbitrary module as long as it implements the interface described above. 
//
//  Member typedefs 'in' and 'out' are ordinarily used to reference the appropriate
//  type of input and output metaports for the channel.  For example, cynw_p2p<T>::base_in //  and cynw_p2p<T>::base_out 
//
// example:
//
//   In this example, the 'L' template parameter has been left at its 
//   default value of PIN which will select the cynw_p2p<T,PIN> class.
//
//   typedef sc_uint<8> DT;
//
//   // A writer module.
//   SC_MODULE(writer) 
//   {
//     cynw_p2p<DT>::out pout;
//     ...
//   };
//
//   // A reader module.
//   SC_MODULE(reader) 
//   {
//     cynw_p2p<DT>::in pin;
//     ...
//   };
//
//   // A parent module with a cynw_p2p channel connecting the writer and reader.
//   SC_MODULE(parent) 
//   {
//     writer w;
//     reader r;
//     cynw_p2p<DT> chan;
//
//     SC_CTOR(parent) 
//     {
//       r.pin(chan);
//       w.pout(chan);
//     }
//   };
//
//
////////////////////////////////////////////////////////////
template <class T, typename CYN_LIN=CYN::PIN, typename CYN_LOUT=CYN_LIN>
class cynw_p2p
  : public cynw_p2p_signals<T>
  , public cynw_clk_rst_facade
{
  public:
    typedef cynw_p2p<T,CYN_LIN,CYN_LOUT>        this_type;
    typedef cynw_p2p_signals<T>                 signals_type;
    typedef signals_type                        base_type;
    typedef cynw_p2p_export_in<T,CYN_LIN>	export_in;
    typedef cynw_p2p_export_out<T,CYN_LOUT>	export_out;
    typedef cynw_p2p_in<T,CYN_LIN>		in;
    typedef cynw_p2p_out<T,CYN_LOUT>	        out;
    typedef cynw_p2p_base_in<T,CYN_LIN>	        base_in;
    typedef cynw_p2p_base_out<T,CYN_LOUT>	base_out;
    typedef this_type                           chan;

    cynw_p2p( const char* name=sc_gen_unique_name("cynw_p2p"), 
	      int tlm_fifo_depth=CYNW_P2P_DEFAULT_TLM_FIFO_DEPTH )
      : base_type(name)
    {}
};

////////////////////////////////////////////////////////////
//
// class: cynw_p2p<T,TLM>
//
// kind: 
//
//   channel
//
// summary: 
//   TLM version of the cynw_p2p channel.
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: TLM or PIN.  This class is 
//       selected when L=TLM.
//
// details:
//   
//   This version of cynw_p2p uses either an sc_fifo<T> or a tlm_fifo<T>.
//   tlm_fifo<T> will be used unless CYN_NO_OSCI_TLM is defined.  The 'in' and
//   'out' member typedefs make it plug replacible with the with the
//   cynw_p2p<T,PIN> channel.
//
// example:
//
//   This example is the same as the example shown for cynw_p2p<T,PIN>, 
//   except the L template parameter has been given as TLM, causing this
//   class to be chosen.  Since the ::in and ::out typedefs are used to
//   specify port types, this will also serve to cause TLM-level metaports
//   to be instantiated.
//   default value of PIN which will select the cynw_p2p<T,PIN> class.
//
//     typedef sc_uint<8> DT;
//
//     // A writer module.
//     SC_MODULE(writer) 
//     {
//       cynw_p2p<DT,TLM>::out pout;
//       ...
//     };
//
//     // A reader module.
//     SC_MODULE(reader) 
//     {
//       cynw_p2p<DT,TLM>::in pin;
//       ...
//     };
//
//     // A parent module with a cynw_p2p channel connecting the writer and reader.
//     SC_MODULE(parent) 
//     {
//       writer w;
//       reader r;
//       cynw_p2p<DT,TLM> chan;
//
//       SC_CTOR(parent) 
//       {
//         r.pin(chan);
//         w.pout(chan);
//       }
//     };
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p<T,CYN::TLM,CYN::TLM>
  : public CYN_USE_FIFO_CHAN<T>
  , public cynw_clk_rst_facade
{
  public:
    
    typedef cynw_p2p<T,CYN::TLM>            this_type;
    typedef CYN_USE_FIFO_CHAN<T>            base_type;
    typedef cynw_p2p_in<T,CYN::TLM>	    in;
    typedef cynw_p2p_out<T,CYN::TLM>	    out;
    typedef cynw_p2p_base_in<T,CYN::TLM>    base_in;
    typedef cynw_p2p_base_out<T,CYN::TLM>   base_out;
#ifndef CYN_NO_OSCI_TLM
    typedef cynw_p2p_export_in<T,CYN::TLM>  export_in;
    typedef cynw_p2p_export_out<T,CYN::TLM> export_out;
#endif
    typedef this_type                       chan;

    cynw_p2p( const char* name=sc_gen_unique_name("p2p"), 
	      int tlm_fifo_depth=CYNW_P2P_DEFAULT_TLM_FIFO_DEPTH ) 
      : base_type(name,tlm_fifo_depth)
    {}
};


////////////////////////////////////////////////////////////
//
// class: cynw_p2p<T,TLM,PIN>
//
// kind: 
//
//   metaport
//
// summary: 
//   TLM to PIN adapting channel.
//
// template parameters:
//
//   T : The data type carried on the interface.
//
// details:
//
//   This channel can be bound to a writer that is TLM, and a reader
//   that is PIN. 
//
// example:
//
//   SC_MODULE(writer) {
//     cynw_p2p<DT,TLM>::out dout;
//     ...
//   };
//   
//   SC_MODULE(reader) {
//     cynw_p2p<DT,PIN>::in din;
//   };
//    
//
//   SC_MODULE(parent) {
//      writer w;
//      reader r;
//      cynw_p2p<DT,TLM,PIN> chan;
//
//      SC_CTOR(parent) {
//        writer.dout(chan.input);
//        reader.din(chan.output);
//        ...
//      }
//      ...
//    };
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p<T,CYN::TLM,CYN::PIN>
  : public cynw_p2p_out_if<T>
  , public cynw_clk_rst_facade
{
  public:
    
    typedef cynw_p2p<T,CYN::TLM,CYN::PIN>   this_type;
    typedef cynw_p2p_in<T,CYN::TLM>	    in;
    typedef cynw_p2p_out<T,CYN::PIN>	    out;
    typedef cynw_p2p_base_in<T,CYN::TLM>    base_in;
    typedef cynw_p2p_base_out<T,CYN::PIN>   base_out;
    typedef this_type                       chan;

    cynw_p2p( const char* name=sc_gen_unique_name("p2p"))
    {
      input(output);
    }

    cynw_p2p_base_out<T,CYN::PIN> input;
    cynw_p2p<T,CYN::PIN> output;
    
    CYNW_P2P_OUT_DIRECT_PROXY_FUNCS;

    void reset() 
    {
      input.reset();
    }
};

////////////////////////////////////////////////////////////
//
// class: cynw_p2p<T,PIN,TLM>
//
// kind: 
//
//   metaport
//
// summary: 
//   PIN to TLM adapting channel.
//
// template parameters:
//
//   T : The data type carried on the interface.
//
// details:
//
//   This channel can be bound to a writer that is PIN, and a reader
//   that is TLM. 
//
// example:
//
//   SC_MODULE(writer) {
//     cynw_p2p<DT,PIN>::out dout;
//     ...
//   };
//   
//   SC_MODULE(reader) {
//     cynw_p2p<DT,TLM>::in din;
//   };
//    
//
//   SC_MODULE(parent) {
//      writer w;
//      reader r;
//      cynw_p2p<DT,PIN,TLM> chan;
//
//      SC_CTOR(parent) {
//        writer.dout(chan.input);
//        reader.din(chan.output);
//        ...
//      }
//      ...
//    };
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p<T,CYN::PIN,CYN::TLM>
  : public cynw_p2p_in_if<T>
  , public cynw_clk_rst_facade
{
  public:
    
    typedef cynw_p2p<T,CYN::TLM,CYN::PIN>   this_type;
    typedef cynw_p2p_in<T,CYN::PIN>	    in;
    typedef cynw_p2p_out<T,CYN::TLM>	    out;
    typedef cynw_p2p_base_in<T,CYN::PIN>    base_in;
    typedef cynw_p2p_base_out<T,CYN::TLM>   base_out;
    typedef this_type                       chan;

    cynw_p2p( const char* name=sc_gen_unique_name("p2p"))
    {
      output(input);
    }

    cynw_p2p_base_in<T,CYN::PIN> output;
    cynw_p2p<T,CYN::PIN> input;
    
    CYNW_P2P_IN_DIRECT_PROXY_FUNCS;
    
    void reset() 
    {
      output.reset();
    }
};

////////////////////////////////////////////////////////////
//
// class: cynw_p2p_in_redir<T,PIN>
//
// kind: 
//
//   metaport
//
// summary: 
//   Direction-changing input metaport.
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//   This class can be used in place of a cynw_p2p_in<T,PIN> in cases
//   were the port needs to be directly connected to the input of a cynw_p2p<T>
//   or cynw_fifo<T>.  This class is a cynw_p2p_base_in<T,PIN> metaport,
//   and contains a cynw_p2p_base_out<T,PIN> metaport named redir_in.
//   The class contains an SC_METHOD that simply connects one port to 
//   the other.  
//
// example:
//
//   SC_MODULE(M)
//   {
//     // Instantiate a cynw_p2p_in_redir<> as an input metaport so we can 
//     // connect a FIFO's input side directly to it.
//     cynw_p2p_in_redir<DT> din;
//     cynw_fifo<DT,16> fifo;
//
//     SC_CTOR(M)
//     {
//      // Bind the FIFO's input to the redirected port of the cynw_p2p_in_redir<>.
//      // This effectively hooks the FIFO's input directly to the input metaport.
//	din.redir_in( fifo.input );
//     }
//   };
//
//
////////////////////////////////////////////////////////////
template <class T, typename CYN_L=CYN::PIN>
class cynw_p2p_in_redir
  : public sc_module,
    public cynw_p2p_base_in<T,CYN_L>,
    public cynw_hier_bind_detector
{
  public:
    HLS_EXPOSE_PORT( OFF, redir_in );

    SC_HAS_PROCESS(cynw_p2p_in_redir);

    typedef cynw_p2p_in_redir<T,CYN_L>    this_type;
    typedef cynw_p2p_base_in<T,CYN_L>   metaport;

    cynw_p2p_in_redir( sc_module_name name = sc_module_name(sc_gen_unique_name("cynw_p2p_in_redir")), bool is_subclass=false)
      : sc_module(name),
	metaport(HLS_CAT_NAMES(name,"port")),
	redir_in(HLS_CAT_NAMES(name,"redir"))
    {
      // Method to ferry signals from metaport to signals.
      SC_METHOD(xfer_in);
      sensitive << metaport::vld;
      sensitive << metaport::data;

      SC_METHOD(xfer_out);
      sensitive << redir_in.busy;
    }

    //
    // Port for redir_in binding.
    //
    cynw_p2p_base_out<T,CYN_L> redir_in;

  protected:
    void xfer_in()
    {
      if ( is_hierarchically_bound() ) 
	return;

      redir_in.vld = metaport::vld.read();
      redir_in.data = metaport::data.read();
    }
    void xfer_out()
    {
      if ( is_hierarchically_bound() ) 
	return;

      metaport::busy = redir_in.busy.read();
    }
};


////////////////////////////////////////////////////////////
//
// class: cynw_p2p_in_redir<T,TLM>
//
// kind: 
//
//   metaport
//
// summary: 
//   Direction-changing input metaport.
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : Specify TLM to select this class.
//
// details:
//
//   This is a TLM version of cynw_p2p_in_redir<T,PIN> and performs
//   the same direction-changing function.
//
// example:
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p_in_redir<T,CYN::TLM>
  : public cynw_p2p_base_in<T,CYN::TLM>
{
  public:
    typedef cynw_p2p_in_redir<T,CYN::TLM>    this_type;
    typedef cynw_p2p_base_in<T,CYN::TLM>   metaport;

    SC_HAS_PROCESS(this_type);

    cynw_p2p_in_redir( const char* name=sc_gen_unique_name("cynw_p2p_in_redir"), bool is_subclass=false )
      : metaport(HLS_CAT_NAMES(name,"port")),
	redir_in(HLS_CAT_NAMES(name,"redir")),
	xfer_proxy(this,name)
    {
    }

    //
    // Port for redir_in binding.
    //
    cynw_p2p_base_out<T,CYN::TLM> redir_in;

  protected:
    //
    // We cannot derive from both sc_port and sc_module because they share
    // a non-virtual base class in sc_object.  So, put the method in a proxy class.
    //
    SC_MODULE(xfer_proxy_t)
    {
      SC_HAS_PROCESS(xfer_proxy_t);
      xfer_proxy_t( this_type* parent, sc_module_name name )
	: sc_module(name), p_parent(parent)
      {
	SC_THREAD(xfer);
      }

      void xfer()
      {
	while (1) 
	{
	  p_parent->redir_in.put( p_parent->metaport::get() );
	}
      }
      this_type* p_parent;
    };
    xfer_proxy_t xfer_proxy;
};

////////////////////////////////////////////////////////////
//
// class: cynw_p2p_out_redir<T,PIN>
//
// kind: 
//
//   metaport
//
// summary: 
//   Direction-changing output metaport.
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//   This class can be used in place of a cynw_p2p_out<T,PIN> in cases
//   were the port needs to be directly connected to the output of a cynw_p2p<T>
//   or cynw_fifo<T>.  This class is a cynw_p2p_base_out<T,PIN> metaport,
//   and contains a cynw_p2p_base_in<T,PIN> metaport named redir_out.
//   The class contains an SC_METHOD that simply connects one port to 
//   the other.  
//
// example:
//
//   SC_MODULE(M)
//   {
//     // Instantiate a cynw_p2p_out_redir<> as an output metaport so we can 
//     // connect a FIFO's output side directly to it.
//     cynw_p2p_out_redir<DT> dout;
//     cynw_fifo<DT,16> fifo;
//
//     SC_CTOR(M)
//     {
//      // Bind the FIFO's output to the redirected port of the cynw_p2p_out_redir<>.
//      // This effectively hooks the FIFO's output directly to the output metaport.
//	din.redir_out( fifo.output );
//     }
//   };
//
//
////////////////////////////////////////////////////////////
template <class T, typename CYN_L=CYN::PIN>
class cynw_p2p_out_redir
  : public sc_module,
    public cynw_p2p_base_out<T,CYN_L>,
    public cynw_hier_bind_detector
{
  public:
    HLS_EXPOSE_PORT( OFF, redir_out );

    SC_HAS_PROCESS(cynw_p2p_out_redir);

    typedef cynw_p2p_out_redir<T,CYN_L>    this_type;
    typedef cynw_p2p_base_out<T,CYN_L>   metaport;

    cynw_p2p_out_redir( sc_module_name name=sc_module_name(sc_gen_unique_name("cynw_p2p_out_redir")), bool is_subclass=false)
      : sc_module(name),
	metaport(HLS_CAT_NAMES(name,"port")),
	redir_out(HLS_CAT_NAMES(name,"redir"))
    {
      // Method to ferry signals from metaport to signals.
      SC_METHOD(xfer_in);
      sensitive << metaport::busy;

      SC_METHOD(xfer_out);
      sensitive << redir_out.vld;
      sensitive << redir_out.data;
    }

    //
    // Port for redir_out binding.
    //
    cynw_p2p_base_in<T,CYN_L> redir_out;

  protected:
    void xfer_in()
    {
      if ( is_hierarchically_bound() ) 
	return;

      redir_out.busy = metaport::busy.read();
    }
    void xfer_out()
    {
      if ( is_hierarchically_bound() ) 
	return;

      metaport::vld = redir_out.vld.read();
      metaport::data = redir_out.data.read();
    }
};


////////////////////////////////////////////////////////////
//
// class: cynw_p2p_out_redir<T,TLM>
//
// kind: 
//
//   metaport
//
// summary: 
//   Direction-changing output metaport.
//
// template parameters:
//
//   T : The data type carried on the interface.
//   L : Specify TLM to select this class.
//
// details:
//
//   This is a TLM version of cynw_p2p_out_redir<T,PIN> and performs
//   the same direction-changing function.
//
// example:
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p_out_redir<T,CYN::TLM>
  : public cynw_p2p_base_out<T,CYN::TLM>
{
  public:
    typedef cynw_p2p_out_redir<T,CYN::TLM>    this_type;
    typedef cynw_p2p_base_out<T,CYN::TLM>   metaport;

    SC_HAS_PROCESS(this_type);

    cynw_p2p_out_redir( const char* name=sc_gen_unique_name("cynw_p2p_out_redir"), bool is_subclass=false)
      : metaport(HLS_CAT_NAMES(name,"port")),
	redir_out(HLS_CAT_NAMES(name,"redir")),
	xfer_proxy(this,name)
    {
    }

    //
    // Port for redir_out binding.
    //
    cynw_p2p_base_in<T,CYN::TLM> redir_out;

  protected:
    //
    // We cannot derive from both sc_port and sc_module because they share
    // a non-virtual base class in sc_object.  So, put the method in a proxy class.
    //
    SC_MODULE(xfer_proxy_t)
    {
      SC_HAS_PROCESS(xfer_proxy_t);
      xfer_proxy_t( this_type* parent, sc_module_name name )
	: sc_module(name), p_parent(parent)
      {
	SC_THREAD(xfer);
      }

      void xfer()
      {
	while (1) 
	{
	  p_parent->metaport::put( p_parent->redir_out.get() );
	}
      }
      this_type* p_parent;
    };
    xfer_proxy_t xfer_proxy;
};


////////////////////////////////////////////////////////////
//
// class: cynw_p2p_direct<T,PIN>
//
// kind:
//
//   channel
//
// summary: 
//
//   A cynw_p2p channal that can be directly accessed by two threads.
//
// template parameters:
//
//   T : The data type carried across the channel.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//   This class operates similarly to cynw_p2p, but it designed
//   to be directly accessed from two SC_CTHREADs without requiring
//   instantiation and binding of ports. 
//
//   The cynw_p2p_direct class has two interfaces: 
//
//     input :  is a cynw_p2p_out_if<T> used to write values
//              to the channel.
//
//     output : is a cynw_p2p_in_if<T> used to read values
//              to the channel.
//
//   These interfaces can be used in all of the ways described
//   for cynw_p2p_in<T,PIN> and cynw_p2p_out<T,PIN>.  This includes
//   support for access to the channel from a stallable thread.  
//   The input and output interfaces can be connected using stall_prop()
//   as described for cynw_p2p_in<T,PIN> and cynw_p2p_out<T,PIN>.
//
// example:
//
//   Access to a cynw_p2p_direct from two un-pipelined threads:
//
//     typedef sc_uint<8> DT;
//
//     SC_MODULE(M) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> rst;
//
//       // Input and output metaports.
//       cynw_p2p<DT>::base_in inp;
//       cynw_p2p<DT>::base_out outp;
//
//       // The channel.
//       cynw_p2p_direct<DT> chan;
//
//       SC_CTOR(M) 
//       {
//         // Start two threads.
//         SC_CTHREAD( source, clk.pos() );
//         reset_signal_is( rst, 0 );
//         SC_CTHREAD( sink, clk.pos() );
//         reset_signal_is( rst, 0 );
//       }
//
//       // Source thread.
//       void source()
//       {
//         // Reset the input port and the channels's input.
//         inp.reset();
//         chan.input.reset();
//
//         // Write values from the input to the channel.
//         while (1) 
//         {
//           DT val = inp.get();
//           chan.input = val;
//         }
//       }
//
//       // Sink thread.
//       void source()
//       {
//         // Reset the output port and the channel's output.
//         outp.reset();
//         chan.output.reset();
//
//         // Read values from the channel and write them to the output.
//         while (1) 
//         {
//           DT val = chan.output.get();
//           outp = val;
//         }
//       }
//     };
//
//   Reading from a channel from a stallable, pipelined thread:
//
//     typedef sc_uint<8> DT;
//
//     SC_MODULE(M) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> rst;
//
//       // The input metaport is simple, but the output metaport,
//       // which will be used by the stallable downstream thread,
//       // is not.
//       cynw_p2p<DT>::base_in inp;
//       cynw_p2p<DT>::out outp;
//
//       // The channel.
//       cynw_p2p_direct<DT> chan;
//
//       SC_CTOR(M) 
//       {
//         // Bind clk and rst to the channel's output.
//         outp.clk_rst(this);
//
//         // Make a stall_prop() binding from the DUT's output to the channel's output.
//         chan.output.stall_prop( outp );
//
//         // Start two threads.
//         SC_CTHREAD( source, clk.pos() );
//         reset_signal_is( rst, 0 );
//         SC_CTHREAD( sink, clk.pos() );
//         reset_signal_is( rst, 0 );
//       }
//
//       // The source thread is the same is it was in the preceding example.
//       void source()
//       {
//         // Reset the input port and the channel's input.
//         inp.reset();
//         chan.input.reset();
//
//         // Write values from the input to the channel.
//         while (1) 
//         {
//           DT val = inp.get();
//           chan.input = val;
//         }
//       }
//
//       // The sink thread is pipelined, and written to use soft-stall.
//       void source()
//       {
//         // Reset the output port and the channel's output.
//         outp.reset();
//         chan.output.reset();
//
//         // Read values from the channel and write them to the output.
//         while (1) 
//         {
//           HLS_PIPELINE_LOOP(1,"pipe");
//           DT val = chan.output.get( false );
//           outp.put( val );
//         }
//       }
//     };
//
////////////////////////////////////////////////////////////
template <class T, typename CYN_L=CYN::PIN>
class cynw_p2p_direct
  : public sc_module,
    public cynw_clk_rst
{
  public:
    typedef cynw_p2p_direct<T,CYN_L>   this_type;

    cynw_p2p_direct( sc_module_name name=sc_module_name(sc_gen_unique_name("cynw_p2p_direct")), 
		     int tlm_fifo_depth=CYNW_P2P_DEFAULT_TLM_FIFO_DEPTH,
		     unsigned options_in=0 )
      : sc_module( name ),
	input(HLS_CAT_NAMES(name,"input"),options_in),
	output(HLS_CAT_NAMES(name,"output"),options_in),
        m_chan("") // Avoid prefixing names.
    {
      // Bind the channel to the direct-access ports.
      output( m_chan );
      input( m_chan );

      // Route clk and rst to the channel and the ports.
      output.clk_rst( *this );
      input.clk_rst( *this );
    }

	void start_of_simulation()
	{
		esc_trace( m_chan.data );
		esc_trace( m_chan.vld );
		esc_trace( m_chan.busy );
	}

    //
    // Input and output ports.
    //
    // These ports can be used to access the channel directly from threads 
    // in the same module.
    //
    cynw_p2p_out<T,CYN_L> input;
    cynw_p2p_in<T,CYN_L> output;

    //
    // Provide a set of functions implementing the the cynw_p2p_in_if
    // and cynw_p2p_out_if, proxies to the input and output ports.
    //
    CYNW_P2P_DIRECT_PROXY_FUNCS

  protected:
    // 
    // The channel itself.
    //
    class cynw_p2p<T> m_chan;

};

////////////////////////////////////////////////////////////
//
// class: cynw_p2p_direct<T,TLM>
//
// kind:
//
//   channel
//
// summary: 
//
//   TLM version of cynw_p2p_direct<T>
//
// template parameters:
//
//   T : The data type carried across the channel.
//   L : The abstraction level: this class is selected
//       when L=TLM.
//
// details:
//
//   The cynw_p2p_direct<T,TLM> class is plug replacible with
//   cynw_p2p_direct<T,PIN>, but it's implemented using either 
//   a tlm_fifo<T> or an sc_fifo<T> depending on whether CYN_NO_OSCI_TLM 
//   is defined.
//
// example:
//
//     typedef sc_uint<8> DT;
//
//     SC_MODULE(M) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> rst;
//
//       // Input and output metaports.
//       cynw_p2p<DT,TLM>::base_in inp;
//       cynw_p2p<DT,TLM>::base_out outp;
//
//       // The channel.
//       cynw_p2p_direct<DT,TLM> chan;
//
//       SC_CTOR(M) 
//       {
//         // This binding is not really necessay, but provides
//         // compatibility with cynw_p2p_direct<T,PIN>.
//         chan.clk_rst(this);
//
//         // Start two threads.
//         SC_CTHREAD( source, clk.pos() );
//         reset_signal_is( rst, 0 );
//         SC_CTHREAD( sink, clk.pos() );
//         reset_signal_is( rst, 0 );
//       }
//
//       // Source thread.
//       void source()
//       {
//         // These resets don't do anything, but provide compatibility
//         // with the PIN version.
//         inp.reset();
//         chan.input.reset();
//
//         // Write values from the input to the channel.
//         while (1) 
//         {
//           DT val = inp.get();
//           chan.input = val;
//         }
//       }
//
//       // Sink thread.
//       void source()
//       {
//         outp.reset();
//         chan.output.reset();
//         while (1) 
//         {
//           DT val = chan.output.get();
//           outp = val;
//         }
//       }
//     };
//
////////////////////////////////////////////////////////////
template <class T>
class cynw_p2p_direct<T,CYN::TLM>
  : public sc_module
  , public cynw_clk_rst_facade
{
  public:
    typedef cynw_p2p_direct<T,CYN::TLM>     this_type;
    typedef CYN_USE_FIFO_CHAN<T>	    chan_type;

    cynw_p2p_direct( sc_module_name name= sc_module_name(sc_gen_unique_name("cynw_p2p_direct")), 
		     int tlm_fifo_depth=CYNW_P2P_DEFAULT_TLM_FIFO_DEPTH,
		     unsigned options_in=0 )
      : sc_module(name),
        chan( name, tlm_fifo_depth ),
        input( HLS_CAT_NAMES(name,"input"), options_in ),
        output( HLS_CAT_NAMES(name,"output"), options_in )
    {
      // Bind the input and output ports to the fifo.
      input(chan);
      output(chan);
    }

    cynw_p2p_out<T,CYN::TLM> input;
    cynw_p2p_in<T,CYN::TLM> output;
    chan_type chan;

    //
    // Provide a set of functions implementing the the cynw_p2p_in_if
    // and cynw_p2p_out_if, proxies to the input and output ports.
    //
    CYNW_P2P_DIRECT_PROXY_FUNCS

  protected:
};


}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif

// 
// sc_trace specializations
//

#ifndef STRATUS
template <typename T> 
void sc_trace( sc_trace_file *tf, const cynw_p2p_signals<T>& obj, const std::string& n ) { 
  sc_trace( tf, obj.busy, n + ".busy" ); 
  sc_trace( tf, obj.vld, n + ".vld" ); 
  sc_trace( tf, obj.data, n + ".data" );
} 
#define CYNW_P2P_SC_TRACE(cynw_class) \
template <typename T> \
void sc_trace( sc_trace_file *tf, const cynw_class<T,CYN::PIN>& obj, const std::string& n ) { \
  sc_trace( tf, obj.busy, n + ".busy" ); \
  sc_trace( tf, obj.vld, n + ".vld" ); \
  sc_trace( tf, obj.data, n + ".data" ); \
} \
template <typename T> \
void sc_trace( sc_trace_file *tf, const cynw_class<T,CYN::TLM>& obj, const std::string& n ) {}

#define CYNW_P2P_SC_TRACE_MEMBER(cynw_class,cynw_member) \
template <typename T> \
void sc_trace( sc_trace_file *tf, const cynw_class<T,CYN::PIN>& obj, const std::string& n ) { \
  sc_trace( tf, obj.cynw_member, n ); \
} \
template <typename T> \
void sc_trace( sc_trace_file *tf, const cynw_class<T,CYN::TLM>& obj, const std::string& n ) {}
#else 
template <typename T> 
void sc_trace( sc_trace_file *tf, const cynw_p2p_signals<T>& obj, const std::string& n ) {} 
#define CYNW_P2P_SC_TRACE(cynw_class) \
template <typename T> \
void sc_trace( sc_trace_file *tf, const cynw_class<T,CYN::PIN>& obj, const std::string& n ) {} \
template <typename T> \
void sc_trace( sc_trace_file *tf, const cynw_class<T,CYN::TLM>& obj, const std::string& n ) {}

#define CYNW_P2P_SC_TRACE_MEMBER(cynw_class,cynw_member) \
template <typename T> \
void sc_trace( sc_trace_file *tf, const cynw_class<T,CYN::PIN>& obj, const std::string& n ) {}
#endif

CYNW_P2P_SC_TRACE(cynw_p2p_base_in)
CYNW_P2P_SC_TRACE(cynw_p2p_in)
CYNW_P2P_SC_TRACE(cynw_p2p_base_out)
CYNW_P2P_SC_TRACE(cynw_p2p_out)
CYNW_P2P_SC_TRACE(cynw_p2p)
CYNW_P2P_SC_TRACE_MEMBER(cynw_p2p_direct,input)

#endif

