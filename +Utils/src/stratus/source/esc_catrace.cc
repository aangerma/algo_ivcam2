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
/*
 * This file contains the functions used to enable tracing in verilated modules.
 * It is not normally compiled with the esc library because it needs the verilator
 * sources.  It gets built only when a "CA" simConfig is built.
 */

#ifdef NCSC
#include <string>
typedef std::string sc_string;
#define SYSTEMC_VERSION 20070314
#endif

// include the SystemPerl trace and coverage code
#include "Sp.cpp"
#include "esc_catrace.h"
#include "esc.h"

// The folllowing constant matches one defined in the wrappers.
#define MAX_SIMCONFIG_LENGTH 128

TraceFileType* esc_ca_trace_file = 0;

TraceFileType* esc_get_ca_trace_file()
{
    if ( esc_trace_is_enabled( esc_trace_vcd ) )
    {
        if ( ! esc_ca_trace_file )
        {
            Verilated::traceEverOn(true);
            esc_ca_trace_file = new TraceFileType;
        }
    }
    return esc_ca_trace_file;
}

static bool trace_open = false;
void esc_open_ca_trace_file()
{
    if ( esc_ca_trace_file && ! trace_open )
    {
		static char defineBuf[MAX_SIMCONFIG_LENGTH];
		const char *simConfig = NULL;
		if ( qbhGetDefine( "BDW_SIM_CONFIG", defineBuf, MAX_SIMCONFIG_LENGTH ) == qbhOK )
		{
			simConfig = defineBuf;
		}
		else
		{
			simConfig = getenv( "BDW_SIM_CONFIG" );
		}

		if ( simConfig == NULL )
		{
			esc_report_error( esc_fatal, "BDW_SIM_CONFIG needs to be set" );
		}

		char *vcdFileName;
		qbhProjectHandle hProj = qbhEmptyHandle;
		qbhError err = qbhGetVCDFileName(hProj, simConfig, 1, &vcdFileName );
		if ( err != qbhOK )
        {
            esc_report_error( esc_fatal, "Unable to get vcd trace file name for CA Simulation" );
			return;
        }

        esc_ca_trace_file->open(vcdFileName);
        trace_open = true;
    }
}

void esc_close_ca_trace_file()
{
    if ( esc_ca_trace_file && trace_open )
    {
        esc_ca_trace_file->close();
        trace_open = false;
    }
}

