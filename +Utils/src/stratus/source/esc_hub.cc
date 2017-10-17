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
// esc_hub.cc: This file defines the interface of classes that are
//             used by SystemC to interact with the Hub.
//
// Author: Andrew Fairley
// Created: March 5, 2002
// Copyright(c) 2002 Forte Design Systems
//
///////////////////////////////////////////////////////////////////////

#include "esc.h"
#include <assert.h>
#include <stdarg.h>
#if __GNUC__ < 3
#include <stdio.h>
#else
#include <iostream>
#endif
#include <time.h>
#include <unistd.h>
#include <sys/utsname.h>

#define ERR_BUFF_SIZE 4096
#define ESC_RAN_SEED  1

//------------------------------------------------------------------------------
// Static member data
//------------------------------------------------------------------------------
esc_hub *esc_hub::m_current_p					= NULL;
int      esc_hub::m_systemc_is_master			= 1;
int		 esc_hub::m_inited						= 0;
qbhValRecEncodingInfo* esc_hub::m_info			= NULL;
esc_vector<esc_tx_logger*> esc_hub::m_open_loggers;
esc_sim_log *esc_sim_log::cur_sim_log = NULL;
esc_ran_gen< int > *esc_hub::m_ran_gen = NULL;

//------------------------------------------------------------------------------
// esc_hub constructor
//------------------------------------------------------------------------------
esc_hub::esc_hub( int is_master )
	: sc_module( sc_module_name("esc_hub") ),
	  m_cb_list(0)
{
	SC_THREAD(main);

	m_inited = 0;
	esc_hub::m_systemc_is_master = is_master;

	// Register this domain with the HUB.
	register_domain( is_master );

	esc_register_types();
	esc_enable_cosim();
#if SYSTEMC_VERSION >= 20120701
	sc_report_handler::set_actions( SC_ID_NO_SC_START_ACTIVITY_ , SC_DO_NOTHING);
#endif
}

//------------------------------------------------------------------------------
// esc_hub destructor
//------------------------------------------------------------------------------
esc_hub::~esc_hub()
{
	if ( m_info )
	{
		delete m_info;
		m_info = NULL;
	}
}

//------------------------------------------------------------------------------
// main()
//------------------------------------------------------------------------------
void esc_hub::main()
{
	while( 1 )
	{
		// Default to waiting awhile
		sc_time t( 100000, SC_SEC );

		// If we should kick off some callbacks...
		if ( m_cb_list && m_cb_list->m_time == esc_normalize_to_ps(sc_time_stamp()) )
		{
			esc_cb_elem *iter = m_cb_list->m_cb_elem;
			esc_cb_elem *tmp = NULL;
			esc_timed_cb_elem *ttmp = NULL;

			while ( iter )
			{
				(iter->m_callbackFunc)( iter->m_callbackData );
				
				tmp = iter->m_next;
				delete iter;
				iter = tmp;
			}
			
			ttmp = m_cb_list->m_next;
			delete m_cb_list;
			m_cb_list = ttmp;
		}
		
		// Figure out how long to wait for...
		if ( m_cb_list )
		{
			// assumes m_time is in ps
			double delta = m_cb_list->m_time - esc_normalize_to_ps(sc_time_stamp());

			if ( delta > 0 )
			{
				t = sc_time( delta, SC_PS );
			}
		}
		
		// Wait until we time out, or are interrupted
		wait( t, m_interrupt_event );
	}
}

void esc_hub::close_all_open_loggers()
{
	while( ! m_open_loggers.empty() )
	{
		esc_tx_logger *iter=m_open_loggers.at(0);
		iter->close(); // removes itself from the list
	}
}

//------------------------------------------------------------------------------
// Static function that registers the SystemC domain and returns its handle
//------------------------------------------------------------------------------
int esc_hub::register_domain( int is_master )
{
	qbhDomainCallbacks callbacks;
	callbacks.exec		= esc_hub::static_domain_exec_cb;
	callbacks.name		= esc_hub::static_domain_name_cb;
	callbacks.value		= esc_hub::static_domain_value_cb;
	callbacks.schedule	= esc_hub::static_domain_schedule_cb;

	// Register this domain with the HUB:
	qbhError hubErr = qbhRegisterDomain( "SystemC",
										 &callbacks,
										 (is_master ? qbhDomainExecMaster : qbhDomainExecCooperative),
										 this,
										 &m_domain_handle );

	// Register the encoding
	if ( hubErr == qbhOK )
	{
		m_info = new qbhValRecEncodingInfo;
		m_info->p_bitValues = (unsigned char*)"01ZX";
		m_info->v_bvEncoding = qbhBvABVal;
		hubErr = qbhSetValRecEncoding( m_domain_handle, m_info );
	}

	return (hubErr == qbhOK);
}


//------------------------------------------------------------------------------
// Static callback passed to HUB 
//------------------------------------------------------------------------------
qbhError
esc_hub::static_domain_name_cb( qbhDomainHandle			hDomain,
								void*					userData,
								qbhDomainNameActivity	code,
								qbhHandle				inHandle,
								qbhHandle*				outHandle,
								char *					name,
							    qbhNetlistNodeType		kind )
{
	qbhError status = qbhOK;

	try
	{
		// Pass the request to the non-static member function
		// which handles domain callback requests:
		status = ((esc_hub*)userData)->domain_name_cb( hDomain, code, inHandle, outHandle, name, kind );
	}
    catch( const sc_exception& x )
    {
		esc_report_error( esc_fatal, (char*)x.what() );
    }
    catch( const char* s )
    {
		esc_report_error( esc_fatal, (char*)s );
    }
    catch( ... )
    {
		esc_report_error( esc_fatal, "UNKNOWN EXCEPTION OCCURED" );
    }

	return status;
}

qbhError
esc_hub::static_domain_exec_cb(	qbhDomainHandle d,
								void* userData,
								qbhDomainExecActivity code,
								double inTime,
								double* outTime )
{
	qbhError status = qbhOK;

	try
	{
		// Pass the request to the non-static member function
		// which handles domain callback requests:
		status = ((esc_hub*)userData)->domain_exec_cb( d, code, inTime, outTime );
	}
	catch( const sc_exception& x )
    {
		esc_report_error( esc_fatal, (char*)x.what() );
    }
    catch( const char* s )
    {
		esc_report_error( esc_fatal, (char*)s );
    }
    catch( ... )
    {
		esc_report_error( esc_fatal, "UNKNOWN EXCEPTION OCCURED" );
    }

	return status;
}

//------------------------------------------------------------------------------
// Static callback passed to HUB 
//------------------------------------------------------------------------------
qbhError
esc_hub::static_domain_value_cb( qbhDomainHandle		hDomain,
								 void*					userData,
								 qbhDomainNameActivity	code,
								 qbhHandle				inHandle,
								 qbhHandle*				outHandle )
{
	qbhError status = qbhOK;

	try
	{
		// Pass the request to the non-static member function
		// which handles domain callback requests:
		status = ((esc_hub*)userData)->domain_value_cb( hDomain, code, inHandle, outHandle );
	}
	catch( const sc_exception& x )
    {
		esc_report_error( esc_fatal, (char*)x.what() );
    }
    catch( const char* s )
    {
		esc_report_error( esc_fatal, (char*)s );
    }
    catch( ... )
    {
		esc_report_error( esc_fatal, "UNKNOWN EXCEPTION OCCURED" );
    }

	return status;
}

//------------------------------------------------------------------------------
// Static callback passed to HUB 
//------------------------------------------------------------------------------
qbhError
esc_hub::static_domain_schedule_cb(	qbhDomainHandle 		d,
									void* 					userData,
									qbhDomainScheduleActivity	code,
									double					time, // in ps
									qbhEventCallback		callbackFunc,
									void *					callbackData )
{
	qbhError status = qbhOK;

	try
	{
		// Pass the request to the non-static member function
		// which handles domain callback requests:
		status = ((esc_hub*)userData)->domain_schedule_cb( d, code, time, callbackFunc, callbackData );
	}
	catch( const sc_exception& x )
    {
		esc_report_error( esc_fatal, (char*)x.what() );
    }
    catch( const char* s )
    {
		esc_report_error( esc_fatal, (char*)s );
    }
    catch( ... )
    {
		esc_report_error( esc_fatal, "UNKNOWN EXCEPTION OCCURED" );
    }

	return status;
}

    namespace sc_core
    {
        extern void pln(); 
    }

// Called from slave SystemC programs to initialize the Hub connection.
int esc_hub::hubconnect()
{
	esc_init_exceptions();

#if ( ! defined(BDW_COWARE) )
	// Only OSCI SystemC has this function.
	sc_core::pln();
#endif

#ifdef WIN32
	// This is normally done by SC's main(), so we must do it when SC is a slave.
	PVOID mainfiber = ConvertThreadToFiber( NULL );
#endif

	// Register with the Hub as a slave and create an esc_hub object if necessary.
	if ( m_current_p )
	{
		if ( !m_current_p->is_registered() )
			return 0;
		qbhSetExecType( m_current_p->domain(), qbhDomainExecCooperative );
		return 1;
	}
	m_current_p = new esc_hub( 0 );
	return m_current_p->is_registered();
}

// Called from standalone SystemC programs to initialize the Hub as a slave.
int esc_hub::load()
{
	esc_init_exceptions();

	// Register with the Hub as a master and create an esc_hub object if necessary.
	if ( m_current_p )
	{
		if ( !m_current_p->is_registered() )
			return 0;
		qbhSetExecType( m_current_p->domain(), qbhDomainExecMaster );
		return 1;
	}
	m_current_p = new esc_hub( 1 );
	return m_current_p->is_registered();
}

//------------------------------------------------------------------------------
// Handles HUB-generated name requests of the domain.
//------------------------------------------------------------------------------
/*
 * This signature is expected of the callback functions associated
 * with external domains to perform namespace related activities.  
 * It will be called at various times by the HUB as described by the 
 * 'code' field.
 *
 *	qbhDomainNameFindEntity	 :	Finds a signal or a module given the slash-separated
 *								path in the 'name' parameter.  If inHandle is not 
 *								qbhEmptyHandle, it should be taken as a parent handle
 *								and the name as a relative name.
 *
 *	qbhDomainNameNextChild	 :	Traverses the namespace from the position defined
 *								by inHandle and *outHandle as follows:
 *						
 *									inHandle			*outHandle		|	result
 *									--------------------------------------------------------------
 *									qbhEmptyHandle		qbhEmptyHandle	|	root module
 *									module				qbhEmptyHandle	|	first child of module
 *									module				sibling			|	next sibling in module
 *									qbhEmptyHandle		sibling			|	next top-level sibling
 *
 *								The result should be returned in *outHandle.
 *								If the iteration should stop, qbhEmptyHandle should
 *								be returned.
 *
 *  qbhDomainNameParent		 :  Returns the parent of inHandle in *outHandle
 *
 *	qbhDomainNameGetInfo	 :	Gives information about the entity whose handle is
 *								given in the inHandle parameter.  The *outHandle
 *								parameter is returned filled with a pointer to 
 *								a qbhEntityInfo struct.  The memory of that struct
 *								is owned by the domain.
 *	
 */
qbhError
esc_hub::domain_name_cb( qbhDomainHandle		hDomain,
						 qbhDomainNameActivity	code,
						 qbhHandle				inHandle,
						 qbhHandle*				outHandle,
						 char *					name,
					     qbhNetlistNodeType		kind )
{
	qbhError status = qbhOK;

	switch( code )
	{
	case qbhDomainNameFindEntity:
		{
			*outHandle = qbhEmptyHandle;

			// if no parent is specified
			if ( inHandle == qbhEmptyHandle )
				*outHandle = (qbhHandle)SC_FIND_OBJECT(name);
			else
			{
				sc_object *parent = (sc_object*)inHandle;

				// name should be parentName/name
				const char *pName = parent->name();
				char *buf = (char*)malloc(strlen(pName)+strlen(name)+2);
				sprintf(buf,"%s/%s",pName,name);

				*outHandle = (qbhHandle)SC_FIND_OBJECT(buf);

				free(buf);
			}

			// Filter for kind if one is given.
			if ( ( kind != qbhNetlistUnknown ) && ( *outHandle != qbhEmptyHandle ) && ( *outHandle != 0 )  )
			{
				qbhEntityInfo info;
				domain_name_cb( hDomain, qbhDomainNameGetInfo, *outHandle, (qbhHandle*)&info, NULL, qbhNetlistUnknown );
				if ( info.kind != kind )
					*outHandle = qbhEmptyHandle;
			}

			if ( *outHandle == qbhEmptyHandle || *outHandle == 0 )
				status = qbhErrorNotFound;
		}
		break;
	case qbhDomainNameNextChild:
		{
			// return the root node
			if ( inHandle == qbhEmptyHandle && *outHandle == qbhEmptyHandle )
			{
				*outHandle = (qbhHandle)sc_get_curr_simcontext()->first_object();
			}
			// first child of node
			else if ( inHandle != qbhEmptyHandle && *outHandle == qbhEmptyHandle )
			{
#if (SYSTEMC_VERSION >= 20070314)
				// In SystemC 2.2, get_child_objects() has been deprecated.
				*outHandle = qbhEmptyHandle;
#else
				sc_object *parent = (sc_object*)inHandle;
				sc_module *module = dynamic_cast< sc_module* >(parent);

				if ( module && module->get_child_objects().size() > 0 )
					*outHandle = (qbhHandle)module->get_child_objects()[0];
				else
					*outHandle = qbhEmptyHandle;
#endif
			}
			// next sibling of node
			else if ( inHandle != qbhEmptyHandle && *outHandle != qbhEmptyHandle )
			{
#if (SYSTEMC_VERSION >= 20070314)
				// In SystemC 2.2, get_child_objects() has been deprecated.
				*outHandle = qbhEmptyHandle;
#else
				sc_object *sibling = (sc_object*)*outHandle;
				*outHandle = qbhEmptyHandle;

				sc_object *parent = (sc_object*)inHandle;
				sc_module *module = dynamic_cast< sc_module* >(parent);

				if ( module )
				{
				    sc_object** end_pp = (sc_object**)&(module->get_child_objects()[module->get_child_objects().size()]);
					for( sc_object **iter = (sc_object**)&module->get_child_objects()[0]; 
						 *outHandle == qbhEmptyHandle && iter!= end_pp;
						 iter++ )
					{
						if ( *iter == sibling && iter+1 != end_pp )
							*outHandle = (qbhHandle)*(iter+1);
					}
				}
#endif
			}
			// next top-level sibling
			else if ( inHandle == qbhEmptyHandle && *outHandle != qbhEmptyHandle )
			{
				sc_object *sibling = (sc_object*)*outHandle;

				sc_object *iter = sc_get_curr_simcontext()->first_object();

				// brutal, but the only option provided by sc_object_manager
				while ( iter && iter != sibling )
					iter = sc_get_curr_simcontext()->next_object();

				iter = sc_get_curr_simcontext()->next_object();

				// Look for the next node that contains no separators (and therefore is a topmost-node
				while ( iter && strchr((char*)iter->name(),'.') )
					iter = sc_get_curr_simcontext()->next_object();
					
				*outHandle = iter ? (qbhHandle)iter : qbhEmptyHandle;
			}

			// Filter for kind if one is given.
			if ( ( kind != qbhNetlistUnknown ) && ( *outHandle != qbhEmptyHandle ) )
			{
				qbhEntityInfo info;				
				domain_name_cb( hDomain, qbhDomainNameGetInfo, qbhEmptyHandle, (qbhHandle*)&info, NULL, qbhNetlistUnknown );
				if ( info.kind != kind )
					*outHandle = qbhEmptyHandle;
			}

			if ( *outHandle == qbhEmptyHandle )
				status = qbhErrorNotFound;
		}
		break;
	case qbhDomainNameParent:
		{
			sc_object *obj = (sc_object*)inHandle;

			*outHandle = qbhEmptyHandle;

			char *buf=strdup(obj->name());

			char *iter = strrchr(buf,'.');

			if ( iter )
			{
				*iter = '\0';
				*outHandle = (qbhHandle)SC_FIND_OBJECT(buf);
			}

			free(buf);

			status = qbhOK;
		}
		break;
	case qbhDomainNameGetInfo:
		{
			if ( inHandle == qbhEmptyHandle )
			{
				*outHandle = qbhEmptyHandle;
				status = qbhErrorNoValue;
			}
			else
			{
				// don't make copies of char*'s, it's understood that the domain owns the info
				qbhEntityInfo *info = new qbhEntityInfo;

				sc_object *obj = (sc_object*)inHandle;
				
				qbhHandle par = qbhEmptyHandle;

				domain_name_cb( hDomain, qbhDomainNameParent, inHandle, &par, NULL, qbhNetlistUnknown );
				char *parentName=(char*)"";
				if ( par != qbhEmptyHandle )
				{
					sc_object *pobj = (sc_object*)par;
					parentName = (char*)pobj->name();
				}

				// advance past the parent's full name, and the separator if there is one
				int advance=strlen(parentName);
				if ( advance )
					advance++;

				info->name		= (char*)(obj->name()+advance);
				info->modName	= parentName;
				if ( !strcmp(obj->kind(),"sc_module") )
				{
					info->kind	= qbhNetlistModule;
					info->type	= qbhEmptyHandle;
				}
				else if ( !strcmp(obj->kind(),"sc_signal") )
				{
					info->kind	= qbhNetlistSignal;

					esc_type_params *params = new esc_type_params;
					params->info = info;
					esc_type_handler::determine_type( (sc_object*)obj, esc_type, (void*)params );
					delete params;

					// make sure it worked
					assert( info->type && info->type != qbhEmptyHandle );
				}
				else if ( !strcmp(obj->kind(),"sc_clock") )
				{
					info->kind	= qbhNetlistSignal;
					info->type	= HubGetType( (bool*)NULL ); // is this correct?
				}
				else if ( !strcmp(obj->kind(),"esc_chan") )
				{
					info->kind	= qbhNetlistChannel;
					info->type	= qbhEmptyHandle; // can't easily tell b/c would need to be able to cast to esc_chan<T>
				}
				else
				{
					info->kind	= qbhNetlistUnknown;
					info->type = qbhEmptyHandle;
				}

				qbhEntityInfo *inInfo = (qbhEntityInfo*)outHandle;

				*inInfo = *info;
			}
		}
		break;
	case qbhDomainNameAddWatcher:
		{
			// obj must be an esc_watchable<> with a datatype that has been registered
			void *obj = (inHandle==qbhEmptyHandle) ? NULL : (void*)inHandle;

			int success = 1;

			// Do a find, if it can't be found, don't do the next steps
			//if ( success )
			//	success = ( SC_FIND_OBJECT( name ) != 0 );

			// This will determine the datatype that esc_watchable<> is templated on,
			//  and create an esc_hub_watcher for it.
			if ( success )
				success = esc_type_handler::determine_type( (sc_object*)obj, esc_watch, name );

			if ( ! success )
				status = qbhErrorGeneric;
		}
		break;
	default:
		{
			status = qbhErrorGeneric;
		}
		break;
	}

	return status;
}

/* 
 * This signature is expected of the callback functions associated
 * with external domains to perform value related activities.  
 * It will be called at various times by the HUB as described by the 
 * 'code' field.
 *
 *	qbhDomainValueGet		:	The current value of the signal whose handle is
 *								in inHandle will be returned in *outHandle.
 *								If *outHandle is qbhEmptyHandle, the callee should
 *								create a new handle and expect the caller to delete it.
 *								Otherwise, the callee should fill in the value in
 *								*outHandle.
 *
 *	qbhDomainValueSet		:	Sets the value of the signal whose handle
 *								is given in inHandle.  The value is given by
 *								*outHandle.
 *	
 */
qbhError
esc_hub::domain_value_cb( qbhDomainHandle		hDomain,
						  qbhDomainNameActivity	code,
						  qbhHandle				inHandle,
						  qbhHandle*			outHandle )
{
	qbhError status = qbhOK;
	switch( code )
	{
	case qbhDomainValueGet:
		{

		}
		break;
	case qbhDomainValueSet:
		{
			// For right now, tread inHandle as an sc_object*
			sc_object* obj = (sc_object*)inHandle;

			// if it's an sc_signal
			if ( !strcmp( obj->kind(), "sc_signal") )
			{
				
			}
		}
		break;
	default:
		{
			status = qbhErrorGeneric;
		}
		break;
	}

	return status;
}

//------------------------------------------------------------------------------
// Runs the SystemC simulator until quiet without advancing time.
// The API for doing this is version-dependent, so there are ifdef's 
// in this function.
//------------------------------------------------------------------------------
void
esc_hub::exec_sc_now()
{
	if (ESC_SIM_STOPPED)
		return;

#if ( defined(BDW_COWARE) || defined(SC_API_VERSION_STRING) ) 
#if (SYSTEMC_VERSION >= 20070314)
	// SystemC 2.2
	do {
	    sc_start(SC_ZERO_TIME);
	} while ( sc_pending_activity_at_current_time() && !ESC_SIM_STOPPED);
#else
	// SystemC 2.1 and 2.1v1
	sc_start(sc_time(0ULL,true));
#endif
#else
	// SystemC 2.0.1
	sc_cycle(0, SC_PS);
#endif
}

//------------------------------------------------------------------------------
// Handles HUB-generated exec requests of the domain.
//------------------------------------------------------------------------------
qbhError
esc_hub::domain_exec_cb( qbhDomainHandle d,
						 qbhDomainExecActivity code,
						 double inTime,			// in ps
						 double* outTime )		// in ps
{
	switch( code )
	{
		case qbhDomainExecStart	:	
			//fprintf(stderr,"\tqbhDomainExecStart\n");
			if ( !esc_elaboration_errors ) 
			{
#if defined(SC_API_VERSION_STRING)
				sc_start(sc_time(0ULL,true));
#else
				sc_initialize();
#endif
			}
			break;
		case qbhDomainExecRestart:	
			//fprintf(stderr,"\tqbhDomainExecRestart\n");
			break;
		case qbhDomainExecDone	:	
			//fprintf(stderr,"\tqbhDomainExecDone\n");
			qbhUnregisterDomain( d );
			break;

		case qbhDomainExecNow	:
		{
			//fprintf(stderr,"\tqbhDomainExecNow\n");

			if ( inTime == 0 && !m_inited )
				init();

			if ( !esc_elaboration_errors ) 
			{
			  // Execute all activity at current time.  
			  exec_sc_now();
			} else {
			  esc_stop();
			}
			break;
		}			
		case qbhDomainExecToTime:	
		{
			//fprintf(stderr,"\tqbhDomainExecToTime\n");

			if ( inTime == 0 && !m_inited )
				init();

			// Tell it to run for some period of time
			sc_time runTo(inTime,SC_PS);
			sc_time delta = runTo - sc_time_stamp();

			// If delta isn't greater than the minimum time resolution, don't try running
			if ( delta >= sc_get_time_resolution() )
			{
				if (   !ESC_SIM_STOPPED
				    && !esc_elaboration_errors ) 
				{
				  sc_start(delta);	// must be used in place of sc_cycle(delta) b/c m_timed_events gets used
				  exec_sc_now();
				} else {
				  esc_stop();
				}
			}

			break;
		}

		case qbhDomainCurrentTime:	
		{
			if ( outTime )
				*outTime = esc_normalize_to_ps(sc_time_stamp());

			break;
		}
		default:
		{
			return qbhErrorGeneric;

			break;
		}
	}
	
	return qbhOK;
}

//------------------------------------------------------------------------------
// Handles HUB-generated requests of the domain.
//------------------------------------------------------------------------------

/* 
 * This signature is expected of the callback functions associated
 * with external domains to perform activities related to event scheduling.  
 * It will be called at various times by the HUB as described by the 
 * 'code' field.
 * When the scheduled event occurs, the callee calls qbhEventOccurred().
 *
 *	qbhDomainScheduleOnChange		:	Schedules a callback when the signal
 *										given in 'handle' changes value.
 *										The callbackId value will be provided to qbhEventOccurred().
 *										This callback will repeat on each change until cancelled.
 *		
 *	qbhDomainScheduleAfterTime		:	Schedules a callback when the amount of
 *										time stored in the time value handle in the
 *										'handle' parameter has expired.  The
 *										time value has units of pico-seconds.
 *										The callbackId value will be provided to qbhEventOccurred().
 *										This is a one-shot event.
 *
 *	qbhDomainScheduleCancel			:	Cancels the callback identified by the given callbackId.
 */

qbhError
esc_hub::domain_schedule_cb( qbhDomainHandle 		d,
							 qbhDomainScheduleActivity	code,
							 double					time,        // this time is relative, and in ps
							 qbhEventCallback		callbackFunc,
							 void *					callbackData )
{
	
	switch ( code )
	{
	case qbhDomainScheduleOnChange		:
		break;
		
	case qbhDomainScheduleAfterTime		:
		{	
			// Modify the callback list, or start one if it doesn't already exist
			esc_cb_elem *sce = new esc_cb_elem( callbackFunc, callbackData );
			add( sce, time + esc_normalize_to_ps(sc_time_stamp()) );

			// If the new entry in the callback list is the first one, trigger the interrupt event
			if ( m_cb_list && m_cb_list->m_cb_elem == sce && sce->m_next == NULL )
				m_interrupt_event.notify();
		}
		break;
		
	case qbhDomainScheduleCancel			:
		break;
	default									:
		break;
	}

	return qbhOK;
}

void esc_hub::add( esc_cb_elem *elem, double timePS )
{
	// If the list doesn't exist yet
	if ( ! m_cb_list )
	{
		m_cb_list = new esc_timed_cb_elem( timePS, elem );
	}
	// or the new time is before the first element
	else if ( timePS < m_cb_list->m_time )
	{
		esc_timed_cb_elem *tce = new esc_timed_cb_elem( timePS, elem );
		tce->m_next = m_cb_list;
		m_cb_list = tce;
	}
	// or at the same time as the first element
	else if ( timePS == m_cb_list->m_time )
	{
		elem->m_next = m_cb_list->m_cb_elem;
		m_cb_list->m_cb_elem = elem->m_next;
	}
	else
	{
		esc_timed_cb_elem *iter = m_cb_list;
		
		while( iter->m_next )
		{
			if ( timePS < iter->m_next->m_time )
			{
				esc_timed_cb_elem *tce = new esc_timed_cb_elem( timePS, elem );
				tce->m_next = iter->m_next;
				iter->m_next = tce;
				break;
			}
			else if ( timePS == iter->m_next->m_time )
			{
				elem->m_next = iter->m_next->m_cb_elem;
				iter->m_next->m_cb_elem = elem->m_next;
				break;
			}
		}
		// If the element should go at the end
		if ( ! iter->m_next )
		{
			esc_timed_cb_elem *tce = new esc_timed_cb_elem( timePS, elem );
			iter->m_next = tce;
		}
	}
}

void esc_hub::init()
{
	if ( !esc_elaboration_errors ) 
	{
#if defined(SC_API_VERSION_STRING)
		sc_start(sc_time(0ULL,true));
#else
		sc_initialize();
#endif
		esc_signal_hub_master_base::initialize_hub_masters();

		m_inited = 1;
		m_init_event.notify();
	}
}

int esc_hub::rand()
{
	if ( esc_hub::m_ran_gen == NULL )
	{
		static esc_ran_dist_uniform ud;
		esc_hub::m_ran_gen = new esc_ran_gen< int >( ud, ESC_RAN_SEED );
	}

	return esc_hub::m_ran_gen->generate();
}

void esc_hub::srand( unsigned seed )
{
	if ( esc_hub::m_ran_gen == NULL )
	{
		delete esc_hub::m_ran_gen;
	}

	esc_ran_dist_uniform ud;
	esc_hub::m_ran_gen = new esc_ran_gen< int >( ud, seed );
}

int esc_rand( void )
{
	return esc_hub::rand();
}

void esc_srand( unsigned int seed )
{
	esc_hub::srand( seed );
}

int esc_connect()
{
	return esc_hub::hubconnect();
}

int esc_load()
{
	return esc_hub::load();
}

int esc_start()
{
	return esc_hub::start();
}

void esc_finish_log()
{
	if ( esc_sim_log::cur_sim_log == NULL )
		return;

	time_t t = time( NULL );
	char *timeBuf = ctime( &t );

	char *c = strrchr( timeBuf, '\n' );
	if ( *c )
		*c = 0;

	esc_log_setting( "end_time", timeBuf );

	esc_close_log();
}

static bool esc_start_log_noparse(int argc, char *argv[])
{
	bool retval = esc_open_log();
	if ( ! retval )
		return false;

	char pathBuf[PATH_MAX];
	getcwd( pathBuf, PATH_MAX );

	struct utsname utsBuf;
	uname( &utsBuf );

#if __GNUC__ < 3
	ostrstream unameStr;
#else
	ostringstream unameStr;
#endif
	unameStr << utsBuf.sysname << ' ' << utsBuf.release << ' '
			 << utsBuf.machine << ends;
#if __GNUC__ < 3
	char *uname = unameStr.str();
#else
	char *uname = (char *) strdup( unameStr.str().c_str() );
#endif

	esc_log_setting( "tool_kind", "LogicSimulator" );

	const char *simName = qbhSimulatorName();
	if ( simName == NULL )
	{
#if defined(BDW_COWARE)
		simName = "Convergen-SC";
#else
#if defined(BDW_VISTA)
		simName = "Vista";
#else
		simName = "OSCI";
#endif
#endif
		esc_log_setting( "tool_name", simName );
	}
	else
	{
		esc_log_setting( "tool_name", simName );
	}

	esc_log_setting( "hostname", utsBuf.nodename );
	esc_log_setting( "uname", uname );
	esc_log_setting( "cwd", pathBuf );
	esc_log_setting( "user", getenv( "USER" ) );

	time_t t = time( NULL );
	char *timeBuf = ctime( &t );

	char *c = strrchr( timeBuf, '\n' );
	if ( *c )
		*c = 0;

	esc_log_setting( "gen_time", timeBuf );
	
#if __GNUC__ < 3
	delete[] uname;
#else
	free( uname );
#endif
	// INCOMPLETE: We don't have an API for getting the simulator version.

	atexit( esc_finish_log );

	return true;
}

bool esc_start_log()
{
	return esc_start_log_noparse( esc_argc(), (char **)esc_argv() );
}

int esc_initialize()
{
#ifndef BDW_COWARE
	int retval = esc_load();
	if ( retval )
		retval = esc_start();

	return retval;
#else
	esc_init_exceptions();
	return 1;
#endif
}

int esc_initialize( int argc, char* argv[] )
{
#ifndef BDW_COWARE
	int retval = esc_load();
	if ( retval )
	{
		qbhParseCmdLine( argc, argv );

		retval = esc_start_log_noparse( esc_argc(), (char **)esc_argv() );
		retval = retval && esc_start();
	}

	return retval;
#else
	qbhParseCmdLine( argc, argv );
	esc_init_exceptions();
	return esc_start_log_noparse( esc_argc(), (char **)esc_argv() );
#endif
}

sc_event &esc_init_event()
{
	return esc_hub::current()->init_event();
}

int esc_end_cosim()
{
	return ( qbhEndCosim() == qbhOK );
}

#if ( defined( BDW_VISTA ) )
extern "C" void v2_before_elaboration();
#endif

extern "C" HUBEXPORT void hub_libdef_default_callback( qbhLibraryCallbackReason cbr )
	{
	switch( cbr )
	{
	case qbhLoadTime :
		{
			esc_connect();
		}
		break;	
	case qbhElabTime :
		{
			esc_start_log();
#if ( defined( BDW_VISTA ) )
			const char *active =  getenv("V2_SIMULATION_ACTIVE");

			if (active && *active && (*active != '0'))
			{
				v2_before_elaboration();
			}
#endif
			try
			{
				esc_elaborate();
			}
			catch( const sc_exception& x )
			{
				esc_report_error( esc_fatal, (char*)x.what() );
				esc_elaboration_errors = true;
				sc_stop();
				break;
			}
			catch( const char* s )
			{
				esc_report_error( esc_fatal, (char*)s );
				esc_elaboration_errors = true;
				sc_stop();
				break;
			}
			catch( ... )
			{
				esc_report_error( esc_fatal, "UNKNOWN EXCEPTION OCCURED" );
				esc_elaboration_errors = true;
				sc_stop();
				break;
			}

		}
		break;
	case qbhUnloadTime :
		{
			esc_cleanup();
			esc_finish_log();
			esc_close_open_loggers();
		}
		break;
	case qbhExecStartTime :
		{
			//sc_initialize();
		}
		break;
	case qbhExecDoneTime :
		{
		}
		break;
	case qbhExecRestartTime :
		{
		}
		break;
	}
}

const char *esc_get_hub_define( const char *define_name )
{
	static char buf[1024];
	if ( qbhOK == qbhGetDefine( define_name, buf, sizeof(buf) ) )
		return buf;
	else
		return 0;
}

void esc_stop()
{
	// Prevent more than one call to stop things.
	static bool been_called = false;
	if ( been_called )
		return;
	been_called = true;
#ifndef BDW_COWARE
	if ( esc_is_slave() )
		esc_end_cosim();
	else
#endif
		sc_stop();
}

// Cause an exception to be thrown to initialize the 
// exception handling subsystem.  This prevents stack overflows
// that can occur if an exception occurs on a QT stack.
int esc_init_exceptions()
{
	int result = 1;
	try
	{
		throw 0;
	}
	catch (int i) {}
	return result;
}


//
// class esc_sim_log
//

esc_sim_log::esc_sim_log( const char* path) : m_simLog(qbhEmptyHandle)
{
	p_path = path ? strdup( path ) : 0;
}

esc_sim_log::~esc_sim_log()
{
	qbhCloseSimLog( m_simLog );
	free( p_path );
}

void esc_sim_log::close()
{
	qbhCloseSimLog( m_simLog );
	m_simLog = qbhEmptyHandle;
}


bool esc_sim_log::open()
{
	if ( m_simLog != qbhEmptyHandle )
		return false;

	qbhError result = qbhOpenSimLog( p_path, &m_simLog );

	return result == qbhOK;
}

bool esc_sim_log::log_message_no_varargs(  const char *moduleName, int conditionCode,
										   const char *buf )
{
	qbhError result = qbhLogMessage( &m_simLog, conditionCode, moduleName, buf);

	return result == qbhOK;
}

bool esc_sim_log::log_message(  const char *moduleName, int conditionCode,
								const char *formatStr, ... )
{
	char *buf = (char*)malloc(ERR_BUFF_SIZE);
	va_list ap;
	va_start( ap, formatStr );
	vsprintf( buf, formatStr, ap );
	va_end( ap );

	bool result = log_message_no_varargs( moduleName, conditionCode, buf );

	free( buf );
	return result;
}

bool esc_sim_log::log_pass()
{
	qbhError result = qbhLogPass( &m_simLog );
	return result == qbhOK;
}

bool esc_sim_log::log_fail()
{
	qbhError result = qbhLogFail( &m_simLog );
	return result == qbhOK;
}

bool esc_sim_log::log_setting(const char *name, const char *value )
{
	qbhError result = qbhLogSetting( &m_simLog, name, value );
	return result == qbhOK;
}

bool esc_sim_log::log_latency( const char* module, unsigned long latency,
							   const char* label)
{
	// -1 tells it not to log.
	qbhError result = qbhLogLatency( &m_simLog, module,
									 -1, -1, (double)latency, label );
	return result == qbhOK;
}

bool esc_sim_log::log_latency( const char* module, unsigned long min_latency,
							   unsigned long max_latency, double mean_latency,
							   const char* label)
{
	qbhError result = qbhLogLatency( &m_simLog, module,
									 min_latency, max_latency, mean_latency, label );
	return result == qbhOK;
}

bool esc_sim_log::log_representation( const char* module,
									  const char* instance_path,
									  int representation )
{
	qbhError result = qbhLogRepresentation( &m_simLog, module,
											instance_path, representation );
	return result == qbhOK;
}

//
// logging functions
//
bool esc_open_log( const char *path)
{
	if ( esc_sim_log::cur_sim_log != NULL )
	{
		esc_sim_log::cur_sim_log->close();
		delete esc_sim_log::cur_sim_log;
	}

	esc_sim_log::cur_sim_log = new esc_sim_log( path );
	return esc_sim_log::cur_sim_log->open();
}

void esc_close_log()
{
	if ( esc_sim_log::cur_sim_log != NULL )
	{
		esc_sim_log::cur_sim_log->close();
		delete esc_sim_log::cur_sim_log;
		esc_sim_log::cur_sim_log = NULL;
	}
}

void esc_report_log_not_open()
{
	static bool suggested_init = false;

	if ( esc_hub::has_domain() || suggested_init )
		esc_report_error( esc_error, "Simulation log not open" );
	else
	{
		esc_report_error( esc_error, "Simulation log not open. Did you remember to call esc_initialize()?" );
		suggested_init = true;
	}
}

bool esc_log_message( const char *moduleName, int conditionCode,
					  const char *formatStr, ... )
{
	if ( esc_sim_log::cur_sim_log != NULL )
	{
		char *buf = (char*)malloc(ERR_BUFF_SIZE);
		va_list ap;
		va_start( ap, formatStr );
		vsprintf( buf, formatStr, ap );
		va_end( ap );

		bool result = esc_sim_log::cur_sim_log->log_message_no_varargs( moduleName,
																		conditionCode,
																		buf );

		free( buf );
		return result;
	}
	else
	{
		return false;
	}
}

bool esc_log_setting( const char *name, const char *value )
{
	if ( esc_sim_log::cur_sim_log != NULL )
		return esc_sim_log::cur_sim_log->log_setting( name, value );
	else
	{
		esc_report_log_not_open();
		return false;
	}
}

bool esc_log_pass()
{
	if ( esc_sim_log::cur_sim_log != NULL )
		return esc_sim_log::cur_sim_log->log_pass();
	else
	{
		esc_report_log_not_open();
		return false;
	}
}

bool esc_log_fail()
{
	if ( esc_sim_log::cur_sim_log != NULL )
		return esc_sim_log::cur_sim_log->log_fail();
	else
	{
		esc_report_log_not_open();
		return false;
	}
}

bool esc_log_latency( const char* module, unsigned long latency, const char* label)
{
	if ( esc_sim_log::cur_sim_log != NULL )
		return esc_sim_log::cur_sim_log->log_latency( module, latency, label );
	else
	{
		esc_report_log_not_open();
		return false;
	}
}

bool esc_log_latency( const char* module, unsigned long min_latency,
				  unsigned long max_latency, double mean_latency,
				  const char* label)
{
	if ( esc_sim_log::cur_sim_log != NULL )
		return esc_sim_log::cur_sim_log->log_latency( module, min_latency, max_latency,
													  mean_latency, label );
	else
	{
		esc_report_log_not_open();
		return false;
	}
}

bool esc_log_representation( const char* module,
							 const char* instance_path,
							 int representation )
{
	if ( esc_sim_log::cur_sim_log != NULL )
		return esc_sim_log::cur_sim_log->log_representation( module,
															 instance_path,
															 representation );
	else
	{
		esc_report_log_not_open();
		return false;
	}
}


//
// Define a string that BDW_VERSIONS can grep for.
const char* esc_systemc_version = "esc_systemc_version_" esc_xstr(SYSTEMC_VERSION);

bool esc_elaboration_errors = false;

//
// Create a module that will be instantiated if libesc.a is linked in at all.
// This module is used to verify that a wrapper was instantiated for each module
// in the current simConfig.
//
SC_MODULE(bdw_wrapper_checker)
{
	SC_HAS_PROCESS(bdw_wrapper_checker);
	bdw_wrapper_checker( sc_module_name name=sc_module_name("bdw_wrapper_checker") )
		: sc_module(name)
	{
	}

	~bdw_wrapper_checker()
	{
		for ( esc_vector<char*>::iterator it = m_wrappers.begin();  it != m_wrappers.end(); it++ ) 
			delete *it;
	}

	void end_of_elaboration()
	{
		// If we've already detected a missing esc_elaborate(),
		// don't issue what could be misleading messages about missing wrappers.
		if (esc_elaboration_errors)
			return;

		const char *projPath = getenv("BDW_PROJECT_FILE");
		const char* simConfig = getenv("BDW_SIM_CONFIG");
		if (projPath && simConfig) {
			char** names;
			qbhError err = qbhGetCynthModuleNames( projPath, simConfig, &names, true );
			if ( err == qbhOK )
			{
				char** name = names;
				while ( *name ) {
					bool found = false;
					for ( esc_vector<char*>::iterator it = m_wrappers.begin();  !found && (it != m_wrappers.end()); it++ ) 
					{
						found = (0 == strcmp( *it, *name ));
					}

					if (!found)
					{
						esc_report_error( esc_warning, 
											"\n#############################################################################\n"
											"WARNING: No wrapper modules for cynthModule '%s' have been instantiated.\n"
											"         Did you instantiate '%s' directly instead of using '%s_wrapper'?\n%s"
											"#############################################################################\n",
											*name, *name, *name, 
											esc_is_slave() ? 
											"         Did you instantiate your design directly in sc_main() rather than in esc_elaborate() ?\n%" : "" );
					}
					delete *name++;
				}
				delete names;
			}
		}
	}
	esc_vector<char*> m_wrappers;

	void log_wrapper_inst( const char* modName )
	{
		if (!modName || !*modName)
			return;

		esc_vector<char*>::iterator it;
		for ( it = m_wrappers.begin();  it != m_wrappers.end(); it++ ) 
		{
			if ( 0 == strcmp( modName, *it ) )
				return;
		}
		m_wrappers.push_back( strdup(modName) );
	}
};

static bdw_wrapper_checker m_bdw_wrapper_checker("bdw_wrapper_checker");

void esc_log_wrapper_inst( const char* modName ) 
{
	m_bdw_wrapper_checker.log_wrapper_inst( modName );
}

#ifdef NC_SYSTEMC
// Define a default top level module to be used with ncsim
SC_MODULE(scTop)
{
    SC_CTOR(scTop) {
        esc_elaborate();
    };
    ~scTop() {
        esc_cleanup();
    };
};

NCSC_MODULE_EXPORT(scTop);

#endif

