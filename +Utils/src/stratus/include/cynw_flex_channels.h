// *****************************************************************************
// *****************************************************************************
// ctos_flex_channels.h
//
// This file is the main header file for the Cadence Flex Channel library.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_FLEX_CHANNELS_H
#define CYNW_FLEX_CHANNELS_H


// *****************************************************************************
#define FLEX_CHANNELS_VERSION_STRING    "2_0_0"
#define FLEX_CHANNELS_VERSION_MAJOR     2
#define FLEX_CHANNELS_VERSION_MINOR     0
#define FLEX_CHANNELS_VERSION_PATCH     0
#define FLEX_CHANNELS_ORIGINATOR        "CADENCE"
// *****************************************************************************
//
#include "stratus_hls.h" // Added

#include "cynw_flex_channels_defines.h"
#include "cynw_flex_channels_utils.h"

#include "cynw_flex_channels_traits.h"
#include "cynw_flex_channels_default_traits.h"

#include "cynw_put_get_channels/cynw_put_get_channels.h"
#include "cynw_put_get_channels/cynw_put_get_internal.h"

// adaptors to p2p initiators
#include "cynw_flex_channels_p2p.h"

// put_get_direct
#include "cynw_put_get_channels/cynw_put_get_direct.h"

// Macros for backward compatibility
#include "cynw_flex_channels_macros.h"

#endif

