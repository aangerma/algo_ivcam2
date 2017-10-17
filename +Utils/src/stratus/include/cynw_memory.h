/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/
#ifndef Cynw_Memory_H_INCLUDED
#define Cynw_Memory_H_INCLUDED

#include <cynthhl.h>
#if !defined(STRATUS_VLG)
#include <esc.h>
#endif

#if defined STRATUS 
#pragma hls_ip_def
#endif	

#if ( ! defined(SC_API_VERSION_STRING) || defined(BDW_COWARE) )
#define USE_GENERIC_BASE 0
#else
#define USE_GENERIC_BASE 0	// disabled for 2.4.1
#endif

//------------------------------------------------------------------------------
// Cynthesizer external memory classes
// -----------------------------------
//
// External memory modeling for Cynthesizer is done using a set of classes
// that defines a family of memories.  A memory family is a set of memories that
// shared the characteristics of protocol, latency, and port organization, but
// contains several members, each with different address size, word width, and
// delay characteristics.  A set of templated classes is defined once for each 
// family of memories, and individual memories from the family are defined as 
// needed by specifying template parameters.
//
// There are 3 important classes defined for each memory family:
//
// 1. A memory table-of-contents (TOC) class.  This class defines various types
//    related to the memory family.
//
// 2. A memory model class. This class defines a module that implements the 
//    behavioral model for the memory.
//
// 3. A client port container class.  This class is instantiated in clients of 
//    the memory to define the pinout and protocol for accessing the memory.  
//    This class is synthesizable.
//
// For example:

/* 
  //------------------------------------------------------------------------------
  // Memory table-of-contents
  //------------------------------------------------------------------------------
  template <int A, int D, unsigned SETUP=0, unsigned DELAY=0, unsigned S=(1<<A) >
  class ramA {
    public:
      typedef sc_uint<A>                                  address_type;
      typedef sc_uint<D>                                  data_type;
      typedef ramA<A,D,S>                                 this_type;
      typedef cynw_memory_if< address_type, data_type >   if_type;
      typedef ramA_model< this_type >                     model;
      typedef ramA_port< this_type, SETUP, DELAY >        base_port;
      typedef cynw_memory_port< base_port >               port;
      typedef cynw_memory_port< base_port, sc_int<D> >    s_port;
      typedef cynw_memory_ut_port< this_type >            ut_port;
      enum {
        SIZE = S
      };
  };

  //------------------------------------------------------------------------------
  // Memory model class
  //------------------------------------------------------------------------------
  template <typename MEM>
  class ramA_model :
      public sc_module,
      public cynw_memory_model_base<MEM>
  {
    // See cynw_memory_model_base<MEM> for details.
  };


  //------------------------------------------------------------------------------
  // Client port container class
  //------------------------------------------------------------------------------

  template <typename MEM>
  class mymem_port
  {
    typedef typename MEM::data_type             data_type;
    typedef typename MEM::address_type          address_type;

    data_type get( const address_type& address ) ;
    {
        CYN_MEM_READ_TX( <setup>, <delay>, <pipe_init>, this, <address>, 0, "" );
        // Memory read protocol
    }

    void put( const address_type& address, const data_type& data )
    {
        CYN_MEM_WRITE_TX( <setup>, <pipe_init>, this, <address>, 0, "" );
        // Memory write protocol
    }

    void reset()
    {
        CYN_PROTOCOL("reset");
        // Reset output ports
    }

    // Define signal-level ports.
    sc_out<address_type> ADDR;
    sc_out<bool>         CE;
    sc_in<data_type>     DIN;
    sc_out<data_type>    DOUT;
    sc_out<bool>         WE;
  }; 
*/
//
// Individual members of the memory family can be defined by specifying 
// template parameters to the memory family class.  For example:
//
/*
  //------------------------------------------------------------------------------
  // Specific memory definitions:
  //------------------------------------------------------------------------------
  typedef ramA<8,32,1200,2500>  ramA_256X32;
  typedef ramA<10,32,1250,2700> ramA_1024X32;

*/
// 
// A synthesizable module that accesses the external memory can then instantiate a 
// port class and access it using array access syntax.  For example:
//
/*
 
  SC_MODULE(dut) {
    
    // Declare memory ports.
    ramA_256X32::port     ram1;
    ramA_256X32::port     ram2;
    ramA_1024X32::port    ram3;

    void thread() {
      while (1) {

    // Read and write memories using array access syntax.
    for ( sc_uint<10> i=0; i < 256; i++ ) {
      ram3[i] = ram1[i] + ram2[i];
    }
  };

 */
//
// A memory model can then be instantiated in a system-level netlist as follows:
//
/*
 
 SC_MODULE(system) {

   // Declare memory models.
   ramA_256X32::model   ram1;
   ramA_256X32::model   ram2;
   ramA_1024X32::model  ram3;
   dut m_dut;

   SC_CTOR(system) {

     // Connect pins of dut and memory models.
     ram1.CE( m_dut.ram1_CE );
     ram1.ADDR( m_dut.ram1_ADDR );
     ...
   }
 };
 */
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// cynw_memory_if<AT,DT> - MEMORY ACCESS INTERFACE
//
// This class implements a memory access interface whose characteristics
// are specified by the AT and DT template parameters:
//
//     AT - the type of the address used to access a memory location.
//     DT - the type of data at each memory location.
//
// These types are exposed in member typesdefs named address_type and 
// data_type respectively.
//
// The cynw_memory_if<AT,DT> class defines two pure virtual member functions:
// 
//    virtual data_type get( const address_type& address )
//
//      Reads a data value from the specified address.
//
//    virtual void put( const address_type& address, const data_type& data )
//      
//      Writes a data value to the specified address.
//
//------------------------------------------------------------------------------
template <typename CYN_AT, typename CYN_DT=cyn_enum<0> >
class cynw_memory_if : virtual public sc_interface {
  public:
    //typedef CYN_AT address_type;
    //typedef CYN_DT data_type;

  public:
    cynw_memory_if() {}
    virtual CYN_DT get( const CYN_AT& address ) = 0;
    virtual void put( const CYN_AT& address, 
                      const CYN_DT& data ) = 0;
  private:
    cynw_memory_if( const cynw_memory_if<CYN_AT,CYN_DT>& );
    void operator = ( const cynw_memory_if<CYN_AT,CYN_DT>& );
};

//------------------------------------------------------------------------------
// Specialization of cynw_memory_if class for legacy support.
//
// In previous releases, a memory family class MEM was used as the template
// parameter for cynw_memory_if. That form has been deprecated, but is supported
// by this specialization.
//
//------------------------------------------------------------------------------
template <typename CYN_MEM>
class cynw_memory_if< CYN_MEM, cyn_enum<0> >
  : public cynw_memory_if<typename CYN_MEM::address_type, typename CYN_MEM::data_type> 
{
};


//------------------------------------------------------------------------------
// CONVERSION FUNCTIONS - 
//      cynw_interpret(FROM,TO) AND cynw_interpret_from_generic_base()
//
// The cynw_interpret(FROM,TO) function is used to read data from 
// and write data to memories.  Any data type that supports casts to and from 
// the data_type of a memory (ordinarily sc_uint<N>) will be automatically 
// supported by the implementation of cynw_interpret below.  For other data 
// types, specializations of the cynw_interpret(FROM,TO) function must be 
// provided in order to support accessing memory using that data type.
// 
// The cynw_interpret_from_generic_base() templated function performs 
// conversions from sc_generic base to the standard SystemC integer types. It 
// is necessary for synthesis.
//------------------------------------------------------------------------------

#define CYNW_INTERPRET_UINT(OTHER) \
    inline void cynw_interpret( const OTHER& from, sc_uint_base& to ) \
    { \
        to = from; \
    } \
    inline void cynw_interpret( const sc_uint_base& from, OTHER& to ) \
    { \
        to = from; \
    } 

#define CYNW_INTERPRET_UNSIGNED(OTHER) \
    inline void cynw_interpret( const OTHER& from, sc_unsigned& to ) \
    { \
        to = from; \
    } \
    inline void cynw_interpret( const sc_unsigned& from, OTHER& to ) \
    { \
        to = from.to_uint64(); \
    } 

#define CYNW_INTERPRET(OTHER) \
    CYNW_INTERPRET_UINT(OTHER) \
    CYNW_INTERPRET_UNSIGNED(OTHER) 


CYNW_INTERPRET(char) 
CYNW_INTERPRET(short)
CYNW_INTERPRET(int)
CYNW_INTERPRET(long)
CYNW_INTERPRET(int64)
CYNW_INTERPRET(unsigned char)
CYNW_INTERPRET(unsigned short)
CYNW_INTERPRET(unsigned int)
CYNW_INTERPRET(unsigned long)
CYNW_INTERPRET(uint64)
CYNW_INTERPRET(sc_int_base)
CYNW_INTERPRET(sc_signed)

// TO TYPE IS sc_uint_base:

inline void cynw_interpret( const sc_uint_base& from, sc_uint_base& to ) 
{ 
    to = from; 
} 
inline void cynw_interpret( const sc_unsigned& from, sc_uint_base& to ) 
{ 
    to = from; 
} 
 
// TO TYPE IS sc_unsigned:

inline void cynw_interpret( const sc_unsigned& from, sc_unsigned& to ) 
{ 
    to = from; 
} 
inline void cynw_interpret( const sc_uint_base& from, sc_unsigned& to ) 
{ 
    to = from; 
} 
 
#if USE_GENERIC_BASE
    template<int CYN_W, typename O>
    inline void cynw_interpret_from_generic_base( 
	sc_int<CYN_W>& result, const sc_generic_base<O>& value )
    {
	result = value->to_uint64();
    }

    template<int CYN_W, typename O>
    inline void cynw_interpret_from_generic_base( 
        sc_uint<CYN_W>& result, const sc_generic_base<O>& value )
    {
        result = value->to_uint64();
    }
    
    template<int CYN_W, typename O>
    inline void cynw_interpret_from_generic_base( 
        sc_bigint<CYN_W>& result, const sc_generic_base<O>& value )
    {
        value->to_sc_signed(&result);
    }
    
    template<int CYN_W, typename O>
    inline void cynw_interpret_from_generic_base( 
        sc_biguint<CYN_W>& result, const sc_generic_base<O>& value )
    {
        value->to_sc_unsigned(&result);
    }
#endif // USE_GENERIC_BASE

#undef CYNW_INTERPRET_UINT
#undef CYNW_INTERPRET_UNSIGNED


//------------------------------------------------------------------------------
// Fallback cynw_interpret for cases where its applied to 2 values of the 
// same type.
//------------------------------------------------------------------------------
template <typename T>
inline void cynw_interpret( const T& from, T& to ) 
{
  to = from;
}

//------------------------------------------------------------------------------
// cynw_memory_ref<IF,ACCESS> - Enacapsulates a reference to a memory location
//                                  for use in a read or write operation.
//
// This class is a proxy for a particular location in an object that implements
// an interface containing addressed get and put functions. The IF class
// must provide two typenames:
//     address_type - the type of the address used to access data.
//     data_type    - the type of the data to be accessed.
// The actual interface defines addressed get and put methods:
//     data_type get( const address_type& )
//     void put( const address_type&, const data_type& )
//
// Any class implementing cynw_memory_if<address_type,data_type> will fulfill 
// these requirements, but any other class that also meets this requirements 
// will be compatible with cynw_memory_ref as well.
//
// The ACCESS template parameter defines the type of value that will be read 
// from and written to the memory.  If this type does not match MEM::data_type,
// the type of value stored in the memory, cynw_interpret<FROM,TO> functions 
// must be available to convert between ACCESS and MEM::data_type. If no ACCESS
// template argument is supplied, it defaults to the data_type of the IF class.
//
// This class is not ordinarily instantiated by user-written code.
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS= typename CYN_IF::data_type, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAPPING = HLS::COMPACT >
#if USE_GENERIC_BASE
    class cynw_memory_ref : 
		public sc_generic_base<cynw_memory_ref<CYN_IF,CYN_ACCESS> > {
#else
    class cynw_memory_ref {
#endif
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref<CYN_IF,CYN_ACCESS,CYN_MAPPING>      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
	return address;
    }
    access_type value () const
    {
	data_type data_value = m_iface_p->iface_type::get(m_address);
	access_type result;
        cynw_interpret( data_value, result );
	return result;
    }
    operator access_type () 
    {
        return value();
    }
    access_type operator * ()
    {
        return value();
    }
    data_type data_value()
    {
        return m_iface_p->iface_type::get(m_address);
    }
    // The following three operator = overloads should allow the assignment to 
    // the memory location any value that can also be assigned to an instance 
   // of access_type. (PR12505)
    template<typename OTHER>
    inline void operator = ( const OTHER& data )
    {
	access_type from; 
	data_type    to;
	from = data;
	cynw_interpret(from, to);
        m_iface_p->iface_type::put( m_address, to );
    }
    template< typename CYN_IF1, typename ACCESS1>
    inline void operator = ( const cynw_memory_ref<CYN_IF1,ACCESS1>& data )
    {
	data_type    to;
	cynw_interpret(data.value(), to);
        m_iface_p->iface_type::put( m_address, to );
    }
    inline void operator = ( const this_type& data )
    {
        m_iface_p->iface_type::put( m_address, ((this_type&)data).data_value() );
    }
    uint64 operator [] ( int bit )
    {
        return m_iface_p->iface_type::get(m_address)[bit];
    }
    uint64 range( int left, int right )
    {
        return m_iface_p->iface_type::get(m_address)(left, right);
    }
    access_type operator ~ () 
    {
        return ~value();
    }
    access_type operator - () 
    {
        return -value();
    }
    bool operator ! () 
    {
        return ( value() != 0 );
    }
    uint64 to_uint64() const
    {
	uint64 result;
        cynw_interpret( m_iface_p->iface_type::get(m_address), result );
	return result;
    }
    int64 to_int64() const
    {
	int64 result;
        cynw_interpret( m_iface_p->iface_type::get(m_address), result );
	return result;
    }
    void to_sc_signed( sc_signed& result ) const
    {
        result = m_iface_p->iface_type::get(m_address); 
    }
    void to_sc_unsigned( sc_unsigned& result ) const
    {
        result = m_iface_p->iface_type::get(m_address);
    }

#if USE_GENERIC_BASE
    template<typename OTHER> 
    inline void operator = ( const sc_generic_base<OTHER>& value ) 
    { 
	data_type tmp;
	cynw_interpret_from_generic_base(tmp,value);
	m_iface_p->iface_type::put(m_address, tmp);
    }
#endif

  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

// STREAM I/O OPERATOR:

template< typename CYN_IF, typename CYN_ACCESS, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP >
ostream& operator << ( ostream& os, const cynw_memory_ref<CYN_IF,CYN_ACCESS,CYN_MAP>& a )
{
    return os << a.value();
}

// SHIFT OPERATORS:

template< typename CYN_IF, typename CYN_ACCESS,HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP >
CYN_ACCESS operator << ( const cynw_memory_ref<CYN_IF,CYN_ACCESS,CYN_MAP>& a, int b )
{
    return (CYN_ACCESS) (a.value() << b);
}

template< typename CYN_IF, typename CYN_ACCESS,HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP >
CYN_ACCESS operator >> ( const cynw_memory_ref<CYN_IF,CYN_ACCESS,CYN_MAP>& a, int b )
{
    return (CYN_ACCESS) (a.value() >> b);
}


//------------------------------------------------------------------------------
// CYNW_MEM_SQUARE_BRACKETS and CYN_MEM_SQUARE_BRACKETS_INDIRECT macros
//
// Designed to be used in the public section of a class body.
//
// Defines a set of operator[] operators returning the given ref_type.
//
// The CYNW_MEM_SQUARE_BRACKETS macro can add operator[] syntax that
// will support indexing operations on either the left hand side or 
// right hand side of an assignment.  In order to support 
// CYNW_MEM_SQUARE_BRACKETS, the class must have several members defined.  
// For example:
//
// class my_indexable {
//   public:
//     typedef sc_uint<8>	data_type;
//     typedef sc_uint<10>	address_type;
//     CYNW_MEM_SQUARE_BRACKETS( cynw_memory_ref< my_indexable > )
//
//    data_type get( const address_type& address );
//    void put( const address_type& address, const data_type& data );
//
//    ...
//
// CYN_MEM_SQUARE_BRACKETS directs get/put calls to the object in which the
// declaration appears.  CYN_MEM_SQUARE_BRACKETS_INDIRECT accepts a pointer
// argument that specifies the object to which calls should be directed.
//
// The required attibutes of the class are:
//
// 1.  Member typedefs with the names 'address_type' and 'data_type' that 
//     define the address and data type used by the interface.
//
// 2.  get() and put() member functions consistent with the cynw_memory_if interface.
//
// 3.  A CYNW_MEMORY_SQUARE_BRACKETS() macro with an argument that is a 
//     cynw_memory_ref<> type.  The template arguments for cynw_memory_ref are:
//
//        1) The class itself. In this example, my_indexable.  This is required.
//        2) The type that should be used in operator[] calls.  This is required
//           only if the data type used with operator[] is different to the 
//           data type of the target.  For example, if the memory stored 
//           unsigned data, but access to the data should be signed, then 
//           cynw_memory_ref< my_indexable, sc_int<8> > can be specified.
//------------------------------------------------------------------------------
#define CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, obj, offset, op, addr_type ) \
  ref_type operator [] ( const sc_int_base& address ) \
  { \
      ref_type rslt = ref_type(  obj, cynw_memory_ref_calc_address( (ref_type*)0, (addr_type)address) op (uint64)(offset)); \
	  CYN_MARK_TX_CALL( rslt ); \
	  return rslt; \
  } \
  ref_type operator [] ( const sc_uint_base& address ) \
  { \
      ref_type rslt = ref_type(  obj, cynw_memory_ref_calc_address( (ref_type*)0, (addr_type)address) op (uint64)(offset)); \
	  CYN_MARK_TX_CALL( rslt ); \
	  return rslt; \
  } \
  ref_type operator [] ( uint64 address ) \
  { \
      ref_type rslt = ref_type(  obj, cynw_memory_ref_calc_address( (ref_type*)0, (addr_type)address) op (uint64)(offset)); \
	  CYN_MARK_TX_CALL( rslt ); \
	  return rslt; \
  } \
  template<typename CYN_IF1, typename ACCESS1> \
  ref_type operator [] ( const cynw_memory_ref<CYN_IF1,ACCESS1>& address ) \
  { \
      ref_type rslt = ref_type( obj, cynw_memory_ref_calc_address( (ref_type*)0, (addr_type)(address.value())) op (uint64)(offset)); \
	  CYN_MARK_TX_CALL( rslt ); \
	  return rslt; \
  } 

#define CYNW_MEM_SQUARE_BRACKETS( rt ) \
  CYNW_MEM_SQUARE_BRACKETS_INDIRECT( rt, this, 0, +, uint64 )


//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[N][M], COMPACT >
//
// Template specialization of cynw_memory_ref for 2D arrays with COMPACT address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D1][CYN_D0], HLS::COMPACT >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref<CYN_IF,CYN_ACCESS>      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D1][CYN_D0], HLS::COMPACT >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {
}

    static uint64 calc_address( uint64 address )
    {
      return (uint64)address * CYN_D0;
    }

    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, +, uint64 )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[N][M], SIMPLE >
//
// Template specialization of cynw_memory_ref for 2D arrays with SIMPLE address
// mapping.  Addresses are 
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D1][CYN_D0], HLS::SIMPLE >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref<CYN_IF,CYN_ACCESS>      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D1][CYN_D0], HLS::SIMPLE >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    { 
    }

    static uint64 calc_address( uint64 address )
    {
      return (uint64)address << cyn_log::log2<CYN_D0>::value;
    }

    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, |, sc_uint< cyn_log::log2<CYN_D0>::value > )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[K][N][M], COMPACT >
//
// Template specialization of cynw_memory_ref for 3D arrays with COMPACT address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D1][CYN_D0], HLS::COMPACT >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address * CYN_D1 * CYN_D0);
    }

    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, +, uint64 )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< CYN_IF, ACCESS[K][N][M], SIMPLE >
//
// Template specialization of cynw_memory_ref for 3D arrays with SIMPLE address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D1][CYN_D0], HLS::SIMPLE >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address << (cyn_log::log2<CYN_D1>::value + cyn_log::log2<CYN_D0>::value));
    }

    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, |, sc_uint< cyn_log::log2<CYN_D1>::value > )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[J][K][N][M], COMPACT >
//
// Template specialization of cynw_memory_ref for 4D arrays with COMPACT address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address * CYN_D2 * CYN_D1 * CYN_D0);
    }
    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, +, uint64 )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[J][K][N][M], SIMPLE >
//
// Template specialization of cynw_memory_ref for 4D arrays with SIMPLE address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address << (cyn_log::log2<CYN_D2>::value + cyn_log::log2<CYN_D1>::value) + cyn_log::log2<CYN_D0>::value);
    }
    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, |, sc_uint< cyn_log::log2<CYN_D2>::value > )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[J][K][N][M][O], COMPACT >
//
// Template specialization of cynw_memory_ref for 5D arrays with COMPACT address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address * CYN_D3 * CYN_D2 * CYN_D1 * CYN_D0);
    }
    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, +, uint64 )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[J][K][N][M][O], SIMPLE >
//
// Template specialization of cynw_memory_ref for 5D arrays with SIMPLE address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address << (cyn_log::log2<CYN_D3>::value + cyn_log::log2<CYN_D2>::value + cyn_log::log2<CYN_D1>::value) 
				  + cyn_log::log2<CYN_D0>::value);
    }
    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, |, sc_uint< cyn_log::log2<CYN_D3>::value > )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[J][K][N][M][O][P], COMPACT >
//
// Template specialization of cynw_memory_ref for 6D arrays with COMPACT address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D5, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address * CYN_D4 * CYN_D3 * CYN_D2 * CYN_D1 * CYN_D0);
    }
    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, +, uint64 )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[J][K][N][M][O][P], SIMPLE >
//
// Template specialization of cynw_memory_ref for 6D arrays with SIMPLE address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D5, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address << (cyn_log::log2<CYN_D4>::value + cyn_log::log2<CYN_D3>::value + cyn_log::log2<CYN_D2>::value 
				  + cyn_log::log2<CYN_D1>::value) + cyn_log::log2<CYN_D0>::value);
    }
    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, |, sc_uint< cyn_log::log2<CYN_D4>::value > )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[J][K][N][M][O][P][Q], COMPACT >
//
// Template specialization of cynw_memory_ref for 7D arrays with COMPACT address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D6, int CYN_D5, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address * CYN_D5 * CYN_D4 * CYN_D3 * CYN_D2 * CYN_D1 * CYN_D0);
    }
    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, +, uint64 )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[J][K][N][M][O][P][Q], SIMPLE >
//
// Template specialization of cynw_memory_ref for 7D arrays with SIMPLE address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D6, int CYN_D5, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address << (cyn_log::log2<CYN_D5>::value + cyn_log::log2<CYN_D4>::value + cyn_log::log2<CYN_D3>::value 
				  + cyn_log::log2<CYN_D2>::value + cyn_log::log2<CYN_D1>::value) + cyn_log::log2<CYN_D0>::value);
    }
    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, |, sc_uint< cyn_log::log2<CYN_D5>::value > )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[J][K][N][M][O][P][Q][R], COMPACT >
//
// Template specialization of cynw_memory_ref for 8D arrays with COMPACT address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D7, int CYN_D6, int CYN_D5, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D7][CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D7][CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::COMPACT >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address * CYN_D6 * CYN_D5 * CYN_D4 * CYN_D3 * CYN_D2 * CYN_D1 * CYN_D0);
    }
    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, +, uint64 )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// cynw_memory_ref< IF, ACCESS[J][K][N][M][O][P][Q][R], SIMPLE >
//
// Template specialization of cynw_memory_ref for 8D arrays with SIMPLE address
// mapping.
//
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D7, int CYN_D6, int CYN_D5, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0 >
class cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D7][CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >
{
  public:
    typedef typename CYN_IF::address_type       address_type;
    typedef typename CYN_IF::data_type          data_type;
    typedef CYN_ACCESS                          access_type;
    typedef CYN_IF                              iface_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >      ref_type;
    typedef cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D7][CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], HLS::SIMPLE >      this_type;

  public:
    cynw_memory_ref( iface_type* iface_p, const address_type& address ) :
        m_address(address), m_iface_p(iface_p)
    {}

    static uint64 calc_address( uint64 address )
    {
      return ((uint64)address << (cyn_log::log2<CYN_D6>::value + cyn_log::log2<CYN_D5>::value + cyn_log::log2<CYN_D4>::value 
				  + cyn_log::log2<CYN_D3>::value + cyn_log::log2<CYN_D2>::value + cyn_log::log2<CYN_D1>::value) 
				  + cyn_log::log2<CYN_D0>::value);
    }
    CYNW_MEM_SQUARE_BRACKETS_INDIRECT( ref_type, m_iface_p, m_address, |, sc_uint< cyn_log::log2<CYN_D6>::value > )
  protected:
    address_type m_address; // Address to be accessed in the memory.
    iface_type*  m_iface_p; // Interface to access memory with.
};

//------------------------------------------------------------------------------
// Address calculation proxy for first-dimension operator[]
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAPPING >
static uint64 cynw_memory_ref_calc_address( cynw_memory_ref< CYN_IF, CYN_ACCESS, CYN_MAPPING >* ref,
					    uint64 address )
{
  return address;
}

//------------------------------------------------------------------------------
// Address calculation proxy for second-dimension operator[]
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D1, int CYN_D0, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAPPING >
static uint64 cynw_memory_ref_calc_address( cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D1][CYN_D0], CYN_MAPPING >* ref,
					    uint64 address )
{
  return cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D1][CYN_D0], CYN_MAPPING >::calc_address(address);
}

//------------------------------------------------------------------------------
// Address calculation proxy for third-dimension operator[]
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D2, int CYN_D1, int CYN_D0, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAPPING >
static uint64 cynw_memory_ref_calc_address( cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >* ref,
					    uint64 address )
{
  return cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >::calc_address(address);
}

//------------------------------------------------------------------------------
// Address calculation proxy for fourth-dimension operator[]
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAPPING >
static uint64 cynw_memory_ref_calc_address( cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D3][CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >* ref,
					    uint64 address )
{
  return cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D3][CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >::calc_address(address);
}

//------------------------------------------------------------------------------
// Address calculation proxy for fifth-dimension operator[]
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAPPING >
static uint64 cynw_memory_ref_calc_address( cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >* ref,
					    uint64 address )
{
  return cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >::calc_address(address);
}

//------------------------------------------------------------------------------
// Address calculation proxy for sixth-dimension operator[]
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D5, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAPPING >
static uint64 cynw_memory_ref_calc_address( cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >* ref,
					    uint64 address )
{
  return cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >::calc_address(address);
}

//------------------------------------------------------------------------------
// Address calculation proxy for seventh-dimension operator[]
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D6, int CYN_D5, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAPPING >
static uint64 cynw_memory_ref_calc_address( cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >* ref,
					    uint64 address )
{
  return cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >::calc_address(address);
}

//------------------------------------------------------------------------------
// Address calculation proxy for eighth-dimension operator[]
//------------------------------------------------------------------------------
template< typename CYN_IF, typename CYN_ACCESS, int CYN_D7, int CYN_D6, int CYN_D5, int CYN_D4, int CYN_D3, int CYN_D2, int CYN_D1, int CYN_D0, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAPPING >
static uint64 cynw_memory_ref_calc_address( cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D7][CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >* ref,
					    uint64 address )
{
  return cynw_memory_ref< CYN_IF, CYN_ACCESS[CYN_D7][CYN_D6][CYN_D5][CYN_D4][CYN_D3][CYN_D2][CYN_D1][CYN_D0], CYN_MAPPING >::calc_address(address);
}

//------------------------------------------------------------------------------
// cynw_memory_ut_port<MEM> - Port providing untimed access to a memory.
//
// The template arguments are:
//    MEM  - A memory family class.
//    ACCESS - The type of values read from and written to the memory.
//
// This port class can be bound to an interface of type cynw_memory_if<>.
// A common application of cynw_memory_ut_port<MEM> is to provide untimed
// access to a memory model from a testbench.  When a cynw_memory_ut_port<MEM>
// is bound to a memory model based on cynw_memory_model_base<MEM>, it accesses
// the untimed impementation of cynw_memory_if<> in that class, and so gives
// untimed access to the memory through the port.
//
// A definition of operator[] is also provided so that array style access can be
// used on the port.
//
// The ACCESS template parameter defines the type of value that will be read from
// and written to the memory.  If this type does not match MEM::data_type, the
// type of value stored in the memory, cynw_interpret<FROM,TO> functions must be
// available to convert between ACCESS and MEM::data_type.
//------------------------------------------------------------------------------
template< typename CYN_MEM, typename CYN_ACCESS=typename CYN_MEM::data_type >
class cynw_memory_ut_port : 
    public sc_port<cynw_memory_if< typename CYN_MEM::address_type, typename CYN_MEM::data_type>, 1>
{
  public:
    typedef typename CYN_MEM::address_type            address_type;
    typedef typename CYN_MEM::data_type               data_type;
    typedef cynw_memory_ut_port<CYN_MEM,CYN_ACCESS>       this_type;
    typedef cynw_memory_ref<this_type,CYN_ACCESS>     ref_type;

  public:
    cynw_memory_ut_port( const char* name )
    {}
    cynw_memory_ut_port()
    {}

    CYNW_MEM_SQUARE_BRACKETS( ref_type )

    inline data_type get( const address_type& address )
    {
        return (*this)->get(address);
    }

    inline void put( const address_type& address, const data_type& data )
    {
        (*this)->put(address, data);
    }

  private: // disabled
    cynw_memory_ut_port( const this_type& );
    this_type& operator = ( const this_type& );
};

//------------------------------------------------------------------------------
// cynw_memory_port - INDEXED AND TYPED ACCESS CLASS FOR MEMORY CLIENTS
//
// The cynw_memory_port class adds operator[] support and type-specific
// support to a memory client port class.  
//
// cynw_memory_port is ordinarily used in memory TOC classes as follows:
//
//  typedef myport< this_type, SETUP, DELAY >         base_port;
//  typedef cynw_memory_port< base_port >             port;
//  typedef cynw_memory_port< base_port, sc_int<D> >  s_port;
//
// where base_port defines the port class itself, port defines a type indexable
// with operator[] using the memory's native type, and 's_port' defines a 
// type indexable with operator[] and using sc_int<D> as an access type.
//
// The LEVEL template argument can be used to control whether a pin-level 
// port implementation or untimed implementation is used.  
//------------------------------------------------------------------------------
template < typename CYN_PORT, typename CYN_ACCESS=typename CYN_PORT::data_type, typename LEVEL=CYN::PIN >
class cynw_memory_port : public CYN_PORT
{
  public:
    typedef cynw_memory_port<CYN_PORT,CYN_ACCESS>             this_type;
    typedef cynw_memory_ref< this_type, CYN_ACCESS >      ref_type;
    typedef typename CYN_PORT::data_type                  data_type;
    typedef typename CYN_PORT::address_type               address_type;

    cynw_memory_port()
    {}
    cynw_memory_port( const char* name ) : CYN_PORT(name)
    {}

    CYNW_MEM_SQUARE_BRACKETS( ref_type )
};

//------------------------------------------------------------------------------
// cynw_memory_port< PORT, ACCESS, CYN::TLM > - SPECIALIZATION FOR TLM MEMORY ACCESS
//
// This partial template specialization that causes declarations
// of the form:
//
//   cynw_memory_port< base_port, access_type, CYN::TLM >
//
// to be equivalent to:
//
//   cynw_memory_ut_port< base_port >
//
//------------------------------------------------------------------------------
template < typename CYN_PORT, typename CYN_ACCESS >
class cynw_memory_port<CYN_PORT,CYN_ACCESS,CYN::TLM> 
   : public cynw_memory_ut_port< typename CYN_PORT::if_type, CYN_ACCESS >
{
  public:
    typedef cynw_memory_port<CYN_PORT,CYN_ACCESS,CYN::TLM>    this_type;
    typedef cynw_memory_ref< this_type, CYN_ACCESS >      ref_type;
    typedef typename CYN_PORT::data_type                  data_type;
    typedef typename CYN_PORT::address_type               address_type;

    cynw_memory_port()
    {}
    cynw_memory_port( const char* name ) : cynw_memory_ut_port<CYN_PORT,CYN_ACCESS>(name)
    {}
};



//------------------------------------------------------------------------------
// cynw_memory_model_base - BASE CLASS FOR MEMORY MODELS
//
// This class implements the core of a memory model for a given memory class
// including storage allocation, and an untimed implementation of get() and
// put() from cynw_memory_if<>.   It also adds operator[] support for 
// direct, untimed access to the memory.
//
// cynw_memory_model_base is suitable for use as a base class for either an
// RTL memory model, or an untimed model.  This class is not derived from
// sc_module or sc_primitive channel, defering that priviledge to the derived
// class.
//
// An untimed memory model can be defined by either instantiating this class
// directly for a given memory family class, or by deriving a subclass from it.
//
// A pin-accurate memory model can be defined by deriving from 
// cynw_memory_model_base<MEM> and adding signal-level port definitions and a 
// thread to operate the protocol at the ports.  For example:
/*
  template <typename MEM>
  class ramA_model :
      public sc_module,
      public cynw_memory_model_base<MEM>
  {
    public:
      typedef ramA_model<MEM>         this_type;

    public:
      SC_CTOR(ramA_model) {
          // Setup an thread to operate the model's interface.
          SC_METHOD(operate);
          sensitive << CLK.pos();
      }
      void operate()
      {
          // Main execution thread.
          if ( CE.read() ) {
              if ( WE ) {
                  put( ADDR.read(), DIN.read() );
              } else {
                  DOUT = get( ADDR.read() );
              }
          }
      }
    public:
      // Define signal-level ports.
      sc_in_clk                   CLK;        
      sc_in<address_type>         ADDR;      
      sc_in<bool>                 CE;       
      sc_out<data_type>           DOUT;    
      sc_in<data_type>            DIN;    
      sc_in<bool>                 WE;    
  };

 */
//
// Either an untimed or a pin-accurate model based on cynw_memory_model_base<MEM>
// can be accessed in an untimed fashion via its cynw_memory_if<> implementation.
//
//------------------------------------------------------------------------------
template< typename CYN_MEM >
class cynw_memory_model_base 
    : public cynw_memory_if< typename CYN_MEM::address_type, typename CYN_MEM::data_type >
{
  public:
    typedef typename CYN_MEM::address_type               address_type;
    typedef typename CYN_MEM::data_type                  data_type;
    typedef cynw_memory_model_base<CYN_MEM>              this_type;
    typedef cynw_memory_ref< this_type, data_type >  ref_type;

    CYNW_MEM_SQUARE_BRACKETS( ref_type )

    cynw_memory_model_base<CYN_MEM>(const char* name=0)
    {}
    virtual ~cynw_memory_model_base<CYN_MEM>() 
    {}

  public: // cynw_memory_interface methods:
    virtual data_type get( const address_type& address )
    {
        return m_memory[address];
    }

    virtual void put( const address_type& address, 
                      const data_type& data ) 
    {
        m_memory[address] = data;
    }

    virtual void reset()
    {}
    
  protected:
    data_type m_memory[CYN_MEM::SIZE];  // Storage for memory.

  private:
    cynw_memory_model_base( const cynw_memory_model_base<CYN_MEM>& );
    void operator = ( const cynw_memory_model_base<CYN_MEM>& );
};

#if defined(__GNUC__) && BDW_USE_SCV
//------------------------------------------------------------------------------
// cynw_scv_memory_tx<AT,DT> - Memory transaction class.
//
// The template arguments are:
//    AT  - The address type of the memory.
//    DT  - The data type of the memory.
//
// Stores information related to an SCV transaction on a memory.
// This class is suitable for storing the information relative to a transaction
// on a memory after it has been started, and before it has finished.
//------------------------------------------------------------------------------
template< typename CYN_AT, typename CYN_DT >
struct cynw_scv_memory_tx
{
	typedef CYN_AT      address_type;
	typedef CYN_DT      data_type;

	bool			rw;	 // True if read, false if write. 
	scv_tr_handle	tx;  // SCV transaction handle.
	address_type	addr;// Address value.
	data_type		data;// Data value.

	cynw_scv_memory_tx()
		: rw(0), addr(0)
	{}

	cynw_scv_memory_tx( const cynw_scv_memory_tx<address_type,data_type>& other )
		: rw(other.rw), tx(other.tx), addr(other.addr), data(other.data)
	{}

	cynw_scv_memory_tx( bool rw_in, scv_tr_handle tx_in, address_type addr_in, data_type data_in )
		: rw(rw_in), tx(tx_in), addr(addr_in), data(data_in)
	{}

	cynw_scv_memory_tx< address_type, data_type >& operator=( const cynw_scv_memory_tx< address_type, data_type >& other )
	{
		rw = other.rw;
		tx = other.tx;
		addr = other.addr;
		data = other.data;
		return *this;
	}

	// Returns true if the transaction is valid and active.
	bool is_active()
	{
		return ( tx.is_valid() && tx.is_active() );
	}

};

//------------------------------------------------------------------------------
// cynw_scv_memory_tx_stream<AT,DT> - SCV transaction stream for memories
//
// The template arguments are:
//    AT  - The address type of the memory.
//    DT  - The data type of the memory.
//
// Stores an scv_tr_stream, and generators for read and write transactions
// for a memory with the given address and data type.  A memory model will 
// typically contain a stream for each access port.
//------------------------------------------------------------------------------
template< typename CYN_AT, typename CYN_DT >
struct cynw_scv_memory_tx_stream
{
	typedef CYN_AT      address_type;
	typedef CYN_DT      data_type;
	typedef cynw_scv_logging<address_type>                address_log_type;
	typedef cynw_scv_logging<data_type>                   data_log_type;
	typedef cynw_scv_memory_tx< address_type, data_type > tx_t;

	cynw_scv_memory_tx_stream( const char* name, scv_tr_db* db )
	{
		if ( db != 0 ) {
			m_stream = new scv_tr_stream( name, "cynw_memory", db );
			m_read_gen = new scv_tr_generator< address_type, data_type >( "read", *m_stream, "address", "data" );
			m_write_gen = new scv_tr_generator< address_type, data_type >( "write", *m_stream, "address", "data" );
		} else {
			m_stream = 0;
			m_read_gen = 0;
			m_write_gen = 0;
		}
	}

	~cynw_scv_memory_tx_stream()
	{
		delete m_stream;
		delete m_read_gen;
		delete m_write_gen;
	}

	// Returns 'true' if a valid database was used to construct the object.
	bool enabled()
	{
		return (m_stream != 0);
	}

	// Write the start of a write transaction, and return a populated tx_t struct for it.
	tx_t begin_write_tx( const address_type& addr, const data_type& data )
	{
		tx_t tx;

		if (enabled()) {
			tx.addr = addr;
			tx.data = data;
			tx.rw = false;
			tx.tx = m_write_gen->begin_transaction( address_log_type::attrib_value(addr) );
		}
		
		return tx;
	}

	// Write the start of a read transaction, and return a populated tx_t struct for it.
	tx_t begin_read_tx( const address_type& addr )
	{
		tx_t tx;

		if (enabled()) {
			tx.addr = addr;
			tx.data = 0;
			tx.rw = true;
			tx.tx = m_read_gen->begin_transaction( address_log_type::attrib_value(addr) );
		}
		
		return tx;
	}

	// Write the end of a write transaction.
	void end_write_tx( tx_t& tx )
	{
		if (enabled()) {
			m_write_gen->end_transaction( tx.tx, data_log_type::attrib_value(tx.data) );
		}
	}

	// Write the end of a read transaction.
	void end_read_tx( tx_t& tx, const data_type& data )
	{
		if (enabled()) {
			m_read_gen->end_transaction( tx.tx, data_log_type::attrib_value(data) );
		}
	}

	// Write the end of either a read or a write transaction depending on the contents of 'tx'.
	// The 'data' param is only used for reads.
	void end_tx( tx_t& tx, const data_type& data )
	{
		if (enabled()) {
			if (tx.rw) {
				end_read_tx( tx, data );
			} else {
				end_write_tx( tx );
			}
		}
	}
	
	// Generate a zero-length write transaction.
	void gen_write_tx( const address_type& addr, const data_type& data )
	{
		if (enabled()) {
			scv_tr_handle tx = m_write_gen->begin_transaction( address_log_type::attrib_value(addr) );;
			m_write_gen->end_transaction( tx, data_log_type::attrib_value(data) );;
		}
	}

	// Generate a zero-length read transaction.
	void gen_read_tx( const address_type& addr, const data_type& data )
	{
		if (enabled()) {
			scv_tr_handle tx = m_read_gen->begin_transaction( address_log_type::attrib_value(addr) );;
			m_read_gen->end_transaction( tx, data_log_type::attrib_value(data) );;
		}
	}

	scv_tr_stream* m_stream;
	scv_tr_generator< typename address_log_type::attrib_type, typename data_log_type::attrib_type >* m_read_gen;
	scv_tr_generator< typename address_log_type::attrib_type, typename data_log_type::attrib_type >* m_write_gen;
};
#else

#ifdef STRATUS_VLG
class scv_tr_db;
#endif

//------------------------------------------------------------------------------
//
// Stub versions of SCV memory logging classes for use when either SCV is not aviablable,
// or when processing with a Cynthesizer application.
//
//------------------------------------------------------------------------------
template< typename CYN_AT, typename CYN_DT >
struct cynw_scv_memory_tx
{
	typedef CYN_AT      address_type;
	typedef CYN_DT      data_type;

	cynw_scv_memory_tx()
	{}

	cynw_scv_memory_tx( const cynw_scv_memory_tx<address_type,data_type>& other )
	{}

	// Returns true if the transaction is valid and active.
	bool is_active()
	{
		return false;
	}
};

template< typename CYN_AT, typename CYN_DT >
struct cynw_scv_memory_tx_stream
{
	typedef CYN_AT      address_type;
	typedef CYN_DT      data_type;
	typedef cynw_scv_memory_tx< address_type, data_type > tx_t;

	cynw_scv_memory_tx_stream( const char* name, scv_tr_db* db )
	{}
	bool enabled()
	{
		return false;
	}
	tx_t begin_write_tx( const address_type& addr, const data_type& data )
	{
		tx_t tx;
		return tx;
	}
	tx_t begin_read_tx( const address_type& addr )
	{
		tx_t tx;
		return tx;
	}
	void end_write_tx( tx_t& tx ) {}
	void end_read_tx( tx_t& tx, const data_type& data ) { }
	void end_tx( tx_t& tx, const data_type& data ) {}
	void gen_write_tx( const address_type& addr, const data_type& data ) {}
	void gen_read_tx( const address_type& addr, const data_type& data ) {}
};
#endif

// MATHEMATICS OPERATORS:

#define CYNW_MEM_MATH_OPERATORS(OP) \
template< typename CYN_IF1, int CYN_W1, typename CYN_IF2, int CYN_W2, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP1, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP2 > \
inline int64 operator OP (  \
        const cynw_memory_ref<CYN_IF1,sc_int<CYN_W1>,CYN_MAP1 >& a, \
        const cynw_memory_ref<CYN_IF2,sc_int<CYN_W2>,CYN_MAP2 >& b) \
{ \
        return a.value() OP b.value(); \
} \
 \
template< typename CYN_IF1, int CYN_W1, typename CYN_IF2, int CYN_W2, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP1, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP2  > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF1,sc_uint<CYN_W1>,CYN_MAP1 >& a, \
        const cynw_memory_ref<CYN_IF2,sc_uint<CYN_W2>,CYN_MAP2 >& b) \
{ \
        return a.value() OP b.value(); \
} \
 \
template< typename CYN_IF1, int CYN_W1, typename CYN_IF2, int CYN_W2, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP1, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP2  > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF1,sc_int<CYN_W1>,CYN_MAP1 >& a, \
        const cynw_memory_ref<CYN_IF2,sc_uint<CYN_W2>,CYN_MAP2 >& b) \
{ \
        return a.value() OP b.value(); \
} \
 \
template< typename CYN_IF1, int CYN_W1, typename CYN_IF2, int CYN_W2, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP1, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP2  > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF1,sc_uint<CYN_W1>,CYN_MAP1 >& a, \
        const cynw_memory_ref<CYN_IF2,sc_int<CYN_W2>,CYN_MAP2 >& b) \
{ \
        return a.value() OP b.value(); \
} \
 \
 \
 \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        char b ) \
{ \
        return a.value() OP b; \
} \
 \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        char a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        short b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        short a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        int b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        int a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        long b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        long a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        int64 b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        int64 a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        unsigned char b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        unsigned char a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        unsigned short b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        unsigned short a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        unsigned int b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        unsigned int a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        unsigned long b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        unsigned long a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        uint64 b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        uint64 a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
 \
 \
 \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline int64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        char b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline int64 operator OP (  \
        char a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline int64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        short b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline int64 operator OP (  \
        short a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline int64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        int b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline int64 operator OP (  \
        int a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline int64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        long b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline int64 operator OP (  \
        long a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline int64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        int64 b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline int64 operator OP (  \
        int64 a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline int64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        unsigned char b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        unsigned char a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        unsigned short b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        unsigned short a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        unsigned int b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        unsigned int a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        unsigned long b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        unsigned long a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        uint64 b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
inline uint64 operator OP (  \
        uint64 a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
}

// BOOLEAN OPERATORS:

#define CYNW_MEM_BOOLEAN_OPERATORS(OP) \
template< typename CYN_IF1, int CYN_W1, typename CYN_IF2, int CYN_W2, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP1, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP2  > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF1,sc_int<CYN_W1>,CYN_MAP1 >& a, \
        const cynw_memory_ref<CYN_IF2,sc_int<CYN_W2>,CYN_MAP2 >& b) \
{ \
        return a.value() OP b.value(); \
} \
 \
template< typename CYN_IF1, int CYN_W1, typename CYN_IF2, int CYN_W2, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP1, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP2  > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF1,sc_uint<CYN_W1>,CYN_MAP1 >& a, \
        const cynw_memory_ref<CYN_IF2,sc_uint<CYN_W2>,CYN_MAP2 >& b) \
{ \
        return a.value() OP b.value(); \
} \
 \
template< typename CYN_IF1, int CYN_W1, typename CYN_IF2, int CYN_W2, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP1, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP2  > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF1,sc_int<CYN_W1>,CYN_MAP1 >& a, \
        const cynw_memory_ref<CYN_IF2,sc_uint<CYN_W2>,CYN_MAP2 >& b) \
{ \
        return a.value() OP b.value(); \
} \
 \
template< typename CYN_IF1, int CYN_W1, typename CYN_IF2, int CYN_W2, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP1, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP2  > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF1,sc_uint<CYN_W1>,CYN_MAP1 >& a, \
        const cynw_memory_ref<CYN_IF2,sc_int<CYN_W2>,CYN_MAP2 >& b) \
{ \
        return a.value() OP b.value(); \
} \
 \
 \
 \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        char b ) \
{ \
        return a.value() OP b; \
} \
 \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        char a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        short b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        short a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        int b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        int a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        long b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        long a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        int64 b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        int64 a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        unsigned char b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        unsigned char a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        unsigned short b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        unsigned short a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        unsigned int b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        unsigned int a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        unsigned long b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        unsigned long a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& a, \
        uint64 b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        uint64 a, \
        const cynw_memory_ref<CYN_IF,sc_uint<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
 \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        char b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        char a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        short b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        short a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        int b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        int a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        long b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        long a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        int64 b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        int64 a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        unsigned char b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        unsigned char a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        unsigned short b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        unsigned short a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        unsigned int b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        unsigned int a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        unsigned long b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        unsigned long a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& a, \
        uint64 b ) \
{ \
        return a.value() OP b; \
} \
template< typename CYN_IF, int CYN_W, HLS::HLS_INDEX_MAPPING_OPTIONS CYN_MAP > \
bool operator OP (  \
        uint64 a, \
        const cynw_memory_ref<CYN_IF,sc_int<CYN_W>,CYN_MAP >& b ) \
{ \
        return a OP b.value(); \
}

CYNW_MEM_MATH_OPERATORS(+)
CYNW_MEM_MATH_OPERATORS(-)
CYNW_MEM_MATH_OPERATORS(*)
CYNW_MEM_MATH_OPERATORS(/)
CYNW_MEM_MATH_OPERATORS(%)
CYNW_MEM_MATH_OPERATORS(&)
CYNW_MEM_MATH_OPERATORS(|)
CYNW_MEM_MATH_OPERATORS(^)

CYNW_MEM_BOOLEAN_OPERATORS(==)
CYNW_MEM_BOOLEAN_OPERATORS(!=)
CYNW_MEM_BOOLEAN_OPERATORS(<)
CYNW_MEM_BOOLEAN_OPERATORS(<=)
CYNW_MEM_BOOLEAN_OPERATORS(>)
CYNW_MEM_BOOLEAN_OPERATORS(>=)

#undef CYNW_MEM_MATH_OPERATORS
#undef CYNW_MEM_BOOLEAN_OPERATORS

#endif // Cynw_Memory_H_INCLUDED

