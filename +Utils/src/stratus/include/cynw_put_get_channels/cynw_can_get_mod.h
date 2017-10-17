// *****************************************************************************
// *****************************************************************************
// cynw_can_get_mod.h
//
// This file contains the implementation of Can_get_mod module.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_CAN_GET_MOD_H
#define CYNW_CAN_GET_MOD_H


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw {

struct Can_get_mod 
    : sc_module
    , sc_interface 
{
    sc_in <bool>        valid;
    sc_in <bool>        ready;
    sc_out<bool>        can_get;

    SC_CTOR(Can_get_mod)
        : valid("valid")
        , ready("ready")
        , can_get("can_get")
    {
        SC_METHOD(process);
        sensitive << valid << ready;
    }

    void process() {
        can_get = (valid || !ready);
    }
};

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif

#endif

