//
// This file can be used to the replace the put/get initiators communicating inter-threads.
// The code can be used both CtoS and Cynthesizer.
// 
// Created by Xingri Li<xingri@cadence.com>
//

#ifndef PUT_GET_INTERNAL__H
#define PUT_GET_INTERNAL__H

#include <systemc.h>


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw {

// NB_PUT_INTERNAL
template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct nb_put_internal : nb_put_initiator_imp<T,TRAITS,TRAITS::Level> {
	HLS_METAPORT;
	HLS_EXPOSE_PORT(OFF, data);
	HLS_EXPOSE_PORT(OFF, ready);
	HLS_EXPOSE_PORT(OFF, valid);
    nb_put_internal(sc_module_name n = sc_gen_unique_name("nb_put_initiator")) 
        : nb_put_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};

// NB_GET_INTERNAL
template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct nb_get_internal : nb_get_initiator_imp<T,TRAITS,TRAITS::Level> {
	HLS_METAPORT;
	HLS_EXPOSE_PORT(OFF, data);
	HLS_EXPOSE_PORT(OFF, ready);
	HLS_EXPOSE_PORT(OFF, valid);
    nb_get_internal(sc_module_name n = sc_gen_unique_name("nb_get_initiator")) 
        : nb_get_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};

// PUT_INTERNAL
template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct put_internal : put_initiator_imp<T,TRAITS,TRAITS::Level> {
	HLS_METAPORT;
	HLS_EXPOSE_PORT(OFF, data);
	HLS_EXPOSE_PORT(OFF, ready);
	HLS_EXPOSE_PORT(OFF, valid);
    put_internal(sc_module_name n = sc_gen_unique_name("nb_put_initiator")) 
        : put_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};

// GET_INTERNAL
template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct get_internal : get_initiator_imp<T,TRAITS,TRAITS::Level> {
	HLS_METAPORT;
	HLS_EXPOSE_PORT(OFF, data);
	HLS_EXPOSE_PORT(OFF, ready);
	HLS_EXPOSE_PORT(OFF, valid);
    get_internal(sc_module_name n = sc_gen_unique_name("nb_get_initiator")) 
        : get_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};

// B_PUT_INTERNAL
template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct b_put_internal : b_put_initiator_imp<T,TRAITS,TRAITS::Level> {
	HLS_METAPORT;
	HLS_EXPOSE_PORT(OFF, data);
	HLS_EXPOSE_PORT(OFF, ready);
	HLS_EXPOSE_PORT(OFF, valid);
    b_put_internal(sc_module_name n = sc_gen_unique_name("nb_put_initiator")) 
        : b_put_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};

// NB_GET_INTERNAL
template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct b_get_internal : b_get_initiator_imp<T,TRAITS,TRAITS::Level> {
	HLS_METAPORT;
	HLS_EXPOSE_PORT(OFF, data);
	HLS_EXPOSE_PORT(OFF, ready);
	HLS_EXPOSE_PORT(OFF, valid);
    b_get_internal(sc_module_name n = sc_gen_unique_name("nb_get_initiator")) 
        : b_get_initiator_imp<T,TRAITS,TRAITS::Level>(n) 
    { }
};

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif


#endif
