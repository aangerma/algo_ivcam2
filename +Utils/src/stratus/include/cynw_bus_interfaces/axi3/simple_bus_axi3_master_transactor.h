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

#include "axi3_master_transactor.h"
#include "axi3_master_segmenter.h"
#include "axi3_master_aligner.h"
#include "axi3_ports.h"

#if defined STRATUS
#pragma hls_ip_def
#endif

namespace cynw {
namespace axi3 {

using namespace simple_bus;


template <class top_traits, class SB_TRAITS, class AXI_EXT_LEN_TRAITS>
class simple_bus_axi_master_transactor
  : public sc_module
  , public axi3_initiator_ports<typename AXI_EXT_LEN_TRAITS::super>
{
public:

  typedef typename AXI_EXT_LEN_TRAITS::super AXI_TRAITS;

  bus_nb_put_get_target_socket<1, SB_TRAITS>   target1; 

  axi_master_segmenter<top_traits, AXI_EXT_LEN_TRAITS, top_traits::segmenter_enabled> segmenter;
  axi_master_aligner<SB_TRAITS, AXI_EXT_LEN_TRAITS> aligner;
  axi_master_transactor<top_traits, AXI_TRAITS> master_transactor;

  simple_bus_axi_master_transactor(sc_module_name name) :
    target1("target1"),
    segmenter("segmenter"),
    aligner("aligner"),
    master_transactor("master_transactor")
  {
    segmenter.clk(clk);
    segmenter.reset(reset);

    master_transactor.clk(clk);
    master_transactor.reset(reset);

    target1.target_port(aligner.target1.target_port);

    bind_nb_put_get_sockets(aligner.initiator1, segmenter.target1);

    bind_nb_put_get_sockets(segmenter.initiator1, master_transactor.target1);

    bind_submod(master_transactor);
  }

  sc_in_clk clk;
  sc_in< bool > reset;

};


}; // namespace axi3
}; // namespace cynw

