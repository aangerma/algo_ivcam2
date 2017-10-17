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


template <class SB_TRAITS, class AXI_TRAITS>
class axi_slave_aligner :
  public sc_module,
  public bus_fw_nb_put_get_if<1, AXI_TRAITS >
{
 public:

  typedef typename AXI_TRAITS::awchan_t awchan_t;
  typedef typename AXI_TRAITS::archan_t archan_t;
  typedef typename AXI_TRAITS::wchan_t wchan_t;
  typedef typename AXI_TRAITS::rchan_t rchan_t;
  typedef typename AXI_TRAITS::bchan_t bchan_t;

  bus_nb_put_get_target_socket<1, AXI_TRAITS >         target1;
  bus_nb_put_get_initiator_socket<1, SB_TRAITS >      	initiator1;

  axi_slave_aligner(sc_module_name name) : sc_module(name), 
			      target1("target1"),
			      initiator1("initiator1")
  {
    target1.target_port(*this);

    // enforce that axi data bus width is same as simple bus data width
    sc_assert(AXI_TRAITS::data_bytes == SB_TRAITS::data_bytes); 
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
      SC_REPORT_ERROR("/axi3_slave_aligner", str.str().c_str());
      sc_assert(false);
    }

#endif

    // enforce only INCR or FIXED bursts (no WRAP)
    sc_assert((awchan.burst == 0) || (awchan.burst == 1));

    typename SB_TRAITS::awchan_t simple_awchan;

    simple_awchan.addr = awchan.addr;
    simple_awchan.beats = awchan.len;
    simple_awchan.size = awchan.size;
    simple_awchan.tid = awchan.tid;

    if (awchan.burst == AXI_FIXED_ADDR_BURST)   
    {
      simple_awchan.fixed = true;
    }
    else 
    {
      simple_awchan.fixed = false;
    }

    bool ret = initiator1.awchan->nb_put(simple_awchan);
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
      SC_REPORT_ERROR("/axi3_slave_aligner", str.str().c_str());
      sc_assert(false);
    }

    // enforce only INCR or FIXED bursts (no WRAP)
    sc_assert((archan.burst == 0) || (archan.burst == 1));

#endif

    typename SB_TRAITS::archan_t simple_archan;

    simple_archan.addr  = archan.addr;
    simple_archan.beats = archan.len;
    simple_archan.size = archan.size;
    simple_archan.tid = archan.tid;

    if (archan.burst == AXI_FIXED_ADDR_BURST)   
    {
        simple_archan.fixed = true;
    }
    else 
    {
        simple_archan.fixed = false;
    }

    bool ret = initiator1.archan->nb_put(simple_archan);
    sc_assert(ret);
    return true;
  }

  virtual bool nb_can_put_archan(tag<1>* t = 0) const { return (initiator1.archan->nb_can_put()); }
  virtual void reset_nb_put_archan(tag<1>* t = 0) { initiator1.archan->reset_put(); }

  virtual bool nb_put_wchan(const wchan_t& wchan, tag<1>* t = 0)
  { 
    if (!nb_can_put_wchan()) return false;

    typename SB_TRAITS::wchan_t simple_wchan;

    simple_wchan.data = wchan.data ;
    simple_wchan.byte_enables = wchan.strb ;
    simple_wchan.tid = wchan.tid;

    bool ret = initiator1.wchan->nb_put(simple_wchan);
    sc_assert(ret);
    return true;
  }

  virtual bool nb_can_put_wchan(tag<1>* t = 0) const { return (initiator1.wchan->nb_can_put()); }
  virtual void reset_nb_put_wchan(tag<1>* t = 0) {  return initiator1.wchan->reset_put(); }

  virtual bool nb_get_rchan(rchan_t& rchan, tag<1>* t = 0)
  {
    if (!nb_can_get_rchan()) return false;

    typename SB_TRAITS::rchan_t simple_rchan;

    bool ret = initiator1.rchan->nb_get(simple_rchan);
    sc_assert(ret);

    rchan.data = simple_rchan.data ;
    rchan.tid = simple_rchan.tid;
    rchan.last = simple_rchan.last;

    if (!simple_rchan.ok)
      rchan.resp = AXI_SLVERR_RESPONSE;
    else
      rchan.resp = AXI_OK_RESPONSE;
    
    return true;
  }

  virtual bool nb_can_get_rchan(tag<1>* t = 0) const { return (initiator1.rchan->nb_can_get()); }
  virtual void reset_nb_get_rchan(tag<1>* t = 0) {  return initiator1.rchan->reset_get(); }

  virtual bool nb_get_bchan(bchan_t& bchan, tag<1>* t = 0)
  {
    typename SB_TRAITS::bchan_t simple_bchan;

    bool ret = initiator1.bchan->nb_get(simple_bchan);

    if (!simple_bchan.ok )
      bchan.resp = AXI_SLVERR_RESPONSE;
    else
      bchan.resp = AXI_OK_RESPONSE;

    bchan.tid = simple_bchan.tid;

    return ret;
  }

  virtual bool nb_can_get_bchan(tag<1>* t = 0) const { return initiator1.bchan->nb_can_get(); }
  virtual void reset_nb_get_bchan(tag<1>* t = 0) {  return initiator1.bchan->reset_get(); }
};


}; // namespace axi3
}; // namespace cynw
