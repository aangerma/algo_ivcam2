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


//
// To the LRM writer : these classes are purely artifacts of the implementation.
//

#ifndef CYNW_TLM_PUT_GET_IMP_HEADER
#define CYNW_TLM_PUT_GET_IMP_HEADER

#include "../cynw_tlm_interfaces/cynw_tlm_master_slave_ifs.h"


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw_tlm
{

template < typename REQ , typename RSP >
class tlm_master_imp :
	public sc_module,
	public virtual tlm_master_if< REQ , RSP >
{
  public:
    sc_port<tlm_fifo_put_if<REQ> > put_fifo;
    sc_port<tlm_fifo_get_if<RSP> > get_fifo;
    sc_export<tlm_master_if< REQ , RSP > > master_export;

    typedef REQ PUT_DATA;
    typedef RSP GET_DATA;

    tlm_master_imp(const sc_module_name &name) 
    :   sc_module(name),
	put_fifo("put_fifo"),
        get_fifo("get_fifo"),
	master_export("master_export")
    {
	master_export(*this);
    }

    void reset_master() { 
	put_fifo->reset_put();
	get_fifo->reset_get();
    }

    // put interface
  public:
    void reset_put(tlm_tag<PUT_DATA> *t = 0) { put_fifo->reset_put(); }
    void put( const PUT_DATA &t ) { put_fifo->put( t ); }

    bool nb_put( const PUT_DATA &t ) { return put_fifo->nb_put( t ); }
    bool nb_can_put( tlm_tag<PUT_DATA> *t = 0 ) const {
	return put_fifo->nb_can_put( t );
    }

  private:
    const sc_event &ok_to_put( tlm_tag<PUT_DATA> *t = 0 ) const {
	return not_supported();
    }

    // get interface
  public:
    void reset_get(tlm_tag<GET_DATA> *t = 0) { get_fifo->reset_get(); }
    GET_DATA get( tlm_tag<GET_DATA> *t = 0 ) { return get_fifo->get(); }

    bool nb_get( GET_DATA &t ) { return get_fifo->nb_get( t ); }
  
    bool nb_can_get( tlm_tag<GET_DATA> *t = 0 ) const {
	return get_fifo->nb_can_get( t );
    }

  private:
    virtual const sc_event &ok_to_get( tlm_tag<GET_DATA> *t = 0 ) const {
	return not_supported();
    }

    // peek interface
  public:
    GET_DATA peek( tlm_tag<GET_DATA> *t = 0 ) const { return get_fifo->peek(); }

    bool nb_peek( GET_DATA &t ) const { return get_fifo->nb_peek( t); }
  
    bool nb_can_peek( tlm_tag<GET_DATA> *t = 0 ) const {
	return get_fifo->nb_can_peek( t );
    }

  private:
    virtual const sc_event &ok_to_peek( tlm_tag<GET_DATA> *t = 0 ) const {
	return not_supported();
    }

    sc_event &not_supported() const {return *(new sc_event);}
};

template < typename REQ , typename RSP >
class tlm_slave_imp :
    public sc_module,
    public virtual tlm_slave_if< REQ , RSP >
{
  public:
    sc_port<tlm_fifo_put_if<RSP> > put_fifo;
    sc_port<tlm_fifo_get_if<REQ> > get_fifo;
    sc_export<tlm_slave_if< REQ , RSP > > slave_export;

    tlm_slave_imp(const sc_module_name &name) 
    :    sc_module(name),
	put_fifo("put_fifo"),
        get_fifo("get_fifo"),
	slave_export("slave_export")
    {
	slave_export(*this);
    }

    void reset_slave() { 
	put_fifo->reset_put();
	get_fifo->reset_get();
    }


    typedef RSP PUT_DATA;
    typedef REQ GET_DATA;

    // put interface
  public:
    void reset_put(tlm_tag<PUT_DATA> *t = 0) { put_fifo->reset_put(); }
    void put( const PUT_DATA &t ) { put_fifo->put( t ); }

    bool nb_put( const PUT_DATA &t ) { return put_fifo->nb_put( t ); }
    bool nb_can_put( tlm_tag<PUT_DATA> *t = 0 ) const {
	return put_fifo->nb_can_put( t );
    }

  private:
    const sc_event &ok_to_put( tlm_tag<PUT_DATA> *t = 0 ) const {
	return not_supported();
    }

    // get interface
  public:
    void reset_get(tlm_tag<GET_DATA> *t = 0) { get_fifo->reset_get(); }
    GET_DATA get( tlm_tag<GET_DATA> *t = 0 ) { return get_fifo->get(); }

    bool nb_get( GET_DATA &t ) { return get_fifo->nb_get( t ); }
  
    bool nb_can_get( tlm_tag<GET_DATA> *t = 0 ) const {
	return get_fifo->nb_can_get( t );
    }

  private:
    virtual const sc_event &ok_to_get( tlm_tag<GET_DATA> *t = 0 ) const {
	return not_supported();
    }

    // peek interface
  public:
    GET_DATA peek( tlm_tag<GET_DATA> *t = 0 ) const { return get_fifo->peek(); }

    bool nb_peek( GET_DATA &t ) const { return false/*get_fifo->nb_peek( t )*/; }
  
    bool nb_can_peek( tlm_tag<GET_DATA> *t = 0 ) const {
	return get_fifo->nb_can_peek( t );
    }

  private:
    virtual const sc_event &ok_to_peek( tlm_tag<GET_DATA> *t = 0 ) const {
	return not_supported();
    }

    sc_event &not_supported() const {return *(new sc_event);}
};

}; // namespace cynw_tlm
#endif
