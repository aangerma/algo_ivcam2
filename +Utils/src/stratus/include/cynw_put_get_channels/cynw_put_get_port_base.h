/*
 *   cynw_put_get_port_base.h   oshima@cadence 140909
 */

#ifndef CYNW_PUT_GET_PORT_BASE__H
#define CYNW_PUT_GET_PORT_BASE__H

# include <stratus_hls.h>
# include "cynw_comm_util.h"


#if defined STRATUS 
#pragma hls_ip_def
#endif	


namespace cynw {

template<typename T>
struct cynw_put_port_base
: cynw_hier_bind_detector
{
    HLS_METAPORT;
    typedef cynw_put_port_base<T>  this_type;
    sc_out<bool>            valid;
    sc_out<T>               data;
    sc_in<bool>             ready;

    cynw_put_port_base(const char* name = "")
    : valid(HLS_CAT_NAMES(name,"valid"))
    , data(HLS_CAT_NAMES(name,"data"))
    , ready(HLS_CAT_NAMES(name,"ready"))
    {}

    template<typename T_CHAN>
    void bind(T_CHAN& chan) 
    {
      cynw_mark_hierarchical_binding(&chan);
      valid(chan.valid);
      data(chan.data);
      ready(chan.ready);
    }
    template<typename T_CHAN>
    void operator() (T_CHAN& chan) 
    {
      bind(chan);
    }
    
    friend void sc_trace(sc_trace_file* tf, const this_type& obj, const std::string& n)
    {
      sc_trace( tf, obj.valid, n + ".valid" );
      sc_trace( tf, obj.data, n + ".data" );
      sc_trace( tf, obj.ready, n + ".ready" );
    }
};


template<typename T>
struct cynw_get_port_base
: cynw_hier_bind_detector
{
    HLS_METAPORT;
    typedef cynw_get_port_base<T>  this_type;
    sc_in<bool>            valid;
    sc_in<T>               data;
    sc_out<bool>           ready;

    cynw_get_port_base(const char* name = "")
    : valid(HLS_CAT_NAMES(name,"valid"))
    , data(HLS_CAT_NAMES(name,"data"))
    , ready(HLS_CAT_NAMES(name,"ready"))
    {}

    template<typename T_CHAN>
    void bind(T_CHAN& chan) 
    {
      cynw_mark_hierarchical_binding(&chan);
      valid(chan.valid);
      data(chan.data);
      ready(chan.ready);
    }
    template<typename T_CHAN>
    void operator() (T_CHAN& chan) 
    {
      bind(chan);
    }
    
    friend void sc_trace(sc_trace_file* tf, const this_type& obj, const std::string& n)
    {
      sc_trace( tf, obj.valid, n + ".valid" );
      sc_trace( tf, obj.data, n + ".data" );
      sc_trace( tf, obj.ready, n + ".ready" );
    }
};

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif


#endif // CYNW_PUT_GET_PORT_BASE__H
