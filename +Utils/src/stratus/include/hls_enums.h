/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/
#ifndef hls_enums_h_INCLUDED
#define hls_enums_h_INCLUDED

#if defined STRATUS && ! defined _STRATUS_internal_
#pragma hls_ip_def
#endif  

#define STRATUS_VERSION 201501


/* Package all of this in a namespace. */
namespace   HLS {

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to region directives
*/
enum HLS_REGION_OPTIONS {
    DPOPT_DEFAULT       = 0x0000,
    REGION_DEFAULT      = 0x0000,

    BEFORE_UNROLL       = 0x0001,
    FPGA_ONLY           = 0x0002,
    NO_CONSTANTS        = 0x0004,
    NO_CSE              = 0x0008,
    NO_DCE              = 0x0010,
    NO_TRIMMING         = 0x0040,
    NO_CHAIN_IN         = 0x0800,
    NO_CHAIN_OUT        = 0x1000,
    ALWAYS_MUX          = 0x2000,
    DPOPT_DISABLE       = 0x4000,
    HOIST_ARRAYS        = 0x8000,
    BEFORE_INLINE       = 0x10000,
    ARTIFICIAL_INP_CONSTR = 0x20000,    // Set if an input/output/latency
    ARTIFICIAL_OUT_CONSTR = 0x40000,    // constraint has been made up by
    ARTIFICIAL_LAT_CONSTR = 0x80000,    // stratus_hls rather than by the user.
    NO_WIRE_ONLY          = 0x100000,
    DPOPT_FPGA_USE_DSP    = 0x200000,
    AFTER_UNROLL          = 0x400000,
    NO_ALTS       = NO_CONSTANTS|NO_TRIMMING|NO_CSE|NO_DCE,
    REGION_PHASE_OPT    = BEFORE_INLINE | BEFORE_UNROLL | AFTER_UNROLL
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to floating protocol directives
*/
enum HLS_FLOATING_PROTOCOL_OPTIONS {
   HLS_DEFAULT_FP        = 0x00000000,
   HLS_MEM_READ_FP       = 0x00000001,
   HLS_MEM_WRITE_FP      = 0x00000002,
   HLS_ATOMIC_FP         = 0x00000004,
   HLS_UNATOMIC_FP       = 0x00000008,
   HLS_SIDE_EFFECT_FP    = 0x00000010,
   HLS_CP_FP             = 0x00000020,
   HLS_UNSTALLABLE_FP    = 0x00000040,
   HLS_UPDATE_LATENCY    = 0x00000080,
   HLS_IGNORE_BOUNDARIES = 0x00000100,
   HLS_CALC_MEM_IO       = 0x00000200,

   HLS_NO_CHAIN_MEM_IN   = 0x00000400,
   HLS_NO_CHAIN_MEM_OUT  = 0x00000800,
   HLS_NO_CHAIN_MEM_IO   = 0x00000c00,
   HLS_CHAIN_MEM_IN      = 0x00001000,
   HLS_CHAIN_MEM_OUT     = 0x00002000,
   HLS_CHAIN_MEM_IO      = 0x00003000,
   HLS_NO_SPEC_READS     = 0x00004000, 
   HLS_ALLOW_SPEC_READS  = 0x00008000, 
   HLS_IS_CONDITIONAL    = 0x00010000, 

   // Reserve bits shifted by HLS_CPI_DEF_OFFSET bits from the set above

   HLS_UNSTALLABLE_INPUTS= 0x01000000, 
   HLS_NO_STALL_FIFO     = 0x02000000, 
   HLS_USING_REG_PORT    = 0x04000000, 
   HLS_USING_REG_EX_PORT = 0x08000000
};

// For the _DEF_ settings below.
//   0x00040000 to 0x00800000
#define HLS_CPI_DEF_OFFSET 8 
#define HLS_DEF_NO_CHAIN_MEM_IN     (HLS::HLS_NO_CHAIN_MEM_IN   << HLS_CPI_DEF_OFFSET)
#define HLS_DEF_NO_CHAIN_MEM_OUT    (HLS::HLS_NO_CHAIN_MEM_OUT   << HLS_CPI_DEF_OFFSET)
#define HLS_DEF_NO_CHAIN_MEM_IO     (HLS::HLS_NO_CHAIN_MEM_IO   << HLS_CPI_DEF_OFFSET)
#define HLS_DEF_CHAIN_MEM_IN        (HLS::HLS_CHAIN_MEM_IN      << HLS_CPI_DEF_OFFSET)
#define HLS_DEF_CHAIN_MEM_OUT       (HLS::HLS_CHAIN_MEM_OUT     << HLS_CPI_DEF_OFFSET)
#define HLS_DEF_CHAIN_MEM_IO        (HLS::HLS_CHAIN_MEM_IO      << HLS_CPI_DEF_OFFSET)
#define HLS_DEF_NO_SPEC_READS       (HLS::HLS_NO_SPEC_READS     << HLS_CPI_DEF_OFFSET)
#define HLS_DEF_ALLOW_SPEC_READS    (HLS::HLS_ALLOW_SPEC_READS   << HLS_CPI_DEF_OFFSET)

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to flattening directives
*/
enum HLS_FLATTEN_OPTIONS {
    DONT_FLATTEN=0,
    DEFAULT_FLATTEN, 
    DPOPT_FLATTEN, 
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to rom initialization directives
*/
enum HLS_ROM_FORMAT  {
  HLS_ROM_FORMAT_LB,
  HLS_BIN,
  HLS_DBL,
  HLS_FLT = HLS_DBL,
  HLS_DEC,
  HLS_HEX,
  HLS_ROM_DATA_UNKNOWN,
  HLS_ROM_FORMAT_UB
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to index mapping directives
*/
enum HLS_ARRAY_MAPPING_OPTIONS {
    DONT_MAP,
    MAP_MEMORY,
    MAP_REG_BANK
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to index mapping directives
*/
enum HLS_INDEX_MAPPING_OPTIONS {
    COMPACT         = 0x100, 
    SIMPLE          = 0x101, 
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to pipelining directives
*/
enum HLS_PIPELINE_OPTIONS {
    HARD_STALL      = 0x200,
    SOFT_STALL      = 0x201,
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to output options directives
*/
enum HLS_OUTPUT_OPTIONS {
  SYNC_HOLD=0,
  SYNC_NO_HOLD,
  SYNC_STALL_NO_HOLD,
  ASYNC_HOLD,
  ASYNC_NO_HOLD,
  ASYNC_STALL_NO_HOLD,
  SYNC_POWER_HOLD,
  ASYNC_POWER_HOLD,
  ASYNC_HIGH,
  ASYNC_LOW,
  SYNC_ASYNC_OPTS=0xf,
  WEAK_TIMING=0xf0,
  ASYNC_HOLD_WEAK_TIMING = ASYNC_HOLD | WEAK_TIMING,
  ASYNC_NO_HOLD_WEAK_TIMING = ASYNC_NO_HOLD | WEAK_TIMING,
  ASYNC_STALL_NO_HOLD_WEAK_TIMING = ASYNC_STALL_NO_HOLD | WEAK_TIMING,
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that may be passed to loop unrolling directives
*/
enum HLS_UNROLL_OPTIONS  {
  OFF                   = 0,
  ON                    = 1,
  ALL                   = 0x1000,
  AGGRESSIVE            = 0x1001,
  COMPLETE              = 0x1002,
  CONSERVATIVE          = 0x1003,
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that specify reset kind.
*/
enum HLS_RESET_TYPE_KIND {
  HLS_RESET_NONE          = 0,
  HLS_RESET_IS_SYNC       = 0x1,
  HLS_RESET_IS_ASYNC      = 0x2,
  HLS_RESET_IS_SYNC_ASYNC = 0x3
} ;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Enumerate the options that specify stable input options.
*/
enum HLS_ASSUME_STABLE_OPTIONS {
  HLS_ASSUME_STABLE_DEFAULT = 0,
  UNTIMED = 1,
};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* A template type that can be used to create a type that corresponds to 
* a specific integer.  This is useful in some template applications.
*/
template <int T>  
struct hls_enum { 
  enum { value=T };
};

};

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Value passed in place of a timing value in various directives to indicate
* that timing should be calculated rather than specified.
*/
#define		HLS_CALC_TIMING   -1


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Value that means the latency should only be printed, and not constrained
* to a particular value, when specified as the max_lat value.
*/
#define		HLS_PRINT_LATENCY -1
#define		HLS_INFINITE -1

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Value that means the minimum latency found by scheduler should be used
* as the max latency value.
*/
#define         HLS_ACHIEVABLE    -2

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Utility macro that ensures that a macro argument is converted to a string,
* even if it was specified with another macro.
*/
#define HLS_TO_STR(tok) #tok

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Utility macro that gives a string constant for a type name.
* This is useful, for example, when a type is specified as a template 
* parameters, but a string is required for either printing, or use
* in a directive.
*/
#define HLS_TYPE_TO_STR(t) typeid(t).name()

#endif  // hls_enums_h_INCLUDED
