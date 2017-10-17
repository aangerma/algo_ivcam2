/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/

#ifndef Cynw_Fixed_H_INCLUDED
#define Cynw_Fixed_H_INCLUDED

#if defined STRATUS 
#pragma hls_ip_def
#endif	

#define CYNW_FIXED_VERSION 20140506

#ifndef RND_SAT_OPTIM
#define RND_SAT_OPTIM 0
#define RND_SAT_OPTIM_U 0
#endif

#ifndef _TIME_H
#define _TIME_H
#define _UNDOTIME_
#endif

#include <math.h>

#include <sstream>
using std::cerr;
using std::cout;
using std::ios;
using std::ostream;
using std::ostringstream;
using std::endl;
using std::ends;

#ifdef _UNDOTIME_
#undef _UNDOTIME_
#undef _TIME_H
#endif

#define CYNW_BITS_PER_BYTE 8
#define CYNW_BITS_PER_INT ((int)sizeof(int)*CYNW_BITS_PER_BYTE)
#define CYNW_BITS_PER_LONG ((int)sizeof(long)*CYNW_BITS_PER_BYTE)
#define CYNW_BITS_PER_LONGLONG 64
#define CYNW_LOG_BITS_PER_INT 5
#define CYNW_BITS_PER_DOUBLE 64
#define CYNW_LOG_BITS_PER_DOUBLE 6
#define CYNW_INTS_PER_DOUBLE 2

#define CYNW_FLOAT_MAN 23
#define CYNW_FLOAT_EXP 8
#define CYNW_DOUBLE_MAN 52
#define CYNW_DOUBLE_EXP 11

#define CYNW_BIAS(E) ((1<<(E-1))-1)
#define CYNW_FLOAT_BIAS CYNW_BIAS(CYNW_FLOAT_EXP)
#define CYNW_DOUBLE_BIAS CYNW_BIAS(CYNW_DOUBLE_EXP)

// IF THERE ARE NO SYSTEMC FIXED POINT CLASSES DEFINED ALIAS OURS:
//
// Pick up some additional background typing and set usings for them

#if !defined(SC_INCLUDE_FX)
#   define sc_fixed cynw_fixed
#   define sc_ufixed cynw_ufixed
#   define sc_fixed_fast cynw_fixed
#   define sc_ufixed_fast cynw_ufixed

#   include "sysc/datatypes/fx/sc_fxdefs.h"
#endif

// We need to define these way because bdw_wrap_gen ignores things:

using sc_dt::SC_E;
using sc_dt::SC_F;
using sc_dt::sc_fmt;
using sc_dt::SC_LATER;
using sc_dt::SC_NOW;
using sc_dt::SC_OFF;
using sc_dt::sc_o_mode;
using sc_dt::SC_ON;
using sc_dt::sc_q_mode;
using sc_dt::SC_RND;
using sc_dt::SC_RND_CONV;
using sc_dt::SC_RND_INF;
using sc_dt::SC_RND_MIN_INF;
using sc_dt::SC_RND_ZERO;
using sc_dt::SC_SAT;
using sc_dt::SC_SAT_SYM;
using sc_dt::SC_SAT_ZERO;
using sc_dt::sc_switch;
using sc_dt::SC_TRN;
using sc_dt::SC_TRN_ZERO;
using sc_dt::SC_WRAP;
using sc_dt::SC_WRAP_SM;


#include "cynthhl.h"

// STORAGE TYPES FOR FIXED POINT TYPES:
//
// Fixed point values are stored within cynw_fixed variables as sc_int<W> 
// or sc_bigint<W> values. Similarly, cynw_ufixed variables have values that
// are stored as either sc_uint<W> or sc_biguint<W> values. A template
// specialization / typedef trick is used to map a fixed point bit width to 
// the appropriate storage type. The default class definition for 
// cynw_fx_types<W> is set up to use sc_bigint<W> or sc_biguint<W> values. 
// If the width is 64 bits or less a template specialization exists so that 
// the representation will use sc_int<W> or sc_uint<W>.

template<int W> struct cynw_fx_types 
{ 
    typedef sc_dt::sc_bigint<W>   iarg_type;
    typedef sc_dt::sc_bigint<W>   ivalue_type;
    typedef sc_dt::sc_unsigned    subref_cast; // type of part select value.
    typedef sc_dt::sc_biguint<W>  uarg_type;   // type of unsigned
    typedef sc_dt::sc_biguint<W>  uvalue_type;
};

#if !defined(STRATUS_HLS)
#   define CYNW_FX_TYPES(W) \
    template<> struct cynw_fx_types<W> \
    { \
    typedef long long          iarg_type; \
    typedef sc_dt::sc_int<W>   ivalue_type; \
    typedef unsigned long long subref_cast; \
    typedef unsigned long long uarg_type; \
    typedef sc_dt::sc_uint<W>  uvalue_type; \
    };
#else
// @@@@#### ACG #   define CYNW_FIXED_NO_DOUBLE_CAST 1
#   define CYNW_FX_TYPES(W) \
    template<> struct cynw_fx_types<W> \
    { \
    typedef sc_dt::sc_int<W>   iarg_type; \
    typedef sc_dt::sc_int<W>   ivalue_type; \
    typedef unsigned long long subref_cast; \
    typedef sc_dt::sc_uint<W>  uarg_type; \
    typedef sc_dt::sc_uint<W>  uvalue_type; \
    };
#endif // !defined(STRATUS_HLS)

    CYNW_FX_TYPES(1)  CYNW_FX_TYPES(2)  CYNW_FX_TYPES(3)  CYNW_FX_TYPES(4) 
    CYNW_FX_TYPES(5)  CYNW_FX_TYPES(6)  CYNW_FX_TYPES(7)  CYNW_FX_TYPES(8) 
    CYNW_FX_TYPES(9)  CYNW_FX_TYPES(10) CYNW_FX_TYPES(11) CYNW_FX_TYPES(12) 
    CYNW_FX_TYPES(13) CYNW_FX_TYPES(14) CYNW_FX_TYPES(15) CYNW_FX_TYPES(16) 
    CYNW_FX_TYPES(17) CYNW_FX_TYPES(18) CYNW_FX_TYPES(19) CYNW_FX_TYPES(20)
    CYNW_FX_TYPES(21) CYNW_FX_TYPES(22) CYNW_FX_TYPES(23) CYNW_FX_TYPES(24) 
    CYNW_FX_TYPES(25) CYNW_FX_TYPES(26) CYNW_FX_TYPES(27) CYNW_FX_TYPES(28) 
    CYNW_FX_TYPES(29) CYNW_FX_TYPES(30) CYNW_FX_TYPES(31) CYNW_FX_TYPES(32) 
    CYNW_FX_TYPES(33) CYNW_FX_TYPES(34) CYNW_FX_TYPES(35) CYNW_FX_TYPES(36) 
    CYNW_FX_TYPES(37) CYNW_FX_TYPES(38) CYNW_FX_TYPES(39) CYNW_FX_TYPES(40)
    CYNW_FX_TYPES(41) CYNW_FX_TYPES(42) CYNW_FX_TYPES(43) CYNW_FX_TYPES(44) 
    CYNW_FX_TYPES(45) CYNW_FX_TYPES(46) CYNW_FX_TYPES(47) CYNW_FX_TYPES(48) 
    CYNW_FX_TYPES(49) CYNW_FX_TYPES(50) CYNW_FX_TYPES(51) CYNW_FX_TYPES(52) 
    CYNW_FX_TYPES(53) CYNW_FX_TYPES(54) CYNW_FX_TYPES(55) CYNW_FX_TYPES(56) 
    CYNW_FX_TYPES(57) CYNW_FX_TYPES(58) CYNW_FX_TYPES(59) CYNW_FX_TYPES(60)
    CYNW_FX_TYPES(61) CYNW_FX_TYPES(62) CYNW_FX_TYPES(63) CYNW_FX_TYPES(64)


#undef CYNW_FX_TYPES

#define CYNW_IARG(W) (typename cynw_fx_types<W>::iarg_type)
#define CYNW_UARG(W) (typename cynw_fx_types<W>::uarg_type)
#define CYNW_IVAL(W)  typename cynw_fx_types<W>::ivalue_type
#define CYNW_UVAL(W)  typename cynw_fx_types<W>::uvalue_type
#define CYNW_SUBREF(W) typename cynw_fx_types<W>::subref_cast

// CYNW_FX_LS_EXTRA_BITS - extra bits for left shift operations.
//
// By default left shift results will be the same size as the target of the
// shift. This produces the minimum hardware for the shift. To get more 
// precision users will have to cast the target to a larger size, or use
// a temporary variable that is that larger size:
//    (a) x = (larger_type)y << z;
//    (b) larger_type y_tmp = y;
//        x = y_tmp << z;
// Alternatively, if CYNW_FX_LS_EXTRA_BITS is defined before this file is 
// included the value will be used for left shift results. 

#ifndef CYNW_FX_LS_EXTRA_BITS
#   define CYNW_FX_LS_EXTRA_BITS 0
#endif
#define CYNW_FX_LS_SIZE (W+CYNW_FX_LS_EXTRA_BITS)

// CYNW_FX_RS_EXTRA_BITS - extra bits for right shift results.
//
// By default right shift results will be the same size as the target of the
// shift. This produces the minimum hardware for the shift. To get more 
// precision users will have to cast the target to a larger size, or use
// a temporary variable that is that larger size:
//    (a) x = (larger_type)y >> z;
//    (b) larger_type y_tmp = y;
//        x = y_tmp >> z;
// Alternatively, if CYNW_FX_RS_EXTRA_BITS is defined before this file is 
// included the value will be used to expand the number of bits in right shift 
// results. 

#ifndef CYNW_FX_RS_EXTRA_BITS
#   define CYNW_FX_RS_EXTRA_BITS 0
#endif
#define CYNW_FX_RS_SIZE (W+CYNW_FX_RS_EXTRA_BITS)

// CYNW_FX_NO_SHIFT_WARNING - supress warnings about illegal shifts
//
// If this symbol is defined then warnings about shifts that exceed the
// width of their targets will not be produced during behavioral simulations.

// CYNW_FX_RS_ROUND - perform rounding on the results of right shifts.
//
// By default right shift results are not rounded, any rounding that occurs
// will occur when the right shift result is assigned to a variable whose
// type specifies rounding. The means that extra bits may be needed to
// accomplish that rounding process (see CYNW_FX_RS_EXTRA_BITS above.) Those
// extra bits may involve the generation of more hardware that if rounding
// is applied during the shift process. So if CYNW_FX_RS_ROUND is defined
// as 1 before this file is included then rounding will be applied to the
// immediate results of right shifts, unless CYNW_FX_RS_EXTRA_BITS has been
// specified as a value other than 0.

#ifndef CYNW_FX_RS_ROUND
#   define CYNW_FX_RS_ROUND 0
#endif

// RESOLUTION CALCULATION MACROS:

#define CYNW_MAX(A,B) (A<B?B:A)
#define CYNW_MIN(A,B) (A>B?B:A)
#define CYNW_RES_W (CYNW_MAX(I,I1)+CYNW_MAX(W-I,W1-I1)+1) 
#define CYNW_RES_I (CYNW_MAX(I,I1)+1) 
#define CYNW_RES_WW (CYNW_MAX(I,WW)+(W-I)+1)  
#define CYNW_RES_IW (CYNW_MAX(I,WW)+1) 
#define CYNW_RES_WW_U ( CYNW_RES_WW+1 ) 
#define CYNW_RES_IW_U ( CYNW_RES_IW+1 )
#define CYNW_RES_WINT (CYNW_MAX(I,CYNW_BITS_PER_INT)+(W-I)+1)  
#define CYNW_RES_IINT (CYNW_MAX(I,CYNW_BITS_PER_INT)+1) 


#define CYNW_EFF_W ((W>I) ? ((I>0) ? W+1 : W-(I)+1) : I)

#define CYNW_RES_MUL_W (W+W1) 
#define CYNW_RES_MUL_WW (W+WW) 
#define CYNW_RES_MUL_W_INT (W+CYNW_BITS_PER_INT) 

#define CYNW_RES_MUL_I ( (I+I1) )
#define CYNW_RES_MUL_IW ( ((W+WW) > CYNW_RES_MUL_WW) ? (I-W+64) : (I+WW) )
#define CYNW_RES_MUL_I_INT ( ((W+CYNW_BITS_PER_INT) > CYNW_RES_MUL_W_INT) ? (I-W+64) : (I+CYNW_BITS_PER_INT) )


// ARITHMETIC RESULT MODES:
//
// Because sc_fixed/sc_ufixed use doubles for arithmetic, and we allocate
// as many bits as the operation requires, where possible, don't do any 
// intermediate processing.

#define CYNW_ARES_O_MODE SC_WRAP
#define CYNW_ARES_Q_MODE SC_TRN

#define CYNW_RES_O_MODE ((O_MODE==SC_SAT_SYM)?SC_SAT:(sc_o_mode)O_MODE)

// TEMPLATE DEFINTIONS TO MAKE THE CODE LOOK CLEANER: 

#define CWFX_TEMPLATE \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS>

#define CWFX_TEMPLATE1 \
template<int W1, int I1, sc_q_mode Q_MODE1, sc_o_mode O_MODE1, int N_BITS1>

#define CWFX_TEMPLATE2 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, \
     int W1, int I1, sc_q_mode Q_MODE1, sc_o_mode O_MODE1, int N_BITS1>

#define CWFX_TEMPLATE_WW \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, int WW>

// SHORT CUTS FOR VALUES:

#define CWFX_FIXED cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>
#define CWFX_FIXED1 cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1>
#define CWFX_UFIXED cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>
#define CWFX_UFIXED1 cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1>

// DOUBLE PRECISION 
//
// CYNW_FX_DW - width of cynw_fixed values that are conversions of double and float values,
//              default is 64.
// CYNW_FX_IW - integer width of cynw_fixed values that are conversions of double and float
//              values, default is half the value of CYNW_FX_DW.
#if !defined(CYNW_FX_DW)
#   define CYNW_FX_DW 64
#endif
#if !defined(CYNW_FX_IW)
#   define CYNW_FX_IW (CYNW_FX_DW/2)
#endif

// CYNW_FX_DIV_BITS 
//
// This #define controls how many bits are added to the intermediate result 
// width for division. The base width is W+W1. This is not enough to produce 
// results that match sc_fixed division operations unless the destination 
// variable is smaller than <W,I>. 
// 
// The default value for CYNW_FX_DIV_BITS is 1 for <WRAP,TRN> and 2 for 
// everything else. This will cause results to match sc_fixed if the 
// destination is <W,I>. If the destination has more fractional bits than W-I, 
// then CYNW_FX_DIV_BITS needs to be bigger to produce the same results. The 
// value of CYNW_FX_DIV_BITS effects how big the divider is. 

#ifndef CYNW_FX_DIV_BITS
#   define CYNW_FX_DIV_BITS ((O_MODE==SC_WRAP && Q_MODE==SC_TRN) ? 1 : 2)
#endif

// NEW RESOLUTION CALCULATION MACROS:

#define CWFX_ADD_W(Wa,Ia,Wb,Ib) (CYNW_MAX(Ia,Ib)+CYNW_MAX(Wa-Ia,Wb-Ib)+1)
#define CWFX_ADD_I(Ia,Ib)       (CYNW_MAX(Ia,Ib)+1)
#define CWFX_MUL_I(Ia,Ib)       (Ia+Ib)
#define CYNW_DIV_I(W1,I1)       (I+W1-I1)
#define CYNW_DIV_W(WW,II)       (W+WW+CYNW_FX_DIV_BITS+(II<0?-II:0)) 
#define CYNW_DIV_WU(WW,II)      (CYNW_DIV_W(WW,II)+1)
#define CWFX_MUL_W(Wa,Ia,Wb,Ib) (Wa+Wb)
#define CWFX_SUB_W(Wa,Ia,Wb,Ib) (CYNW_MAX(Ia,Ib)+CYNW_MAX(Wa-Ia,Wb-Ib)+1)
#define CWFX_SUB_I(Ia,Ib)       (CYNW_MAX(Ia,Ib)+1)

// RESULT TYPES FOR MATH OPERATIONS: 
//
// The postfixes on these macros specify the signedness of the operands:
//     _SS - signed op signed
//     _SU - signed op unsigned
//     _US - unsigned op signed
//     _UU - unsigned op unsigned
// 
// Sizing of constant double and float operands:
//   (1) For add, multiply, and subtract operations double and float operands
//       will be cast to cynw_fixed instances whose total width and integer
//       width will be the same as the other operand of the operation. This
//       is done before sizing the results of the operation.
//
// Sizing of add and subtract results:
//   (1) If an add is a mixture of signedness, the total width and integer width
//       of the unsigned value will be increased by 1 before calculating the
//       total width and integer width of the result.
//   (2) The integer width of the result will be the larger of the integer
//       widths of the two operands (adjusted per 1 above.)
//   (3) The total width of the result will be the integer width calculated
//       in 2 above plus the larger of the fraction widths of the two 
//       operands ( the fractional width is the total width minus the 
//       integer width.)
//
// Sizing of multiply results:
//   (1) The total width is the sum of the total widths of the two operands.
//   (2) The integer width is the sum of the integer widths of the two 
//       operands.
// 
// Sizing of division and modulo results:
//   (1) The total width of the result will be the sum of the total widths
//       of the two operands, plus the value of CYNW_FX_DIV_BITS, plus the
//       negative integer width of the divisor if that width is less than
//       zero.
//   (2) The integer width of the result is the integer width of the numerator
//       plus the fractional width of the divisor ( the total width of the
//       divisor minus the integer width of the divisor).

#define CWFX_ADD_SS(Wa,Ia,Wb,Ib) \
    cynw_fixed< CWFX_ADD_W(Wa,Ia,Wb,Ib),   CWFX_ADD_I(Ia,Ib) >
#define CWFX_ADD_SU(Wa,Ia,Wb,Ib) \
    cynw_fixed< CWFX_ADD_W(Wa,Ia,Wb,Ib)+1, CWFX_ADD_I(Ia,Ib)+1 >
#define CWFX_ADD_US(Wa,Ia,Wb,Ib) \
    cynw_fixed< CWFX_ADD_W(Wa,Ia,Wb,Ib)+1, CWFX_ADD_I(Ia,Ib)+1 >
#define CWFX_ADD_UU(Wa,Ia,Wb,Ib) \
    cynw_ufixed< CWFX_ADD_W(Wa,Ia,Wb,Ib),   CWFX_ADD_I(Ia,Ib) >

#define CWFX_DIV(Wa,Ia,Wb,Ib) /* legacy */ \
    cynw_fixed<Wa+Wb+CYNW_FX_DIV_BITS+(Ib<0?-Ib:0), Ia+Wb-Ib>
#define CWFX_DIVS(Wa,Ia,Wb,Ib) \
    cynw_fixed<Wa+Wb+CYNW_FX_DIV_BITS+(Ib<0?-Ib:0), Ia+Wb-Ib>
#define CWFX_DIVU(Wa,Ia,Wb,Ib) \
    cynw_ufixed<Wa+Wb+CYNW_FX_DIV_BITS+(Ib<0?-Ib:0), Ia+Wb-Ib>

#define CWFX_MUL_SS(Wa,Ia,Wb,Ib) \
    cynw_fixed< CWFX_MUL_W(Wa,Ia,Wb,Ib), CWFX_MUL_I(Ia,Ib) >
#define CWFX_MUL_SU(Wa,Ia,Wb,Ib) \
    cynw_fixed< CWFX_MUL_W(Wa,Ia,Wb,Ib), CWFX_MUL_I(Ia,Ib) >
#define CWFX_MUL_US(Wa,Ia,Wb,Ib) \
    cynw_fixed< CWFX_MUL_W(Wa,Ia,Wb,Ib), CWFX_MUL_I(Ia,Ib) >
#define CWFX_MUL_UU(Wa,Ia,Wb,Ib) \
    cynw_ufixed< CWFX_MUL_W(Wa,Ia,Wb,Ib), CWFX_MUL_I(Ia,Ib) >

#define CWFX_SUB_SS(Wa,Ia,Wb,Ib) \
    cynw_fixed< CWFX_SUB_W(Wa,Ia,Wb,Ib),   CWFX_SUB_I(Ia,Ib) >
#define CWFX_SUB_SU(Wa,Ia,Wb,Ib) \
    cynw_fixed< CWFX_SUB_W(Wa,Ia,Wb,Ib)+1, CWFX_SUB_I(Ia,Ib)+1 >
#define CWFX_SUB_US(Wa,Ia,Wb,Ib) \
    cynw_fixed< CWFX_ADD_W(Wa,Ia,Wb,Ib)+1, CWFX_ADD_I(Ia,Ib)+1 >
#define CWFX_SUB_UU(Wa,Ia,Wb,Ib) \
    cynw_fixed< CWFX_SUB_W(Wa,Ia,Wb,Ib),   CWFX_SUB_I(Ia,Ib) >

// CYNW_FIXED_GENERIC_BASE
//
// If this #define has a non-zero value then cynw_fixed and cynw_ufixed will
// be derived from sc_generic_base<T>, and there will not be any casts for
// sc_int<W>, etc. in their definitions. This removes the ambiguity that would
// be present if casts to double() and sc_int<W>, etc., were both present
// in cynw_fixed and cynw_ufixed. sc_int<W>, etc., know how to assign a
// value from sc_generic_base<T> so the casts are not necessary. 

#ifndef CYNW_FIXED_GENERIC_BASE
#   define CYNW_FIXED_GENERIC_BASE 1
#endif

#define CYNW_MAXPOS ((CYNW_IVAL(W))~((CYNW_IVAL(W))(1)<<(W-1)))
#define CYNW_MAXNEG ((CYNW_IVAL(W))((CYNW_IVAL(W))(1)<<(W-1)))
#define CYNW_MAXNEGP1 ((CYNW_IVAL(W))(((CYNW_IVAL(W))(1)<<(W-1))+1))
#define CYNW_UMAXPOS ((CYNW_UVAL(W))~(CYNW_IVAL(W))0)

// Define some DPOPT directives for use when required
#if defined CYNW_FX_NO_DPOPT
#define CYNW_DPOPT_DIV
#else
#define CYNW_DPOPT_DIV CYN_DPOPT_INLINE(DPOPT_DEFAULT, "DivRem", "DivRem")
#endif

/* this suppresses messages about DPOPT_INLINE being ignored when nested */
#if defined(STRATUS_HLS) && !defined(CYN_DONT_SUPPRESS_MSGS)
#pragma cyn_suppress_msgs NOTE
#endif

#define CYNW_FIXED_EXPLICIT 

// Short cut to output a type name to a stream:
   
#define CYNW_FX_NAME(TYPE,W,I,Q_MODE,O_MODE,N_BITS) \
    #TYPE << "<" \
    << W << ","  \
    << I << "," \
    << Q_MODE << "," \
    << O_MODE << "," \
    << N_BITS \
    << ">"
		     
// forward declare cynw_fixed and cynw_ufixed 
template<const int W, const int I, const sc_q_mode Q_MODE=SC_TRN, const sc_o_mode O_MODE=SC_WRAP, const int N_BITS=0> class cynw_fixed;

template<const int W, const int I, const sc_q_mode Q_MODE=SC_TRN, const sc_o_mode O_MODE=SC_WRAP, const int N_BITS=0> class cynw_ufixed;

// +============================================================================
// | cynw_fixed_subref_r<W,O_MODE> - Read Only Part Selection For cynw_fixed.
// | 
// | This class implements the read-only part selection class for cynw_fixed
// | targets.
// +============================================================================
template<const int W, const sc_o_mode O_MODE>
class cynw_fixed_subref_r 
{
  public:
    typedef cynw_fixed_subref_r<W,O_MODE> this_type;

  public:
    cynw_fixed_subref_r(const CYNW_IVAL(W)& target, int l, int r) :
        m_l(l), m_r(r), m_target(target)
    { 
    }
    
  public:
    operator CYNW_SUBREF(W) () const
    {
        return (CYNW_SUBREF(W)) (((CYNW_UVAL(W))m_target)(m_l,m_r));
    }

  protected: // data fields.
    int                 m_l;
    int                 m_r;
    const CYNW_IVAL(W)& m_target;

  private:
    const this_type operator = (const this_type&);
};

template<const int W, const sc_o_mode O_MODE>
inline 
ostream& operator << (ostream& os, const cynw_fixed_subref_r<W,O_MODE>& a)
{
    sc_bv<W> temp = a();
    // os << (const CYNW_UVAL(W))a;
    os << temp;
    return os;
}


// +============================================================================
// | cynw_fixed_subref<W,O_MODE> - Read-Write Part Selection For cynw_fixed.
// | 
// | This class implements the read-write part selection class for cynw_fixed
// | targets.
// +============================================================================
template<const int W, const sc_o_mode O_MODE>
class cynw_fixed_subref 
{
  public:
    typedef cynw_fixed_subref<W,O_MODE> this_type;

  public:
    cynw_fixed_subref(CYNW_IVAL(W)& target, int l, int r) :
        m_l(l), m_r(r), m_target(target)
    { 
    }
    
  public:
    const this_type& operator = (const this_type& v)
    {
        m_target(m_l,m_r) = (CYNW_UVAL(W))v;
#       if !defined(STRATUS_HLS)
            if ( O_MODE == SC_SAT_SYM && m_target == CYNW_MAXNEG ) 
	    {
                cout << "#####################################################";
                cout << "#######################" << endl;
                cout << "# WARNING: cynw_fixed type with O_MODE = SC_SAT_SYM ";
		cout << "was set to an illegal  #" << endl;
                cout << "# value using a subref or range operator. " << endl;
                cout << "#####################################################";
                cout << "#######################" << endl;
            }
#       endif
        return *this;
    }
    template<typename T>
    const this_type& operator = (const T& v)
    {
        m_target(m_l,m_r) = v;
#       if !defined(STRATUS_HLS)
            if ( O_MODE == SC_SAT_SYM && m_target == CYNW_MAXNEG ) 
	    {
                cout << "#####################################################";
                cout << "#######################" << endl;
                cout << "# WARNING: cynw_fixed type with O_MODE = SC_SAT_SYM ";
		cout << "was set to an illegal  #" << endl;
                cout << "# value using a subref or range operator. " << endl;
                cout << "#####################################################";
                cout << "#######################" << endl;
            }
#       endif
        return *this;
    }

  public:
    operator CYNW_SUBREF(W) () const
    {
        return (CYNW_SUBREF(W)) (((CYNW_UVAL(W))m_target)(m_l,m_r));
    }

  protected:
    int           m_l;
    int           m_r;
    CYNW_IVAL(W)& m_target;
};

template<const int W, const sc_o_mode O_MODE>
inline ostream& operator << (ostream& os, const cynw_fixed_subref<W,O_MODE>& a)
{
    sc_bv<W> temp = a();
    // os << (const CYNW_UVAL(W))a;
    os << temp;
    return os;
}


// +============================================================================
// | cynw_ufixed_subref_r<W,O_MODE> - Read Only Part Selection For cynw_ufixed.
// | 
// | This class implements the read-only part selection class for cynw_ufixed
// | targets.
// +============================================================================
template<const int W, const sc_o_mode O_MODE>
class cynw_ufixed_subref_r {
  public:
    typedef cynw_ufixed_subref_r<W,O_MODE> this_type;

  public:
    cynw_ufixed_subref_r(const CYNW_UVAL(W)& target, int l, int r) :
        m_l(l), m_r(r), m_target(target)
    { 
        //cout << "ufixed_subref_r: " << target << " " << l << " " << r << endl;
    }
    
  public:
    operator CYNW_SUBREF(W) () const
    {
        return (CYNW_SUBREF(W)) (((CYNW_UVAL(W))m_target)(m_l,m_r));
    }

  protected:
    int               m_l;
    int               m_r;
    const CYNW_UVAL(W)& m_target;

  private:
    const this_type& operator = (const this_type&);
};

template<const int W, const sc_o_mode O_MODE>
inline 
ostream& operator << (ostream& os, const cynw_ufixed_subref_r<W,O_MODE>& a)
{
    os << (const CYNW_UVAL(W))a;
    return os;
}

// +============================================================================
// | cynw_ufixed_subref<W,O_MODE> - Read-Write Part Selection For cynw_ufixed.
// | 
// | This class implements the read-write part selection class for cynw_ufixed
// | targets.
// +============================================================================
template<const int W, const sc_o_mode O_MODE>
class cynw_ufixed_subref {
  public:
    typedef cynw_ufixed_subref<W,O_MODE> this_type;

  public:
    cynw_ufixed_subref(CYNW_UVAL(W)& target, int l, int r) :
        m_l(l), m_r(r), m_target(target)
    { 
        //cout << "ufixed_subref: " << target << " " << l << " " << r << endl;
    }
    
  public:
    const this_type& operator = (const this_type& v)
    {
        m_target(m_l,m_r) = (CYNW_UVAL(W))v;
        return *this;
    }
    template<typename T>
    const this_type& operator = (const T& v)
    {
        m_target(m_l,m_r) = v;
        return *this;
    }

  public:
    operator CYNW_SUBREF(W) () const
    {
        return (CYNW_SUBREF(W)) (((CYNW_UVAL(W))m_target)(m_l,m_r));
    }

  protected:
    int         m_l;
    int         m_r;
    CYNW_UVAL(W)& m_target;
};


template<const int W, const sc_o_mode O_MODE>
inline ostream& operator << (ostream& os, const cynw_ufixed_subref<W,O_MODE>& a)
{
    os << (const CYNW_UVAL(W))a;
    return os;
}

// WARNING: this will only be totally accurate where valid source bits are <= 52

template<int W>
inline std::string cwfx_decimal_fraction( sc_biguint<W> source )
{
    double fraction = 0.0;
    double mult = 1.0;
    for ( int src_i = W-1; src_i >=0; --src_i ) {
	mult = mult * 0.5;
        fraction += mult * source[src_i];
    }
    std::ostringstream fracStream;
    fracStream.precision(40);
    fracStream.setf(ios::fixed);
    fracStream << fraction;
    std::string buffer = fracStream.str();
    int buffer_n = buffer.size();
    int back_i;
    for ( back_i = buffer_n-1; back_i > 2; --back_i ) {
        if ( buffer[back_i] != '0' ) break;
    }
    buffer[back_i+1] = '\0';
    return &buffer[2];
}


// +============================================================================
// | cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> - Signed Fixed Point Class
// | 
// | This is a synthesizable fixed point class that emulates the behavior of
// | sc_fixed.
// +============================================================================
template<const int W, const int I, const sc_q_mode Q_MODE, 
         const sc_o_mode O_MODE, const int N_BITS >
#if CYNW_FIXED_GENERIC_BASE
    class cynw_fixed : 
    public sc_dt::sc_generic_base<cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> > {
#else
    class cynw_fixed {
#endif

  public: // typedef shortcuts:
    typedef cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> this_type;

  public: // Constructors
    cynw_fixed(int a) 
    {
        cynw_fixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,SC_TRN,SC_WRAP,0> tmp;
        tmp.value = a;
        *this = tmp;
    }

    cynw_fixed(unsigned int a) 
    {
      cynw_fixed<CYNW_BITS_PER_INT+1,CYNW_BITS_PER_INT+1,SC_TRN,SC_WRAP,0> tmp;
      tmp.value = a;
      *this = tmp;
    }

    cynw_fixed(double a) 
    {
        // Note: just convert to a cynw_fixed that is 2 bits bigger on either 
	// end, and then let assignment do the rounding and saturation.
       
        sc_int<CYNW_DOUBLE_EXP>                     exp;
        sc_uint<CYNW_BITS_PER_DOUBLE>               ireg;
        sc_biguint<CYNW_DOUBLE_MAN+1>               man;
        cynw_fixed<W+4,I+2, Q_MODE, O_MODE, N_BITS> tmp;

        ireg = doubleToRawBits(a);        
        exp = ireg(CYNW_DOUBLE_MAN+CYNW_DOUBLE_EXP-1,CYNW_DOUBLE_MAN) - 
	      CYNW_DOUBLE_BIAS;
        man = ireg(CYNW_DOUBLE_MAN-1,0);

        if( (ireg & 0x7fffffffffffffffLL)==0 ) 
	{
            tmp.value = 0;
        }
	else
	{
            man[CYNW_DOUBLE_MAN] = 1;
            int shft = CYNW_DOUBLE_MAN+1-((int)exp+1)-(W+4-(I+2));
            if (shft < -CYNW_DOUBLE_MAN)
                tmp.value = 0;
            else if (shft < 0) 
	    {
                tmp.value = man << -shft;
            } 
	    else if (shft == 0)
	    {
                tmp.value = man;
	    }
            else if (shft <= CYNW_DOUBLE_MAN) 
	    {
                tmp.value = man >> shft;
		// or in the sticky bit
                (tmp.value) |= (sc_uint<1>)(man(shft-1,0)!=0);  
            } 
	    else
	    {
	        // sticky bit is all that's left
                tmp.value = 1;                
	    }
	    // sticky bit on high side
            if (CYNW_DOUBLE_MAN+1-shft > W+2) 
                tmp.value[W+2] = 1;   
	    // don't flip sign bit
            tmp.value[W+3] = 0;               
            if( ireg[CYNW_DOUBLE_MAN+CYNW_DOUBLE_EXP] )
                tmp.value = -tmp.value;
        }
        *this = tmp;
    }

    template<int WW>
    cynw_fixed(const sc_int<WW> & a) 
    {
        cynw_fixed<WW,WW,SC_TRN,SC_WRAP,0> tmp;
        tmp.value = a;
        *this = tmp;
     }

    template<int WW>
    cynw_fixed(const sc_uint<WW> & a) 
    {
        cynw_ufixed<WW,WW,SC_TRN,SC_WRAP,0> tmp;
        tmp.value = a;
        *this = tmp;
    }

    template<int WW>
    cynw_fixed(const sc_bigint<WW> & a) 
    {
        // cynw_fixed<WW,WW,SC_TRN,SC_WRAP,0> tmp;
        cynw_fixed<CYNW_MIN(WW,W),CYNW_MIN(WW,W),SC_TRN,SC_WRAP,0> tmp;
        tmp.value = a;
        *this = tmp;
    }

    template<int WW>
    cynw_fixed(const sc_biguint<WW> & a) 
    {
        // cynw_fixed<WW+1,WW+1,SC_TRN,SC_WRAP,0> tmp;
        cynw_fixed<CYNW_MIN(WW+1,W),CYNW_MIN(WW+1,W),SC_TRN,SC_WRAP,0> tmp;
        tmp.value = a;
        *this = tmp;
    }

    // This one is here to catch constructors,
    //  i.e. cynw_fixed<.> a(cf), which otherwise won't get seen
    cynw_fixed(const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> &a) 
    {
        *this = a;
    }

    template<const int W1, const int I1, const sc_q_mode Q1, const sc_o_mode O1,             const int N1>
    cynw_fixed(const cynw_fixed<W1,I1,Q1,O1,N1> &a) 
    {
        *this = a;
    }

    template<const int W1, const int I1, const sc_q_mode Q1, const sc_o_mode O1,
             const int N1>
    cynw_fixed(const cynw_ufixed<W1,I1,Q1,O1,N1> &a) 
    {
        cynw_fixed<W1+1,I1+1,SC_TRN,SC_WRAP,0> tmp;
        tmp.value = a.value;
        *this = tmp;
    }

    cynw_fixed(long a)
    {
        *this = (sc_int<CYNW_BITS_PER_LONG>)a;
    }

    cynw_fixed(long long a) 
    {
        *this = (sc_int<CYNW_BITS_PER_LONGLONG>)a;
    }

    cynw_fixed(unsigned long a) 
    {
        *this = (sc_uint<CYNW_BITS_PER_LONG>)a;
    }

    cynw_fixed(unsigned long long a) 
    {
        *this = (sc_uint<CYNW_BITS_PER_LONGLONG>)a;
    }

    cynw_fixed() 
    {
        value = 0;
    }

    // Destructor
    ~cynw_fixed() { }

    // width methods:

    int iwl() const { return I; }
    int wl() const  { return W; }
  
    
    // DEBUGGING METHODS THAT ARE NOT SYNTHESIZABLE:

#ifndef STRATUS_HLS
#if 1
    void to_dec_string( ostringstream& s, bool prefix, sc_fmt fmt ) const
    {
	sc_biguint<CYNW_MAX(1,W-I)> fracPart;
	std::string                 fracString;
	std::ostringstream          fracStream;
	std::ostringstream          intStream;
	sc_biguint<CYNW_MAX(I,1)>   intPart;
	std::string                 intString;
	CYNW_IVAL(W)                unsValue;

	if ( value  < CYNW_IVAL(W)(0) ) {
	    unsValue = CYNW_IVAL(W)(0)-value; // keep startus happy with cynw_cm_float.
	    s << "-";
	}
	else {
	    unsValue = value;
	}

	if ( prefix ) { s << "0d"; }

        if ( (CYNW_IVAL(W))0 == value ) { 
            s << "0" << ends;
            return;
        }

        if (I>0 && W>I)       { intPart = unsValue(W-1,W-I); }
        else if (I>0 && W<=I) { intPart = unsValue << ((W<=I) ? (I-W) : 0); }
        else                  { intPart = 0; }

        if ( W-I > 0 && I>=0)     { fracPart = unsValue(W-I-1,0); }
        else if ( W-I > 0 && I<0) { fracPart = unsValue; }
        else                      { fracPart = 0; }


	if ( SC_F == fmt ) {
	    if ( 0 != intPart ) {
		s << intPart;
		if ( 0 != fracPart ) {
		    s << "." << cwfx_decimal_fraction(fracPart);
		}
	    }
	    else {
		s << "." << cwfx_decimal_fraction(fracPart);
	    }
        }
        else {
	    if ( 0 != intPart ) {
	        intStream << intPart;
		intString = intStream.str();
		s << intString[0] << ".";
		for ( size_t str_i = 1; str_i < intString.size(); ++str_i ) {s << intString[str_i];}
		if ( 0 != fracPart ) {
		    s << cwfx_decimal_fraction(fracPart);
		}
		s << "e0" << intString.size()-1 << ends;
	    }
	    else {
	        fracStream << cwfx_decimal_fraction(fracPart);
		fracString = fracStream.str();
		size_t nonZero_i;
		for ( nonZero_i = 0; nonZero_i < fracString.size(); ++nonZero_i ) {
		    if ( '0' != fracString[nonZero_i] ) { break; }
		}
		s << fracString[nonZero_i] << ".";
		for ( size_t frac_i = nonZero_i + 1; frac_i < fracString.size(); ++frac_i ) {
		    s << fracString[frac_i];
		}
                s << "e-0" << nonZero_i+1;
	    }
        }
	s << ends;
    }
        
    const std::string to_string( sc_numrep nr, bool prefix, sc_fmt fmt ) 
    const
    {
        static std::string val("");
        ostringstream s;

        if ( SC_DEC == nr ) {
            to_dec_string( s, prefix, fmt );
	    val = s.str().c_str();
	    return val;
	}

  
        sc_biguint<CYNW_MAX(I,1)> int_part;
        sc_biguint<CYNW_MAX(1,W-I)> frac_part;
        if (I>0 && W>I)
            int_part = value(W-1,W-I);
        else if (I>0 && W<=I)
            int_part = value << ((W<=I) ? (I-W) : 0);
        else
            int_part = 0;
        if ( W-I > 0 && I>=0)
            frac_part = value(W-I-1,0);
        else if ( W-I > 0 && I<0)
            frac_part = value;
        else
            frac_part = 0;
        int int_mod_bits;
        int int_words;
        int frac_mod_bits;
        int frac_words;
        int i;
        char c;
        sc_uint<8> word;

        switch( nr )
        {
	  case SC_BIN:
	    if( prefix ) s << "0b";
	    for(i=I;i>0;i--) s << int_part[i-1];
	    if (W-I>0)
		s << "." ;
	    for(i=W-I;i>0;i--) s << frac_part[i-1];
	    break;
          case SC_OCT:
	    int_mod_bits = (I>0) ? I%3 : 0;
	    frac_mod_bits = (W>I) ? (W-I)%3 : 0;
	    int_words = (I>0) ? (I/3 + (int_mod_bits ? 1:0)) : 0;
	    frac_words = (W>I) ? ((W-I)/3 + (frac_mod_bits ? 1:0)) : 0;
	    if( prefix ) s << "0o";
	    for(i=int_words;i>0;i--) 
	    {
		if( i==int_words && int_mod_bits!=0 ) 
		{
		    word = int_part(I-1,I-int_mod_bits);
		    if ( int_mod_bits!=0 && value[W-1]) 
		    {
		      word |= ((0x7) << int_mod_bits);
		      word &= 0x7;
		    }
		}
		else
		{
		    word = int_part(i*3-1,i*3-3);
	      }
	      c = (sc_uint<8>)'0'+word;
	      s << c;
	  }
	  if (frac_words>0 || frac_mod_bits>0)
	      s << ".";
	  for(i=frac_words;i>0;i--) 
	  {
	      if( frac_mod_bits != 0 ) 
	      {
		  if( i == 1 )
		      word = frac_part(frac_mod_bits-1,0) << (3-frac_mod_bits);
		  else
		      word = frac_part((i-1)*3-1+frac_mod_bits,(i-1)*3-3+
			     frac_mod_bits);
	      }
	      else
	      {
		  word = frac_part(i*3-1,i*3-3);
	      }
	      c = (sc_uint<8>)'0'+word;
	      s << c;
	  }
	  break;
        case SC_HEX:
	  int_mod_bits = (I>0) ? I%4 : 0;
	  frac_mod_bits = (W>I) ? (W-I)%4 : 0;
	  int_words = (I>0) ? (I/4 + (int_mod_bits ? 1:0)) : 0;
	  frac_words = (W>I) ? ((W-I)/4 + (frac_mod_bits ? 1:0)) : 0;
	  if( prefix ) s << "0x";
	  for(i=int_words;i>0;i--) 
	  {
	      if( i==int_words && int_mod_bits!=0 ) 
	      {
		  word = int_part(I-1,I-int_mod_bits);
		  if ( int_mod_bits!=0 && value[W-1]) 
		  {
		    word |= ((0xf) << int_mod_bits);
		    word &= 0xf;
		  }
	      }
	      else
	      {
		  word = int_part(i*4-1,i*4-4);
	      }
	      if( (unsigned int)word > 9 ) 
		  c = (sc_uint<8>)'a'+word-10;
	      else
		  c = (sc_uint<8>)'0'+word;
	      s << c;
	  }
	  if (frac_words>0 || frac_mod_bits>0)
	      s << ".";
	  for(i=frac_words;i>0;i--) 
	  {
	      if( frac_mod_bits!=0 ) 
	      {
		  if( i==1 ) 
		  {
		      word = frac_part(frac_mod_bits-1,0) << (4-frac_mod_bits);
		  } 
		  else
		      word = frac_part((i-1)*4-1+frac_mod_bits,(i-1)*4-4+
			     frac_mod_bits);
	      }
	      else
	      {
		  word = frac_part(i*4-1,i*4-4);
	      }
	      if( (unsigned int)word > 9 ) 
		  c = (sc_uint<8>)'a'+word-10;
	      else
		  c = (sc_uint<8>)'0'+word;
	      s << c;
	  }
	  break;
        case SC_CSD:
          break;
        default:
	    cerr << "cynw_fixed::to_string() - "
                 << "number representation  not handled: " 
                 << nr << endl;
            break;
      }
      s << ends;
      val = s.str().c_str();
      return val;
  }
#else
    const std::string to_string( sc_numrep nr, bool prefix, sc_fmt fmt ) 
    const
    {
        static std::string exp("");
        static std::string val("");
        ostringstream s,sf;
  
        sc_biguint<CYNW_MAX(I,1)> int_part;
        sc_biguint<CYNW_MAX(1,W-I)> frac_part;
        if (I>0 && W>I)
            int_part = value(W-1,W-I);
        else if (I>0 && W<=I)
            int_part = value << ((W<=I) ? (I-W) : 0);
        else
            int_part = 0;
        if ( W-I > 0 && I>=0)
            frac_part = value(W-I-1,0);
        else if ( W-I > 0 && I<0)
            frac_part = value;
        else
            frac_part = 0;
        int int_mod_bits;
        int int_words;
        int frac_mod_bits;
        int frac_words;
        int i;
        char c;
        sc_uint<8> word;

        switch( nr )
        {
          case SC_DEC:
            sf.precision(40);
            if( fmt == SC_F ) 
	    {
		sf.setf(ios::fixed); 
            } 
	    else 
	    {
		sf.setf( ios::scientific );
            }
            sf << to_double() << ends;
            val = ( char * ) sf.str().c_str();
  
            i = val.find_last_of('e');
            if ( i > 0 )
            {
		exp = val.substr(i);
		--i;
            }
            else
            {
		exp = "";
		i = val.size()-1;
            }
            for ( ; i > 0; --i )
            {
		if ( val[i] != '0' ) break;
            }
            if( val[i]=='.' ) --i;
            val = val.substr(0,i+1) + exp;
  
	    if( val[0] == '-' ) 
	    {
		val = val.substr(1,val.size()-1);
		s << "-";
	    }
	    if (val[0]=='0' && val[1]=='.') // remove leading zero
	    {
		val = val.substr(1,val.size()-1);
	    }
	    if( prefix ) s << "0d";
	    s << val << ends;
	    break;
	  case SC_BIN:
	    if( prefix ) s << "0b";
	    for(i=I;i>0;i--) s << int_part[i-1];
	    if (W-I>0)
		s << "." ;
	    for(i=W-I;i>0;i--) s << frac_part[i-1];
	    break;
          case SC_OCT:
	    int_mod_bits = (I>0) ? I%3 : 0;
	    frac_mod_bits = (W>I) ? (W-I)%3 : 0;
	    int_words = (I>0) ? (I/3 + (int_mod_bits ? 1:0)) : 0;
	    frac_words = (W>I) ? ((W-I)/3 + (frac_mod_bits ? 1:0)) : 0;
	    if( prefix ) s << "0o";
	    for(i=int_words;i>0;i--) 
	    {
		if( i==int_words && int_mod_bits!=0 ) 
		{
		    word = int_part(I-1,I-int_mod_bits);
		    if ( int_mod_bits!=0 && value[W-1]) 
		    {
		      word |= ((0x7) << int_mod_bits);
		      word &= 0x7;
		    }
		}
		else
		{
		    word = int_part(i*3-1,i*3-3);
	      }
	      c = (sc_uint<8>)'0'+word;
	      s << c;
	  }
	  if (frac_words>0 || frac_mod_bits>0)
	      s << ".";
	  for(i=frac_words;i>0;i--) 
	  {
	      if( frac_mod_bits != 0 ) 
	      {
		  if( i == 1 )
		      word = frac_part(frac_mod_bits-1,0) << (3-frac_mod_bits);
		  else
		      word = frac_part((i-1)*3-1+frac_mod_bits,(i-1)*3-3+
			     frac_mod_bits);
	      }
	      else
	      {
		  word = frac_part(i*3-1,i*3-3);
	      }
	      c = (sc_uint<8>)'0'+word;
	      s << c;
	  }
	  break;
        case SC_HEX:
	  int_mod_bits = (I>0) ? I%4 : 0;
	  frac_mod_bits = (W>I) ? (W-I)%4 : 0;
	  int_words = (I>0) ? (I/4 + (int_mod_bits ? 1:0)) : 0;
	  frac_words = (W>I) ? ((W-I)/4 + (frac_mod_bits ? 1:0)) : 0;
	  if( prefix ) s << "0x";
	  for(i=int_words;i>0;i--) 
	  {
	      if( i==int_words && int_mod_bits!=0 ) 
	      {
		  word = int_part(I-1,I-int_mod_bits);
		  if ( int_mod_bits!=0 && value[W-1]) 
		  {
		    word |= ((0xf) << int_mod_bits);
		    word &= 0xf;
		  }
	      }
	      else
	      {
		  word = int_part(i*4-1,i*4-4);
	      }
	      if( (unsigned int)word > 9 ) 
		  c = (sc_uint<8>)'a'+word-10;
	      else
		  c = (sc_uint<8>)'0'+word;
	      s << c;
	  }
	  if (frac_words>0 || frac_mod_bits>0)
	      s << ".";
	  for(i=frac_words;i>0;i--) 
	  {
	      if( frac_mod_bits!=0 ) 
	      {
		  if( i==1 ) 
		  {
		      word = frac_part(frac_mod_bits-1,0) << (4-frac_mod_bits);
		  } 
		  else
		      word = frac_part((i-1)*4-1+frac_mod_bits,(i-1)*4-4+
			     frac_mod_bits);
	      }
	      else
	      {
		  word = frac_part(i*4-1,i*4-4);
	      }
	      if( (unsigned int)word > 9 ) 
		  c = (sc_uint<8>)'a'+word-10;
	      else
		  c = (sc_uint<8>)'0'+word;
	      s << c;
	  }
	  break;
        case SC_CSD:
          break;
        default:
	    cerr << "cynw_fixed::to_string() - "
                 << "number representation  not handled: " 
                 << nr << endl;
            break;
      }
      s << ends;
      val = s.str().c_str();
      return val;
  }
#endif

  const std::string to_bin() const
  {
      return to_string( SC_BIN, -1, SC_F );
  }
  const std::string to_dec() const
  {
      return to_string( SC_DEC, false, SC_F );
  }
  const std::string to_hex() const
  {
      return to_string( SC_HEX, -1, SC_F );
  }
  const std::string to_oct() const
  {
      return to_string( SC_OCT, -1, SC_F );
  }
  const std::string to_string() const
  {
      return to_string(SC_DEC, false, SC_F);
  }

  const std::string to_string(sc_numrep nr) const
  {
      return to_string(nr, (nr!=SC_DEC), SC_F);
  }

  const std::string to_string(sc_numrep nr, bool prefix) const
  {
      return to_string(nr, prefix, SC_F);
  }

  const std::string to_string(sc_fmt fmt) const
  {
      return to_string(SC_DEC, false, fmt);
  }

  const std::string to_string(sc_numrep nr, sc_fmt fmt) const
  {
      return to_string(nr, true, fmt);
  }

  void print( ostream& os ) const
  {
	print( os, sc_io_base(os, SC_DEC) );
  }
  void print( ostream& os, sc_numrep base ) const
  {
	switch( base ) {
	  case SC_BIN: os << this->to_bin().c_str(); break;
	  default:
	  case SC_DEC: os << this->to_dec().c_str(); break;
	  case SC_HEX: os << this->to_hex().c_str(); break;
	  case SC_OCT: os << this->to_oct().c_str(); break;
        }
  }

  void dump( ostream& cout ) const
  {
      cout << "value  = " << to_string(SC_HEX) << endl;
      cout << "wl     = " << W << endl;
      cout << "iwl    = " << I << endl;
      cout << "q_mode = " ;
      switch( Q_MODE )
      {
          case SC_TRN: cout << "SC_TRN"; break;
          case SC_RND: cout << "SC_RND"; break;
          case SC_RND_INF: cout << "SC_RND_INF"; break;
      }
      cout << endl;
      cout << "o_mode = ";
      switch( O_MODE )
      {
          case SC_WRAP: cout << "SC_WRAP"; break;
          case SC_SAT: cout << "SC_SAT"; break;
          case SC_SAT_SYM: cout << "SC_SAT_SYM"; break;
      }
      cout << endl;
      cout << "n_bits = 0" << endl;
  }

#endif //STRATUS_HLS

// NCSC VALUE ACCESS METHODS:

#if defined(NC_SYSTEMC)
    const char* ncsc_print() const                          
    { 
        std::ostringstream ostr;
        print(ostr); 
	return ostr.str().c_str();
    }
    const char* ncsc_print_r( sc_numrep r ) const
    { 
        std::ostringstream ostr;
        print(ostr, r); 
	return ostr.str().c_str();
    }
#endif // defined(NC_SYSTEMC)
  
    // +--------------------------------------------------------------------------------------------
    // |"cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>::round"
    // | 
    // | This method determines whether this object instance's value should
    // | be incremented based on the supplied rounding information, and performs
    // | the increment if needed.
    // |
    // | Arguments:
    // |     lR = least significant remaining bit.
    // |     mD = most significant deleted bit.
    // |     r  = logical or of the deleted bits except mD.
    // |     sR = sign bit 
    // +--------------------------------------------------------------------------------------------
    void round( const sc_uint<1>& lR, const sc_uint<1>& mD, 
		const sc_uint<1>& r, const sc_uint<1>& sR )
    {
        switch(Q_MODE)
	{
	    // SC_RND: Add the most significant deleted bit to remaining bits.
	
	    case SC_RND:
	        if ( mD ) value++;
		break;
    
	    // SC_RND_ZERO: If the most significant deleted bit is 1 and either
	    //              the sign bit or at least one other deleted bit is 1,
	    //              add 1 to the remaining bits.
    
	    case SC_RND_ZERO:
	        if ( (sc_uint<1>)( mD & (sR | r) ) ) value++;
		break;
    
	    // SC_RND_MIN_INF: If the most significant deleted bit is 1 and at 
	    // least one other deleted bit is 1, add 1 to the remaining bits.
    
	    case SC_RND_MIN_INF:
	        if ( (sc_uint<1>)(mD & r) ) value++;
		break;
    
	    // SC_RND_INF: If the most significant deleted bit is 1 and either
	    // the inverted value of the sign bit or at least one other deleted
	    // bit is 1, add 1 to the remaining bits.
    
	    case SC_RND_INF:
	        if ( (sc_uint<1>)(mD & (~sR | r)) ) value++;
		break;
    
	    // SC_RND_CONV: If the most significant deleted bit is 1 and either
	    // the least significant of the remaining bits or at least one other
	    // deleted bit is 1, add 1 to the remaining bits.
    
	    case SC_RND_CONV:
	        if ( (sc_uint<1>)(mD & (lR | r)) ) value++;
		break;
    
	    // SC_TRN_ZERO: if the sign bit is 1 and either the most significant
	    // deleted bit or at least one other deleted bit is 1, add 1 to the 
	    // remaining bits.
    
	    case SC_TRN_ZERO:
	        if ( (sc_uint<1>)(sR & (mD | r)) ) value++;
		break;

	    default: // SC_TRN
	        break;
	}
    }
  
  // cynw_fixed OPERATOR = OVERLOADS:
  
  const this_type & operator = (const int& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }

  const this_type & operator = (const unsigned int& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }

  const this_type & operator = (const double& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }

  const this_type & operator = (const long& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }

  const this_type & operator = (const long long& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }

  const this_type & operator = (const unsigned long& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }

  const this_type & operator = (const unsigned long long& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }

  template<int WW>
  const this_type & operator = (const sc_int<WW>& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }

  template<int WW>
  const this_type & operator = (const sc_uint<WW>& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }

  template<int WW>
  const this_type & operator = (const sc_bigint<WW>& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }

  template<int WW>
  const this_type & operator = (const sc_biguint<WW>& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }

  template<int W1, int I1, sc_q_mode Q1, sc_o_mode O1, int N1>
  const this_type & operator = (const cynw_ufixed<W1,I1,Q1,O1,N1>& i) 
  {
      *this = cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
      return *this;
  }
  template<int W1, int I1, sc_q_mode Q1, sc_o_mode O1, int N1>
  const this_type & operator = (const cynw_fixed<W1,I1,Q1,O1,N1> & a) 
  {
      sc_uint<1> rndbit = 0;
#if RND_SAT_OPTIM
      sc_uint<1> at_maxpos = 0;
#endif
      if (O_MODE==SC_WRAP_SM) 
      {
          // SC_WRAP_SM is not implemented. 
          // assert(0);
      }
      if ( ( W==W1) && (I==I1) )
      {
        value = a.value;
        if ( O_MODE == SC_SAT_SYM )
        {
            if ( value == CYNW_MAXNEG )
                value = CYNW_MAXNEGP1;
        }
        return *this;
      } 
      else 
      {
          if((W-I)==(W1-I1))
              value = a.value;
          else if((W-I)>(W1-I1))
              value = (CYNW_IVAL(W))(a.value) << (((W-I)-(W1-I1))<0 ? 0 : 
		                                     ((W-I)-(W1-I1)));
          else 
	  {
              sc_uint<1> sR = (sc_uint<1>)(a.value)[W1-1];
              sc_uint<1> mD = (W1-I1)-(W-I)>W1 ? (sc_uint<1>)0 : 
		                           (sc_uint<1>)(a.value)[(W1-I1)-(W-I)-1];
              sc_uint<1> lR = (W1-I1)-(W-I)>=W1 ? (sc_uint<1>)0 : 
		                             (sc_uint<1>)(a.value)[(W1-I1)-(W-I)];
              sc_uint<1> r = (((W1-I1)-(W-I) == 1) || ((W1-I1)-(W-I) > W1)) ? 
		                              0 : (a.value)((W1-I1)-(W-I)-2,0)!=0;
              (((W1-I1)-(W-I))>W1) ? value = 0 : (I<I1) ? 
		  value = ((a.value) >> (CYNW_MAX(0,(W1-I1)-(W-I)))) : 
		  value = (CYNW_IVAL(W))((a.value) >> (CYNW_MAX(0,(W1-I1)-(W-I))));

              if(Q_MODE==SC_TRN) 
                  rndbit = 0;                               // 0
              else if(Q_MODE==SC_RND) 
                  rndbit = mD;                              // mD
              else if (Q_MODE==SC_RND_ZERO) // mD & (sR | r)
	      {
                  rndbit = mD & (sR | r);
              } 
	      else if(Q_MODE==SC_RND_INF) // mD & (!sR | r)
	      {
                  rndbit = mD & (~sR | r);
              } 
	      else if (Q_MODE==SC_RND_MIN_INF) // mD & r
	      {
                  rndbit = mD & r;
              } 
	      else if (Q_MODE==SC_RND_CONV) // mD & (lR | r)
	      {
                  rndbit = mD & (lR | r);
              } 
	      else if(Q_MODE==SC_TRN_ZERO) // sR & (mD | r)
	      {
                  rndbit = sR & (mD | r);
              }
              if (O_MODE==SC_WRAP && N_BITS>1 && value.and_reduce() && 
		  !(a.value)[W1-1] && rndbit ) 
	      {
                  value(W-2,0) = 0;
              } 
	      else
#if RND_SAT_OPTIM
              at_maxpos = (value==CYNW_MAXPOS);
              if (O_MODE==SC_WRAP || O_MODE==SC_WRAP_SM || O_MODE==SC_SAT_ZERO 
		  || (O_MODE==SC_SAT && I1>I) || !at_maxpos) 
	      {
                  if (rndbit) 
                      value++;
                  //value += rndbit;
              }
#else
              if (O_MODE==SC_WRAP || O_MODE==SC_WRAP_SM || O_MODE==SC_SAT_ZERO 
		  || value!=CYNW_MAXPOS) 
	      {
                  if (rndbit) 
                      value++;
              }
#endif // if 1
          }

          // Handle the Overflow mode

          if( O_MODE==SC_SAT_SYM ) 
	  {
              if ( I1==I ) 
	      {
                  if(value==CYNW_MAXNEG)
                      value = CYNW_MAXNEGP1;
              } 
	      else if ( I1>I ) 
	      {
                  if ( (I1-I) >= W1 ) 
		  {
                       if ( a.value.or_reduce() )
                          value = a.value[W1-1] ? CYNW_MAXNEG : CYNW_MAXPOS;
                  } 
		  else if ( ((a.value[W1-(I1-I)-1] == 0) && 
			     a.value(W1-1,W1-(I1-I)).or_reduce()) ||
                             ((a.value[W1-(I1-I)-1] == 1) && 
			      !a.value(W1-1,W1-(I1-I)).and_reduce()) )
		  {
                      value = a.value[W1-1] ? CYNW_MAXNEGP1 : CYNW_MAXPOS;
		  }
		  if( value==CYNW_MAXNEG )
		       value = CYNW_MAXNEGP1;
              }
          } 
	  else if (O_MODE==SC_SAT && I1>I) 
	  {
              if ( (I1-I) >= W1 ) 
	      {
                   if ( a.value.or_reduce() )
                      value = a.value[W1-1] ? CYNW_MAXNEG : CYNW_MAXPOS;
              } 
	      else if ( ((a.value[W1-(I1-I)-1] == 0) && 
			  a.value(W1-1,W1-(I1-I)).or_reduce()) || 
#if RND_SAT_OPTIM
                    at_maxpos ||
#endif
                   ((a.value[W1-(I1-I)-1] == 1) && 
		    !a.value(W1-1,W1-(I1-I)).and_reduce()) )
	      {
                  value = a.value[W1-1] ? CYNW_MAXNEG : CYNW_MAXPOS;
	      }
          } 
	  else if(O_MODE==SC_SAT_ZERO && I1==I) 
	  {
              if( ( (value[W-1] == 0) && a.value[W1-1] ) ||
                  ( (value[W-1] == 1) && !a.value[W1-1] ) )
	      {
                  value = 0;
	      }
          } 
	  else if(O_MODE==SC_SAT_ZERO && I1>I) 
	  {
              if ( (I1-I) >= W1 ) 
	      {
                   value = 0;
              } 
	      else if ( ((value[W-1] == 0) && 
			a.value(W1-1,W1-(I1-I)).or_reduce()) ||
                        ((value[W-1] == 1) && 
			 !a.value(W1-1,W1-(I1-I)).and_reduce()) )
	      {
                  value = 0;
	      }
          } 
	  else if (O_MODE==SC_WRAP && N_BITS>0 && I1>I) 
	  {
              if ( ((value[W-1] == 0) && 
		    a.value(W1-1,W1-(CYNW_MIN(I1-I,W1))).or_reduce() && 
		    !(rndbit && a.value(W1-1,W1-W).and_reduce())) ||
                   ((value[W-1] == 1) && 
		    !a.value(W1-1,W1-(CYNW_MIN(I1-I,W1))).and_reduce()) )
	      {
                  if (a.value[W1-1]) 
		  {
                      if (N_BITS>1) 
                        value = ((sc_uint<1>)1, (sc_uint<N_BITS-1>)0, (sc_uint<W-N_BITS>)value(W-N_BITS-1,0));
                      else
                        value = ((sc_uint<1>)1, value(W-2,0));
                  } 
		  else 
		  {
                      if (N_BITS>1) 
                        value = ((sc_uint<1>)0, (sc_uint<N_BITS-1>)~0, 
				      (sc_uint<W-N_BITS>)value(W-N_BITS-1,0));
                      else
                        value = ((sc_uint<1>)0, value(W-2,0));
                  }
	      }
          } 
	  else if (O_MODE==SC_WRAP && N_BITS>0 && I1==I) 
	  {
              if ( value[W-1] != a.value[W1-1] )
	      {
                  if (a.value[W1-1]) 
		  {
                      if (N_BITS>1) 
                        value = ((sc_uint<1>)1, (sc_uint<N_BITS-1>)0, 
				       (sc_uint<W-N_BITS>)value(W-N_BITS-1,0));
                      else
                        value = ((sc_uint<1>)1, value(W-2,0));
                  } 
		  else 
		  {
                      if (N_BITS>1) 
                        value = ((sc_uint<1>)0, (sc_uint<N_BITS-1>)~0, 
				      (sc_uint<W-N_BITS>)value(W-N_BITS-1,0));
                      else
                        value = ((sc_uint<1>)0, value(W-2,0));
                  }
	      }
          }
      }
      return *this;
  }
  
    // sc_dt::sc_generic_base REQUIRED METHODS:
    
    inline int to_int() const
    {
        sc_int<32> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }

    inline int64 to_int64() const
    {
        sc_int<64> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }

    inline long to_long() const
        {
        sc_int<64> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }

    inline void to_sc_signed(sc_signed& result) const
    {
        if (W>I) 
            result = value >> ((W-I>0) ? (W-I) : 0); 
        else
            result = value << ((W-I>0) ? 0 : (I-W)); 
    }

    inline void to_sc_unsigned(sc_unsigned& result) const
    {
        if (W>I) 
            result = value >> ((W-I>0) ? (W-I) : 0); 
        else
            result = value << ((W-I>0) ? 0 : (I-W)); 
    }

    inline unsigned int to_uint() const
    {
	sc_uint<32> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }

    inline uint64 to_uint64() const
    {
        sc_uint<64> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }

    inline unsigned long to_ulong() const
    {
	sc_uint<64> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }

    // CASTS THAT ARE NECESSARY IF sc_dt::sc_generic_base IS NOT USED AS A BASE
    // CLASS

#if !CYNW_FIXED_GENERIC_BASE
    template<int WW>
    operator sc_int<WW> () const 
    {
       sc_int<WW> res;
       if (W>I) 
       {
	   res = value >> ((W-I>0) ? (W-I) : 0); 
       } 
       else
	   res = value << ((W-I>0) ? 0 : (I-W)); 
       return res;
   }
     
   template<int WW>
   operator sc_bigint<WW> () const 
   {
       sc_bigint<WW> res;
       if (W>I) 
       {
	   res = value >> W-I; 
       } 
       else
	    res = value << I-W; 
       return res;
   }

    template<int WW>
    operator sc_uint<WW> () const 
    {
        sc_uint<WW> res;
        if (W>I) 
	{
            res = value >> ((W-I>0) ? (W-I) : 0); 
        } 
	else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }

    template<int WW>
    operator sc_biguint<WW> () const 
    {
        sc_biguint<WW> res;
        if (W>I) 
	{
            res = value >> ((W-I>0) ? (W-I) : 0); 
        } 
	else
             res = value << ((W-I>0) ? 0 : (I-W)); 
          return res;
      }
#endif // !CYNW_FIXED_GENERIC_BASE

#if !defined(CYNW_FIXED_NO_DOUBLE_CAST)
    operator double() const
    {
        return to_double();
    }
#endif // defined(CYNW_FIXED_NO_DOUBLE_CAST)

#ifndef STRATUS_HLS
    double to_double () const {
        double res;
        if (W==I)
            res = value.to_double();
        else if (W>I) 
            res = (value.to_double()) / pow(2.0,(W-I));
        else
            res = (value.to_double()) * pow(2.0,(I-W));
        return res;
    }
#else
    sc_int<CYNW_BITS_PER_DOUBLE> to_double() const 
    {
        HLS_MESSAGE(2843);
	return 0;
    }
#endif // STRATUS_HLS

    // +------------------------------------------------------------------------
    // | cynw_fixed UNARY ARITHMETIC OPERATORS:
    // +------------------------------------------------------------------------

    cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> operator ++ () 
    {
        *this = *this + (sc_uint<1>)1;
        return *this;
    }

    cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> operator ++ (int) 
    {
        cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> res = *this;
        *this = res + (sc_uint<1>)1;
        return res;
    }

    cynw_fixed<W+1,I+1,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> operator - () const 
    {
        cynw_fixed<W+1,I+1,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> res = *this;
        res.value = -(res.value);
#if 0
      if( (O_MODE == SC_SAT || O_MODE == SC_SAT_SYM) | O_MODE==SC_SAT_ZERO )
          if( (value[W-1] == res.value[W-1]) && res.value[W-1] ) 
          res.value = (O_MODE==SC_SAT_ZERO) ? (CYNW_IVAL(W))0 : 
                                               CYNW_MAXPOS;
#endif // 0
        return res;
    }

    cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> operator + () const 
    {
        return *this;
    }

    cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> operator -- () 
    {
        *this = *this - (sc_uint<1>)1;
        return *this;
    }

    cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> operator -- (int) 
    {
        cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> res = *this;
        *this = *this - (sc_uint<1>)1;
        return res;
    }

    cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> operator ~ () const 
    {
        cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> res;
        res.value = ~value;
        return res;
    }
    
// +----------------------------------------------------------------------------
// |"cynw_fixed<...>::operator <<"
// | 
// | This operator implements the left shift operator on this object instance.
// | instance. CYNW_FX_LS_SIZE controls the size of the result of the shift 
// | operation, by default it is W, the size of this object instance. 
// |
// | Notes:
// |   (1) In the saturation mode support below note that the range of bits
// |       that are tested when determining if saturation should occur or
// |       not include the new sign bit, since the shift could change the
// |       sign of the result.
// | Arguments:
// |     shift = amount to left shift this object instance's value by.
// | A cynw_fixed<...> instance containing the shifte value.
// +----------------------------------------------------------------------------
template<typename SHIFT>
cynw_fixed<CYNW_FX_LS_SIZE,I+CYNW_FX_LS_SIZE-W,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,
	   N_BITS> 
operator << (const SHIFT& shift) const 
{
    sc_uint<CYN_LOG2(CYNW_FX_LS_SIZE)>                                         b;
    cynw_fixed<CYNW_FX_LS_SIZE,I+CYNW_FX_LS_SIZE-W,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> res;

    // Non-positive shift is treated as a no-op, and an warning is issued
    // in behavioral mode.
    //
    // Note this also eliminates issues with ishift >= CYNW_FX_LS_SIZE-W
    // when CYNW_FX_LS_SIZE is defined as W
    
    if ((int)shift <= 0) 
    {	
#       if !defined(CYNHTHL) && !defined(CYNW_FX_NO_SHIFT_WARNING)
	    if ( (int)shift < 0 )
	    {
		cout << "Warning!!!! cynw_fixed<" << W << "," << I << ","
		     << Q_MODE << "," << O_MODE << "," << N_BITS << "> "
		     << " << " << b << " will be ignored since the shift "
		     << " factor is negative " << endl;
	    }
#       endif
	res.value = value;
    } 

    else 
    {
	// If the shift size is larger than the hardware implementation
	// shift factor can hold set it to that maximum. In behavioral mode 
	// complain.
	
	if ( (int)shift > CYNW_FX_LS_SIZE )
	{
#           if !defined(CYNHTHL) && !defined(CYNW_FX_NO_SHIFT_WARNING)
	        cout << "WARNING: For expression " << endl
		     << "    "
		     << CYNW_FX_NAME(cynw_fixed,W,I,Q_MODE,O_MODE,N_BITS)
		     << " << " << shift << endl 
		     << "  shift value " << shift << " > " 
		     << CYNW_FX_LS_SIZE
		     << " the equation will be changed to " 
		     << endl << "    "
		     << CYNW_FX_NAME(cynw_fixed,W,I,Q_MODE,O_MODE,N_BITS)
		     << " << " << CYNW_FX_LS_SIZE
		     << endl;
#           endif
	    b = sc_uint<CYN_LOG2(CYNW_FX_LS_SIZE)>(CYNW_FX_LS_SIZE);
	}
	else
	{
	    b = sc_uint<CYN_LOG2(CYNW_FX_LS_SIZE)>(shift);
	}
	unsigned int extraBits = CYNW_FX_LS_SIZE-W;

	// WRAP MODE: 
	//
	// N_BITS == 0: All bits except for the deleted bits are copied to the 
	//              result.
	// N_BITS == 1: The result number gets the sign bit of the original 
	//              number. The remaining bits are copied from the original
	//              number.
	// N_BITS >  1: The result number shall get the sign bit of the original
	//              number. The saturated bits shall get the inverse value 
	//              of the sign bit of the original number. The remaining 
	//              bits shall be copied from the original number.

	if ( O_MODE==SC_WRAP && (b>=CYNW_FX_LS_SIZE)) 
	{
	    res.value = 0;
	} 

	// SYMMETRIC WRAP MODE: 
	//
	// N_BITS == 0: The sign bit of the result number shall get the value 
	//              of the least significant deleted bit. The remaining 
	//              bits shall be XORed with the original and the new value
	//              of the sign bit of the result.
	// N_BITS == 1: The result number shall get the sign bit of the original
	//              number. The remaining bits shall be XORed with the 
	//              original and the new value of the sign bit of the 
	//              result.
	// N_BITS >  1: The result number shall get the sign bit of the original
	//              number. The saturated bits shall get the inverse value 
	//              of the sign bit of the original number. The remaining 
	//              bits shall be XORed with the original value of the least
	//              significant saturated bit and the inverse value of the 
	//              original sign bit.

	else if ( O_MODE==SC_WRAP_SM && (b>=CYNW_FX_LS_SIZE)) 
	{
	    res.value = 0;
	} 

	// SATURATION MODE: 
	//
	// The result number gets the sign bit of the original number. The 
	// remaining bits get the inverse value of the sign bit.

	else if (O_MODE==SC_SAT && b>=extraBits) 
	{
	    if ( (value[W-1] == 0) && 
		 (b>=CYNW_FX_LS_SIZE ? (value.or_reduce()) :
	       (value(W-1,W-1-(b-(extraBits))).or_reduce())))
	    {
		res.value = (~((CYNW_IVAL(CYNW_FX_LS_SIZE))(1) <<
			    (CYNW_FX_LS_SIZE-1)));
	    }
	    else if ( (value[W-1] == 1) && 
		      (b>=CYNW_FX_LS_SIZE ? (value.or_reduce()) :
				(value >> (W-1-(b-(extraBits)))) != -1) )
	    {
		res.value = ((CYNW_IVAL(CYNW_FX_LS_SIZE))(1) <<
			    (CYNW_FX_LS_SIZE-1));
	    }
	    else
	    {
		res.value = CYNW_UARG(CYNW_FX_LS_SIZE)(value) << b;
	    }
	} 

	// ZERO SATURATION MODE: if there is a loss of precision set the
	// result to zero.
       
	else if ( O_MODE==SC_SAT_ZERO && b>=(extraBits) ) 
	{
	    if ( ( (value[W-1] == 0) 
		 && (b>=CYNW_FX_LS_SIZE ? (value.or_reduce()) : 
		           (value(W-1,W-1-(b-(extraBits))).or_reduce())) )
		 || ( ((value[W-1] == 1) 
		 && (b>=CYNW_FX_LS_SIZE ? (value.or_reduce()) : 
	                      (value >> (W-1-(b-(extraBits))) ) != -1 ) ) ) )
	    {
		res.value = 0;
	    }
	    else
	    {
		res.value = CYNW_UARG(CYNW_FX_LS_SIZE)(value) << b;
	    }
	} 

	// SYMMETRIC SATURATION MODE: 
	//
	// The result number gets the sign bit of the original number. The 
	// remaining bits get the inverse value of the sign bit, except the 
	// least significant remaining bit, which shall be set to one.
	
	else if ( O_MODE==SC_SAT_SYM && b>(extraBits)) 
	{
	    if ( (value[W-1] == 0) && 
		 (b>=CYNW_FX_LS_SIZE ? (value.or_reduce()) :
	                    (value(W-1,W-1-(b-(extraBits))).or_reduce())))
	    {
		res.value = (~((CYNW_IVAL(CYNW_FX_LS_SIZE))(1) <<
			    (CYNW_FX_LS_SIZE-1)));
	    }
	    else if ( (value[W-1] == 1) && 
		      (b>=CYNW_FX_LS_SIZE ? (value.or_reduce()) :
	                        (value >> (W-1-(b-(extraBits))) ) != -1 ) )
	    {
		res.value = -(~((CYNW_IVAL(CYNW_FX_LS_SIZE))(1) <<
			     (CYNW_FX_LS_SIZE-1)));
	    }
	    else
	    {
		res.value = CYNW_UARG(CYNW_FX_LS_SIZE)(value) << b;
	    }
	} 

	// NO SATURATION TO BE PERFORMED:
	//
	// There was no overflow or this is a mode that just assigns the value.

	else
	{
	    res.value = (b > CYNW_FX_LS_SIZE) ? 0 : 
		                            CYNW_UARG(CYNW_FX_LS_SIZE)(value) << b;
	}
    }
    return res;
}

template<typename SHIFT>
this_type operator <<= (const SHIFT& b) 
{
    *this = *this << b;
    return *this;
}
    
// +----------------------------------------------------------------------------
// |"cynw_fixed<...>::operator >>"
// | 
// | This operator implements the right shift operator on this object instance.
// | instance. 
// |
// | Arguments:
// |     shift = amount to left shift this object instance's value by.
// | A cynw_fixed<...> instance containing the shifted result.
// +----------------------------------------------------------------------------
template<typename SHIFT>
cynw_fixed<CYNW_FX_RS_SIZE,I,Q_MODE,CYNW_RES_O_MODE, N_BITS>
operator >> ( const SHIFT& shift ) const 
{
    int                                                       ishift;
    cynw_fixed<CYNW_FX_RS_SIZE,I,Q_MODE,CYNW_RES_O_MODE, N_BITS> res;

    ishift = shift;

    // SHIFT FACTOR IS NOT POSITIVE:
    //
    // Copy the bits as is, and in behavioral mode produce a warning.

    if ( ishift <= 0 )
    {
#       if !defined(CYNHTHL) && !defined(CYNW_FX_NO_SHIFT_WARNING)
	    if ( ishift < 0 )
	    {
		cout << "Warning!!!! cynw_fixed<" << W << "," << I << ","
		     << Q_MODE << "," << O_MODE << "," << N_BITS << "> "
		     << " >> " << shift << " will be ignored since the shift "
		     << " factor is negative " << endl;
	    }
#       endif
	res.value = value << (CYNW_FX_RS_SIZE-W);
    }

    // SHIFT FACTOR IS LARGER THAN THE TARGET WIDTH: 
    // 
    // If the target is negative and we are truncating the result will be -1, 
    // otherwise it will be zero, either because of rounding or the fact the
    // original value was positive.

    else if ( ishift > CYNW_FX_RS_SIZE ) 
    {
	if ( (Q_MODE == SC_TRN || !CYNW_FX_RS_ROUND) && value[W-1] )
	    res.value = -1;
	else
	    res.value = 0;
    } 

    // SHIFT FACTOR IS > 0 AND <= THE TARGET WIDTH:
    //
    // Set the value based on one of three cases:
    // (a) If the result width is larger than the original target do the 
    //     appropriate adjustment before performing the shift.
    // (b) If our target value is implemented as a native SystemC type
    //     account for the fact we can't handle a shift by 64.
    // (c) Otherwise just do the shift.
    //
    // Perform rounding if that is requested.
    
    else 
    {
	if ( CYNW_FX_RS_SIZE > W )
	{
	    res.value = (value,CYNW_UVAL(CYNW_FX_RS_SIZE-W)(0)); 
	    res.value = (res.value) >> ishift;
	}
	else if ( CYNW_FX_RS_SIZE <= 64 && ishift == 64 )
	{
	    res.value = value[W-1] ? -1 : 0;
	}
	else
	{
	    res.value = value >> ishift; 
	}
	if ( CYNW_FX_RS_ROUND && CYNW_FX_RS_SIZE == W )  
	{
	    res.round( (sc_uint<1>)res.value[0], (sc_uint<1>)value[ishift-1],
		       ishift == 1 ? 0 : value(ishift-2,0).or_reduce(),
		       (sc_uint<1>)value[W-1] );
	}
    }

    return res;
}


template<typename SHIFT>
cynw_fixed<W,I,Q_MODE,CYNW_RES_O_MODE,N_BITS> operator >>= (const SHIFT& shift) 
{
    *this = *this >> shift;
    return *this;
}

    // +------------------------------------------------------------------------
    // | cynw_fixed LOGICAL OPERATORS:
    // +------------------------------------------------------------------------

    template<int W1, int I1, sc_q_mode Q1, sc_o_mode O1, int N1>
    cynw_fixed<CYNW_RES_W,CYNW_RES_I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> 
    operator | (const cynw_fixed<W1,I1,Q1,O1,N1> & b) const 
    {
        cynw_fixed<CYNW_RES_W,CYNW_RES_I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> res;
        if((W-I)==(W1-I1)) 
	{
            res.value = CYNW_IARG(CYNW_RES_W)value | (b.value);
        } 
	else if ((W-I)>(W1-I1)) 
	{
            res.value = CYNW_IARG(CYNW_RES_W)(b.value) << (((W-I)-(W1-I1))<0 ? 0 : ((W-I)-(W1-I1)));
            res.value = (res.value) | value;
        }
	else
	{
            res.value = CYNW_IARG(CYNW_RES_W)value << (((W1-I1)-(W-I))<0 ? 0 : ((W1-I1)-(W-I)));
            res.value = (res.value) | (b.value);
        }
        return res;
    }

    template<int W1, int I1, sc_q_mode Q1, sc_o_mode O1, int N1>
    cynw_fixed<CYNW_RES_W,CYNW_RES_I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> 
    operator & (const cynw_fixed<W1,I1,Q1,O1,N1> & b) const 
    {
        cynw_fixed<CYNW_RES_W,CYNW_RES_I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> res;
        if((W-I)==(W1-I1)) 
	{
            res.value = CYNW_IARG(CYNW_RES_W)value & (b.value);
        } 
	else if ((W-I)>(W1-I1)) 
	{
            res.value = CYNW_IARG(CYNW_RES_W)(b.value) << (((W-I)-(W1-I1))<0 ? 0 : ((W-I)-(W1-I1)));
            res.value = (res.value) & value;
        }
	else
	{
            res.value = CYNW_IARG(CYNW_RES_W)value << (((W1-I1)-(W-I))<0 ? 0 : ((W1-I1)-(W-I)));
            res.value = (res.value) & (b.value);
        }
        return res;
    }

    template<int W1, int I1, sc_q_mode Q1, sc_o_mode O1, int N1>
    cynw_fixed<CYNW_RES_W,CYNW_RES_I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> 
    operator ^ (const cynw_fixed<W1,I1,Q1,O1,N1> & b) const 
    {
        cynw_fixed<CYNW_RES_W,CYNW_RES_I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> res;
        if((W-I)==(W1-I1)) 
	{
            res.value = CYNW_IARG(CYNW_RES_W)value ^ (b.value);
        } 
	else if ((W-I)>(W1-I1)) 
	{
            res.value = CYNW_IARG(CYNW_RES_W)(b.value) << (((W-I)-(W1-I1))<0 ? 0 : ((W-I)-(W1-I1)));
            res.value = (res.value) ^ value;
        }
	else
	{
            res.value = CYNW_IARG(CYNW_RES_W)value << (((W1-I1)-(W-I))<0 ? 0 : ((W1-I1)-(W-I)));
            res.value = (res.value) ^ (b.value);
        }
        return res;
    }

    template<typename OTHER>
    void operator += (const OTHER & b) 
    {
        *this = *this + b;
    }

    template<typename OTHER>
    void operator -= (const OTHER & b) 
    {
        *this = *this - b;
    }

    template<typename OTHER>
    void operator *= (const OTHER & b) 
    {
        *this = *this * b;
    }
  
    template<typename OTHER>
    void operator /= (const OTHER & b) 
    {
        *this = *this / b;
    }
    
    template<const int W1, const int I1, const sc_q_mode Q1, const sc_o_mode O1,
             const int N1>
    void operator &= (const cynw_fixed<W1,I1,Q1,O1,N1> & b) 
    {
        cynw_fixed<W,I> res;
        res = *this & b;
        value = res.value;
        if( O_MODE==SC_SAT_SYM )
        {
            if( value==CYNW_MAXNEG )
                value = CYNW_MAXNEGP1;
        }
    }

    template<const int W1, const int I1, const sc_q_mode Q1, const sc_o_mode O1,
             const int N1>
    void operator |= (const cynw_fixed<W1,I1,Q1,O1,N1> & b) 
    {
        cynw_fixed<W,I> res;
        res = *this | b;
        value = res.value;
        if( O_MODE==SC_SAT_SYM )
        {
            if( value==CYNW_MAXNEG )
                value = CYNW_MAXNEGP1;
        }
    }

    template<const int W1, const int I1, const sc_q_mode Q1, const sc_o_mode O1,             const int N1>
    void operator ^= (const cynw_fixed<W1,I1,Q1,O1,N1> & b) 
    {
        cynw_fixed<W,I> res;
        res = *this ^ b;
        value = res.value;
        if( O_MODE==SC_SAT_SYM )
        {
            if( value==CYNW_MAXNEG )
                value = CYNW_MAXNEGP1;
        }
    }

    // +------------------------------------------------------------------------
    // | cynw_fixed SELECTION (RANGE) OPERATORS:
    // +------------------------------------------------------------------------

    // Range operators
    cynw_fixed_subref_r<W,O_MODE> operator () () const 
    {
        return cynw_fixed_subref_r<W,O_MODE>(value, W-1, 0);
    }
  
    cynw_fixed_subref<W,O_MODE> operator () () 
    {
        return cynw_fixed_subref<W,O_MODE>(value, W-1, 0);
    }
  
    cynw_fixed_subref_r<W,O_MODE> operator () (int a, int b) const 
    {
        return cynw_fixed_subref_r<W,O_MODE>(value, a, b);
    }
  
    cynw_fixed_subref_r<W,O_MODE> range(int a, int b) const {
        return cynw_fixed_subref_r<W,O_MODE>(value, a, b);
    }

    cynw_fixed_subref<W,O_MODE> operator () (int a, int b) 
    {
        return cynw_fixed_subref<W,O_MODE>(value, a, b);
    }
  
    cynw_fixed_subref<W,O_MODE> range(int a, int b) {
        return cynw_fixed_subref<W,O_MODE>(value, a, b);
    }
  
    cynw_fixed_subref_r<W,O_MODE> range() const {
        return cynw_fixed_subref_r<W,O_MODE>(value, W-1, 0);
    }

    cynw_fixed_subref<W,O_MODE> range() {
        return cynw_fixed_subref<W,O_MODE>(value, W-1, 0);
    }


    cynw_fixed_subref<W,O_MODE>  operator [] (const int a) 
    {
        return cynw_fixed_subref<W,O_MODE>(value,a,a);
    }
  
    // +------------------------------------------------------------------------
    // | cynw_fixed PUBLIC METHODS:
    // +------------------------------------------------------------------------

#   if defined(STRATUS_HLS)
        float rawBitsTofloat(int pi);
        int floatToRawBits(float pf);
        double rawBitsTodouble(long long pi);
        long long doubleToRawBits(double pf);
#   else 
  
        float rawBitsTofloat(int pi) 
	{
            union { float f; int i; } x;
            x.i = pi;
            return x.f;
        } 
  
        int floatToRawBits(float pf) 
	{
            union { float f; int i; } x;
            x.f = pf;
            return x.i;
        } 

        double rawBitsTodouble(long long pi) 
	{
            union { double d; long long ll; } x;
            x.ll = pi;
            return x.d;
        } 
        
        long long doubleToRawBits(double pf) 
	{
            union { double d; long long ll; } x;
            x.d = pf;
            return x.ll;
        } 
#endif

    // +------------------------------------------------------------------------
    // | cynw_fixed DATA STORAGE:
    // +------------------------------------------------------------------------

    CYNW_IVAL(W) value;
  protected:  

};


// +------------------------------------------------------------------------
// | cynw_fixed PUBLIC NON-MEMBER FUNCTIONS:
// +------------------------------------------------------------------------

template<int W>
static inline sc_biguint<W> sqrt(
    const sc_biguint<W> &x
)
{
    sc_biguint<W> q = 0;       // quotient output
    sc_biguint<W> r;       // remainder 

    r = x;

    int stages = W/2;
    for (int i = stages - 1; i >= 0; i--) {
        sc_biguint<W> d = (q << (i + 1)) | (sc_biguint<W>(1) << (2 * i));
        if (r >= d) {
            r -= d;
            q |= sc_biguint<W>(1) << i;
        }
    }
    return q;
}

#define CYNW_SQRTHALF 0xb504f333f9de600LL

template<const int W, const int I, const sc_q_mode Q_MODE, 
         const sc_o_mode O_MODE, const int N_BITS>
cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> 
sqrt( cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & a ) 
{
    cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> res;
    sc_biguint<W+W-I> x = (sc_biguint<W+W-I>)a.value;
    if( (W-I) & 1 ) 
    {
        x = x << W-I-1;
        x = sqrt(x);
        res.value = (x * (sc_biguint<61>)((CYNW_SQRTHALF) >> (60-(W)))) >> (W-1);
    }
    else
    {
        x = x << W-I;
        res.value = sqrt(x);
    }
    return res;
}

template <const int W, const int I, const sc_q_mode Q_MODE, 
          const sc_o_mode O_MODE, const int N_BITS>
cynw_fixed<W+(O_MODE!=SC_WRAP?1:0),I+(O_MODE!=SC_WRAP?1:0),Q_MODE,
           CYNW_RES_O_MODE,N_BITS> 
round (const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & a) 
{
    cynw_fixed<W+(O_MODE!=SC_WRAP?1:0),I+(O_MODE!=SC_WRAP?1:0),Q_MODE,
               CYNW_RES_O_MODE,N_BITS> res;
    if( (a.value) < (CYNW_IVAL(W))0 ) 
    {
        res.value =  -(a.value);
        res.value = (res.value) + ( CYNW_IVAL(W)(1LL) << (W-I-1) );
        res = -floor(res);
    } 
    else 
    {
        res.value = (a.value) + ( CYNW_IVAL(W)(1LL) << (W-I-1) );
        res = floor(res);
    }
     return res;
}

template <const int W, const int I, const sc_q_mode Q_MODE, 
          const sc_o_mode O_MODE, const int N_BITS>
cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> 
floor(const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & a) 
{
    cynw_fixed<W,I,CYNW_ARES_Q_MODE,CYNW_ARES_O_MODE,N_BITS> res;
     res.value = (a.value) & ~((1LL << (W-I))-1);
     return res;
}

template <const int W, const int I, const sc_q_mode Q_MODE, 
          const sc_o_mode O_MODE, const int N_BITS>
inline ostream & operator << ( ostream& os, 
	                       const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>& a ) 
{
#ifndef STRATUS_HLS
    a.print( os );
#endif
    return os;
}

template <const int W, const int I, const sc_q_mode Q_MODE, 
          const sc_o_mode O_MODE, const int N_BITS>
inline void sc_trace( sc_trace_file *tf, 
                      const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS>& object, 
                      const std::string& name )
{
    sc_trace( tf, object.value, name );
}

// +============================================================================
// | cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> - Unsigned Fixed Point Class
// | 
// | This is a synthesizable fixed point class that emulates the behavior of
// | sc_ufixed.
// +============================================================================
template<const int W, const int I, const sc_q_mode Q_MODE, const sc_o_mode O_MODE, const int N_BITS >
#if CYNW_FIXED_GENERIC_BASE
    class cynw_ufixed : 
    public sc_dt::sc_generic_base<cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> > {
#else
    class cynw_ufixed {
#endif

  public: // typedef short cuts
    typedef cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> this_type;

  public: // Constructors
    cynw_ufixed(const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> &a) 
    {
        *this = a;
    }

    template<const int W1, const int I1, const sc_q_mode Q1, const sc_o_mode O1,
             const int N1>
    cynw_ufixed(const cynw_ufixed<W1,I1,Q1,O1,N1> &a) 
    {
        *this = a;
    }

    template<const int W1, const int I1, const sc_q_mode Q1, const sc_o_mode O1,
             const int N1>
    cynw_ufixed(const cynw_fixed<W1,I1,Q1,O1,N1> &a) 
    {
        if (O_MODE==SC_WRAP && N_BITS>0) 
	{
            cynw_fixed<W1+1,I1+1,Q1,O1,N1> a1;
            cynw_fixed<W+1,I+1,Q_MODE,O_MODE,N_BITS> tmp;
            cynw_ufixed<W+1,I+1,Q_MODE,O_MODE,N_BITS> tmpu;
            a1.value = ((sc_uint<1>)0, a.value);
            tmp = a1;
            tmpu.value = tmp.value;
            *this = tmpu;
        } 
	else if ((O_MODE==SC_WRAP && (I1<I || (W1>W && W1-I1>W-I))) || 
		 (O_MODE==SC_SAT_ZERO && I1<=I)) 
	{
            // Note: This is the general case code. It works for all cases, but
	    // is more register-intensive than the following else branch, so it
	    // is only used for those cases that it is needed. 
	   
            cynw_fixed<W+1,I+1,Q_MODE,O_MODE,N_BITS> tmp;
            tmp = a;
            if ((O_MODE==SC_SAT || O_MODE==SC_SAT_SYM || O_MODE==SC_SAT_ZERO) 
		&& tmp.value[W]==1)
                value = 0;
            else
                value = tmp.value;
          } 
  	  else 
	  {
              // Note: This code works for all of the other cases, and 
	      // synthsizes more efficiently. 

              cynw_ufixed<W1,I1,SC_TRN,SC_WRAP,0> tmp;
              tmp.value = a.value;
	     
              // Handle underflow

              if( (O_MODE==SC_SAT || O_MODE==SC_SAT_SYM))
              {
                  if( a.value[W1-1] )
                      tmp.value = 0;
              }
              *this = tmp;
          }
      }

      cynw_ufixed(int a) 
      {
          cynw_fixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,SC_TRN,SC_WRAP,0> tmp;
      
          // Handle underflow
          
	  tmp.value = a;
          if( (O_MODE==SC_SAT || O_MODE==SC_SAT_SYM || O_MODE==SC_SAT_ZERO) )
          {
              if( a < 0 )
                  tmp.value = 0;
          }
          *this = tmp;
      }

      cynw_ufixed(long a)
      {
          cynw_fixed<CYNW_BITS_PER_LONG,CYNW_BITS_PER_LONG,SC_TRN,SC_WRAP,0> 
	      tmp;
          // Handle underflow
          tmp.value = a;
          if( (O_MODE==SC_SAT || O_MODE==SC_SAT_SYM || O_MODE==SC_SAT_ZERO) )
          {
              if( a < 0 )
                  tmp.value = 0;
          }
          *this = tmp;
      }

      cynw_ufixed(long long a) 
      {
          cynw_fixed<CYNW_BITS_PER_LONGLONG,CYNW_BITS_PER_LONGLONG,SC_TRN,
	              SC_WRAP,0> tmp;
          // Handle underflow
          tmp.value = a;
          if( (O_MODE==SC_SAT || O_MODE==SC_SAT_SYM || O_MODE==SC_SAT_ZERO) )
          {
              if( a < 0 )
                  tmp.value = 0;
          }
          *this = tmp;
      }

      cynw_ufixed(unsigned int a) 
      {
          cynw_ufixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,SC_TRN,SC_WRAP,0> tmp;
          tmp.value = a;
          *this = tmp;
      }

      cynw_ufixed(unsigned long a) 
      {
	  *this = (sc_uint<CYNW_BITS_PER_LONG>)a;
      }

      cynw_ufixed(unsigned long long a) 
      {
	  *this = (sc_uint<CYNW_BITS_PER_LONGLONG>)a;
      }

      cynw_ufixed(double a) 
      {
	  /* Note: convert double to a cynw_fixed, and then let 
	   *       assignment do the rounding and overflow.
	   */
	  cynw_fixed<W+1,I+1,Q_MODE,O_MODE,N_BITS==0?0:N_BITS+1> tmpf(a);
	  cynw_ufixed<W+1,I+1> tmpu = tmpf;
	  if( (O_MODE==SC_SAT || O_MODE==SC_SAT_SYM || O_MODE==SC_SAT_ZERO) )
	  {   // Handle underflow
	      if( tmpf.value[W] )
		  tmpu.value = 0;
	  }
	  *this = tmpu;
      }

      template<int WW>
      cynw_ufixed(const sc_int<WW> & a) 
      {
	  // Handle underflow
	  cynw_fixed<WW,WW> tmp;
	  tmp.value = a;
	  if( (O_MODE==SC_SAT || O_MODE==SC_SAT_SYM || O_MODE==SC_SAT_ZERO) )
	  {
	      if( a[WW-1] )
		  tmp.value = 0;
          }
          *this = tmp;
      }

      template<int WW>
      cynw_ufixed(const sc_uint<WW> & a) 
      {
          cynw_ufixed<WW,WW,SC_TRN,SC_WRAP,0> tmp;
          tmp.value = a;
          *this = tmp;
      }

      template<int WW>
      cynw_ufixed(const sc_bigint<WW> & a) 
      {
          cynw_fixed<WW,WW,SC_TRN,SC_WRAP,0> tmp;
          tmp.value = a;
          // Handle underflow
          if( (O_MODE==SC_SAT || O_MODE==SC_SAT_SYM || O_MODE==SC_SAT_ZERO) )
          {
              if( a[WW-1] )
                  tmp.value = 0;
          }
          *this = tmp;
      }

      template<int WW>
      cynw_ufixed(const sc_biguint<WW> & a) 
      {
          cynw_ufixed<CYNW_MIN(W,WW),CYNW_MIN(W,WW),SC_TRN,SC_WRAP,0> tmp;
          tmp.value = a;
          *this = tmp;
      }

      cynw_ufixed() {
          value = 0;
      }

      // Destructor
      ~cynw_ufixed() { }
  
      // width methods:

      int iwl() const { return I; }
      int wl() const  { return W; }
  
    // DEBUGGING METHODS THAT ARE NOT SYNTHESIZABLE:

#ifndef STRATUS_HLS
    const std::string to_string( sc_numrep nr, bool prefix, 
                                 sc_fmt fmt ) const
    {
        static std::string val;
        cynw_fixed<W+1,I+1,Q_MODE,O_MODE,N_BITS> tmp = *this;
        val = tmp.to_string(nr, prefix, fmt);
        return val;
    }


    const std::string to_bin() const
    {
        return to_string( SC_BIN, true, SC_F );
    }
    const std::string to_dec() const
    {
        return to_string( SC_DEC, 0, SC_F );
    }
    const std::string to_hex() const
    {
        return to_string( SC_HEX, -1, SC_F );
    }
    const std::string to_oct() const
    {
        return to_string( SC_OCT, true, SC_F );
    }
    const std::string to_string() const
    {
        return to_string(SC_DEC, false, SC_F);
    }
    
    const std::string to_string(sc_numrep nr) const
    {
        return to_string(nr, (nr!=SC_DEC), SC_F);
    }
    
    const std::string to_string(sc_numrep nr, bool prefix) const
    {
        return to_string(nr, prefix, SC_F);
    }
    
    const std::string to_string(sc_fmt fmt) const
    {
        return to_string(SC_DEC, false, fmt);
    }
    
    const std::string to_string(sc_numrep nr, sc_fmt fmt) const
    {
        return to_string(nr, true, fmt);
    }
    
  void print( ostream& os ) const
  {
	print( os, sc_io_base(os, SC_DEC) );
  }
  void print( ostream& os, sc_numrep base ) const
  {
	switch( base ) {
	  case SC_BIN: os << this->to_bin().c_str(); break;
	  default:
	  case SC_DEC: os << this->to_dec().c_str(); break;
	  case SC_HEX: os << this->to_hex().c_str(); break;
	  case SC_OCT: os << this->to_oct().c_str(); break;
        }
    }

    void dump( ostream& cout ) const
    {
        cout << "value  = " << to_string(SC_HEX) << endl;
        cout << "wl     = " << W << endl;
        cout << "iwl    = " << I << endl;
        cout << "q_mode = " ;
        switch( Q_MODE )
        {
          case SC_TRN: cout << "SC_TRN"; break;
          case SC_RND: cout << "SC_RND"; break;
          case SC_RND_INF: cout << "SC_RND_INF"; break;
        }
        cout << endl;
        cout << "o_mode = ";
        switch( O_MODE )
        {
          case SC_WRAP: cout << "SC_WRAP"; break;
          case SC_SAT: cout << "SC_SAT"; break;
          case SC_SAT_SYM: cout << "SC_SAT_SYM"; break;
        }
        cout << endl;
        cout << "n_bits = 0" << endl;
    }
    
#endif //STRATUS_HLS

// NCSC VALUE ACCESS METHODS:

#if defined(NC_SYSTEMC)
    const char* ncsc_print() const                          
    { 
        std::ostringstream ostr;
        print(ostr); 
	return ostr.str().c_str();
    }
    const char* ncsc_print_r( sc_numrep r ) const
    { 
        std::ostringstream ostr;
        print(ostr, r); 
	return ostr.str().c_str();
    }
#endif // defined(NC_SYSTEMC)

    // +------------------------------------------------------------------------
    // |"cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>::round"
    // | 
    // | This method determines whether this object instance's value should
    // | be incremented based on the supplied rounding information, and performs
    // | the increment if needed.
    // |
    // | Arguments:
    // |     lR = least significant remaining bit.
    // |     mD = most significant deleted bit.
    // |     r  = logical or of the deleted bits except mD.
    // | Result is 1 if should increment, 0 if not.
    // +------------------------------------------------------------------------
    void round( const sc_uint<1>& lR, const sc_uint<1>& mD, 
                const sc_uint<1>& r )
    {
	switch( Q_MODE )
	{
	    // SC_RND: Add the most significant deleted bit to the remaining 
	    //         bits.
	    case SC_RND:
		value += mD;
		break;


	    // SC_RND_INF: Add the most significant deleted bit to the result.

	    case SC_RND_INF:
		value += mD;
		break;

	    // SC_RND_CONV: If the most significant deleted bit is 1 and either
	    //              the least significant of the remaining bits or at 
	    //              least one other deleted bit is 1, add 1 to the 
	    //              remaining bits.

	    case SC_RND_CONV:
		value += (sc_uint<1>)(mD & (lR | r ));
		break;

	    // The rules below are not supposed to have an effect per the 2011
	    // IEEE 1666 standard, but they do in SystemC 2.2 and below, so
	    // they are turned on for the moment.
#if 1
	    case SC_RND_ZERO:
		value += (sc_uint<1>)(mD & r);
		break;

	    case SC_RND_MIN_INF :
		value += (sc_uint<1>)(mD & r);
		break;
#endif

	    default: // SC_TRN, SC_TRN_ZERO
	        break;
	}
    }

    // cynw_ufixed OPERATOR = OVERLOADS:
  
    const this_type & operator = (const int& i) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
        return *this;
    }

    const this_type & operator = (const unsigned int& i) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
        return *this;
    }

    const this_type & operator = (const double& i) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
        return *this;
    }

    const this_type & operator = (const long& i) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
        return *this;
    }

    const this_type & operator = (const long long& i) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
        return *this;
    }

    const this_type & operator = (const unsigned long& i) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
        return *this;
    }

    const this_type & operator = (const unsigned long long& i) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
        return *this;
    }

    template<int WW>
    const this_type & operator = (const sc_int<WW>& i) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
        return *this;
    }

    template<int WW>
    const this_type & operator = (const sc_uint<WW>& i) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
        return *this;
    }

    template<int WW>
    const this_type & operator = (const sc_bigint<WW>& i) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
        return *this;
    }

    template<int WW>
    const this_type & operator = (const sc_biguint<WW>& i) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(i);
        return *this;
    }

    template<int W1, int I1, sc_q_mode Q1, sc_o_mode O1, int N1>
    const this_type & operator = (const cynw_ufixed<W1,I1,Q1,O1,N1>& a) 
    {
#if RND_SAT_OPTIM_U
        sc_uint<1> at_umaxpos = 0;
#endif
        if((W-I)==(W1-I1))
            value = a.value;
        else if((W-I)>(W1-I1))
            value = (CYNW_UVAL(W))(a.value)<<(((W-I)-(W1-I1))<0 ? 0 : ((W-I)-(W1-I1)));
        else 
	{
            sc_uint<1> rndbit;
            sc_uint<1> mD = (W1-I1)-(W-I)>W1 ? (sc_uint<1>)0 : (sc_uint<1>)a.value[(W1-I1)-(W-I)-1];
            sc_uint<1> lR = (W1-I1)-(W-I)>=W1 ? (sc_uint<1>)0 : (sc_uint<1>)a.value[(W1-I1)-(W-I)];
            sc_uint<1> r = (((W1-I1)-(W-I) == 1) || ((W1-I1)-(W-I) > W1)) ? 0 : a.value((W1-I1)-(W-I)-2,0)!=0;
            (((W1-I1)-(W-I))>W1) ? value = 0 : 
	    value = (a.value)>>(CYNW_MAX(0,(W1-I1)-(W-I)));
  
            if(Q_MODE==SC_TRN || Q_MODE==SC_TRN_ZERO) 
                rndbit = 0;                                       // 0
            if(Q_MODE==SC_RND || Q_MODE==SC_RND_INF) 
                rndbit = mD;                                      // mD
            else if (Q_MODE==SC_RND_MIN_INF || Q_MODE==SC_RND_ZERO) // mD & r
	    {
                rndbit = mD & r;
            } 
	    else if (Q_MODE==SC_RND_CONV) // mD & (lR | r)
	    {
                rndbit = mD & (lR | r);
            } 
#if RND_SAT_OPTIM_U
            at_umaxpos = (value==CYNW_UMAXPOS);
            if (O_MODE==SC_WRAP || O_MODE==SC_WRAP_SM || O_MODE==SC_SAT_ZERO ||
		(O_MODE==SC_SAT || O_MODE==SC_SAT_SYM) || !at_umaxpos) 
	    {
                //value += rndbit;
                if (rndbit)
                  value++;
            }
#else
            if (O_MODE==SC_WRAP || O_MODE==SC_WRAP_SM || O_MODE==SC_SAT_ZERO ||
                value!=CYNW_UMAXPOS) 
	    {
                if (rndbit) 
                    value++;
            }
#endif
        }
        
        // Handle the Overflow mode
        if((O_MODE==SC_SAT || O_MODE==SC_SAT_SYM) && I1>I)
        {
#if RND_SAT_OPTIM_U
            if ( a.value(W1-1,W1-(CYNW_MIN(I1-I,W1))).or_reduce() || at_umaxpos)
#else
            if ( a.value(W1-1,W1-(CYNW_MIN(I1-I,W1))).or_reduce() ) 
#endif
                value = CYNW_UMAXPOS;
        }  
        else if(O_MODE==SC_SAT_ZERO && I1>I) 
        {
            if ( a.value(W1-1,W1-(CYNW_MIN(I1-I,W1))).or_reduce() )
                value = 0;
        } 
        else if (O_MODE==SC_WRAP && N_BITS>0 && I1>I) 
        {
            if ( a.value(W1-1,W1-(CYNW_MIN(I1-I,W1))).or_reduce() )
                value = ((sc_uint<N_BITS>)~0, 
		               (sc_uint<W-N_BITS>)value(W-N_BITS-1,0));
        }
        return *this;
    }

    template<int W1, int I1, sc_q_mode Q1, sc_o_mode O1, int N1>
    const this_type & operator = (const cynw_fixed<W1,I1,Q1,O1,N1> & a) 
    {
        *this = cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>(a);
        return *this;
    }

    // METHODS THAT ARE REQUIRED BY THE sc_dt::sc_generic_base CLASS:

    inline int to_int() const
    {
        sc_int<32> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
        res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }
    inline int64 to_int64() const
    {
        sc_int<64> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }
   inline long to_long() const
    {
        sc_int<64> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }
    inline void to_sc_signed(sc_signed& result) const
    {
        if (W>I) 
            result = value >> ((W-I>0) ? (W-I) : 0); 
        else
            result = value << ((W-I>0) ? 0 : (I-W)); 
    }
    inline void to_sc_unsigned(sc_unsigned& result) const
    {
        if (W>I) 
            result = value >> ((W-I>0) ? (W-I) : 0); 
        else
            result = value << ((W-I>0) ? 0 : (I-W)); 
    }
    inline unsigned int to_uint() const
    {
            sc_uint<32> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }
    inline uint64 to_uint64() const
    {
        sc_uint<64> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }
    inline unsigned long to_ulong() const
    {
	sc_uint<64> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }

    // CASTS THAT ARE NECESSARY IF sc_dt::sc_generic_base IS NOT USED AS A BASE
    // CLASS

#if !CYNW_FIXED_GENERIC_BASE
    template<int WW>
    operator sc_int<WW> () const 
    {
        sc_int<WW> res;
        if (W>I) 
            res = value >> ((W-I>0) ? (W-I) : 0); 
	else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }
     
    template<int WW>
    operator sc_bigint<WW> () const 
    {
         sc_bigint<WW> res;
         if (W>I) 
            res = value >> W-I; 
         else
            res = value << I-W; 
         return res;
    }

    template<int WW>
    operator sc_uint<WW> () const 
    {
        sc_uint<WW> res;
        if (W>I)
            res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }

    template<int WW>
    operator sc_biguint<WW> () const 
    {
        sc_biguint<WW> res;
        if (W>I) 
           res = value >> ((W-I>0) ? (W-I) : 0); 
        else
            res = value << ((W-I>0) ? 0 : (I-W)); 
        return res;
    }
#endif // CYNW_FIXED_GENERIC_BASE

#if !defined(CYNW_FIXED_NO_DOUBLE_CAST)
    operator double() const
    {
        return to_double();
    }
#endif // defined(CYNW_FIXED_NO_DOUBLE_CAST)

#ifndef STRATUS_HLS
    double to_double () const 
    {
        double res;
        if (W==I)
            res = value.to_double();
        else
        if (W>I)
            res = (value.to_double()) / pow(2.0,(W-I));
        else
            res = (value.to_double()) * pow(2.0,(I-W));
        return res;
    }
#else
    sc_int<CYNW_BITS_PER_DOUBLE> to_double() const 
    {
        HLS_MESSAGE(2844);
	return 0;
    }
#endif // STRATUS_HLS

    // +------------------------------------------------------------------------
    // | cynw_ufixed UNARY ARITHMETIC OPERATORS:
    // +------------------------------------------------------------------------

    cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> operator ++ () 
    {
        *this = *this + (sc_uint<1>)1;
        return *this;
    }

    cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> operator ++ (int) 
    {
        cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> res = *this;
        *this = *this + (sc_uint<1>)1;
        return res;
    }
  
    cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> operator + () const 
    {
        return *this;
    }
  
    cynw_fixed<W+1,I+1,Q_MODE,O_MODE,N_BITS> operator - () const 
    {
        cynw_fixed<W+1,I+1,Q_MODE,O_MODE,N_BITS> res = *this;
        res.value = -(res.value);
        return res;
    }
  
    cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> operator -- () 
    {
        *this = *this - (sc_uint<1>)1;
        return *this;
    }
  
    cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> operator -- (int) 
    {
        cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> res = *this;
        *this = *this - (sc_uint<1>)1;
        return res;
    }
  
    cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> operator ~ () const 
    {
        cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> res;
        res.value = ~value;
        return res;
    }
  
// +----------------------------------------------------------------------------
// |"cynw_ufixed<...>::operator <<"
// | 
// | This operator implements the left shift operator on this object instance.
// | instance. CYNW_FX_LS_SIZE controls the size of the result of the shift 
// | operation, by default it is W, the size of this object instance. 
// |
// | Arguments:
// |     shift = amount to left shift this object instance's value by.
// | A cynw_fixed<...> instance containing the shifte value.
// +----------------------------------------------------------------------------
template<class SHIFT>
cynw_ufixed<CYNW_FX_LS_SIZE,I+CYNW_FX_LS_SIZE-W,Q_MODE,O_MODE,N_BITS> 
operator << ( const SHIFT& shift ) const 
{
    int                                                             ishift;
    cynw_ufixed<CYNW_FX_LS_SIZE,I+CYNW_FX_LS_SIZE-W,Q_MODE,O_MODE,N_BITS> res;

    ishift = shift;

    // Negative shift factors are ignored, except that a behavioral mode
    // message will be issued.
    
    if ( ishift <= 0) 
    {
#       if !defined(CYNHTHL) && !defined(CYNW_FX_NO_SHIFT_WARNING)
	    if ( ishift < 0 )
	    {
		cout << "Warning!!!! cynw_ufixed<" << W << "," << I << ","
		     << Q_MODE << "," << O_MODE << "," << N_BITS << "> "
		     << " << " << shift << " will be ignored since the shift "
		     << " factor is negative " << endl;
	    }
#       endif
        res.value = value;
    } 

    else 
    {
	res.value = CYNW_UARG(CYNW_FX_LS_SIZE)(value) << ishift; 

	// If the shift size is larger than the hardware implementation
	// shift factor can hold set it to that maximum. In behavioral mode 
	// complain.
	
	if ( ishift > CYNW_FX_LS_SIZE )
	{
#           if !defined(STRATUS_HLS) && !defined(CYNW_FX_NO_SHIFT_WARNING)
	        cout << "WARNING: For expression " << endl
		     << "    "
		     << CYNW_FX_NAME(cynw_ufixed,W,I,Q_MODE,O_MODE,N_BITS)
		     << " << " << shift << endl 
		     << "  shift value " << ishift << " > " 
		     << CYNW_FX_LS_SIZE
		     << " so all bits will be shifted off the top "
		     << endl;
#           endif
	    ishift = CYNW_FX_LS_SIZE;
	}

	// WRAP MODE: 
	
	if (O_MODE==SC_WRAP )
	{
	    if (ishift >=CYNW_FX_LS_SIZE)
	         res.value = 0;
	    else
		 res.value = CYNW_UARG(CYNW_FX_LS_SIZE)(value) << ishift;
	}

	// SATURATION AND SYMMETRIC SATURATION MODE: 
	// 
	// In the case of overflow the remaining bits shall be set to 1 
	// (overflow) or 0 (underflow). What is an underflow in this case?

	else if ( O_MODE == SC_SAT || O_MODE == SC_SAT_SYM )
	{
	     int lost_bits = (ishift+W) - CYNW_FX_LS_SIZE;
	     if ( lost_bits > 0 && (lost_bits >= W ? value.or_reduce() :
					value(W-1,W-lost_bits).or_reduce() ) ) {
		 res.value = (~(CYNW_UVAL(CYNW_FX_LS_SIZE))0);
	     } 
	     else {
		 res.value = CYNW_UARG(CYNW_FX_LS_SIZE)(value) << ishift;
	     }
	}

	// ZERO SATURATION MODE: if there is a loss of precision set the
	// result to zero.
       
	else if ( O_MODE==SC_SAT_ZERO ) 
	{
	     int lost_bits = (ishift+W) - CYNW_FX_LS_SIZE;
	     if ( lost_bits > 0 && (lost_bits >= W ? value.or_reduce() :
					value(W-1,W-lost_bits).or_reduce() ) ) {
		res.value = 0;
	    }
	    else
	    {
		 res.value = CYNW_UARG(CYNW_FX_LS_SIZE)(value) << ishift;
	    }
	}

	// NO SATURATION TO BE PERFORMED:
	//
	// There was no overflow or this is a mode that just assigns the value.

	else
	{
	    res.value = CYNW_UARG(CYNW_FX_LS_SIZE)(value) << ishift;
	}
    }
    return res;
}

template<typename SHIFT>
cynw_ufixed<W,I,Q_MODE,CYNW_RES_O_MODE,N_BITS> operator <<= (const SHIFT& b)
{
    *this = *this << b;
    return *this;
}
  
// +----------------------------------------------------------------------------
// |"cynw_ufixed<...>::operator >>"
// | 
// | This operator implements the right shift operator on this object instance.
// | instance. 
// |
// | Arguments:
// |     shift = amount to left shift this object instance's value by.
// | A cynw_ufixed<...> instance containing the shifted result.
// +----------------------------------------------------------------------------
template<typename SHIFT>
cynw_ufixed<CYNW_FX_RS_SIZE,I,Q_MODE,CYNW_RES_O_MODE, N_BITS> 
operator >> ( const SHIFT& shift ) const 
{
    int                                                        ishift;
    cynw_ufixed<CYNW_FX_RS_SIZE,I,Q_MODE,CYNW_RES_O_MODE, N_BITS> res;

    ishift = shift;

    // SHIFT FACTOR IS NOT POSITIVE:
    //
    // Copy the bits as is, and in behavioral mode produce a warning.

    if ( ishift <= 0 )
    {
#       if !defined(CYNHTHL) && !defined(CYNW_FX_NO_SHIFT_WARNING)
	    if ( ishift < 0 )
	    {
		cout << "Warning!!!! cynw_ufixed<" << W << "," << I << ","
		     << Q_MODE << "," << O_MODE << "," << N_BITS << "> "
		     << " >> " << shift << " will be ignored since the shift "
		     << " factor is negative " << endl;
	    }
#       endif
	res.value = value << (CYNW_FX_RS_SIZE-W);
    }

    // SHIFT FACTOR WILL SHIFT OUT ALL THE BITS IN THE TARGET
    // 
    // The result will be zero.

    else if ( ishift > CYNW_FX_RS_SIZE ) 
    {
	res.value = 0;
    } 

    // SHIFT FACTOR IS > 0 AND <= THE TARGET WIDTH:
    //
    // Set the value based on one of three cases:
    // (a) If the result width is larger than the original target do the 
    //     appropriate adjustment before performing the shift.
    // (b) If our target value is implemented as a native SystemC type
    //     account for the fact we can't handle a shift by 64.
    // (c) Otherwise just do the shift.
    //
    // Perform rounding if that is requested.
    
    else 
    {
	if ( CYNW_FX_RS_SIZE > W )
	{
	    res.value = (value,CYNW_UVAL(CYNW_FX_RS_SIZE-W)(0)); 
	    res.value = (res.value) >> ishift;
	}
	else if ( CYNW_FX_RS_SIZE <= 64 && ishift == 64 )
	{
	    res.value = 0;
	}
	else
	{
	    res.value = value >> ishift; 
	}
	if ( CYNW_FX_RS_ROUND ) 
	{
	    res.round( (sc_uint<1>)res.value[0], (sc_uint<1>)value[ishift-1],
		       ishift == 1 ? 0 : value(ishift-2,0).or_reduce() );
	}
    }

    return res;
}

template<typename SHIFT>
cynw_ufixed<W,I,Q_MODE,CYNW_RES_O_MODE,N_BITS> operator >>= (const SHIFT& shift)
{
    *this = *this >> shift;
    return *this;
}
  
    // +------------------------------------------------------------------------
    // | cynw_ufixed LOGICAL OPERATORS:
    // +------------------------------------------------------------------------

    template<int W1, int I1, sc_q_mode Q1, sc_o_mode O1, int N1>
    cynw_ufixed<CYNW_RES_W,CYNW_RES_I,Q_MODE,O_MODE,N_BITS> 
    operator | (const cynw_ufixed<W1,I1,Q1,O1,N1> & b) const 
    {
        cynw_ufixed<CYNW_RES_W,CYNW_RES_I,Q_MODE,O_MODE,N_BITS> res;
        if((W-I)==(W1-I1)) 
	{
            res.value = CYNW_UARG(CYNW_RES_W)value | (b.value);
        } 
	else if ((W-I)>(W1-I1)) 
	{
            res.value = CYNW_UARG(CYNW_RES_W)(b.value) << (((W-I)-(W1-I1))<0 ? 
		                      0 : ((W-I)-(W1-I1)));
            res.value = (res.value) | value;
        } 
	else 
	{
            res.value = CYNW_UARG(CYNW_RES_W)value << (((W1-I1)-(W-I))<0 ? 
		                      0 : ((W1-I1)-(W-I)));
            res.value = (res.value) | (b.value);
        }
        return res;
    }

    template<int W1, int I1, sc_q_mode Q1, sc_o_mode O1, int N1>
    cynw_ufixed<CYNW_RES_W,CYNW_RES_I,Q_MODE,O_MODE,N_BITS> 
    operator & (const cynw_ufixed<W1,I1,Q1,O1,N1> & b) const 
    {
        cynw_ufixed<CYNW_RES_W,CYNW_RES_I,Q_MODE,O_MODE,N_BITS> res;
        if((W-I)==(W1-I1)) 
	{
            res.value = CYNW_UARG(CYNW_RES_W)value & (b.value);
        } 
	else if ((W-I)>(W1-I1)) 
	{
            res.value = CYNW_UARG(CYNW_RES_W)(b.value) << (((W-I)-(W1-I1))<0 ? 
		                        0 : ((W-I)-(W1-I1)));
            res.value = (res.value) & value;
        } 
	else 
	{
            res.value = CYNW_UARG(CYNW_RES_W)value << (((W1-I1)-(W-I))<0 ? 
		                        0 : ((W1-I1)-(W-I)));
            res.value = (res.value) & (b.value);
        }
        return res;
    }

    template<int W1, int I1, sc_q_mode Q1, sc_o_mode O1, int N1>
    cynw_ufixed<CYNW_RES_W,CYNW_RES_I,Q_MODE,O_MODE,N_BITS> 
    operator ^ (const cynw_ufixed<W1,I1,Q1,O1,N1> & b) const 
    {
        cynw_ufixed<CYNW_RES_W,CYNW_RES_I,Q_MODE,O_MODE,N_BITS> res;
        if((W-I)==(W1-I1)) 
	{
            res.value = CYNW_UARG(CYNW_RES_W)value ^ (b.value);
        } 
	else if ((W-I)>(W1-I1)) 
	{
            res.value = CYNW_UARG(CYNW_RES_W)(b.value) << (((W-I)-(W1-I1))<0 ? 
		                         0 : ((W-I)-(W1-I1)));
            res.value = (res.value) ^ value;
        } 
	else 
	{
            res.value = CYNW_UARG(CYNW_RES_W)value << (((W1-I1)-(W-I))<0 ? 
		                        0 : ((W1-I1)-(W-I)));
            res.value = (res.value) ^ (b.value);
        }
        return res;
    }

    // +------------------------------------------------------------------------
    // | cynw_ufixed OPERATORS EQUAL OPERATORS:
    // +------------------------------------------------------------------------

    template<typename OTHER>
    void operator += (const OTHER & b) 
    {
        *this = *this + b;
    }

    template<typename OTHER>
    void operator -= (const OTHER & b) 
    {
        *this = *this - b;
    }
  
    template<typename OTHER>
    void operator *= (const OTHER & b) 
    {
        *this = *this * b;
    }
  
    template<typename OTHER>
    void operator /= (const OTHER & b) 
    {
        *this = *this / b;
    }
  
    template<const int W1, const int I1, const sc_q_mode Q1, const sc_o_mode O1,
             const int N1>
    void operator &= (const cynw_ufixed<W1,I1,Q1,O1,N1> & b) 
    {
        cynw_ufixed<W,I> res;
        res = *this & b;
        value = res.value;
    }
  
    template<const int W1, const int I1, const sc_q_mode Q1, const sc_o_mode O1,
             const int N1>
    void operator |= (const cynw_ufixed<W1,I1,Q1,O1,N1> & b) 
    {
        cynw_ufixed<W,I> res;
        res = *this | b;
        value = res.value;
    }
  
    template<const int W1, const int I1, const sc_q_mode Q1, const sc_o_mode O1,
             const int N1>
    void operator ^= (const cynw_ufixed<W1,I1,Q1,O1,N1> & b) 
    {
        cynw_ufixed<W,I> res;
        res = *this ^ b;
        value = res.value;
    }
  
    // +------------------------------------------------------------------------
    // | cynw_fixed SELECTION (RANGE) OPERATORS:
    // +------------------------------------------------------------------------

    cynw_ufixed_subref_r<W,O_MODE> operator () () const 
    {
        return cynw_ufixed_subref_r<W,O_MODE>(value,W-1,0);
    }
  
    cynw_ufixed_subref<W,O_MODE> operator () () 
    {
        return cynw_ufixed_subref<W,O_MODE>(value,W-1,0);
    }
  
    cynw_ufixed_subref_r<W,O_MODE> operator () (int a, int b) const 
    {
        return cynw_ufixed_subref_r<W,O_MODE>(value,a,b);
    }
  
    cynw_ufixed_subref_r<W,O_MODE> range(int a, int b) const 
    {
        return cynw_ufixed_subref_r<W,O_MODE>(value,a,b);
    }
  
    cynw_ufixed_subref<W,O_MODE> operator () (int a, int b) 
    {
        return cynw_ufixed_subref<W,O_MODE>(value,a,b);
    }
  
    cynw_ufixed_subref<W,O_MODE> range(int a, int b) 
    {
        return cynw_ufixed_subref<W,O_MODE>(value,a,b);
    }
  
    cynw_ufixed_subref_r<W,O_MODE> range() const 
    {
        return cynw_ufixed_subref_r<W,O_MODE>(value,W-1,0);
    }
  
    cynw_ufixed_subref<W,O_MODE> range() 
    {
        return cynw_ufixed_subref<W,O_MODE>(value,W-1,0);
    }
  
    cynw_ufixed_subref<W,O_MODE> operator [] (const int a) 
    {
        return cynw_ufixed_subref<W,O_MODE>(value,a,a);
    }
  
    // +------------------------------------------------------------------------
    // | cynw_ufixed PUBLIC METHODS:
    // +------------------------------------------------------------------------

#ifdef STRATUS_HLS
    float rawBitsTofloat(int pi);
    int floatToRawBits(float pf);
    double rawBitsTodouble(long pi);
    long long doubleToRawBits(double pf);
#else 
  
    float rawBitsTofloat(int pi) 
    {
        union { float f; int i; } x;
        x.i = pi;
        return x.f;
    } 
    
    int floatToRawBits(float pf) 
    {
        union { float f; int i; } x;
        x.f = pf;
        return x.i;
    } 
  
    double rawBitsTodouble(long long pi) 
    {
        union { double d; long long ll; } x;
        x.ll = pi;
        return x.d;
    } 
    
    long long doubleToRawBits(double pf) 
    {
        union { double d; long long ll; } x;
        x.d = pf;
        return x.ll;
    } 
#endif


    // +------------------------------------------------------------------------
    // | cynw_fixed DATA STORAGE:
    // +------------------------------------------------------------------------

    CYNW_UVAL(W) value;
  protected:  
};


// +------------------------------------------------------------------------------------------------
// |"cwfx_convert_double"
// | 
// | This function converts the supplied double value to a cynw_fixed<CYNW_FX_DW,CYNW_FX_IW> object
// | instance.
// |
// | Arguments:
// |     dbl = value to be converted
// | Result:
// |     cynw_fixed<CYNW_FX_DW,CYNW_FX_IW> representing 'dbl' as a fixed point number.
// +------------------------------------------------------------------------------------------------
inline cynw_fixed<CYNW_FX_DW,CYNW_FX_IW> cwfx_convert_double( double dbl )
{
    cynw_fixed<CYNW_FX_DW,CYNW_FX_IW> result(dbl);

#   if !defined(STRATUS_HLS)
        double resDouble = (double)0x7fffffffLL;
        if ( dbl > resDouble ) {
	    std::cout << "cwfx_convert_double - double is too large to represent " << std::endl;
	    std::cout << " source   " << dbl << std::endl;
	    std::cout << " max size " << resDouble << std::endl;
	}
        // std::cout << dbl << " -> " << resDouble << std::endl;
#   else
	HLS_MESSAGE(2980);
#   endif
    return result;
}

#define CYNW_FIXED_COMPARE(OP) \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, \
                          const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )  \
{ \
    return (left.value) OP (right.value); \
} \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, \
       int W1, int I1, sc_q_mode Q_MODE1, sc_o_mode O_MODE1, int N_BITS1> \
inline bool operator OP ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, \
                       const cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right)  \
{ \
    if(I<I1)  \
    { \
	if ( (W-I) < (W1-I1) ) /* use right's size. */ \
	{ \
            cynw_fixed<W1,I1,Q_MODE,O_MODE,N_BITS> temp; \
            temp = left; \
            return (temp.value) OP (right.value); \
	} \
	else /* use right's int and left's fraction */ \
	{ \
            cynw_fixed<I1+(W-I),I1> temp_left; \
            cynw_fixed<I1+(W-I),I1> temp_right; \
	    temp_left = left; \
	    temp_right = right; \
	    return (temp_left.value) OP (temp_right.value); \
	} \
    }  \
    else  \
    { \
	if ( (W-I) > (W1-I1) ) /* use left's size. */ \
	{ \
            cynw_fixed<W,I,Q_MODE1,O_MODE1,N_BITS1> temp; \
            temp = right; \
            return (left.value) OP (temp.value); \
	} \
	else /* use left's int and right's fraction */ \
	{ \
            cynw_fixed<I+(W1-I1),I> temp_left; \
            cynw_fixed<I+(W1-I1),I> temp_right; \
	    temp_left = left; \
	    temp_right = right; \
	    return (temp_left.value) OP (temp_right.value); \
	} \
    } \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, \
       int W1, int I1, sc_q_mode Q_MODE1, sc_o_mode O_MODE1, int N_BITS1> \
inline bool operator OP ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, \
                      const cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) \
{ \
    cynw_fixed<W1+1,I1+1> temp(right); \
    return left OP temp; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, int WW> \
inline bool operator OP ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,  \
                      const sc_int<WW> & right )  \
{ \
    cynw_fixed<WW,WW> temp(right); \
    return left OP temp; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, int WW> \
inline bool operator OP ( const sc_int<WW> & left, \
                          const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right ) \
{ \
    cynw_fixed<WW,WW> temp(left); \
    return temp OP right; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, int WW> \
inline bool operator OP ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, \
                          const sc_uint<WW> & right )  \
{ \
    cynw_ufixed<WW,WW> temp(right); \
    return left OP temp; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, int WW> \
inline bool operator OP ( const sc_uint<WW> & left,  \
                          const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right ) \
{ \
    cynw_ufixed<WW,WW> temp(left); \
    return temp OP right; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,  \
                      const int & right )  \
{ \
    cynw_fixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT> temp(right); \
    return left OP temp; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const int & left,  \
                      const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right ) \
{ \
    cynw_fixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT> temp(left); \
    return temp OP right; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, \
                          const double & right)  \
{ \
    return left OP cwfx_convert_double(right); \
} \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const double & left,  \
                      const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right ) \
{ \
    return cwfx_convert_double(left) OP right; \
}
// +----------------------------------------------------------------------------
// |"cynw_fixed operator =="
// | 
// | These operator overloads implement equal comparison of cynw_fixed 
// | instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------
CYNW_FIXED_COMPARE(==)
  
// +----------------------------------------------------------------------------
// |"cynw_fixed operator !="
// | 
// | These operator overloads implement not equal comparison of cynw_fixed 
// | instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------
CYNW_FIXED_COMPARE(!=)
  
// +----------------------------------------------------------------------------
// |"cynw_fixed operator >"
// | 
// | These operator overloads implement greater than comparison of cynw_fixed 
// | instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------

CYNW_FIXED_COMPARE(>)
  
// +----------------------------------------------------------------------------
// |"cynw_fixed operator >="
// | 
// | These operator overloads implement less than or equal comparison of 
// | cynw_fixed instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------
CYNW_FIXED_COMPARE(>=)
  
// +----------------------------------------------------------------------------
// |"cynw_fixed operator <"
// | 
// | These operator overloads implement less than comparison of cynw_fixed 
// | instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------
CYNW_FIXED_COMPARE(<)
  
// +----------------------------------------------------------------------------
// |"cynw_fixed operator <="
// | 
// | These operator overloads implement less than or equal comparison of 
// | cynw_fixed instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------
CYNW_FIXED_COMPARE(<=)
  
// +----------------------------------------------------------------------------
// |"cynw_fixed operator +"
// | 
// | These operator overloads implement addition of cynw_fixed instances.
// |
// | Arguments:
// |     left  = left operand for the addition
// |     right = left operand for the addition
// | Result is cynw_fixed instance that is the result of the addition.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE2 
inline CWFX_ADD_SS(W,I,W1,I1) 
operator + ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_ADD_SS(W,I,W1,I1) res;
    if((W-I)==(W1-I1))
    {
      res.value = CYNW_IARG( CWFX_ADD_W(W,I,W1,I1) )(left.value) + 
                  CYNW_IARG( CWFX_ADD_W(W,I,W1,I1) )(right.value);
    }
    else if((W-I) > (W1-I1)) 
    {
#if 1
        res.value = (left.value) + CYNW_IVAL( CWFX_ADD_W(W,I,W1,I1) )(
	               CYNW_IVAL( CWFX_ADD_W(W,I,W1,I1) )(right.value) << 
                         ((W-I-W1+I1)<0 ? 0 : (W-I-W1+I1)) 
	            );
#else
        res.value = CYNW_IARG( CWFX_ADD_W(W,I,W1,I1) )(right.value) << 
                         ((W-I-W1+I1)<0 ? 0 : (W-I-W1+I1));
        res.value = (left.value) + (res.value);
#endif
    }
    else 
    {
        res.value = (CYNW_IARG( CWFX_ADD_W(W,I,W1,I1) )left.value) << 
			((W1-I1-W+I)<0 ? 0 : (W1-I1-W+I));
        res.value = (res.value) + (right.value);
    }

    return res;
}
  
CWFX_TEMPLATE2 
inline CWFX_ADD_SU(W,I,W1,I1)
operator + ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    cynw_fixed<W1+1,I1+1> temp(right);
    return left + temp;
}

CWFX_TEMPLATE_WW 
inline CWFX_ADD_SS(W,I,WW,WW)
operator + ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
             const sc_int<WW> & right ) 
{
    cynw_fixed<WW,WW> temp(right);
    return left + temp;
}

CWFX_TEMPLATE_WW 
inline CWFX_ADD_SS(WW,WW,W,I)
operator + ( const sc_int<WW> & left, 
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_fixed<WW,WW> temp(left);
    return temp + right;
}

CWFX_TEMPLATE_WW 
inline CWFX_ADD_SU(W,I,WW,WW)
operator + ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_uint<WW> & right ) 
{
    cynw_ufixed<WW,WW> temp(right);
    return left + temp;
}

CWFX_TEMPLATE_WW 
inline CWFX_ADD_US(WW,WW,W,I)
operator + ( const sc_uint<WW> & left, 
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_ufixed<WW,WW> temp(left);
    return temp + right;
}

CWFX_TEMPLATE 
inline CWFX_ADD_SS(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator + ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
             const int & right ) 
{
    sc_int<CYNW_BITS_PER_INT> temp(right);
    return left + temp;
}

CWFX_TEMPLATE 
inline CWFX_ADD_SS(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator + ( const int & left, 
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_int<CYNW_BITS_PER_INT> temp(left);
    return temp + right;
}

CWFX_TEMPLATE 
inline CWFX_ADD_SU(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator + ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
             const unsigned int & right ) 
{
    sc_uint<CYNW_BITS_PER_INT> temp(right);
    return left + temp;
}

CWFX_TEMPLATE 
inline CWFX_ADD_US(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator + (  const unsigned int & left, 
              const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_uint<CYNW_BITS_PER_INT> temp(left);
    return temp + right;
}

CWFX_TEMPLATE 
inline CWFX_ADD_SS(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator + ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
             const double & right) 
{
    return left + cwfx_convert_double(right);
}

CWFX_TEMPLATE 
inline CWFX_ADD_SS(CYNW_FX_DW,CYNW_FX_IW,W,I)
operator + ( const double & left, 
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return cwfx_convert_double(left) + right;
}

CWFX_TEMPLATE 
inline CWFX_ADD_SS(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator + ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
             const float & right) 
{
    return left + cwfx_convert_double(right);
}

CWFX_TEMPLATE 
inline CWFX_ADD_SS(W,I,W,I)
operator + ( const float & left, 
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return (double)left + right;
}
  
// +----------------------------------------------------------------------------
// |"cynw_fixed operator -"
// | 
// | These operator overloads implement subtraction of cynw_fixed instances.
// |
// | Arguments:
// |     left  = left operand for the subtraction
// |     right = left operand for the subtraction
// | Result is cynw_fixed instance that is the result of the subtraction.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE2
inline CWFX_SUB_SS(W,I,W1,I1)
operator - ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_SUB_SS(W,I,W1,I1) res;

    // Both sides have the same number of fraction bits:

    if((W-I)==(W1-I1))
    {
        res.value = CYNW_IVAL(CWFX_SUB_W(W,I,W1,I1) )(left.value) - (right.value);
    }

    // Left-hand side has more fraction bits, adjust the right-hand side:

    else if((W-I) > (W1-I1)) 
    {
        // res.value = left.value - (CYNW_IVAL( CWFX_SUB_W(W,I,W1,I1) ))(
        res.value = (left.value) - (CYNW_IVAL( CWFX_SUB_W(W,I,W1,I1) ))(
	               (CYNW_IVAL( CWFX_SUB_W(W,I,W1,I1) ))(right.value) << 
                       ((W-I-W1+I1)<0 ? 0 : (W-I-W1+I1))
	            );
    }

    // Right-hand side has more fraction bits, adjust the left-hand side:

    else 
    {
        res.value = (CYNW_IVAL( CWFX_SUB_W(W,I,W1,I1) ))(
	                (CYNW_IVAL( CWFX_SUB_W(W,I,W1,I1) ))(left.value) << 
			((W1-I1-W+I)<0 ? 0 : (W1-I1-W+I))
		    ) - (right.value);

    }
    return res;
}

CWFX_TEMPLATE2
inline CWFX_SUB_SU(W,I,W1,I1)
operator - ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_SUB_SU(W,I,W1,I1) res;

    // Both sides have the same number of fraction bits:

    if((W-I)==(W1-I1))
    {
	res.value = left.value;
        res.value = (res.value) - (right.value);
        // res.value = CYNW_IARG(CYNW_RES_W)left.value - right.value;
    }

    // Left-hand side has more fraction bits, adjust the right-hand side:

    else if((W-I) > (W1-I1)) 
    {
        res.value = (left.value) - 
        CYNW_IVAL(CWFX_SUB_W(W,I,W1,I1))((CYNW_IARG(CWFX_SUB_W(W,I,W1,I1))right.value) <<
            ((W-I-W1+I1)<0 ? 0 : (W-I-W1+I1)));
    }

    // Right-hand side has more fraction bits, adjust the left-hand side:

    else 
    {
        res.value = (CYNW_IVAL(CWFX_SUB_W(W,I,W1,I1)))(((CYNW_IVAL(CWFX_SUB_W(W,I,W1,I1)))(left.value)
        )<<((W1-I1-W+I)<0 ? 0 : (W1-I1-W+I))) - (right.value);

    }
    return res;
}

CWFX_TEMPLATE_WW
inline CWFX_SUB_SS(W,I,WW,WW)
operator - ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_int<WW> & right )  
{
    cynw_fixed<WW,WW> temp(right);

    return left - temp;
}

CWFX_TEMPLATE_WW
inline CWFX_SUB_SS(WW,WW,W,I)
operator - ( const sc_int<WW> & left, 
         const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_fixed<WW,WW> temp(left);

    return temp - right;
}

CWFX_TEMPLATE_WW
inline CWFX_SUB_SU(W,I,WW,WW)
operator - ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_uint<WW> & right ) 
{
    cynw_ufixed<WW,WW> temp(right);

    return left - temp;
}

CWFX_TEMPLATE_WW
inline CWFX_SUB_US(WW,WW,W,I)
operator - ( const sc_uint<WW> & left,
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_ufixed<WW,WW> temp(left);

    return temp - right;
}

CWFX_TEMPLATE
inline CWFX_SUB_SS(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator - ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const int & right ) 
{
    sc_int<CYNW_BITS_PER_INT> temp(right);
    
    return left - temp;
}

CWFX_TEMPLATE
inline CWFX_SUB_SS(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator - ( const int & left,
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_int<CYNW_BITS_PER_INT> temp(left);
    
    return temp - right;
}

CWFX_TEMPLATE
inline CWFX_SUB_SU(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator - ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const unsigned int & right ) 
{
    sc_uint<CYNW_BITS_PER_INT> temp(right);
    
    return left - temp;
}

CWFX_TEMPLATE
inline CWFX_SUB_US(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator - ( const unsigned int & left,
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_uint<CYNW_BITS_PER_INT> temp(left);
    
    return temp - right;
}

CWFX_TEMPLATE
inline CWFX_SUB_SS(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator - ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
             const double & right ) 
{
    return left - cwfx_convert_double(right);
}

CWFX_TEMPLATE
inline CWFX_SUB_SS(CYNW_FX_DW,CYNW_FX_IW,W,I)
operator - ( const double & left, 
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return cwfx_convert_double(left) - right;
}

CWFX_TEMPLATE
inline CWFX_SUB_SS(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator - ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
             const float & right ) 
{
    return left - cwfx_convert_double(right);
}

CWFX_TEMPLATE
inline CWFX_SUB_SS(W,I,W,I)
operator - ( const float & left, 
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return (double)left - right;
}

// +----------------------------------------------------------------------------
// |"cynw_fixed operator *"
// | 
// | These operator overloads implement multiplication of cynw_fixed instances.
// |
// | Notes:
// |   (1) For asymmetric multiplies consider using widths to guarantee the
// |       smaller operand stays small. This will require some experimentation
// |       since there is some QOR weirdness in the experiments I have run so
// |       far.
// | Arguments:
// |     left  = left operand for the multiplication
// |     right = left operand for the multiplication
// | Result is cynw_fixed instance that is the result of the multiplication.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE2
inline CWFX_MUL_SS(W,I,W1,I1)
operator * ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
	     const cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right) 
{
    CWFX_MUL_SS(W,I,W1,I1)             res; // result to return.
    CYNW_IVAL( CWFX_MUL_W(W,I,W1,I1) ) z;   // temp whose use improves QOR.

    z = CYNW_IARG( CWFX_MUL_W(W,I,W1,I1) )(left.value) * (right.value);
    res.value = z;
    return res;
}

CWFX_TEMPLATE2
inline CWFX_MUL_SU(W,I,W1,I1)
operator * ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_MUL_SU(W,I,W1,I1) res;
    if ( W > W1 ) { // keep smaller operand small.
	res.value = left.value;
	res.value = (res.value) * (right.value);
    }
    else {
	res.value = right.value;
	res.value = (res.value) * (left.value);
    }
    return res;
}

CWFX_TEMPLATE_WW
inline CWFX_MUL_SS(W,I,WW,WW)
operator * ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_int<WW> & right ) 
{
    cynw_fixed<WW,WW> temp(right);

    return left * temp;
}

CWFX_TEMPLATE_WW
inline CWFX_MUL_SS(WW,WW,W,I)
operator * ( const sc_int<WW> & left,
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_fixed<WW,WW> temp(left);

    return temp * right;
}

CWFX_TEMPLATE_WW
inline CWFX_MUL_SU(W,I,WW,WW)
operator * ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_uint<WW> & right ) 
{
    cynw_ufixed<WW,WW> temp(right);

    return left * temp;
}

CWFX_TEMPLATE_WW
inline CWFX_MUL_US(WW,WW,W,I)
operator * ( const sc_uint<WW> & left,
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_ufixed<WW,WW> temp(left);

    return temp * right;
}

CWFX_TEMPLATE
inline CWFX_MUL_SS(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator * ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
         const int & right ) 
{
    sc_int<CYNW_BITS_PER_INT> temp(right);
    return left * temp;
}

CWFX_TEMPLATE
inline CWFX_MUL_SS(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator * ( const int & left,
         const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_int<CYNW_BITS_PER_INT> temp(left);
    return temp * right;
}

CWFX_TEMPLATE
inline CWFX_MUL_SU(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator * ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const unsigned int & right ) 
{
    sc_uint<CYNW_BITS_PER_INT> temp(right);
    return left * temp;
}

CWFX_TEMPLATE
inline CWFX_MUL_US(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator * ( const unsigned int & left,
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_uint<CYNW_BITS_PER_INT> temp(left);
    return temp * right;
}

CWFX_TEMPLATE
inline CWFX_MUL_SS(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator * ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const double & right ) 
{
    return left * cwfx_convert_double(right);

}
CWFX_TEMPLATE
inline CWFX_MUL_SS(CYNW_FX_DW,CYNW_FX_IW,W,I)
operator * ( const double & left, 
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return cwfx_convert_double(left) * right;
}

CWFX_TEMPLATE
inline CWFX_MUL_SS(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator * ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const float & right ) 
{
    return left * cwfx_convert_double(right);
}

CWFX_TEMPLATE
inline CWFX_MUL_SS(W,I,W,I)
operator * ( const float & left, 
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return (double)left * right;
}

// +----------------------------------------------------------------------------
// |"cynw_fixed / denominator"
// | 
// | These operator overloads implement divison of cynw_fixed instances.
// |
// | Arguments:
// |     left  = left operand for the divison
// |     right = left operand for the divison
// | Result is cynw_fixed instance that is the result of the divison.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE2
inline CWFX_DIVS(W,I,W1,I1)
operator / ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_DIVS(W,I,W1,I1) res;
#   ifndef STRATUS_HLS
        if(right.value == 0 ) 
        {
            res = 0;
            cout << "cynw_fixed: Error, Divide by 0 attempted" << endl;
            return res;
        }
#   endif
    if ((O_MODE==SC_SAT || O_MODE==SC_SAT_ZERO || O_MODE==SC_SAT_SYM) && 
       (left.value)==CYNW_MAXNEG && (right.value)==(CYNW_IVAL(W1))(~(1ull<<W1)))
    {
        res.value = ~((CYNW_IVAL(CYNW_DIV_W(W1,I1)))(1)<<
	                   (CYNW_DIV_W(W1,I1)-1));
    }
    else
    {
        CYNW_UVAL(W) t1 = (CYNW_UVAL(W))left.value;
        CYNW_UVAL(W1) t2 = (CYNW_UVAL(W1))right.value;
        sc_uint<1> isneg = t1[W-1] ^ t2[W1-1];
        if( t1[W-1] ) 
	{
            t1 = ~t1 + (sc_uint<1>)1;
        }
        if( t2[W1-1] ) 
	{
	    t2 = ~t2 + (sc_uint<1>)1;
        }
        CYNW_UVAL(CYNW_DIV_W(W1,I1)) t3;
        CYNW_UVAL(W1+1)              t4;
        t3 = (CYNW_UVAL(CYNW_DIV_W(W1,I1)))t1 << (CYNW_DIV_W(W1,I1)-W);
        {
            CYNW_DPOPT_DIV;
            t4 = t3 % t2;
            t3 = t3 / t2;
        }
        if( isneg ) 
	{
            t3 |= (sc_uint<1>)(t4 != (CYNW_UVAL(W1+1))0);
            res.value = ~t3 + (CYNW_UVAL(1))1;
        }
	else
	{
            res.value = t3 | (sc_uint<1>)(t4 != (CYNW_UVAL(W1+1))0);
        }
    }
    return res;
}

CWFX_TEMPLATE2
inline CWFX_DIVS(W,I,W1,I1)
operator / ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_DIVS(W,I,W1,I1) res;
#   ifndef STRATUS_HLS
        if(right.value == 0 ) 
        {
            res = 0;
            cout << "cynw_fixed: Error, Divide by 0 attempted" << endl;
            return res;
        }
#   endif
    if ((O_MODE==SC_SAT || O_MODE==SC_SAT_ZERO || O_MODE==SC_SAT_SYM) && 
       (left.value)==CYNW_MAXNEG && (right.value)==(CYNW_IVAL(W1))(~(1ull<<W1)))
    {
        res.value = ~((CYNW_IVAL(CYNW_DIV_W(W1,I1)))(1)<<
	                   (CYNW_DIV_W(W1,I1)-1));
    }
    else
    {
        CYNW_UVAL(W) t1 = (CYNW_UVAL(W))left.value;
        CYNW_UVAL(W1) t2 = (CYNW_UVAL(W1))right.value;
        sc_uint<1> isneg = t1[W-1] != 0;
        if( t1[W-1] ) 
	{
            t1 = ~t1 + (sc_uint<1>)1;
        }
        CYNW_UVAL(CYNW_DIV_W(W1,I1)) t3;
        CYNW_UVAL(W1+1)              t4;
        t3 = (CYNW_UVAL(CYNW_DIV_W(W1,I1)))t1 << (CYNW_DIV_W(W1,I1)-W);
        {
            CYNW_DPOPT_DIV;
            t4 = t3 % t2;
            t3 = t3 / t2;
        }
        if( isneg ) 
	{
            t3 |= (sc_uint<1>)(t4 != (CYNW_UVAL(W1+1))0);
            res.value = ~t3 + (CYNW_UVAL(1))1;
        }
	else
	{
            res.value = t3 | (sc_uint<1>)(t4 != (CYNW_UVAL(W1+1))0);
        }
    }
    return res;
}

CWFX_TEMPLATE_WW
inline CWFX_DIVS(W,I,WW,WW) 
operator / ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_int<WW> & right ) 
{
    cynw_fixed<WW,WW> temp(right);
    return left / temp;
}

CWFX_TEMPLATE_WW
inline CWFX_DIVS(WW,WW,W,I) 
operator / ( const sc_int<WW> & left,
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_fixed<WW,WW> temp(left);
    return temp / right;
}

CWFX_TEMPLATE_WW
inline CWFX_DIVS(WW,WW,W,I)
operator / ( const sc_int<WW> & left,
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_fixed<WW,WW>                        temp_l(left);

    return temp_l / right;
}

CWFX_TEMPLATE_WW
inline CWFX_DIVS(W,I,WW,WW) 
operator / ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_uint<WW> & right ) 
{
    cynw_ufixed<WW,WW> temp(right);

    return left / temp;
}

CWFX_TEMPLATE
inline 
CWFX_DIVS(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator / ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const int & right ) 
{
    sc_int<CYNW_BITS_PER_INT> temp(right);
    
    return left / temp;
}

CWFX_TEMPLATE
inline 
CWFX_DIVS(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator / ( const int & left,
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_int<CYNW_BITS_PER_INT> temp(left);
    
    return temp / right;
}

CWFX_TEMPLATE
inline 
CWFX_DIVS(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator / ( const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const unsigned int & right ) 
{
    cynw_fixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT> temp(right);
    
    return left / temp;
}

CWFX_TEMPLATE
inline CWFX_DIVS(CYNW_FX_DW,CYNW_FX_IW,W,I)
operator / (
    const double & left, const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return cwfx_convert_double(left) / right;
}

CWFX_TEMPLATE
inline CWFX_DIVS(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator / (
    const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, const double & right) 
{
    return left / cwfx_convert_double(right);
}

CWFX_TEMPLATE
inline CWFX_DIVS(W,I,W,I)
operator / (
    const float & left, const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return (double)left / right;
}

CWFX_TEMPLATE
inline CWFX_DIVS(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator / (
    const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & left, const float & right) 
{
    return left / cwfx_convert_double(right);
}

// +----------------------------------------------------------------------------
// |"cynw_ufixed operator +"
// | 
// | These operator overloads implement addition of cynw_fixed instances.
// |
// | Arguments:
// |     left  = left operand for the addition
// |     right = left operand for the addition
// | Result is cynw_fixed instance that is the result of the addition.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE2
inline CWFX_ADD_UU(W,I,W1,I1)
operator + ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_ADD_UU(W,I,W1,I1) res;

      if((W-I)==(W1-I1)) 
      {
          res.value = CYNW_UARG( CWFX_ADD_W(W,I,W1,I1) )(left.value) +
                      CYNW_UARG( CWFX_ADD_W(W,I,W1,I1) )(right.value);
      } 
      else if((W-I) > (W1-I1)) 
      {
#if 0 // @@@@####
          res.value = left.value + CYNW_UARG( CWFX_ADD_W(W,I,W1,I1) )(
	                 (CYNW_UARG( CWFX_ADD_W(W,I,W1,I1) )right.value) << 
                         ((W-I-W1+I1)<0 ? 0 : (W-I-W1+I1))
	              );
#else
          res.value = (CYNW_UARG( CWFX_ADD_W(W,I,W1,I1) )right.value) << 
                         ((W-I-W1+I1)<0 ? 0 : (W-I-W1+I1));
	  res.value = (left.value) + (res.value);
#endif
      }
      else
      {
#if 0 // @@@@####
	  res.value = CYNW_UARG( CWFX_ADD_W(W,I,W1,I1) )(
			  (CYNW_UARG( CWFX_ADD_W(W,I,W1,I1) )left.value) << 
			  ((W1-I1-W+I)<0 ? 0 : (W1-I1-W+I))
		      ) + right.value;
#else

	  res.value = (CYNW_UARG( CWFX_ADD_W(W,I,W1,I1) )left.value) << 
			  ((W1-I1-W+I)<0 ? 0 : (W1-I1-W+I)) ;
	  res.value = (res.value) + (right.value);
#endif
      }

    return res;
}
  
CWFX_TEMPLATE2 
inline CWFX_ADD_US(W,I,W1,I1)
operator + ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    cynw_fixed<W+1,I+1> temp(left);
    return temp + right;
}

CWFX_TEMPLATE_WW 
inline CWFX_ADD_US(W,I,WW,WW)
operator + ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
             const sc_int<WW> & right ) 
{
    cynw_fixed<WW,WW> temp(right);
    return left + temp;
}

CWFX_TEMPLATE_WW 
inline CWFX_ADD_SU(WW,WW,W,I)
operator + ( const sc_int<WW> & left, 
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_fixed<WW,WW> temp(left);
    return temp + right;
}

CWFX_TEMPLATE_WW 
inline CWFX_ADD_UU(W,I,WW,WW)
operator + ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_uint<WW> & right ) 
{
    cynw_ufixed<WW,WW> temp(right);
    return left + temp;
}

CWFX_TEMPLATE_WW 
inline CWFX_ADD_UU(WW,WW,W,I)
operator + ( const sc_uint<WW> & left, 
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_ufixed<WW,WW> temp(left);
    return temp + right;
}

CWFX_TEMPLATE 
inline CWFX_ADD_US(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator + ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
             const int & right ) 
{
    sc_int<CYNW_BITS_PER_INT> temp(right);
    return left + temp;
}

CWFX_TEMPLATE 
inline CWFX_ADD_SU(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator + ( const int & left, 
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_int<CYNW_BITS_PER_INT> temp(left);
    
    return temp + right;
}

CWFX_TEMPLATE 
inline CWFX_ADD_US(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator + ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const double & right) 
{
    return left + cwfx_convert_double(right);
}

CWFX_TEMPLATE 
inline CWFX_ADD_SU(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator + ( const double & left, 
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return cwfx_convert_double(left) + right;
}
  
CWFX_TEMPLATE 
inline CWFX_ADD_US(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator + ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
             const float & right) 
{
    return left + cwfx_convert_double(right);
}

CWFX_TEMPLATE 
inline CWFX_ADD_SU(W,I,W,I)
operator + ( const float & left, 
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return (double)left + right;
}
  
// +----------------------------------------------------------------------------
// |"cynw_ufixed operator -"
// | 
// | These operator overloads implement subtraction of cynw_fixed instances.
// |
// | Arguments:
// |     left  = left operand for the subtraction
// |     right = left operand for the subtraction
// | Result is cynw_fixed instance that is the result of the subtraction.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE2
inline CWFX_SUB_UU(W,I,W1,I1)
operator - ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_SUB_UU(W,I,W1,I1) res;

    // Both values have the same number of fraction bits:

    if((W-I)==(W1-I1)) 
    {
        res.value = CYNW_UARG( CWFX_SUB_W(W,I,W1,I1) )(left.value) - (right.value);
    } 

    // The left-hand side has more fraction bits, adjust the right-hand side:

    else if((W-I) > (W1-I1)) 
    {
        res.value = (left.value) - CYNW_UARG( CWFX_SUB_W(W,I,W1,I1) )(
	               CYNW_UARG( CWFX_SUB_W(W,I,W1,I1) )(right.value) << 
                       ((W-I-W1+I1)<0 ? 0 : (W-I-W1+I1))
	            );
    }

    // The right-hand side has more fraction bits, adjust the left-hand side:

    else
    {
        res.value = CYNW_UARG( CWFX_SUB_W(W,I,W1,I1) )(
	                CYNW_UARG( CWFX_SUB_W(W,I,W1,I1) )(left.value) << 
			((W1-I1-W+I)<0 ? 0 : (W1-I1-W+I))
		    ) - (right.value);
    }

    return res;
}

CWFX_TEMPLATE2
inline CWFX_SUB_US(W,I,W1,I1)
operator - ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_SUB_US(W,I,W1,I1) res;

    // Both values have the same number of fraction bits:

    if((W-I)==(W1-I1)) 
    {
        res.value = (CYNW_UVAL( CWFX_ADD_W(W,I,W1,I1) ))(left.value) - (right.value);
    } 

    // The left-hand side has more fraction bits, adjust the right-hand side:

    else if((W-I) > (W1-I1)) 
    {
        res.value = (left.value) - (CYNW_IVAL( CWFX_ADD_W(W,I,W1,I1) ))(
	                (CYNW_IVAL( CWFX_ADD_W(W,I,W1,I1) ))(right.value) <<
			((W-I-W1+I1)<0 ? 0 : (W-I-W1+I1))
	            );
    }

    // The right-hand side has more fraction bits, adjust the left-hand side:

    else
    {
        res.value = (CYNW_UVAL( CWFX_ADD_W(W,I,W1,I1) ))(
	                (CYNW_UVAL( CWFX_ADD_W(W,I,W1,I1) )) (left.value)
			<< ((W1-I1-W+I)<0 ? 0 : (W1-I1-W+I))
                    ) - (right.value);
    }

    return res;
}

CWFX_TEMPLATE_WW
inline CWFX_SUB_US(W,I,WW,WW)
operator - ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_int<WW> & right )  
{
    cynw_fixed<WW,WW> temp(right);
    return left - temp;
}

CWFX_TEMPLATE_WW
inline CWFX_SUB_SU(WW,WW,W,I)
operator - ( const sc_int<WW> & left, 
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_fixed<WW,WW> temp(left);
    return temp - right;
}

CWFX_TEMPLATE_WW
inline CWFX_SUB_UU(W,I,WW,WW)
operator - ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_uint<WW> & right ) 
{
    cynw_ufixed<WW,WW> temp(right);

    return left - temp;
}

CWFX_TEMPLATE_WW
inline CWFX_SUB_UU(WW,WW,W,I)
operator - ( const sc_uint<WW> & left,
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_ufixed<WW,WW> temp(left);

    return temp - right;
}

CWFX_TEMPLATE
inline CWFX_SUB_US(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator - ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const int & right ) 
{
    sc_int<CYNW_BITS_PER_INT> temp(right);
    
    return left - temp;
}

CWFX_TEMPLATE
inline CWFX_SUB_SU(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator - ( const int & left,
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_int<CYNW_BITS_PER_INT> temp(left);
    
    return temp - right;
}

CWFX_TEMPLATE
inline CWFX_SUB_US(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator - ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
             const double & right ) 
{
    return left - cwfx_convert_double(right);
}

CWFX_TEMPLATE
inline CWFX_SUB_SU(CYNW_FX_DW,CYNW_FX_IW,W,I)
operator - ( const double & left, 
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return cwfx_convert_double(left) - right;
}

CWFX_TEMPLATE
inline CWFX_SUB_US(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator - ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, 
	     const float & right ) 
{
    return left - cwfx_convert_double(right);
}

CWFX_TEMPLATE
inline CWFX_SUB_SU(W,I,W,I)
operator - ( const float & left, 
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return (double)left - right;
}

// +----------------------------------------------------------------------------
// |"cynw_ufixed operator *"
// | 
// | These operator overloads implement multiplication of cynw_fixed instances.
// |
// | Notes:
// |   (1) For asymmetric multiplies consider using widths to guarantee the
// |       smaller operand stays small. This will require some experimentation
// |       since there is some QOR weirdness in the experiments I have run so
// |       far.
// | Arguments:
// |     left  = left operand for the multiplication
// |     right = left operand for the multiplication
// | Result is cynw_fixed instance that is the result of the multiplication.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE2
inline CWFX_MUL_UU(W,I,W1,I1)
operator * ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
	     const cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right) 
{
    CWFX_MUL_UU(W,I,W1,I1)             res; // result to return.
    CYNW_UVAL( CWFX_MUL_W(W,I,W1,I1) ) z;   // temp whose use improves QOR.

    z = CYNW_UARG(CYNW_RES_MUL_W)(left.value) * (right.value);
    res.value = z;
   return res;
}

CWFX_TEMPLATE2
inline CWFX_MUL_US(W,I,W1,I1)
operator * ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_MUL_US(W,I,W1,I1) res;
    if ( W >= W1 ) { // keep smaller operand small.
       res.value = left.value;
       res.value = (res.value) * (right.value);
    } 
    else {
       res.value = right.value;
       res.value = (res.value) * (left.value);
    }
   return res;
}

CWFX_TEMPLATE_WW
inline CWFX_MUL_US(W,I,WW,WW)
operator * ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_int<WW> & right ) 
{
    cynw_fixed<WW,WW> temp(right);
    return left * temp;
}

CWFX_TEMPLATE_WW
inline CWFX_MUL_SU(WW,WW,W,I)
operator * ( const sc_int<WW> & left, 
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_fixed<WW,WW> temp(left);

    return temp * right;
}

CWFX_TEMPLATE_WW
inline CWFX_MUL_UU(W,I,WW,WW)
operator * ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_uint<WW> & right ) 
{
    cynw_ufixed<WW,WW> temp(right);
    return left * temp;
}

CWFX_TEMPLATE_WW
inline CWFX_MUL_UU(WW,WW,W,I)
operator * ( const sc_uint<WW> & left,
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_ufixed<WW,WW> temp(left);
    return temp * right;
}

CWFX_TEMPLATE
inline CWFX_MUL_US(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator * ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const int & right ) 
{
    sc_int<CYNW_BITS_PER_INT> temp(right);
    return left * temp;
}

CWFX_TEMPLATE
inline CWFX_MUL_UU(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator * ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const unsigned int & right ) 
{
    sc_uint<CYNW_BITS_PER_INT> temp(right);
    return left * temp;
}

CWFX_TEMPLATE
inline CWFX_MUL_SU(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator * ( const int & left,
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_int<CYNW_BITS_PER_INT> temp(left);
    return temp * right;
}

CWFX_TEMPLATE
inline CWFX_MUL_UU(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator * ( const unsigned int & left,
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_uint<CYNW_BITS_PER_INT> temp(left);
    return temp * right;
}

CWFX_TEMPLATE
inline CWFX_MUL_US(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator * ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const double & right ) 
{
    return left * cwfx_convert_double(right);
}

CWFX_TEMPLATE
inline CWFX_MUL_SU(CYNW_FX_DW,CYNW_FX_IW,W,I)
operator * ( const double & left, 
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return cwfx_convert_double(left) * right;
}

CWFX_TEMPLATE
inline CWFX_MUL_US(W,I,CYNW_FX_DW,CYNW_FX_IW)
operator * ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const float & right ) 
{
    return left * cwfx_convert_double(right);
}

CWFX_TEMPLATE
inline CWFX_MUL_SU(W,I,W,I)
operator * ( const float & left, 
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return (double)left * right;
}

// +----------------------------------------------------------------------------
// |"cynw_ufixed / denominator"
// | 
// | These operator overloads implement divison of cynw_fixed instances.
// |
// | Arguments:
// |     left  = left operand for the divison
// |     right = left operand for the divison
// | Result is cynw_fixed instance that is the result of the divison.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE2
inline CWFX_DIVU(W,I,W1,I1) 
operator / ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_DIVU(W,I,W1,I1) res;
#   ifndef STRATUS_HLS
        if((right.value) == 0 ) 
        {
            res = 0;
            cout << "cynw_ufixed: Error, Divide by 0 attempted" << endl;
            return res;
        }
#   endif
    {
        CYNW_UVAL(CYNW_DIV_W(W1,I1)) t3 = 
	    (CYNW_UVAL(CYNW_DIV_W(W1,I1)))(left.value) << (CYNW_DIV_W(W1,I1)-W);
        CYNW_UVAL(W1+1) t4;
        {
        CYNW_DPOPT_DIV;
        t4 = t3 % (right.value);
        t3 = t3 / (right.value);
    }
    res.value = t3 | (sc_uint<1>)(t4 != (CYNW_UVAL(W1+1))0);
    }
    return res;
  }

CWFX_TEMPLATE2
inline CWFX_DIVS(W+1,I+1,W1,I1) 
operator / ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) 
{
    CWFX_DIVS(W+1,I+1,W1,I1) res;
#   ifndef STRATUS_HLS
        if((right.value) == 0 ) 
        {
            res = 0;
            cout << "cynw_fixed: Error, Divide by 0 attempted" << endl;
            return res;
        }
#   endif
    if ((O_MODE==SC_SAT || O_MODE==SC_SAT_ZERO || O_MODE==SC_SAT_SYM) && 
       (left.value)==CYNW_MAXNEG && (right.value)==(CYNW_IVAL(W1))(~(1ull<<W1)))
    {
        res.value = ~((CYNW_IVAL(CYNW_DIV_W(W1,I1)))(1)<<
	                   (CYNW_DIV_W(W1,I1)-1));
    }
    else
    {
        CYNW_UVAL(W) t1 = (CYNW_UVAL(W))left.value;
        CYNW_UVAL(W1) t2 = (CYNW_UVAL(W1))right.value;
        sc_uint<1> isneg = (int)t2[W1-1];
        if( t2[W1-1] ) 
	{
	    t2 = ~t2 + (sc_uint<1>)1;
        }
        CYNW_UVAL(CYNW_DIV_W(W1,I1)) t3;
        CYNW_UVAL(W1+1)              t4;
        t3 = (CYNW_UVAL(CYNW_DIV_W(W1,I1)))t1 << (CYNW_DIV_W(W1,I1)-W);
        {
            CYNW_DPOPT_DIV;
            t4 = t3 % t2;
            t3 = t3 / t2;
        }
        if( isneg ) 
	{
            t3 |= (sc_uint<1>)(t4 != (CYNW_UVAL(W1+1))0);
            res.value = ~t3 + (CYNW_UVAL(1))1;
        }
	else
	{
            res.value = t3 | (sc_uint<1>)(t4 != (CYNW_UVAL(W1+1))0);
        }
    }
    return res;
}

CWFX_TEMPLATE_WW
inline CWFX_DIVS(W+1,I+1,WW,WW)
operator / ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_int<WW> & right ) 
{
    cynw_fixed<WW,WW>   temp_r(right);
    return left / temp_r;
}

CWFX_TEMPLATE_WW
inline CWFX_DIVU(W,I,WW,WW)
operator / ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const sc_uint<WW> & right ) 
{
    cynw_ufixed<WW,WW> temp(right);

    return left / temp;
}

CWFX_TEMPLATE_WW
inline CWFX_DIVU(W,I,WW,WW)
operator / ( const sc_uint<WW> & left,
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_ufixed<WW,WW> temp(left);

    return temp / right;
}

CWFX_TEMPLATE_WW
inline CWFX_DIVS(WW+1,WW+1,W,I) 
operator / ( const sc_uint<WW> & left,
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_ufixed<WW,WW> temp(left);

    return temp / right;
}

CWFX_TEMPLATE
inline CWFX_DIVS(W+1,I+1,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator / ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const int & right ) 
{
    sc_int<CYNW_BITS_PER_INT> temp(right);
    
    return left / temp;
}

CWFX_TEMPLATE
inline CWFX_DIVS(CYNW_BITS_PER_INT+1,CYNW_BITS_PER_INT+1,W,I)
operator / ( const int & left,
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    sc_int<CYNW_BITS_PER_INT> temp(left);
    
    return temp / right;
}

CWFX_TEMPLATE
inline CWFX_DIVS(CYNW_BITS_PER_INT+1,CYNW_BITS_PER_INT+1,W,I)
operator / ( const unsigned int & left,
             const cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_ufixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT> temp(left);
    
    return temp / right;
}

CWFX_TEMPLATE
inline CWFX_DIVU(W,I,CYNW_BITS_PER_INT,CYNW_BITS_PER_INT)
operator / ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,
             const unsigned int & right ) 
{
    cynw_ufixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT> temp(right);
    
    return left / temp;
}

CWFX_TEMPLATE
inline CWFX_DIVU(CYNW_BITS_PER_INT,CYNW_BITS_PER_INT,W,I)
operator / ( const unsigned int & left,
             const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    cynw_ufixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT> temp(left);
    
    return temp / right;
}

CWFX_TEMPLATE
inline CWFX_DIVS(W,I,CYNW_FX_DW,CYNW_FX_IW) operator / (
    const double & left, const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return cwfx_convert_double(left) / right;
}

CWFX_TEMPLATE
inline CWFX_DIVS(W,I,CYNW_FX_DW,CYNW_FX_IW) operator / (
    const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, const double & right) 
{
    return left / cwfx_convert_double(right);
}

CWFX_TEMPLATE
inline CWFX_DIVS(W,I,W,I) operator / (
    const float & left, const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )
{
    return (double)left / right;
}

CWFX_TEMPLATE
inline CWFX_DIVS(W,I,CYNW_FX_DW,CYNW_FX_IW) operator / (
    const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, const float & right) 
{
    return left / cwfx_convert_double(right);
}

#define CYNW_UFIXED_COMPARE(OP) \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, \
                          const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right )  \
{ \
    return (left.value) OP (right.value); \
} \
   \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, \
       int W1, int I1, sc_q_mode Q_MODE1, sc_o_mode O_MODE1, int N_BITS1> \
inline bool operator OP ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, \
                       const cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right)  \
{ \
    if(I<I1)  \
    { \
	if ( (W-I) < (W1-I1) ) /* use right's size. */ \
	{ \
            cynw_ufixed<W1,I1,Q_MODE,O_MODE,N_BITS> temp; \
            temp = left; \
            return (temp.value) OP (right.value); \
	} \
	else /* use right's int and left's fraction. */ \
	{ \
            cynw_ufixed<I1+(W-I),I1> temp_left; \
            cynw_ufixed<I1+(W-I),I1> temp_right; \
	    temp_left = left; \
	    temp_right = right; \
	    return (temp_left.value) OP (temp_right.value); \
	} \
    }  \
    else  \
    { \
	if ( (W-I) > (W1-I1) ) /* use left's size. */ \
	{ \
            cynw_ufixed<W,I,Q_MODE1,O_MODE1,N_BITS1> temp; \
            temp = right; \
            return (left.value) OP (temp.value); \
	} \
	else /* use left's int and right's fraction. */ \
	{ \
            cynw_ufixed<I+(W1-I1),I> temp_left; \
            cynw_ufixed<I+(W1-I1),I> temp_right; \
	    temp_left = left; \
	    temp_right = right; \
	    return (temp_left.value) OP (temp_right.value); \
	} \
    } \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, \
       int W1, int I1, sc_q_mode Q_MODE1, sc_o_mode O_MODE1, int N_BITS1> \
inline bool operator OP ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, \
                      const cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> & right ) \
{ \
    cynw_fixed<W+1,I+1> temp(left); \
    return temp OP right; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, int WW> \
inline bool operator OP ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,  \
                      const sc_int<WW> & right )  \
{ \
    cynw_fixed<WW,WW> temp(right); \
    return left OP temp; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, int WW> \
inline bool operator OP ( const sc_int<WW> & left, \
                          const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right ) \
{ \
    cynw_fixed<WW,WW> temp(left); \
    return temp OP right; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, int WW> \
inline bool operator OP ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, \
                          const sc_uint<WW> & right )  \
{ \
    cynw_ufixed<WW,WW> temp(right); \
    return left OP temp; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS, int WW> \
inline bool operator OP ( const sc_uint<WW> & left,  \
                          const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right ) \
{ \
    cynw_ufixed<WW,WW> temp(left); \
    return temp OP right; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,  \
                      const int & right )  \
{ \
    cynw_fixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT> temp(right); \
    return left OP temp; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const int & left,  \
                      const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right ) \
{ \
    cynw_fixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT> temp(left); \
    return temp OP right; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left,  \
                      const unsigned int & right )  \
{ \
    cynw_ufixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT> temp(right); \
    return left OP temp; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const unsigned int & left,  \
                      const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right ) \
{ \
    cynw_ufixed<CYNW_BITS_PER_INT,CYNW_BITS_PER_INT> temp(left); \
    return temp OP right; \
} \
 \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & left, \
                          const double & right)  \
{ \
    cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> temp(right); \
    return left OP cwfx_convert_double(right); \
} \
template<int W, int I, sc_q_mode Q_MODE, sc_o_mode O_MODE, int N_BITS> \
inline bool operator OP ( const double & left,  \
                      const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & right ) \
{ \
    return cwfx_convert_double(left) OP right; \
} \
   \
// +----------------------------------------------------------------------------
// |"cynw_ufixed operator =="
// | 
// | These operator overloads implement equal comparison of cynw_fixed 
// | instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------
CYNW_UFIXED_COMPARE(==)
  
// +----------------------------------------------------------------------------
// |"cynw_ufixed operator !="
// | 
// | These operator overloads implement not equal comparison of cynw_fixed 
// | instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------
CYNW_UFIXED_COMPARE(!=)
  
// +----------------------------------------------------------------------------
// |"cynw_ufixed operator >"
// | 
// | These operator overloads implement greater than comparison of cynw_fixed 
// | instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------
CYNW_UFIXED_COMPARE(>)
  
// +----------------------------------------------------------------------------
// |"cynw_ufixed operator >="
// | 
// | These operator overloads implement less than or equal comparison of 
// | cynw_fixed instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------
CYNW_UFIXED_COMPARE(>=)
  
// +----------------------------------------------------------------------------
// |"cynw_ufixed operator <"
// | 
// | These operator overloads implement less than comparison of cynw_fixed 
// | instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------
CYNW_UFIXED_COMPARE(<)
  
// +----------------------------------------------------------------------------
// |"cynw_ufixed operator <="
// | 
// | These operator overloads implement less than or equal comparison of 
// | cynw_fixed instances.
// |
// | Arguments:
// |     left  = left operand for the comparison
// |     right = left operand for the comparison
// | Result is boolean result of the comparison.
// +----------------------------------------------------------------------------
CYNW_UFIXED_COMPARE(<=)
  
/*
 * --------------------------------------------------------------
 *  public non-member functions
 * --------------------------------------------------------------
 */

#define CYNW_SQRTHALF 0xb504f333f9de600LL

CWFX_TEMPLATE
cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> sqrt( cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & a ) 
{
    cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> res;
    sc_uint<W+W-I> x = (sc_uint<W+W-I>)a.value;
    if( (W-I) & 1 ) 
    {
        x = x << W-I-1;
        x = sqrt(x);
        res.value = (x * (sc_uint<61>)((CYNW_SQRTHALF) >> (60-(W)))) >> (W-1);
    }
    else
    {
        x = x << W-I;
        res.value = sqrt(x);
    }
    return res;
}

CWFX_TEMPLATE
cynw_ufixed<W+(O_MODE!=SC_WRAP?1:0),I+(O_MODE!=SC_WRAP?1:0),Q_MODE,O_MODE,N_BITS> round (const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & a) {
       cynw_ufixed<W+(O_MODE!=SC_WRAP?1:0),I+(O_MODE!=SC_WRAP?1:0),Q_MODE,O_MODE,N_BITS> res;
           res.value = (a.value) + ( (CYNW_UVAL(W))(1LL) << (W-I-1));
           res = floor(res);
       return res;
   }

CWFX_TEMPLATE
cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> floor(const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> & a) {
       cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> res;
       res.value = (a.value) & ~((1LL << (W-I))-1);
            // @@@@#### ~( ( (CYNW_UVAL(W))(1) << (W-I)) -1 );
       return res;
   }

CWFX_TEMPLATE
inline
ostream & operator << ( ostream& os, const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>& a ) 
{
#ifndef STRATUS_HLS
    a.print( os );
#endif
    return os;
}

CWFX_TEMPLATE
inline void sc_trace( sc_trace_file *tf, 
        const cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS>& object, 
        const std::string& name ) 
{
    sc_trace( tf, object.value, name );
}

//------------------------------------------------------------------------------
// cynw_interpret() OVERLOADS TO ALLOW cynw_fixed USE WITH EXTERNAL MEMORIES:
//------------------------------------------------------------------------------
template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline 
void cynw_interpret( const sc_biguint<W>& from, cynw_fixed<W,I,Q,O,N>& to )
{
    to.value = from;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline 
void cynw_interpret( const cynw_fixed<W,I,Q,O,N>& from, sc_biguint<W>& to )
{
    to = from.value;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline void cynw_interpret( const sc_uint<W>& from, cynw_fixed<W,I,Q,O,N>& to )
{
    to.value = from;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline void cynw_interpret( const cynw_fixed<W,I,Q,O,N>& from, sc_uint<W>& to )
{
    to = from.value;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline 
void cynw_interpret( const sc_bigint<W>& from, cynw_fixed<W,I,Q,O,N>& to )
{
    to.value = from;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline 
void cynw_interpret( const cynw_fixed<W,I,Q,O,N>& from, sc_bigint<W>& to )
{
    to = from.value;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline void cynw_interpret( const sc_int<W>& from, cynw_fixed<W,I,Q,O,N>& to )
{
    to.value = from;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline void cynw_interpret( const cynw_fixed<W,I,Q,O,N>& from, sc_int<W>& to )
{
    to = from.value;
}

//------------------------------------------------------------------------------
// cynw_interpret() OVERLOADS TO ALLOW cynw_ufixed USE WITH EXTERNAL MEMORIES:
//------------------------------------------------------------------------------
template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline 
void cynw_interpret( const sc_biguint<W>& from, cynw_ufixed<W,I,Q,O,N>& to )
{
    to.value = from;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline 
void cynw_interpret( const cynw_ufixed<W,I,Q,O,N>& from, sc_biguint<W>& to )
{
    to = from.value;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline void cynw_interpret( const sc_uint<W>& from, cynw_ufixed<W,I,Q,O,N>& to )
{
    to.value  = from;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline void cynw_interpret( const cynw_ufixed<W,I,Q,O,N>& from, sc_uint<W>& to )
{
    to = from.value;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline 
void cynw_interpret( const sc_bigint<W>& from, cynw_ufixed<W,I,Q,O,N>& to )
{
    to.value = from;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline 
void cynw_interpret( const cynw_ufixed<W,I,Q,O,N>& from, sc_bigint<W>& to )
{
    to = from.value;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline void cynw_interpret( const sc_int<W>& from, cynw_ufixed<W,I,Q,O,N>& to )
{
    to.value = from;
}

template<int W, int I, sc_q_mode Q, sc_o_mode O, int N>
inline void cynw_interpret( const cynw_ufixed<W,I,Q,O,N>& from, sc_int<W>& to )
{
    to = from.value;
}


// Remove the symbols we created...

#undef CYNW_FX_LS_SIZE
#undef CYNW_FX_RS_SIZE

#if 0 // Some of these are used by other code, determine which ones.
#undef CWFX_ADD_SS
#undef CWFX_ADD_SU
#undef CWFX_ADD_US
#undef CWFX_MUL_SS
#undef CWFX_MUL_SU
#undef CWFX_MUL_US
#undef CWFX_SUB_SS
#undef CWFX_SUB_SU
#undef CWFX_SUB_US
#undef CWFX_DIVU
#undef CWFX_DIVS
#undef CWFX_TEMPLATE
#undef CWFX_TEMPLATE2
#undef CWFX_TEMPLATE_WW
#undef CYNW_BIAS
#undef CYNW_BITS_PER_BYTE
#undef CYNW_BITS_PER_DOUBLE
#undef CYNW_BITS_PER_INT
#undef CYNW_BITS_PER_LONG
#undef CYNW_BITS_PER_LONGLONG
#undef CYNW_DOUBLE_BIAS
#undef CYNW_DOUBLE_EXP
#undef CYNW_DOUBLE_MAN
#undef CYNW_DPOPT_DIV
#undef CYNW_DPOPT_DIVCYN_DPOPT_INLINE
#undef CYNW_EFF_W
#undef CYNW_FIXED_EXPLICIT
#undef CYNW_FIXED_GENERIC_BASE
#undef CYNW_FLOAT_BIAS
#undef CYNW_FLOAT_EXP8
#undef CYNW_FLOAT_MAN23
#undef CYNW_FX_DIV_BITS
#undef CYNW_FX_NAME
#undef CYNW_FX_TYPES
#undef CYNW_IARG
#undef CYNW_INTS_PER_DOUBLE
#undef CYNW_IVAL
#undef CYNW_LOG_BITS_PER_DOUBLE
#undef CYNW_LOG_BITS_PER_INT
#undef CYNW_MAX
#undef CYNW_MAXNEG
#undef CYNW_MAXNEGP
#undef CYNW_MAXPOS
#undef CYNW_MIN
#undef CYNW_DIV_WU(I1)
#undef CYNW_DRES
#undef CYNW_RES_I
#undef CYNW_RES_IINT
#undef CYNW_RES_IW
#undef CYNW_RES_IW_U
#undef CYNW_RES_MUL_I
#undef CYNW_RES_MUL_I_INT
#undef CYNW_RES_MUL_IW
#undef CYNW_RES_MUL_W_INT
#undef CYNW_RES_MUL_W
#undef CYNW_RES_MUL_WW
#undef CYNW_RES_O_MODE
#undef CYNW_RES_W
#undef CYNW_RES_WINT
#undef CYNW_RES_WW
#undef CYNW_RES_WW_U
#undef CYNW_SQRTHALF
#undef CYNW_SUBREF
#undef CYNW_UARG
#undef CYNW_UMAXPOS
#undef CYNW_UVAL
#undef RND_SAT_OPTIM
#undef RND_SAT_OPTIM_U
#endif 

#endif // Cynw_Fixed_H_INCLUDED


