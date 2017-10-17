// *****************************************************************************
// *****************************************************************************
// cynw_blocking_get_initiators.h
//
// This file contains the definition of always-block get initiator. 
// This initiator will always take at one or more clock cycle per get()
// transaction.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_BLOCKING_GET_INITIATOR_H
#define CYNW_BLOCKING_GET_INITIATOR_H

#include "cynw_put_get_port_base.h"


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw {

// *****************************************************************************
// This struct is for the implementation of the initiator. Template parameter 
// LEVEL is used to select either a TLM or a signal-level configuration.
// Partial template specialization is used below for the implementations of 
// these configurations.
// *****************************************************************************
template <typename T, typename TRAITS, bool LEVEL>
struct b_get_initiator_imp
{ };


// *****************************************************************************
// This struct is the specialization for the transaction-level configuration.
// *****************************************************************************
template <typename T, typename TRAITS>
struct b_get_initiator_imp<T,TRAITS,0> 
    : sc_module
    , sc_interface
{
    HLS_METAPORT;

    b_get_initiator_imp(sc_module_name);

    template<typename CHAN>
    void                    operator()(CHAN& chan);
    template<typename CHAN>
    void                    bind(CHAN& chan);
    template<typename CLK, typename RST>
    void                    clk_rst(CLK&, RST&);

    virtual void            get(T& v);
    virtual T               get(cynw_tlm::tlm_tag<T>* t=0);
    virtual void            reset_get(cynw_tlm::tlm_tag<T>* t=0);
    virtual void            reset();

    sc_port<cynw_tlm::tlm_blocking_get_if<T> > p;
};


// *****************************************************************************
// This struct is the specialization for the signal-level configuration.
// *****************************************************************************
template <typename T, typename TRAITS>
struct b_get_initiator_imp<T,TRAITS,1> 
    : cynw_get_port_base<T>
{
    b_get_initiator_imp(sc_module_name);

    typedef b_get_initiator_imp<T,TRAITS,1>  this_type;
    typedef cynw_get_port_base<T>            base_type;

    template<typename CHAN>
    void                    operator()(CHAN& chan);
    template<typename CHAN>
    void                    bind(CHAN& chan);
    template<typename CLK, typename RST>
    void                    clk_rst(CLK&, RST&);

    virtual void            get(T& v);
    virtual T               get(cynw_tlm::tlm_tag<T>* t=0);
    virtual void            reset_get(cynw_tlm::tlm_tag<T>* t=0);
    virtual void            reset();
    std::string             _name;
    std::string             name() { return _name; }

public:
//    sc_in<bool>             valid;
//    sc_out<bool>            ready;
//    sc_in<T>                data;

private:
#ifndef STRATUS
    FLEX_CHANNELS_RESET_CHECK_DECL;
#endif
};


// ****************************************************************************
// This is the struct to be used in the SystemC designs. The TRAITS type 
// provides the definition level parameter.
// ****************************************************************************
template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct b_get_initiator : b_get_initiator_imp<T,TRAITS,TRAITS::Level> {
    b_get_initiator(sc_module_name n = sc_gen_unique_name("b_get_initiator")) 
        : b_get_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};


// ---------------------------------------------------------------------------
// Internal method definitions
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Internal method definitions for b_get_initiator_imp (TLM)

template <typename T, typename TRAITS>
inline 
b_get_initiator_imp<T,TRAITS,0>::b_get_initiator_imp(sc_module_name n)
    : sc_module(n)
    , p("p")
{ }


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
b_get_initiator_imp<T,TRAITS,0>::operator()(CHAN& chan) { 
    p.bind(chan); 
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
b_get_initiator_imp<T,TRAITS,0>::bind(CHAN& chan) { 
    operator()(chan); 
}


template <typename T, typename TRAITS>
template<typename CLK, typename RST>
inline void
b_get_initiator_imp<T,TRAITS,0>::clk_rst(CLK&, RST&)  { }


template <typename T, typename TRAITS>
inline void
b_get_initiator_imp<T,TRAITS,0>::get(T& v) {
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
#endif
    p->get(v); 
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    OStrStream msg;
    msg << v;
    tr.record_attribute("get_data", OStrStream_string(msg));
    tr.end_transaction();
#endif
}


template <typename T, typename TRAITS>
inline T
b_get_initiator_imp<T,TRAITS,0>::get(cynw_tlm::tlm_tag<T>* t) { 
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
#endif
    T v =  p->get(t); 
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    OStrStream msg;
    msg << t;
    tr.record_attribute("get_data", OStrStream_string(msg));
    tr.end_transaction();
#endif
    return v;
} 


template <typename T, typename TRAITS>
inline void
b_get_initiator_imp<T,TRAITS,0>::reset_get(cynw_tlm::tlm_tag<T>* t) { 
    p->reset_get(); //Michele Petracca on 04/24/2015
}


template <typename T, typename TRAITS>
inline void
b_get_initiator_imp<T,TRAITS,0>::reset() {
    reset_get();
}


// ---------------------------------------------------------------------------
// Internal method definitions for b_get_initiator_imp (signal-level)

template <typename T, typename TRAITS>
inline
b_get_initiator_imp<T,TRAITS,1>::b_get_initiator_imp(sc_module_name n)
    : _name(n)
#ifndef STRATUS
    , FLEX_CHANNELS_RESET_CHECK_CTOR
#endif
//    , valid("valid")
//    , ready("ready")
//    , data("data") 
{ 
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
b_get_initiator_imp<T,TRAITS,1>::operator()(CHAN& chan) {
    cynw_mark_hierarchical_binding(&chan);
//    valid(chan.valid);
//    ready(chan.ready);
//    data(chan.data);
    base_type::bind(chan);
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
b_get_initiator_imp<T,TRAITS,1>::bind(CHAN& chan) {
    operator()(chan);
}


template <typename T, typename TRAITS>
template<typename CLK, typename RST>
inline void 
b_get_initiator_imp<T,TRAITS,1>::clk_rst(CLK&, RST&) { }


template <typename T, typename TRAITS>
inline void 
b_get_initiator_imp<T,TRAITS,1>::get(T& v) {
    HLS_DEFINE_PROTOCOL("B_GET_PROTOCOL");
    if (base_type::is_hierarchically_bound()) return;    
    FLEX_CHANNELS_PROTOCOL(B_GET_START) ;
    FLEX_CHANNELS_RESET_CHECK;
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
#endif
    base_type::ready  = 1;
    FLEX_CHANNELS_LABEL(WAIT_B_GET)  
    do { wait(); } while (base_type::valid != 1);
    v     = base_type::data;
    base_type::ready = 0;
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    OStrStream msg;
    msg << v;
    tr.record_attribute("get_data", OStrStream_string(msg));
    tr.end_transaction();
#endif
    FLEX_CHANNELS_PROTOCOL(B_GET_END) ;
}


template <typename T, typename TRAITS>
inline T 
b_get_initiator_imp<T,TRAITS,1>::get(cynw_tlm::tlm_tag<T>* t) {
    FLEX_CHANNELS_RESET_CHECK;
    T v;
    if (base_type::is_hierarchically_bound()) return v;
    get(v);
    return v;
}


template <typename T, typename TRAITS>
inline void 
b_get_initiator_imp<T,TRAITS,1>::reset_get(cynw_tlm::tlm_tag<T>* t) { 
    HLS_DEFINE_PROTOCOL("RESET_GET_PROTOCOL");
    if (base_type::is_hierarchically_bound()) return;    
    FLEX_CHANNELS_RESET_CALLED;
    base_type::ready = 0;
}


template <typename T, typename TRAITS>
inline void
b_get_initiator_imp<T,TRAITS,1>::reset() {
    reset_get();
}

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif

#endif

