// *****************************************************************************
// *****************************************************************************
// cynw_sync_snd.h
//
// This file contains definition of Sync_Snd module, responsible for setting
// valid signals.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_SYNC_SND_H
#define CYNW_SYNC_SND_H

# include "cynw_comm_util.h"


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw {

template<typename TRAITS>
struct Sync_Snd 
    : sc_module
    , sc_interface 
    , cynw_hier_bind_detector
{
    sc_in <bool>        clk;
    sc_in <bool>        rst;
    sc_out<bool>        valid;
    sc_in <bool>        ready;
    sc_in <bool>        set_valid_curr;

    sc_signal<bool>     set_valid_prev;
    sc_signal<bool>     reset_valid_prev;
    sc_signal<bool>     reset_valid_curr;
    sc_signal<bool>     valid_flop;

    SC_CTOR(Sync_Snd)
        : clk("clk")
        , rst("rst")
        , valid("valid")
        , ready("ready")
        , set_valid_curr("set_valid_curr")
        , set_valid_prev("set_valid_prev")
        , reset_valid_prev("reset_valid_prev")
        , reset_valid_curr("reset_valid_curr")
        , valid_flop("valid_flop")
    {
        SC_METHOD(back_method);
        if (TRAITS::ResetSync) {
            if (TRAITS::PosEdgeClk) {
                sensitive << clk.pos();
            } else {
                sensitive << clk.neg();
            }
        } else {
            if ( TRAITS::PosEdgeClk && TRAITS::ResetLevel) {
                sensitive << clk.pos() << rst.pos();
            } else if ( TRAITS::PosEdgeClk && !TRAITS::ResetLevel) {
                sensitive << clk.pos() << rst.neg();
            } else if ( !TRAITS::PosEdgeClk && TRAITS::ResetLevel) {
                sensitive << clk.neg() << rst.pos();
            } else if ( !TRAITS::PosEdgeClk && !TRAITS::ResetLevel) {
                sensitive << clk.neg() << rst.neg();
            }
        }
        dont_initialize();

        SC_METHOD(valid_arb);
        sensitive   << set_valid_curr << set_valid_prev
                    << reset_valid_curr << reset_valid_prev
                    << valid_flop;
        dont_initialize();
    }

    void mark_hier() {
      set_is_hierarchicall_bound(true);
    }

    void reset_valid() {
        reset_valid_curr = !reset_valid_curr;
    }

    void back_method() {
        if (rst == TRAITS::ResetLevel) {
            set_valid_prev   = 0;
            reset_valid_prev = 0;
            reset_valid_curr = 0;
            valid_flop       = 0;
        } else {
            if (ready) {
                reset_valid();
            }
            valid_flop       = valid;
            set_valid_prev   = set_valid_curr;
            reset_valid_prev = reset_valid_curr;
        }
    }

    void valid_arb() {
        if (is_hierarchically_bound()) return;
        bool b = 0;
        if (set_valid_curr != set_valid_prev) {
            b = 1;
        } else if (reset_valid_curr != reset_valid_prev) {
            b = 0;
        } else { 
            b = valid_flop; 
        }
        valid = b;
    }
};

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif


#endif

