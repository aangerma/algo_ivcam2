// *****************************************************************************
// *****************************************************************************
// ctos_flex_channels_default_traits.h
//
// This file contains the definition of the Flex Channel traits. 
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_FLEX_CHANNELS_DEFAULT_TRAITS_H
#define CYNW_FLEX_CHANNELS_DEFAULT_TRAITS_H

#include "cynw_flex_channels_traits.h"
#include "cyn_enums.h"

#ifndef FLEX_CHANNELS_OVERRIDE_DEFAULT_TRAITS
// The macro definition FLEX_CHANNELS_OVERRIDE_DEFAULT_TRAITS enables the user 
// to define custom default traits files. 

// *****************************************************************************
// Flex Channel supports both TLM Interface and Signal-level Interface (default)
// To simulate the TLM interface define TLM_SIM macro
//      #define TLM_SIM
// Below default traits definition for the two abstraction levels
//
#ifdef  TLM_SIM
#warning "TLM_SIM compile flag is deprecated. Please use ioConfig instead."
typedef TLM_TRAITS  DEFAULT_TRAITS;
#else

#ifndef ioConfig
#define ioConfig PIN
#endif

template <typename LEVEL>
struct DEFAULT_TRAITS_ : public SIG_TRAITS
{};

template <>
struct DEFAULT_TRAITS_<CYN::TLM> : public TLM_TRAITS
{};

#define DEFAULT_TRAITS DEFAULT_TRAITS_<ioConfig>

#endif //TLM_SIM

#endif //FLEX_CHANNELS_OVERRIDE_DEFAULT_TRAITS

#endif //CYNW_FLEX_CHANNELS_DEFAULT_TRAITS_H

