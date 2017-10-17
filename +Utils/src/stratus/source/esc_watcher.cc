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
// esc_watcher.cc: This file contains implementations of non-inline 
//					esc_watchable and esc_watcher class members.
//					
// Copyright(c) 2002 Forte Design Systems
//
///////////////////////////////////////////////////////////////////////

#include "esc.h"

//------------------------------------------------------------------------------
// Static member data
//------------------------------------------------------------------------------

// Table indexed by sc_object* containing esc_watchable_base*

sc_phash<sc_object*, esc_watchable_base*>* esc_watchable_base::m_watchable_table = 0;


//------------------------------------------------------------------------------
// Class esc_watchable_base
//------------------------------------------------------------------------------

// Compares two pointers trivially.
static int esc_compare_sc_object_void(const void* a, const void* b)
{
	if ( a < b )
		return -1;
	else if ( a > b )
		return 1;
	else
		return 0;
}


// Allocates and sets up the table of watchables.
void esc_watchable_base::init_table()
{
	m_watchable_table = new sc_phash<sc_object*, esc_watchable_base*>;
	m_watchable_table->set_cmpr_fn(esc_compare_sc_object_void);
}

// Adds a watchable to the table.
// Generates an error if it's already in the table.
bool esc_watchable_base::register_watchable( esc_watchable_base* watchable )
{
	if ( !m_watchable_table )
		init_table();

	sc_object *target = watchable->target();
	assert( target != 0 );

	esc_watchable_base* existing = find_for( target );
	if ( !existing )
	{
		m_watchable_table->insert( target, watchable );
		return true;
	}	
	else
	{
		esc_report_error( esc_error, "Attempt to register a second esc_watchable_base for sc_object %s",
							target->name() );
		return false;
	}
}
