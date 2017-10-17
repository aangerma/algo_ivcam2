/**************************************************************************
**
** This file is part of the Cynthesizer (TM) software product and is protected 
** by law including United States copyright laws, international treaty 
** provisions, and other applicable laws.
**
** Copyright (c) 2012 Forte Design Systems and / or its subsidiary(-ies).  All
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
// esc_type.cc: This file registers types with the Hub.
//
// Author: Andrew Fairley
// Created: May 13, 2002
// Copyright(c) 2002 Forte Design Systems
//
///////////////////////////////////////////////////////////////////////
#include "esc.h"


// If this file gets loaded, a large number of functions will be defined in the
// linking application, which may cause a crash while initializing the C++ runtime
// exception handling table while executing on a QT stack.  To workaround this
// problem, cause esc_init_exceptions() to be called at load time.
static int __init_exceptions = esc_init_exceptions();

esc_type_fp *esc_type_handler::m_link_functions = NULL;
esc_type_fp *esc_type_handler::m_type_functions = NULL;
esc_type_fp *esc_type_handler::m_watch_functions = NULL;
esc_type_fp *esc_type_handler::m_log_functions = NULL;

//------------------------------------------------------------------------------
// Register types
//
// This function, while appearing unnecessary, creates a dependency between 
// esc_type.o and esc_hub.o, because it is called from the constructor for 
// esc_hub in esc_hub.cc.  Because there is a dependency between the two object
// files, the hub_register_signal_type macros below will be executed.
// This function is only important when the user code is not compiled into a
// shared library and loaded by the Hub.
//
//------------------------------------------------------------------------------
void esc_register_types()
{
	//
	// gcc 3.3.2 + ld 2.14 on Solaris have a problem whereby they need extra template
	// instantiations.
	//

	sc_signal< sc_lv< 10 > > esc_lv_template_instance;
	sc_signal< sc_bv< 10 > > esc_bv_template_instance;
	sc_signal< sc_signed > esc_signed_template_instance;
	sc_signal< sc_unsigned > esc_unsigned_template_instance;
	//sc_signal< sc_fix > esc_fix_template_instance;
}
