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

#ifndef ESC_SOURCE_HEADER_GUARD__
#define ESC_SOURCE_HEADER_GUARD__

/*!
  \file esc_source.h
  \brief Classes and functions for SystemC sources

  For more information about using SystemC sources, refer to the ESC User's Guide.
*/

template< class retT >
class esc_id_val_pair
{
public:
	esc_id_val_pair( int id )
		: m_id(id),
		  m_next(NULL),
		  m_ready(0) {}

	int					m_id;
	retT				m_val;
	char				m_ready;
	esc_id_val_pair *  m_next; // lower in queue
};

/*!
  \class esc_source
  \brief The base class for sources that can be used from SystemC or the Hub.

  Sources are objects which supply a value when their casting operator are 
  invoked. The code for generating the values to return is contained in the 
  virtual method generate(), which must be overloaded by classes derived 
  from esc_source. The code in the generate() method will be executed as a 
  thread. Values for this object are specified by calling the write() method 
  from the generate() method.

  The is_empty() virtual method can optionally be overridden by derived 
  classes to build finite sources.  Those who access finite sources must test 
  is_empty() between each access.  To complete the protocal, the derived class 
  for the finite source must set the m_empty member when it completes its sequence.
*/
  
template< class T >
class esc_source
{
 public:
	//! Constructor
	inline				esc_source();
	//! Destructor
	inline				~esc_source();

	/*!
	  \brief Generates values for the source
	  
	  When overloaded, this function will be run in its own thread until it has
	  generated all the values that this source can generate.

	  When creating a class derived from esc_source, this is the only function
	  that must be written.

	  Users should not call this function directly.
	*/
	inline virtual void generate();

	/*!
	  \brief Returns a value from the source that has been made available by generate()
	  \return The generated value
	 */
	inline				operator T ();

	/*!
	  \brief Called from within generate(), makes a value available for return from operator T()

	  This is a blocking call.
	*/
	inline void			write( T value );
	
	/*!
	  \brief Returns whether the source has generated all of its values.

	  m_empty, which this function returns, must be set and cleared by the user's derived generate()
	*/
	inline virtual int	is_empty()
							{ return m_empty; }
	/*!
	  \brief Called from generate(), causes further calls to is_empty() to return true.

	  The user's derived generate() function must explicitly make this call.
	*/
	inline virtual void set_done()
							{ m_empty = 1; }

	/*!
	  \internal
	  
	  Because the generate function may be overloaded, we need a single function that
	  can be called with SC_THREAD() which will call the (possibly overloaded)
	  generate().
	*/
	static int			generate_wrap( esc_source<T> *src );

 protected:
	int					m_empty;	// Becomes true when a finite source completes.
	sc_event			m_val_avail;// Triggered when a value is written.
	sc_event			m_val_req;	// Triggered when a value is requested.
	//sc_join_handle 		m_thread_h;	// Handle of spawned thread.
	int 				m_thread_rslt; // Place to hold return value from thread.
	int					m_thread_state;// 0==uncreated, 1=created, -1=failed to create.
	int					m_next_req_num; // Used to id values returned from write()

	esc_id_val_pair<T> *m_queue_front; // List of value/id pairs to return next
	esc_id_val_pair<T> *m_queue_back;

	//! \internal
	inline bool			create_thread();
};

template< class T >
inline
esc_source<T>::esc_source()
{
	m_empty = 0;
	m_queue_front = NULL;
	m_queue_back = NULL;
	m_thread_rslt = 0;
	m_next_req_num = 0;
	m_thread_state = 0; 

	if ( sc_get_curr_simcontext()->is_running() )
	{
		// Create a thread immediately.
		create_thread();
	}
	else
	{
#if BDW_HUB
		// If the simulation is under Hub control, increment the number of outstanding sources.
		if ( !esc_hub::m_systemc_is_master )
			esc_hub::m_num_reged_tests_and_srcs++;
#endif
	}

}

template< class T >
inline
esc_source<T>::~esc_source()
{

}

template< class T >
inline
void esc_source<T>::generate()
{
	esc_report_error( esc_error, "You must overload the generate() method for classes derived from esc_source<T>\n");
}

// Attempts to create a thread, once only, if one isn't already running.
// Reports errors if they occur.
// Should only be called during execution.
template< class T >
inline
bool esc_source<T>::create_thread()
{
	// It's already been created.
	if ( m_thread_state == 1 )
		return true;
	else if ( m_thread_state == -1 )
		return false;

#if 0
	if ( thread_pool::global_thread_pool )
	{
		//m_thread_h = sc_spawn_function(&m_thread_rslt,&esc_source<T>::generate_wrap,this);
		m_thread_state = 1;
		return true;
	}
	else
	{
		esc_report_error( esc_fatal, "esc_source: Attempt to create a source when the thread pool is not been initialized.\n\nCall thread_pool::init(N) during elaboration.\n");
		m_thread_state = -1;
		return false;
	}
#else
	esc_report_error( esc_fatal, "esc_source: This class is no longer supported.\n");
#endif
}

template< class T >
inline
esc_source<T>::operator T ()
{
	// Make sure the source has a thread.
	if ( !create_thread() )
	{
		static T bad_rslt;
		return bad_rslt;
	}

	// take a number
	int my_id = m_next_req_num++;

	esc_id_val_pair<T> *snvp = new esc_id_val_pair<T>(my_id);

	// add it into the list
	if ( ! m_queue_front )
		m_queue_front = snvp;

	if ( ! m_queue_back )
	{
		m_queue_back = snvp;
	}
	else
	{
		m_queue_back->m_next = snvp;
		m_queue_back = snvp;
	}

	while ( 1 )
	{
		// if the value is ready to be returned
		if ( m_queue_front->m_id == my_id && m_queue_front->m_ready == 1 )
		{
			T my_val = m_queue_front->m_val;
			esc_id_val_pair<T> *tmp = m_queue_front->m_next;
			if ( m_queue_front == m_queue_back )
				m_queue_back = NULL;
			delete m_queue_front;
			m_queue_front = tmp;

			// prevent possibility of overflow
			if ( ! m_queue_front )
				m_next_req_num = 0;
			else // tickle the val_avail, so other threads can get their val
				m_val_avail.notify();

			return my_val;
		}
		else
		{
			// make sure the write() gets woken up again
			m_val_req.notify();
			wait( m_val_avail );
		}
	}

	return m_queue_front->m_val; // satisfy compiler, will never actually get here
}

template< class T >
inline
int esc_source<T>::generate_wrap( esc_source<T> *src )
{
	src->generate();

	return 0;
}

template< class T >
inline void
esc_source<T>::write( T value )
{
	// if no one has requested a value yet, wait
	if ( !m_queue_front )
	{
		wait( m_val_req );
	}

	assert( m_queue_front );

	// add it to the queue
	m_queue_front->m_val = value;
	m_queue_front->m_ready = 1;

	m_val_avail.notify();

	wait( m_val_req );
}

#endif // ESC_SOURCE_HEADER_GUARD__
