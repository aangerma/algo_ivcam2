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

#include "axi3_slave_transactor.h"
#include "axi3_slave_aligner.h"
#include "axi3_ports.h"

#if defined STRATUS
#pragma hls_ip_def
#endif

namespace cynw {
namespace axi3 {

using namespace simple_bus;

template <class top_traits, class SB_TRAITS, class AXI_TRAITS>
class simple_bus_axi_slave_transactor 
 : public sc_module
 , public axi3_target_ports<AXI_TRAITS>
{
public:
  bus_nb_put_get_initiator_socket<1, SB_TRAITS> initiator1; 

  axi_slave_aligner<SB_TRAITS, AXI_TRAITS> slave_aligner;
  axi_slave_transactor<top_traits, AXI_TRAITS> slave_transactor;

  simple_bus_axi_slave_transactor(sc_module_name name) : 
    initiator1("initiator1"),
    slave_aligner("slave_aligner"),
    slave_transactor("slave_transactor")
  {
    slave_transactor.clk(clk);
    slave_transactor.reset(reset);

    slave_aligner.initiator1.awchan(initiator1.awchan);
    slave_aligner.initiator1.wchan(initiator1.wchan);
    slave_aligner.initiator1.archan(initiator1.archan);
    slave_aligner.initiator1.rchan(initiator1.rchan);
    slave_aligner.initiator1.bchan(initiator1.bchan);

    bind_nb_put_get_sockets(slave_transactor.initiator1, slave_aligner.target1);

    bind_submod(slave_transactor);
  }

  sc_in_clk clk;
  sc_in< bool > reset;
};

}; // namespace axi3
}; // namespace cynw

