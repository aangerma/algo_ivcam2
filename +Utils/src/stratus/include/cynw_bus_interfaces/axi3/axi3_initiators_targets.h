
#pragma once

#if defined STRATUS
#pragma hls_ip_def
#endif

namespace cynw {
namespace axi3 {



template <typename traits, unsigned tag, unsigned io_config>
struct axi3_initiator_imp
{
  // General form of template , never used
  typedef typename traits::TEMPLATE_INSTANTIATION_ERROR TEMPLATE_INSTANTIATION_ERROR;
};


template <typename traits, unsigned tag>
struct axi3_initiator_imp<traits, tag, IO_CONFIG_TLM1>
  : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>
  , sc_interface
{
  // specialization for TLM1 LEVEL

  axi3_initiator_imp(sc_module_name n) : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>(n) {}

  template <typename CHAN> void operator()(CHAN& chan) {
   bind_nb_put_get_sockets( (*this) , chan.target1);
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }
};

template <typename traits, unsigned tag=1>
struct axi3_initiator : public axi3_initiator_imp<traits, tag, traits::io_config>
{
public:
  axi3_initiator(sc_module_name n = "axi3_initiator") : axi3_initiator_imp<traits, tag, traits::io_config>(n) {}

  static const unsigned data_bytes = traits::tlm_traits::data_bytes;
  typedef traits TRAITS;
}; 



template <typename traits, unsigned tag, unsigned io_config>
struct axi3_target_imp
{
  // General form of template , never used
  typedef typename traits::TEMPLATE_INSTANTIATION_ERROR TEMPLATE_INSTANTIATION_ERROR;
};

template <typename traits, unsigned tag>
struct axi3_target_imp<traits, tag, IO_CONFIG_TLM1>
  : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>
{
  // specialization for TLM1 LEVEL

  axi3_target_imp(sc_module_name n) : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>(n) {}

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }
};

template <typename traits, unsigned tag=1>
struct axi3_target : public axi3_target_imp<traits, tag, traits::io_config>
{
public:
  axi3_target(sc_module_name n = "axi3_target") : axi3_target_imp<traits, tag, traits::io_config>(n) {}

  static const unsigned data_bytes = traits::tlm_traits::data_bytes;
  typedef traits TRAITS;
};


template <typename traits, unsigned io_config>
struct axi3_channel_imp
{
  // General form of template , never used
  typedef typename traits::TEMPLATE_INSTANTIATION_ERROR TEMPLATE_INSTANTIATION_ERROR;
};


template <typename traits>
struct axi3_channel_imp<traits, IO_CONFIG_TLM1> 
  : public bus_nb_put_get_channel<typename traits::tlm_traits>
{
  // specialization for TLM1 LEVEL

  axi3_channel_imp(sc_module_name n = "axi3_channel") : bus_nb_put_get_channel<typename traits::tlm_traits>(n) {}

  template <typename TARG> void operator()(TARG& targ) {
    (*this).target1.target_port(targ.target_port);
  }
};

template <typename traits>
struct axi3_channel : public axi3_channel_imp<traits, traits::io_config>
{
  axi3_channel(sc_module_name n = "axi3_channel") : axi3_channel_imp<traits, traits::io_config>(n) {}

  typedef traits TRAITS;
};


template <typename traits, unsigned tag>
struct axi3_initiator_imp<traits, tag, IO_CONFIG_AXI3_SIG>
  : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>
  , axi3_initiator_ports<typename traits::hw_bus_traits>
{
  // specialization for AXI3 SIGNAL

  axi3_initiator_imp(sc_module_name n) : 
      bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>(n)
    , xtor("xtor")
  {
    bind_submod(xtor);

    bind_nb_put_get_sockets((*this), xtor.target1);
  }

  axi3::axi_master_transactor<traits, typename traits::hw_bus_traits> xtor;

  template <typename CHAN> void operator()(CHAN& chan)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here

    axi3_initiator_ports<typename traits::hw_bus_traits>::bind_chan(chan);
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst)
  {
    xtor.clk(clk);
    xtor.reset(rst);
  }
};

template <typename traits, unsigned tag>
struct axi3_target_imp<traits, tag, IO_CONFIG_AXI3_SIG>
  : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>
  , axi3_target_ports<typename traits::hw_bus_traits>
{
  // specialization for AXI3 SIGNAL

  axi3_target_imp(sc_module_name n) : 
      bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>(n)
    , CTOR_NM(xtor)
  {
    bind_submod(xtor);

    bind_nb_put_get_sockets(xtor.initiator1, (*this));
  }

  axi3::axi_slave_transactor<traits, typename traits::hw_bus_traits> xtor;

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst)
  {
    xtor.clk(clk);
    xtor.reset(rst);
  }

  template <typename CHN> void operator()(CHN& chn)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here

    axi3_target_ports<typename traits::hw_bus_traits>::bind_chan(chn);
  }
};


template <typename traits>
struct axi3_channel_imp<traits, IO_CONFIG_AXI3_SIG>
  : public sc_module
  , public axi3_signals<typename traits::hw_bus_traits>
{
  // specialization for AXI3 SIGNAL

  axi3_channel_imp(sc_module_name n = "axi3_channel") : 
     sc_module(n)
   {}

  template <typename TARG> void operator()(TARG& targ)
  {
    bind_submod(targ);
  }
};



template <typename traits, unsigned tag, unsigned io_config>
struct hier_axi3_initiator_imp
{
  // General form of template , never used
  typedef typename traits::TEMPLATE_INSTANTIATION_ERROR TEMPLATE_INSTANTIATION_ERROR;
};

template <typename traits, unsigned tag>
struct hier_axi3_initiator_imp<traits, tag, IO_CONFIG_TLM1>
  : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>
  , sc_interface
{
  // specialization for TLM LEVEL

  hier_axi3_initiator_imp(sc_module_name n) : bus_nb_put_get_initiator_socket<tag, typename traits::tlm_traits>(n) {}

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
struct hier_axi3_initiator : public hier_axi3_initiator_imp<traits, tag, traits::io_config>
{
public:
  hier_axi3_initiator(sc_module_name n = "hier_axi3_initiator") : hier_axi3_initiator_imp<traits, tag, traits::io_config>(n) {}

  static const unsigned data_bytes = traits::tlm_traits::data_bytes;
  typedef traits TRAITS;
}; 



template <typename traits, unsigned tag, unsigned io_config>
struct hier_axi3_target_imp
{
  // General form of template , never used
  typedef typename traits::TEMPLATE_INSTANTIATION_ERROR TEMPLATE_INSTANTIATION_ERROR;
};

template <typename traits, unsigned tag>
struct hier_axi3_target_imp<traits, tag, IO_CONFIG_TLM1>
  : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>
{
  // specialization for TLM LEVEL

  hier_axi3_target_imp(sc_module_name n) : bus_nb_put_get_target_socket<tag, typename traits::tlm_traits>(n) {}

  template <typename TARG> void hier_bind(TARG& subtarg)
  {
    (*this).target_port(subtarg.target_port);
  }

  template <typename CLK, typename RST> void clk_rst(CLK& clk, RST& rst) { }
};

template <typename traits, unsigned tag=1>
struct hier_axi3_target : public hier_axi3_target_imp<traits, tag, traits::io_config>
{
public:
  hier_axi3_target(sc_module_name n = "hier_axi3_target") : hier_axi3_target_imp<traits, tag, traits::io_config>(n) {}

  static const unsigned data_bytes = traits::tlm_traits::data_bytes;
  typedef traits TRAITS;
};


template <typename traits, unsigned tag>
struct hier_axi3_initiator_imp<traits, tag, IO_CONFIG_AXI3_SIG>
  :
   CYNW_NO_MODULE_BASE
   axi3_initiator_ports<typename traits::hw_bus_traits>
{
  // specialization for AXI3 SIGNAL

  hier_axi3_initiator_imp(sc_module_name n) 
   CYNW_NO_MODULE_INIT
  { }

  template <typename CHAN> void operator()(CHAN& chan)
  {
    // this function is called by TB, which means that CtoS does not execute it during elab, which means
    // that only top level to channel bindings should be included here

    bind_chan(chan);
  }

  template <typename TARG> void hier_bind(TARG& targ)
  {
    bind_submod(targ);
  }
};


template <typename traits, unsigned tag>
struct hier_axi3_target_imp<traits, tag, IO_CONFIG_AXI3_SIG>
  :
    CYNW_NO_MODULE_BASE
    axi3_target_ports<typename traits::hw_bus_traits>
{
  // specialization for AXI3 SIGNAL

  hier_axi3_target_imp(sc_module_name n) 
    CYNW_NO_MODULE_INIT
  { }

  template <typename TARG> void hier_bind(TARG& targ)
  {
    bind_submod(targ);
  }
};


}; // namespace axi3
}; // namespace cynw




