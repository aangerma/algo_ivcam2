/**************************************************************************
**
** This file is part of the Cynthesizer (TM) software product and is protected 
** by law including United States copyright laws, international treaty 
** provisions, and other applicable laws.
**
** Copyright (c) 2013 Forte Design Systems and / or its subsidiary(-ies).  All
rights reserved.
**
** This file may only be used under the terms of an active Cynthesizer Software 
** License Agreement (SLA) and only for the limited "Purpose" stated in
that
** agreement. All clauses in the SLA apply to the contents of this file,
** including, but not limited to, Confidentiality, License rights, Warranty
** and Limitation of Liability.

** If you have any questions regarding the use of this file, please contact
** Forte Design Systems at: Sales@ForteDS.com
**
***************************************************************************/
//
// Support for safe access to types for SCV logging
//
// A given type may or may not have had SCV extensions defined for it.
// When emitting SCV logging code for a type in an IP class that has a
// user-specified or templated data type, it is not possible to know from
// that IP class whether SCV extensions have been defined for it.  
// 
// The cynw_scv_logging<> classes provide a mechanism that allows SCV logging
// to be setup safely for any type that is also known to have supporting functions
// required for sc_signal.  Specifically, any type that has either SCV extensions
// defined, or has an opertor<<( ostream& ); defined is supported.  The SCV
// extensions will be used if available, and the operator<< wil be used as a 
// fallback, and "string" will be used as the logging type.
//
// To enable a type for auto logging using its SCV extensions, a macro definition
// must be made for it.  If the type is not templated, the CYNW_ENABLE_SCV_LOGGING
// macro must be used as follows:
//
//   struct mystruct {
//      sc_uint<8> a;
//      sc_uint<8> d;
//   };
//
//   SCV_EXTENSIONS(mystruct) {
//   public:
//     scv_extensions< sc_uint<8> > addr;
//     scv_extensions< sc_uint<8> > data;
//     SCV_EXTENSIONS_CTOR(mystruct) {
//       SCV_FIELD(addr);
//       SCV_FIELD(data);
//     }
//   };
//
//   CYNW_ENABLE_SCV_LOGGING(mystruct)
// 
// The "CYNW_ENABLE_SCV_LOGGING(mystruct)" statement is a statement that SCV extensions exist.
//
// If the type is templated, the CYNW_ENABLE_SCV_LOGGING_TEMPLATE macro must be used instead.
// For example: 
//
//   template <int N>
//   struct mystruct {
//      sc_uint<N> a;
//      sc_uint<N> d;
//   };
//   ...
//   
//   template <int N>
//   CYNW_ENABLE_SCV_LOGGING( mystruct<N> )
//
// 
// When setting up logging for an anonymous type, the SCV API should be used as follows:
//
//  // Declare a generator whose start type is the template parameter T:
//  scv_tr_generator< cynw_scv_logging<T>::attrib_type >* gen;
//
//  // Being a transaction with the start attribute value of type T in variable 'val' :
//  gen->begin_transaction( cynw_scv_logging<T>::attrib_value(val) );
//

#ifndef ESC_SCV_HEADER_GUARD__
#define ESC_SCV_HEADER_GUARD__

#include <systemc.h>
#include <string>
#include <sstream>

class scv_tr_db;

#if BDW_HUB

/*!
  \brief Returns the currently open SCV transaction database.
*/
scv_tr_db* esc_get_scv_tr_db();

/*!
  \brief Sets the database to be used for SCV transaction logging.
*/
void esc_set_scv_tr_db( scv_tr_db* db );

/*!
  \brief Initializes SCV transaction logging

  After this function is called, if SCV logging has been enabled, and
  is supported by the current execution environment, the SCV transaction
  logging API can be used to log transactions.
*/
scv_tr_db* esc_open_scv_tr_db();

// This function is static so that it will be sensitive to BDW_USE_SCV in 
// the end user's environment rather than the configuration-time environment.
inline bool esc_enable_scv_logging();


#if BDW_USE_SCV

#include <scv.h>
#include <scv_tr_fsdb.h>

template <typename T>
struct cynw_scv_logging {
	enum {converts_type=1};
	typedef sc_string attrib_type;
	static attrib_type attrib_value( const T& value )
	{
		std::ostringstream str;
		str << value << ends;
		return sc_string(str.str());
	}

	template <int CYN_N>
	static void convert( const T (&inval)[CYN_N], attrib_type (&outval)[CYN_N] ) {
		for (int i=0; i<CYN_N; i++) {
				outval[i] = attrib_value(inval[i]);
		}
	};
	
	template <int CYN_N, int CYN_M>
	static void convert( const T (&inval)[CYN_N][CYN_M], attrib_type (&outval)[CYN_N][CYN_M] ) {
		for (int i=0; i<CYN_N; i++) {
			for (int j=0; i<CYN_M; i++) {
				outval[i][j] = attrib_value(inval[i][j]);
			}
		}
	};

	static void record_attrib( scv_tr_handle m_tx, const char* name, const T &a ) { 
		m_tx.record_attribute( name, attrib_value(a) );
	} 

	template <int CYN_N> 
	static void record_attrib( scv_tr_handle m_tx, const char* name, const T (&a)[CYN_N] ) {
		typename cynw_scv_logging<T>::attrib_type ca[CYN_N];
		cynw_scv_logging<T>::convert( a, ca );
		m_tx.record_attribute( name, ca );
	};
	
	template <int CYN_N, int CYN_M> 
	static void record_attrib( scv_tr_handle m_tx, const char* name, const T (&a)[CYN_N][CYN_M] ) {
		typename cynw_scv_logging<T>::attrib_type ca[CYN_N][CYN_M];
		cynw_scv_logging<T>::convert( a, ca );
		m_tx.record_attribute( name, ca );
	}
};

#define CYNW_ENABLE_SCV_LOGGING_TEMPLATE(...) \
  struct cynw_scv_logging< __VA_ARGS__ > { \
    enum {converts_type=0}; \
    typedef __VA_ARGS__ attrib_type; \
    static attrib_type attrib_value( const __VA_ARGS__& value ) \
    { \
		return value; \
    } \
	template <int CYN_N> \
	static void convert( const __VA_ARGS__ (&inval)[CYN_N], __VA_ARGS__ (&outval)[CYN_N] ) { \
		for (int i=0; i<CYN_N; i++) { \
				outval[i] = attrib_value(inval[i]); \
		} \
	} \
	 \
	template <int CYN_N, int CYN_M> \
	static void convert( const __VA_ARGS__ (&inval)[CYN_N][CYN_M], __VA_ARGS__ (&outval)[CYN_N][CYN_M] ) { \
		for (int i=0; i<CYN_N; i++) { \
			for (int j=0; i<CYN_M; i++) { \
				outval[i][j] = attrib_value(inval[i][j]); \
			} \
		} \
	} \
	static void record_attrib( scv_tr_handle m_tx, const char* name, const __VA_ARGS__ &a ) { \
		m_tx.record_attribute( name, a ); \
	} \
	template <int CYN_N> \
	static void record_attrib( scv_tr_handle m_tx, const char* name, const __VA_ARGS__ (&a)[CYN_N] ) { \
		m_tx.record_attribute( name, a ); \
	} \
	template <int CYN_N, int CYN_M> \
	static void record_attrib( scv_tr_handle m_tx, const char* name, const __VA_ARGS__ (&a)[CYN_N][CYN_M] ) { \
		m_tx.record_attribute( name, a ); \
	} \
  }

#define CYNW_ENABLE_SCV_LOGGING(type) \
  template <> \
  CYNW_ENABLE_SCV_LOGGING_TEMPLATE(type)


/* Enable logging for intrinsic types.
 */
CYNW_ENABLE_SCV_LOGGING(bool);
CYNW_ENABLE_SCV_LOGGING(char);
CYNW_ENABLE_SCV_LOGGING(unsigned char);
CYNW_ENABLE_SCV_LOGGING(short);
CYNW_ENABLE_SCV_LOGGING(unsigned short);
CYNW_ENABLE_SCV_LOGGING(int);
CYNW_ENABLE_SCV_LOGGING(unsigned int);
CYNW_ENABLE_SCV_LOGGING(long);
CYNW_ENABLE_SCV_LOGGING(unsigned long);
CYNW_ENABLE_SCV_LOGGING(long long);
CYNW_ENABLE_SCV_LOGGING(unsigned long long);
CYNW_ENABLE_SCV_LOGGING(float);
CYNW_ENABLE_SCV_LOGGING(double);
CYNW_ENABLE_SCV_LOGGING(std::string);

/* Enable logging for un-templated SystemC types. 
 */
CYNW_ENABLE_SCV_LOGGING(sc_bit);
CYNW_ENABLE_SCV_LOGGING(sc_logic);
CYNW_ENABLE_SCV_LOGGING(sc_signed);
CYNW_ENABLE_SCV_LOGGING(sc_unsigned);
CYNW_ENABLE_SCV_LOGGING(sc_int_base);
CYNW_ENABLE_SCV_LOGGING(sc_uint_base);
CYNW_ENABLE_SCV_LOGGING(sc_lv_base);
CYNW_ENABLE_SCV_LOGGING(sc_bv_base);


/* Enable logging for sized bit vector SystemC types. 
 */
template <int W> CYNW_ENABLE_SCV_LOGGING_TEMPLATE( sc_uint<W> );
template <int W> CYNW_ENABLE_SCV_LOGGING_TEMPLATE( sc_int<W> );
template <int W> CYNW_ENABLE_SCV_LOGGING_TEMPLATE( sc_biguint<W> );
template <int W> CYNW_ENABLE_SCV_LOGGING_TEMPLATE( sc_bigint<W> );
template <int W> CYNW_ENABLE_SCV_LOGGING_TEMPLATE( sc_bv<W> );
template <int W> CYNW_ENABLE_SCV_LOGGING_TEMPLATE( sc_lv<W> );

/* Enable logging for cynw_float 
 */
/*!
  \brief Enables SCV logging and opens a database if one has not already been opened.

  If SCV logging is enabled and the database is successfully opened, returns true.
*/
inline bool esc_enable_scv_logging()
{
	if ( esc_trace_is_enabled( esc_trace_scv ) ) 
	{
		if ( !esc_get_scv_tr_db() )
			esc_open_scv_tr_db();

		return esc_get_scv_tr_db();
	} else {
		return false;
	}
}
#else
inline bool esc_enable_scv_logging()
{
	return false;
}
#endif

#else

inline scv_tr_db* esc_get_scv_tr_db()
{
  return 0;
}

inline void esc_set_scv_tr_db( scv_tr_db* db )
{
}

inline scv_tr_db* esc_open_scv_tr_db()
{
  return 0;
}

inline bool esc_enable_scv_logging()
{
	return false;
}

#endif

#endif // ESC_SCV_HEADER_GUARD__
