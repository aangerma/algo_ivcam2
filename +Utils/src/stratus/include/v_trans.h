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
#ifndef V_TRANS_HEADER_GUARD__
#define V_TRANS_HEADER_GUARD__

/*!
  \file v_trans.h
  \brief This file contains the built-in HUB-to/from translation functions for basic C++ types.

  Copyright(c) Forte Design Systems
*/

#if BDW_HUB

// Translation function flags
//! Tells the HubTrans() function to use the preexisting value, and not create a new one
#define trans_no_create 0x0001
//! Tells the HubTrans() function to lock the value
#define trans_lock      0x0002

// needs access to the C-API and Cynlib types
#include "capicosim.h"

//
// constants
//
//! Maximum number of characters per string - used when sending char*s/cynw_strings from the Hub
const int MAX_STRING_LENGTH = 1024;





//
// -----------------------------------
// RAVE byte <--> C/C++ const char
// -----------------------------------
//
/*!
  \brief Gets the Hub type for a const char *
  \param v Any const char *, can be null
  \return The qbhTypeHandle for a const char *
*/
inline qbhTypeHandle HubGetType( const char* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
	    qbhGetType( "byte", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( const char* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if( index > -1 )
		qbhIndexedSetByteValue( *h, index, *v );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetByteValue( *h, *v );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( const char* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( const char* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeByte( buffer, *v );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( const char* v,
						  char* buffer )
{
	sprintf( buffer, "%c", *v );
}

//
// -----------------------------------
// RAVE byte <--> C/C++ char
// -----------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  char* v,
						  int index=-1,
						  int flags=0 )
{
	unsigned char rave_char;

	if( index > -1 )
		qbhIndexedGetByteValue( h, index, &rave_char );
	else
	    qbhGetByteValue( h, &rave_char );

	*v = (unsigned char)rave_char;
}

/*!
  \brief Gets the Hub type for a char *
  \param v Any char *, can be null
  \return The qbhTypeHandle for a char *
*/
inline qbhTypeHandle HubGetType( char* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
	    qbhGetType( "byte", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( char* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if( index > -1 )
		qbhIndexedSetByteValue( *h, index, *v );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetByteValue( *h, *v );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( char* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( char* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeByte( buffer, *v );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( char* v,
						  char* buffer )
{
	sprintf( buffer, "%c", *v );
}

//
// -----------------------------------
// RAVE byte <--> C/C++ const double
// -----------------------------------
//
/*!
  \brief Gets the Hub type for a const double *
  \param v Any const double *, can be null
  \return The qbhTypeHandle for a const double *
*/
inline qbhTypeHandle HubGetType( const double* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
	    qbhGetType( "real", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( const double* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if( index > -1 )
		qbhIndexedSetRealValue( *h, index, *v );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetRealValue( *h, *v );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( const double* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( const double* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeReal( buffer, *v );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( const double* v,
						  char* buffer )
{
	sprintf( buffer, "%g", *v );
}

//
// -----------------------------------
// RAVE byte <--> C/C++ double
// -----------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  double* v,
						  int index=-1,
						  int flags=0 )
{
	double rave_double;

	if( index > -1 )
		qbhIndexedGetRealValue( h, index, &rave_double );
	else
	    qbhGetRealValue( h, &rave_double );

	*v = rave_double;
}

/*!
  \brief Gets the Hub type for a const double *
  \param v Any const double *, can be null
  \return The qbhTypeHandle for a const double *
*/
inline qbhTypeHandle HubGetType( double* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
	    qbhGetType( "real", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( double* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if( index > -1 )
		qbhIndexedSetRealValue( *h, index, *v );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetRealValue( *h, *v );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( double* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( double* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeReal( buffer, *v );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( double* v,
						  char* buffer )
{
	sprintf( buffer, "%g", *v );
}


//
// -----------------------------------
// RAVE byte <--> C/C++ unsigned char
// -----------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  unsigned char* v,
						  int index=-1,
						  int flags=0 )
{
	unsigned char rave_uchar;

	if( index > -1 )
		qbhIndexedGetByteValue( h, index, &rave_uchar );
	else
	    qbhGetByteValue( h, &rave_uchar );

	*v = rave_uchar;
}

/*!
  \brief Gets the Hub type for a unsigned char *
  \param v Any unsigned char*, can be null
  \return The qbhTypeHandle for a unsigned char *
*/
inline qbhTypeHandle HubGetType( unsigned char* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
	    qbhGetType( "byte", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( unsigned char* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if( index > -1 )
		qbhIndexedSetByteValue( *h, index, *v );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetByteValue( *h, *v );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( unsigned char* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( unsigned char* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeByte( buffer, *v );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( unsigned char* v,
						  char* buffer )
{
	sprintf( buffer, "%c", *v );
}

//
// --------------------------------------
// RAVE integer <--> C/C++ int
// --------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  int* v,
						  int index=-1,
						  int flags=0 )
{
	int rave_int;

	if( index > -1 )
		qbhIndexedGetIntValue( h, index, &rave_int );
	else
	    qbhGetIntValue( h, &rave_int );

	*v = rave_int;
}

/*!
  \brief Gets the Hub type for a int *
  \param v Any int *, can be null
  \return The qbhTypeHandle for a int *
*/
inline qbhTypeHandle HubGetType( int* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
	    qbhGetType( "integer", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( int* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if( index > -1 )
		qbhIndexedSetIntValue( *h, index, *v );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetIntValue( *h, *v );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( int* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( int* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeInteger( buffer, *v );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( int* v,
						  char* buffer )
{
	sprintf( buffer, "%d", *v );
}

//
// --------------------------------------
// RAVE integer <--> C/C++ const int
// --------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  const int* v,
						  int index=-1,
						  int flags=0 )
{
	int rave_int;

	if( index > -1 )
		qbhIndexedGetIntValue( h, index, &rave_int );
	else
	    qbhGetIntValue( h, &rave_int );

	//*v = rave_int;
}

/*!
  \brief Gets the Hub type for a const int *
  \param v Any const int *, can be null
  \return The qbhTypeHandle for a const int *
*/
inline qbhTypeHandle HubGetType( const int* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
	    qbhGetType( "integer", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( const int* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if( index > -1 )
		qbhIndexedSetIntValue( *h, index, *v );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetIntValue( *h, *v );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( const int* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( const int* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeInteger( buffer, *v );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( const int* v,
						  char * buffer )
{
	sprintf( buffer, "%d\n", *v );
}

//
// --------------------------------------
// RAVE integer <--> C/C++ long 
// --------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  long* v,
						  int index=-1,
						  int flags=0 )
{
	int rave_int;

	if( index > -1 )
		qbhIndexedGetIntValue( h, index, &rave_int );
	else
	    qbhGetIntValue( h, &rave_int );

	*v = (long)rave_int;
}

/*!
  \brief Gets the Hub type for a long *
  \param v Any long *, can be null
  \return The qbhTypeHandle for a long *
*/
inline qbhTypeHandle HubGetType( long* v )
{
    static qbhTypeHandle typeh = qbhEmptyHandle;
	if ( typeh == qbhEmptyHandle )
	    qbhGetType( "integer", &typeh );
    return typeh;
}

/*!
  \brief Sends a value from an external domain to the Hub
  \param v The value to send to the Hub
  \param h The handle of the value to be sent
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransTo( long* v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if( index > -1 )
		qbhIndexedSetIntValue( *h, index, *v );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetIntValue( *h, *v );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( long* v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( long* v,
						  qbhEventBuffer* buffer )
{
	qbhTdbEncodeInteger( buffer, *v );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( long* v,
						  char* buffer )
{
	sprintf( buffer, "%ld", *v );
}

//
// --------------------------------------
// RAVE real <--> C/C++ double *
// --------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  double** v,
						  int index=-1,
						  int flags=0 )
{
	HubTransFrom( h, *v, index, flags );
}

/*!
  \brief Gets the Hub type for a double **
  \param v Any double **, can be null
  \return The qbhTypeHandle for a double **
*/
inline qbhTypeHandle HubGetType( double** v )
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
inline void HubTransTo( double** v,
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
inline void HubCleanupValue( double** v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( double** v,
						  qbhEventBuffer* buffer )
{
	HubEncodeTdb( *v, buffer );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( double** v,
						  char* buffer )
{
	HubEncodeCsv( *v, buffer );
}

//
// --------------------------------------
// RAVE string <--> C/C++ char*
// --------------------------------------
//
/*!
  \brief Retrieves a value from the Hub for the external domain
  \param h The Hub handle for the value to be retrieved
  \param v The value to be set, must be non-null
  \param index Non-negative if this value is an element in an array, -1 ow.
  \param flags Some combination of trans_no_create and trans_lock
*/
inline void HubTransFrom( qbhValueHandle h,
						  char** v,
						  int index=-1,
						  int flags=0 )
{
    int length = MAX_STRING_LENGTH;
	char string[MAX_STRING_LENGTH];

	if( index > -1 )
		qbhIndexedGetStringValue( h, index, string, &length );
	else
	    qbhGetStringValue( h, string, &length );

	// Copy or create the new string:
	if( flags & trans_no_create )
	{ *v = strdup( string ); }
	else
	{
		*v = new char[length];
		*v = strdup( string );
	}
}

/*!
  \brief Gets the Hub type for a char **
  \param v Any char **, can be null
  \return The qbhTypeHandle for a char **
*/
inline qbhTypeHandle HubGetType( char** v )
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
inline void HubTransTo( char** v,
						qbhValueHandle *h,
						int index=-1,
						int flags=0 )
{
	if( index > -1 )
		qbhIndexedSetStringValue( *h, index, *v );
	else
	{
		qbhCreateValue( HubGetType(v), h );
	    qbhSetStringValue( *h, *v );
	}
}

/*!
  \brief Performs cleanup on a value, defaults to doing nothing
  \param v The value to be cleaned up
*/
inline void HubCleanupValue( char** v )
{
}

/*!
  \brief Encodes a value for storing into a tdb database
  \param v The value to be encoded
  \param buffer The buffer to encode the value into, must be non-null
*/
inline void HubEncodeTdb( char** v,
						  qbhEventBuffer* buffer )
{
	HubEncodeTdb( *v, buffer );
}

/*!
  \brief Encodes a value for storing into a comma separated value (CSV) file
  \param v The value to be encoded
  \param buffer the buffer to print the value into, must be non-null
*/
inline void HubEncodeCsv( char** v,
						  char* buffer )
{
	HubEncodeCsv( *v, buffer );
}


#else // BDW_HUB

typedef void *qbhTypeHandle;
typedef void *qbhValueHandle;

#endif // BDW_HUB


/*!
  \brief Macro to define a NULL template for a type that isn't to go over the Hub.
  \param T the type to create Hub*() functions for.

  Use of this macro is required when instantiating channels using 
  C++ classes that have no translators declared.
*/
#define HubNullType( T ) \
	inline void HubTransFrom( qbhValueHandle h, T *v, int index=-1, int flags=0 ) {}	\
	inline qbhTypeHandle HubGetType( T *v ) { return (qbhTypeHandle)-1; } \
	inline void HubTransTo( T *v, qbhValueHandle *h, int index=-1, int flags=0 ) {} \
	inline void HubCleanupValue( T *v ) {}



#endif
