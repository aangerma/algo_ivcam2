/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/
#ifndef cyn_enums_h_INCLUDED
#define cyn_enums_h_INCLUDED

#if defined STRATUS && ! defined _STRATUS_internal_
#pragma hls_ip_def
#endif	

#include "hls_enums.h"

namespace	CYN {

namespace	ENUMS {

/* 
* Guard "obvious" enum names by defining a macro for them.
* The "then" part of the conditional gives the best possible messaging
*   from g++ and bdw_extract when the user's macro definition is processed 
*   before this file. The "else" part gives us an unconditional definition of 
*   the macro so that there will at least be a warning issued if a conflicting 
*   user definition is processed later.
* Do all this because g++ gives a much better message for a redefined macro 
*   than if a macro instance appears in an enum definition or where an enum 
*   literal is expected.
* Don't do all this if DONT_USE_NAMESPACE_CYN_ENUMS is defined. In this case, 
*   we assume that the user will use the "[CYN::]ENUMS::" prefix on any
*   identifier he wants to get from here and will deal with any conflicting
*   macros on their own.
*/
#ifndef	DONT_USE_NAMESPACE_CYN_ENUMS
#ifdef AGGRESSIVE
#  define AGGRESSIVE
#  error  "AGGRESSIVE" is reserved by Cynthesizer. It may not be #defined by the user.
#else	/* AGGRESSIVE */
#  define AGGRESSIVE AGGRESSIVE
#endif /* AGGRESSIVE */
#ifdef ALL
#  define ALL
#  error  "ALL" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* ALL */
#  define ALL	ALL
#endif /* ALL */
#ifdef COMPACT
#  define COMPACT
#  error  "COMPACT" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* COMPACT */
#  define COMPACT	COMPACT
#endif /* COMPACT */
#ifdef COMPLETE
#  define COMPLETE
#  error  "COMPLETE" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* COMPLETE */
#  define COMPLETE	COMPLETE
#endif /* COMPLETE */
#ifdef CONSERVATIVE
#  define CONSERVATIVE
#  error  "CONSERVATIVE" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* CONSERVATIVE */
#  define CONSERVATIVE	CONSERVATIVE
#endif /* CONSERVATIVE */
#ifdef METHOD_DPOPT
#  define METHOD_DPOPT
#  error  "METHOD_DPOPT" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* METHOD_DPOPT */
#  define METHOD_DPOPT	METHOD_DPOPT
#endif /* METHOD_DPOPT */
#ifdef METHOD_TRANSLATE
#  define METHOD_TRANSLATE
#  error  "METHOD_TRANSLATE" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* METHOD_TRANSLATE */
#  define METHOD_TRANSLATE	METHOD_TRANSLATE
#endif /* METHOD_TRANSLATE */
#ifdef METHOD_SYNTHESIZE
#  define METHOD_SYNTHESIZE
#  error  "METHOD_SYNTHESIZE" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* METHOD_SYNTHESIZE */
#  define METHOD_SYNTHESIZE	METHOD_SYNTHESIZE
#endif /* METHOD_SYNTHESIZE */
#ifdef MEM_DISTANCE
#  define MEM_DISTANCE
#  error  "MEM_DISTANCE" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* MEM_DISTANCE */
#  define MEM_DISTANCE	MEM_DISTANCE
#endif /* MEM_DISTANCE */
#ifdef ACCESSES_MUTUALLY_EXCLUSIVE
#  define ACCESSES_MUTUALLY_EXCLUSIVE
#  error  "ACCESSES_MUTUALLY_EXCLUSIVE" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* ACCESSES_MUTUALLY_EXCLUSIVE*/
#  define ACCESSES_MUTUALLY_EXCLUSIVE	ACCESSES_MUTUALLY_EXCLUSIVE
#endif /* ACCESSES_MUTUALLY_EXCLUSIVE*/
#ifdef OFF
#  define OFF
#  error  "OFF" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* OFF */
#  define OFF		OFF
#endif /* OFF */
#ifdef ON
#  define ON
#  error  "ON" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* ON */
#  define ON		ON
#endif /* ON */
#ifdef SIMPLE
#  define SIMPLE
#  error  "SIMPLE" is reserved by Cynthesizer. It may not be #defined by the user.
#else /* SIMPLE */
#  define SIMPLE	SIMPLE
#endif /* SIMPLE */
#endif	// DONT_USE_NAMESPACE_CYN_ENUMS

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Utility macro that ensures that a macro argument is converted to a string,
* even if it was specified with another macro.
*/
#define CYN_TO_STR(tok) #tok

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Utility macro that gives a string constant for a type name.
* This is useful, for example, when a type is specified as a template 
* parameters, but a string is required for either printing, or use
* in a directive.
*/
#define CYN_TYPE_TO_STR(t) typeid(t).name()

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the types of data files we are prepared to read.
* The characters in cyn_rom_char must match the directive names to the enum 
*   values.
*/
typedef enum {
  CYN_ROM_DATA_TYPE_LB     = HLS::HLS_ROM_FORMAT_LB,
  CYN_BIN                  = HLS::HLS_BIN,
  CYN_DBL                  = HLS::HLS_DBL,
  CYN_FLT		   = HLS::HLS_FLT,
  CYN_DEC                  = HLS::HLS_DEC,
  CYN_HEX                  = HLS::HLS_HEX,
  CYN_ROM_DATA_UNKNOWN     = HLS::HLS_ROM_DATA_UNKNOWN,
  CYN_ROM_DATA_TYPE_UB     = HLS::HLS_ROM_FORMAT_UB
}		CYN_ROM_DATA_TYPE;
  
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate some directive parameter values.
*/
typedef enum {
  ALL_CONST             = 2,
  LHS_CONST             = 3,
  MEM_DISTANCE          = 4,
  ACCESS_PATTERN        = 5,
  INTERFACE_DISTANCE    = 6,
  INVERT_DIMS           = 0x10,
  DIR_OPT_UB
} 		DIR_OPT;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to Cynthesizer CYN_FLATTEN
*   directives.
*/
typedef enum {
  DEFAULT_ACCESS	= HLS::DEFAULT_FLATTEN,
  DPOPT_ACCESS		= HLS::DPOPT_FLATTEN,
}		FLATTEN_TO;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to Cynthesizer BALANCE_EXPR
*   directives.
*/
typedef enum {
  BAL_OFF 	= 0x0,  /* no tree balancing */
  BAL_WIDTH	= 0x1,  /* minimize tree width at each node */
  BAL_DELAY	= 0x2,  /* minimize delay at each node */
  BAL_FACTOR	= 0x10,	/* factor out common multiplier values (i.e.: a*5 + b*5 -> (a+b)*5) */
  BAL_WIDTH_FACTOR = BAL_WIDTH | BAL_FACTOR,
  BAL_DELAY_FACTOR = BAL_DELAY | BAL_FACTOR
}		BAL_DIR_OPT;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to CYN_SCHED_OPTION
*   directives.
*/
typedef enum {
  SCHED_OPT_NONE 	= 0x00,  
  SCHED_AGGRESSIVE_2 	= 0x01,  
  SCHED_BIAS_FU_COST 	= 0x02,  
  SCHED_ASAP		= 0x04,
  SCHED_ALLOW_PIPE_MOVEMENT = 0x08,
  SCHED_ORDER_FIRST	= 0x10,
  SCHED_OPT_LAST	= 0x10,
}		SCHED_OPT;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to Cynthesizer DPOPT_INLINE
*   or CYN_PARTITION directives.
* Only options not supported in Stratus are specified here.  
* Any options supported in Stratus are found in hls_enums.h
*/
typedef enum {
  NO_DEAD	= HLS::NO_DCE,
  NO_ENABLE     = 0x0040,
  OPTIM_AREA	= 0x0080,
  OPTIM_DELAY	= 0x0100,
  OPTIM_MERGE	= 0x0200,
  WITH_ENABLE   = 0x0400,

  /* The original, now deprecated, keywords */
  DIR_OPT_DEPR		= 0x80000000,

  DPOPT_EARLY		= DIR_OPT_DEPR | HLS::BEFORE_UNROLL,
  DPOPT_FPGA_ONLY	= DIR_OPT_DEPR | HLS::FPGA_ONLY,
  DPOPT_NO_CONSTANTS	= DIR_OPT_DEPR | HLS::NO_CONSTANTS,
  DPOPT_NO_CSE		= DIR_OPT_DEPR | HLS::NO_CSE,
  DPOPT_NO_DCE		= DIR_OPT_DEPR | HLS::NO_DCE,
  DPOPT_NO_DEAD		= DIR_OPT_DEPR | NO_DEAD,
  DPOPT_NO_ENABLE	= DIR_OPT_DEPR | NO_ENABLE,
  DPOPT_NO_TRIMMING	= DIR_OPT_DEPR | HLS::NO_TRIMMING,
  DPOPT_OPTIM_AREA	= DIR_OPT_DEPR | OPTIM_AREA,
  DPOPT_OPTIM_DELAY	= DIR_OPT_DEPR | OPTIM_DELAY,
  DPOPT_OPTIM_MERGE	= DIR_OPT_DEPR | OPTIM_MERGE,
  DPOPT_WITH_ENABLE	= DIR_OPT_DEPR | WITH_ENABLE,

  DPOPT_NO_ALTS		= DIR_OPT_DEPR | HLS::NO_ALTS,
}		DPOPT_INLINE_OPT;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate directive parameter values for the Cynthesizer 
*   CYN_METHOD_PROCESSING directive.
*/
typedef enum {
  METHOD_PROCESSING_OPT_LB,
  METHOD_DPOPT,
  METHOD_SYNTHESIZE,
  METHOD_TRANSLATE,
  DPOPT_MTHD,
  SYNTH_MTHD,
  TRANS_MTHD,
  METHOD_PROCESSING_OPT_UB
} 		METHOD_PROCESSING_OPT;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to Cynthesizer CYN_PROTOCOL_INLINE
*   directives.
*/

#define CYN_CPI_DEF_OFFSET 8 

typedef enum {

   CYN_CPI_DEFAULT       = HLS::HLS_DEFAULT_FP,
   CYN_MEM_READ_TX       = HLS::HLS_MEM_READ_FP,
   CYN_MEM_WRITE_TX      = HLS::HLS_MEM_WRITE_FP,
   CYN_ATOMIC_TX	 = HLS::HLS_ATOMIC_FP,
   CYN_UNATOMIC_TX       = HLS::HLS_UNATOMIC_FP,
   CYN_SIDE_EFFECT_TX    = HLS::HLS_SIDE_EFFECT_FP,
   CYN_CP_TX             = HLS::HLS_CP_FP,
   CYN_UNSTALLABLE_TX    = HLS::HLS_UNSTALLABLE_FP,
   CYN_UPDATE_LATENCY    = HLS::HLS_UPDATE_LATENCY,
   CYN_IGNORE_BOUNDARIES = HLS::HLS_IGNORE_BOUNDARIES,
   CYN_CALC_MEM_IO	 = HLS::HLS_CALC_MEM_IO,

   CYN_NO_CHAIN_MEM_IN	 = HLS::HLS_NO_CHAIN_MEM_IN,
   CYN_NO_CHAIN_MEM_OUT	 = HLS::HLS_NO_CHAIN_MEM_OUT,
   CYN_NO_CHAIN_MEM_IO	 = HLS::HLS_NO_CHAIN_MEM_IO,
   CYN_CHAIN_MEM_IN	 = HLS::HLS_CHAIN_MEM_IN,
   CYN_CHAIN_MEM_OUT	 = HLS::HLS_CHAIN_MEM_OUT,
   CYN_CHAIN_MEM_IO	 = HLS::HLS_CHAIN_MEM_IO,
   CYN_NO_SPEC_READS	 = HLS::HLS_NO_SPEC_READS,
   CYN_ALLOW_SPEC_READS	 = HLS::HLS_ALLOW_SPEC_READS,
   CYN_IS_CONDITIONAL	 = HLS::HLS_IS_CONDITIONAL,

   // Support old names for chaining settings.
   CYN_ASYNC_MEM_IN	 = CYN_CHAIN_MEM_IN,
   CYN_ASYNC_MEM_OUT	 = CYN_CHAIN_MEM_OUT,
   CYN_ASYNC_MEM_IO	 = CYN_CHAIN_MEM_IO,
   CYN_REG_MEM_IN	 = CYN_NO_CHAIN_MEM_IN,
   CYN_REG_MEM_OUT	 = CYN_NO_CHAIN_MEM_OUT,
   CYN_REG_MEM_IO	 = CYN_NO_CHAIN_MEM_IO,

   // Reserve bits shifted by CYN_CPI_DEF_OFFSET bits from the set above
   // For the _DEF_ settings below.
   //   0x00040000 to 0x00800000
   CYN_DEF_REG_MEM_IN	 =  CYN_REG_MEM_IN	   << CYN_CPI_DEF_OFFSET,
   CYN_DEF_REG_MEM_OUT	 =  CYN_REG_MEM_OUT	   << CYN_CPI_DEF_OFFSET,
   CYN_DEF_REG_MEM_IO	 =  CYN_REG_MEM_IO	   << CYN_CPI_DEF_OFFSET,
   CYN_DEF_ASYNC_MEM_IN	 =  CYN_ASYNC_MEM_IN	   << CYN_CPI_DEF_OFFSET,
   CYN_DEF_ASYNC_MEM_OUT =  CYN_ASYNC_MEM_OUT	   << CYN_CPI_DEF_OFFSET,
   CYN_DEF_ASYNC_MEM_IO	 =  CYN_ASYNC_MEM_IO	   << CYN_CPI_DEF_OFFSET,
   CYN_DEF_NO_CHAIN_MEM_IN= HLS_DEF_NO_CHAIN_MEM_IN,
   CYN_DEF_NO_CHAIN_MEM_OUT=HLS_DEF_NO_CHAIN_MEM_OUT,
   CYN_DEF_NO_CHAIN_MEM_IO= HLS_DEF_NO_CHAIN_MEM_IO,
   CYN_DEF_CHAIN_MEM_IN	 =  HLS_DEF_CHAIN_MEM_IN,
   CYN_DEF_CHAIN_MEM_OUT =  HLS_DEF_CHAIN_MEM_OUT,
   CYN_DEF_CHAIN_MEM_IO	 =  HLS_DEF_CHAIN_MEM_IO,
   CYN_DEF_NO_SPEC_READS =  HLS_DEF_NO_SPEC_READS,
   CYN_DEF_ALLOW_SPEC_READS=HLS_DEF_ALLOW_SPEC_READS,

   CYN_UNSTALLABLE_INPUTS= HLS::HLS_UNSTALLABLE_INPUTS, 
   CYN_NO_STALL_FIFO	 = HLS::HLS_NO_STALL_FIFO, 
   CYN_USING_REG_PORT	 = HLS::HLS_USING_REG_PORT, 
   CYN_USING_REG_EX_PORT = HLS::HLS_USING_REG_EX_PORT,
   
 } CYN_PROTOCOL_INLINE_OPT;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate parameter values for the CYN_PARTITION and CYN_STAGE directives.
* (Note: These have been deprecated in version 3.6.)
*/
typedef enum {
  
  PARTITION_DEFAULT		= 0x00000000,

  /* Duplicates from DPOPT: 0x0001 through 0x0040 */
  PARTITION_NO_CONSTANTS	= HLS::NO_CONSTANTS,
  PARTITION_NO_DEAD		= HLS::NO_DCE,
  PARTITION_NO_TRIMMING		= HLS::NO_TRIMMING,
  PARTITION_NO_CSE		= HLS::NO_CSE,

  PARTITION_IGNORE_BOUNDARIES   = CYN_IGNORE_BOUNDARIES,  /* Note: 0x0100 */
  PARTITION_NO_SYNC_IN		= 0x00000200,
  PARTITION_NO_SYNC_OUT		= 0x00000400,
  PARTITION_NO_SYNC		= (PARTITION_NO_SYNC_IN | PARTITION_NO_SYNC_OUT),

  PARTITION_NO_PIPE		= 0x00001000,
  PARTITION_MACRO_PIPELINE	= 0x00002000,
  PARTITION_TX			= 0x00004000,

  /* The following options are deprecated in version 3.6. */
  EXEC_AUTO			= 0x00100000,
  EXEC_TX,
  EXEC_DPOPT,
  EXEC_FREE
} 		PARTITION_DIRECTIVE_OPT;


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Value passed in place of a timing value to CYN_MEM_READ_TX, CYN_MEM_WRITE_TX,
* CYN_PROTOCOL_TX, CYN_INPUT_DELAY, or CYN_OUTPUT_DELAY.  It indicates that
* stratus_hls should attempt to calculate a timing value.
*/
#define		CYN_CALC_TIMING -1

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Value passed as the "max" argument to CYN_LATENCY to request that the
* smallest achievable latency be used as a the max latency constraint.
*/
#define		CYN_CALC_LATENCY -2

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Value passed in place of a timing value to CYN_MEM_READ_TX, CYN_MEM_WRITE_TX,
* CYN_PROTOCOL_TX, CYN_INPUT_DELAY, or CYN_OUTPUT_DELAY.  It indicates that
* stratus_hls should avoid timing issues by registering I/O.
*/
#define		CYN_FORCE_REG 0

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Values set in CYN_RESET_TYPE variable to indicate the style of reset
* being used in the thread or method where the variable appears.
*/
typedef enum {
  CYN_RESET_NONE          = HLS::HLS_RESET_NONE,
  CYN_RESET_IS_SYNC       = HLS::HLS_RESET_IS_SYNC,
  CYN_RESET_IS_ASYNC      = HLS::HLS_RESET_IS_ASYNC,
  CYN_RESET_IS_SYNC_ASYNC = HLS::HLS_RESET_IS_SYNC_ASYNC,
} CYN_RESET_TYPE_KIND;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Options used by generated interfaces.
*/
typedef enum {
  CYNIF_DO_WRITE   = 0x1,
  CYNIF_DO_READ    = 0x2,
  CYNIF_DO_ADVANCE = 0x4
} CYNIF_OPTION_VALUE;

}; /* namespace ENUMS */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* A template type that can be used to create a type that corresponds to 
* a specific integer.  This is useful in some template applications.
*/
template <int T>  
struct cyn_enum { 
  enum { value=T };
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* A pre-defined set of typed enumerations.
* These values are typically used in two places:
*
* 1. In template specializations for abstraction-level-specific versions of 
*    modular interfaces.
*
* 2. In project.tcl files as values in ioConfig statements that are used to
*    select amongst template specializations.
*
* Enumeration values up to 100 are reserved by Cadence for future use.
* Customers defining their own cyn_enum values should use values greater 
* then 100 to avoid clashes with future Cynthesizer releases.
*/

typedef cyn_enum<1> PIN;		// A pin-level interface.
typedef cyn_enum<2> TLM;		// A transaction-level interface.

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* cyn_log
*
* Template utilities for computing the log of a number in a type context.
* This is particularly useful when sizing an sc_uint big enough to address
* an array of a given size.
*
* Usage:
*   cyn_log::log2<4>::value gives the value 2.
*
*   Values that are not powers of two are rounded up so that:
*
*       2 ^ log2<N> >= N
*
*   so that log2<5> gives 3 because 3 bits are required to hold 5 values,
*
*   The log2<> template can be used to give the number of bits required to address
*   an array of a given size when declaring types as follows:
*
*     template <int N>
*     void f( int a[N] ) {
*       // Declare an sc_uint big enough to address the given array.
*       sc_uint< cyn_log::log2<N>::value > a;
*       ...
*     }
*
*/
namespace cyn_log {
  template<int num> struct log2_calc { enum { value = log2_calc<(num/2)>::value+1 }; };
  template<> struct log2_calc<0> { enum { value = 0 }; };
  template<int num> struct log2 { enum { value = log2_calc<(num-1)>::value }; };
  template<> struct log2<0> { enum { value = 0 }; };
  template<> struct log2<1> { enum { value = 1 }; };
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* cyn_type_compare
*
* A utility for comparing two types.
*
* Usage:
*   cyn_type_compare<int,float>::SAME is 0.
*   cyn_type_compare<int,int>::SAME is 1.
*
* This is useful in templated code when different actions should be taken
* depending on whether two template typename actuals are the same.
*
*/
template <typename T1, typename T2>
struct cyn_type_compare
{ 
  enum { SAME=0 };
};

template <typename T1>
struct cyn_type_compare<T1,T1>
{
  enum { SAME=1 };
};
 

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
   Macros for creating unique variable names based on __LINE__.
   Usage is:

    int CYN_LINENAME(x);
    int CYN_LINENAME(x);

  will cause a unique name to be generated for each use of the macro that's on
  a separate line.
 */
#define _CYN_LINENAME_CAT( name, line ) name##line
#define _CYN_LINENAME( name, line ) _CYN_LINENAME_CAT( name, line )
#define CYN_LINENAME( name ) _CYN_LINENAME( name, __LINE__ )

}; /* namespace	CYN  */

#endif	// cyn_enums_h_INCLUDED
