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
///////////////////////////////////////////////////////////////////////
//
// esc_cosim.cc: This file defines functions for cosimulation with
//				 verilog and SystemC through the Hub.
//
// Author: Andrew Fairley
// Created: April 22, 2002
// Copyright(c) 2002 Forte Design Systems
//
///////////////////////////////////////////////////////////////////////

#define SC_INCLUDE_DYNAMIC_PROCESSES 1
#define SC_INCLUDE_FX
#include "esc.h"
#include <stdarg.h>
#if __GNUC__ < 3
#include <stdio.h>
#else
#include <iostream>
#endif
#include <string.h>
#include <stdlib.h>

#if (_MSC_VER)
#define strcasecmp stricmp
#endif


// Declare  static member.
esc_vector<esc_signal_hub_master_base*> esc_signal_hub_master_base::m_hub_masters;

// The folllowing constant matches one defined in the wrappers.
#define MAX_SIMCONFIG_LENGTH 128

//------------------------------------------------------------------------------
// Helper functions
//------------------------------------------------------------------------------
int		currentModuleNum = 0;

char *genUniqueName()
{
	char *name = new char[100];
	sprintf(name,"esc_unique_obj_%d",currentModuleNum++);
	return name;
}

//------------------------------------------------------------------------------
// Enable cosimulation
//
// This function, while appearing unnecessary, creates a dependency between 
// esc_cosim.o and esc_hub.o, because it is called from the constructor for 
// esc_hub in esc_hub.cc.  Because there is a dependency between the two object
// files, the hub_register_signal_type macros below will be executed.
// This function is only important when the user code is not compiled into a
// shared library and loaded by the Hub.
//
//------------------------------------------------------------------------------
void esc_enable_cosim()
{
}

//------------------------------------------------------------------------------
// Starting in SC2.3, if the "multiple writers" warning for sc_signal is 
// disabled, multiple writes will silently stop occuring.  This causes a very
// hard to find sim mismatch issue.  SC2.3 provides a mechanism for allowsing
// multiple writers to an sc_signal.  This function will detect when the 
// multiple writers warning is turned off, and issue a warning with a suggestion
// to use the new mechanism.  The warning is only checked in SC2.3+.
//
//------------------------------------------------------------------------------
void esc_multiple_writers_warning()
{
#if SYSTEMC_VERSION >= 20120701
	static bool reported = false;
	if (reported)
		return;
	reported = true;

	sc_actions old = sc_report_handler::set_actions(
						 SC_ID_MORE_THAN_ONE_SIGNAL_DRIVER_,SC_THROW);

	if ( old == SC_DO_NOTHING)
	{
		esc_report_error( esc_warning, 
                          "The SystemC warning for multiple drivers of an sc_signal<> was disabled in your SystemC code\n"
						  "by a call to sc_report_handler::set_actions(SC_ID_MORE_THAN_ONE_SIGNAL_DRIVER_,SC_DO_NOTHING).\n"
						  "In previous version of SystemC, this allowed writes from different threads to succeed,\n"
						  "but in SystemC 2.3, such writes will be prevented.  This may cause simulation mismatches"
						  "that are very hard to find since the warning has been disabled.\n\n"
						  "SystemC 2.3 provides a mechanism for specifying that a signal can have multiple drivers.\n"
						  "For example:\n\n"
						  "  sc_signal<sc_uint<8>, SC_MANY_WRITERS>  my_signal;\n\n"
						  "We recommend that you:\n\n"
						  "1. Re-enable the multiple drivers warning to find the signals that are being multiply written.\n"
						  "2. Declare those signals with the SC_MANY_WRITERS parameter.\n" );

		sc_report_handler::set_actions(SC_ID_MORE_THAN_ONE_SIGNAL_DRIVER_,old);
	}

#endif
}

//------------------------------------------------------------------------------
// SystemC-Hub Cosimulation functions
//------------------------------------------------------------------------------

int esc_link_signals( esc_link_direction_t direction, const char* int_path, 
					  const char* ext_path, const char* ext_domain, double input_delay )
{
	if ( !int_path || !*int_path || !ext_path || !*ext_path )
		return 0;

	int retval = 1;

	sc_object *obj = SC_FIND_OBJECT( int_path );

	if ( !obj )
		retval = 0;
	else if ( !strcmp(obj->kind(),"sc_clock") )
	{
		esc_link_signals( direction, (sc_clock*)obj, ext_path, ext_domain, input_delay );
	}
	else
	{
		esc_type_params *params = new esc_type_params;
		params->direction		= direction;
		params->extern_path		= (char*)ext_path;
		params->extern_domain	= (char*)ext_domain;
		esc_type_handler::determine_type( obj, esc_link, (void*)params );
		delete params;
	}

	return retval;
}

// Used to eliminate unusued variable warnings.
template <typename T>
static void esc_use_var( T* )
{}

int esc_link_signals( esc_link_direction_t direction, sc_clock* clk, 
					  const char* ext_path, const char *ext_domain, double input_delay )
{
	if ( !clk || !ext_path || !*ext_path )
		return 0;

	int retval = 1;

	esc_synchronizer< bool > *esc_syncher = ( direction == esc_link_in ) ?
		new esc_synchronizer< bool >( clk->name(), ext_path ) : NULL;

	esc_signal_sc_clock *esc_clk = new esc_signal_sc_clock( *clk, esc_syncher );

	if ( direction == esc_link_out )
	{
		esc_signal_sc_master< sc_clock > *esc_master_clk 
			= new esc_signal_sc_master< sc_clock >( genUniqueName(), esc_clk, 
										(char*)ext_domain, (char*)ext_path, 1);
		esc_use_var(esc_master_clk);
	}
	else
	{
		esc_signal_hub_master< sc_clock > *esc_master_clk 
			= new esc_signal_hub_master< sc_clock >( genUniqueName(), esc_clk,
													 (char*)ext_domain,
													 (char*)ext_path );
		esc_use_var(esc_master_clk);
	}

	return retval;
}

int esc_hub_register_clock( sc_clock* clk, esc_clk_edge clkedge,
							double first_edge_time_ps,
							const char *module_path,
							const char *ext_domain,
							const char *ext_clock_name)
{
	if ( !clk )
		return 0;

#if ( SYSTEMC_VERSION >= 20050714 )
	double first_edge_from_clock = clk->start_time().to_seconds() * 1.0e12;

// This error check is redundant with the one in esc_link_clockgen().
#if 0
	if ( first_edge_from_clock != first_edge_time_ps )
	{
		esc_report_error( esc_error,
						  "Clock start time %lg ps from project file conflicts with start time %lg ps from sc_clock.\nUsing value from clock.\n",
						  first_edge_time_ps, first_edge_from_clock);

	}
#endif

	first_edge_time_ps = first_edge_from_clock;
#endif

	int retval = 1;

	if ( ext_clock_name == NULL )
		ext_clock_name = clk->basename();

	char *ext_path = esc_make_path( ext_domain, module_path, ext_clock_name );

	esc_synchronizer< bool > *esc_syncher =
		new esc_synchronizer< bool >( clk->name(), ext_path, clkedge );

	esc_signal_sc_clock *esc_clk = new esc_signal_sc_clock( *clk, esc_syncher );
	esc_signal_hub_master< sc_clock > *esc_hub_master_clk 
		= new esc_signal_hub_master< sc_clock >( genUniqueName(), esc_clk, 
												 NULL, (char *)ext_path );
	delete[] ext_path;

	esc_signal_sc_master< sc_clock > *esc_master_clk 
		= new esc_signal_sc_master< sc_clock >( genUniqueName(), esc_clk, 
									NULL, NULL, 1, 0, clkedge);

	esc_syncher->m_cHandle = esc_hub_master_clk->m_cHandle;

	if ( first_edge_time_ps != 0 )
	{
		// assumes delta is in ps
		if ( qbhRequestDelayedCallback( first_edge_time_ps, 
										esc_signal_sc_master< sc_clock >::static_changed, 
										esc_master_clk ) != qbhOK )
			esc_report_error( esc_error, "Couldn't call qbhRequestDelayedCallback in %s\n",
							  esc_master_clk->name());
	}

	return retval;
}

int esc_link_signals( const char *link_file_name )
{
	FILE *fd = fopen( link_file_name, "r" );
	if ( fd == NULL )
		return -1;

	char buf[2048];

	int line=0;
	while ( fgets(buf, 2048, fd) )
	{
		char *lbuf = buf;

		char *source_domain = lbuf;
		char *internal_path = 0;
		char *external_path = 0;
		char *external_dom  = 0;
		char *iter=lbuf;
		char insideQuote=0;

		line++;

		while ( *iter != '\n' && *iter != '\r' && *iter != '\0' )
		{
			if ( *iter == '"' )
				insideQuote = !insideQuote;
			else if ( *iter == ' ' && !insideQuote )
			{
				*iter='\0';
				if ( internal_path == 0 )
					internal_path=iter+1;
				else if ( external_path == 0 )
					external_path=iter+1;
				else if ( external_dom == 0 )
					external_dom=iter+1;
			}

			iter++;
		}

		*iter = '\0';

		esc_link_direction_t direction = esc_link_none;

		if ( source_domain && !strcmp(source_domain,"esc_link_in") )
			direction = esc_link_in;
		else if ( source_domain && !strcmp(source_domain,"esc_link_out") )
			direction = esc_link_out;
		else if ( source_domain && !strcmp(source_domain,"esc_link_inout") )
			direction = esc_link_inout;

		// If it successfully parsed the line
		if ( external_path != 0 && external_path != iter-1 && !insideQuote )
			esc_link_signals( direction, internal_path, external_path, external_dom );
		else
			esc_report_error( esc_error, "Error reading line %d from file %s\n",
							  line, link_file_name );
	}

	return 0;
}

char *esc_make_path( const char *ext_domain,
					 const char *module_path,
					 const char *signal_name )
{
	char *result =
		new char[strlen(ext_domain) + strlen(module_path) + strlen(signal_name) + 3];

	const char *s = signal_name;
	while (*s && *s++ != '.')
		continue;

	if ( ! *s )
		s = signal_name;

	sprintf(result, "%s:%s/%s", ext_domain, module_path, s);

	return result;
}

/*!
 \brief Fills in parameters for a generated HDL clock.
 \param clock sc_clock from which to extract the parameter values.
 \param start_time The start time for the clock.
 \param module_path The path to the module containing the signal in the external domain
 \param ext_domain The name of the external domain
 \return Non-zero on success.
*/
int esc_link_clockgen( sc_clock *clock, const sc_time& start_time,
					   const char* module_path, const char* ext_domain, 
					   const char* clk_name )
{
	double duty_cycle = clock->duty_cycle();
	cynw_string prefix( clk_name );

#if ( defined(SC_API_VERSION_STRING) || defined(BDW_COWARE) )
// CnSC v2005.2.0 and OSCI SystemC 2.1v1 typedef
// sc_string to std::string, which doesn't
// have a cast operator to const char *.
	esc_hdl_probe<bool> *clk_firstEdge =
		new esc_hdl_probe<bool>( esc_make_path( ext_domain,
												  module_path, 
												  (prefix + "_firstEdge").c_str() ) );
	esc_hdl_probe<bool> *clk_initialized =
		new esc_hdl_probe<bool>( esc_make_path( ext_domain,
												  module_path, 
												  (prefix + "_initialized").c_str() ) );
	esc_hdl_probe<sc_time> *clk_startTime =
		new esc_hdl_probe<sc_time>( esc_make_path( ext_domain,
												   module_path, 
												   (prefix + "_startTime").c_str() ) );
	esc_hdl_probe<sc_time> *clk_firstHalf =
		new esc_hdl_probe<sc_time>( esc_make_path( ext_domain,
												   module_path, 
												   (prefix + "_firstHalf").c_str() ) );
	esc_hdl_probe<sc_time> *clk_secondHalf =
		new esc_hdl_probe<sc_time>( esc_make_path( ext_domain,
												   module_path, 
												   (prefix + "_secondHalf").c_str() ) );
#else
	esc_hdl_probe<bool> *clk_firstEdge =
		new esc_hdl_probe<bool>( esc_make_path( ext_domain,
												  module_path, 
												  prefix + "_firstEdge" ) );
	esc_hdl_probe<bool> *clk_initialized =
		new esc_hdl_probe<bool>( esc_make_path( ext_domain,
												  module_path, 
												  prefix + "_initialized" ) );
	esc_hdl_probe<sc_time> *clk_startTime =
		new esc_hdl_probe<sc_time>( esc_make_path( ext_domain,
												   module_path, 
												   prefix + "_startTime" ) );
	esc_hdl_probe<sc_time> *clk_firstHalf =
		new esc_hdl_probe<sc_time>( esc_make_path( ext_domain,
												   module_path, 
												   prefix + "_firstHalf" ) );
	esc_hdl_probe<sc_time> *clk_secondHalf =
		new esc_hdl_probe<sc_time>( esc_make_path( ext_domain,
												   module_path, 
												   prefix + "_secondHalf" ) );
#endif

	int success = 1;

	if ( clock->read() == true )
	{
		*clk_firstEdge = bool(0);
	}
	else
	{
		*clk_firstEdge = bool(1);
	}

	*clk_startTime = start_time;

	// ASSUMPTION for now: 0 < duty_cycle < 1
	sc_time firstHalf = clock->period() * duty_cycle;
	sc_time secondHalf = clock->period() - firstHalf;

	if ( duty_cycle < 0.0 || duty_cycle > 1.0 )
		success = 0;

	// Make sure the clock period halves are at least a pico-second
	// since we set the resolution of the Verilog simulator to 
	// a pico-second.
	double firstHalfPS = firstHalf.to_seconds() * 1.0e12;
	double secondHalfPS = secondHalf.to_seconds() * 1.0e12;
	if ( (firstHalfPS <= 1.0) || (secondHalfPS < 1.0) ) 
	{
		esc_report_error( esc_error, "Clock period of %.3g ps is too small to be accurately simulated in a cosimulation.\n", firstHalfPS+secondHalfPS );
		success = false;
	}

	*clk_firstHalf = firstHalf;
	*clk_secondHalf = secondHalf;

	*clk_initialized = bool(1);

	delete clk_initialized;
	delete clk_secondHalf;
	delete clk_firstHalf;
	delete clk_startTime;
	delete clk_firstEdge;

	return success;
}

double esc_config_clock_period( const char *module, double default_period )
{
	double outPeriod = 0.0;
	qbhProjectHandle hProj = qbhEmptyHandle;
	qbhError status = qbhGetModuleClockPeriod( hProj, module, default_period, &outPeriod );

	if ( status == qbhErrorInitError )
	{
		esc_report_error( esc_error, "No simulation configuration was specified in the environment" );
	}
	else if ( status == qbhErrorNoProject )
	{
		esc_report_error( esc_error, "There is no current project" );
	}
	else if ( status == qbhErrorBadName )
	{
		if ( module == NULL )
		{
			esc_report_error( esc_error,
							  "Could not find the clock period for the given simulation configuration" );
		}
		else
		{
			esc_report_error( esc_error,
							  "Could not find the clock period for module %s for the given simulation configuration",
							  module );
		}
	}

	return outPeriod;
}

double esc_config_clock_period( double default_period )
{
	return esc_config_clock_period( NULL, default_period );
}

//
// VCD tracing functions and variables
//
static sc_trace_file *esc_vcd_file = NULL;

sc_trace_file *esc_vcd_trace_file()
{
	return esc_vcd_file;
}

sc_trace_file *esc_get_vcd_trace_file()
{
	if ( esc_vcd_file == NULL )
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
		qbhError err = qbhGetVCDFileName(hProj, simConfig, 0, &vcdFileName );
		if ( err != qbhOK )
			return NULL;

		esc_open_vcd_trace( vcdFileName );
	}
	return esc_vcd_file;
}

void esc_open_vcd_trace( const char *file_name )
{
	// SystemC suffixes .vcd to filenames automatically. Make sure
	// that doesn't get tacked onto a filename that already has the suffix.
	if ( strrchr( file_name, '.' ) != NULL )
	{
		char *trunc_file_name = new char[strlen(file_name)+1];
		strcpy( trunc_file_name, file_name );

		char *dot = strrchr( trunc_file_name, '.' );
		if ( strcmp( dot, ".vcd" ) == 0 )
			*dot = 0;

		esc_vcd_file = sc_create_vcd_trace_file( trunc_file_name );

		delete[] trunc_file_name;
	}
	else
	{
		esc_vcd_file = sc_create_vcd_trace_file( file_name );
	}

#       if defined(SYSTEMC_2_3_0)
	    //sc_set_default_time_unit(1,SC_SEC);//sc2.0
	    ((vcd_trace_file*)esc_vcd_file)->set_time_unit( 1, SC_PS );
#       else
	    ((vcd_trace_file*)esc_vcd_file)->sc_set_vcd_time_unit( -12 );
#       endif
}

void esc_close_vcd_trace()
{
	if (esc_vcd_file != NULL )
	{
		sc_close_vcd_trace_file( esc_vcd_file );
		esc_vcd_file = NULL;
	}
}

//
// FSDB tracing functions and variables
//

// Pointer to the wrapper-provided function for opening FSDB.
static pvf_filename esc_open_fsdb_trace;

void esc_set_open_fsdb_trace( pvf_filename fsdb_opener )
{
	esc_open_fsdb_trace = fsdb_opener;
}

// Pointer to the wrapper-provided function for opening FSDB SCV files.
static pvf_filename esc_open_fsdb_scv_trace;

void esc_set_open_fsdb_scv_trace( pvf_filename fsdb_scv_opener )
{
	esc_open_fsdb_scv_trace = fsdb_scv_opener;
}

static sc_trace_file *esc_fsdb_file = NULL;

sc_trace_file *esc_fsdb_trace_file()
{
	return esc_fsdb_file;
}

esc_trace_t esc_trace_type()
{
	if (esc_trace_is_enabled(esc_trace_vcd ))
		return esc_trace_vcd;
	else if  (esc_trace_is_enabled(esc_trace_fsdb ))
		return esc_trace_fsdb;
	else
		return esc_trace_off;
}

sc_trace_file *esc_get_fsdb_trace_file()
{
	if ( esc_fsdb_file == NULL )
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

		char *fsdbFileName;
		qbhProjectHandle hProj = qbhEmptyHandle;
		qbhError err = qbhGetFSDBFileName(hProj, simConfig, 0, &fsdbFileName );
		if ( err != qbhOK )
			return NULL;

		(*esc_open_fsdb_trace)( fsdbFileName );
	}
	return esc_fsdb_file;
}

//
// tracing functions for all formats
//
sc_trace_file *esc_get_trace_file( esc_trace_t traceType )
{
	switch ( traceType )
	{
	case esc_trace_vcd:
		return esc_get_vcd_trace_file();
	case esc_trace_fsdb:
		return esc_get_fsdb_trace_file();
	default:
		return NULL;
	}
}

sc_trace_file *esc_trace_file( esc_trace_t traceType )
{
	switch ( traceType )
	{
	case esc_trace_vcd:
		return esc_vcd_trace_file();
	case esc_trace_fsdb:
		return esc_fsdb_trace_file();
	default:
		return NULL;
	}
}

void esc_set_trace_file( sc_trace_file *trace_file, esc_trace_t traceType)
{
	switch ( traceType )
	{
	case esc_trace_vcd:
		esc_vcd_file = trace_file;
	case esc_trace_fsdb:
		esc_fsdb_file = trace_file;
	default:
		return;
	}
}

bool esc_trace_is_enabled( esc_trace_t traceType )
{
	int result = 0;
	qbhError status = qbhGetCurrentProjectDoesTrace( (qbhTraceType)traceType,
													 &result );

	if ( status == qbhErrorNoProject )
	{
		esc_report_error( esc_error, "There is no current project" );
		return false;
	}

	return (bool)result;
}

// The current transaction database.
static scv_tr_db* bdw_scv_tr_db = 0;

scv_tr_db* esc_get_scv_tr_db()
{
	return bdw_scv_tr_db;
}


void esc_set_scv_tr_db( scv_tr_db* db )
{
	bdw_scv_tr_db = db;
}


scv_tr_db* esc_open_scv_tr_db()
{
	if ( !esc_get_scv_tr_db() )
	{

		if ( esc_trace_is_enabled( esc_trace_fsdb ) )
		{
			// Open the wrapper-provided FSDB SCV logger.
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

			// We use the same name as the SystemC signal-level FSDB file.
			char *fsdbFileName;
			qbhProjectHandle hProj = qbhEmptyHandle;
			qbhError err = qbhGetFSDBFileName(hProj, simConfig, 0, &fsdbFileName );
			if ( err != qbhOK )
				return NULL;

			(*esc_open_fsdb_scv_trace)( fsdbFileName );
		}
	}

	return esc_get_scv_tr_db();
}


#if HUB_USE_DYNAMIC_PRODCESSES 
void esc_signal_sc_clock_base::spawn()
{
	m_thread = sc_spawn( sc_bind( &esc_signal_sc_clock_base::update_synchronizer, this), 
						 sc_gen_unique_name("update_synchronizer") );
}

void esc_signal_sc_master_base::spawn( const sc_event* e )
{
	sc_spawn_options options;
	options.spawn_method();
	options.set_sensitivity( e );
	m_method = sc_spawn( sc_bind( &esc_signal_sc_master_base::changed, this), 
						 sc_gen_unique_name("changed"), &options);
}
#endif
#if 0
//
// gcc 3.3.2 + ld 2.14 on Solaris have a problem whereby they need extra template
// instantiations.
//

sc_signal< sc_lv< 10 > > esc_lv_template_instance;
sc_signal< sc_bv< 10 > > esc_bv_template_instance;
sc_signal< sc_signed > esc_signed_template_instance;
sc_signal< sc_unsigned > esc_unsigned_template_instance;
sc_signal< sc_fix > esc_fix_template_instance;
#endif
