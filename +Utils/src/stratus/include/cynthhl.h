/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/
#ifndef cynthhl_h_INCLUDED
#define cynthhl_h_INCLUDED

#if defined STRATUS  &&  ! defined CYN_DONT_SUPPRESS_MSGS
#pragma cyn_suppress_msgs NOTE
#endif	// STRATUS  &&  CYN_DONT_SUPPRESS_MSGS

#if defined STRATUS 
#pragma hls_ip_def
#endif	

#include "stratus_hls.h"

#include	"cyn_enums.h"

#ifndef DONT_USE_NAMESPACE_HLS
using namespace HLS;
#endif


/* Package all of this in a namespace. */
namespace	CYN {

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Definitions that should be visible only to stratus_hls and bdw_extract.
*/
#if defined( STRATUS_HLS ) || defined( BDW_EXTRACT )

/* 
* Macros that should have a "real" definition for stratus_hls and bdw_extract and 
* a void definition otherwise.
*/
#define		CYN_CONST						\
		  const

#else  // STRATUS_HLS  ||  BDW_EXTRACT

#define	 CYN_CONST

#endif // STRATUS_HLS || BDW_EXTRACT

#define  CYN_INITIATION_INTERVAL  HLS_INITIATION_INTERVAL  
#define  CYN_CLOCK_PERIOD         HLS_CLOCK_PERIOD
#define  CYN_FU_CLOCK_PERIOD      HLS_FU_CLOCK_PERIOD
#define	 CYN_REG_SETUP_TIME       HLS_REG_SETUP_TIME
#define	 CYN_REG_DELAY            HLS_REG_DELAY
#define  CYN_REAL_CLOCK_PERIOD    HLS_REAL_CLOCK_PERIOD
#define  CYN_CYCLE_SLACK_VALUE    HLS_CYCLE_SLACK_VALUE
#define  CYN_DPOPT_WITH_ENABLE	  HLS_DPOPT_WITH_ENABLE
#define	 CYN_RESET_TYPE		  HLS_RESET_TYPE

#define     CYN_INLINE_DECL static inline void

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Definitions that differ for stratus_hls and bdw_extract vs. the rest of the
* world.
*/
#if defined( STRATUS_HLS ) || defined( BDW_EXTRACT )

#define		CYN_DIR_BODY ;
#define		CYN_DIR_DECL extern void

#else		// STRATUS_HLS  ||  BDW_EXTRACT

#define		CYN_DIR_BODY {}
#define		CYN_DIR_DECL CYN_INLINE_DECL

#endif		// STRATUS_HLS  ||  BDW_EXTRACT


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Visible/Documented
*/

CYN_DIR_DECL    CYN_BALANCE_EXPR( ENUMS::BAL_DIR_OPT /* options */,
				  const char* /*str*/ = "" )
		  CYN_DIR_BODY

CYN_DIR_DECL	CYN_BREAK_DATAFLOW( const void* /*var*/,
				    const char* /*str*/ = "" )
		  CYN_DIR_BODY

CYN_DIR_DECL    CYN_BOUNDARY( int, const char* /*str*/ = "" )
                  CYN_DIR_BODY

template<typename T1>
CYN_DIR_DECL    CYN_CONSTRAIN( int options,const T1& port1,int distance, const char* str = "" ) {
                 _HLS_CONSTRAIN_ARRAY_MAX_DISTANCE( (void*) &port1 , distance, (char*) str );
		}

template<typename T1>
CYN_DIR_DECL    CYN_CONSTRAIN( int options,const T1& port1,char* pattern, const char* str = "" ) {
                 _HLS_DEFINE_ACCESS_PATTERN( (void*) &port1 , pattern, (char*) str );
		}

template<typename T1, typename T2>
CYN_DIR_DECL CYN_CONSTRAIN( int options,const T1& port1,const T2& port2, int distance, const char* str = "" ) {
                 _HLS_CONSTRAIN_ARRAY_MAX_DISTANCE( (void*) &port1 , (void*) &port2, distance, (char*) str );
		}

CYN_INLINE_DECL	CYN_CYCLE_SLACK( double slack, const char* str = "" ) {
		  HLS_SET_CYCLE_SLACK( slack, str );
		}

CYN_INLINE_DECL	CYN_DEFAULT_INPUT_DELAY( double delay,
					 const char* str = "" ) {
		  HLS_SET_DEFAULT_INPUT_DELAY( delay, str );
		}
CYN_DIR_DECL	CYN_DEFAULT_OUTPUT_REQUIRED( double /*delay*/,
					     const char* /*str*/ = "" )
  		  CYN_DIR_BODY
CYN_INLINE_DECL	CYN_DEFAULT_OUTPUT_OPTIONS( HLS::HLS_OUTPUT_OPTIONS options=HLS::SYNC_HOLD, 
					    double delay = CYN_CALC_TIMING,
					    const char* str = "" ) {
  		  HLS_SET_DEFAULT_OUTPUT_OPTIONS( options );
		  if ((options==ASYNC_HOLD) ||(options==ASYNC_NO_HOLD) ||(options==ASYNC_STALL_NO_HOLD) ||(options==ASYNC_POWER_HOLD) ||(options==ASYNC_HIGH) ||(options==ASYNC_LOW))
		    HLS_SET_DEFAULT_OUTPUT_DELAY( (delay >= 0.0) ? HLS_CLOCK_PERIOD-delay : -1.0 );
		}
CYN_DIR_DECL	CYN_DONT_INLINE( const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_INLINE_DECL	CYN_DPOPT_INLINE( unsigned int opts, const char* name,
				  const char* /*str*/ = "" ) {
			_HLS_DPOPT_REGION( opts, name );
		}
CYN_DIR_DECL	CYN_DPOPT_DEFAULT_INPUT_DELAY( double /*delay*/,
					       const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_DPOPT_INPUT_DELAY( double /*delay*/,
				       const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_DPOPT_DEFAULT_OUTPUT_REQUIRED( double /*delay*/,
						   const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_DPOPT_MAX_OUTPUT_DELAY( double /*delay*/,
					    const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_DPOPT_LATENCY( int /*min*/, int /*max*/,
				   const char* /*str*/ = "" )
		  CYN_DIR_BODY

CYN_INLINE_DECL	CYN_MESSAGE( int msg_no, const char* str = "" ) {
		  HLS_MESSAGE( msg_no, str );
		}

CYN_INLINE_DECL	CYN_FLATTEN( const void* var, const char* str ) {
		  _HLS_FLATTEN_ARRAY( var, HLS::DEFAULT_FLATTEN );
		}
CYN_INLINE_DECL	CYN_FLATTEN( const void* var, unsigned flatten = HLS::ON, ENUMS::FLATTEN_TO target = ENUMS::DEFAULT_ACCESS, const char* str = "" ) {
		  _HLS_FLATTEN_ARRAY( var, (HLS::HLS_FLATTEN_OPTIONS)target );
		}

CYN_INLINE_DECL	CYN_ARRAY_MEMORY( const void* var, const char* mem_type="", const char* comment="" ) {
		  _HLS_MAP_TO_MEMORY( var, mem_type, 0 );
		}
CYN_INLINE_DECL	CYN_ARRAY_REG_BANK( const void* var, const char* comment="") {
		  HLS_MAP_TO_REG_BANK( var );
		}
CYN_INLINE_DECL	CYN_ARRAY_FLATTEN( const void* var, int flatten = HLS::ON, const char* str = "" ) {
		  _HLS_FLATTEN_ARRAY( var, (HLS::HLS_FLATTEN_OPTIONS)flatten );
		}
CYN_INLINE_DECL CYN_ARRAY_DPOPT_ACCESS( const void* var, int flatten = HLS::ON, const char* str = "" ) {
		  _HLS_FLATTEN_ARRAY( var, HLS::DPOPT_FLATTEN );
		}
CYN_INLINE_DECL	CYN_ARRAY_SEPARATE( const void* var, int num_dims=1) {
		  HLS_SEPARATE_ARRAY( var, num_dims );
		}
CYN_DIR_DECL	CYN_ARRAY_SPLIT( const void* /*var*/, int num_split)
		  CYN_DIR_BODY

CYN_DIR_DECL	CYN_DPOPT_ROM( const void* /*var*/, const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_FORK( const char* /*name*/, int /*???*/ ) CYN_DIR_BODY
CYN_DIR_DECL	CYN_JOIN( const char* /*name*/, int /*???*/ ) CYN_DIR_BODY
CYN_INLINE_DECL	CYN_INDEX_MAPPING( const void* var,
				   int mapping,
				   const char* str = "" ) {
		  HLS_MAP_ARRAY_INDEXES( var, (HLS::HLS_INDEX_MAPPING_OPTIONS)mapping );
		}

CYN_INLINE_DECL	CYN_INITIATE( int kind, int interval,
			      const char* str = "" ) {
		  _HLS_PIPELINE_LOOP( HLS::HARD_STALL, interval, str );
		}
CYN_INLINE_DECL	CYN_INITIATE_PARTITION( int interval, const char* str = "" ) {
		  _HLS_PIPELINE_LOOP( HLS::HARD_STALL, interval, str );
		}
CYN_INLINE_DECL	CYN_LATENCY( int min, int max,
			     const char* str ) {
		  HLS_CONSTRAIN_LATENCY( min, max, str );
		}
CYN_DIR_DECL	CYN_METHOD_PROCESSING( ENUMS::METHOD_PROCESSING_OPT /*option*/,
				       const char* /*str*/ = "" )
  		  CYN_DIR_BODY
CYN_INLINE_DECL	CYN_NO_FLATTEN( const void* var, const char* str = "" ) {
		  HLS_FLATTEN_ARRAY( var, HLS::DONT_FLATTEN ); 
		}

CYN_DIR_DECL	CYN_PARTIAL_FLATTEN( const void* /*var*/,
				     const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_PATH_DELAY_LIMIT( const char* /*lim = "off"*/,
				      const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_PATH_DELAY_LIMIT( int /*lim*/, const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_PRINT_LATENCY( const char* /*required str*/ ) CYN_DIR_BODY
CYN_INLINE_DECL	CYN_PROTOCOL( const char* str ) {
		  HLS_DEFINE_PROTOCOL(str);
		}
template <typename T>
CYN_INLINE_DECL	CYN_PROTOCOL_INLINE( double setup, double delay,
				     int pipeline_II, void* context,
				     int flags, T address, const char* str ) {
		  _HLS_DEFINE_FLOATING_PROTOCOL( setup, delay, pipeline_II, context, flags, address, str );
		}
CYN_INLINE_DECL	CYN_ROM_INIT( const void* array,
			      ENUMS::CYN_ROM_DATA_TYPE dt,
			      char* file_name, 
			      const char* str = "" ) {
		  _HLS_INITIALIZE_ROM( array, (HLS::HLS_ROM_FORMAT)dt, file_name );
		}
#define		CYN_ROM_INIT_B( file_name, type, array, required_str )	\
		  CYN_ROM_INIT( type, (array), CYN::ENUMS::CYN_BIN,	\
				(file_name), (required_str) )
#define		CYN_ROM_INIT_H( file_name, type, array, required_str )	\
		  CYN_ROM_INIT( type, (array), CYN::ENUMS::CYN_HEX,	\
				(file_name), (required_str) )

CYN_INLINE_DECL	CYN_ROM_INIT_END() {
		  HLS_END_INITIALIZE_ROM();
		}
CYN_INLINE_DECL	CYN_SCHED_AGGRESSIVE_1( HLS::HLS_UNROLL_OPTIONS option,
				        const char* str = "" ) {
  		  HLS_REMOVE_CONTROL( option, str );
		}
CYN_INLINE_DECL	CYN_SCHED_AGGRESSIVE_1( const char* str = "" ) {
  		  HLS_REMOVE_CONTROL( HLS::ON, str );
		}

CYN_DIR_DECL	CYN_SCHED_OPTION( unsigned /* ENUMS::SCHED_OPT opt*/, 
				  int /*value*/ = HLS::ON, 
				  const char* /*str*/ = "" )
  		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_PRESERVE_SIGNALS(
				  const char* /*str*/ = "" )
  		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_UNROLL( int type, const char* str= "" )
  		  CYN_DIR_BODY

CYN_INLINE_DECL	CYN_STALL_LOOPS( HLS::HLS_UNROLL_OPTIONS type = HLS::ALL,
				 const char* str = "",
				 void* skip_context = 0 ) {
		  HLS_DEFINE_STALL_LOOP( type, str );
		}

template<typename HLS_T1>
HLS_INLINE_DECL CYN_SET_STALL_VALUE( const HLS_T1&  io,
                                     int            value,
				     const char*    str ) {
                    _HLS_SET_STALL_VALUE( &io, value, true, 0, 0 );
                }

template<typename HLS_T1>
HLS_INLINE_DECL CYN_SET_STALL_VALUE( const HLS_T1&  io,
                                     int            value,
				     void*	    skip = 0,
				     void*	    goes_with = 0 ) {
                    _HLS_SET_STALL_VALUE( &io, value, true, skip, goes_with );
                }

template<typename HLS_T1>
HLS_INLINE_DECL CYN_SET_STALL_LOCAL( const HLS_T1&  io,
                                     int            value,
				     const char*    str = "" ) {
                    _HLS_SET_STALL_VALUE( &io, value, false, 0, 0 );
                }

CYN_DIR_DECL	CYN_TIMING_AGGRESSION( int /*lvl*/, const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_INLINE_DECL	CYN_UNROLL( int type, int iterations,
			    const char* str = "" ) {
		  _HLS_UNROLL_LOOP( (HLS::HLS_UNROLL_OPTIONS)type, iterations, str );
		}

CYN_DIR_DECL	CYN_WRITE_AHEAD( int /* max_distance */, const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_WRITE_AHEAD( const char* /* reading_partition */, int /* max_distance */,
			    const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_INLINE_DECL	CYN_COALESCE( HLS::HLS_UNROLL_OPTIONS opts, const char* str = "" ) {
                  HLS_COALESCE_LOOP( opts, str );
		}
CYN_INLINE_DECL	CYN_COALESCE_PIPE( HLS::HLS_UNROLL_OPTIONS opts, const char* str = "" ) {
		  HLS_COALESCE_LOOP( CONSERVATIVE, str );
		}
CYN_INLINE_DECL	CYN_COALESCE_NEST( HLS::HLS_UNROLL_OPTIONS opts, const char* str = ""  ) {
		  HLS_COALESCE_LOOP( ALL, str );
		}

CYN_DIR_DECL	CYN_DEFAULT_INTERFACE( const char* /*iface_name*/, const char* /* res_name */ = "" )
                  CYN_DIR_BODY


template<class T> 
CYN_INLINE_DECL CYN_STABLE_INPUT( T& port, const char *str = "" ) { 
  _HLS_ASSUME_STABLE(HLS::HLS_ASSUME_STABLE_DEFAULT, &(port), str); 
}
template<class T> 
CYN_INLINE_DECL CYN_STABLE_INPUT( HLS::HLS_ASSUME_STABLE_OPTIONS opts, T& port, const char *str = "" ) { 
  _HLS_ASSUME_STABLE(opts, &(port), str); 
}
template<class T1, class T2> 
CYN_INLINE_DECL CYN_STABLE_INPUTS( T1& port1, T2 &port2, const char *str = "" ) { 
  _HLS_ASSUME_STABLE_RANGE(HLS::HLS_ASSUME_STABLE_DEFAULT, &(port1), &(port2), str); 
}
template<class T1, class T2> 
CYN_INLINE_DECL CYN_STABLE_INPUTS( HLS::HLS_ASSUME_STABLE_OPTIONS opts, T1& port1, T2& port2, const char *str = "" ) { 
  _HLS_ASSUME_STABLE_RANGE(opts, &(port1), &(port2), str); 
}

#define		CYN_RESET_BLOCK( comment ) \
		  CYN_SCHED_AGGRESSIVE_1( OFF, "hls_reset_block_" comment ); \
		  HLS_DEFINE_PROTOCOL("hls_reset_block_" comment )
/* 
* These directives reference ports.  Hiding their contents from all except
* stratus_hls makes them easier to use with modular interfaces that have TLM
* versions.
*/
#ifdef STRATUS_HLS
CYN_DIR_DECL	_CYN_SCALAR_REPLACEMENT( void* /*port*/, const char* /*str*/ = "" )
		  CYN_DIR_BODY
#define		_CYN_SCALAR_REPLACEMENT( port, required_str )		\
		  _CYN_SCALAR_REPLACEMENT( &(port), (required_str) )

CYN_DIR_DECL    CYN_GUARD_WRITES( void* /*port*/,
				  const char* /*str*/ = "" ) CYN_DIR_BODY
#define		CYN_GUARD_WRITES( port, required_str )		\
		  CYN_GUARD_WRITES( &(port), (required_str) )


template <typename T>
CYN_INLINE_DECL	CYN_INPUT_DELAY( T& port, double delay,
				 const char* str = "" ) {
		  HLS_SET_INPUT_DELAY( port, delay );
		}

template <typename T>
CYN_INLINE_DECL	CYN_BOUNDED_VALUE( T& port, const char* str = "" ) {
		  _HLS_SET_IS_BOUNDED( &port, str );
		}

template <typename CYN_T1, typename CYN_T2>
CYN_INLINE_DECL	CYN_BOUNDED_VALUES( CYN_T1& port1, CYN_T2& port2, const char* str = "" ) {
		  _HLS_SET_ARE_BOUNDED( &port1, &port2, str );
		}

// Pre-release versions used the name CYN_MUTEXED_VALUE.  Keep backwards compatibility.
#ifndef CYN_MUTEXED_VALUE
#define CYN_MUTEXED_VALUE CYN_BOUNDED_VALUE
#endif
#ifndef CYN_MUTEXED_VALUES
#define CYN_MUTEXED_VALUES CYN_BOUNDED_VALUES
#endif

CYN_DIR_DECL	CYN_OUTPUT_REQUIRED( void* /*port*/, double /*delay*/,
				     const char* /*str*/ = "" )
		  CYN_DIR_BODY
CYN_DIR_DECL	_CYN_PRESERVE( void* /*port*/ )
		  CYN_DIR_BODY
template<class T>
void CYN_OUTPUT_OPTIONS( T& port,
				     HLS::HLS_OUTPUT_OPTIONS options=HLS::SYNC_HOLD, 
				     double delay = CYN_CALC_TIMING,
				     const char* str = 0 ) {
		  _HLS_SET_OUTPUT_OPTIONS( (void*)&port, options );
		  if ((options==ASYNC_HOLD) ||(options==ASYNC_NO_HOLD) ||(options==ASYNC_STALL_NO_HOLD) ||(options==ASYNC_POWER_HOLD) ||(options==ASYNC_HIGH) ||(options==ASYNC_LOW))
		    _HLS_SET_OUTPUT_DELAY( (void*)&port, (delay >= 0.0) ? HLS_CLOCK_PERIOD-delay : -1.0 );
		}

#define		CYN_OUTPUT_REQUIRED( port, delay, required_str )	\
		  CYN_OUTPUT_REQUIRED( &(port), (delay), (required_str) )

#else	// defined STRATUS_HLS
#define         CYN_GUARD_WRITES( port, required_str )
#define		CYN_INPUT_DELAY( port, delay, required_str )
#define		_CYN_PRESERVE( port )
#define		CYN_BOUNDED_VALUE( port, required_str )
#define		CYN_BOUNDED_VALUES( port1, port2, required_str )
#ifndef CYN_MUTEXED_VALUE
#define CYN_MUTEXED_VALUE CYN_BOUNDED_VALUE
#endif
#ifndef CYN_MUTEXED_VALUES
#define CYN_MUTEXED_VALUES CYN_BOUNDED_VALUES
#endif

#define		CYN_OUTPUT_REQUIRED( port, delay, required_str )
template<class T>
CYN_INLINE_DECL	CYN_OUTPUT_OPTIONS( const T& port,
				     HLS::HLS_OUTPUT_OPTIONS options=HLS::SYNC_HOLD, 
				     double delay = CYN_CALC_TIMING,
				     const char* str = 0 ) {}
#endif	// defined STRATUS_HLS

/* 
* These directives can reference an arbitrary variable or an SC_MODULE's 
* method, so there isn't a good way to declare the formal parameters (and g++ 
* doesn't support passing everything we support through "...").
*/
#if	defined( STRATUS_HLS ) || defined( BDW_EXTRACT )

CYN_DIR_DECL	CYN_ASYNC( ... ) CYN_DIR_BODY
CYN_DIR_DECL	CYN_BIND( ... ) CYN_DIR_BODY
CYN_DIR_DECL	CYN_MAP_INSTRUCTION(  const char* /*name*/, ... )
		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_MAP_INSTRUCTION(  int /*opts*/, const char* /*name*/, ... )
		  CYN_DIR_BODY
CYN_DIR_DECL	CYN_CONFIG_INSTRUCTION(  const char* /*param*/, ... )
		  CYN_DIR_BODY
template <typename T>
CYN_INLINE_DECL	CYN_BIND_INPUT( const char* /*port_name*/, T& in_val ) {}
template <typename T>
CYN_INLINE_DECL	CYN_BIND_OUTPUT( const char* /*port_name*/, T& out_val ) {}
CYN_DIR_DECL	CYN_ATTRIB_VALUE(  const char* /*attrib*/, ... )
		  CYN_DIR_BODY
#define		CYN_SUGGEST_LIB_CONFIG( libname, mname )
#define		CYN_MEM_READ_TX( setup, delay, pipeline_II, context,	\
				 addr_param, flags, required_str )	\
		  HLS_DEFINE_FLOATING_PROTOCOL( (setup), (delay), (pipeline_II),	\
				       (context),(CYN_MEM_READ_TX | flags), \
				       (addr_param), "mem_read"##required_str )

#define		CYN_MEM_WRITE_TX( setup, pipeline_II, context,		\
				  addr_param, flags, required_str )	\
		  HLS_DEFINE_FLOATING_PROTOCOL( (setup), (0), (pipeline_II),	\
				       (context), (CYN_MEM_WRITE_TX | flags), \
				       (addr_param),			\
				       "mem_write"##required_str )

#define         CYN_PROTOCOL_TX( setup, delay, pipeline_II, flags,	\
				 required_str )				\
          	  HLS_DEFINE_FLOATING_PROTOCOL( (setup), (delay), (pipeline_II),	\
				       0, (CYN_CP_TX | flags), 0,	\
				       "cptx_"##required_str)

CYN_DIR_DECL	CYN_SYNC( ... ) CYN_DIR_BODY
#define		CYN_VOLATILE  HLS_SET_IS_VOLATILE
CYN_DIR_DECL	CYN_DONT_CARE( ... ) CYN_DIR_BODY
CYN_DIR_DECL	CYN_SINGLE_CYCLE( ... ) CYN_DIR_BODY
CYN_DIR_DECL	CYN_NO_RENAME( ... ) CYN_DIR_BODY
CYN_DIR_DECL	CYN_MARK_TX_CALL( ... ) CYN_DIR_BODY
CYN_DIR_DECL	CYN_CONSTANT_SET_VALUE( ... ) CYN_DIR_BODY
CYN_DIR_DECL	CYN_ASSUME_VALUE( ... ) CYN_DIR_BODY
template <typename T>
CYN_INLINE_DECL	CYN_ALT_CLOCK_PERIOD( T& clock, double period ) {
	_HLS_SET_CLOCK_PERIOD( &clock, period );
}
#else	// defined( STRATUS_HLS ) || defined( BDW_EXTRACT )
 
#define		CYN_ASYNC( thread, port, str )
#define		CYN_BIND( local, port )
#define		CYN_MEM_READ_TX( setup, delay, pipeline_II, context,	\
				 addr_param, flags, required_str )
#define		CYN_MEM_WRITE_TX( setup, pipeline_II, context,		\
				  addr_param, flags, required_str )
#define         CYN_PROTOCOL_TX(setup,delay,pipeline_II,flags,required_str)
#define		CYN_PROTOCOL_INLINE( setup, delay, c, d, e, f, g )
#define		CYN_SYNC( thread, port, str )
#define		CYN_VOLATILE HLS_SET_IS_VOLATILE
#define		CYN_DONT_CARE( var )
#define		CYN_SINGLE_CYCLE( var )
#define		CYN_NO_RENAME( var )
#define		CYN_MARK_TX_CALL( var )
template <class T>
CYN_DIR_DECL	CYN_CONSTANT_SET_VALUE( T&, ... ) CYN_DIR_BODY
template <class T>
CYN_DIR_DECL	CYN_ASSUME_VALUE( T&, ... ) CYN_DIR_BODY
template <class T>
CYN_DIR_DECL	CYN_ALT_CLOCK_PERIOD( T&, ... ) CYN_DIR_BODY

#if defined(__GNUC__) && BDW_HUB
#define		CYN_MAP_INSTRUCTION( name ) \
    static esc_instruction_func_dispatcher cyn_map_instruction_dispatcher( name ); \
    cyn_map_instruction_dispatcher.init()

#define		CYN_CONFIG_INSTRUCTION( name, value ) \
    cyn_map_instruction_dispatcher.add_param( name, value )

#define		CYN_BIND_INPUT( name, ref ) \
    cyn_map_instruction_dispatcher.add_port( ref, name, true )

#define		CYN_BIND_OUTPUT( name, ref ) \
    cyn_map_instruction_dispatcher.add_port( ref, name, false )

#define		CYN_ATTRIB_VALUE( spec, value ) \
    static esc_temp_attrib_value  CYN_LINENAME(esc_temp_attrib_value_s_)( spec, value, 0 ); \
    esc_temp_attrib_value  CYN_LINENAME(esc_temp_attrib_value_)( &(CYN_LINENAME(esc_temp_attrib_value_s_)) )
#define		CYN_SUGGEST_LIB_CONFIG( libname, mname )
#else  // defined(__GNUC__) && BDW_HUB
}
#include <systemc.h>
namespace	CYN {

#ifndef STRATUS

/* Definitions for runtime feedback about unavailable library functions for 
   behavioral simulations when no runtime system is available to generate them.
 */
struct cyn_instruction_param_t {

  cyn_instruction_param_t( const char* n, int v ) : pname(n) { char vs[16]; sprintf(vs,"%d",v); pval = vs; }
  cyn_instruction_param_t( const char* n, const char* v ) : pname(n), pval(v) {}
  cyn_instruction_param_t( const cyn_instruction_param_t& other ) : pname(other.pname), pval(other.pval) {}

  static std::string tcl_sample( const std::string& is, std::vector<cyn_instruction_param_t>& params ) {
    std::string s;
    s += is + "attribValues \\\n";
    for ( std::vector<cyn_instruction_param_t>::iterator it=params.begin(); it != params.end(); it++ ) {
      s += is + "    {" + (*it).pname + " " + (*it).pval + "} \\\n";
    }
    return s;
  }

  std::string pname;
  std::string pval;

} ;

static std::vector<cyn_instruction_param_t> cyn_cur_instruction_params;
static std::string cyn_cur_instruction_name;

#define		CYN_MAP_INSTRUCTION( name ) cyn_cur_instruction_name = name; cyn_cur_instruction_params.clear()
#define		CYN_CONFIG_INSTRUCTION( name, value ) cyn_cur_instruction_params.push_back( cyn_instruction_param_t((name),(value)) )
#define		CYN_BIND_INPUT( name, ref ) 
#define		CYN_BIND_OUTPUT( name, ref ) 
#define		CYN_ATTRIB_VALUE( spec, value ) 
#define         CYN_SUGGEST_LIB_CONFIG( libname, in_modnames ) \
  static bool cyn_suggestion_emitted = false; \
  if ( !cyn_suggestion_emitted ) { \
    cerr << "*\n* ERROR: A " << libname << " library function is unavailable for simulation.\n"; \
    std::string modnames = in_modnames; \
    cerr << "*\n*        The '" << cyn_cur_instruction_name << "' instruction is available in the following library modules:\n*\n*          " << modnames << "\n"; \
    for ( unsigned int imn=0; imn < modnames.length(); imn++ ) { if (modnames[imn] == ',') {modnames.resize(imn);break;} } \
    cerr << "*\n*        Suggested addition for library definition file:\n"; \
    cerr << "*\n*          cellMathModule <name> " << modnames << " {\n"; \
    cerr << cyn_instruction_param_t::tcl_sample( "*            ", cyn_cur_instruction_params ); \
    cerr << "*          }\n"; \
    cyn_suggestion_emitted = true; \
  }
#else // STRATUS
#define		CYN_MAP_INSTRUCTION( name ) 
#define		CYN_CONFIG_INSTRUCTION( name, value ) 
#define		CYN_BIND_INPUT( name, ref ) 
#define		CYN_BIND_OUTPUT( name, ref ) 
#define		CYN_ATTRIB_VALUE( spec, value ) 
#define         CYN_SUGGEST_LIB_CONFIG( libname, in_modnames ) 
#endif // STRATUS
          
#endif // defined(__GNUC__) && BDW_HUB

#endif	// defined( STRATUS_HLS ) || defined( BDW_EXTRACT )

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* These directives can reference an arbitrary variable so there isn't a
* good way to declare the formal parameters (and g++ doesn't support
* passing everything we support through "...").
* This is like the above group, but include stratus_vlg.
*/
#if	defined( STRATUS_HLS ) || defined( STRATUS_VLG ) || defined( BDW_EXTRACT )

#define		CYN_INLINE_MODULE int hls_inline_module
#define		CYN_EXPOSE_PORT( on_off, port ) \
		  CYN_EXPOSE_PORTS( on_off, port, port )
#if	defined( STRATUS_VLG )
#define		CYN_EXPOSE_PORTS( on_off, start, end ) \
		  int hls_expose_ports_##start##_HLS_SEP_##end
#else	// defined( STRATUS_VLG)
#define		CYN_EXPOSE_PORTS( on_off, start, end ) \
		  HLS::hls_enum<on_off> hls_expose_ports_##start##_HLS_SEP_##end
#endif	// defined( STRATUS_VLG)
#define		CYN_METAPORT int hls_meta_port
template <class T>
CYN_INLINE_DECL	CYN_SUPPRESS_MSG_SYM( unsigned int msgId, T& sym ) {
		  HLS_SUPPRESS_MSG_SYM( msgId, sym );
		}

#else	// defined( STRATUS_HLS ) || defined( STRATUS_VLG ) || defined( BDW_EXTRACT )

#define		CYN_INLINE_MODULE
#define		CYN_EXPOSE_PORTS( on_off, start, end )
#define		CYN_EXPOSE_PORT( on_off, port )
#define		CYN_METAPORT
#define		CYN_SUPPRESS_MSG_SYM( id, sym, ... )


#endif	// defined( STRATUS_HLS ) || defined( STRATUS_VLG ) || defined( BDW_EXTRACT )


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Binding directives need to be visible _only_ to stratus_hls
*/
#ifdef	STRATUS_HLS
CYN_DIR_DECL	CYN_MEM_BIND( const void* /*array*/,
			      void/*sc_module*/* /*mem_inst*/,
			      int /*options*/, 
			      const void* /*clock*/,
			      const char* /*str*/ = "" )
		  CYN_DIR_BODY
#define		CYN_MEM_INST( mem_type, mem_inst, required_str )	\
		  mem_type* mem_inst
#define		CYN_MEM_BIND_TYPE( array, mem_type, required_str )	\
		{							\
		  CYN_MEM_INST( mem_type, mem_type##__##array, required_str ); \
		  CYN_MEM_BIND( array, &mem_type##__##array, 0, 0, required_str );\
		}
#define		CYN_MEM_BIND_CLK( array, mem_type, clock, required_str )	\
		{							\
		  CYN_MEM_INST( mem_type, mem_type##_bind__, required_str ); \
		  CYN_MEM_BIND( array, &mem_type##_bind__, 0, &clock, required_str );\
		}
#else	// STRATUS_HLS
#define		CYN_MEM_BIND( array, mem_inst, options, clock, required_str )
#define		CYN_MEM_BIND_TYPE( array, mem_type, required_str )
#define		CYN_MEM_INST( type, name, required_str )
#define		CYN_MEM_BIND_CLK( array, mem_type, clock, required_str )
#endif	// STRATUS_HLS

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* ROM initialization directives have different implementations for
*   stratus_hls, stratus_vlg, and "other" (e.g. g++).
*/
#if	defined STRATUS_HLS

#define		CYN_ROM_INIT( type, array, dt, file_name, required_str )      \
		  CYN_ROM_INIT( (array), (dt), (file_name), (required_str) );\
		  cyn_rom_interp_init< type, sizeof(array)/sizeof(type) >(  \
		    (const type*) (array), (dt), (file_name), (required_str)\
		  );							      \
		  CYN_ROM_INIT_END()

  

#elif	defined STRATUS_VLG

#define		CYN_ROM_INIT( type, array, dt, file_name, required_str )\
		  extern void cyn_rom_init( ENUMS::CYN_ROM_DATA_TYPE,	\
					    char*, const void* );	\
		  cyn_rom_init( (dt), (file_name), (array) )

#else

#define		CYN_ROM_INIT( type, array, dt, file_name, required_str )     \
		  cyn_rom_init<type>( sizeof( array ), (const type*) (array),\
				      (dt), (file_name),		     \
				      (required_str), __FILE__, __LINE__ )
#endif

#undef		CYN_DIR_BODY
#undef		CYN_DIR_DECL

//
// CYN_PRESERVE definitions.
//

#if	defined( STRATUS_HLS ) 

}
#include "systemc.h"
namespace CYN {

template<class T>
void CYN_PRESERVE( sc_signal<T>& sig, bool even_if_no_use_def=true ) {
		  _HLS_PRESERVE_SIGNAL( (void*)&sig, even_if_no_use_def );
		  CYN_VOLATILE( sig, even_if_no_use_def );
		}

template <class T, int CYN_N>
void CYN_PRESERVE( sc_signal<T> (&sig)[CYN_N], bool even_if_no_use_def=true) {
		  _HLS_PRESERVE_SIGNAL( sig, even_if_no_use_def );
		  CYN_VOLATILE( sig, even_if_no_use_def );
		}

template <class T, int CYN_N, int CYN_M>
void CYN_PRESERVE( sc_signal<T> (&sig)[CYN_N][CYN_M], bool even_if_no_use_def=true ) {
		  _HLS_PRESERVE_SIGNAL( sig, even_if_no_use_def );
		  CYN_VOLATILE( sig, even_if_no_use_def );
		}

template <class T, int CYN_N, int CYN_M, int CYN_O>
void CYN_PRESERVE( sc_signal<T> (&sig)[CYN_N][CYN_M][CYN_O], bool even_if_no_use_def=true ) {
		  _HLS_PRESERVE_SIGNAL( sig, even_if_no_use_def );
		  CYN_VOLATILE( sig, even_if_no_use_def );
		}

template <class T, int CYN_N, int CYN_M, int CYN_O, int CYN_P>
void CYN_PRESERVE( sc_signal<T> (&sig)[CYN_N][CYN_M][CYN_O][CYN_P], bool even_if_no_use_def=true ) {
		  _HLS_PRESERVE_SIGNAL( sig, even_if_no_use_def );
		  CYN_VOLATILE( sig, even_if_no_use_def );
		}


#else

template<class T>
void CYN_PRESERVE( T& v, bool even_if_no_use_def=true) {}

#endif

}; /* namespace CYN */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* A convenience macro that can be used to build a name from two char* 
* strings.  A common application is for the formation of name strings
* for member ports in metaports where the metaport class is not an sc_module.
*/
#if !defined(STRATUS_HLS) && !defined(BDW_EXTRACT)
#define CYN_CAT_NAMES( n1, n2 ) \
  ( (n1 && *n1) ? ((const char*)n1 + std::string("_" n2)).c_str() : (const char*)n2 )
#else
#define CYN_CAT_NAMES( n1, n2 ) n1
#endif

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Helper code for ROM initialization.
*/
#include	"cyn_rom.h"

#ifndef	DONT_USE_NAMESPACE_CYN
using namespace CYN;
#ifndef	DONT_USE_NAMESPACE_CYN_ENUMS
using namespace CYN::ENUMS;
#endif	// DONT_USE_NAMESPACE_CYN_ENUMS
#endif	// DONT_USE_NAMESPACE_CYN

// MACRO THAT RETURNS THE INTEGER LOG BASE 2 OF NUMBERS THROUGH 32 BITS:

#define CYN_LOG2(X) \
    (X > 2147483647 ? 32 : \
    (X > 1073741823 ? 31 : \
    (X > 536870911 ? 30 : \
    (X > 268435455 ? 29 : \
    (X > 134217727 ? 28 : \
    (X > 67108863 ? 27 : \
    (X > 33554431 ? 26 : \
    (X > 16777215 ? 25 : \
    (X > 8388607 ? 24 : \
    (X > 4194303 ? 23 : \
    (X > 2097151 ? 22 : \
    (X > 1048575 ? 21 : \
    (X > 524287 ? 20 : \
    (X > 262143 ? 19 : \
    (X > 131071 ? 18 : \
    (X > 65535 ? 17 : \
    (X > 32767 ? 16 : \
    (X > 16383 ? 15 : \
    (X > 8191 ? 14 : \
    (X > 4095 ? 13 : \
    (X > 2047 ? 12 : \
    (X > 1023 ? 11 : \
    (X > 511 ? 10 : \
    (X > 255 ? 9 : \
    (X > 127 ? 8 : \
    (X > 63 ? 7 : \
    (X > 31 ? 6 : \
    (X > 15 ? 5 : \
    (X > 7 ? 4 : \
    (X > 3 ? 3 : \
    (X > 1 ? 2 : 1 )))))))))))))))))))))))))))))))

#if !defined(SC_API_VERSION_STRING) // #### && !defined(CYNTH_HL)
    //=========================================================================
    // watching CONSTRUCT: this is for backward compatibility to 2.0.1 
	//                     environments for 2.1 designs
	//                     this is a macro to make the watching visible
	//                     to existing cynth code.
    //=========================================================================

#   define reset_signal_is( port, level ) watching( port.delayed() == level );

#endif //!defined(SC_API_VERSION_STRING) && !defined(CYNTH_HL)

namespace CYN {
#if defined(STRATUS_HLS)
template <typename T, typename CYN_T2, typename CYN_T3>
extern uint64 CYN_MASKED_READ( T mread, CYN_T2 val, CYN_T3 m );

template <typename T, int CYN_N, typename CYN_T2, typename CYN_T3>
static void cynw_masked_write( T (&ar)[CYN_N], uint64 ad, CYN_T2 d, CYN_T3 m )
{
  ar[ad] = CYN_MASKED_READ( ar[ad], d, m );
}
#else
template <typename T, typename CYN_T2, typename CYN_T3>
inline T CYN_MASKED_READ( T v, CYN_T2 d, CYN_T3 m )
{
  return (v & (~(T)m)) | ((T)d & (T)m);
}

template <typename T, int CYN_N, typename CYN_T2, typename CYN_T3>
inline void cynw_masked_write( T (&ar)[CYN_N], uint64 ad, CYN_T2 d, CYN_T3 m )
{
  ar[ad] = CYN_MASKED_READ( ar[ad], d, m );
}
#endif
}

#endif // cynthhl_h_INCLUDED
