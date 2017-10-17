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

namespace cynw {
namespace axi3 {


////////////////////////
// AXI3 protocol types:


// AXI response status
enum axi_response_status { 
  AXI_OK_RESPONSE     = 0,
  AXI_EXOKAY_RESPONSE = 1, 
  AXI_SLVERR_RESPONSE = 2,
  AXI_DECERR_RESPONSE = 3
};

// AXI burst address modes
enum axi_burst_mode {
  AXI_FIXED_ADDR_BURST = 0,
  AXI_INCR_ADDR_BURST  = 1, 
  AXI_WRAP_ADDR_BURST  = 2
};



template <typename BASE>
struct axi3_width_traits : public BASE   // this inheritance is required due to ctos limitations with multiple inheritance
{
  static const int LEN_W    = 4;
  static const int BURST_W  = 2;
  static const int BRESP_W  = 2;
  static const int LOCK_W   = 2;
  static const int CACHE_W  = 4;
  static const int PROT_W   = 3;
  static const int RID_W     = BASE::ID_W ; // ID_W obtained from base traits class simple_bus_traits_base
  static const int WID_W     = BASE::ID_W ; // ID_W obtained from base traits class simple_bus_traits_base
  // static const int SIZE_W   = 3; // this is obtained from base traits class simple_bus_traits_base
};

template <typename BASE_TRAITS>
struct axi3_types_traits : public BASE_TRAITS
{
  static const int addr_bytes = BASE_TRAITS::addr_bytes;
  static const int data_bytes = BASE_TRAITS::data_bytes;
  static const int ADDR_W   = addr_bytes * 8;
  static const int DATA_W   = data_bytes * 8;
  static const int DATA_W_LOG2 = BASE_TRAITS::default_size;

  typedef typename BASE_TRAITS::data_t axi3_data_t; 
  typedef typename BASE_TRAITS::addr_t axi3_addr_t; 
  typedef sc_uint<data_bytes>      axi3_strb_t; 

  typedef sc_uint<BASE_TRAITS::RID_W>		axi3_rid_t;
  typedef sc_uint<BASE_TRAITS::WID_W>		axi3_wid_t;
  typedef sc_uint<BASE_TRAITS::LEN_W>    	axi3_len_t;  // number of beats MINUS one as per AXI3 protocol
  typedef sc_uint<BASE_TRAITS::BURST_W>    	axi3_burst_t;
  typedef sc_uint<BASE_TRAITS::SIZE_W>    	axi3_size_t; // # of bytes to be read/written as (1 << N), i.e. 0 -> 1, 2 -> 4, etc.
  typedef sc_uint<BASE_TRAITS::BRESP_W>    	axi3_bresp_t;
  typedef sc_uint<BASE_TRAITS::LOCK_W>    	axi3_lock_t;
  typedef sc_uint<BASE_TRAITS::CACHE_W>    	axi3_cache_t;
  typedef sc_uint<BASE_TRAITS::PROT_W>    	axi3_prot_t;
  typedef sc_uint<BASE_TRAITS::LEN_W + 1>	axi3_max_transfer_t;  // data type capable of holding max transfers
};



// write request type
template <typename T >
struct axi3_awchan_t : public T
{
    typename T::axi3_wid_t              tid;
    typename T::axi3_addr_t		addr;
    typename T::axi3_len_t              len;
    typename T::axi3_burst_t            burst;
    typename T::axi3_size_t             size;
    typename T::axi3_lock_t             lock;
    typename T::axi3_cache_t            cache;
    typename T::axi3_prot_t             prot;

    axi3_awchan_t() : tid(0), addr(0), len(0), burst(0), size(T::DATA_W_LOG2), lock(0), cache(0), prot(0) {}

    bool operator==(const axi3_awchan_t<T>& r) const
    {
      return ((tid == r.tid) && (addr == r.addr) && (len == r.len) && (size == r.size) && (burst == r.burst) 
            && (lock == r.lock) && (cache == r.cache) && (prot == r.prot));
    }
};

template <typename T>
static std::ostream& operator<<(std::ostream& s, const axi3_awchan_t<T>& r) { s<<r.addr; return s;}
template <typename T>
static void sc_trace(sc_trace_file* f, const axi3_awchan_t<T>& r, const std::string& s) {}

// read request type

template <typename T>
struct axi3_archan_t
{
    typename T::axi3_rid_t              tid;
    typename T::axi3_addr_t 		addr;
    typename T::axi3_len_t              len;
    typename T::axi3_burst_t            burst;
    typename T::axi3_size_t             size;
    typename T::axi3_lock_t             lock;
    typename T::axi3_cache_t            cache;
    typename T::axi3_prot_t             prot;

    axi3_archan_t() : tid(0), addr(0), len(0), burst(0), size(T::DATA_W_LOG2), lock(0), cache(0), prot(0) {}

    bool operator==(const axi3_archan_t<T>& r) const
    {
      return ((tid == r.tid) && (addr == r.addr) && (len == r.len) && (burst == r.burst) && (size == r.size)
            && (lock == r.lock) && (cache == r.cache) && (prot == r.prot));
    }
};

template <typename T>
static std::ostream& operator<<(std::ostream& s, const axi3_archan_t<T>& r) { s<<r.addr; return s;}
template <typename T>
static void sc_trace(sc_trace_file* f, const axi3_archan_t<T>& r, const std::string& s) {}

// write data type

template <typename T>
struct axi3_wchan_t
{
    typename T::axi3_wid_t	tid;
    typename T::axi3_data_t	data;
    typename T::axi3_strb_t	strb;
    bool			last; 

    axi3_wchan_t() : tid(0), data(0), strb(~0), last(false) {}

    bool operator==(const axi3_wchan_t<T>& r) const
    {
      return ((tid == r.tid) && (data == r.data) && (strb == r.strb) && (last == r.last));
    }
};

template <typename T>
static std::ostream& operator<<(std::ostream& s, const axi3_wchan_t<T>& r) { s<<r.data; return s;}
template <typename T>
static void sc_trace(sc_trace_file* f, const axi3_wchan_t<T>& r, const std::string& s) {}

// read data type

template <typename T>
struct axi3_rchan_t
{
    typename T::axi3_rid_t              tid;
    typename T::axi3_data_t 		data;
    bool                    		last;
    typename T::axi3_bresp_t            resp;    

    axi3_rchan_t() : tid(0), data(0), last(false), resp(AXI_OK_RESPONSE) {}

    bool operator==(const axi3_rchan_t<T>& r) const
    {
      return ((tid == r.tid) && (data == r.data) && (last == r.last) && (resp == r.resp));
    }
};

template <typename T>
static std::ostream& operator<<(std::ostream& s, const axi3_rchan_t<T>& r) { s<<r.data; return s;}
template <typename T>
static void sc_trace(sc_trace_file* f, const axi3_rchan_t<T>& r, const std::string& s) {}


// response data type

template <typename T>
struct axi3_bchan_t
{
  typename T::axi3_wid_t    tid;
  typename T::axi3_bresp_t  resp;

  axi3_bchan_t() : tid(0), resp(AXI_OK_RESPONSE) {}

  bool operator==(const axi3_bchan_t<T>& r) const
  {
    return ((tid == r.tid) && (resp == r.resp));
  }
};

template <typename T>
static std::ostream& operator<<(std::ostream& s, const axi3_bchan_t<T>& r) { s<<r.resp; return s;}
template <typename T>
static void sc_trace(sc_trace_file* f, const axi3_bchan_t<T>& r, const std::string& s) {}

// enum axi3_rw_mode { READ_WRITE=0, READ_ONLY=1, WRITE_ONLY=2};  // ctos 12.2 doesn't support enums like this yet..

typedef unsigned axi3_rw_mode;
static const unsigned READ_WRITE = 0;
static const unsigned READ_ONLY = 1;
static const unsigned WRITE_ONLY = 2;

typedef bool axi3_xtor_mode;
static const axi3_xtor_mode XTOR_DEF = true;

template <typename BASE_TRAITS>
struct axi3_traits : public BASE_TRAITS
{
  typedef BASE_TRAITS base_traits;

  typedef typename BASE_TRAITS::axi3_addr_t  addr_t;
  typedef typename BASE_TRAITS::axi3_strb_t  strb_t;
  typedef typename BASE_TRAITS::axi3_data_t  data_t;
  typedef typename BASE_TRAITS::axi3_wid_t   wid_t;
  typedef typename BASE_TRAITS::axi3_rid_t   rid_t;
  typedef axi3_awchan_t<BASE_TRAITS>         awchan_t;
  typedef axi3_archan_t<BASE_TRAITS>         archan_t;
  typedef axi3_wchan_t<BASE_TRAITS>          wchan_t;
  typedef axi3_rchan_t<BASE_TRAITS>          rchan_t;
  typedef axi3_bchan_t<BASE_TRAITS>          bchan_t;

  static const unsigned max_transfers = 16;  // axi3 max transfers is 16 per burst
  static const unsigned segment_boundary = 0x1000; // axi3 bursts are segmented on 4k boundary
  static const unsigned segment_bits = 12; // axi3 4k = 2^12
  static const axi3_rw_mode rw_mode = axi3::READ_WRITE;  // indicates if socket is rw, read_only, write_only
  static const axi3_xtor_mode xtor_mode = XTOR_DEF;
};

template <typename AXI3_TRAITS>
struct axi3_ext_len_traits : public AXI3_TRAITS
{
  typedef AXI3_TRAITS super;
  typedef typename AXI3_TRAITS::base_traits BASE_TRAITS;

  struct awchan_t : public axi3_awchan_t<BASE_TRAITS>
  {
    typename BASE_TRAITS::axi3_addr_t ext_len;  // Number of transfers in BEATS, not bytes!, 0 means 1 beat, 1 means 2 beats..

    awchan_t() : ext_len(0) {}

    bool operator==(const awchan_t& r) const
    {
      return ((ext_len == r.ext_len) && axi3_awchan_t<BASE_TRAITS>::operator==(r));
    }
  };

  struct archan_t : public axi3_archan_t<BASE_TRAITS>
  {
    typename BASE_TRAITS::axi3_addr_t ext_len;  // Number of transfers in BEATS, not bytes!, 0 means 1 beat, 1 means 2 beats..

    archan_t() : ext_len(0) {}

    bool operator==(const archan_t& r) const
    {
      return ((ext_len == r.ext_len) && axi3_archan_t<BASE_TRAITS>::operator==(r));
    }
  };
};

template <typename T>
static std::ostream& operator<<(std::ostream& s, const typename axi3_ext_len_traits<T>::awchan_t& r) { s<<r.ext_len; return s;}
template <typename T>
static std::ostream& operator<<(std::ostream& s, const typename axi3_ext_len_traits<T>::archan_t& r) {  s<<r.ext_len; return s;}

}; // namespace axi3
}; // namespace cynw


