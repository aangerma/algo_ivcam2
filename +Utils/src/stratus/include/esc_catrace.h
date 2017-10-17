/**************************************************************************
**
** This file is part of the Cynthesizer (TM) software product and is protected 
** by law including United States copyright laws, international treaty 
** provisions, and other applicable laws.
**
** Copyright (c) 2013 Forte Design Systems and / or its subsidiary(-ies).  All
rights reserved.
**
** This file may only be used under the terms of an active Cynthesizer Software 
** License Agreement (SLA) and only for the limited "Purpose" stated in
that
** agreement. All clauses in the SLA apply to the contents of this file,
** including, but not limited to, Confidentiality, License rights, Warranty
** and Limitation of Liability.

** If you have any questions regarding the use of this file, please contact
** Forte Design Systems at: Sales@ForteDS.com
**
***************************************************************************/

#ifndef ESC_CATRACE_HEADER_GUARD__
#define ESC_CATRACE_HEADER_GUARD__

/*
 * This file defines the functions used for enabling tracing inside verilated modules
 */

#ifdef USE_VERILATED_VCD
#include "verilated_vcd_sc.h"
typedef VerilatedVcdSc TraceFileType;
#else
#include "SpTraceVcd.h"
typedef SpTraceFile TraceFileType;
#endif

#include "verilated.h"


extern TraceFileType* esc_ca_trace_file;

TraceFileType* esc_get_ca_trace_file();
void esc_open_ca_trace_file();
void esc_close_ca_trace_file();
 
#endif // ESC_CATRACE_HEADER_GUARD__
