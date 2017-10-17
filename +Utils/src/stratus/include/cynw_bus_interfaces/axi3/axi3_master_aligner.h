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


#pragma once

#if defined STRATUS
#pragma hls_ip_def
#endif

namespace cynw {
namespace axi3 {

using namespace simple_bus;


template <class SB_TRAITS, class AXI_EXT_LEN_TRAITS>
class axi_master_aligner:
  public sc_module,
  public bus_fw_nb_put_get_if<1, SB_TRAITS >
{
 public:

  typedef typename SB_TRAITS::awchan_t awchan_t;
  typedef typename SB_TRAITS::archan_t archan_t;
  typedef typename SB_TRAITS::wchan_t wchan_t;
  typedef typename SB_TRAITS::rchan_t rchan_t;
  typedef typename SB_TRAITS::bchan_t bchan_t;

  bus_nb_put_get_target_socket<1, SB_TRAITS> target1; 
  bus_nb_put_get_initiator_socket<1, AXI_EXT_LEN_TRAITS>      initiator1;
  typedef typename AXI_EXT_LEN_TRAITS::data_t data_t;


  SC_HAS_PROCESS(axi_master_aligner);

  axi_master_aligner(sc_module_name name) : sc_module(name), 
			      target1("target1"),
			      initiator1("initiator1")
  {
    target1.target_port(*this);

    // this version of aligner requires simple_bus bus data width to match axi bus data width
    sc_assert(AXI_EXT_LEN_TRAITS::data_bytes == SB_TRAITS::data_bytes); 
  }

  virtual bool nb_put_awchan(const awchan_t& awchan, tag<1>* t = 0)
  {
    if (!nb_can_put_awchan()) return false;

#ifndef STRATUS
    // enforce that address is aligned to transfer size
    if (((awchan.addr >> awchan.size) << awchan.size) != awchan.addr)
    {
      std::stringstream str;
      str << "Simple Bus protocol error: ((awchan.addr >> awchan.size) << awchan.size) != awchan.addr" << endl;
      str << "awchan.addr: 0x" << hex << awchan.addr << " awchan.size: 0x" << awchan.size << endl;
      str << "awchan.addr must be aligned to (decimal)" << dec << (1 << awchan.size) << " byte boundary." << endl;
      SC_REPORT_ERROR("/axi3_master_aligner", str.str().c_str());
      sc_assert(false);
    }

#endif

    typename AXI_EXT_LEN_TRAITS::awchan_t axi_awchan;

    axi_awchan.addr = awchan.addr;
    axi_awchan.ext_len = awchan.beats;
    axi_awchan.size = awchan.size;
    axi_awchan.tid = awchan.tid;

    if (awchan.fixed)
      axi_awchan.burst = AXI_FIXED_ADDR_BURST;
    else
      axi_awchan.burst = AXI_INCR_ADDR_BURST;

    bool ret = initiator1.awchan->nb_put(axi_awchan);
    sc_assert(ret);
    return true;
  }

  virtual bool nb_can_put_awchan(tag<1>* t = 0) const { return (initiator1.awchan->nb_can_put()); }
  virtual void reset_nb_put_awchan(tag<1>* t = 0) { initiator1.awchan->reset_put(); }

  virtual bool nb_put_archan(const archan_t& archan, tag<1>* t = 0)
  {
    if (!nb_can_put_archan()) return false;

#ifndef STRATUS
    // enforce that address is aligned to transfer size
    if (((archan.addr >> archan.size) << archan.size) != archan.addr)
    {
      std::stringstream str;
      str << "Simple Bus protocol error: ((archan.addr >> archan.size) << archan.size) != archan.addr" << endl;
      str << "archan.addr: 0x" << hex << archan.addr << " archan.size: 0x" << archan.size << endl;
      str << "archan.addr must be aligned to (decimal)" << dec << (1 << archan.size) << " byte boundary." << endl;
      SC_REPORT_ERROR("/axi3_master_aligner", str.str().c_str());
      sc_assert(false);
    }

#endif

    typename AXI_EXT_LEN_TRAITS::archan_t axi_archan;

    axi_archan.addr = archan.addr;
    axi_archan.ext_len = archan.beats;
    axi_archan.size = archan.size;
    axi_archan.tid = archan.tid;

    if (archan.fixed)
      axi_archan.burst = AXI_FIXED_ADDR_BURST;
    else
      axi_archan.burst = AXI_INCR_ADDR_BURST;

    bool ret = initiator1.archan->nb_put(axi_archan);
    sc_assert(ret);
    return true;
  }

  virtual bool nb_can_put_archan(tag<1>* t = 0) const { return (initiator1.archan->nb_can_put()); }
  virtual void reset_nb_put_archan(tag<1>* t = 0) { initiator1.archan->reset_put(); }

  virtual bool nb_put_wchan(const wchan_t& wchan, tag<1>* t = 0)
  { 
    if (!nb_can_put_wchan()) return false;

    typename AXI_EXT_LEN_TRAITS::wchan_t axi_wchan;

    axi_wchan.data = wchan.data ;
    axi_wchan.strb = wchan.byte_enables;
    axi_wchan.tid =  wchan.tid;

    bool ret = initiator1.wchan->nb_put(axi_wchan);
    sc_assert(ret);
    return true;
  }

  virtual bool nb_can_put_wchan(tag<1>* t = 0) const { return (initiator1.wchan->nb_can_put()); }
  virtual void reset_nb_put_wchan(tag<1>* t = 0) {  return initiator1.wchan->reset_put(); }

  virtual bool nb_get_rchan(rchan_t& rchan, tag<1>* t = 0)
  {
    if (!nb_can_get_rchan()) return false;


    typename AXI_EXT_LEN_TRAITS::rchan_t axi_rchan;

    bool ret = initiator1.rchan->nb_get(axi_rchan);
    sc_assert(ret);

    rchan.data = axi_rchan.data;
    rchan.tid = axi_rchan.tid;

    if ((axi_rchan.resp == AXI_OK_RESPONSE) )
      rchan.ok   = true;
    else
      rchan.ok   = false;

    return true;
  }

  virtual bool nb_can_get_rchan(tag<1>* t = 0) const { return (initiator1.rchan->nb_can_get()); }

  virtual void reset_nb_get_rchan(tag<1>* t = 0) {initiator1.rchan->reset_get(); }

  virtual bool nb_get_bchan(bchan_t& bchan, tag<1>* t = 0)
  {
    typename AXI_EXT_LEN_TRAITS::bchan_t axi_bchan;

    bool ret = initiator1.bchan->nb_get(axi_bchan);

    if (!ret) return false;

    bchan.tid = axi_bchan.tid;

    if ((axi_bchan.resp == AXI_OK_RESPONSE)  )
      bchan.ok   = true;
    else
      bchan.ok   = false;

    return ret;
  }

  virtual bool nb_can_get_bchan(tag<1>* t = 0) const { return initiator1.bchan->nb_can_get(); }
  virtual void reset_nb_get_bchan(tag<1>* t = 0) {  return initiator1.bchan->reset_get(); }
};


}; // namespace axi3
}; // namespace cynw


