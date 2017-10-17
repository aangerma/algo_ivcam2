// *****************************************************************************
// *****************************************************************************
// cynw_sync_rcv.h
//
// This file contains definition of Sync_Rcv module, responsible for setting 
// the ready signal, and buffering input data when necessary.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_SYNC_RCV_H
#define CYNW_SYNC_RCV_H

# include "cynw_comm_util.h"


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw {

template<typename T, typename TRAITS>
struct Sync_Rcv 
    : sc_module
    , sc_interface 
    , cynw_hier_bind_detector
{
    sc_in <bool>            clk;
    sc_in <bool>            rst;

    sc_in <bool>            valid;
    sc_out<bool>            ready;
    sc_in <T>               data;
    sc_out<T>               data_buf;
    sc_in<bool>             set_ready_curr;

    sc_signal<bool>         set_ready_prev;
    sc_signal<bool>         reset_ready_prev;
    sc_signal<bool>         reset_ready_curr;
    sc_signal<bool>         ready_flop;

    SC_CTOR(Sync_Rcv)
        : clk("clk")
        , rst("rst")
        , valid("valid")
        , ready("ready")
        , data("data")
        , data_buf("data_buf")
        , set_ready_curr("set_ready_curr")
        , set_ready_prev("set_ready_prev")
        , reset_ready_prev("reset_ready_prev")
        , reset_ready_curr("reset_ready_curr")
        , ready_flop("ready_flop")
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

        SC_METHOD(ready_arb);
        sensitive << set_ready_curr   
                  << set_ready_prev
                  << reset_ready_curr
                  << reset_ready_prev 
                  << ready_flop;
        dont_initialize();
    }

    void mark_hier() {
      set_is_hierarchicall_bound(true);
    }

    void reset_ready() {
        reset_ready_curr = !reset_ready_curr.read();
    }

    void buffer_incoming_data() {
//        data_buf = data;
        data_buf.write(data.read());
    }

    void back_method() {
        if (rst == TRAITS::ResetLevel) {
            set_ready_prev   = 0;
            reset_ready_prev = 0;
            reset_ready_curr = 0;
            ready_flop       = 1;
            if (TRAITS::ResetData) {
                data_buf = T();
            }
        } else {
            if (valid && ready) {
                buffer_incoming_data();
                reset_ready();
            }
            ready_flop       = ready;
            set_ready_prev   = set_ready_curr;
            reset_ready_prev = reset_ready_curr;
        }
    }

    void ready_arb() {
        if (is_hierarchically_bound()) return;
        bool b = 0;
        if (set_ready_curr != set_ready_prev) {
            b = 1; 
        } else if (reset_ready_curr != reset_ready_prev) {
            b = 0;
        } else {
            b = ready_flop;
        }
        ready = b;
    }
};

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif


#endif

