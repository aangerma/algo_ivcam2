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

#include "systemc.h"
#include "../simple_bus/simple_bus.h"

#include "axi3_traits.h"

#if defined STRATUS
#pragma hls_ip_def
#endif

namespace cynw {
namespace axi3 {

using namespace simple_bus;



template <class top_traits, class T, axi3_rw_mode rw_mode, axi3_xtor_mode xtor_mode>
class axi_master_transactor_imp  {};

template <class top_traits, class T>
class axi_master_transactor_imp<top_traits, T, axi3::READ_WRITE, axi3::XTOR_DEF> :
  public sc_module,
  public bus_fw_nb_put_get_if<2, T>
{
public:
  typedef typename T::awchan_t awchan_t;
  typedef typename T::archan_t archan_t;
  typedef typename T::wchan_t wchan_t;
  typedef typename T::rchan_t rchan_t;
  typedef typename T::bchan_t bchan_t;

  sc_in_clk clk;
  sc_in< bool > reset;

#include "axi3_master_write_ports.h"

#include "axi3_master_read_ports.h"

  bus_nb_put_get_target_socket<2, T>   target1;

private:

  SC_HAS_PROCESS(axi_master_transactor_imp);

  put_get_channel<awchan_t, typename top_traits::put_get_traits> aw_chan;
  put_get_channel<wchan_t, typename top_traits::put_get_traits> w_chan;
  put_get_channel<archan_t, typename top_traits::put_get_traits> ar_chan;
  put_get_channel<rchan_t, typename top_traits::put_get_traits> r_chan;
  put_get_channel<bchan_t, typename top_traits::put_get_traits>   b_chan;


  nb_put_initiator<awchan_t, typename top_traits::put_get_traits> aw;
  nb_put_initiator<wchan_t, typename top_traits::put_get_traits> w;
  nb_put_initiator<archan_t, typename top_traits::put_get_traits> ar;
  nb_get_initiator<rchan_t, typename top_traits::put_get_traits> r;
  nb_get_initiator<bchan_t, typename top_traits::put_get_traits>   b;

public:

  axi_master_transactor_imp(sc_module_name name)
  : sc_module(name),
    clk("clk"),
    reset("reset")
    ,
#include "axi3_write_ctors.h"
    ,
#include "axi3_read_ctors.h"
    , target1("target1")
    , aw_chan("aw_chan")
    , w_chan("w_chan")
    , ar_chan("ar_chan")
    , r_chan("r_chan")
    , b_chan("b_chan")
    , aw("aw")
    , w("w")
    , ar("ar")
    , r("r")
    , b("b")
   {
    print_version();

    target1.target_port(*this);

    aw.clk_rst(clk, reset);
    w.clk_rst(clk, reset);
    ar.clk_rst(clk, reset);
    r.clk_rst(clk, reset);
    b.clk_rst(clk, reset);

    aw(aw_chan);
    w(w_chan);
    ar(ar_chan);
    r(r_chan);
    b(b_chan);


    SC_METHOD(f_aw_chan_valid);
    sensitive << aw_chan.valid;

    SC_METHOD(f_awready);
    sensitive << AWREADY;

    SC_METHOD(f_aw_chan_data);
    sensitive << aw_chan.data;


    SC_METHOD(f_w_chan_valid);
    sensitive << w_chan.valid;

    SC_METHOD(f_wready);
    sensitive << WREADY;

    SC_METHOD(f_w_chan_data);
    sensitive << w_chan.data;


    SC_METHOD(f_ar_chan_valid);
    sensitive << ar_chan.valid;

    SC_METHOD(f_arready);
    sensitive << ARREADY;

    SC_METHOD(f_ar_chan_data);
    sensitive << ar_chan.data;


    SC_METHOD(f_rvalid);
    sensitive << RVALID;

    SC_METHOD(f_r_chan_ready);
    sensitive << r_chan.ready;

    SC_METHOD(f_rchan);
    sensitive << RDATA << RID << RRESP << RLAST;


    SC_METHOD(f_bvalid);
    sensitive << BVALID;

    SC_METHOD(f_b_chan_ready);
    sensitive << b_chan.ready;

    SC_METHOD(f_bresp);
    sensitive << BID << BRESP;
   }

private:

  void f_aw_chan_valid() { AWVALID = aw_chan.valid; }

  void f_awready() { aw_chan.ready = AWREADY; }

  void f_aw_chan_data() 
  {
   AWLEN = aw_chan.data.read().len;
   AWSIZE = aw_chan.data.read().size;
   AWBURST = aw_chan.data.read().burst;
   AWID = aw_chan.data.read().tid;
   AWADDR = aw_chan.data.read().addr;
   AWLOCK = aw_chan.data.read().lock;
   AWCACHE = aw_chan.data.read().cache;
   AWPROT = aw_chan.data.read().prot;
  }

  void f_w_chan_valid() { WVALID = w_chan.valid; }

  void f_wready() { w_chan.ready = WREADY; }

  void f_w_chan_data() 
  {
   WID = w_chan.data.read().tid;
   WSTRB = w_chan.data.read().strb;
   WDATA = w_chan.data.read().data;
   WLAST = w_chan.data.read().last;
  }

  void f_ar_chan_valid() { ARVALID = ar_chan.valid; }

  void f_arready() { ar_chan.ready = ARREADY; }

  void f_ar_chan_data() 
  {
   ARLEN = ar_chan.data.read().len;
   ARSIZE = ar_chan.data.read().size;
   ARBURST = ar_chan.data.read().burst;
   ARID = ar_chan.data.read().tid;
   ARADDR = ar_chan.data.read().addr;
   ARLOCK = ar_chan.data.read().lock;
   ARCACHE = ar_chan.data.read().cache;
   ARPROT = ar_chan.data.read().prot;
  }

  void f_rvalid() { r_chan.valid = RVALID; }

  void f_r_chan_ready() { RREADY = r_chan.ready; }

  void f_rchan()
  {
    typename T::rchan_t d;

    d.data = RDATA;
    d.last = RLAST;
    d.resp = RRESP;
    d.tid  = RID;

    r_chan.data = d;
  }

  void f_bvalid() { b_chan.valid = BVALID; }

  void f_b_chan_ready() { BREADY = b_chan.ready; }

  void f_bresp()
  {
    typename T::bchan_t d;  

    d.resp = BRESP;
    d.tid  = BID;

    b_chan.data = d;
  }


  //
  //  target1 methods:
  //

  virtual bool nb_put_awchan(const awchan_t& awchan, tag<2>* t = 0) { return aw.nb_put(awchan); }
  virtual bool nb_can_put_awchan(tag<2>* t = 0) const { return aw.nb_can_put(); }
  virtual void reset_nb_put_awchan(tag<2>* t = 0) { aw.reset_put(); }

  virtual bool nb_put_archan(const archan_t& archan, tag<2>* t = 0) { return ar.nb_put(archan); }
  virtual bool nb_can_put_archan(tag<2>* t = 0) const { return ar.nb_can_put(); }
  virtual void reset_nb_put_archan(tag<2>* t = 0) { ar.reset_put(); }

  virtual bool nb_put_wchan(const wchan_t& wchan, tag<2>* t = 0) { return w.nb_put(wchan); }
  virtual bool nb_can_put_wchan(tag<2>* t = 0) const { return w.nb_can_put(); }
  virtual void reset_nb_put_wchan(tag<2>* t = 0) { w.reset_put(); }

  virtual bool nb_get_rchan(rchan_t& rchan, tag<2>* t = 0) { return r.nb_get(rchan); }
  virtual bool nb_can_get_rchan(tag<2>* t = 0) const { return r.nb_can_get(); }
  virtual void reset_nb_get_rchan(tag<2>* t = 0) { r.reset_get(); }

  virtual bool nb_get_bchan(bchan_t& bchan, tag<2>* t = 0) { return b.nb_get(bchan); }
  virtual bool nb_can_get_bchan(tag<2>* t = 0) const { return b.nb_can_get(); }
  virtual void reset_nb_get_bchan(tag<2>* t = 0) { b.reset_get(); }
};

template <class top_traits, class T>
class axi_master_transactor_imp<top_traits, T, axi3::READ_ONLY, axi3::XTOR_DEF> :
  public sc_module,
  public bus_fw_nb_put_get_if<2, T>
{
public:
  typedef typename T::awchan_t awchan_t;
  typedef typename T::archan_t archan_t;
  typedef typename T::wchan_t wchan_t;
  typedef typename T::rchan_t rchan_t;
  typedef typename T::bchan_t bchan_t;

  sc_in_clk clk;
  sc_in< bool > reset;

#include "axi3_master_read_ports.h"

  bus_nb_put_get_target_socket<2, T>   target1;

private:

  SC_HAS_PROCESS(axi_master_transactor_imp);

  put_get_channel<archan_t, typename top_traits::put_get_traits> ar_chan;
  put_get_channel<rchan_t, typename top_traits::put_get_traits> r_chan;


  nb_put_initiator<archan_t, typename top_traits::put_get_traits> ar;
  nb_get_initiator<rchan_t, typename top_traits::put_get_traits> r;

public:

  axi_master_transactor_imp(sc_module_name name)
  : sc_module(name),
    clk("clk"),
    reset("reset")
    ,
#include "axi3_read_ctors.h"
    , target1("target1")
    , ar_chan("ar_chan")
    , r_chan("r_chan")
    , ar("ar")
    , r("r")
   {
    target1.target_port(*this);

    ar.clk_rst(clk, reset);
    r.clk_rst(clk, reset);

    ar(ar_chan);
    r(r_chan);

    SC_METHOD(f_ar_chan_valid);
    sensitive << ar_chan.valid;

    SC_METHOD(f_arready);
    sensitive << ARREADY;

    SC_METHOD(f_ar_chan_data);
    sensitive << ar_chan.data;


    SC_METHOD(f_rvalid);
    sensitive << RVALID;

    SC_METHOD(f_r_chan_ready);
    sensitive << r_chan.ready;

    SC_METHOD(f_rchan);
    sensitive << RDATA << RID << RRESP << RLAST;

   }

private:

  void f_ar_chan_valid() { ARVALID = ar_chan.valid; }

  void f_arready() { ar_chan.ready = ARREADY; }

  void f_ar_chan_data() 
  {
   ARLEN = ar_chan.data.read().len;
   ARSIZE = ar_chan.data.read().size;
   ARBURST = ar_chan.data.read().burst;
   ARID = ar_chan.data.read().tid;
   ARADDR = ar_chan.data.read().addr;
   ARLOCK = ar_chan.data.read().lock;
   ARCACHE = ar_chan.data.read().cache;
   ARPROT = ar_chan.data.read().prot;
  }

  void f_rvalid() { r_chan.valid = RVALID; }

  void f_r_chan_ready() { RREADY = r_chan.ready; }

  void f_rchan()
  {
    typename T::rchan_t d;

    d.data = RDATA;
    d.last = RLAST;
    d.resp = RRESP;
    d.tid  = RID;

    r_chan.data = d;
  }

  //
  //  target1 methods:
  //

  void wr_err() const { SC_REPORT_FATAL("/axi3/read_only", "write transaction occured on read only socket"); }

  virtual bool nb_put_awchan(const awchan_t& awchan, tag<2>* t = 0) { wr_err(); return false; }
  virtual bool nb_can_put_awchan(tag<2>* t = 0) const { wr_err(); return false; }
  virtual void reset_nb_put_awchan(tag<2>* t = 0) { }

  virtual bool nb_put_wchan(const wchan_t& wchan, tag<2>* t = 0) { wr_err(); return false; }
  virtual bool nb_can_put_wchan(tag<2>* t = 0) const { wr_err(); return false; }
  virtual void reset_nb_put_wchan(tag<2>* t = 0) { }

  virtual bool nb_get_bchan(bchan_t& bchan, tag<2>* t = 0) { wr_err(); return false; }
  virtual bool nb_can_get_bchan(tag<2>* t = 0) const { wr_err(); return false; }
  virtual void reset_nb_get_bchan(tag<2>* t = 0) { }

  virtual bool nb_put_archan(const archan_t& archan, tag<2>* t = 0) { return ar.nb_put(archan); }
  virtual bool nb_can_put_archan(tag<2>* t = 0) const { return ar.nb_can_put(); }
  virtual void reset_nb_put_archan(tag<2>* t = 0) { ar.reset_put(); }

  virtual bool nb_get_rchan(rchan_t& rchan, tag<2>* t = 0) { return r.nb_get(rchan); }
  virtual bool nb_can_get_rchan(tag<2>* t = 0) const { return r.nb_can_get(); }
  virtual void reset_nb_get_rchan(tag<2>* t = 0) { r.reset_get(); }
};

template <class top_traits, class T>
class axi_master_transactor_imp<top_traits, T, axi3::WRITE_ONLY, axi3::XTOR_DEF> :
  public sc_module,
  public bus_fw_nb_put_get_if<2, T>
{
public:
  typedef typename T::awchan_t awchan_t;
  typedef typename T::archan_t archan_t;
  typedef typename T::wchan_t wchan_t;
  typedef typename T::rchan_t rchan_t;
  typedef typename T::bchan_t bchan_t;

  sc_in_clk clk;
  sc_in< bool > reset;

#include "axi3_master_write_ports.h"

  bus_nb_put_get_target_socket<2, T>   target1;

private:

  SC_HAS_PROCESS(axi_master_transactor_imp);

  put_get_channel<awchan_t, typename top_traits::put_get_traits> aw_chan;
  put_get_channel<wchan_t, typename top_traits::put_get_traits> w_chan;
  put_get_channel<bchan_t, typename top_traits::put_get_traits>   b_chan;


  nb_put_initiator<awchan_t, typename top_traits::put_get_traits> aw;
  nb_put_initiator<wchan_t, typename top_traits::put_get_traits> w;
  nb_get_initiator<bchan_t, typename top_traits::put_get_traits>   b;

public:

  axi_master_transactor_imp(sc_module_name name)
  : sc_module(name),
    clk("clk"),
    reset("reset")
    ,
#include "axi3_write_ctors.h"
    , target1("target1")
    , aw_chan("aw_chan")
    , w_chan("w_chan")
    , b_chan("b_chan")
    , aw("aw")
    , w("w")
    , b("b")
   {
    target1.target_port(*this);

    aw.clk_rst(clk, reset);
    w.clk_rst(clk, reset);
    b.clk_rst(clk, reset);

    aw(aw_chan);
    w(w_chan);
    b(b_chan);


    SC_METHOD(f_aw_chan_valid);
    sensitive << aw_chan.valid;

    SC_METHOD(f_awready);
    sensitive << AWREADY;

    SC_METHOD(f_aw_chan_data);
    sensitive << aw_chan.data;


    SC_METHOD(f_w_chan_valid);
    sensitive << w_chan.valid;

    SC_METHOD(f_wready);
    sensitive << WREADY;

    SC_METHOD(f_w_chan_data);
    sensitive << w_chan.data;

    SC_METHOD(f_bvalid);
    sensitive << BVALID;

    SC_METHOD(f_b_chan_ready);
    sensitive << b_chan.ready;

    SC_METHOD(f_bresp);
    sensitive << BID << BRESP;
   }

private:

  void f_aw_chan_valid() { AWVALID = aw_chan.valid; }

  void f_awready() { aw_chan.ready = AWREADY; }

  void f_aw_chan_data() 
  {
   AWLEN = aw_chan.data.read().len;
   AWSIZE = aw_chan.data.read().size;
   AWBURST = aw_chan.data.read().burst;
   AWID = aw_chan.data.read().tid;
   AWADDR = aw_chan.data.read().addr;
   AWLOCK = aw_chan.data.read().lock;
   AWCACHE = aw_chan.data.read().cache;
   AWPROT = aw_chan.data.read().prot;
  }

  void f_w_chan_valid() { WVALID = w_chan.valid; }

  void f_wready() { w_chan.ready = WREADY; }

  void f_w_chan_data() 
  {
   WID = w_chan.data.read().tid;
   WSTRB = w_chan.data.read().strb;
   WDATA = w_chan.data.read().data;
   WLAST = w_chan.data.read().last;
  }

  void f_bvalid() { b_chan.valid = BVALID; }

  void f_b_chan_ready() { BREADY = b_chan.ready; }

  void f_bresp()
  {
    typename T::bchan_t d;  

    d.resp = BRESP;
    d.tid  = BID;

    b_chan.data = d;
  }


  //
  //  target1 methods:
  //

  virtual bool nb_put_awchan(const awchan_t& awchan, tag<2>* t = 0) { return aw.nb_put(awchan); }
  virtual bool nb_can_put_awchan(tag<2>* t = 0) const { return aw.nb_can_put(); }
  virtual void reset_nb_put_awchan(tag<2>* t = 0) { aw.reset_put(); }

  virtual bool nb_put_wchan(const wchan_t& wchan, tag<2>* t = 0) { return w.nb_put(wchan); }
  virtual bool nb_can_put_wchan(tag<2>* t = 0) const { return w.nb_can_put(); }
  virtual void reset_nb_put_wchan(tag<2>* t = 0) { w.reset_put(); }

  virtual bool nb_get_bchan(bchan_t& bchan, tag<2>* t = 0) { return b.nb_get(bchan); }
  virtual bool nb_can_get_bchan(tag<2>* t = 0) const { return b.nb_can_get(); }
  virtual void reset_nb_get_bchan(tag<2>* t = 0) { b.reset_get(); }

  void rd_err() const { SC_REPORT_FATAL("/axi3/write_only", "read transaction occured on write only socket"); }

  virtual bool nb_put_archan(const archan_t& archan, tag<2>* t = 0) { rd_err(); return false; }
  virtual bool nb_can_put_archan(tag<2>* t = 0) const { rd_err(); return false; }
  virtual void reset_nb_put_archan(tag<2>* t = 0) { }

  virtual bool nb_get_rchan(rchan_t& rchan, tag<2>* t = 0) { rd_err(); return false; }
  virtual bool nb_can_get_rchan(tag<2>* t = 0) const { rd_err(); return false; }
  virtual void reset_nb_get_rchan(tag<2>* t = 0) { }

};

template <class top_traits, class T>
class axi_master_transactor : public axi_master_transactor_imp<top_traits, T, T::rw_mode, T::xtor_mode>
{
 public:
   axi_master_transactor(sc_module_name nm) : axi_master_transactor_imp<top_traits, T, T::rw_mode, T::xtor_mode>(nm) {}
};

}; // namespace axi3
}; // namespace cynw
