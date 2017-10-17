/****************************************************************************
*
*  Copyright (C) 2006, Forte Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Forte Design Systems.
*
****************************************************************************/

#if !defined(cynw_ahb_slave_h_INCLUDED)
#define cynw_ahb_slave_h_INCLUDED

#include "cynthhl.h"
#include "cyn_enums.h"

#include "amba_bus/amba_ahb_ports.h"
#include "amba_bus/cynw_ahb_master.h"
#include "cynw_simple_fifo.h"

// #### namespace amba {

enum cynw_decoder_status
{
	cds_okay = 0,
	cds_busy,
	cds_error
};
typedef sc_uint<2> cds_value;

//==============================================================================
// cynw_ahb_slave_port<DECODER,LEVEL> 
//             CONTAINER CLASS THAT IMPLEMENTS AN AHB SLAVE
//
//==============================================================================
template<typename DECODER, typename LEVEL=CYN::PIN> class cynw_ahb_slave_port;


//==============================================================================
// cynw_ahb_slave_port<DECODER,TLM_PASS_THRU>  
// 
// CONTAINER CLASS FOR A TLM-LEVEL AHB SLAVE
//
// Note that this class is an instance of the cynw_ahb_master_if class and
// it is also an sc_export of that class! The reason for this strange 
// structure is so that BDW sees this class as an sc_export and will 
// put an sc_export for it into the wrapper class it constructs for the
// bus interface this class appears in. The instance of this class that 
// appears as a field in the BDW wrapper will use the constructor that does 
// not have a name argument. The instance that is dynamically allocated as
// the actual instance (within the BDW wrapper) will use the constructor
// that has a name argument. So the class instance created with the named
// constructor will bind its sc_export to itself. The BDW execution 
// environment will bind the sc_export in the class instance created without
// a name argument to the one with the name argument, so both sc_exports
// will point to the dynamically created instance.
//
//      +----------------------+   +----------------+<--+<--+
//      | wrapper instance     |   |  real instance |   |   |
//      |                      |   |                |   |   |
//      | +-----------+        |   | +-----------+  |   |   |
//      | | sc_export |------------->| sc_export |------+   |
//      | +-----------+        |   | +-----------+  |       |
//      | +------------------+ |   +----------------+       |
//      | | gamma_ahb_slave* |------------------------------+
//      | +------------------+ |
//      +----------------------+
//==============================================================================
template<typename DECODER>
class cynw_ahb_slave_port<DECODER,TLM_PASS_THRU> : 
    public sc_export<cynw_ahb_master_if>,
	public cynw_ahb_master_if
{
	typedef cynw_ahb_slave_port<DECODER,TLM_PASS_THRU> this_type;
  public:
	cynw_ahb_slave_port( const char* name_p ) : m_decoder("decoder")
	{
		sc_export<cynw_ahb_master_if>::bind(*this);
	}
	cynw_ahb_slave_port() : m_decoder("decoder")
	{
	}
	virtual ~cynw_ahb_slave_port()
	{}

  public:
    virtual inline bool read( const sc_uint<32>& addr, sc_uint<32>& data );
    virtual inline bool read( 
		const sc_uint<32>&, unsigned int, sc_uint<32>* );

    virtual inline bool read_wrap( 
		const sc_uint<32>&, unsigned int, sc_uint<32>* );

    virtual inline void reset();

    virtual inline bool write(const sc_uint<32>& addr, const sc_uint<32>& data);
    virtual inline bool write( 
		const sc_uint<32>&, unsigned int, const sc_uint<32>* );

    virtual inline bool write_wrap( 
		const sc_uint<32>&, unsigned int, const sc_uint<32>* );

	CYN_METAPORT;
	DECODER m_decoder;

  private:
    cynw_ahb_slave_port( const this_type& );	
    const this_type& operator = ( const this_type& );	
};

//------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------
template<typename DECODER>
inline bool cynw_ahb_slave_port<DECODER,TLM_PASS_THRU>::read( 
	const sc_uint<32>& addr, sc_uint<32>& data )
{ 
	switch ( m_decoder.get( addr, data ) )
	{
	  case cds_okay: return false;
	  default:       return true; // ####
	}

}


//------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------
template<typename DECODER>
inline bool cynw_ahb_slave_port<DECODER,TLM_PASS_THRU>::read( 
	const sc_uint<32>&addr, unsigned int data_n, sc_uint<32>* data_p )
{ 
	sc_uint<32>  address;  // Next address to read from.
	unsigned int data_i;   // Element in data_p now setting.
	bool         rc=false; // return code.

	address = addr;
	for ( data_i = 0; data_i < data_n; data_i++ )
	{
		switch( m_decoder.get( address, data_p[data_i]) ) 
        {
		  case cds_okay:
			break;
		  default:
		    rc = true; 
			break;
		}
		address += 4;
	}
	return rc;
}

//------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------
template<typename DECODER>
inline bool cynw_ahb_slave_port<DECODER,TLM_PASS_THRU>::read_wrap( 
	const sc_uint<32>&addr, unsigned int data_n, sc_uint<32>* data_p )
{ 
	sc_uint<32>  address;  // Next address to read from.
	unsigned int data_i;   // Element in data_p now setting.
	int          hob;      // High order bit of address wrap.
	bool         rc=false; // return code.

	switch( data_n )
	{
	  case 4:  hob = 3; break;
	  case 8:  hob = 4; break;
	  case 16: hob = 5; break;
	  default:
		cerr << "Illegal read wrap count " << data_n
			 << " value must be 4, 8, or 16" << endl;
		return true;
	}
	address = addr;
	for ( data_i = 0; data_i < data_n; data_i++ )
	{
		switch( m_decoder.get( address, data_p[data_i]) ) 
        {
		  case cds_okay:
			break;
		  default:
		    rc = true; 
			break;
		}
		address(hob,2) = address(hob,2) + 1;
	}
	return rc;
}


//------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------
template<typename DECODER>
inline void cynw_ahb_slave_port<DECODER,TLM_PASS_THRU>::reset()
{
}


//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,TLM_PASS_THRU>::write"
//------------------------------------------------------------------------------
template<typename DECODER>
inline bool cynw_ahb_slave_port<DECODER,TLM_PASS_THRU>::write(
	const sc_uint<32>& addr, const sc_uint<32>& data ) 
{ 
	switch( m_decoder.put( addr, data) ) 
	{
	  case cds_okay: return false;
	  default:       return true; // ####
	}
}


//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,TLM_PASS_THRU>::write"
//------------------------------------------------------------------------------
template<typename DECODER>
inline bool cynw_ahb_slave_port<DECODER,TLM_PASS_THRU>::write( 
	const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p )
{
	sc_uint<32> address;  // address for write call.
	sc_uint<32> data;     // data to be written.
	bool        rc=false; // return code.

	address = addr;
	for ( unsigned int data_i = 0; data_i < data_n; data_i++, address+=4 )
	{
		data = data_p[data_i];
		switch( m_decoder.put( address, data) ) 
		{
		  case cds_okay:
		  	break;
		  default:
		  	rc = true; 
			break;
		}
	}
	return rc;
}

//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,TLM_PASS_THRU>::write_wrap"
//------------------------------------------------------------------------------
template<typename DECODER>
inline bool cynw_ahb_slave_port<DECODER,TLM_PASS_THRU>::write_wrap( 
	const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p )
{
	sc_uint<32> address;  // address for write call.
	sc_uint<32> data;	  // data for write.
	int         hob;      // high order bit of address wrap.
	bool        rc=false; // return code.

	switch( data_n )
	{
	  case 4:  hob = 3; break;
	  case 8:  hob = 4; break;
	  case 16: hob = 5; break;
	  default:
		cerr << "Illegal read wrap count " << data_n
			 << " value must be 4, 8, or 16" << endl;
		return true;
	}
	address = addr;
	for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
	{
		data = data_p[data_i];
		switch( m_decoder.put( address, data) ) 
		{
		  case cds_okay:
		  	break;
		  default:
		  	rc = true; 
			break;
		}
		address(hob,2) = address(hob,2) + 1;
	}
	return rc;
}

//==============================================================================
// cynw_ahb_slave_port<DECODER,TLM_OSCI>  
// 
// CONTAINER CLASS - OSCI TLM-LEVEL AHB SLAVE
//
// Note that this class is an instance of the osci_tlm_ahb_transport_if class 
// and it is also an sc_export of that class! The reason for this strange 
// structure is so that BDW sees this class as an sc_export and will 
// put an sc_export for it into the wrapper class it constructs for the
// bus interface this class appears in. The instance of this class that 
// appears as a field in the BDW wrapper will use the constructor that does 
// not have a name argument. The instance that is dynamically allocated as
// the actual instance (within the BDW wrapper) will use the constructor
// that has a name argument. So the class instance created with the named
// constructor will bind its sc_export to itself. The BDW execution 
// environment will bind the sc_export in the class instance created without
// a name argument to the one with the name argument, so both sc_exports
// will point to the dynamically created instance.
//
//      +----------------------+   +----------------+<--+<--+
//      | wrapper instance     |   |  real instance |   |   |
//      |                      |   |                |   |   |
//      | +-----------+        |   | +-----------+  |   |   |
//      | | sc_export |------------->| sc_export |------+   |
//      | +-----------+        |   | +-----------+  |       |
//      | +------------------+ |   +----------------+       |
//      | | gamma_ahb_slave* |------------------------------+
//      | +------------------+ |
//      +----------------------+
//==============================================================================

template<typename DECODER>
class cynw_ahb_slave_port<DECODER,TLM_OSCI> : 
	public sc_export<osci_tlm_ahb_transport_if>,
	public osci_tlm_ahb_transport_if
{
	typedef cynw_ahb_slave_port<DECODER,TLM_OSCI> this_type;
  public:
  	cynw_ahb_slave_port(const char* name_p): m_decoder("decoder")
	{
		sc_export<osci_tlm_ahb_transport_if>::bind(*this);
	}
  	cynw_ahb_slave_port() : m_decoder("decoder")
	{
	}
	inline virtual ~cynw_ahb_slave_port()
	{}

  public:
    virtual osci_tlm_ahb_response transport( const osci_tlm_ahb_request& req )
	{
		sc_uint<32>            address;  // Address of next slave access.
		amba::hburst_type      burst;    // Request count.
		sc_uint<8>             byte;     // Byte value.
		int                    data_i;   // Element of data now accessing.
		int                    data_n;   // Number of elements to process.
		sc_uint<16>            halfword; // 16-bit value.
		osci_tlm_ahb_response  resp;     // Response.
		amba::hsize_type       size;     // Size of data in request.
		sc_uint<32>            word;     // 32-bit value.
		bool                   write;    // True if this is a write request.

		req.decode_opcode( write, size, burst );

		// WRITE REQUEST:

		if ( write )
		{
			switch ( burst )
			{
			  case amba::hburst_single:
			  	switch ( size )
				{
				  case amba::hsize_32:
					word = req.m_data.words[0];
				  	m_decoder.put( req.m_address, word); 
					break;
				  default:
				  	cerr << __FILE__ << "(" << __LINE__ << ") unknown size "
					     << size << " " << hex << req.m_opcode << endl;
					resp.m_error = true;
					return resp;
				}
			    break;

			  case amba::hburst_incr4:
			  case amba::hburst_incr8:
			  case amba::hburst_incr16:
			    switch( burst )
				{
				  case amba::hburst_incr4:  data_n = 4;  break;
				  case amba::hburst_incr8:  data_n = 8;  break;
				  case amba::hburst_incr16: data_n = 16; break;
				}
				address = req.m_address;
			  	switch ( size )
				{
				  case amba::hsize_32:
					for ( data_i = 0; data_i < data_n; data_i++, address+=4 )
					{
						word = req.m_data.words[data_i];
						m_decoder.put( address, word ); 
					}
					break;
				  default:
				  	cerr << __FILE__ << "(" << __LINE__ << ") unknown size "
					     << size << endl;
					resp.m_error = true;
					return resp;
				}
				break;

			  case amba::hburst_wrap4:
				address = req.m_address;
			  	switch ( size )
				{
				  case amba::hsize_32:
					for ( data_i = 0; data_i < 4; data_i++ )
					{
						word = req.m_data.words[data_i];
						m_decoder.put( address, word ); 
						address(3,2) = address(3,2) + 1;
					}
					break;
				  default:
				  	cerr << __FILE__ << "(" << __LINE__ << ") unknown size "
					     << size << endl;
					resp.m_error = true;
					return resp;
				}
				break;

			  case amba::hburst_wrap8:
				address = req.m_address;
			  	switch ( size )
				{
				  case amba::hsize_32:
					for ( data_i = 0; data_i < 8; data_i++ )
					{
						word = req.m_data.words[data_i];
						m_decoder.put( address, word ); 
						address(4,2) = address(4,2) + 1;
					}
					break;
				  default:
				  	cerr << __FILE__ << "(" << __LINE__ << ") unknown size "
					     << size << endl;
					resp.m_error = true;
					return resp;
				}
				break;

			  case amba::hburst_wrap16:
				address = req.m_address;
			  	switch ( size )
				{
				  case amba::hsize_32:
					for ( data_i = 0; data_i < 16; data_i++ )
					{
						word = req.m_data.words[data_i];
						m_decoder.put( address, word ); 
						address(5,2) = address(5,2) + 1;
					}
					break;
				  default:
				  	cerr << __FILE__ << "(" << __LINE__ << ") unknown size "
					     << size << endl;
					resp.m_error = true;
					return resp;
				}
				break;
			}
		}

		// READ REQUEST:

		else
		{
		    switch ( burst )
			{
			  case amba::hburst_single:
			  	switch ( size )
				{
				  case amba::hsize_32:
				  	m_decoder.get(  req.m_address, word ); 
					resp.m_data.words[0] = word;
					break;
				  default:
				  	cerr << __FILE__ << "(" << __LINE__ << ") unknown size "
					     << size << endl;
					resp.m_error = true;
					return resp;
				}
				break;
				
			  case amba::hburst_incr4: 
			  case amba::hburst_incr8:
			  case amba::hburst_incr16:
			    switch( burst )
				{
				  case amba::hburst_incr4:  data_n = 4;  break;
				  case amba::hburst_incr8:  data_n = 8;  break;
				  case amba::hburst_incr16: data_n = 16; break;
				}
				address = req.m_address;
			  	switch ( size )
				{
				  case amba::hsize_32:
					for ( data_i = 0; data_i < data_n; data_i++ )
					{
				  	    m_decoder.get(  address, word ); 
					    resp.m_data.words[data_i] = word;
						address += 4;
					}
					break;
				  default:
				  	cerr << __FILE__ << "(" << __LINE__ << ") unknown size "
					     << size << endl;
					resp.m_error = true;
					return resp;
				}
				break;

			  case amba::hburst_wrap4: 
				address = req.m_address;
			  	switch ( size )
				{
				  case amba::hsize_32:
					for ( data_i = 0; data_i < 4; data_i++ )
					{
				  	    m_decoder.get( address, word ); 
					    resp.m_data.words[data_i] = word;
						address(3,2) = address(3,2) + 1;
					}
				}
				break;

			  case amba::hburst_wrap8:
				address = req.m_address;
			  	switch ( size )
				{
				  case amba::hsize_32:
					for ( data_i = 0; data_i < 8; data_i++ )
					{
				  	    m_decoder.get( address, word ); 
					    resp.m_data.words[data_i] = word;
						address(4,2) = address(4,2) + 1;
					}
				}
				break;

			  case amba::hburst_wrap16:
				address = req.m_address;
			  	switch ( size )
				{
				  case amba::hsize_32:
					for ( data_i = 0; data_i < 16; data_i++ )
					{
				  	    m_decoder.get( address, word ); 
					    resp.m_data.words[data_i] = word;
						address(5,2) = address(5,2) + 1;
					}
					break;
				  default:
				  	cerr << __FILE__ << "(" << __LINE__ << ") unknown size "
					     << size << endl;
					resp.m_error = true;
					return resp;
				}
				break;
			}
		}
		resp.m_error = false;
		return resp;
	}

	CYN_METAPORT;
	DECODER m_decoder;

  private:
    cynw_ahb_slave_port( const this_type& );	
    const this_type& operator = ( const this_type& );	
};


//==============================================================================
// cynw_ahb_slave_port<DECODER,CYN::PIN>  
//
// CONTAINER CLASS FOR A PIN-LEVEL AHB SLAVE SUPPORTING 32-BIT TRANSFERS
//
// The cynw_ahb_slave_base class contains the ports to be exported by
// bdw_wrapgen. By splitting out the ports from the class containing the
// bus_monitor thread we insure that bdw_wrapgen won't create a thread 
// in the wrapper class (in addition to the one in the actual class.)
//==============================================================================
template<typename DECODER>
class cynw_ahb_slave_base : 
	public amba::ahb_slave_ports
{
  public:
    cynw_ahb_slave_base(
		const char* name_p=sc_gen_unique_name("ahb_slave_base") ) : 
		m_decoder("decoder")
	{}

	CYN_METAPORT; 
	DECODER m_decoder;
};

template<typename DECODER>
class cynw_ahb_slave_port<DECODER,CYN::PIN> : 
	public sc_module,
	public cynw_ahb_slave_base<DECODER>
{
	typedef cynw_ahb_slave_port<DECODER,CYN::PIN> SC_CURRENT_MODULE;
	typedef cynw_ahb_slave_port<DECODER,CYN::PIN> this_type;
  public:
  	CYN_INLINE_MODULE;
	SC_CTOR(cynw_ahb_slave_port) 
#if defined(ioConfig_STYLE2)
		: 
		m_sm_address("sm_address"),
		m_sm_burst("sm_burst"),
		m_sm_enable("sm_enable"),
		m_sm_fifo("read_fifo"),
		m_sm_write_data("sm_write_data"),
		m_sm_write_enable("sm_write_enable")
#endif
#if defined(ioConfig_NON_BLK)
		:
		m_sm_fifo("read_fifo")
#endif
	{
	    SC_CTHREAD( bus_monitor, this->m_HCLK.pos() );
		reset_signal_is( this->m_HRESETn, false );
#       if defined(ioConfig_STYLE2)
	        SC_CTHREAD( storage_manager, this->m_HCLK.pos() );
		    reset_signal_is( this->m_HRESETn, false );
#       endif
#       if defined(EXERCISE_MASTER) && !defined(CYNTHHL)
			m_busy_duration = 0;
#       endif
	}
	inline void busy_wait( amba::ahb_control& control );
	inline void bus_monitor();
	inline void emit_error();
	inline void get_data( amba::ahb_control& control, sc_uint<32>& data );
	inline void get_request( amba::ahb_control& control );
	inline bool nb_put_again( amba::ahb_control& control ); 
	inline bool nb_put_data( amba::ahb_control& control, 
		const sc_uint<32>& data );
	inline void put_data( amba::ahb_control& control, const sc_uint<32>& data );
	inline void reset();
#if defined(ioConfig_STYLE2)
	inline void storage_manager();
#endif

#   if defined(EXERCISE_MASTER) && !defined(CYNTHHL)
#       define EXERCISE_MASTER_RESET m_busy_cycle_i = 0
#       define EXERCISE_MASTER_INCREMENT(CONTROL) show_busy(CONTROL)
		// wait for a number of cycles unless this is a single transfer
        inline void show_busy(amba::ahb_control& control)
        {
			if ( control.m_burst == amba::hburst_single ) return;
            if ( m_busy_duration > 0 && m_busy_start_i == m_busy_cycle_i )
            {
                this->m_HREADY = false;
                for ( int wait_i = 0; wait_i < m_busy_duration; wait_i++ )
                {
					busy_wait(control);
                }
            }
			m_busy_cycle_i++;
        }

        inline void set_busy( int start_i, int duration )
        {
            m_busy_start_i = start_i;
            m_busy_duration = duration;
        }

        int m_busy_cycle_i;   // Current cycle.
        int m_busy_duration;  // Duration of the busy.
        int m_busy_start_i;   // Cycle within operation to start busy.
#   else
#       define EXERCISE_MASTER_RESET
#       define EXERCISE_MASTER_INCREMENT(CONTROL)
#   endif

	sc_signal<sc_uint<32> >  m_next_address; // Next addr in burst
	sc_signal<sc_uint<32> >  m_sm_next_address; // Next addr in burst

#if defined(ioConfig_STYLE2)
	// INTRA-THREAD COMMUNICATION: bus_monitor() and sm_manager()
	//
	// (1) For write operations the m_sm_burst field is ignored, writes
	//     are always presented as single operations.
	// (2) For read operations the m_write_data field is ignored.
	// (3) The m_sm_enable single is held high for a single clock for
	//     each operation presented to the storage manager.

	sc_signal<sc_uint<32> >     m_sm_address;      // address storage access.
	sc_signal<sc_uint<3> >      m_sm_burst;        // burst type.
	sc_signal<bool>             m_sm_enable;       // true to activate sm.
	cynw_simple_fifo<sc_uint<32>,4> m_sm_fifo;     // read fifo.
	sc_signal<sc_uint<32> >     m_sm_write_data;   // data for write operation.
	sc_signal<bool>             m_sm_write_enable; // true if write operation.
#endif

#if defined(ioConfig_NON_BLK)
	cynw_simple_fifo<sc_uint<32>,4> m_sm_fifo;     // read fifo.
#endif

  private:
    cynw_ahb_slave_port( const this_type& );	
    const this_type& operator = ( const this_type& );	
};

//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,CYN::PIN>::busy_wait"
//
// This method waits one clock with an indication of busy, updating the 
// control information.
//
//------------------------------------------------------------------------------
template<typename DECODER>
inline void cynw_ahb_slave_port<DECODER,CYN::PIN>::busy_wait( 
	amba::ahb_control& control )
{
	{
		CYN_PROTOCOL("busy_wait");

		this->m_HREADY = false; 
		this->m_HRESP = amba::hresp_okay;
		wait();

		control.m_address = this->m_HADDR.read();
		control.m_burst = this->m_HBURST.read();
		control.m_sel = this->m_HSEL.read();
		control.m_size = this->m_HSIZE.read();
		control.m_trans = this->m_HTRANS.read();
		control.m_write = this->m_HWRITE.read();
	}
}

//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,CYN::PIN>::bus_monitor"
//
// This method provides the semantics for the ahb bus monitoring thread.
//
//    READ SEQUENCE:
//            | addr1    | addr2    | addr3    | addr4    | ADDR1    |
//            |          | data1    | data2    | data3    | data4    | DATA1
// get_request|          | put_data | put_data | put_data | put_data | put_data
//            | read(d1) | read(d2) | read(d2) | read(d3) | read(d4) | read(D1)
//
//    WRITE SEQUENCE:
//            | addr1    | addr2    | addr3    | addr4    | ADDR1    |
//            |          | data1    | data2    | data3    | data4    | DATA1
// get_request| get_data | get_data | get_data | get_data | get_data |
//            |          | write(d1)| write(d2)| write(d3)| write(d4)| write(D1)
//------------------------------------------------------------------------------
template<typename DECODER>
inline void cynw_ahb_slave_port<DECODER,CYN::PIN>::bus_monitor()
{
	amba::ahb_control control;      // Control information from the request.
	sc_uint<32>       data;         // Data to transfer to or from the bus.

#if defined(ioConfig_BLK)
	sc_uint<5>        count;        // Number of transfers to be done.
	sc_uint<2>        error;        // Error return value.
	sc_uint<8>        i;            // Iteration now performing.
	sc_uint<3>        latency;      // Latency for the operation.
	sc_uint<32>       next_address; // Next address.
	{ 
		CYN_PROTOCOL("reset");
		this->m_HREADY = true;
		this->m_HRESP = amba::hresp_okay;        
		this->m_HSPLIT = 0;
		this->m_HRDATA = 0;
		this->reset();
		this->m_decoder.nb_deassert();
		wait(); 
    }

    for (;;)
    {
        get_request( control );
		// EXERCISE_MASTER_RESET;
        do{
			// EXERCISE_MASTER_INCREMENT(control);
			if( control.m_write )
			{
				m_next_address = control.m_address;
				get_data( control, data );
				error = this->m_decoder.put( m_next_address.read(), data );
			}
		    else
			{
				{
					this->m_decoder.get( control.m_address, data ); 
				}
				put_data( control, data );
				//put_data( control );
			}
			if ( error == cds_error )
			{
				cout << " emitting error " << endl;
				emit_error();
				break;
			}
		} while( control.m_trans == amba::htrans_sequential );
	}
#elif defined(ioConfig_STYLE2)
	{ 
		CYN_PROTOCOL("reset");
		this->m_HREADY = true;
		this->m_HRESP = amba::hresp_okay;        
		this->m_HSPLIT = 0;
		this->m_HRDATA = 0;
		this->reset();
		this->m_sm_fifo.pop_reset();
		m_sm_enable = false;
		wait(); 
    }

    for (;;)
    {
        get_request( control );
		// EXERCISE_MASTER_RESET;
		// EXERCISE_MASTER_INCREMENT(control);
		if( control.m_write )
		{
			do{
				m_next_address = control.m_address;
				get_data( control, data );
				m_sm_address = m_next_address;
				m_sm_enable = true;
				m_sm_write_enable = true;
				m_sm_write_data = data;
			} while( control.m_trans == amba::htrans_sequential );
		}
		else
		{
			m_sm_address = control.m_address;
			m_sm_write_enable = false;
			m_sm_enable = true;
			m_sm_burst = control.m_burst;
			{
                do 
				{
					while ( m_sm_fifo.is_empty() )
					{
						busy_wait( control );
						m_sm_enable = false;
					}
					{
						m_sm_fifo.nb_pop(data);
						put_data(control, data);
						m_sm_enable = false;
					}
				} while( control.m_trans != amba::htrans_idle );
			}
		}
	}
#elif defined(ioConfig_NON_BLK)
	sc_uint<32> address;      // address in storage to be accessed.
	sc_uint<5>  bus_count;    // count of words left to write to bus.
	sc_uint<32> bus_data;     // data to write to bus.
	sc_uint<5>  fifo_count;   // count of words left to write to fifo.
	sc_uint<3>  latency;      // count of waits to be done before reading memory
	sc_uint<5>  mem_count;    // count of words left to read from memory.
	sc_uint<32> mem_data;     // data read from memory.
	bool        master_ready; // true if master was ready last cycle.

	{ 
		CYN_PROTOCOL("reset");
		this->m_HREADY = true;
		this->m_HRESP = amba::hresp_okay;        
		this->m_HSPLIT = 0;
		this->m_HRDATA = 0;
		this->reset();
		this->m_decoder.nb_deassert();
		this->m_sm_fifo.pop_reset();
		this->m_sm_fifo.push_reset();
		wait(); 
    }
    for (;;)
    {   
        get_request( control );
#		if !defined(CYNTHHL)	
			assert( m_sm_fifo.is_empty() );
#		endif

		// WRITE OPERATION:

		if( control.m_write )
		{   
			do{ 
				address = control.m_address;
				get_data( control, data );
				this->m_decoder.nb_put( address, data );
			} while( control.m_trans == amba::htrans_sequential );
		}

		// READ OPERATION:

		else
		{   
            switch ( control.m_burst )
            {
              case hburst_single:
                mem_count = 1; break;
              case hburst_incr:
              case hburst_wrap4:
              case hburst_incr4:
                  mem_count = 4; break;
              case hburst_wrap8:
              case hburst_incr8:
                  mem_count = 8; break;
              case hburst_wrap16:
              case hburst_incr16:
                  mem_count = 16; break;
              default:
                mem_count = 0;
                break;
            }
			latency = this->m_decoder.get_latency( address );
			bus_count = mem_count;
			fifo_count = mem_count;
			address = control.m_address;
			master_ready = true;
			for ( ; bus_count > 0; )
			{
				CYN_PROTOCOL("read_loop");
				// printf("read loop bus %lld mem %lld latency %lld fifo %lld data %lld\n", (uint64)bus_count, (uint64)mem_count, (uint64)latency, (uint64)fifo_count, (uint64)m_decoder.m_rf0.m_read_data.read());


				// INITIATE MEMORY READ OPERATIONS:

                if ( mem_count > 0 ) {
                    this->m_decoder.nb_get_start( address );
                    switch ( control.m_burst )
                    {
                      case hburst_wrap4:  address(3,2)=address(3,2)+1;   break;
                      case hburst_wrap8:  address(4,2)=address(4,2)+1;   break;
                      case hburst_wrap16: address(5,2)=address(5,2)+1;   break;
                      default:            address(31,2)=address(31,2)+1; break;
                    }
					mem_count--;
                } 

				// LOAD FIFO WITH RESULTS OF THE READ:

				if ( latency > 0 )
				{
					latency--;
				}
                else 
				{
					if ( fifo_count > 0 ) 
					{
						this->m_decoder.nb_get(mem_data);
						m_sm_fifo.nb_push( mem_data );
						fifo_count--;
					}
				}

				// UNLOAD FIFO AND WRITE THE BUS:
				//
				// A wait() is always done in this section.

				{
					if ( master_ready && m_sm_fifo.is_empty() )
					{
						busy_wait( control );
					}
					else
					{
						if ( master_ready )
						{
							m_sm_fifo.nb_pop(bus_data);
							master_ready = nb_put_data( control, bus_data );
						}
						else
						{
							master_ready = nb_put_again( control );
						}
						if ( master_ready )
						{
							bus_count--;
						}
					}
					if ( mem_count == 0 ) 
					{ 
						this->m_decoder.nb_deassert(); 
					}
				}
			}
		}
	} 
#endif
}


//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,CYN::PIN>::emit_error"
//
// This method puts an error response on the bus. The response consists of
// two cycles: the first shows an error and drives ready low. The second
// shows an error and drives ready high. On exit the ready signal will
// be assigned high and the response will be assigned okay.
//------------------------------------------------------------------------------
template<typename DECODER>
inline void cynw_ahb_slave_port<DECODER,CYN::PIN>::emit_error()
{
	{
		CYN_PROTOCOL("emit_error");

		this->m_HREADY = false;
		this->m_HRESP = amba::hresp_error;
		wait();
		this->m_HREADY = true;
		wait();
		this->m_HRESP = amba::hresp_okay;
	}
}

//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,CYN::PIN>::get_data"
//
// This method reads from the bus the next word of the current request.
//
//------------------------------------------------------------------------------
template<typename DECODER>
inline void cynw_ahb_slave_port<DECODER,CYN::PIN>::get_data( 
	amba::ahb_control& control, sc_uint<32>& data )
{
	sc_uint<2> trans;	// HTRANS value.

	{
		CYN_PROTOCOL("get_data");

		this->m_HREADY = true;
		this->m_HRESP = amba::hresp_okay;
		do {
			wait();
			trans = this->m_HTRANS.read();
		} while ( trans == amba::htrans_busy );

		control.m_address = this->m_HADDR.read();
		control.m_burst = this->m_HBURST.read();
		control.m_sel = this->m_HSEL.read();
		control.m_size = this->m_HSIZE.read();
		control.m_trans = trans;
		control.m_write = this->m_HWRITE.read();

		data = this->m_HWDATA.read();

		this->m_HREADY = false; // assume it will take more than one cycle.
	}
}

//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,CYN::PIN>::get_request"
//
// This method.
//------------------------------------------------------------------------------
template<typename DECODER>
inline void cynw_ahb_slave_port<DECODER,CYN::PIN>::get_request( 
	amba::ahb_control& control )
{
	bool       select; // Value of HSEL.
	sc_uint<3> trans;  // Value of HTRANS.

	{
		CYN_PROTOCOL("get_request");
		CYN_INPUT_DELAY(this->m_HADDR,0.4,"HADDR delay");
		CYN_INPUT_DELAY(this->m_HBURST,0.4,"HBURST delay");
		CYN_INPUT_DELAY(this->m_HREADY,0.4,"HREADY delay");
		CYN_INPUT_DELAY(this->m_HSEL,0.4,"HSEL delay");
		CYN_INPUT_DELAY(this->m_HSIZE,0.4,"HSIZE delay");
		CYN_INPUT_DELAY(this->m_HTRANS,0.4,"HTRANS delay");
		CYN_INPUT_DELAY(this->m_HWRITE,0.4,"HWRITE delay");

		this->m_HREADY = true;
		this->m_HRESP = amba::hresp_okay;
		do {
			wait();
			select = this->m_HSEL.read();
			trans = this->m_HTRANS.read();
#           if defined(ioConfig_BLK)
			this->m_decoder.nb_deassert();
#			elif defined(ioConfig_STYLE2)
				m_sm_enable = false; 
#			endif 
		} while ( !select || ( trans == amba::htrans_idle ) );

		control.m_address = this->m_HADDR.read();
		control.m_burst = this->m_HBURST.read();
		control.m_sel = select;
		control.m_size = this->m_HSIZE.read();
		control.m_trans = trans;
		control.m_write = this->m_HWRITE.read();
		this->m_HREADY = false;
	}
}

//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,CYN::PIN>::nb_put_again"
//
// This method writes to the ahb bus the next word of the current request if
// the master is ready.
//    true  = master was ready
//    false = master was busy
//------------------------------------------------------------------------------
template<typename DECODER>
inline bool cynw_ahb_slave_port<DECODER,CYN::PIN>::nb_put_again( 
	amba::ahb_control& control )
{
	sc_uint<2> trans;	// HTRANS value.
	{
		//CYN_PROTOCOL("nb_put_again");

		this->m_HREADY = true;
		this->m_HRESP = amba::hresp_okay;
		wait();
		trans = this->m_HTRANS.read();

		control.m_address = this->m_HADDR.read();
		control.m_burst = this->m_HBURST.read();
		control.m_sel = this->m_HSEL.read();
		control.m_size = this->m_HSIZE.read();
		control.m_trans = trans;
		control.m_write = this->m_HWRITE.read();

		this->m_HREADY = false; // assume it will take more than one cycle.
		return ( trans == amba::htrans_busy ) ? false : true;
	}
}

//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,CYN::PIN>::nb_put_data"
//
// This method writes to the ahb bus the next word of the current request if
// the master is ready.
//    true  = master was ready
//    false = master was busy
//------------------------------------------------------------------------------
template<typename DECODER>
inline bool cynw_ahb_slave_port<DECODER,CYN::PIN>::nb_put_data( 
	amba::ahb_control& control, const sc_uint<32>& data )
{
	sc_uint<2> trans;	// HTRANS value.
	{
		//CYN_PROTOCOL("nb_put_data");

		this->m_HRDATA = data; 
		this->m_HREADY = true;
		this->m_HRESP = amba::hresp_okay;
		wait();
		trans = this->m_HTRANS.read();

		control.m_address = this->m_HADDR.read();
		control.m_burst = this->m_HBURST.read();
		control.m_sel = this->m_HSEL.read();
		control.m_size = this->m_HSIZE.read();
		control.m_trans = trans;
		control.m_write = this->m_HWRITE.read();

		this->m_HREADY = false; // assume it will take more than one cycle.
		return ( trans == amba::htrans_busy ) ? false : true;
	}
}

//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,CYN::PIN>::put_data"
//
// This method writes to the ahb bus the next word of the current request. If
// the master is not ready the method will wait until it is.
//------------------------------------------------------------------------------
template<typename DECODER>
inline void cynw_ahb_slave_port<DECODER,CYN::PIN>::put_data( 
	amba::ahb_control& control, const sc_uint<32>& data )
{
	sc_uint<2> trans;	// HTRANS value.
	{
		CYN_PROTOCOL("put_data");

		this->m_HRDATA = data; 
		this->m_HREADY = true;
		this->m_HRESP = amba::hresp_okay;
		do {
			wait();
			trans = this->m_HTRANS.read();
		} while ( trans == amba::htrans_busy );

		control.m_address = this->m_HADDR.read();
		control.m_burst = this->m_HBURST.read();
		control.m_sel = this->m_HSEL.read();
		control.m_size = this->m_HSIZE.read();
		control.m_trans = trans;
		control.m_write = this->m_HWRITE.read();

		this->m_HREADY = false; // assume it will take more than one cycle.
	}
}

//------------------------------------------------------------------------------
//"cynw_ahb_slave_port<DECODER,CYN::PIN>::reset"
//
// This method performs a reset of this interface.
//------------------------------------------------------------------------------
template<typename DECODER>
inline void cynw_ahb_slave_port<DECODER,CYN::PIN>::reset()
{
}

#if defined(ioConfig_STYLE2)
template<typename DECODER>
inline void cynw_ahb_slave_port<DECODER,CYN::PIN>::storage_manager()
{
	sc_uint<32>       address;      // address to be written.
	sc_uint<3>        burst;        // opcode for storage manager to process.
	sc_uint<5>        count;        // count of read operations to perform.
	sc_uint<32>       data;         // data to transfer to or from the bus.
	bool              enable;       // true if storage manager request made.
	sc_uint<8>        i;            // read loop iterator.
	sc_uint<3>        latency;      // Latency for the operation.
	bool              write_enable; // true if requested operation is a write.


	{ 
		CYN_PROTOCOL("reset");
		this->m_decoder.nb_deassert();
		m_sm_fifo.push_reset();
		wait(); 
    }

    for (;;)
    {
		{
			CYN_PROTOCOL("poll");
			do
			{
				wait();
				assert( m_sm_fifo.is_empty() );
				enable = m_sm_enable.read();
				this->m_decoder.nb_deassert();
			} while ( !enable );
			burst = m_sm_burst.read();
			address = m_sm_address.read();
			data = m_sm_write_data.read();
			write_enable = m_sm_write_enable.read();
		}

		// WRITE OPERATION: THESE ARE PRESENTED SINGLE OPERATIONS:

		if ( write_enable )
		{
			this->m_decoder.nb_put( m_sm_address.read(), data );
		}

		// READ OPERATION:

		else
		{
			switch ( burst )
			{
			  case hburst_single: 
				count = 1; break;
			  case hburst_incr:
			  case hburst_wrap4:
			  case hburst_incr4:
				  count = 4; break;
			  case hburst_wrap8:
			  case hburst_incr8:
				  count = 8; break;
			  case hburst_wrap16:
			  case hburst_incr16:
				  count = 16; break;
			  default:
			  	cout << " #### #### hit default!!! " << endl;
				count = 0;
				break;
			}
			latency = this->m_decoder.get_latency( address ); 
			for ( i = 0; i < (count+latency); i++ )
			{
				if ( i < count )
				{
					this->m_decoder.nb_get_start( address );
					switch ( burst )
					{
					case hburst_wrap4:
						address(3,2) = address(3,2)+1;
						break;
					case hburst_wrap8:
						address(4,2) = address(4,2)+1;
						break;
					case hburst_wrap16:
						address(5,2) = address(5,2)+1;
						break;
					default:
						address(31,2) = address(31,2)+1;
						break;
					}
				}
				else
				{
					this->m_decoder.nb_deassert();
				}
				if ( i >= latency )
				{
					this->m_decoder.nb_get(data);
					m_sm_fifo.nb_push( data );
				}
				wait();
			} 
		}
	}
}

#endif // defined(ioConfig_STYLE2)

// } // namespace amba

#endif // !defined(cynw_ahb_slave_h_INCLUDED)
