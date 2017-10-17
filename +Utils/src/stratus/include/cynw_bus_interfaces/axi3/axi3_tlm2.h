/*
* (c) 2012 Cadence Design Systems, Inc. All rights reserved worldwide.
*
* MATERIALS FURNISHED BY CADENCE HEREUNDER ("DESIGN ELEMENTS")
* ARE PROVIDED FOR FREE TO CADENCE'S CUSTOMERS WHO HAVE SIGNED
* CADENCE SOFTWARE LICENSE AGREEMENT (E.G., SOFTWARE USE AND
* MAINTENANCE AGREEMENT, CADENCE FIXED TERM USE AGREEMENT) AS
* PART OF COMMITTED MATERIALS OR COMMITTED PROGRAMS AS DEFINED
* IN SUCH SOFTWARE LICENSE AGREEMENT.  DESIGN MATERIALS ARE
* PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, AND CADENCE
* AND ITS SUPPLIERS SPECIFICALLY DISCLAIM ANY WARRANTY OF
* NONINFRINGEMENT, FITNESS FOR A PARTICULAR PURPOSE OR
* MERCHANTABILITY.  CADENCE AND ITS SUPPLIERS SHALL NOT BE
* LIABLE FOR ANY COSTS OF PROCUREMENT OF SUBSTITUTES, LOSS OF
* PROFITS, INTERRUPTION OF BUSINESS, OR FOR ANY OTHER SPECIAL,
* CONSEQUENTIAL OR INCIDENTAL DAMAGES, HOWEVER CAUSED, WHETHER
* FOR BREACH OF WARRANTY, CONTRACT, TORT, NEGLIGENCE, STRICT
* LIABILITY OR OTHERWISE."  IN ADDITION, CADENCE WILL HAVE NO
* LIABILITY FOR DAMAGES OF ANY KIND, INCLUDING DIRECT DAMAGES,
* RESULTING FROM THE USE OF THE DESIGN MATERIALS.
*
*/



#ifndef AXI3_TLM2_H
#define AXI3_TLM2_H true

#pragma once

#include "tlm2_transactors.h"


namespace cynw {
namespace axi3 {

template <typename traits, unsigned tag>
struct axi3_initiator_imp<traits, tag, IO_CONFIG_TLM2>
  : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>
  , sc_interface
{
  // specialization for TLM2 LEVEL

  typedef typename traits::simple_bus_traits sbtraits;

  axi3_initiator_imp(sc_module_name n) :
     bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>(n)
   , slave_aligner("slave_aligner")
   , tlm2_xtor("tlm2_xtor")
  {
    bind_nb_put_get_sockets((*this), slave_aligner.target1);
    bind_nb_put_get_sockets(slave_aligner.initiator1, tlm2_xtor.target1);
    tlm2_xtor.tlm2_initiator(tlm2);
  }

  template <typename CHAN> void operator()(CHAN& chan) {
   tlm2(chan.initiator1);
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }

  axi_slave_aligner<sbtraits, typename traits::tlm_traits> slave_aligner;
  simple_bus_to_tlm2_initiator<sbtraits> tlm2_xtor;
  multi_passthrough_initiator_socket<simple_bus_to_tlm2_initiator<sbtraits>, sbtraits::data_bytes*8> tlm2;
};


template <typename traits>
struct rtl_to_tlm2_axi3_initiator
  : public axi3_initiator_imp<traits, 1, IO_CONFIG_TLM2>
  , public bus_fw_nb_put_get_if<1, typename traits::tlm_traits>
{
  typedef typename traits::tlm_traits tlm_traits;

  rtl_to_tlm2_axi3_initiator(sc_module_name n) : 
    axi3_initiator_imp<traits, 1, IO_CONFIG_TLM2>(n)
    , axi3_targ1("axi3_targ1")
    , axi3_channel1("aci3_channel1")
  {
    axi3_channel1(axi3_targ1);
    axi3_targ1.target_port(*this);
  }

  axi3_channel<traits>& rtl_channel()
  {
    return axi3_channel1;
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst)
  {
    axi3_initiator_imp<traits, 1, IO_CONFIG_TLM2>::clk_rst(clk, rst);
    axi3_targ1.clk_rst(clk, rst);
  }

  axi3_target_imp<traits, 1, IO_CONFIG_AXI3_SIG> axi3_targ1;
  axi3_channel<traits> axi3_channel1;

  virtual bool nb_put_awchan(const typename tlm_traits::awchan_t& awchan, tag<1>* t ) { return (*this).awchan->nb_put(awchan); } 
  virtual bool nb_can_put_awchan(tag<1>* t ) const { return (*this).awchan->nb_can_put(); } 
  virtual void reset_nb_put_awchan(tag<1>* t ) { (*this).awchan->reset_put(); } 
  virtual bool nb_put_archan(const typename tlm_traits::archan_t& archan, tag<1>* t ) { return (*this).archan->nb_put(archan); } 
  virtual bool nb_can_put_archan(tag<1>* t ) const { return (*this).archan->nb_can_put(); } 
  virtual void reset_nb_put_archan(tag<1>* t ) { (*this).archan->reset_put(); } 
  virtual bool nb_put_wchan(const typename tlm_traits::wchan_t& wchan, tag<1>* t ) { return (*this).wchan->nb_put(wchan); } 
  virtual bool nb_can_put_wchan(tag<1>* t ) const { return (*this).wchan->nb_can_put(); } 
  virtual void reset_nb_put_wchan(tag<1>* t ) { (*this).wchan->reset_put(); } 
  virtual bool nb_get_rchan(typename tlm_traits::rchan_t& rchan, tag<1>* t ) { return (*this).rchan->nb_get(rchan); } 
  virtual bool nb_can_get_rchan(tag<1>* t ) const { return (*this).rchan->nb_can_get(); } 
  virtual void reset_nb_get_rchan(tag<1>* t ) { (*this).rchan->reset_get(); } 
  virtual bool nb_get_bchan(typename tlm_traits::bchan_t& bchan, tag<1>* t ) { return (*this).bchan->nb_get(bchan); } 
  virtual bool nb_can_get_bchan(tag<1>* t ) const { return (*this).bchan->nb_can_get(); }
  virtual void reset_nb_get_bchan(tag<1>* t ) { (*this).bchan->reset_get(); }
};




template <typename traits>
struct rtl_to_tlm2_axi3_target
  : public axi3_target_imp<traits, 1, IO_CONFIG_TLM2>
  , public bus_fw_nb_put_get_if<1, typename traits::tlm_traits>
{
  typedef typename traits::tlm_traits tlm_traits;

  rtl_to_tlm2_axi3_target(sc_module_name n) : 
    axi3_target_imp<traits, 1, IO_CONFIG_TLM2>(n)
    , axi3_init1("axi3_init1")
    , axi3_channel1("aci3_channel1")
  {
    target_port(*this);
    axi3_init1(axi3_channel1);
  }

  template <typename TARG> void rtl_target(TARG& targ) {
    axi3_channel1(targ);
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst)
  {
    axi3_target_imp<traits, 1, IO_CONFIG_TLM2>::clk_rst(clk, rst);
    axi3_init1.clk_rst(clk, rst);
  }

  axi3_initiator_imp<traits, 1, IO_CONFIG_AXI3_SIG> axi3_init1;
  axi3_channel<traits> axi3_channel1;

  virtual bool nb_put_awchan(const typename tlm_traits::awchan_t& awchan, tag<1>* t ) { return (axi3_init1.xtor.target1).awchan->nb_put(awchan); } 
  virtual bool nb_can_put_awchan(tag<1>* t ) const { return (axi3_init1.xtor.target1).awchan->nb_can_put(); } 
  virtual void reset_nb_put_awchan(tag<1>* t ) { (axi3_init1.xtor.target1).awchan->reset_put(); } 
  virtual bool nb_put_archan(const typename tlm_traits::archan_t& archan, tag<1>* t ) { return (axi3_init1.xtor.target1).archan->nb_put(archan); } 
  virtual bool nb_can_put_archan(tag<1>* t ) const { return (axi3_init1.xtor.target1).archan->nb_can_put(); } 
  virtual void reset_nb_put_archan(tag<1>* t ) { (axi3_init1.xtor.target1).archan->reset_put(); } 
  virtual bool nb_put_wchan(const typename tlm_traits::wchan_t& wchan, tag<1>* t ) { return (axi3_init1.xtor.target1).wchan->nb_put(wchan); } 
  virtual bool nb_can_put_wchan(tag<1>* t ) const { return (axi3_init1.xtor.target1).wchan->nb_can_put(); } 
  virtual void reset_nb_put_wchan(tag<1>* t ) { (axi3_init1.xtor.target1).wchan->reset_put(); } 
  virtual bool nb_get_rchan(typename tlm_traits::rchan_t& rchan, tag<1>* t ) { return (axi3_init1.xtor.target1).rchan->nb_get(rchan); } 
  virtual bool nb_can_get_rchan(tag<1>* t ) const { return (axi3_init1.xtor.target1).rchan->nb_can_get(); } 
  virtual void reset_nb_get_rchan(tag<1>* t ) { (axi3_init1.xtor.target1).rchan->reset_get(); } 
  virtual bool nb_get_bchan(typename tlm_traits::bchan_t& bchan, tag<1>* t ) { return (axi3_init1.xtor.target1).bchan->nb_get(bchan); } 
  virtual bool nb_can_get_bchan(tag<1>* t ) const { return (axi3_init1.xtor.target1).bchan->nb_can_get(); }
  virtual void reset_nb_get_bchan(tag<1>* t ) { (axi3_init1.xtor.target1).bchan->reset_get(); }
};


template <typename traits, unsigned tag>
struct axi3_target_imp<traits, tag, IO_CONFIG_TLM2>
  : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>
{
  // specialization for TLM2 LEVEL

  typedef typename traits::simple_bus_traits sbtraits;
  typedef axi3::axi3_ext_len_traits<typename traits::hw_bus_traits> axi_ext_len_traits;

  axi3_target_imp(sc_module_name n) :
     bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>(n)
   , tlm2_xtor("tlm2_xtor")
   , segmenter("segmenter")
   , aligner("aligner")
  {
    bind_nb_put_get_sockets(tlm2_xtor.initiator1,  aligner.target1);

    bind_nb_put_get_sockets(aligner.initiator1, segmenter.target1);

    bind_nb_put_get_sockets(segmenter.initiator1, (*this));

    tlm2(tlm2_xtor.tlm2_target);
  }

  tlm2_target_to_simple_bus<sbtraits>    tlm2_xtor;
  multi_passthrough_target_socket<tlm2_target_to_simple_bus<sbtraits>, sbtraits::data_bytes*8> tlm2;


  // stuart: this IO_CONFIG is always for TLM2 simulation, but currently we are using the synthesizeable segmenter here,
  // and this is inefficient for simulation since it has separate processes and lots of context switching. This could
  // be optimized in the future to eliminate the separate processes and context switching.

  axi_master_segmenter<traits, axi_ext_len_traits, 1> segmenter;
  axi_master_aligner<sbtraits, axi_ext_len_traits> aligner;

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst)
  {
    segmenter.clk(clk);
    segmenter.reset(rst);

    tlm2_xtor.clk(clk);
  }
};


template <typename traits>
struct axi3_channel_imp<traits, IO_CONFIG_TLM2> 
  : public tlm2_init_targ_channel<typename traits::simple_bus_traits>
{
  // specialization for TLM2 LEVEL

  axi3_channel_imp(sc_module_name n = "axi3_channel") : tlm2_init_targ_channel<typename traits::simple_bus_traits>(n) {}

  template <typename TARG> void operator()(TARG& targ) {
    (*this).target1(targ.tlm2);
  }

};


template <typename traits, unsigned tag>
struct hier_axi3_initiator_imp<traits, tag, IO_CONFIG_TLM2>
  : sc_module
{
  // specialization for TLM2 LEVEL

   hier_axi3_initiator_imp(sc_module_name n) : sc_module(n) {}

   multi_passthrough_initiator_socket<hier_axi3_initiator_imp<traits,tag,IO_CONFIG_TLM2>, traits::tlm_traits::data_bytes*8> tlm2;

  template <typename CHAN> void operator()(CHAN& chan) {
   tlm2(chan.target1);
  }

  template <typename INIT> void hier_bind(INIT& subinit)
  {
   subinit.tlm2(tlm2);
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }
};

template <typename traits, unsigned tag>
struct hier_axi3_target_imp<traits, tag, IO_CONFIG_TLM2>
  : sc_module
{
  // specialization for TLM2 LEVEL

  hier_axi3_target_imp(sc_module_name n) : sc_module(n) {}

  multi_passthrough_target_socket<hier_axi3_target_imp<traits,tag,IO_CONFIG_TLM2>, traits::tlm_traits::data_bytes*8> tlm2;

  template <typename TARG> void hier_bind(TARG& subtarg)
  {
    tlm2(subtarg.tlm2);
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }
};



}; // namespace axi3
}; // namespace cynw

#endif
