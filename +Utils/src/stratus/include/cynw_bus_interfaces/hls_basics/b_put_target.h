

#pragma once

#include "hls_basics.h"

namespace cynw {


// general template
template <typename T, typename TRAITS, bool LEVEL>
struct b_put_target_imp { };

// specialization for Level==TLM
template <typename T, typename TRAITS>
struct b_put_target_imp<T,TRAITS,0>
    : sc_module
    , sc_interface
{
    b_put_target_imp(sc_module_name n) : sc_module(n), CTOR_NM(target_port) {}

    template<typename CHAN> void                    operator()(CHAN& chan) { target_port(chan); }
    template<typename CHAN> void                    bind(CHAN& chan) { operator()(chan); }
    template<typename CLK, typename RST> void                    clk_rst(CLK&, RST&) {}

    sc_port<tlm_blocking_put_if<T> > target_port;
};


// specialization for Level==SIGNAL
template <typename T, typename TRAITS>
struct b_put_target_imp<T,TRAITS,1>
    : sc_module
    , sc_interface
{
    sc_in<bool> clk;
    sc_in<bool> reset;
    sc_in<bool> valid;
    sc_out<bool> ready;
    sc_in<T> data;

    SC_HAS_PROCESS(b_put_target_imp);

    b_put_target_imp(sc_module_name n) : 
	sc_module(n)
	, CTOR_NM(clk)
	, CTOR_NM(reset)
	, CTOR_NM(valid)
	, CTOR_NM(ready)
	, CTOR_NM(data)
	, CTOR_NM(target_port)
    {
      SC_THREAD_CLOCK_RESET_TRAITS(main, clk, reset, TRAITS);
    }

    template<typename CHAN> void                    operator()(CHAN& chan) { target_port(chan); }
    template<typename CHAN> void                    bind(CHAN& chan) { operator()(chan); }
    template<typename CLK, typename RST> void                    clk_rst(CLK& clk_, RST& rst) { clk(clk_); reset(rst); }

    sc_port<tlm_blocking_put_if<T> > target_port;

    void main() {
       T v;

       target_port->reset_put();
       wait();

       while (1)
       {
	  ready = true;
	  do {
           wait();
           v = data;
          } while (valid != true);
	  ready = false;
          target_port->put(v);
       }
    }
};

template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct b_put_target : b_put_target_imp<T, TRAITS, TRAITS::Level>
{
  b_put_target(sc_module_name n = "b_put_target") : b_put_target_imp<T,TRAITS,TRAITS::Level>(n) {}
};


// general template
template <typename T, typename TRAITS, bool level>
struct b_put_target_channel_imp : sc_module { };

// specialization for Level==TLM
template <typename T, typename TRAITS>
struct b_put_target_channel_imp<T,TRAITS,0> : public tlm_blocking_put_if<T>
{
    b_put_target_channel_imp(sc_module_name n) : CTOR_NM(target_port) { }

    template<typename TARG> void                    operator()(TARG& targ) { target_port(targ.target_port); }
  
    sc_port<tlm_blocking_put_if<T> > target_port;

    virtual void            put(const T& v) { target_port->put(v); }
    virtual void            reset_put(tlm_tag<T>*) { target_port->reset_put(); } 
};

// specialization for Level==SIGNAL
template <typename T, typename TRAITS>
struct b_put_target_channel_imp<T,TRAITS,1>
    : sc_module
    , sc_interface
{
    sc_signal<bool> ready;
    sc_signal<bool> valid;
    sc_signal<T>    data;

    SC_CTOR(b_put_target_channel_imp)
	: CTOR_NM(ready)
	, CTOR_NM(valid)
	, CTOR_NM(data)
    { }

    template<typename TARG> void operator()(TARG& targ)
    {
      targ.ready(ready);
      targ.data(data);
      targ.valid(valid);
    }
};

template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct b_put_target_channel : b_put_target_channel_imp<T, TRAITS, TRAITS::Level>
{
  b_put_target_channel(sc_module_name n = "b_put_target_channel") : b_put_target_channel_imp<T, TRAITS, TRAITS::Level>(n) {}
};



//// hier_put_target:

// general template
template<typename T, typename TRAITS, bool Level>
struct hier_put_target_imp
{};

// TLM level specialization
template<typename T, typename TRAITS>
struct hier_put_target_imp<T,TRAITS,0>
    : sc_interface
    , sc_module
{
    hier_put_target_imp(sc_module_name nm)
        : sc_module(nm)
        , CTOR_NM(target_port)
    {}

    template<typename TARG> void operator()(TARG& targ) { target_port(targ.target_port); }

    sc_port<tlm_blocking_put_if<T> > target_port;
};

// signal level specialization
template<typename T, typename TRAITS>
struct hier_put_target_imp<T,TRAITS,1>
    : sc_interface
    , sc_module
{   
    hier_put_target_imp(sc_module_name nm)
        : sc_module(nm)
        , CTOR_NM(valid)
        , CTOR_NM(ready)
        , CTOR_NM(data)
    {}

    template<typename TARG> void operator()(TARG& targ) { targ.valid(valid); targ.ready(ready); targ.data(data); }

    sc_in<bool>            valid;
    sc_out<bool>            ready;
    sc_in<T>              data;
};

template <typename T, typename TRAITS=DEFAULT_TRAITS>
struct hier_put_target : hier_put_target_imp<T,TRAITS,TRAITS::Level> {
    hier_put_target(sc_module_name n = "hier_put_target") : hier_put_target_imp<T,TRAITS,TRAITS::Level>(n) { }
};

}; // namespace cynw


