// *****************************************************************************
// *****************************************************************************
// cynw_non_blocking_put_initiator.h
//
// This file contains the definition of never-block put initiator. 
// These initiators always return immediatly when calling nb_put().
// No clock cycles are ever consumed by these initiators. 
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_NON_BLOCKING_PUT_INITIATOR_H
#define CYNW_NON_BLOCKING_PUT_INITIATOR_H

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
struct nb_put_initiator_imp 
{ };


// *****************************************************************************
// This struct is the specialization for the transaction-level configuration.
// *****************************************************************************
template<typename T, typename TRAITS>
struct nb_put_initiator_imp<T, TRAITS, 0>
    : sc_module
    , sc_interface
{
    HLS_METAPORT;

    nb_put_initiator_imp(sc_module_name);

    template<typename CHAN>
    void                    operator()(CHAN& chan);
    template<typename CHAN>
    void                    bind(CHAN& chan);
    template<typename CLK, typename RST>
    void                    clk_rst(CLK clk_in, RST rst_in);

    virtual bool            nb_put(const T &v);
    virtual bool            nb_can_put(cynw_tlm::tlm_tag<T>* t=0) const;
    virtual const sc_event& ok_to_put (cynw_tlm::tlm_tag<T>* t=0) const;
    virtual void            reset_put (cynw_tlm::tlm_tag<T>* t=0);
    virtual void            reset(); 

    sc_port<cynw_tlm::tlm_nonblocking_put_if<T> > p;
};


// *****************************************************************************
// This struct is the specialization for the signal-level configuration.
// *****************************************************************************
template<typename T, typename TRAITS>
struct nb_put_initiator_imp<T, TRAITS, 1>
    : sc_module
    , sc_interface
    , cynw_put_port_base<T>
{
    nb_put_initiator_imp(sc_module_name);
    typedef nb_put_initiator_imp<T, TRAITS, 1> this_type;
    typedef cynw_put_port_base<T>              base_type;

    template<typename CHAN>
    void                    operator()(CHAN& chan);
    template<typename CHAN>
    void                    bind(CHAN& chan);
    template<typename CLK, typename RST>
    void                    clk_rst(CLK& clk_in, RST& rst_in);

    virtual bool            nb_put(const T &v);
    virtual bool            nb_can_put(cynw_tlm::tlm_tag<T>* t=0) const;
    virtual const sc_event& ok_to_put (cynw_tlm::tlm_tag<T>* t=0) const;
    virtual void            reset_put (cynw_tlm::tlm_tag<T>* t=0);
    virtual void            reset(); 

public:
    sc_in <bool>            clk;
    sc_in <bool>            rst;
//    sc_out<bool>            valid;
//    sc_out<T>               data;
//    sc_in <bool>            ready;

private:
    sc_signal<bool>         set_valid_curr;

    Sync_Snd<TRAITS>        sync_snd;
    Can_put_mod             nb_can_put_mod1;
    sc_signal<bool>         nb_can_put_sig1;
    Can_put_mod             nb_can_put_mod2;
    sc_signal<bool>         nb_can_put_sig2;

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
struct nb_put_initiator : nb_put_initiator_imp<T,TRAITS,TRAITS::Level> {
    nb_put_initiator(sc_module_name n = sc_gen_unique_name("nb_put_initiator"))
        : nb_put_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};


// ---------------------------------------------------------------------------
// Internal method definitions
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Internal method definitions for nb_put_initiator_imp (TLM)

template<typename T, typename TRAITS>
inline
nb_put_initiator_imp<T,TRAITS,0>:: nb_put_initiator_imp(sc_module_name n) 
    : sc_module(n) 
    , p("p")
{ }


template<typename T, typename TRAITS>
template<typename CHAN_T>
inline void 
nb_put_initiator_imp<T,TRAITS,0>::operator()(CHAN_T& chan) { 
    p.bind(chan);
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
nb_put_initiator_imp<T,TRAITS,0>::bind(CHAN& chan) {
    operator()(chan);
}


template<typename T, typename TRAITS>
template<typename CLK_T, typename RST_T>
inline void 
nb_put_initiator_imp<T,TRAITS,0>::clk_rst(CLK_T clk_in, RST_T rst_in) 
{ }


template<typename T, typename TRAITS>
inline bool 
nb_put_initiator_imp<T,TRAITS,0>::nb_put(const T &v) {
    bool result = p->nb_put(v); 
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    if (result) {
        OStrStream msg;
        msg << v;
        cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
        tr.record_attribute("nb_put_data", OStrStream_string(msg));
        tr.end_transaction();
    }
#endif
    return result;
}


template<typename T, typename TRAITS>
inline bool 
nb_put_initiator_imp<T,TRAITS,0>::nb_can_put(cynw_tlm::tlm_tag<T>* t) const {
    return p->nb_can_put(t);
}


template<typename T, typename TRAITS>
inline const sc_event&
nb_put_initiator_imp<T,TRAITS,0>::ok_to_put( cynw_tlm::tlm_tag<T>* t) const {
    return p->ok_to_put();
}


template<typename T, typename TRAITS>
inline void 
nb_put_initiator_imp<T,TRAITS,0>::reset_put(cynw_tlm::tlm_tag<T>* t) { 
    p->reset_put(); //Michele Petracca on 04/24/2015
}


template <typename T, typename TRAITS>
inline void
nb_put_initiator_imp<T,TRAITS,0>::reset() {
    reset_put();
}


// ---------------------------------------------------------------------------
// Internal method definitions for nb_put_initiator_imp (signal-level)

template<typename T, typename TRAITS>
inline 
nb_put_initiator_imp<T,TRAITS,1>::nb_put_initiator_imp(sc_module_name n) 
    : sc_module(n)
    , clk("clk")
    , rst("rst")
//    , valid("valid")
//    , data("data")
//    , ready("ready")
    , set_valid_curr("set_valid_curr")
    , sync_snd("sync_snd")
    , nb_can_put_mod1("nb_can_put_mod1")
    , nb_can_put_sig1("nb_can_put_sig1")
    , nb_can_put_mod2("nb_can_put_mod2")
    , nb_can_put_sig2("nb_can_put_sig2")
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

    nb_can_put_mod1.ready(base_type::ready);
    nb_can_put_mod1.valid(base_type::valid);
    nb_can_put_mod1.can_put(nb_can_put_sig1);
    nb_can_put_mod2.ready(base_type::ready);
    nb_can_put_mod2.valid(base_type::valid);
    nb_can_put_mod2.can_put(nb_can_put_sig2);
}


template<typename T,typename TRAITS>
template<typename CHAN>
inline void 
nb_put_initiator_imp<T,TRAITS,1>::operator()(CHAN& chan) {
    cynw_mark_hierarchical_binding(&chan);
    if (base_type::is_hierarchically_bound())
      sync_snd.set_is_hierarchicall_bound(true);
//    valid(chan.valid);
//    ready(chan.ready);
//    data (chan.data );
  base_type::bind(chan);
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
nb_put_initiator_imp<T,TRAITS,1>::bind(CHAN& chan) {
    operator()(chan);
}


template<typename T,typename TRAITS>
template<typename CLK, typename RST>
inline void 
nb_put_initiator_imp<T,TRAITS,1>::clk_rst(CLK& clk_in, RST& rst_in) {
    clk(clk_in);
    rst(rst_in);
}


template<typename T, typename TRAITS>
inline bool 
nb_put_initiator_imp<T,TRAITS,1>::nb_put(const T &v) {
    FLEX_CHANNELS_RESET_CHECK;
    FLEX_CHANNELS_PROTOCOL(NB_PUT_START) ;
    bool result; // Changed
    { HLS_DEFINE_PROTOCOL("NB_PUT_PROTOCOL"); // Added
    if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
        if (multi_calls_in_cycle_var != multi_calls_in_cycle_sig) {
            return false;
        }
    } else {
        FLEX_CHANNELS_SAFETY_CHECK("nb_put()");
    }
    //bool result; // Changed
    if (!nb_can_put_sig2.read()) {
        result = false;
    }  else {
        set_valid();
        base_type::data = v;
        result = true;
        if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
            multi_calls_in_cycle_var = ! multi_calls_in_cycle_var;
            multi_calls_in_cycle_sig = ! multi_calls_in_cycle_sig;
        }
    }
    } // End of HLS_DEFINE_PROTOCOL("NB_PUT_PROTOCOL")
    FLEX_CHANNELS_PROTOCOL(NB_PUT_END) ;
#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
    if (result) {
        OStrStream msg;
        msg << v;
        cve_tr_handle tr = cve_tr_begin(this->basename(), this->name());
        tr.record_attribute("nb_put_data", OStrStream_string(msg));
        tr.end_transaction();
    }
#endif
    return result; 
}


template<typename T, typename TRAITS>
inline bool 
nb_put_initiator_imp<T,TRAITS,1>::nb_can_put(cynw_tlm::tlm_tag<T>* t) const {
    FLEX_CHANNELS_RESET_CHECK;
    if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
        if (multi_calls_in_cycle_var != multi_calls_in_cycle_sig) { 
            return false;
        }
    } else {
        FLEX_CHANNELS_CAN_SAFETY_CHECK("nb_can_put()","nb_put()");
    }
    return nb_can_put_sig1.read();
}


template<typename T,typename TRAITS>
inline const sc_event&
nb_put_initiator_imp<T,TRAITS,1>::ok_to_put(cynw_tlm::tlm_tag<T>* t) const {
    sc_assert(false); sc_event* e=NULL; return *e;
}


template<typename T,typename TRAITS>
inline void 
nb_put_initiator_imp<T,TRAITS,1>::reset_put(cynw_tlm::tlm_tag<T>* t) {
    FLEX_CHANNELS_SAFETY_RESET;
    FLEX_CHANNELS_RESET_CALLED;
    if (base_type::is_hierarchically_bound()) {
      // no reset
    } else
    if (TRAITS::ResetData) {
        base_type::data = T(); 
    }
    set_valid_curr = 0;
    if (TRAITS::Allow_Multiple_Calls_Per_Cycle) {
        multi_calls_in_cycle_var = 0;
        multi_calls_in_cycle_sig = 0;
    }
}


template <typename T,typename TRAITS>
inline void
nb_put_initiator_imp<T,TRAITS,1>::reset() {
    reset_put();
}

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif


#endif

