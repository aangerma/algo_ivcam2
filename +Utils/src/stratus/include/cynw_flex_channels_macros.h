// *****************************************************************************
// *****************************************************************************
// ctos_put_get_channels_macros.h
//
// This file contains the definitions of sockets and channel macros.
// This is for backward compatibility to version 1.0 of the FlexChannels.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_PUT_GET_CHANNELS_MACROS_H
#define CYNW_PUT_GET_CHANNELS_MACROS_H


// Initiators:

// 1. may-block
#define GET_INITIATOR(type, n)                  get_initiator<type > n
#define PUT_INITIATOR(type, n)                  put_initiator<type > n

// 2. Blocking
#define B_GET_INITIATOR(type, n)                b_get_initiator<type > n
#define B_PUT_INITIATOR(type, n)                b_put_initiator<type > n

// 3. Non-blocking
#define NB_GET_INITIATOR(type, n)               nb_get_initiator<type > n
#define NB_PUT_INITIATOR(type, n)               nb_put_initiator<type > n

#define INITIATOR_CTOR(n)                       n(#n)
#define INITIATOR_BIND(n, CLK, RST)             n.clk_rst(CLK,RST)
#define INITIATOR_BIND_SIGS(n, CLK, RST)        n.clk_rst(CLK,RST)

// Channel:
#define PUT_GET_CHANNEL(type, n)                put_get_channel<type> n
#define PUT_GET_CHANNEL_CTOR(n)                 n(#n)

#define PUT_GET_CHANNEL_BIND_INITIATOR(chan, init)  \
                                                init(chan)

// Hierarchical Initiators:

// 1. May-block hierarchical
#define PUT_HIER_INITIATOR(type, n)             hier_put_initiator<type > n
#define GET_HIER_INITIATOR(type, n)             hier_get_initiator<type > n

// 2. Non-Blocking hierarchical
#define NB_GET_HIER_INITIATOR(type, n)	        hier_get_initiator<type > n
#define NB_PUT_HIER_INITIATOR(type, n)	        hier_put_initiator<type > n

// 2. Blocking hierarchical
#define B_GET_HIER_INITIATOR(type, n)	        hier_get_initiator<type > n
#define B_PUT_HIER_INITIATOR(type, n)	        hier_put_initiator<type > n

#define HIER_INITIATOR_CTOR(n)                  INITIATOR_CTOR(n)
#define HIER_INITIATOR_BIND(n, clk, rst)        /* empty */
#define HIER_INITIATOR_BIND_INITIATOR(n, submod_init) \
                                                submod_init(n)

#endif

