// *****************************************************************************
// *****************************************************************************
// cynw_put_get_channel.h
//
// This file contains the definitions of the put/get channel.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_PUT_GET_CHANNEL_H
#define CYNW_PUT_GET_CHANNEL_H


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw {


// *****************************************************************************
// This struct is for the implementation of the channel. Template parameter 
// LEVEL is used to select either a TLM or a signal-level configuration.
// Partial template specialization is used below for the implementations of 
// these configurations.
// *****************************************************************************
template <typename T, typename TRAITS, bool level>
struct put_get_channel_imp 
    : sc_module 
{ };


// *****************************************************************************
// This struct is the specialization for the transaction-level configuration.
// *****************************************************************************
template <typename T, typename TRAITS>
struct put_get_channel_imp<T,TRAITS,0> 
    : cynw_tlm::tlm_fifo<T, TRAITS::Put_Get_Channel_FIFO_Size>
{
    put_get_channel_imp(const char* n)
        : cynw_tlm::tlm_fifo<T, TRAITS::Put_Get_Channel_FIFO_Size>(n)
    { }
};


// *****************************************************************************
// This struct is the specialization for the signal-level configuration.
// *****************************************************************************
template <typename T, typename TRAITS>
struct put_get_channel_imp<T,TRAITS,1> 
    : sc_module
    , sc_interface
{

    sc_signal<bool> ready;
    sc_signal<bool> valid;
    sc_signal<T>    data;

    SC_CTOR(put_get_channel_imp)
        : ready("ready")
        , valid("valid")
        , data ("data") 
    { }
};


// ****************************************************************************
// This is the struct to be used in the SystemC designs. The TRAITS type 
// provides the definition level parameter.
// ****************************************************************************
template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct put_get_channel: 
    put_get_channel_imp<T,TRAITS,TRAITS::Level> 
{

    put_get_channel(sc_module_name n = sc_gen_unique_name("put_get_channel"))
        : put_get_channel_imp<T,TRAITS,TRAITS::Level>(n) 
    { }

    typedef get_initiator<T,TRAITS>         in;
    typedef put_initiator<T,TRAITS>         out;
    typedef b_get_initiator<T,TRAITS>       b_in;
    typedef b_put_initiator<T,TRAITS>       b_out;
    typedef nb_get_initiator<T,TRAITS>      nb_in;
    typedef nb_put_initiator<T,TRAITS>      nb_out;

    typedef hier_get_initiator<T,TRAITS>    hier_in;
    typedef hier_put_initiator<T,TRAITS>    hier_out;
};

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif


#endif

