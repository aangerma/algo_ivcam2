/*
 * $Header: /home/gthomas/work/final-cvs-src/Forte/bdw/stshare/results/capicosim.h,v 1.19 2013-11-20 13:35:34 acg Exp $
 * Copyright Forte Design Systems, 1989-1998
 */
/*! \file */ 

#ifndef COSIMCAPI_HEADER
#define COSIMCAPI_HEADER

#include "qbhCapi.h"

/*******************************************************
 *
 * HUB co-simulation support routines.
 *
 * These routines support external domains that implement 
 * execution support for HUB objects that must co-simulate
 * with other domain's implementations and uses of the same
 * objects.  Each domain must implement a kernel that processes
 * HUB activity within itself.  This API allows such a domain
 * to synchronize with the HUB and, by proxy, with other similar
 * domains.
 *
 *******************************************************/

typedef qbhHandle qbhDomainHandle;
typedef qbhHandle qbhDriverHandle;
typedef qbhHandle qbhConsumerHandle;
typedef qbhHandle qbhProjectHandle;
typedef qbhHandle qbhLibraryHandle;
typedef qbhHandle qbhSimLogHandle;
typedef qbhHandle qbhInstructionHandle;

/********************************************************
 * Error codes for capicosim.
 ********************************************************/
#define qbhErrorBadFeedbackType 20
#define qbhErrorNoDomain		21
#define qbhErrorInitError		23
#define qbhErrorBadOption		24
#define	qbhErrorNotFirstCaller	25
#define qbhErrorTypeConversion	26
#define qbhErrorBadArguments	27
#define qbhErrorBadName			28
#define qbhErrorNoProject		29
#define qbhErrorBadProject		30
#define qbhErrorBadInstr		31
#define qbhErrorBadInstName		32

/*
 * Execution domain callback functions.
 *
 * When an execution domain registers with the Hub, it must
 * provide a set of callback functions that the Hub
 * can use to interact with the domain.
 *
 * The functions are defined along with their signatures
 * below.
 *
 */


/*
 * Activity codes sent to domain exec callback functions.
 */
typedef enum {
	qbhDomainExecStart,
	qbhDomainExecRestart,
	qbhDomainExecDone,
	qbhDomainExecToTime,
	qbhDomainExecNow,
	qbhDomainCurrentTime
} qbhDomainExecActivity;

/*
 * This signature is expected of the callback functions associated
 * with external domains to perform execution cycle related activities.  
 * It will be called at various times by the HUB as described by the 
 * 'code' field.
 *
 *	qbhDomainExecStart	:	Execution has begun.
 *
 *	qbhDomainExecRestart:	A restart has been executed.
 *
 *	qbhDomainExecDone	:	Execution is complete.  Cleanup can occur.
 *							Domains will be informed after libraries.
 *
 *	qbhDomainExecToTime	:	The domain should execute until the time given by
 *							inTime which should be deemed to be the current
 *							simulation time.  The *outTime parameter should be
 *							filled in with the time _delta_ after which the next 
 *							execution should take place for the domain.
 *
 *	qbhDomainExecNow	:	The domain should execute until it has
 *							no more activity without advancing simulation time.
 *							The *outTime parameter should be filled in with
 *							the time delta after which the HUB should be re-executed.
 *							Times are given in pico-seconds.
 *
 *	qbhDomainCurrentTime:	The domain should fill in the outTime parameter with
 *							a double giving the number of pico-seconds that 
 *							represents the current simulation time.
 */
typedef qbhError (*qbhDomainExecCallback)(	qbhDomainHandle			hDomain,
											void *					userData,
											qbhDomainExecActivity	code,
											double					inTime,
											double *				outTime );


/*
 * These must match those in resdefs.hpp
 */
typedef enum {
	qbhNetlistUnknown	= 0,
	qbhNetlistSignal	= 1,
	qbhNetlistModule	= 2,
	qbhNetlistTask		= 3,
	qbhNetlistFunction	= 4,
	qbhNetlistBegin		= 5,
	qbhNetlistFork		= 6,
	qbhNetlistChannel	= 7,
	qbhNetlistDispatcher= 8,
	qbhNetlistBfmStatus	= 9
} qbhNetlistNodeType;

/*
 * These must match definitions in esc_cosim.h
 */
typedef enum {
	qbhTraceVCD  = 0,
	qbhTraceFSDB = 1,
	qbhTraceSCV = 2
} qbhTraceType;

/*
 * Struct that is used to describe a signal or module.
 */
typedef struct
{
	char *				name;			// The name of the entity.  Memory is owned by domain.
	char *				modName;		// The name of the module for which this entity is an instance.
	qbhNetlistNodeType	kind;			// The kind of entity.
	qbhTypeHandle		type;			// The entities type if appropriate.
} qbhEntityInfo;

/*
 * Struct that is used to describe a synthesized pipelined loop.
 */
typedef struct
{
	int					initInterval;   // initiation interval for a pipelined loop
	int					preLoopWaits;   // # of waits before the 1st I/O in the loop
	int					IOspan;		    // last read - preLoopWaits + 1
	int					loopIterations; // # of loop iterations; < 0 if unknown
} qbhLoopInfo;

/*
 * Struct that is used to describe a synthesized latency block.
 */
typedef struct
{
	int latency;				// total latency for block; depends on simConfig TBehMode
	int totalPreReadWaits;		// total # of waits before the 1st read in the block
	int userPreReadWaits;		// # of protocol waits before the 1st read in the block
	int totalPreWriteWaits;		// total # of waits before the 1st write in the block
	int userWaits;				// # of protocol waits in the whole block
} qbhLatencyInfo;

/*
 * Activity codes sent to domain name functions.
 */
typedef enum {
	qbhDomainNameFindEntity,
	qbhDomainNameNextChild,
	qbhDomainNameParent,
	qbhDomainNameGetInfo,
	qbhDomainNameRegister,
	qbhDomainNameAddWatcher
} qbhDomainNameActivity;



/*
 * This signature is expected of the callback functions associated
 * with external domains to perform namespace related activities.  
 * It will be called at various times by the HUB as described by the 
 * 'code' field.
 *
 *	qbhDomainNameFindEntity	 :	Finds a signal or a module given the slash-separated
 *								path in the 'name' parameter.  If inHandle is not 
 *								qbhEmptyHandle, it should be taken as a parent handle
 *								and the name as a relative name.  The 'kind' parameter, 
 *								unless it is qbhNetlistUnknown, should be used
 * 								as a filter on the type of node that is returned.
 *
 *	qbhDomainNameNextChild	 :	Traverses the namespace from the position defined
 *								by inHandle and *outHandle as follows:
 *						
 *									inHandle		*outHandle			|	result
 *									------------------------------------------------
 *									qbhEmptyHandle	qbhEmptyHandle		|	root module
 *									module			qbhEmptyHandle		|	first child of module
 *									module			sibling				|	next sibling in module
 *
 *								The result should be returned in *outHandle.
 *								If the iteration should stop, qbhEmptyHandle should
 *								be returned.   The 'kind' parameter, 
 *								unless it is qbhNetlistUnknown, should be used
 * 								as a filter on the type of node that is returned.
 *
 *  qbhDomainNameParent		 :  Returns the parent of inHandle in *outHandle
 *
 *	qbhDomainNameGetInfo	 :	Gives information about the entity whose handle is
 *								given in the inHandle parameter.  The *outHandle
 *								parameter is returned filled with a pointer to 
 *								a qbhEntityInfo struct.  The memory of that struct
 *								is owned by the domain.
 * 
 *	qbhDomainNameRegister :		Requests that a channel be registered for the object
 *								referenced by inHandle whose type is 'kind'.
 *								If a registration is successfully performed, the
 *								channel handle given by the Hub must be returned
 *								in the *outHandle parameter.
 *
 *	qbhDomainNameAddWatcher :	Requests that a watcher be added for the channel
 *								identified by name.
 */
typedef qbhError (*qbhDomainNameCallback)(	qbhDomainHandle			hDomain,
											void*					userData,
											qbhDomainNameActivity	code,
											qbhHandle				inHandle,
											qbhHandle*				outHandle,
											char *					name,
											qbhNetlistNodeType		kind );

/*
 * Activity codes sent to domain value functions.
 */
typedef enum {
	qbhDomainValueGet,
	qbhDomainValueSet
} qbhDomainValueActivity;

/* 
 * This signature is expected of the callback functions associated
 * with external domains to perform value related activities.  
 * It will be called at various times by the HUB as described by the 
 * 'code' field.
 *
 *	qbhDomainValueGet		:	The current value of the signal whose handle is
 *								in inHandle will be returned in *outHandle.
 *								If *outHandle is qbhEmptyHandle, the callee should
 *								create a new handle and expect the caller to delete it.
 *								Otherwise, the callee should fill in the value in
 *								*outHandle.
 *
 *	qbhDomainValueSet		:	Sets the value of the signal whose handle
 *								is given in inHandle.  The value is given by
 *								*outHandle.
 *	
 */
typedef qbhError (*qbhDomainValueCallback)(	qbhDomainHandle			hDomain,
											void*					userData,
											qbhDomainNameActivity	code,
											qbhHandle				inHandle,
											qbhHandle*				outHandle );

/*
 * Activity codes sent to domain schedule functions.
 */
typedef enum {
	qbhDomainScheduleOnChange,
	qbhDomainScheduleAfterTime,
	qbhDomainScheduleCancel
} qbhDomainScheduleActivity;

typedef void (*qbhEventCallback)( void * data );

/* 
 * This signature is expected of the callback functions associated
 * with external domains to perform activities related to event scheduling.  
 * It will be called at various times by the HUB as described by the 
 * 'code' field.
 * When the scheduled event occurs, the callee calls qbhEventOccurred().
 *
 *	qbhDomainScheduleOnChange		:	Schedules a callback when the signal
 *										given in 'handle' changes value.
 *										The callbackId value will be provided to qbhEventOccurred().
 *										This callback will repeat on each change until cancelled.
 *		
 *	qbhDomainScheduleAfterTime		:	Schedules a callback when the amount of
 *										time stored in the time value handle in the
 *										'handle' parameter has expired.  The
 *										time value has units of pico-seconds.
 *										The callbackId value will be provided to qbhEventOccurred().
 *										This is a one-shot event.
 *
 *	qbhDomainScheduleCancel			:	Cancels the callback identified by the given callbackId.
 */
typedef qbhError (*qbhDomainScheduleCallback)(	qbhDomainHandle			hDomain,
												void*					userData,
												qbhDomainScheduleActivity	code,
												double					time,
												qbhEventCallback		callbackFunc,
												void *                  callbackData );

/*
 * A qbhDomainCallbacks structure holds pointers to the
 * callbacks from a particular domain.
 */
#ifdef __cplusplus
extern "C" {
#endif

typedef struct 
{
	qbhDomainExecCallback		exec;
	qbhDomainNameCallback		name;
	qbhDomainValueCallback		value;
	qbhDomainScheduleCallback	schedule;
} 
qbhDomainCallbacks;

#ifdef __cplusplus
}
#endif

/*
 * Execution styles for domains.
 * These values describe the several forms of execution interaction that the
 * Hub will use to keep in sync with the domain.
 */
typedef enum {
	qbhDomainExecMaster,			// The domain acts as a master.  It is the sole arbiter of time.
	qbhDomainExecCooperative,		// The domain will allow the Hub to arbitrate its advancement of time. 
	qbhDomainExecPassive			// The domain does not have a notion of time to be synced.
} qbhDomainExecType;

/*
 * A structure that describes a buffer into which serialized data
 * can be written.
 */
#ifdef __cplusplus
struct qbhEventBuffer
#else
typedef struct
#endif

{
	char*	start;		/* The original start of the buffer. */
	char*	next;		/* The next location to write to. */
	int		left;		/* The number of bytes remaining in the buffer. */
}

#ifdef __cplusplus
;
#else
qbhEventBuffer;
#endif


/*
 * Activity codes sent to channel callback functions.
 */
typedef enum {
	qbhDriverAdded=0,
	qbhDriverRemoved=1,
	qbhValueFanout=2,
	qbhValueAcked=3,
	qbhValueRequested=4,
	qbhGetValueCompletion=5,
	qbhConsumerEnabled=6,
	qbhConsumerDisabled=7,
	qbhNumChannelActivities=7
} qbhExtChannelActivity;

/*
 * This signature is expected of the callback functions associated
 * with external channel implementations.  It will be called when another
 * HUB entity has affected the channel in some way.  How the channel was
 * affected is desribed by the 'code' field:
 *
 *	qbhDriverAdded		:	A driver from another domain has become active.
 *							Its handle is given in 'info'.
 *
 *	qbhDriverRemoved	:	The driver whose handle is given in 'info' has become inactive.
 *
 *	qbhValueFanout		:	A value has passed through the channel under the control 
 *							of another domain.  The value's handle is given in 'info'.
 *							The callback function is responsible for fanning the value
 *							out to all watchers in its own domain.
 *
 *	qbhValueRequested	:	A new value is being requested from the driver identified
 *							by the handle in the 'info' parameter.  The info parameter
 *							will be one of the driverIds registered by the channel
 *							with qbhEnableDriver().  If a value could be obtained,
 *							then it is returned in the outVal parameter.  Otherwise,
 *							outVal is left set to qbhEmtpyHandle.
 *
 *	qbhValueAcked		:	A previously driven value has been acknowledged.
 *							In this case, the 'info' parameter contains the
 *							value being acknowledged.  This value will always be the
 *							same handle as was returned from the qbhValueRequested
 *							callback.  The value handle can be used to extract output
 *							parameters, and then it can be either destroyed or saved
 *							for later reuse.
 *
 *	qbhGetValueCompletion:	A value has finally been obtained for a qbhGetDriverValue()
 *							call that did not immediately return a value.  The 'info'
 *							parameter will contain the qbhDriverHandle for the driver from 
 *							which the value was requested.  The 'outVal' parameter will
 *							contain a qbhValueHandle for the value.  Memory management
 *							for this value follows the pattern used by qbhGetDriverValue().
 *							That is, the value is owned by the driver, and should not
 *							be destroyed by the consumer.  When the consumer is done
 *							processing the value, qbhAckValue() must be called.
 *							
 *
 *	qbhConsumerEnabled:		A consumer from another domain has been enabled for this 
 *							channel.
 *
 *	qbhConsumerDisabled:	A consumer from another domain is no longer the consumer for
 *							this channel.
 */
typedef qbhError (*qbhChannelCallback)(	qbhChannelHandle		chan,
										void *					userData,
										qbhExtChannelActivity	code,
										qbhHandle				info,
										qbhHandle				*outVal );


/*
 * Channel kinds used by qbhRegisterChannel.
 */
typedef enum {
	qbhDefChannel=0,
	qbhBfmChannel=1,
	qbhSignalChannel=2,
	qbhMemoryChannel=3,
	qbhNumChannelKinds=4
} qbhChannelKind;

/*
 * Channel roles.
 */
typedef enum {
	qbhNoRole,
	qbhProducerRole,
	qbhConsumerRole,
	qbhWatcherRole,
	qbhPokerRole
} qbhChannelRole;


/*
 * Reason codes for qbhObjectFactoryCallback.
 */
typedef enum {
	qbhCreateObject,		/* Create an object. */
	qbhGetObjectValue,		/* Get a value from the given object. */
	qbhDestroyObject		/* Destroy the given object. */
} qbhObjectFactoryCallbackReason;

/*
 *  Prototype for callback function requesting that a HUB object instance be created.
 *	A pointer to a factory function is supplied by an external domain that registers
 *	an implementation of a HUB object.
 *
 *	hubHandle		:	The HUB's handle for the object.
 *
 *	factoryUserData	:	The user-data pointer that was supplied when the factory 
 *						was registered.
 *
 *	objectUserData	:	A user-data handle that is to be filled in by the callback when
 *						qbhCreateObject is given, and is supplied to the callback for
 *						all other codes.
 *
 *	qbhObjectFactoryCallbackReason	:	The reason for the callback:
 *
 *		qbhCreateObject	:	A request is being made to create an instance of the object.
 *							The params array will be supplied along with this code.
 *
 *		qbhGetObjectValue:	A value is being requested from the object.  If the object
 *							is a function, the params array will be supplied.  The
 *							value can be returned in the *outVal parameter.  If no value
 *							can be supplied, *outVal should be set to qbhEmptyHandle.
 *
 *		qbhDestroyObject:	The given object instance is no longer needed by the HUB
 *							and can be destroyed.
 *
 *	params		:	An array of qbhValueHandle's giving the parameters to be used in
 *					the context of the current callback.
 *
 *	nParams		:	The number of parameters in the params array.
 *
 *	outVal		:	An output parameter that can contain a value produced for the object.
 *					The HUB will destroy the value after it's done with it.
 */
typedef qbhError (*qbhObjectFactoryCallback)(	qbhHandle		hubHandle, 
												void *			factoryUserData,
												void **			objectUserData,
												qbhObjectFactoryCallbackReason	reason,
												qbhValueHandle *params,
												int				nParams,
												qbhHandle 		*outVal );

/*
 * Structure defining information about a HUB type.
 */
#ifdef __cplusplus
extern "C" {
#endif

typedef struct
{
	qbhType		kind;		// The qbhType code for the type.
	int			hasOutput;	// Non-zero if the type has output parameter support.
	char *		name;		// Name string.  Memory owned by HUB.
}
qbhTypeInfoStruct;

#ifdef __cplusplus
}
#endif

/*
 * This enum is used both to label individual events as to what portion
 * of a transaction they're referring to, and to describe the style
 * of feedback that an entity can provide over the course of execution.
 * The meanings of these values may therefore be different for each function
 * that they're used with. 
 */
typedef enum {
	qbhNonEvent		= -1,	/* Non-event event. */
	qbhInstantEvent	= 0,	/* An event without duration. */
	qbhStartEvent	= 1,	/* The start of an event with duration. */
	qbhEndEvent		= 2,	/* The end of an event with duration. */
	qbhStartEndEvent= 3,	/* Both the starts and ends of events will be provided. */
	qbhFeedbackTypeNum= 4	/* The number of elements in this enum. */
} qbhEventFeedbackType;

/*
 * Handle types used for 
 */
typedef qbhHandle qbhTdbHandle;
typedef qbhHandle qbhTdbChannelHandle;
typedef qbhHandle qbhCoverdefHandle;
typedef qbhHandle qbhBucketHandle;
typedef qbhHandle qbhResultsDescrHandle;

/*
 * TDB-related error codes.
 */
#define qbhErrorFailedOpenWrite		30
#define qbhErrorDupChannel			31
#define	qbhErrorBadChannelName		32
#define	qbhErrorNoDirectEncode		33
#define qbhErrorFailedOpenRead		34
#define qbhErrorBadDirection		35
#define qbhErrorFailedRewrite		36
#define qbhErrorFailedRead			37
#define qbhErrorNonExistentBucket	38
#define qbhErrorArrayTooSmall		39
#define qbhErrorCannotMerge			40
#define qbhErrorNonExistentDescr	41
#define qbhErrorParamsNotAllowed	42
#define qbhErrorElabFailed			43
#define qbhErrorFailedWrite			44
#define qbhErrorNonExistentCoverdef	45

/* Provides the tags for the qbhValueRecord structure */
typedef enum {
	qbhUnknownValType,
	qbhIntValType,
	qbhByteValType,
	qbhBitValType,
	qbhBitvecValType,
	qbhABValType,
	qbhLongABValType,

	qbhTimeValType,
	qbhRealValType,
	qbhStringValType,
	qbhInt64ValType
} qbhValueRecordType;

/* Identical to the s_acc_vecval from acc_user.h */
typedef struct _qbhABVal
{
	int aval;
	int bval;
} qbhABVal;


/*
 * An extension of RSV.
 * Adds reference counting and A/B val support.
 * May add aggregated data type support in the future.
 */
typedef struct _qbhValueRecord
{
	int					refs;
	qbhValueRecordType	tag;
	union
	{
		int				v_int;
		unsigned char	v_byte;
		unsigned char	v_bit;
		double			v_time;
		double			v_real;
		char*			v_string;
#if 0
		RdbTime			v_int64;
#endif
		struct
		{
			int			length;
			char*		bits;
		}				v_bitvec;
		struct
		{
			int			length;
			qbhABVal	bits;
		}				v_abval;
		struct
		{
			int			length;
			qbhABVal *	bits;
		}				v_long_abval;
	}					v_value;
} qbhValueRecord;

// Default values for bit values. These are used as indices into the bit value table
// in qbhValRecEncodingInfo below.
#define qbhVal0			0
#define qbhVal1			1
#define qbhValZ			2
#define qbhValX			3

// Enum defining the way bit vectors can be encoded.
typedef enum
{
	qbhBvCharArray,		/* Bit vectors encoded as char arrays with LHS at index 0. */
	qbhBvCharArrayRev,	/* Bit vectors encoded as char arrays with RHS at index 0. */
	qbhBvABVal			/* Bit vectors encoded as Verilog A/B vals. */
} qbhBitVectorEncoding;

/*
 * This structure is used by an SSL to publish the way in which it
 * encodes values into raveSimValue structures.
 *
 * The p_bitValues field contains an array of characters that is 
 * indexed by the 4 qbhVal* values and contains one of the SSL-encoded
 * values.  It is used to convert SSL-encoded values
 * into native values and vice-versa.  If the p_bitValues
 * field is NULL, bit values are assumed to be encoded directly as 
 * qbhVal* values.
 *
 * The v_bvEncoding field tells how bit vectors are encoded.
 */
typedef struct
{
	unsigned char *			p_bitValues;
	qbhBitVectorEncoding	v_bvEncoding;
} qbhValRecEncodingInfo;

/*
 * A structure that describes a name/value pair.
 */
#ifdef __cplusplus
struct qbhNameValuePair
#else
typedef struct
#endif

{
	char*	name;		
	char*	value;		
}

#ifdef __cplusplus
;
#else
qbhNameValuePair;
#endif


#ifndef SKIP_FUNC_DEFS
/*
 * Registers a domain given a name.
 * Returns an exiting domain if its already registered.
 * The domain handle is used to identify the context from
 * which many calls in the API are made.
 *
 *	name		The name that the Hub should associated with this domain.
 *
 *	cb			The array of callbacks to use when communicating with the
 *				domain.  If the domain does not support one of the
 *				callbacks, it should be filled in with 0.
 *
 *	userData	The value of this parameter will be returned in calls
 *				to the domain's callback functions for context.
 *
 *	outHandle	The value of this output parameter will be filled in
 *				with the handle that the Hub has associated with the
 *				domain.  This domain handle must be provided in
 *				several other qbh* routines.
 */
RCEXT qbhError qbhRegisterDomain(	const char *				name,
									qbhDomainCallbacks *cb,
									qbhDomainExecType	execType,
									void *				userData,
									qbhDomainHandle *	outHandle );

RCEXT qbhError qbhUnregisterDomain( qbhDomainHandle	outHandle );


/*
 * Sets the execution style for a previously registered domain.
 */
RCEXT qbhError qbhSetExecType(	qbhDomainHandle 	hDomain,
							 	qbhDomainExecType	execType );

/*
 * This function is used to report the occurrence of events 
 * scheduled in calls to the domain's schedule callback.
 * The callbackId value should be the same one supplied when
 * the callback was registered.
 */
RCEXT qbhError qbhEventOccurred(	void *		callbackId );


/* 
 * Used by qbhDomainExecMaster domains to set the Hub's simulation time 
 * asynchronously.  The time value is given in pico-seconds.
 */
RCEXT qbhError qbhSetCurrentTime(	qbhDomainHandle hDomain, double		tPS );

/*******************************************************
 *
 * Hub loading routines
 *
 * The functions in this header are used only when loading
 * the Hub from a stand-alone C program.
 *
 *******************************************************/

/* 
 * Initializes the Hub for execution without executing a test.
 * All files registered with qbhLoadFile are parsed and any tests
 * registered with qbhLoadTest are elaborated.
 * This function need not be called if qbhRunTest is to be called.
 */
RCEXT qbhError qbhInit(qbhDomainHandle hDomain);

/*
 * Parse command line options to set internal state from command line
 */
RCEXT qbhError qbhParseCmdLine( int argc, char* argv[] );

/*
 * Gives the number of arguments passed to qbhParseCmdLine, or passed to
 * an HDL simulator via the 'argv' option.
 */
RCEXT int qbhArgc();

/*
 * Access an argument previously passed to qbhParseCmdLine, or passed to
 * an HDL simulator via the 'argv' option.
 */
RCEXT char *qbhArgv( int index );

/*
 * Access to all arguments previously passed to qbhParseCmdLine, or passed to
 * an HDL simulator via the 'argv' option.
 */
RCEXT char **qbhArgvAll();

/*
 * Return the name of simulator either from arguments previously passed to
 * qbhParseCmdLine, or from a loaded PLI library.
 */
RCEXT const char *qbhSimulatorName();

/*
 * Sets the given Hub option to the given value.
 */
RCEXT qbhError qbhSetOption( qbhDomainHandle hDomain, char *option, char *value );

/*
 * Registers an implementation of a channel for a specific domain.
 * The attributes of the channel are described by the parameters to the function.
 * If other domains have already registered channels with the same name,
 * the given attributes are checked for consistency with the other registrations.  
 * If this is the first registration of a channel with the given name, then other 
 * domains must be consistent with the definition given here.
 *
 * A callback and userData pointer is associated with this domain's implementation
 * of the named channel, and a handle to the channel is returned in outChan.
 *
 * The attribute-describing parameters are:
 *
 *	type:			A handle to the type of data that will flow over the channel.
 *
 *	kind:			A classification for the channel.
 *
 *	dir:			The direction of data flow over the channel.
 *
 *	mux:			Non-zero if the channel can have multiple drivers.
 *
 *	config:			A configuration string specific to the kind.
 *					If this parameter is NULL, other domains may specify this value.
 *
 */
RCEXT qbhError qbhRegisterChannel( 	char *				name,
									qbhTypeHandle		type,
									qbhChannelKind		kind,
									qbhDirection		dir,
									int					mux,
									char *				config,
									qbhDomainHandle		domain,
									qbhChannelCallback	cb,
									void *				userData,
									qbhChannelHandle*	outChan );


/*
 * Retrieves the userData pointer registered with the given channel 
 * in the given domain.
 * Returns qbhErrorInvalidHandle if the channel was not registered in the domain.
 */
RCEXT qbhError qbhGetChannelData(	qbhDomainHandle		domain,
									qbhChannelHandle	chan,
									void **				userData );
									

/*
 * Called when the given domain wishes to become the consumer (ack-er)
 * for the given channel.  If there is already an ack'er for the channel
 * in another domain, qbhAlreadyAcked is returned.
 * No further action is taken by the HUB: it is the responsibility of
 * the calling domain to draw values from the channel when appropriate.
 */
RCEXT qbhError qbhEnableConsumer(	qbhChannelHandle	chan,
									qbhDomainHandle		hDomain );

/*
 * Called when the given domain no longer wants to be the consumer for
 * the given channel.
 */
RCEXT qbhError qbhDisableConsumer(	qbhChannelHandle	chan,
									qbhDomainHandle		hDomain );

/* 
 * Enables a new driver for the given channel in the given domain.
 * The driverId handle can be any tag required by the calling domain to
 * identify the driver.  This driverId will be supplied to the channel 
 * callback during a qbhValueRequested to identify the driver from 
 * which a value should be requested.
 */
RCEXT qbhError qbhEnableDriver(		qbhChannelHandle	channel,
									qbhDomainHandle		domain,
									qbhHandle			driverId );

/*
 * Removes the given driverId as a driver for the given channel in 
 * from the given domain.
 */
RCEXT qbhError qbhDisableDriver(	qbhChannelHandle	channel,
									qbhDomainHandle		domain,
									qbhHandle			driverId );

/*
 * Gets a value from a specific driver of a specific channel
 * and return it to the specified domain.
 * This function is used when driver for a channel is in a different
 * domain than the consumer for the channel.
 *
 * The HUB will ensure that the value returned is fanned out to
 * all domains except for the domain that is currently the consumer
 * for the channel.
 *
 * If the driver cannot produce a value but an error did not occur,
 * then outVal will contain qbhEmptyHandle.  In this case, the caller
 * can assume that the given channel's callback will be called with 
 * qbhGetValueCompletion when the value is finally available.  If a value handle
 * is returned in outVal, it is to be considered owned by the 
 * driver and so not free'd.
 *
 * The caller is required to ack the value when done with it by calling
 * qbhAckValue().  The value handle must be passed back with the ack call 
 * so that output params can be extracted.
 */
RCEXT qbhError qbhGetDriverValue(	qbhDriverHandle		hDriver,
									qbhChannelHandle	channel,
									qbhDomainHandle		domain,
									qbhValueHandle *	outVal );

/*
 * A driver calls this function when it has a value available to be read
 * by the HUB.  When the HUB has demand on this channel, it will request
 * a value through the domain's registered channel callback.
 */
RCEXT qbhError qbhDriverValueAvailable( qbhDriverHandle		hDriver,
										qbhChannelHandle	channel,
										qbhDomainHandle		domain );

/* 
 * Called by a consumer when it is done with a value that it 
 * obtained from a driver in another domain. 
 * The consumer is responsible for preserving the value handle it 
 * received in qbhGetDriverValue so that it can be returned in qbhAckValue.
 * The value passed back may have been modified to implement output parameters.
 * The value will be deleted (or unreferenced anyway) before returning.
 */
RCEXT qbhError qbhAckValue(			qbhChannelHandle	channel,
									qbhDomainHandle		domain,
									qbhValueHandle		value );
									

/*
 * Register an external implementation of a HUB object from the given domain
 * with the given name and type.  A callback function is supplied to handle
 * activities related to the object.  The userData pointer given will be 
 * supplied in the callback along with the HUB's handle for the object.
 */
RCEXT qbhError qbhRegisterObjectFactory(	qbhDomainHandle	domain,
											char *			name,
											qbhObjectType	objType,
											qbhObjectFactoryCallback callback,
											void *			userData );

#define qbhFatalCode	0
#define qbhErrorCode	1
#define qbhWarningCode	2
#define qbhNoteCode		3

/*
 *  Run-time error reporting.
 */
RCEXT qbhError qbhReportRuntimeError(	qbhDomainHandle domain,
									  	int conditionCode,
									  	char* format,
									  	... );
/*
 * Fills in the given qbhTypeInfoStruct for the given type.
 */
RCEXT qbhError qbhGetTypeInfo(	qbhTypeHandle	   hType,
								qbhTypeInfoStruct *typeInfo );

/* 
 * Called when a value has passed through the given channel under the 
 * control of the given domain and must be fanned out to other domains.
 *
 * The 'feedback' parameter describes what portion of a transaction
 * the event describes:
 *
 *	qbhInstantEvent			This is the only event that will be given
 *
 *	qbhStartEvent			This is the start time for an event that has duration.
 *							
 *	qbhEndEvent				This is the end time for an event that has duration.
 *							The start time is expected to be reported separately.
 *							However, if the startTime parameter is >= 0, then it is used
 *							as the start time.  Otherwise, the start time is
 *							taken from a previously sent start event.
 *
 *	qbhStartEndEvent		A single report is being made at the end time
 *							of the event, and the start time is included
 *							as an absolute time sometime in the past.
 *	
 * To specify an unset start time, use -1.0.
 * 
 */
RCEXT qbhError qbhFanoutValue(		qbhChannelHandle	channel,
									qbhDomainHandle		domain,
									qbhValueHandle		value,
									qbhEventFeedbackType feedback,
									double				startTime );



/**********************************************************************
 *
 * TDB access functions.
 *
 **********************************************************************/
/*
 * Creates a new TDB file handle.
 * If write is non-zero, creates a new file, deleting any file that
 * already existed at the same path.
 *
 * Values of '0' for 'write' are currently not supported.
 *
 * Returns the handle for the open TDB in hTDB on success.
 */
RCEXT qbhError qbhTdbOpenFile(	char*			path,
					  			qbhDirection	dir,
					  			qbhTdbHandle*	hTDB );

/* 
 * Closes the given TDB file.
 */
RCEXT qbhError qbhTdbCloseFile(	qbhTdbHandle	hTDB );

/* 
 * Changes the TDB's access mode from read to write.
 */
RCEXT qbhError qbhRewriteTdb(	qbhTdbHandle	hTDB );
								
/* 
 * Routines for reading coverdefs
 */
RCEXT qbhError qbhReadCover(	qbhTdbHandle		hTDB,
								const char*			hierName,
								qbhCoverdefHandle*	hCdefOut );
RCEXT qbhError qbhReadAllCovers(	qbhTdbHandle		hTDB,
									int					useCdefsFromRave );
RCEXT qbhError qbhGetCover(	qbhTdbHandle		hTDB,
							const char*			hierName,
							qbhCoverdefHandle*	hCdefOut );
/* 
 * Routines for writing coverdefs
 */
RCEXT qbhError qbhWriteCover(	qbhTdbHandle		hTDB,
								const char*			hierName,
								qbhCoverdefHandle	hCdef );
RCEXT qbhError qbhWriteAllCovers(	qbhTdbHandle		hTDB );

/* 
 * Create a new instance of a coverdef
 */
RCEXT qbhError qbhCreateCover(	const char*			cdefName,
								qbhValueHandle*		params,
								int					nParams,
								qbhCoverdefHandle*	hCoverOut);

/*
 * Coverdef traversal routines.
 */
RCEXT qbhError qbhGetTopBucket(	qbhCoverdefHandle	hCdef,
								qbhBucketHandle		*hBucket);
RCEXT qbhError qbhIndexedGetBucket(	qbhBucketHandle		hBucketIn,
									int					*indices,
									int					nIndices,
									qbhBucketHandle		*hBucketOut);
RCEXT qbhError qbhValueGetBucket(	qbhBucketHandle		hBucketIn,
									qbhValueHandle		*values,
									int					nValues,
									qbhBucketHandle		*hBucketOut);
RCEXT qbhError qbhGetFirstBucket(	qbhBucketHandle			hBucketIn,
									qbhBucketIterationStyle	bis,
									qbhBucketHandle			*hBucketOut);
RCEXT qbhError qbhGetNextBucket(	qbhBucketHandle			hBucketIn,
									qbhBucketIterationStyle	bis,
									qbhBucketHandle			*hBucketOut);
RCEXT qbhError qbhGetFirstCoverdef(	qbhCoverdefHandle		hCoverdefIn,
									qbhCoverdefHandle		*hCoverdefOut);
RCEXT qbhError qbhGetNextCoverdef(	qbhCoverdefHandle		hCoverdefIn,
									qbhCoverdefHandle		*hCoverdefOut);


/*
 * Routines for accessing the data in coverdefs.
 */
RCEXT qbhError qbhGetNumDimensions(qbhCoverdefHandle hCdef,
								   int				 *numDimensions);
RCEXT qbhError qbhGetCoverdefName(	qbhCoverdefHandle	hCdef,
									char				**cdefName);
/*
 * Routines for altering the data in coverdefs.
 */
RCEXT qbhError qbhContribute(qbhCoverdefHandle hCdef,
							 qbhValueHandle	   *values,
							 int			   nValues,
							 int			   *contributed);
RCEXT qbhError qbhMergeCoverdefs(qbhCoverdefHandle hSource,
								 qbhCoverdefHandle hTarget);

/*
 * Routines for accessing the data in coverdef buckets.
 */
RCEXT qbhError qbhGetMean(	qbhBucketHandle		hBucket,
							qbhValueHandle		*outVal);
RCEXT qbhError qbhGetMin(	qbhBucketHandle		hBucket,
							qbhValueHandle		*outVal);
RCEXT qbhError qbhGetMax(	qbhBucketHandle		hBucket,
							qbhValueHandle		*outVal);
RCEXT qbhError qbhGetFillLevel(	qbhBucketHandle		hBucket,
								int					*fillLevel);
RCEXT qbhError qbhGetCount(	qbhBucketHandle		hBucket,
							long				*count);
RCEXT qbhError qbhGetNumBuckets(	qbhBucketHandle		hBucket,
									int					subtractExcludes,
									int					*nBuckets);
RCEXT qbhError qbhGetNumHit(	qbhHandle		hBucket,
								int				*nHit);
RCEXT qbhError qbhGetNumFilled(	qbhHandle		hBucket,
								int				*nFilled);
RCEXT qbhError qbhGetPctHit(	qbhHandle		hBucket,
								double			*pctHit);
RCEXT qbhError qbhGetPctFilled(	qbhHandle		hBucket,
								double			*pctFilled);
RCEXT qbhError qbhGetIndices(	qbhBucketHandle		hBucket,
								int					*indices,
								int					*nIndices);
RCEXT qbhError qbhGetBucketName(	qbhBucketHandle		hBucket,
									char				**bucketName);
RCEXT qbhError qbhGetIsExcluded(	qbhBucketHandle		hBucket,
									int					*excluded);

/*
 * Results description tree traversal routines
 */

RCEXT qbhError qbhGetRoot(	qbhTdbHandle			hTdb,
							qbhResultsDescrHandle	*hDescr);
RCEXT qbhError qbhGetDescr(	qbhTdbHandle			hTdb,
							const char				*hierName,
							qbhResultsDescrHandle	*hDescr);
RCEXT qbhError qbhGetSibling(	qbhResultsDescrHandle	hDescrIn,
								qbhResultsDescrHandle	*hDescrOut);
RCEXT qbhError qbhGetParent(	qbhResultsDescrHandle	hDescrIn,
								qbhResultsDescrHandle	*hDescrOut);
RCEXT qbhError qbhGetFirstChild(	qbhResultsDescrHandle	hDescrIn,
									qbhResultsDescrHandle	*hDescrOut);


/*
 * Results description tree access routines
 */
RCEXT qbhError qbhGetDescrName(		qbhResultsDescrHandle	hDescr,
									const char				**hierName);
RCEXT qbhError qbhGetObjectType(qbhResultsDescrHandle	hDescr,
								qbhResultsObjectType	*objType);
RCEXT qbhError qbhGetTypeFromResultsDescr(qbhResultsDescrHandle	hDescr,
										 qbhTypeHandle			*hType);
RCEXT qbhError qbhGetCoverFromResultsDescr(qbhResultsDescrHandle	hDescr,
										   qbhCoverdefHandle		*hCover);

/* 
 * Creates a new stream to which events can be logged for the given TDB.
 *	
 *	hTDB			The handle of a TDB that's current open for write.
 *
 *	channelName		The name to be given to the channel.  The set of channel
 *					names in a single TDB must be unique.
 *
 *	hType			The type handle for values written to the channel.
 *
 *	feedback		Indicates what kind of events will be written for this
 *					channel.  The value of this parameter defines what values
 *					of the 'feedback' parameter will be expected in qbhTdbWriteEvent.
 *								
 *					qbhTdbAddChannel	qbhTdbWriteEvent
 *					----------------------------------------
 *					qbhInstantEvent		qbhInstantEvent		
 *					qbhStartEvent		qbhStartEvent
 *					qbhEndEvent			qbhEndEvent	
 *					qbhStartEndEvent	qbhStartEvent,qbhEndEvent
 *
 */									
RCEXT qbhError qbhTdbAddChannel(qbhTdbHandle			hTDB,
								char*					channelName,
								qbhTypeHandle			hType,
								qbhEventFeedbackType	feedback,
								qbhTdbChannelHandle*	hChannel );

/*
 * Writes an event stored in a qbhEventBuffer to stream for the 
 * given TDB channel.  The event must be encoded in a qbhEventBuffer.
 * If the 'buf' parameter is NULL, then it is assumed the event
 * currently encoded in the TDB file's event buffer is to be written.
 * Otherwise the memory between 'start' and 'next' in the given buffer
 * is written.
 *
 * The event is assumed to have either a start or an end at the 
 * current HUB time.  The current time and the startTime parameter
 * give the event its start and end time values when combined with
 * the feedback type that was specified when the channel was registered.
 *
 *	qbhTdbWriteEvent	qbhTdbAddChannel   Start/end
 *  -----------------	----------------   -------------------------
 *	qbhInstantEvent		qbhInstantEvent		curtime is both start and end.
 *	qbhStartEvent		qbhStartEvent		curtime is both start and end.
 *	qbhStartEvent		qbhStartEndEvent	curtime is start, end is not set.
 *	qbhEndEvent			qbhEndEvent			curtime is end, if start time is >=0, 
 *												it is used, otherwise, start=end.
 *	qbhEndEvent			qbhStartEndEvent	curtime is end, if start time is >=0, 
 *												it is used, otherwise, start time
 *												from previous qbhStartEvent is used.
 *	qbhStartEndEvent	Unused.
 * 
 */
RCEXT qbhError qbhTdbWriteEvent(qbhTdbChannelHandle		hChannel,
								qbhEventBuffer*			buf, 
								qbhEventFeedbackType	feedback,
								double					startTime );

/* 
 * Returns the given open TDB file's event buffer.  Encoding directly
 * into this buffer is the highest performance method of storing events.
 * Each TDB file has one event buffer.  The programmer must ensure that
 * only one value at a time is being encoded into the event buffer.
 */
RCEXT qbhError qbhTdbGetEventBuffer(	qbhTdbChannelHandle	hChannel,
										qbhEventBuffer*		buf );


/* 
 * The functions encode values with specific types into the given buffer,
 * and then advance the pointers in the buffer.  
 * No type handle is given in these calls, so the programmer must ensure that
 * the exactly correct type of value is used.
 */
RCEXT qbhError qbhTdbEncodeInteger(		qbhEventBuffer*	buf, int	val );
RCEXT qbhError qbhTdbEncodeByte( 		qbhEventBuffer*	buf, unsigned char	val );
RCEXT qbhError qbhTdbEncodeBit( 		qbhEventBuffer*	buf, char	val );
RCEXT qbhError qbhTdbEncodeReal( 		qbhEventBuffer*	buf, double	val );
RCEXT qbhError qbhTdbEncodeTime(		qbhEventBuffer*	buf, double	val );
RCEXT qbhError qbhTdbEncodeString(		qbhEventBuffer*	buf, char*	val );
RCEXT qbhError qbhTdbEncodeBitVector(	qbhEventBuffer*	buf, char*	val );
RCEXT qbhError qbhTdbEncodeByteVector(	qbhEventBuffer*	buf, unsigned char*	val, int len );

/* 
 * Starts the encoding of an aggregate value into the given buffer.
 * The number of items in the aggregate value is given in the call, and
 * the programmer must ensure that the same number of calls to a qbhEncode* call
 * are subsequently made.
 */
RCEXT qbhError qbhTdbEncodeArray(		qbhEventBuffer*	buf, qbhTypeHandle hElemType, int nElems );
RCEXT qbhError qbhTdbEncodeRecord(		qbhEventBuffer*	buf, int nFields );
RCEXT qbhError qbhTdbEncodeOp(			qbhEventBuffer*	buf, int nFields, int tag );

/**********************************************************************
 *
 * Value functions
 *
 **********************************************************************/


// Defines the value encoding used by the domain.
// All qbhSetSignalValue and qbhGetSignalValue calls from
// this domain will expect this encoding.  If this function
// is not called, default encoding will be used.  Default
// encoding is ???
RCEXT qbhError qbhSetValRecEncoding(	
									qbhDomainHandle hDomain,
									qbhValRecEncodingInfo *info );

// Initializes a qbhValueRecord.  
// Sets ref count and tag.  Adds a lock if specified.
// (Macro candidate.)
RCEXT qbhError qbhInitValRec( 
							 qbhValueRecord*	val,
							 qbhValueRecordType type,
							 int addLock );

// Reinitializes a qbhValueRecord.  
// Sets ref count and tag. Frees memory in fields. Adds a lock if specified.
// (Macro candidate.)
RCEXT qbhError qbhReinitValRec( 
							   qbhValueRecord*	val,
							   qbhValueRecordType type,
							   int fromLength,
							   int toLength,
							   int addLock );

// mallocs a qbhValueRecord and initializes it.
// (Macro candidate.)
RCEXT qbhError qbhAllocValRec( 
							  qbhValueRecordType type,
							  int addLock,
							  qbhValueRecord** outVal );

// Adds a lock to the value.
// (Macro candidate.)
RCEXT qbhError qbhLockValRec( qbhValueRecord*	val );

// Removes a lock from the value.
// Optionally deletes if the lock count reaches 0.
// (Macro candidate.)
RCEXT qbhError qbhUnlockValRec(
							   qbhValueRecord*	val,
							   int deleteIf0 );

// Used to assert that a qbhValueRecord is not longer
// being referenced. This form should be used by those
// who point at a qbhValueRecord but do not lock it.  If
// there are no more locks remaining, the value is
// deleted.
// (Macro candidate.)
RCEXT qbhError qbhUnrefValRec( qbhValueRecord*	val );

// Returns non-zero if the reference count is 0.
// (Macro candidate.)
RCEXT int qbhValRecIsWritable( qbhValueRecord*	val );

// Copies the value if it is not writable.  Otherwise,
// gives back the same value.  Does not add a lock, and 
// does not expect that the caller has placed a lock.
// (Macro candidate.)
RCEXT qbhError qbhGetWritableValRec( qbhValueRecord*	inVal,
									 qbhValueRecord**	outVal );

// Makes a duplicate of the value using the tag to
// duplicate the data fields.
RCEXT qbhError qbhDuplicateValRec( qbhValueRecord*	inVal,
								   qbhValueRecord**	outVal );

// Copies fields in a value from one to the other. New string or bit vector
// memory is allocated.
RCEXT qbhError qbhCopyValRec( const qbhValueRecord*		inVal,
							  qbhValueRecord*			outVal );

// Gets the length field from the value if it has one.
RCEXT qbhError qbhGetValRecLength( const qbhValueRecord*		inVal,
								   int*							length);


/**********************************************************************
 *
 * Netlist traversal functions
 *
 **********************************************************************/
/*
 * Handle types used
 */
typedef qbhHandle qbhNetlistHandle;


/*
 * Finds a node in the netlist domain with the given pathname
 * An optional parent handle can be used to begin the search.
 * Paths can be separated either by Verilog-style '.' or '/'.
 * An optional prefix followed by a colon can specify a domain name.
 * Example: qbhNetlistFind( "verilog:/testbench/clk", ... );
 * If the prefix isn't used, the char* domain must be specified
 */
RCEXT qbhError qbhNetlistFind( char*				path,
							   char*				domain,
							   qbhNetlistHandle		hParent,
							   qbhNetlistHandle		*outNode,
							   qbhNetlistNodeType	kind );

/*
 * Gets the topmost netlist node for the given domain.
 */
RCEXT qbhError qbhNetlistGetTop( char*					domain,
								 qbhNetlistHandle *		outNode );

/*
 * Gets the next topmost netlist node for the given domain.
 */
RCEXT qbhError qbhNetlistNextTop( qbhNetlistHandle *	outNode );

/*
 * Gives the qbhNetlistNodeType describing the kind of node,
 * and if the node is a qbhNetlistSignal, also gives the signal's
 * data type in a qbhTypeHandle.
 */
RCEXT qbhError qbhNetlistGetType( qbhNetlistHandle		hNode,
								  qbhNetlistNodeType *	outKind,
								  qbhTypeHandle *		outHandle );

/*
 * Gives the non-hierarchical name of the given node.
 * The char* returned is a pointer to storage owned by the Hub which
 * may be overwritten.
 */
RCEXT qbhError qbhNetlistGetName( qbhNetlistHandle		hNode,
								  char **				outName );

/*
 * Gives the hierarchical path of the given node.
 * The char* returned is a pointer to storage owned by the Hub
 * which may be overwritten.
 */
RCEXT qbhError qbhNetlistGetPath( qbhNetlistHandle		hNode,
								  char **				outPath );

/*
 * Gives the first child node for the given parent.
 * For leaf nodes, qbhOK is returned but *outChild is set to
 * qbhEmptyHandle.
 */
RCEXT qbhError qbhNetlistChild( qbhNetlistHandle		hParent,
								qbhNetlistHandle *		outChild );

/*
 * Gives the parent node for the given child.
 * For topmost nodes, qbhOK is returned but *outParent is set to
 * qbhEmptyHandle.
 */
RCEXT qbhError qbhNetlistParent( qbhNetlistHandle		hChild,
								 qbhNetlistHandle *		outParent );

/*
 * Gives the next sibling node for the given node.
 * For last children, qbhOK is returned by *outSibling is set to
 * qbhEmptyHandle.
 */
RCEXT qbhError qbhNetlistSibling( qbhNetlistHandle		hParent,
								  qbhNetlistHandle *	outSibling );



/**********************************************************************
 *
 * Co-simulation functions.
 *
 **********************************************************************/

/*
 * Handle types used
 */
typedef qbhHandle qbhCallbackHandle;

/*
 * Function prototype for signal change callbacks.
 * The userData pointer is the same pointer registered with 
 * qbhRegisterSignalChangeCallback().
 */
typedef qbhError (*qbhSignalChangeCallback)(
											qbhNetlistHandle hNet,
											void *userData,
											qbhValueRecord *value);

/*
 * Registers a callback that will fire whenever the given signal changes value.
 * The userData pointer is passed as an argument to the callback function.
 * A handle is also returned for the callback so that it can be removed later.
 */
RCEXT qbhError qbhRegisterSignalChangeCallback(	qbhNetlistHandle		hNet,
												qbhDomainHandle			hDomain,
												qbhSignalChangeCallback callback,
												void *					userData,
												int						cycleOnly,
												qbhCallbackHandle *		outHandle );

/*
 * Removes a callback function previously installed with 
 * qbhRegisterSignalChangeCallback().
 */
RCEXT qbhError qbhRemoveSignalChangeCallback(		qbhCallbackHandle		hCallback );

/*
 * Gets the value of the given signal.
 * The value is returned in a buffer owned by the Hub, using the formatting
 * previously defined for the domain by qbhSetValRecEncoding.  If no domain is
 * given, or if no value encoding was specified for the domain, default
 * encoding is used.
 * The caller is expected to either add a lock to the value to keep a copy of it,
 * or call qbhUnrefValRec() when done with the value.
 */
RCEXT qbhError qbhGetSignalValue( qbhNetlistHandle		hNet,
								  qbhDomainHandle		hDomain,
								  qbhValueRecord **		value );

/*
 * Sets the value of the given signal.
 * The encoding registered for the given domain is expected in the value.  The
 * caller should expect that the Hub will unreference the value before returning,
 * so if the caller does not wish the buffer to be destroyed, the caller should
 * place a lock on it.
 */
RCEXT qbhError qbhSetSignalValue( qbhNetlistHandle		hNet,
								  qbhDomainHandle		hDomain,
								  qbhValueRecord *		value,
								  double				delay );
/*
 * Callback function signature for qbhRequestDelayedCallback
 */
typedef qbhError (*qbhDelayedCallback)( void *userData );

/*
 * Causes the given callback function to be called after the given amount of time
 * has passed.
 * The userData pointer is passed as a parameter to the callback function.
 */
RCEXT qbhError qbhRequestDelayedCallback( double tPS,
										  qbhDelayedCallback callback,
										  void *userData );

/*
 * Causes a co-simulation to end.
 * If Hub-based co-simulation was started using qbStartCosim, then calling
 * this function will cause qbStartCosim to return.  The simulation can be
 * stopped from there from the HDL simulator.
 */
RCEXT qbhError qbhEndCosim();

/* 
 * Gets the string associated with the given 'define' name.
 * Fills in the outValName buffer with the value.
 * If there is no define by the given name, qbhErrorBadName is returned.
 */
RCEXT qbhError qbhGetDefine( const char *defineName, char *outValName, int outValNameLen );

/*
 * Look up the clock period for the given project & module for the current sim config.
 * If the module name is null, return that for the first non-behavioral module found,
 * and return the default period if all modules are behavioral.
 * If the module name is NOT null, return its clock period if it isn't behavioral;
 * return the default if it is.
 * If the project handle is empty, use the current project.
 */
RCEXT qbhError qbhGetModuleClockPeriod( qbhProjectHandle	hProject,
										const char *moduleName,
										double defaultPeriod,
										double *outPeriod );

/*
 * Look up the output signal names for the given project & module, the current sim config,
 * and the given directive.
 * If the module name or directive name are null, it's an error.
 * If the project handle is empty, use the current project.
 */
RCEXT qbhError qbhGetDirectiveOutputs( qbhProjectHandle	hProject,
									   const char *moduleName,
									   const char *directiveName,
									   char ***outSignalNames );

/*
 * Open a BDW project description file and build objects for it.
 */
RCEXT qbhError qbhOpenProject( const char *			path, 
							   qbhProjectHandle	*	hProject );

/*
 * If there's a BDW current project, return it.
 */
RCEXT qbhError qbhGetCurrentProject( qbhProjectHandle	*	hProject );

/*
 * Destroy the objects representing a BDW project.
 */
RCEXT qbhError qbhCloseProject( qbhProjectHandle	hProject );

/*
 * Find out the representation for a module within a project.
 * The module name and the simConfig name must be non-null, but if the instance name
 * is null the default representation is returned.
 */
RCEXT qbhError qbhGetRepresentation( qbhProjectHandle	hProject,
									 const char *		moduleName,
									 const char *		simConfigName,
									 const char *		instName,
									 int *				representation);

/*
 * Returns true if the given port on the given module is used as a clock
 * anywhere in the hierarchy beneath the module.
 */
RCEXT int qbhGetPortUsedAsClock( qbhProjectHandle	hProj,
								 const char *		moduleName,
								 const char *		portName,
								 const char *		simConfigName );
/*
 * Gets the verilogInputDelay setting for the given or current project.
 */
RCEXT qbhError qbhVerilogInputDelay( qbhProjectHandle	hProj,
									 const char *		simConfigName,
									 double*			delay );
/*
 * Find the VCD file name for the given simConfig. There are two flavors of VCD file
 * that we write: one for a C++ simulation and one for and HDL cosim.
 * The simConfig name and outFileName must be non-null.
 */
RCEXT qbhError qbhGetVCDFileName( qbhProjectHandle	hProject,
								  const char *		simConfigName,
								  int				isHDL,
								  char **			outFileName);

/*
 * Find the FSDB file name for the given simConfig. There are two flavors of FSDB file
 * that we write: one for a C++ simulation and one for and HDL cosim.
 * The simConfig name and outFileName must be non-null.
 */
RCEXT qbhError qbhGetFSDBFileName( qbhProjectHandle	hProject,
								   const char *		simConfigName,
								   int				isHDL,
								   char **			outFileName);
/*
 * Close a simulation log and destroy its handle.
 */
RCEXT qbhError qbhCloseSimLog( qbhSimLogHandle hSimLog );

/*
 * Open an XML simulation log and return a handle to it.
 * If the path is null, use one supplied on the command line.
 * If that path is null, use environment variables to create one.
 * If they are unset, use a default.
 */
RCEXT qbhError qbhOpenSimLog( const char *path, qbhSimLogHandle *hSimLog );

/*
 * Put a message in the simulation log file, including condition code and module name.
 * If the log file does not exist, create it and return the new handle.
 */
qbhError qbhLogMessage( qbhSimLogHandle *hSimLog,
						int conditionCode,
						const char *moduleName,
						const char *text);

/*
 * Mark the simulation log as having passed a test.
 * If the log file does not exist, create it and return the new handle.
 */
qbhError qbhLogPass( qbhSimLogHandle *hSimLog );

/*
 * Mark the simulation log as having failed a test.
 * If the log file does not exist, create it and return the new handle.
 */
qbhError qbhLogFail( qbhSimLogHandle *hSimLog );

/*
 * Put a tag setting in the simulation log file, including name and value.
 * If the log file does not exist, create it and return the new handle.
 */
qbhError qbhLogSetting( qbhSimLogHandle *hSimLog,
						const char *name,
						const char *value );

/*
 * Put a latency measurement in the simulation log file, including module name,
 * min, max, and mean latencies in clock cycles, and an optional label.
 * If the log file does not exist, create it and return the new handle.
 */
qbhError qbhLogLatency( qbhSimLogHandle *hSimLog,
						const char *module,
						int min_latency,
						int max_latency,
						double mean_latency,
						const char *label );

/*
 * Put an instance representation in the simulation log file, including module name,
 * instance name, and the representation.
 * If the log file does not exist, create it and return the new handle.
 */
qbhError qbhLogRepresentation( qbhSimLogHandle *hSimLog,
							   const char *module,
							   const char *instance_path,
							   int representation );


/* 
 * Get the names of the cynthModules used in the given simConfig
 * Returns dynamically allocated strings in a dynamically allocated,
 * NULL-terminated array.  The caller must free both the names
 * and the array.
 */
qbhError qbhGetCynthModuleNames( const char* project_file,
							     const char* sim_config_name,
							     char*** names,
								 int	 omitNoWrapper );

/*
 * Returns true if the current project has any tracing turned on
 * for the given trace type (VCD, FSDB)
 * using the logOptions command in project.tcl.
 */
RCEXT qbhError qbhGetCurrentProjectDoesTrace( qbhTraceType trace_type,
											  int* result );


/*
 * Finds an instruction function for a library module bound to the given set of configParams.
 * The ports list will contain a set of port names, and their directions in the order that
 * the caller will provide them.  This may be different to the order of parameters in the 
 * instruction function itself.
 * Returns a pointer to the instruction function.  When called, the function returned will reorder 
 * parameters accoring to the ports array, and call the function.
 */
RCEXT qbhError qbhGetInstructionFunction( qbhProjectHandle		hProject,
										  const char*           instrName,
										  qbhNameValuePair**	configParams,
										  qbhNameValuePair**	ports,
										  qbhInstructionHandle* hInstr );

/* Execute an instruction given a set of parameters.
   The function described by hInstr is executed, using the input and output parameters
   in 'vals'.  The order of 'vals' has been extabilished by the order of the 'ports'
   array given to qbhGetInstructionFunction().  It will be "straightened out" to match 
   the order of the "real" function before calling it.
   Input parameters are expected to be in qbhValueRecords corresponding to input ports,
   and the caller can extract output values from qbhValueRecords corresponding to output ports.
 */
RCEXT qbhError qbhCallInstructionFunction( qbhInstructionHandle hInstr,
										   qbhValueRecord** vals );
/*
 * Allocates or frees a qbhNameValuePair.
 */
RCEXT qbhNameValuePair* qbhCreateNameValuePair( const char* n, const char* val );
RCEXT void qbhFreeNameValuePair( qbhNameValuePair* pair );
RCEXT void qbhFreeNameValuePairs( qbhNameValuePair** pairs );

RCEXT qbhHandle qbhAddTempAttribValue( qbhProjectHandle hProject, const char* spec, const char* value );
RCEXT void		qbhPushTempAttribValue( qbhProjectHandle hProject, qbhHandle hAttrib );
RCEXT void		qbhPopTempAttribValue( qbhProjectHandle hProject, qbhHandle hAttrib );
RCEXT void      qbhDeleteTempAttribValue( qbhProjectHandle hProject, qbhHandle hAttrib );

typedef void (*qbhInstructionFuncPtr)( qbhValueRecord** params );

#endif
#endif

