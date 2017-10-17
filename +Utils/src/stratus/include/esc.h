/**************************************************************************
**
** This file is part of the Cynthesizer (TM) software product and is protected 
** by law including United States copyright laws, international treaty 
** provisions, and other applicable laws.
**
** Copyright (c) 2012 Forte Design Systems and / or its subsidiary(-ies).  All
rights reserved.
** Copyright (c) 2015 Cadence Design Systems, Inc. All rights reserved worldwide.
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

#ifndef ESC_HEADER_GUARD_
#define ESC_HEADER_GUARD_

/*!
  \file esc.h
  \brief This file facilitates the inclusion of the SystemC verification classes.
*/

#define esc_str(S) # S
#define esc_xstr(S) esc_str(S)

/* The MY_VERSION macro is used to enable automated version numbering. */
#define	MY_VERSION "15.21-s103"
#define BDS_VERSION MY_VERSION "  (" esc_xstr(BDW_DATE) ")"

/*!
  \mainpage

  \section Introduction
  \b Introduction
  <br>
  This is intended as a comprehensive listing of classes and functions that compose
  ESC.  There are both a separate ESC Users Guide and examples using ESC available for download
  on the Web Learning Center: http://support.forteds.com.

  \section Usage
  \b Usage
  <br>
  Select Compound List above to see a list of classes with a short description for each.
  <br>
  Select File Members above to see a list of \#defines (all caps) and C-style functions that
  are a part of ESC.
*/

#if defined(WIN32)
/*! The ESC_EXPORT symbol can be used in Windows DLLs to cause the name of a function
	to be exported from the DLL. This typically required for Hub library callbacks.
	For example:
	\code
	extern "C" ESC_EXPORT void my_callback( qbhLibraryCallbackReason cbr )
	\endcode
 */
# define ESC_EXPORT __declspec( dllexport )
#else
# define ESC_EXPORT
#endif

// Define HUBEXPORT macro for making symbols visible to the HUB.
#if defined(WIN32)
# ifndef HUBEXPORT
#   define HUBEXPORT __declspec( dllexport )
#   define HUBIMPORT __declspec( dllimport )
# endif
#else
# define HUBEXPORT
# define HUBIMPORT
#endif

#if defined(SYSTEMC_INT)
# define SCEXPORT HUBEXPORT
#else
# define SCEXPORT HUBIMPORT
#endif

//! Typedef of an esc_handle
typedef unsigned long esc_handle;
//! Value of an esc_handle when there is an error
#define esc_bad_handle 0xffffffff
//! Value of an esc_handle when it is empty
#define esc_empty_handle esc_bad_handle

// For OSCI SystemC 2.1v1, we want sc_string defined to ::std::string.
#define SC_USE_STD_STRING

// Base SystemC classes
#include "systemc.h"

#if defined(NC_SYSTEMC) || SYSTEMC_VERSION > 20041012
typedef std::string sc_string;
#endif

// For OSCI SystemC 2.1v1, we want sc_string defined to ::std::string.
#if defined(SC_API_VERSION_STRING)
	typedef std::string cynw_string;
#else
	typedef sc_string cynw_string;
#endif

#if defined(__GNUC__) && (__GNUC__ >= 3)
#include <iostream>
#include <sstream>
using std::ostringstream;
using std::ends;
#endif

#define esc_fatal		0		//! Passed in to esc_report_error(), esc_fatal means report error and exit
#define esc_error		1		//! Passed in to esc_report_error(), esc_error means report error
#define esc_warning		2		//! Passed in to esc_report_error(), esc_warning means report message as a warning
#define esc_note		3		//! Passed in to esc_report_error(), esc_note means report message as a note

/*!
  \brief Reports an error
  \param conditionCode Can be esc_fatal, esc_error, esc_warning, or esc_note

  If HUB=1, it will call qbhReportRuntimeError(isFatal, buffer),
  if HUB=0, it will throw an exception if it's fatal, or otherwise print to stderr
 */
inline
void  esc_report_error( int conditionCode, const char* format, ... );

#if BDW_HUB
#include "capicosim.h"
#endif

// SystemC verification classes
#include "esc_utils.h"
#include "esc_trans.h"
#include "esc_hub.h"
#include "esc_watcher.h"
#include "esc_mem.h"
#include "esc_source.h"
#include "esc_ran.h"
#include "esc_msg.h"
#include "esc_tx.h"
#include "esc_encoder.h"
#include "esc_decoder.h"
#include "esc_dispatcher.h"
#include "esc_log.h"
#include "esc_cosim.h"
#include "esc_type.h"
#include "esc_csvlog.h"
#include "esc_chan.h"
#include "esc_hub_link.h"
#include "esc_scv.h"
#include "esc_elab.h"
#include "esc_cleanup.h"

inline
void  esc_report_error( int conditionCode, const char* format, ... )
{
	char buf[8192];

	va_list ap;

	va_start(ap, format);
	vsprintf(buf, format, ap);
	va_end(ap);

#if BDW_HUB
	//
	// esc_hub::domain() has the side effect of creating an esc_hub if none exists yet.
	// This causes a SystemC error if simulation has already started because esc_hub
	// is derived from sc_module.
	//
	if ( esc_hub::has_domain() )
	{
		const char *hashes = "######################################################################\n";

		if ( conditionCode == esc_fatal )
		{
			qbhPrintf( hashes );
			qbhPrintf( hashes );
			//cerr << hashes << endl << hashes << endl << endl;
		}
		qbhReportRuntimeError( esc_hub::domain(), conditionCode, buf );
		if ( conditionCode == esc_fatal )
		{
			qbhPrintf( hashes );
			qbhPrintf( hashes );
			//cerr << endl << hashes << endl << hashes << endl;
		}
	}
	else
		fprintf(stderr,"%s\n",buf);
	if ( conditionCode == esc_fatal )
    {
		esc_stop();
        exit(1);
    }
#else
	if ( conditionCode == esc_fatal )
	{
#if ( defined(SC_API_VERSION_STRING) || defined(BDW_COWARE) )
// CnSC v2005.2.0 and OSCI SystemC 2.1v1 typedef
// sc_exception to std::exception, which doesn't
// have a constructor that takes a string argument.
		throw sc_exception();
#else
		throw sc_exception(buf);
#endif
	}
	else
		fprintf(stderr,"%s\n",buf);
#endif // BDW_HUB
}

#endif // ESC_HEADER_GUARD_
