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

#if defined STRATUS
#pragma hls_ip_def
#endif

namespace cynw {

template <typename T>
class hls_sig_in_if : virtual public sc_interface
{
public:
  virtual const T read() const = 0;
  virtual void wait_value_change() = 0;  // making this const is problematic since sc_module::wait() is non-const
  virtual void wait_value_change_to(T v) = 0;  // making this const is problematic since sc_module::wait() is non-const
};

template <typename T>
class hls_sig_out_if : virtual public hls_sig_in_if<T>
{
public:
  virtual void write(const T& v) = 0;
};


// General template:
template <typename T, bool sig_level = true>
class hls_sig_in
{};

// TLM level specialization:

template <typename T>
class hls_sig_in<T, false> : public sc_port<hls_sig_in_if<T> >
{
public:
  typedef hls_sig_in<T, false> this_type;
  typedef sc_port<hls_sig_in_if<T> > base_type;
  typedef base_type in_port_type;
  typedef sc_port<hls_sig_out_if<T> > out_port_type;

// ctors, dtors:
  explicit hls_sig_in(const char* name_) : base_type(name_) {}
  virtual ~hls_sig_in() {}

// bind to in interface
  void bind(hls_sig_in_if<T>& interface_) { sc_port_base::bind(interface_); }
  void operator() (hls_sig_in_if<T>& interface_) { bind(interface_); }

// bind to parent in port
  void bind(in_port_type& parent_) { sc_port_base::bind(parent_); }
  void operator()(in_port_type& parent_) { bind(parent_); }

// bind to parent out port
  void bind(out_port_type& parent_) { sc_port_base::bind(parent_); }
  void operator()(out_port_type& parent_) { sc_port_base::bind(parent_); }

// interface access shortcut methods

  const T read() const { return (*this)->read(); }
  operator const T () const { return (*this)->read(); }

  void wait_value_change() { return (*this)->wait_value_change(); }
  void wait_value_change_to(T v) { return (*this)->wait_value_change_to(v); }

private:
  // disabled
  hls_sig_in(const this_type&);
  this_type& operator=(const this_type&);
};

// Signal level specialization:

template <typename T>
class hls_sig_in<T, true> : public sc_module, public hls_sig_in_if<T>
{
public:
  typedef hls_sig_in<T, true> this_type;
  sc_in<T> signal;
#if !defined(STRATUS) 
  sc_port<hls_sig_in_if<T> > port;  // This port is only used for execution of runtime checks in hls_sig
#endif

// ctors, dtors:
  explicit hls_sig_in(const sc_module_name &name_) : sc_module(name_), signal(name_) {}
  virtual ~hls_sig_in() {}

  // bind to channel or to parent hls_sig_in or parent hls_sig_out ports
  template <class CHAN> void operator() (CHAN& chan) {
    signal(chan . signal); 
#if !defined(STRATUS) 
     port(chan);
#endif
  }

// interface access shortcut methods

  const T read() const {
#if !defined(STRATUS) 
    (void) port->read();
#endif
    return signal.read(); 
  }

  operator const T () const { return (*this).read(); }

  void wait_value_change() 
  {
    HLS_DEFINE_PROTOCOL("value_change");
    T old_value = read();

    do {
      wait();
    } while (read() == old_value);
  }

  void wait_value_change_to(T v) 
  {
    HLS_DEFINE_PROTOCOL("value_change_to");
    while (!(read() == v))
      wait();
  }

private:
  // disabled
  hls_sig_in(const this_type&);
  this_type& operator=(const this_type&);
};

// General template:
template <typename T, bool sig_level = true>
class hls_sig_out
{};

// TLM specialization:
template <typename T>
class hls_sig_out<T, false> : public sc_port<hls_sig_out_if<T> >
{
public:
  typedef hls_sig_out<T> this_type;
  typedef sc_port<hls_sig_out_if<T> > base_type;
  typedef base_type out_port_type;
  typedef sc_port<hls_sig_in_if<T> > in_port_type;

// ctors, dtors:
  explicit hls_sig_out(const char* name_) : base_type(name_) {}
  virtual ~hls_sig_out() {}

// bind to out interface
  void bind(hls_sig_out_if<T>& interface_) { sc_port_base::bind(interface_); }
  void operator() (hls_sig_out_if<T>& interface_) { bind(interface_); }

// bind to parent out port
  void bind(out_port_type& parent_) { sc_port_base::bind(parent_); }
  void operator()(out_port_type& parent_) { bind(parent_); }

// interface access shortcut methods

  const T read() const { return (*this)->read(); }
  operator const T () const { return (*this)->read(); }

  void write(const T& v) { return (*this)->write(v); }

  const T& operator=(const T& v) { write(v); return v; }

private:
  // disabled
  hls_sig_out(const this_type&);
  this_type& operator=(const this_type&);
};


// signal level specialization:
template <typename T>
class hls_sig_out<T, true> : public sc_module, public hls_sig_out_if<T>
{
public:
  typedef hls_sig_out<T> this_type;
  sc_out<T> signal;
#if !defined(STRATUS) 
  sc_port<hls_sig_out_if<T> > port;  // This port is only used for execution of runtime checks in hls_sig
#endif

// ctors, dtors:
  explicit hls_sig_out(const sc_module_name &name_) : sc_module(name_) , signal(name_) {}
  virtual ~hls_sig_out() {}

  // bind to channel or to parent hls_sig_in or parent hls_sig_out ports
  template <class CHAN> void operator() (CHAN& chan) 
  {
     signal(chan . signal); 
#if !defined(STRATUS) 
     port(chan);
#endif
  }

// interface access shortcut methods

  const T read() const {
#if !defined(STRATUS) 
    (void) port->read();
#endif
    return signal.read(); 
  }

  operator const T () const { return read(); }

  void wait_value_change() 
  {
    HLS_DEFINE_PROTOCOL("value_change");
    T old_value = read();

    do {
      wait();
    } while (read() == old_value);
  }

  void wait_value_change_to(T v) 
  {
    HLS_DEFINE_PROTOCOL("value_change_to");
    while (!(read() == v))
      wait();
  }

  void write(const T& v) {
#if !defined(STRATUS) 
    port->write(v);
#endif
    signal.write(v); 
  }

  const T& operator=(const T& v) { write(v); return v;}

private:
  // disabled
  hls_sig_out(const this_type&);
  this_type& operator=(const this_type&);
};


// General template, never instantiated, defaults to signal level specialization:

template <typename T, bool sig_level = true>
class hls_sig
{};

// TLM level specialization:

template <typename T>
class hls_sig<T, false> : public hls_sig_out_if<T>, public sc_module
{
public:
  typedef hls_sig<T, false> this_type;

  explicit hls_sig(sc_module_name nm = sc_gen_unique_name("hls_sig")) : sc_module(nm) { } 

  const T read() const { return variable; }

  operator T() const { return read(); }

  void write(const T& v) 
  {
   variable = v; 
   signal.write(v);
  }

  const T& operator=(const T& v) { write(v); return v; }

  this_type& operator=(const this_type& t) { write(t.read()); return *this; }

  void wait_value_change() 
  {
    T old_value = read();

    do {
      wait(const_cast<sc_signal<T> &>(signal).value_changed_event());
    } while (read() == old_value);
  }

  void wait_value_change_to(T v) 
  {
    while (!(read() == v))
      wait(const_cast<sc_signal<T> &>(signal).value_changed_event());
  }

  T variable;
  sc_signal<T> signal;

};

// Signal level specialization:

template <typename T>
class hls_sig<T, true> : public hls_sig_out_if<T> // , public sc_module
{
public:
  typedef hls_sig<T, true> this_type;

  explicit hls_sig(const char* nm = sc_gen_unique_name("hls_sig")) : /* sc_module("mod"), */ signal(nm) { }

  operator T() const { return read(); }

  const T read() const 
  { 
    HLS_DEFINE_PROTOCOL("read");
#if !defined(STRATUS) 
    if (( !(signal.read() == variable)) && (writer_process == sc_get_current_process_handle()))
    {
      std::stringstream str;
      str << "For object: " << signal.name() << endl;
      str << "hls_sig written and read in same clock cycle but old value instead of new value will be read" << endl;
      str << "hls_sig signal value: " << signal.read() << " : variable value: " << variable << endl;
      SC_REPORT_ERROR("/hls_sig", str.str().c_str());
    }
#endif
    return signal.read(); 
  }

  void write(const T& v)
  {
    HLS_DEFINE_PROTOCOL("read");
    signal.write(v);
#if !defined(STRATUS) 
    variable = v;
    writer_process = sc_get_current_process_handle();
#endif
  }

  const T& operator=(const T& v) { write(v); return v; }

#if !defined(STRATUS) 
// Alas, there seems to be no way to get CtoS to handle this, and it is needed for "sig1 = sig2;" to synthesize...
// workaround is to use: "sig1 = sig2.read(); "
  this_type& operator=(const this_type& t) { write(t.read()); return *this; }
#endif

  void wait_value_change() 
  {
    HLS_DEFINE_PROTOCOL("value_change");
    T old_value = read();

    do {
	wait();
    } while (read() == old_value);
  }

  void wait_value_change_to(T v) 
  {
    HLS_DEFINE_PROTOCOL("value_change_to");
    while (!(read() == v))
      wait();
  }

  sc_signal<T> signal;
#if !defined(STRATUS) 
  T variable;
  sc_process_handle writer_process;
#endif

};


////////////////////////////////////////////
// These template functions below are for use in testbenches, not in HLS synthesizeable models.
// They mimic hls_sig APIs while working on normal sc_signals.

template <class traits, class T, class S> void hls_wait_value_changed_to(S& in_if, T val)
{
    while (in_if.read() != val)
    {
      if (traits::Level == true)
        wait();
      else
        wait(in_if.value_changed_event());
    }
}

template <class traits, class S> void hls_wait_value_changed(S& in_if)
{
    typename S::data_type val = in_if.read();

    while (in_if.read() == val)
    {
      if (traits::Level == true)
        wait();
      else
        wait(in_if.value_changed_event());
    }
}

}; // namespace cynw


