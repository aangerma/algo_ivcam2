/****************************************************************************
*
*  Copyright (C) 2006, Forte Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Forte Design Systems.
*
****************************************************************************/

#if !defined(amba_ahb_interfaces_h_INCLUDED)
#define amba_ahb_interfaces_h_INCLUDED

//#define EXPORT sc_port
#define EXPORT sc_export

namespace amba {

//==============================================================================
// AMBA AHB BUS Arbiter Interface
//
// ahb_arbiter_iface - signals and exports contained within ahb bus to
//                          be connected to an arbiter for the ahb bus. This
//                          is connected to an ahb_arbiter_port instance
//                          within an amba ahb bus. The EXPORTs in this
//                          class are arbiter-centric.
//==============================================================================
class ahb_arbiter_iface {
    typedef sc_signal_in_if<sc_uint<32> > in_if_addr;
    typedef sc_signal_in_if<bool>         in_if_bool;
    typedef sc_signal_in_if<sc_uint<2> >  in_if_2;
    typedef sc_signal_in_if<sc_uint<3> >  in_if_3;
    typedef sc_signal_in_if<sc_uint<16> > in_if_16;

  public: // inputs:
	EXPORT<in_if_addr> m_HADDR;          // Transfer address.
	EXPORT<in_if_3>    m_HBURST;         // See HBURST_values.
    EXPORT<in_if_bool> m_HBUSREQ[16];    // Bus request signals.
	sc_in<bool>        m_HCLK;           // Clock.
    EXPORT<in_if_bool> m_HLOCK[16];      // Master requires lock.
	EXPORT<in_if_bool> m_HREADY;         // Slave ready signal.
	EXPORT<in_if_2>    m_HRESP;          // See HRESP_values.
	sc_in<bool>        m_HRESETn;        // Reset signal.
	EXPORT<in_if_16>   m_HSPLIT[16];     // Slave splits.
	EXPORT<in_if_2>    m_HTRANS;         // See HTRANS_values.

  public: // outputs:
    sc_signal<bool>         m_HGRANT[16]; // Bus grant signals.
    sc_signal<sc_uint<4> >  m_HMASTER;    // Who has lock.
    sc_signal<bool>         m_HMASTLOCK;  // Current transfers are locked.

  public:
    inline ahb_arbiter_iface(
	    const char* name = sc_gen_unique_name("ahb_arbiter_iface"));
};

//------------------------------------------------------------------------------
//"ahb_arbiter_iface::ahb_arbiter_iface"
//
//------------------------------------------------------------------------------
inline ahb_arbiter_iface::ahb_arbiter_iface( const char* name ) :
    m_HADDR((std::string(name)+"_m_HADDR").c_str()),
    m_HBURST((std::string(name)+"_m_HBURST").c_str()),
    m_HCLK((std::string(name)+"_m_HCLK").c_str()),
    m_HREADY((std::string(name)+"_m_HREADY").c_str()),
    m_HRESP((std::string(name)+"_m_HRESP").c_str()),
    m_HRESETn((std::string(name)+"_m_HRESETn").c_str()),
    m_HTRANS((std::string(name)+"_m_HTRANS").c_str()),
    m_HMASTER((std::string(name)+"_m_HMASTER").c_str()),
    m_HMASTLOCK((std::string(name)+"_m_HMASTLOCK").c_str())
{
}


//==============================================================================
// AMBA AHB BUS Master Connections.
//
// ahb_master_iface - signals and exports within ahb bus to be 
//                         connected to an ahb_master_ports instance.
//                         The EXPORTs in this class are master-centric
//                         as opposed to bus-centric.
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
class ahb_master_iface {
  public: // inputs:
	sc_in<bool>                            m_HCLK;    // Clock signal.
	EXPORT<sc_signal_in_if<bool> >         m_HGRANT;  // Bus grant.
	EXPORT<sc_signal_in_if<sc_uint<32> > > m_HRDATA;  // Read data.
	EXPORT<sc_signal_in_if<bool> >         m_HREADY;  // Ready signal.
	EXPORT<sc_signal_in_if<bool> >         m_HRESETn; // Reset signal.
	EXPORT<sc_signal_in_if<sc_uint<2> > >  m_HRESP;   // Slave response.

  public: // outputs:
  	sc_signal<sc_uint<32> >                   m_HADDR;   // Transfer address.
	sc_signal<sc_uint<3> >                    m_HBURST;  // Burst mode.
	sc_signal<bool>                           m_HBUSREQ; // Bus request.
	sc_signal<bool>                           m_HLOCK;   // Bus lock.
	sc_signal<sc_uint<4> >                    m_HPROT;   // See HPROT_values.
	sc_signal<sc_uint<3> >                    m_HSIZE;   // See HSIZE_values.
	sc_signal<sc_uint<2> >                    m_HTRANS;  // See HTRANS_values.
	sc_signal<sc_uint<32> >                   m_HWDATA;  // Write data.
	sc_signal<bool>                           m_HWRITE;  // True if writing.

  public: // methods and operators:
    inline ahb_master_iface(
	    const char* name = sc_gen_unique_name("ahb_master_xf"));
};
  	
//------------------------------------------------------------------------------
//"ahb_master_iface::ahb_master_iface"
//
//------------------------------------------------------------------------------
inline ahb_master_iface::ahb_master_iface( const char* name ) :

    // INPUTS:

	m_HCLK((std::string(name)+"_HCLK").c_str()),
	m_HGRANT((std::string(name)+"_HGRANT").c_str()),
	m_HRDATA((std::string(name)+"_HRDATA").c_str()),
	m_HREADY((std::string(name)+"_HREADY").c_str()),
	m_HRESETn((std::string(name)+"_HRESETn").c_str()),
	m_HRESP((std::string(name)+"_HRESP").c_str()),

    // OUTPUTS:

	m_HADDR((std::string(name)+"_HADDR").c_str()),
	m_HBURST((std::string(name)+"_HBURST").c_str()),
	m_HBUSREQ((std::string(name)+"_HBUSREQ").c_str()),
	m_HLOCK((std::string(name)+"_HLOCK").c_str()),
	m_HPROT((std::string(name)+"_HPROT").c_str()),
	m_HSIZE((std::string(name)+"_HSIZE").c_str()),
	m_HTRANS((std::string(name)+"_HTRANS").c_str()),
	m_HWDATA((std::string(name)+"_HWDATA").c_str()),
	m_HWRITE((std::string(name)+"_HWRITE").c_str())
{}

//==============================================================================
// AMBA AHB BUS Slave Interface
//
// ahb_slave_iface - signals and exports within ahb bus to be 
//                        connected to an ahb_slave_ports instance.
//                        The EXPORTs in this class are slave-centric
//                        as opposed to bus-centric.
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
class ahb_slave_iface {
    typedef sc_signal_in_if<sc_uint<32> > in_if_addr;
    typedef sc_signal_in_if<bool>         in_if_bool;
    typedef sc_signal_in_if<sc_uint<32> > in_if_data;
    typedef sc_signal_in_if<sc_uint<2> >  in_if_2;
    typedef sc_signal_in_if<sc_uint<3> >  in_if_3;
    typedef sc_signal_in_if<sc_uint<4> >  in_if_4;

  public: // inputs:
  	EXPORT<in_if_addr>   m_HADDR;      // Transfer address.
	EXPORT<in_if_3>      m_HBURST;     // Burst mode.
	sc_in<bool>          m_HCLK;	   // Clock signal.
	EXPORT<in_if_4>      m_HMASTER;    // Current bus master.
	EXPORT<in_if_bool>   m_HMASTLOCK;  // True if bus is locked.
	EXPORT<in_if_4>      m_HPROT;      // See HPROT_values.
	EXPORT<in_if_bool>   m_HRESETn;    // Reset signal.
	EXPORT<in_if_bool>   m_HSEL;       // True if this slave selected.
	EXPORT<in_if_3>      m_HSIZE;      // Size of data word.
	EXPORT<in_if_2>      m_HTRANS;     // Transfer type.
	EXPORT<in_if_data>   m_HWDATA;     // Write data.
	EXPORT<in_if_bool>   m_HWRITE;     // True if writing.

  public: // outputs:
	sc_signal<sc_uint<32> > m_HRDATA;     // Read data.
	sc_signal<bool>         m_HREADY;     // Ready bit.
	sc_signal<sc_uint<2> >  m_HRESP;      // See HRESP_values.
	sc_signal<sc_uint<16> > m_HSPLIT;     // Legal master retries on split.

  public: // methods and operators:
  	inline ahb_slave_iface(
	    const char* name = sc_gen_unique_name("ahb_slave_xf"));
};
  	
//------------------------------------------------------------------------------
//"ahb_slave_iface::ahb_slave_iface"
//
//------------------------------------------------------------------------------
inline ahb_slave_iface::ahb_slave_iface( const char* name ) :
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
{}

} // namespace amba

#endif // !defined(amba_ahb_interfaces_h_INCLUDED)
