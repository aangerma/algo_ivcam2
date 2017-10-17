// *****************************************************************************
// *****************************************************************************
// cynw_non_blocking_get_peek_initiator.h
//
// This file contains the definition of never-block get-peek initiator. 
// These initiators always return immediatly when calling nb_get() or nb_peek(). 
// No clock cycles are ever consumed by these initiators. 
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_NON_BLOCKING_GET_PEEK_INITIATOR_H
#define CYNW_NON_BLOCKING_GET_PEEK_INITIATOR_H

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
template<typename T, typename TRAITS, bool LEVEL>
struct nb_get_peek_initiator_imp
{ };


// *****************************************************************************
// This struct is the specialization for the transaction-level configuration.
// *****************************************************************************
template<typename T, typename TRAITS>
struct nb_get_peek_initiator_imp<T,TRAITS,0> 
    : sc_module
    , sc_interface
{
    HLS_METAPORT;

    nb_get_peek_initiator_imp(sc_module_name);

    template<typename CHAN>
    void                    operator()(CHAN& chan);
    template<typename CHAN>
    void                    bind(CHAN& chan);
    template<typename CLK, typename RST>
    void                    clk_rst (CLK&, RST&);

    virtual bool            nb_get(T& v);
    virtual bool            nb_can_get(cynw_tlm::tlm_tag<T>* t=0) const;
    virtual const sc_event& ok_to_get (cynw_tlm::tlm_tag<T>* t=0) const;

    virtual bool            nb_peek(T& v) const;
    virtual bool            nb_can_peek(cynw_tlm::tlm_tag<T>* t=0) const;
    virtual const sc_event& ok_to_peek (cynw_tlm::tlm_tag<T>* t=0) const;

    virtual void            reset_get (cynw_tlm::tlm_tag<T>* t=0);
    virtual void            reset(); 

    sc_port<cynw_tlm::tlm_nonblocking_get_peek_if<T> > p;
};


// *****************************************************************************
// This struct is the specialization for the signal-level configuration.
// *****************************************************************************
template<typename T, typename TRAITS>
struct nb_get_peek_initiator_imp<T,TRAITS,1> 
    : sc_module
    , sc_interface
    , cynw_get_port_base<T>
{
    nb_get_peek_initiator_imp(sc_module_name);

    typedef nb_get_peek_initiator_imp<T,TRAITS,1>  this_type;
    typedef cynw_get_port_base<T>                  base_type;

    template<typename CHAN>
    void                    operator()(CHAN& chan); 
    template<typename CHAN>
    void                    bind(CHAN& chan);
    template<typename CLK, typename RST>
    void                    clk_rst(CLK&, RST&);

    virtual bool            nb_get(T& v);
    virtual bool            nb_can_get(cynw_tlm::tlm_tag<T>* t=0) const;
    virtual const sc_event& ok_to_get(cynw_tlm::tlm_tag<T>*  t=0) const;

    virtual bool            nb_peek(T& v) const;
    virtual bool            nb_can_peek(cynw_tlm::tlm_tag<T>* t=0) const;
    virtual const sc_event& ok_to_peek(cynw_tlm::tlm_tag<T>*  t=0) const;

    virtual void            reset_get(cynw_tlm::tlm_tag<T>*  t=0);
    virtual void            reset(); 

public:
    sc_in <bool>            clk;
    sc_in <bool>            rst;
//    sc_in <bool>            valid;
//    sc_in <T>               data;
//    sc_out<bool>            ready;

private:
    sc_signal<bool>         set_ready_curr;
    sc_signal<T>            data_buf;

    Sync_Rcv<T,TRAITS>      sync_rcv;
    Can_get_mod             nb_can_get_mod1;
    Can_get_mod             nb_can_get_mod2;

    sc_signal<bool>         nb_can_get_sig1;
    sc_signal<bool>         nb_can_get_sig2;

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
struct nb_get_peek_initiator 
    : nb_get_peek_initiator_imp<T,TRAITS,TRAITS::Level> 
{
    nb_get_peek_initiator(sc_module_name n = sc_gen_unique_name("nb_get_peek_initiator"))
        : nb_get_peek_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};


// ---------------------------------------------------------------------------
// Internal method definitions
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Internal method definitions for nb_get_peek_initiator_imp (TLM)

template <typename T, typename TRAITS>
inline
nb_get_peek_initiator_imp<T,TRAITS,0>::nb_get_peek_initiator_imp(sc_module_name n) 
    : sc_module(n)
    , p("p")
{ }


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
nb_get_peek_initiator_imp<T,TRAITS,0>::operator()(CHAN& chan) { 
    p.bind(chan); 
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
nb_get_peek_initiator_imp<T,TRAITS,0>::bind(CHAN& chan) {
    operator()(chan);
}


template <typename T, typename TRAITS>
template<typename CLK, typename RST>
inline void 
nb_get_peek_initiator_imp<T,TRAITS,0>::clk_rst(CLK&, RST&) { }


template <typename T, typename TRAITS>
inline bool
nb_get_peek_initiator_imp<T,TRAITS,0>::nb_get(T& v) {
    bool result = p->nb_get(v);
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    if (result) {
        OStrStream msg;
        msg << v;
        cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
        tr.record_attribute("nb_get_data", OStrStream_string(msg));
        tr.end_transaction();
    }
#endif
    return result;
}


template <typename T, typename TRAITS>
inline bool 
nb_get_peek_initiator_imp<T,TRAITS,0>::nb_can_get(cynw_tlm::tlm_tag<T>* t) const {
    return p->nb_can_get(t);
}


template <typename T, typename TRAITS>
inline const sc_event&
nb_get_peek_initiator_imp<T,TRAITS,0>::ok_to_get(cynw_tlm::tlm_tag<T>* t) const {
    return p->ok_to_get(t);    
}


template <typename T, typename TRAITS>
inline bool
nb_get_peek_initiator_imp<T,TRAITS,0>::nb_peek(T &v) const {
    return p->nb_peek(v);
}


template <typename T, typename TRAITS>
inline bool
nb_get_peek_initiator_imp<T,TRAITS,0>::nb_can_peek(cynw_tlm::tlm_tag<T>* t) const {
    return p->nb_can_peek(t); 
}


template<typename T, typename TRAITS>
inline const sc_event&
nb_get_peek_initiator_imp<T,TRAITS,0>::ok_to_peek(cynw_tlm::tlm_tag<T>* t) const {
    return p->ok_to_peek(t); 
}


template <typename T, typename TRAITS>
inline void 
nb_get_peek_initiator_imp<T,TRAITS,0>::reset_get(cynw_tlm::tlm_tag<T>* t) { 
    p->reset_get(); //Michele Petracca on 04/24/2015
}


template <typename T, typename TRAITS>
inline void
nb_get_peek_initiator_imp<T,TRAITS,0>::reset() {
    reset_get();
}


// ---------------------------------------------------------------------------
// Internal method definitions for nb_get_peek_initiator_imp (signal-level)

template <typename T, typename TRAITS>
inline
nb_get_peek_initiator_imp<T,TRAITS,1>::nb_get_peek_initiator_imp(sc_module_name n)
    : sc_module(n)
    , clk("clk")
    , rst("rst")
//    , valid("valid")
//    , data("data")
//    , ready("ready")
    , set_ready_curr("set_ready_curr")
    , data_buf("data_buf")
    , sync_rcv("sync_rcv")
    , nb_can_get_mod1("nb_can_get_mod1")
    , nb_can_get_sig1("nb_can_get_sig1")
    , nb_can_get_mod2("nb_can_get_mod2")
    , nb_can_get_sig2("nb_can_get_sig2")
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

    nb_can_get_mod1.ready(base_type::ready);
    nb_can_get_mod1.valid(base_type::valid);
    nb_can_get_mod1.can_get(nb_can_get_sig1);
    nb_can_get_mod2.ready(base_type::ready);
    nb_can_get_mod2.valid(base_type::valid);
    nb_can_get_mod2.can_get(nb_can_get_sig2);
}


template<typename T, typename TRAITS>
template<typename CHAN>
inline void 
nb_get_peek_initiator_imp<T,TRAITS,1>::operator()(CHAN& chan) {
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
nb_get_peek_initiator_imp<T,TRAITS,1>::bind(CHAN& chan) {
    operator()(chan);
}


template<typename T, typename TRAITS>
template<typename CLK, typename RST>
inline void 
nb_get_peek_initiator_imp<T,TRAITS,1>::clk_rst(CLK& clk_in, RST& rst_in) {
    clk(clk_in);
    rst(rst_in);
}


template<typename T, typename TRAITS>
inline bool 
nb_get_peek_initiator_imp<T,TRAITS,1>::nb_get(T &v) {
    FLEX_CHANNELS_RESET_CHECK;
    FLEX_CHANNELS_PROTOCOL(NB_GET_START) ;
    bool result;
    { HLS_DEFINE_PROTOCOL("NB_GET_PROTOCOL") ;
    if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
        if (multi_calls_in_cycle_var != multi_calls_in_cycle_sig) {
            return false;
        }
    } else {
        FLEX_CHANNELS_SAFETY_CHECK("nb_get()");
    }
    if (!nb_can_get_sig2.read()) {
        result = false;
    } else {
        if (base_type::ready) {
            sc_assert(base_type::valid);
            v = base_type::data;
        } else {
            v = data_buf;
        }
        set_ready();
        result = true;
        if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
            multi_calls_in_cycle_var = ! multi_calls_in_cycle_var;
            multi_calls_in_cycle_sig = ! multi_calls_in_cycle_sig;
        }
    }
    } // HLS_DEFINE_PROTOCOL("NB_GET_PROTOCOL") ;
    FLEX_CHANNELS_PROTOCOL(NB_GET_END) ;
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    if (result) {
        OStrStream msg;
        msg << v;
        cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
        tr.record_attribute("nb_get_data", OStrStream_string(msg));
        tr.end_transaction();
    }
#endif
    return result;
}


template<typename T, typename TRAITS>
inline bool 
nb_get_peek_initiator_imp<T,TRAITS,1>::nb_can_get(cynw_tlm::tlm_tag<T>* t) const {
    FLEX_CHANNELS_RESET_CHECK;
    if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
        if (multi_calls_in_cycle_var != multi_calls_in_cycle_sig) {
            return false;
        }
    } else {
        FLEX_CHANNELS_CAN_SAFETY_CHECK("nb_can_get()","nb_get()");
    }
    return nb_can_get_sig1.read();
}


template<typename T, typename TRAITS>
inline const sc_event&
nb_get_peek_initiator_imp<T,TRAITS,1>::ok_to_get(cynw_tlm::tlm_tag<T>* t) const {
    sc_assert(false); sc_event* e; return *e;
}


template <typename T, typename TRAITS>
inline bool
nb_get_peek_initiator_imp<T,TRAITS,1>::nb_peek(T& v) const {
    FLEX_CHANNELS_RESET_CHECK;
    FLEX_CHANNELS_PROTOCOL(NB_PEEK_START) ;
    bool result;
    { HLS_DEFINE_PROTOCOL("NB_PEEK_PROTOCOL") ;
    if (!nb_can_get_sig2.read()) {
        result = false;
    } else {
        // do not consume the data
        if (base_type::ready) {
            sc_assert(base_type::valid);
            v = base_type::data;
        } else {
            v = data_buf;
        }
        result = true;
    }
    } // HLS_DEFINE_PROTOCOL("NB_PEEK_PROTOCOL") ;
    FLEX_CHANNELS_PROTOCOL(NB_PEEK_END) ;
    return result;
}


template <typename T, typename TRAITS>
inline bool
nb_get_peek_initiator_imp<T,TRAITS,1>::nb_can_peek(cynw_tlm::tlm_tag<T>* t) const {
    return nb_can_get(); 
}


template<typename T, typename TRAITS>
inline const sc_event&
nb_get_peek_initiator_imp<T,TRAITS,1>::ok_to_peek(cynw_tlm::tlm_tag<T>* t) const {
    sc_assert(false); sc_event* e; return *e;
}


template<typename T, typename TRAITS>
inline void 
nb_get_peek_initiator_imp<T,TRAITS,1>::reset_get(cynw_tlm::tlm_tag<T>* t) {
    FLEX_CHANNELS_SAFETY_RESET;
    FLEX_CHANNELS_RESET_CALLED;
    set_ready_curr = 0;
    if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
        multi_calls_in_cycle_var = 0;
        multi_calls_in_cycle_sig = 0;
    }
}


template <typename T, typename TRAITS>
inline void
nb_get_peek_initiator_imp<T,TRAITS,1>::reset() {
    reset_get();
}

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif


#endif

