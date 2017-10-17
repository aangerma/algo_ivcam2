// *****************************************************************************
// *****************************************************************************
// cynw_may_block_get_initiator.h
//
// This file contains the definition of may-block get initiator. 
// This initiator may take one or more clock cycle per get() transaction.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_MAY_BLOCK_GET_INITIATOR_H
#define CYNW_MAY_BLOCK_GET_INITIATOR_H

#include "cynw_put_get_port_base.h"

# include <stratus_hls.h>

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
template<typename T, typename TRAITS, bool LEVEL>
struct get_initiator_imp
{ };


// *****************************************************************************
// This struct is the specialization for the transaction-level configuration.
// *****************************************************************************
template<typename T, typename TRAITS>
struct get_initiator_imp<T,TRAITS,0>
    : sc_module
    , sc_interface
{
    HLS_METAPORT;

    get_initiator_imp(sc_module_name);

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

    sc_port<cynw_tlm::tlm_blocking_get_if<T> >    p;
};


// *****************************************************************************
// This struct is the specialization for the signal-level configuration.
// *****************************************************************************
template<typename T, typename TRAITS>
struct get_initiator_imp<T,TRAITS,1>
    : sc_module
    , sc_interface
    , cynw_get_port_base<T>
{
    get_initiator_imp(sc_module_name);

    typedef get_initiator_imp<T,TRAITS,1>  this_type;
    typedef cynw_get_port_base<T>          base_type;

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

public:
    sc_in <bool>            clk;
    sc_in <bool>            rst;
//    sc_in <bool>            valid;
//    sc_in <T>               data;
//    sc_out<bool>            ready;

public:
    sc_signal<bool>         multiple_calls_in_rtl;
private:
    sc_signal<bool>         set_ready_curr;
    sc_signal<T>            data_buf;

    Sync_Rcv<T,TRAITS>      sync_rcv;
    Can_get_mod             can_get_mod;
    sc_signal<bool>         can_get_sig;

    bool                    multi_calls_in_cycle_var; 
    sc_signal<bool>         multi_calls_in_cycle_sig;

    inline void             set_ready() { set_ready_curr = !set_ready_curr; }

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
struct get_initiator : get_initiator_imp<T,TRAITS,TRAITS::Level> {
    get_initiator(sc_module_name n = sc_gen_unique_name("get_initiator")) 
        : get_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};


// ---------------------------------------------------------------------------
// Internal method definitions
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Internal method definitions for get_initiator_imp (TLM)

template<typename T, typename TRAITS>
inline
get_initiator_imp<T,TRAITS,0>::get_initiator_imp(sc_module_name n) 
    : sc_module(n)
    , p("p")
{ }


template<typename T, typename TRAITS>
template<typename CHAN>
inline void            
get_initiator_imp<T,TRAITS,0>::operator()(CHAN& chan) {
    p.bind(chan); 
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
get_initiator_imp<T,TRAITS,0>::bind(CHAN& chan) {
    operator()(chan);
}


template<typename T, typename TRAITS>
template<typename CLK, typename RST>
inline void
get_initiator_imp<T,TRAITS,0>::clk_rst(CLK&, RST&) { }


template<typename T, typename TRAITS>
inline void    
get_initiator_imp<T,TRAITS,0>::get(T& v) { 
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


template<typename T, typename TRAITS>
inline T
get_initiator_imp<T,TRAITS,0>::get(cynw_tlm::tlm_tag<T>* t) { 
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
#endif
    T v = p->get(t); 
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    OStrStream msg;
    msg << v;
    tr.record_attribute("get_data", OStrStream_string(msg));
    tr.end_transaction();
#endif
    return v;
}

 
template<typename T, typename TRAITS>
inline void
get_initiator_imp<T,TRAITS,0>::reset_get(cynw_tlm::tlm_tag<T>* t) { 
    p->reset_get(); //Michele Petracca on 04/24/2015
}


template <typename T, typename TRAITS>
inline void
get_initiator_imp<T,TRAITS,0>::reset() {
    reset_get();
}


// ---------------------------------------------------------------------------
// Internal method definitions for get_initiator_imp (signal-level)

template <typename T, typename TRAITS>
inline
get_initiator_imp<T,TRAITS,1>::get_initiator_imp(sc_module_name n)
    : sc_module(n)
    , clk("clk")
    , rst("rst")
//    , valid("valid")
//    , data("data")
//    , ready("ready")
    , multiple_calls_in_rtl("multiple_calls_in_rtl")
    , set_ready_curr("set_ready_curr")
    , data_buf("data_buf")
    , sync_rcv("sync_rcv")
    , can_get_mod("can_get_mod")
    , can_get_sig("can_get_sig")
    , multi_calls_in_cycle_sig("multi_calls_in_cycle_sig") 

#ifndef STRATUS
    , FLEX_CHANNELS_SAFETY_CTOR
    , FLEX_CHANNELS_RESET_CHECK_CTOR
#endif
{
    sync_rcv.clk(clk);
    sync_rcv.rst(rst);
    sync_rcv.valid(base_type::valid);
    sync_rcv.ready(base_type::ready);
    sync_rcv.set_ready_curr(set_ready_curr);
    sync_rcv.data(base_type::data);
    sync_rcv.data_buf(data_buf);

    can_get_mod.ready(base_type::ready);
    can_get_mod.valid(base_type::valid);
    can_get_mod.can_get(can_get_sig);
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
get_initiator_imp<T,TRAITS,1>::operator()(CHAN& chan) {
    cynw_mark_hierarchical_binding(&chan);
    if (base_type::is_hierarchically_bound())
      sync_rcv.set_is_hierarchicall_bound(true);
//    valid(chan.valid);
//    ready(chan.ready);
//    data (chan.data );
    base_type::bind(chan);
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
get_initiator_imp<T,TRAITS,1>::bind(CHAN& chan) {
    operator()(chan);
}


template <typename T, typename TRAITS>
template<typename CLK, typename RST>
inline void 
get_initiator_imp<T,TRAITS,1>::clk_rst(CLK& clk_in, RST& rst_in) {
    clk (clk_in);
    rst (rst_in);
}


template<typename T, typename TRAITS>
inline void    
get_initiator_imp<T,TRAITS,1>::get(T& v) { 
    v = get(NULL);
}


template <typename T, typename TRAITS>
inline T 
get_initiator_imp<T,TRAITS,1>::get(cynw_tlm::tlm_tag<T>* t) {
    FLEX_CHANNELS_RESET_CHECK;
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
#endif
    FLEX_CHANNELS_PROTOCOL(GET_START) ; 
    T item; // Changed
    { HLS_DEFINE_PROTOCOL("GET_PROTOCOL");
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
        FLEX_CHANNELS_SAFETY_CHECK("get()");
    }
    FLEX_CHANNELS_LABEL(WAIT_GET)

   if ( HLS_INITIATION_INTERVAL > 0 ) { 
     do { wait(); } while (!can_get_sig.read()) ;
   } else {
     while (!can_get_sig.read())  wait();
   }
 
    //T item; // Changed
    set_ready();
    if (base_type::ready) {
        sc_assert(base_type::valid);
        item = base_type::data.read();
    } else {
        item = data_buf.read();
    }
    if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
        multi_calls_in_cycle_var = !multi_calls_in_cycle_var;
        multi_calls_in_cycle_sig = !multi_calls_in_cycle_sig;
    }
    } // End of HLS_DEFINE_PROTOCOL("GET_PROTOCOL")
    FLEX_CHANNELS_PROTOCOL(GET_END) ;

#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    OStrStream msg;
    msg << item;
    tr.record_attribute("get_data", OStrStream_string(msg));
    tr.end_transaction();
#endif
    return item;
}


template <typename T, typename TRAITS>
inline void 
get_initiator_imp<T,TRAITS,1>::reset_get(cynw_tlm::tlm_tag<T>* t) {
    FLEX_CHANNELS_RESET_CALLED;
    set_ready_curr = 0;
    if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
        multi_calls_in_cycle_var = 0;
        multi_calls_in_cycle_sig = 0;
        multiple_calls_in_rtl = 0;
    } else {
        FLEX_CHANNELS_SAFETY_RESET;
    }
}


template <typename T, typename TRAITS>
inline void
get_initiator_imp<T,TRAITS,1>::reset() {
    reset_get();
}

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif


#endif

