

#ifndef HLS_BASICS_H
#define HLS_BASICS_H true


#pragma once

#include "stratus_hls.h"

#include "cynw_flex_channels.h"
#include "hls_threads.h"
#include "hls_array.h"
#include "hls_sig.h"

#define CTOR_NM(nm)  nm ( #nm )

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif

#ifdef NC_SYSTEMC
#ifdef STRATUS
// error - BOTH NC_SYSTEMC and STRATUS tool flags are set!
#endif
#endif


#endif
