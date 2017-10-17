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

template <class top_traits, class T, axi3_rw_mode rw_mode, axi3_xtor_mode xtor_mode>
class axi_slave_transactor_imp  {};

template <class top_traits, class T>
class axi_slave_transactor_imp<top_traits, T, axi3::READ_WRITE, axi3::XTOR_DEF> :
  public sc_module
{
public:
  typedef typename T::awchan_t awchan_t;
  typedef typename T::archan_t archan_t;
  typedef typename T::wchan_t wchan_t;
  typedef typename T::rchan_t rchan_t;
  typedef typename T::bchan_t bchan_t;

  SC_HAS_PROCESS( axi_slave_transactor_imp );

  sc_in_clk clk;
  sc_in< bool > reset;

#include "axi3_slave_write_ports.h"
#include "axi3_slave_read_ports.h"

  simple_bus::bus_nb_put_get_initiator_socket<1, T > initiator1;


  put_get_channel<awchan_t, typename top_traits::put_get_traits> aw_chan;
  put_get_channel<wchan_t, typename top_traits::put_get_traits> w_chan;
  put_get_channel<archan_t, typename top_traits::put_get_traits> ar_chan;
  put_get_channel<rchan_t, typename top_traits::put_get_traits> r_chan;
  put_get_channel<bchan_t, typename top_traits::put_get_traits>   b_chan;

  nb_get_initiator<awchan_t, typename top_traits::put_get_traits> aw;
  nb_get_initiator<wchan_t, typename top_traits::put_get_traits> w;
  nb_get_initiator<archan_t, typename top_traits::put_get_traits> ar;
  nb_put_initiator<rchan_t, typename top_traits::put_get_traits> r;
  nb_put_initiator<bchan_t, typename top_traits::put_get_traits>   b;

  axi_slave_transactor_imp(sc_module_name name)
    : sc_module(name), 
      clk("clk"),
      reset("reset")
     ,
#include "axi3_write_ctors.h"
     ,
#include "axi3_read_ctors.h"
    , initiator1("initiator1")
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

    SC_THREAD_CLOCK_RESET_TRAITS(read_thread, clk, reset, top_traits::put_get_traits);
    SC_THREAD_CLOCK_RESET_TRAITS(write_thread, clk, reset, top_traits::put_get_traits);


    SC_METHOD(f_awvalid);
    sensitive << AWVALID;

    SC_METHOD(f_aw_chan_ready);
    sensitive << aw_chan.ready;

    SC_METHOD(f_aawchan);
    sensitive << AWLEN << AWSIZE << AWBURST << AWID << AWADDR << AWLOCK << AWCACHE << AWPROT ; 


    SC_METHOD(f_wvalid);
    sensitive << WVALID;

    SC_METHOD(f_w_chan_ready);
    sensitive << w_chan.ready;

    SC_METHOD(f_wchan);
    sensitive << WID << WSTRB << WDATA << WLAST;


    SC_METHOD(f_arvalid);
    sensitive << ARVALID;

    SC_METHOD(f_ar_chan_ready);
    sensitive << ar_chan.ready;

    SC_METHOD(f_aarchan);
    sensitive << ARLEN << ARSIZE << ARBURST << ARID << ARADDR << ARLOCK << ARCACHE << ARPROT ;


    SC_METHOD(f_r_chan_valid);
    sensitive << r_chan.valid;

    SC_METHOD(f_rready);
    sensitive << RREADY;

    SC_METHOD(f_r_chan_data);
    sensitive << r_chan.data;


    SC_METHOD(f_b_chan_valid);
    sensitive << b_chan.valid;

    SC_METHOD(f_bready);
    sensitive << BREADY;

    SC_METHOD(f_b_chan_data);
    sensitive << b_chan.data;
   }

private:

  void f_awvalid() { aw_chan.valid = AWVALID; }

  void f_aw_chan_ready() { AWREADY = aw_chan.ready ; }

  void f_aawchan() 
  {
   awchan_t d;

   d.len = AWLEN;
   d.size = AWSIZE;
   d.burst = AWBURST;
   d.tid = AWID;
   d.addr = AWADDR.read();
   d.lock = AWLOCK;
   d.cache = AWCACHE;
   d.prot = AWPROT;

   aw_chan.data = d;
  }

  void f_wvalid() { w_chan.valid = WVALID; }

  void f_w_chan_ready() { WREADY = w_chan.ready; }

  void f_wchan() 
  {
   wchan_t d;

   d.tid = WID;
   d.strb = WSTRB;
   d.data = WDATA;
   d.last = WLAST;

   w_chan.data = d;
  }

  void f_arvalid() { ar_chan.valid = ARVALID; }

  void f_ar_chan_ready() { ARREADY = ar_chan.ready ; }

  void f_aarchan() 
  {
   archan_t d;

   d.len = ARLEN;
   d.size = ARSIZE;
   d.burst = ARBURST;
   d.tid = ARID;
   d.addr = ARADDR.read();
   d.lock = ARLOCK;
   d.cache = ARCACHE;
   d.prot = ARPROT;

   ar_chan.data = d;
  }

  void f_r_chan_valid() { RVALID = r_chan.valid ; }

  void f_rready() { r_chan.ready = RREADY; }

  void f_r_chan_data()
  {
    RDATA = r_chan.data.read().data;
    RLAST = r_chan.data.read().last;
    RRESP = r_chan.data.read().resp;
    RID = r_chan.data.read().tid;
  }

  void f_b_chan_valid() { BVALID = b_chan.valid ; }

  void f_bready() {b_chan.ready = BREADY; }

  void f_b_chan_data()
  {
    BRESP = b_chan.data.read().resp;
    BID = b_chan.data.read().tid;
  }

  void read_thread()
  {
    HLS_DEFINE_PROTOCOL("read_thread");
    ar.reset_get();
    r.reset_put();
  
    initiator1.archan->reset_put();
    initiator1.rchan->reset_get();
  
    wait();
  
    while (1)
    {
      if (ar.nb_can_get() && initiator1.archan->nb_can_put())
      {
        archan_t archan_buf;
        (ar.nb_get(archan_buf));
        (initiator1.archan->nb_put(archan_buf));
      }
  
      if (r.nb_can_put() && initiator1.rchan->nb_can_get())
      {
        rchan_t rchan_buf;
        (initiator1.rchan->nb_get(rchan_buf));
        (r.nb_put(rchan_buf));
      }
  
      wait();
    }
  }

  void write_thread()
  {
    HLS_DEFINE_PROTOCOL("write_thread");
    aw.reset_get();
    w.reset_get();
    b.reset_put();
  
    initiator1.awchan->reset_put();
    initiator1.wchan->reset_put();
    initiator1.bchan->reset_get();
  
    wait();
  
    while (1)
    {
      if (aw.nb_can_get() && initiator1.awchan->nb_can_put())
      {
        awchan_t awchan_buf;
        (aw.nb_get(awchan_buf));
        (initiator1.awchan->nb_put(awchan_buf));
      }
  
      if (w.nb_can_get() && initiator1.wchan->nb_can_put())
      {
        wchan_t wchan_buf;
        (w.nb_get(wchan_buf));
        (initiator1.wchan->nb_put(wchan_buf));
      }
  
      if (b.nb_can_put() && initiator1.bchan->nb_can_get())
      {
        bchan_t bchan_buf;
        (initiator1.bchan->nb_get(bchan_buf));
        (b.nb_put(bchan_buf));
      }
  
      wait();
    }
  }

};

template <class top_traits, class T>
class axi_slave_transactor_imp<top_traits, T, axi3::READ_ONLY, axi3::XTOR_DEF> :
  public sc_module
{
public:
  typedef typename T::awchan_t awchan_t;
  typedef typename T::archan_t archan_t;
  typedef typename T::wchan_t wchan_t;
  typedef typename T::rchan_t rchan_t;
  typedef typename T::bchan_t bchan_t;

  SC_HAS_PROCESS( axi_slave_transactor_imp );

  sc_in_clk clk;
  sc_in< bool > reset;

#include "axi3_slave_read_ports.h"

  simple_bus::bus_nb_put_get_initiator_socket<1, T > initiator1;


  put_get_channel<archan_t, typename top_traits::put_get_traits> ar_chan;
  put_get_channel<rchan_t, typename top_traits::put_get_traits> r_chan;

  nb_get_initiator<archan_t, typename top_traits::put_get_traits> ar;
  nb_put_initiator<rchan_t, typename top_traits::put_get_traits> r;

  axi_slave_transactor_imp(sc_module_name name)
    : sc_module(name), 
      clk("clk"),
      reset("reset")
    ,
#include "axi3_read_ctors.h"
    , initiator1("initiator1")
    , ar_chan("ar_chan")
    , r_chan("r_chan")
    , ar("ar")
    , r("r")
  {   
    ar.clk_rst(clk, reset);
    r.clk_rst(clk, reset); 
  
    ar(ar_chan);
    r(r_chan);

    SC_THREAD_CLOCK_RESET_TRAITS(read_thread, clk, reset, top_traits::put_get_traits);


    SC_METHOD(f_arvalid);
    sensitive << ARVALID;

    SC_METHOD(f_ar_chan_ready);
    sensitive << ar_chan.ready;

    SC_METHOD(f_aarchan);
    sensitive << ARLEN << ARSIZE << ARBURST << ARID << ARADDR << ARLOCK << ARCACHE << ARPROT ;


    SC_METHOD(f_r_chan_valid);
    sensitive << r_chan.valid;

    SC_METHOD(f_rready);
    sensitive << RREADY;

    SC_METHOD(f_r_chan_data);
    sensitive << r_chan.data;

   }

private:


  void f_arvalid() { ar_chan.valid = ARVALID; }

  void f_ar_chan_ready() { ARREADY = ar_chan.ready ; }

  void f_aarchan() 
  {
   archan_t d;

   d.len = ARLEN;
   d.size = ARSIZE;
   d.burst = ARBURST;
   d.tid = ARID;
   d.addr = ARADDR.read();
   d.lock = ARLOCK;
   d.cache = ARCACHE;
   d.prot = ARPROT;

   ar_chan.data = d;
  }

  void f_r_chan_valid() { RVALID = r_chan.valid ; }

  void f_rready() { r_chan.ready = RREADY; }

  void f_r_chan_data()
  {
    RDATA = r_chan.data.read().data;
    RLAST = r_chan.data.read().last;
    RRESP = r_chan.data.read().resp;
    RID = r_chan.data.read().tid;
  }

  void read_thread()
  {
    HLS_DEFINE_PROTOCOL("read_thread");
    ar.reset_get();
    r.reset_put();
  
    initiator1.archan->reset_put();
    initiator1.rchan->reset_get();
  
    wait();
  
    while (1)
    {
      if (ar.nb_can_get() && initiator1.archan->nb_can_put())
      {
        archan_t archan_buf;
        (ar.nb_get(archan_buf));
        (initiator1.archan->nb_put(archan_buf));
      }
  
      if (r.nb_can_put() && initiator1.rchan->nb_can_get())
      {
        rchan_t rchan_buf;
        (initiator1.rchan->nb_get(rchan_buf));
        (r.nb_put(rchan_buf));
      }
  
      wait();
    }
  }
};

template <class top_traits, class T>
class axi_slave_transactor_imp<top_traits, T, axi3::WRITE_ONLY, axi3::XTOR_DEF> :
  public sc_module
{
public:
  typedef typename T::awchan_t awchan_t;
  typedef typename T::archan_t archan_t;
  typedef typename T::wchan_t wchan_t;
  typedef typename T::rchan_t rchan_t;
  typedef typename T::bchan_t bchan_t;

  SC_HAS_PROCESS( axi_slave_transactor_imp );

  sc_in_clk clk;
  sc_in< bool > reset;

#include "axi3_slave_write_ports.h"

  simple_bus::bus_nb_put_get_initiator_socket<1, T > initiator1;


  put_get_channel<awchan_t, typename top_traits::put_get_traits> aw_chan;
  put_get_channel<wchan_t, typename top_traits::put_get_traits> w_chan;
  put_get_channel<bchan_t, typename top_traits::put_get_traits>   b_chan;

  nb_get_initiator<awchan_t, typename top_traits::put_get_traits> aw;
  nb_get_initiator<wchan_t, typename top_traits::put_get_traits> w;
  nb_put_initiator<bchan_t, typename top_traits::put_get_traits>   b;

  axi_slave_transactor_imp(sc_module_name name)
    : sc_module(name), 
      clk("clk"),
      reset("reset")
     ,
#include "axi3_write_ctors.h"
    , initiator1("initiator1")
    , aw_chan("aw_chan")
    , w_chan("w_chan")
    , b_chan("b_chan")
    , aw("aw")
    , w("w")
    , b("b")
  {   
    aw.clk_rst(clk, reset);
    w.clk_rst(clk, reset);
    b.clk_rst(clk, reset); 
  
    aw(aw_chan);
    w(w_chan);
    b(b_chan);

    SC_THREAD_CLOCK_RESET_TRAITS(write_thread, clk, reset, top_traits::put_get_traits);


    SC_METHOD(f_awvalid);
    sensitive << AWVALID;

    SC_METHOD(f_aw_chan_ready);
    sensitive << aw_chan.ready;

    SC_METHOD(f_aawchan);
    sensitive << AWLEN << AWSIZE << AWBURST << AWID << AWADDR << AWLOCK << AWCACHE << AWPROT ;


    SC_METHOD(f_wvalid);
    sensitive << WVALID;

    SC_METHOD(f_w_chan_ready);
    sensitive << w_chan.ready;

    SC_METHOD(f_wchan);
    sensitive << WID << WSTRB << WDATA << WLAST;

    SC_METHOD(f_b_chan_valid);
    sensitive << b_chan.valid;

    SC_METHOD(f_bready);
    sensitive << BREADY;

    SC_METHOD(f_b_chan_data);
    sensitive << b_chan.data;
   }

private:

  void f_awvalid() { aw_chan.valid = AWVALID; }

  void f_aw_chan_ready() { AWREADY = aw_chan.ready ; }

  void f_aawchan() 
  {
   awchan_t d;

   d.len = AWLEN;
   d.size = AWSIZE;
   d.burst = AWBURST;
   d.tid = AWID;
   d.addr = AWADDR.read();
   d.lock = AWLOCK;
   d.cache = AWCACHE;
   d.prot = AWPROT;

   aw_chan.data = d;
  }

  void f_wvalid() { w_chan.valid = WVALID; }

  void f_w_chan_ready() { WREADY = w_chan.ready; }

  void f_wchan() 
  {
   wchan_t d;

   d.tid = WID;
   d.strb = WSTRB;
   d.data = WDATA;
   d.last = WLAST;

   w_chan.data = d;
  }

  void f_b_chan_valid() { BVALID = b_chan.valid ; }

  void f_bready() {b_chan.ready = BREADY; }

  void f_b_chan_data()
  {
    BRESP = b_chan.data.read().resp;
    BID = b_chan.data.read().tid;
  }

  void write_thread()
  {
    HLS_DEFINE_PROTOCOL("write_thread");
    aw.reset_get();
    w.reset_get();
    b.reset_put();
  
    initiator1.awchan->reset_put();
    initiator1.wchan->reset_put();
    initiator1.bchan->reset_get();
  
    wait();
  
    while (1)
    {
      if (aw.nb_can_get() && initiator1.awchan->nb_can_put())
      {
        awchan_t awchan_buf;
        (aw.nb_get(awchan_buf));
        (initiator1.awchan->nb_put(awchan_buf));
      }
  
      if (w.nb_can_get() && initiator1.wchan->nb_can_put())
      {
        wchan_t wchan_buf;
        (w.nb_get(wchan_buf));
        (initiator1.wchan->nb_put(wchan_buf));
      }
  
      if (b.nb_can_put() && initiator1.bchan->nb_can_get())
      {
        bchan_t bchan_buf;
        (initiator1.bchan->nb_get(bchan_buf));
        (b.nb_put(bchan_buf));
      }
  
      wait();
    }
  }

};

template <class top_traits, class T>
class axi_slave_transactor : public axi_slave_transactor_imp<top_traits, T, T::rw_mode, T::xtor_mode>
{
 public:
   axi_slave_transactor(sc_module_name nm) : axi_slave_transactor_imp<top_traits, T, T::rw_mode, T::xtor_mode>(nm) {}
};

  
}; // namespace axi3
}; // namespace cynw

