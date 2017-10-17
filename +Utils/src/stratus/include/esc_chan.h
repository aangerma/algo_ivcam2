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
#ifndef esc_channel_h_INCLUDED
#define esc_channel_h_INCLUDED

/*!
// \file	esc_chan.h	
// \brief	Contains channel classes for inter-module communication.
//	
*/
// Copyright(c) 2001 Forte Design Systems 
//

// Disable warnings regarding debug symbol shortening on VC.
#if (_MSC_VER)
#pragma warning( disable : 4786 )  
#endif

#include <stdarg.h>
#include <assert.h>

// FORWARD REFERENCES:

template< class T > class esc_chan_in;
template< class T > class esc_chan_out;
template< class T > class esc_chan_out_base;
template< class T > class esc_chan_txout;
template< class T > class esc_chan_txin;

//! Code used in the configure_in() interface to indicate that a time-zero power-on reset is to be performed.
#define ESC_POWERON_IN	0x00000001

//! Code used in the configure_out() interface to indicate that a time-zero power-on reset is to be performed.
#define ESC_POWERON_OUT	0x00000002

//! A code, suitable for use in either configure_in(), configure_out(), or an esc_chan port class's configure() function 
//! to indicate that a time-zero power-on reset is to be performed.
#define ESC_POWERON	(ESC_POWERON_IN | ESC_POWERON_OUT)

//! Code used in the configure_in() interface to indicate that an explicit reset is to be performed.
#define ESC_RESET_IN	0x00000004

//! Code used in the configure_out() interface to indicate that an explicit reset is to be performed.
#define ESC_RESET_OUT	0x00000008

//! A code, suitable for use in either configure_in(), configure_out(), or an esc_chan port class's configure() function 
//! to indicate that a explicit reset is to be performed.
#define ESC_RESET		(ESC_RESET_IN | ESC_RESET_OUT)


// gcc requires the use of typename in places where VC does not allow it.
#if (_MSC_VER)
#define gcc_typename
#else
#define gcc_typename typename
#endif

/*!==============================================================================
// \class esc_chan_in_if 
// \brief Base class for ESC channel read interface.
//
// This class provides the interface for reading from a channel instance.
//
//==============================================================================
*/
template< class T >
class esc_chan_in_if : virtual public esc_watchable_in_if<T>
{
  public:
	/*! \brief Read a value without un-blocking writers. 
	 *
	 *	The aread() function will return a value that has been written
	 *	to the channel.  If no value is available, the call will block
	 *	waiting for one.  Calling aread() on a channel will not un-block
	 *	channel writers blocked in write() or wait_read_done().
	 *
	 * \param id Used to identify the reader for implementations
	 *	that support multiple readers.  Ordinarily, the id parameter is 
	 *	supplied by esc_chan port classes that connect to esc_chans but 
	 *	not directly by application code that interacts with esc_chan.
	 *
	 * \return T
	 *	The value read from the channel.
	 */
    virtual T aread( int id=-1 )=0;

	/*! \brief	Follows an aread() to indicate the consumer is done.
	 *
	 *	The aread_done() method is called by a consumer after a value
	 *	has been read using aread().  The aread_done() call will un-block
	 *	any writers blocked on write() or wait_read_done().  The time
	 *	between the call to aread() and aread_done() will appear as a
	 *	delay on the channel to blocked writers.
	 *
	 * \param id Used to identify the reader for implementations
	 *	that support multiple readers.  Ordinarily, the id parameter is 
	 *	supplied by esc_chan port classes that connect to esc_chans but not 
	 *	directly by application code that interacts with esc_chan.
	 */
    virtual void aread_done( int id=-1 )=0;

	/*!	\brief	Configures the input interface
 	 *	\param	code	A code describing what configuration is to be performed.
	 *	\param	param	A general purpose parameter.
	 *	\return Returns true for success or false for failure.
	 *
	 *	The configure_in() method provides a mean of performing configuration
	 *	or passing other out-of-band messages to an esc_chan.  The 'code'
	 *	parameter describes the type of configuration that is to be performed.
	 *	A small number of code values are pre-defined by ESC, and others can
	 *	be added by application code as required.  The pre-defined codes are:
	 *	
	 *	\li \em ESC_POWERON_IN: A time-zero power-on reset is to be performed.
	 *	\li \em ESC_RESET_IN: An explicit reset has been performed by application code.
	 *
	 *	The default esc_chan implementation of configure_in() does nothing.
	 *	An adaptor class is an example of a subclass that might implement configure_in().
	 */
	virtual bool configure_in( unsigned int code, void* param=0 )=0;

	/*! \brief	Tests whether a value is available to read.
	 *
	 *	is_empty() can be used to test whether a call to read() or aread()
	 *	would block.  
	 *
	 *	\return 1 if a value is available to read, and 0 if no value is available.
	 */
    virtual bool is_empty()=0;

	/*! \brief	Reads a value without inserting a delay
	 *
	 *	The read() function can be used in place of an aread()/aread_done()
	 *	pair when the consumer does not need to insert a delay onto the channel.
	 *	The read() method is ordinarily implemented trivially as an aread() 
	 *	followed by an aread_done().
	 *
	 * \param id Used to identify the reader for implementations
	 *	that support multiple readers.  Ordinarily, the id parameter is 
	 *	supplied by esc_chan port classes that connect to esc_chans but not 
	 *	directly by application code that interacts with esc_chan.
	 *
	 *	\return	The value read.
	 */
    virtual T read( int id=-1 )=0;

	/*! \brief	Registers a port as a consumer of the channel.
	 *
	 *	When an esc_chan_in port binds to a channel, it registers itself with
	 *	the channel so that the channel will know how many readers it has.
	 *	This allows channel implementations that support multiple readers to
	 *	properly arbitrate amongst the readers.
	 *
	 *	This method is ordinarily called by a channel port class and not directly
	 *	by channel consumers.
	 *
	 *	\return	A unique ID for the consumer.
	 */
	virtual int register_consumer()=0;

  protected:
    esc_chan_in_if() {}
  
  private:
    esc_chan_in_if( const esc_chan_in_if<T>& );
    esc_chan_in_if<T>& operator = ( const esc_chan_in_if<T>& );
};


/*!==============================================================================
// \class esc_chan_out_if
// \brief Base class for ESC channel write interface.
//
// This class provides the interface for writing to a channel instance.
//
//==============================================================================
*/
template< class T >
class esc_chan_out_if : virtual public sc_interface {
  public:
	/*! \brief	Writes a value without waiting for it to be read.
	 *
	 *	The awrite() function will write a value to the channel
	 *	and return as soon as that value has been written to the channel.
	 *	It will not block waiting for the value to be read.  The awrite()
	 *	method will block until space taken by preceding writes has been
	 *	cleared so that the write can proceed.
	 *
	 *	\param id	If this optional parameter is used by some channel
	 *	implementations to uniquely identify the writer for use in 
	 *	arbitration.  This parameter is not used by some channel
	 *	implementations.  Ordinarily, the id parameter is supplied by 
	 *	esc_chan port classes that connect to esc_chans but not directly
	 *	by application code that interacts with esc_chan.
	 */
    virtual void awrite( const T& value, int id=-1 )=0;

	/*!	\brief	Configures the output interface
 	 *	\param	code	A code describing what configuration is to be performed.
	 *	\param	param	A general purpose parameter.
	 *	\return Returns true for success or false for failure.
	 *
	 *	The configure_out() method provides a mean of performing configuration
	 *	or passing other out-of-band messages to an esc_chan.  The 'code'
	 *	parameter describes the type of configuration that is to be performed.
	 *	A small number of code values are pre-defined by ESC, and others can
	 *	be added by application code as required.  The pre-defined codes are:
	 *	
	 *	\li \em ESC_POWERON_OUT: A time-zero power-on reset is to be performed.
	 *	\li \em ESC_RESET_OUT: An explicit reset has been performed by application code.
	 *
	 *	The default esc_chan implementation of configure_out() does nothing.
	 */
	virtual bool configure_out( unsigned int code, void* param=0 )=0;

	/*!	\brief	Tests whether a value can be written without blocking.
	 *
	 *	is_full() can be used to test whether a call to awrite()
	 *	would block.  This is true when any previously written value
	 *	has been read.  Note that a call to write() may still block
	 *	since it requires that the written value be read before 
	 *	returning.
	 *
	 *	\return 1 if a value can be written without blocking, 0 if 
	 *	awrite() would block.
	 */
    virtual bool is_full()=0;

	/*!	\brief	Tests whether a previously written value has been read.
	 *
	 *	is_read_done() can be used to test whether a value previously 
	 *	written with awrite() has both been read to completion.  That
	 *	is, whether it has been read, and any delay inserted by the 
	 *	reader has passed.
	 *	
	 *	This method may not be meaningful for some channel implementations.
	 *
	 *	\return 1 if there is no previously written value that has yet
	 *	to be fully read.
	 */
    virtual bool is_read_done()=0;

	/*! \brief	Registers a port as a producer for the channel.
	 *
	 *	When an esc_chan_out port binds to a channel, it registers itself with
	 *	the channel so that the channel will know how many writers it has.
	 *	This allows channel implementations that support multiple writers to
	 *	properly arbitrate amongst the writers.
	 *
	 *	This method is ordinarily called by a channel port class and not directly
	 *	by channel consumers.
	 *
	 *	\return	A unique ID for the producer.
	 */
	virtual int register_producer()=0;

	/*! \brief	Waits until a previously written value has been fully read.
	 *
	 *	The wait_read_done() method will wait until a previously
	 *	written value has both been read, and any delay inserted by the
	 *	reader has passed.  

	 *	This method may not be meaningful for some channel implementations.
	 */
    virtual void wait_read_done()=0;

	/*! \brief	Writes a value and waits until it has been fully read.
	 *
	 *	This method will write a value to the channel and wait until
	 *	it has both been read and any delay inserted by the reader has
	 *	passed.  It is typically impemented as an awrite() followed by
	 *	a wait_read_done().
	 *
	 *	\param id	If this optional parameter is used by some channel
	 *	implementations to uniquely identify the writer for use in 
	 *	arbitration.  This parameter is not used by some channel
	 *	implementations.  Ordinarily, the id parameter is supplied by 
	 *	esc_chan port classes that connect to esc_chans but not directly
	 *	by application code that interacts with esc_chan.
	 */
    virtual void write( const T& value, int id=-1 )=0;
  
  protected:
    esc_chan_out_if() {}

  private:
    esc_chan_out_if( const esc_chan_out_if<T>& );
    esc_chan_out_if<T>& operator = ( const esc_chan_out_if<T>& );
};


/*!==============================================================================
// \class	esc_chan
// \brief	A base class for ESC channel classes.
//
// This class acts as a base class for all channel classes that implement both
// the esc_chan_in_if and public esc_chan_out_if interfaces.  
// esc_chan provides a basic point-to-point communications protocol.
// Derived classes may override some or all of its members.  An esc_chan may be
// instantiated directly.  
//
// esc_chan is derived from esc_watchable<T> so that esc_watcher<T>'s can observe 
// activity on the channel.
//
//==============================================================================
*/
template< class T > 
class esc_chan :
	public sc_prim_channel,
	public esc_watchable<T>,
    public esc_chan_in_if<T>, 
    public esc_chan_out_if<T> 
{
  public:
	//! Convenience typedef for the esc_chan_in<T> port class.  
	//! Can be used as esc_chan<T>::in
    typedef class esc_chan_in<T> in;

	//! Convenience typedef for the esc_chan_out<T> port class.  
	//! Can be used as esc_chan<T>::out
    typedef class esc_chan_out<T> out;

	//! Convenience typedef for the esc_watchable_in port class
	//! for esc_watchable's that are actually esc_chan's.
	//! Can be used as esc_chan<T>::watch_in
	typedef class esc_watchable_in<T> watch_in;

	//! Convenience typedef for the esc_watchable_queue_in port class
	//! for esc_watchable's that are actually esc_chan's.
	//! Can be used as esc_chan<T>::queue_in
	typedef class esc_watchable_queue_in<T> queue_in;

  public:
	//! Constructor
	esc_chan( const char* name=0, sc_object* proxy=0 );

    virtual bool				is_empty() 
    { 
    	return !m_value_present; 
    }
    virtual const char*			kind() const 
    { 
    	return "esc_chan"; 
    }
    operator T () 
    { 
    	return read(); 
    }
    virtual T					aread( int id=-1 );
    virtual void				aread_done( int id=-1 );
    virtual T					read( int id=-1 );
	virtual int					register_consumer();
    virtual void				update() 
    {}
    
  public:
	virtual void				add_watcher( esc_watcher<T>* watcher, esc_event_type events=ESC_ALL_EVENTS )
	{
		esc_watchable<T>::add_watcher( watcher, events );
	}
	virtual bool				configure_in( unsigned int code, void* param=0 )
	{
		return true;
	}
	virtual bool				configure_out( unsigned int code, void* param=0 )
	{
		return true;
	}

    virtual void				awrite( const T& value, int id=-1 );
    virtual bool				is_full() 
    { 
    	return m_value_present; 
    }
    virtual bool				is_read_done()
	{
		return ( !m_value_present && !m_aread_started );
	}	
    esc_chan<T>&				operator = ( const T& value ) 
    { 
    	write( value ); 
    	return *this; 
    }
	virtual int					register_producer() { return -1; } // Not used by esc_chan<T>
    virtual void				wait_read_done();
    virtual void				write( const T& value, int id=-1 );

	/*!
	  \brief Used to determine what events can be watched on this esc_chan
	  \return The events that this esc_chan generates (as a combination of ESC_*_EVENT.)
	*/
	virtual esc_event_type		notify_events() 
	{ 
		return (ESC_WRITE_START_EVENT | ESC_WRITE_END_EVENT | ESC_READ_START_EVENT | ESC_READ_END_EVENT); 
	}

  protected:
	int	 	 m_aread_started;	// The number of areads that have occurred without an aread_done().
	bool	 m_awrite_started;	// An awrite has occured, but it has not yet written its value.
	int		 m_num_readers;		// The number of registered readers.
    T        m_value;           // Value being transferred.
    int		 m_value_present;   // Non-zero if a value has been written and not yet consumed.
	int		 m_waiting_consumer;// The number of consumers waiting for data to read.
    sc_event m_wake_consumer;   // Event to wake consumer on wait to read.
    sc_event m_wake_producer;   // Event to wake producer on wait to write.

	void end_of_elaboration()
	{
		// If no consumers have been registered, set m_num_readers to 1 so protocols will
		// expect a single reader.
		if ( m_num_readers == 0 )
			m_num_readers = 1;
	}
};


//------------------------------------------------------------------------------
//"esc_chan<T>::esc_chan"
//
//------------------------------------------------------------------------------
template< class T > esc_chan<T>::esc_chan( const char* name, sc_object* proxy )
	:	sc_prim_channel( name ? name : sc_gen_unique_name( "esc_chan" ) ),
		esc_watchable<T>( proxy ? proxy : this ),
		m_num_readers(0),
	    m_wake_consumer(), m_wake_producer(), 
	    m_aread_started(0), m_awrite_started(false), 
	    m_waiting_consumer(0), m_value_present(0)
{
}


//------------------------------------------------------------------------------
//"esc_chan<T>::read"
//
//------------------------------------------------------------------------------
template< class T > T esc_chan<T>::read( int id )
{
	// By definition, this is a read() followed by an aread_done().
	T value = aread( id );
	aread_done( id );
	return value;
}

//------------------------------------------------------------------------------
//"esc_chan<T>::register_consumer"
//
//------------------------------------------------------------------------------
template< class T > int esc_chan<T>::register_consumer()
{
	// Just increments the semaphore value that's used as a threshold for
	// un-blocking writers.
	return m_num_readers++;
}

//------------------------------------------------------------------------------
//"esc_chan<T>::aread"
//
//------------------------------------------------------------------------------
template< class T > T esc_chan<T>::aread( int id )
{
	// Implicitly complete any outstanding aread().
	if ( m_aread_started ) 
		aread_done( id );

	// Wait for a value to be written if necessary.
    if ( !m_value_present ) 
	{
    	m_waiting_consumer++;
    	wait( m_wake_consumer );
    	m_waiting_consumer--;
	}

	// Record that the value has been consumed but that the read has not been completed
	// by an aread_done().  Also notify any awriter blocked waiting for the value to be consumed.  
	// We avoid triggering the m_wake_producer event unless its know that an awrite() is blocked 
	// waiting on it so that we avoid un-blocking a writer that is waiting for an aread_done() instead.
    m_value_present = 0;
    m_aread_started = 1;
	if ( m_awrite_started )
		m_wake_producer.notify();

	// Notify watchers.
	notify_read_start( &m_value );

    return m_value;
}

//------------------------------------------------------------------------------
//"esc_chan<T>::aread_done"
//
//------------------------------------------------------------------------------
template< class T > void esc_chan<T>::aread_done( int id )
{
	if ( m_aread_started )
	{
        // Wake up the producer and clear the m_aread_started flag.
	    m_wake_producer.notify();
        m_aread_started = 0;

		// Notify watchers.
		notify_read_end( &m_value );
	}
	else
	{
		esc_report_error( esc_error, "%s: %s: %s: aread_done() called without a preceding aread()\n", 
							ESC_CUR_TIME_STR, kind(), ((sc_prim_channel*)this)->name() );
	}
}


//------------------------------------------------------------------------------
//"esc_chan<T>::awrite"
//
//------------------------------------------------------------------------------
template< class T > void esc_chan<T>::awrite( const T& value, int id )
{
	// If a previously written value has not yet been read, wait for it to be read.
	// We mark the fact that there's a blocked awrite() because the m_wake_producer
	// event is also used to wake blocked wait_read_done() calls.
    if ( m_value_present ) 
	{
		m_awrite_started = true;
    	wait( m_wake_producer );
		m_awrite_started = false;
	}

	// Write the value, mark it as present, and notify any waiting consumer.
    m_value_present = m_num_readers;
    m_value = value;
	if ( m_waiting_consumer ) 
	    m_wake_consumer.notify();

	// Fan out to watchers.
	notify_write_start( &m_value );
}

//------------------------------------------------------------------------------
//"esc_chan<T>::write"
//
//------------------------------------------------------------------------------
template< class T > void esc_chan<T>::write( const T& value, int id )
{
	// By definition, this is an awrite() followed by a wait_read_done().
	awrite( value, id );
	wait_read_done();
}

//------------------------------------------------------------------------------
//"esc_chan<T>::wait_read_done"
//
//------------------------------------------------------------------------------
template< class T > void esc_chan<T>::wait_read_done()
{
	if ( m_awrite_started )
	{
		esc_report_error( esc_error, "%s: %s: %s: wait_read_done() being performed during concurrent awrite()\n", 
							ESC_CUR_TIME_STR, kind(), ((sc_prim_channel*)this)->name() );
	}
	if ( !is_read_done() )
	{
    	wait( m_wake_producer );
	}
	// Fan out to watchers.
	this->notify_write_end();
}

/*!==============================================================================
// \class	esc_pp_chan
// \brief	A channel class for point-to-point communication.
//
// esc_pp_chan exports the basic point-to-point communications protocol implemented
// by esc_chan.  It can be used interchangably with esc_chan.
//
//==============================================================================
*/
template< class T > 
class esc_pp_chan : public esc_chan<T>
{
  public:
	//! Constructor
	esc_pp_chan( const char* name=0, sc_object* proxy=0 ) : esc_chan<T>(name,proxy)
	{}

    virtual const char*			kind() const 
    { 
    	return "esc_pp_chan"; 
    }
  protected:
};

/*!==============================================================================
// \class	esc_async_chan
// \brief	An ESC channel class for asynchronous communications.
//
// esc_async_chan implements the esc_chan_out_if in a non-blocking way
// to allow a channel writer to pass information to observers without
// modifying its threading behavior.
//
// When the write() method is called, if there is a blocked reader
// the value will be returned from the reader's in its aread() call.  Additionally,
// the esc_async_chan's watchers are informed of the write.  However, if
// there is no reader blocked when write() is called, the write() call does
// not block waiting for one.  This allows readers and watchers to observe an esc_async_chan
// without influencing its threading behavior.
//
// The esc_async_chan class is often used to implement message passing schemes 
// between threads.  The esc_watchable::queue_in port provides a convenient method
// of synchronizing threads connected by esc_async_chan.
//
//==============================================================================
*/
template< class T > 
class esc_async_chan : public esc_chan<T>
{
  public:
	//! Constructor
	esc_async_chan( const char* name=0, sc_object* proxy=0 ) : esc_chan<T>(name,proxy)
	{}
    virtual const char*			kind() const 
    { 
    	return "esc_async_chan"; 
    }
    
  public:
	//
	// Functions re-implemented from esc_chan<T>
	//

    virtual void				awrite( const T& value, int id=-1 );

	//! An esc_async_chan is, by definition, never full.
    virtual bool				is_full() 
    { 
    	return false; 
    }
	//! Because it never waits for a read to be done, an esc_async_chan always returns true for is_read_done().
    virtual bool				is_read_done()
	{
		return true;
	}	
	//! the wait_read_done() method is a no-op on an esc_async_chan.
    virtual void				wait_read_done()
	{
	}

	/*!
	  \brief Used to determine what events can be watched on this esc_chan
	  \return An esc_async_chan generates only ESC_WRITE_END_EVENT.
	*/
	virtual esc_event_type		notify_events() 
	{ 
		return (ESC_WRITE_END_EVENT); 
	}

  protected:
};

//! Specifies the type of algorithm that will be used to select producers for esc_mp_chan.
enum esc_mp_selector_type { 
	//! A round-robin algorithm.
	esc_rr_select, 
	//! Random selection with a flat distribution.
	esc_ran_select,
	//! A custom selector set with set_selector().
	esc_custom_select
};

//------------------------------------------------------------------------------
// esc_async_chan<T>::write
//
//------------------------------------------------------------------------------
template< class T > void esc_async_chan<T>::awrite(const T& value, int id )
{
	if ( this->m_waiting_consumer	)
	{
		// There's a waiting consumer, so do a the base class's awrite().
		esc_chan<T>::awrite( value, id );
	}

	// Always fanout ESC_WRITE_END_EVENT now since wait_read_done() is a noop.
	notify_write_end( &value );

	// If there was no consumer, we must remove a lock after fanning out to 
	// allow writers to send values with locks on them.
	if ( ! this->m_waiting_consumer )
		esc_msg_unlock<T>( &value );
}

//==============================================================================
/*!
 	\class	esc_mp_chan
	\brief	A multi-producer channel

	The esc_mp_chan class multiplexes several channel producers into a single
	channel consumer.  
*/
//==============================================================================
template< class T > 
class esc_mp_chan : public esc_chan<T>
{
  public:
	/*! \brief	Base class for selectors for esc_mp_chan objects.
		The base class behavior selects producers in round-robin order.
		Classes should be derived from this base class to specify other
		selection behavior.
	 */
	class selector 
	{
	  public:
		//! Constructor
		selector( esc_mp_chan<T>* chan_p ) : m_n_prod(0), m_last_prod(-1), m_chan_p(chan_p)
		{}

		virtual ~selector() {}

		//! Called by esc_mp_chan after elaboration completes to store the number of producers the selector must select amongst.
		void set_n_producers( int n )
		{
			m_n_prod = n;
		}

		int get_n_producers()
		{
			return m_n_prod;
		}

		/*! \brief	Producer selection function.
			The select() function is called once by the esc_mp_chan once for each
			value that is read from the channel.  The selector class is expected to
			return an integer value between 0 and n-1 where n is the number of 
			producers specified in set_n_producers().  

			This default implementations uses a round-robin scheme.  Derived classes
			should overload this virtual function to provide other selection behavior.
		 */
		virtual int select()
		{
			return ( (++m_last_prod) % m_n_prod );
		}

		//! Returns the channel with which this selector is associatied. 
		esc_mp_chan<T>* channel() { return m_chan_p; }

	  protected:
		int m_n_prod;
		int m_last_prod;
		esc_mp_chan<T>* m_chan_p;
	};

#if BDW_HUB
	/*! \brief	Random generator-based selectors for esc_mp_chan.

		This random generator-based selector selects amongst producers using
		a random generator.  The random generator is constructed using either 
		the random distribution given in the constructor, or if no distribution
		is given, a flat distribution.  The random generator is seeded based 
		on a hash of the name of the esc_mp_chan with which the selector is
		associated.  A separate instance of ran_selector should be used for 
		each esc_mp_chan so activity on one esc_mp_chan will not affect the
		selection behavior of another.
	 */
	class ran_selector : public selector
	{
	  public:
		/*! \brief	Constructor
			\param chan_p	The esc_mp_chan for which the selector should be used.  The channel's name is used to seed the selector's rangen.
			\param dist_p	The random distribution that should be used for the selector.  If none is specified, a flat distribution is used.
		 */
		ran_selector( esc_mp_chan<T>* chan_p, esc_ran_dist* dist_p=0 )
			: selector(chan_p)
		{
			if ( dist_p )
				m_rangen_p = new esc_ran_gen<int>( *dist_p, chan_p->name() );
			else
				m_rangen_p = new esc_ran_gen<int>( chan_p->name() );
		}
		/*! \brief	Constructor
			\param seed_str	The string that should be used to seed the selector's random generator.
			\param dist_p	The random distribution that should be used for the selector.  If none is specified, a flat distribution is used.
		 */
		ran_selector( esc_mp_chan<T>* chan_p, const char * seed_str, esc_ran_dist *dist_p=0 )
			: selector(chan_p)
		{
			if ( dist_p )
				m_rangen_p = new esc_ran_gen<int>( *dist_p, seed_str );
			else
				m_rangen_p = new esc_ran_gen<int>( seed_str );
		}
		~ran_selector()
		{
			delete m_rangen_p;
		}
		virtual int select()
		{
			return m_rangen_p->generate( 0, num_producers()-1 );
		}
	  protected:
		esc_ran_gen<int> *m_rangen_p;
	};
#endif


	/*! \brief Constructor
		\param name_p		The name that will be given to the esc_mp_chan.
		\param proxy	The sc_object that this class is a sibling of.
	 */
	esc_mp_chan( const char* name, sc_object* proxy )
		: esc_chan<T>( name, proxy ), m_n_prod(0), m_selector_t(esc_rr_select), 
		  m_producer_flags(0), m_unread_values(0), m_num_unread(0), m_selector_p(0), m_owns_selector(false)
	{
	}

	/*! \brief Constructor
		\param name_p		The name that will be given to the esc_mp_chan.
		\param selector_t	Specifies the type of selection algorithm that will be used.  Defaults to esc_rr_select.  See set_selector() for details.
	 */
	esc_mp_chan( const char* name=0, esc_mp_selector_type selector_t=esc_rr_select )
		: esc_chan<T>( name ), m_n_prod(0), m_selector_t(selector_t), 
		  m_producer_flags(0), m_unread_values(0), m_num_unread(0), m_selector_p(0), m_owns_selector(false)
	{
		set_selector( selector_t );
	}

#if BDW_HUB
	/*! \brief Constructor using a specific random distribution.
		\param name_p		The name that will be given to the esc_mp_chan.
		\param randist		A random distribution that will be used to create a random selector.

		This form of constructor will cause a ran_selector to be created with the given
		distribution.  The ran_selector's random generator will be seeded based 
		on the hierarchical name of the esc_mp_chan.
	 */
	esc_mp_chan( const char* name, esc_ran_dist &randist )
		: esc_chan<T>( name ), m_n_prod(0), m_selector_t(esc_ran_select), m_selector_p(0), 
			m_producer_flags(0), m_num_unread(0), m_owns_selector(true), m_unread_values(0)
	{
		set_selector( randist ); 
	}
#endif

	//! Destructor
	~esc_mp_chan()
	{
		if ( m_owns_selector )			
			delete m_selector_p;
		for ( sc_event **it = m_producer_events.begin(); it != m_producer_events.end(); it++ ) 
			delete (*it);
		delete m_producer_flags;
		delete m_unread_values;
	}

	/*! \brief	Sets the selector object that will be used by the channel to select producers.
		\param	selector_t	Gives the type of selector that should be used.  Options are:

		\li	esc_rr_select	A round-robin algorithm will be used.  The order of port binding will determine the execution order.
		\li esc_ran_select	A random generator with a flat distribution will be used to select the next producer.  The random generator will be seeded using the esc_mp_chan's name.
		\li	esc_custom_select	A custom selector will be used.  The selector_p parameter must be specified when using this value.

		An esc_mp_chan's selector may set or reset at any time after the object is constructed.
	 */
	void set_selector( esc_mp_selector_type selector_t, selector* selector_p=0 )
	{
		// Delete any previously specified selector and adopt the new one.
		if ( m_owns_selector )
			delete m_selector_p;

		switch ( m_selector_t )
		{
#if BDW_HUB
			case esc_ran_select:
				if ( selector_p )
				{
					m_selector_p = selector_p;
					m_owns_selector = false;
				}
				else							
				{
					m_selector_p = new ran_selector( this ); 
					m_owns_selector = true;
				}
				break;
#else
			case esc_ran_select:		
				esc_report_error( esc_error, "%s: %s: Cannot use a random selector unless compiling with Hub support.",
										kind(), "?" );
				// Fall through to esc_rr_select.
#endif
			case esc_rr_select:	
				m_selector_p = new selector( this ); 
				m_owns_selector = true;
				break;

			case esc_custom_select:	
				m_selector_p = selector_p;
				m_owns_selector = false;
				break;

			default:			break;
		}

	}

	// \brief A convenience function that sets selector_p as a custom selector.
	void set_selector( selector* selector_p=0 )
	{
		set_selector( esc_custom_select, selector_p );
	}

	/*! \brief Sets the selector for the esc_mp_chan to use the given random distribution.
		\param randist		A random distribution that will be used to create a random selector.

		This function will cause a ran_selector to be created with the given
		distribution.  The ran_selector's random generator will be seeded based 
		on the hierarchical name of the esc_mp_chan.
	 */
#if BDW_HUB
	void set_selector( esc_ran_dist &randist )
	{
		set_selector( esc_ran_select, new ran_selector( this, &randist ) );
		m_owns_selector = true;
	}
#endif
	//
	// Functions re-implemented from esc_chan<T>
	//

    virtual const char*			kind() const 
    { 
    	return "esc_mp_chan"; 
    }

	//! Selects a producer to unblock using the configured selector, and then performs a normal aread().
    virtual T	 aread( int id=-1 );

	//! Blocks waiting to be selected by the configured selector, and then performs an normal awrite().
    virtual void awrite( const T& value, int id=-1 );

	//! Registers the caller as a producer, returning it a unique ID.
	virtual int	 register_producer();

	//! Returns the number of registered producers.
	int num_producers()	{ return m_n_prod; }

	/*! \brief	Returns true if the producer at the given index has written a value.
		\param	index	The index of the producer.  The order of producer indices matches the order in which ports were bound to the channel.
		The value for a given producer will be true if that producer has written a value that has
		not yet been read.
	*/
	bool is_writing( int index ) { return (m_unread_values[index] != 0); }


	/*	\brief	Returns the value that is being written by the given producer
		\param	index	The index of the producer.  The order of producer indices matches the order in which ports were bound to the channel.
		The value given for each producer is a pointer to the value
		that has been written by that producer but which has not yet been read.
	 */
	const T* value_being_written( int index )	{ return m_unread_values[index]; }
	
	//! Gives the number of producers who are writing values that have not yet been read.
	int num_writing() const { return m_num_unread; }

  protected:
	selector *m_selector_p;
	int m_n_prod;
	esc_mp_selector_type m_selector_t;
	sc_pvector<sc_event*> m_producer_events;
	char *m_producer_flags;
	T** m_unread_values;
	int m_num_unread;
	bool m_owns_selector;

	void end_of_elaboration()
	{
		esc_chan<T>::end_of_elaboration();

		// If no selector has been specified yet and we expected one, create a default one
		// and issue a warning.
		if ( !m_selector_p && (m_selector_t == esc_custom_select) )
		{
			m_selector_p = new selector( this );
			esc_report_error( esc_error, "%s: %s: A custom selector was expected, but none was specified via set_selector()\n",
								kind(), ((sc_prim_channel*)this)->name() );
		}

		// Tell the selector how many producers have been bound.
		m_selector_p->set_n_producers( m_n_prod );

		// Create as flags as there are producers.
		m_producer_flags = new char[ m_n_prod ];
		memset( m_producer_flags, '\0', m_n_prod*sizeof(char) );
		m_unread_values = (T**)new char[ m_n_prod*sizeof(T*) ];
		memset( m_unread_values, '\0', m_n_prod*sizeof(T*) );
	}
};

//------------------------------------------------------------------------------
//"esc_mp_chan::aread()"
//
//------------------------------------------------------------------------------
template <class T>
T esc_mp_chan<T>::aread( int id )
{
	// Find a producer to select.
	int producer = m_selector_p->select();

	if ( (producer < 0) || ( producer >= num_producers() ) )
	{
		esc_report_error( esc_error, "%s: %s: %s: Bad producer index given by selector.",
							ESC_CUR_TIME_STR, kind(), ((sc_prim_channel*)this)->name() );
		producer = 0;
	}

	// If the producer is already waiting, wake him up.
	// Otherwise, set its flag to tell it that it's been selected.
	if ( m_producer_flags[producer] )
		m_producer_events[producer]->notify();
	else
		m_producer_flags[producer] = 1;

	// Do a normal aread() which will block waiting for the selected producer to do an awrite.
	return esc_chan<T>::aread();
}

//------------------------------------------------------------------------------
//"esc_mp_chan::awrite()"
//
//------------------------------------------------------------------------------
template <class T>
void esc_mp_chan<T>::awrite( const T& value, int id )
{
	if ( ( id < 0 ) || ( id >= m_n_prod ) )
	{
		esc_report_error( esc_error, "%s: %s: %s: Attempt to write from an unregistered producer\n", 
								ESC_CUR_TIME_STR, kind(), ((sc_prim_channel*)this)->name() );
		return;
	}
	// If we've not yet been selected,  already selected, 
	// block waiting for this producer to be selected.  Mark the fact that we're waiting.
	if ( !m_producer_flags[id]  )
	{
		m_producer_flags[id] = 1;
		m_unread_values[id] = (T*)&value;
		m_num_unread++;
		wait( *m_producer_events[id] );
	}

	// Do a normal awrite() after being selected.
	m_producer_flags[id] = 0;
	m_unread_values[id] = 0;
	m_num_unread--;
	esc_chan<T>::awrite( value );
}

//------------------------------------------------------------------------------
//"esc_mp_chan::register_producer()"
//
//------------------------------------------------------------------------------
template <class T>
int	esc_mp_chan<T>::register_producer()
{
	// Create and store an event for the producer.
	m_producer_events.push_back( new sc_event );

	// Return unique ID and increment count.
	return m_n_prod++;
}


//==============================================================================
/*!
 	\class	esc_mc_chan
	\brief	A multi-consumer esc_chan class

	The esc_mc_chan class supports multiple consumers and a single producer.
	For value written to the channel, each registered consumer of the channel
	must read the value before the writer is un-blocked.
*/
//==============================================================================
template< class T > 
class esc_mc_chan : public esc_chan<T>
{
  public:
	/*! \brief Constructor
		\param name	The leaf name that will be given to the channel.
		\param proxy	The sc_object that this class is a sibling of.
	 */
	esc_mc_chan( const char *name_, sc_object* proxy=0 ) : 
		esc_chan<T>( name_, proxy ), m_aread_started_cons(0), m_aread_last_cons(0), m_aread_last(0xff)
	{}
	~esc_mc_chan()
	{
		delete m_aread_started_cons;
		delete m_aread_last_cons;
	}

    virtual const char*			kind() const 
    { 
    	return "esc_mc_chan"; 
    }

	bool valid_id( int id ) const
	{
		return ( (id >= 0) && (id < this->m_num_readers) );
	}

	//
	// Functions re-implemented from esc_chan<T>
	//
	 
    virtual T	 aread( int id=-1 );
    virtual void aread_done( int id=-1 );

  protected:
	unsigned char*	 m_aread_started_cons;	// Per-consumer bit saying who has started a read.
	unsigned char*	 m_aread_last_cons;		// Per-consumer bit identifying the last value read.
	unsigned char	 m_aread_last;			// 0 or 1 as a tag for the last value written.

	void end_of_elaboration()
	{
		esc_chan<T>::end_of_elaboration();

		if ( this->m_num_readers )
		{
			// Allocate and clear the per-consumer arrays.
			m_aread_started_cons = new unsigned char[ this->m_num_readers ];
			memset( m_aread_started_cons, 0, this->m_num_readers );
			m_aread_last_cons = new unsigned char[ this->m_num_readers ];
			memset( m_aread_last_cons, 0, this->m_num_readers );
		}
		else
		{
			esc_report_error( esc_error, "%s: %s: No consumers registered.\n",
								kind(), ((sc_prim_channel*)this)->name() );
		}
	}
};

//==============================================================================
// "esc_mc_chan<T>::aread()"
//==============================================================================
template <class T>
T esc_mc_chan<T>::aread( int id )
{
	assert( valid_id(id) );

	// If this consumer has started an aread() but not called aread_done(),
	// do it implicitly.
	if ( m_aread_started_cons[id] ) 
		aread_done( id );

	// If not all of our siblings have yet finished reading the last value,
	// wait for them to finish.
	if ( m_aread_last_cons[id] == m_aread_last )
    	wait( this->m_wake_producer );
	 
	// Wait for a value to be written if necessary.
    if ( !this->m_value_present ) 
	{
        this->m_waiting_consumer++;
    	wait( this->m_wake_consumer );
        this->m_waiting_consumer--;
	}

	// Decrement m_value_preset and mark this consumer's slot as having started an aread.  
	// Also mark which value this consumer has read.  See below for update of m_aread_started.
    this->m_value_present--;
	m_aread_started_cons[id] = 1;
	m_aread_last_cons[id] = m_aread_last;

	// Notify any awriter blocked waiting for the value to be consumed if m_value_present
	// has gone to 0.
	// We avoid triggering the m_wake_producer event unless its know that an awrite() is blocked 
	// waiting on it so that we avoid un-blocking a writer that is waiting for an aread_done() instead.
	if ( this->m_awrite_started && !this->m_value_present )
		this->m_wake_producer.notify();

	if ( this->m_value_present == ( this->m_num_readers-1 ) )
	{
		// This is the first consumer to read the value.

		// Set the m_aread_started member such that it will reach 0 after the last consumer
		// has done an aread_done().  This hysteresis assures that all readers will do both
		// an aread() and an aread_done() before the value is seen as having been read.
        this->m_aread_started = this->m_num_readers;

		// Place an extra lock on the value for each secondary reader.
		for ( int i=0; i<this->m_num_readers-1; i++ )
			esc_msg_lock<T>( &this->m_value );

		// Notify the watchers that the read has started.
		// A read_start/read_end pair for an esc_mc_chan is the time from the
		// first reader reading to that last reader doing aread_done().
		notify_read_start( &this->m_value );
	}

    return this->m_value;
}

//==============================================================================
// "esc_mc_chan<T>::aread_done()"
//==============================================================================
template <class T>
void esc_mc_chan<T>::aread_done( int id )
{
	assert( valid_id(id) );
	
	if ( m_aread_started_cons[id] )
	{
        this->m_aread_started--;
		m_aread_started_cons[id] = 0;

		// External observers and writers are notified only when all readers finish.
		if ( this->m_aread_started == 0 )
		{
			// Wake any writers blocked waiting for a read to complete.
            this->m_wake_producer.notify();

			// Change the mark on the last value read after all have read it.
			m_aread_last = ~m_aread_last;

			// Notify watchers only if this is the last aread to finish.
			notify_read_end( &this->m_value );
		}
	}
	else
	{
		esc_report_error( esc_error, "%s: %s: %s: aread_done() called without a preceding aread() from consumer #%d\n", 
				ESC_CUR_TIME_STR, kind(), ((sc_prim_channel*)this)->name(), id );
	}
}

/*!==============================================================================
//	\class	esc_term_chan
//	\brief	A terminal channel
//
//	An esc_term_chan may have producers, but not consumers.  It is designed to model
//	a channel at the periphery of the design.  Typically, an sc_module with an 
//	esc_chan<T>::out port will be bound to an esc_term_chan<T> when there is no
//	consumer model to be placed at the other end of the channel.
//
//	An esc_term_chan behaves as though it has an infinite sink as a consumer.  To 
//	the writer, it appears as though each value written is immediately consumed.
//	
//	An esc_term_chan may be watched as an esc_watchable<T>.  Unlike most other esc_chan
//	classes, esc_term_chan generates only ESC_WRITE_START_EVENT and ESC_WRITE_END_EVENT
//	events.
//
//	Because there is no consumer reading from an esc_term_chan, the esc_term_chan
//	will remove locks from values written to it using esc_msg_unlock.  An overload
//	of this function must be provided whenever esc_term_chan<T> is used where T
//	is a pointer to an esc_msg* subclass.
//	
//==============================================================================
*/
template< class T > 
class esc_term_chan : public esc_chan<T>
{
  public:
	//! Constructor
	esc_term_chan( const char* name=0, sc_object* proxy=0 )
		: esc_chan<T>( name, proxy )
	{}

	// 
	// Functions reimplemented from esc_chan_in_if
	//

    virtual bool				is_empty() 
    { 
    	return true; 
    }
    virtual const char*			kind() const 
    { 
    	return "esc_term_chan"; 
    }
	// Illegal functions.
    virtual T					aread( int id=-1 )		{ show_err(); return this->m_value; }
    virtual void				aread_done( int id=-1 )	{ show_err(); }
    virtual T					read( int id=-1 )		{ show_err(); return this->m_value; }

	//
	// Functions reimplemented from esc_chan_out_if
	//    
    virtual void				awrite( const T& value, int id=-1 )
	{
        this->m_value = value;
		notify_write_start( &value );
	}
    virtual bool				is_full() 
    { 
    	return false; 
    }
    virtual bool				is_read_done()
	{
		return true;
	}	
    virtual void				wait_read_done()
	{
		notify_write_end( &this->m_value );
		esc_msg_unlock<T>( &this->m_value );
	}

	virtual esc_event_type		notify_events() 
	{ 
		return (ESC_WRITE_START_EVENT | ESC_WRITE_END_EVENT); 
	}

  protected:
	void show_err()
	{
		esc_report_error( esc_error, "%s: %s: %s: An esc_term_chan cannot be read from.\n", 
							ESC_CUR_TIME_STR, kind(), ((sc_prim_channel*)this)->name() );
	}
};


//==============================================================================
/*!
 	\class	esc_chan_holder
	\brief	A proxy for to an esc_chan

	This class acts as a proxy for an esc_chan class.  An esc_chan_holder contains
	an instance of the esc_chan class given the the template paramater T_CHAN.  It 
	implements all of it's interface functions by simply calling the same function
	on the esc_chan object it contains.

	The esc_chan_holder class is useful for multiple inheritance applications where 
	a derived class requires the esc_chan interfaces and must also derive from a class
	related to sc_object such as sc_module.  Since esc_chan subclasses are also derived
	from sc_object, this causes ambiguities.  In such cases, an application can simply
	derive from esc_chan_holder<T,T_CHAN> where T_CHAN is the esc_chan<T> class it would
	logically derive from.
*/
//==============================================================================
template< class T, class T_CHAN=esc_chan<T> > 
class esc_chan_holder :
    public esc_chan_in_if<T>, 
    public esc_chan_out_if<T> 
{
  public:
	/*! \brief Constructor
		\param proxy	The sc_object that this class is a sibling of.
	 */
	esc_chan_holder( sc_object* proxy )
		: m_chan( (proxy ? (cynw_string(proxy->basename()) + cynw_string("_esc_chan")) : "esc_chan"), proxy )
	{}

    virtual bool is_empty()				{ return m_chan.is_empty(); }
    operator T () 
    { 
    	return read(); 
    }
    esc_chan<T>& operator = ( const T& value ) 
    { 
    	write( value ); 
    	return *this; 
    }
    virtual T	 aread( int id=-1 )			{ return m_chan.aread( id ); }
    virtual void aread_done( int id=-1 )	{ m_chan.aread_done( id ); }
	virtual bool configure_in( unsigned int code, void* param=0 )
											{ return m_chan.configure_in( code, param ); }
	virtual bool configure_out( unsigned int code, void* param=0 )
											{ return m_chan.configure_out( code, param ); }
    virtual T	 read( int id=-1 )			{ return m_chan.read( id ); }
	virtual int	 register_consumer()		{ return m_chan.register_consumer(); }

    virtual void awrite( const T& value, int id=-1 )
											{ m_chan.awrite( value, id ); }
    virtual bool is_full() 					{ return m_chan.is_full(); }
    virtual bool is_read_done()				{ return m_chan.is_read_done(); }
	virtual int	register_producer()			{ return m_chan.register_producer(); }
    virtual void wait_read_done()			{ m_chan.wait_read_done(); }
    virtual void write( const T& value, int id=-1 )
											{ m_chan.write( value, id ); }

	virtual void add_watcher( esc_watcher<T>* watcher, esc_event_type events=ESC_ALL_EVENTS )
											{ m_chan.add_watcher( watcher, events ); }
	virtual esc_event_type notify_events() 	{ return m_chan.notify_events(); }
  protected:
	T_CHAN m_chan;
};

//==============================================================================
/*!
 	\class	esc_chan_in_holder
	\brief	A proxy for the esc_chan_in_if of an esc_chan class

	This class acts as a proxy for an esc_chan class that will supply the implementation
	of the esc_chan_in_if.  An esc_chan_in_holder instantiates an instance of 
	an esc_chan class for the given data type.  The esc_chan_in_if interface
	is implemented by passing the calls along to the held esc_chan.
	
	The default esc_chan class used is esc_pp_chan.  However, the optional
	second template parameter can be used to override this with any class
	that implements the esc_chan_in_if interface.

	Applications of esc_chan_in_holder are similar to those for esc_chan_holder.  esc_chan_in_holder
	is the appropriate choice when it is desired that only the esc_chan_in_if be exported
	from the held esc_chan class.Like esc_chan_holder, esc_chan_in_holder is useful for multiple inheritance
	applications where a subclass must also derive from an sc_primitive_channel such as 
	sc_module.  It allows these applications to be built without producing ambiguous functions.
*/
//==============================================================================
template< class T, class T_CHAN=esc_pp_chan<T> > 
class esc_chan_in_holder :
    public esc_chan_in_if<T>
{
  public:
	/*! \brief Constructor
		\param proxy	The sc_object that this class is a sibling of.
	 */
	esc_chan_in_holder( sc_object* proxy=0 )
		: m_chan_in( ((proxy!=0) ? (cynw_string(proxy->basename()) + cynw_string("_esc_chan_in")) : cynw_string("in_if")), proxy )
	{}

    virtual bool is_empty()				{ return m_chan_in.is_empty(); }
    operator T () 
    { 
    	return read(); 
    }
    virtual T aread( int id=-1 )		{ return m_chan_in.aread( id ); }
    virtual void aread_done( int id=-1 ){ m_chan_in.aread_done( id ); }
	virtual bool configure_in( unsigned int code, void* param=0 )
											{ return m_chan_in.configure_in( code, param ); }
    virtual T read( int id=-1 )		{ return m_chan_in.read( id ); }
	virtual int	 register_consumer()	{ return m_chan_in.register_consumer(); }

	virtual void add_watcher( esc_watcher<T>* watcher, esc_event_type events=ESC_ALL_EVENTS )
											{ m_chan_in.add_watcher( watcher, events ); }
	virtual esc_event_type notify_events() 	{ return m_chan_in.notify_events(); }
  protected:
	T_CHAN m_chan_in;	// The channel whose esc_chan_in_if is proxied.
};

//==============================================================================
/*!
 	\class	esc_chan_out_holder
	\brief	A proxy for the esc_chan_out_if of an esc_chan class

	This class acts as a proxy for an esc_chan class that will supply the implementation
	of the esc_chan_out_if.  An esc_chan_out_holder instantiates an instance of 
	an esc_chan class for the given data type.  The esc_chan_out_if interface
	is implemented by passing the calls along to the held esc_chan.
	
	The default esc_chan class used is esc_pp_chan.  However, the optional
	second template parameter can be used to override this with any class
	that implements the esc_chan_out_if interface.

	Applications of esc_chan_out_holder are similar to those for esc_chan_holder.  esc_chan_out_holder
	is the appropriate choice when it is desired that only the esc_chan_out_if be exported
	from the held esc_chan class.Like esc_chan_holder, esc_chan_out_holder is useful for multiple inheritance
	applications where a subclass must also derive from an sc_primitive_channel such as 
	sc_module.  It allows these applications to be built without producing ambiguous functions.
*/
//==============================================================================
template< class T, class T_CHAN=esc_pp_chan<T> > 
class esc_chan_out_holder :
    public esc_chan_out_if<T>
{
  public:
	/*! \brief Constructor
		\param proxy	The sc_object that this class is a sibling of.
	 */
	esc_chan_out_holder( sc_object* proxy=0 )
		: m_chan_out( ((proxy!=0) ? (cynw_string(proxy->basename()) + cynw_string("_esc_chan_out")) : cynw_string("out_if")), proxy )
	{}

    virtual void awrite( const T& value, int id=-1 )
											{ m_chan_out.awrite( value, id ); }
	virtual bool configure_out( unsigned int code, void* param=0 )
											{ return m_chan_out.configure_out( code, param ); }
    virtual bool is_full() 					{ return m_chan_out.is_full(); }
    virtual bool is_read_done()				{ return m_chan_out.is_read_done(); }
	virtual int	register_producer()			{ return m_chan_out.register_producer(); }
    virtual void wait_read_done()			{ m_chan_out.wait_read_done(); }
    virtual void write( const T& value, int id=-1 )
											{ m_chan_out.write( value, id ); }

  protected:
	T_CHAN m_chan_out;	// The channel whose esc_chan_out_if is proxied.
};

//==============================================================================
/*!
 	\class	esc_2chan_holder
	\brief	A proxy for two esc_chan objects

	This class acts as a proxy for two esc_chan classes, one of which will supply
	the esc_chan_in_if implementation, and the other of which will supply the 
	esc_chan_out_if implementations.  An esc_2chan_holder contains one instance of
	each of the esc_chan classes given: T_SOURCE_CHAN and T_TARGET_CHAN.  The data types
	of the two channels need not be the same.  The template parameter T_SOURCE gives the
	data type used in the esc_chan_out_if, and the T_TARGET parameter gives the data
	type used in the esc_chan_in_if.  If only one data type is given, then
	the output data type defaults to the specified input data type.

	Applications of esc_2chan_holder are similar to those for esc_chan_holder.  esc_2chan_holder
	is the appropriate choice when different data types and/or esc_chan subclasses must
	be combined.  Like esc_chan_holder, esc_2chan_holder is useful for multiple inheritance
	applications where a subclass must also derive from an sc_primitive_channel such as 
	sc_module.  It allows these applications to be built without producing ambiguous functions.
*/
//==============================================================================
template< class T_SOURCE, class T_TARGET=T_SOURCE, class T_SOURCE_CHAN=esc_pp_chan<T_SOURCE>, class T_TARGET_CHAN=esc_pp_chan<T_TARGET> > 
class esc_2chan_holder :
    public esc_chan_out_holder<T_SOURCE,T_SOURCE_CHAN>,
    public esc_chan_in_holder<T_TARGET,T_TARGET_CHAN>
{
  public:
	/*! \brief Default constructor.
	 */
	esc_2chan_holder()
	{}

	/*! \brief Constructor that supplies a proxy module.
		\param proxy	The sc_object that this class is a sibling of.

		If a proxy sc_module is given, then when that sc_module is logged, the
		held target_chan() will be the entity that's logged.
	 */
	esc_2chan_holder( sc_object* proxy )
		: esc_chan_out_holder<T_SOURCE,T_SOURCE_CHAN>( proxy ),
		  esc_chan_in_holder<T_TARGET,T_TARGET_CHAN>( 0 ) // The proxy can only be sent to one esc_chan.
	{}

	/*! \brief The source channel from which data values are read by the main thread.

		Values are read from the source_chan() and written to the target_chan().
		The source_chan() channel is also the channel to which values are written by 
		other modules.
	 */
	T_SOURCE_CHAN& source_chan() { return this->m_chan_out; }

	/*! \brief The target channel to which data values are written by the main thread.

		Values are read from the source_chan() and written to the target_chan().
		The target_chan() channel is also the channel from which values are read by 
		other modules.
	 */
	T_TARGET_CHAN& target_chan() { return this->m_chan_in; }

  protected:
};


//==============================================================================
/*!
 	\class	esc_chan_conn
	\brief	A module that connects two esc_chan's that carry the same data type.

	An esc_chan_conn connects two esc_chan's carrying the same data type by reading 
	values from one and writing values to the other.  It provides a useful way of 
	connecting two esc_chan's with different behavior.  The following example
	shows how an esc_mp_chan and an esc_mc_chan can be combined to create a 
	channel that supports multiple producers and multiple consumers.

	\code
	
	esc_chan_conn< int, esc_mp_chan<int>, esc_mc_chan<int> > my_mp_mc_chan( "my_mp_mc_chan" );

	\endcode

	An esc_chan_conn contains instances of the two esc_chan classes given in the 
	template parameters.  The second template argument, T_SOURCE_CHAN, gives the 
	esc_chan that will provide the esc_chan_out_if to which external modules will write.
	The third template argument, T_TARGET_CHAN, gives the esc_chan that will provide the 
	esc_chan_in_if from which external modules will read.

	The underlying esc_chan's can be accessed using the source_chan() and target_chan()
	functions.  Since the underlying esc_chan's are constructed out of the user's control,
	access later access may be required to those esc_chan's for configuration purposes.
	The following example shows how the my_mp_mc_chan from the preceding example can have
	the selector set for it's source_chan():

	\code

	esc_ran_dist_exponential selector_ran_dist( "exp_dist" );
	my_mp_mc_chan.source_chan().set_selector( selector_ran_dist );

	\endcode
	
	The esc_chan_conn class may be instantiated directly for connections that only
	require the default behavior.  Alternately, classes may be derived from esc_chan_conn 
	to provide different behaviors.  For example, the following class overloads the 
	main() thread function to insert a given number of clocks between source and 
	target values:

	Note that since an esc_chan_conn is itself an sc_module, derived classes may add
	ports as required.  If a derived class adds ports, it should pass 'false' for the
	call_end_module constructor parameter.

	For applications that require the connection of channels with different data types,
	user-defined interfaces, or signal-level interfaces, the esc_adaptor class hierarchy
	provides a more appropriate solution.  See the documentation for esc_adator.h 
	on the "File List" page for details.
*/
//==============================================================================
template< class T, class T_SOURCE_CHAN=esc_pp_chan<T>, class T_TARGET_CHAN=esc_pp_chan<T> > 
class esc_chan_conn :
	public sc_module,
    public esc_2chan_holder<T,T,T_SOURCE_CHAN,T_TARGET_CHAN>
{

  public:
	SC_HAS_PROCESS(esc_chan_conn);

	/*! \brief Constructor
		\param name	The name that will be given to the sc_module.
		\param call_end_module 'true' if end_module() will be called, 'false' if it should not be.  Derived classes that add their own ports should specify 'false'.
	 */
	esc_chan_conn( const char *name, bool call_end_module=true )
		: sc_module(name),
		  esc_2chan_holder<T,T,T_SOURCE_CHAN,T_TARGET_CHAN>( this )
	{
		SC_THREAD(main);
		if ( call_end_module )
			end_module();
	}

  protected:
	/*!	\brief	Thread main function
		The default implementation reads from the source_chan() and writes to the target_chan().
		Blocking reads and writes are performed such that other modules that read the target_chan()
		will be blocked until values are written by other modules to the source_chan() and vice-versa.
	 */
	virtual void main()
	{
		while (1)
		{
            this->target_chan().write( this->source_chan().aread() );
            this->source_chan().aread_done();
		}
	}
};


/*!
//==============================================================================
	\class esc_chan_encoder 
	\brief Transaction encoder for writing to an esc_chan.

	This class provides an encoder that implements it's target interface by 
	creating a corresponding transaction object and writing it to an esc_chan.
	A calls to an interface function in the encoder will block until the write() 
	to the esc_chan un-blocks.

	The esc_chan_encoder class can be used in a fashion similar to an esc_chan_txout
	port class.  This makes esc_chan_encoder a convenient replacement for esc_chan_txout
	for code that is not in an sc_module.

	For example, if an esc_chan is declared to carry a transaction object as:

	\code
		 esc_chan<my_tx*>	mytx_chan;
	\endcode

	then if the interface my_if contains a function with the signature "void send( int val )",
	a function could be written to write transactions to the channel using an esc_chan_encoder as:

	\code
		void f( esc_chan<my_tx>* chan_p )
		{
			esc_chan_encoder< my_if > outchan( chan_p );
			outchan.send( 10 );
		}
	\endcode

	Then the function could be called for a particular esc_chan instance as:

	\code
	 	f( &mytx_chan );
	\endcode

	which will result in a 'send' transaction being created by the encoder and written to 
	the mytx_chan channel.

	The template parameter T must be either an interface class (_if) or a transaction
	base class (_tx) for the target interface produced by hubsync.

/==============================================================================
*/
template< class T > 
class esc_chan_encoder 
	: public T::esc_chan_encoder_t
{
  public:
	typedef esc_chan_out_if< typename T::tx_t* >	if_type;
	typedef typename T::esc_chan_encoder_t			base_type;

	esc_chan_encoder( if_type *target=0 ) : base_type( target )
	{}
};

/*!
//==============================================================================
// \class esc_chan_in 
// \brief Channel input port.
//
// This class provides the input port for reading from an esc_chan instance.
//==============================================================================
*/
template< class T > class esc_chan_in : public sc_port<esc_chan_in_if<T>,1> 
{
  public:
    typedef T                         data_type;

    typedef esc_chan_in_if<data_type> if_type;
    typedef sc_port<if_type,1>        base_type;
    typedef esc_chan_in<data_type>    this_type;

    typedef if_type                   in_if_type;
    typedef sc_port_b<in_if_type>     in_port_type;

  public:
    esc_chan_in() : base_type(), m_consumer_id(-1) {}
    explicit esc_chan_in( const char* name ) : base_type(name) {}
    esc_chan_in( in_if_type& interface_ ) : 
    	base_type( interface_ ) { do_reg(interface_); }
    esc_chan_in( const in_if_type& interface_ ) : 
    	base_type( CCAST<in_if_type&>( interface_ ) ) { do_reg(interface_); }
    esc_chan_in( const char* name, in_if_type& interface_ ) : 
        base_type( name, interface_ ) { do_reg(interface_); }
    esc_chan_in( const char* name, const in_if_type& interface_ ) : 
        base_type( name, CCAST<in_if_type&>( interface_ ) ) { do_reg(interface_); }
    esc_chan_in( const char* name, in_port_type& parent ) : 
        base_type( name, parent) {}
    esc_chan_in( this_type& parent ) : base_type( parent ) {}
    esc_chan_in( const char* name, this_type& parent ) : 
        base_type( name, parent) {}

    // bind to in interface

    void bind( in_if_type& interface_ )
	{ sc_port_base::bind( interface_ ); do_reg(interface_); }

    void bind( const in_if_type& interface_ )
	{ bind( CCAST<in_if_type&>( interface_ ) ); }

    void operator () ( const in_if_type& interface_ )
	{ bind( CCAST<in_if_type&>( interface_ ) ); }

    void operator () ( in_if_type& interface_ )
	{ bind( interface_ ); }

    // bind to parent in port

    void bind( in_port_type& parent_ )
        { sc_port_base::bind( parent_ ); }

    void operator () ( in_port_type& parent_ )
        { sc_port_base::bind( parent_ ); }


    virtual ~esc_chan_in() {}

  public:
    data_type aread()				{ return (*this)->aread(m_consumer_id); }
    void aread_done()				{ (*this)->aread_done(m_consumer_id); }
	bool configure_in( unsigned int code, void* param=0 )
									{ return (*this)->configure_in( (code & ~(ESC_RESET_OUT|ESC_POWERON_OUT)), param ); }
    bool is_empty()					{ return (*this)->is_empty(); }
    const char* kind() const 		{ return "esc_chan_in"; }
    operator T () 					{ return (*this)->read(m_consumer_id); }
    data_type read()				{ return (*this)->read(m_consumer_id); }
	void add_watcher( esc_watcher<T>* watcher, esc_event_type events=ESC_ALL_EVENTS )
	{
		if ( sc_get_curr_simcontext()->is_running() )
		{
			// If this happens after elab, just add the watcher.
			(*this)->add_watcher( watcher, events );
		}
		else
		{
			// If this occurs before a watchable has been bound, queue it up.
			queue_add_watcher( watcher, events );
		}
	}


	/*! \brief	Gives the ID of this channel that will be passed to the target channel.
	 *	When the esc_chan_txin port reads encoded operations frin the target channel,
	 *	it passes this consumer_id() as an identification of the reading module.  This
	 *	is important for esc_chan subclasses that support multiple consumers such as
	 * 	esc_mc_chan<T>.  Ordinarily, when reading transactions through a port, users need
	 *	not provide the consumer_id() themselves.
	 *
	 *	When the -> operator in the sc_port<T> base class is used on an esc_chan_txin
	 *	port to directly access the target channel, the caller must supply the consumer_id()
	 *	value directly because the esc_chan_txin port is not involved.  This can be done
	 *	as follows:
	 *
	 *	\code
	 *	esc_chan_txin<my_if>	iport;	// Port declaration.
	 *	...
	 *
	 *	// Directly reading to the target port using the consumer_id stored in the port.
	 *	my_tx* mytx = iport->read( iport.consumer_id() );
	 *	\endcode
	 *
	 *	The consumer_id() need not be passed unless the target channel supports multiple consumers.
	 */
	int consumer_id() { return m_consumer_id; }
  protected:
    void end_of_elaboration()
	{
		// Register any watchers added during elab.
		for ( queued_add_watcher** qe = m_queued_watchers.begin(); qe != m_queued_watchers.end(); qe++ ) 
		{
			(*this)->add_watcher( (*qe)->m_watcher_p, (*qe)->m_events );
			delete (*qe);
		}

		sc_port_base::end_of_elaboration();
	}

	//! \internal
	// Called at port binding time to cause registration with channel.
	void do_reg( in_if_type& iface )
	{
		m_consumer_id = iface.register_consumer(); 		
	}
	int m_consumer_id;

  private: // Disabled actions.
    esc_chan_in( const this_type& );
    this_type& operator = ( const this_type& );

	struct queued_add_watcher
	{
		queued_add_watcher( esc_watcher<T>* watcher, esc_event_type events ) 
			: m_watcher_p(watcher), m_events(events) 
		{}
		esc_watcher<T>* m_watcher_p;
		esc_event_type m_events;
	};

	sc_pvector<queued_add_watcher*> m_queued_watchers;

	//! \internal
	// Queue an add_watcher request.
    void queue_add_watcher( esc_watcher<T>* watcher, esc_event_type events )
	{
		m_queued_watchers.push_back( new queued_add_watcher(watcher, events ) );
	}

};

/*!
//==============================================================================
// \class esc_chan_out_base 
// \brief Base class for esc_chan output port classes.
//
// This class provides a common base class for the esc_chan_out and esc_chan_txout
// port classes, primarily to support port registration with the esc_chan.
//==============================================================================
*/
template< class T > 
class esc_chan_out_base : public sc_port<esc_chan_out_if<T>,1> 
{
  public:
    typedef T                          data_type;

    typedef esc_chan_out_if<data_type> if_type;
    typedef sc_port<if_type,1>         base_type;
    typedef esc_chan_out_base<data_type>   this_type;

    typedef if_type                    out_if_type;
    typedef sc_port_b<out_if_type>     out_port_type;

  public:
    esc_chan_out_base() : base_type(), m_producer_id(-1)  {}
    explicit esc_chan_out_base( const char* name ) : base_type(name) {}
    esc_chan_out_base( out_if_type& interface_ ) : base_type( interface_ ) {do_reg(interface_);}
    esc_chan_out_base( const out_if_type& interface_ ) : base_type( CCAST<out_if_type&>( interface_ ) ) {do_reg(interface_);}
    esc_chan_out_base( const char* name, out_if_type& interface_ ) : 
        base_type( name, interface_) {do_reg(interface_);}
    esc_chan_out_base( const char* name, const out_if_type& interface_ ) : 
        base_type( name, CCAST<out_if_type&>( interface_ ) ) {do_reg(interface_);}
    esc_chan_out_base( const char* name, out_port_type& parent ) : 
        base_type( name, parent) {}
    esc_chan_out_base( this_type& parent ) : base_type( parent ) {}
    esc_chan_out_base( const char* name, this_type& parent ) : 
        base_type( name, parent) {}

    // bind to out interface

    void bind( out_if_type& interface_ )
		{ sc_port_base::bind( CCAST<out_if_type&>( interface_ ) ); do_reg(interface_); }

    void bind( const out_if_type& interface_ )
		{ bind( CCAST<out_if_type&>( interface_ ) ); }

    void operator () ( const out_if_type& interface_ )
		{ bind( CCAST<out_if_type&>( interface_ ) ); }

    void operator () ( out_if_type& interface_ )
		{ bind( interface_ ); }

    // bind to parent in port

    void bind( out_port_type& parent_ )
        { sc_port_base::bind( parent_ ); }

    void operator () ( out_port_type& parent_ )
        { sc_port_base::bind( parent_ ); }


    virtual ~esc_chan_out_base() {}

	//! \internal
	// Called at port binding time to cause registration with channel.
	void do_reg( out_if_type& iface )
	{
		m_producer_id = iface.register_producer(); 		
	}
	/*! \brief	Gives the ID of this channel that will be passed to the target channel.
	 *	When the esc_chan_txout port writes encoded operations to the target channel,
	 *	it passes this producer_id() as an identification of the writing module.  This
	 *	is important for esc_chan subclasses that support multiple producers such as
	 * 	esc_mp_chan<T>.  Ordinarily, when writing transactions through a port, users need
	 *	not provide the producer_id() themselves.
	 *
	 *	When the -> operator in the sc_port<T> base class is used on an esc_chan_txout
	 *	port to directly access the target channel, the caller must supply the producer_id()
	 *	value directly because the esc_chan_txout port is not involved.  This can be done
	 *	as follows:
	 *
	 *	\code
	 *	esc_chan_txout<my_if>	oport;	// Port declaration.
	 *	...
	 *	my_tx* mytx = ...;	// A transaction object obtained somehow.
	 *
	 *	// Directly writing to the target port using the producer_id stored in the port.
	 *	oport->write( mytx, oport.producer_id() ); 
	 *	\endcode
	 *
	 *	The producer_id() need not be passed unless the target channel supports multiple producers.
	 */
	int producer_id() { return m_producer_id; }
  public:   
  protected:
	int m_producer_id;
};



/*!
//==============================================================================
// \class esc_chan_out 
// \brief Channel output port.
//
// This class provides the output port for writing to an esc_chan instance.
//==============================================================================
*/
template< class T > 
class esc_chan_out : public esc_chan_out_base<T>
{
  public:
    typedef T                          data_type;

    typedef esc_chan_out_if<data_type> if_type;
    typedef esc_chan_out_base<data_type> base_type;
    typedef esc_chan_out<data_type>    this_type;

    typedef if_type                    out_if_type;
    typedef sc_port_b<out_if_type>     out_port_type;

  public:
    esc_chan_out() : base_type() {}
    explicit esc_chan_out( const char* name ) : base_type(name) {}
    esc_chan_out( out_if_type& interface_ ) : base_type( interface_ ) {}
    esc_chan_out( const out_if_type& interface_ ) : base_type( interface_ ) {}
    esc_chan_out( const char* name, out_if_type& interface_ ) : 
        base_type( name, interface_) {}
    esc_chan_out( const char* name, const out_if_type& interface_ ) : 
        base_type( name, interface_) {}
    esc_chan_out( const char* name, out_port_type& parent ) : 
        base_type( name, parent) {}
    esc_chan_out( this_type& parent ) : base_type( parent ) {}
    esc_chan_out( const char* name, this_type& parent ) : 
        base_type( name, parent) {}

  public:   
    void awrite( const data_type& value )				{ (*this)->awrite( value, this->m_producer_id ); }
	bool configure_out( unsigned int code, void* param=0 )	{ return (*this)->configure_out( (code & ~(ESC_RESET_IN|ESC_POWERON_IN)), param ); }
    bool is_full()										{ return (*this)->is_full(); }
    bool is_read_done()									{ return (*this)->is_read_done(); }
    const char* kind() const 							{ return "esc_chan_out"; }
    const esc_chan_out<T>& operator = ( const T& value ){ (*this)->write(value); return *this; }
    void wait_read_done()								{ (*this)->wait_read_done(); }
    void write( const data_type& value )				{ (*this)->write( value, this->m_producer_id ); }
};

/*!
//==============================================================================
	\class esc_chan_txout 
	\brief Encoding port class for an interface that connects to an esc_chan.

	This class provides the an output port for a channel class that contains
	an encoder for a specific interface.  When a function in the interface is called,
	an encoded transaction is created for the function call and written to the 
	esc_chan bound to the port.  The interface function returns when the channel's
	write() function un-blocks.

	This port is ordinarily instantiated using an interface class as a template argument.
	For example, if a declaration appears in module X of the form:

	\code
		esc_chan_txout< my_if >	outchan;
	\endcode

	and an esc_chan templated on a pointer to the associated transaction class 
	is declared as:

	\code
	 esc_chan< my_tx* >	mytx_chan;
	\endcode

	then the port can be connected to the channel like this:

	\code
	 X x;
	 x.outchan( mytx_chan );
	\endcode

	If the interface my_if contains a function with the signature "void send( int val )",
	then from within module X, the port can be written to as follows:

	\code
	outchan.send( 10 );
	\endcode

	which will result in a 'send' transaction being encoded by the port and written to 
	the mytx_chan channel.

	The template argument T may either be a transaction class, or an interface class
	produced by hubsync.

//==============================================================================
*/
template< class T > 
class esc_chan_txout 
	:	public esc_chan_out_base<typename T::tx_t*>,
		public T::encoder_t
{
  public:
	typedef typename T::tx_t				tx_type;
	typedef typename tx_type::encoder_t		encoder_type;

    typedef tx_type*                    	data_type;

    typedef esc_chan_out_if<data_type>		if_type;
    typedef esc_chan_out_base<data_type>	base_type;
    typedef esc_chan_txout<T>				this_type;

    typedef if_type							out_if_type;
    typedef sc_port_b<out_if_type>			out_port_type;


  public:
    esc_chan_txout() 
    	: esc_chan_out_base< T >(), encoder_type( &m_encoder_target ), base_type(), m_encoder_target(this), m_do_blocking_write(true) {}
    explicit esc_chan_txout( const char* name ) 
    	: esc_chan_out_base< T >(), encoder_type( &m_encoder_target ), base_type(name), m_encoder_target(this), m_do_blocking_write(true) {}

    esc_chan_txout( if_type& interface_ )
    	: esc_chan_out_base< T >(), encoder_type( &m_encoder_target ), m_encoder_target(this), m_do_blocking_write(true) 
    	{ base_type::bind( interface_ ); }
    esc_chan_txout( const if_type& interface_ )
    	: esc_chan_out_base< T >(), encoder_type( &m_encoder_target ), m_encoder_target(this), m_do_blocking_write(true)
    	{ base_type::bind( interface_ ); }

    esc_chan_txout( const char* name, out_if_type& interface_ )
		: esc_chan_out_base< T >(), encoder_type( &m_encoder_target ), base_type( name, interface_), m_encoder_target(this), m_do_blocking_write(true) {}
    esc_chan_txout( const char* name, const out_if_type& interface_ )
		: esc_chan_out_base< T >(), encoder_type( &m_encoder_target ), base_type( name, interface_), m_encoder_target(this), m_do_blocking_write(true) {}
    esc_chan_txout( const char* name, out_port_type& parent )
		: esc_chan_out_base< T >(), encoder_type( &m_encoder_target ), base_type( name, parent), m_encoder_target(this), m_do_blocking_write(true) {}
    esc_chan_txout( this_type& parent ) 
    	: esc_chan_out_base< T >(), encoder_type( &m_encoder_target ), base_type( parent ), m_encoder_target(this), m_do_blocking_write(true) {}
    esc_chan_txout( const char* name, this_type& parent )
		: esc_chan_out_base< T >(), encoder_type( &m_encoder_target ), base_type( name, parent), m_encoder_target(this), m_do_blocking_write(true) {}

	/*!	\brief	Configures whether or not blocking writes will be done to the target channel.
		\param s	true if blocking writes are to be done, false if non-blocking writes are to be done.
				
		When an interface function is called on an esc_chan_txout port, the port's encoder
		creates a transaction value and writes it to the target channel.  Ordinarily, a blocking
		write is performed such that the interface call will not return until the transaction
		has been fully read by the channel's consumer.  This behavior can be changed by calling
		set_do_blocking_write().  If set_do_blocking_write(false) is called on an esc_chan_txout port,
		then interface function calls to the port will return as soon as the transaction can be 
		written to the port rather than after the value has been read.
	 */
	void set_do_blocking_write( bool s=false )
	{
		m_do_blocking_write = s;
	}

	/*	\brief	Gives the target channel to which the port is bound.

		The target_chan() function is useful in cases where the target channel must be 
		interacted with directly rather than indirectly through the port's encoder.  This
		is necessary either when transaction values are written directly to the port using
		awrite() or write(), or for ports that do not do blocking writes where the module 
		must later wait for the read to finish using wait_read_done() or is_read_done().
	 */
	out_if_type& target_chan()
	{
		return *((*this)[0]);
	}
  public:   
  protected:
	/*! \internal
		Acts as a target of the encoder.  Writes the encoded tx value to
		the channel with this port's id.  It chooses between write() and awrite()
		based on whether the port is configured for blocking or non-blocking writes.
	 */
	class chan_tx_writer;
	friend class chan_tx_writer ;
	class chan_tx_writer : public esc_encoder_target<typename T::tx_ref_t>
	{
	  public:
		chan_tx_writer( esc_chan_txout<T> *port_p ) : m_port_p(port_p)
		{}
		inline void write_tx( typename T::tx_ref_t val ) 
		{
			if ( m_port_p->m_do_blocking_write )
				m_port_p->target_chan().write( val, m_port_p->producer_id() ); 
			else
				m_port_p->target_chan().awrite( val, m_port_p->producer_id() ); 
		}
		esc_chan_txout<T> *m_port_p;
	};
	chan_tx_writer m_encoder_target;
	bool m_do_blocking_write;
};

//! \internal
//! Provided for backwards compatibility with pre-release versions of ESC.
#define ESC_CHAN_TXOUT(txbase) \
	esc_chan_txout< txbase##_tx >

/*!
//==============================================================================
	\class esc_chan_txin 
	\brief Decoding port class for an interface that connects to an esc_chan.

	This class provides an input port for an esc_chan that carries encoded transactions.
	The port continually reads encoded transactions from the esc_chan to which it's
	bound, decodes the transactions it reads, then calls the appropriate interface 
	function on the parent module.

	The port is designed to operate in a thread owned by the parent module.  

	This port is ordinarily instantiated using an interface class as a template argument.
	For example, if a declaration appears in module X of the form:

	\code
		esc_chan_txout< my_if >	inchan;
	\endcode

	and an esc_chan templated on a pointer to the associated transaction class 
	is declared as:

	\code
		esc_chan< my_tx* >	mytx_chan;
	\endcode

	then the port can be connected to the channel like this:

	\code
		X x;
		x.inchan( mytx_chan );
	\endcode

	If module X configures the inchan port as follows in its constructor:


	\code
		X() : inchan(this)
	\endcode

	so that the target of the port's decoder is an instance of module X, then
	as transactions are read from the mytx_chan channel by the port, they are
	dispatched on module X by calling the functions in module X's implementation
	of the my_if interface.  

	The template argument T may either be a transaction class, or an interface class
	produced by hubsync.

//==============================================================================
*/
template< class T > 
class esc_chan_txin 
	:	public esc_chan_in< typename T::tx_t* >,
		public T::tx_t::decoder_t
{
  public:
	typedef typename T::tx_t			tx_type;
	typedef typename tx_type::decoder_t decoder_type;

    typedef tx_type*                    data_type;

	typedef esc_chan_txin<T>            this_type; // ACG
    typedef esc_chan_in_if<data_type>	if_type;
    typedef esc_chan_in<data_type> 	 	base_type;

    typedef if_type                  	in_if_type;
    typedef sc_port_b<in_if_type>    	in_port_type;

  public:
	/*! \brief	Constructor
		\param target			Gives the target interface on which methods will be called for incoming operations.
		\param create_thread	If true, an internal thread is created.
		\param thread_style 	Specifies the threading style for decoded operations.  See esc_decoder for details.

		Ordinarily, an esc_chan_txin is declared within an sc_module that implements the tx_type::if_t interface.
		In this case, the target constructor parameter is the this parameter for the sc_module.
		However, the target interface may be any object that implements the tx_type::if_t interface.
		The esc_chan_txin will be self-executing if the create_thread parameter is true.  A thread will
		be created within the port that will continuously read from the connected channel and dispatch
		incoming transactions on the target interface.  If the port is created with create_thread=false,
		then either the dispatch_one() or dispatch_all() methods must be called by another thread
		in order to cause incoming operations to be read and dispatched.

		When an incoming operation is read from the channel and dispatched through the decoder, the delay
		between the aread() and aread_done() on the channel is determined by the thread_style parameter.
		See esc_decoder for details.
	 */
    esc_chan_txin( typename tx_type::if_t* target=0, bool create_thread=true, esc_decoder_thread_style thread_style=esc_thread_inline ) 
    	: base_type(), decoder_type( target, thread_style ), m_decoder_thread_p(0), m_done_aread_done(false)
    {
		if ( create_thread )
			m_decoder_thread_p = new decoder_thread(this);
    }

	//! Alternate form of constructor that specifies a name for the port.
    esc_chan_txin( const char *name, typename tx_type::if_t* target=0, bool create_thread=true, esc_decoder_thread_style thread_style=esc_thread_inline ) 
    	: base_type(name), decoder_type( target, thread_style ), m_decoder_thread_p(0)
    {
		if ( create_thread )
			m_decoder_thread_p = new decoder_thread(this);
    }

    virtual ~esc_chan_txin() 
    {
		delete m_decoder_thread_p;
    }

	/*	\brief	Gives the source channel to which the port is bound.

		The source_chan() function is useful in cases where the source channel must be 
		interacted with directly rather than indirectly through the port's decoder.
	 */
	in_if_type& source_chan()
	{
		return *((*this)[0]);
	}
  public:

	/*! \brief Reads one transaction from the channel and dispatches through the decoder.
	 *	Both the channel's writer and the caller of this function will be blocked until 
	 *	the decoder's write_tx() method returns.  The thread_style parameter given in
	 *  the ports constructor determines when the write_tx method will return.  See
	 *	esc_decoder for a detailed description.
	 */
	void dispatch_one()
	{
		m_done_aread_done = false;
		tx_type* tx = source_chan().aread( this->consumer_id() );
		write_tx( tx );
		if ( !m_done_aread_done )
			source_chan().aread_done( this->consumer_id() );

	}

	/*! \brief Reads and dispatches forever.
	 *	This method is intended to be called once from a thread within the module that
	 *	owns this port.  It should be called from a thread and not from the module's contructor.
	 *	That thread will then continuously read transactions from the bound channel and dispatche
	 *	them on the interface that is the target of the decoder.
	 */
	void dispatch_all()
	{
		while (1) dispatch_one();
	}

	/*!	\brief	Indicates that the transaction is done
	 *
	 *	This function can be called from the target interface to indicate that the
	 *	transaction is done and that an aread_done() can be done on the channel.
	 *	It has a similar effect to the tx_done() member of esc_decoder.  In fact,
	 *	if the threading style is anything except esc_thread_inline, the tx_done
	 *	for the base tx_type::decoder_t class is called to implement it.
	 *
	 *	Calling tx_done is only required when the target interface needs to un-block
	 *	the channel's producer before it returns.  Note that for ports with the 
	 *	esc_thread_inline threading style, this will result in a delay before the 
	 *	channel is read again, but with other threading styles, the channel will 
	 *	be read again immediately such that transactions may be overlapped.
	 */
	inline void tx_done()
	{
		if ( m_decoder_thread_p )
		{
			if ( decoder_type::m_threading == esc_thread_inline )
			{
				source_chan().aread_done( this->consumer_id() );
				m_done_aread_done = true;
			}
			else
				decoder_type::tx_done();
		}
	}
	

  protected:
	// Internal module used to house a thread that runs the decoder.
	class decoder_thread : public sc_module
	{
	  public:
	    SC_HAS_PROCESS(	decoder_thread );
		decoder_thread( esc_chan_txin<T> *port ) 
			: sc_module( "decoder_thread" ), p_port(port)
		{
			SC_THREAD(main);
			end_module();
		}		
		void main()
		{
			p_port->dispatch_all();
		}
		esc_chan_txin<T> *p_port;
	};
	decoder_thread *m_decoder_thread_p;
	bool m_done_aread_done;

	//! \internal
    void end_of_elaboration()
	{
		base_type::end_of_elaboration();

		// Verify that a target has been set.
		if ( !this->target() )
			esc_report_error( esc_error, "%s: %s: %s: Target interface has not been set.\n", 
								ESC_CUR_TIME_STR, "esc_chan_txin", this->name() );
	}

  private: // Disabled actions.
    esc_chan_txin( const this_type& );
    this_type& operator = ( const this_type& );
};

//! \internal
//! Provided for backwards compatibility with pre-release versions of ESC.
#define ESC_CHAN_TXIN(txbase) \
	esc_chan_txin< txbase##_tx >

#endif // esc_channel_h_INCLUDED
