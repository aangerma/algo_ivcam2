/*
 * $Header: /home/gthomas/work/final-cvs-src/Forte/bdw/stshare/results/qbhCapi.h,v 1.3 2013-11-07 16:59:52 sbs Exp $
 * Copyright Forte Design Systems, 1989-1998
 */

#ifndef QBHCAPI_HEADER
#define QBHCAPI_HEADER

#if _WIN32 && ! USEGCC
#	ifdef QBHCAPI_INT_HEADER
#		ifdef __cplusplus
#			define RCEXT extern "C" __declspec( dllexport )
#		else
#			define RCEXT extern __declspec( dllexport )
#		endif
# 	else
#		ifdef __cplusplus
#			define RCEXT extern "C"	__declspec( dllimport ) 
#		else
#			define RCEXT extern __declspec( dllimport ) 
#		endif
#	endif
#else
#	ifdef __cplusplus
#		define RCEXT extern "C" 
#	else
#		define RCEXT extern 
#	endif
#endif


// Time is a 64-bit integer storing pico-seconds.
#if _WIN32
typedef _int64 RdbTime;
typedef _int64 RdbData64;
#else
typedef long long RdbTime;
typedef long long RdbData64;
#endif

#define UNSET_RDBTIME -1

// These values describe the class which should be
// created for an event in a stream.
// THESE NUMBERS ARE SAVED PERSISTENTLY IN FILES!
typedef enum
{
	qbhRetNone=0,
	qbhRetStreamDescr=1,
	qbhRetDiagramRunStatus=2,
	qbhRetStreamIndex=3,
	qbhRetStreamHeader=4,
	qbhRetChannelValue=5,
	qbhRetValueDescr=6,
	qbhRetRaveValueDescr=7,
	qbhRetStreamdefDescr=8,
	qbhRetSignalValue=12,
	qbhRetNetlistDescr=13,
	qbhRetNum=14
} qbhResultsObjectType;

// 
// Type codes
//
typedef enum
{
	qbhVTCBadType=0,
	qbhVTCInt=1,
	qbhVTCBit=2,
	qbhVTCByte=3,
	qbhVTCReal=4,
	qbhVTCArray=5,
	qbhVTCRecord=6,
	qbhVTCTime=7,
	qbhVTCString=8,
	qbhVTCOpset=9,
	qbhVTCNumTypes=10
} qbhValueTypeCode;

//
// Types of boolean queries
//
typedef enum
{
	qbhBCTAnd,
	qbhBCTOr,
	qbhBCTNot,
	qbhBCTXor
} qbhboolQueryType;

#ifdef min 
#undef min
#endif
#ifdef max
#undef max
#endif

// must match with ssl/fsdb/fsdb.hpp and ssl/fsdb/ssl.cpp
typedef enum
{
	qbhNLTNnknown   = 0,
	qbhNLTSignal    = 1,
	qbhNLTModule    = 2,
	qbhNLTTask      = 3,
	qbhNLTFunction  = 4,
	qbhNLTBegin     = 5,
	qbhNLTFork      = 6
} qbhNetlistType;


/*
 *  Opaque handles
 */
typedef unsigned long qbhHandle;
typedef qbhHandle qbhTypeHandle;
typedef qbhHandle qbhValueHandle;
typedef qbhHandle qbhChannelHandle;
typedef qbhHandle qbhRanDefHandle;
typedef qbhHandle qbhRanGenHandle;

#define qbhBadHandle 0xffffffff
#define qbhEmptyHandle qbhBadHandle
	
/*
 * Enumerations for value types.
 */
typedef enum {
	qbhBadType=0,
	qbhInt=1,
	qbhBit=2,
	qbhByte=3,
	qbhReal=4,
	qbhArray=5,
	qbhRecord=6,
	qbhTime=7,
	qbhString=8,
	qbhOpset=9,
	qbhNumTypes=10
} qbhType;

/*
 * Iteration styles for buckets
 */
typedef enum {
	qbhIterNoExcludes	= 0,
	qbhIterRaw			= 1,
	qbhIterHit			= 2,
	qbhIterUnhit		= 3,
	qbhIterFilled		= 4,
	qbhIterUnfilled		= 5
} qbhBucketIterationStyle;
	
/*
 * Error codes.
 */
#define	qbhOK							0
#define	qbhErrorInvalidHandle			1
#define	qbhErrorNoConversion			2
#define	qbhErrorIndexOutOfBounds		3
#define	qbhErrorInvalidRecordField		4
#define	qbhErrorInvalidOpName			5
#define	qbhErrorNoProgram				6
#define	qbhErrorBadType					7
#define	qbhErrorNotFound				8
#define	qbhErrorNoDelaySupport			9
#define	qbhErrorNoValue					10
#define	qbhAlreadyAcked					11
#define	qbhAlreadyDefined				12
#define	qbhNotSettable					13
#define	qbhWrongParamCount				14
#define	qbhErrorNoLicense				15
#define qbhErrorGeneric					16
#define qbhThreadPoolUninitialized		17

typedef int qbhError;


/*
 * Types of HUB objects.
 */
#define qbhRangenObject		3

typedef int qbhObjectType;


/*
 * Values for bit types.
 */
#define qbhBit0 ((unsigned char)'0')
#define qbhBit1 ((unsigned char)'1') 
#define qbhBitX ((unsigned char)'X') 
#define qbhBitZ ((unsigned char)'Z') 
/*
 * Enumerations for channel directions.
 */
typedef enum {
	qbhInput=0,
	qbhOutput=1,
	qbhInternal=2
} qbhDirection;
/*
 *  Record describing a channel event.
 */
typedef enum {
	qbhValueSent,			
	qbhValueConsumed
} qbhChannelActivity;

typedef struct qbhChannelEvent {
	qbhChannelActivity		activity;
	qbhValueHandle			value;
	double					when;
	qbhChannelHandle		channel;
	unsigned long			id;
	long					index;
	int						reason;
} qbhChannelEvent;


/*
 * Prototype and enums for library management callback functions.
 */
typedef enum {
	qbhLoadTime,
	qbhElabTime,
	qbhExecStartTime,
	qbhExecDoneTime,
	qbhExecRestartTime,
	qbhUnloadTime
} qbhLibraryCallbackReason;

typedef void (*qbhLibraryCallback)( qbhLibraryCallbackReason cbr );


#ifndef SKIP_FUNC_DEFS
/*
 * Return a static tring pointer for the error status passed in.
 * This is very useful in error messages.
*/
RCEXT	const char *		qbhErrorString(qbhError);

/*
 *  Retrieve the type of the value.
 *  An enum is returned and a type handle is supplied
 *  as an output parameter.
 */
RCEXT qbhError		qbhGetValueType(qbhValueHandle h, qbhTypeHandle *t, qbhType *ty);
RCEXT qbhError		qbhIndexedGetValueType(qbhHandle h, int index, char *opName, qbhTypeHandle *t, qbhType *ty);

/*
 *	Get a type by name.
 *	Either builtin types or types declared in RAVE can be accessed.
 */
RCEXT qbhError qbhGetType(const char *typeName, qbhTypeHandle *h );

/*
 * Given a typeHandle, return the type.
 *
 */
RCEXT qbhError qbhGetTypeFromTypeHandle(qbhTypeHandle h, qbhType *ty);

/*
 *	Get an array type whose element type and msb/lsb are given.
 *	If msb and lsb are -1, the array will be unconstrained.
 */
RCEXT qbhError	qbhGetArrayType( const char *typeName, int msb, int lsb, qbhTypeHandle *th );

/*
 *	Get an array type whose element type and msb/lsb are given.
 *	If msb and lsb are -1, the array will be unconstrained.
 */
RCEXT qbhError	qbhGetArrayTypeFromTypeHandle(qbhTypeHandle h, int msb, int lsb, qbhTypeHandle *th );

/*
 * Given a type handle, return the list of field names. These strings
 * are in the HUB space and must NOT be deleted by the use. The array
 * that contains them IS the responsability of the user. The function
 * accepts an optional operation name, in case the type is actually an
 * opset. In this case, it will find the operation type in the opset and
 * return the field names of the operation in question.
 *
 * The first argument passed in may be either a value handle or a type 
 * handle.
*/
RCEXT qbhError		qbhGetFieldNames(qbhHandle h, char *opName, char **fieldNames, int *numFields );

/*
 *  Retrieve the appropriately typed value, performing
 *  conversions if necessary.
 */
RCEXT qbhError		qbhGetIntValue( qbhValueHandle h, int *res);
RCEXT qbhError		qbhGetBitValue( qbhValueHandle h, char *res);
RCEXT qbhError 		qbhGetByteValue( qbhValueHandle h, unsigned char *res);
RCEXT qbhError		qbhGetRealValue( qbhValueHandle h, double *res);
RCEXT qbhError		qbhGetTimeValue( qbhValueHandle h, double *res);
RCEXT qbhError		qbhGetStringValue( qbhValueHandle h, char* res, int *len );
RCEXT qbhError		qbhGetBitVectorValue( qbhValueHandle h, char* value, int *len );
RCEXT qbhError		qbhGetByteVectorValue( qbhValueHandle h, unsigned char* res, int *len );

/*
 * Get the size of the array.
 */
RCEXT qbhError		qbhGetArraySize( qbhValueHandle h, int *size);

/*
 *	Value-retrieval functions which accept an index value that
 *	is an index into an array, record, or operation parameter set.
 */
RCEXT qbhError		qbhIndexedGetIntValue( qbhValueHandle h,int index ,int *result);
RCEXT qbhError		qbhIndexedGetBitValue( qbhValueHandle h,int index ,char *result);
RCEXT qbhError 		qbhIndexedGetByteValue( qbhValueHandle h,int index ,unsigned char *result);
RCEXT qbhError		qbhIndexedGetRealValue( qbhValueHandle h,int index ,double *result);
RCEXT qbhError		qbhIndexedGetTimeValue( qbhValueHandle h,int index ,double *result);
RCEXT qbhError		qbhIndexedGetStringValue( qbhValueHandle h, int index, char* value, int *len );
RCEXT qbhError		qbhIndexedGetBitVectorValue( qbhValueHandle h, int index, char* value, int *len);
RCEXT qbhError		qbhIndexedGetByteVectorValue( qbhValueHandle h, int index, unsigned char* value, int *len);
RCEXT qbhError		qbhIndexedGetHandleValue(qbhValueHandle h,int index , qbhValueHandle outHandle);

/*
 *  Functions to set handle values from C values.
 *  Conversions are applied if required.
 *
 */
RCEXT qbhError	qbhSetIntValue( qbhValueHandle h, int value );
RCEXT qbhError	qbhSetBitValue( qbhValueHandle h, char value );
RCEXT qbhError	qbhSetByteValue( qbhValueHandle h, unsigned char value );
RCEXT qbhError	qbhSetRealValue( qbhValueHandle h, double value );
RCEXT qbhError	qbhSetTimeValue( qbhValueHandle h , double value );
RCEXT qbhError	qbhSetStringValue( qbhValueHandle h, char* value );
RCEXT qbhError	qbhSetBitVectorValue( qbhValueHandle h, char* value, int len );
RCEXT qbhError	qbhSetByteVectorValue( qbhValueHandle h, unsigned char* value, int len );
RCEXT qbhError	qbhSetHandleValue( qbhValueHandle h, qbhValueHandle value );
/*
 *	Value-setting functions which accept an index value that
 *	is an index into an array, record, or operation parameter set.
 */
RCEXT qbhError	qbhIndexedSetIntValue( qbhValueHandle h, int index, int value);
RCEXT qbhError	qbhIndexedSetBitValue( qbhValueHandle h, int index, char value);
RCEXT qbhError	qbhIndexedSetByteValue( qbhValueHandle h, int index, unsigned char value);
RCEXT qbhError	qbhIndexedSetRealValue( qbhValueHandle h, int index, double value);
RCEXT qbhError	qbhIndexedSetTimeValue( qbhValueHandle h, int index, double value);
RCEXT qbhError	qbhIndexedSetStringValue( qbhValueHandle h, int index, char* value);
RCEXT qbhError	qbhIndexedSetBitVectorValue( qbhValueHandle h, int index, const char* value, int len);
RCEXT qbhError	qbhIndexedSetByteVectorValue( qbhValueHandle h, int index, unsigned char* value, int len);
RCEXT qbhError	qbhIndexedSetHandleValue( qbhValueHandle h, int index, qbhValueHandle value);
/*
 *  Value creation and destruction.
 */
RCEXT qbhError		qbhCreateValue(qbhTypeHandle h, qbhValueHandle *vh);
RCEXT qbhError		qbhCopyValue(qbhTypeHandle h, qbhValueHandle *vh);
RCEXT qbhError		qbhDestroyHandle(qbhValueHandle val);
/*
 *  Opset support
 */
RCEXT qbhError		qbhGetOpsetOpNames(qbhValueHandle h, char **opNames, int *numOps );
RCEXT qbhError		qbhGetOpName(qbhValueHandle h, char **);
RCEXT qbhError		qbhGetOpTag(qbhValueHandle h, int *);
RCEXT qbhError		qbhCreateOpValue(qbhTypeHandle h, const char *opName, qbhValueHandle *vh);
RCEXT qbhError		qbhCreateOpTagValue(qbhTypeHandle h, int opTag, qbhValueHandle *vh);

/*
 *  Random number generation support
 */
RCEXT qbhError		qbhCreateRanDist( char* name,
									  unsigned type,
									  double param,
									  double scale,
									  double* probArray,
									  unsigned probs,
									  qbhRanDefHandle* distHandle );
RCEXT qbhError		qbhCreateRanGen( qbhRanDefHandle distHandle,
									 unsigned seedIndex,
									 char* seedStr,
									 qbhRanGenHandle* genHandle );
RCEXT qbhError		qbhFindRanDist( char* name,
									qbhRanDefHandle* distHandle );
RCEXT qbhError		qbhGetRandomValue( qbhRanGenHandle genHandle,
									   qbhTypeHandle typeHandle,
									   int lowerBound,
									   int upperBound,
									   qbhValueHandle* valueHandle );

RCEXT qbhError qbhGetRandomIntValue( 	qbhRanGenHandle genHandle,
										int lowerBound,
										int upperBound,
								  		int* outValue );

RCEXT qbhError		qbhGetRanbase(	int *ranbase );
RCEXT qbhError		qbhSetRanbase(	int ranbase );

/*
 *  Retrieve the type of the type.
 *  An enum is returned and a type handle is supplied
 *  as an output parameter.
 */
RCEXT qbhError		qbhGetChannelType( qbhChannelHandle h, qbhTypeHandle *t, qbhType *te);
	
	
/*
 *	Functions for enumerating and querying channels.
 */
RCEXT qbhError		qbhFindChannel( char *name, qbhChannelHandle *ch);
RCEXT qbhError		qbhChannelName( qbhChannelHandle , char **name);

/*
 *	Function for sending values to channels.
 *
 *  The value will be converted to the type of the channel if required.
 *  If the driver handle is 0, then sendchan() semantics are implied.
 */
RCEXT qbhError qbhSendChannel(	qbhHandle d, qbhChannelHandle c, qbhValueHandle v );

/*
 * Function to print onto the output transcript in a manner synchronized
 * with the rest of the RAVE (and simulator) world.
 */
RCEXT void qbhPrintf( const char * format, ...);

#endif
#endif

