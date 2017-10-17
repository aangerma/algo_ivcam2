#ifndef CYNW_FLEX_CHANNELS_P2P_H
#define CYNW_FLEX_CHANNELS_P2P_H

#include <systemc.h>


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw {
template <typename T>
struct p2p_if {
	sc_signal<bool>  vld;
	sc_signal<bool>  busy;
	sc_signal<T >    data;
};

template <typename T>
struct flex_channels_if {
	sc_signal<bool>  valid;
	sc_signal<bool>  ready;
	sc_signal<T >    data;
};

template <typename T>
struct p2p_to_flex_channel: sc_module
{
	
	p2p_if<T >  		in;
	flex_channels_if<T > 	out;	

	void method_data() {
		out.data.write(in.data.read());
	}	
	void method_valid() {
		out.valid.write(in.vld.read());
	}
	void method_ready() {
		in.busy.write( !out.ready.read() );
	}
	
	SC_CTOR(p2p_to_flex_channel)
	{
		SC_METHOD(method_data);
		sensitive << in.data;
		SC_METHOD(method_valid);
		sensitive << in.vld;
		SC_METHOD(method_ready);
		sensitive << out.ready;			
	}
};

template <typename T>
struct flex_to_p2p_channel : sc_module
{

	flex_channels_if<T > 	in;
	p2p_if<T >  		out;

	void method_data() {
		out.data.write(in.data.read());
	}		
	void method_valid() {
		out.vld.write(in.valid.read());
	}
	void method_ready() {
		in.ready.write( !out.busy.read() );
	}
	
	SC_CTOR(flex_to_p2p_channel)
	{
		SC_METHOD(method_data);
		sensitive << in.data;
		SC_METHOD(method_valid);
		sensitive << in.valid;
		SC_METHOD(method_ready);
		sensitive <<out.busy;			
	}
};

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif

#endif
