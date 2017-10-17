// *****************************************************************************
// *****************************************************************************
// cynw_can_put_mod.h
//
// This file contains the implementation of Can_put_mod module.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_CAN_PUT_MOD_H
#define CYNW_CAN_PUT_MOD_H


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw {

struct Can_put_mod 
    : sc_module
    , sc_interface 
{
    sc_in <bool>        valid;
    sc_in <bool>        ready;
    sc_out<bool>        can_put;

    SC_CTOR(Can_put_mod)
        : valid("valid")
	, ready("ready")
	, can_put("can_put")
    {
        SC_METHOD(process);
        sensitive << valid << ready;
    }

    void process() {
        can_put = !(valid && !ready);
    }
};

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif

#endif

