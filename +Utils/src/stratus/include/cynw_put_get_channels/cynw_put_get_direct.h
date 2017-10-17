// *****************************************************************************
// *****************************************************************************
// cynw_put_get_direct.h 
//
//  Usage : 
//    #include "cynw_put_get_channels/cynw_put_get_direct.h"
//    
//    put_get_direct<int,DEFAULT_TRAITS, b_get_initiator<int>, nb_put_initiator<int> > chan;
//    
//    , chan("chan")    
//
//    submod1.dout(chan.input);
//    submod2.din(chan.output);
//
//
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2014 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_PUT_GET_DIRECT_H
#define CYNW_PUT_GET_DIRECT_H

//#include "cynw_put_get_channels.h"


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw {

template
<
  typename T
, typename TRAITS   = DEFAULT_TRAITS
, typename out_type = put_initiator<T,TRAITS>
, typename in_type  = get_initiator<T,TRAITS>
>
struct put_get_direct
{

  typedef put_get_channel<T,TRAITS>           chan_type;

  out_type  output;
  in_type   input;
  chan_type chan;

  put_get_direct(sc_module_name n = sc_gen_unique_name("put_get_direct"))
  : output(HLS_CAT_NAMES(n,"output"))
  , input(HLS_CAT_NAMES(n,"input"))
  , chan(HLS_CAT_NAMES(n,"chan"))
  {
    output(chan);
    input(chan);
  };

  template<typename T0, typename T1>
  void clk_rst(T0& clkIn, T1& rstIn)
  {
    input.clk_rst(clkIn,rstIn);
    output.clk_rst(clkIn,rstIn);
  }
}; // put_get_direct

template
<
  typename T
, typename TRAITS   = DEFAULT_TRAITS
>
struct nb_put_get_direct: 
  public put_get_direct< T
                     , TRAITS
                     , nb_put_initiator<T,TRAITS>
                     , nb_get_initiator<T,TRAITS>
                   >
 
{
  nb_put_get_direct(sc_module_name n = sc_gen_unique_name("nb_put_get_direct")):
     put_get_direct<T , TRAITS , nb_put_initiator<T,TRAITS> , nb_get_initiator<T,TRAITS> > (n) 
  { }
}; // nb_put_get_direct

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif


#endif // CYNW_PUT_GET_DIRECT__H
