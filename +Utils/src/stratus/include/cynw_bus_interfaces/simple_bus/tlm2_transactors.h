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


#ifndef TLM2_TRANSACTORS_H
#define TLM2_TRANSACTORS_H true


#pragma once

#include "tlm.h"
#include "tlm_utils/multi_passthrough_initiator_socket.h"
#include "tlm_utils/multi_passthrough_target_socket.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include "vp_tlm_fifo.h"

namespace cynw {
namespace simple_bus {

using namespace tlm;
using namespace tlm_utils;


template <typename T>
static void copy_val_to_buf(const T val, unsigned char* p)
{
    *(T *)p = val;
}

template <> void copy_val_to_buf<sc_biguint<128> >(const sc_biguint<128> val, unsigned char* p)
{
    for (int i = 0; i < 16; i++)
      p[i] = val.range( (8*i) + 7 , (8*i) ).to_uint();
}

template <> void copy_val_to_buf<sc_biguint<256> >(const sc_biguint<256> val, unsigned char* p)
{
    for (int i = 0; i < 32; i++)
      p[i] = val.range( (8*i) + 7 , (8*i) ).to_uint();
}

template <> void copy_val_to_buf<sc_biguint<512> >(const sc_biguint<512> val, unsigned char* p)
{
    for (int i = 0; i < 64; i++)
      p[i] = val.range( (8*i) + 7 , (8*i) ).to_uint();
}

template <> void copy_val_to_buf<sc_biguint<1024> >(const sc_biguint<1024> val, unsigned char* p)
{
    for (int i = 0; i < 128; i++)
      p[i] = val.range( (8*i) + 7 , (8*i) ).to_uint();
}

template <typename T>
static void copy_buf_to_val(unsigned char* p, T& val)
{
    val = *(T *)p;
}

template <> void copy_buf_to_val<sc_biguint<128> >(unsigned char* p, sc_biguint<128>& val)
{
  val = 0;
  for (int i = 16; --i >= 0; ) {
    val = val * 256;
    val += p[i];
  }
}

template <> void copy_buf_to_val<sc_biguint<256> >(unsigned char* p, sc_biguint<256>& val)
{
  val = 0;
  for (int i = 32; --i >= 0; ) {
    val = val * 256;
    val += p[i];
  }
}

template <> void copy_buf_to_val<sc_biguint<512> >(unsigned char* p, sc_biguint<512>& val)
{
  val = 0;
  for (int i = 64; --i >= 0; ) {
    val = val * 256;
    val += p[i];
  }
}

template <> void copy_buf_to_val<sc_biguint<1024> >(unsigned char* p, sc_biguint<1024>& val)
{
  val = 0;
  for (int i = 128; --i >= 0; ) {
    val = val * 256;
    val += p[i];
  }
}


template <class SB_TRAITS>
class simple_bus_to_tlm2_initiator :
  public sc_module,
  public bus_fw_nb_put_get_if<1, SB_TRAITS >
{
public:
  multi_passthrough_initiator_socket<simple_bus_to_tlm2_initiator<SB_TRAITS>, SB_TRAITS::data_bytes*8> tlm2_initiator;
  bus_nb_put_get_target_socket<1, SB_TRAITS > target1;
  typedef typename SB_TRAITS::data_t data_t;
  typedef typename SB_TRAITS::awchan_t awchan_t;
  typedef typename SB_TRAITS::archan_t archan_t;
  typedef typename SB_TRAITS::wchan_t wchan_t;
  typedef typename SB_TRAITS::rchan_t rchan_t;
  typedef typename SB_TRAITS::bchan_t bchan_t;

  sc_event *external_wakeup;

  simple_bus_to_tlm2_initiator ( sc_module_name name) :
    tlm2_initiator("tlm2_initiator"),
    target1("target1"),
    external_wakeup(0),
    bchan_fifo("bchan_fifo", 2)
  {
    target1.target_port(*this);

    awchan_valid = false;
    archan_valid = false;
    wchan_buf = wchan_ptr = 0;
    rchan_buf = rchan_ptr = 0;
    wchan_buf_len = rchan_buf_len = 0;
  }

  void set_wakeup_event(sc_event* e)
  {
    external_wakeup = e;
  }

  // stuart: current limitations:
  //  - addresses must be aligned to bus data width, # bytes must be multiple of bus data width
  //  - byte enables are ignored and not propagated yet
  //  - bus size field in awchan and archan must be equal to bus data width and is currently ignored
  //  - bus awchan and archan can only have fixed set to false
  //  - streaming width must be equal to data length, implying normal incrementing burst
  //
  // this transactor does currently support concurrent read and write bursts on simple_bus, but note the corresponding burst write
  // on the tlm2_initiator will not occur until ALL of write data has been collected.

  bool awchan_valid;
  bool archan_valid;
  bool read_error;
  uint64 awchan_addr;
  uint64 awchan_tid;
  uint64 wlen_total;
  uint64 wlen_remain;
  uint64 rlen;
  uint64 archan_tid;
  unsigned char* wchan_buf;
  unsigned char* wchan_ptr;
  unsigned char* rchan_buf;
  unsigned char* rchan_ptr;
  uint64 wchan_buf_len;
  uint64 rchan_buf_len;
  struct bchan_item 
  {
   uint64 tid;
   bool ok;
  };
  vp_tlm::vp_tlm_fifo<bchan_item> bchan_fifo;

  ~simple_bus_to_tlm2_initiator()
  {
    if (wchan_buf)
      delete [] wchan_buf;
    if (rchan_buf)
      delete [] rchan_buf;
  }

  void alloc_wchan_buf(uint64 n)
  {
    if (wchan_buf_len >= n)
      return;

    if (wchan_buf)
      delete [] wchan_buf;

    wchan_buf = new unsigned char[n];
    wchan_buf_len = n;
  }

  void alloc_rchan_buf(uint64 n)
  {
    if (rchan_buf_len >= n)
      return;

    if (rchan_buf)
      delete [] rchan_buf;

    rchan_buf = new unsigned char[n];
    rchan_buf_len = n;
  }

  virtual bool nb_put_awchan(const awchan_t& awchan, tag<1>* t = 0)
  {
   if (external_wakeup) external_wakeup->notify();

   if (!nb_can_put_awchan())
     return false;

   awchan_valid = true;
   awchan_addr = awchan.addr;
   awchan_tid = awchan.tid;
   wlen_total = wlen_remain = (awchan.beats + 1) * SB_TRAITS::data_bytes;

   sc_assert(wlen_total);

   alloc_wchan_buf(wlen_total);
   wchan_ptr = wchan_buf;

   return true;
  }

  virtual bool nb_can_put_awchan(tag<1>* t = 0) const { return !awchan_valid; }
  virtual void reset_nb_put_awchan(tag<1>* t = 0) {}

  virtual bool nb_put_wchan(const wchan_t& wchan, tag<1>* t = 0)
  {
   if (external_wakeup) external_wakeup->notify();

    if (!nb_can_put_wchan())
      return false;

    sc_assert(wchan.tid == awchan_tid);

    copy_val_to_buf(wchan.data, wchan_ptr);

    wchan_ptr += SB_TRAITS::data_bytes;
    wlen_remain -= SB_TRAITS::data_bytes;

    if (wlen_remain <= 0)
    {
      tlm_generic_payload tx;
      sc_time tm(SC_ZERO_TIME);

      tx.set_write();
      tx.set_address(awchan_addr);
      tx.set_data_ptr(wchan_buf);
      tx.set_data_length(wlen_total);
      tx.set_byte_enable_ptr(NULL);
      tx.set_byte_enable_length(0);
      tx.set_streaming_width(wlen_total);

      // LOG("TLM2 b_transport WRITE: " << hex << awchan_addr << " " << wlen_total);

      // strictly speaking, it is not allowed to directly call the blocking function below from nb_put_wchan, which
      // is a non-blocking function. However, in practice, b_transport should never or rarely ever block (since that
      // is how TLM2 models get their performance), and also, in practice, the model calling nb_put_wchan will almost always
      // immediately wait for successful completion. Even if neither of these two conditions apply, the worst case impact
      // would be a deadlock of the simulation (as opposed to an incorrect result).
      tlm2_initiator->b_transport(tx, tm);

      wchan_ptr = 0;
      awchan_valid = false;

      bchan_item item;
      item.tid = awchan_tid;
  
      if (tx.get_response_status() == TLM_OK_RESPONSE)
        item.ok = true;
      else
        item.ok = false;

      bchan_fifo.put(item);
    }

    return true;
  }

  virtual bool nb_can_put_wchan(tag<1>* t = 0) const { return awchan_valid; }
  virtual void reset_nb_put_wchan(tag<1>* t = 0) {}

  virtual bool nb_get_bchan(bchan_t& bchan, tag<1>* t = 0)
  {
   if (external_wakeup) external_wakeup->notify();

    if (!nb_can_get_bchan())
      return false;

    bchan_item item = bchan_fifo.get();

    bchan.ok = item.ok;
    bchan.tid = item.tid; 

    return true;
  }

  virtual bool nb_can_get_bchan(tag<1>* t = 0) const { return bchan_fifo.nb_can_get(); }
  virtual void reset_nb_get_bchan(tag<1>* t = 0) {}


  virtual bool nb_put_archan(const archan_t& archan, tag<1>* t = 0)
  {
   if (external_wakeup) external_wakeup->notify();

   if (!nb_can_put_archan())
     return false;

   archan_valid = true;
   archan_tid = archan.tid;
   rlen = (archan.beats + 1) * SB_TRAITS::data_bytes;

   sc_assert(rlen);

   alloc_rchan_buf(rlen);
   rchan_ptr = rchan_buf;

   tlm_generic_payload tx;
   sc_time tm(SC_ZERO_TIME);

   tx.set_read();
   tx.set_address(archan.addr);
   tx.set_data_ptr(rchan_buf);
   tx.set_data_length(rlen);
   tx.set_byte_enable_ptr(NULL);
   tx.set_byte_enable_length(0);
   tx.set_streaming_width(rlen);

   // LOG("TLM2 b_transport READ: " << hex << archan.addr << " " << rlen);

      // strictly speaking, it is not allowed to directly call the blocking function below from nb_put_archan, which
      // is a non-blocking function. However, in practice, b_transport should never or rarely ever block (since that
      // is how TLM2 models get their performance), and also, in practice, the model calling nb_put_archan will almost always
      // immediately wait for successful completion. Even if neither of these two conditions apply, the worst case impact
      // would be a deadlock of the simulation (as opposed to an incorrect result).
   tlm2_initiator->b_transport(tx, tm);

   read_error = false;

   if (tx.get_response_status() != TLM_OK_RESPONSE)
     read_error = true;

   return true;
  }

  virtual bool nb_can_put_archan(tag<1>* t = 0) const { return !archan_valid; }
  virtual void reset_nb_put_archan(tag<1>* t = 0) {}

  virtual bool nb_get_rchan(rchan_t& rchan, tag<1>* t = 0)
  {
    if (external_wakeup) external_wakeup->notify();

    if (!nb_can_get_rchan())
      return false;

    copy_buf_to_val(rchan_ptr, rchan.data);

    if (read_error)
      rchan.ok = false;
    else
      rchan.ok = true;

    rchan.tid = archan_tid;

    rchan_ptr += SB_TRAITS::data_bytes;
    rlen -= SB_TRAITS::data_bytes;

    if (rlen <= 0)
    {
      archan_valid = false;
      rchan_ptr = 0;
      rchan.last = true;
    }

    return true;
  }

  virtual bool nb_can_get_rchan(tag<1>* t = 0) const { return (rlen > 0); }
  virtual void reset_nb_get_rchan(tag<1>* t = 0) {}
};



template <class SB_TRAITS>
class tlm2_target_to_simple_bus :
  public sc_module
{
public:
  multi_passthrough_target_socket<tlm2_target_to_simple_bus<SB_TRAITS>, SB_TRAITS::data_bytes*8> tlm2_target;
  bus_nb_put_get_initiator_socket<1, SB_TRAITS > initiator1;
  typedef typename SB_TRAITS::data_t data_t;
  typedef typename SB_TRAITS::awchan_t awchan_t;
  typedef typename SB_TRAITS::archan_t archan_t;
  typedef typename SB_TRAITS::wchan_t wchan_t;
  typedef typename SB_TRAITS::rchan_t rchan_t;
  typedef typename SB_TRAITS::bchan_t bchan_t;

  sc_in<bool> clk;
  sc_event *external_wakeup;


  tlm2_target_to_simple_bus (sc_module_name name) :
    tlm2_target("tlm2_target")
    , initiator1("initiator1")
    , clk("clk")
    , external_wakeup(0)
  {
    tlm2_target.register_b_transport(this, &tlm2_target_to_simple_bus<SB_TRAITS>::b_transport);
  }

  void set_wakeup_event(sc_event* e)
  {
    external_wakeup = e;
  }

  void start_of_simulation()
  {
    // TLM2 API doesn't propagate reset state, but we need to propagate reset to downstream channnels..
    initiator1.awchan->reset_put();
    initiator1.wchan->reset_put();
    initiator1.archan->reset_put();
    initiator1.rchan->reset_get();
    initiator1.bchan->reset_get();
  }

  // stuart: current limitations are same as in tlm2_initiator transactor

  virtual void b_transport(int tag, tlm_generic_payload& tx, sc_time& dt)
  {
    tlm_command command     = tx.get_command();
    uint64 addr             = tx.get_address();
    uint64 length           = tx.get_data_length();
    unsigned char* data_ptr = tx.get_data_ptr();

    if (external_wakeup) external_wakeup->notify();

    if (tag)
    {
       SC_REPORT_ERROR("/tlm2_target_to_simple_bus", "non-zero port tag indicates illegal multiple binding");
       sc_assert(false);
    }

#ifdef TLM2_TX_SIGNAL_WAIT
    // This wait() is needed if TLM2 tx is interfacing with RTL signal level model (which is a rare case)
    // If the wait() is omitted when it is needed, the FLEX_CHAN error indicates that nb* was called >1 in cycle
    wait(clk.posedge_event());
#endif

    tx.set_response_status(TLM_OK_RESPONSE);

    if (command == TLM_WRITE_COMMAND)
    {
      awchan_t awchan;
      awchan.addr = addr;
      awchan.beats = (length / SB_TRAITS::data_bytes) - 1;

      if (((awchan.beats + 1) * SB_TRAITS::data_bytes)  != length)
        SC_REPORT_ERROR("/tlm2_target_to_simple_bus", "b_transport length is not multiple of AXI buswidth");
    

      while (!initiator1.awchan->nb_put(awchan)) 
           wait(clk.posedge_event());

      wchan_t wchan;

      while (length > 0)
      {
        // stuart - need to verify cast is safe since TLM2 data array is in host endian format
        copy_buf_to_val(data_ptr, wchan.data);

        data_ptr += SB_TRAITS::data_bytes;
        length -= SB_TRAITS::data_bytes;

        while (!initiator1.wchan->nb_put(wchan)) 
           wait(clk.posedge_event());
      }

      bchan_t bchan;

      while (!initiator1.bchan->nb_get(bchan)) 
           wait(clk.posedge_event());

      sc_assert(bchan.tid == 0);

      if (bchan.ok != true)
        tx.set_response_status(TLM_GENERIC_ERROR_RESPONSE);
    }
   
    if (command == TLM_READ_COMMAND)
    {
      archan_t archan;
      archan.addr = addr;
      archan.beats = (length / SB_TRAITS::data_bytes) - 1;

      if (((archan.beats + 1) * SB_TRAITS::data_bytes)  != length)
        SC_REPORT_ERROR("/tlm2_target_to_simple_bus", "b_transport length is not multiple of AXI buswidth");
    

      while (!initiator1.archan->nb_put(archan)) 
           wait(clk.posedge_event());

      rchan_t rchan;

      while (length > 0)
      {
        while (!initiator1.rchan->nb_get(rchan)) 
           wait(clk.posedge_event());

        sc_assert(rchan.tid == 0);

        // stuart - need to verify cast is safe since TLM2 data array is in host endian format
        copy_val_to_buf(rchan.data, data_ptr);

        data_ptr += SB_TRAITS::data_bytes;
        length -= SB_TRAITS::data_bytes;

        if (rchan.ok != true)
          tx.set_response_status(TLM_GENERIC_ERROR_RESPONSE);
      }
    }
  }
};

template <class SB_TRAITS>
class tlm2_init_targ_channel : public sc_module {
public:

   multi_passthrough_target_socket<tlm2_init_targ_channel<SB_TRAITS>, SB_TRAITS::data_bytes*8> target1;
   multi_passthrough_initiator_socket<tlm2_init_targ_channel<SB_TRAITS>, SB_TRAITS::data_bytes*8> initiator1;

   tlm2_init_targ_channel(sc_module_name name) :
     sc_module(name)
   {
   }

   void before_end_of_elaboration()
   {
     initiator1(target1);
   }
};




template <typename traits, unsigned tag>
struct simple_bus_initiator_imp<traits, tag, IO_CONFIG_TLM2>
  : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>
  , sc_interface
{
  // specialization for TLM2 LEVEL

  simple_bus_initiator_imp(sc_module_name n) :
     bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>(n)
   , xtor("xtor")
   , tlm2("tlm2")
   {
        bind_nb_put_get_sockets((*this), xtor.target1); 
        xtor.tlm2_initiator(tlm2);
   }

  template <typename CHAN> void operator()(CHAN& chan) {
   tlm2(chan.initiator1);
  }

   simple_bus_to_tlm2_initiator<typename traits::tlm_traits> xtor;
   multi_passthrough_initiator_socket<simple_bus_initiator_imp<typename traits::tlm_traits,tag,IO_CONFIG_TLM2>, traits::tlm_traits::data_bytes*8> tlm2;

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }
};

template <typename traits, unsigned tag>
struct simple_bus_target_imp<traits, tag, IO_CONFIG_TLM2>
  : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>
{
  // specialization for TLM2 LEVEL

  simple_bus_target_imp(sc_module_name n) : 
     bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>(n)
   , xtor("xtor")
   , tlm2("tlm2")
   {
        bind_nb_put_get_sockets(xtor.initiator1, (*this)); 
        tlm2(xtor.tlm2_target);
   }

  tlm2_target_to_simple_bus<typename traits::tlm_traits>    xtor;

  multi_passthrough_target_socket<simple_bus_target_imp<typename traits::tlm_traits,tag,IO_CONFIG_TLM2>, traits::tlm_traits::data_bytes*8> tlm2;

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst)
  {
    xtor.clk(clk);
  }
};

template <typename traits>
struct simple_bus_channel_imp<traits, IO_CONFIG_TLM2> 
  : public tlm2_init_targ_channel<typename traits::tlm_traits>
{
  // specialization for TLM2 LEVEL

  simple_bus_channel_imp(sc_module_name n = "simple_bus_channel") : tlm2_init_targ_channel<typename traits::tlm_traits>(n) {}

  template <typename TARG> void operator()(TARG& targ) {
    (*this).target1(targ.tlm2);
  }

};


template <typename traits, unsigned tag>
struct hier_simple_bus_initiator_imp<traits, tag, IO_CONFIG_TLM2>
  : sc_module
{
  // specialization for TLM2 LEVEL

   hier_simple_bus_initiator_imp(sc_module_name n) : sc_module(n), tlm2("tlm2") {}

   multi_passthrough_initiator_socket<hier_simple_bus_initiator_imp<traits,tag,IO_CONFIG_TLM2>, traits::tlm_traits::data_bytes*8> tlm2;

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
struct hier_simple_bus_target_imp<traits, tag, IO_CONFIG_TLM2>
  : sc_module
{
  // specialization for TLM2 LEVEL

  hier_simple_bus_target_imp(sc_module_name n) : sc_module(n), tlm2("tlm2") {}

  multi_passthrough_target_socket<hier_simple_bus_target_imp<traits,tag,IO_CONFIG_TLM2>, traits::tlm_traits::data_bytes*8> tlm2;

  template <typename TARG> void hier_bind(TARG& subtarg)
  {
    tlm2(subtarg.tlm2);
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }
};

}; // namespace simple_bus
}; // namespace cynw;


#endif
