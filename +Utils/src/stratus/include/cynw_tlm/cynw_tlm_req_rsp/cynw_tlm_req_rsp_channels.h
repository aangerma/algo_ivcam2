/*****************************************************************************

  The following code is derived, directly or indirectly, from the SystemC
  source code Copyright (c) 1996-2004 by all Contributors.
  All Rights reserved.

  The contents of this file are subject to the restrictions and limitations
  set forth in the SystemC Open Source License Version 2.4 (the "License");
  You may not use this file except in compliance with such restrictions and
  limitations. You may obtain instructions on how to receive a copy of the
  License at http://www.systemc.org/. Software distributed by Contributors
  under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
  ANY KIND, either express or implied. See the License for the specific
  language governing rights and limitations under the License.

 *****************************************************************************/


#ifndef CYNW_TLM_REQ_RSP_CHANNELS
#define CYNW_TLM_REQ_RSP_CHANNELS

#include "../cynw_tlm_adapters/cynw_tlm_adapters.h"
#include "../cynw_tlm_fifo/cynw_tlm_fifo.h"
#include "../cynw_tlm_req_rsp/cynw_tlm_put_get_imp.h"


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw_tlm
{

template < typename REQ , typename RSP, int REQ_SIZE, int RSP_SIZE >
class tlm_req_rsp_channel : public sc_module
{
public:
  // uni-directional slave interface

  sc_export< tlm_fifo_get_if< REQ > > get_request_export;
  sc_export< tlm_fifo_put_if< RSP > > put_response_export;

  // uni-directional master interface

  sc_export< tlm_fifo_put_if< REQ > > put_request_export;
  sc_export< tlm_fifo_get_if< RSP > > get_response_export;

  // master / slave interfaces

  sc_export< tlm_master_if< REQ , RSP > > master_export;
  sc_export< tlm_slave_if< REQ , RSP > > slave_export;

  tlm_req_rsp_channel( sc_module_name module_name ) :
    sc_module( module_name  ) ,
    master("master") , 
    slave("slave") ,
    request_fifo("request_fifo") ,
    response_fifo("response_fifo") {

      master.put_fifo(request_fifo);
      master.get_fifo(response_fifo);

      slave.put_fifo(response_fifo);
      slave.get_fifo(request_fifo);
      

      put_request_export( request_fifo );
      get_request_export( request_fifo );
    
      put_response_export( response_fifo );
      get_response_export( response_fifo );

      master_export( master );
      slave_export( slave );
    
  }

protected:

  tlm_master_imp< REQ , RSP > master;
  tlm_slave_imp< REQ , RSP > slave;

  tlm_fifo<REQ, REQ_SIZE> request_fifo;
  tlm_fifo<RSP, RSP_SIZE> response_fifo;
};

template < typename REQ , typename RSP >
class tlm_transport_channel : public sc_module
{
public:

  // master transport interface

  sc_export< tlm_transport_if< REQ , RSP > > target_export;

  // slave interfaces

  sc_export< tlm_fifo_get_if< REQ > > get_request_export;
  sc_export< tlm_fifo_put_if< RSP > > put_response_export;

  sc_export< tlm_slave_if< REQ , RSP > > slave_export;

  tlm_transport_channel() :
    sc_module( sc_module_name( sc_gen_unique_name("transport_channel" ) ) ) ,
    target_export("target_export") ,
    req_rsp( "req_rsp" , 1 , 1 ) ,
    t2m("ts2m")
  {
    this->do_binding();
  }

  tlm_transport_channel( sc_module_name nm ) :
    sc_module( nm ) ,
    target_export("target_export") ,
    req_rsp( "req_rsp") ,
    t2m("tsm" )
  {
    target_export( t2m.target_export );

    t2m.master_port( req_rsp.master_export );

    get_request_export( req_rsp.get_request_export );
    put_response_export( req_rsp.put_response_export );
    slave_export( req_rsp.slave_export );
  }

private:

  tlm_req_rsp_channel< REQ , RSP, 1, 1 > req_rsp;
  tlm_transport_to_master< REQ , RSP > t2m;

};

}; // namespace cynw_tlm
#endif
