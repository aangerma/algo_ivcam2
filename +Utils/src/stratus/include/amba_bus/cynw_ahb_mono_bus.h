/****************************************************************************
*
*  Copyright (C) 2006, Forte Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Forte Design Systems.
*
****************************************************************************/

#if !defined(cynw_ahb_mono_bus_h_INCLUDED)
#define cynw_ahb_mono_bus_h_INCLUDED

#include "amba_bus/amba_ahb_interfaces.h"
#include "amba_bus/amba_ahb_ports.h"
#include "cyn_enums.h"
#include "cynw_ahb_master.h"
#include "cynw_stream_helpers.h"

using namespace amba;
using cynw::out_format;
using cynw::out_text;

#define LOG2_SLAVES 4               // Log 2 of number of slaves to support.
#define SLAVES_N (1 << LOG2_SLAVES) // Number of slaves to support.

#define DEBUG_VERIFY_AHB_MASTER false

#define LOG_ERROR( MSG ) \
	log_error( MSG, __FILE__, __LINE__, m_state, m_start_time )

#define TRACE_N 128

template<typename LEVEL> class cynw_ahb_mono_bus;


//==============================================================================
// cynw_dummy_ahb_master
//==============================================================================
class cynw_dummy_ahb_master : public cynw_ahb_master_if, public sc_prim_channel
{
  public:
  	cynw_dummy_ahb_master( const char* name_p ) : sc_prim_channel(name_p) {}
	virtual ~cynw_dummy_ahb_master() {}

  public:
  	virtual bool read( const sc_uint<32>& addr, sc_uint<8>& data )
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool read( const sc_uint<32>& addr, sc_uint<16>& data )
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool read( const sc_uint<32>& addr, sc_uint<32>& data )
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}

  	virtual bool read(const sc_uint<32>& addr, unsigned int, sc_uint<8>*)
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool read(const sc_uint<32>& addr, unsigned int, sc_uint<16>*)
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool read(const sc_uint<32>& addr, unsigned int, sc_uint<32>*)
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}

  	virtual bool read_wrap(
		const sc_uint<32>& addr, unsigned int, sc_uint<8>*)
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool read_wrap(
		const sc_uint<32>& addr, unsigned int, sc_uint<16>*)
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool read_wrap(
		const sc_uint<32>& addr, unsigned int, sc_uint<32>*)
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}

	virtual void reset()
	{
		cerr << "Accessing unconnected port" << endl;
	}

  	virtual bool write( const sc_uint<32>& addr, const sc_uint<8>& data )
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool write( const sc_uint<32>& addr, const sc_uint<16>& data )
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool write( const sc_uint<32>& addr, const sc_uint<32>& data )
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}

  	virtual bool write(
		const sc_uint<32>& addr, unsigned int, const sc_uint<8>* )
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool write(
		const sc_uint<32>& addr, unsigned int, const sc_uint<16>* )
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool write(
		const sc_uint<32>& addr, unsigned int, const sc_uint<32>* )
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}

  	virtual bool write_wrap(
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<8>* data_p )
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool write_wrap(
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<16>* data_p)
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}
  	virtual bool write_wrap(
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p)
	{
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << addr << endl;
		return true;
	}

  private:
  	cynw_dummy_ahb_master( const cynw_dummy_ahb_master& );
  	const cynw_dummy_ahb_master& operator = ( const cynw_dummy_ahb_master& );
};

//==============================================================================
// cynw_ahb_mono_bus<TLM_PASS_THRU> - 
//           TRANSACTION-LEVEL MODEL OF SINGLE MASTER/SINGLE SLAVE AHB BUS
//
//==============================================================================

template<>
class cynw_ahb_mono_bus<TLM_PASS_THRU> : 
	public cynw_ahb_master_if, public sc_prim_channel
{
  public: // constructor and destructor:
  	cynw_ahb_mono_bus( const char* name_p ) : 
		sc_prim_channel(name_p),
		m_dummy_slave("dummy_slave")
	{
		m_masters_n = 0;
		m_slaves_n = 0;
		m_reset = true;
	}
	virtual ~cynw_ahb_mono_bus()
	{
	}

  public: // binding of masters and slaves:
	void add_master( sc_port<cynw_ahb_master_if,1>& master );
	// #### void add_slave( cynw_ahb_master_if& slave );
	void add_slave( sc_export<cynw_ahb_master_if>& slave );
	virtual void before_end_of_elaboration();

  public: // bus support:
    unsigned int address_decode( const sc_uint<32>& addr );
	inline ostream& annotate() { return cout; }
	inline sc_signal<bool>& reset_signal() { return m_reset; }

  public: // cynw_ahb_master_if methods:
    virtual bool read( const sc_uint<32>& addr, sc_uint<8>& data );
    virtual bool read( const sc_uint<32>& addr, sc_uint<16>& data );
    virtual bool read( const sc_uint<32>& addr, sc_uint<32>& data );

    virtual bool read( const sc_uint<32>&, unsigned int, sc_uint<8>* );
    virtual bool read( const sc_uint<32>&, unsigned int, sc_uint<16>* );
    virtual bool read( const sc_uint<32>&, unsigned int, sc_uint<32>* );

    virtual bool read_wrap( const sc_uint<32>&, unsigned int, sc_uint<8>* );
    virtual bool read_wrap( const sc_uint<32>&, unsigned int, sc_uint<16>* );
    virtual bool read_wrap( const sc_uint<32>&, unsigned int, sc_uint<32>* );

    virtual void reset();

    virtual bool write( const sc_uint<32>& addr, const sc_uint<8>& data );
    virtual bool write( const sc_uint<32>& addr, const sc_uint<16>& data );
    virtual bool write( const sc_uint<32>& addr, const sc_uint<32>& data );

    virtual bool write( const sc_uint<32>&, unsigned int, const sc_uint<8>* );
    virtual bool write( const sc_uint<32>&, unsigned int, const sc_uint<16>* );
    virtual bool write( const sc_uint<32>&, unsigned int, const sc_uint<32>* );

    virtual bool write_wrap( 
		const sc_uint<32>&, unsigned int, const sc_uint<8>* );
    virtual bool write_wrap( 
		const sc_uint<32>&, unsigned int, const sc_uint<16>* );
    virtual bool write_wrap( 
		const sc_uint<32>&, unsigned int, const sc_uint<32>* );

  public: // Signals bound to dut ports.
  	sc_in<bool>                   m_clk;          // Clock.
	sc_signal<bool>               m_reset;        // Reset signal.

  protected: // storage:
	cynw_dummy_ahb_master         m_dummy_slave;      // Unconnected slave(s).
	unsigned int                  m_masters_n;        // Number of masters.
	sc_port<cynw_ahb_master_if,1> m_slaves[SLAVES_N]; // Ports connecting slaves
	unsigned int                  m_slaves_n;         // Number of slaves.

  private: // disabled:
  	cynw_ahb_mono_bus( const cynw_ahb_mono_bus& );
  	const cynw_ahb_mono_bus& operator = ( const cynw_ahb_mono_bus& );
};

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_PASS_THRU>::address_decode"
//------------------------------------------------------------------------------
inline unsigned int cynw_ahb_mono_bus<TLM_PASS_THRU>::address_decode( const sc_uint<32>& addr )
{
	return addr(31,28);
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_PASS_THRU>::
//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<TLM_PASS_THRU>::add_master(sc_port<cynw_ahb_master_if,1>& master)
{
	if ( m_masters_n >= 16 ) 
	{
		cerr << "cynw_ahb_mono_bus<TLM_PASS_THRU>::add_master - attempt to add more than 16 "
		     << " masters " << endl;
	}
	m_masters_n++;
	master(*this);
}


//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_PASS_THRU>::add_slave"
//------------------------------------------------------------------------------
#if 0
inline void cynw_ahb_mono_bus<TLM_PASS_THRU>::add_slave( 
	cynw_ahb_master_if& slave )
{
	if ( m_slaves_n >= 16 ) 
	{
		cerr << "cynw_ahb_mono_bus<TLM_PASS_THRU>::add_slave - attempt to add more than 16 "
		     << " slaves " << endl;
	}
	m_slaves[m_slaves_n](slave);
	m_slaves_n++;
}
#endif //0

inline void cynw_ahb_mono_bus<TLM_PASS_THRU>::add_slave( 
	sc_export<cynw_ahb_master_if>& slave )
{
	if ( m_slaves_n >= 16 ) 
	{
		cerr << "cynw_ahb_mono_bus<TLM_PASS_THRU>::add_slave - attempt to add more than 16 "
		     << " slaves " << endl;
	}
	m_slaves[m_slaves_n](slave);
	m_slaves_n++;
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_PASS_THRU>::before_end_of_elaboration"
//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<TLM_PASS_THRU>::before_end_of_elaboration()
{
	for ( unsigned int slave_i = m_slaves_n; slave_i < SLAVES_N; slave_i++ )
	{
		m_slaves[slave_i](m_dummy_slave);
	}
}


//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_PASS_THRU>::read - single value"
//------------------------------------------------------------------------------
inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::read( 
	const sc_uint<32>& addr, sc_uint<8>& data )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->read(addr, data );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::read( 
	const sc_uint<32>& addr, sc_uint<16>& data )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->read(addr, data );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::read( 
	const sc_uint<32>& addr, sc_uint<32>& data )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->read(addr, data );
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_PASS_THRU>::read"
//------------------------------------------------------------------------------
inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::read( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<8>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->read(addr, data_n, data_p );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::read( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<16>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->read(addr, data_n, data_p );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::read( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<32>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->read(addr, data_n, data_p );
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_PASS_THRU>::read_wrap"
//------------------------------------------------------------------------------
inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::read_wrap( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<8>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->read_wrap(addr, data_n, data_p );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::read_wrap( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<16>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->read_wrap(addr, data_n, data_p );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::read_wrap( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<32>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->read_wrap(addr, data_n, data_p );
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_PASS_THRU>::reset"
//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<TLM_PASS_THRU>::reset()
{
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_PASS_THRU>::write - single value"
//------------------------------------------------------------------------------
inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::write( 
	const sc_uint<32>& addr, const sc_uint<8>& data )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->write(addr, data );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::write( 
	const sc_uint<32>& addr, const sc_uint<16>& data )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->write(addr, data );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::write( 
	const sc_uint<32>& addr, const sc_uint<32>& data )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->write(addr, data );
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_PASS_THRU>::write"
//------------------------------------------------------------------------------
inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::write( 
	const sc_uint<32>& addr, unsigned int data_n, const sc_uint<8>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->write(addr, data_n, data_p );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::write( 
	const sc_uint<32>& addr, unsigned int data_n, const sc_uint<16>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->write(addr, data_n, data_p );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::write( 
	const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->write(addr, data_n, data_p );
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_PASS_THRU>::write_wrap"
//------------------------------------------------------------------------------
inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::write_wrap( 
	const sc_uint<32>& addr, unsigned int data_n, const sc_uint<8>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->write_wrap(addr, data_n, data_p );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::write_wrap( 
	const sc_uint<32>& addr, unsigned int data_n, const sc_uint<16>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->write_wrap(addr, data_n, data_p );
}

inline bool cynw_ahb_mono_bus<TLM_PASS_THRU>::write_wrap( 
	const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p )
{
	unsigned int slave_i = address_decode(addr);
	return m_slaves[slave_i]->write_wrap(addr, data_n, data_p );
}

//==============================================================================
// osci_tlm_dummy_ahb_slave
//==============================================================================
class osci_tlm_dummy_ahb_slave : 
    public osci_tlm_ahb_transport_if,
    public sc_prim_channel
{
  public:
  	osci_tlm_dummy_ahb_slave( const char* name_p ) : sc_prim_channel(name_p) {}
	virtual ~osci_tlm_dummy_ahb_slave() {}

  public:
  	virtual osci_tlm_ahb_response  transport( const osci_tlm_ahb_request& req )
	{
		osci_tlm_ahb_response response;
		cerr << "Accessing unconnected port: ahb address = " 
		     << hex << req.m_address << endl;
		response.m_error = true;
		return response;
	}

	virtual void reset()
	{
		cerr << "Accessing unconnected port" << endl;
	}

  private:
  	osci_tlm_dummy_ahb_slave( const osci_tlm_dummy_ahb_slave& );
  	const osci_tlm_dummy_ahb_slave& operator = ( 
		const osci_tlm_dummy_ahb_slave& );
};

//==============================================================================
// cynw_ahb_mono_bus<TLM_PASS_THRU> - 
//           TRANSACTION-LEVEL MODEL OF SINGLE MASTER/SINGLE SLAVE AHB BUS
//
//==============================================================================
template<>
class cynw_ahb_mono_bus<TLM_OSCI> :
	public osci_tlm_ahb_transport_if, 
	public sc_prim_channel
{
  public: // constructor and destructor:
  	cynw_ahb_mono_bus( const char* name_p ) : 
		sc_prim_channel(name_p),
		m_dummy_slave("dummy_slave")
	{
		m_masters_n = 0;
		m_slaves_n = 0;
		m_reset = true;
	}
	virtual ~cynw_ahb_mono_bus()
	{
	}

  public: // binding of masters and slaves:
	void add_master( sc_port<osci_tlm_ahb_transport_if,1>& master );
	// #### void add_slave( osci_tlm_ahb_transport_if& slave );
	void add_slave( sc_export<osci_tlm_ahb_transport_if>& slave );
	virtual void before_end_of_elaboration();
	inline ostream& annotate() { return cout; }

  public: // bus support:
    unsigned int address_decode( const sc_uint<32>& addr );

  public: // transport methods:
    virtual osci_tlm_ahb_response transport( const osci_tlm_ahb_request& req );

  public: 
  	sc_in<bool>               m_clk;          // Compatibility w/other levels.
	sc_signal<bool>           m_reset;        // Compatibility w/other levels.

  protected: // storage:
	osci_tlm_dummy_ahb_slave  m_dummy_slave;      // Unconnected slave(s).
	unsigned int              m_masters_n;        // Number of masters.
	osci_tlm_ahb_port         m_slaves[SLAVES_N]; // Slave ports.
	unsigned     int          m_slaves_n;         // Number of slaves.

  private: // disabled:
  	cynw_ahb_mono_bus( const cynw_ahb_mono_bus& );
  	const cynw_ahb_mono_bus& operator = ( const cynw_ahb_mono_bus& );
};

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_OSCI>::address_decode"
//------------------------------------------------------------------------------
inline unsigned int cynw_ahb_mono_bus<TLM_OSCI>::address_decode( const sc_uint<32>& addr )
{
	return addr(31,28);
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_OSCI>::add_master"
//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<TLM_OSCI>::add_master(
	sc_port<osci_tlm_ahb_transport_if,1>& master)
{
	if ( m_masters_n >= 16 ) 
	{
		cerr << "cynw_ahb_mono_bus<TLM_OSCI>::add_master - attempt to add more than 16 "
		     << " masters " << endl;
	}
	m_masters_n++;
	master(*this);
}


//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_OSCI>::add_slave"
//------------------------------------------------------------------------------
#if 0
inline void 
cynw_ahb_mono_bus<TLM_OSCI>::add_slave( osci_tlm_ahb_transport_if& slave )
{
	if ( m_slaves_n >= 16 ) 
	{
		cerr << "cynw_ahb_mono_bus<TLM_OSCI>::add_slave - attempt to add more than 16 "
		     << " slaves " << endl;
	}
	m_slaves[m_slaves_n](slave);
	m_slaves_n++;
}
#endif // 0

inline void cynw_ahb_mono_bus<TLM_OSCI>::add_slave( 
	sc_export<osci_tlm_ahb_transport_if>& slave )
{
	if ( m_slaves_n >= 16 ) 
	{
		cerr << "cynw_ahb_mono_bus<TLM_OSCI>::add_slave - attempt to add more than 16 "
		     << " slaves " << endl;
	}
	m_slaves[m_slaves_n](slave);
	m_slaves_n++;
}


//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_OSCI>::before_end_of_elaboration"
//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<TLM_OSCI>::before_end_of_elaboration()
{
	for ( unsigned int slave_i = m_slaves_n; slave_i < SLAVES_N; slave_i++ )
	{
		m_slaves[slave_i](m_dummy_slave);
	}
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<TLM_OSCI>::transport"
//------------------------------------------------------------------------------
inline osci_tlm_ahb_response cynw_ahb_mono_bus<TLM_OSCI>::transport( 
	const osci_tlm_ahb_request& req )
{
	unsigned int          slave_i;   // Slave device to talk to.

	slave_i = address_decode(req.m_address);
	return m_slaves[slave_i]->transport( req );
}

//==============================================================================
// cynw_ahb_mono_bus<CYN::PIN> 
//
// SIMPLE PIN LEVEL SINGLE MASTER/SINGLE SLAVE AHB BUS
//
//==============================================================================
enum ahb_state
{
	ahbst_idle = 0,		 // Bus is idle.
	ahbst_idle_transfer, // Master requested bus, then did not transfer.
	ahbst_read_single,   // Read a single value.
	ahbst_read_incr,     // Read an unspecifed number of values.
	ahbst_read_incr4,    // Read a 4 value burst.
	ahbst_read_incr8,    // Read a 8 value burst.
	ahbst_read_incr16,   // Read a 16 value burst.
	ahbst_read_wrap4,    // Read a 4 value wrapping burst.
	ahbst_read_wrap8,    // Read a 8 value wrapping burst.
	ahbst_read_wrap16,   // Read a 16 value wrapping burst.
	ahbst_write_single,  // Write a single value.
	ahbst_write_incr,    // Write an unspecifed number of values.
	ahbst_write_incr4,   // Write a 4 value burst.
	ahbst_write_incr8,   // Write a 8 value burst.
	ahbst_write_incr16,  // Write a 16 value burst.
	ahbst_write_wrap4,   // Write a 4 value wrapping burst.
	ahbst_write_wrap8,   // Write a 8 value wrapping burst.
	ahbst_write_wrap16,  // Write a 16 value wrapping burst.
	ahbst_error 		 // Error detected, wait for slave de-select.
};

template<>
class cynw_ahb_mono_bus<CYN::PIN> : public sc_module
{
  public:
	SC_CTOR(cynw_ahb_mono_bus) : 
		m_diagnostics("ERROR.log"), m_master("master")//, m_slave("slave")
	{
		SC_CTHREAD(monitor,m_clk.pos());

		SC_CTHREAD(protocol_verifier,m_clk.pos());
		reset_signal_is( m_reset, false );

		SC_METHOD(slave_mux);
		sensitive << m_slave_i;
		for ( int i = 0; i < SLAVES_N; i++ )
		{
			sensitive << m_slave[i].m_HRDATA;
			sensitive << m_slave[i].m_HREADY;
			sensitive << m_slave[i].m_HRESP;
			sensitive << m_slave[i].m_HSPLIT;
		}

		SC_METHOD(slave_select);
		sensitive << m_master.m_HADDR << m_select_enable;

		m_HRESETn(m_reset);

		m_master.m_HCLK(m_clk);
        m_master.m_HGRANT( m_HGRANT );
        m_master.m_HRESETn( m_reset );
        m_master.m_HRDATA(m_HRDATA);
        m_master.m_HREADY(m_HREADY);
        m_master.m_HRESP(m_HRESP);

		for ( int i = 0; i < SLAVES_N; i++ )
		{
			m_slave[i].m_HADDR(m_master.m_HADDR);
			m_slave[i].m_HBURST(m_master.m_HBURST);
			m_slave[i].m_HCLK(m_clk);
			m_slave[i].m_HMASTER(m_HMASTER);
			m_slave[i].m_HMASTLOCK(m_HMASTLOCK);
			m_slave[i].m_HPROT(m_master.m_HPROT);
			m_slave[i].m_HRESETn(m_reset);
			m_slave[i].m_HSEL(m_HSEL[i]); 
			m_slave[i].m_HSIZE(m_master.m_HSIZE);
			m_slave[i].m_HTRANS(m_master.m_HTRANS);
			m_slave[i].m_HWDATA(m_master.m_HWDATA);
			m_slave[i].m_HWRITE(m_master.m_HWRITE);
		}

		m_errors = 0;
		m_select_enable = false;
		m_slaves_n = 0;
	}
	virtual inline ~cynw_ahb_mono_bus()
	//virtual void end_of_simulation()
	{
		m_diagnostics << endl << endl;
		switch ( m_errors )
		{
		  case 0: 
			m_diagnostics << "No errors detected" << endl;
			cout << "No errors detected" << endl;
			break;
		  case 1: 
			m_diagnostics << "1 error detected" << endl;
			cout << "1 error detected" << endl;
			break;
		  default:
			m_diagnostics << m_errors << " errors detected" << endl;
			cout << m_errors << " errors detected" << endl;
			break;
		}
		m_diagnostics.close();
	}

	inline void add_master( ahb_master_ports& master );
	inline void add_slave( ahb_slave_ports& slave );
	inline const char* ahb_state_text( ahb_state state );
	inline ostream& annotate();
	inline ahb_state decode_operation( int& count );
	inline void dump_bus( ostream& os, const char* prefix_p="" );
    inline const char* hburst_text( int burst );
    inline int hsize_number( int size );
    inline const char* hresp_text( int resp );
    inline const char* htrans_text( int trans );
	inline void load( ahb_values& values );
	inline ostream& log_error( 
		const char*, const char*, int, ahb_state, sc_time& );
	inline void monitor();
	inline void protocol_verifier();
	inline void slave_mux();
	inline void slave_select();
	inline sc_uint<32> update_address( const sc_uint<32>& curr_address );
	inline bool validate_address( const sc_uint<3>&, const sc_uint<32>& );


	// SNAP SHOT OF CURRENT BUS VALUES:

	ahb_values m_trace[TRACE_N]; // Trace of each value in operation.
	int        m_trace_i;        // Current instance in operation.
  

	// MISCELLANEOUS SUPPORT FOR THIS OBJECT INSTANCE:

    sc_in<bool>     m_clk;           // Clock signal.
	ofstream        m_diagnostics;   // Diagnostics stream.
	int             m_transfer_i;    // Number of current transfer.
	int             m_transfer_n;    // Number of transfers to perform.
	int             m_errors;        // # of errors seen.
	sc_signal<bool> m_reset;         // Reset signal (to bind to dut.)
	sc_signal<bool> m_select_enable; // True if should select slave.
	sc_time         m_start_time;    // Start time of current operation.
    enum ahb_state  m_state;         // Current bus state.

	// SIGNALS TO BE DRIVEN TO SIMULATE AHB BUS CIRCUITRY:

    sc_signal<bool>         m_HGRANT;           // Bus grant.
	sc_signal<sc_uint<4> >  m_HMASTER;          // Current master.
	sc_signal<bool>         m_HMASTLOCK;        // Master lock.
    sc_in<bool>             m_HRESETn;          // Reset signal.
    sc_signal<bool>         m_HSEL[SLAVES_N+1]; // Select signal (1 per slave).

    // SLAVE SIGNALS THAT MUST BE MULTIPLEXED DEPENDENT UPON ADDRESS:

    sc_signal<sc_uint<32> > m_HRDATA;         // Read data from slave.
	sc_signal<bool>         m_HREADY;         // True if slave is ready.
	sc_signal<sc_uint<2> >  m_HRESP;          // Slave response.
	sc_signal<sc_uint<16> > m_HSPLIT;         // Split mask.

	// MASTER AND SLAVE BEING SIMULATED:

	ahb_master_iface        m_master;          // Interface to the master.
	ahb_slave_iface         m_slave[SLAVES_N]; // Interface to the slave.
	sc_signal<int>          m_slave_i;         // Active slave.
	int                     m_slaves_n;        // Number of slaves.
};


//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<CYN::PIN>::add_master( ahb_master_ports& master )
{
	master(m_master);
}

//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<CYN::PIN>::add_slave( ahb_slave_ports& slave )
{
	slave(m_slave[m_slaves_n]);
	m_slaves_n++;
}

//------------------------------------------------------------------------------
inline const char* cynw_ahb_mono_bus<CYN::PIN>::ahb_state_text(ahb_state state)
{
	static const char* ahb_states[] =
	{
	    "ahbst_idle",
	    "ahbst_idle_transfer",
	    "ahbst_read_single",
	    "ahbst_read_incr,",
	    "ahbst_read_incr4",
	    "ahbst_read_incr8",
	    "ahbst_read_incr16",
	    "ahbst_read_wrap4",
	    "ahbst_read_wrap8",
	    "ahbst_read_wrap16",
	    "ahbst_write_single",
	    "ahbst_write_incr",
	    "ahbst_write_incr4",
	    "ahbst_write_incr8",
	    "ahbst_write_incr16",
	    "ahbst_write_wrap4",
	    "ahbst_write_wrap8",
	    "ahbst_write_wrap16",
	    "ahbst_error"		 
	};
	return ahb_states[state];
}


//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<CYN::PIN>::decode_operation"
//
// This method returns the stream for the error log.
//------------------------------------------------------------------------------
inline ostream& cynw_ahb_mono_bus<CYN::PIN>::annotate()
{
	return m_diagnostics;
}


//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<CYN::PIN>::decode_operation"
//
// This method sets the state for the transaction that is beginning in this
// cycle based on its burst setting. It also sets the number of transfers.
//------------------------------------------------------------------------------
inline ahb_state cynw_ahb_mono_bus<CYN::PIN>::decode_operation( int& count )
{
	ahb_state next_state;

	switch ( m_trace[m_trace_i].m_HBURST )
	{
	  case hburst_single:
	  	next_state = m_trace[m_trace_i].m_HWRITE == true ?
		    ahbst_write_single : ahbst_read_single;
		count = 1;
		break;

	  case hburst_incr:
	  	next_state = m_trace[m_trace_i].m_HWRITE == true ?
		    ahbst_write_incr : ahbst_read_incr;
		count = 0;
		break;

	  case hburst_incr4:
	  	next_state = m_trace[m_trace_i].m_HWRITE == true ?
		    ahbst_write_incr4 : ahbst_read_incr4;
		count = 4;
		break;

	  case hburst_incr8:
	  	next_state = m_trace[m_trace_i].m_HWRITE == true ?
		    ahbst_write_incr8 : ahbst_read_incr8;
		count = 8;
		break;

	  case hburst_incr16:
	  	next_state = m_trace[m_trace_i].m_HWRITE == true ?
		    ahbst_write_incr16 : ahbst_read_incr16;
		count = 16;
		break;

	  case hburst_wrap4:
	  	next_state = m_trace[m_trace_i].m_HWRITE == true ?
		    ahbst_write_wrap4 : ahbst_read_wrap4;
		count = 4;
		break;

	  case hburst_wrap8:
	  	next_state = m_trace[m_trace_i].m_HWRITE == true ?
		    ahbst_write_wrap8 : ahbst_read_wrap8;
		count = 8;
		break;

	  case hburst_wrap16:
	  	next_state = m_trace[m_trace_i].m_HWRITE == true ?
		    ahbst_write_wrap16 : ahbst_read_wrap16;
		count = 16;
		break;

	  default:
		LOG_ERROR("Unkown burst value")
			<< hburst_text(m_trace[m_trace_i].m_HBURST) << endl;
		next_state = ahbst_error;
		count = 0;
	}
	return next_state;
}

//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<CYN::PIN>::dump_bus( 
	ostream& os, const char* prefix_p )
{
	m_trace[0].dump( os, prefix_p, true );
	for ( int trace_i = 1; trace_i <= m_trace_i; trace_i++ )
	{
		m_trace[trace_i].dump( os, prefix_p );
	}
}

//------------------------------------------------------------------------------
const char* cynw_ahb_mono_bus<CYN::PIN>::hburst_text( int burst )
{
	static const char* text[] =
	{
        "hburst_single",
        "hburst_incr",
        "hburst_wrap4",
        "hburst_incr4",
        "hburst_wrap8",
        "hburst_incr8",
        "hburst_wrap16",
        "hburst_incr16"
	};
	static char unknown[] = "*** unknown ***";

	if ( (burst >= hburst_single) && (burst <= hburst_incr16) )
		return text[burst];
	else
		return unknown;
}


//------------------------------------------------------------------------------
int cynw_ahb_mono_bus<CYN::PIN>::hsize_number( int size )
{
	static int numbers[] =
	{
        8, 16, 32, 64, 128, 256, 512, 1024
	};
	if ( (size >= hsize_8) && (size <= hsize_1024) )
		return numbers[size];
	else
		return 0;
}


//------------------------------------------------------------------------------
const char* cynw_ahb_mono_bus<CYN::PIN>::hresp_text( int resp )
{
	static const char* text[] =
	{
        "hresp_okay",
        "hresp_error",
        "hresp_retry",
        "hresp_split"
	};
	static char unknown[] = "*** unknown ***";
	if ( (resp >= hresp_okay) && (resp <= hresp_split) )
		return text[resp];
	else
		return unknown;
}


//------------------------------------------------------------------------------
const char* cynw_ahb_mono_bus<CYN::PIN>::htrans_text( int trans )
{
	static const char* text[] =
	{
        "htrans_idle",
        "htrans_busy",
        "htrans_nonsequential",
        "htrans_sequential"
	};
	static char unknown[] = "*** unknown ***";
	if ( (trans >= htrans_idle) && (trans <= htrans_sequential) )
		return text[trans];
	else
		return unknown;
}


//------------------------------------------------------------------------------
inline ostream& cynw_ahb_mono_bus<CYN::PIN>::log_error( 
	const char* msg, const char* file, int line, ahb_state state, 
	sc_time& start_time )
{
#   if 0 // set to 1 to dump error header to normal output.
		ostream& logout = cout;
#   else
		ostream& logout = m_diagnostics;
#   endif
	m_errors++;
	logout << endl;
	logout << "--------------------"
		   << "--------------------"
		   << "--------------------" 
		   << "--------------------" 
		   << endl;
	logout << "*** " << msg << " *** " << endl << endl;
	logout << " Detected at source location:" << file 
		   << "(" << dec << line << ")" << endl;
	logout << " Current simulation time is(" << sc_time_stamp() 
		   << "), operation started at (" << start_time << ")" 
		   << endl;
	logout << " Bus state is " << ahb_state_text(state) 
		   << " and the ahb register contents are:" << endl;
	dump_bus(logout, "    ");
	return logout;
}

//------------------------------------------------------------------------------

inline void cynw_ahb_mono_bus<CYN::PIN>::load( ahb_values& values )
{
	// Set sample time:
	
	values.m_time = sc_time_stamp();
	
    // Pick up master side values of interest:

	values.m_HADDR   = m_master.m_HADDR.read();
	values.m_HBURST  = m_master.m_HBURST.read();
	values.m_HBUSREQ = m_master.m_HBUSREQ.read();
	values.m_HCLK    = m_master.m_HCLK.read();
	values.m_HGRANT  = m_HGRANT.read();
	values.m_HPROT   = m_master.m_HPROT.read();
	values.m_HRESETn = m_HRESETn.read();
	values.m_HSIZE   = m_master.m_HSIZE.read();
	values.m_HTRANS  = m_master.m_HTRANS.read();
	values.m_HWDATA  = m_master.m_HWDATA.read();
	values.m_HWRITE  = m_master.m_HWRITE.read();

    // Pick up slave side values of interest:

	values.m_HMASTER   = m_HMASTER.read();
	values.m_HMASTLOCK = m_HMASTLOCK.read();
	values.m_HRDATA    = m_HRDATA.read();
	values.m_HREADY    = m_HREADY.read();
	values.m_HRESP     = m_HRESP.read();
	values.m_HSPLIT    = m_HSPLIT.read();
	int slave_i = m_slave_i.read();
	if ( slave_i < m_slaves_n )
		values.m_HSEL      = m_HSEL[slave_i].read();
	else
		values.m_HSEL = false;
}
//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<CYN::PIN>::monitor()
{
	bool ready;  // HREADY value.
	int  trans;  // HTRANS value.

	// RESET SIGNALS THAT ARE WRITTEN TO MASTER:

	m_select_enable = false;
	m_HGRANT = false;
	m_HMASTLOCK = false;
	m_HMASTER = 0;
    m_reset = false;
    wait();
    m_reset = true;

	for (;;)
	{
		// WAIT FOR A BUS REQUEST:

		m_select_enable = false;
		m_HGRANT = false;
		do 
		{
			wait();
		} while ( m_master.m_HBUSREQ.read() == false );


		// GRANT BUS TO MASTER AND SELECT THE SLAVE:

		m_HGRANT = true;
		wait();
		m_select_enable = true;


		// SET HMASTER CAUSING HSEL FOR NEXT CYCLE:

		do { 
			wait(); 
			ready = m_slave[m_slave_i.read()].m_HREADY.read();
		} while ( !ready );

		// OUR "DEVICE" IS NOW SELECTED, POLL FOR HTRANS CHANGING:

		m_HGRANT = false; 
		do
		{
			wait();
			trans = m_master.m_HTRANS.read();
			ready = m_slave[m_slave_i.read()].m_HREADY.read();
		} while ( (trans != htrans_idle) || !ready );
	}
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<CYN::PIN>::protocol_verifier"
//
//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<CYN::PIN>::protocol_verifier()
{
	sc_uint<32>    next_address;  // Address for next cycle.

    // RESET ASSERTED:

	{
		m_state = ahbst_idle;
		m_start_time = sc_time_stamp();
		wait();
	}

	// OUT OF RESET, START MONITORING THE BUS:

	for (;;)
	{
		// PICK UP ALL THE SIGNALS TO BE CHECKED:

		wait();
		m_trace_i = ( m_state == ahbst_idle ) ? 0 : m_trace_i+1;
		if ( m_trace_i >= (int)sizeof(m_trace)/(int)sizeof(ahb_values) )
		{
			cerr << "Trace buffer exceeded m_trace_i=" << m_trace_i << endl;
		    m_trace_i--;
			LOG_ERROR("Trace buffer exceeded") << endl;
			m_trace_i = 0;
		}
		load(m_trace[m_trace_i]);

		//cout << sc_time_stamp() << " " << ahb_state_text(m_state) << endl;
		//dump_bus( cout );
		switch ( m_state )
		{
		  // BUS WAS IDLE LAST CYCLE:

		  case ahbst_idle: 

		  	// No device selection: verify slave is indicating idle
			m_start_time = sc_time_stamp();
		    if ( m_trace[m_trace_i].m_HSEL == false )
		    {
			    if ( m_trace[m_trace_i].m_HREADY == false )
			    {
				    LOG_ERROR("HREADY FALSE")
					    << "HREADY is false when HSEL is false" << endl;
			    }
			    if ( m_trace[m_trace_i].m_HRESP != hresp_okay )
			    {
				    LOG_ERROR("HRESP not OK")
					    << "HRESP is not OK when HSEL is false "
					    << "value is " 
						<< hresp_text(m_trace[m_trace_i].m_HRESP) << endl;
			    }
			}

			// Device is selected: verify signals from master for start of
			// and operation:
			else 
			{
				switch ( m_trace[m_trace_i].m_HTRANS )
				{
				  case htrans_idle:
				  	m_state = ahbst_idle_transfer;
					break;
				  case htrans_nonsequential: // legal start to operation
				  	validate_address( m_trace[m_trace_i].m_HBURST, 
						m_trace[m_trace_i].m_HADDR );
					m_state = decode_operation(m_transfer_n);
					m_transfer_i = 0;
					next_address = update_address(m_trace[m_trace_i].m_HADDR);
				  	break;
				  default: // busy and sequential
				    LOG_ERROR("Expected nonsequential transfer")
					    << " but transfer type is " 
						<< htrans_text(m_trace[m_trace_i].m_HTRANS) << endl;
				  	break;
				}
			}
			break;

		 // MASTER REQUESTED THE BUS AND PRESENTED AN IDLE TRANSFER

		 case ahbst_idle_transfer:
		 	if ( m_trace[m_trace_i].m_HSEL == true )
			{
			    if ( m_trace[m_trace_i].m_HREADY == false )
			    {
				    LOG_ERROR("HREADY FALSE")
					    << "HREADY is false for idle transfer cycle" << endl;
			    }
				if ( m_trace[m_trace_i].m_HRESP != hresp_okay )
				{
				    LOG_ERROR("HRESP not OK")
					    << "HRESP is not okay for idle transfer cycle" << endl;
				}
				m_state = ahbst_idle;
			}
  
		  // SINGLE TRANSFER READ:

          case ahbst_read_single:
			switch ( m_trace[m_trace_i].m_HTRANS )
			{
			  case htrans_idle: 
			    if ( m_trace[m_trace_i].m_HREADY == true )
				{
				    m_state = ahbst_idle; 
				}
			    break;
			  case htrans_busy:
			  	break;
			  default:
				LOG_ERROR("HTRANS is not idle")
					<< "HTRANS must be idle in cycle 2 of a single value "
					<< "transfer but it was "
					<< htrans_text(m_trace[m_trace_i].m_HTRANS) << endl;
				m_state = ahbst_error;
			    break;
		  	}
		    break;

		  // UNKNOWN TRANSFER LENGTH READ:

          case ahbst_read_incr:
		    break;

		  // A BURST READ:

          case ahbst_read_incr4:
          case ahbst_read_incr8:
          case ahbst_read_incr16:
          case ahbst_read_wrap4:
          case ahbst_read_wrap8:
          case ahbst_read_wrap16:

			if ( m_transfer_i != m_transfer_n-1 )
			{
				if ( m_trace[m_trace_i].m_HADDR != next_address )
				{
					LOG_ERROR("Address mismatch")
						<< "Expected address " << next_address
						<< " (0x" << hex << next_address << ")"
						<< " Got address " << dec << m_trace[m_trace_i].m_HADDR 
						<< " (0x" << hex << m_trace[m_trace_i].m_HADDR << ")" 
						<< endl;
				}
			}

			// slave responded not ready:

            if ( m_trace[m_trace_i].m_HREADY == false ) continue;

			// slave was ready:

		    switch ( m_trace[m_trace_i].m_HTRANS )
			{
			  case htrans_nonsequential:
			  	// #### if ( m_transfer_i != 0 )
				{
					LOG_ERROR("Only first transfer is nonsequential")
						<< " but transfer " << m_transfer_i 
						<< " was also" << endl;
					m_state = ahbst_error;
				}
				if ( ++m_transfer_i == m_transfer_n ) m_state = ahbst_idle;
				break;
			  case htrans_sequential:
				next_address = update_address(next_address);
				if ( ++m_transfer_i == m_transfer_n ) m_state = ahbst_idle;
				break;
			  case htrans_busy: // #### check for busy response from slave? 
			  	break;
			  case htrans_idle:
				if ( ++m_transfer_i == m_transfer_n ) 
				{
					m_state = ahbst_idle;
				}
				else
				{
					LOG_ERROR("Early termination of transfer")
						<< "Master went idle with " 
						<< (m_transfer_n-m_transfer_i)
						<< " transfers remaining" << endl;
					m_state = ahbst_error;
				}
				break;
			}
		    break;

		  // SINGLE TRANSFER WRITE:

          case ahbst_write_single:
			switch ( m_trace[m_trace_i].m_HTRANS )
			{
			  case htrans_idle:
			    if ( m_trace[m_trace_i].m_HREADY == false )
				{
					LOG_ERROR("HREADY is false")
						<< "HREADY must be true for a single value transfer"
						<< endl;
					m_state = ahbst_error;
				}
				m_state = ahbst_idle; // #### do we need to check next clock?
			    break;
			  case htrans_busy:
			  	break;
			  default:
			    if ( m_trace[m_trace_i].m_HREADY == true ) 
				{
			  	    LOG_ERROR("HTRANS is not idle")
				        << "HTRANS must be idle in cycle 2 of a single value "
					    << "transfer but it was "
					    << htrans_text(m_trace[m_trace_i].m_HTRANS) << endl;
			        m_state = ahbst_error;
				}
			    break;
		  	}
		    break;

		  // UNKNOWN TRANSFER LENGTH WRITE:

          case ahbst_write_incr:
		    break;

		  // BURST TRANSFER:

          case ahbst_write_incr4:
          case ahbst_write_incr8:
          case ahbst_write_incr16:
          case ahbst_write_wrap4:
          case ahbst_write_wrap8:
          case ahbst_write_wrap16:
			if ( m_transfer_i != m_transfer_n-1 )
			{
				if ( m_trace[m_trace_i].m_HADDR != next_address )
				{
					LOG_ERROR("Address mismatch")
						<< "Expected address " << next_address
						<< " (0x" << hex << next_address << ")"
						<< " Got address " << dec << m_trace[m_trace_i].m_HADDR 
						<< " (0x" << hex << m_trace[m_trace_i].m_HADDR << ")" 
						<< endl;
				}
			}

			// slave responded not ready:

            if ( m_trace[m_trace_i].m_HREADY == false ) continue;

			// slave was ready:

		    switch ( m_trace[m_trace_i].m_HTRANS )
			{
			  case htrans_nonsequential:
			  	if ( m_transfer_i != 0 )
				{
					LOG_ERROR("Only first transfer is nonsequential")
						<< " but transfer " << m_transfer_i 
						<< " was also" << endl;
					m_state = ahbst_error;
				}
				if ( ++m_transfer_i == m_transfer_n ) m_state = ahbst_idle;
				break;
			  case htrans_sequential:
				next_address = update_address(next_address);
				if ( ++m_transfer_i == m_transfer_n ) m_state = ahbst_idle;
				break;
			  case htrans_busy: // #### check for busy response? 
			  	break;
			  case htrans_idle:
				if ( ++m_transfer_i == m_transfer_n ) 
				{
					m_state = ahbst_idle;
				}
				else
				{
					LOG_ERROR("Early termination of transfer")
						<< "Master went idle with " 
						<< (m_transfer_n-m_transfer_i)
						<< " transfers remaining" << endl;
					m_state = ahbst_error;
				}
				break;
			}
		    break;

		 // ERROR DETECTED WAIT FOR THE DEVICE TO BE UNSELECTED BEFORE CHECKING

		 case ahbst_error:
		 	if ( m_trace[m_trace_i].m_HSEL == false )
			{
				m_state = ahbst_idle;
			}
		 	break;

         default:
			LOG_ERROR("Unkown bus state") << endl;
			m_state = ahbst_error;
			break;

		} // state switch
	} // for loop
}


//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<CYN::PIN>::slave_mux"
//
// This method muxes the slave signals based on the selected slave.
//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<CYN::PIN>::slave_mux()
{
	int slave_i = m_slave_i.read();

	for ( int slave_i = 0; slave_i < m_slaves_n; slave_i++ )
		m_HSEL[slave_i] = false;

	if ( slave_i < m_slaves_n )
	{
		m_HRDATA = m_slave[slave_i].m_HRDATA.read();
		m_HREADY = m_slave[slave_i].m_HREADY.read();
		m_HRESP = m_slave[slave_i].m_HRESP.read();
		m_HSPLIT = m_slave[slave_i].m_HSPLIT.read();
		m_HSEL[slave_i] = true;
	}
	else
	{
		m_HREADY = true;
		m_HRESP = hresp_okay;
		m_HSPLIT = 0;
	}
}


//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<CYN::PIN>::slave_select"
//
// This method updates performs the multiplexing between the various slaves
// and the master. It uses the upper address bits of m_HADDR to decide which
// slave to select.
//------------------------------------------------------------------------------
inline void cynw_ahb_mono_bus<CYN::PIN>::slave_select()
{
	m_slave_i = ( m_select_enable.read() == false ) ? SLAVES_N+1 :
		m_master.m_HADDR.read()(31,32-LOG2_SLAVES);
}

//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<CYN::PIN>::update_address"
//
// This method updates the address for the next cycle based on the current
// cycle's control
//------------------------------------------------------------------------------
inline sc_uint<32> cynw_ahb_mono_bus<CYN::PIN>::update_address( 
	const sc_uint<32>& current_address )
{
	sc_uint<32> next_address;

	switch( m_trace[m_trace_i].m_HBURST )
	{
	  case hburst_single:
	  case hburst_incr:
	  case hburst_incr4:
	  case hburst_incr8:
	  case hburst_incr16:
	  	switch( m_trace[m_trace_i].m_HSIZE )
		{
		  case hsize_8:  next_address = current_address + 1; break;
		  case hsize_16: next_address = current_address + 2; break;
		  case hsize_32: next_address = current_address + 4; break;
		}
	    break;
	  case hburst_wrap4:
	    next_address = current_address;
	  	switch( m_trace[m_trace_i].m_HSIZE )
		{
		  case hsize_8:  next_address(1,0) = current_address(1,0) + 1; break;
		  case hsize_16: next_address(2,1) = current_address(2,1) + 1; break;
		  case hsize_32: next_address(3,2) = current_address(3,2) + 1; break;
		}
	    break;
	  case hburst_wrap8:
	    next_address = current_address;
	  	switch( m_trace[m_trace_i].m_HSIZE )
		{
		  case hsize_8:  next_address(2,0) = current_address(2,0) + 1; break;
		  case hsize_16: next_address(3,1) = current_address(3,1) + 1; break;
		  case hsize_32: next_address(4,2) = current_address(4,2) + 1; break;
		}
	    break;
	  case hburst_wrap16:
	    next_address = current_address;
	  	switch( m_trace[m_trace_i].m_HSIZE )
		{
		  case hsize_8:  next_address(3,0) = current_address(3,0) + 1; break;
		  case hsize_16: next_address(4,1) = current_address(4,1) + 1; break;
		  case hsize_32: next_address(5,2) = current_address(5,2) + 1; break;
		}
	    break;
	  default:
	  	next_address = current_address;
		break;
	}

	return next_address;
}


//------------------------------------------------------------------------------
//"cynw_ahb_mono_bus<CYN::PIN>::validate_address"
//
// This method verifies the address matches the transfer size.
//------------------------------------------------------------------------------
inline bool cynw_ahb_mono_bus<CYN::PIN>::validate_address( 
	const sc_uint<3>& size, const sc_uint<32>& address )
{
	switch( size )
	{
	  case hsize_8:
	  	break;
	  case hsize_16:
	  	if ( address[0] )
		{
			LOG_ERROR("Bad address alignment") 
				<< "transfering 16 bits but low order bit of address is 1"
				<< endl;
			return false;
		}
		break;
	  case hsize_32:
	  	if ( address(1,0) )
		{
			LOG_ERROR("Bad address alignment") 
				<< "transfering 32 bits but low order two bits of address are"
				<< " non-zero " << endl;
		}
		return false;
	}
	return true;
}

#undef LOG2_SLAVES
#undef SLAVES_N

#endif // !defined(cynw_ahb_mono_bus_h_INCLUDED)
