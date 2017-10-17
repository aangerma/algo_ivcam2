/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/
#ifndef Cynw_cm_Float_int_H_INCLUDED
#define Cynw_cm_Float_int_H_INCLUDED

#include <math.h>
#include "stratus_hls.h"

#define CYNW_CM_FLOAT_VERSION 20100129

#include "cynw_cm_float_base.h"

/////////////////////////////////////////////////////////////////////////////////////////////////
//
//    The cynw_cm_float<> class is configured with template parameters that define both how floating 
//    point numbers are representated, and how operations are performed on them.  The template signature is:
//
//    template<const int E, const int M, const int ACCURACY=CYNW_REDUCED_ACCURACY, 
//    const int ROUND=CYNW_NEAREST, const int NaN=1>
//
//    where the values are defined as follows:
//
//    E : Exponent size
//
//    Specifies the exponent size.
//
//    default: no default.  A value must be specified.
//
//
//    M : Mantissa size
//
//    Specifies the mantissa size.
//
//    default: not default.  A value must be specified
// 
//    ACCURACY : Accuracy option
//
//    Defines the nature of the accuracy of operations by determining their method of implementation.  
//    See the Module Reference for details on the effect of this parameter on various operations. 
//
//    Options are:
//
//    CYNW_REDUCED_ACCURACY=0 
//        Use a reduced accuracy module if it is available.
//
//    CYNW_BEST_ACCURACY=1 
//        Use an IEEE-compliant module if it available.
//
//    CYNW_NATIVE_ACCURACY=2
//        Use a native C++ double for calculations.  Not synthesizable.
//    default: CYNW_REDUCED_ACCURACY
//
//    CYNW_EXCEPTION_ACCURACY=3 
//        Use an IEEE-compliant module, including exceptions if it available.
//
//        
//    ROUND : Rounding mode
//
//    Specifies the rounding mode for IEEE-standard modules.  Options are:
//
//    CYNW_NEAREST=0 : Round to the nearest even.
//
//    CYNW_POSINF=1 : Round to +infinity.
//
//    CYNW_NEGINF=2 : Round to -infinity.
//
//    CYNW_RNDZERO=3 : Round to zero.
//    default: CYNW_NEAREST
//
//    NaN : Not-a-number handling
//
//    Specified NaN handling for IEEE-standard modules.  Options are:
//
//    0 : Returns a constant NaN.
//    1 : IEEE-compliant NaN handling.  Left-hand operand has priority.
//    2 : IEEE-compliant NaN handling.  Right-hand operand has priority.
//    default 1
//
/////////////////////////////////////////////////////////////////////////////////////////////////

//
//  For now, define some template parameters  hich have been removed from the template parameters, but
//  not yet from the code.
//
#define DENORM 1
#define DENORM1 1
#define EXCP 0
#define EXCP1 0

/*
------------------------------------------------------------------------------
Create DPOPT inlined major functions (Add, Mul, Div, Sqrt, ...) and
minor functions (int_to_cynw_cm_float, double_to_cynw_cm_float, ...)
The default is to DPOPT the functions. This can be turned off.
------------------------------------------------------------------------------
*/

#if defined CYNW_CM_FLOAT_NO_DPOPT || defined CYNW_CM_FLOAT_NO_DPOPT_ADD
#define CWF_DPOPT_ADD
#else
#define CWF_DPOPT_ADD HLS_DPOPT_REGION(HLS::NO_CONSTANTS|HLS::NO_TRIMMING,"cynw_cm_float_add")
#endif

#if defined CYNW_CM_FLOAT_NO_DPOPT || defined CYNW_CM_FLOAT_NO_DPOPT_MUL
#define CWF_DPOPT_MUL
#else
#define CWF_DPOPT_MUL HLS_DPOPT_REGION(HLS::NO_CONSTANTS|HLS::NO_TRIMMING,"cynw_cm_float_mul")
#endif

#if defined CYNW_CM_FLOAT_NO_DPOPT || defined CYNW_CM_FLOAT_NO_DPOPT_DIV
#define CWF_DPOPT_DIV
#else
#define CWF_DPOPT_DIV HLS_DPOPT_REGION(HLS::NO_CONSTANTS|HLS::NO_TRIMMING,"cynw_cm_float_div")
#endif

#if defined CYNW_CM_FLOAT_NO_DPOPT || defined CYNW_CM_FLOAT_NO_DPOPT_SQRT
#define CWF_DPOPT_SQRT
#else
#define CWF_DPOPT_SQRT HLS_DPOPT_REGION(HLS::NO_CONSTANTS|HLS::NO_TRIMMING,"cynw_cm_float_sqrt")
#endif

#if defined CYNW_CM_FLOAT_NO_DPOPT || defined CYNW_CM_FLOAT_NO_DPOPT_REL
#define CWF_DPOPT_REL(X)
#else
#define CWF_DPOPT_REL(X) HLS_DPOPT_REGION(HLS::NO_CONSTANTS|HLS::NO_TRIMMING,X,X)
#endif

#if defined CYNW_CM_FLOAT_NO_DPOPT || defined CYNW_CM_FLOAT_NO_DPOPT_CNV
#define CWF_DPOPT_CNV(X)
#else
#define CWF_DPOPT_CNV(X) HLS_DPOPT_REGION(HLS::NO_CONSTANTS|HLS::NO_TRIMMING|HLS::NO_WIRE_ONLY,X,X)
#endif

#if defined CYNW_CM_FLOAT_NO_DPOPT || defined CYNW_CM_FLOAT_NO_DPOPT_ADD || defined CYNW_CM_FLOAT_NO_DPOPT_MUL || \
    defined CYNW_CM_FLOAT_NO_DPOPT_DIV || defined CYNW_CM_FLOAT_NO_DPOPT_SQRT || defined CYNW_CM_FLOAT_NO_DPOPT_CNV
#define DPOPTINLINESMALL(X) HLS_DPOPT_REGION(HLS::NO_CONSTANTS|HLS::NO_TRIMMING,X,X)
#else
#define DPOPTINLINESMALL(X)
#endif 


#if defined STRATUS  &&  ! defined CYN_DONT_SUPPRESS_MSGS
#pragma cyn_suppress_msgs NOTE
#endif	// STRATUS  &&  CYN_DONT_SUPPRESS_MSGS

#if defined STRATUS 
#pragma hls_ip_def
#endif	



/*
------------------------------------------------------------------------------
Floating-point exception flag masks.
------------------------------------------------------------------------------
*/
enum cynw_cm_float_ex_flag_value {
    cynw_ex_none      =  0,
    cynw_ex_inexact   =  1,
    cynw_ex_divbyzero =  2,
    cynw_ex_underflow =  4,
    cynw_ex_overflow  =  8,
    cynw_ex_invalid   = 16
};

/*
------------------------------------------------------------------------------
Floating-point exception flags.
Default value with no flags
------------------------------------------------------------------------------
*/
template<bool CYNW_ACTIVE, int CYNW_RAW_BITS >
class cynw_cm_float_ex_flags {
  public:
    enum {n_bits=0};
    template <int CYN_N>
    static sc_uint<5> extract( const sc_uint<CYN_N>& bits ) { return 0; }
    cynw_cm_float_ex_flags( const cynw_cm_float_ex_flag_value val=cynw_ex_none ) {}
    template <bool T, int CYNW_RAW_BITS2>
    cynw_cm_float_ex_flags( const cynw_cm_float_ex_flags<T,CYNW_RAW_BITS2> val ) {}
    template <bool T, int CYNW_RAW_BITS2>
    cynw_cm_float_ex_flags& operator=( const cynw_cm_float_ex_flags<T,CYNW_RAW_BITS2> val ) { return *this; }
    bool is_set() const {return false;}
    sc_uint<5> get() const { return 0; }
    sc_uint<1> is_set(const cynw_cm_float_ex_flag_value flag) const { return 0; }
    void set(const sc_uint<5> v ) {}
    template <int CYN_N>
    void set(const sc_uint<CYN_N> v, unsigned msb, unsigned lsb ) {}
    void set(const cynw_cm_float_ex_flag_value flag) { }
    void clear(const cynw_cm_float_ex_flag_value flag) { }
    void clear() { }
};



/*
------------------------------------------------------------------------------
Specialization with 5 bit value.
------------------------------------------------------------------------------
*/
template<int CYNW_RAW_BITS>
class cynw_cm_float_ex_flags<true,CYNW_RAW_BITS> {
  public:
    enum {n_bits=5};

    sc_uint<5> flags;

    template <int CYN_N>
    static sc_uint<5> extract( const sc_uint<CYN_N>& bits ) 
    { 
        return bits.range( CYNW_RAW_BITS+4, CYNW_RAW_BITS ); 
    }

    cynw_cm_float_ex_flags( const cynw_cm_float_ex_flag_value val=cynw_ex_none )
        : flags(val)
    {}
    template <bool T, int CYNW_RAW_BITS2>
    cynw_cm_float_ex_flags( const cynw_cm_float_ex_flags<T,CYNW_RAW_BITS2> val )
        : flags( val.get() )
    {}
    template <bool T, int CYNW_RAW_BITS2>
    cynw_cm_float_ex_flags& operator=( const cynw_cm_float_ex_flags<T,CYNW_RAW_BITS2> val )
    {
        flags = val.get();
        return *this;
    }
    bool is_set() const 
    { 
        return (flags != 0);
    }
    sc_uint<5> get() const 
    { 
        return flags;
    }
    sc_uint<1> is_set(const cynw_cm_float_ex_flag_value flag) const
    {
        return ((flags & (sc_uint<5>((unsigned)flag))) != 0);
    }
    void set(const sc_uint<5> v )
    {
        flags = v;
    }
    template <int CYN_N>
    void set(const sc_uint<CYN_N> v, unsigned msb, unsigned lsb ) 
    {
        flags = v.range( msb, lsb );
    }
    void set(const cynw_cm_float_ex_flag_value flag)
    {
        flags |= (sc_uint<5>((unsigned)flag));
    }
    void clear(const cynw_cm_float_ex_flag_value flag)
    {
        flags &= ~(sc_uint<5>((unsigned)flag));
    }
    void clear()
    {
        flags = 0;
    }
};



#define BITS_PER_BYTE 8
#define CW_BITS_PER_INT 32
#define LOG_BITS_PER_INT 5
#define CW_BITS_PER_DOUBLE 64
#define LOG_BITS_PER_DOUBLE 6
#define INTS_PER_DOUBLE 2

#define FLOAT_MAN 23
#define FLOAT_EXP 8
#define DOUBLE_MAN 52
#define DOUBLE_EXP 11

#define LOG_MAX_M 8

#define BIAS(E) ((1<<(E-1))-1)
#define FLOAT_BIAS BIAS(FLOAT_EXP)
#define DOUBLE_BIAS BIAS(DOUBLE_EXP)

#define zESet ((sc_uint<E>)((1<<E)-1))
#define zMSet ((sc_uint<M>)(((1ll)<<M)-1))

#define X	(ROUND>0?3:1)

/*
------------------------------------------------------------------------------
Floating-point rounding mode codes.
------------------------------------------------------------------------------
*/
#define CYNW_NEAREST 0
#define CYNW_POSINF 1
#define CYNW_NEGINF 2
#define CYNW_RNDZERO 3

/*
-----------------------------------------------------------------------------
Floatin-point accuracy codes.
-----------------------------------------------------------------------------
*/
#define CYNW_REDUCED_ACCURACY 0
#define CYNW_BEST_ACCURACY 1
#define CYNW_NATIVE_ACCURACY 2
#define CYNW_EXCEPTION_ACCURACY 3


/*
------------------------------------------------------------------------------
class definition.
------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY=CYNW_REDUCED_ACCURACY, const int ROUND=CYNW_NEAREST, const int NaN=1>
class cynw_cm_float {

public:
  sc_uint<M> man;
  sc_uint<E> exp;
  sc_uint<1> sign;

  enum {
    n_raw_bits = E+M+1,                 // Number of raw bits to store.
  };
  typedef cynw_cm_float_ex_flags<ACCURACY==CYNW_EXCEPTION_ACCURACY,n_raw_bits> exception_t;
  enum {
    n_ex_bits = exception_t::n_bits,    // Number of exception bits computed.
    n_raw_bits_ex = E+M+1+n_ex_bits     // Number of bits computed, with exceptions.
  };

  // Constructors
  cynw_cm_float() {
    sign = 0;
    exp = 0;
    man = 0;
  }
  
  cynw_cm_float(sc_uint<1> zSign, sc_uint<E> zExp, sc_uint<M> zMan) { 
    sign = zSign;
    exp = zExp;
    man = zMan;
  }
  
  template<int W>
  cynw_cm_float(const sc_int<W> & a) { 
	cynw_cm_float<E,M,ACCURACY,ROUND,NaN> f = int_to_cynw_cm_float(a);
    sign = f.sign;
    exp = f.exp;
    man = f.man;
  }
  
  cynw_cm_float(const int & a) {
	cynw_cm_float<E,M,ACCURACY,ROUND,NaN> f = int_to_cynw_cm_float(a);
    sign = f.sign;
    exp = f.exp;
    man = f.man;
  }
  
  cynw_cm_float(const long long & a) {
	cynw_cm_float<E,M,ACCURACY,ROUND,NaN> f = ll_to_cynw_cm_float(a);
    sign = f.sign;
    exp = f.exp;
    man = f.man;
  }
  
  cynw_cm_float(const float & a) {
	cynw_cm_float<E,M,ACCURACY,ROUND,NaN> f = float_to_cynw_cm_float(a);
    sign = f.sign;
    exp = f.exp;
    man = f.man;
  }
  
  cynw_cm_float(const double & a) {
	cynw_cm_float<E,M,ACCURACY,ROUND,NaN> f = double_to_cynw_cm_float(a);
    sign = f.sign;
    exp = f.exp;
    man = f.man;
  }
  
  template<const int E1, const int M1, const int ACCURACY1, const int ROUND1, const int NaN1>
  cynw_cm_float(const cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> & a) {
	cynw_cm_float<E,M,ACCURACY,ROUND,NaN> f = to_cynw_cm_float(a);
    sign = f.sign;
    exp = f.exp;
    man = f.man;
  }
  
  
  // Destructor
  ~cynw_cm_float() {
  }
  
  
  // Overloading the assignment operator
  // provide an "operator =" for the special case of source and sink being the same format
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & operator = (cynw_cm_float<E,M,ACCURACY,ROUND,NaN> a) {
    this->sign = a.sign;
    this->exp = a.exp;
    this->man = a.man;
    return *this;
  }

  // This provides an "operator =" for all types for which there is a constructor
  template<typename OTHER>
  const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & operator = ( const OTHER & value ) { 
	  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> temp(value);
	  return *this = temp;
  }


  // Overloading the cast operators
  template<int W>
  operator sc_int<W> () const {
    sc_int<W> res;
    if (W<=CW_BITS_PER_INT)
      res = to_int();
    else
      res = to_int64();
    return res;
  }

/*
  ------------------------------------------------------------------------------
 * Note: we don't define these casts because if you do, then you get ambiguous conversions
 *
  operator long long () {
    long long res;
    res = to_int64(*this);
    return res;
  }
  operator int () {
    int res;
    res = to_int();
    return res;
  }
  operator float () {
    float res;
    res = to_float(*this);
    return res;
  }
  operator double () {
    double res;
    res = to_double(*this);
    return res;
  }
  ------------------------------------------------------------------------------
 */

  // Overloading arithmetic operators
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> operator + (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b) const  {
    return cynw_cm_float_add(*this, b, (sc_uint<1>)(0));
  }
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> operator - (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b) const {
    return cynw_cm_float_add(*this, b, (sc_uint<1>)(1));
  }
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> operator - () const {		// unary minus
    return cynw_cm_float_res(~this->sign, this->exp, this->man);
  }
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> operator * (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b) const {
    return cynw_cm_float_mul(*this, b);
  }

  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> operator / (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b) const {
    return cynw_cm_float_div(*this, b);
  }

  // Overloading the arithmetic assignment operators
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> operator += (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a) {
    *this = cynw_cm_float_add(*this, a, (sc_uint<1>)0);
    return *this;
  }

  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> operator -= (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a) {
    *this = cynw_cm_float_add(*this, a, (sc_uint<1>)1);
    return *this;
  }

  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> operator *= (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a) {
    *this = cynw_cm_float_mul(*this, a);
    return *this;
  }

  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> operator /= (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a) {
    *this = cynw_cm_float_div(*this, a);
    return *this;
  }

  // Overloading the relational operators
  int operator == (cynw_cm_float<E,M,ACCURACY,ROUND,NaN> a) const {
    return cynw_cm_float_eq_cynw_cm_float(*this, a, 0);
  }
  int operator != (cynw_cm_float<E,M,ACCURACY,ROUND,NaN> a) const {
    return cynw_cm_float_eq_cynw_cm_float(*this, a, 1);
  }
  int operator < (cynw_cm_float<E,M,ACCURACY,ROUND,NaN> a) const {
    return cynw_cm_float_lt_cynw_cm_float(*this, a, 0);
  }
  int operator <= (cynw_cm_float<E,M,ACCURACY,ROUND,NaN> a) const {
    return cynw_cm_float_lt_cynw_cm_float(*this, a, 1);
  }
  int operator > (cynw_cm_float<E,M,ACCURACY,ROUND,NaN> a) const {
    return cynw_cm_float_lt_cynw_cm_float(a, *this, 0);
  }
  int operator >= (cynw_cm_float<E,M,ACCURACY,ROUND,NaN> a) const {
    return cynw_cm_float_lt_cynw_cm_float(a, *this, 1);
  }


  /*
  ------------------------------------------------------------------------------
  Public member functions.
  ------------------------------------------------------------------------------
  */
  int to_int() const;
  long long to_int64() const;
  float to_float() const;
  double to_double() const;
  std::string to_string() const;
  

  sc_uint<n_raw_bits> raw_bits() const {
	  sc_uint<n_raw_bits> u; 
	  u = (sign, exp, man);
	  return u;
  }
  
  void raw_bits(const sc_uint<n_raw_bits> u) {
	  this->sign = u[E+M];
	  this->exp = u.range(E+M-1,M);
	  this->man = u.range(M-1,0);
  }

  sc_uint<n_raw_bits> to_rawBits() const {
	  return raw_bits();
  }
  
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> rawBitsToCynw_cm_float(sc_uint<n_raw_bits> u) const {
	  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;
	  res.raw_bits(u);
	  return res;
  }

#ifdef CYNTHHL
  float rawBitsTofloat(int pi) const;
#else
  float rawBitsTofloat(int pi) const {
	 float*  pf = reinterpret_cast<float*>(&pi);
	 return *pf;
  } 
#endif
  
#ifdef CYNTHHL
  int floatToRawBits(float pf) const;
#else
  int floatToRawBits(float pf) const{
	 int*  pi = reinterpret_cast<int*>(&pf);
	 return *pi;
  } 
#endif

#ifdef CYNTHHL
  double rawBitsTodouble(long long pi) const;
#else
  double rawBitsTodouble(long long pi) const {
	 double*  pf = reinterpret_cast<double*>(&pi);
	 return *pf;
  } 
#endif
  
#ifdef CYNTHHL
  long long doubleToRawBits(double pf) const;
#else
  long long doubleToRawBits(double pf) const {
	 long long*  pi = reinterpret_cast<long long*>(&pf);
	 return *pi;
  } 
#endif
  
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> sqrt() const ;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> recip() const ;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> rsqrt() const ;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> log2() const ;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> exp2() const ;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> sin() const ;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> cos() const ;

  // dot is our friend
template<const int E1, const int M1, const int ACCURACY1, const int ROUND1, const int NaN1>
friend cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> dot(
            const cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> & a0,
            const cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> & a1,
            const cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> & b0,
            const cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> & b1
        );
  
  // madd is our friend
template<const int E1, const int M1, const int ACCURACY1, const int ROUND1, const int NaN1>
friend cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> madd(
            const cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> & a,
            const cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> & b,
            const cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> & c
        );
  
  // When executing behavioral models generated by CMD in SC2.2 in a thread or cthread,
  // it is usually necessary to increase the stack size for the accessing thread.
  // Emit a NOTE message once during a simulation where this is the case.
  // There is no way to check the stack size programatically, so the message will 
  // be emitted whether or not the stack size has been set.
  static void stack_size_note()
  {
#if !defined(CYNTHESIZER) && ( SYSTEMC_VERSION >= 20070314 )
    if ( (sc_get_curr_process_kind() == SC_CTHREAD_PROC_) || (sc_get_curr_process_kind() == SC_THREAD_PROC_) ) {
        static bool emitted = false;
        if (!emitted) {
            emitted = true;
            fprintf( stderr, "**********************************************************************\n"
                             "* *NOTE: This simulation requires an increased SystemC stack size\n"
                             "*        because it uses cynw_cm_float in a behavioral simulation.\n"
                             "*        Be sure that you have added a set_stack_size() call after each\n"
                             "*        SC_CTHREAD statement for threads that access cynw_cm_float.\n"
                             "*        For example:\n"
                             "*          SC_CTHREAD(%s,clk.pos());\n"
                             "*          set_stack_size(0x100000);\n"
                             "*        If the default stack size is used, crashes may result during\n"
                             "*        simulation.\n"
                             "*************************************************************************\n",
                             sc_get_current_process_handle().name() );
       }
    }
#endif
  }
protected:  
  
/*
------------------------------------------------------------------------------
Routine to raise any or all of the software IEC/IEEE floating-point
exception flags.
------------------------------------------------------------------------------
*/
  void raise(cynw_cm_float_ex_flag_value flag) {
    this->ex.set(flag);
  }

  /*
  ------------------------------------------------------------------------------
  Internal member functions.
  ------------------------------------------------------------------------------
  */
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> cynw_cm_float_res(const sc_uint<1> zSign, const sc_uint<E> & zExp, const sc_uint<M> & zMan ) const;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> cynw_cm_float_inf(const sc_uint<1> zSign) const;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> cynw_cm_float_zero(const sc_uint<1> zSign) const;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> cynw_cm_float_default_NaN(  ) const;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> propagatecynw_cm_floatNaN(const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a, const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b) const;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> round_cynw_cm_float(sc_uint<1> zSign, sc_uint<E>  zExp, sc_uint<M>  zMan, 
                            	   const sc_uint<1> round, const sc_uint<1> sticky) const;
  sc_uint<LOG_MAX_M> normalize_cynw_cm_float_subnormal(sc_uint<M> *pSig) const;

  int cynw_cm_float_lt_cynw_cm_float(const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a, const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b, const sc_uint<1> eq) const;
  int cynw_cm_float_eq_cynw_cm_float(const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a, const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b, const sc_uint<1> noteq) const;

  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> cynw_cm_float_mul (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a, const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b) const;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> cynw_cm_float_add (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a, const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b, sc_uint<1> zSign) const;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> cynw_cm_float_div (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a, const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b) const;

  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> int_to_cynw_cm_float(const int a) const;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> ll_to_cynw_cm_float(const long long & a) const;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> float_to_cynw_cm_float(const float & f) const;
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> double_to_cynw_cm_float(const double & d) const;
  template<const int E1, const int M1, const int ACCURACY1, const int ROUND1, const int NaN1>
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> to_cynw_cm_float(const cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> & a) const;

  
  template<const int S>
  inline void shift_down_jamming(sc_uint<S> & a, sc_uint<E+1> count, sc_uint<S> *zPtr ) const
  {
      DPOPTINLINESMALL("shift_down_jamming");
	  sc_uint<S> z;
	  sc_uint<S> mask;
  
	  if (count >= S) {					// <<<<< sets to 0 if they are all shifted off
		  z = 0;	
	  }
	  else { 
		  z = a >> count;
		  mask = (sc_uint<S>)(~(sc_uint<S>)((~(sc_uint<S>)(0ll)) << count));	// same as above
		  z[0] |= ((a & mask) != 0);	// if any 1 bits are shifted off, set the low order bit
	  }
	  *zPtr = z;
  }

  
  template<const int S>
  inline unsigned count_leading_zeros(const sc_uint<S> & a) const {
    DPOPTINLINESMALL("countLeading0");
	sc_uint<LOG_BITS_PER_DOUBLE+1> i;			// log(max(S))+1, which is at least 6+1 (log(64)+1)

	/* note: this can be called with a=0 */
	for (i=0; i<S; i++) 
		if (a[S-1-(unsigned)i] == 1)
			break;
	return (unsigned)i;
  }

};




/*****************************************************************
		   the implementation
*****************************************************************/




/*
------------------------------------------------------------------------------
Produce a cynw_cm_float from sign, exp, man.
------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::cynw_cm_float_res(const sc_uint<1> zSign, const sc_uint<E> & zExp, const sc_uint<M> & zMan ) const {

  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res(zSign, zExp, zMan);

  return res;
}


/*
------------------------------------------------------------------------------
Produce an infinity cynw_cm_float with given sign.
------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::cynw_cm_float_inf(const sc_uint<1> zSign) const {

  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res(zSign, zESet, NaN ? (sc_uint<M>)0 : zMSet);

  return res;
}


/*
------------------------------------------------------------------------------
Produce a zero cynw_cm_float with given sign.
------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::cynw_cm_float_zero(const sc_uint<1> zSign) const {

  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res(zSign, (sc_uint<E>)0, (sc_uint<M>)0);

  return res;
}



/*
------------------------------------------------------------------------------
Produce a default NaN cynw_cm_float.
------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::cynw_cm_float_default_NaN(  ) const {

  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res((sc_uint<1>)0, zESet, zMSet);

  return res;
}



/*
------------------------------------------------------------------------------
Takes two cynw_cm_float floating-point values `a' and `b', one of which
is a NaN, and returns the appropriate NaN result.  If either `a' or `b' is a
signaling NaN, the invalid exception is raised.
------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::propagatecynw_cm_floatNaN(const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a, const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b) const {
	if (b.exp == zESet && b.man != 0) {
	    if (b.sign == 0 && b.man == zMSet)
	    	raise(cynw_ex_invalid);
	    return b;
	} else
	if (a.sign == 0 && a.man == zMSet)
		raise(cynw_ex_invalid);
	return a;
}




/*
------------------------------------------------------------------------------
Rounds the cynw_cm_float to the appropriate result.
------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::round_cynw_cm_float(sc_uint<1> zSign, sc_uint<E>  zExp, sc_uint<M>  zMan, 
												        const sc_uint<1> round, const sc_uint<1> sticky) const
{
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;
  exception_t zEx;
  
  if (ROUND == CYNW_NEAREST) {
	  if (round && (sticky || zMan[0])) {				// r & s or r & ~s & p0
		  if (zMan == zMSet) {	
		    if (NaN) {
			  zMan = 0;											
			  zExp++;
			  if (zExp == zESet) {					// notify if it became inf
				  zEx.set(cynw_ex_overflow);
			  }
			} else {
			  if (zExp != zESet) {
				zMan = 0;											
				zExp++;
			  }
			}
		  } else 
			  zMan++;		
		  zEx.set(cynw_ex_inexact);			// this gets set a lot
	  }
  } else
  if (ROUND == CYNW_NEGINF) {
	  if (zSign && (round || sticky)) {
		  if (zMan == zMSet) {	
		    if (NaN) {
			  zMan = 0;											
			  zExp++;
			  if (zExp == zESet) {					// notify if it became inf
				  zEx.set(cynw_ex_overflow);
			  }
			} else {
			  if (zExp != zESet) {
				zMan = 0;											
				zExp++;
			  }
			}
		  } else 
			  zMan++;		
		  zEx.set(cynw_ex_inexact);
	  }
  } else
  if (ROUND == CYNW_POSINF) {
	  if ((~zSign) && (round || sticky)) {
		  if (zMan == zMSet) {	
		    if (NaN) {
			  zMan = 0;											
			  zExp++;
			  if (zExp == zESet) {					// notify if it became inf
				  zEx.set(cynw_ex_overflow);
			  }
			} else {
			  if (zExp != zESet) {
				zMan = 0;											
				zExp++;
			  }
			}
		  } else 
			  zMan++;		
		  zEx.set(cynw_ex_inexact);
	  }
  }

  res.sign = zSign;
  res.exp = zExp;
  res.man = zMan;

  return res;
}




/*
-------------------------------------------------------------------------------
Normalizes the subnormal floating-point value represented
by the denormalized significand `aSig'. 
-------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline
sc_uint<LOG_MAX_M> cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::normalize_cynw_cm_float_subnormal(sc_uint<M> *pSig) const {

  sc_uint<LOG_MAX_M> shiftCount;		// this is log(Max M)
  
  shiftCount = count_leading_zeros<M>(*pSig);
  sc_uint<M> t = *pSig << shiftCount;
  *pSig = (t(M-2,0), 0);				// shift left one more
  return shiftCount;
}






/*
 *
 *	Conversions
 *
 */


/*
-------------------------------------------------------------------------------
Converts an int to a cynw_cm_float.
-------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::int_to_cynw_cm_float(const int a) const
{
  sc_uint<1> zSign;
  sc_uint<E> zExp;
  sc_uint<M> zMan;
  sc_uint<M+1> zManp1;
  sc_uint<CW_BITS_PER_INT> zSig;
  sc_uint<1> r, s;
  sc_int<LOG_BITS_PER_INT+1> lz, u, l;				// plus a sign bit
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;
  
 {CWF_DPOPT_CNV("int_to_cynw_cm_float");  
  if (a == 0) {
    zSign = 0;
    zExp = 0;
    zMan = 0;
    res = cynw_cm_float_res(zSign, zExp, zMan);
  } else
  if (a == 0x80000000) {
    zSign = 1;
    zExp = BIAS(E) + CW_BITS_PER_INT - 1;
    zMan = 0;
    res = cynw_cm_float_res(zSign, zExp, zMan);
  } else {
	zSign = (a < 0);
	zExp = BIAS(E);
	zSig = zSign ? -a : a;
	r = s = 0;
	
	lz = count_leading_zeros<CW_BITS_PER_INT>(zSig);
	u = CW_BITS_PER_INT-1-lz;
	l = (u-M > 0) ? u-M : 0;			// cynth_max((u-M, 0);
	zManp1 = zSig((int)u, (int)l);
	zExp += u;							// note: we don't check for overflow here. If the bias
	if (u > M) {						// is less than 31, then an int could overflow. That
	  r = zSig[(int)l-1];					// would happen if E<6.
	  if (l > 1) {
		s = zSig((int)l-2,0) == 0 ? 0 : 1;
	  }
	} else {
	  zManp1 = zManp1 << (M-u);
	} 

	zMan = zManp1(M-1,0);
	res = round_cynw_cm_float(zSign, zExp, zMan, (unsigned)r, (unsigned)s);
  }
  return res;
 }
}


/*
-------------------------------------------------------------------------------
Converts a long long to a cynw_cm_float.
-------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::ll_to_cynw_cm_float(const long long &a) const
{
  sc_uint<1> zSign;
  sc_uint<E> zExp;
  sc_uint<M> zMan;
  sc_uint<M+1> zManp1;
  sc_uint<CW_BITS_PER_DOUBLE> zSig;
  sc_uint<1> r, s;
  sc_int<LOG_BITS_PER_DOUBLE+1> lz, u, l;				// plus a sign bit

  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;
  
 {CWF_DPOPT_CNV("int64_to_cynw_cm_float");  
  if (a == 0) {
    zSign = 0;
    zExp = 0;
    zMan = 0;
    res = cynw_cm_float_res(zSign, zExp, zMan);
  } else
  if (a == 0x8000000000000000LL) {
    zSign = 1;
    zExp = BIAS(E) + CW_BITS_PER_DOUBLE - 1;
    zMan = 0;
    res = cynw_cm_float_res(zSign, zExp, zMan);
  } else {
	zSign = (a < 0);
	zExp = BIAS(E);
	zSig = zSign ? -a : a;
	r = s = 0;
	
	lz = count_leading_zeros<CW_BITS_PER_DOUBLE>(zSig);
	u = CW_BITS_PER_DOUBLE-1-lz;
	l = (u-M > 0) ? u-M : 0;
	zManp1 = zSig(u, l);
	if (u >= BIAS(E)) { 
	  zExp = zESet;
	  zMan = 0;
	  res = cynw_cm_float_res(zSign, zExp, zMan);
	} else {
	  zExp += u;
	  if (u > M) {
		r = zSig[l-1];
		if (l > 1) {
		  s = zSig(l-2,0) == 0 ? 0 : 1;
		}
	  } else {
		zManp1 = zManp1 << (M-u);
	  } 
  
	  zMan = zManp1(M-1,0);
	  res = round_cynw_cm_float(zSign, zExp, zMan, r, s);
	}

  }
  return res;
 }
}


/*
-------------------------------------------------------------------------------
Converts a float to a cynw_cm_float.
-------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::float_to_cynw_cm_float(const float & f) const
{
  cynw_cm_float<FLOAT_EXP,FLOAT_MAN,ACCURACY,ROUND,NaN> ff;
  sc_uint<CW_BITS_PER_INT> ireg;
  
  ireg = floatToRawBits(f);						// first, convert to cynw_cm_float<8,23>
  ff.sign = ireg[FLOAT_MAN+FLOAT_EXP];			
  ff.exp = ireg(FLOAT_MAN+FLOAT_EXP-1, FLOAT_MAN);
  ff.man = ireg(FLOAT_MAN-1, 0);
  if (!DENORM && ff.exp==0)
     if (ff.man[FLOAT_MAN-1]==0)				// it is too small
         ff.man = 0;
     else 
         ff.man <<= 1;							// our non-DENORM format is normalized
  
  return to_cynw_cm_float(ff);						// then convert to cynw_cm_float<E,M>
}


/*
-------------------------------------------------------------------------------
Converts a double to a cynw_cm_float.
(This will be used to synthesize constants.)
-------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::double_to_cynw_cm_float(const double & d) const 
{
  sc_uint<1> zSign;
  sc_uint<E> zExp;
  sc_uint<M> zMan;
  sc_uint<CW_BITS_PER_DOUBLE> ireg;
  sc_uint<DOUBLE_EXP> dexp;
  sc_uint<DOUBLE_MAN> dman;
  sc_uint<1> r, s;
  exception_t zEx;
  
  ireg = doubleToRawBits(d);
  zSign = ireg[DOUBLE_MAN+DOUBLE_EXP];
  dexp = ireg(DOUBLE_MAN+DOUBLE_EXP-1, DOUBLE_MAN);
  r = s = 0;

#if !defined(CYNTHESIZER)
  // Note: constants can't be NaN or Inf, so this isn't needed when cynthesizing
  if (NaN && dexp==BIAS(DOUBLE_EXP+1)) {						// it's a NaN or an Inf
  	  zExp = zESet;
  	  if (ireg(DOUBLE_MAN-1, 0) == 0)
  	      zMan = 0;												// infinity
  	  else
  	      zMan = zMSet;											// NaN
  } else
#endif
  if (NaN && DOUBLE_EXP > E && dexp > BIAS(E)+DOUBLE_BIAS) {	// overflow
  	  zExp = zESet;
  	  zMan = 0;
	  zEx.set(cynw_ex_inexact);
  } else 
  if (!NaN && DOUBLE_EXP > E && dexp > BIAS(E)+DOUBLE_BIAS+1) {	// overflow
  	  zExp = zESet;
  	  zMan = zMSet;
	  zEx.set(cynw_ex_inexact);
  } else 
  if (DOUBLE_EXP > E ? DOUBLE_BIAS-BIAS(E)-M > dexp : 0) {		// underflow
	  zExp = zMan = 0;											//  to 0
	  zEx.set(cynw_ex_inexact);
  } else 
  if (DOUBLE_EXP > E && !DENORM && dexp < DOUBLE_BIAS-BIAS(E)) {//  underflow
	  zExp = zMan = 0;											//  to 0
	  zEx.set(cynw_ex_inexact);
  } else {
      if (DOUBLE_EXP > E && DENORM && dexp <= DOUBLE_BIAS-BIAS(E)) {		// graceful underflow
          unsigned shift = (unsigned)(DOUBLE_BIAS-BIAS(E) - dexp);
          zExp = 0;
		  dman = ((sc_uint<1>)1,ireg(DOUBLE_MAN-1, 1));
          dman >>= shift;
      } else {
		  zExp  = dexp - DOUBLE_BIAS + BIAS(E);	
		  dman = ireg(DOUBLE_MAN-1, 0);
	  }
	  if (E > DOUBLE_EXP && dexp == 0) {		// it's a denorm, and the exponent range is larger
		  sc_uint<LOG_BITS_PER_DOUBLE> lz = count_leading_zeros<DOUBLE_MAN>(dman);
		  dman <<= lz+1; 						// denorm becomes normalized
	  }
	  if (M == DOUBLE_MAN)
	      zMan = dman;
	  else
	  if (M < DOUBLE_MAN) {
		  zMan  = dman(DOUBLE_MAN-1, DOUBLE_MAN-M);	// round the mantissa
		  r = dman[DOUBLE_MAN-M-1];
		  if (DOUBLE_MAN-M > 1) 
			s = dman(DOUBLE_MAN-M-2,0) == 0 ? 0 : 1;
		  else
		    s = 0;
		  zEx.set(cynw_ex_inexact);
	  } else
	  if (M > DOUBLE_MAN) {
		  zMan  = (dman, (sc_uint<M-DOUBLE_MAN>)0);	// pad mantissa on the right
	  }
  }

  if (M < DOUBLE_MAN)
      return round_cynw_cm_float(zSign, zExp, zMan, r, s );
  else
	  return cynw_cm_float_res(zSign, zExp, zMan);
}



/*
-------------------------------------------------------------------------------
Converts a cynw_cm_float to an int.
-------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline int cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::to_int() const
{
  int shiftCount;
  sc_uint<CW_BITS_PER_INT> zMan;
  int z;
  
 {CWF_DPOPT_CNV("cynw_cm_float_to_int");  
  shiftCount = exp - BIAS(E);
  if ((BIAS(E)<(CW_BITS_PER_INT-1)) && NaN && (exp == zESet))
	  z = sign ? 0x80000000 : 0x7FFFFFFF;
  else 
  if ((BIAS(E)>=(CW_BITS_PER_INT-1)) && (CW_BITS_PER_INT - 1) <= shiftCount)
	  z = sign ? 0x80000000 : 0x7FFFFFFF;
  else 
  if ( 0 <= shiftCount ) {
      if (M < CW_BITS_PER_INT-1) 							// get the mantissa, add the hidden bit
		  zMan = ((sc_uint<1>)1, man, (sc_uint<CW_BITS_PER_INT-M-1>)0);	// left justified
	  else
	      zMan = ((sc_uint<1>)1, man(M-1,M-CW_BITS_PER_INT+1)); // as much of the mantissa as will fit
	  z = zMan >> (sc_uint<LOG_BITS_PER_INT>)(CW_BITS_PER_INT-1-shiftCount);	// scale right
	  if (sign) z = - z;
  }
  else 	// shiftCount < 0
	  z = 0;
 }
  return z;
}



/*
-------------------------------------------------------------------------------
Converts a cynw_cm_float to a long long.
-------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline long long cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::to_int64() const
{
   int shiftCount;
   sc_uint<CW_BITS_PER_DOUBLE> zMan;
   long long z;

 {CWF_DPOPT_CNV("cynw_cm_float_to_int64");  
   shiftCount = exp - BIAS(E);
   if ((BIAS(E)<(CW_BITS_PER_DOUBLE-1)) && NaN && (exp == zESet))
      z = sign ? 0x8000000000000000LL : 0x7FFFFFFFFFFFFFFFLL;
   else
   if ((BIAS(E)>=(CW_BITS_PER_DOUBLE-1)) && (CW_BITS_PER_DOUBLE - 1) <= shiftCount)
      z = sign ? 0x8000000000000000LL : 0x7FFFFFFFFFFFFFFFLL;
   else
   if ( 0 <= shiftCount ) {
      if (M < CW_BITS_PER_DOUBLE-1) 				// get the mantissa, add the hidden bit
		  zMan = ((sc_uint<1>)1, man, (sc_uint<CW_BITS_PER_DOUBLE-1-M>)0);	// left justified
	  else
	      zMan = ((sc_uint<1>)1, man(M-1,M-CW_BITS_PER_DOUBLE+1));
	  z = zMan >> (sc_uint<LOG_BITS_PER_DOUBLE>)(CW_BITS_PER_DOUBLE-1-shiftCount);	// right justify
	  if (sign) z = - z;
   }
   else 	// shiftCount < 0
	  z = 0;
   return z;
 }
}





/*
-------------------------------------------------------------------------------
Converts a cynw_cm_float<1> to a cynw_cm_float<2>.
-------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
template<const int E1, const int M1, const int ACCURACY1, const int ROUND1, const int NaN1>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::to_cynw_cm_float(const cynw_cm_float<E1,M1,ACCURACY1,ROUND1,NaN1> & a) const
{
    /* Note: 
    	This code assumes that DENORM==DENORM1 and NaN==Nan1.
     */
     
    cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;
    sc_uint<M+2> zSig;
    sc_uint<(E1>E?E1:E)> shiftcount;				// this can be as big as the biggest exponent
    sc_uint<(E1>E?E1:E)> biasdiff;					// this is used to avoid compiler warnings
    
    sc_uint<1> needRounding = 0;
    
	// cynw_cm_float conversion requires DENORM and NaN template parameters of the source and sink to match 
#if !defined(CYNTHESIZER)   
	assert (DENORM1 == DENORM && NaN1 == NaN);
#endif

 {CWF_DPOPT_CNV("cynw_cm_float_to_cynw_cm_float");  
    res.sign = a.sign;			// sign is easy
    
    biasdiff = (E>E1) ? (BIAS(E)-BIAS(E1)) : (BIAS(E1)-BIAS(E));
    
	if (NaN && a.exp == ((sc_uint<E1>)((1<<E1)-1))) { // incoming is a NaN or inifinity
		res.exp = zESet;								// result is a NaN or inifinity
		if (M1>M) 
			res.man = (a.man==0) ? (sc_uint<M>)0 : (sc_uint<M>)((1<<M)-1);
		else
		if (M1==M)
			res.man = a.man;
		else
			res.man = (sc_uint<M>)(a.man, (sc_uint<M-M1>)0);
	} else
    if (E1 == E) {				// exponents are equal
		res.exp = a.exp;
		if (M1 == M)						// note: this case never happens, because the implicit
			res.man = a.man;				//       copy constructor is used instead when E==E1 and M==M1
		else
		if (M1 < M) {
			res.man = (sc_uint<M>) (a.man, (sc_uint<M-M1>)0);
		} else {
			if (M1-M == 1)
				res = round_cynw_cm_float(res.sign, res.exp, a.man(M1-1,M1-M), (sc_uint<1>)a.man[0], (sc_uint<1>)0);
			else
				res = round_cynw_cm_float(res.sign, res.exp, a.man(M1-1,M1-M), (sc_uint<1>)a.man[M1-M-1], (sc_uint<1>)(a.man(M1-M-2,0)!=0));
		}
    } else
    if (E1 < E) {							// result exponent field is bigger than source, no problems
		if (DENORM && a.exp == 0 && a.man > 0) {
			shiftcount = count_leading_zeros<M1>(a.man);
			if (shiftcount >= biasdiff)
			   res.exp = res.man = 0;
			else {									// the result is normalized
				res.exp = biasdiff - shiftcount;
				if (M1>M) {
					sc_uint<M1> tman = (sc_uint<M1>)(a.man << (shiftcount+1));
					zSig = (M1>M+1) ? tman(M1-1,M1-M-2) : sc_uint<M1+1>((tman, (sc_uint<1>)0));
					if (M1>M+2)
						zSig[0] = (sc_uint<1>)(tman(M1-M-2,0) != 0);
					needRounding = 1;
				} else {							// M1 <= M
					zSig = (((sc_uint<M1>)(a.man << shiftcount)), (sc_uint<M-M1+2>)0);
					res.man = zSig(M,1);				// omit leading 1, no rounding needed
				}
			}
		} else 
		if (a.exp == 0 && a.man == 0) {
			res.exp = res.man = 0;
		} else {										// not zero, not denorm
			res.exp = a.exp + biasdiff;		// new biased exponent
			if (M1>M) {
				zSig = (M1>M+1) ? a.man(M1-1,M1-M-2) : sc_uint<M1+1>((a.man, (sc_uint<1>)0));
				if (M1>M+2)
					zSig[0] = (sc_uint<1>)(a.man(M1-M-2,0) != 0);
				needRounding = 1;
			} else
			if (M1==M)
				res.man = a.man;
			else {
				res.man = (sc_uint<M>)(a.man, (sc_uint<M-M1>)0);
			}
		}
		if (needRounding)
			res = round_cynw_cm_float(res.sign, res.exp, zSig(M+1,2), (sc_uint<1>)zSig[1], (sc_uint<1>)zSig[0]);
    } else 
    {										// E < E1:  result exponent field is smaller than source
		if (a.exp > (BIAS(E) + BIAS(E1))) {			// it's too big
			res.exp = zESet;							// maximum exponent
			if (NaN)
				res.man = 0;							// infinity, not NaN
			else
				res.man = zMSet;						// just max
		} else
		if ((DENORM && a.exp <= biasdiff) || (!DENORM && a.exp < biasdiff)) {		// it's too small
			if (DENORM && a.exp==0) {
				if (biasdiff >= M) 
				   res.exp = res.man = 0;				// too small for denorm
				else {								// this is an uncommon case: biasdiff < M
				   shiftcount = count_leading_zeros<M1>(a.man);
				   if (shiftcount < M - biasdiff) {
					 res.exp = 0;
					 shiftcount = biasdiff + shiftcount;
					 if (M1>M) {
					   if (M1-M == 1)
						   zSig = (sc_uint<M+2>)(a.man(M1-1,M1-M-1), (sc_uint<1>)0);
					   else {
						   zSig = (sc_uint<M+2>)(a.man(M1-1,M1-M-2));
						   if (M1-M > 2)
							   zSig[0] = (sc_uint<1>)(a.man(M1-M-2,0) != 0);
					   }
					 } else
					 if (M1==M) {
						   zSig = (sc_uint<M+2>)(a.man(M1-1,0), (sc_uint<2>)0);
					 } else {
						 zSig = (sc_uint<M+2>)(a.man, (sc_uint<M-M1+2>)0);
					 }
					 shift_down_jamming<M+2>(zSig, shiftcount, &zSig);
					 needRounding = 1;
				   } else {
					 res.exp = res.man = 0;			// underflow
				   }
				}
			} else 
			if (DENORM) {							// source is not denorm, but result could be
				shiftcount = biasdiff - a.exp;
				if (shiftcount <= M) {					// it will fit as a denorm
				  res.exp = 0;
				  if (M1>M) {
					zSig = (sc_uint<M+2>)((sc_uint<1>)1, a.man(M1-1,M1-M-1));
					if (M1-M > 1) {
						zSig[0] |= (sc_uint<1>)(a.man(M1-M-2,0)!=0);
					}	
				  } else
				  if (M1==M) {
						zSig = (sc_uint<M+2>)((sc_uint<1>)1, a.man, (sc_uint<1>)0);
				  } else {
						zSig = (sc_uint<M+2>)((sc_uint<1>)1, a.man, (sc_uint<M-M1+1>)0);
				  }
				  shift_down_jamming<M+2>(zSig, shiftcount, &zSig);
				  needRounding = 1;
				} else 									// it won't fit as a denorm
				  res.exp = res.man = 0;				// underflow
			} else 									// too small, and not DENORM
				res.exp = res.man = 0;				// just underflow
		} else {										// normal case, not too small or too large
			res.exp = a.exp - biasdiff;					// new biased exponent
			if (M1>M) {
				if (M1-M == 1)
					zSig = (sc_uint<M+2>)(a.man, (sc_uint<1>)0);
				else {
					zSig = (sc_uint<M+2>)(a.man(M1-1,M1-M-2));
					if (M1-M>2)
						zSig[0] |= (sc_uint<1>)(a.man(M1-M-2,0) != 0);		// sticky bit
				}
				needRounding = 1;
			} else
			if (M1==M) {
				res.man = a.man;
			} else {
				res.man = (sc_uint<M>)(a.man, (sc_uint<M-M1>)0);
			}
		}
		if (needRounding)
			res = round_cynw_cm_float(res.sign, res.exp, zSig(M+1,2), (sc_uint<1>)zSig[1], (sc_uint<1>)zSig[0]);
    }
	return res;
 }
}




/*
-------------------------------------------------------------------------------
Converts a cynw_cm_float to a float.
(Not Cynthesizable)
-------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline float cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::to_float() const
{
    double t = to_double();
    float res = t;						// let the underlying hardware do all the work
    return res;
}


/*
-------------------------------------------------------------------------------
Converts a cynw_cm_float to a double.
(Not Cynthesizable)
-------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline double cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::to_double() const
{
  sc_uint<1> fsign;
  sc_uint<DOUBLE_MAN> fman;
  sc_uint<DOUBLE_EXP> fexp;
  long long ires;				
  unsigned lz;					
  
  								
#if !defined(CYNTHESIZER)   				// note: this relies on long long having the same number of bits as double
  assert (DOUBLE_EXP+DOUBLE_MAN+1 == (sizeof(ires)*8));
#endif

  fsign = sign;

  if (exp == 0 && (man == 0 || E > DOUBLE_EXP)) {
		ires = (fsign, (sc_uint<DOUBLE_EXP>)0, (sc_uint<DOUBLE_MAN>)0);
  } else
  if (!DENORM && exp == 0 && E == DOUBLE_EXP) {		
	  fexp = 0;							// convert our denorm format to IEEE denorm format
	  if (M >= DOUBLE_MAN-1) 			
		fman = ((sc_uint<1>)1,man(M-1,M-DOUBLE_MAN+1));
	  else 
		fman = ((sc_uint<1>)1, man, (sc_uint<DOUBLE_MAN-M-1>)0);
	  ires = (fsign, fexp, fman);
  } else
  if (DENORM && exp == 0) {				// handle regular denorms
	  if (DENORM && E < DOUBLE_EXP) {
		lz = count_leading_zeros<M>(man);
		sc_uint<M> tman = man << (lz+1);
		fexp = DOUBLE_BIAS > BIAS(E) ? DOUBLE_BIAS - BIAS(E) - lz : 0;
				// note: the above ugly code is there to avoid a warning
		if (M >= DOUBLE_MAN) 
		  fman = (sc_uint<DOUBLE_MAN>)(tman(M-1,M-DOUBLE_MAN));
		else 
		  fman = (tman, (sc_uint<DOUBLE_MAN-M>)0);
	  } else {							// E == DOUBLE_EXP
		if (M >= DOUBLE_MAN) 
		  fman = man(M-1,M-DOUBLE_MAN);
		else 
		  fman = (man, (sc_uint<DOUBLE_MAN-M>)0);
	  }
	  ires = (fsign, fexp, fman);
  }
  else if (NaN && exp == zESet) {  		// Handle NaN and Inf
	  if (man == 0) {      // Infinity
		fexp = (unsigned)~0;
		fman = 0;
		ires = (fsign, fexp, fman);
	  } else {     	 	// NaN
		fexp = (unsigned)~0;
		fman = ((unsigned long long)~0ll);
		ires = (fsign, fexp, fman);
	  } 
  }
  else {
	  // Normal computation
	  fexp = exp + DOUBLE_BIAS - BIAS(E);
#if !defined(CYNTHESIZER)   				// note: if E > DOUBLE_EXP, then the exponent could overflow
  	  assert (exp > BIAS(E) ? exp - BIAS(E) <= DOUBLE_BIAS : BIAS(E) - exp <= DOUBLE_BIAS);
#endif
	  if (M >= DOUBLE_MAN) {
		fman = man(M-1,M-DOUBLE_MAN);		// note that if M>DOUBLE_MAN, there is no rounding
	  }
	  else {
		fman = (man, (sc_uint<DOUBLE_MAN-M>)0);
	  }
	  ires = (fsign, fexp, fman);
  }
  return rawBitsTodouble(ires);
}


/*
-------------------------------------------------------------------------------
Converts a cynw_cm_float to a string.
(Not Cynthesizable)
-------------------------------------------------------------------------------
*/
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline std::string cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::to_string() const
{
	double d = (*this).to_double();
#ifdef SC_API_VERSION_STRING
        char buffer[64];
        std::string result;
        sprintf(buffer, "%f", d);
        result = buffer;
        return result;
#else
	return sc_string::to_string("%f", d);
#endif
}



/*
 *
 *	Relational Operators
 *
 */
 
/*
 *-----------------------------------------------------------------------------
 *	<, <=
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
int cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::cynw_cm_float_lt_cynw_cm_float(const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> &a, 
											const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> &b, const sc_uint<1> eq) const 
{
  sc_uint<1> aSign, bSign;
  sc_uint<1> res, notNaN, equal;
  
  equal = eq;
 {CWF_DPOPT_REL("cynw_cm_float_ltle");
  switch ((a.exp,a.man)) {
     case 0:
     	aSign = 0;				// comparisons ignore the sign of 0
     	break;
     default:
     	aSign = a.sign;
  }
  switch ((b.exp,b.man)) {
     case 0:
     	bSign = 0;				// comparisons ignore the sign of 0
     	break;
     default:
     	bSign = b.sign;
  }

  notNaN = 1;
  if (NaN) {  
	  if ((a.exp == zESet && a.man) || (b.exp == zESet && b.man)) 		// a or b is NaN
		  notNaN = 0;
  }
  if (aSign && !bSign)
    res = 1;
  else if (!aSign && bSign)
    res = 0;
  else 
  if (a.exp < b.exp) 
    res = !aSign;			// a < b if positive
  else
  if (b.exp < a.exp)
    res = aSign;			// a > b if positive
  else						// exp is the same, use mantissa
  if (a.man < b.man)
    res = !aSign;			// a < b if positive
  else
  if (b.man < a.man)
    res = aSign;			// a > b if positive
  else
	res = equal;			// a == b
  return res & notNaN;
 }
}
 


/*
 *-----------------------------------------------------------------------------
 *	==, !=
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
int cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::cynw_cm_float_eq_cynw_cm_float(const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> &a, 
											const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> &b, const sc_uint<1> noteq) const 
{
  sc_uint<1> aSign, bSign;
  sc_uint<1> res;
  
 {CWF_DPOPT_REL("cynw_cm_float_eq");
  switch ((a.exp,a.man)) {
     case 0:
     	aSign = 0;				// comparisons ignore the sign of 0
     	break;
     default:
     	aSign = a.sign;
  }
  switch ((b.exp,b.man)) {
     case 0:
     	bSign = 0;				// comparisons ignore the sign of 0
     	break;
     default:
     	bSign = b.sign;
  }
  if (NaN) {  
	  if (((a.exp == zESet) && a.man) || ((b.exp == zESet) && b.man)) {		// a or b is NaN
		  res = 0;
	  } else {
		  res = ((a.man == b.man) && (a.exp == b.exp) && (aSign == bSign));
	  }
  } else
	  res = ((a.man == b.man) && (a.exp == b.exp) && (aSign == bSign));
  return res ^ noteq;
 }
}


/*
 *-----------------------------------------------------------------------------
 *
 *	Mul
 *
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::cynw_cm_float_mul(
    const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a, 
	const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b ) const
{ 
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();

      sc_uint<n_raw_bits_ex> r;
      if ( ACCURACY == CYNW_REDUCED_ACCURACY ) {
          cynw_cm_float_mul_i<E,M,E,M,n_ex_bits> (a.sign,a.exp,a.man,b.sign,b.exp,b.man,r);
      } else {
          cynw_cm_float_mul_ieee_i<E,M,E,M,ROUND,NaN,n_ex_bits> (a.sign,a.exp,a.man,b.sign,b.exp,b.man,r);
      }
      res.sign = r[E+M];
      res.exp = r.range(E+M-1,M);
      res.man = r.range(M-1,0);
      return res;
  } else {
      res = double_to_cynw_cm_float( to_double() * b.to_double() );
      return res;
  }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY,
    const int ROUND, const int NaN>
inline 
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> mul (
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm,
        sc_uint<5>& ex )
{ 
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<E_RSLT+M_RSLT+1+res_t::n_ex_bits> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      if ( ACCURACY == CYNW_REDUCED_ACCURACY ) {
          cynw_cm_float_mul_i<E_RSLT,M_RSLT,E,M,res_t::n_ex_bits> (a.sign,a.exp,a.man,b.sign,b.exp,b.man,r);
      } else {
          cynw_cm_float_mul_ieee_i<E_RSLT,M_RSLT,E,M,ROUND,NaN,res_t::n_ex_bits> (a.sign,a.exp,a.man,b.sign,b.exp,b.man,r);
      }
      ex = res_t::exception_t::extract(r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {
      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( a.to_double() * b.to_double() );
      return res;
  }
}

//
// "mul" function with specified output widths and dynamic rounding mode.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> mul ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return mul<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, rm, ex );
} 


//
// "mul" function with specified output widths and exception output.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> mul ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        sc_uint<5>& ex )
{
    return mul<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
} 

//
// "mul" function with specified output widths.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> mul ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b )
{
    sc_uint<5> ex;
    return mul<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
} 

//
// "mul" function
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> mul ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b )
{
    sc_uint<5> ex;
    return mul<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
}

//
// "mul" function with exception output.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> mul ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        sc_uint<5>& ex)
{
  return mul<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
}

//
// "mul" function with dynamic rounding mode.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> mul ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return mul<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, rm, ex );
}


/*
 *-----------------------------------------------------------------------------
 *
 *	Add/Sub
 *
 *	Returns the result of adding the values of the floating-point values `a' and `b'. 
 *	The addition is performed according to the IEC/IEEE Standard for Binary 
 *	Floating-point Arithmetic. Will also do subtract.
 *
 *-----------------------------------------------------------------------------
 */
template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::cynw_cm_float_add (
    const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a, 
	const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b, 
	const sc_uint<1> subtractNotAdd) const
{
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;
  
  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<1> bsign;

      if ( subtractNotAdd ) {
          bsign = !b.sign;
      } else {
          bsign = b.sign;
      }
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      sc_uint<n_raw_bits_ex> r;
      if ( ACCURACY == CYNW_REDUCED_ACCURACY ) {
          cynw_cm_float_add_i<E,M,E,M,n_ex_bits> (a.sign,a.exp,a.man,bsign,b.exp,b.man,r);
      } else {
          cynw_cm_float_add_ieee_i<E,M,E,M,ROUND,NaN,n_ex_bits> (a.sign,a.exp,a.man,bsign,b.exp,b.man,r);
      }
      res.sign = r[E+M];
      res.exp = r.range(E+M-1,M);
      res.man = r.range(M-1,0);
      return res;
  } else {

      if ( subtractNotAdd ) {
          res = double_to_cynw_cm_float( to_double() - b.to_double() );
      } else {
          res = double_to_cynw_cm_float( to_double() + b.to_double() );
      }
      return res;
  }
}

//
// "add" function with all options.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> add ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm,
        sc_uint<5>& ex )
{
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<res_t::n_raw_bits_ex> r;

      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      if ( ACCURACY == CYNW_REDUCED_ACCURACY ) {
          cynw_cm_float_add_i<E_RSLT,M_RSLT,E,M,res_t::n_ex_bits> (a.sign,a.exp,a.man,b.sign,b.exp,b.man,r);
      } else {
          cynw_cm_float_add_ieee_i<E_RSLT,M_RSLT,E,M,ROUND,NaN,res_t::n_ex_bits> (a.sign,a.exp,a.man,b.sign,b.exp,b.man,r);
      }
      ex = res_t::exception_t::extract(r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {
      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( a.to_double() + b.to_double() );
      return res;
  }
}

//
// "add" function with specified output widths and dynamic rounding mode.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> add ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return add<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, rm, ex );
} 


//
// "add" function with specified output widths and exception output.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> add ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        sc_uint<5>& ex )
{
    return add<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
} 

//
// "add" function with specified output widths.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> add ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b )
{
    sc_uint<5> ex;
    return add<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
} 

//
// "add" function
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> add ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b )
{
    sc_uint<5> ex;
    return add<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
}

//
// "add" function with exception output.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> add ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        sc_uint<5>& ex)
{
  return add<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
}

//
// "add" function with dynamic rounding mode.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> add ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return add<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, rm, ex );
}


template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, 
    const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> sub (
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm,
        sc_uint<5>& ex )
{
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;
  sc_uint<1> bsign = !b.sign;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<E_RSLT+M_RSLT+1+res_t::n_ex_bits> r;

      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      if ( ACCURACY == CYNW_REDUCED_ACCURACY ) {
          cynw_cm_float_add_i<E_RSLT,M_RSLT,E,M,res_t::n_ex_bits> (a.sign,a.exp,a.man,bsign,b.exp,b.man,r);
      } else {
          cynw_cm_float_add_ieee_i<E_RSLT,M_RSLT,E,M,ROUND,NaN,res_t::n_ex_bits> (a.sign,a.exp,a.man,bsign,b.exp,b.man,r);
      }
      ex = res_t::exception_t::extract(r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {
      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( a.to_double() - b.to_double() );
      return res;
  }
}

//
// "sub" function with specified output widths and dynamic rounding mode.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> sub ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return sub<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, rm, ex );
} 


//
// "sub" function with specified output widths and exception output.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> sub ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        sc_uint<5>& ex )
{
    return sub<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
} 

//
// "sub" function with specified output widths.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> sub ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b )
{
    sc_uint<5> ex;
    return sub<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
} 

//
// "sub" function
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> sub ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b )
{
    sc_uint<5> ex;
    return sub<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
}

//
// "sub" function with exception output.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> sub ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        sc_uint<5>& ex)
{
  return sub<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
}

//
// "sub" function with dynamic rounding mode.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> sub ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return sub<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, rm, ex );
}


/*
 *-----------------------------------------------------------------------------
 *
 *	Div
 *  main routine
 *
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::cynw_cm_float_div (
    const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a, 
	const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b ) const
{ 
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<n_raw_bits> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_div_ieee_i<E,M,E,M,ROUND,NaN,n_ex_bits> (a.sign,a.exp,a.man,b.sign,b.exp,b.man,r);
      res.sign = r[E+M];
      res.exp = r.range(E+M-1,M);
      res.man = r.range(M-1,0);
      return res;
  } else {

      res = double_to_cynw_cm_float( to_double() / b.to_double() );
      return res;
  }
}


template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY,
    const int ROUND, const int NaN>
inline 
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> div (
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm,
        sc_uint<5>& ex )
{ 
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<E_RSLT+M_RSLT+1+res_t::n_ex_bits> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_div_ieee_i<E_RSLT,M_RSLT,E,M,ROUND,NaN,res_t::n_ex_bits> (a.sign,a.exp,a.man,b.sign,b.exp,b.man,r);
      ex = res_t::exception_t::extract(r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {
      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( a.to_double() / b.to_double() );
      return res;
  }
}

//
// "div" function with specified output widths and dynamic rounding mode.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> div ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return div<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, rm, ex );
} 


//
// "div" function with specified output widths and exception output.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> div ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        sc_uint<5>& ex )
{
    return div<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
} 

//
// "div" function with specified output widths.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> div ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b )
{
    sc_uint<5> ex;
    return div<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
} 

//
// "div" function
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> div ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b )
{
    sc_uint<5> ex;
    return div<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
}

//
// "div" function with exception output.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> div ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        sc_uint<5>& ex)
{
  return div<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, ROUND, ex );
}

//
// "div" function with dynamic rounding mode.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> div ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return div<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, rm, ex );
}


/*
 *-----------------------------------------------------------------------------
 *
 *	Sqrt
 *
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::sqrt () const
{ 
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      if ( ACCURACY == CYNW_REDUCED_ACCURACY ) {
          sc_uint<E+M+1> r;
          cynw_cm_float_sqrt_i<E,M,E,M> (sign,exp,man,r);
          res.sign = r[E+M];
          res.exp = r.range(E+M-1,M);
          res.man = r.range(M-1,0);
          return res;
      } else {
          // Note that sqrt differs from other ops that also have IEEE versions in that it
          // does not have an OutExWidth config param.  This is because sqrt also appears in other
          // modules, which would require that all of those also have OutExWidth.  
          sc_uint<n_raw_bits_ex> r;
          cynw_cm_float_sqrt_ieee_i<E,M,E,M,ROUND,NaN,n_ex_bits> (sign,exp,man,r);
          res.sign = r[E+M];
          res.exp = r.range(E+M-1,M);
          res.man = r.range(M-1,0);
          return res;
      }
  } else {

      res = double_to_cynw_cm_float( ::sqrt( to_double() ) );
      return res;
  }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY,
    const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> sqrt (
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const sc_uint<3> rm,
        sc_uint<5>& ex )
{
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      if ( ACCURACY == CYNW_REDUCED_ACCURACY ) {
          sc_uint<E_RSLT+M_RSLT+1> r;
          cynw_cm_float_sqrt_i<E_RSLT,M_RSLT,E,M> (a.sign,a.exp,a.man,r);
          res.sign = r[E_RSLT+M_RSLT];
          res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
          res.man = r.range(M_RSLT-1,0);
          return res;
      } else {
          // Note that sqrt differs from other ops that also have IEEE versions in that it
          // does not have an OutExWidth config param.  This is because sqrt also appears in other
          // modules, which would require that all of those also have OutExWidth.  
          sc_uint<E_RSLT+M_RSLT+1+res_t::n_ex_bits> r;
          cynw_cm_float_sqrt_ieee_i<E_RSLT,M_RSLT,E,M,ROUND,NaN,res_t::n_ex_bits> (a.sign,a.exp,a.man,r);
          ex = res_t::exception_t::extract(r);
          res.sign = r[E_RSLT+M_RSLT];
          res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
          res.man = r.range(M_RSLT-1,0);
          return res;
      }
  } else {
      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( ::sqrt( a.to_double() ) );
      return res;
  }
}

//
// "sqrt" function with specified output widths and dynamic rounding mode.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> sqrt ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return sqrt<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, rm, ex );
} 


//
// "sqrt" function with specified output widths and exception output.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> sqrt ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        sc_uint<5>& ex )
{
    return sqrt<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, ROUND, ex );
} 

//
// "sqrt" function with specified output widths.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> sqrt ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a )
{
    sc_uint<5> ex;
    return sqrt<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, ROUND, ex );
} 

//
// "sqrt" function
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> sqrt ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a )
{
    sc_uint<5> ex;
    return sqrt<E,M,E,M,ACCURACY,ROUND,NaN>( a, ROUND, ex );
}

//
// "sqrt" function with exception output.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> sqrt ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        sc_uint<5>& ex)
{
  return sqrt<E,M,E,M,ACCURACY,ROUND,NaN>( a, ROUND, ex );
}

//
// "sqrt" function with dynamic rounding mode.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> sqrt ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return sqrt<E,M,E,M,ACCURACY,ROUND,NaN>( a, rm, ex );
}

/*
 *-----------------------------------------------------------------------------
 *
 *	recip
 *
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::recip () const
{ 
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<n_raw_bits> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_recip_i<E,M,E,M> (sign,exp,man,r);
      res.sign = r[E+M];
      res.exp = r.range(E+M-1,M);
      res.man = r.range(M-1,0);
      return res;
  } else {

      res = double_to_cynw_cm_float( 1.0 / to_double() );
      return res;
  }
}

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> recip (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{ 
    return a.recip();
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY,
    const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> recip (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<E_RSLT+M_RSLT+1> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_recip_i<E_RSLT,M_RSLT,E,M> (a.sign,a.exp,a.man,r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {

      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( 1.0 / a.to_double() );
      return res;
  }
}

/*
 *-----------------------------------------------------------------------------
 *
 *	rsqrt
 *
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::rsqrt () const
{ 
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<n_raw_bits> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_rsqrt_i<E,M,E,M> (sign,exp,man,r);
      res.sign = r[E+M];
      res.exp = r.range(E+M-1,M);
      res.man = r.range(M-1,0);
      return res;
  } else {

      res = double_to_cynw_cm_float( 1.0 / ::sqrt( to_double() ) );
      return res;
  }
}

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> rsqrt (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{ 
    return a.rsqrt();
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY,
    const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> rsqrt (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<E_RSLT+M_RSLT+1> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_rsqrt_i<E_RSLT,M_RSLT,E,M> (a.sign,a.exp,a.man,r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {

      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( 1.0 / ::sqrt( a.to_double() ) );
      return res;
  }
}

/*
 *-----------------------------------------------------------------------------
 *
 *	log2
 *
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::log2 () const
{ 
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<n_raw_bits> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_log2_i<E,M,E,M> (sign,exp,man,r);
      res.sign = r[E+M];
      res.exp = r.range(E+M-1,M);
      res.man = r.range(M-1,0);
      return res;
  } else {

      res = double_to_cynw_cm_float( ::log( to_double())/::log((double)2) );
      return res;
  }
}

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> log2 (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{ 
    return a.log2();
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY,
    const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> log2 (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<E_RSLT+M_RSLT+1> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_log2_i<E_RSLT,M_RSLT,E,M> (a.sign,a.exp,a.man,r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {

      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( ::log( a.to_double())/::log((double)2) );
      return res;
  }
}

/*
 *-----------------------------------------------------------------------------
 *
 *	exp2
 *
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::exp2 () const
{ 
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<n_raw_bits> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_exp2_i<E,M,E,M> (sign,exp,man,r);
      res.sign = r[E+M];
      res.exp = r.range(E+M-1,M);
      res.man = r.range(M-1,0);
      return res;
  } else {

      res = double_to_cynw_cm_float( ::pow( 2, to_double() ) );
      return res;
  }
}

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> exp2 (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{ 
    return a.exp2();
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY,
    const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> exp2 (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<E_RSLT+M_RSLT+1> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_exp2_i<E_RSLT,M_RSLT,E,M> (a.sign,a.exp,a.man,r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {

      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( ::pow( 2, a.to_double() ) );
      return res;
  }
}

/*
 *-----------------------------------------------------------------------------
 *
 *	sin
 *
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::sin () const
{ 
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<n_raw_bits> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_sin_i<E,M,E,M> (sign,exp,man,r);
      res.sign = r[E+M];
      res.exp = r.range(E+M-1,M);
      res.man = r.range(M-1,0);
      return res;
  } else {

      res = double_to_cynw_cm_float( ::sin( to_double() ) );
      return res;
  }
}

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> sin (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{ 
    return a.sin();
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY,
    const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> sin (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<E_RSLT+M_RSLT+1> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_sin_i<E_RSLT,M_RSLT,E,M> (a.sign,a.exp,a.man,r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {

      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( ::sin( a.to_double() ) );
      return res;
  }
}

/*
 *-----------------------------------------------------------------------------
 *
 *	cos
 *
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::cos () const
{ 
  cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<n_raw_bits> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_cos_i<E,M,E,M> (sign,exp,man,r);
      res.sign = r[E+M];
      res.exp = r.range(E+M-1,M);
      res.man = r.range(M-1,0);
      return res;
  } else {

      res = double_to_cynw_cm_float( ::cos( to_double() ) );
      return res;
  }
}

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> cos (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{ 
    return a.cos();
}


template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY,
    const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> cos (const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a)
{
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<E_RSLT+M_RSLT+1> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_cos_i<E_RSLT,M_RSLT,E,M> (a.sign,a.exp,a.man,r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {

      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( ::cos( a.to_double() ) );
      return res;
  }
}

/*
 *-----------------------------------------------------------------------------
 *
 *	dot product
 *
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> dot (
            const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a0,
            const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a1,
            const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b0,
            const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b1
        ) 
{ 
  typedef cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<res_t::n_raw_bits> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_dot_i<E,M,E,M> (a0.sign,a0.exp,a0.man,
                                                                  a1.sign,a1.exp,a1.man,
                                                                  b0.sign,b0.exp,b0.man,
                                                                  b1.sign,b1.exp,b1.man,r);
      res.sign = r[E+M];
      res.exp = r.range(E+M-1,M);
      res.man = r.range(M-1,0);
      return res;
  } else {

      res = res.double_to_cynw_cm_float( ( a0.to_double() * a1.to_double() ) + ( b0.to_double() * b1.to_double() ) );
      return res;
  }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY,
    const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> dot (
            const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a0,
            const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a1,
            const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b0,
            const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b1
        ) 
{ 
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<E_RSLT+M_RSLT+1> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_dot_i<E_RSLT,M_RSLT,E,M> (a0.sign,a0.exp,a0.man,
                                                                  a1.sign,a1.exp,a1.man,
                                                                  b0.sign,b0.exp,b0.man,
                                                                  b1.sign,b1.exp,b1.man,r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {

      res = cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN>( ( a0.to_double() * a1.to_double() ) + ( b0.to_double() * b1.to_double() ) );
      return res;
  }
}

/*
 *-----------------------------------------------------------------------------
 *
 *	Multiply and add
 *
 *-----------------------------------------------------------------------------
 */

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> madd (
            const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
            const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
            const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & c
        ) 
{ 
  typedef cynw_cm_float<E,M,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<res_t::n_raw_bits_ex> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_madd_ieee_i<E,M,E,M,ROUND,NaN> (a.sign,a.exp,a.man,
                                          b.sign,b.exp,b.man,
                                          c.sign,c.exp,c.man,
					  r);
      res.sign = r[E+M];
      res.exp = r.range(E+M-1,M);
      res.man = r.range(M-1,0);
      return res;
  } else {

      res = res.double_to_cynw_cm_float( ( a.to_double() * b.to_double() ) + c.to_double() );
      return res;
  }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY,
    const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> madd (
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & c,
        const sc_uint<3> rm,
        sc_uint<5>& ex )
{ 
  typedef cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> res_t;
  res_t res;

  if ( ACCURACY != CYNW_NATIVE_ACCURACY ) {
      sc_uint<E_RSLT+M_RSLT+1+res_t::n_ex_bits> r;
      cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::stack_size_note();
      cynw_cm_float_madd_ieee_i<E_RSLT,M_RSLT,E,M,ROUND,NaN,res_t::n_ex_bits> (a.sign,a.exp,a.man,
							      b.sign,b.exp,b.man,
							      c.sign,c.exp,c.man,
							      r);
      ex = res_t::exception_t::extract(r);
      res.sign = r[E_RSLT+M_RSLT];
      res.exp = r.range(E_RSLT+M_RSLT-1,M_RSLT);
      res.man = r.range(M_RSLT-1,0);
      return res;
  } else {

      res = res.double_to_cynw_cm_float( ( a.to_double() * b.to_double() ) + c.to_double() );
      return res;
  }
}

//
// "madd" function with specified output widths and dynamic rounding mode.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> madd ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & c,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return madd<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, c, rm, ex );
} 


//
// "madd" function with specified output widths and exception output.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> madd ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & c,
        sc_uint<5>& ex )
{
    return madd<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, c, ROUND, ex );
} 

//
// "madd" function with specified output widths.
//
template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E_RSLT,M_RSLT,ACCURACY,ROUND,NaN> madd ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & c )
{
    sc_uint<5> ex;
    return madd<E_RSLT,M_RSLT,E,M,ACCURACY,ROUND,NaN>( a, b, c, ROUND, ex );
} 

//
// "madd" function with exception output.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> madd ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & c,
        sc_uint<5>& ex)
{
  return madd<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, c, ROUND, ex );
}

//
// "madd" function with dynamic rounding mode.
//
template<const int E, const int M, const int ACCURACY, const int ROUND, const int NaN>
inline
cynw_cm_float<E,M,ACCURACY,ROUND,NaN> madd ( 
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & a,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & b,
        const cynw_cm_float<E,M,ACCURACY,ROUND,NaN> & c,
        const sc_uint<3> rm )
{
    sc_uint<5> ex;
    return madd<E,M,E,M,ACCURACY,ROUND,NaN>( a, b, c, rm, ex );
}

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
void sc_trace( sc_trace_file* tf, 
               const cynw_cm_float<E,M,ACCURACY,ROUND,NaN>& port, 
#ifdef SC_API_VERSION_STRING
               const std::string& name ) 
#else
               const sc_string& name ) 
#endif
{ 
#if !defined(CYNTHESIZER)
  if(tf){
    sc_trace( tf, port.sign, name + std::string(".sign") );
    sc_trace( tf, port.exp, name + std::string(".exp") );
    sc_trace( tf, port.man, name + std::string(".man") );
  }
#endif
}


template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline 
ostream& operator << ( ostream& os, const cynw_cm_float<E,M,ACCURACY,ROUND,NaN>& a) 
{ 
   // Some code to dump your variable to "os" via << operators. 
   os << a.to_double() ;
   return os; 
} 


template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline void cynw_interpret(const sc_uint<cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::n_raw_bits>& from, cynw_cm_float<E,M,ACCURACY,ROUND,NaN>& to)
{
  to.raw_bits(from);
}

template<const int E, const int M, const int ACCURACY,  const int ROUND, const int NaN>
inline void cynw_interpret(const cynw_cm_float<E,M,ACCURACY,ROUND,NaN>& from, sc_uint<cynw_cm_float<E,M,ACCURACY,ROUND,NaN>::n_raw_bits>& to)
{
  to = from.raw_bits();
}



#undef X

#endif // cynw_cm_float_int_H_INCLUDED
