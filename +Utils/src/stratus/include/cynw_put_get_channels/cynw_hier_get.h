// *****************************************************************************
// *****************************************************************************
// cynw_hier_get_initiator.h
//
// This file contains the definition of hierarchical get initiators. 
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_HIER_GET_INITIATOR_H
#define CYNW_HIER_GET_INITIATOR_H

#include "../cynw_flex_channels_default_traits.h"
#include "../cynw_tlm/cynw_tlm.h"

#include <stratus_hls.h>

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
struct hier_get_initiator_imp
{ };


// *****************************************************************************
// This struct is the specialization for the transaction-level configuration.
// *****************************************************************************
template<typename T, typename TRAITS>
struct hier_get_initiator_imp<T, TRAITS, 0> 
    : virtual cynw_tlm::tlm_get_peek_if<T>
    , sc_module
{
    HLS_METAPORT;

    hier_get_initiator_imp(sc_module_name);

    template<typename CHAN>
    void                    operator()(CHAN& chan);
    template<typename CHAN>
    void                    bind(CHAN& chan);

    virtual void            get(T& v);
    virtual T               get(cynw_tlm::tlm_tag<T>* t=0);
    virtual bool            nb_get(T &v);
    virtual bool            nb_can_get(cynw_tlm::tlm_tag<T>* t=0) const;

    virtual void            reset_get (cynw_tlm::tlm_tag<T>* t=0);
    virtual const sc_event& ok_to_get (cynw_tlm::tlm_tag<T>* t=0) const;

    virtual T               peek(cynw_tlm::tlm_tag<T>* t=0) const;
    virtual void            peek(T &v) const;
    virtual bool            nb_can_peek(cynw_tlm::tlm_tag<T>* t=0) const;
    virtual bool            nb_peek(T& v) const;
    virtual const sc_event& ok_to_peek (cynw_tlm::tlm_tag<T>* t=0) const;

    sc_port<cynw_tlm::tlm_get_peek_if<T> > p;
};


// *****************************************************************************
// This struct is the specialization for the signal-level configuration.
// *****************************************************************************
template<typename T, typename TRAITS>
struct hier_get_initiator_imp<T,TRAITS,1> 
    : sc_interface
{
    HLS_METAPORT; // Added
    hier_get_initiator_imp(sc_module_name);

    template<typename CHAN>
    void                    operator()(CHAN& ch);
    template<typename CHAN>
    void                    bind(CHAN& chan);

    sc_in <bool>            valid;
    sc_out<bool>            ready;
    sc_in <T>               data;
    std::string             _name;
    std::string             name() { return _name; }
};


// ****************************************************************************
// This is the struct to be used in the SystemC designs. The TRAITS type 
// provides the definition level parameter.
// ****************************************************************************
template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct hier_get_initiator : hier_get_initiator_imp<T,TRAITS,TRAITS::Level> {
    hier_get_initiator(sc_module_name n = sc_gen_unique_name("hier_get_initiator")) 
        : hier_get_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};


// ---------------------------------------------------------------------------
// Internal method definitions
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Internal method definitions for hier_get_initiator_imp (TLM)

template<typename T, typename TRAITS>
inline
hier_get_initiator_imp<T,TRAITS,0>::hier_get_initiator_imp(sc_module_name n)
    : sc_module(n)
    , p("p")
{ } 


template<typename T, typename TRAITS>
template<typename CHAN>
inline void 
hier_get_initiator_imp<T,TRAITS,0>::operator()(CHAN& chan) { 
    p.bind(chan); 
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
hier_get_initiator_imp<T,TRAITS,0>::bind(CHAN& chan) {
    operator()(chan);
}


template<typename T, typename TRAITS>
inline void
hier_get_initiator_imp<T,TRAITS,0>::get(T& v) { 
    p->get(v); 
}


template<typename T, typename TRAITS>
inline T
hier_get_initiator_imp<T,TRAITS,0>::get(cynw_tlm::tlm_tag<T>* t) { 
    return p->get(t); 
} 


template<typename T, typename TRAITS>
inline bool
hier_get_initiator_imp<T,TRAITS,0>::nb_can_get(cynw_tlm::tlm_tag<T>* t) const {
    return p->nb_can_get(t);
}
   

template<typename T, typename TRAITS>
inline void
hier_get_initiator_imp<T,TRAITS,0>::reset_get(cynw_tlm::tlm_tag<T>* t) { 
    p->reset_get(); //Michele Petracca on 04/24/2015
}


template<typename T, typename TRAITS>
inline bool
hier_get_initiator_imp<T,TRAITS,0>::nb_get(T &v) { 
    return p->nb_get(v); 
}


template<typename T, typename TRAITS>
inline const sc_event&
hier_get_initiator_imp<T,TRAITS,0>::ok_to_get(cynw_tlm::tlm_tag<T>* t) const { 
    return p->ok_to_get(); 
}


template<typename T, typename TRAITS>
inline T
hier_get_initiator_imp<T,TRAITS,0>::peek(cynw_tlm::tlm_tag<T>* t) const {
    return p->peek(t);
}


template<typename T, typename TRAITS>
inline void
hier_get_initiator_imp<T,TRAITS,0>::peek(T& v) const {
    p->peek(v);
}


template<typename T, typename TRAITS>
inline bool
hier_get_initiator_imp<T,TRAITS,0>::nb_can_peek(cynw_tlm::tlm_tag<T>* t) const {
    return p->nb_can_peek(t);
}


template<typename T, typename TRAITS>
inline bool
hier_get_initiator_imp<T,TRAITS,0>::nb_peek(T& v) const { 
    return p->nb_peek(v); 
}


template<typename T, typename TRAITS>
inline const sc_event&
hier_get_initiator_imp<T,TRAITS,0>::ok_to_peek(cynw_tlm::tlm_tag<T>* t) const { 
    return p->ok_to_peek(); 
}


// ---------------------------------------------------------------------------
// Internal method definitions for hier_get_initiator_imp (signal-level)

template<typename T, typename TRAITS>
inline
hier_get_initiator_imp<T,TRAITS,1>::hier_get_initiator_imp(sc_module_name n)
    : _name(n)
    , valid( HLS_CAT_NAMES(n,"valid") )
    , ready( HLS_CAT_NAMES(n,"ready") )
    , data ( HLS_CAT_NAMES(n,"data") ) 
{ }


template<typename T, typename TRAITS>
template<typename CHAN>
inline void 
hier_get_initiator_imp<T,TRAITS,1>::operator()(CHAN& chan) {
    valid(chan.valid);
    ready(chan.ready);
    data (chan.data);
}


template <typename T, typename TRAITS>
template<typename CHAN>
inline void 
hier_get_initiator_imp<T,TRAITS,1>::bind(CHAN& chan) {
    operator()(chan);
}

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif

#endif

