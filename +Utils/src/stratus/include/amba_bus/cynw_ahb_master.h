/****************************************************************************
*
*  Copyright (C) 2006, Forte Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Forte Design Systems.
*
****************************************************************************/

#if !defined(cynw_ahb_master_h_INCLUDED)
#define cynw_ahb_master_h_INCLUDED

#include "amba_ahb_ports.h"
#include "tlm_interfaces/tlm_core_ifs.h"
#include "cyn_enums.h"


#define DEBUG_CYNW_AHB_MASTER false

// DEFINE THE SYMBOL "EXERCISE_SLAVE" TO EXERCISE OF THE SLAVE RESPONSES TO BUSY
// DEFINE THE SYMBOL "PASS_0in" TO GET CODE THAT PASSES 0-in TESTS
#define PASS_0in

//==============================================================================
// cynw_ahb_master_if
//==============================================================================
class cynw_ahb_master_if : virtual public sc_interface
{
  	typedef cynw_ahb_master_if this_type;
  public:
  	cynw_ahb_master_if() {}
	virtual ~cynw_ahb_master_if() {}
  public:
  	virtual bool read( const sc_uint<32>& addr, sc_uint<8>& data ) 
	{ return false; }
  	virtual bool read( const sc_uint<32>& addr, sc_uint<16>& data )
	{ return false; }
  	virtual bool read( const sc_uint<32>& addr, sc_uint<32>& data )=0;

  	virtual bool read( const sc_uint<32>&, unsigned int, sc_uint<8>* )
	{ return false; }
  	virtual bool read( const sc_uint<32>&, unsigned int, sc_uint<16>* )
	{ return false; }
  	virtual bool read( const sc_uint<32>&, unsigned int, sc_uint<32>* )=0;

  	virtual 
	bool read_wrap( const sc_uint<32>&, unsigned int, sc_uint<8>*)
	{ return false; }
  	virtual 
	bool read_wrap(const sc_uint<32>&, unsigned int, sc_uint<16>*)
	{ return false; }
  	virtual 
	bool read_wrap(const sc_uint<32>&, unsigned int, sc_uint<32>*)=0;

	virtual void reset()= 0;

  	virtual bool write( const sc_uint<32>& addr, const sc_uint<8>& data )
	{ return false; }
  	virtual bool write( const sc_uint<32>& addr, const sc_uint<16>& data )
	{ return false; }
  	virtual bool write( const sc_uint<32>& addr, const sc_uint<32>& data )=0;

  	virtual 
	bool write( const sc_uint<32>&, unsigned int, const sc_uint<8>*)
	{ return false; }
  	virtual 
	bool write(const sc_uint<32>&, unsigned int, const sc_uint<16>*)
	{ return false; }
  	virtual 
	bool write(const sc_uint<32>&, unsigned int, const sc_uint<32>*)=0;

  	virtual 
	bool write_wrap( const sc_uint<32>&, unsigned int, const sc_uint<8>* )
	{ return false; }
  	virtual 
	bool write_wrap(const sc_uint<32>&, unsigned int, const sc_uint<16>* )
	{ return false; }
  	virtual 
	bool write_wrap(const sc_uint<32>&, unsigned int, const sc_uint<32>*)=0;

  private:
  	cynw_ahb_master_if( const this_type& );
  	const this_type& operator = ( const this_type& );
};

//==============================================================================
// cynw_ahb_master_port
//==============================================================================
template<typename LEVEL=CYN::PIN> class cynw_ahb_master_port;

typedef cyn_enum<101> TLM_PASS_THRU;

//==============================================================================
// cynw_ahb_master_port<TLM_PASS_THRU>
//==============================================================================
template<>
class cynw_ahb_master_port<TLM_PASS_THRU> : 
	public sc_port<cynw_ahb_master_if,1>
{
  	typedef cynw_ahb_master_port<TLM_PASS_THRU> this_type;
  public:
  	cynw_ahb_master_port(const char* name_p) : 
		sc_port<cynw_ahb_master_if,1>(name_p)
		{}
  	cynw_ahb_master_port() : sc_port<cynw_ahb_master_if,1>()
		{}
	virtual ~cynw_ahb_master_port() 
		{}
    inline void set_busy( int, int )
	{
	}
    
  public:
	inline void annotate( int lineno ) {}

  public:
  	inline bool read( const sc_uint<32>& addr, sc_uint<8>& data )
		{ return (*this)->read( addr, data ); }
  	inline bool read( const sc_uint<32>& addr, sc_uint<16>& data )
		{ return (*this)->read( addr, data ); }
  	inline bool read( const sc_uint<32>& addr, sc_uint<32>& data )
		{ return (*this)->read( addr, data ); }
  	inline bool read( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<8>* data_p )
		{ return (*this)->read( addr, data_n, data_p ); }
  	inline bool read( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<16>* data_p )
		{ return (*this)->read( addr, data_n, data_p ); }
  	inline bool read( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<32>* data_p )
		{ return (*this)->read( addr, data_n, data_p ); }
  	virtual 
	bool read_wrap( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<8>* data_p)
		{ return (*this)->read_wrap( addr, data_n, data_p ); }
  	virtual 
	bool read_wrap(
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<16>* data_p)
		{ return (*this)->read_wrap( addr, data_n, data_p ); }
  	virtual 
	bool read_wrap(
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<32>* data_p)
		{ return (*this)->read_wrap( addr, data_n, data_p ); }
	inline void reset()
		{ (*this)->reset(); }
  	inline bool write( const sc_uint<32>& addr, const sc_uint<8>& data )
		{ return (*this)->write( addr, data ); }
  	inline bool write( const sc_uint<32>& addr, const sc_uint<16>& data )
		{ return (*this)->write( addr, data ); }
  	inline bool write( const sc_uint<32>& addr, const sc_uint<32>& data )
		{ return (*this)->write( addr, data ); }
  	inline bool write( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<8>* data_p )
		{ return (*this)->write( addr, data_n, data_p ); }
  	inline bool write( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<16>* data_p)
		{ return (*this)->write( addr, data_n, data_p ); }
  	inline bool write( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p)
		{ return (*this)->write( addr, data_n, data_p ); }
  	inline bool write_wrap(
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<8>* data_p )
		{ return (*this)->write_wrap( addr, data_n, data_p ); }
  	inline bool write_wrap(
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<16>* data_p)
		{ return (*this)->write_wrap( addr, data_n, data_p ); }
  	inline bool write_wrap(
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p)
		{ return (*this)->write_wrap( addr, data_n, data_p ); }

  private:
  	cynw_ahb_master_port( const this_type& );
  	const this_type& operator = ( this_type& );
};


class osci_tlm_ahb_request
{
  public:
  	enum opcode
	{
		op_read       = 0x00,                     // xxxxx0
		op_write      = 0x01,                     // xxxxx1
		op_rw_mask    = 0x01,                     // xxxxx1
		op_size_8     = amba::hsize_8 << 1,       // xx000x
		op_size_16    = amba::hsize_16 << 1,      // xx001x
		op_size_32    = amba::hsize_32 << 1,      // xx010x
		op_size_mask  = 0x0e,                     // xx111x
        op_burst_1    = amba::hburst_single << 4, // 000xxxx
        op_burst_4    = amba::hburst_incr4 << 4,  // 011xxxx
        op_burst_8    = amba::hburst_incr8 << 4,  // 101xxxx
        op_burst_16   = amba::hburst_incr16 << 4, // 111xxxx
		op_burst_mask = 0x70                      // 111xxxx
	};

  public:
	inline void decode_opcode( 
		bool& write, amba::hsize_type& size, amba::hburst_type& burst ) const
	{
		write = m_opcode & op_rw_mask;
		size = (m_opcode & op_size_mask) >> 1;
		burst = (m_opcode & op_burst_mask) >> 4;
	}

	inline void set_opcode( bool write, const amba::hsize_type& size, 
		const amba::hburst_type& burst ) 
	{
		m_opcode = (write ? op_write : op_read);
		m_opcode |= (size << 1);
        m_opcode |= ( burst << 4 );
	}

  public:
  	sc_uint<7>  m_opcode;             // Opcode for operation.
	sc_uint<32> m_address;            // Address to transfer from/to.
	union {                           // Data to be written:
		unsigned char  bytes[16];     // ... as 8-bit data.
		unsigned short halfwords[16]; // ... as 16-bit data.
		unsigned int   words[16];     // ... as 32-bit data.
	}           m_data;
};

class osci_tlm_ahb_response
{
  public:
  	bool m_error;                     // True if error detected.
	union {                           // Data returned:
		unsigned char  bytes[16];     // ... as 8-bit data.
		unsigned short halfwords[16]; // ... as 16-bit data.
		unsigned int   words[16];     // ... as 32-bit data.
	}    m_data;
};

typedef tlm::tlm_transport_if<osci_tlm_ahb_request,osci_tlm_ahb_response> 
	osci_tlm_ahb_transport_if;
typedef sc_port<osci_tlm_ahb_transport_if,1> osci_tlm_ahb_port;
typedef cyn_enum<102> TLM_OSCI;

//==============================================================================
// cynw_ahb_master_port<TLM_OSCI>
//==============================================================================
template<>
class cynw_ahb_master_port<TLM_OSCI> :
    public osci_tlm_ahb_port 
{
  	typedef cynw_ahb_master_port<TLM_OSCI> this_type;
  public:
  	cynw_ahb_master_port(const char* name_p) : osci_tlm_ahb_port(name_p)
		{}
  	cynw_ahb_master_port() : osci_tlm_ahb_port("ahb_bus_port")
		{}
	virtual ~cynw_ahb_master_port() 
		{}

  public:
	inline void annotate( int lineno ) {}

  public:
	inline bool read( 
		const sc_uint<32>& addr, sc_uint<8>& data )
	{
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.

		request.set_opcode(false, amba::hsize_8, amba::hburst_single);
		request.m_address = addr;
		response = (*this)->transport(request);
		data = response.m_data.bytes[0];
		return response.m_error;
	}

	inline bool read( 
		const sc_uint<32>& addr, sc_uint<16>& data )
	{
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.

		request.set_opcode(false, amba::hsize_16, amba::hburst_single);
		request.m_address = addr;
		response = (*this)->transport(request);
		data = response.m_data.halfwords[0];
		return response.m_error;
	}

	inline bool read( 
		const sc_uint<32>& addr, sc_uint<32>& data )
	{
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		request.set_opcode(false, amba::hsize_32, amba::hburst_single);
		request.m_address = addr;
		response = (*this)->transport(request);
		data = response.m_data.words[0];
		return response.m_error;
	}

	inline bool read( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<8>* data_p )
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch ( data_n )
		{
		  case 1:  burst = amba::hburst_single; break;
		  case 4:  burst = amba::hburst_incr4;  break;
		  case 8:  burst = amba::hburst_incr8;  break;
		  case 16: burst = amba::hburst_incr16; break;
		  default:
			cerr << __FILE__ << "(" << __LINE__ << ") unsupported size " 
				 << data_n << endl;
			return true;
		}

		request.set_opcode(false, amba::hsize_8, burst);
		request.m_address = addr;
		response = (*this)->transport(request);
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			data_p[data_i] = response.m_data.bytes[data_i];
		}
		return response.m_error;
	}

	inline bool read( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<16>* data_p )
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch ( data_n )
		{
		  case 1:  burst = amba::hburst_single; break;
		  case 4:  burst = amba::hburst_incr4;  break;
		  case 8:  burst = amba::hburst_incr8;  break;
		  case 16: burst = amba::hburst_incr16; break;
		  default:
			cerr << __FILE__ << "(" << __LINE__ << ") unsupported size " << data_n
				 << endl;
			return true;
		}

		request.set_opcode(false, amba::hsize_16, burst);
		request.m_address = addr;
		response = (*this)->transport(request);
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			data_p[data_i] = response.m_data.halfwords[data_i];
		}
		return response.m_error;
	}

	inline bool read( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<32>* data_p )
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch ( data_n )
		{
		  case 1:  burst = amba::hburst_single; break;
		  case 4:  burst = amba::hburst_incr4;  break;
		  case 8:  burst = amba::hburst_incr8;  break;
		  case 16: burst = amba::hburst_incr16; break;
		  default:
			cerr << __FILE__ << "(" << __LINE__ << ") unsupported size " << data_n
				 << endl;
			return true;
		}

		request.set_opcode(false, amba::hsize_32, burst);
		request.m_address = addr;
		response = (*this)->transport(request);
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			data_p[data_i] = response.m_data.words[data_i];
		}
		return response.m_error;
	}

	inline bool read_wrap( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<8>* data_p )
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch( data_n )
		{
	      case 4:  burst = amba::hburst_wrap4;  break;
	      case 8:  burst = amba::hburst_wrap8;  break;
	      case 16: burst = amba::hburst_wrap16; break;
		  default:
            cerr << "Illegal read wrap count " << data_n
				 << " value must be 4, 8, or 16" << endl;
			return true;
		}
		request.set_opcode(false, amba::hsize_8, burst);
		request.m_address = addr;
		response = (*this)->transport(request);
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			data_p[data_i] = response.m_data.bytes[data_i];
		}
		return response.m_error;
	}

	inline bool read_wrap( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<16>* data_p )
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch( data_n )
		{
	      case 4:  burst = amba::hburst_wrap4;  break;
	      case 8:  burst = amba::hburst_wrap8;  break;
	      case 16: burst = amba::hburst_wrap16; break;
		  default:
            cerr << "Illegal read wrap count " << data_n
				 << " value must be 4, 8, or 16" << endl;
			return true;
		}
		request.set_opcode(false, amba::hsize_16, burst);
		request.m_address = addr;
		response = (*this)->transport(request);
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			data_p[data_i] = response.m_data.halfwords[data_i];
		}
		return response.m_error;
	}

	inline bool read_wrap( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<32>* data_p )
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch( data_n )
		{
	      case 4:  burst = amba::hburst_wrap4;  break;
	      case 8:  burst = amba::hburst_wrap8;  break;
	      case 16: burst = amba::hburst_wrap16; break;
		  default:
            cerr << "Illegal read wrap count " << data_n
				 << " value must be 4, 8, or 16" << endl;
			return true;
		}
		request.set_opcode(false, amba::hsize_32, burst);
		request.m_address = addr;
		response = (*this)->transport(request);
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			data_p[data_i] = response.m_data.words[data_i];
		}
		return response.m_error;
	}

	inline void reset()
	{
	}
	
    inline void set_busy( int, int )
	{
	}

	inline bool write( 
		const sc_uint<32>& addr, const sc_uint<8>& data )
	{
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		request.set_opcode(true, amba::hsize_8, amba::hburst_single);
		request.m_address = addr;
		request.m_data.bytes[0] = data;
		response = (*this)->transport(request);
		return response.m_error;
	}

	inline bool write( 
		const sc_uint<32>& addr, const sc_uint<16>& data )
	{
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.

		request.set_opcode(true, amba::hsize_16, amba::hburst_single);
		request.m_address = addr;
		request.m_data.halfwords[0] = data;
		response = (*this)->transport(request);
		return response.m_error;
	}

	inline bool write( 
		const sc_uint<32>& addr, const sc_uint<32>& data )
	{
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		request.set_opcode(true, amba::hsize_32, amba::hburst_single);
		request.m_address = addr;
		request.m_data.words[0] = data;
		response = (*this)->transport(request);
		return response.m_error;
	}

	inline bool write( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<8>* data_p )
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch ( data_n )
		{
		  case 1:  burst = amba::hburst_single; break;
		  case 4:  burst = amba::hburst_incr4;  break;
		  case 8:  burst = amba::hburst_incr8;  break;
		  case 16: burst = amba::hburst_incr16; break;
		  default:
			cerr << __FILE__ << "(" << __LINE__ << ") unsupported size " << data_n
				 << endl;
			return true;
		}

		request.set_opcode(true, amba::hsize_8, burst);
		request.m_address = addr;
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			request.m_data.bytes[data_i] = data_p[data_i];
		}
		response = (*this)->transport(request);
		return response.m_error;
	}

	inline bool write( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<16>* data_p )
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch ( data_n )
		{
		  case 1:  burst = amba::hburst_single; break;
		  case 4:  burst = amba::hburst_incr4;  break;
		  case 8:  burst = amba::hburst_incr8;  break;
		  case 16: burst = amba::hburst_incr16; break;
		  default:
			cerr << __FILE__ << "(" << __LINE__ << ") unsupported size " << data_n
				 << endl;
			return true;
		}

		request.set_opcode(true, amba::hsize_16, burst);
		request.m_address = addr;
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			request.m_data.halfwords[data_i] = data_p[data_i];
		}
		response = (*this)->transport(request);
		return response.m_error;
	}

	inline bool write( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p )
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch ( data_n )
		{
		  case 1:  burst = amba::hburst_single; break;
		  case 4:  burst = amba::hburst_incr4;  break;
		  case 8:  burst = amba::hburst_incr8;  break;
		  case 16: burst = amba::hburst_incr16; break;
		  default:
			cerr << __FILE__ << "(" << __LINE__ << ") unsupported size " << data_n
				 << endl;
			return true;
		}

		request.set_opcode(true, amba::hsize_32, burst);
		request.m_address = addr;
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			request.m_data.words[data_i] = data_p[data_i];
		}
		response = (*this)->transport(request);
		return response.m_error;
	}

	inline bool write_wrap( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<8>* data_p )
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch ( data_n )
		{
		  case 4:  burst = amba::hburst_wrap4;  break;
		  case 8:  burst = amba::hburst_wrap8;  break;
		  case 16: burst = amba::hburst_wrap16; break;
		  default:
		    cerr << "Illegal wrap count " << data_n 
				 << " must be 4, 8, or 16" <<endl;
			return true;
		}
		request.set_opcode(true, amba::hsize_8, burst);
		request.m_address = addr;
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			request.m_data.bytes[data_i] = data_p[data_i];
		}
		response = (*this)->transport(request);
		return response.m_error;
	}

	inline bool write_wrap( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<16>* data_p)
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch ( data_n )
		{
		  case 4:  burst = amba::hburst_wrap4;  break;
		  case 8:  burst = amba::hburst_wrap8;  break;
		  case 16: burst = amba::hburst_wrap16; break;
		  default:
		    cerr << "Illegal wrap count " << data_n 
				 << " must be 4, 8, or 16" <<endl;
			return true;
		}
		request.set_opcode(true, amba::hsize_16, burst);
		request.m_address = addr;
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			request.m_data.halfwords[data_i] = data_p[data_i];
		}
		response = (*this)->transport(request);
		return response.m_error;
	}

	inline bool write_wrap( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p)
	{
		amba::hburst_type     burst;     // Type of burst to perform.
		osci_tlm_ahb_request  request;   // Request of slave device.
		osci_tlm_ahb_response response;  // Response from slave device.
		
		switch ( data_n )
		{
		  case 4:  burst = amba::hburst_wrap4;  break;
		  case 8:  burst = amba::hburst_wrap8;  break;
		  case 16: burst = amba::hburst_wrap16; break;
		  default:
		    cerr << "Illegal wrap count " << data_n 
				 << " must be 4, 8, or 16" <<endl;
			return true;
		}
		request.set_opcode(true, amba::hsize_32, burst);
		request.m_address = addr;
		for ( unsigned int data_i = 0; data_i < data_n; data_i++ )
		{
			request.m_data.words[data_i] = data_p[data_i];
		}
		response = (*this)->transport(request);
		return response.m_error;
	}


  private:
  	cynw_ahb_master_port( const this_type& );
  	const cynw_ahb_master_port<TLM_OSCI>& operator = ( this_type& );
};

//==============================================================================
// cynw_ahb_master_port<CYN::PIN>
//==============================================================================
template<>
class cynw_ahb_master_port<CYN::PIN> : public amba::ahb_master_ports
{
  	typedef cynw_ahb_master_port<CYN::PIN> this_type;
  public:
  	inline cynw_ahb_master_port( const char* name ) : 
		amba::ahb_master_ports( (std::string(name)+"_master_ports").c_str() ) 
#       if defined(CYNW_DEBUG_AHB_MASTER)
		, m_debug("master_debug_port")
#       endif
	{}
  	inline cynw_ahb_master_port() : amba::ahb_master_ports("master_ports") {}
	virtual ~cynw_ahb_master_port() {}
    cynw_ahb_master_port<CYN::PIN>* operator -> () { return this; }

#	if defined(EXERCISE_SLAVE) && !defined(CYNTHHL)
#		define TEST_SLAVE_WAIT(CYCLE_I) busy_wait(CYCLE_I)
		inline void busy_wait( int cycle_i )
		{
			bool ready;
            if ( m_busy_duration > 0 && m_busy_start_i == cycle_i )
            {
                m_HTRANS = amba::htrans_busy;
                for ( int wait_i = 0; wait_i < m_busy_duration; wait_i++ )
                {
                    do {
                        wait();
                        ready = m_HREADY.read();
                    }    while ( !ready );
                }
                m_HTRANS = amba::htrans_idle;
            }
		}

		inline void set_busy( int start_i, int duration )
		{
			m_busy_start_i = start_i;
			m_busy_duration = duration;
		}

		int m_busy_duration;  // Duration of the busy.
		int m_busy_start_i;   // Cycle within operation to start busy.
#	else
#		define TEST_SLAVE_WAIT(CYCLE_I)
#	endif

  public: // debug methods:
#   if !defined(CYNTHHL)
        inline void debug( const char* name, int lineno )
        {
	        if ( !DEBUG_CYNW_AHB_MASTER ) return;
	        cout << sc_time_stamp() << ": " << name 
			     << "(" << lineno << ")" << endl
	             << "    address      = " << m_HADDR.read() << endl
	             << "    burst type   = " << hburst_text(m_HBURST.read()) 
			     << endl
	             << "    data size    = " << hsize_number(m_HSIZE.read()) 
			     << endl
	             << "    slave ready  = " << m_HREADY.read() << endl
	             << "    slave resp   = " << m_HRESP.read() << endl
	             << "    read data    = " << m_HRDATA.read() << endl
	             << "    trans type   = " << htrans_text(m_HTRANS.read()) 
			     << endl
	             << "    write enable = " << m_HWRITE.read() << endl
	             << "    write data   = " << m_HWDATA.read() << endl;
	    }
        inline const char* hburst_text( int burst );
	    inline int hsize_number( int size ); 
	    inline const char* htrans_text( int trans );
#	else
        inline void debug( const char* filename, int lineno ) {}
#	endif // !defined(CYNTHHL)
    
  public:
  	inline bool read( const sc_uint<32>& addr, sc_uint<8>& data );
  	inline bool read( const sc_uint<32>& addr, sc_uint<16>& data );
  	inline bool read( const sc_uint<32>& addr, sc_uint<32>& data );
  	inline bool read( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<8>* data_p );
  	inline bool read( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<16>* data_p );
  	inline bool read( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<32>* data_p );

	inline bool read_common( const sc_uint<32>& addr, amba::HSIZE_values hsize,
	    sc_uint<32>& data );

	template<typename D>
  	inline bool read_incr_common( 
		const sc_uint<32>& addr, unsigned int data_n, int incr, D* data_p );

	template<typename D>
  	inline bool read_wrap_common( 
		const sc_uint<32>& addr, unsigned int data_n, int lob, D* data_p );

  	inline bool read_wrap( 
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<8>* data_p
	);
  	inline bool read_wrap(
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<16>* data_p
	);
  	inline bool read_wrap(
		const sc_uint<32>& addr, unsigned int data_n, sc_uint<32>* data_p
	);

	inline void reset()
    {   
        CYN_PROTOCOL("ahb_master_reset");
#       if defined(CYNW_DEBUG_AHB_MASTER)
		    m_debug = __LINE__;
#       endif
        m_HADDR = 0;
        m_HBURST = amba::hburst_single;
        m_HBUSREQ = false;
        m_HLOCK = false;
        m_HPROT = amba::hprot_opcode;
        m_HSIZE = amba::hsize_32;
        m_HTRANS = amba::htrans_idle;
		m_HWDATA = 0;
        m_HWRITE = false;
    }

  	inline bool write( const sc_uint<32>& addr, const sc_uint<8>& data );
  	inline bool write( const sc_uint<32>& addr, const sc_uint<16>& data );
  	inline bool write( const sc_uint<32>& addr, const sc_uint<32>& data );
  	inline bool write( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<8>* data_p
	);
  	inline bool write( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<16>* data_p
	);
  	inline bool write( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p
	);

	inline bool write_common( const sc_uint<32>& addr, amba::HSIZE_values hsize,
	    const sc_uint<32>& data );

	template<typename D>
  	inline bool write_incr_common( 
		const sc_uint<32>& addr, unsigned int data_n, int incr, const D* data_p
	);
	template<typename D>
  	inline bool write_wrap_common( 
		const sc_uint<32>& addr, unsigned int data_n, int lob, const D* data_p
	);

  	inline bool write_wrap( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<8>* data_p
	);
  	inline bool write_wrap( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<16>* data_p
	);
  	inline bool write_wrap( 
		const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p
	);

  public:
	CYN_METAPORT;
#   if defined(CYNW_DEBUG_AHB_MASTER)
		inline void annotate( int lineno ) { m_debug = lineno; }
		sc_out<sc_uint<32> > m_debug;
#    else
		inline void annotate( int lineno ) {}
#    endif

  private:
  	cynw_ahb_master_port( const this_type& );
  	const this_type& operator = ( const this_type& );
};

#if !defined(CYNTHHL)
//------------------------------------------------------------------------------
const char* cynw_ahb_master_port<CYN::PIN>::hburst_text( int burst )
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

	if ( (burst >= amba::hburst_single) && (burst <= amba::hburst_incr16) )
		return text[burst];
	else
		return unknown;
}


//------------------------------------------------------------------------------
int cynw_ahb_master_port<CYN::PIN>::hsize_number( int size )
{
	static int numbers[] =
	{
        8, 16, 32, 64, 128, 256, 512, 1024
	};
	if ( (size >= amba::hsize_8) && (size <= amba::hsize_1024) )
		return numbers[size];
	else
		return 0;
}


//------------------------------------------------------------------------------
const char* cynw_ahb_master_port<CYN::PIN>::htrans_text( int trans )
{
	static const char* text[] =
	{
        "htrans_idle",
        "htrans_busy",
        "htrans_nonsequential",
        "htrans_sequential"
	};
	static char unknown[] = "*** unknown ***";
	if ( (trans >= amba::htrans_idle) && (trans <= amba::htrans_sequential) )
		return text[trans];
	else
		return unknown;
}
#endif // !defined(CYNTHHL)

//------------------------------------------------------------------------------
//"cynw_ahb_master_port<CYN::PIN>::read_common - single value" 
//
// This method provides the bus manipulations necessary to read a single
// value from a slave through the AHB bus. If the transfer is less than
// 32 bits the data will have been placed in the correct lane by the slave.
//    addr  = address on AHB bus to write to.
//    hsize = HSIZE register value indicating size of the transfer.
//    data  = 32-bit value representing the data.
// Return code is false if an error is detected.
//------------------------------------------------------------------------------
inline bool cynw_ahb_master_port<CYN::PIN>::read_common( 
	const sc_uint<32>& addr, amba::HSIZE_values hsize, sc_uint<32>& data )
{
    bool       grant;  // Value of HGRANT.
    bool       ready;  // Value of HREADY.
	sc_uint<2> resp;   // Value of HRESP.

	// BUS ACQUISTION PHASE:

retry:
    {
        CYN_PROTOCOL("read_single_common_bus_request");

		debug(__FILE__,__LINE__);
        m_HBUSREQ = true;
		m_HLOCK = false;
		m_HTRANS = amba::htrans_idle;
        do {
            annotate(__LINE__);
			wait();
            grant = m_HGRANT.read();
        } while ( !grant );
        m_HBUSREQ = false;

		// ADDRESS PHASE:
		//
		// Set up the request and wait one clock to check the device's
		// initial response. If its not ready spin until it goes ready,
		// or presents an exception.

		debug(__FILE__,__LINE__);
        m_HADDR = addr;
        m_HBURST = amba::hburst_single;
        m_HSIZE = hsize;
        m_HTRANS = amba::htrans_nonsequential;
		m_HWRITE = false;
        annotate(__LINE__);
		wait();
        ready = m_HREADY.read();
#if !defined(PASS_0in)
		if ( !ready )
		{
            do
            {
                annotate(__LINE__);
				wait();
                ready = m_HREADY.read();
                resp = m_HRESP.read();
            } while ( !ready && (resp == amba::hresp_okay) );
        }
		else
		{
			resp = amba::hresp_okay; // ignore first HRESP value.
		}

		// DATA PHASE:
		//
		// Wait for the slave to present data.

		do
		{
			switch ( resp )
			{
			  case amba::hresp_okay:
				break;
			  case amba::hresp_retry:
			  case amba::hresp_split:
				{
					CYN_PROTOCOL("cynth_kludge");
				}
				goto retry;
			  default:
				{
					CYN_PROTOCOL("read_single_common_error");
					m_HTRANS = amba::htrans_idle;
					annotate(__LINE__);
					wait();
				}
			    return true;
			}

			debug(__FILE__,__LINE__);
			TEST_SLAVE_WAIT(0);
			m_HTRANS = amba::htrans_idle;
			do {
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready && (resp == amba::hresp_okay) );
			data = m_HRDATA.read();
		} while ( resp != amba::hresp_okay );
#else
	    // SLAVE NOT READY 
		if ( !ready )
		{   
			annotate(__LINE__);
			wait();
			ready = m_HREADY.read();
			resp = m_HRESP.read();
		}
		do
		{
			if ( !ready )
			{   
				switch ( resp )
				{   
				  case amba::hresp_okay:
					break;
				  case amba::hresp_retry:
				  case amba::hresp_split:
					{
						CYN_PROTOCOL("cynth_kludge"); // eliminates ERROR 11.
					}
					goto retry;
				  default:
					{   
						CYN_PROTOCOL("write_wrap_common_error");
						m_HTRANS = amba::htrans_idle;
						annotate(__LINE__);
						wait();
					}   
					return false;
				}   
			} 
            else
			{
				m_HTRANS = amba::htrans_idle;
			}
			annotate(__LINE__);
			wait();
			ready = m_HREADY.read();
			resp = m_HRESP.read();
		} while ( !ready );
		data = m_HRDATA.read();
		m_HTRANS = amba::htrans_idle; // ####
#endif
	}
	return true;
}

//------------------------------------------------------------------------------
//"cynw_ahb_master_port<CYN::PIN>::read - single value" 
//
// These methods will read single values from slaves through the AHB bus.
// Each of them will call read_common() with the appropriate information
// to actually perform the transfer. For transfers of less than 32 bits
// the data will be extracted from the proper lane.
//    addr = 32-bit address on the AHB bus to read.
//    data = where to place data value read value.
// Return code is false if an error is detected.
//------------------------------------------------------------------------------
inline bool cynw_ahb_master_port<CYN::PIN>::read( 
	const sc_uint<32>& addr, sc_uint<8>& data )
{
	bool        rc;
	sc_uint<32> temp_data;
	rc = read_common(addr, amba::hsize_8, temp_data);
	switch ( (int)addr(1,0) )
	{
#   if defined(BETA_AHB_BIG_ENDIAN)
	  case  3: data = temp_data(7,0);   break;
	  case  2: data = temp_data(15,8);  break;
	  case  1: data = temp_data(23,16); break;
	  default: data = temp_data(31,24); break;
#	else
	  case  0: data = temp_data(7,0);   break;
	  case  1: data = temp_data(15,8);  break;
	  case  2: data = temp_data(23,16); break;
	  default: data = temp_data(31,24); break;
#	endif
	}
	return rc;
}

inline bool cynw_ahb_master_port<CYN::PIN>::read( 
	const sc_uint<32>& addr, sc_uint<16>& data )
{
	bool        rc;
	sc_uint<32> temp_data;
	rc = read_common(addr, amba::hsize_16, temp_data);
	switch ( (int)addr(1,0) )
	{
#   if defined(BETA_AHB_BIG_ENDIAN)
	  case  1: data = temp_data(15,0);  break;
	  default: data = temp_data(31,16); break;
#	else
	  case  0: data = temp_data(15,0);  break;
	  default: data = temp_data(31,16); break;
#	endif
	}
	return rc;
}

inline bool cynw_ahb_master_port<CYN::PIN>::read( 
	const sc_uint<32>& addr, sc_uint<32>& data )
{
	return read_common(addr, amba::hsize_32, data);
}

//------------------------------------------------------------------------------
//"cynw_ahb_master_port<CYN::PIN>::read_incr_common"
//
// Return code is false if an error occurred.
//------------------------------------------------------------------------------
template<typename D>
inline bool cynw_ahb_master_port<CYN::PIN>::read_incr_common( 
	const sc_uint<32>& addr, unsigned int data_n, int incr, D* data_p )
{
	sc_uint<32>  address; // Address incrementer.
	sc_uint<3>   burst;   // Value for HBURST.
    sc_uint<5>   data_i;  // Index into data_p.
    bool         grant;   // Value of HGRANT.
	sc_uint<4>   hsize;   // Size of data words.
    bool         ready;   // Value of HREADY.
	sc_uint<2>   resp;    // Value of HRESP.

	// SET UP:

	address = addr;
	data_i = 0;

	// BUS ACQUISTION PHASE:

retry:
    {
        CYN_PROTOCOL("read_incr_common");

        m_HBUSREQ = true;
		m_HLOCK = false;
		m_HTRANS = amba::htrans_idle; // in case this is a retry.
        do {
            annotate(__LINE__);
			wait();
            grant = m_HGRANT.read();
        } while ( !grant );
        m_HBUSREQ = false;

		// ADDRESS PHASE:

        switch ( data_n ) 
        {       
          case 4:  burst = amba::hburst_incr4;  break;
          case 8:  burst = amba::hburst_incr8;  break;
          case 16: burst = amba::hburst_incr16; break;
		  default: burst = amba::hburst_incr;   break;
        }         
        m_HADDR = address;
		address = address + incr;
        m_HBURST = burst;
        switch ( incr )
        {
          case 1:  hsize = amba::hsize_8;  break;
          case 2:  hsize = amba::hsize_16; break;
          default: hsize = amba::hsize_32; break;
        }
        m_HSIZE = hsize;
        m_HTRANS = amba::htrans_nonsequential;
		m_HWRITE = false;

		annotate(__LINE__);
		wait();
		ready = m_HREADY.read();
#if !defined(PASS_0in)
		if ( !ready )
		{
			do
			{
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready && (resp == amba::hresp_okay) );
		}
		else
		{
			resp = amba::hresp_okay; // ignore first HRESP value.
		}

		// DATA PHASE:
		//
		// Wait for the slave to present us with data.
		// Update the control information.

		for ( ; data_i < data_n; )
		{
			// PROCESS SLAVE RESPONSE FROM PREVIOUS CYCLE:

			switch ( resp )
			{
			  case amba::hresp_okay:
				break;
			  case amba::hresp_retry:
			  case amba::hresp_split:
				{
					CYN_PROTOCOL("cynth_kludge");
				}
                goto retry;
              default:
				{
					CYN_PROTOCOL("read_incr_common_error");
					m_HTRANS = amba::htrans_idle;
					annotate(__LINE__);
					wait();
				}
				return true;
			}

			// READ THE WORD:

			m_HADDR = address;
			address = address + incr;
			TEST_SLAVE_WAIT(data_i);
			m_HTRANS = ( data_i == data_n-1 ) ?
				amba::htrans_idle : amba::htrans_sequential;
			do {
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready && (resp == amba::hresp_okay) );
			if ( resp == amba::hresp_okay )
			{
				data_p[data_i] = m_HRDATA.read();	
				data_i = data_i + 1;
			}
		}
#else
	    // SLAVE NOT READY WHEN WE GOT BUS - HOLD INITIAL DATA FOR A CLOCK
		
		if ( !ready )
		{   
			annotate(__LINE__);
			wait();
			ready = m_HREADY.read();
			resp = m_HRESP.read();
		}
		for ( ; data_i < data_n; )
		{
			// SLAVE INDICATES NOT READY CHECK FOR A TERMINATION SEQUENCE:

			if ( !ready )
			{   
				switch ( resp )
				{   
				  case amba::hresp_okay: // slave busy
					break;
				  case amba::hresp_retry:
				  case amba::hresp_split:
					{
						CYN_PROTOCOL("cynth_kludge"); // eliminates ERROR 11.
					}
					goto retry;
				  default:
					{   
						CYN_PROTOCOL("write_single_common_error");
						m_HTRANS = amba::htrans_idle;
						annotate(__LINE__);
						wait();
					}   
					return false;
				}   
			} 

			// SLAVE INDICATES READY:
			//
			// Set the control information for the next cycle.

            else
			{
				m_HTRANS = (data_i == (data_n-1)) ?
				    amba::htrans_idle : amba::htrans_sequential;
				m_HADDR = address;
				address = address + incr;
			}

			// READ THE NEXT VALUE:

			annotate(__LINE__);
			wait();
			ready = m_HREADY.read();
			resp = m_HRESP.read();
			if ( ready )
			{
				data_p[data_i] = m_HRDATA.read();
				data_i = data_i + 1;
			}
		}
#endif // 0
	} 
	return true;
}

//------------------------------------------------------------------------------
inline bool cynw_ahb_master_port<CYN::PIN>::read( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<8>* data_p )
{
	return read_incr_common(addr, data_n, 1, data_p);
}

inline bool cynw_ahb_master_port<CYN::PIN>::read( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<16>* data_p )
{
	return read_incr_common(addr, data_n, 2, data_p);
}

inline bool cynw_ahb_master_port<CYN::PIN>::read( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<32>* data_p )
{
	return read_incr_common(addr, data_n, 4, data_p);
}

//------------------------------------------------------------------------------
//"cynw_ahb_master_port<CYN::PIN>::read_wrap_common"
//------------------------------------------------------------------------------
template<typename D>
inline bool cynw_ahb_master_port<CYN::PIN>::read_wrap_common( 
	const sc_uint<32>& addr, unsigned int data_n, int lob, D* data_p )
{
	sc_uint<32>  address; // Address incrementer.
	sc_uint<3>   burst;   // Value for HBURST.
    sc_uint<5>   data_i;  // Index into data_p.
    bool         grant;   // Value of HGRANT.
	int          hob;     // Index of high order bit of address wrap.
	sc_uint<4>   hsize;   // Size of data words.
    bool         ready;   // Value of HREADY.
	sc_uint<2>   resp;    // Value of HRESP.

	// SET UP:

	address = addr;
	data_i = 0;

	// BUS ACQUISTION PHASE:

retry:
    {
        CYN_PROTOCOL("read_wrap_common");

        m_HBUSREQ = true;
		m_HLOCK = false;
		m_HTRANS = amba::htrans_idle; // in case this is a retry.
        do {
            annotate(__LINE__);
			wait();
            grant = m_HGRANT.read();
        } while ( !grant );
        m_HBUSREQ = false;

		// ADDRESS PHASE:

        switch ( data_n>>2 ) 
        {       
          case 1:  burst = amba::hburst_wrap4;  hob = lob+1; break;
          case 2:  burst = amba::hburst_wrap8;  hob = lob+2; break;
          default: burst = amba::hburst_wrap16; hob = lob+3; break;  
        }         
        m_HADDR = address;
		address(hob,lob) = address(hob,lob) + 1;
        m_HBURST = burst;
        switch ( lob )
        {
          case 0:  hsize = amba::hsize_8;  break;
          case 1:  hsize = amba::hsize_16; break;
          default: hsize = amba::hsize_32; break;
        }
        m_HSIZE = hsize;
        m_HTRANS = amba::htrans_nonsequential;
		m_HWRITE = false;

		annotate(__LINE__);
		wait();
		ready = m_HREADY.read();
#if !defined(PASS_0in)
		if ( !ready )
		{
			do
			{
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready && (resp == amba::hresp_okay) );
		}
		else
		{
			resp = amba::hresp_okay; // ignore first HRESP value.
		}

		// DATA PHASE:
		//
		// Wait for the slave to present us with data.
		// Update the control information.

		for ( ; data_i < ((unsigned int)2 << (hob-lob)); )
		{
			// PROCESS SLAVE RESPONSE FROM PREVIOUS CYCLE:

			switch ( resp )
			{
			  case amba::hresp_okay:
				break;
			  case amba::hresp_retry:
			  case amba::hresp_split:
				{
					CYN_PROTOCOL("cynth_kludge");
				}
                goto retry;
              default:
				{
					CYN_PROTOCOL("read_wrap_common_error");
					m_HTRANS = amba::htrans_idle;
					annotate(__LINE__);
					wait();
				}
				return true;
			}

			// READ THE WORD:

			m_HADDR = address;
			address(hob,lob) = address(hob,lob) + 1;
			TEST_SLAVE_WAIT(data_i);
			m_HTRANS = ( data_i == (((unsigned int)2 << (hob-lob))-1) ) ?
				amba::htrans_idle : amba::htrans_sequential;
			do {
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready && (resp == amba::hresp_okay) );
			if ( resp == amba::hresp_okay )
			{
				extern ostream& tb_log_file(); // ####
				tb_log_file() << sc_time_stamp() << " #### master reading data " << m_HRDATA.read() << endl;
				data_p[data_i] = m_HRDATA.read();	
				data_i = data_i + 1;
			}
		}
#else
	    // SLAVE NOT READY WHEN WE GOT BUS - HOLD INITIAL DATA FOR A CLOCK
		
		if ( !ready )
		{   
			annotate(__LINE__);
			wait();
			ready = m_HREADY.read();
			resp = m_HRESP.read();
		}
		for ( ; data_i < ((unsigned int)2 << (hob-lob)); )
		{
			// SLAVE INDICATES NOT READY CHECK FOR A TERMINATION SEQUENCE:

			if ( !ready )
			{   
				switch ( resp )
				{   
				  case amba::hresp_okay: // slave busy
					break;
				  case amba::hresp_retry:
				  case amba::hresp_split:
					{
						CYN_PROTOCOL("cynth_kludge"); // eliminates ERROR 11.
					}
					goto retry;
				  default:
					{   
						CYN_PROTOCOL("write_single_common_error");
						m_HTRANS = amba::htrans_idle;
						annotate(__LINE__);
						wait();
					}   
					return false;
				}   
			} 

			// SLAVE INDICATES READY:
			//
			// Set the control information for the next cycle.

            else
			{
				m_HTRANS = (data_i == (data_n-1)) ?
				    amba::htrans_idle : amba::htrans_sequential;
				m_HADDR = address;
				address(hob,lob) = address(hob,lob) + 1;
			}

			// READ THE NEXT VALUE:

			annotate(__LINE__);
			wait();
			ready = m_HREADY.read();
			resp = m_HRESP.read();
			if ( ready )
			{
				data_p[data_i] = m_HRDATA.read();
				data_i = data_i + 1;
			}
		}
#endif // 0
	} 
	return true;
}

//------------------------------------------------------------------------------
//"cynw_ahb_master_port<CYN::PIN>::read_wrap"
//------------------------------------------------------------------------------
inline bool cynw_ahb_master_port<CYN::PIN>::read_wrap( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<8>* data_p )
{
	return read_wrap_common( addr, data_n, 0, data_p );
}

inline bool cynw_ahb_master_port<CYN::PIN>::read_wrap( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<16>* data_p )
{
	return read_wrap_common( addr, data_n, 1, data_p );
}

inline bool cynw_ahb_master_port<CYN::PIN>::read_wrap( 
	const sc_uint<32>& addr, unsigned int data_n, sc_uint<32>* data_p )
{
	return read_wrap_common( addr, data_n, 2, data_p );
}

//------------------------------------------------------------------------------
//"cynw_ahb_master_port<CYN::PIN>::write_common - single value"
//
// This method provides the bus manipulations necessary to write a single
// value to a slave through the AHB bus. If the transfer is less than
// 32 bits the data must be placed in the correct lanes.
//    addr  = address on AHB bus to write to.
//    hsize = HSIZE register value indicating size of the transfer.
//    data  = 32-bit value representing the data.
// Return code is false if an error is detected.
//------------------------------------------------------------------------------
inline bool cynw_ahb_master_port<CYN::PIN>::write_common( 
	const sc_uint<32>& addr, amba::HSIZE_values hsize, const sc_uint<32>& data )
{
    bool       grant;  // Value of HGRANT.
    bool       ready;  // Value of HREADY.
	sc_uint<2> resp;   // Value of HRESP.

	// BUS ACQUISTION PHASE:

retry:
    {
        CYN_PROTOCOL("write_single_common");

		debug(__FILE__,__LINE__);
        m_HBUSREQ = true;
		m_HLOCK = false;
        m_HTRANS = amba::htrans_idle;
        do {
            annotate(__LINE__);
			wait();
            grant = m_HGRANT.read();
        } while ( !grant );
        m_HBUSREQ = false;

		// ADDRESS PHASE:
		//
		// Set up the request and wait one clock to check the device's
		// initial response. If its not ready spin until it goes ready,
		// or presents an exception.

		debug(__FILE__,__LINE__);
        m_HADDR = addr;
        m_HBURST = amba::hburst_single;
        m_HSIZE = hsize;
        m_HTRANS = amba::htrans_nonsequential;
		m_HWRITE = true;
        m_HWDATA = data;

		annotate(__LINE__);
		wait();
		ready = m_HREADY.read();
#if !defined(PASS_0in)
		if ( !ready )
		{
			do
			{
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready && (resp == amba::hresp_okay) );
		}
		else
		{
			resp = amba::hresp_okay; // ignore first HRESP value.
		}

		// DATA PHASE:
		//
		// Update the control information for the data cycle.
		// If an error, retry, or skip occurs process them appropriately.
		// The nested CYN_PROTOCOL blocks are necessary because of the
		// return and the goto.

		do
		{
			switch ( resp )
			{
			  case amba::hresp_okay:
				break;
			  case amba::hresp_retry:
			  case amba::hresp_split:
				{
					CYN_PROTOCOL("cynth_kludge");
				}
				goto retry;
			  default:
				{
					CYN_PROTOCOL("write_single_common_error");
					m_HTRANS = amba::htrans_idle;
					annotate(__LINE__);
					wait();
				}
				return true;
			}
			TEST_SLAVE_WAIT(0); 
			m_HTRANS = amba::htrans_idle;
			do {
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready && (resp == amba::hresp_okay) );
		} while ( resp != amba::hresp_okay );

#else
	    // SLAVE NOT READY 
		if ( !ready )
		{   
			annotate(__LINE__);
			wait();
			ready = m_HREADY.read();
			resp = m_HRESP.read();
		}
		do
		{
			if ( !ready )
			{   
				switch ( resp )
				{   
				  case amba::hresp_okay:
					break;
				  case amba::hresp_retry:
				  case amba::hresp_split:
					{
						CYN_PROTOCOL("cynth_kludge"); // eliminates ERROR 11.
					}
					goto retry;
				  default:
					{   
						CYN_PROTOCOL("write_wrap_common_error");
						m_HTRANS = amba::htrans_idle;
						annotate(__LINE__);
						wait();
					}   
					return false;
				}   
			} 
            else
			{
				m_HTRANS = amba::htrans_idle;
			}
			annotate(__LINE__);
			wait();
			ready = m_HREADY.read();
			resp = m_HRESP.read();
		} while ( !ready );
		m_HTRANS = amba::htrans_idle; // ####
#endif // 0
	}
	return true;
}

//------------------------------------------------------------------------------
//"cynw_ahb_master_port<CYN::PIN>::write - single value"
//
// These methods will write single values to slaves through the AHB bus.
// Each of them will call write_common() with the appropriate information
// to actually perform the transfer. For transfers of less than 32 bits
// the data will be replicated into each lane.
//    addr = 32-bit address on the AHB bus to write to.
//    data = value to be written.
// Return code is false if an error is detected.
//------------------------------------------------------------------------------
inline bool cynw_ahb_master_port<CYN::PIN>::write( 
	const sc_uint<32>& addr, const sc_uint<8>& data )
{
	return write_common(addr, amba::hsize_8, (data,data,data,data) );
}

inline bool cynw_ahb_master_port<CYN::PIN>::write( 
	const sc_uint<32>& addr, const sc_uint<16>& data )
{
	return write_common(addr, amba::hsize_16, (data,data) );
}

inline bool cynw_ahb_master_port<CYN::PIN>::write( 
	const sc_uint<32>& addr, const sc_uint<32>& data )
{
	return write_common(addr, amba::hsize_32, data );
}

//------------------------------------------------------------------------------
template<typename D>
inline bool cynw_ahb_master_port<CYN::PIN>::write_incr_common( 
	const sc_uint<32>& addr, unsigned int data_n, int incr, const D* data_p )
{
	sc_uint<32> address;       // Address incrementer.
	sc_uint<3>  burst;         // Burst value.
	sc_uint<5>  data_i;        // Data value now writing.
    bool        grant;         // Value of HGRANT.
	sc_uint<4>  hsize;         // Size of data words.
    bool        ready;         // Value of HREADY.
	sc_uint<2>  resp;          // Value of HRESP.

	// SET UP:

	address = addr;
	data_i = 0;

	// BUS ACQUISTION PHASE:

retry:
    {
        CYN_PROTOCOL("write_incr_common");

        m_HBUSREQ = true;
		m_HLOCK = false;
		m_HTRANS = amba::htrans_idle;
        do {
            annotate(__LINE__);
			wait();
            grant = m_HGRANT.read();
        } while ( !grant );
        m_HBUSREQ = false;

		// ADDRESS PHASE:
		//
		// Send the initial control information and wait until slave is ready.
		// At that point the slave will be processing the control information 
		// during the current cycle.

		debug(__FILE__,__LINE__);
		switch ( data_n )
		{
		  case 4:  burst = amba::hburst_incr4;  break;
		  case 8:  burst = amba::hburst_incr8;  break;
		  case 16: burst = amba::hburst_incr16; break;
		  default: burst = amba::hburst_incr;   break;
		}
        m_HADDR = address;
		address = address + incr;
		m_HBURST = burst;
		switch ( incr )
		{
		  case 1:  hsize = amba::hsize_8;  break;
		  case 2:  hsize = amba::hsize_16; break;
		  default: hsize = amba::hsize_32; break;
		}
        m_HSIZE = hsize;
        m_HTRANS = amba::htrans_nonsequential;
		m_HWRITE = true;

		annotate(__LINE__);
		wait();
		ready = m_HREADY.read();

#if !defined(PASS_0in)
		if ( !ready )
		{
			do
			{
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready && (resp == amba::hresp_okay) );
		}
		else
		{
			resp = amba::hresp_okay; // ignore first HRESP value.
		}

		// DATA PHASE:
		//
		// If an error, retry, or skip occurs process them appropriately.
		// Update the control information for a data cycle.

		for ( ; data_i < data_n; )
		{
			// PROCESS SLAVE RESPONSE FROM PREVIOUS CYCLE:

			switch ( resp )
			{
			  case amba::hresp_okay:
				break;
			  case amba::hresp_retry:
			  case amba::hresp_split:
				{
					CYN_PROTOCOL("cynth_kludge");
				}
				goto retry;
			  default:
				{
					CYN_PROTOCOL("write_incr_common_error");
					m_HTRANS = amba::htrans_idle;
					annotate(__LINE__);
					wait();
				}
				return true;
			}

			// WRITE THE NEXT WORD:

			m_HADDR = address;
			address = address + incr;
			m_HWDATA = data_p[data_i]; 
			TEST_SLAVE_WAIT(data_i); 
			m_HTRANS = (data_i == (data_n-1)) ?
				amba::htrans_idle: amba::htrans_sequential;
			do {
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready && (resp == amba::hresp_okay) );
			if ( resp == amba::hresp_okay ) 
			{
				data_i = data_i + 1;
			}
		}
#else
		// DATA PHASE:
		//
		// If an error, retry, or skip occurs process them appropriately.
		// Update the control information for a data cycle.

		for ( ; data_i < data_n; )
		{
			// SLAVE NOT READY
			//
			// Hold the current control information for a clock.

			if ( !ready )
			{   
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			}

			// LOOP PROCESSING DATA WORDS UNTIL COUNT EXHAUSTED

			do
			{
				if ( !ready )
				{   
					switch ( resp )
					{   
					  case amba::hresp_okay:
						break;
					  case amba::hresp_retry:
					  case amba::hresp_split:
						{
							CYN_PROTOCOL("cynth_kludge"); // eliminates ERROR 11.
						}
						goto retry;
					  default:
						{   
							CYN_PROTOCOL("write_single_common_error");
							m_HTRANS = amba::htrans_idle;
							annotate(__LINE__);
							wait();
						}   
						return false;
					}   
				} 
				else
				{
					m_HTRANS = (data_i == (data_n-1)) ?
						amba::htrans_idle : amba::htrans_sequential;
					m_HADDR = address;
					address = address + incr;
					m_HWDATA = data_p[data_i]; 
					data_i = data_i + 1;
				}
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready );
		}
#endif
	}
	return true;
}

//------------------------------------------------------------------------------
//"cynw_ahb_master_port<CYN::PIN>::write - write multiple values"
//------------------------------------------------------------------------------
inline bool cynw_ahb_master_port<CYN::PIN>::write( 
	const sc_uint<32>& addr, unsigned int data_n, const sc_uint<8>* data_p )
{
	return write_incr_common(addr, data_n, 1, data_p);
}

inline bool cynw_ahb_master_port<CYN::PIN>::write( 
	const sc_uint<32>& addr, unsigned int data_n, const sc_uint<16>* data_p )
{
	return write_incr_common(addr, data_n, 2, data_p);
}

inline bool cynw_ahb_master_port<CYN::PIN>::write( 
	const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data )
{
	return write_incr_common(addr, data_n, 4, data );
}

//------------------------------------------------------------------------------
template<typename D>
inline bool cynw_ahb_master_port<CYN::PIN>::write_wrap_common( 
	const sc_uint<32>& addr, unsigned int data_n, int lob, const D* data_p )
{
	sc_uint<32> address;       // Address incrementer.
	sc_uint<3>  burst;         // Burst value.
	sc_uint<5>  data_i;        // Data value now writing.
    bool        grant;         // Value of HGRANT.
	int         hob;           // Index of high order address bit.
	sc_uint<4>  hsize;         // Size of data words.
    bool        ready;         // Value of HREADY.
	sc_uint<2>  resp;          // Value of HRESP.

	// SET UP:

	address = addr;
	data_i = 0;

	// BUS ACQUISTION PHASE:

retry:
    {
        CYN_PROTOCOL("write_wrap_common");

        m_HBUSREQ = true;
		m_HLOCK = false;
		m_HTRANS = amba::htrans_idle;
        do {
            annotate(__LINE__);
			wait();
            grant = m_HGRANT.read();
        } while ( !grant );
        m_HBUSREQ = false;

		// ADDRESS PHASE:
		//
		// Send the initial control information and wait until slave is ready.
		// At that point the slave will be processing the control information 
		// during the current cycle.

		debug(__FILE__,__LINE__);
		switch ( data_n >> 2 )
		{
		  case 1:  burst = amba::hburst_wrap4;  hob = lob+1; break;
		  case 2:  burst = amba::hburst_wrap8;  hob = lob+2; break;
		  default: burst = amba::hburst_wrap16; hob = lob+3; break;
		}
        m_HADDR = address;
		address(hob,lob) = address(hob,lob) + 1;
		m_HBURST = burst;
		switch ( lob )
		{
		  case 0:  hsize = amba::hsize_8;  break;
		  case 1:  hsize = amba::hsize_16; break;
		  default: hsize = amba::hsize_32; break;
		}
        m_HSIZE = hsize;
        m_HTRANS = amba::htrans_nonsequential;
		m_HWRITE = true;

		annotate(__LINE__);
		wait();
		ready = m_HREADY.read();

#if !defined(PASS_0in)
		if ( !ready )
		{
			do
			{
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready && (resp == amba::hresp_okay) );
		}
		else
		{
			resp = amba::hresp_okay; // ignore first HRESP value.
		}

		// DATA PHASE:
		//
		// If an error, retry, or skip occurs process them appropriately.
		// Update the control information for a data cycle.

		for ( ; data_i < ((unsigned int)2<<(hob-lob)); )
		{
			// PROCESS SLAVE RESPONSE FROM PREVIOUS CYCLE:

			switch ( resp )
			{
			  case amba::hresp_okay:
				break;
			  case amba::hresp_retry:
			  case amba::hresp_split:
				{
					CYN_PROTOCOL("cynth_kludge");
				}
				goto retry;
			  default:
				{
					CYN_PROTOCOL("write_wrap_common_error");
					m_HTRANS = amba::htrans_idle;
					annotate(__LINE__);
					wait();
				}
				return true;
			}

			// WRITE THE NEXT WORD:

			m_HADDR = address;
			address(hob,lob) = address(hob,lob) + 1;
			m_HWDATA = data_p[data_i]; 
			TEST_SLAVE_WAIT(data_i); 
			//m_HTRANS = (data_i == (((unsigned int)2<<(hob-lob))-1) ) ?  
			m_HTRANS = (data_i == (data_n-1)) ?
				amba::htrans_idle: amba::htrans_sequential;
			do {
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready && (resp == amba::hresp_okay) );
			if ( resp == amba::hresp_okay ) 
			{
				data_i = data_i + 1;
			}
		}
#else
		// SLAVE NOT READY
		//
		// Hold the current control information for a clock.

		if ( !ready )
		{   
			annotate(__LINE__);
			wait();
			ready = m_HREADY.read();
			resp = m_HRESP.read();
		}
		for ( ; data_i < ((unsigned int)2<<(hob-lob)); )
		{
			do
			{
				if ( !ready )
				{   
					switch ( resp )
					{   
					  case amba::hresp_okay:
						break;
					  case amba::hresp_retry:
					  case amba::hresp_split:
						{
							CYN_PROTOCOL("cynth_kludge"); // eliminates ERROR 11.
						}
						goto retry;
					  default:
						{   
							CYN_PROTOCOL("write_single_common_error");
							m_HTRANS = amba::htrans_idle;
							annotate(__LINE__);
							wait();
						}   
						return false;
					}   
				} 
				else
				{
					m_HTRANS = (data_i == (data_n-1)) ?
						amba::htrans_idle : amba::htrans_sequential;
					m_HADDR = address;
					address(hob,lob) = address(hob,lob) + 1;
					m_HWDATA = data_p[data_i]; 
					data_i = data_i + 1;
				}
				annotate(__LINE__);
				wait();
				ready = m_HREADY.read();
				resp = m_HRESP.read();
			} while ( !ready );
		}
#endif
	}
	return true;
}

//------------------------------------------------------------------------------
//"cynw_ahb_master_port<CYN::PIN>::write_wrap"
//------------------------------------------------------------------------------
inline bool cynw_ahb_master_port<CYN::PIN>::write_wrap(
    const sc_uint<32>& addr, unsigned int data_n, const sc_uint<8>* data_p )
{ 
	return write_wrap_common( addr, data_n, 0, data_p ); 

}

inline bool cynw_ahb_master_port<CYN::PIN>::write_wrap(
    const sc_uint<32>& addr, unsigned int data_n, const sc_uint<16>* data_p )
{ 
	return write_wrap_common( addr, data_n, 1, data_p ); 

}

inline bool cynw_ahb_master_port<CYN::PIN>::write_wrap(
    const sc_uint<32>& addr, unsigned int data_n, const sc_uint<32>* data_p )
{ 
	return write_wrap_common( addr, data_n, 2, data_p ); 
}

#endif // !defined(cynw_ahb_master_h_INCLUDED)
