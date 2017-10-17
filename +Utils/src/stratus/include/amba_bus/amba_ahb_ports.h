/****************************************************************************
*
*  Copyright (C) 2006, Forte Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Forte Design Systems.
*
****************************************************************************/

#if !defined(amba_ahb_ports_h_INCLUDED)
#define amba_ahb_ports_h_INCLUDED

#include "cynthhl.h"                      // Get CYN_PROTOCOL and CYN_METAPORT.
#include "cynw_stream_helpers.h"          // Pick up stream support.
#include "amba_bus/amba_ahb_interfaces.h" // Pick up interface definitions.

using cynw::out_format;
using cynw::out_text;

namespace amba {

enum HBURST_values {
	hburst_single = 0, // 000: single transfer
	hburst_incr   = 1, // 001: incrementing burst of unspecified length.
	hburst_wrap4  = 2, // 010: 4-beat wrapping burst.
	hburst_incr4  = 3, // 011: 4-beat incrementing burst.
	hburst_wrap8  = 4, // 011: 8-beat wrapping burst.
	hburst_incr8  = 5, // 101: 8-beat incrementing burst.
	hburst_wrap16 = 6, // 110: 16-beat wrapping burst.
	hburst_incr16 = 7  // 111: 16-beat incrementing burst.
};
typedef sc_uint<3> hburst_type;

enum HPROT_values {   // Bits or'ed.
	hprot_opcode         = 0, // xxx0: Opcode fetch.
	hprot_data           = 1, // xxx1: Data access.
	hprot_user           = 0, // xx0x: User access.
	hprot_priviledged    = 2, // xx1x: Priviledged access.
	hprot_not_bufferable = 0, // x0xx: Not bufferable.
	hprot_bufferable     = 4, // x1xx: Bufferable.
	hprot_not_cacheable  = 0, // 0xxx: Not cacheable.
	hprot_cacheable      = 8  // 1xxx: Cacheable.
};
typedef sc_uint<4> hprot_type;

enum HRESP_values {
	hresp_okay  = 0, // 00: transfer has completed successfully.
	hresp_error = 1, // 01: error detected.
	hresp_retry = 2, // 10: retry transfer of data.
	hresp_split = 3  // 11: retry transfer on next bus grant.
};
typedef sc_uint<2> hresp_type;

enum HSIZE_values {
	hsize_8    = 0, // 000: byte transfer.
	hsize_16   = 1, // 001: halfword transfer.
	hsize_32   = 2, // 010: word transfer.
	hsize_64   = 3, // 011: 64 bits
	hsize_128  = 4, // 100: four-word line.
	hsize_256  = 5, // 101: eight-word line.
	hsize_512  = 6, // 110: 512 bits
	hsize_1024 = 7  // 111: 1024 bits
};
typedef sc_uint<3> hsize_type;

enum HTRANS_values {
	htrans_idle = 0,      // 00: master idle.
	htrans_busy,          // 01: master busy, not transferring.
	htrans_nonsequential, // 10: first transfer of a sequence.
	htrans_sequential     // 11: subsequent transfer of a sequence.
};
typedef sc_uint<2> htrans_type;

//==============================================================================
// AMBA AHB control FROM SLAVE'S POINT OF VIEW
//==============================================================================
class ahb_control {
  public:
    sc_uint<32> m_address; // Address of request.
	sc_uint<3>  m_burst;   // Number of data transfers.
	bool        m_sel;     // Select line for device.
	sc_uint<3>  m_size;    // Length of each data transfer.
	sc_uint<2>  m_trans;   // Transfer type.
	bool        m_write;   // True is this is a write request.
};

//==============================================================================
// AMBA AHB BUS Arbiter Ports
//
// ahb_arbiter_ports - ports contained in an arbiter for the ahb bus. This
//                          is connected to an ahb_arbiter_iface instance
//                          within an amba ahb bus.
//==============================================================================
class ahb_arbiter_ports {
	CYN_METAPORT;
  public: // inputs:
	sc_in<sc_uint<32> >   m_HADDR;          // Transfer address.
	sc_in<sc_uint<3> >    m_HBURST;         // See HBURST_values.
    sc_in<bool>           m_HBUSREQ[16];    // Bus request signals.
	sc_in<bool>           m_HCLK;           // Clock.
	sc_in<bool>           m_HRESETn;        // Reset signal.
    sc_in<bool>           m_HLOCK[16];      // Master requires lock.
	sc_in<bool>           m_HREADY;         // Slave ready signal.
	sc_in<sc_uint<2> >    m_HRESP;          // See HRESP_values.
	sc_in<sc_uint<16> >   m_HSPLIT[16];     // Slave splits.
	sc_in<sc_uint<2> >    m_HTRANS;         // See HTRANS_values.

  public: // outputs:
    sc_inout<bool>         m_HGRANT[16];  // Bus grant signals.
    sc_inout<sc_uint<4> >  m_HMASTER;     // Who has lock.
    sc_inout<bool>         m_HMASTLOCK;   // Current transfers are locked.

  public:
    inline ahb_arbiter_ports(
	    const char* name = sc_gen_unique_name("ahb_arbiter_ports"));
	inline void bind( ahb_arbiter_iface& );
	inline void bind( ahb_arbiter_ports& );
	inline void operator () ( ahb_arbiter_iface& );
	inline void operator () ( ahb_arbiter_ports& );
};

//------------------------------------------------------------------------------
//"ahb_arbiter_ports::ahb_arbiter_ports"
//
//------------------------------------------------------------------------------
inline ahb_arbiter_ports::ahb_arbiter_ports( const char* name ) :
    m_HADDR((std::string(name)+"_m_HADDR").c_str()),
    m_HBURST((std::string(name)+"_m_HBURST").c_str()),
    m_HCLK((std::string(name)+"_m_HCLK").c_str()),
    m_HRESETn((std::string(name)+"_m_HRESETn").c_str()),
    m_HREADY((std::string(name)+"_m_HREADY").c_str()),
    m_HRESP((std::string(name)+"_m_HRESP").c_str()),
    m_HTRANS((std::string(name)+"_m_HTRANS").c_str()),
    m_HMASTER((std::string(name)+"_m_HMASTER").c_str()),
    m_HMASTLOCK((std::string(name)+"_m_HMASTLOCK").c_str())
{}  


//------------------------------------------------------------------------------
//"ahb_arbiter_ports::bind"
//
//------------------------------------------------------------------------------
inline void ahb_arbiter_ports::bind( ahb_arbiter_iface& iface )
{
	unsigned int slave_i;

    m_HADDR(iface.m_HADDR);
    m_HBURST(iface.m_HBURST);
    m_HCLK(iface.m_HCLK);
    m_HRESETn(iface.m_HRESETn);
    m_HREADY(iface.m_HREADY);
    m_HRESP(iface.m_HRESP);
    m_HTRANS(iface.m_HTRANS);
    m_HMASTER(iface.m_HMASTER);
    m_HMASTLOCK(iface.m_HMASTLOCK);
	for ( slave_i = 0; slave_i < 16; slave_i++ )
	{
		m_HBUSREQ[slave_i](iface.m_HBUSREQ[slave_i]);
		m_HGRANT[slave_i](iface.m_HGRANT[slave_i]);
		m_HLOCK[slave_i](iface.m_HLOCK[slave_i]);
		m_HSPLIT[slave_i](iface.m_HSPLIT[slave_i]);
	}
}

inline void ahb_arbiter_ports::bind( ahb_arbiter_ports& ports )
{
	unsigned int slave_i;

    m_HADDR(ports.m_HADDR);
    m_HBURST(ports.m_HBURST);
    m_HCLK(ports.m_HCLK);
    m_HRESETn(ports.m_HRESETn);
    m_HREADY(ports.m_HREADY);
    m_HRESP(ports.m_HRESP);
    m_HTRANS(ports.m_HTRANS);
    m_HMASTER(ports.m_HMASTER);
    m_HMASTLOCK(ports.m_HMASTLOCK);
	for ( slave_i = 0; slave_i < 16; slave_i++ )
	{
		m_HBUSREQ[slave_i](ports.m_HBUSREQ[slave_i]);
		m_HGRANT[slave_i](ports.m_HGRANT[slave_i]);
		m_HLOCK[slave_i](ports.m_HLOCK[slave_i]);
		m_HSPLIT[slave_i](ports.m_HSPLIT[slave_i]);
	}
}

//------------------------------------------------------------------------------
//"ahb_arbiter_ports::bind"
//
//------------------------------------------------------------------------------
inline void ahb_arbiter_ports::operator () ( ahb_arbiter_iface& iface )
{
	bind(iface);
}

inline void ahb_arbiter_ports::operator () ( ahb_arbiter_ports& ports )
{
	bind(ports);
}


//==============================================================================
// AMBA AHB BUS Master Ports
//
// ahb_master_ports - ports contained in a master for the ahb bus. This
//                         is connected to an ahb_master_iface instance
//                         within an amba ahb bus.
//
//               +-----------+
//    HCLK------>|           |---> HADDR
//    HGRANT[n]->|           |---> HBURST
//    HRDATA---->|           |---> HBUSREQ[n]
//    HREADY---->| AHB MASTER|---> HLOCK[n]
//    HRESP----->|           |---> HPROT
//               |           |---> HSIZE
//               |           |---> HTRANS
//               |           |---> HWDATA
//               |           |---> HWRITE
//               +-----------+
//
//==============================================================================
class ahb_master_ports {
	CYN_METAPORT;
  public: // inputs:
	sc_in<bool>            m_HCLK;    // Clock signal.
	sc_in<bool>            m_HGRANT;  // Bus grant.
	sc_in<sc_uint<32> >    m_HRDATA;  // Read data.
	sc_in<bool>            m_HREADY;  // Slave ready signal.
	sc_in<bool>            m_HRESETn; // Reset signal.
	sc_in<sc_uint<2> >     m_HRESP;   // Slave response.

  public: // outputs:
  	sc_inout<sc_uint<32> > m_HADDR;   // Transfer address.
	sc_inout<sc_uint<3> >  m_HBURST;  // Burst mode.
	sc_inout<bool>         m_HBUSREQ; // Bus request.
	sc_inout<bool>         m_HLOCK;   // Bus lock.
	sc_inout<sc_uint<4> >  m_HPROT;   // See HPROT_values.
	sc_inout<sc_uint<3> >  m_HSIZE;   // See HSIZE_values.
	sc_inout<sc_uint<2> >  m_HTRANS;  // See HTRANS_values.: master idle.
	sc_inout<sc_uint<32> > m_HWDATA;  // Write data.
	sc_inout<bool>         m_HWRITE;  // True if writing.

  public: // methods and operators:
    inline ahb_master_ports(
		const char* name=sc_gen_unique_name("ahb_master_ports"));
	inline void bind( ahb_master_iface& iface );
	inline void bind( ahb_master_ports& ports );
	inline void operator () ( ahb_master_iface& iface );
	inline void operator () ( ahb_master_ports& ports );
    inline void reset();
};
  	
//------------------------------------------------------------------------------
//"ahb_master_ports::ahb_master_ports"
//
//------------------------------------------------------------------------------
inline ahb_master_ports::ahb_master_ports( const char* name ) :
	// inputs:
	m_HCLK((std::string(name)+"_HCLK").c_str()),
	m_HGRANT((std::string(name)+"_HGRANT").c_str()),
	m_HRDATA((std::string(name)+"_HRDATA").c_str()),
	m_HREADY((std::string(name)+"_HREADY").c_str()),
	m_HRESETn((std::string(name)+"_HRESETn").c_str()),
	m_HRESP((std::string(name)+"_HRESP").c_str()),

	// outputs:
	m_HADDR((std::string(name)+"_HADDR").c_str()),
	m_HBURST((std::string(name)+"_HBURST").c_str()),
	m_HBUSREQ((std::string(name)+"_HBUSREQ").c_str()),
	m_HLOCK((std::string(name)+"_HLOCK").c_str()),
	m_HPROT((std::string(name)+"_HPROT").c_str()),
	m_HSIZE((std::string(name)+"_HSIZE").c_str()),
	m_HTRANS((std::string(name)+"_HTRANS").c_str()),
	m_HWDATA((std::string(name)+"_HWDATA").c_str()),
	m_HWRITE((std::string(name)+"_HWRITE").c_str())
{
	// SET UP THE INPUT DELAYS:

    CYN_INPUT_DELAY(m_HGRANT,0.4,"HGRANT delay");
    CYN_INPUT_DELAY(m_HRDATA,0.4,"HRDATA delay");
	CYN_INPUT_DELAY(m_HREADY,0.4,"HREADY delay");
	CYN_INPUT_DELAY(m_HRESP, 0.4,"HRESP delay");
}


//------------------------------------------------------------------------------
//"ahb_master_ports::bind"
//
//------------------------------------------------------------------------------
inline void ahb_master_ports::bind( ahb_master_iface& iface )
{
	// BIND INPUTS:

    m_HCLK(iface.m_HCLK);
    m_HGRANT(iface.m_HGRANT);
    m_HRDATA(iface.m_HRDATA);
    m_HREADY(iface.m_HREADY);
    m_HRESP(iface.m_HRESP);
    m_HRESETn(iface.m_HRESETn);

    // BIND OUTPUTS:

    m_HADDR(iface.m_HADDR);
    m_HBURST(iface.m_HBURST);
    m_HBUSREQ(iface.m_HBUSREQ);
    m_HLOCK(iface.m_HLOCK);
    m_HPROT(iface.m_HPROT);
    m_HSIZE(iface.m_HSIZE);
    m_HTRANS(iface.m_HTRANS);
    m_HWDATA(iface.m_HWDATA);
    m_HWRITE(iface.m_HWRITE);
}

inline void ahb_master_ports::bind( ahb_master_ports& ports )
{
	// BIND INPUTS:

    m_HCLK(ports.m_HCLK);
    m_HGRANT(ports.m_HGRANT);
    m_HRDATA(ports.m_HRDATA);
    m_HREADY(ports.m_HREADY);
    m_HRESP(ports.m_HRESP);
    m_HRESETn(ports.m_HRESETn);

    // BIND OUTPUTS:

    m_HADDR(ports.m_HADDR);
    m_HBURST(ports.m_HBURST);
    m_HBUSREQ(ports.m_HBUSREQ);
    m_HLOCK(ports.m_HLOCK);
    m_HPROT(ports.m_HPROT);
    m_HSIZE(ports.m_HSIZE);
    m_HTRANS(ports.m_HTRANS);
    m_HWDATA(ports.m_HWDATA);
    m_HWRITE(ports.m_HWRITE);
}

//------------------------------------------------------------------------------
//"ahb_master_ports::operator ()"
//
//------------------------------------------------------------------------------
inline void ahb_master_ports::operator () ( ahb_master_iface& iface )
{
	bind(iface);
}

inline void ahb_master_ports::operator () ( ahb_master_ports& ports )
{
	bind(ports);
}

//------------------------------------------------------------------------------
//"ahb_master_ports::reset"
//------------------------------------------------------------------------------
inline void ahb_master_ports::reset()
{
    {
		CYN_PROTOCOL("ahb_master_reset");
		m_HADDR = 0;
		m_HBURST = hburst_single;
		m_HBUSREQ = false;
		m_HLOCK = false;
		m_HPROT = hprot_opcode;
		m_HSIZE = hsize_32;
		m_HTRANS = htrans_idle;
		m_HWRITE = false;
	}
}


//==============================================================================
// AMBA AHB BUS Slave Ports
//
// ahb_slave_ports - ports contained in a slave for the ahb bus. This
//                        is connected to an ahb_slave_iface instance
//                        within an amba ahb bus.
//
//               +-----------+
//    HADDR----->|           |
//    HBURST---->|           |
//    HCLK------>|           |---> HRDATA
//    HMASTER--->|           |
//    HMASTLOCK->| AHB SLAVE |---> HREADY
//    HPROT----->|           |
//    HSEL------>|           |---> HRESP
//    HSIZE----->|           |
//    HTRANS---->|           |---> HSPLIT
//    HWDATA---->|           |
//    HWRITE---->|           |
//               +-----------+
//
//==============================================================================
class ahb_slave_ports {
	CYN_METAPORT;
  public: // inputs:
  	sc_in<sc_uint<32> >    m_HADDR;      // Transfer address.
	sc_in<sc_uint<3> >     m_HBURST;     // Burst mode.
	sc_in<bool>            m_HCLK;	     // Clock signal.
	sc_in<sc_uint<4> >     m_HMASTER;    // Current bus master.
	sc_in<bool>            m_HMASTLOCK;  // True if bus is locked.
	sc_in<sc_uint<4> >     m_HPROT;      // See HPROT_values.
	sc_in<bool>            m_HRESETn;    // Reset signal.
	sc_in<bool>            m_HSEL;       // True if this slave selected.
	sc_in<sc_uint<3> >     m_HSIZE;      // Size of transfer.
	sc_in<sc_uint<2> >     m_HTRANS;     // Transfer type.
	sc_in<sc_uint<32> >    m_HWDATA;     // Write data.
	sc_in<bool>            m_HWRITE;     // True if writing.

  public: // outputs:
	sc_inout<sc_uint<32> > m_HRDATA;     // Read data.
	sc_inout<bool>         m_HREADY;     // Ready bit.
	sc_inout<sc_uint<2> >  m_HRESP;      // See HRESP_values.
	sc_inout<sc_uint<16> > m_HSPLIT;     // Legal master retries on split.
  
  public: // methods and operators:
    inline ahb_slave_ports(
	    const char* name = sc_gen_unique_name("ahb_slave_port"));
	inline void bind( ahb_slave_iface& iface );
	inline void bind( ahb_slave_ports& ports );
	inline void operator () ( ahb_slave_iface& iface );
	inline void operator () ( ahb_slave_ports& ports );
	inline void reset();
	inline void respond( const sc_uint<2>& rc );
    inline bool wait_for_request( sc_uint<32>& address, sc_uint<32>& data );
};
  	
//------------------------------------------------------------------------------
//"ahb_slave_ports::ahb_slave_ports"
//
//------------------------------------------------------------------------------
inline ahb_slave_ports::ahb_slave_ports( const char* name ) :
	// inputs:
	m_HADDR((std::string(name)+"_HADDR").c_str()),
	m_HBURST((std::string(name)+"_HBURST").c_str()),
	m_HCLK((std::string(name)+"_HCLK").c_str()),
	m_HMASTER((std::string(name)+"_HMASTER").c_str()),
	m_HMASTLOCK((std::string(name)+"_HMASTLOCK").c_str()),
	m_HPROT((std::string(name)+"_HPROT").c_str()),
	m_HRESETn((std::string(name)+"_HRESETn").c_str()),
	m_HSEL((std::string(name)+"_HSEL").c_str()),
	m_HTRANS((std::string(name)+"_HTRANS").c_str()),
	m_HWDATA((std::string(name)+"_HWDATA").c_str()),
	m_HWRITE((std::string(name)+"_HWRITE").c_str()),
	// outputs:
	m_HRDATA((std::string(name)+"_HRDATA").c_str()),
	m_HREADY((std::string(name)+"_HREADY").c_str()),
	m_HRESP((std::string(name)+"_HRESP").c_str()),
	m_HSPLIT((std::string(name)+"_HSPLIT").c_str())
{
}

  	
//------------------------------------------------------------------------------
//"ahb_slave_ports::bind" 
//
//------------------------------------------------------------------------------
inline void ahb_slave_ports::bind( ahb_slave_iface& iface )
{
	// BIND INPUTS:

    m_HADDR(iface.m_HADDR);
    m_HBURST(iface.m_HBURST);
    m_HCLK(iface.m_HCLK);
    m_HMASTER(iface.m_HMASTER);
    m_HMASTLOCK(iface.m_HMASTLOCK);
    m_HPROT(iface.m_HPROT);
    m_HRESETn(iface.m_HRESETn);
    m_HSIZE(iface.m_HSIZE);
    m_HSEL(iface.m_HSEL);
    m_HTRANS(iface.m_HTRANS);
    m_HWDATA(iface.m_HWDATA);
    m_HWRITE(iface.m_HWRITE);

	// BIND OUTPUTS:

    m_HRDATA(iface.m_HRDATA);
    m_HREADY(iface.m_HREADY);
    m_HRESP(iface.m_HRESP);
    m_HSPLIT(iface.m_HSPLIT);
}

inline void ahb_slave_ports::bind( ahb_slave_ports& port )
{
	// BIND INPUTS:

    m_HADDR(port.m_HADDR);
    m_HBURST(port.m_HBURST);
    m_HCLK(port.m_HCLK);
    m_HMASTER(port.m_HMASTER);
    m_HMASTLOCK(port.m_HMASTLOCK);
    m_HPROT(port.m_HPROT);
    m_HRESETn(port.m_HRESETn);
    m_HSIZE(port.m_HSIZE);
    m_HSEL(port.m_HSEL);
    m_HTRANS(port.m_HTRANS);
    m_HWDATA(port.m_HWDATA);
    m_HWRITE(port.m_HWRITE);

	// BIND OUTPUTS:

    m_HRDATA(port.m_HRDATA);
    m_HREADY(port.m_HREADY);
    m_HRESP(port.m_HRESP);
    m_HSPLIT(port.m_HSPLIT);
}

//------------------------------------------------------------------------------
//"ahb_slave_ports::operator ()" 
//
//------------------------------------------------------------------------------
inline void ahb_slave_ports::operator() ( ahb_slave_iface& iface )
{
	bind(iface);
}

inline void ahb_slave_ports::operator() ( ahb_slave_ports& port )
{
	bind(port);
}

//------------------------------------------------------------------------------
//"ahb_slave_ports::reset"
//
// This methods resets this slave instance's ahb interface.
//------------------------------------------------------------------------------
void ahb_slave_ports::reset()
{
    {
		CYN_PROTOCOL("ahb_slave_reset");
		m_HREADY = true;
		m_HRESP = hresp_okay;
		m_HSPLIT = 0;
	}
}

//------------------------------------------------------------------------------
//"ahb_slave_ports::respond"
//
// This methods responds with the supplied indication to the AHB bus. 
//     rc = HRESP register value to be returned
// #### NEEDS WORK?
//------------------------------------------------------------------------------
void ahb_slave_ports::respond( const sc_uint<2>& rc )
{
	switch( (int)rc )
	{
	  // SUCCESSFUL OPERATION:

	  case hresp_okay:
		{
			CYN_PROTOCOL("ahb_slave_respond_okay");
			m_HREADY = true;
			m_HRESP = hresp_okay;
			wait();
		}
		break;

	  // OPERATION DID NOT COMPLETE:
	  //
	  // Indicate an the reason for two clocks by holding the bus busy
	  default:
		{
			CYN_PROTOCOL("ahb_slave_respond_exception");
			m_HREADY = false;
			m_HRESP = rc;
			wait();
			m_HREADY = true;
			wait();
			m_HRESP = hresp_okay;
		}
		break;
	}
}

//------------------------------------------------------------------------------
//"ahb_slave_ports::wait_for_request"
//
// This method waits for a request to arrive from the AHB bus. 
//------------------------------------------------------------------------------
bool ahb_slave_ports::wait_for_request(sc_uint<32>& address, sc_uint<32>& data)
{
	bool select;
	bool write_enable;

	// ADDRESS PHASE:

    {
		CYN_PROTOCOL("ahb_wait_for_request_address");


		m_HREADY = true;
		m_HRESP = hresp_okay;
		do { 
			wait(); 
			address = m_HADDR.read();
			select = m_HSEL.read();
			write_enable = m_HWRITE.read();
		} while ( !select );
	}

	// DATA PHASE (IF THIS IS A WRITE):

	if ( write_enable )
    {
		CYN_PROTOCOL("ahb_wait_for_request_data");
        
		m_HREADY = true;
		m_HRESP = hresp_okay;
		wait();
		data = m_HWDATA.read();
		m_HREADY = false; // assume it will take more than one cycle.
	}

	return write_enable;
}

//==============================================================================
//"ahb_values" -  SNAP SHOT OF BUS VALUES
//
//==============================================================================
class ahb_values
{
  public:
	inline void dump( ostream& os, const char* prefix_p, bool header = false );
    inline const char* hburst_text( int burst );
    inline int hsize_number( int size );
    inline const char* hresp_text( int resp );
    inline const char* htrans_text( int trans );

  public:
    sc_uint<32>    m_HADDR;      // Transfer address.
    sc_uint<3>     m_HBURST;     // Burst mode.
	bool           m_HBUSREQ;    // Bus request.
    bool           m_HCLK;       // Clock signal.
	bool           m_HGRANT;     // Grant.
    sc_uint<4>     m_HMASTER;    // Current bus master.
    bool           m_HMASTLOCK;  // True if bus is locked.
    sc_uint<4>     m_HPROT;      // See HPROT_values.
    sc_uint<32>    m_HRDATA;     // Read data.
    bool           m_HREADY;     // Ready bit.
    bool           m_HRESETn;    // Reset signal.
    sc_uint<2>     m_HRESP;      // See HRESP_values.
    bool           m_HSEL;       // True if this slave selected.
    sc_uint<16>    m_HSPLIT;     // Legal master retries on split.
    sc_uint<3>     m_HSIZE;      // Size of transfer.
    sc_uint<2>     m_HTRANS;     // Transfer type.
    sc_uint<32>    m_HWDATA;     // Write data.
    bool           m_HWRITE;     // True if writing.
	sc_time        m_time;       // Time of sampling.
};

//------------------------------------------------------------------------------
//"ahb_values::dump"
//------------------------------------------------------------------------------
inline void ahb_values::dump( ostream& os, const char* prefix_p, bool header )
{
	if ( header )
	{
		os << prefix_p;
		os << "Cycle    ADDR     BURST  CLK MASTER PROT RDATA    BUSREQ GRANT ";
		os << "RESETn READY RESP  SEL   SIZE SPLIT TRANS  WDATA    WRITE";
        os << endl;
		os << prefix_p;
		os << "-------- -------- ------ --- ------ ---- -------- ------ ----- ";
		os << "------ ----- ---- ----- ---- ----- ------ -------- -----";
        os << endl;
	}

	os << prefix_p;
    os << out_text(m_time.to_string().c_str(), 8) << " "
       << out_format("%08llx", m_HADDR) << " "
       << out_text( hburst_text(m_HBURST), 6) << " "
       << " " << m_HCLK << " " << " "
       << out_format(" %2lld ", m_HMASTER) << " "
       <<  (m_HMASTLOCK ? "L" : " ") << " "
       << out_format("%04llx", m_HPROT) << " "
       << out_format("%08llx", m_HRDATA) << " "
	   << (m_HBUSREQ ? "TRUE  "  : "false ") << " "
	   << (m_HGRANT ? "TRUE "  : "false") << " "
       << (m_HRESETn ? "TRUE  " : "false ") << " "
       << (m_HREADY ? "TRUE " : "false") << " "
       << out_text(hresp_text(m_HRESP),5) << " "
       << (m_HSEL ? "TRUE " : "false") << " "
       << out_format("%4d", hsize_number(m_HSIZE)) << " "
       << out_format("%04llx ", m_HSPLIT) << " "
       << out_text(htrans_text(m_HTRANS),6) << " "
       << out_format("%08llx", m_HWDATA) << " "
       << (m_HWRITE ? "TRUE " : "false") << endl;
}

//------------------------------------------------------------------------------
//"ahb_values::hburst_text"
//------------------------------------------------------------------------------
inline const char* ahb_values::hburst_text( int burst )
{
    static const char* text[] =
    {
        "single",
        "incr",
        "wrap4",
        "incr4",
        "wrap8",
        "incr8",
        "wrap16",
        "incr16"
    };
    static char unknown[] = "*** unknown ***";

    if ( (burst >= hburst_single) && (burst <= hburst_incr16) )
        return text[burst];
    else
        return unknown;
}


//------------------------------------------------------------------------------
//"ahb_values::hsize_number"
//------------------------------------------------------------------------------
inline int ahb_values::hsize_number( int size )
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
//"ahb_values::hresp_text"
//------------------------------------------------------------------------------
inline const char* ahb_values::hresp_text( int resp )
{
    static const char* text[] =
    {
        "okay",
        "ERROR",
        "RETRY",
        "SPLIT"
    };
    static char unknown[] = "*** unknown ***";
    if ( (resp >= hresp_okay) && (resp <= hresp_split) )
        return text[resp];
    else
        return unknown;
}


//------------------------------------------------------------------------------
//"ahb_values::htrans_text"
//------------------------------------------------------------------------------
inline const char* ahb_values::htrans_text( int trans )
{
    static const char* text[] =
    {
        "idle",
        "busy",
        "nonseq",
        "seq"
    };
    static char unknown[] = "*** unknown ***";
    if ( (trans >= htrans_idle) && (trans <= htrans_sequential) )
        return text[trans];
    else
        return unknown;
}

} // namespace amba

#endif // !defined(amba_ahb_ports_h_INCLUDED)
