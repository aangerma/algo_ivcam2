
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



#ifndef SIMPLE_BUS_H
#define SIMPLE_BUS_H true


#pragma once

#include "../hls_basics/hls_basics.h"


#include "simple_bus_ifs.h"
#include "simple_bus_adaptors.h"

namespace cynw {
namespace simple_bus {

// simple_bus streaming burst items
// - abstract away the underlying bus protocol (AXI, AHB, OCP), etc.
// - abstract away the initiator / target socket data width
// - protocol relationships between items on different channels is very similar to AXI
// - addresses are expressed in BYTES
// - lengths are expressed in beats, similar to AXI. A zero beat count indicates 1 transfer, beat==1 indicates 2 transfers, etc.


struct simple_bus_width_traits_16
{
  static const unsigned data_bytes = 2;
  static const unsigned addr_bytes = 4;
  static const unsigned default_size = 1;
  static const unsigned SIZE_W = 3;
  static const unsigned ID_W  = 4;
};

struct simple_bus_width_traits_32
{
  static const unsigned data_bytes = 4;
  static const unsigned addr_bytes = 4;
  static const unsigned default_size = 2;
  static const unsigned SIZE_W = 3;
  static const unsigned ID_W  = 4;
};

struct simple_bus_width_traits_64
{
  static const unsigned data_bytes = 8;
  static const unsigned addr_bytes = 4;
  static const unsigned default_size = 3;
  static const unsigned SIZE_W = 3;
  static const unsigned ID_W  = 4;
};

struct simple_bus_width_traits_128
{
  static const unsigned data_bytes = 16;
  static const unsigned addr_bytes = 4;
  static const unsigned default_size = 4;
  static const unsigned SIZE_W = 3;
  static const unsigned ID_W  = 4;
};

struct simple_bus_width_traits_256
{
  static const unsigned data_bytes = 32;
  static const unsigned addr_bytes = 4;
  static const unsigned default_size = 5;
  static const unsigned SIZE_W = 3;
  static const unsigned ID_W  = 4;
};

struct simple_bus_width_traits_512
{
  static const unsigned data_bytes = 64;
  static const unsigned addr_bytes = 4;
  static const unsigned default_size = 6;
  static const unsigned SIZE_W = 3;
  static const unsigned ID_W  = 4;
};

struct simple_bus_width_traits_1024
{
  static const unsigned data_bytes = 128;
  static const unsigned addr_bytes = 4;
  static const unsigned default_size = 7;
  static const unsigned SIZE_W = 3;
  static const unsigned ID_W  = 4;
};

template <typename width_traits, typename DATA_T, typename ADDR_T>
struct simple_bus_types_traits : public width_traits
{
  typedef ADDR_T addr_t;
  typedef DATA_T data_t;
  typedef sc_uint<width_traits::SIZE_W> simple_bus_size_t; // # of bytes to be read/written on each read/write data transfer, expressed as (1 << N), i.e. 0 -> 1, 2 -> 4, etc.
  typedef sc_uint<width_traits::ID_W > simple_bus_tid_t; // transaction ID
};

template <typename TB>
struct simple_bus_awchan_t
{
  typename TB::addr_t addr;   // burst adddress, expressed in BYTES
  typename TB::addr_t beats;    
       // - lengths are expressed in beats, similar to AXI. A zero beat count indicates 1 transfer, beat==1 indicates 2 transfers, etc.
  bool                fixed;  // true iff this is a FIXED burst, false if it is an INCREMENTING burst
  typename TB::simple_bus_size_t size; // # of bytes to be read/written on each read/write data transfer,
                          //  expressed as (1 << N), i.e. 0 -> 1, 2 -> 4, etc.
  typename TB::simple_bus_tid_t tid;  // transaction ID

  simple_bus_awchan_t() : addr(0), beats(0), fixed(false), size(TB::default_size), tid(0) {}

  bool operator==(const simple_bus_awchan_t& r)
  {
      return ((addr == r.addr) && (beats == r.beats) && (fixed == r.fixed) && (size == r.size) && (tid == r.tid));
  }
};


template <typename TB>
static std::ostream& operator<<(std::ostream& s, const simple_bus_awchan_t<TB>& r) { return s;}
template <typename TB>
static void sc_trace(sc_trace_file* f, const simple_bus_awchan_t<TB>& r, const std::string& s) {}

template <typename TB>
struct simple_bus_archan_t
{
  typename TB::addr_t addr;   // burst adddress, expressed in BYTES
  typename TB::addr_t beats;   
       // - lengths are expressed in beats, similar to AXI. A zero beat count indicates 1 transfer, beat==1 indicates 2 transfers, etc.
  bool                fixed;  // true iff this is a FIXED burst, false if it is an INCREMENTING burst
  typename TB::simple_bus_size_t size; // # of bytes to be read/written on each read/write data transfer,
                          //  expressed as (1 << N), i.e. 0 -> 1, 2 -> 4, etc.
  typename TB::simple_bus_tid_t tid;  // transaction ID

  simple_bus_archan_t() : addr(0), beats(0), fixed(false), size(TB::default_size), tid(0) {}

  bool operator==(const simple_bus_archan_t& r)
  {
      return ((addr == r.addr) && (beats == r.beats) && (fixed == r.fixed) && (size == r.size) && (tid == r.tid));
  }
};

template <typename TB>
static std::ostream& operator<<(std::ostream& s, const simple_bus_archan_t<TB>& r) { return s;}
template <typename TB>
static void sc_trace(sc_trace_file* f, const simple_bus_archan_t<TB>& r, const std::string& s) {}

template <typename TB>
struct simple_bus_wchan_t
{
  typename TB::data_t     data;   // the write data
  sc_uint<TB::data_bytes> byte_enables;
  typename TB::simple_bus_tid_t tid;  // transaction ID

  simple_bus_wchan_t() : data(0), byte_enables(~0), tid(0) {}
  bool operator==(const simple_bus_wchan_t& r)
  {
    return ((data == r.data) && (byte_enables == r.byte_enables) && (tid == r.tid));
  }
};

template <typename TB>
static std::ostream& operator<<(std::ostream& s, const simple_bus_wchan_t<TB>& r) { return s;}
template <typename TB>
static void sc_trace(sc_trace_file* f, const simple_bus_wchan_t<TB>& r, const std::string& s) {}

template <typename TB>
struct simple_bus_rchan_t
{
  typename TB::data_t data;      // the read data
  bool                ok;        // true iff read was successful, indicates that read data item is valid
  typename TB::simple_bus_tid_t tid;  // transaction ID
  bool last;  // indicates if this is the last transfer in overall simple bus read burst

  simple_bus_rchan_t() : data(0), ok(true), tid(0) , last(false) {}
  bool operator==(const simple_bus_rchan_t& r)
  {
    return ((data == r.data) && (ok == r.ok) && (tid == r.tid) && (last == r.last));
  }
};

template <typename TB>
static std::ostream& operator<<(std::ostream& s, const simple_bus_rchan_t<TB>& r) { return s;}
template <typename TB>
static void sc_trace(sc_trace_file* f, const simple_bus_rchan_t<TB>& r, const std::string& s) {}

template <typename TB>
struct simple_bus_bchan_t
{
  bool  ok;    // true iff entire write burst write was successful
  typename TB::simple_bus_tid_t tid;  // transaction ID

  simple_bus_bchan_t() : ok(true), tid(0) {}
  bool operator==(const simple_bus_bchan_t& r)
  {
    return ((ok == r.ok) && (tid == r.tid));
  }
};

template <typename TB>
static std::ostream& operator<<(std::ostream& s, const simple_bus_bchan_t<TB>& r) { return s;}
template <typename TB>
static void sc_trace(sc_trace_file* f, const simple_bus_bchan_t<TB>& r, const std::string& s) {}


typedef unsigned io_config_t;
static const unsigned IO_CONFIG_TLM1 = 0;
static const unsigned IO_CONFIG_TLM2 = 1;
static const unsigned IO_CONFIG_AXI3_SIG = 2;
static const unsigned IO_CONFIG_AXI4_LITE_SIG = 3;
// enum io_config_t { IO_CONFIG_TLM1, IO_CONFIG_AXI3_SIG };  // This is better but CtoS doesn't support it currently

template <typename TB>
struct simple_bus_traits : public TB
{
  typedef simple_bus_awchan_t<TB>    awchan_t;
  typedef simple_bus_archan_t<TB>    archan_t;
  typedef simple_bus_wchan_t<TB>    wchan_t;
  typedef simple_bus_rchan_t<TB>    rchan_t;
  typedef simple_bus_bchan_t<TB>      bchan_t;
};


struct simple_bus_traits_base_16: public simple_bus_types_traits<simple_bus_width_traits_16, unsigned short, unsigned> {};

struct simple_bus_traits_base_32: public simple_bus_types_traits<simple_bus_width_traits_32, unsigned, unsigned> {};

struct simple_bus_traits_base_64: public simple_bus_types_traits<simple_bus_width_traits_64, unsigned long long, unsigned> {};

struct simple_bus_traits_base_128: public simple_bus_types_traits<simple_bus_width_traits_128, sc_biguint<128>, unsigned> {};

struct simple_bus_traits_base_256: public simple_bus_types_traits<simple_bus_width_traits_256, sc_biguint<256>, unsigned> {};

struct simple_bus_traits_base_512: public simple_bus_types_traits<simple_bus_width_traits_512, sc_biguint<512>, unsigned> {};

struct simple_bus_traits_base_1024: public simple_bus_types_traits<simple_bus_width_traits_1024, sc_biguint<1024>, unsigned> {};


template <typename traits, unsigned tag, io_config_t io_config>
struct simple_bus_initiator_imp
{
  // General form of template , never used
  typedef typename traits::TEMPLATE_INSTANTIATION_ERROR TEMPLATE_INSTANTIATION_ERROR;
};

template <typename traits, unsigned tag>
struct simple_bus_initiator_imp<traits, tag, IO_CONFIG_TLM1>
  : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>
  , sc_interface
{
  // specialization for TLM1 LEVEL

  simple_bus_initiator_imp(sc_module_name n) : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>(n) {}

  template <typename CHAN> void operator()(CHAN& chan) {
   bind_nb_put_get_sockets( (*this) , chan.target1);
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }
};

template <typename traits, unsigned tag=1>
struct simple_bus_initiator : public simple_bus_initiator_imp<traits, tag, traits::io_config>
{
public:
  simple_bus_initiator(sc_module_name n = "simple_bus_initiator") : simple_bus_initiator_imp<traits, tag, traits::io_config>(n) {}

  static const unsigned data_bytes = traits::tlm_traits::data_bytes;
  static const unsigned default_size = traits::tlm_traits::default_size;
}; 



template <typename traits, unsigned tag, io_config_t io_config>
struct simple_bus_target_imp
{
  // General form of template , never used
  typedef typename traits::TEMPLATE_INSTANTIATION_ERROR TEMPLATE_INSTANTIATION_ERROR;
};

template <typename traits, unsigned tag>
struct simple_bus_target_imp<traits, tag, IO_CONFIG_TLM1>
  : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>
{
  // specialization for TLM1 LEVEL

  simple_bus_target_imp(sc_module_name n) : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>(n) {}

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }
};

template <typename traits, unsigned tag=1>
struct simple_bus_target : public simple_bus_target_imp<traits, tag, traits::io_config>
{
public:
  simple_bus_target(sc_module_name n = "simple_bus_target") : simple_bus_target_imp<traits, tag, traits::io_config>(n) {}

  static const unsigned data_bytes = traits::tlm_traits::data_bytes;
  static const unsigned default_size = traits::tlm_traits::default_size;
};


template <typename traits, unsigned io_config>
struct simple_bus_channel_imp
{
  // General form of template , never used
  typedef typename traits::TEMPLATE_INSTANTIATION_ERROR TEMPLATE_INSTANTIATION_ERROR;
};

template <typename traits>
struct simple_bus_channel_imp<traits, IO_CONFIG_TLM1> 
  : public bus_nb_put_get_channel<typename traits::tlm_traits>
{
  // specialization for TLM1 LEVEL

  simple_bus_channel_imp(sc_module_name n = "simple_bus_channel") : bus_nb_put_get_channel<typename traits::tlm_traits>(n) {}

  template <typename TARG> void operator()(TARG& targ) {
    (*this).target1.target_port(targ.target_port);
  }
};

template <typename traits>
struct simple_bus_channel : public simple_bus_channel_imp<traits, traits::io_config>
{
  simple_bus_channel(sc_module_name n = "simple_bus_channel") : simple_bus_channel_imp<traits, traits::io_config>(n) {}

};


///////////// stuart



template <typename traits, unsigned tag, unsigned io_config>
struct hier_simple_bus_initiator_imp
{
  // General form of template , never used
  typedef typename traits::TEMPLATE_INSTANTIATION_ERROR TEMPLATE_INSTANTIATION_ERROR;
};

template <typename traits, unsigned tag>
struct hier_simple_bus_initiator_imp<traits, tag, IO_CONFIG_TLM1>
  : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>
  , sc_interface
{
  // specialization for TLM LEVEL

  hier_simple_bus_initiator_imp(sc_module_name n) : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>(n) {}

  template <typename CHAN> void operator()(CHAN& chan) {
   bind_nb_put_get_sockets( (*this) , chan.target1);
  }

  template <typename TARG> void hier_bind(TARG& subinit)
  {
   bind_nb_put_get_sockets( subinit, (*this) );
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }
};

template <typename traits, unsigned tag=1>
struct hier_simple_bus_initiator : public hier_simple_bus_initiator_imp<traits, tag, traits::io_config>
{
public:
  hier_simple_bus_initiator(sc_module_name n = "hier_simple_bus_initiator") : hier_simple_bus_initiator_imp<traits, tag, traits::io_config>(n) {}

  static const unsigned data_bytes = traits::tlm_traits::data_bytes;
  static const unsigned default_size = traits::tlm_traits::default_size;
}; 



template <typename traits, unsigned tag, unsigned io_config>
struct hier_simple_bus_target_imp
{
  // General form of template , never used
  typedef typename traits::TEMPLATE_INSTANTIATION_ERROR TEMPLATE_INSTANTIATION_ERROR;
};

template <typename traits, unsigned tag>
struct hier_simple_bus_target_imp<traits, tag, IO_CONFIG_TLM1>
  : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>
{
  // specialization for TLM LEVEL

  hier_simple_bus_target_imp(sc_module_name n) : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>(n) {}

  template <typename TARG> void hier_bind(TARG& subtarg)
  {
    (*this).target_port(subtarg.target_port);
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }
};

template <typename traits, unsigned tag=1>
struct hier_simple_bus_target : public hier_simple_bus_target_imp<traits, tag, traits::io_config>
{
public:
  hier_simple_bus_target(sc_module_name n = "hier_simple_bus_target") : hier_simple_bus_target_imp<traits, tag, traits::io_config>(n) {}

  static const unsigned data_bytes = traits::tlm_traits::data_bytes;
  static const unsigned default_size = traits::tlm_traits::default_size;
};


}; // namespace simple_bus
}; // namespace cynw




#endif
