

#pragma once

#if defined STRATUS
#pragma hls_ip_def
#endif

#include "axi3_write_ctors_decl.h"
#include "axi3_read_ctors_decl.h"

namespace cynw {
namespace simple_bus {

template <class L, class R> void axi3_bind_write(L& left, R& rt)
{
    left.AWVALID(rt.AWVALID);  
    left.AWLEN(rt.AWLEN);  
    left.AWSIZE(rt.AWSIZE);  
    left.AWBURST(rt.AWBURST);  
    left.AWID(rt.AWID);  
    left.AWADDR(rt.AWADDR);  
    left.AWREADY(rt.AWREADY);  
    left.AWLOCK(rt.AWLOCK);  
    left.AWCACHE(rt.AWCACHE);  
    left.AWPROT(rt.AWPROT);  
    left.WVALID(rt.WVALID);  
    left.WID(rt.WID);  
    left.WSTRB(rt.WSTRB);  
    left.WREADY(rt.WREADY);  
    left.WDATA(rt.WDATA);  
    left.WLAST(rt.WLAST);  
    left.BVALID(rt.BVALID);  
    left.BID(rt.BID);  
    left.BREADY(rt.BREADY);  
    left.BRESP(rt.BRESP);  
}

template <class L, class R> void axi3_bind_read(L& left, R& rt)
{
    left.ARVALID(rt.ARVALID);  
    left.ARLEN(rt.ARLEN);  
    left.ARSIZE(rt.ARSIZE);  
    left.ARBURST(rt.ARBURST);  
    left.ARID(rt.ARID);  
    left.ARADDR(rt.ARADDR);  
    left.ARREADY(rt.ARREADY);  
    left.ARLOCK(rt.ARLOCK);  
    left.ARCACHE(rt.ARCACHE);  
    left.ARPROT(rt.ARPROT);  
    left.RVALID(rt.RVALID);  
    left.RID(rt.RID);  
    left.RREADY(rt.RREADY);  
    left.RDATA(rt.RDATA);  
    left.RRESP(rt.RRESP);  
    left.RLAST(rt.RLAST);  
}


template <class axitraits, axi3::axi3_rw_mode mode>
class axi3_signals_imp {};

template <class axitraits>
struct axi3_signals_imp<axitraits, axi3::READ_WRITE> 
{
  axi3_signals_imp(const char* n = NULL)
    : 
AXI3_WRITE_PORTS_CTOR(n)
    ,
AXI3_READ_PORTS_CTOR(n)

  {}

  template <typename SUBMOD> void bind_submod(SUBMOD& submod)
  {
    axi3_bind_write(submod, *this);
    axi3_bind_read(submod, *this);
  }

#include "axi3_write_signals.h"
#include "axi3_read_signals.h"
};

template <class axitraits>
struct axi3_signals_imp<axitraits, axi3::READ_ONLY> 
{
  axi3_signals_imp() 
    : 
#include "axi3_read_ctors.h"
  {}

  template <typename SUBMOD> void bind_submod(SUBMOD& submod)
  {
    axi3_bind_read(submod, *this);
  }

#include "axi3_read_signals.h"
};

template <class axitraits>
struct axi3_signals_imp<axitraits, axi3::WRITE_ONLY> 
{
  axi3_signals_imp() 
    : 
#include "axi3_write_ctors.h"
  {}

  template <typename SUBMOD> void bind_submod(SUBMOD& submod)
  {
    axi3_bind_write(submod, *this);
  }

#include "axi3_write_signals.h"
};

template <class axitraits>
struct axi3_signals : axi3_signals_imp<axitraits, axitraits::rw_mode> 
{ };

  

template <class axitraits, axi3::axi3_rw_mode mode>
class axi3_initiator_ports_imp {};

template <class axitraits>
struct axi3_initiator_ports_imp<axitraits, axi3::READ_WRITE> 
{
  HLS_METAPORT;

  axi3_initiator_ports_imp(const char *n = NULL)
    : 
AXI3_WRITE_PORTS_CTOR(n)
    ,
AXI3_READ_PORTS_CTOR(n)
  {}

  
  typedef axitraits T;
#include "axi3_master_write_ports.h"
#include "axi3_master_read_ports.h"

  template <typename CHAN> void bind_chan(CHAN& chan)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here

    axi3_bind_write(*this, chan);
    axi3_bind_read(*this, chan);
  }

  template <typename XTOR> void bind_submod(XTOR& xtor)
  {
    axi3_bind_write(xtor, *this);
    axi3_bind_read(xtor, *this);
  }
};

template <class axitraits>
struct axi3_initiator_ports_imp<axitraits, axi3::READ_ONLY> 
{
  HLS_METAPORT;

  axi3_initiator_ports_imp(const char *n = NULL)
    : 
AXI3_READ_PORTS_CTOR(n)
  {}

  typedef axitraits T;
#include "axi3_master_read_ports.h"

  template <typename CHAN> void bind_chan(CHAN& chan)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here

    axi3_bind_read(*this, chan);
  }

  template <typename XTOR> void bind_submod(XTOR& xtor)
  {
    axi3_bind_read(xtor, *this);
  }
};

template <class axitraits>
struct axi3_initiator_ports_imp<axitraits, axi3::WRITE_ONLY> 
{
  HLS_METAPORT;

  axi3_initiator_ports_imp(const char *n = NULL)
    : 
AXI3_WRITE_PORTS_CTOR(n)
  {}

  typedef axitraits T;
#include "axi3_master_write_ports.h"
  
  template <typename CHAN> void bind_chan(CHAN& chan)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here

    axi3_bind_write(*this, chan);
  }

  template <typename XTOR> void bind_submod(XTOR& xtor)
  {
    axi3_bind_write(xtor, *this);
  }
};

template <class axitraits>
struct axi3_initiator_ports : axi3_initiator_ports_imp<axitraits, axitraits::rw_mode> 
{
	axi3_initiator_ports(const char *n = NULL)
	: axi3_initiator_ports_imp<axitraits, axitraits::rw_mode>(n)
	{}
};


template <class axitraits, axi3::axi3_rw_mode mode>
class axi3_target_ports_imp {};

template <class axitraits>
struct axi3_target_ports_imp<axitraits, axi3::READ_WRITE> 
{
  HLS_METAPORT;

  axi3_target_ports_imp(const char *n = NULL)
    : 
AXI3_WRITE_PORTS_CTOR(n)
   ,
AXI3_READ_PORTS_CTOR(n)
  {}

  typedef axitraits T;
#include "axi3_slave_write_ports.h"
#include "axi3_slave_read_ports.h"

  template <typename CHAN> void bind_chan(CHAN& chan)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here

    axi3_bind_write(*this, chan);
    axi3_bind_read(*this, chan);
  }

  template <typename XTOR> void bind_submod(XTOR& xtor)
  {
    axi3_bind_write(xtor, *this);
    axi3_bind_read(xtor, *this);
  }
};

template <class axitraits>
struct axi3_target_ports_imp<axitraits, axi3::READ_ONLY> 
{
  HLS_METAPORT;

  axi3_target_ports_imp(const char *n = NULL)
    : 
AXI3_READ_PORTS_CTOR(n)
  {}

  typedef axitraits T;
#include "axi3_slave_read_ports.h"

  template <typename CHAN> void bind_chan(CHAN& chan)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here

    axi3_bind_read(*this, chan);
  }

  template <typename XTOR> void bind_submod(XTOR& xtor)
  {
    axi3_bind_read(xtor, *this);
  }
};

template <class axitraits>
struct axi3_target_ports_imp<axitraits, axi3::WRITE_ONLY> 
{
  HLS_METAPORT;

  axi3_target_ports_imp(const char *n = NULL)
    : 
AXI3_WRITE_PORTS_CTOR(n)
  {}

  typedef axitraits T;
#include "axi3_slave_write_ports.h"
  
  template <typename CHAN> void bind_chan(CHAN& chan)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here
    axi3_bind_write(*this, chan);
  }

  template <typename XTOR> void bind_submod(XTOR& xtor)
  {
    axi3_bind_write(xtor, *this);
  }
};

template <class axitraits>
struct axi3_target_ports : axi3_target_ports_imp<axitraits, axitraits::rw_mode> 
{
	axi3_target_ports(const char *n = NULL)
	: axi3_target_ports_imp<axitraits, axitraits::rw_mode>(n)
		{}
};


}; // namespace simple_bus
}; // namespace cynw

#ifdef CYNW_TLM_PROMOTE_PORTS


#define AXI3_TARGET_PORTS(name, traits) \
  sc_in< bool >                                 name ## _AWVALID;  \
  sc_in<sc_uint<traits::hw_bus_traits::LEN_W> >         name ## _AWLEN;  \
  sc_in <sc_uint<traits::hw_bus_traits::SIZE_W> >       name ## _AWSIZE;  \
  sc_in <sc_uint<traits::hw_bus_traits::BURST_W> >      name ## _AWBURST;  \
  sc_in <sc_uint<traits::hw_bus_traits::WID_W> >        name ## _AWID;  \
  sc_in< sc_uint<traits::hw_bus_traits::ADDR_W> >      name ## _AWADDR;  \
  sc_out< bool >                                name ## _AWREADY;  \
  sc_in< sc_uint<traits::hw_bus_traits::LOCK_W> >       name ## _AWLOCK; \
  sc_in< sc_uint<traits::hw_bus_traits::CACHE_W> >      name ## _AWCACHE;  \
  sc_in< sc_uint<traits::hw_bus_traits::PROT_W> >       name ## _AWPROT; \
  \
  sc_in< bool >                                 name ## _WVALID;  \
  sc_in< sc_uint<traits::hw_bus_traits::WID_W> >        name ## _WID;  \
  sc_in< traits::hw_bus_traits::strb_t>                name ## _WSTRB;  \
  sc_in< traits::hw_bus_traits::data_t>                name ## _WDATA;  \
  sc_in< bool >                                 name ## _WLAST;  \
  sc_out< bool >                                name ## _WREADY;  \
  \
  sc_in< bool >                                 name ## _BREADY;  \
  sc_out< sc_uint<traits::hw_bus_traits::WID_W> >       name ## _BID;  \
  sc_out< bool >                                name ## _BVALID;  \
  sc_out< sc_uint<traits::hw_bus_traits::BRESP_W> >     name ## _BRESP;  \
  \
  sc_in< bool >                                 name ## _ARVALID;  \
  sc_in< sc_uint<traits::hw_bus_traits::LEN_W> >        name ## _ARLEN;  \
  sc_in <sc_uint<traits::hw_bus_traits::SIZE_W> >       name ## _ARSIZE;  \
  sc_in <sc_uint<traits::hw_bus_traits::BURST_W> >      name ## _ARBURST;  \
  sc_in <sc_uint<traits::hw_bus_traits::RID_W> >        name ## _ARID;  \
  sc_in< sc_uint<traits::hw_bus_traits::ADDR_W> >      name ## _ARADDR;  \
  sc_out< bool >                                name ## _ARREADY;  \
  sc_in< sc_uint<traits::hw_bus_traits::LOCK_W> >       name ## _ARLOCK; \
  sc_in< sc_uint<traits::hw_bus_traits::CACHE_W> >      name ## _ARCACHE;  \
  sc_in< sc_uint<traits::hw_bus_traits::PROT_W> >       name ## _ARPROT; \
  \
  sc_in< bool >                                 name ## _RREADY;  \
  sc_out< bool >                                name ## _RVALID;  \
  sc_out< sc_uint<traits::hw_bus_traits::RID_W> >       name ## _RID;  \
  sc_out< traits::hw_bus_traits::data_t>               name ## _RDATA;  \
  sc_out< sc_uint<traits::hw_bus_traits::BRESP_W> >     name ## _RRESP;  \
  sc_out< bool >                                name ## _RLAST 

#define AXI3_INITIATOR_PORTS(name, traits) \
  sc_out< bool >                                 name ## _AWVALID;  \
  sc_out<sc_uint<traits::hw_bus_traits::LEN_W> >         name ## _AWLEN;  \
  sc_out <sc_uint<traits::hw_bus_traits::SIZE_W> >       name ## _AWSIZE;  \
  sc_out <sc_uint<traits::hw_bus_traits::BURST_W> >      name ## _AWBURST;  \
  sc_out <sc_uint<traits::hw_bus_traits::WID_W> >        name ## _AWID;  \
  sc_out< sc_uint<traits::hw_bus_traits::ADDR_W> >      name ## _AWADDR;  \
  sc_in< bool >                                name ## _AWREADY;  \
  sc_out< sc_uint<traits::hw_bus_traits::LOCK_W> >       name ## _AWLOCK; \
  sc_out< sc_uint<traits::hw_bus_traits::CACHE_W> >      name ## _AWCACHE;  \
  sc_out< sc_uint<traits::hw_bus_traits::PROT_W> >       name ## _AWPROT; \
  \
  sc_out< bool >                                 name ## _WVALID;  \
  sc_out< sc_uint<traits::hw_bus_traits::WID_W> >        name ## _WID;  \
  sc_out< traits::hw_bus_traits::strb_t>                name ## _WSTRB;  \
  sc_out< traits::hw_bus_traits::data_t>                name ## _WDATA;  \
  sc_out< bool >                                 name ## _WLAST;  \
  sc_in< bool >                                name ## _WREADY;  \
  \
  sc_out< bool >                                 name ## _BREADY;  \
  sc_in< sc_uint<traits::hw_bus_traits::WID_W> >       name ## _BID;  \
  sc_in< bool >                                name ## _BVALID;  \
  sc_in< sc_uint<traits::hw_bus_traits::BRESP_W> >     name ## _BRESP;  \
  \
  sc_out< bool >                                 name ## _ARVALID;  \
  sc_out< sc_uint<traits::hw_bus_traits::LEN_W> >        name ## _ARLEN;  \
  sc_out <sc_uint<traits::hw_bus_traits::SIZE_W> >       name ## _ARSIZE;  \
  sc_out <sc_uint<traits::hw_bus_traits::BURST_W> >      name ## _ARBURST;  \
  sc_out <sc_uint<traits::hw_bus_traits::RID_W> >        name ## _ARID;  \
  sc_out< sc_uint<traits::hw_bus_traits::ADDR_W> >      name ## _ARADDR;  \
  sc_in< bool >                                name ## _ARREADY;  \
  sc_out< sc_uint<traits::hw_bus_traits::LOCK_W> >       name ## _ARLOCK; \
  sc_out< sc_uint<traits::hw_bus_traits::CACHE_W> >      name ## _ARCACHE;  \
  sc_out< sc_uint<traits::hw_bus_traits::PROT_W> >       name ## _ARPROT; \
  \
  sc_out< bool >                                 name ## _RREADY;  \
  sc_in< bool >                                name ## _RVALID;  \
  sc_in< sc_uint<traits::hw_bus_traits::RID_W> >       name ## _RID;  \
  sc_in< traits::hw_bus_traits::data_t>               name ## _RDATA;  \
  sc_in< sc_uint<traits::hw_bus_traits::BRESP_W> >     name ## _RRESP;  \
  sc_in< bool >                                name ## _RLAST 


#define CTOR_2NM(nm1, nm2)  nm1 ## _ ## nm2 ( #nm1 "_" #nm2)

#define AXI3_TARGET_PORTS_CTOR(name) \
    CTOR_2NM(name, AWVALID), \
    CTOR_2NM(name, AWLEN), \
    CTOR_2NM(name, AWSIZE), \
    CTOR_2NM(name, AWBURST), \
    CTOR_2NM(name, AWID), \
    CTOR_2NM(name, AWADDR), \
    CTOR_2NM(name, AWREADY), \
    CTOR_2NM(name, AWLOCK), \
    CTOR_2NM(name, AWCACHE), \
    CTOR_2NM(name, AWPROT), \
    CTOR_2NM(name, WVALID), \
    CTOR_2NM(name, WID), \
    CTOR_2NM(name, WSTRB), \
    CTOR_2NM(name, WDATA), \
    CTOR_2NM(name, WLAST), \
    CTOR_2NM(name, WREADY), \
    CTOR_2NM(name, BREADY), \
    CTOR_2NM(name, BID), \
    CTOR_2NM(name, BVALID), \
    CTOR_2NM(name, BRESP), \
    CTOR_2NM(name, ARVALID), \
    CTOR_2NM(name, ARLEN), \
    CTOR_2NM(name, ARSIZE), \
    CTOR_2NM(name, ARBURST), \
    CTOR_2NM(name, ARID), \
    CTOR_2NM(name, ARADDR), \
    CTOR_2NM(name, ARREADY), \
    CTOR_2NM(name, ARLOCK), \
    CTOR_2NM(name, ARCACHE), \
    CTOR_2NM(name, ARPROT), \
    CTOR_2NM(name, RREADY), \
    CTOR_2NM(name, RVALID), \
    CTOR_2NM(name, RID), \
    CTOR_2NM(name, RDATA), \
    CTOR_2NM(name, RRESP), \
    CTOR_2NM(name, RLAST)

#define AXI3_INITIATOR_PORTS_CTOR(name) AXI3_TARGET_PORTS_CTOR(name)

#define BIND3(name, targ, sig)  targ . sig ( name ## _ ## sig )

#define AXI3_TARGET_PORTS_BIND(name, targ) \
    BIND3(name, targ, AWVALID), \
    BIND3(name, targ, AWLEN), \
    BIND3(name, targ, AWSIZE), \
    BIND3(name, targ, AWBURST), \
    BIND3(name, targ, AWID), \
    BIND3(name, targ, AWADDR), \
    BIND3(name, targ, AWREADY), \
    BIND3(name, targ, AWLOCK), \
    BIND3(name, targ, AWCACHE), \
    BIND3(name, targ, AWPROT), \
    BIND3(name, targ, WVALID), \
    BIND3(name, targ, WID), \
    BIND3(name, targ, WSTRB), \
    BIND3(name, targ, WDATA), \
    BIND3(name, targ, WLAST), \
    BIND3(name, targ, WREADY), \
    BIND3(name, targ, BREADY), \
    BIND3(name, targ, BID), \
    BIND3(name, targ, BVALID), \
    BIND3(name, targ, BRESP), \
    BIND3(name, targ, ARVALID), \
    BIND3(name, targ, ARLEN), \
    BIND3(name, targ, ARSIZE), \
    BIND3(name, targ, ARBURST), \
    BIND3(name, targ, ARID), \
    BIND3(name, targ, ARADDR), \
    BIND3(name, targ, ARREADY), \
    BIND3(name, targ, ARLOCK), \
    BIND3(name, targ, ARCACHE), \
    BIND3(name, targ, ARPROT), \
    BIND3(name, targ, RREADY), \
    BIND3(name, targ, RVALID), \
    BIND3(name, targ, RID), \
    BIND3(name, targ, RDATA), \
    BIND3(name, targ, RRESP), \
    BIND3(name, targ, RLAST)

#define AXI3_INITIATOR_PORTS_BIND(name, targ) AXI3_TARGET_PORTS_BIND(name, targ)

#else

#define AXI3_TARGET_PORTS(name, traits)  bool name ## _dummy
#define AXI3_INITIATOR_PORTS(name, traits)  bool name ## _dummy

#define AXI3_TARGET_PORTS_CTOR(name)  name ## _dummy (true)
#define AXI3_INITIATOR_PORTS_CTOR(name)  name ## _dummy (true)

#define AXI3_TARGET_PORTS_BIND(name, targ)  /* empty */
#define AXI3_INITIATOR_PORTS_BIND(name, targ)  /* empty */

#endif
   

