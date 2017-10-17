// *****************************************************************************
// *****************************************************************************
// cynw_blocking_put_initiator.h
//
// This file contains the definition of always-block put initiator. 
// This initiator will always take at one or more clock cycle per put()
// transaction.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_BLOCKING_PUT_INITIATOR_H
#define CYNW_BLOCKING_PUT_INITIATOR_H

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
struct b_put_initiator_imp
{ };


// *****************************************************************************
// This struct is the specialization for the transaction-level configuration.
// *****************************************************************************
template <typename T, typename TRAITS>
struct b_put_initiator_imp<T,TRAITS,0>
    : sc_module
    , sc_interface
{
    HLS_METAPORT;

    b_put_initiator_imp(sc_module_name);

    template<typename CHAN>
    void                    operator()(CHAN& chan);
    template<typename CHAN>
    void                    bind(CHAN& chan);
    template<typename CLK, typename RST>
    void                    clk_rst(CLK&, RST&);

    virtual void            put(const T& v);
    virtual void            reset_put(cynw_tlm::tlm_tag<T>* t=0);
    virtual void            reset();

    sc_port<cynw_tlm::tlm_blocking_put_if<T> > p;
};


// *****************************************************************************
// This struct is the specialization for the signal-level configuration.
// *****************************************************************************
template <typename T, typename TRAITS>
struct b_put_initiator_imp<T,TRAITS,1>
    : cynw_put_port_base<T>
{
    b_put_initiator_imp(sc_module_name);

    typedef b_put_initiator_imp<T,TRAITS,1>  this_type;
    typedef cynw_put_port_base<T>            base_type;

    template<typename CHAN>
    void                    operator()(CHAN& chan);
    template<typename CHAN>
    void                    bind(CHAN& chan);
    template<typename CLK, typename RST>
    void                    clk_rst(CLK&, RST&);

    virtual void            put(const T& v);
    virtual void            reset_put(cynw_tlm::tlm_tag<T>* t=0);
    virtual void            reset();
    std::string             _name;
    std::string             name() { return _name; }

public:
//    sc_out<bool>            valid;
//    sc_in <bool>            ready;
//    sc_out<T>               data;

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
struct b_put_initiator : b_put_initiator_imp<T,TRAITS,TRAITS::Level> {
    b_put_initiator(sc_module_name n = sc_gen_unique_name("b_put_initiator")) 
        : b_put_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};


// ---------------------------------------------------------------------------
// Internal method definitions
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Internal method definitions for b_put_initiator_imp (TLM)

template <typename T, typename TRAITS>
inline
b_put_initiator_imp<T,TRAITS,0>::b_put_initiator_imp(sc_module_name n)
    : sc_module(n)
    , p("p")
{ }


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
b_put_initiator_imp<T,TRAITS,0>::operator()(CHAN& chan) { 
    p.bind(chan); 
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
b_put_initiator_imp<T,TRAITS,0>::bind(CHAN& chan) { 
    operator()(chan); 
}


template <typename T, typename TRAITS>
template<typename CLK, typename RST>
inline void
b_put_initiator_imp<T,TRAITS,0>::clk_rst(CLK&, RST&) { }


template <typename T, typename TRAITS>
inline void
b_put_initiator_imp<T,TRAITS,0>::put(const T& v) { 
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    OStrStream msg;
    msg << v;
    cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
    tr.record_attribute("b_put_data", OStrStream_string(msg));
#endif
    p->put(v); 
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    tr.end_transaction();
#endif
}


template <typename T, typename TRAITS>
inline void
b_put_initiator_imp<T,TRAITS,0>::reset_put(cynw_tlm::tlm_tag<T>* t) { 
    p->reset_put(); //Michele Petracca on 04/24/2015
}


template <typename T, typename TRAITS>
inline void
b_put_initiator_imp<T,TRAITS,0>::reset() {
    reset_put();
}


// ---------------------------------------------------------------------------
// Internal method definitions for b_put_initiator_imp (signal-level)

template <typename T, typename TRAITS>
inline
b_put_initiator_imp<T,TRAITS,1>::b_put_initiator_imp(sc_module_name n)
    : _name(n)
//    , valid("valid")
//    , ready("ready")
//    , data("data") 
#ifndef STRATUS
    , FLEX_CHANNELS_RESET_CHECK_CTOR
#endif
{ }


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
b_put_initiator_imp<T,TRAITS,1>::operator()(CHAN& chan) {
//    valid(chan.valid);
//    ready(chan.ready);
//    data (chan.data );
  base_type::bind(chan);
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
b_put_initiator_imp<T,TRAITS,1>::bind(CHAN& chan) { 
    operator()(chan); 
}


template <typename T, typename TRAITS>
template<typename CLK, typename RST>
inline void
b_put_initiator_imp<T,TRAITS,1>::clk_rst(CLK&, RST&) { }


template <typename T, typename TRAITS>
inline void 
b_put_initiator_imp<T,TRAITS,1>::put(const T& v) {
    HLS_DEFINE_PROTOCOL("PUT_PROTOCOL");
    FLEX_CHANNELS_PROTOCOL(B_PUT_START) ;
    FLEX_CHANNELS_RESET_CHECK;
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    OStrStream msg;
    msg << v;
    cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
    tr.record_attribute("b_put_data", OStrStream_string(msg));
#endif
    base_type::data = v;
    base_type::valid = 1;
    FLEX_CHANNELS_LABEL(WAIT_B_PUT)  
    do { wait(); } while (base_type::ready != 1);
    base_type::valid = 0;
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    tr.end_transaction();
#endif
    FLEX_CHANNELS_PROTOCOL(B_PUT_END) ;
}


template <typename T, typename TRAITS>
inline void 
b_put_initiator_imp<T,TRAITS,1>::reset_put(cynw_tlm::tlm_tag<T>* t) {
    HLS_DEFINE_PROTOCOL("RESET_PUT_PROTOCOL");
    if (base_type::is_hierarchically_bound()) return;
    FLEX_CHANNELS_RESET_CALLED;
    if (TRAITS::ResetData) {
        base_type::data = T();
    }
    base_type::valid = 0;
}


template <typename T, typename TRAITS>
inline void
b_put_initiator_imp<T,TRAITS,1>::reset() {
    reset_put();
}

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif

#endif

