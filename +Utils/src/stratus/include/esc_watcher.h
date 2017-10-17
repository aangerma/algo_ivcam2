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

#ifndef ESC_WATCH_HEADER_GUARD__
#define ESC_WATCH_HEADER_GUARD__

/*!
	\file esc_watcher.h
	\brief Classes supporting transaction watching
 */

//
// Forward declarations.
//
template <class T> class esc_watcher;
template <class T> class esc_watchable_in;
template <class T> class esc_watchable_queue_in;


//==============================================================================
/*! 
	\class esc_watchable_base 

    \brief Non-templated base class for watchable entities.

	Each esc_watchable_base is associated with an sc_object.  The esc_watchable_base
	contains a direct pointer to the sc_object.  There is also a hash table containing
	esc_watchable_base*'s and indexed by sc_object so that an esc_watchable_base
	may be found given an sc_object.  There can be only one esc_watchable_base for
	each sc_object.

	
*/
//==============================================================================
class esc_watchable_base
{
  public:
	/*! 
	  \brief Constructor
	  \param target_p The target to set
	*/
	esc_watchable_base( sc_object *target_p=0 )
		: m_target_p(target_p)
	{
		if ( target() ) 
			register_watchable( this );
	}

	virtual ~esc_watchable_base() {}

	/*! \brief	Sets the target object and registers the esc_watchable_base.  
	 *  \param target_p The target to set
	 *  \return Non-zero on success
	 *
	 *	An error is generated and false returned if the target has already been set,
	 *	or if the target is already associated with another esc_watchable_base.
	 */
	bool set_target( sc_object *target_p )
	{
		if ( !target() )
		{
			m_target_p = target_p;
			return register_watchable( this );
		}
		else
		{
			esc_report_error( esc_error, "Attempt to set the target of an esc_watchable_base to %s after the target has already been set.",
								watch_name() );
			return false;
		}
	}

	//! Gives a pointer to the sc_object with which this esc_watchable is associated.
	sc_object *target()
	{
		return m_target_p;
	}

	/*!
	 *	\brief	Gives the full pathname that this object should have from
	 *			the point of view of a watcher.  
	 *
	 *	\return The default implementation of watch_name() calls the name()
	 *			member of the target object, or returns 0 if there is no currently
	 *			set target.
	 *
	 *			This function can be implemented by derived classes to provide
	 *			an alternative name.  Pathnames returned may use either '.'
	 *			or '/' as a separator.
	 */
	virtual const char *watch_name()
	{
		if ( target() )
			return target()->name();
		else
			return 0;
	}

	// Static functions.

	/*!
	  \internal
	  \brief Tries to find an esc_watchable given an sc_object
	  \param target The sc_object* that may also be an esc_watchable_base*
	  \return target cast to an esc_watchable_base, if it is one, or null otherwise.
	*/
	static esc_watchable_base* find_for( sc_object *target )
	{
		if ( m_watchable_table )
			return (*m_watchable_table)[ target ];
		else
			return 0;
	}

  protected:
	sc_object* m_target_p;	

	//! \internal Supporting types and functions for the watchable hash table.
	static sc_phash<sc_object*, esc_watchable_base*>* m_watchable_table;

	//! \internal Registers an esc_watchable_base that has already been associated with an sc_object
	static bool register_watchable( esc_watchable_base* watchable );

	//! \internal Initializes watchable table.
	static void init_table();
};


//==============================================================================
/*! 
	\class esc_watchable_in_if

    \brief Interface definition for esc_watchable.

*/
//==============================================================================
template <class T>
class esc_watchable_in_if : virtual public sc_interface
{
  public:
	/*! 
	  \brief Registers an esc_watcher<T> for a specific set of events.
	  \param watcher The watcher that will be watching this instance
	  \param events The events that the watcher will watch
	*/
	virtual void add_watcher( esc_watcher<T>* watcher, esc_event_type events=ESC_ALL_EVENTS )=0;

	/*!
	  \brief Used to determine what events can be watched on this watchable
	  \return The events that this watchable generates (as a combination of ESC_*_EVENT.)
	*/
	virtual esc_event_type notify_events()=0;

};

//==============================================================================
/*! 
	\class esc_watchable

    \brief Base class for watchable entities.

	A class can be made watchable by an esc_tx_watcher by inheriting
	from esc_watchable and by calling methods in esc_watchable to
	inform the watchers about events.  esc_watchable 
	allows esc_tx_watchers to register for various watchable events.

	The following is a full list of watchable events:
	\code
	ESC_CHANGED_EVENT       Duration-free value change events
	ESC_WRITE_START_EVENT   The start of write operations with duration.
	ESC_WRITE_END_EVENT     The end of write operations with duration.
	ESC_READ_START_EVENT    The start of read operations with duration.
	ESC_READ_END_EVENT      The end of read operations with duration.
	ESC_ALL_EVENTS      	All events types.
	\endcode
	
*/
//==============================================================================
template <class T>
class esc_watchable : public esc_watchable_base, virtual public esc_watchable_in_if<T>
{
  public:
	//! Convenience typedef for the esc_watchable_in<T> port class.
	//! Can be used as esc_watchable<T>::in
    typedef class esc_watchable_in<T> in;

	//! Convenience typedef for the esc_watchable_queue_in<T> port class.
	//! Can be used as esc_watchable<T>::queue_in
    typedef class esc_watchable_queue_in<T> queue_in;

	/*!
	  \brief Constructor
	  \param target_p The target object
	*/
	esc_watchable( sc_object *target_p=0 )
		: esc_watchable_base(target_p),
		m_changed_watchers_p(0), m_write_start_watchers_p(0), m_write_end_watchers_p(0), 
		m_read_start_watchers_p(0), m_read_end_watchers_p(0), m_eventHandle(0)
	{}
	 
	//! Destructor
	virtual ~esc_watchable()
	{
		delete m_changed_watchers_p;
		delete m_write_start_watchers_p;
		delete m_write_end_watchers_p;
		delete m_read_start_watchers_p;
		delete m_read_end_watchers_p;
	}

	//! Returns a null reference to the data type that this class is templated on
	const T& get_data_ref() const
		{ return *(T*)NULL; }

	/*! \brief Registers an esc_watcher<T> for a specific set of events.
	 *	\param watcher
	 *		A pointer the watcher being registered.
	 *	<br><br>
	 *	The watcher object given will have its notify() method
	 *	called whenever the events specified in the \em events
	 *	parameter occur.
	 *	<br><br>

	 *	\param events
	 *		A bit-encoded word defining the events that the watcher should receive.
	 *		Any of these value can be specified, or'd together:
	 *
	 *	\code
	 *	ESC_CHANGED_EVENT       Duration-free value change events
	 *	ESC_WRITE_START_EVENT   The start of write operations with duration.
	 *	ESC_WRITE_END_EVENT     The end of write operations with duration.
	 *	ESC_READ_START_EVENT    The start of read operations with duration.
	 *	ESC_READ_END_EVENT      The end of read operations with duration.
	 *	ESC_ALL_EVENTS      	All events types.
	 *	\endcode
	 *			
	 */
	void add_watcher( esc_watcher<T>* watcher, esc_event_type events=ESC_ALL_EVENTS );

	sc_pvector< esc_watcher<T>* >*	write_end_watchers()
									{ return m_write_end_watchers_p; }

	/*!
	  \brief Used to determine what events can be watched on this watchable
	  \return The default implementation returns all possible events.
	*/
	virtual esc_event_type			notify_events() { return ESC_ALL_EVENTS; }

  protected:
	sc_pvector< esc_watcher<T>* >*	m_changed_watchers_p;
	sc_pvector< esc_watcher<T>* >*	m_write_start_watchers_p;
	sc_pvector< esc_watcher<T>* >*	m_write_end_watchers_p;
	sc_pvector< esc_watcher<T>* >*	m_read_start_watchers_p;
	sc_pvector< esc_watcher<T>* >*	m_read_end_watchers_p;
	esc_handle						m_eventHandle;

	// Functions used by derived classes to generate notifications.

	/*! 
	 *  \brief Notifies watchers registered for the ESC_CHANGED_EVENT.
	 *	\param value
	 *		A pointer to the new value.  If given, this value is provided to watchers for reference.
	 */
	void notify_changed( const T* value=0 );

	/*!
	 *  \brief Notifies watchers registered for the ESC_READ_START_EVENT.
	 *	\param value
	 *		A pointer to the new value.  If given, this value is provided to watchers for reference.
	 *	\return notify_read_start returns a handle that can be used to identify this 
	 *		transaction in a subsequent call to notify_read_end 
	 */
	esc_handle notify_read_start( const T* value=0 );

	/*!
	 *  \brief Notifies watchers registered for the ESC_READ_END_EVENT.
	 *	\param value
	 *		A pointer to the new value.  If given, this value is provided to watchers for reference.
	 *	\param handle
	 *		If specified, the handle parameter should be the return value from the
	 *		notify_read_start call corresponding to the start of the same transaction.
	 */
	void notify_read_end( const T* value=0, esc_handle handle=esc_empty_handle );

	/*!
	 *  \brief Notifies watchers registered for the ESC_WRITE_START_EVENT.
	 *	\param value
	 *		A pointer to the new value.  If given, this value is provided to watchers for reference.
	 *	\return notify_write_start returns a handle that can be used to identify this 
	 *		transaction in a subsequent call to notify_write_end 
	 */
	esc_handle notify_write_start( const T* value=0 );

	/*!
	 *  \brief Notifies watchers registered for the ESC_WRITE_END_EVENT.
	 *	\param value
	 *		A pointer to the new value.  If given, this value is provided to watchers for reference.
	 *	\param handle
	 *		If specified, the handle parameter should be the return value from the
	 *		notify_write_start call corresponding to the start of the same transaction.
	 */
	void notify_write_end( const T* value=0, esc_handle handle=esc_empty_handle );

  private:
	//! \internal Adds a logger to the specified queue.
	inline void add_to_queue( sc_pvector< esc_watcher<T>* >** queue_p, esc_watcher<T>* watcher );
	//! \internal Calls the watch_notify() function with the given event flag for all watchers in the given queue
	inline void notify_all( sc_pvector< esc_watcher<T>* >* queue_p, 
							esc_event_type flag, 
							const T* value, 
							esc_handle handle=esc_empty_handle );
};

//==============================================================================
/*! \brief Gives the esc_watchable<T> registered for the given sc_object if any.

	\param target	The sc_object for which to find an esc_watchable<T>
	\param result	An output parameter that will hold the esc_watchable<T>* if found.
	\return true if an esc_watchable<T> is registered, false, if not.

	The template parameter T is implied by the result parameter and is the type
	of the template parameter used with the registered esc_watchable.
 */
//==============================================================================
template <class T>
inline bool esc_watchable_for( sc_object* target, esc_watchable<T>** result )
{
	esc_watchable_base* watch_base = esc_watchable_base::find_for( target );
	if ( watch_base )
	{
		*result = dynamic_cast< esc_watchable<T>* >( watch_base );
		return ( result != 0 );
	}
	else
	{
		*result = 0;
		return 0;
	}
}

//==============================================================================
/*! \brief No-op overload for sc_signal types to support esc_register_signal_type.
 */
//==============================================================================
template <class T>
inline bool esc_watchable_for( sc_object* target, sc_signal<T>** result )
{
	return false;
}

//==============================================================================
/*! 
	\class esc_primitive_watcher

    \brief Non-templated base class for watchable entity adaptor.

*/
//==============================================================================
class esc_primitive_watcher
{
  public:

	//! Constructor
	esc_primitive_watcher() : m_flag(0)
	{}
	//! Destructor
	virtual ~esc_primitive_watcher()
	{}

	/*! \brief	Gives the event flag that has just been received.

		This method is intended to be used by watchers that are called through decoders
		and so do not recieve event flags directly.  
	 */
	unsigned short event_flag()
	{
		return m_flag;
	}
  protected:	
  	unsigned short m_flag;	
};

//==============================================================================
/*! 
	\class esc_watcher

    \brief Templated base class for entities that monitor esc_watchables.

	The template parameter \em T is the type of the data being watched.	

	The esc_watcher class can be treated much like an sc_interface class.
	That is, classes that wish to register as watchers of esc_watchables must
	be derived from this class and will ordinarily implement the virtual functions
	in the class.  In this case, the watch_notify() function is the interface's 
	sole virtual function.  The esc_watcher class does not, however, strictly follow the 
	sc_interface paradigm since it contains data and default function implementations.
*/
//==============================================================================
template <class T>
class esc_watcher : public esc_primitive_watcher
{
  public:
	//! Constructor
	esc_watcher()
	{}

	/*!	\brief	virtual function used to inform a watcher when an event has occurred.
	 *
	 *	The default implementation of this function just stores the incoming flags
	 *	in the m_flags variable.  This supports watchers that are informed of events
	 *	by the direct calling of interface functions.  The m_flags members gives those
	 *	functions an indication of what event occurred to cause the interface function in
	 *	the watcher to be called. 
	 *
	 *	\param	flag	The \em flag parameter is a single one of the ESC_*_EVENT flags
	 *					indicating which event has occurred.  
	 *
	 *	\param	value	A pointer to the value associated with the event.
	 *					If there is no relevant value, this parameter will be 0.
	 */ 
	virtual void watch_notify( esc_event_type flag, const T* value, esc_handle handle )
	{
		m_flag = flag;
	}

  protected:
};


template <class T>
inline void esc_watchable<T>::add_watcher( esc_watcher<T>* watcher, esc_event_type events )
{
	if ( events & ESC_CHANGED_EVENT )
		add_to_queue( &m_changed_watchers_p, watcher );
	if ( events & ESC_WRITE_START_EVENT )
		add_to_queue( &m_write_start_watchers_p, watcher );
	if ( events & ESC_WRITE_END_EVENT )
		add_to_queue( &m_write_end_watchers_p, watcher );
	if ( events & ESC_READ_START_EVENT )
		add_to_queue( &m_read_start_watchers_p, watcher );
	if ( events & ESC_READ_END_EVENT )
		add_to_queue( &m_read_end_watchers_p, watcher );
}

template <class T>
inline void esc_watchable<T>::notify_changed( const T* value )
{
	notify_all( m_changed_watchers_p, ESC_CHANGED_EVENT, value );
}

template <class T>
esc_handle esc_watchable<T>::notify_read_start( const T* value )
{
	esc_handle thisHandle = m_eventHandle++;
	if ( m_eventHandle == esc_empty_handle )
		m_eventHandle++;
	notify_all( m_read_start_watchers_p, ESC_READ_START_EVENT, value, thisHandle );
	return thisHandle;
}

template <class T>
void esc_watchable<T>::notify_read_end( const T* value, esc_handle handle )
{
	notify_all( m_read_end_watchers_p, ESC_READ_END_EVENT, value, handle );
}

template <class T>
esc_handle esc_watchable<T>::notify_write_start( const T* value )
{
	esc_handle thisHandle = m_eventHandle++;
	if ( m_eventHandle == esc_empty_handle )
		m_eventHandle++;
	notify_all( m_write_start_watchers_p, ESC_WRITE_START_EVENT, value, thisHandle );
	return thisHandle;
}

template <class T>
void esc_watchable<T>::notify_write_end( const T* value, esc_handle handle )
{
	notify_all( m_write_end_watchers_p, ESC_WRITE_END_EVENT, value, handle );
}

template <class T>
inline void esc_watchable<T>::add_to_queue( sc_pvector< esc_watcher<T>* >** queue_p, esc_watcher<T>* watcher )
{
	if ( !*queue_p )
		*queue_p = new sc_pvector< esc_watcher<T>* >;
	(*queue_p)->push_back( watcher );
}

template <class T>
inline void esc_watchable<T>::notify_all( sc_pvector< esc_watcher<T>* >* queue_p, 
										  esc_event_type flag, 
										  const T* value,
										  esc_handle handle )
{
	if ( !queue_p )
		return;

	for ( esc_watcher<T>** watcher = queue_p->begin(); watcher != queue_p->end(); watcher++ ) 
		(*watcher)->watch_notify( flag, value, handle );
}

template <class T> class esc_chan_in;

//==============================================================================
/*!
 * \class esc_watchable_in
 * \brief Input port for the esc_watchable<T> class.
 *
 * This class provides the input port for adding esc_watchers to an esc_watchable.
*/
//==============================================================================
template< class T > 
class esc_watchable_in : public sc_port<esc_watchable_in_if <T>,0>
{
  public:
	//! The data type
    typedef T                         		data_type;

	//! The watchable interface type
    typedef esc_watchable_in_if<T>			if_type;
	//! The sc_port type
    typedef sc_port<if_type,0>        		base_type;
	//! The watchable type
    typedef esc_watchable_in<data_type>   	this_type;

	//! The interface type
    typedef if_type                   		in_if_type;
	//! The sc_port_b type
    typedef sc_port_b<in_if_type>     		in_port_type;

	//! The esc_chan_in type
	typedef esc_chan_in<data_type>			in_chan_port_type;

  public:
	//! Constructor
    esc_watchable_in() : base_type() {}
	//! Constructor
    explicit esc_watchable_in( const char* name ) : base_type(name) {}
	//! Constructor
    esc_watchable_in( esc_watchable_in_if<T>& interface_ ) : base_type( interface_ ) {}
	//! Constructor
    esc_watchable_in( const char* name, in_if_type& interface_ ) : 
        base_type( name, interface_) {}
	//! Constructor
    esc_watchable_in( const char* name, in_port_type& parent ) : 
        base_type( name, parent) {}
	//! Constructor
    esc_watchable_in( this_type& parent ) : base_type( parent ) {}
	//! Constructor
    esc_watchable_in( const char* name, this_type& parent ) : 
        base_type( name, parent) {}

	// Bind to parent channel port.

    void bind( in_chan_port_type& parent_ )
	{ sc_port_base::bind( parent_ ); }

    void operator () ( in_chan_port_type& parent_ )
	{ sc_port_base::bind( parent_ ); }

    // bind to in interface

    void bind( const in_if_type& interface_ )
	{ sc_port_base::bind( CCAST<in_if_type&>( interface_ ) ); }

    void operator () ( const in_if_type& interface_ )
	{ sc_port_base::bind( CCAST<in_if_type&>( interface_ ) ); }


    virtual ~esc_watchable_in() {}

  public:
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
	esc_event_type notify_events()
	{
		// If we're already bound, pass on to target.  Otherwise, return 0.
		if ( this->get_interface() )
			return (*this)->notify_events();
		else
			return 0;
	}

  private: // Disabled actions.
    esc_watchable_in( const this_type& );
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

  protected:
	//! \internal
	// Add queued watchers now that we have a watchable.
    void end_of_elaboration()
	{
		for ( queued_add_watcher** qe = m_queued_watchers.begin(); qe != m_queued_watchers.end(); qe++ ) 
		{
			(*this)->add_watcher( (*qe)->m_watcher_p, (*qe)->m_events );
			delete (*qe);
		}
		m_queued_watchers.erase_all();
	}

};


//==============================================================================
/*!
// \class esc_watchable_txin 
// \brief Decoding port class that calls functions on a target interface for incoming transactions.
//
// This class provides an input port for an esc_watchable that carries encoded transactions.
// Each time an event is generated by the watchable, it is passed through the decoder
// and dispatched on the target interface.
// 
// This port class is derived from esc_watcher<> and registers for notification with
// the target esc_watchable using the flags given in the constructor.  
// 
// This class is ordinarily instantiated through the convenience macro ESC_WATCHABLE_TXIN.
*/
//==============================================================================
template< class T_TX > 
class esc_watchable_txin 
	:	public esc_watchable_in< T_TX* >,
		public esc_watcher< T_TX* >,
		public T_TX::decoder_t
{
  public:
    typedef T_TX*                      	data_type;
    typedef esc_watchable_txin<T_TX>	this_type;
    typedef esc_watchable_in< T_TX* >  	base_type;
	typedef typename T_TX::if_t			if_type;
    typedef if_type       		        in_if_type;
    typedef sc_port_b<in_if_type>     	in_port_type;
	typedef typename T_TX::decoder_t	decoder_type;

  public:
	//! Constructor.
    esc_watchable_txin( if_type* target=0, esc_event_type events=ESC_ALL_EVENTS ) 
    	: base_type(), decoder_type( target ), m_events(events)
    {}
	//! Constructor.
    esc_watchable_txin( const char* name, if_type* target=0, esc_event_type events=ESC_ALL_EVENTS ) 
    	: base_type(name), decoder_type( target ), m_events(events) 
    {}
	//! Constructor.
    esc_watchable_txin( in_if_type& interface_, if_type* target=0, esc_event_type events=ESC_ALL_EVENTS ) 
    	: base_type( interface_ ), decoder_type( target ), m_events(events)
    {}
	//! Constructor.
    esc_watchable_txin( const char* name, in_if_type& interface_, if_type* target, esc_event_type events=ESC_ALL_EVENTS ) 
        : base_type( name, interface_), decoder_type( target ), m_events(events) 
    {}
	//! Constructor.
    esc_watchable_txin( const char* name, in_port_type& parent ) : base_type( name, parent) {} 
	//! Constructor.
    esc_watchable_txin( this_type& parent ) : base_type( parent ) {}
	//! Constructor.
    esc_watchable_txin( const char* name, this_type& parent ) : base_type( name, parent) {}

	//! Destructor.
    virtual ~esc_watchable_txin() {}

  public:
	/*! \brief	Sets the events that this port will watch for.
		\param events	Bit flags specifying which events will be watched for.  See esc_watchable<T> for descriptions of these flags.

		The events that this port will watch for may be specified after the port
		has been constructed but before execution begins using this function.
	 */
	 void set_event_types( esc_event_type events )
	 {
		m_events = events;
	 }

  protected:
	//! \internal
    void end_of_elaboration()
	{
		// Add ourselves as a watcher of the target.
		(*this)->add_watcher( this, m_events );

		// Register any other spuriously added watchers.
		base_type::end_of_elaboration();
	}
	esc_event_type m_events;

	//! \internal
	//! Implementation of watch_notify() from esc_watcher interface.
	//! Incoming transactions are decoded as they arrive.
	void watch_notify( esc_event_type flag, const data_type* tx, esc_handle handle )
	{
        this->m_flag = flag;
		if ( tx )
			decode_tx( *tx );
	}

  private: // Disabled actions.
    esc_watchable_txin( const this_type& );
    this_type& operator = ( const this_type& );
};

//! \internal
//! Provided for backwards compatibility with pre-release versions of ESC.
#define ESC_WATCHABLE_TXIN(opset) \
	esc_watchable_txin< opset##_tx >


//==============================================================================
/*!
// \class esc_watchable_queue_in 
// \brief Port class for esc_watchables that queues values until they're read.
//
// This class provides an input port that can be bound to an esc_watchable.  
// The subset of events that will be queued is selected by an event mask given
// in the constructor.  Each time an event that contains a value is received, 
// it is added to a queue.  Each time the port's read() method is called, the 
// item at the head of the queue is returned along with the event flag and handle 
// that accompanied the original event.  If there are no events in the queue, 
// the read() method blocks until an event occurs.
// 
*/
//==============================================================================
template< class T > 
class esc_watchable_queue_in 
	:	public esc_watchable_in< T >,
		public esc_watcher< T >
{
  public:
    typedef T                      		data_type;
	typedef esc_watchable_queue_in<T>	this_type;
    typedef esc_watchable_in< T >  		base_type;

    typedef esc_watchable_in_if<data_type> in_if_type; // ACG
    typedef sc_port_b<in_if_type>     	in_port_type;  // ACG

  public:
	/*! \brief Constructor
	 *	\param events	Specifies the events that this port will watch for on the watchable to which this port is bound.
	 */
    esc_watchable_queue_in( esc_event_type events=ESC_ALL_EVENTS ) 
    	: base_type(), m_events(events), m_wake_reader()
    {}
	//! Constructor
    esc_watchable_queue_in( const char* name, esc_event_type events=ESC_ALL_EVENTS ) 
    	: base_type(name), m_events(events) 
    {}
	//! Constructor
    esc_watchable_queue_in( in_if_type& interface_, esc_event_type events=ESC_ALL_EVENTS ) 
    	: base_type( interface_ ), m_events(events) 
    {}
	//! Constructor
    esc_watchable_queue_in( const char* name, esc_watchable_in_if<data_type>& interface_, esc_event_type events=ESC_ALL_EVENTS )
		: base_type( name, interface_ ), m_events(events)
	{}
	//! Constructor
    esc_watchable_queue_in( esc_watchable_in_if<data_type>& interface_ )
		: base_type( interface_ ), m_events(0)
	{}
	//! Constructor
    esc_watchable_queue_in( const char* name, in_port_type& parent ) : base_type( name, parent) {}
        
	//! Constructor
    esc_watchable_queue_in( this_type& parent ) : base_type( parent ) {}
	//! Constructor
    esc_watchable_queue_in( const char* name, this_type& parent ) : base_type( name, parent) {}
	//! Destructor
    virtual ~esc_watchable_queue_in() {}
  public:
	/*!	\brief	Reads the next value from the queue
		\param flag_p	An optional output parameter in which the flag that accompanied the original event is stored.
		\param handle_p	An optional output parameter in which the handle that accompanied the original event is stored.
		\return The value sent with the orignal event

		The esc_watchable_queue_in port stores only events that contains values.  Therefore, the read()
		method will always return a value.  It is not possible to observe value-free watchable events
		using an esc_watchable_queue_in.

		The value returned will have have one lock on it that must be removed by the caller.  This lock
		protects the value from deletion for as long as it is in the queue.  Locks are only relevant 
		for data types that derive from esc_msg, such as hubsync-produced transaction classes.  See
		esc_msg_unlock() for details.
	 */
	T read( esc_event_type *flag_p=0, esc_handle *handle_p=0 )
	{
		// Wait until there's a value.
		while ( m_queue.empty() )
			wait( m_wake_reader );

		// Remove the head of the queue.
		event* rslt = m_queue[0];
		m_queue.erase( m_queue.front() );

		// Extract values from event record.
		T val = rslt->m_val;
		if ( flag_p )
			*flag_p = rslt->m_flag;
		if ( handle_p )
			*handle_p = rslt->m_handle;

		// Cleanup and return.
		delete rslt;
		return val;
	}	

	/*! \brief	Sets the events that this port will watch for.
		\param events	Bit flags specifying which events will be watched for.  See esc_watchable<T> for descriptions of these flags.

		The events that this port will watch for may be specified after the port
		has been constructed but before execution begins using this function.
		The 
	 */
	 void set_event_types( esc_event_type events )
	 {
		m_events = events;
	 }
  protected:
    void end_of_elaboration()
	{
		// Add ourselves (our decoder) as a watcher of the target.
		(*this)->add_watcher( this, m_events );

		// Register any other spuriously added watchers.
		base_type::end_of_elaboration();
	}

	void watch_notify( esc_event_type flag, const T* value, esc_handle handle )
	{
		// Skip value-free events.
		if ( !value )
			return;

		// Create an event record and queue it.
		// Place a lock on the value while it's on the queue.
		esc_msg_lock( (T*)value );
		event *e = new event( *(T*)value, flag, handle );
		m_queue.push_back( e );
		if ( m_queue.size() == 1 )
			m_wake_reader.notify();
	}

	// Structs used to store event arguments in the queue.
	struct event 
	{
		event( T& val, esc_event_type flag, esc_handle handle )
			: m_val(val), m_flag(flag), m_handle(handle)
		{}
		T m_val;
		esc_event_type m_flag;
		esc_handle m_handle;
	};
	esc_event_type m_events;	// Events that will be watched for.
	esc_vector<event*> m_queue;	// Queue of events.
    sc_event m_wake_reader;   	// Event to wake reader when queue no longer empty.

  private: // Disabled actions.
    esc_watchable_queue_in( const this_type& );
    this_type& operator = ( const this_type& );
};


/*!
 * \brief	Gives access to the registered read-end watchers that implement the given interface.
 * \param	ifname	The interface on which the caller will be making a function call.
 * \param	handle	The handle returned from notify_read_start()
 *
 * This macro is intended to be used as follows:
 *
 * \code
 *	NOTIFY_READ_END(my_interface,my_handle)->interface_func( x, y );
 * \endcode
 *
 * where my_interface is the name of a the interface that contains interface_func(),
 * and interface_func() is a function that is to be logged as an operation along with
 * parameters \em a and \em b.
 *
 * The registered watcher must implement the interface or a runtime error will result.
 */
#define NOTIFY_READ_END_IF( ifname, hHandle ) \
	if ( m_read_end_watchers_p ) \
		for ( esc_watcher<ifname*>** watcher = m_read_end_watchers_p->begin(); \
				watcher != m_read_end_watchers_p->end(); watcher++ ) \
			(*watcher)->watch_notify( ESC_READ_END_EVENT, 0, hHandle ), \
			(dynamic_cast<ifname*>(*watcher))

/*!
 * \brief	Gives access to the registered read-end watchers that implement the given interface.
 * \param	ifname	The interface on which the caller will be making a function call.
 * \param	handle	The handle returned from notify_write_start().
 *
 * This macro is intended to be used as follows:
 *
 * \code
 *	NOTIFY_WRITE_END(my_interface,my_handle)->interface_func( x, y );
 * \endcode
 *
 * where my_interface is the name of a the interface that contains interface_func(),
 * and interface_func() is a function that is to be logged as an operation along with
 * parameters \em a and \em b.
 *
 * The registered watcher must implement the interface or a runtime error will result.
 */
#define NOTIFY_WRITE_END_IF( ifname, hHandle ) \
	if ( m_write_end_watchers_p ) \
		for ( esc_watcher<ifname*>** watcher = m_write_end_watchers_p->begin(); \
				watcher != m_write_end_watchers_p->end(); watcher++ ) \
			(*watcher)->watch_notify( ESC_WRITE_END_EVENT, 0, hHandle ), \
			(dynamic_cast<ifname*>(*watcher))

/*!
 * \brief	Gives access to the registered read-end watchers for the specified watchable that implement the given interface.
 * \param	watchable The watchable whos read-end watchers will be notified.
 * \param	ifname	The interface on which the caller will be making a function call.
 * \param	handle	The handle returned from notify_write_start().
 *
 * This macro is intended to be used as follows:
 *
 * \code
 *	NOTIFY_WRITE_END(my_watchable,my_interface,my_handle)->interface_func( x, y );
 * \endcode
 *
 * where my_interface is the name of a the interface that contains interface_func(),
 * and interface_func() is a function that is to be logged as an operation along with
 * parameters \em a and \em b.
 *
 * The registered watcher must implement the interface or a runtime error will result.
 */
#define NOTIFY_WRITE_END_IF_ALT( watchable, ifname, hHandle ) \
	if ( (watchable)->write_end_watchers() ) \
		for ( esc_watcher<ifname*>** watcher = (watchable)->write_end_watchers()->begin(); \
				watcher != (watchable)->write_end_watchers()->end(); watcher++ ) \
			(*watcher)->watch_notify( ESC_WRITE_END_EVENT, 0, hHandle ), \
			(dynamic_cast<ifname*>(*watcher))

#endif

