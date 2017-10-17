/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/

#ifndef cynw_float_base_h
#define cynw_float_base_h

#include "cynthhl.h"

//
// Default templates for CMD functions
//

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ROUND, const int NaN, const int CYNW_EX>
void cynw_cm_float_mul_ieee_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        const sc_uint<1> & b_sign,
        const sc_uint<E> & b_exp, 
        const sc_uint<M> & b_man,
        sc_uint<E_RSLT+M_RSLT+1+CYNW_EX> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_mul_ieee_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "RoundMode", ROUND);
        CYN_CONFIG_INSTRUCTION( "NanMode", NaN );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_CONFIG_INSTRUCTION( "OutExWidth", CYNW_EX );
        CYN_CONFIG_INSTRUCTION( "HasRoundModeInput", (ROUND<0) );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_INPUT ( "b_sign", b_sign );
        CYN_BIND_INPUT ( "b_exp",  b_exp );
        CYN_BIND_INPUT ( "b_man",  b_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_mul_ieee" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int CYNW_EX>
void cynw_cm_float_mul_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        const sc_uint<1> & b_sign,
        const sc_uint<E> & b_exp, 
        const sc_uint<M> & b_man,
        sc_uint<E_RSLT+M_RSLT+1+CYNW_EX> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_mul_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_CONFIG_INSTRUCTION( "OutExWidth", CYNW_EX );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_INPUT ( "b_sign", b_sign );
        CYN_BIND_INPUT ( "b_exp",  b_exp );
        CYN_BIND_INPUT ( "b_man",  b_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_mul" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ROUND, const int NaN, const int CYNW_EX>
static void cynw_cm_float_add_ieee_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        const sc_uint<1> & b_sign,
        const sc_uint<E> & b_exp, 
        const sc_uint<M> & b_man,
        sc_uint<E_RSLT+M_RSLT+1+CYNW_EX> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_add_ieee_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "RoundMode", ROUND );
        CYN_CONFIG_INSTRUCTION( "NanMode", NaN );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_CONFIG_INSTRUCTION( "OutExWidth", CYNW_EX );
        CYN_CONFIG_INSTRUCTION( "HasRoundModeInput", (ROUND<0) );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_INPUT ( "b_sign", b_sign );
        CYN_BIND_INPUT ( "b_exp",  b_exp );
        CYN_BIND_INPUT ( "b_man",  b_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_add2_ieee" )
    }
}



template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int CYNW_EX>
static void cynw_cm_float_add_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        const sc_uint<1> & b_sign,
        const sc_uint<E> & b_exp, 
        const sc_uint<M> & b_man,
        sc_uint<E_RSLT+M_RSLT+1+CYNW_EX> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_add_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_CONFIG_INSTRUCTION( "OutExWidth", CYNW_EX );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_INPUT ( "b_sign", b_sign );
        CYN_BIND_INPUT ( "b_exp",  b_exp );
        CYN_BIND_INPUT ( "b_man",  b_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_add2" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ROUND, const int NaN, const int CYNW_EX>
static void cynw_cm_float_div_ieee_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        const sc_uint<1> & b_sign,
        const sc_uint<E> & b_exp, 
        const sc_uint<M> & b_man,
        sc_uint<E_RSLT+M_RSLT+1+CYNW_EX> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_div_ieee_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "RoundMode", ROUND );
        CYN_CONFIG_INSTRUCTION( "NanMode", NaN );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_CONFIG_INSTRUCTION( "OutExWidth", CYNW_EX );
        CYN_CONFIG_INSTRUCTION( "HasRoundModeInput", (ROUND<0) );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_INPUT ( "b_sign", b_sign );
        CYN_BIND_INPUT ( "b_exp",  b_exp );
        CYN_BIND_INPUT ( "b_man",  b_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_div_ieee" )
    }
}


template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ROUND, const int NaN, const int CYNW_EX>
static void cynw_cm_float_sqrt_ieee_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        sc_uint<E_RSLT+M_RSLT+1+CYNW_EX> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_sqrt_ieee_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "RoundMode", ROUND );
        CYN_CONFIG_INSTRUCTION( "NanMode", NaN );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_CONFIG_INSTRUCTION( "OutExWidth", CYNW_EX );
        CYN_CONFIG_INSTRUCTION( "HasRoundModeInput", (ROUND<0) );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_sqrt_ieee" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M>
static void cynw_cm_float_sqrt_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        sc_uint<E_RSLT+M_RSLT+1> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_sqrt_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_unit, cynw_cm_float_sqrt" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M>
static void cynw_cm_float_recip_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        sc_uint<E_RSLT+M_RSLT+1> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_recip_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_rcp, cynw_cm_float_unit, cynw_cm_float_rcp_rsq_log_exp, cynw_cm_float_rcp_rsq" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M>
static void cynw_cm_float_rsqrt_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        sc_uint<E_RSLT+M_RSLT+1> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_rsqrt_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_rsq, cynw_cm_float_unit, cynw_cm_float_rcp_rsq_log_exp, cynw_cm_float_rcp_rsq" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M>
static void cynw_cm_float_log2_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        sc_uint<E_RSLT+M_RSLT+1> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_log2_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_log2, cynw_cm_float_unit, cynw_cm_float_rcp_rsq_log_exp" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M>
static void cynw_cm_float_exp2_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        sc_uint<E_RSLT+M_RSLT+1> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_exp2_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_exp2, cynw_cm_float_unit, cynw_cm_float_rcp_rsq_log_exp" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M>
static void cynw_cm_float_sin_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        sc_uint<E_RSLT+M_RSLT+1> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_sin_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_unit, cynw_cm_float_sin, cynw_cm_float_sin_cos" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M>
static void cynw_cm_float_cos_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        sc_uint<E_RSLT+M_RSLT+1> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_cos_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_unit, cynw_cm_float_cos, cynw_cm_float_sin_cos" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M>
static void cynw_cm_float_dot_i ( 
        const sc_uint<1> & a0_sign, 
        const sc_uint<E> & a0_exp, 
        const sc_uint<M> & a0_man,
        const sc_uint<1> & a1_sign, 
        const sc_uint<E> & a1_exp, 
        const sc_uint<M> & a1_man,
        const sc_uint<1> & b0_sign, 
        const sc_uint<E> & b0_exp, 
        const sc_uint<M> & b0_man,
        const sc_uint<1> & b1_sign, 
        const sc_uint<E> & b1_exp, 
        const sc_uint<M> & b1_man,
        sc_uint<E_RSLT+M_RSLT+1> & x )
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_dot_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_BIND_INPUT ( "a0_sign", a0_sign );
        CYN_BIND_INPUT ( "a0_exp",  a0_exp );
        CYN_BIND_INPUT ( "a0_man",  a0_man );
        CYN_BIND_INPUT ( "a1_sign", a1_sign );
        CYN_BIND_INPUT ( "a1_exp",  a1_exp );
        CYN_BIND_INPUT ( "a1_man",  a1_man );
        CYN_BIND_INPUT ( "b0_sign", b0_sign );
        CYN_BIND_INPUT ( "b0_exp",  b0_exp );
        CYN_BIND_INPUT ( "b0_man",  b0_man );
        CYN_BIND_INPUT ( "b1_sign", b1_sign );
        CYN_BIND_INPUT ( "b1_exp",  b1_exp );
        CYN_BIND_INPUT ( "b1_man",  b1_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_dp2" )
    }
}

template<const int E_RSLT, const int M_RSLT, const int E, const int M, const int ROUND, const int NaN, const int CYNW_EX>
static void cynw_cm_float_madd_ieee_i ( 
        const sc_uint<1> & a_sign, 
        const sc_uint<E> & a_exp,
        const sc_uint<M> & a_man, 
        const sc_uint<1> & b_sign,
        const sc_uint<E> & b_exp, 
        const sc_uint<M> & b_man,
        const sc_uint<1> & c_sign,
        const sc_uint<E> & c_exp, 
        const sc_uint<M> & c_man,
        sc_uint<E_RSLT+M_RSLT+1+CYNW_EX> & x)
{
    {
        CYN_MAP_INSTRUCTION( "cynw_cm_float_madd_ieee_i" );
        CYN_CONFIG_INSTRUCTION( "OutExpWidth", E_RSLT );
        CYN_CONFIG_INSTRUCTION( "OutMantWidth", M_RSLT );
        CYN_CONFIG_INSTRUCTION( "InExpWidth", E );
        CYN_CONFIG_INSTRUCTION( "InMantWidth", M );
        CYN_CONFIG_INSTRUCTION( "RoundMode", ROUND );
        CYN_CONFIG_INSTRUCTION( "NanMode", NaN );
        CYN_CONFIG_INSTRUCTION( "HasAsyncReset", (HLS_RESET_TYPE & 0x2)>>1);
        CYN_CONFIG_INSTRUCTION( "HasSyncReset", (HLS_RESET_TYPE & 0x1));
        CYN_CONFIG_INSTRUCTION( "HasEnable", HLS_DPOPT_WITH_ENABLE );
        CYN_CONFIG_INSTRUCTION( "OutExWidth", CYNW_EX );
        CYN_CONFIG_INSTRUCTION( "HasRoundModeInput", (ROUND<0) );
        CYN_BIND_INPUT ( "a_sign", a_sign );
        CYN_BIND_INPUT ( "a_exp",  a_exp );
        CYN_BIND_INPUT ( "a_man",  a_man );
        CYN_BIND_INPUT ( "b_sign", b_sign );
        CYN_BIND_INPUT ( "b_exp",  b_exp );
        CYN_BIND_INPUT ( "b_man",  b_man );
        CYN_BIND_INPUT ( "c_sign", c_sign );
        CYN_BIND_INPUT ( "c_exp",  c_exp );
        CYN_BIND_INPUT ( "c_man",  c_man );
        CYN_BIND_OUTPUT( "x",      x );
	CYN_SUGGEST_LIB_CONFIG( "cynw_cm_float", "cynw_cm_float_madd_ieee" )
    }
}


#endif // cynw_float_base_h

