/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/

#ifndef CYNW_FIFO_H
#define CYNW_FIFO_H

#include <systemc.h>
#include <cynthhl.h>

#include "cynw_p2p.h"

#if defined STRATUS  &&  ! defined CYN_DONT_SUPPRESS_MSGS
#pragma cyn_suppress_msgs NOTE
#endif	// STRATUS  &&  CYN_DONT_SUPPRESS_MSGS

#if defined STRATUS 
#pragma hls_ip_def
#endif	

// By default, a register bank will be used for fifos with more than this number of elements.
#ifndef CYNW_FIFO_REG_BANK_LIMIT
#define CYNW_FIFO_REG_BANK_LIMIT 1024
#endif

//#define esc_trace_vcd 0

namespace cynw
{

////////////////////////////////////////////////////////////
//
// class: cynw_fifo<T,N,PIN>
//
// kind:
//
//   channel
//
// summary: 
//
//   Synthesizable fixed-length fifo.
//
// template parameters:
//
//   T : The data type carried across the channel.
//   N : The depth of the fifo.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//   cynw_fifo is a synthesizable, pin-level behavioral model for a fixed
//   length FIFO.  The FIFO can store a maximum of N items, where N is the
//   second template parameter.  If a data value is written to the FIFO while
//   the reader is not ready to read it, the value is stored in the FIFO.  If
//   the FIFO becomes full, the busy signal is asserted at the FIFO's input.
//
//   If there are data values stored in the FIFO when a reader attempts to read
//   from the FIFO, a value will be returned.  When the FIFO becomes empty, the
//   vld line is deasserted on its output.  
//
//   The FIFO also has asynchronous pass-through behavior where data written
//   while the reader is not busy will be passed through asynchronously.
//
//   cynw_fifo uses the cynw_p2p protocol at its input and output.  This
//   version of cynw_fifo is designed to be used between tho modules.  It can
//   be bound to cynw_p2p metaports as a way of adding buffering to any
//   cynw_p2p connection.  For buffering between two threads internal to a
//   module, use cynw_fifo_direct instead.
//
//   The FIFO is synthesized as an inline module.  It is implemented as a
//   set of registers with an output mux.
//
//   cynw_fifo objects must be connected to a clock and reset signal from
//   its parent module.  See cynw_clk_rst for details on binding options.
//
// example:
//
//   Connecting two modules with cynw_p2p metaports:
//
//     typedef sc_uint<8> DT;
//
//     // Writer with output metaport.
//     SC_MODULE(writer)
//     {
//       cynw_p2p<DT>::base_out dout;
//       ...
//     };
//
//     // Reader with input metaport.
//     SC_MODULE(reader)
//     {
//       cynw_p2p<DT>::base_in din;
//       ...
//     };
//
//     // Parent with cynw_fifo instance and binding calls.
//     SC_MODULE(parent) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> reset;
//
//       writer w;
//       reader r;
//       cynw_fifo<DT,16> fifo;
//
//       SC_CTOR(parent)
//       {
//         // Bind the fifo's ports.
//         // Notice that there are separate 'input' and 'output' members
//         // to which each port must be bound.
//         w.dout( fifo.input );
//         r.din( fifo.output );
//
//         // Connect clk and rst to the fifo.
//         fifo.clk_rst( clk, reset );
//       }
//     };
//
//  The reader and writer may also declare their ports as cynw_fifo<T,N>::in or
//  cynw_fifo<T,N>::out instead:
//
//     SC_MODULE(writer)
//     {
//       cynw_fifo<DT,16>::out dout;
//       ...
//     };
//
//     SC_MODULE(reader)
//     {
//       cynw_fifo<DT,16>::in din;
//       ...
//     };
//
////////////////////////////////////////////////////////////
template <class T, int CYN_N, typename CYN_L=CYN::PIN>
class cynw_fifo
  : public sc_module,
    public cynw_clk_rst
{
  public:
    //CYN_INLINE_MODULE;
    typedef cynw_fifo<T,CYN_N,CYN_L>            this_type;
    typedef class cynw_p2p_in<T,CYN_L>  in;
    typedef class cynw_p2p_out<T,CYN_L> out;

    SC_HAS_PROCESS(cynw_fifo);

    cynw_fifo( sc_module_name name=sc_module_name(sc_gen_unique_name("cynw_fifo")), bool from_subclass=false )
      : sc_module( name ),
        input(HLS_CAT_NAMES(name,"input")),
        output(HLS_CAT_NAMES(name,"output")),
	cur(HLS_CAT_NAMES(name,"cur")),
	data_set(HLS_CAT_NAMES(name,"data_set"))
    {
      if (CYN_N > CYNW_FIFO_REG_BANK_LIMIT)
	HLS_MAP_TO_REG_BANK(data);
      else
	HLS_FLATTEN_ARRAY(data,"");

      SC_METHOD(input_busy_thread);
      sensitive << cur;
      sensitive << output.busy;
      dont_initialize();

      SC_METHOD(output_vld_thread);
      sensitive << cur;
      sensitive << input.vld;
      dont_initialize();

      SC_METHOD(output_data_thread);
      sensitive << cur;
      sensitive << input.data;
      sensitive << data_set;
      dont_initialize();

      SC_METHOD(cur_thread);
      sensitive << cynw_clk_rst::clk.pos();
      dont_initialize();

      SC_METHOD(data_thread);
      sensitive << cynw_clk_rst::clk.pos();
      dont_initialize();
    }

    //
    // Signals for the input and output interfaces.
    // 
    cynw_p2p_signals<T> input;
    cynw_p2p_signals<T> output;

    //
    // Default implementation of cur pointer is binary encoded.
    //
    template <typename CYN_MUX_T>
    struct cur_t {

      typedef sc_uint< cyn_log::log2<CYN_N+1>::value> val_t;
      typedef sc_uint< cyn_log::log2<CYN_N>::value> rval_t;

      typedef cur_t< CYN_MUX_T > this_type;

      static val_t reset_value()
      {
	return -1;
      }
      static bool full( const val_t& v )
      {
	return (CYN_N>0) ? (v == (val_t)(CYN_N-1)) : true;
      }
      static bool empty( const val_t& v )
      {
	return (CYN_N>0) ? (v == (val_t)-1) : true;
      }
      static val_t incr( const val_t& v )
      {
	return v+1;
      }
      static val_t decr( const val_t& v )
      {
	return v-1;
      }
    };
  
    //
    // One-hot implementation for sc_uint/sc_int/sc_biguint/sc_bigint
    //
    struct onehot_cur_t {

      typedef sc_uint< CYN_N+1 > val_t;

      typedef onehot_cur_t this_type;

      static val_t reset_value()
      {
	return 1;
      }

      static bool full( const val_t& v )
      {
	return (CYN_N>0) ? v[CYN_N] : true;
      }
      static bool empty( const val_t& v )
      {
	return (CYN_N>0) ? v[0] : true;
      }
      static val_t incr( const val_t& v )
      {
	return v << 1;
      }
      static val_t decr( const val_t& v )
      {
	return v >> 1;
      }
    };

#ifndef CYNW_USE_ONEHOT_FIFO_MUX
#define CYNW_USE_ONEHOT_FIFO_MUX 0
#endif
#if CYNW_USE_ONEHOT_FIFO_MUX
    template <int CYN_W0>
    struct cur_t< sc_uint<CYN_W0> > : public onehot_cur_t {};
    template <int CYN_W1>
    struct cur_t< sc_int<CYN_W1> > : public onehot_cur_t {};
    template <int CYN_W2>
    struct cur_t< sc_biguint<CYN_W2> > : public onehot_cur_t {};
    template <int CYN_W3>
    struct cur_t< sc_bigint<CYN_W3> > : public onehot_cur_t {};
#endif

    // 
    // Registers
    //
    T data[(CYN_N>0)?CYN_N:1];				// Stored data.
    sc_signal< typename cur_t<T>::val_t > cur;	// Mux selector. 
    sc_signal<bool> data_set;           // Trigger to compensate for no sc_signal data[].
    
    //
    // Methods
    //

    //
    // Asynchronous SC_METHOD.
    //
    // Asserts the vld output unless FIFO is empty, and there's no
    // currently valid input data.
    //
    void output_vld_thread()
    {
        output.vld.write( !cur_t<T>::empty( cur.read() ) || input.vld.read() );
    }

    //
    // Asynchronous SC_METHOD.
    //
    // Always ready to accept a new value unless we're full.
    // If the output is being read, accept a new value as well.
    //
    void input_busy_thread()
    {
      input.busy = ( cur_t<T>::full( cur.read() ) && output.busy.read() );
    }

    // Cheap template trick to get W out of T.
    template <int CYN_W>
    static sc_int<CYN_W> word_mask( const sc_int<CYN_W>& sample, bool bit )
    { 
      return (sc_int<CYN_W>)((sc_int<1>)bit);
    }
    template <int CYN_W>
    static sc_uint<CYN_W> word_mask( const sc_uint<CYN_W>& sample, bool bit )
    { 
      return (sc_uint<CYN_W>)((sc_int<CYN_W>)((sc_int<1>)bit));
    }
    template <int CYN_W>
    static sc_bigint<CYN_W> word_mask( const sc_bigint<CYN_W>& sample, bool bit )
    { 
      return (sc_bigint<CYN_W>)((sc_bigint<1>)bit);
    }
    template <int CYN_W>
    static sc_biguint<CYN_W> word_mask( const sc_biguint<CYN_W>& sample, bool bit )
    { 
      return (sc_biguint<CYN_W>)((sc_bigint<CYN_W>)((sc_bigint<1>)bit));
    }

    // 
    // MUX implementations.
    //
    // There are 2 mux implementations: a one-hot version for sc_uint and
    // sc_int, and a SCHED_AGGRESSIVE_1 version for other data types (like
    // structs).  This provides support for arbitrary data types in fifos,
    // but does not sacrifice the potentially better QOR with a one-hot
    // version.
    //

    //
    // SCHED_AGGRESSIVE_1 vesion of mux.
    //
    template <class CYN_MUX_T>
    class mux_output_t 
    {
      public:
      T mux_value( this_type* f )  \
      {
	  HLS_REMOVE_CONTROL(ON,"");
	  T rslt;
          rslt = f->data[(typename cur_t<CYN_MUX_T>::rval_t)f->cur.read()];
	  return rslt;
      }
    };

#define CYNW_FIFO_MUX_VALUE_ONEHOT_IMPL \
      /* 'cur' is a one-hot vector, and we generate a one-hot mux out of &'s and |'s */ \
      /* that selects amongst the current input value, and words in the fifo. */ \
      T mux_value( this_type* f ) \
      {  \
	  T rslt = 0;  \
	  /* Implement mux with &'s and ||'s. */  \
	  for ( int i=1; i <= CYN_N; i++ ) {  \
	    /* word_mask() is a template trick to get a word-width mask with */  \
	    /* all 1's or all 0's depending on a bit in 'cur'. */   \
	    T mask = word_mask((T)0, f->cur.read()[i]);  \
	    T val = f->data[i-1]; \
	    /*rslt |= ( val & mask);  */ \
	    rslt = rslt | ( val & mask);  \
	  }  \
	  return rslt; \
      }

#if CYNW_USE_ONEHOT_FIFO_MUX
    //
    // One-hot versions of mux for sc_uint, sc_int, sc_biguint, and sc_bigint.
    //
    template <int CYN_W0>
    class mux_output_t< sc_uint<CYN_W0> >
    {
      public:
	CYNW_FIFO_MUX_VALUE_ONEHOT_IMPL
    };

    template <int CYN_W1>
    class mux_output_t< sc_int<CYN_W1> >
    {
      public:
	CYNW_FIFO_MUX_VALUE_ONEHOT_IMPL
    };

    template <int CYN_W2>
    class mux_output_t< sc_bigint<CYN_W2> >
    {
      public:
	CYNW_FIFO_MUX_VALUE_ONEHOT_IMPL
    };

    template <int CYN_W3>
    class mux_output_t< sc_biguint<CYN_W3> >
    {
      public:
	CYNW_FIFO_MUX_VALUE_ONEHOT_IMPL
    };
#endif

    
    //
    // Asynchronous SC_METHOD
    //
    // Implements a mux to select the data output based on the 'cur' vector.
    //
    void output_data_thread()
    {
      if ( cur_t<T>::empty( cur.read() ) ) {
        // Fifo is empty.  Pass through the current input.
        output.data.write( input.data.read() );
      } else { 
	mux_output_t<T> mux;
	output.data.write( mux.mux_value( this ) );
      }
    }

    // 
    // Synchronous SC_METHOD
    //
    // 'cur' is a shift register that always contains exactly one 1.
    // Its used as a one-hot selector for the output mux.
    //
    void cur_thread()
    {
      if ( rst_active() ) {
	HLS_SET_IS_RESET_BLOCK("cur_thread");
        cur.write( cur_t<T>::reset_value() );
      } else {
        bool shift = input.vld.read() && output.busy.read() && !cur_t<T>::full( cur.read() );
        bool unshift = !input.vld.read() && !output.busy.read() && !cur_t<T>::empty( cur.read() );
        if ( shift ) {
          cur.write( cur_t<T>::incr( cur.read() ) );
        } else if ( unshift ) {
          cur.write( cur_t<T>::decr( cur.read() ) );
        }
      }
    }

    // 
    // Synchronous SC_METHOD.
    //
    // Advances the fifo as a shift register when there is a new input
    // but the output is not ready.
    //
    // Note that the fifo data is not cleared at reset.
    //
    void data_thread()
    {
      // bool rst = rst_active();  // Sample to get side effects.
      rst_active();  // Sample to get side effects.

      if ( input.vld.read() && ( !cur_t<T>::full( cur.read() ) || !output.busy.read() ) ) {
	HLS_REMOVE_CONTROL(OFF,"data_thread");
        for ( int i=CYN_N-1; i > 0; i-- ) {
          data[i] = data[i-1];
        }
        data[0] = input.data.read();
#ifndef STRATUS_HLS
        // This bit is here to compensate for the fact that the data array is not 
        // an sc_signal.  This allows us to be sensitive to changes in data for SC sim.
        data_set = !data_set;
#endif
      }
    }
  public:
    void trace_on()
    {
	esc_trace_signal( &output.vld, (sc_string(name())+".output.vld").c_str(), esc_trace_vcd );
	esc_trace_signal( &output.busy, (sc_string(name())+".output.busy").c_str(), esc_trace_vcd );
	esc_trace_signal( &output.data, (sc_string(name())+".output.data").c_str(), esc_trace_vcd );
	esc_trace_signal( &input.vld, (sc_string(name())+".input.vld").c_str(), esc_trace_vcd );
	esc_trace_signal( &input.busy, (sc_string(name())+".input.busy").c_str(), esc_trace_vcd );
	esc_trace_signal( &input.data, (sc_string(name())+".input.data").c_str(), esc_trace_vcd );
	esc_trace_signal( &cur, (sc_string(name())+".cur").c_str(), esc_trace_vcd );
	esc_trace_signal( &this_type::data_set, (sc_string(name())+".data_set").c_str(), esc_trace_vcd );
    }

	void start_of_simulation()
	{
		esc_trace( cur );
	}

};

////////////////////////////////////////////////////////////
// Specialization for CYN_N==0.
// Degenerates to a the equivalent of a cynw_p2p_direct.
////////////////////////////////////////////////////////////
template <class T>
class cynw_fifo<T,0,CYN::PIN>
  : public sc_module,
    public cynw_clk_rst
{
  public:
    typedef cynw_fifo<T,0,CYN::PIN>            this_type;
    typedef class cynw_p2p_in<T,CYN::PIN>  in;
    typedef class cynw_p2p_out<T,CYN::PIN> out;

    SC_HAS_PROCESS(cynw_fifo);

    cynw_fifo( sc_module_name name=sc_module_name(sc_gen_unique_name("cynw_fifo")), bool from_subclass=false )
      : sc_module( name ),
        input(HLS_CAT_NAMES(name,"input")),
        output(HLS_CAT_NAMES(name,"output"))
    {
      SC_METHOD(xfer_in);
      sensitive << input.vld;
      sensitive << input.data;

      SC_METHOD(xfer_out);
      sensitive << output.busy;
    }

    //
    // Signals for the input and output interfaces.
    // 
    cynw_p2p_signals<T> input;
    cynw_p2p_signals<T> output;

  public:
    void xfer_in() {
      output.vld.write( input.vld.read() );
      output.data.write( input.data.read() );
    }

    void xfer_out() {
      input.busy.write( output.busy.read() );
    }
};

////////////////////////////////////////////////////////////
//
// class: cynw_fifo<T,CYN_N,TLM>
//
// kind:
//
//   channel
//
// summary: 
//
//   TLM version of cynw_fifo<T,CYN_N>
//
// template parameters:
//
//   T : The data type carried across the channel.
//   N : The depth of the fifo.
//   L : The abstraction level: this class is selected
//       when L=TLM.
//
// details:
//
//   This version of cynw_fifo uses either an sc_fifo<T> or a tlm_fifo<T>.
//   tlm_fifo<T> will be used unless CYN_NO_OSCI_TLM is defined.
//   This class is plug-compatible with cynw_fifo<T,N,PIN>.
//
// example:
//
//   Connecting two modules with cynw_p2p<T,TLM> metaports:
//
//     typedef sc_uint<8> DT;
//
//     // Writer with output metaport.
//     SC_MODULE(writer)
//     {
//       cynw_p2p<DT,TLM>::base_out dout;
//       ...
//     };
//
//     // Reader with input metaport.
//     SC_MODULE(reader)
//     {
//       cynw_p2p<DT,TLM>::base_in din;
//       ...
//     };
//
//     // Parent with cynw_fifo instance and binding calls.
//     SC_MODULE(parent) 
//     {
//       sc_in_clk clk;
//       sc_in<bool> reset;
//
//       writer w;
//       reader r;
//       cynw_fifo<DT,16,TLM> fifo;
//
//       SC_CTOR(parent)
//       {
//         // Bind the fifo to the writer and reader.
//         w.dout( fifo.input );
//         r.din( fifo.output );
//
//         // clk and reset are not actually used, but this binding
//         // call is supported for compatibility with cynw_fifo<T,N,PIN>.
//         fifo.clk_rst( clk, reset );
//       }
//     };
//
////////////////////////////////////////////////////////////
template <class T, int CYN_N>
class cynw_fifo<T,CYN_N,CYN::TLM>
  : public CYN_USE_FIFO_CHAN<T>,
    public cynw_clk_rst_facade
{
  public:
    typedef cynw_fifo<T,CYN_N,CYN::TLM>   this_type;
    typedef CYN_USE_FIFO_CHAN<T>      base_type;
    typedef cynw_p2p_in<T,CYN::TLM>   in;
    typedef cynw_p2p_out<T,CYN::TLM>  out;

    cynw_fifo( const char* name=sc_gen_unique_name("cynw_fifo") )
      : base_type( name, (CYN_N>0)?CYN_N:1 ),
        output(*this),
        input(*this)
    {
    }

    //
    // References to the input and output interfaces on the fifo.
    // This allows binding using the same form as is used for 
    // cynw_fifo<T,PIN>.
    // 
    CYN_USE_FIFO_IN_IF<T>& output;
    CYN_USE_FIFO_OUT_IF<T>& input;

  protected:
};

////////////////////////////////////////////////////////////
//
// class: cynw_fifo_direct<T,N,PIN>
//
// kind:
//
//   channel
//
// summary: 
//
//   Synthesizable pin-level FIFO model designed for use between
//   threads in a single module.
//
// template parameters:
//
//   T : The data type carried across the channel.
//   N : The depth of the fifo.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//   This class operates similarly to cynw_fifo, but it designed
//   to be directly accessed from two SC_CTHREADs without requiring
//   instantiation and binding of ports. 
//
//   The cynw_fifo_direct class has two interfaces: 
//
//     input :  is a cynw_p2p_out_if<T> used to write values
//              to the FIFO.
//
//     output : is a cynw_p2p_in_if<T> used to read values
//              to the FIFO.
//
//   These interfaces can be used in all of the ways described
//   for cynw_p2p_in<T,PIN> and cynw_p2p_out<T,PIN>.  This includes
//   support for access to the FIFO from a stallable thread.  
//   The input and output interfaces can be connected using stall_prop()
//   for direct stall propagation as described for cynw_p2p_in<T,PIN> 
//   and cynw_p2p_out<T,PIN>.
//
//   The cynw_p2p_in_if<> and cynw_p2p_out_if<> interface functions
//   are provided as members of cynw_fifo_direct<>.  An exception is 
//   the reset() function.  Instead, reset_in() should be called from 
//   the reading thread, and reset_out() should be called from the writing 
//   thread.
//
// example:
//
//   Access to a cynw_fifo_direct from two threads:
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
//       // The fifo.
//       cynw_fifo_direct<DT,16> fifo;
//
//       SC_CTOR(M) 
//       {
//         // Bind the fifo to clk and rst.
//         fifo.clk_rst(this);
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
//         // Reset the input port and the fifo's input.
//         inp.reset();
//         fifo.reset_out();
//
//         // Write values from the input to the fifo.
//         while (1) 
//         {
//           DT val = inp.get();
//           fifo.put(val);
//         }
//       }
//
//       // Sink thread.
//       void sink()
//       {
//         // Reset the output port and the fifo's output.
//         outp.reset();
//         fifo.reset_in();
//
//         // Read values from the fifo and write them to the output.
//         while (1) 
//         {
//           DT val = fifo.get();
//           outp = val;
//         }
//       }
//     };
//
//
////////////////////////////////////////////////////////////
template <class T, int CYN_N, typename CYN_L=CYN::PIN>
class cynw_fifo_direct
  : public sc_module,
    public cynw_clk_rst
{
  public:

    typedef cynw_fifo_direct<T,CYN_N,CYN_L>   this_type;

    cynw_fifo_direct( sc_module_name name=sc_module_name(sc_gen_unique_name("cynw_fifo_direct")), unsigned options_in=0 )
      : sc_module( name ),
        input(HLS_CAT_NAMES(name,"input"),options_in),
        output(HLS_CAT_NAMES(name,"output"),options_in),
        m_fifo("fifo")
    {
      // Bind the fifo to the direct-access ports.
      output( m_fifo.output );
      input( m_fifo.input );

      // Route clk and rst to the fifo and the ports.
      output.clk_rst( *this );
      input.clk_rst( *this );
      m_fifo.clk_rst(*this);
    }

    //
    // Input and output ports.
    //
    // These ports can be used to access the fifo directly from threads 
    // in the same module.
    //
    cynw_p2p_out<T,CYN_L> input;
    cynw_p2p_in<T,CYN_L> output;

    //
    // Provide a set of functions implementing the the cynw_p2p_in_if
    // and cynw_p2p_out_if, proxied to the input and output ports.
    //
    CYNW_P2P_DIRECT_PROXY_FUNCS

	void start_of_simulation()
	{
		esc_trace( m_fifo.input.data );
		esc_trace( m_fifo.input.vld );
		esc_trace( m_fifo.input.busy );
		esc_trace( m_fifo.output.data );
		esc_trace( m_fifo.output.vld );
		esc_trace( m_fifo.output.busy );
	}

  protected:
    // 
    // The fifo itself.
    //
    class cynw_fifo<T,CYN_N,CYN_L> m_fifo;

};

////////////////////////////////////////////////////////////
//
// class: cynw_fifo_direct<T,CYN_N,TLM>
//
// kind:
//
//   channel
//
// summary: 
//
//   TLM version of cynw_fifo_direct<T,CYN_N>
//
// template parameters:
//
//   T : The data type carried across the channel.
//   N : The depth of the fifo.
//   L : The abstraction level: this class is selected
//       when L=TLM.
//
// details:
//
//   The cynw_fifo_direct<T,N,TLM> class is plug replacible with
//   cynw_fifo_direct<T,N,PIN>, but it's implemented using either 
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
//       // The fifo.
//       cynw_fifo_direct<DT,16,TLM> fifo;
//
//       SC_CTOR(M) 
//       {
//         // This binding is not really necessay, but provides
//         // compatibility with cynw_fifo_direct<T,N,PIN>.
//         fifo.clk_rst(this);
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
//         fifo.reset_out();
//
//         // Write values from the input to the fifo.
//         while (1) 
//         {
//           DT val = inp.get();
//           fifo.put(val);
//         }
//       }
//
//       // Sink thread.
//       void source()
//       {
//         outp.reset();
//         fifo.reset_in();
//         while (1) 
//         {
//           DT val = fifo.get();
//           outp = val;
//         }
//       }
//     };
//
////////////////////////////////////////////////////////////
template <class T, int CYN_N>
class cynw_fifo_direct<T,CYN_N,CYN::TLM>
  :  public cynw_clk_rst_facade
{
  public:
    HLS_INLINE_MODULE;

    typedef cynw_fifo<T,CYN_N,CYN::TLM>   this_type;
    typedef CYN_USE_FIFO_CHAN<T>      chan_type;

    cynw_fifo_direct( const char* name=sc_gen_unique_name("cynw_fifo"),
	              unsigned options_in=0)
      : chan( name, CYN_N ),
        input( HLS_CAT_NAMES(name,"input"), options_in ),
        output( HLS_CAT_NAMES(name,"output"), options_in )
    {
      // Bind the input and output ports to the fifo.
      input(chan);
      output(chan);
    }

    cynw_p2p_base_out<T,CYN::TLM> input;
    cynw_p2p_base_in<T,CYN::TLM> output;
    chan_type chan;

    //
    // Provide a set of functions implementing the the cynw_p2p_in_if
    // and cynw_p2p_out_if, proxied to the input and output ports.
    //
    CYNW_P2P_DIRECT_PROXY_FUNCS

  protected:
};

//
// Specializations for cynw_wait_can_get() for cynw_fifo_direct.
//
template <class CYN_T1,class CYN_L, int CYN_N>
void cynw_wait_can_get( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1 )
{
  cynw_wait_can_get( p1.output );
}

template <class CYN_T1, class CYN_T2, class CYN_L, int CYN_N>
void cynw_wait_can_get( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2 )
{
  cynw_wait_can_get( p1.output, p2.output );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_L, int CYN_N>
void cynw_wait_can_get( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3 )
{
  cynw_wait_can_get( p1.output, p2.output, p3.output );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_L, int CYN_N>
void cynw_wait_can_get( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3, cynw_fifo_direct<CYN_T4,CYN_N,CYN_L>& p4 )
{
  cynw_wait_can_get( p1.output, p2.output, p3.output, p4.output );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_L, int CYN_N>
void cynw_wait_can_get( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3, cynw_fifo_direct<CYN_T4,CYN_N,CYN_L>& p4, cynw_fifo_direct<CYN_T5,CYN_N,CYN_L>& p5 )
{
  cynw_wait_can_get( p1.output, p2.output, p3.output, p4.output,
		      p5.output );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_L, int CYN_N>
void cynw_wait_can_get( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3, cynw_fifo_direct<CYN_T4,CYN_N,CYN_L>& p4, cynw_fifo_direct<CYN_T5,CYN_N,CYN_L>& p5, cynw_fifo_direct<CYN_T6,CYN_N,CYN_L>& p6 )
{
  cynw_wait_can_get( p1.output, p2.output, p3.output, p4.output,
		      p5.output, p6.output );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_L, int CYN_N>
void cynw_wait_can_get( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3, cynw_fifo_direct<CYN_T4,CYN_N,CYN_L>& p4, cynw_fifo_direct<CYN_T5,CYN_N,CYN_L>& p5, cynw_fifo_direct<CYN_T6,CYN_N,CYN_L>& p6, cynw_fifo_direct<CYN_T7,CYN_N,CYN_L>& p7 )
{
  cynw_wait_can_get( p1.output, p2.output, p3.output, p4.output,
		      p5.output, p6.output, p7.output );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8, class CYN_L, int CYN_N>
void cynw_wait_can_get( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3, cynw_fifo_direct<CYN_T4,CYN_N,CYN_L>& p4, cynw_fifo_direct<CYN_T5,CYN_N,CYN_L>& p5, cynw_fifo_direct<CYN_T6,CYN_N,CYN_L>& p6, cynw_fifo_direct<CYN_T7,CYN_N,CYN_L>& p7, cynw_fifo_direct<CYN_T8,CYN_N,CYN_L>& p8 )
{
  cynw_wait_can_get( p1.output, p2.output, p3.output, p4.output,
		      p5.output, p6.output, p7.output, p8.output );
}


//
// Specializations for cynw_wait_can_put() for cynw_fifo_direct.
//
template <class CYN_T1,class CYN_L, int CYN_N>
void cynw_wait_can_put( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1 )
{
  cynw_wait_can_put( p1.input );
}

template <class CYN_T1, class CYN_T2, class CYN_L, int CYN_N>
void cynw_wait_can_put( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2 )
{
  cynw_wait_can_put( p1.input, p2.input );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_L, int CYN_N>
void cynw_wait_can_put( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3 )
{
  cynw_wait_can_put( p1.input, p2.input, p3.input );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_L, int CYN_N>
void cynw_wait_can_put( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3, cynw_fifo_direct<CYN_T4,CYN_N,CYN_L>& p4 )
{
  cynw_wait_can_put( p1.input, p2.input, p3.input, p4.input );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_L, int CYN_N>
void cynw_wait_can_put( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3, cynw_fifo_direct<CYN_T4,CYN_N,CYN_L>& p4, cynw_fifo_direct<CYN_T5,CYN_N,CYN_L>& p5 )
{
  cynw_wait_can_put( p1.input, p2.input, p3.input, p4.input,
		      p5.input );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_L, int CYN_N>
void cynw_wait_can_put( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3, cynw_fifo_direct<CYN_T4,CYN_N,CYN_L>& p4, cynw_fifo_direct<CYN_T5,CYN_N,CYN_L>& p5, cynw_fifo_direct<CYN_T6,CYN_N,CYN_L>& p6 )
{
  cynw_wait_can_put( p1.input, p2.input, p3.input, p4.input,
		      p5.input, p6.input );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_L, int CYN_N>
void cynw_wait_can_put( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3, cynw_fifo_direct<CYN_T4,CYN_N,CYN_L>& p4, cynw_fifo_direct<CYN_T5,CYN_N,CYN_L>& p5, cynw_fifo_direct<CYN_T6,CYN_N,CYN_L>& p6, cynw_fifo_direct<CYN_T7,CYN_N,CYN_L>& p7 )
{
  cynw_wait_can_put( p1.input, p2.input, p3.input, p4.input,
		      p5.input, p6.input, p7.input );
}

template <class CYN_T1, class CYN_T2, class CYN_T3, class CYN_T4, class CYN_T5, class CYN_T6, class CYN_T7, class CYN_T8, class CYN_L, int CYN_N>
void cynw_wait_can_put( cynw_fifo_direct<CYN_T1,CYN_N,CYN_L>& p1, cynw_fifo_direct<CYN_T2,CYN_N,CYN_L>& p2, cynw_fifo_direct<CYN_T3,CYN_N,CYN_L>& p3, cynw_fifo_direct<CYN_T4,CYN_N,CYN_L>& p4, cynw_fifo_direct<CYN_T5,CYN_N,CYN_L>& p5, cynw_fifo_direct<CYN_T6,CYN_N,CYN_L>& p6, cynw_fifo_direct<CYN_T7,CYN_N,CYN_L>& p7, cynw_fifo_direct<CYN_T8,CYN_N,CYN_L>& p8 )
{
  cynw_wait_can_put( p1.input, p2.input, p3.input, p4.input,
		      p5.input, p6.input, p7.input, p8.input );
}

////////////////////////////////////////////////////////////
//
// class: cynw_fifo_direct_in<T,N,PIN>
//
// kind:
//
//   metaport
//
// summary: 
//
//   An input metaport containing a fifo.
//
// template parameters:
//
//   T : The data type carried across the channel.
//   N : The depth of the fifo.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//  This class can be instantiated as an input metaport for connection
//  to a cynw_p2p<T> channel.  It also contains a built-in fifo that
//  can be accessed like cynw_fifo_direct<T,N,L>. 
//
// example:
//
//   SC_MODULE(M)
//   {
//     // Instantiate A cynw_fifo_direct_in<>.
//     // This will act as an input metaport that can be connected
//     // to any cynw_p2p<> compatible channel.
//     cynw_fifo_direct_in< sc_uint<32>, 16 > din;
//
//     // Other ports.
//     cynw_p2p< sc_uint<32> >::base_out dout;
//     sc_in_clk clk;
//     sc_in<bool> reset;
//    
//     SC_CTOR(dut)
//       : din("din"), dout("dout")
//     {
//    	// Clock and reset must be connected to the cynw_fifo_direct_in<>.
//    	din.clk_rst( clk, reset );
//    
//    	SC_CTHREAD(exec2,clk.pos());
//    	watching( reset.delayed() == 0 );
//     }
//     void exec2()
//     {
//       din.reset();
//       dout.reset();
//       {HLS_DEFINE_PROTOCOL("reset"); wait();}
//    
//       while (1)
//       {
//    	   // Reading from the din port reads from the fifo in the port.
//    	   sc_uint<32> d = din.get();
//    	   dout.put( d+1 );
//       }
//     }
//   };
//
////////////////////////////////////////////////////////////
template <class T, int CYN_N, typename CYN_L=CYN::PIN>
class cynw_fifo_direct_in
  : public cynw_p2p_in_redir<T,CYN_L>,
    public cynw_clk_rst
{
  public:
    HLS_EXPOSE_PORTS( OFF, clk, rst );

    typedef cynw_fifo_direct<T,CYN_N,CYN_L>   this_type;
    typedef cynw_p2p_in_redir<T,CYN_L>    redir_type;

    cynw_fifo_direct_in( sc_module_name name=sc_module_name(sc_gen_unique_name("cynw_fifo_direct_in")), 
	                 unsigned options_in=0 )
      : redir_type(HLS_CAT_NAMES(name,"io"),true),
	cynw_clk_rst(name),
	m_fifo(name),
        output( HLS_CAT_NAMES(name,"output"), options_in )
    {
      // Bind the fifo to the direct-access port and to the redir port.
      output( m_fifo.output );
      redir_in( m_fifo.input );

      // Route clk and rst to the fifo and the ports.
      output.clk_rst( *this );
      m_fifo.clk_rst(*this);
    }

    //
    // Output port.
    //
    // This port can be used to access the fifo directly from threads 
    // in the same module.
    //
    cynw_p2p_in<T,CYN_L> output;

    //
    // Provide a set of functions implementing the the cynw_p2p_in_if
    // proxied to the output port.
    //
    CYNW_P2P_IN_DIRECT_PROXY_FUNCS
    
    void reset()
    {
      output.reset();
    }

    CYNW_CLK_RST_FUNCS

  protected:
    // 
    // The fifo itself.
    //
    class cynw_fifo<T,CYN_N,CYN_L> m_fifo;
};


////////////////////////////////////////////////////////////
//
// class: cynw_fifo_direct_in<T,N,TLM>
//
// kind:
//
//   metaport
//
// summary: 
//
//   TLM version of cynw
//
// template parameters:
//
//   T : The data type carried across the channel.
//   N : The depth of the fifo.
//   L : Specify TLM to select this version.
//
// details:
//
//  This class is a TLM version of cynw_fifo_direct_in<T,N,PIN>.
//  It contains a cynw_fifo_direct<T,N,TLM>.  It is plug-replacible with
//  cynw_fifo_direct_in<T,N,PIN>.
//
// example:
//
//
////////////////////////////////////////////////////////////
template <class T, int CYN_N>
class cynw_fifo_direct_in<T,CYN_N,CYN::TLM>
  : public cynw_p2p_in_redir<T,CYN::TLM>
{
  public:
    typedef cynw_fifo_direct<T,CYN_N,CYN::TLM>   this_type;
    typedef cynw_p2p_in_redir<T,CYN::TLM>    redir_type;

    cynw_fifo_direct_in( sc_module_name name=sc_module_name(sc_gen_unique_name("cynw_fifo_direct_in")), 
	                 unsigned options_in=0 )
      : redir_type(HLS_CAT_NAMES(name,"io"),true),
        m_fifo(name),
	output( HLS_CAT_NAMES(name,"output"), options_in )
    {
      // Bind the fifo to the direct-access port and to the redir port.
      output( m_fifo.output );
      redir_in( m_fifo.input );
    }

    //
    // Output port.
    //
    // This port can be used to access the fifo directly from threads 
    // in the same module.
    //
    cynw_p2p_in<T,CYN::TLM> output;

    //
    // Provide a set of functions implementing the the cynw_p2p_in_if
    // proxied to the output port.
    //
    CYNW_P2P_IN_DIRECT_PROXY_FUNCS
    
    void reset()
    {
    }

    CYNW_CLK_RST_FACADE_FUNCS

  protected:
    // 
    // The fifo itself.
    //
    class cynw_fifo<T,CYN_N,CYN::TLM> m_fifo;
};


////////////////////////////////////////////////////////////
//
// class: cynw_fifo_direct_out<T,N,PIN>
//
// kind:
//
//   metaport
//
// summary: 
//
//   An output metaport containing a fifo.
//
// template parameters:
//
//   T : The data type carried across the channel.
//   N : The depth of the fifo.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//  This class can be instantiated as an output metaport for connection
//  to a cynw_p2p<T> channel.  It also contains a built-in fifo that
//  can be accessed like cynw_fifo_direct<T,N,L>. 
//
// example:
//
//   SC_MODULE(M)
//   {
//     // Instantiate A cynw_fifo_direct_out<>.
//     // This will act as an output metaport that can be connected
//     // to any cynw_p2p<> compatible channel.
//     cynw_fifo_direct_out< sc_uint<32>, 16 > dout;
//
//     // Other ports.
//     cynw_p2p< sc_uint<32> >::base_in din;
//     sc_in_clk clk;
//     sc_in<bool> reset;
//    
//     SC_CTOR(dut)
//       : din("din"), dout("dout")
//     {
//    	// Clock and reset must be connected to the cynw_fifo_direct_out<>.
//    	dout.clk_rst( clk, reset );
//    
//    	SC_CTHREAD(exec2,clk.pos());
//    	watching( reset.delayed() == 0 );
//     }
//     void exec2()
//     {
//       din.reset();
//       dout.reset();
//       {HLS_DEFINE_PROTOCOL("reset"); wait();}
//    
//       while (1)
//       {
//    	   // Writing from the dout port writes to the fifo in the port.
//    	   sc_uint<32> d = din.get();
//    	   dout.put( d+1 );
//       }
//     }
//   };
//
////////////////////////////////////////////////////////////
template <class T, int CYN_N, typename CYN_L=CYN::PIN>
class cynw_fifo_direct_out
  : public cynw_p2p_out_redir<T,CYN_L>,
    public cynw_clk_rst
{
  public:
    HLS_EXPOSE_PORTS( OFF, clk, rst );

    typedef cynw_fifo_direct<T,CYN_N,CYN_L>   this_type;
    typedef cynw_p2p_out_redir<T,CYN_L>    redir_type;

    cynw_fifo_direct_out( sc_module_name name=sc_module_name(sc_gen_unique_name("cynw_fifo_direct_out")), 
	                  unsigned options_in=0 )
      : redir_type(HLS_CAT_NAMES(name,"io"),true),
	cynw_clk_rst(name),
        m_fifo(name),
        input( HLS_CAT_NAMES(name,"input"), options_in )
    {
      // Bind the fifo to the direct-access port and to the redir port.
      input( m_fifo.input );
      redir_out( m_fifo.output );

      // Route clk and rst to the fifo and the ports.
      input.clk_rst( *this );
      m_fifo.clk_rst(*this);
    }

    //
    // Output port.
    //
    // This port can be used to access the fifo directly from threads 
    // in the same module.
    //
    cynw_p2p_out<T,CYN_L> input;

    //
    // Provide a set of functions implementing the the cynw_p2p_out_if
    // proxied to the input ports.
    //
    CYNW_P2P_OUT_DIRECT_PROXY_FUNCS
    
    void reset()
    {
      input.reset();
    }

    CYNW_CLK_RST_FUNCS

  protected:
    // 
    // The fifo itself.
    //
    class cynw_fifo<T,CYN_N,CYN_L> m_fifo;
};


////////////////////////////////////////////////////////////
//
// class: cynw_fifo_direct_out<T,N,TLM>
//
// kind:
//
//   metaport
//
// summary: 
//
//   TLM version of cynw
//
// template parameters:
//
//   T : The data type carried across the channel.
//   N : The depth of the fifo.
//   L : Specify TLM to select this version.
//
// details:
//
//  This class is a TLM version of cynw_fifo_direct_out<T,N,PIN>.
//  It contains a cynw_fifo_direct<T,N,TLM>.  It is plug-replacible with
//  cynw_fifo_direct_out<T,N,PIN>.
//
// example:
//
//
////////////////////////////////////////////////////////////
template <class T, int CYN_N>
class cynw_fifo_direct_out<T,CYN_N,CYN::TLM>
  : public cynw_p2p_out_redir<T,CYN::TLM>
{
  public:
    typedef cynw_fifo_direct<T,CYN_N,CYN::TLM>   this_type;
    typedef cynw_p2p_out_redir<T,CYN::TLM>    redir_type;

    cynw_fifo_direct_out( sc_module_name name=sc_module_name(sc_gen_unique_name("cynw_fifo_direct_out")), 
			  unsigned options_in=0 )
      : redir_type(HLS_CAT_NAMES(name,"io"),true),
        m_fifo(name),
	input( HLS_CAT_NAMES(name,"input"), options_in )
    {
      // Bind the fifo to the direct-access port and to the redir port.
      input( m_fifo.input );
      redir_out( m_fifo.output );
    }

    //
    // Output port.
    //
    // This port can be used to access the fifo directly from threads 
    // in the same module.
    //
    cynw_p2p_out<T,CYN::TLM> input;

    //
    // Provide a set of functions implementing the the cynw_p2p_out_if
    // proxied to the input ports.
    //
    CYNW_P2P_OUT_DIRECT_PROXY_FUNCS
    
    void reset()
    {
    }

    //CYNW_CLK_RST_FACADE_FUNCS
    
  protected:
    // 
    // The fifo itself.
    //
    class cynw_fifo<T,CYN_N,CYN::TLM> m_fifo;
};


////////////////////////////////////////////////////////////
//
// class: cynw_stall_fifo<T,N,PIN>
//
// kind:
//
//   channel
//
// summary: 
//
//   FIFO designed to be attached to the output of a multi-cycle
//   component to store values while the reader is stalled.
//
// template parameters:
//
//   T : The data type of the output of the component.
//   N : The depth of the fifo.  
//       This should match the latency of the component whose output
//       is being stored.
//   L : The abstraction level: TLM or PIN.  Default is PIN.
//
// details:
//
//  The cynw_stall_fifo class is an inline module that's designed
//  to be instantiated in a metaport that accesses a stallable
//  component.  It should be connected as follows:
//
//  sc_in<T> din
//
//    Should be bound to either an input port or a signal that carries
//    the output of the target component.
//
//  sc_out<T> dout
//
//    Should be bound to either an output port or a signal that will
//    be read from the stallable thread.  This output should be 
//    used as would the output of the target component.
//
//  sc_in<bool> stalling
//    
//    Should be bound to either an input port or a signal that is
//    asserted whenever the accessing thread is stalled. 
//
//  sc_in<bool> start
//    
//    Should be bound to either an input port or a signal that is
//    asserted during the cycle when a transaction is being started,
//    and deasserted when no transaction is being started.
//    Need not be deasserted during a stall.
//
//  sc_in<bool> end
//    
//    Should be bound to either an input port or a signal that is
//    asserted during the cycle when a transaction's output is being
//    read and deasserted when the output will not be read.
//    Need not be deasserted during a stall.
//
//  sc_out<bool> running
//   
//    Indicates that a transaction is in progress on the target componenent.
//    This will be true for N cycles after a cycle where 'start' is
//    asserted.  This is useful for applications, like a CE on a memory,
//    that can be deasserted after all started transactions have completed
//    and the accessing thread is stalling.
//
// example:
//
//  Metaport for accessing an external memory that can also be stalled.
//
//
#define sensitive base_type::sensitive

template <class T, int CYN_N, typename CYN_L=CYN::PIN>
class cynw_stall_fifo
  : public cynw_fifo<T,CYN_N,CYN_L>
{
  public:
    SC_HAS_PROCESS(cynw_stall_fifo);

    typedef cynw_stall_fifo<T,CYN_N,CYN_L>    this_type;
    typedef cynw_fifo<T,CYN_N,CYN_L>          base_type;
    typedef base_type                 fifo_type;
    
    sc_in<bool> stalling;
    sc_in<bool> start;
    sc_in<bool> end;
    sc_out<bool> running;
    sc_in<T> din;
    sc_out<T> dout;
    
    cynw_stall_fifo( const char* name=sc_gen_unique_name("cynw_stall_fifo") )
      : base_type( name, true ),
        m_active_shift_reg( HLS_CAT_NAMES(name,"m_active_shift_reg") ),
        m_reading_shift_reg( HLS_CAT_NAMES(name,"m_reading_shift_reg") )
    {
      SC_METHOD(vld_in_thread);
      sensitive << m_active_shift_reg;

      SC_METHOD(running_thread);
      sensitive << m_active_shift_reg;

      SC_METHOD(busy_out_thread);
      sensitive << m_reading_shift_reg;
      sensitive << stalling;
    
      SC_METHOD(din_thread);
      sensitive << din;

      SC_METHOD(dout_thread);
      sensitive << base_type::output.data;

      SC_METHOD(shift_thread);
      sensitive << base_type::clk.pos();
      base_type::dont_initialize();
    }

    //
    // Asynchronous SC_METHOD
    //
    // Wires the din port, which is the output of the target component,
    // to the input of the fifo.
    //
    void din_thread()
    {
        base_type::input.data.write( din.read() );
    }

    //
    // Asynchronous SC_METHOD
    //
    // Wires the fifo's output to the dout port.
    //
    void dout_thread()
    {
        dout.write( base_type::output.data.read() );
    }

    //
    // Synchronous SC_METHOD
    //
	// This method updates two shift registers that track state relative to the 
	// fifo.
	//
	// 1. m_active_shift_reg
	//
	//    This register captures when valid transactions are being executed by the
    //    target component.  A '1' is written to the LSB in cycles when 'start' is
    //    asserted, but the stall is not.  The register is N bits wide, and is
    //    shifted once per cycle.  The LSB will contain a '1' if the target
    //    component should be completing a valid transaction.
	//
	// 2. m_reading_shift_reg
	//
	//    This register captures when the reading thread is expected to be 
	//    reading a value from the FIFO.  It operates similarly to m_active_shift_reg,
	//    but it does not actually shift when the stall is active. This will result
	//    in a bit being set N+nStall cycles after an operation is started where nStall
	//    is the number of cycles that the accessing thread is stalled.
    //
    void shift_thread() 
    {
      if ( this->rst_active() ) {
	HLS_SET_IS_RESET_BLOCK("shift_thread");
        m_active_shift_reg.write( 0 );
	m_reading_shift_reg.write( 0 );
      } else {
	HLS_REMOVE_CONTROL(ON,"");
	bool new_bit = ( !stalling.read() && start.read() );
        m_active_shift_reg.write( (m_active_shift_reg.read() << 1) | new_bit );
	if ( !stalling.read() ) 
	  m_reading_shift_reg.write( (m_reading_shift_reg.read() << 1) | new_bit );
      }
    }
      
    //
    // Asynchronous SC_METHOD
    //
    // Connnects the output of the stall shift register to the 
    // vld input of the fifo.  If a 1 comes out of the shift
    // register, a stall was not in progress when the transaction
    // was started, so it is valid data.
    //
    void vld_in_thread() 
    {
	bool v = m_active_shift_reg.read()[CYN_N-1];
        base_type::input.vld.write( v );
    }

    //
    // Asynchronous SC_METHOD
    //
    // Asserts the 'running' output whenever there is a bit stored in the 
    // m_active_shift_reg register.
    //
    void running_thread() 
    {
      running.write( m_active_shift_reg.read() != 0 );
    }

    //
    // Asynchronous SC_METHOD
    //
    // It is assumed that the FIFO is being read by its reader
    // when the last bit of m_reading_shift_reg is set and a 
    // stall is not occuring.
    //
    void busy_out_thread()
    {
        base_type::output.busy.write( !m_reading_shift_reg.read()[CYN_N-1]  || stalling.read() );
    }

    void trace_on()
    {
      base_type::trace_on();
      esc_trace_signal( &m_active_shift_reg, (sc_string(base_type::name())+".m_active_shift_reg").c_str(), esc_trace_vcd );
      esc_trace_signal( &this_type::stalling, (sc_string(base_type::name())+".stalling").c_str(), esc_trace_vcd );
    }

  protected:
    sc_signal< sc_uint<CYN_N> > m_active_shift_reg;
    sc_signal< sc_uint<CYN_N> > m_reading_shift_reg;
};

#undef sensitive

// 
// sc_trace specializations
//

#ifndef STRATUS
#define CYNW_FIFO_SC_TRACE(cynw_class) \
template <typename T, int CYN_N> \
void sc_trace( sc_trace_file *tf, const cynw_class<T,CYN_N,CYN::PIN>& obj, const std::string& n ) { \
  sc_trace( tf, obj.input, n + ".input" ); \
  sc_trace( tf, obj.output, n + ".output" ); \
} \
template <typename T, int CYN_N> \
void sc_trace( sc_trace_file *tf, const cynw_class<T,CYN_N,CYN::TLM>& obj, const std::string& n ) {}

#else 
#define CYNW_FIFO_SC_TRACE(cynw_class) \
template <typename T, int CYN_N> \
void sc_trace( sc_trace_file *tf, const cynw_class<T,CYN_N,CYN::PIN>& obj, const std::string& n ) {} \
template <typename T, int CYN_N> \
void sc_trace( sc_trace_file *tf, const cynw_class<T,CYN_N,CYN::TLM>& obj, const std::string& n ) {}

#endif

CYNW_FIFO_SC_TRACE(cynw_fifo)
CYNW_FIFO_SC_TRACE(cynw_fifo_direct)

};

#endif
