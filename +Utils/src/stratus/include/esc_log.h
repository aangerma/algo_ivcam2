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

#ifndef ESC_LOG_HEADER_GUARD__
#define ESC_LOG_HEADER_GUARD__

/*!
	\file esc_log.h
	\brief Classes supporting transaction logging for SystemC
 */

#if BDW_HUB

//
// Forward declarations.
//
class esc_tx_logger;

struct time_handle
{
	// This struct does not have to convert its sc_time to ps, 
	// but doing so will help avoid future problems.

	time_handle(esc_handle handle, sc_time time) 
		: h(handle), t( sc_time( esc_normalize_to_ps(time), SC_PS ) )
	{}
	esc_handle	h;
	sc_time		t;
};

//==============================================================================
/*! 
	\class esc_log_watcher

    \brief Templated base class for watchers that write to esc_tx_loggers.

	An esc_log_watcher exists for each object being watched by an esc_tx_logger.
	There should be a specialization of this class for each specialization of
	esc_tx_logger.

	The basic flow is:
	<li>A class derived from esc_watchable calls one of the \em log_*(T value) methods 
	to indicate that an event has occurred.
	<li>An esc_watchable informs the esc_log_watchers registered for that event
	via the watch_notify()
	<li>esc_log_watcher derived classes encode transaction values appropriately for
	their target data stores.

	The template parameter \em T is the type of the data being logged.	
*/
//==============================================================================
template <class T>
class esc_log_watcher : public esc_watcher<T>
{
  public:
	/*! \brief Constructor.  
	 *
	 *	Uses the default_start() and default_end() methods in the 
	 *	esc_tx_logger it's given to determine which events to watch on its target.
	 *	Registers as a logger with the target using these event flags.
	 */
	esc_log_watcher( esc_watchable<T> *target, esc_tx_logger *logger )
		: m_target_p( target ), m_logger_p(logger)
			//m_started(0), m_instant( logger->default_start() == ESC_CHANGED_EVENT ),
			//m_start( logger->default_start() ), m_end( logger->default_end() )
	{
		// If the default flags are not produced by the watchable, 
		// look for backup flags.
		esc_event_type gens_events = target->notify_events();
		if ( !( gens_events & m_start ) )
		{
			esc_event_type alt = (( m_start == ESC_WRITE_START_EVENT) ? ESC_READ_START_EVENT : ESC_WRITE_START_EVENT);
			if ( gens_events & alt )
				m_start = alt;
			else if ( gens_events & ESC_CHANGED_EVENT )
			{
				m_start = ESC_CHANGED_EVENT;
				m_instant = 1;
			}
			else
				m_start = 0;
		}
		if ( !( gens_events & m_end ) )
		{
			esc_event_type alt = (( m_end == ESC_WRITE_END_EVENT) ? ESC_READ_END_EVENT : ESC_WRITE_END_EVENT);
			if ( gens_events & alt )
				m_end = alt;
			else if ( gens_events & ESC_CHANGED_EVENT )
			{
				m_end = ESC_CHANGED_EVENT;
				m_instant = 1;
			}
			else 
				m_end = 0;
		}

		// Register with the watchable using our current event flags.
		if ( m_start | m_end )
			target->add_watcher( this, m_start | m_end );
	}

	/*! \brief Finds the start time associated with the given handle
	    \param handle The handle returned from notify_read/write_start()
	    \return The sc_time associated with the handle (or the current time if the handle is empty.)
	*/
	sc_time startTimeForHandle( esc_handle handle )
	{
		time_handle *th=NULL;
		sc_time retval = sc_time( esc_normalize_to_ps(sc_time_stamp()), SC_PS );

		if ( handle == esc_empty_handle )
			return retval;

		int i = 0;
		for( i=0; !th && i<m_start_times.size(); i++)
		{
			if ( m_start_times[i]->h == handle )
				th = m_start_times[i];
		}
		if ( th )
		{
			retval = th->t;
			delete th;

			if ( m_start_times.size() == 1 )
			{
				m_start_times.erase_all();
			}
			else
			{
				// Ugly remove
				m_start_times[i] = m_start_times[m_start_times.size()-1];
				m_start_times.decr_count();
			}
		}

		return retval;
	}

  protected:	
	esc_watchable<T>*  m_target_p;	// Item we're watching
	esc_tx_logger* m_logger_p;		// Logger we're writing to.
	int m_started;					// True if the start has been seen but the end hasn't.
	int m_instant;					// True if we're logging changes only.  No duration.
	unsigned short m_start;			// Event flag that indicates the start of a transaction.
	unsigned short m_end;			// Event flag that indicates the start of a transaction.
	sc_time m_start_time;			// Recorded start time for transaction in ps.
	sc_pvector<time_handle*> m_start_times;  // Hash table of start times
};

//==============================================================================
/*! 
	\class esc_tx_logger

    \brief Base class for transaction loggers

	A subclass of esc_tx_logger should be defined for each target transaction
	data store.  

*/
//==============================================================================
class esc_tx_logger
{
  public:
	//! Constructor.
	esc_tx_logger()
		: m_start_flag(ESC_READ_START_EVENT), m_end_flag(ESC_READ_END_EVENT), m_on(0)
	{}
	//! Destructor.
	virtual ~esc_tx_logger()
	{
		for ( esc_primitive_watcher** watcher = m_watchers.begin(); watcher != m_watchers.end(); watcher++ ) 
			delete (*watcher);
	}
	//! Closes an open log file.  Must be overloaded by derived classes.
    virtual void close()
	{
		esc_hub::remove_open_logger(this);
	}

	//! Prevents writes to the data store.
    virtual void off()
	{
		m_on = 0;
	}
	//! Re-enables writes to the data store.
    virtual void on()
	{
		m_on = 1;
	}

	//! Returns true if the logger is currently open.
	virtual bool is_open() const=0;

	//! Opens a log file for write at the given pathname.  Must be overloaded by derived classes.
    virtual bool open( const char* fname )
	{
		esc_hub::add_open_logger( this );
		return true;
	}

	// \internal	Adds a watcher to the vector of watchers.
	void add( esc_primitive_watcher *watcher )
	{
		m_watchers.push_back( watcher );
	}
	//! Adds an item to be logged by reference.  Must be overloaded by derived classes.
    template <class T> int add( esc_watchable<T>* target )
	{
		esc_report_error( esc_error, "esc_tx_logger class missing template <class T> void add( esc_watchable<T>* target ) implementation\n" );
		return 0;
	}
	//! Adds an item to be logged by name.  Must be overloaded by derived classes.
    template <class T> int add( T* sample_p, const char* var1_p )
	{
		esc_report_error( esc_error, "esc_tx_logger class missing template <class T> void add( T* sample, char* var1_p ) implementation\n" );
		return 0;
	}

	//! Adds an item to be logged by name.  Must be overloaded by derived classes.
	virtual int add( const char* name_p )
	{
		esc_report_error( esc_error, "esc_tx_logger class missing void add( char* var1_p ) implementation\n" );
		return 0;
	}

	//! Adds an sc_object to be logged.  Must be overloaded by derived classes.
    virtual int add_object( sc_object* obj_p )
	{
		esc_report_error( esc_error, "esc_tx_logger class missing void add_object( sc_object* var1_p ) implementation\n" );
		return 0;
	}

	/*!
	  \brief Gives the ESC_*_EVENT flag used to recognize transaction starts.  

	  This setting affects subsequently-added items.
	*/
	unsigned short default_start()
	{
		return m_start_flag;
	}
	/*!
	  \brief Gives the ESC_*_EVENT flag used to recognize transaction ends.

	  This setting affects subsequently-added items.
	*/
	unsigned short default_end()
	{
		return m_end_flag;
	}

	/*!
	  \brief Returns non-zero if the default setting is currently set to log duration-free value changes.

	  This setting affects subsequently-added items.
	*/
	int default_on_change()
	{
		return (m_start_flag == ESC_CHANGED_EVENT);
	}

	/*!
	  \brief Sets the ESC_*_EVENT flags used to recognize transaction start and ends for 
	  transactions with duration.

	  Affects subsequently-added items.  
	*/
	void set_default_start_end( unsigned short start=ESC_READ_START_EVENT, unsigned short end=ESC_READ_END_EVENT )
	{
		 m_start_flag = start;
		 m_end_flag = end;
	}
	/*!
	  \brief Sets the ESC_*_EVENT flag used to recognize transaction ends for transactions
	  with duration that report at the end time but do not report at the start time.

	  Affects subsequently-added items.
	*/
	void set_default_end( unsigned short end=ESC_READ_END_EVENT )
	{
		 m_start_flag = ESC_NO_EVENT;
		 m_end_flag = end;
	}
	//! Causes subsequently added items to have their values logged when they change
	//! without any record of duration.
	void set_default_on_change()
	{
		 m_start_flag = ESC_CHANGED_EVENT;
		 m_end_flag = ESC_NO_EVENT;
	}

  protected:
	unsigned short m_start_flag;
	unsigned short m_end_flag;	
	int m_on;
	sc_pvector<esc_primitive_watcher *> m_watchers;
};


#endif // BDW_HUB

#endif // ESC_LOG_HEADER_GUARD__
