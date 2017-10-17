/* 
 * (c) 2011 Cadence Design Systems, Inc. All rights reserved worldwide. 
 * 
 * MATERIALS FURNISHED BY CADENCE HEREUNDER ARE PROVIDED "AS IS"
 * WITHOUT WARRANTY OF ANY KIND, AND CADENCE SPECIFICALLY DISCLAIMS ANY
 * WARRANTY OF NONINFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE OR
 * MERCHANTABILITY. CADENCE SHALL NOT BE LIABLE FOR ANY COSTS OF
 * PROCUREMENT OF SUBSTITUTES, LOSS OF PROFITS, INTERRUPTION OF BUSINESS,
 * OR FOR ANY OTHER SPECIAL, CONSEQUENTIAL OR INCIDENTAL DAMAGES, HOWEVER
 * CAUSED, WHETHER FOR BREACH OF WARRANTY, CONTRACT, TORT, NEGLIGENCE,
 * STRICT LIABILITY OR OTHERWISE."  
 *
 */


#pragma once

///////////////////

#include "axi3_version.h"
#include "simple_bus_axi3_master_transactor.h"
#include "simple_bus_axi3_slave_transactor.h"
#include "axi3_adaptors.h"
#include "axi3_ports.h"

#define CYNW_NO_MODULE_BASE 	sc_module, sc_interface,
#define CYNW_NO_MODULE_INIT 	: sc_module(n)

/*

This ifdef below is no longer needed with newer versions of CtoS..

Reason for the ifdef was: The hier initiator and target sockets need to NOT inherit from sc_module when IO_CONFIG is at the signal
level, or else CtoS will not collapse the sockets (since there are no TLM function calls on hier sockets),
and then CtoS will see the signal port bindings as illegal.


#ifdef STRATUS
#define CYNW_NO_MODULE_BASE 	// empty
#define CYNW_NO_MODULE_INIT 	// empty
#else
#define CYNW_NO_MODULE_BASE 	sc_module,
#define CYNW_NO_MODULE_INIT 	: sc_module(n)
#endif

*/


#if defined STRATUS
#pragma hls_ip_def
#endif


namespace cynw {
namespace simple_bus {


template <typename traits, unsigned tag>
struct simple_bus_initiator_imp<traits, tag, IO_CONFIG_AXI3_SIG>
  : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>
  , axi3_initiator_ports<typename traits::hw_bus_traits>
{
  // specialization for AXI3 SIGNAL

  typedef typename traits::hw_bus_traits  axitraits;

  simple_bus_initiator_imp(sc_module_name n) : 
      bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>(n)
    , xtor("xtor")
  {
    bind_submod(xtor);

    bind_nb_put_get_sockets((*this), xtor.target1);
  }

  axi3::simple_bus_axi_master_transactor
       <traits, typename traits::tlm_traits, axi3::axi3_ext_len_traits<typename traits::hw_bus_traits> >	xtor;

  template <typename CHN> void operator()(CHN& chn)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here

    axi3_initiator_ports<axitraits>::bind_chan(chn);
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst)
  {
    xtor.clk(clk);
    xtor.reset(rst);
  }
};

template <typename traits, unsigned tag>
struct simple_bus_target_imp<traits, tag, IO_CONFIG_AXI3_SIG>
  : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>
  , axi3_target_ports<typename traits::hw_bus_traits>
{
  // specialization for AXI3 SIGNAL

  typedef typename traits::hw_bus_traits  axitraits;

  simple_bus_target_imp(sc_module_name n) : 
      bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>(n)
    , CTOR_NM(xtor)
  {
    bind_submod(xtor);

    bind_nb_put_get_sockets(xtor.initiator1, (*this));
  }

  axi3::simple_bus_axi_slave_transactor
       <traits, typename traits::tlm_traits, axi3::axi3_ext_len_traits<typename traits::hw_bus_traits> >	xtor;

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst)
  {
    xtor.clk(clk);
    xtor.reset(rst);
  }

  template <typename CHN> void operator()(CHN& chn)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here

    axi3_target_ports<axitraits>::bind_chan(chn);
  }
};

template <typename traits>
struct simple_bus_channel_imp<traits, IO_CONFIG_AXI3_SIG>
  : public sc_module
  , public axi3_signals<typename traits::hw_bus_traits>
{
  // specialization for AXI3 SIGNAL

  simple_bus_channel_imp(sc_module_name n = "simple_bus_channel") : 
     sc_module(n)
   {}

  template <typename TARG> void operator()(TARG& targ)
  {
    bind_submod(targ);
  }
};


/////// hier_simple_bus_initiator / target :

template <typename traits, unsigned tag>
struct hier_simple_bus_initiator_imp<traits, tag, IO_CONFIG_AXI3_SIG>
  :
    CYNW_NO_MODULE_BASE
    axi3_initiator_ports<typename traits::hw_bus_traits>
{
  // specialization for AXI3 SIGNAL

  hier_simple_bus_initiator_imp(sc_module_name n)
	CYNW_NO_MODULE_INIT
  { }

  template <typename CHAN> void operator()(CHAN& chan)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here

    bind_chan(chan);
  }

  template <typename TARG> void hier_bind(TARG& targ)
  {
    bind_submod(targ);
  }
};


template <typename traits, unsigned tag>
struct hier_simple_bus_target_imp<traits, tag, IO_CONFIG_AXI3_SIG>
  :
    CYNW_NO_MODULE_BASE
    axi3_target_ports<typename traits::hw_bus_traits>
{
  // specialization for AXI3 SIGNAL

  hier_simple_bus_target_imp(sc_module_name n)
   CYNW_NO_MODULE_INIT
  { }

  template <typename TARG> void hier_bind(TARG& targ)
  {
    bind_submod(targ);
  }
};

}; // namespace simple_bus
}; // namespace cynw

