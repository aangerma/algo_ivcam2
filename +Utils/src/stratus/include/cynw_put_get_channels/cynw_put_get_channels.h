// *****************************************************************************
// *****************************************************************************
// cynw_put_get_channels.h
//
// This file is the main header file for the Put/Get channels which are part of 
// the Cadence FlexChannels library.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_PUT_GET_CHANNELS_H
#define CYNW_PUT_GET_CHANNELS_H


// Backward compatibility:
#ifdef FLEX_CHAN_TRANSACTION_RECORD
#define FLEX_CHANNELS_RECORD_TRANSACTIONS
#endif

# include <stratus_hls.h>

#ifdef FLEX_CHANNELS_RECORD_TRANSACTIONS
#include "cve.h"
#endif

#include "../cynw_flex_channels.h"
#include "../cynw_tlm/cynw_tlm.h"

// Internal modules. 
#include "cynw_sync_snd.h"
#include "cynw_sync_rcv.h"
#include "cynw_can_put_mod.h"
#include "cynw_can_get_mod.h"

// Always block initiator.
#include "cynw_blocking_put.h"
#include "cynw_blocking_get.h"
// May block initiator.
#include "cynw_may_block_put.h"
#include "cynw_may_block_get.h"
#include "cynw_may_block_get_peek.h"
// Never block initiator.
#include "cynw_non_blocking_put.h"
#include "cynw_non_blocking_get.h"
#include "cynw_non_blocking_get_peek.h"

// Hierarchical initiators
#include "cynw_hier_put.h"
#include "cynw_hier_get.h"

// Channels.
#include "cynw_put_get_channel.h"

#endif

