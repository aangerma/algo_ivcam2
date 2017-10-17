// *****************************************************************************
// *****************************************************************************
// ctos_flex_channels_traits.h
//
// This file contains the definition of the Flex Channel traits. 
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_FLEX_CHANNELS_TRAITS_H
#define CYNW_FLEX_CHANNELS_TRAITS_H


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw {

// *****************************************************************************
// class TLM_TRAITS_BASE
// 
// This struct is the base class for selecting TLM implementation. 
//
// *****************************************************************************
struct TLM_TRAITS_BASE { 
    // The variable "Level" is used to select between the TLM and the 
    // signal-level configuration of initiators and channels.
    //      - Level = 0 : TLM channel and initiators,
    //      - Level = 1 : signal-level channel and initiators.
    static const bool Level     = 0;
    // The variable "Put_Get_Channel_FIFO_Size" is used to specify the size
    // of the FIFO inside a put-get channel. 
    static const unsigned int Put_Get_Channel_FIFO_Size = 2;
};


// *****************************************************************************
// class TLM_TRAITS_BASE
//
// This is the default class for selecting TLM-level implementation.
// *****************************************************************************
struct TLM_TRAITS : TLM_TRAITS_BASE { };


// *****************************************************************************
// class SIG_TRAITS_BASE
//
// *****************************************************************************
struct SIG_TRAITS_BASE {
    static const bool   Level      = 1;
    // The variable "Allow_Multiple_Calls_Per_Cycle" is used to insert a wait() 
    // in a may-block put() or get(). This wait is executed when the function 
    // is called more once in a cycle. Note that this additional wait() will 
    // not be in the RTL.
    static const bool   Allow_Multiple_Calls_Per_Cycle     = 0;
    // Setting variable "Allow_Multiple_Calls_Per_Cycle_RTL" will insert the 
    // additional wait statement into the code parsed by CtoS. If this variable
    // is not set, a bit "multiple_calls_in_rtl" is set in the RTL when there
    // is more than one call per cycle.
    static const bool   Allow_Multiple_Calls_Per_Cycle_RTL = 0;


    enum {  pos     = true,
            neg	    = false,
            sync    = true,
            async   = false,
            high    = true,
            low     = false
    };
 
    //
    // The following traits structs are used to select 
    //      - clock edge, 
    //      - reset synchronous or asynchronous
    //      - reset polarity
    //      - whether to reset data signals or not. 
    static const bool PosEdgeClk = pos;
    static const bool ResetSync  = async;
    static const bool ResetLevel = low;
    static const bool ResetData  = false;
};

// Following are pre-defined signal-level configurations:

// Default resets are asynchronous 

struct SIG_TRAITS_pCLK_nRST : SIG_TRAITS_BASE 
{ 
    static const bool PosEdgeClk = 1;
    static const bool ResetLevel = 0;
    static const bool ResetData  = 0;
};

struct SIG_TRAITS_pCLK_nRST_ResetData : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 1;
    static const bool ResetLevel = 0;
    static const bool ResetData  = 1;
};

struct SIG_TRAITS_pCLK_pRST : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 1;
    static const bool ResetLevel = 1;
    static const bool ResetData  = 0;
};

struct SIG_TRAITS_pCLK_pRST_ResetData : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 1;
    static const bool ResetLevel = 1;
    static const bool ResetData  = 1;
};

struct SIG_TRAITS_nCLK_nRST : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 0;
    static const bool ResetLevel = 0;
    static const bool ResetData  = 0;
};

struct SIG_TRAITS_nCLK_nRST_ResetData : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 0;
    static const bool ResetLevel = 0;
    static const bool ResetData  = 1;
};

struct SIG_TRAITS_nCLK_pRST : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 0;
    static const bool ResetLevel = 1;
    static const bool ResetData  = 0;
};

struct SIG_TRAITS_nCLK_pRST_ResetData : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 0;
    static const bool ResetLevel = 1;
    static const bool ResetData  = 1;
};


//
// Shorter names and default initiators:
//
typedef SIG_TRAITS_pCLK_nRST            SIG_TRAITS;
typedef SIG_TRAITS_pCLK_nRST_ResetData  SIG_TRAITS_ResetData;


// Synchronous resets:

struct SIG_TRAITS_pCLK_SYNC_nRST : SIG_TRAITS_BASE 
{ 
    static const bool PosEdgeClk = 1;
    static const bool ResetLevel = 0;
    static const bool ResetData  = 0;
    static const bool ResetSync  = sync;
};

struct SIG_TRAITS_pCLK_SYNC_nRST_ResetData : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 1;
    static const bool ResetLevel = 0;
    static const bool ResetData  = 1;
    static const bool ResetSync  = sync;
};

struct SIG_TRAITS_pCLK_SYNC_pRST : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 1;
    static const bool ResetLevel = 1;
    static const bool ResetData  = 0;
    static const bool ResetSync  = sync;
};

struct SIG_TRAITS_pCLK_SYNC_pRST_ResetData : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 1;
    static const bool ResetLevel = 1;
    static const bool ResetData  = 1;
    static const bool ResetSync  = sync;
};

struct SIG_TRAITS_nCLK_SYNC_nRST : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 0;
    static const bool ResetLevel = 0;
    static const bool ResetData  = 0;
    static const bool ResetSync  = sync;
};

struct SIG_TRAITS_nCLK_SYNC_nRST_ResetData : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 0;
    static const bool ResetLevel = 0;
    static const bool ResetData  = 1;
    static const bool ResetSync  = sync;
};

struct SIG_TRAITS_nCLK_SYNC_pRST : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 0;
    static const bool ResetLevel = 1;
    static const bool ResetData  = 0;
    static const bool ResetSync  = sync;
};

struct SIG_TRAITS_nCLK_SYNC_pRST_ResetData : SIG_TRAITS_BASE 
{
    static const bool PosEdgeClk = 0;
    static const bool ResetLevel = 1;
    static const bool ResetData  = 1;
    static const bool ResetSync  = sync;
};

}; // namespace cynw

#ifndef DONT_USE_NAMESPACE_CYNW
using namespace cynw;
#endif

#endif

