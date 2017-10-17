/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/
#if !defined(cynw_memory_internal_h_INCLUDED)
#define cynw_memory_internal_h_INCLUDED

#if defined STRATUS 
#pragma hls_ip_def
#endif	

//==============================================================================
// CLASS cynw_process_id - Class to map module process to an integer value
//
//==============================================================================

template< unsigned int N >
class cynw_process_id {
  public:
#	if !defined(CYNTH_HL)
    inline cynw_process_id()
    {
        m_process_n = 0;
    }
    unsigned int operator () ()
    {
        sc_process_b* current_p;    // Current process.
        unsigned int  process_i;    // Entry in m_process_v examining.

        current_p = 
            sc_get_curr_simcontext()->get_curr_proc_info()->process_handle;
        for ( process_i = 0; process_i < m_process_n; process_i++ )
        {
            if ( m_process_v[process_i] == current_p ) return process_i;
        }
        if ( process_i >= N )
        {
            cout << "Too many process ids!" << endl;
            return 0; 
        }
        else
        {
            m_process_v[process_i] = current_p;
            m_process_n = process_i+1;
            return process_i;
        }
    }
  protected:
    unsigned int   m_process_n;    // Number of elements used in m_process_v.
    sc_process_b*  m_process_v[N]; // Vector of process ids.
#else
	inline cynw_process_id()
	{}
	unsigned int operator () ()
	{
		cynw_current_thread process_id;
		return process_id;
	}
  protected:
#endif
  private:
    cynw_process_id( const cynw_process_id& );
    const cynw_process_id& operator = ( const cynw_process_id& );
};

//==============================================================================
// GENERIC BEHAVIORAL VERSION:
//==============================================================================

template< typename MEM, unsigned int N >
class cynw_mem_internal
{
  public:
    typedef typename MEM::access_type access_type;
    typedef sc_uint<MEM::AW>          address_type;
    typedef typename MEM::data_type   data_type;
    typedef cynw_mem_internal<MEM,N>  this_type;
  public:
    cynw_mem_internal( const char* name = "dummy" )
    {
    }
    cynw_memory_ref<this_type,access_type> operator [] ( uint64 address )
    {
        return cynw_memory_ref<this_type,access_type>(this,address);
    }

  public:
    void dump( int n )
    {
        for ( int i = 0; i < n; i++ )
        {
            cout << "memory[" << i << "] is " << m_memory[i] << endl;
        }
    }
    data_type get(const address_type& address) const
    {
        data_type result;
        result = m_memory[address];
        return result;
    }
    void put( const address_type& address, const data_type& data )
    {
        m_memory[address] = data;
    }
  protected:
    data_type   m_memory[MEM::SIZE];
};

//==============================================================================
// cynw_mem_internal_base<MEM,N>
//
// This class is the base class for partially specialized multi-access memories.
//==============================================================================

template< typename MEM, unsigned int N >
class cynw_mem_internal_base : public sc_module
{
	CYN_INLINE_MODULE
  public:
    typedef typename MEM::access_type access_type;
    typedef sc_uint<MEM::AW>          address_type;
    typedef typename MEM::data_type   data_type;
    typedef cynw_mem_internal<MEM,N>  this_type;
  public:
    class Port {
      public:
        typedef typename MEM::access_type access_type;
        typedef sc_uint<MEM::AW>          address_type;
        typedef typename MEM::data_type   data_type;
        typedef cynw_mem_internal<MEM,N>  this_type;
      public:
        Port()
        {}
        data_type get(const address_type& address) const
        {
            data_type       result;       // Result to be returned.
#			if !defined(C_CP)
				sc_uint<1>      back_to_back; // Not 0 if we already have grant.
				back_to_back = m_grant.read();
#           endif      
            m_address = address;
            m_req = 1;
            m_we = false;
			do { ::wait(::sc_get_curr_simcontext()); } while (!m_grant.read());
#           if !defined(C_CP)
				if ( back_to_back ) ::wait(::sc_get_curr_simcontext());
#           endif
            m_req = 0;
            result = m_q_p->read();    
            return result;
        }
        void put( const address_type& address, const data_type& data )
        {
            m_address = address;
            m_data = data;
            m_we = true;
            m_req = 1;
            do { ::wait(::sc_get_curr_simcontext()); } while (!m_grant.read());
            m_req = 0;
        }
      public:
        mutable sc_signal<address_type> m_address;  // Address for operation.
        mutable sc_signal<data_type>    m_data;     // Data for write.
        mutable sc_signal<sc_uint<1> >  m_grant;    // Arbiter grant.
        mutable sc_signal<sc_uint<1> >  m_req;      // Arbiter request.
        sc_signal<data_type>*           m_q_p;      // Output from ram.
        mutable sc_signal<bool>         m_we;       // True if write requested.
      private:
        Port(const Port&);
        const Port& operator = (const Port&);
    };
  public:
    cynw_mem_internal_base( sc_module_name name ) : sc_module(name)
    {
    }

    void dump( int n )
    {
        for ( int i = 0; i < n; i++ )
        {
            cout << "memory[" << i << "] is " << m_memory[i] << endl;
        }
    }


    // CURRENT THREAD TO INTEGER PROCESS NUMBER:

        cynw_process_id<N>  process_id;  // Registers process ids.

    // COMMON FIELDS:

    sc_in_clk            m_clk;                 // Clock.
    data_type            m_memory[MEM::SIZE];   // Storage for memory.
    sc_signal<data_type> m_q;                   // Output data signal.
    sc_in<bool>          m_reset;               // Reset signal.
};


#define CYN_SET_C_CP_DELAYS(PORT,CLK,SETUP,DELAY) \
	CYN_OUTPUT_REQUIRED( PORT.m_address, CLK-DELAY, #PORT".m_address required" ); \
	CYN_OUTPUT_REQUIRED( PORT.m_data, SETUP, #PORT".m_data required" ); \
	CYN_INPUT_DELAY( PORT.m_grant, DELAY, #PORT".m_grant delay" );\
	CYN_OUTPUT_REQUIRED( PORT.m_req, SETUP, #PORT".m_req required" ); \
	CYN_OUTPUT_REQUIRED( PORT.m_we, SETUP, #PORT".m_we required" ); 

#define CYN_SET_DELAYS(PORT,CLK,SETUP,DELAY) \
	CYN_INPUT_DELAY( PORT.m_address, CLK-SETUP, #PORT".m_address delay" ); \
	CYN_INPUT_DELAY( PORT.m_data, CLK-SETUP, #PORT".m_data delay" ); \
	CYN_OUTPUT_REQUIRED( PORT.m_grant, CLK-DELAY, #PORT".m_grant required" );\
	CYN_INPUT_DELAY( PORT.m_req, CLK-SETUP, #PORT".m_req delay" ); \
	CYN_INPUT_DELAY( PORT.m_we, CLK-SETUP, #PORT".m_we delay" ); 

//==============================================================================
template< typename MEM >
class cynw_mem_internal<MEM,2> : public cynw_mem_internal_base<MEM,2>
{
  public:
    typedef typename MEM::access_type                access_type;
    typedef sc_uint<MEM::AW>                         address_type;
    typedef typename MEM::data_type                  data_type;
    typedef typename cynw_mem_internal<MEM,2>::Port  port_type;
                                                                   
  public:
    cynw_mem_internal( sc_module_name name=sc_gen_unique_name("mem_internal")) :
		cynw_mem_internal_base<MEM,2>(name)
    {
        SC_HAS_PROCESS(cynw_mem_internal);

		// DEFINE THREAD THAT WILL PROCESS THE REQUESTS FROM get() AND put()
        // 
		// If this is not a synthesis run, but we want single cycle processing
		// set the thread up for negative edge processing.

#		if defined(C_CP) && !defined(CYNTH_HL)
			SC_CTHREAD(process,m_clk.neg())
#		else
			SC_CTHREAD(process,m_clk.pos())
#		endif
        watching( m_reset.delayed() == false );
        m_port0.m_q_p = &m_q;
        m_port1.m_q_p = &m_q;
#       ifdef STRATUS_HLS
            CYN_SET_DELAYS(m_port0,CLK_PERIOD,SETUP,DELAY)
            CYN_SET_DELAYS(m_port1,CLK_PERIOD,SETUP,DELAY)
            CYN_OUTPUT_REQUIRED( m_q, CLK_PERIOD - DELAY, "q required" );
         
#           ifdef C_CP 
                CYN_SET_C_CP_DELAYS(m_port0,CLK_PERIOD,SETUP,DELAY)
                CYN_SET_C_CP_DELAYS(m_port1,CLK_PERIOD,SETUP,DELAY)
                CYN_INPUT_DELAY( m_q, DELAY, "q delay" );
#           endif C_CP
#       endif
    }

    cynw_memory_ref<port_type,access_type> operator [] ( uint64 address )
    {
        switch ( process_id() )
        {
          default:
          case 0:
            return cynw_memory_ref<port_type,access_type>( &m_port0, address );
          case 1:
            return cynw_memory_ref<port_type,access_type>( &m_port1, address );
        }
    }
    
    void process()
    {
        address_type address;   // Address to access.
        data_type    data;      // Data value to be written.
        bool         we;        // True if this is a write.
        {
            CYN_PROTOCOL("proc reset")
            m_q = 0;
            wait();
        }
        while ( 1 )
        {
			CYN_PROTOCOL( "proc clock" );
            wait();
            
            sc_uint<4> state;
            state = (
                m_port0.m_grant.read(), 
                m_port1.m_grant.read(),
                m_port0.m_req.read(), 
                m_port1.m_req.read() );
            switch( state )
            {
                        // GG RR    GG RR
                        // 01 01    01 01
                        // -- --    -- --
                        // 00 00    00 00 (0)
                        // 01 00    00 00 (4)
                        // 10 00    00 00 (8)
                        // 11 xx    00 xx (c-f)
              default:
                m_port0.m_grant = 0;
                m_port1.m_grant = 0;
                we = false;
                address = 0;
                break;
                        // GG RR    GG RR
                        // 01 01    01 01
                        // -- --    -- --
              case 0x1: // 00 01 -> 01 01
              case 0x5: // 01 01 -> 01 01
              case 0x9: // 10 01 -> 01 01
              case 0xb: // 10 11 -> 01 11
                m_port0.m_grant = 0;
                m_port1.m_grant = 1;
                address = m_port1.m_address.read();
                data = m_port1.m_data.read();
                we = m_port1.m_we.read();
                break;
                        // GG RR    GG RR
                        // 01 01    01 01
                        // -- --    -- --
              case 0x2: // 00 10 -> 10 10
              case 0x3: // 00 11 -> 10 11
              case 0x6: // 01 10 -> 10 10
              case 0x7: // 01 11 -> 10 11
              case 0xa: // 10 10 -> 10 10
                m_port0.m_grant = 1;
                m_port1.m_grant = 0;
                address = m_port0.m_address.read();
                data = m_port0.m_data.read();
                we = m_port0.m_we.read();
                break;
            }

            if ( we )
            {
                m_memory[address] = data;
                // wait();
                m_q = 0;
            }
            else
            {
                m_q = m_memory[address];
            }
        }
    }
    port_type  m_port0;
    port_type  m_port1;
};

//==============================================================================
template< typename MEM >
class cynw_mem_internal<MEM,3> : public cynw_mem_internal_base<MEM,3>
{
  public:
    typedef typename MEM::access_type                access_type;
    typedef sc_uint<MEM::AW>                         address_type;
    typedef typename MEM::data_type                  data_type;
    typedef typename cynw_mem_internal<MEM,3>::Port  port_type;

  public:
    cynw_mem_internal( sc_module_name name=sc_gen_unique_name("mem_internal")) :
		cynw_mem_internal_base<MEM,3>(name)
    {
        SC_HAS_PROCESS(cynw_mem_internal);
        SC_CTHREAD(process,m_clk.pos())
        watching( m_reset.delayed() == false );
        m_port0.m_q_p = &m_q;
        m_port1.m_q_p = &m_q;
        m_port2.m_q_p = &m_q;
#       ifdef STRATUS_HLS
            CYN_SET_DELAYS(m_port0,CLK_PERIOD,SETUP,DELAY)
            CYN_SET_DELAYS(m_port1,CLK_PERIOD,SETUP,DELAY)
            CYN_SET_DELAYS(m_port2,CLK_PERIOD,SETUP,DELAY)
            CYN_OUTPUT_REQUIRED( m_q, CLK_PERIOD - DELAY, "q required" );
         
#           ifdef C_CP 
				CYN_SET_C_CP_DELAYS(m_port0,CLK_PERIOD,SETUP,DELAY)
				CYN_SET_C_CP_DELAYS(m_port1,CLK_PERIOD,SETUP,DELAY)
				CYN_SET_C_CP_DELAYS(m_port2,CLK_PERIOD,SETUP,DELAY)
                CYN_INPUT_DELAY( m_q, DELAY, "q delay" );
#           endif // C_CP
#       endif // CYNTH_HL
    }

    cynw_memory_ref<port_type,access_type> operator [] ( uint64 address )
    {
        switch ( process_id() )
        {
          default:
          case 0:
            return cynw_memory_ref<port_type,access_type>( &m_port0, address );
          case 1:
            return cynw_memory_ref<port_type,access_type>( &m_port1, address );
          case 2:
            return cynw_memory_ref<port_type,access_type>( &m_port2, address );
        }
    }


    void process()
    {
        address_type address;   // Address to access.
        data_type    data;      // Data value to be written.
        bool         we;        // True if this is a write.
        {
            CYN_PROTOCOL("proc reset")
            m_q = 0;
            wait();
        }
        while ( 1 )
        {   
			CYN_PROTOCOL( "proc clock" );
            
            sc_uint<6> state;
            state = (
                m_port0.m_grant.read(), 
                m_port1.m_grant.read(),
                m_port2.m_grant.read(),
                m_port0.m_req.read(),
                m_port1.m_req.read(), 
                m_port2.m_req.read() );
            switch( state )
            { 
                         // GGG RRR   GGG RRR
                         // 012 012    012 012
                         // --- ---    --- ---
                         // 000 000 -> 000 000  (0)
                         // 001 000 -> 000 000  (8)
                         // 010 000 -> 000 000  (10)
                         // 011 xxx -> 000 xxx  (18-1f)
                         // 100 000 -> 000 000  (20)
                         // 101 xxx -> 000 xxx  (28-2f)
                         // 11x xxx -> 000 xxx  (30-3f)
              default:
                m_port0.m_grant = 0;
                m_port1.m_grant = 0;
                we = false;
                address = 0;
                break;
                         // GGG RRR    GGG RRR
                         // 012 012    012 012
                         // --- ---    --- ---
              case 0x4:  // 000 100 -> 100 100
              case 0x5:  // 000 101 -> 100 101
              case 0x6:  // 000 110 -> 100 110
              case 0x7:  // 000 111 -> 100 111
              case 0xc:  // 001 100 -> 100 100
              case 0xd:  // 001 101 -> 100 101
              case 0xe:  // 001 110 -> 100 110
              case 0xf:  // 001 111 -> 100 111
              case 0x14: // 010 100 -> 100 100
              case 0x15: // 010 101 -> 100 101
              case 0x16: // 010 110 -> 100 110
              case 0x24: // 100 100 -> 100 100
                m_port0.m_grant = 1;
                m_port1.m_grant = 0;
                m_port2.m_grant = 0;
                address = m_port0.m_address.read();
                data = m_port0.m_data.read();
                we = m_port0.m_we.read();
                break;
                         // GGG RRR    GGG RRR
                         // 012 012    012 012
                         // --- ---    --- ---
              case 0x2:  // 000 010 -> 010 010
              case 0x3:  // 000 011 -> 010 011
              case 0xa:  // 001 010 -> 010 010
              case 0xb:  // 001 101 -> 010 011
              case 0x12: // 001 010 -> 010 010
              case 0x22: // 100 010 -> 010 010
              case 0x23: // 100 011 -> 010 011
              case 0x26: // 100 110 -> 010 110
              case 0x27: // 100 111 -> 010 111
                m_port0.m_grant = 0;
                m_port1.m_grant = 1;
                m_port2.m_grant = 0;
                address = m_port1.m_address.read();
                data = m_port1.m_data.read();
                we = m_port1.m_we.read();
                break;
                         // GGG RRR    GGG RRR
                         // 012 012    012 012
                         // --- ---    --- ---
              case 0x1:  // 000 001 -> 001 001
              case 0x9:  // 001 001 -> 001 001
              case 0x11: // 010 001 -> 001 001
              case 0x13: // 010 011 -> 001 011
              case 0x17: // 010 111 -> 001 111
              case 0x21: // 100 001 -> 001 001
              case 0x25: // 100 101 -> 001 001
                m_port0.m_grant = 0;
                m_port1.m_grant = 0;
                m_port2.m_grant = 1;
                address = m_port2.m_address.read();
                data = m_port2.m_data.read();
                we = m_port2.m_we.read();
                break;
            }

            if ( we )
            {
                m_memory[address] = data;
                m_q = 0;
            }
            else
            {
                m_q = m_memory[address];
            }
            wait();
        }
    }
    
    port_type  m_port0;
    port_type  m_port1;
    port_type  m_port2;
};

#undef CYN_SET_INPUT_DELAYS
#undef CYN_SET_OUTPUT_REQUIRED

#endif // !defined(cynw_memory_internal_h_INCLUDED)
