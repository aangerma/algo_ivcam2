/**************************************************************************
**
** This file is part of the Cynthesizer (TM) software product and is protected 
** by law including United States copyright laws, international treaty 
** provisions, and other applicable laws.
**
** Copyright (c) 2012 Forte Design Systems and / or its subsidiary(-ies).  All
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

#ifndef ESC_TRANS_HEADER_GUARD__
#define ESC_TRANS_HEADER_GUARD__

/*!
  \file esc_trans.h
  \brief This file contains the built-in HUB-to/from-SystemC translation functions.
*/


#if BDW_HUB

#include "v_trans.h"


//
// ----------------------------------------
// RAVE time <--> sc_time
// ----------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  sc_time* v,
						  int index=-1,
						  int flags=0 )
{
    double rave_time;

	if( index > -1 )
		qbhIndexedGetTimeValue( h, index, &rave_time );
	else
	    qbhGetTimeValue( h, &rave_time );

	*v = sc_time( rave_time, SC_PS );
}

/*!
  \brief Gets the Hub type for an sc_time *
  \param v Any sc_time *, can be null
  \return The qbhTypeHandle for an sc_time *
*/
inline qbhTypeHandle HubGetType( sc_time* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
    	qbhGetType( "time", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( sc_time* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
    double dval = esc_normalize_to_ps(*v);
	if( index > -1 )
		qbhIndexedSetTimeValue( *h, index, dval );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetTimeValue( *h, dval );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( sc_time* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( sc_time* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeTime( buffer, esc_normalize_to_ps(*v) );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( sc_time* v,
						  char* buffer )
{
	sprintf( buffer, "%g", esc_normalize_to_ps(*v) );
}

//
// ----------------------------------------
// RAVE time <--> sc_time
// ----------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  const sc_time* v,
						  int index=-1,
						  int flags=0 )
{
	esc_report_error( esc_error, "HubTransFrom() called on a const sc_time*\n" );
}

/*!
  \brief Gets the Hub type for a const sc_time *
  \param v Any const sc_time *, can be null
  \return The qbhTypeHandle for a const sc_time *
*/
inline qbhTypeHandle HubGetType( const sc_time* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
    	qbhGetType( "time", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( const sc_time* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
    double dval = esc_normalize_to_ps(*v);
	if( index > -1 )
		qbhIndexedSetTimeValue( *h, index, dval );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetTimeValue( *h, dval );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( const sc_time* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( const sc_time* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeTime( buffer, esc_normalize_to_ps(*v) );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( const sc_time* v,
						  char* buffer )
{
	sprintf( buffer, "%g", esc_normalize_to_ps(*v) );
}

//
// ----------------------------------------
// RAVE time <--> sc_time*
// ----------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  sc_time** v,
						  int index=-1,
						  int flags=0 )
{
	HubTransFrom(h,*v,index,flags);
}

/*!
  \brief Gets the Hub type for a sc_time **
  \param v Any sc_time **, can be null
  \return The qbhTypeHandle for a sc_time **
*/
inline qbhTypeHandle HubGetType( sc_time** v )
{
    return HubGetType( *v );
}

/*!
  \brief Gets the Hub type for a const sc_time **
  \param v Any const sc_time **, can be null
  \return The qbhTypeHandle for a const sc_time **
*/
inline qbhTypeHandle HubGetType( const sc_time** v )
{
    return HubGetType( *v );
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( sc_time** v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	HubTransTo( *v, h, index, flags );
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( sc_time** v )
{
	HubCleanupValue( *v );
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( sc_time** v,
						  qbhEventBuffer* buffer )
{
	HubEncodeTdb( *v, buffer );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( sc_time** v,
						  char* buffer )
{
	HubEncodeCsv( *v, buffer );
}

//
// ----------------------------------------
// RAVE bit <--> sc_bit
// ----------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  sc_bit* v,
						  int index=-1,
						  int flags=0 )
{
	char rave_bit;
	if( index > -1 )
		qbhIndexedGetBitValue( h, index, &rave_bit );
	else
	    qbhGetBitValue( h, &rave_bit );
    *v = rave_bit;
}

/*!
  \brief Gets the Hub type for an sc_bit *
  \param v Any sc_bit *, can be null
  \return The qbhTypeHandle for an sc_bit *
*/
inline qbhTypeHandle HubGetType( sc_bit* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
    	qbhGetType( "bit", &typeh );
    return typeh;
}

/*!
  \brief Gets the Hub type for a const sc_bit *
  \param v Any const sc_bit *, can be null
  \return The qbhTypeHandle for a const sc_bit *
*/
inline qbhTypeHandle HubGetType( const sc_bit* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
    	qbhGetType( "bit", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( sc_bit* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	char rave_bit = v->to_char();

	if( index > -1 )
		qbhIndexedSetBitValue( *h, index, rave_bit );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetBitValue( *h, rave_bit );
	}
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( sc_bit* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeBit(buffer,v->to_char());
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( sc_bit* v,
						  char* buffer )
{
	sprintf( buffer, "%c", v->to_char() );
}

//
// ----------------------------------------
// RAVE bit <--> bool
// ----------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  bool* v,
						  int index=-1,
						  int flags=0 )
{
	char rave_bit;
	if( index > -1 )
		qbhIndexedGetBitValue( h, index, &rave_bit );
	else
	    qbhGetBitValue( h, &rave_bit );
    *v = ( rave_bit == '1' ) ? true : false;
}

/*!
  \brief Gets the Hub type for a bool *
  \param v Any bool *, can be null
  \return The qbhTypeHandle for a bool *
*/
inline qbhTypeHandle HubGetType( bool* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
    	qbhGetType( "bit", &typeh );
    return typeh;
}

/*!
  \brief Gets the Hub type for a const bool *
  \param v Any const bool *, can be null
  \return The qbhTypeHandle for a const bool *
*/
inline qbhTypeHandle HubGetType( const bool* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
    	qbhGetType( "bit", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( bool* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	char rave_bit = (char)*v ? '1' : '0';

	if( index > -1 )
		qbhIndexedSetBitValue( *h, index, rave_bit );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetBitValue( *h, rave_bit );
	}
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( bool* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeBit(buffer,(char)*v ? '1' : '0');
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( bool* v,
						  char* buffer )
{
	sprintf( buffer, "%c", (char)*v ? '1' : '0' );
}

//
// ----------------------------------------
// RAVE bitvector  <--> sc_bv<>
// ----------------------------------------
//
/*!
  \brief Gets the Hub type for an sc_bv *
  \param v Any sc_bv *, can be null
  \return The qbhTypeHandle for an sc_bv *
*/
template <int W>
inline qbhTypeHandle HubGetType( sc_bv<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Gets the Hub type for a const sc_bv *
  \param v Any const sc_bv *, can be null
  \return The qbhTypeHandle for a const sc_bv *
*/
template <int W>
inline qbhTypeHandle HubGetType( const sc_bv<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransFrom( qbhValueHandle h,
						  sc_bv<W>* v,
						  int index=-1,
						  int flags=0 )
{
	int length = W + 1;  // + 1 to accomodate returned '\0'

    // grab value from HUB
    char vstring[W+1];   // character array to receive bit array
	vstring[W] = '\0';

	// Check for operation value index:
	if( index > -1 )
	{ qbhIndexedGetBitVectorValue( h, index, vstring, &length ); }
	else
	{ qbhGetBitVectorValue( h, vstring, &length ); } // adds '\0'

	// Strip Xs and Zs from the string
	for ( int i = 0 ; i < W ; i++ )
	{
		if ( vstring[i] != '0' && vstring[i] != '1' )
			vstring[i] = '0';
	}

	*v = vstring;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransTo( sc_bv<W>* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	int length = W;

	char vstring[W+1];

	// HUB values are stored [0:7] (MSB to LSB):
    for(int i = 0; i < length; i++ )
    {
	    vstring[length-i-1] = v->get_bit(i) + '0';
    }
	vstring[W] = '\0';

	// Check for an operation value index:
	if( index > -1 )
		qbhIndexedSetBitVectorValue( *h, index, vstring, length );

	// Otherwise, just set the given value:
	else
	{ 
		qbhCreateValue( HubGetType(v), h );
		qbhSetBitVectorValue( *h, vstring, length );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
template <int W>
inline void HubCleanupValue( sc_bv<W>* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
template <int W>
inline void HubEncodeTdb( sc_bv<W>* v,
						  qbhEventBuffer* buffer )
{
	int length = W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
    {
	    vstring[length-i-1] = v->get_bit(i) + '0';
    }
	vstring[W] = '\0';

	qbhTdbEncodeBitVector( buffer, vstring );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
template <int W>
inline void HubEncodeCsv( sc_bv<W>* v,
						  char* buffer )
{
	int length = W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
    {
	    vstring[length-i-1] = v->get_bit(i) + '0';
    }
	vstring[W] = '\0';

	sprintf( buffer, "%s", vstring );
}

//
// ----------------------------------------
// RAVE bitvector  <--> sc_lv<>
// ----------------------------------------
//
/*!
  \brief Gets the Hub type for a sc_lv *
  \param v Any sc_lv *, can be null
  \return The qbhTypeHandle for a sc_lv *
*/
template <int W>
inline qbhTypeHandle HubGetType( sc_lv<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Gets the Hub type for a const sc_lv *
  \param v Any const sc_lv *, can be null
  \return The qbhTypeHandle for a const sc_lv *
*/
template <int W>
inline qbhTypeHandle HubGetType( const sc_lv<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransFrom( qbhValueHandle h,
						  sc_lv<W>* v,
						  int index=-1,
						  int flags=0 )
{
	int length = W + 1;  // + 1 to accomodate returned '\0'

    // grab value from HUB
    char vstring[W+1];   // character array to receive bit array
	vstring[W] = '\0';

	// Check for operation value index:
	if( index > -1 )
	{ qbhIndexedGetBitVectorValue( h, index, vstring, &length ); }
	else
	{ qbhGetBitVectorValue( h, vstring, &length ); } // adds '\0'

	*v = vstring;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransTo( sc_lv<W>* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	int length = W;

	char vstring[W+1];

	// HUB values are stored [0:7] (MSB to LSB):
    for(int i = 0; i < length; i++ )
    {
	    vstring[length-i-1] = v->get_bit(i) + '0';
    }
	vstring[W] = '\0';

	// Check for an operation value index:
	if( index > -1 )
		qbhIndexedSetBitVectorValue( *h, index, vstring, length );

	// Otherwise, just set the given value:
	else
	{ 
		qbhCreateValue( HubGetType(v), h );
		qbhSetBitVectorValue( *h, vstring, length );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
template <int W>
inline void HubCleanupValue( sc_lv<W>* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
template <int W>
inline void HubEncodeTdb( sc_lv<W>* v,
						  qbhEventBuffer* buffer )
{
	int length = W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
    {
	    vstring[length-i-1] = v->get_bit(i) + '0';
    }
	vstring[W] = '\0';

	qbhTdbEncodeBitVector( buffer, vstring );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
template <int W>
inline void HubEncodeCsv( sc_lv<W>* v,
						  char* buffer )
{
	int length=W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
    {
	    vstring[length-i-1] = v->get_bit(i) + '0';
    }
	vstring[W] = '\0';

	sprintf( buffer, "%s", vstring );
}

//
// ----------------------------------------
// RAVE bitvector  <--> sc_int<>
// ----------------------------------------
//
/*!
  \brief Gets the Hub type for a sc_int *
  \param v Any sc_int *, can be null
  \return The qbhTypeHandle for a sc_int *
*/
template <int W>
inline qbhTypeHandle HubGetType( sc_int<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Gets the Hub type for a const sc_int *
  \param v Any const sc_int *, can be null
  \return The qbhTypeHandle for a const sc_int *
*/
template <int W>
inline qbhTypeHandle HubGetType( const sc_int<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransFrom( qbhValueHandle h,
						  sc_int<W>* v,
						  int index=-1,
						  int flags=0 )
{
	if ( W == 1 )
	{
		// Set as single-bit value.
		sc_bit bitval;
		HubTransFrom( h, &bitval, index, flags );
		*v = bitval;
	}
	else
	{
		int length = W + 1;  // + 1 to accomodate returned '\0'

	    // grab value from HUB
	    char vstring[W+1];   // character array to receive bit array
		vstring[W] = '\0';

		// Check for operation value index:
		if( index > -1 )
		{ qbhIndexedGetBitVectorValue( h, index, vstring, &length ); }
		else
		{ qbhGetBitVectorValue( h, vstring, &length ); } // adds '\0'

		// Strip Xs and Zs from the string
		for ( int i = 0 ; i < W ; i++ )
		{
			(*v)[W-i-1] = (vstring[i] == '1') ? 1 : 0;
		}
	}
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransTo( sc_int<W>* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if ( W == 1 )
	{
		// Treat as single-bit value.
		//   SystemC will produce a -1 with sc_int<1> = 1
		sc_bit bitval( *v ? 1 : 0 );
		HubTransTo( &bitval, h, index, flags );
	}
	else
	{
		int length = W;

		char vstring[W+1];

		// HUB values are stored [0:7] (MSB to LSB):
	    for(int i = 0; i < length; i++ )
	    {
		    vstring[length-i-1] = (*v)[i] + '0';
	    }
		vstring[W] = '\0';

		// Check for an operation value index:
		if( index > -1 )
			qbhIndexedSetBitVectorValue( *h, index, vstring, length );

		// Otherwise, just set the given value:
		else
		{ 
			qbhCreateValue( HubGetType(v), h );
			qbhSetBitVectorValue( *h, vstring, length );
		}
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
template <int W>
inline void HubCleanupValue( sc_int<W>* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
template <int W>
inline void HubEncodeTdb( sc_int<W> *v,
						  qbhEventBuffer* buffer )
{
	int length = W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
	{
		vstring[length-i-1] = (*v)[i] + '0';
	}
	vstring[W] = '\0';
		
	qbhTdbEncodeBitVector( buffer, vstring );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
template <int W>
inline void HubEncodeCsv( sc_int<W> *v,
						  char* buffer )
{
	int length = W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
	{
		vstring[length-i-1] = (*v)[i] + '0';
	}
	vstring[W] = '\0';
		
	sprintf( buffer, "%s", buffer );
}

//
// ----------------------------------------
// RAVE bitvector  <--> sc_uint<>
// ----------------------------------------
//
/*!
  \brief Gets the Hub type for a sc_uint *
  \param v Any sc_uint *, can be null
  \return The qbhTypeHandle for a sc_uint *
*/
template <int W>
inline qbhTypeHandle HubGetType( sc_uint<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Gets the Hub type for a const sc_uint *
  \param v Any const sc_uint *, can be null
  \return The qbhTypeHandle for a const sc_uint *
*/
template <int W>
inline qbhTypeHandle HubGetType( const sc_uint<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransFrom( qbhValueHandle h,
						  sc_uint<W>* v,
						  int index=-1,
						  int flags=0 )
{
	if ( W == 1 )
	{
		// Set as single-bit value.
		sc_bit bitval;
		HubTransFrom( h, &bitval, index, flags );
		*v = bitval;
	}
	else
	{
		int length = W + 1;  // + 1 to accomodate returned '\0'

	    // grab value from HUB
	    char vstring[W+1];   // character array to receive bit array
		vstring[W] = '\0';

		// Check for operation value index:
		if( index > -1 )
		{ qbhIndexedGetBitVectorValue( h, index, vstring, &length ); }
		else
		{ qbhGetBitVectorValue( h, vstring, &length ); } // adds '\0'

		// Strip Xs and Zs from the string
		for ( int i = 0 ; i < W ; i++ )
		{
			(*v)[W-i-1] = (vstring[i] == '1') ? 1 : 0;
		}
	}
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransTo( sc_uint<W>* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if ( W == 1 )
	{
		// Treat as single-bit value.
		sc_bit bitval( (int)(*v) );
		HubTransTo( &bitval, h, index, flags );
	}
	else
	{
		int length = W;

		char vstring[W+1];

		// HUB values are stored [0:7] (MSB to LSB):
	    for(int i = 0; i < length; i++ )
	    {
		    vstring[length-i-1] = (*v)[i] + '0';
	    }
		vstring[W] = '\0';

		// Check for an operation value index:
		if( index > -1 )
			qbhIndexedSetBitVectorValue( *h, index, vstring, length );

		// Otherwise, just set the given value:
		else
		{ 
			qbhCreateValue( HubGetType(v), h );
			qbhSetBitVectorValue( *h, vstring, length );
		}
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
template <int W>
inline void HubCleanupValue( sc_uint<W>* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
template <int W>
inline void HubEncodeTdb( sc_uint<W> *v,
						  qbhEventBuffer* buffer )
{
	int length = W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
	{
		vstring[length-i-1] = (*v)[i] + '0';
	}
	vstring[W] = '\0';
		
	qbhTdbEncodeBitVector( buffer, vstring );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
template <int W>
inline void HubEncodeCsv( sc_uint<W> *v,
						  char* buffer )
{
	int length = W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
	{
		vstring[length-i-1] = (*v)[i] + '0';
	}
	vstring[W] = '\0';
		
	sprintf( buffer, "%s", buffer );
}

//
// ----------------------------------------
// RAVE bitvector  <--> sc_bigint<>
// ----------------------------------------
//
/*!
  \brief Gets the Hub type for a sc_bigint *
  \param v Any sc_bigint *, can be null
  \return The qbhTypeHandle for a sc_bigint *
*/
template <int W>
inline qbhTypeHandle HubGetType( sc_bigint<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Gets the Hub type for a const sc_bigint *
  \param v Any const sc_bigint *, can be null
  \return The qbhTypeHandle for a const sc_bigint *
*/
template <int W>
inline qbhTypeHandle HubGetType( const sc_bigint<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransFrom( qbhValueHandle h,
						  sc_bigint<W>* v,
						  int index=-1,
						  int flags=0 )
{
	int length = W + 1;  // + 1 to accomodate returned '\0'

    // grab value from HUB
    char vstring[W+1];   // character array to receive bit array
	vstring[W] = '\0';

	// Check for operation value index:
	if( index > -1 )
	{ qbhIndexedGetBitVectorValue( h, index, vstring, &length ); }
	else
	{ qbhGetBitVectorValue( h, vstring, &length ); } // adds '\0'

	// Strip Xs and Zs from the string
	for ( int i = 0 ; i < W ; i++ )
	{
		(*v)[W-i-1] = (vstring[i] == '1') ? 1 : 0;
	}
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransTo( sc_bigint<W>* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	int length = W;

	char vstring[W+1];

	// HUB values are stored [0:7] (MSB to LSB):
    for(int i = 0; i < length; i++ )
    {
	    vstring[length-i-1] = (*v)[i] + '0';
    }
	vstring[W] = '\0';

	// Check for an operation value index:
	if( index > -1 )
		qbhIndexedSetBitVectorValue( *h, index, vstring, length );

	// Otherwise, just set the given value:
	else
	{ 
		qbhCreateValue( HubGetType(v), h );
		qbhSetBitVectorValue( *h, vstring, length );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
template <int W>
inline void HubCleanupValue( sc_bigint<W>* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
template <int W>
inline void HubEncodeTdb( sc_bigint<W> *v,
						  qbhEventBuffer* buffer )
{
	int length = W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
	{
		vstring[length-i-1] = (*v)[i] + '0';
	}
	vstring[W] = '\0';
		
	qbhTdbEncodeBitVector( buffer, vstring );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
template <int W>
inline void HubEncodeCsv( sc_bigint<W> *v,
						  char* buffer )
{
	int length = W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
	{
		vstring[length-i-1] = (*v)[i] + '0';
	}
	vstring[W] = '\0';
		
	sprintf( buffer, "%s", buffer );
}


//
// ----------------------------------------
// RAVE bitvector  <--> sc_biguint<>
// ----------------------------------------
//
/*!
  \brief Gets the Hub type for a sc_biguint *
  \param v Any sc_biguint *, can be null
  \return The qbhTypeHandle for a sc_biguint *
*/
template <int W>
inline qbhTypeHandle HubGetType( sc_biguint<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Gets the Hub type for a const sc_biguint *
  \param v Any const sc_biguint *, can be null
  \return The qbhTypeHandle for a const sc_biguint *
*/
template <int W>
inline qbhTypeHandle HubGetType( const sc_biguint<W>* v )
{
	qbhTypeHandle typeh;
	qbhGetArrayType( "bit", W-1, 0, &typeh );  // -1 msb,lsb means unconstrained
	return typeh;
}

/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransFrom( qbhValueHandle h,
						  sc_biguint<W>* v,
						  int index=-1,
						  int flags=0 )
{
	int length = W + 1;  // + 1 to accomodate returned '\0'

    // grab value from HUB
    char vstring[W+1];   // character array to receive bit array
	vstring[W] = '\0';

	// Check for operation value index:
	if( index > -1 )
	{ qbhIndexedGetBitVectorValue( h, index, vstring, &length ); }
	else
	{ qbhGetBitVectorValue( h, vstring, &length ); } // adds '\0'

	// Strip Xs and Zs from the string
	for ( int i = 0 ; i < W ; i++ )
	{
		(*v)[W-i-1] = (vstring[i] == '1') ? 1 : 0;
	}
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template <int W>
inline void HubTransTo( sc_biguint<W>* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	int length = W;

	char vstring[W+1];

	// HUB values are stored [0:7] (MSB to LSB):
    for(int i = 0; i < length; i++ )
    {
	    vstring[length-i-1] = (*v)[i] + '0';
    }
	vstring[W] = '\0';

	// Check for an operation value index:
	if( index > -1 )
		qbhIndexedSetBitVectorValue( *h, index, vstring, length );

	// Otherwise, just set the given value:
	else
	{ 
		qbhCreateValue( HubGetType(v), h );
		qbhSetBitVectorValue( *h, vstring, length );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
template <int W>
inline void HubCleanupValue( sc_biguint<W>* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
template <int W>
inline void HubEncodeTdb( sc_biguint<W> *v,
						  qbhEventBuffer* buffer )
{
	int length = W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
	{
		vstring[length-i-1] = (*v)[i] + '0';
	}
	vstring[W] = '\0';
		
	qbhTdbEncodeBitVector( buffer, vstring );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
template <int W>
inline void HubEncodeCsv( sc_biguint<W> *v,
						  char* buffer )
{
	int length = W;

	char vstring[W+1];

	for(int i = 0; i < length; i++ )
	{
		vstring[length-i-1] = (*v)[i] + '0';
	}
	vstring[W] = '\0';
		
	sprintf( buffer, "%s", buffer );
}

//
//--------------------------------------
// RAVE T[] <--> sc_pvector<T>
//--------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template< class T >
inline void HubTransFrom( qbhValueHandle h,
						  sc_pvector<T>* v,
						  int index=-1,
						  int flags=0 )
{
	qbhValueHandle arrayHandle;

	// If the index parameter is set, get the identified value
	// handle from within the given handle:
	if( index > -1 )
	{
		// Get the array value handle:
		qbhCreateValue( HubGetType(v), &arrayHandle );
		qbhIndexedGetHandleValue( h, index, arrayHandle );
	}

	// Otherwise, use the given handle:
	else
	{ arrayHandle = h; }

	// Get the size of the HUB integer array:
    int size;
	qbhGetArraySize( arrayHandle, &size ); 

    // Set the SystemC T array values:
    for(int i = 0; i < size; i++)
    {
		T val;
		HubTransFrom( arrayHandle, &val, i );
		v->push_back( val );
	}

	// Clean-up:
	qbhDestroyHandle( arrayHandle );
}

/*!
  \brief Gets the Hub type for a sc_pvector *
  \param v Any sc_pvector *, can be null
  \return The qbhTypeHandle for a sc_pvector *
*/
template< class T >
inline qbhTypeHandle HubGetType( sc_pvector<T>* v )
{
	T value;
    qbhTypeHandle typeh;
	qbhTypeHandle vTypeh;

	typeh = HubGetType( &value ); 
    qbhGetArrayTypeFromTypeHandle( typeh, -1, -1, &vTypeh );
    return vTypeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template< class T >
inline void HubTransTo( sc_pvector<T>* v,
						qbhValueHandle* h,
						int index=-1,
						int flags=0 )
{
	qbhValueHandle arrayHandle;

	// Get the size of the int array:
    int size = v->size();

	// Create the HUB array value handle:	
	qbhCreateValue( HubGetType(v), &arrayHandle );
    
	// Set the T array values:
   	for(int i = 0; i < size; i++)
	{
		HubTransTo( &((*v)[i]), &arrayHandle, i );
	}

	// If the index parameter is set, set the indicated value
	// handle within the given handle:
	if( index >= 0 )
	{
		// Set the value within the passed HUB handle:
		qbhIndexedSetHandleValue( *h, index, arrayHandle );
		qbhDestroyHandle( arrayHandle );
	}

	// Otherwise, simply set the given handle:
	else
	{
		*h = arrayHandle;
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
template< class T >
inline void HubCleanupValue( sc_pvector<T>* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
template< class T >
inline void HubEncodeTdb( sc_pvector<T>* v,
						  qbhEventBuffer* buffer )
{
	int size = v->size();

	T val;

	qbhTdbEncodeArray( buffer, HubGetType( val ), size );

	for( int i=0; i<size; i++ )
	{
		HubEncodeTdb( &((*v)[i]), buffer );
	}
}

// NOT CORRECT
/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
template< class T >
inline void HubEncodeCsv( sc_pvector<T>* v,
						  qbhEventBuffer* buffer )
{
	int size = v->size();

	T val;

	for( int i=0; i<size; i++ )
	{
		HubEncodeCsv( &((*v)[i]), buffer );
	}
}

//
// -------------------------
// RAVE byte <--> cynw_string*
// -------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  cynw_string* v,
						  int index=-1,
						  int flags=0 )
{
	int length = MAX_STRING_LENGTH;
	char string[MAX_STRING_LENGTH];

	if( index > -1 )
		qbhIndexedGetStringValue( h, index, string, &length );
	else
	    qbhGetStringValue( h, string, &length );

	*v = string;
}

/*!
  \brief Gets the Hub type for a const cynw_string *
  \param v Any const cynw_string *, can be null
  \return The qbhTypeHandle for a const cynw_string *
*/
inline qbhTypeHandle HubGetType( const cynw_string* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
	    qbhGetType( "string", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( cynw_string* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if( index > -1 )
		qbhIndexedSetStringValue( *h, index, (char*)v->c_str() );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetStringValue( *h, (char*)v->c_str() );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( cynw_string* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( cynw_string* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeString( buffer, (char*)v->c_str() );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( cynw_string* v,
						  char* buffer )
{
	sprintf( buffer, "%s", v->c_str() );
}

//
// --------------------------
// RAVE byte <--> cynw_string**
// --------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  cynw_string** v,
						  int index=-1,
						  int flags=0 )
{
	HubTransFrom(h,*v,index,flags);
}

/*!
  \brief Gets the Hub type for an cynw_string **
  \param v Any cynw_string **, can be null
  \return The qbhTypeHandle for an cynw_string **
*/
inline qbhTypeHandle HubGetType( cynw_string** v )
{
    return HubGetType(*v);
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( cynw_string** v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	HubTransTo(*v,h,index,flags);
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( cynw_string** v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( cynw_string** v,
						  qbhEventBuffer* buffer )
{
	HubEncodeTdb(*v,buffer);
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( cynw_string** v,
						  char* buffer )
{
	HubEncodeCsv(*v,buffer);
}

// Only include translators that utilize the STL vector class
// if specified:

#if TRANS_VECTOR

//
//--------------------------------------
// RAVE T[] <--> std::vector<T> 
//--------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template< class T >
inline void HubTransFrom( qbhValueHandle h,
						  std::vector<T>* v,
						  int index=-1,
						  int flags=0 )
{
	qbhValueHandle arrayHandle;

	// If the index parameter is set, get the identified value
	// handle from within the given handle:
	if( index > -1 )
	{
		// Get the array value handle:
		qbhCreateValue( HubGetType(v), &arrayHandle );
		qbhIndexedGetHandleValue( h, index, arrayHandle );
	}

	// Otherwise, use the given handle:
	else
	{ arrayHandle = h; }

	// Get the size of the HUB integer array:
    int size;
	qbhGetArraySize( arrayHandle, &size ); 

	// Set the vector size:
	v->resize( size );

    // Set the T array values:
    for(int i = 0; i < size; i++)
    {
		HubTransFrom( arrayHandle, &((*v)[i]), i );
	}

	// Clean-up:
	qbhDestroyHandle( arrayHandle );
}

/*!
  \brief Gets the Hub type for a std::vector *
  \param v Any std::vector *, can be null
  \return The qbhTypeHandle for a std::vector *
*/
template< class T >
inline qbhTypeHandle HubGetType( std::vector<T>* v )
{
	T value;
    qbhTypeHandle typeh;
	qbhTypeHandle vTypeh;

	typeh = HubGetType( &value ); 
    qbhGetArrayTypeFromTypeHandle( typeh, -1, -1, &vTypeh );
    return vTypeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template< class T >
inline void HubTransTo( std::vector<T>* v,
						qbhValueHandle* h,
						int index=-1,
						int flags=0 )
{
	qbhValueHandle arrayHandle;

	// Get the size of the array:
    int size = v->size();


	// If the index parameter is set, set the indicated value
	// handle within the given handle:
	if( index >= 0 )
	{
		qbhCreateValue( HubGetType(v), &arrayHandle );

		qbhIndexedGetHandleValue( *h, index, arrayHandle );

		// Set the T array values:
		for(int i = 0; i < size; i++)
		{
			HubTransTo( &((*v)[i]), &arrayHandle, i );
		}

		// Set the value within the passed HUB handle:
		qbhIndexedSetHandleValue( *h, index, arrayHandle );
		qbhDestroyHandle( arrayHandle );
	}

	// Otherwise, simply set the given handle:
	else
	{
		// Create the HUB array value handle:	
		qbhCreateValue( HubGetType(v), &arrayHandle );

		// Set the T array values:
		for(int i = 0; i < size; i++)
		{
			HubTransTo( &((*v)[i]), &arrayHandle, i );
		}

		*h = arrayHandle;
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
template< class T >
inline void HubCleanupValue( std::vector<T>* v )
{
}

#else  // TRANS_VECTOR

//
//--------------------------------------
// RAVE T[] <--> esc_vector<T>
//--------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template< class T >
inline void HubTransFrom( qbhValueHandle h,
						  esc_vector<T>* v,
						  int index=-1,
						  int flags=0 )
{
	qbhValueHandle arrayHandle;

	// If the index parameter is set, get the identified value
	// handle from within the given handle:
	if( index > -1 )
	{
		// Get the array value handle:
		qbhCreateValue( HubGetType(v), &arrayHandle );
		qbhIndexedGetHandleValue( h, index, arrayHandle );
	}

	// Otherwise, use the given handle:
	else
	{ arrayHandle = h; }

	// Get the size of the HUB integer array:
    int size;
	qbhGetArraySize( arrayHandle, &size ); 

	// Set the vector size:
	v->resize( size );

    // Set the T array values:
    for(int i = 0; i < size; i++)
    {
		HubTransFrom( arrayHandle, &((*v)[i]), i );
	}

	// Clean-up:
	qbhDestroyHandle( arrayHandle );
}

/*!
  \brief Gets the Hub type for an esc_vector *
  \param v Any esc_vector *, can be null
  \return The qbhTypeHandle for an esc_vector *
*/
template< class T >
inline qbhTypeHandle HubGetType( esc_vector<T>* v )
{
	T value;
    qbhTypeHandle typeh;
	qbhTypeHandle vTypeh;

	typeh = HubGetType( &value ); 
    qbhGetArrayTypeFromTypeHandle( typeh, -1, -1, &vTypeh );
    return vTypeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
template< class T >
inline void HubTransTo( esc_vector<T>* v,
						qbhValueHandle* h,
						int index=-1,
						int flags=0 )
{
	qbhValueHandle arrayHandle;

	// Get the size of the array:
    int size = v->size();


	// If the index parameter is set, set the indicated value
	// handle within the given handle:
	if( index >= 0 )
	{
		qbhCreateValue( HubGetType(v), &arrayHandle );

		qbhIndexedGetHandleValue( *h, index, arrayHandle );

		// Set the T array values:
		for(int i = 0; i < size; i++)
		{
			HubTransTo( &((*v)[i]), &arrayHandle, i );
		}

		// Set the value within the passed HUB handle:
		qbhIndexedSetHandleValue( *h, index, arrayHandle );
		qbhDestroyHandle( arrayHandle );
	}

	// Otherwise, simply set the given handle:
	else
	{
		// Create the HUB array value handle:	
		qbhCreateValue( HubGetType(v), &arrayHandle );

		// Set the T array values:
		for(int i = 0; i < size; i++)
		{
			HubTransTo( &((*v)[i]), &arrayHandle, i );
		}

		*h = arrayHandle;
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
template< class T >
inline void HubCleanupValue( esc_vector<T>* v )
{
}

#endif // TRANS_VECTOR




#endif // BDW_HUB

#endif // ESC_TRANS_HEADER_GUARD__
