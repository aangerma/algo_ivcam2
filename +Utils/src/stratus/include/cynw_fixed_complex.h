/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/
#if !defined(cynw_fixed_complex_h_included)
#define cynw_fixed_complex_h_included

#include "cynw_fixed.h"
#include "cynw_complex"

#if defined STRATUS 
#pragma hls_ip_def
#endif	

//#define TAG {cout << "!!!!!!!! " << __FILE__ << ":" << __LINE__ << endl; }
#define TAG
//==============================================================================
//
// SOME HELPFUL MACROS:
//
//==============================================================================

// SIGNED:

#ifdef CWCX_COMPLEX
#   error conflict for define CWCX_COMPLEX detected!!!
#endif
#define CWCX_COMPLEX cynw::complex<cynw_fixed<W,I,Q_MODE,O_MODE,N_BITS> >

#ifdef CWCX_COMPLEX1
#   error conflict for define CWCX_COMPLEX1 detected!!!
#endif
#define CWCX_COMPLEX1 \
	cynw::complex<cynw_fixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> >

// UNSIGNED:

#ifdef CYNW_FX_U_COMPLEX
#   error conflict for define CYNW_FX_U_COMPLEX detected!!!
#endif
#define CYNW_FX_U_COMPLEX cynw::complex<cynw_ufixed<W,I,Q_MODE,O_MODE,N_BITS> >

#ifdef CYNW_FX_U_COMPLEX1
#   error conflict for define CYNW_FX_U_COMPLEX1 detected!!!
#endif
#define CYNW_FX_U_COMPLEX1 \
	cynw::complex<cynw_ufixed<W1,I1,Q_MODE1,O_MODE1,N_BITS1> >

#define CWFX_COMPLEX_DIVU(W,I,W1,I1) \
	cynw::complex<cynw_ufixed<W+W1+1,I+I1+1>

// RESULT TYPES FOR MATH OPERATIONS: 
//
// The postfixes on these macros specify the signedness of the operands:
//       _SS - signed op signed
//       _SU - signed op unsigned
//       _US - unsigned op signed
//       _UU - unsigned op unsigned


#define CWCX_ADD_SS(Wa,Ia,Wb,Ib) cynw::complex<CWFX_ADD_SS(Wa,Ia,Wb,Ib) >
#define CWCX_ADD_SU(Wa,Ia,Wb,Ib) cynw::complex<CWFX_ADD_SU(Wa,Ia,Wb,Ib) >
#define CWCX_ADD_US(Wa,Ia,Wb,Ib) cynw::complex<CWFX_ADD_US(Wa,Ia,Wb,Ib) >
#define CWCX_ADD_UU(Wa,Ia,Wb,Ib) cynw::complex<CWFX_ADD_UU(Wa,Ia,Wb,Ib) >

#define CWCX_DIV(Wa,Ia,Wb,Ib) cynw::complex<CWFX_DIV(Wa,Ia,Wb,Ib) >
#define CWCX_DIVM(Wa,Ia,Wb,Ib) cynw::complex<CWFX_DIV(Wa,Ia,Wb,Ib) >
#define CWCX_DIVU(Wa,Ia,Wb,Ib) cynw::complex<CWFX_DIVU(Wa,Ia,Wb,Ib) >

#define CWCX_MUL_SS(Wa,Ia,Wb,Ib) \
    cynw::complex<cynw_fixed<Wa+Wb+1,Ia+Ib+1,Q_MODE,CYNW_RES_O_MODE,N_BITS> >
#define CWCX_MUL_SU(Wa,Ia,Wb,Ib) \
    cynw::complex<cynw_fixed<Wa+Wb+2,Ia+Ib+2,Q_MODE,CYNW_RES_O_MODE,N_BITS> >
#define CWCX_MUL_US(Wa,Ia,Wb,Ib) \
    cynw::complex<cynw_fixed<Wa+Wb+2,Ia+Ib+2,Q_MODE,CYNW_RES_O_MODE,N_BITS> >
#define CWCX_MUL_UU(Wa,Ia,Wb,Ib) \
    cynw::complex<cynw_ufixed<Wa+Wb+1,Ia+Ib+1,Q_MODE,CYNW_RES_O_MODE,N_BITS> >

#define CWCX_SUB_SS(Wa,Ia,Wb,Ib) cynw::complex<CWFX_SUB_SS(Wa,Ia,Wb,Ib) >
#define CWCX_SUB_SU(Wa,Ia,Wb,Ib) cynw::complex<CWFX_SUB_SU(Wa,Ia,Wb,Ib) >
#define CWCX_SUB_US(Wa,Ia,Wb,Ib) cynw::complex<CWFX_SUB_US(Wa,Ia,Wb,Ib) >
#define CWCX_SUB_UU(Wa,Ia,Wb,Ib) cynw::complex<CWFX_SUB_UU(Wa,Ia,Wb,Ib) >

namespace cynw {

// +============================================================================
// | complex<cynw_fixed<W,I,Q_M,O_MODE,N_B> > - fixed point complex class
// +============================================================================
CWFX_TEMPLATE
class complex<CWFX_FIXED >
{
  public: // typdefs:
    typedef CWFX_FIXED          target_type;
    typedef complex<CWFX_FIXED> this_type;

  public: // constructor and destructor:
    complex( const target_type& real = target_type(), 
             const target_type& imag = target_type() );
    template<typename _REAL, typename _IMAG>
    complex( const _REAL& real, const _IMAG& imag );
    template<typename T1>
    complex( const cynw::complex<T1>& other );
    ~complex() {}

  public: // field access:
    const target_type&       imag() const { return m_imag; }
    target_type&             imag()       { return m_imag; }
    const target_type&       real() const { return m_real; }
    target_type&             real()       { return m_real; }
    const complex& rep() const { return *this; }

  public: // self referencing operators using the this object's data type.
    const this_type& operator =  ( const target_type& value );
    const this_type& operator += ( const target_type& value );
    const this_type& operator -= ( const target_type& value );
    const this_type& operator *= ( const target_type& value );
    const this_type& operator /= ( const target_type& value );

  public: // self referencing operators using another data type.
    template< typename OTHER>
    const this_type& operator =  ( const OTHER& value )
        { 
	    m_real = (const target_type)value; 
	    m_imag = (const target_type)0; 
	    return *this; 
        }
    template< typename OTHER>
    const this_type& operator += ( const OTHER& value )
        { *this = *this + value; return *this; }
    template< typename OTHER>
    const this_type& operator -= ( const OTHER& value )
        { *this = *this - value; return *this; }
    template< typename OTHER>
    const this_type& operator *= ( const OTHER& value )
        { *this = *this * value; return *this; }
    template< typename OTHER>
    const this_type& operator /= ( const OTHER& value )
        { TAG *this = *this / value; return *this; }

  public: // self referencing operators using the another complex's data type.
    template< typename OTHER>
    const this_type& operator = ( const cynw::complex<OTHER>& other );
    template< typename OTHER>
    const this_type& operator += ( const cynw::complex<OTHER>& other );
    template< typename OTHER>
    const this_type& operator -= ( const cynw::complex<OTHER>& other );
    template< typename OTHER>
    const this_type& operator *= ( const cynw::complex<OTHER>& other );
    template< typename OTHER>
    const this_type& operator /= ( const cynw::complex<OTHER>& other );
   
  public:
    target_type m_imag; // imaginary component of value.
    target_type m_real; // real component of value.
};

// +============================================================================
// | complex<cynw_ufixed<W,I,Q_M,O_MODE,N_B> > - fixed point complex class
// +============================================================================
CWFX_TEMPLATE
class complex<CWFX_UFIXED >
{
  public: // typdefs:
    typedef CWFX_UFIXED          target_type;
    typedef CYNW_FX_U_COMPLEX this_type;

  public: // constructor and destructor:
    complex( const target_type& real = target_type(), 
             const target_type& imag = target_type() );
    template<typename _REAL, typename _IMAG>
    complex( const _REAL& real, const _IMAG& imag );
    template<typename T1>
    complex( const cynw::complex<T1>& other );
    ~complex() {}

  public: // field access:
    const target_type&       imag() const { return m_imag; }
    target_type&             imag()       { return m_imag; }
    const target_type&       real() const { return m_real; }
    target_type&             real()       { return m_real; }
    const complex& rep() const { return *this; }

  public: // self referencing operators using the this object's data type.
    const this_type& operator =  ( const target_type& value );
    const this_type& operator += ( const target_type& value );
    const this_type& operator -= ( const target_type& value );
    const this_type& operator *= ( const target_type& value );
    const this_type& operator /= ( const target_type& value );

  public: // self referencing operators using another data type.
    template< typename OTHER>
    const this_type& operator =  ( const OTHER& value )
        { 
	    m_real = (const target_type)value; 
	    m_imag = (const target_type)0; 
	    return *this; 
        }
    template< typename OTHER>
    const this_type& operator += ( const OTHER& value )
        { *this = *this + value; return *this; }
    template< typename OTHER>
    const this_type& operator -= ( const OTHER& value )
        { *this = *this - value; return *this; }
    template< typename OTHER>
    const this_type& operator *= ( const OTHER& value )
        { *this = *this * value; return *this; }
    template< typename OTHER>
    const this_type& operator /= ( const OTHER& value )
        { TAG *this = *this / value; return *this; }

  public: // self referencing operators using the another object's data type.
    template< typename OTHER>
    const this_type& operator = ( const cynw::complex<OTHER>& other );
    template< typename OTHER>
    const this_type& operator += ( const cynw::complex<OTHER>& value );
    template< typename OTHER>
    const this_type& operator -= ( const cynw::complex<OTHER>& value );
    template< typename OTHER>
    const this_type& operator *= ( const cynw::complex<OTHER>& value );
    template< typename OTHER>
    const this_type& operator /= ( const cynw::complex<OTHER>& value );
   
  public:
    target_type m_imag; // imaginary component of value.
    target_type m_real; // real component of value.
};

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::complex - components"
// | 
// | This is the object instance constructor for this class that takes 
// | component values.
// |
// | Arguments:
// |     real = real value.
// |     imag = imaginary value.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
inline CWCX_COMPLEX::complex( const CWFX_FIXED& real, const CWFX_FIXED& imag ) : 
    m_imag(imag), m_real(real)
{
}

CWFX_TEMPLATE
template<typename _REAL, typename _IMAG>
inline CWCX_COMPLEX::complex( const _REAL& real, 
                                                       const _IMAG& imag ) 
{
    m_real = real;
    m_imag = imag;
}

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::complex - other complex type"
// | 
// | This is the object instance constructor for this class that takes 
// | another complex type.
// |
// | Arguments:
// |     other = other complex type.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template<typename T1>
inline 
CWCX_COMPLEX::complex(const complex<T1>& other ) :
    m_imag(other.imag()), m_real(other.real())
{
}

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::operator = this component type"
// | 
// | This is the assignment operator for a component value of this type.
// |
// | Arguments:
// |     value = CWCX_COMPLEX value to assign this object instance to.
// | Result is a const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
const CWCX_COMPLEX& 
CWCX_COMPLEX::operator = ( const CWFX_FIXED& value )
{
    m_imag = CWFX_FIXED ();
    m_real = value;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::operator = complex type"
// | 
// | This is the assignment operator for a value of a complex type.
// |
// | Arguments:
// |     value = complex<OTHER> value to assign this object instance to.
// | Result is a const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template < typename OTHER >
const CWCX_COMPLEX& 
CWCX_COMPLEX::operator = ( const complex<OTHER>& value )
{
    m_imag = (const target_type)value.imag();
    m_real = (const target_type)value.real();
    return *this;
}

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::operator += component type"
// | 
// | This operator adds the supplied component instance to this object instance.
// | This only changes the real component of this object instance.
// |
// | Arguments:
// |     value = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
const CWCX_COMPLEX& 
CWCX_COMPLEX::operator += ( const CWFX_FIXED & value )
{
    m_real += value;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::operator += other complex instance"
// | 
// | This operator adds the supplied complex instance to this object instance.
// | This results in changes to both the real and imaginary components of this
// | object instance.
// |
// | Arguments:
// |     value = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template< typename OTHER >
const CWCX_COMPLEX& 
CWCX_COMPLEX::operator += ( const complex<OTHER>& value )
{
    m_real += value.real();
    m_imag += value.imag();
    return *this;
}

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::operator -= component type"
// | 
// | This operator adds the supplied component instance from this object 
// | instance. This only changes the real component of this object instance.
// |
// | Arguments:
// |     value = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
const CWCX_COMPLEX& 
CWCX_COMPLEX::operator -= ( const CWFX_FIXED & value )
{
    m_real -= value;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::operator -= other complex instance"
// | 
// | This operator subtracts the supplied complex instance from this object 
// | instance. This results in changes to both the real and imaginary components
// | of this object instance.
// |
// | Arguments:
// |     value = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template< typename OTHER >
const CWCX_COMPLEX& 
CWCX_COMPLEX::operator -= ( const complex<OTHER>& value )
{
    m_real -= value.real();
    m_imag -= value.imag();
    return *this;
}

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::operator *= component type"
// | 
// | This operator multiplies the supplied component instance from this object 
// | instance. This changes the both components of this object instance.
// |
// | Arguments:
// |     value = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
const CWCX_COMPLEX& 
CWCX_COMPLEX::operator *= ( const CWFX_FIXED & value )
{
    m_imag *= value;
    m_real *= value;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::operator *= other complex instance"
// | 
// | This operator multiplies the supplied complex instance from this object 
// | instance. This results in changes to both the real and imaginary components
// | of this object instance. The order of the assignments below is important!
// |
// | Arguments:
// |     other = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template< typename OTHER >
const CWCX_COMPLEX& CWCX_COMPLEX::operator *= ( 
                                                  const complex<OTHER>& other )
{
    const target_type real = m_real * other.real() - m_imag * other.imag();
    m_imag = m_real * other.imag() + m_imag * other.real();
    m_real = real;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::operator /= component type"
// | 
// | This operator divides this object instance by the  supplied component 
// | instance. This changes the both components of this object instance.
// |
// | Arguments:
// |     other = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
const CWCX_COMPLEX& 
CWCX_COMPLEX::operator /= ( const CWFX_FIXED & other )
{
    TAG
    m_imag /= other;
    m_real /= other;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CWCX_COMPLEX::operator /= other complex instance"
// | 
// | This operator divides this object instance by the supplied complex 
// | instance. This results in changes to both the real and imaginary components
// | of this object instance. The order of the assignments below is important!
// |
// | Arguments:
// |     other = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template< typename OTHER >
const CWCX_COMPLEX& 
CWCX_COMPLEX::operator /= ( const complex<OTHER>& other )
{
    TAG
    const target_type norm = other.real()*other.real() + 
                             other.imag()*other.imag();
    const target_type real = m_real * other.real() + m_imag * other.imag();
    m_imag = (m_imag * other.real() - m_real * other.imag()) / norm;
    m_real = real;
    return *this;
}


// +----------------------------------------------------------------------------
// |"complex + complex"
// | 
// | These operator overloads perform the mulitplication of two complex values.
// |
// | Arguments:
// |     left  = left operand for the multiplication (complex).
// |     right = right operand for the multiplication (complex).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Complex Signed + Complex Signed: non-matching and matching template cases

CWFX_TEMPLATE
inline 
CWCX_ADD_SS(W,I,W,I) 
operator + ( const CWCX_COMPLEX& left, const CWCX_COMPLEX& right )
{
    CWCX_ADD_SS(W,I,W,I) result;

    result.m_real = left.m_real + right.m_real;
    result.m_imag = left.m_imag + right.m_imag;

    return result;
}
  
CWFX_TEMPLATE2
inline 
CWCX_ADD_SS(W,I,W1,I1) 
operator + ( const CWCX_COMPLEX& left, const CWCX_COMPLEX1& right )
{
    CWCX_ADD_SS(W,I,W1,I1)  result;

    result.m_real = left.m_real + right.m_real;
    result.m_imag = left.m_imag + right.m_imag;

    return result;
}
  
// Complex Unsigned + Complex Signed:
//
// (Extra bit for unsigned value sign extension)

CWFX_TEMPLATE2
inline 
CWCX_ADD_US(W,I,W1,I1) 
operator + ( const CYNW_FX_U_COMPLEX& left, const CWCX_COMPLEX1& right )
{
    CWCX_ADD_US(W,I,W1,I1) result;

    result.m_real = left.m_real + right.m_real;
    result.m_imag = left.m_imag + right.m_imag;

    return result;
}
  
// Complex Signed + Complex Unsigned:
//
// (Extra bit for unsigned value sign extension)

CWFX_TEMPLATE2
inline 
CWCX_ADD_SU(W,I,W1,I1)
operator + ( const CWCX_COMPLEX& left, const CYNW_FX_U_COMPLEX1& right )
{
    CWCX_ADD_SU(W,I,W1,I1) result;

    result.m_real = left.m_real + right.m_real;
    result.m_imag = left.m_imag + right.m_imag;

    return result;
}
  
// Complex Unsigned + Complex Unsigned: non-matching and matching template cases

CWFX_TEMPLATE2
inline 
CWCX_ADD_UU(W,I,W1,I1)
operator + ( const CYNW_FX_U_COMPLEX& left, const CYNW_FX_U_COMPLEX1& right )
{
    CWCX_ADD_UU(W,I,W1,I1) result;

    result.m_real = left.m_real + right.m_real;
    result.m_imag = left.m_imag + right.m_imag;

    return result;
}

CWFX_TEMPLATE
inline
CWCX_ADD_SS(W,I,W,I)
operator + ( const CYNW_FX_U_COMPLEX& left, const CYNW_FX_U_COMPLEX& right )
{
    CWCX_ADD_SS(W,I,W,I) result;

    result.m_real = left.m_real + right.m_real;
    result.m_imag = left.m_imag + right.m_imag;

    return result;
}
  

// +----------------------------------------------------------------------------
// |"complex + fixed"
// | 
// | These operator overloads perform the mulitplication of a complex value
// | times a fixed point number.
// |
// | Arguments:
// |     left  = left operand for the multiplication (complex).
// |     right = right operand for the multiplication (fixed).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Complex Signed + Signed: non-matching and matching template cases

CWFX_TEMPLATE2
inline CWCX_ADD_SS(W,I,W1,I1) 
operator + ( const CWCX_COMPLEX& left, const CWFX_FIXED1& right )
{
    CWCX_ADD_SS(W,I,W1,I1) result;

    result.m_real = left.m_real + right;
    result.m_imag = left.m_imag;

    return result;
}
  
CWFX_TEMPLATE
inline CWCX_ADD_SS(W,I,W,I)
operator + ( const CWCX_COMPLEX& left, const CWFX_FIXED& right )
{
    CWCX_ADD_SS(W,I,W,I) result;

    result.m_real = left.m_real + right;
    result.m_imag = left.m_imag;

    return result;
}
  
// Complex Unsigned + Signed:

CWFX_TEMPLATE2
inline CWCX_ADD_US(W,I,W1,I1)
operator + ( const CYNW_FX_U_COMPLEX& left, const CWFX_FIXED1& right )
{
    CWCX_ADD_US(W,I,W1,I1) result;

    result.m_real = left.m_real + right;
    result.m_imag = left.m_imag;

    return result;
}
  
// Complex Signed + Unsigned:

CWFX_TEMPLATE2
inline CWCX_ADD_SU(W,I,W1,I1)
operator + ( const CWCX_COMPLEX& left, const CWFX_UFIXED1& right )
{
    CWCX_ADD_SU(W,I,W1,I1) result;

    result.m_real = left.m_real + right;
    result.m_imag = left.m_imag;

    return result;
}
  
// Complex Unsigned + Unsigned: non-matching and matching template cases

CWFX_TEMPLATE2
inline 
CWCX_ADD_SS(W,I,W1,I1)
operator + ( const CYNW_FX_U_COMPLEX& left, const CWFX_UFIXED1& right )
{
    CWCX_ADD_SS(W,I,W1,I1) result;

    result.m_real = left.m_real + right;
    result.m_imag = left.m_imag;

    return result;
}

CWFX_TEMPLATE
inline 
CWCX_ADD_SS(W,I,W,I)
operator + ( const CYNW_FX_U_COMPLEX& left, const CWFX_UFIXED& right )
{
    CWCX_ADD_SS(W,I,W,I) result;

    result.m_real = left.m_real + right;
    result.m_imag = left.m_imag;

    return result;
}

// +----------------------------------------------------------------------------
// |"fixed + complex"
// | 
// | These operator overloads perform the mulitplication of a fixed point
// | number times a complex value.
// |
// | Arguments:
// |     left  = left operand for the multiplication (fixed).
// |     right = right operand for the multiplication (complex).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Signed + Complex Signed: non-matching and matching template cases

CWFX_TEMPLATE2
inline 
CWCX_ADD_SS(W,I,W1,I1)
operator + ( const CWFX_FIXED& left, const CWCX_COMPLEX1& right )
{
    CWCX_ADD_SS(W,I,W1,I1) result;

    result.m_real = left + right.m_real;
    result.m_imag = right.m_imag;

    return result;
}
  
CWFX_TEMPLATE
inline 
CWCX_ADD_SS(W,I,W,I)
operator + ( const CWFX_FIXED& left, const CWCX_COMPLEX& right )
{
    CWCX_ADD_SS(W,I,W,I) result;

    result.m_real = left + right.m_real;
    result.m_imag = right.m_imag;

    return result;
}
  
// Unsigned + Complex Signed:

CWFX_TEMPLATE2
inline CWCX_ADD_US(W,I,W1,I1)
operator + ( const CWFX_UFIXED& left, const CWCX_COMPLEX1& right )
{
    CWCX_ADD_US(W,I,W1,I1) result;

    result.m_real = left + right.m_real;
    result.m_imag = right.m_imag;

    return result;
}
  
// Signed + Complex Unsigned:

CWFX_TEMPLATE2
inline CWCX_ADD_SU(W,I,W1,I1)
operator + ( const CWFX_FIXED& left, const CYNW_FX_U_COMPLEX1& right )
{
    CWCX_ADD_SU(W,I,W1,I1) result;

    result.m_real = left + right.m_real;
    result.m_imag = right.m_imag;

    return result;
}
  
// Unsigned + Complex Unsigned: non-matching and matching template cases

CWFX_TEMPLATE2
inline CWCX_ADD_UU(W,I,W1,I1)
operator + ( const CWFX_UFIXED& left, const CYNW_FX_U_COMPLEX1& right )
{
    CWCX_ADD_UU(W,I,W1,I1) result;

    result.m_real = left + right.m_real;
    result.m_imag = right.m_imag;

    return result;
}

CWFX_TEMPLATE
inline CWCX_ADD_UU(W,I,W,I)
operator + ( const CWFX_UFIXED& left, const CYNW_FX_U_COMPLEX& right )
{
    CWCX_ADD_UU(W,I,W,I) result;

    result.m_real = left + right.m_real;
    result.m_imag = right.m_imag;

    return result;
}

// +----------------------------------------------------------------------------
// |"complex - complex"
// | 
// | These operator overloads perform the mulitplication of two complex values.
// |
// | Arguments:
// |     left  = left operand for the multiplication (complex).
// |     right = right operand for the multiplication (complex).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Complex Signed - Complex Signed: non-matching and matching template cases

CWFX_TEMPLATE2
inline CWCX_SUB_SS(W,I,W1,I1)
operator - ( const CWCX_COMPLEX& left, const CWCX_COMPLEX1& right )
{
    CWCX_SUB_SS(W,I,W1,I1) result;

    result.m_real = left.m_real - right.m_real;
    result.m_imag = left.m_imag - right.m_imag;

    return result;
}
  
CWFX_TEMPLATE
inline CWCX_SUB_SS(W,I,W,I)
operator - ( const CWCX_COMPLEX& left, const CWCX_COMPLEX& right )
{
    CWCX_SUB_SS(W,I,W,I) result;

    result.m_real = left.m_real - right.m_real;
    result.m_imag = left.m_imag - right.m_imag;

    return result;
}
  
// Complex Unsigned - Complex Signed:
//
// (Extra bit for unsigned value sign extension)

CWFX_TEMPLATE2
inline CWCX_SUB_US(W,I,W1,I1)
operator - ( const CYNW_FX_U_COMPLEX& left, const CWCX_COMPLEX1& right )
{
    CWCX_SUB_US(W,I,W1,I1) result;

    result.m_real = left.m_real - right.m_real;
    result.m_imag = left.m_imag - right.m_imag;

    return result;
}
  
// Complex Signed - Complex Unsigned:
//
// (Extra bit for unsigned value sign extension)

CWFX_TEMPLATE2
inline CWCX_SUB_SU(W,I,W1,I1)
operator - ( const CWCX_COMPLEX& left, const CYNW_FX_U_COMPLEX1& right )
{
    CWCX_SUB_SU(W,I,W1,I1) result;

    result.m_real = left.m_real - right.m_real;
    result.m_imag = left.m_imag - right.m_imag;

    return result;
}
  
// Complex Unsigned - Complex Unsigned: non-matching and matching template cases

CWFX_TEMPLATE2
inline CWCX_SUB_UU(W,I,W1,I1)
operator - ( const CYNW_FX_U_COMPLEX& left, const CYNW_FX_U_COMPLEX1& right )
{
    CWCX_SUB_UU(W,I,W1,I1) result;

    result.m_real = left.m_real - right.m_real;
    result.m_imag = left.m_imag - right.m_imag;

    return result;
}

CWFX_TEMPLATE
inline CWCX_SUB_UU(W,I,W,I)
operator - ( const CYNW_FX_U_COMPLEX& left, const CYNW_FX_U_COMPLEX& right )
{
    CWCX_SUB_UU(W,I,W,I) result;

    result.m_real = left.m_real - right.m_real;
    result.m_imag = left.m_imag - right.m_imag;

    return result;
}

// +----------------------------------------------------------------------------
// |"complex - fixed"
// | 
// | These operator overloads perform the mulitplication of a complex value
// | times a fixed point number.
// |
// | Arguments:
// |     left  = left operand for the multiplication (complex).
// |     right = right operand for the multiplication (fixed).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Complex Signed - Signed: non-matching and matching template cases

CWFX_TEMPLATE2
inline CWCX_SUB_SS(W,I,W1,I1)
operator - ( const CWCX_COMPLEX& left, const CWFX_FIXED1& right )
{
    CWCX_SUB_SS(W,I,W1,I1) result;

    result.m_real = left.m_real - right;
    result.m_imag = left.m_imag;

    return result;
}
  
CWFX_TEMPLATE
inline CWCX_SUB_SS(W,I,W,I)
operator - ( const CWCX_COMPLEX& left, const CWFX_FIXED& right )
{
    CWCX_SUB_SS(W,I,W,I) result;

    result.m_real = left.m_real - right;
    result.m_imag = left.m_imag;

    return result;
}
  
// Complex Unsigned - Signed:

CWFX_TEMPLATE2
inline CWCX_SUB_US(W,I,W1,I1)
operator - ( const CYNW_FX_U_COMPLEX& left, const CWFX_FIXED1& right )
{
    CWCX_SUB_US(W,I,W1,I1) result;

    result.m_real = left.m_real - right;
    result.m_imag = left.m_imag;

    return result;
}
  
// Complex Signed - Unsigned:

CWFX_TEMPLATE2
inline CWCX_SUB_SU(W,I,W1,I1)
operator - ( const CWCX_COMPLEX& left, const CWFX_UFIXED1& right )
{
    CWCX_SUB_SU(W,I,W1,I1) result;

    result.m_real = left.m_real - right;
    result.m_imag = left.m_imag;

    return result;
}
  
// Complex Unsigned - Unsigned: non-matching and matching template cases

CWFX_TEMPLATE2
inline CWCX_SUB_UU(W,I,W1,I1)
operator - ( const CYNW_FX_U_COMPLEX& left, const CWFX_UFIXED1& right )
{
    CWCX_SUB_UU(W,I,W1,I1) result;

    result.m_real = left.m_real - right;
    result.m_imag = left.m_imag;

    return result;
}

CWFX_TEMPLATE
inline CWCX_SUB_UU(W,I,W,I)
operator - ( const CYNW_FX_U_COMPLEX& left, const CWFX_UFIXED& right )
{
    CWCX_SUB_UU(W,I,W,I) result;

    result.m_real = left.m_real - right;
    result.m_imag = left.m_imag;

    return result;
}

// +----------------------------------------------------------------------------
// |"fixed - complex"
// | 
// | These operator overloads perform the mulitplication of a fixed point
// | number times a complex value.
// |
// | Arguments:
// |     left  = left operand for the multiplication (fixed).
// |     right = right operand for the multiplication (complex).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Signed - Complex Signed: non-matching and matching template cases

CWFX_TEMPLATE2
inline CWCX_SUB_SS(W,I,W1,I1)
operator - ( const CWFX_FIXED& left, const CWCX_COMPLEX1& right )
{
    CWCX_SUB_SS(W,I,W1,I1) result;

    result.m_real = left - right.m_real;
    result.m_imag = -right.m_imag;

    return result;
}
  
CWFX_TEMPLATE
inline CWCX_SUB_SS(W,I,W,I)
operator - ( const CWFX_FIXED& left, const CWCX_COMPLEX& right )
{
    CWCX_SUB_SS(W,I,W,I) result;

    result.m_real = left - right.m_real;
    result.m_imag = -right.m_imag;

    return result;
}
  
// Unsigned - Complex Signed:

CWFX_TEMPLATE2
inline CWCX_SUB_US(W,I,W1,I1)
operator - ( const CWFX_UFIXED& left, const CWCX_COMPLEX1& right )
{
    CWCX_SUB_US(W,I,W1,I1) result;

    result.m_real = left - right.m_real;
    result.m_imag = -right.m_imag;

    return result;
}
  
// Signed - Complex Unsigned:

CWFX_TEMPLATE2
inline CWCX_SUB_SU(W,I,W1,I1)
operator - ( const CWFX_FIXED& left, const CYNW_FX_U_COMPLEX1& right )
{
    CWCX_SUB_SU(W,I,W1,I1) result;

    result.m_real = left - right.m_real;
    result.m_imag = -right.m_imag;

    return result;
}
  
// Unsigned - Complex Unsigned: non-matching and matching template cases

CWFX_TEMPLATE
inline CWCX_SUB_UU(W,I,W,I)
operator - ( const CWFX_UFIXED& left, const CYNW_FX_U_COMPLEX& right )
{
    CWCX_SUB_UU(W,I,W,I) result;

    result.m_real = left - right.m_real;
    result.m_imag = -right.m_imag;

    return result;
}

CWFX_TEMPLATE2
inline CWCX_SUB_UU(W,I,W1,I1)
operator - ( const CWFX_UFIXED& left, const CYNW_FX_U_COMPLEX1& right )
{
    CWCX_SUB_UU(W,I,W1,I1) result;

    result.m_real = left - right.m_real;
    result.m_imag = -right.m_imag;

    return result;
}

// +----------------------------------------------------------------------------
// |"complex * complex"
// | 
// | These operator overloads perform the mulitplication of two complex values.
// |
// | Arguments:
// |     left  = left operand for the multiplication (complex).
// |     right = right operand for the multiplication (complex).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Complex Signed * Complex Signed: non-matching and matching template cases
//
// ( 1 extra bit for addition ) 

CWFX_TEMPLATE2
inline CWCX_MUL_SS(W,I,W1,I1)
operator * ( const CWCX_COMPLEX& left, const CWCX_COMPLEX1& right )
{
    CWCX_MUL_SS(W,I,W1,I1) result;

    result.m_real = left.m_real * right.m_real - left.m_imag * right.m_imag;
    result.m_imag = left.m_real * right.m_imag + left.m_imag * right.m_real;

    return result;
}
  
CWFX_TEMPLATE
inline CWCX_MUL_SS(W,I,W,I)
operator * ( const CWCX_COMPLEX& left, const CWCX_COMPLEX& right )
{
    CWCX_MUL_SS(W,I,W,I) result;

    result.m_real = left.m_real * right.m_real - left.m_imag * right.m_imag;
    result.m_imag = left.m_real * right.m_imag + left.m_imag * right.m_real;

    return result;
}
  
// Complex Unsigned * Complex Signed:
//
// ( 1 extra bit for addition ) 

CWFX_TEMPLATE2
inline CWCX_MUL_US(W,I,W1,I1)
operator * ( const CYNW_FX_U_COMPLEX& left, const CWCX_COMPLEX1& right )
{
    CWCX_MUL_US(W,I,W1,I1) result;

    result.m_real = left.m_real * right.m_real - left.m_imag * right.m_imag;
    result.m_imag = left.m_real * right.m_imag + left.m_imag * right.m_real;

    return result;
}
  
// Complex Signed * Complex Unsigned:
//
// ( 1 extra bit for addition ) 

CWFX_TEMPLATE2
inline CWCX_MUL_SU(W,I,W1,I1)
operator * ( const CWCX_COMPLEX& left, const CYNW_FX_U_COMPLEX1& right )
{
    CWCX_MUL_SU(W,I,W1,I1) result;

    result.m_real = left.m_real * right.m_real - left.m_imag * right.m_imag;
    result.m_imag = left.m_real * right.m_imag + left.m_imag * right.m_real;

    return result;
}
  
// Complex Unsigned * Complex Unsigned: non-matching and matching template cases
//
// ( 1 extra bit for addition )

CWFX_TEMPLATE2
inline CWCX_MUL_UU(W,I,W1,I1)
operator * ( const CYNW_FX_U_COMPLEX& left, const CYNW_FX_U_COMPLEX1& right )
{
    CWCX_MUL_UU(W,I,W1,I1) result;

    result.m_real = left.m_real * right.m_real - left.m_imag * right.m_imag;
    result.m_imag = left.m_real * right.m_imag + left.m_imag * right.m_real;

    return result;
}

CWFX_TEMPLATE
inline CWCX_MUL_UU(W,I,W,I)
operator * ( const CYNW_FX_U_COMPLEX& left, const CYNW_FX_U_COMPLEX& right )
{
    CWCX_MUL_UU(W,I,W,I) result;

    result.m_real = left.m_real * right.m_real - left.m_imag * right.m_imag;
    result.m_imag = left.m_real * right.m_imag + left.m_imag * right.m_real;

    return result;
}

// +----------------------------------------------------------------------------
// |"complex * fixed"
// | 
// | These operator overloads perform the mulitplication of a complex value
// | times a fixed point number.
// |
// | Arguments:
// |     left  = left operand for the multiplication (complex).
// |     right = right operand for the multiplication (fixed).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Complex Signed * Signed: non-matching and matching template cases

CWFX_TEMPLATE2
inline CWCX_MUL_SS(W,I1,W,I1)
operator * ( const CWCX_COMPLEX& left, const CWFX_FIXED1& right )
{
    CWCX_MUL_SS(W,I1,W,I1) result;

    result.m_real = left.m_real * right;
    result.m_imag = left.m_imag * right;

    return result;
}
  
CWFX_TEMPLATE
inline CWCX_MUL_SS(W,I,W,I)
operator * ( const CWCX_COMPLEX& left, const CWFX_FIXED& right )
{
    CWCX_MUL_SS(W,I,W,I) result; 

    result.m_real = left.m_real * right;
    result.m_imag = left.m_imag * right;

    return result;
}
  
// Complex Unsigned * Signed:

CWFX_TEMPLATE2
inline CWCX_MUL_US(W,I1,W,I1)
operator * ( const CYNW_FX_U_COMPLEX& left, const CWFX_FIXED1& right )
{
    CWCX_MUL_US(W,I1,W,I1) result;

    result.m_real = left.m_real * right;
    result.m_imag = left.m_imag * right;

    return result;
}
  
// Complex Signed * Unsigned:

CWFX_TEMPLATE2
inline CWCX_MUL_SU(W,I1,W,I1)
operator * ( const CWCX_COMPLEX& left, const CWFX_UFIXED1& right )
{
    CWCX_MUL_SU(W,I1,W,I1) result;

    result.m_real = left.m_real * right;
    result.m_imag = left.m_imag * right;

    return result;
}
  
// Complex Unsigned * Unsigned: non-matching and matching template cases

CWFX_TEMPLATE2
inline CWCX_MUL_UU(W,I1,W,I1)
operator * ( const CYNW_FX_U_COMPLEX& left, const CWFX_UFIXED1& right )
{
    CWCX_MUL_UU(W,I1,W,I1) result;

    result.m_real = left.m_real * right;
    result.m_imag = left.m_imag * right;

    return result;
}

CWFX_TEMPLATE
inline CWCX_MUL_UU(W,I,W,I)
operator * ( const CYNW_FX_U_COMPLEX& left, const CWFX_UFIXED& right )
{
    CWCX_MUL_UU(W,I,W,I) result;

    result.m_real = left.m_real * right;
    result.m_imag = left.m_imag * right;

    return result;
}

// +----------------------------------------------------------------------------
// |"fixed * complex"
// | 
// | These operator overloads perform the mulitplication of a fixed point
// | number times a complex value.
// |
// | Arguments:
// |     left  = left operand for the multiplication (fixed).
// |     right = right operand for the multiplication (complex).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Signed * Complex Signed: non-matching and matching template cases

CWFX_TEMPLATE2
inline CWCX_MUL_SS(W,I,W1,I1)
operator * ( const CWFX_FIXED& left, const CWCX_COMPLEX1& right )
{
    CWCX_MUL_SS(W,I,W1,I1) result;

    result.m_real = left * right.m_real;
    result.m_imag = left * right.m_imag;

    return result;
}
  
CWFX_TEMPLATE
inline CWCX_MUL_SS(W,I,W,I)
operator * ( const CWFX_FIXED& left, const CWCX_COMPLEX& right )
{
    CWCX_MUL_SS(W,I,W,I) result;

    result.m_real = left * right.m_real;
    result.m_imag = left * right.m_imag;

    return result;
}
  
// Unsigned * Complex Signed:

CWFX_TEMPLATE2
inline CWCX_MUL_US(W,I,W1,I1)
operator * ( const CWFX_UFIXED& left, const CWCX_COMPLEX1& right )
{
    CWCX_MUL_US(W,I,W1,I1) result;

    result.m_real = left * right.m_real;
    result.m_imag = left * right.m_imag;

    return result;
}
  
// Signed * Complex Unsigned:

CWFX_TEMPLATE2
inline CWCX_MUL_SU(W,I,W1,I1) operator * ( const CWFX_FIXED& left, 
                                           CWCX_COMPLEX1& right )
{
    CWCX_MUL_SU(W,I,W1,I1) result;

    result.m_real = left * right.m_real;
    result.m_imag = left * right.m_imag;

    return result;
}
  
// Unsigned * Complex Unsigned: non-matching and matching template cases

CWFX_TEMPLATE2
inline CWCX_MUL_UU(W,I,W1,I1)
operator * ( const CWFX_UFIXED& left, const CYNW_FX_U_COMPLEX1& right )
{
    CWCX_MUL_UU(W,I,W1,I1) result;

    result.m_real = left * right.m_real;
    result.m_imag = left * right.m_imag;

    return result;
}

CWFX_TEMPLATE
inline CWCX_MUL_UU(W,I,W,I)
operator * ( const CWFX_UFIXED& left, const CYNW_FX_U_COMPLEX& right )
{
    CWCX_MUL_UU(W,I,W,I) result;

    result.m_real = left * right.m_real;
    result.m_imag = left * right.m_imag;

    return result;
}

// +----------------------------------------------------------------------------
// |"complex / complex"
// | 
// | These operator overloads perform the mulitplication of two complex values.
// |
// | Arguments:
// |     left  = left operand for the multiplication (complex).
// |     right = right operand for the multiplication (complex).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Complex Signed / Complex Signed: non-matching and matching template cases

CWFX_TEMPLATE
inline complex<cynw_fixed<2*(W+W)+1+CYNW_FX_DIV_BITS,2*W+1> >
operator / ( const CWCX_COMPLEX& left, const CWCX_COMPLEX& right )
{
    complex<cynw_fixed<2*(W+W)+1+CYNW_FX_DIV_BITS,2*W+1> > result;
    TAG
    result.m_real = left.m_real * right.m_real + left.m_imag * right.m_imag;
    result.m_imag = (left.m_imag * right.m_real - left.m_real * right.m_imag) /
                    (right.m_real * right.m_real + right.m_imag * right.m_imag);
    return result;
}
  
CWFX_TEMPLATE2
inline complex<cynw_fixed<2*(W+W1)+1+CYNW_FX_DIV_BITS,2*(W1+I-I1)+1> >
operator / ( const CWCX_COMPLEX& left, const CWCX_COMPLEX1& right )
{
    complex<cynw_fixed<2*(W+W1)+1+CYNW_FX_DIV_BITS,2*(W1+I-I1)+1> > result;
    TAG
    result.m_real = left.m_real * right.m_real + left.m_imag * right.m_imag;
    result.m_imag = (left.m_imag * right.m_real - left.m_real * right.m_imag) /
                    (right.m_real * right.m_real + right.m_imag * right.m_imag);
    cout << "result size " << result.real().wl() << " " << result.real().iwl() << endl;
    cout << "imag numerator " << ((left.m_imag * right.m_real - left.m_real * right.m_imag)).wl() << " " << ((left.m_imag * right.m_real - left.m_real * right.m_imag)).iwl() << " " << ((left.m_imag * right.m_real - left.m_real * right.m_imag)) << endl;
    cout << "imag denominator " <<  (right.m_real * right.m_real + right.m_imag * right.m_imag).wl() << " " << (right.m_real * right.m_real + right.m_imag * right.m_imag).iwl() << " " << (right.m_real * right.m_real + right.m_imag * right.m_imag) << endl;
    cout << "divide result " << ( (left.m_imag * right.m_real - left.m_real * right.m_imag) / (right.m_real * right.m_real + right.m_imag * right.m_imag)).wl() << " " << ( (left.m_imag * right.m_real - left.m_real * right.m_imag) / (right.m_real * right.m_real + right.m_imag * right.m_imag)).iwl() << endl;
    cout << "divide result value " << ((left.m_imag * right.m_real - left.m_real * right.m_imag) / (right.m_real * right.m_real + right.m_imag * right.m_imag)) << endl;
    return result;
}
  
// Complex Unsigned / Complex Signed:

CWFX_TEMPLATE2
inline complex<cynw_fixed<2*(W+W1)+1+CYNW_FX_DIV_BITS,2*(W1+I-I1)+1> >
operator / ( const CYNW_FX_U_COMPLEX& left, const CWCX_COMPLEX1& right )
{
    complex<cynw_fixed<2*(W+W1)+1+CYNW_FX_DIV_BITS,2*(W1+I-I1)+1> > result;

    TAG
    result.m_real = left.m_real * right.m_real + left.m_imag * right.m_imag;
    result.m_imag = (left.m_imag * right.m_real - left.m_real * right.m_imag) /
                    (right.m_real * right.m_real + right.m_imag * right.m_imag);
    return result;
}
  
// Complex Signed / Complex Unsigned:

CWFX_TEMPLATE2
inline complex<cynw_fixed<2*(W+W1)+1+CYNW_FX_DIV_BITS,2*(W1+I-I1)+1> >
operator / ( const CWCX_COMPLEX& left, const CYNW_FX_U_COMPLEX1& right )
{
    complex<cynw_fixed<2*(W+W1)+1+CYNW_FX_DIV_BITS,2*(W1+I-I1)+1> > result;

    TAG
    result.m_real = left.m_real * right.m_real + left.m_imag * right.m_imag;
    result.m_imag = (left.m_imag * right.m_real - left.m_real * right.m_imag) /
                    (right.m_real * right.m_real + right.m_imag * right.m_imag);
    return result;
}
  
// Complex Unsigned / Complex Unsigned: non-matching and matching template cases

CWFX_TEMPLATE
inline complex<cynw_fixed<2*(W+W)+1+CYNW_FX_DIV_BITS,2*W+1> >
operator / ( const CYNW_FX_U_COMPLEX& left, const CYNW_FX_U_COMPLEX& right )
{
    complex<cynw_fixed<2*(W+W)+1+CYNW_FX_DIV_BITS,2*W+1> > result;

    result.m_real = left.m_real * right.m_real + left.m_imag * right.m_imag;
    result.m_imag = (left.m_imag * right.m_real - left.m_real * right.m_imag) /
                    (right.m_real * right.m_real + right.m_imag * right.m_imag);
    return result;
}

CWFX_TEMPLATE2
inline complex<cynw_fixed<2*(W+W1)+1+CYNW_FX_DIV_BITS,2*(W1+I-I1)+1> >
operator / ( const CYNW_FX_U_COMPLEX& left, const CYNW_FX_U_COMPLEX1& right )
{
    TAG
    complex<cynw_fixed<2*(W+W1)+1+CYNW_FX_DIV_BITS,2*(W1+I-I1)+1> > result;

    result.m_real = left.m_real * right.m_real + left.m_imag * right.m_imag;
    result.m_imag = (left.m_imag * right.m_real - left.m_real * right.m_imag) /
                    (right.m_real * right.m_real + right.m_imag * right.m_imag);
    cout << "result size " << result.real().wl() << " " << result.real().iwl() << endl;
    cout << "imag numerator " << ((left.m_imag * right.m_real - left.m_real * right.m_imag)).wl() << " " << ((left.m_imag * right.m_real - left.m_real * right.m_imag)).iwl() << " " << ((left.m_imag * right.m_real - left.m_real * right.m_imag)) << endl;
    cout << "imag denominator " <<  (right.m_real * right.m_real + right.m_imag * right.m_imag).wl() << " " << (right.m_real * right.m_real + right.m_imag * right.m_imag).iwl() << " " << (right.m_real * right.m_real + right.m_imag * right.m_imag) << endl;
    cout << "divide result " << ( (left.m_imag * right.m_real - left.m_real * right.m_imag) / (right.m_real * right.m_real + right.m_imag * right.m_imag)).wl() << " " << ( (left.m_imag * right.m_real - left.m_real * right.m_imag) / (right.m_real * right.m_real + right.m_imag * right.m_imag)).iwl() << endl;
    cout << "divide result value " << ((left.m_imag * right.m_real - left.m_real * right.m_imag) / (right.m_real * right.m_real + right.m_imag * right.m_imag)) << endl;
    return result;
}

// +----------------------------------------------------------------------------
// |"complex / fixed"
// | 
// | These operator overloads perform the multiplication of a complex value
// | times a fixed point number.
// |
// | Arguments:
// |     left  = left operand for the multiplication (complex).
// |     right = right operand for the multiplication (fixed).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Complex Signed / Signed: non-matching and matching template cases

CWFX_TEMPLATE
inline complex<CWFX_DIV(W,I,W,I) >
operator / ( const CWCX_COMPLEX& left, const CWFX_FIXED& right )
{
    TAG
    complex<CWFX_DIV(W,I,W,I) > result;

    result.m_real = left.m_real / right;
    result.m_imag = left.m_imag / right;

    return result;
}
  
CWFX_TEMPLATE2
inline complex<CWFX_DIV(W,I,W1,I1) >
operator / ( const CWCX_COMPLEX& left, const CWFX_FIXED1& right )
{
    TAG
    complex<CWFX_DIV(W,I,W1,I1) > result;

    result.m_real = left.m_real / right;
    result.m_imag = left.m_imag / right;

    return result;
}
  
// Complex Unsigned / Signed:

CWFX_TEMPLATE2
inline complex<CWFX_DIV(W,I,W1,I1) >
operator / ( const CYNW_FX_U_COMPLEX& left, const CWFX_FIXED1& right )
{
    TAG
    complex<CWFX_DIV(W,I,W1,I1) > result;

    result.m_real = left.m_real / right;
    result.m_imag = left.m_imag / right;

    return result;
}
  
// Complex Signed / Unsigned:

CWFX_TEMPLATE2
inline complex<CWFX_DIV(W,I,W1,I1) >
operator / ( const CWCX_COMPLEX& left, const CWFX_UFIXED1& right )
{
    TAG
    complex<CWFX_DIV(W,I,W1,I1) > result;

    result.m_real = left.m_real / right;
    result.m_imag = left.m_imag / right;

    return result;
}
  
// Complex Unsigned / Unsigned: non-matching and matching template cases

CWFX_TEMPLATE
inline complex<CWFX_DIVU(W,I,W,I) >
operator / ( const CYNW_FX_U_COMPLEX& left, const CWFX_UFIXED& right )
{
    TAG
    complex<CWFX_DIVU(W,I,W,I) > result;

    result.m_real = left.m_real / right;
    result.m_imag = left.m_imag / right;

    return result;
}

CWFX_TEMPLATE2
inline complex<CWFX_DIVU(W,I,W1,I1) >
operator / ( const CYNW_FX_U_COMPLEX& left, const CWFX_UFIXED1& right )
{
    TAG
    complex<CWFX_DIVU(W,I,W1,I1) > result;

    result.m_real = left.m_real / right;
    result.m_imag = left.m_imag / right;

    return result;
}

// +----------------------------------------------------------------------------
// |"fixed / complex"
// | 
// | These operator overloads perform the mulitplication of a fixed point
// | number times a complex value.
// |
// | Arguments:
// |     left  = left operand for the multiplication (fixed).
// |     right = right operand for the multiplication (complex).
// | Result is a complex value containing the result of the multiplication.
// +----------------------------------------------------------------------------

// Signed / Complex Signed: non-matching and matching template cases

CWFX_TEMPLATE
inline complex<CWFX_DIV(W,I,W,I) >
operator / ( const CWFX_FIXED& left, const CWCX_COMPLEX& right )
{
    TAG
    complex<CWFX_DIV(W,I,W,I) > result;
    result.m_real = left * right.m_real;
    result.m_imag = -left * right.m_imag / cynw::norm(right);

    return result;
}
  
CWFX_TEMPLATE2
inline complex<CWFX_DIV(W,I,W1,I1) >
operator / ( const CWFX_FIXED& left, const CWCX_COMPLEX1& right )
{
    TAG
    const CYNW_FX_U_COMPLEX1      norm = cynw::norm(right);
    complex<CWFX_DIV(W,I,W1,I1) > result;
    result.m_real = left * right.m_real;
    result.m_imag = -left * right.m_imag / norm;

    return result;
}
  
// Unsigned / Complex Signed:

CWFX_TEMPLATE2
inline complex<CWFX_DIV(W,I,W1,I1) >
operator / ( const CWFX_UFIXED& left, const CWCX_COMPLEX1& right )
{
    TAG
    const CYNW_FX_U_COMPLEX1      norm = cynw::norm(right);
    complex<CWFX_DIV(W,I,W1,I1) > result;

    result.m_real = left * right.m_real;
    result.m_imag = -left * right.m_imag / norm;

    return result;
}
  
// Signed / Complex Unsigned:

CWFX_TEMPLATE2
inline complex<CWFX_DIV(W,I,W1,I1) >
operator / ( const CWFX_FIXED& left, const CYNW_FX_U_COMPLEX1& right )
{
    TAG
    const CYNW_FX_U_COMPLEX1      norm = cynw::norm(right);
    complex<CWFX_DIV(W,I,W1,I1) > result;

    result.m_real = left * right.m_real;
    result.m_imag = -left * right.m_imag / norm;

    return result;
}
  
// Unsigned / Complex Unsigned: non-matching and matching template cases

CWFX_TEMPLATE
inline complex<CWFX_DIVU(W,I,W,I) >
operator / ( const CWFX_UFIXED& left, const CYNW_FX_U_COMPLEX& right )
{
    TAG
    complex<CWFX_DIVU(W,I,W,I) > result;

    result.m_real = left * right.m_real;
    result.m_imag = -left * right.m_imag / norm(right);

    return result;
}

CWFX_TEMPLATE2
inline complex<CWFX_DIVU(W,I,W1,I1) >
operator / ( const CWFX_UFIXED& left, const CYNW_FX_U_COMPLEX1& right )
{
    TAG
    const CYNW_FX_U_COMPLEX1       norm = cynw::norm(right);
    complex<CWFX_DIVU(W,I,W1,I1) > result;

    result.m_real = left * right.m_real;
    result.m_imag = -left * right.m_imag / norm;

    return result;
}

#if defined(SYSTEMC_VERSION)
// +----------------------------------------------------------------------------
// | I/O stream operators
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
inline std::ostream& operator << ( std::ostream& os, const CWCX_COMPLEX& a )
{
        os << '(' << a.real() << ',' << a.imag() << ')';
        return os;
}

// +----------------------------------------------------------------------------
// | sc_trace
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
inline void sc_trace( sc_trace_file* tf, const CWCX_COMPLEX& object,
                      const std::string& name )
{
        std::string imag_name;
        std::string real_name;
        imag_name = name + ".imag";
        real_name = name + ".real";
        sc_trace( tf, object.real(), real_name );
        sc_trace( tf, object.imag(), imag_name );
}
#endif // defined(SYSTEMC_VERSION)

//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::complex - components"
// | 
// | This is the object instance constructor for this class that takes 
// | component values.
// |
// | Arguments:
// |     real = real value.
// |     imag = imaginary value.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
inline CYNW_FX_U_COMPLEX::complex( const CWFX_UFIXED& real, 
                                 const CWFX_UFIXED& imag ) : 
    m_imag(imag), m_real(real)
{
}

CWFX_TEMPLATE
template<typename _REAL, typename _IMAG>
inline CYNW_FX_U_COMPLEX::complex( const _REAL& real, 
                                                       const _IMAG& imag ) 
{
    m_real = real;
    m_imag = imag;
}

// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::complex - other complex type"
// | 
// | This is the object instance constructor for this class that takes 
// | another complex type.
// |
// | Arguments:
// |     other = other complex type.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template<typename T1>
inline 
CYNW_FX_U_COMPLEX::complex(const complex<T1>& other ) :
    m_imag(other.imag()), m_real(other.real())
{
}

// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::operator = this component type"
// | 
// | This is the assignment operator for a component value of this type.
// |
// | Arguments:
// |     value = CYNW_FX_U_COMPLEX value to assign this object instance to.
// | Result is a const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
const CYNW_FX_U_COMPLEX& 
CYNW_FX_U_COMPLEX::operator = ( const CWFX_UFIXED& value )
{
    m_imag = CWFX_UFIXED ();
    m_real = value;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::operator = complex type"
// | 
// | This is the assignment operator for a value of a complex type.
// |
// | Arguments:
// |     value = complex<OTHER> value to assign this object instance to.
// | Result is a const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template < typename OTHER >
const CYNW_FX_U_COMPLEX& 
CYNW_FX_U_COMPLEX::operator = ( const complex<OTHER>& value )
{
    m_imag = value.imag();
    m_real = value.real();
    return *this;
}

// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::operator += component type"
// | 
// | This operator adds the supplied component instance to this object instance.
// | This only changes the real component of this object instance.
// |
// | Arguments:
// |     value = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
const CYNW_FX_U_COMPLEX& 
CYNW_FX_U_COMPLEX::operator += ( const CWFX_UFIXED & value )
{
    m_real += value;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::operator += other complex instance"
// | 
// | This operator adds the supplied complex instance to this object instance.
// | This results in changes to both the real and imaginary components of this
// | object instance.
// |
// | Arguments:
// |     value = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template< typename OTHER >
const CYNW_FX_U_COMPLEX& 
CYNW_FX_U_COMPLEX::operator += ( const complex<OTHER>& value )
{
    m_real += value.real();
    m_imag += value.imag();
    return *this;
}

// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::operator -= component type"
// | 
// | This operator adds the supplied component instance from this object 
// | instance. This only changes the real component of this object instance.
// |
// | Arguments:
// |     value = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
const CYNW_FX_U_COMPLEX& 
CYNW_FX_U_COMPLEX::operator -= ( const CWFX_UFIXED & value )
{
    m_real -= value;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::operator -= other complex instance"
// | 
// | This operator subtracts the supplied complex instance from this object 
// | instance. This results in changes to both the real and imaginary components
// | of this object instance.
// |
// | Arguments:
// |     value = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template< typename OTHER >
const CYNW_FX_U_COMPLEX& 
CYNW_FX_U_COMPLEX::operator -= ( const complex<OTHER>& value )
{
    m_real -= value.real();
    m_imag -= value.imag();
    return *this;
}

// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::operator *= component type"
// | 
// | This operator multiplies the supplied component instance from this object 
// | instance. This changes the both components of this object instance.
// |
// | Arguments:
// |     value = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
const CYNW_FX_U_COMPLEX& 
CYNW_FX_U_COMPLEX::operator *= ( const CWFX_UFIXED & value )
{
    m_imag *= value;
    m_real *= value;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::operator *= other complex instance"
// | 
// | This operator multiplies the supplied complex instance from this object 
// | instance. This results in changes to both the real and imaginary components
// | of this object instance. The order of the assignments below is important!
// |
// | Arguments:
// |     other = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template< typename OTHER >
const CYNW_FX_U_COMPLEX& CYNW_FX_U_COMPLEX::operator *= ( 
                                                  const complex<OTHER>& other )
{
    const target_type real = m_real * other.real() - m_imag * other.imag();
    m_imag = m_real * other.imag() + m_imag * other.real();
    m_real = real;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::operator /= component type"
// | 
// | This operator divides this object instance by the  supplied component 
// | instance. This changes the both components of this object instance.
// |
// | Arguments:
// |     other = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
const CYNW_FX_U_COMPLEX& 
CYNW_FX_U_COMPLEX::operator /= ( const CWFX_UFIXED & other )
{
    TAG
    m_imag /= other;
    m_real /= other;
    return *this;
}

// +----------------------------------------------------------------------------
// |"CYNW_FX_U_COMPLEX::operator /= other complex instance"
// | 
// | This operator divides this object instance by the supplied complex 
// | instance. This results in changes to both the real and imaginary components
// | of this object instance. The order of the assignments below is important!
// |
// | Arguments:
// |     other = value to be added.
// | Result is const reference to this object instance.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
template< typename OTHER >
const CYNW_FX_U_COMPLEX& 
CYNW_FX_U_COMPLEX::operator /= ( const complex<OTHER>& other )
{
    TAG
    const target_type real = m_real * other.real() + m_imag * other.imag();
    const target_type norm = cynw::norm(other); 
    m_imag = m_imag * other.real() - m_real * other.imag() / norm;
    m_real = real;
    return *this;
}

// +----------------------------------------------------------------------------
// |"norm(complex<cynw_fixed>)"
// |
// | This function returne the "norm" for the supplied complex value.
// |
// | Arguments:
// |     source = value to return the norm of.
// | Result is the norm.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
inline cynw_fixed<W+W+1,I+I+1,Q_MODE,O_MODE,N_BITS>  
norm( const CWCX_COMPLEX& source )
{
    typename CWCX_COMPLEX::base_type real = source.real();
    typename CWCX_COMPLEX::base_type imag = source.imag();
cout << "@@@@#### " << __FILE__ << ":" << __LINE__ << endl;
    return real*real + imag*imag;
}

// +----------------------------------------------------------------------------
// |"norm(complex<cynw_ufixed>)"
// |
// | This function returne the "norm" for the supplied complex value.
// |
// | Arguments:
// |     source = value to return the norm of.
// | Result is the norm.
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
inline cynw_ufixed<W+W+1,I+I+1,Q_MODE,O_MODE,N_BITS>  
norm( const CYNW_FX_U_COMPLEX& source )
{
    typename CYNW_FX_U_COMPLEX::base_type real = source.real();
    typename CYNW_FX_U_COMPLEX::base_type imag = source.imag();
cout << "@@@@#### " << __FILE__ << ":" << __LINE__ << endl;
    return real*real + imag*imag;
}

#if defined(SYSTEMC_VERSION)
// +----------------------------------------------------------------------------
// | I/O stream operators
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
inline std::ostream& operator << (std::ostream& os, const CYNW_FX_U_COMPLEX& a)
{
        os << '(' << a.real() << ',' << a.imag() << ')';
        return os;
}

// +----------------------------------------------------------------------------
// | sc_trace
// +----------------------------------------------------------------------------
CWFX_TEMPLATE
inline void sc_trace( sc_trace_file* tf, const CYNW_FX_U_COMPLEX& object,
                      const std::string& name )
{
        std::string imag_name;
        std::string real_name;
        imag_name = name + ".imag";
        real_name = name + ".real";
        sc_trace( tf, object.real(), real_name );
        sc_trace( tf, object.imag(), imag_name );
}
#endif // defined(SYSTEMC_VERSION)

} // namespace std

// Clean up after ourselves:

#undef CWCX_COMPLEX
#undef CWCX_COMPLEX1
#undef CYNW_FX_U_COMPLEX
#undef CYNW_FX_U_COMPLEX1

#endif // !defined(cynw_fixed_complex_h_included)
