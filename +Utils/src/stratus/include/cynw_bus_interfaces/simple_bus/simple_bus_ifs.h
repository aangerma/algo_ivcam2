
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

#include "simple_bus.h"

#if defined STRATUS
#pragma hls_ip_def
#endif

namespace cynw {
namespace simple_bus {


template <int N>
class tag{};



template <int N, class T>
class bus_fw_nb_put_get_if : public sc_interface
{
public:
  typedef typename T::awchan_t awchan_t;
  typedef typename T::archan_t archan_t;
  typedef typename T::wchan_t wchan_t;
  typedef typename T::rchan_t rchan_t;
  typedef typename T::bchan_t   bchan_t;

  virtual bool nb_put_awchan(const awchan_t& awchan, tag<N>* t = 0) = 0;
  virtual bool nb_can_put_awchan(tag<N>* t = 0) const = 0;
  virtual void reset_nb_put_awchan(tag<N>* t = 0) = 0;
  virtual void refresh_put_awchan(tag<N>* t = 0) {}
  virtual const sc_event &ok_to_put_awchan(tag<N>* t = 0) const { static sc_event _e; return _e; }

  virtual bool nb_put_archan(const archan_t& archan, tag<N>* t = 0) = 0;
  virtual bool nb_can_put_archan(tag<N>* t = 0) const = 0;
  virtual void reset_nb_put_archan(tag<N>* t = 0) = 0;
  virtual void refresh_put_archan(tag<N>* t = 0) {}
  virtual const sc_event &ok_to_put_archan(tag<N>* t = 0) const { static sc_event _e; return _e; }

  virtual bool nb_put_wchan(const wchan_t& wchan, tag<N>* t = 0) = 0;
  virtual bool nb_can_put_wchan(tag<N>* t = 0) const = 0;
  virtual void reset_nb_put_wchan(tag<N>* t = 0) = 0;
  virtual void refresh_put_wchan(tag<N>* t = 0) {}
  virtual const sc_event &ok_to_put_wchan(tag<N>* t = 0) const { static sc_event _e; return _e; }

  virtual bool nb_get_rchan(rchan_t& rchan, tag<N>* t = 0) = 0;
  virtual bool nb_can_get_rchan(tag<N>* t = 0) const = 0;
  virtual void reset_nb_get_rchan(tag<N>* t = 0) = 0;
  virtual void refresh_get_rchan(tag<N>* t = 0) {}
  virtual bool nb_can_peek_rchan(tag<N>* t = 0) const { return false; }
  virtual bool nb_peek_rchan(rchan_t& rchan, tag<N>* t = 0) const { return false; }
  virtual const sc_event &ok_to_get_rchan(tag<N>* t = 0) const { static sc_event _e; return _e; }

  virtual bool nb_get_bchan(bchan_t& bchan, tag<N>* t = 0) = 0;
  virtual bool nb_can_get_bchan(tag<N>* t = 0) const = 0;
  virtual void reset_nb_get_bchan(tag<N>* t = 0) = 0;
  virtual void refresh_get_bchan(tag<N>* t = 0) {}
  virtual bool nb_can_peek_bchan(tag<N>* t = 0) const { return false; }
  virtual bool nb_peek_bchan(bchan_t& bchan, tag<N>* t = 0) const { return false; }
  virtual const sc_event &ok_to_get_bchan(tag<N>* t = 0) const { static sc_event _e; return _e; }

};


// bus_nb_put_get target socket class

template <int N, class T>
class bus_nb_put_get_target_socket : public sc_module ,
  public cynw_tlm::tlm_nonblocking_put_if<typename T::awchan_t>,
  public cynw_tlm::tlm_nonblocking_put_if<typename T::archan_t>,
  public cynw_tlm::tlm_nonblocking_put_if<typename T::wchan_t>,
  public cynw_tlm::tlm_nonblocking_get_peek_if<typename T::rchan_t>,
  public cynw_tlm::tlm_nonblocking_get_peek_if<typename T::bchan_t>
{
public:
  typedef typename T::addr_t    addr_t;
  typedef typename T::data_t    data_t;
  typedef typename T::awchan_t   awchan_t;
  typedef typename T::archan_t   archan_t;
  typedef typename T::wchan_t   wchan_t;
  typedef typename T::rchan_t   rchan_t;
  typedef typename T::bchan_t     bchan_t;

  bus_nb_put_get_target_socket(sc_module_name name) : sc_module(name)
  {
    awchan(*this);
    archan(*this);
    wchan(*this);
    rchan(*this);
    bchan(*this);
  }

  sc_port<bus_fw_nb_put_get_if<N, T> > target_port;

  sc_export<cynw_tlm::tlm_nonblocking_put_if<awchan_t> >   awchan;
  sc_export<cynw_tlm::tlm_nonblocking_put_if<archan_t> >   archan;
  sc_export<cynw_tlm::tlm_nonblocking_put_if<wchan_t> >   wchan;
  sc_export<cynw_tlm::tlm_nonblocking_get_peek_if<rchan_t> >   rchan;
  sc_export<cynw_tlm::tlm_nonblocking_get_peek_if<bchan_t> >     bchan;

  void start_of_simulation()
  {
    // LOG("Construct Target Socket: addr_bytes: " << T::addr_bytes << " data_bytes: " << T::data_bytes);
  }

  virtual bool nb_put(const awchan_t& awchan)
  {
    return target_port->nb_put_awchan(awchan);
  }

  virtual bool nb_can_put(cynw_tlm::tlm_tag<awchan_t>* t) const
  {
    return target_port->nb_can_put_awchan();
  }

  virtual const sc_event &ok_to_put(cynw_tlm::tlm_tag<awchan_t>* t) const
  {
    return target_port->ok_to_put_awchan();
  }

  virtual void refresh_put(cynw_tlm::tlm_tag<awchan_t>* t)
  {
    target_port->refresh_put_awchan();
  }

  virtual void reset_put(cynw_tlm::tlm_tag<awchan_t>* t)
  {
    target_port->reset_nb_put_awchan();
  }

  virtual bool nb_put(const archan_t& archan)
  {
    return target_port->nb_put_archan(archan);
  }

  virtual bool nb_can_put(cynw_tlm::tlm_tag<archan_t>* t) const
  {
    return target_port->nb_can_put_archan();
  }

  virtual const sc_event &ok_to_put(cynw_tlm::tlm_tag<archan_t>* t) const
  {
    return target_port->ok_to_put_archan();
  }

  virtual void refresh_put(cynw_tlm::tlm_tag<archan_t>* t)
  {
    target_port->refresh_put_archan();
  }

  virtual void reset_put(cynw_tlm::tlm_tag<archan_t>* t)
  {
    target_port->reset_nb_put_archan();
  }

  virtual bool nb_put(const wchan_t& wchan)
  {
    return target_port->nb_put_wchan(wchan);
  }

  virtual bool nb_can_put(cynw_tlm::tlm_tag<wchan_t>* t) const
  {
    return target_port->nb_can_put_wchan();
  }

  virtual const sc_event &ok_to_put(cynw_tlm::tlm_tag<wchan_t>* t) const
  {
    return target_port->ok_to_put_wchan();
  }

  virtual void refresh_put(cynw_tlm::tlm_tag<wchan_t>* t)
  {
    target_port->refresh_put_wchan();
  }

  virtual void reset_put(cynw_tlm::tlm_tag<wchan_t>* t)
  {
    target_port->reset_nb_put_wchan();
  }

  virtual bool nb_get(rchan_t& rchan)
  {
    return target_port->nb_get_rchan(rchan);
  }

  virtual bool nb_can_get(cynw_tlm::tlm_tag<rchan_t>* t) const
  {
    return target_port->nb_can_get_rchan();
  }

  virtual const sc_event &ok_to_get(cynw_tlm::tlm_tag<rchan_t>* t) const
  {
    return target_port->ok_to_get_rchan();
  }

  virtual void reset_get(cynw_tlm::tlm_tag<rchan_t>* t)
  {
    target_port->reset_nb_get_rchan();
  }

  virtual void refresh_get(cynw_tlm::tlm_tag<rchan_t>* t)
  {
    target_port->refresh_get_rchan();
  }

  virtual bool nb_peek( rchan_t& rchan ) const
  {
    return target_port->nb_peek_rchan(rchan);
  }

  virtual bool nb_can_peek( cynw_tlm::tlm_tag<rchan_t>* t = 0 ) const
  {
    return target_port->nb_can_peek_rchan();
  }

  virtual const sc_event &ok_to_peek( cynw_tlm::tlm_tag<rchan_t> *t = 0 ) const
  {
    return target_port->ok_to_get_rchan();
  }

  virtual bool nb_get(bchan_t& bchan)
  {
    return target_port->nb_get_bchan(bchan);
  }

  virtual bool nb_can_get(cynw_tlm::tlm_tag<bchan_t>* t) const
  {
    return target_port->nb_can_get_bchan();
  }

  virtual const sc_event &ok_to_get(cynw_tlm::tlm_tag<bchan_t>* t) const
  {
    return target_port->ok_to_get_bchan();
  }

  virtual void reset_get(cynw_tlm::tlm_tag<bchan_t>* t)
  {
    target_port->reset_nb_get_bchan();
  }

  virtual void refresh_get(cynw_tlm::tlm_tag<bchan_t>* t)
  {
    target_port->refresh_get_bchan();
  }

  virtual bool nb_peek( bchan_t& bchan ) const
  {
    return target_port->nb_peek_bchan(bchan);
  }

  virtual bool nb_can_peek( cynw_tlm::tlm_tag<bchan_t>* t = 0 ) const
  {
    return target_port->nb_can_peek_bchan();
  }

  virtual const sc_event &ok_to_peek( cynw_tlm::tlm_tag<bchan_t> *t = 0 ) const
  {
    return target_port->ok_to_get_bchan();
  }

};


// bus_nb_put_get initiator socket class

template <int N, class T>
class bus_nb_put_get_initiator_socket 
  : public sc_module
  , public sc_interface	// This tells CtoS to collapse this module
{
public:
  typedef typename T::addr_t    addr_t;
  typedef typename T::data_t    data_t;
  typedef typename T::awchan_t   awchan_t;
  typedef typename T::archan_t   archan_t;
  typedef typename T::wchan_t   wchan_t;
  typedef typename T::rchan_t   rchan_t;
  typedef typename T::bchan_t     bchan_t;

  bus_nb_put_get_initiator_socket(sc_module_name name) : sc_module(name)
  {
  }

  void start_of_simulation()
  {
    // LOG("Construct Initiator Socket: addr_bytes: " << T::addr_bytes << " data_bytes: " << T::data_bytes);
  }


  sc_port<cynw_tlm::tlm_nonblocking_put_if<awchan_t> >   awchan;
  sc_port<cynw_tlm::tlm_nonblocking_put_if<archan_t> >   archan;
  sc_port<cynw_tlm::tlm_nonblocking_put_if<wchan_t> >   wchan;
  sc_port<cynw_tlm::tlm_nonblocking_get_peek_if<rchan_t> >   rchan;
  sc_port<cynw_tlm::tlm_nonblocking_get_peek_if<bchan_t> >     bchan;

   virtual void reset_read_chan() {
    archan->reset_put();
    rchan->reset_get();
   }

   virtual void reset_write_chan() {
      awchan->reset_put();
      wchan->reset_put();
      bchan->reset_get();
   }

   virtual void reset() 
   {
     reset_read_chan();
     reset_write_chan();
   }
};


// macro to bind an initiator to a target
// --  Needs to be a macro currently due to CtoS limitations ?
#define bind_nb_put_get_sockets(i, t) \
   i .awchan( t .awchan); \
   i .archan( t .archan); \
   i .wchan( t .wchan); \
   i .rchan( t .rchan); \
   i .bchan  ( t .bchan); 



template<class traits>
class bus_nb_put_get_channel : public sc_module {
public:
   bus_nb_put_get_target_socket<1, traits>  target1;

   bus_nb_put_get_channel(sc_module_name name) :
     sc_module(name)
     , target1("target1")
   {
   }
};

}; // namespace simple_bus
}; // namespace cynw




