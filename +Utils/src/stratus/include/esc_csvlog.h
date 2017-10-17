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

#ifndef ESC_CSVLOG_HEADER_GUARD__
#define ESC_CSVLOG_HEADER_GUARD__

/*!
  \file esc_csvlog.h
  \brief Classes supporting CSV logging for SystemC
*/

#if BDW_HUB

#if __GNUC__ < 3
#include <stdio.h>
#else
#include <iostream>
#endif

#define CSV_BLOCK_SIZE (1024 * 64) // same size as a tdb block

class esc_csv_logger;

template <class T>
class esc_csv_log_watcher : public esc_log_watcher<T>
{
  public:
	esc_csv_log_watcher( esc_watchable<T> *target, esc_tx_logger *logger )
		: esc_log_watcher<T>( target, logger )
	{
		m_event_buf = new char[CSV_BLOCK_SIZE];
	} 

	~esc_csv_log_watcher()
		{
			delete m_event_buf;
			m_event_buf = NULL;
		}


	void watch_notify( esc_event_type flag, const T* value, esc_handle handle=esc_empty_handle );
  protected:
	char * m_event_buf;

	/*!	\internal
	 *	\brief Sets the Hub's current time and prepares the m_event_buffer for encoding.
	 *  \return Zero on error.
	 */
	inline int setup_event_buf()
	{
		// Update the Hub's record of our current time in case we're not
		// co-simulating.  This time will be used as the detect time of
		// the transaction written to the database.

		// Prepare a buffer.
		m_event_buf[0] = '\0'; // clear out the string that was there before

		return 1;
	}
	/*!	\internal
	 *	\brief Commits the event buffer using the class's feedback time and stored start time.
	 *		
	 */
	inline void write_event_buf()
	{
		//fprintf( ((esc_csv_logger*)(this->m_logger_p))->csv_handle(),m_event_buf);

		this->m_started = 0;
	}
};

template <class T>
void esc_csv_log_watcher<T>::watch_notify( esc_event_type flag, const T* value, esc_handle handle )
{
	if ( !this->m_started && (flag & this->m_start) )
	{
		this->m_start_time = sc_time( esc_normalize_to_ps( sc_time_stamp() ), SC_PS );

		if ( handle != esc_empty_handle )
		{
			// constructor converts times to ps
			time_handle *t = new time_handle(handle, sc_time_stamp() );
			this->m_start_times.push_back(t);
		}

		this->m_started = 1;
	}
	if ( this->m_started && (flag & this->m_end) )
	{
		this->m_start_time = this->startTimeForHandle( handle );

		if ( setup_event_buf() )
		{
			HubEncodeCsv( (T*)value, m_event_buf );
			write_event_buf();
		}
	}
}

template <class T>
inline esc_csv_log_watcher<T> *esc_csv_allocate_watcher( esc_watchable<T>* target, esc_csv_logger *logger )
{
	return new esc_csv_log_watcher<T>( target, logger );
}

class esc_csv_logger : public esc_tx_logger
{
  public:
	esc_csv_logger( const char *filename=NULL ) : m_csv_h(NULL)
	{
		if ( filename )
			open( filename );
	}
	virtual ~esc_csv_logger()
	{
		close();
	}
	//! Closes the CSV file if it's open.
	//! All data that has been written to the logger will be written to the 
	//! underlying CSV file.
    void close()
	{
		off();
		esc_tx_logger::close();
		if ( m_csv_h == NULL )
			return;

		fclose( m_csv_h );

		m_csv_h = NULL;
	}

	//! Opens a CSV file for write at the given pathname.  
	//! The file is truncated if it exists and created if it does not exist.
    bool open( const char* fname )
	{
		m_csv_h = fopen( fname, "w" );

		if ( is_open() )
		{
			on();
			esc_tx_logger::open(fname);
			return true;
		}
		else
			return false;
	}

    bool is_open() const
	{
		return (m_csv_h != NULL);
	}

	/*!
	 * \brief	Adds a logged entity to the logger by reference.
	 *			The template parameter is the type of the data being logged.
	 *			This templated function must be implemented in derived classes
	 *			of esc_tx_logger so that a type-specific esc_log_watcher<T>
	 *			can be allocated for the object being logged.
	 *
	 * \param target	The item to be logged.  
	 * \return	Returns non-zero if the object was successfully added for logging
	 *			and 0 if it was not.
	 */
    template <class T> int add( esc_watchable<T>* target )
	{
		if ( !target->target() ) 
		{
			esc_report_error( esc_error, "Attempt to add esc_watchable<T>* with no target sc_object* to esc_csv_logger" );
			return 0;								
		}
		esc_csv_log_watcher<T> *watcher = esc_csv_allocate_watcher( target, this );
		esc_tx_logger::add( watcher );
		return 1;
	}

    template <class T> 
	int add( sc_signal<T>* target )
	{
		esc_report_error( esc_error, "esc_tx_logger cannot log sc_signals" );
		return 0;
	}

	/*!
	 * \brief	Adds an item to be logged by name
	 *
	 * \return	Returns non-zero if the object was successfully added for logging
	 *			and 0 if it was not.
	 *
	 *	The name given found in the SystemC module hierarchy.  The object
	 *	must be found, and the object must be derived from sc_watchable<T>.
	 */
    template <class T> int add( T* sample_p, const char* name_p )
	{
		// When implemented, this function will find an sc_watchable_base by
		// name, and cast it to sc_watchable<T> before adding it.  The 
		// caller will have to call the function like this:
		//	logger.add<mytype>( "a.b.c" );
	    sc_object *obj = sc_get_curr_simcontext()->find_object( name_p );
		if ( !obj )
			return 0;
		esc_watchable<T> *watchable_obj = 0;
		if ( esc_watchable_for( obj, &watchable_obj ) )
			return add( watchable_obj );
		else
			return 0;
	}

	/*!
	  \brief Adds an item to be logged by name
	  \return Returns non-zero if the object was successfully added for logging.

	  The name given found in the SystemC module hierarchy.  The object
	  must be found, and the object must be derived from sc_watchable<T>.
	*/
	int add( const char* name_p )
	{
	    sc_object *obj = sc_get_curr_simcontext()->find_object( name_p );
		if ( !obj )
			return 0;
		return add_object( obj );
	}

	/*!
	  \brief Specifies an sc_object to be logged.
	  
	  The given sc_object must have a derived class that has been registered
	  as a watchable with ESC.  If you have direct access to an esc_watchable
	  object, the add( esc_watchable<T>* ) function should be used instead.

	  \return Returns non-zero if the object was successfully added for logging.
	*/
	int add_object( sc_object* obj )
	{
		int retval = esc_type_handler::determine_type(obj,esc_log,(void*)this);

		if ( retval == 0 )
			esc_report_error( esc_error, "Unable to add '%s' to esc_tdb_logger - datatype may be unregistered.\n",obj->name() );

		return retval;
	}


	//! Gives the handle to the open CSV file.
	FILE *csv_handle()
	{ 
		return m_csv_h;
	}
  protected:
	FILE *m_csv_h;
};

#define CSV_LOG_WATCHER(ifname) \
	class ifname##_csv_log_watcher : public esc_csv_log_watcher<ifname##_if*>, public ifname##_if

//! Declares the constructor within a CSV log watcher class for the given interface.
#define CSV_LOG_WATCHER_CTOR(ifname) \
	public: \
	ifname##_csv_log_watcher( esc_watchable<ifname##_if*>* target, esc_csv_logger *logger ) \
		: esc_csv_log_watcher<ifname##_if*>( target, logger ) \
	{}

//! Declares a log watcher allocation function to go with a CSV_LOG_WATCHER_CLASS(ifname)
//! If a CSV_LOG_WATCHER class is declared, this macro must appear somewhere following that
//! class to ensure that the appropraite logger class will be allocated for the given interface.
#define CSV_LOG_WATCHER_ALLOC_FUNC(ifname) \
	class ifname##_csv_log_watcher; \
	static esc_csv_log_watcher<ifname##_if*> *esc_csv_allocate_watcher( esc_watchable<ifname##_if*>* target, esc_csv_logger *logger ) \
	{ \
		return new ifname##_csv_log_watcher( target, logger ); \
	}

#endif // BDW_HUB

#endif // ESC_CSVLOG_HEADER_GUARD__
