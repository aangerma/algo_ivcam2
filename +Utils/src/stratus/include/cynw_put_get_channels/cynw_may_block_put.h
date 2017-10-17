// *****************************************************************************
// *****************************************************************************
// cynw_may_block_put_initiator.h
//
// This file contains the definition of may-block put initiator. 
// This initiator may take one or more clock cycle per put() transaction.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_MAY_BLOCK_PUT_INITIATOR_H
#define CYNW_MAY_BLOCK_PUT_INITIATOR_H

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
struct put_initiator_imp
{ };


// *****************************************************************************
// This struct is the specialization for the transaction-level configuration.
// *****************************************************************************
template<typename T, typename TRAITS>
struct put_initiator_imp<T,TRAITS,0>
    : sc_module
    , sc_interface
{
    HLS_METAPORT;

    put_initiator_imp(sc_module_name);

    template<typename CHAN>
    void                    operator()(CHAN& chan);
    template<typename CHAN>
    void                    bind(CHAN& chan);
    template<typename CLK, typename RST>
    void                    clk_rst(CLK& , RST&);

    virtual void            put(const T& v);
    virtual void            reset_put(cynw_tlm::tlm_tag<T>* t=0);
    virtual void            reset(); 

    sc_port<cynw_tlm::tlm_blocking_put_if<T> > p;
};


// *****************************************************************************
// This struct is the specialization for the signal-level configuration.
// *****************************************************************************
template<typename T, typename TRAITS>
struct put_initiator_imp<T,TRAITS,1>
    : sc_module
    , sc_interface
    , cynw_put_port_base<T>
{
    put_initiator_imp(sc_module_name);

    typedef put_initiator_imp<T,TRAITS,1>  this_type;
    typedef cynw_put_port_base<T>          base_type;

    template<typename CHAN>
    void                    operator()(CHAN& chan);
    template<typename CHAN>
    void                    bind(CHAN& chan);
    template<typename CLK, typename RST>
    void                    clk_rst(CLK&, RST&);

    virtual void            put(const T &v);
    virtual void            reset_put(cynw_tlm::tlm_tag<T>* t=0);
    virtual void            reset(); 

public:
    sc_in <bool>            clk;
    sc_in <bool>            rst;
//    sc_out<bool>            valid;
//    sc_out<T>               data;
//    sc_in <bool>            ready;

public:
    sc_signal<bool>         multiple_calls_in_rtl;
private:
    sc_signal<bool>         set_valid_curr;

    Sync_Snd<TRAITS>        sync_snd;
    Can_put_mod             can_put_mod;
    sc_signal<bool>         can_put_sig;

    bool                    multi_calls_in_cycle_var;
    sc_signal<bool>         multi_calls_in_cycle_sig; 

    inline void             set_valid() { set_valid_curr = !set_valid_curr; }

#ifndef STRATUS
    FLEX_CHANNELS_SAFETY_DECL;
    FLEX_CHANNELS_RESET_CHECK_DECL;
#endif
};


// ****************************************************************************
// This is the struct to be used in the SystemC designs. The TRAITS type 
// provides the definition level parameter.
// ****************************************************************************
template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct put_initiator : put_initiator_imp<T,TRAITS,TRAITS::Level> {
    put_initiator(sc_module_name n = sc_gen_unique_name("put_initiator"))
        : put_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};


// ---------------------------------------------------------------------------
// Internal method definitions
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Internal method definitions for put_initiator_imp (TLM)

template<typename T, typename TRAITS>
inline
put_initiator_imp<T,TRAITS,0>::put_initiator_imp(sc_module_name n) 
    : sc_module(n)
    , p("p")
{ }


template<typename T, typename TRAITS>
template<typename CHAN>
inline void            
put_initiator_imp<T,TRAITS,0>::operator()(CHAN& chan) { 
    p.bind(chan); 
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
put_initiator_imp<T,TRAITS,0>::bind(CHAN& chan) {
    operator()(chan);
}


template<typename T, typename TRAITS>
template<typename CLK, typename RST>
inline void
put_initiator_imp<T,TRAITS,0>::clk_rst(CLK& , RST&) { }


template<typename T, typename TRAITS>
inline void
put_initiator_imp<T,TRAITS,0>::put(const T& v) { 
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    OStrStream msg;
    msg << v;
    cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
    tr.record_attribute("put_data", OStrStream_string(msg));
#endif
    p->put(v); 
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    tr.end_transaction();
#endif
}


template<typename T, typename TRAITS>
inline void
put_initiator_imp<T,TRAITS,0>::reset_put(cynw_tlm::tlm_tag<T>* t) { 
    p->reset_put(); //Michele Petracca on 04/24/2015
}


template <typename T, typename TRAITS>
inline void
put_initiator_imp<T,TRAITS,0>::reset() {
    reset_put();
}


// ---------------------------------------------------------------------------
// Internal method definitions for put_initiator_imp (signal-level)

template<typename T, typename TRAITS>
inline 
put_initiator_imp<T,TRAITS,1>::put_initiator_imp(sc_module_name n)
    : sc_module(n)
    , clk("clk")
    , rst("rst")
//    , valid("valid")
//    , data("data")
//    , ready("ready")
    , multiple_calls_in_rtl("multiple_calls_in_rtl")
    , set_valid_curr("set_valid_curr")
    , sync_snd("sync_snd")
    , can_put_mod("can_put_mod")
    , can_put_sig("can_put_sig")
    , multi_calls_in_cycle_sig("multi_calls_in_cycle_sig")
#ifndef STRATUS
    , FLEX_CHANNELS_SAFETY_CTOR
    , FLEX_CHANNELS_RESET_CHECK_CTOR
#endif
{
    sync_snd.clk(clk);
    sync_snd.rst(rst);
    sync_snd.valid(base_type::valid);
    sync_snd.ready(base_type::ready);
    sync_snd.set_valid_curr(set_valid_curr);

    can_put_mod.ready(base_type::ready);
    can_put_mod.valid(base_type::valid);
    can_put_mod.can_put(can_put_sig);
}


template<typename T, typename TRAITS>
template<typename CHAN>
inline void 
put_initiator_imp<T,TRAITS,1>::operator()(CHAN& chan) {
    cynw_mark_hierarchical_binding(&chan);
    if (base_type::is_hierarchically_bound())
      sync_snd.set_is_hierarchicall_bound(true);
//    valid(chan.valid);
//    ready(chan.ready);
//    data (chan.data);
    base_type::bind(chan);
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
put_initiator_imp<T,TRAITS,1>::bind(CHAN& chan) {
    operator()(chan);
}


template<typename T, typename TRAITS>
template<typename CLK, typename RST>
inline void 
put_initiator_imp<T,TRAITS,1>::clk_rst(CLK& clk_in, RST& rst_in) {
    clk(clk_in);
    rst(rst_in);
}


template<typename T, typename TRAITS>
inline void 
put_initiator_imp<T,TRAITS,1>::put(const T &v) {
    FLEX_CHANNELS_RESET_CHECK;
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    OStrStream msg;
    msg << v;
    cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
    tr.record_attribute("put_data", OStrStream_string(msg));
#endif
    FLEX_CHANNELS_PROTOCOL(PUT_START) ;
    { HLS_DEFINE_PROTOCOL("PUT_PROTOCOL");
    if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
        if (multi_calls_in_cycle_var != multi_calls_in_cycle_sig) { 
#ifndef STRATUS
            wait();
#else
            if (TRAITS::Allow_Multiple_Calls_Per_Cycle_RTL) {
		wait();
            } else {
		multiple_calls_in_rtl = true;
            }
#endif
        }
    } else {
        FLEX_CHANNELS_SAFETY_CHECK("put()");
    }
    FLEX_CHANNELS_LABEL(WAIT_PUT)
   if ( HLS_INITIATION_INTERVAL > 0 ) {
     do { wait(); } while (!can_put_sig.read()); 
   } else {
     while (!can_put_sig.read())  wait();
   }

    set_valid();
    base_type::data = v;
    if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
        multi_calls_in_cycle_var = !multi_calls_in_cycle_var;
        multi_calls_in_cycle_sig = !multi_calls_in_cycle_sig;
    }
    } // HLS_DEFINE_PROTOCOL("PUT_PROTOCOL");
    FLEX_CHANNELS_PROTOCOL(PUT_END) ;
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    tr.end_transaction();
#endif
}


template<typename T, typename TRAITS>
inline void 
put_initiator_imp<T,TRAITS,1>::reset_put(cynw_tlm::tlm_tag<T>* t) {
    FLEX_CHANNELS_RESET_CALLED;
    if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
        multi_calls_in_cycle_var = 0;
        multi_calls_in_cycle_sig = 0;
        multiple_calls_in_rtl = 0;
    } else {
        FLEX_CHANNELS_SAFETY_RESET;
    }
    if (base_type::is_hierarchically_bound()) {
      // no reset
    } else
    if (TRAITS::ResetData) {
        base_type::data = T();
    }
    set_valid_curr = 0;
}


template <typename T, typename TRAITS>
inline void
put_initiator_imp<T,TRAITS,1>::reset() {
    reset_put();
}

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif


#endif

