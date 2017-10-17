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

template <class traits>
struct axi3_single_rw_if : public sc_interface
{
 typedef typename traits::tlm_traits::archan_t archan_t;
 typedef typename traits::tlm_traits::awchan_t awchan_t;
 typedef typename traits::tlm_traits::rchan_t rchan_t;
 typedef typename traits::tlm_traits::wchan_t wchan_t;
 typedef typename traits::tlm_traits::bchan_t bchan_t;

  // Note: single_read and single_write function implementations can be either nonblocking or blocking.
  // The can_single* functions are always guaranteed to be called prior to a call to single_read or single_write,
  // and the latter functions will only be called if the can_single* functions were true. Thus, each time the
  // single_read() or single_write() function is called, a read item or write item MUST be accepted.

  virtual void reset_single_read() = 0;
  virtual void reset_single_write() = 0;

  virtual void single_read(archan_t& archan, rchan_t& rchan) = 0;
  virtual void single_write(awchan_t& awchan, const wchan_t& wchan, bchan_t& bchan) = 0;

  virtual bool can_single_read() const = 0;
  virtual bool can_single_write() const = 0;
};

template <class traits>
struct axi3_single_rw_adaptor :
   public sc_module
   , public bus_fw_nb_put_get_if<1, typename traits::tlm_traits>
{
 typedef typename traits::tlm_traits::archan_t archan_t;
 typedef typename traits::tlm_traits::awchan_t awchan_t;
 typedef typename traits::tlm_traits::rchan_t rchan_t;
 typedef typename traits::tlm_traits::wchan_t wchan_t;
 typedef typename traits::tlm_traits::bchan_t bchan_t;

 archan_t ar;
 awchan_t aw;
 bchan_t b;
 bool ar_valid, aw_valid, b_valid;
 bool r_error, w_error;

 sc_port<axi3_single_rw_if<traits> > target_port;

 axi3_single_rw_adaptor(sc_module_name nm) : sc_module(nm)
 {
  ar_valid = aw_valid = b_valid = false;
  r_error = w_error = false;
 }

 // Read interface:

 bool nb_put_archan(const archan_t& archan, tag<1>* t)
 {
  if (!nb_can_put_archan()) return false;
 
  r_error = false;

  if (archan.len != 0)
  {
    r_error = true;
  }
 
  ar = archan;
  ar_valid = true;
  return true;
 }

 virtual bool nb_can_put_archan(tag<1>* t = 0) const { return !ar_valid; }
 virtual void reset_nb_put_archan(tag<1>* t = 0) { ar=archan_t(); ar_valid = false; r_error = false; target_port->reset_single_read(); }

 bool nb_get_rchan(rchan_t& rchan, tag<1>* t)
 {
  if (!nb_can_get_rchan())
    return false;

  rchan.resp = AXI_OK_RESPONSE;
  rchan.tid = ar.tid;
  rchan.last = true;

  if (r_error)
  {
    rchan.resp = AXI_SLVERR_RESPONSE;
    if (ar.len == 0)
    {
      ar_valid = false;
      r_error = false;
    }
    else
    {
      ar.len -= 1;
      rchan.last = false;
    }
  }
  else
  {
    // Note: single_read() implementation MAY block.
    // At TLM2/TLM1 level, it is very unlikely that it would block, and even if it did it would most likely be harmless, and worst case would
    // would likely be a deadlocked simulation.
    // AT TLM_SIG / RTL level, since AXI3 slave transactor has separate processes for read and write channel groups, the only impact if 
    // single_read() blocks would be to stall the read group of channels, which is harmless.
    target_port->single_read(ar, rchan);
    ar_valid = false;
  }

  return true;
 }

 virtual bool nb_can_get_rchan(tag<1>* t = 0) const { return r_error || (ar_valid && target_port->can_single_read()); }
 virtual void reset_nb_get_rchan(tag<1>* t = 0) {target_port->reset_single_read(); }


 // Write interface:

  bool nb_put_awchan(const awchan_t& awchan, tag<1>* t)
  {
    if (!nb_can_put_awchan()) return false;

    w_error = false;

    if (awchan.len != 0)
    {
       w_error = true;
    }

    aw = awchan;
    aw_valid = true;
    return true;
  }

  virtual bool nb_can_put_awchan(tag<1>* t = 0) const { return !aw_valid && !b_valid; }

  virtual void reset_nb_put_awchan(tag<1>* t = 0) { aw=awchan_t(); aw_valid = false; w_error = false; target_port->reset_single_write();  }

  bool nb_put_wchan(const wchan_t& wchan, tag<1>* t)
  {
    if (!nb_can_put_wchan()) return false;

    b.resp = AXI_OK_RESPONSE;
    b.tid = aw.tid;
    b_valid = true;

    if (wchan.tid != aw.tid)
    {
      w_error = true;
      SC_REPORT_ERROR("/axi3_adaptor", "AXI3 Protocol error: initiator violated write interleaving depth of one for this target");
    }

    if (w_error)
    {
      b.resp = AXI_SLVERR_RESPONSE;
      if (aw.len == 0)
      {
        aw_valid = false;
        w_error = false;
      }
      else
      {
        aw.len -= 1;
        b_valid = false;
      }
    }
    else
    {
    // Note: single_write() implementation MAY block.
    // At TLM2/TLM1 level, it is very unlikely that it would block, and even if it did it would most likely be harmless, and worst case would
    // would likely be a deadlocked simulation.
    // AT TLM_SIG / RTL level, since AXI3 slave transactor has separate processes for read and write channel groups, the only impact if 
    // single_write() blocks would be to stall the read group of channels, which is harmless.
      target_port->single_write(aw, wchan, b);
      aw_valid = false;
    }

    return true;
  }

  virtual bool nb_can_put_wchan(tag<1>* t = 0) const { return w_error || (aw_valid && target_port->can_single_write()); }
  virtual void reset_nb_put_wchan(tag<1>* t = 0) { b=bchan_t(); b_valid = false; target_port->reset_single_write(); }

  bool nb_get_bchan(bchan_t& bchan, tag<1>* t)
  {
    if (!nb_can_get_bchan())
      return false;

    bchan = b;
    b_valid = 0;
    return true;
  }

  virtual bool nb_can_get_bchan(tag<1>* t = 0) const { return b_valid; }
  virtual void reset_nb_get_bchan(tag<1>* t = 0) { target_port->reset_single_write(); }
};

template <class traits>
struct axi3_multi_rw_if : public sc_interface
{
 typedef typename traits::tlm_traits::archan_t archan_t;
 typedef typename traits::tlm_traits::awchan_t awchan_t;
 typedef typename traits::tlm_traits::rchan_t rchan_t;
 typedef typename traits::tlm_traits::wchan_t wchan_t;
 typedef typename traits::tlm_traits::bchan_t bchan_t;

  virtual void reset_multi_read() = 0;
  virtual void reset_multi_write() = 0;

  // Note: multi_read and multi_write function implementations can be either nonblocking or blocking.
  // The can_multi* functions are always guaranteed to be called prior to a call to multi_read or multi_write,
  // and the latter functions will only be called if the can_multi* functions were true. Thus, each time the
  // multi_read() or multi_write() function is called, a read item or write item MUST be accepted.

  virtual void multi_read(archan_t& archan, rchan_t& rchan, bool& burst_done) = 0;
  virtual void multi_write(awchan_t& awchan, const wchan_t& wchan, bchan_t& bchan, bool& burst_done) = 0;

  virtual bool can_multi_read() const = 0;
  virtual bool can_multi_write() const = 0;
};

template <class traits>
struct axi3_multi_rw_adaptor :
   public sc_module
   , public bus_fw_nb_put_get_if<1, typename traits::tlm_traits>
{
 typedef typename traits::tlm_traits::archan_t archan_t;
 typedef typename traits::tlm_traits::awchan_t awchan_t;
 typedef typename traits::tlm_traits::rchan_t rchan_t;
 typedef typename traits::tlm_traits::wchan_t wchan_t;
 typedef typename traits::tlm_traits::bchan_t bchan_t;

 archan_t ar;
 awchan_t aw;
 bchan_t b;
 bool ar_valid, aw_valid, b_valid;
 bool w_error;

 sc_port<axi3_multi_rw_if<traits> > target_port;

 axi3_multi_rw_adaptor(sc_module_name nm) : sc_module(nm)
 {
  ar_valid = aw_valid = b_valid = false;
  w_error = false;
 }

 // Read interface:

 bool nb_put_archan(const archan_t& archan, tag<1>* t)
 {
  if (!nb_can_put_archan()) return false;
 
  ar = archan;
  ar_valid = true;
  return true;
 }

 virtual bool nb_can_put_archan(tag<1>* t = 0) const { return !ar_valid; }
 virtual void reset_nb_put_archan(tag<1>* t = 0) { ar=archan_t(); ar_valid = false; target_port->reset_multi_read(); }

 bool nb_get_rchan(rchan_t& rchan, tag<1>* t)
 {
  if (!nb_can_get_rchan())
    return false;

  rchan.resp = AXI_OK_RESPONSE;
  rchan.tid = ar.tid;
  rchan.last = false;

  bool burst_done = false;

    // Note: multi_read() implementation MAY block.
    // At TLM2/TLM1 level, it is very unlikely that it would block, and even if it did it would most likely be harmless, and worst case would
    // would likely be a deadlocked simulation.
    // AT TLM_SIG / RTL level, since AXI3 slave transactor has separate processes for read and write channel groups, the only impact if 
    // multi_read() blocks would be to stall the read group of channels, which is harmless.
  target_port->multi_read(ar, rchan, burst_done);

  if (burst_done)
  {
    ar_valid = false;
    rchan.last = true;
  }

  return true;
 }

 virtual bool nb_can_get_rchan(tag<1>* t = 0) const { return ar_valid && target_port->can_multi_read(); }
 virtual void reset_nb_get_rchan(tag<1>* t = 0) {target_port->reset_multi_read(); }


 // Write interface:

  bool nb_put_awchan(const awchan_t& awchan, tag<1>* t)
  {
    if (!nb_can_put_awchan()) return false;

    aw = awchan;
    aw_valid = true;

    b.resp = AXI_OK_RESPONSE;
    b.tid = aw.tid;
    b_valid = false;
    w_error = false;

    return true;
  }

  virtual bool nb_can_put_awchan(tag<1>* t = 0) const { return !aw_valid && !b_valid; }

  virtual void reset_nb_put_awchan(tag<1>* t = 0) { aw=awchan_t(); aw_valid = false; w_error = false; b_valid = false; target_port->reset_multi_write();  }

  bool nb_put_wchan(const wchan_t& wchan, tag<1>* t)
  {
    if (!nb_can_put_wchan()) return false;

    if (wchan.tid != aw.tid)
    {
      w_error = true;
      SC_REPORT_ERROR("/axi3_adaptor", "AXI3 Protocol error: initiator violated write interleaving depth of one for this target");
    }

    bool burst_done = false;

    // Note: multi_read() implementation MAY block.
    // At TLM2/TLM1 level, it is very unlikely that it would block, and even if it did it would most likely be harmless, and worst case would
    // would likely be a deadlocked simulation.
    // AT TLM_SIG / RTL level, since AXI3 slave transactor has separate processes for read and write channel groups, the only impact if 
    // multi_read() blocks would be to stall the read group of channels, which is harmless.
    target_port->multi_write(aw, wchan, b, burst_done);


#ifndef STRATUS
    if (wchan.last != burst_done)
    {
      std::stringstream str;
      str << "wchan.last != burst_done : wchan.last =  " << wchan.last << " burst_done = " << burst_done << endl;
      SC_REPORT_ERROR("/multi_write", str.str().c_str());
      sc_assert(false);
    }
#endif

    if (burst_done)
    {
      aw_valid = false;
      b_valid = true;
    }

    return true;
  }

  virtual bool nb_can_put_wchan(tag<1>* t = 0) const { return aw_valid && target_port->can_multi_write();  }
  virtual void reset_nb_put_wchan(tag<1>* t = 0) { b=bchan_t(); b_valid = false; target_port->reset_multi_write(); }

  bool nb_get_bchan(bchan_t& bchan, tag<1>* t)
  {
    if (!nb_can_get_bchan())
      return false;

    bchan = b;
    b_valid = 0;

    if (w_error)
     bchan.resp = AXI_SLVERR_RESPONSE;

    return true;
  }

  virtual bool nb_can_get_bchan(tag<1>* t = 0) const { return b_valid; }
  virtual void reset_nb_get_bchan(tag<1>* t = 0) { target_port->reset_multi_write(); }
};

}; // namespace axi3
}; // namespace cynw


