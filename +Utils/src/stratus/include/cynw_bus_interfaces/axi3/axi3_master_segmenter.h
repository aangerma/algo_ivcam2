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

template <class T, int SIZE>
class wrap_tlm_fifo_reg_1t : public cynw_tlm::tlm_fifo_reg_1t<T, SIZE>
{
public:
    explicit wrap_tlm_fifo_reg_1t() : cynw_tlm::tlm_fifo_reg_1t<T, SIZE>(sc_gen_unique_name("fifo")) {}
};



template <class top_traits, class AXI_EXT_LEN_TRAITS, bool segmenter_enabled>
class axi_master_segmenter : 
  public sc_module,
  public bus_fw_nb_put_get_if<1, AXI_EXT_LEN_TRAITS > 	
{
 public:
  sc_in_clk clk;
  sc_in<bool> reset;

  static const bool sig_level = true;

  typedef typename AXI_EXT_LEN_TRAITS::super AXI_TRAITS;

  typedef typename AXI_EXT_LEN_TRAITS::awchan_t awchan_t;
  typedef typename AXI_EXT_LEN_TRAITS::archan_t archan_t;
  typedef typename AXI_EXT_LEN_TRAITS::wchan_t wchan_t;
  typedef typename AXI_EXT_LEN_TRAITS::rchan_t rchan_t;
  typedef typename AXI_EXT_LEN_TRAITS::bchan_t bchan_t;

  bus_nb_put_get_target_socket<1, AXI_EXT_LEN_TRAITS> target1;
  bus_nb_put_get_initiator_socket<1, AXI_TRAITS>      initiator1;
  typedef typename bus_nb_put_get_initiator_socket<1, AXI_TRAITS >::data_t data_t;

  SC_HAS_PROCESS(axi_master_segmenter);

  axi_master_segmenter(sc_module_name name) :
      sc_module(name)
    , clk("clk")
    , reset("reset")
    , target1("target1")
    , initiator1("initiator1")
    , awchan_fifo("awchan_fifo")
    , awchan_fifo_put("awchan_fifo_put")
    , awchan_fifo_get("awchan_fifo_get")
    , bchan_fifo("bchan_fifo")
    , bchan_fifo_put("bchan_fifo_put")
    , bchan_fifo_get("bchan_fifo_get")
  {
    target1.target_port(*this);

    if ((AXI_TRAITS::rw_mode == axi3::READ_WRITE) || (AXI_TRAITS::rw_mode == axi3::WRITE_ONLY))
    {
      SC_THREAD_CLOCK_RESET_TRAITS(write_segmenter, clk, reset, top_traits::put_get_traits);
      SC_THREAD_CLOCK_RESET_TRAITS(response_combiner, clk, reset, top_traits::put_get_traits);
    }
    else
    {
      SC_THREAD_CLOCK_RESET_TRAITS(dummy_write_segmenter, clk, reset, top_traits::put_get_traits);
      SC_THREAD_CLOCK_RESET_TRAITS(dummy_response_combiner, clk, reset, top_traits::put_get_traits);
    }

    if ((AXI_TRAITS::rw_mode == axi3::READ_WRITE) || (AXI_TRAITS::rw_mode == axi3::READ_ONLY))
    {
      SC_THREAD_CLOCK_RESET_TRAITS(read_segmenter, clk, reset, top_traits::put_get_traits);
    }

    bchan_fifo_put.clk_rst(clk, reset);
    bchan_fifo_get.clk_rst(clk, reset);

    bchan_fifo_put(bchan_fifo);
    bchan_fifo_get(bchan_fifo);

    awchan_fifo_put.clk_rst(clk, reset);
    awchan_fifo_get.clk_rst(clk, reset);

    awchan_fifo_put(awchan_fifo);
    awchan_fifo_get(awchan_fifo);
  }


  // write segmenter:

  // incoming new awchan reqs are stored here
  put_get_channel<awchan_t, typename top_traits::put_get_traits> awchan_fifo;
  nb_put_initiator<awchan_t, typename top_traits::put_get_traits> awchan_fifo_put;
  nb_get_initiator<awchan_t, typename top_traits::put_get_traits> awchan_fifo_get;

  // A value of 1 in this fifo indicates it is the LAST write burst req of the overall segmented burst
  wrap_tlm_fifo_reg_1t<bool, 3> wlast_burst_fifo;

  // this fifo indicates if last bit should be set on corresponding wchan item
  wrap_tlm_fifo_reg_1t<bool, 8> wlast_bit_fifo;

  // every time a write response is sent up stream, an item is put in this fifo - the value is ignored
  wrap_tlm_fifo_reg_1t<bool, 4> response_sent_fifo;

  // The response combiner puts accumulated responses in this fifo and then the upstream model gets them via nb_get_bchan()
  put_get_channel<bchan_t, typename top_traits::put_get_traits> bchan_fifo;
  nb_put_initiator<bchan_t, typename top_traits::put_get_traits> bchan_fifo_put;
  nb_get_initiator<bchan_t, typename top_traits::put_get_traits> bchan_fifo_get;


  virtual bool nb_put_awchan(const awchan_t& awchan, tag<1>* t = 0)
  {
    if (!nb_can_put_awchan())
      return false;

    bool v = awchan_fifo_put.nb_put(awchan);
    sc_assert(v);
    return true;
  }

  virtual bool nb_can_put_awchan(tag<1>* t = 0) const { return awchan_fifo_put.nb_can_put(); }
  virtual void reset_nb_put_awchan(tag<1>* t = 0) { awchan_fifo_put.reset_put(); }

  virtual bool nb_put_wchan(const wchan_t& wchan, tag<1>* t = 0)
  {
    if (!nb_can_put_wchan())
      return false;

    // stuart - should enforce that wchan.tid matches awchan.tid here , but it is tricky since awchan and wchan
    // may not be fully in sync

    typename AXI_TRAITS::wchan_t tmp = wchan;

    bool last = true;
    bool v = wlast_bit_fifo.nb_get(last);
    sc_assert(v);
    tmp.last = last;
    bool w = initiator1.wchan->nb_put(tmp);
    sc_assert(w);
    return true;
  }

  virtual bool nb_can_put_wchan(tag<1>* t = 0) const
  {
    return wlast_bit_fifo.nb_can_get() && initiator1.wchan->nb_can_put();
  }

  virtual void reset_nb_put_wchan(tag<1>* t = 0)
  {
    wlast_bit_fifo.reset_get();
    initiator1.wchan->reset_put();
  }
  virtual bool nb_get_bchan(bchan_t& bchan, tag<1>* t = 0) { return bchan_fifo_get.nb_get(bchan); }
  virtual bool nb_can_get_bchan(tag<1>* t = 0) const { return bchan_fifo_get.nb_can_get(); }
  virtual void reset_nb_get_bchan(tag<1>* t = 0) {  bchan_fifo_get.reset_get(); }


  // read segmenter:

  hls_sig<bool, sig_level> read_slave_done_toggle;
  hls_sig<bool, sig_level> read_slave_start_toggle;
  hls_sig<archan_t, sig_level> ext_archan;

  virtual bool nb_put_archan(const archan_t& archan, tag<1>* t = 0)
  {
    if (!nb_can_put_archan()) 
      return false;

    ext_archan = archan;
    read_slave_start_toggle = !read_slave_start_toggle;
    return true;
  }

  virtual bool nb_can_put_archan(tag<1>* t = 0) const { return (read_slave_start_toggle == read_slave_done_toggle); }

  virtual void reset_nb_put_archan(tag<1>* t = 0) { read_slave_start_toggle = 0; ext_archan = archan_t(); }

  virtual bool nb_get_rchan(rchan_t& rchan, tag<1>* t = 0) { return initiator1.rchan->nb_get(rchan); }
  virtual bool nb_can_get_rchan(tag<1>* t = 0) const { return initiator1.rchan->nb_can_get(); }
  virtual void reset_nb_get_rchan(tag<1>* t = 0) { initiator1.rchan->reset_get(); } 


  void dummy_write_segmenter()
  {
   // reset state:
   awchan_fifo_get.reset_get();
   response_sent_fifo.reset_get();
   wlast_burst_fifo.reset_put();
   wlast_bit_fifo.reset_put();
   // initiator1.awchan->reset_put();

   while (1) wait();
  }

  void write_segmenter()
  {
   // reset state:
   awchan_fifo_get.reset_get();
   response_sent_fifo.reset_get();
   wlast_burst_fifo.reset_put();
   wlast_bit_fifo.reset_put();
   initiator1.awchan->reset_put();

   sc_uint<4> outstanding_responses = 0;

   bool last_w_tid_valid = false;
   typename AXI_TRAITS::axi3_wid_t last_w_tid = 0;

   while (1) 
   {
     awchan_t ext_awchan;
     const unsigned max_transfers = AXI_TRAITS::max_transfers;

     // stuart - this process always consumes minimum of 2 cycles for every aw item emitted, try to optimize to 1
     // for case where new upstream write address arrives every clock cycle

     do {
      wait();
     } while (!awchan_fifo_get.nb_get(ext_awchan));


     if (last_w_tid_valid && (last_w_tid != ext_awchan.tid) && (outstanding_responses > 0))
      do
      {
        // Flush all outstanding responses before we allow a TID switch
        wait();
        // LOG("segmenter: flushing all responses on TID switch");
        bool b;
        if (response_sent_fifo.nb_get(b))
          outstanding_responses -= 1;
      } while (outstanding_responses > 0);

     // opportunistically try to consume items from response_sent_fifo, without consuming any clock cycles..
     bool b;
     if (response_sent_fifo.nb_get(b))
        outstanding_responses -= 1;

     // don't let the response_sent fifo get full..
     if (outstanding_responses > 8)
     do
     {
        // LOG("segmenter: consuming responses since fifo is full");
        wait();
        bool t;
        if (response_sent_fifo.nb_get(t))
          outstanding_responses -= 1;
     } while (outstanding_responses > 8);

     outstanding_responses += 1;

     last_w_tid_valid = true;
     last_w_tid = ext_awchan.tid;

     typename AXI_TRAITS::axi3_addr_t total_remain = ext_awchan.ext_len + 1;
     typename AXI_TRAITS::axi3_addr_t next_addr = ext_awchan.addr;
     typename AXI_TRAITS::axi3_size_t size = ext_awchan.size;

     while (total_remain != 0)
     {
       typename AXI_TRAITS::axi3_max_transfer_t local_remain = (total_remain <= max_transfers) ? total_remain : max_transfers;

       if (ext_awchan.burst == AXI_INCR_ADDR_BURST)
       {
         // here we enforce AXI3 restriction that bursts cannot span 4k boundaries:

         sc_uint<AXI_TRAITS::segment_bits> loawchan = next_addr;
         sc_uint<AXI_TRAITS::segment_bits + 1> lowbits = loawchan + (local_remain << size);

         if ( (lowbits.to_uint()-1) & AXI_TRAITS::segment_boundary)
         {
           local_remain -= (lowbits.to_uint() & (AXI_TRAITS::segment_boundary - 1)) >> size;
         }
       }

       typename AXI_TRAITS::awchan_t awchan;
       awchan = ext_awchan;
       awchan.len = local_remain - 1;
       awchan.addr = next_addr;

       total_remain -= local_remain;

       if (ext_awchan.burst == AXI_INCR_ADDR_BURST)
         next_addr += local_remain << size;

       bool put_awchan = false;
       bool put_wlast_bit = false;
       bool put_last_burst_bit = false;
       bool last_burst = (total_remain == 0);

       do {
        if (!put_awchan) put_awchan = initiator1.awchan->nb_put(awchan);

        if (!put_wlast_bit) put_wlast_bit = wlast_bit_fifo.nb_put(local_remain == 1);

        if (!put_last_burst_bit) put_last_burst_bit = wlast_burst_fifo.nb_put(last_burst);

        wait();
       } while (!put_awchan || !put_wlast_bit || !put_last_burst_bit);

       --local_remain; // to account for put immediately above..

       bool put_done = false;

       for (; local_remain > 0; --local_remain)
         do {
          put_done = wlast_bit_fifo.nb_put(local_remain == 1);
          wait();
         } while (!put_done);

     }
   }
  }


 void dummy_response_combiner()
 {
    // reset state:
    // initiator1.bchan->reset_get();
    wlast_burst_fifo.reset_get();
    bchan_fifo_put.reset_put();
    response_sent_fifo.reset_put();
    wait();

    while (1) wait();
 }

 void response_combiner()
 {
    // reset state:
    initiator1.bchan->reset_get();
    wlast_burst_fifo.reset_get();
    bchan_fifo_put.reset_put();
    response_sent_fifo.reset_put();
    wait();

    typename AXI_TRAITS::bchan_t accum_bchan, put_bchan;
    typename AXI_TRAITS::bchan_t bchan;

    accum_bchan.resp = AXI_OK_RESPONSE;

    bool got_token = false;
    bool got_response = false;
    bool token = false;
    bool put_bchan_fifo_valid = false;
    bool put_response_sent_fifo_valid = false;

    // this is coded to enable thruput of one response on every clock cycle (arises in case where new write address is
    // issued on every clock cycle
    
    while (1)
    {
       wait();

       if (!put_bchan_fifo_valid && !put_response_sent_fifo_valid)
       {
        if (!got_response)
          got_response = initiator1.bchan->nb_get(bchan);
        if (!got_token)
          got_token = wlast_burst_fifo.nb_get(token);
       }

       // for response combination follow rules in AMBA AXI Protocol spec v 2.0 sec 14.4.1
       if (got_response)
       {
         accum_bchan.resp |= bchan.resp;
         accum_bchan.tid = bchan.tid;
       }

       if (got_response && got_token)
       {
         if (token == true)
         {
           put_bchan_fifo_valid = true;
           put_response_sent_fifo_valid = true;
           put_bchan = accum_bchan;
           accum_bchan.resp = AXI_OK_RESPONSE;
         }

         got_response = false;
         got_token = false;
       }

       if (put_bchan_fifo_valid)
         if (bchan_fifo_put.nb_put(put_bchan))
           put_bchan_fifo_valid = false;

       if (put_response_sent_fifo_valid)
         if (response_sent_fifo.nb_put(true))
           put_response_sent_fifo_valid = false;
    } 
  }

 void read_segmenter()
 {
    // reset state:
    initiator1.archan->reset_put();
    read_slave_done_toggle = 0;
    wait();

    while (1)
    {
     read_slave_start_toggle.wait_value_change();

     read_segmenter_func();

     read_slave_done_toggle = !read_slave_done_toggle;
    }
 }

 void read_segmenter_func()
 {
  const unsigned max_transfers = AXI_TRAITS::max_transfers;
  typename AXI_TRAITS::axi3_addr_t total_remain = ext_archan.read().ext_len + 1;
  typename AXI_TRAITS::axi3_addr_t next_addr = 0;

  typename AXI_TRAITS::archan_t archan;

  archan = ext_archan.read();

  next_addr = archan.addr;
  typename AXI_TRAITS::axi3_size_t size = archan.size;
  
  while (total_remain != 0)
  {
    typename AXI_TRAITS::axi3_max_transfer_t local_remain = (total_remain <= max_transfers ) ?  total_remain : max_transfers;

    if (archan.burst == AXI_INCR_ADDR_BURST)
    {
      // here we enforce AXI3 restriction that bursts cannot span 4k boundaries:
      sc_uint<AXI_TRAITS::segment_bits> loawchan = next_addr;
      sc_uint<AXI_TRAITS::segment_bits + 1> lowbits = loawchan + (local_remain << size);

      if ( (lowbits.to_uint()-1) & AXI_TRAITS::segment_boundary)
      {
        local_remain -= (lowbits.to_uint() & (AXI_TRAITS::segment_boundary - 1)) >> size;
      }
    }

    archan.addr = next_addr;
    archan.len = local_remain - 1;

    bool put_done = false;
    do {
       put_done = initiator1.archan->nb_put(archan);
       wait();
    } while (!put_done);

    if (archan.burst == AXI_INCR_ADDR_BURST)
      next_addr += local_remain << size;

    total_remain -= local_remain;
  }
 }
};

// partial template specialization to eliminate all segmentation functionality:

template <class top_traits, class AXI_EXT_LEN_TRAITS>
class axi_master_segmenter<top_traits, AXI_EXT_LEN_TRAITS, false> : 
  public sc_module,
  public bus_fw_nb_put_get_if<1, AXI_EXT_LEN_TRAITS > 	
{
 public:
  sc_in_clk clk;
  sc_in<bool> reset;


  // Note that no special handling is needed here for AXI_TRAITS::rw_mode since there are no processes
  // here. All unneeded functions will be optimized away by CtoS since they will never be called by the user's code.

  typedef typename AXI_EXT_LEN_TRAITS::super AXI_TRAITS;

  typedef typename AXI_EXT_LEN_TRAITS::awchan_t awchan_t;
  typedef typename AXI_EXT_LEN_TRAITS::archan_t archan_t;
  typedef typename AXI_EXT_LEN_TRAITS::wchan_t wchan_t;
  typedef typename AXI_EXT_LEN_TRAITS::rchan_t rchan_t;
  typedef typename AXI_EXT_LEN_TRAITS::bchan_t bchan_t;

  bus_nb_put_get_target_socket<1, AXI_EXT_LEN_TRAITS> target1;
  bus_nb_put_get_initiator_socket<1, AXI_TRAITS>      initiator1;
  typedef typename bus_nb_put_get_initiator_socket<1, AXI_TRAITS >::data_t data_t;

  SC_HAS_PROCESS(axi_master_segmenter);

  typename AXI_EXT_LEN_TRAITS::axi3_max_transfer_t wlen_cnt;

  axi_master_segmenter(sc_module_name name) :
      sc_module(name)
    , clk("clk")
    , reset("reset")
    , target1("target1")
    , initiator1("initiator1")
  {
    target1.target_port(*this);
  }


  virtual bool nb_put_awchan(const awchan_t& awchan, tag<1>* t = 0)
  {
     if (!nb_can_put_awchan()) return false;

     if ((awchan.ext_len + 1) > AXI_TRAITS::max_transfers)
       SC_REPORT_ERROR("/segmenter", "Error: AXI Segmenter is configured to be OFF but received write burst length greater than 16 transfers");

    if (awchan.burst == AXI_INCR_ADDR_BURST)
    {
         // here we enforce AXI3 restriction that bursts cannot span 4k boundaries:
         sc_uint<AXI_TRAITS::segment_bits> loawchan = awchan.addr;;
         sc_uint<AXI_TRAITS::segment_bits + 1> lowbits = loawchan + ((1 + awchan.ext_len) << awchan.size);

         if ( (lowbits.to_uint()-1) & AXI_TRAITS::segment_boundary)
         {
            SC_REPORT_ERROR("/segmenter", 
		"Error: AXI Segmenter is configured to be OFF but received write burst that spans 4k address boundary");
         }
    }

     awchan_t tmp = awchan;
     tmp.len = awchan.ext_len;

     wlen_cnt = tmp.len;

     bool b = initiator1.awchan->nb_put(tmp);
     sc_assert(b);
     return true;
  }

  virtual bool nb_can_put_awchan(tag<1>* t = 0) const { return (initiator1.awchan->nb_can_put()); }
  virtual void reset_nb_put_awchan(tag<1>* t = 0) { initiator1.awchan->reset_put(); }

  virtual bool nb_put_wchan(const wchan_t& wchan, tag<1>* t = 0)
  { 
    if (!nb_can_put_wchan()) return false;

    // stuart - should enforce tid here matches awchan.tid

    wchan_t tmp = wchan;
    if (wlen_cnt == 0)
      tmp.last = 1;

    --wlen_cnt;

    bool b = initiator1.wchan->nb_put(tmp);
    sc_assert(b);
    return true;
  }

  virtual bool nb_can_put_wchan(tag<1>* t = 0) const { return (initiator1.wchan->nb_can_put()); }
  virtual void reset_nb_put_wchan(tag<1>* t = 0) { initiator1.wchan->reset_put(); }

  virtual bool nb_get_bchan(bchan_t& bchan, tag<1>* t = 0) { return initiator1.bchan->nb_get(bchan); }
  virtual bool nb_can_get_bchan(tag<1>* t = 0) const  { return initiator1.bchan->nb_can_get(); }
  virtual void reset_nb_get_bchan(tag<1>* t = 0) { initiator1.bchan->reset_get(); }


  virtual bool nb_put_archan(const archan_t& archan, tag<1>* t = 0)
  { 
    if ((archan.ext_len + 1) > AXI_TRAITS::max_transfers)
       SC_REPORT_ERROR("/segmenter", 
		"Error: AXI Segmenter is configured to be OFF but received read burst length greater than 16 transfers");

    if (archan.burst == AXI_INCR_ADDR_BURST)
    {
         // here we enforce AXI3 restriction that bursts cannot span 4k boundaries:
         sc_uint<AXI_TRAITS::segment_bits> loawchan = archan.addr;;
         sc_uint<AXI_TRAITS::segment_bits + 1> lowbits = loawchan + ((1 + archan.ext_len) << archan.size);

         if ( (lowbits.to_uint()-1) & AXI_TRAITS::segment_boundary)
         {
	    SC_REPORT_ERROR("/segmenter", 
            	"Error: AXI Segmenter is configured to be OFF but received read burst that spans 4k address boundary");
         }
    }

    archan_t tmp = archan;
    tmp.len = archan.ext_len;

    return initiator1.archan->nb_put(tmp); 
  }

  virtual bool nb_can_put_archan(tag<1>* t = 0) const { return initiator1.archan->nb_can_put(); }
  virtual void reset_nb_put_archan(tag<1>* t = 0) { initiator1.archan->reset_put(); }

  virtual bool nb_get_rchan(rchan_t& rchan, tag<1>* t = 0) { return initiator1.rchan->nb_get(rchan); }
  virtual bool nb_can_get_rchan(tag<1>* t = 0) const { return initiator1.rchan->nb_can_get(); }
  virtual void reset_nb_get_rchan(tag<1>* t = 0) { initiator1.rchan->reset_get(); } 
};

}; // namespace axi3
}; // namespace cynw




