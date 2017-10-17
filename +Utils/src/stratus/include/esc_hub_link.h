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

#ifndef ESC_HUB_LINK_HEADER_GUARD__
#define ESC_HUB_LINK_HEADER_GUARD__

/*!
  \file esc_hub_link.h
  \brief This file defines classes that are used to connect esc_chans with RAVE channels.
*/

template< class T >
class esc_chan;

#if BDW_HUB

/*! \brief Gives the Hub feedback style appropriate for a set of esc_watchable events.
	\param events	A set of event flags returned from notify_events() for an esc_watchable.
	\param reg_events	An output parameter filled in with the event flags for which an esc_watcher should register.

	An esc_watchable publishes the event flags that it will produce in its notify_events()
	method.  The esc_hub_feedback_style() function gives the appropriate Hub feedback type
	for that set of events.

	An esc_watchable may produce more events than the Hub needs to know about.  The esc_hub_feedback_style()
	function chooses a subset of flags from the events parameter and returns them in the 
	reg_events output parameter.  The set of events returned in reg_events is the appropriate
	set for an esc_watcher to register for in order to satisfy the Hub's requirements.
 */
inline qbhEventFeedbackType esc_hub_feedback_style( esc_event_type events, esc_event_type *reg_events )
{
	qbhEventFeedbackType type;
	
	if ( (events & ESC_READ_START_EVENT) && (events & ESC_READ_END_EVENT) )
	{
		type = qbhStartEndEvent;
		*reg_events = (ESC_READ_START_EVENT | ESC_READ_END_EVENT);
	}
	else if ( (events & ESC_WRITE_START_EVENT) && (events & ESC_WRITE_END_EVENT) )
	{
		type = qbhStartEndEvent;
		*reg_events = (ESC_WRITE_START_EVENT | ESC_WRITE_END_EVENT);
	}
	else if ( events & ESC_READ_START_EVENT )
	{
		type = qbhStartEvent;
		*reg_events = ESC_READ_START_EVENT;
	}
	else if ( events & ESC_WRITE_START_EVENT )
	{
		type = qbhStartEvent;
		*reg_events = ESC_WRITE_START_EVENT;
	}
	else if ( events & ESC_READ_END_EVENT )
	{
		type = qbhEndEvent;
		*reg_events = ESC_READ_END_EVENT;
	}
	else if ( events & ESC_WRITE_END_EVENT )
	{
		type = qbhEndEvent;
		*reg_events = ESC_WRITE_END_EVENT;
	}
	else
	{
 		type = qbhInstantEvent;
		*reg_events = ESC_CHANGED_EVENT;
 	}	
	return type;
}

/*!
  \brief Gives the Hub feedback type for the given feedback style and watchable event type.
  \param event A single event flag that describes the event that has just occurred on an esc_watchable.
  \param style The Hub feedback style previously given by esc_hub_feedback_style() for the notify_events().

  When an event is fed back to a Hub channel, it must be accompanied by an indication
  of what kind of event it is.  The system of event identification differs between the
  Hub and the esc_watchable subsystem.  This function translates between the two systems.

  The style parameter gives the hub feedback style previously returned from esc_hub_feedback_style()
  for the notify_events() returned from the esc_watchable whose event is being processed now.
  The feedback style is used together with the identity of the event that has just occurred
  to select the event flag given to the Hub.
    
  \return The feedback type as a qbhEventFeedbackType.  If no Hub event is appropriate, then qbhNonEvent is returned.
*/
inline qbhEventFeedbackType esc_hub_event( esc_event_type event, qbhEventFeedbackType style ) 
{
	switch (style) 
	{
		case qbhStartEvent:
			if (event & (ESC_WRITE_START_EVENT | ESC_READ_START_EVENT))
				return qbhStartEndEvent;
			break;
		case qbhEndEvent:
			if (event & (ESC_WRITE_END_EVENT | ESC_READ_END_EVENT))
				return qbhStartEndEvent;
			break;
		case qbhStartEndEvent:
			if (event & (ESC_WRITE_START_EVENT | ESC_READ_START_EVENT))
				return qbhStartEvent;
			else if (event & (ESC_WRITE_END_EVENT | ESC_READ_END_EVENT))
				return qbhEndEvent;
			break;
 		case qbhInstantEvent:
			if (event & ESC_CHANGED_EVENT )
				return qbhInstantEvent;
			break;
		default:
			break;
	}
	return qbhNonEvent;
}



/*!
  \class esc_hub_object
  \brief Base class for objects connected to the Hub.

  Connecting to the Hub means connecting to a Hub channel.  This is the base class
  for objects that produce values for the Hub, consume values from the Hub, and 
  those that watch esc_chans to send the value to the Hub.  Because this latter form
  may need to be created after time 0, they are not derived from sc_object.
  Producers and consumers need to have threads, and therefore must be derived from
  sc_module.
*/
template < class T >
class esc_hub_object
{
 public:

	// Hub callback member function
	inline static qbhError	hub_callback( 	qbhChannelHandle channelHandle,
										 	void* pExtConnection,
									 	 	qbhExtChannelActivity cbCode,
									 	 	qbhHandle cbInfo,
											qbhHandle* pCbOutValue )
	{
		qbhError error = qbhOK;
	
		// Call the execute HUB callback member function:
		((esc_hub_object<T>*)pExtConnection)->execute_hub_callback( cbCode,
																	cbInfo,
																	pCbOutValue );
		return qbhOK;
	}

						/*!
						  \brief Constructor
						  \param channame Name of the RAVE channel to connect to
						  \param kind The kind of the channel
						*/
						esc_hub_object( const char *channame, qbhChannelKind kind=qbhDefChannel )
							: m_channame_p(channame),
							m_kind(kind),
							m_events(ESC_CHANGED_EVENT),
							m_channel_type(qbhEmptyHandle),
							m_channel_handle(qbhEmptyHandle),
							m_sc_value_available(0)
						{
						}

						//! Destructor
						~esc_hub_object()
						{
						}
						
						//! Initializes the instance
	inline virtual void	initialize()
						{
							T scType;

							m_channel_type = HubGetType( (char*)&scType );

							qbhError err = qbhRegisterChannel( (char*)m_channame_p,
												m_channel_type,
												m_kind,
												qbhInput,
												0,		// channel_mux
												0,		// channel_config
												esc_hub::domain(),
												&esc_hub_object<T>::hub_callback,
												this,
												&m_channel_handle );
							if ( err != qbhOK )
								esc_report_error( esc_error, "Failed to register channel '%s' with the Hub: %s\n",
													m_channame_p, qbhErrorString(err) );
						}

	inline virtual void	execute_hub_callback( qbhExtChannelActivity cbCode,
											  qbhHandle cbInfo,
											  qbhHandle* pCbOutValue )
						{
							// Intentionally empty
						}


	inline bool			is_bound()
						{ return (m_channel_handle != qbhEmptyHandle ); }
							
	const char*			m_channame_p;
	qbhChannelKind		m_kind;		// used with qbhRegisterChannel()
	esc_event_type		m_events;
	qbhTypeHandle		m_channel_type;
	qbhChannelHandle	m_channel_handle;
	T					m_sc_value;
	int					m_sc_value_available;
};

/*!
  \class esc_hub_module
  \brief This is the base class for SystemC modules that interact with the HUB.

  Users should never instantiate this class directly.
*/
template < class T >
class esc_hub_module : public sc_module, public esc_hub_object< T >
{
 public:

	SC_HAS_PROCESS(esc_hub_module);

	inline esc_hub_module( const char* channame, 
			       const char *myname=NULL, 
			       qbhChannelKind kind=qbhDefChannel,
			       bool requires_activation=false );

	inline ~esc_hub_module() {}

	inline virtual void			initialize() {}

	inline void					main();
	inline virtual void			pre()=0;
	inline virtual void			execute()=0;
	inline virtual void			post()=0;

	inline void activate();
 protected:

	int					m_waiting_sc_read;
	qbhValueHandle		m_unacked_sc_value_handle;
	T					m_unacked_sc_value;
	sc_event			m_event;
	int					m_demand;
	bool				m_activated;
};
	
template< class T >
inline
esc_hub_module<T>::esc_hub_module( const char* channame, const char *myname, qbhChannelKind kind, bool requires_activation )
	: sc_module( sc_module_name( (myname!=NULL) ? myname : channame) ),
	 esc_hub_object<T>( channame, kind ),
	 m_waiting_sc_read(0),
	 m_unacked_sc_value_handle(qbhEmptyHandle),
	 m_demand(0),
	 m_activated(!requires_activation)
{
	SC_THREAD(main);
}

// Enables an esc_hub_module that was originally created un-activated.
template< class T >
inline void
esc_hub_module<T>::activate()
{
	if ( !m_activated )
	{
		m_activated = true;
		m_event.notify();
	}
}

template< class T >
inline void
esc_hub_module<T>::main()
{
	while ( !m_activated )
		wait( m_event );

	initialize();

	while (true)
	{
		pre();


		execute();
		

		post();
	}

}


template< class T >
inline void
esc_hub_module<T>::post()
{
	// Could be renamed qbhWakeupHUB(), because 
	//  that's all this function is meant to do

	qbhDriverValueAvailable( qbhEmptyHandle,
                            this->m_channel_handle,
							 esc_hub::domain() );
}

/*!
  \class esc_hub_producer_module
  \brief This class is for SystemC modules that produce values for the Hub.

  Class is templated on T, the class of the value produced.
*/
template < class T >
class esc_hub_producer_module : public esc_hub_module<T>
{
 public:

	// Hub callback member function
	inline static qbhError	hub_callback( 	qbhChannelHandle channelHandle,
										 	void* pExtConnection,
									 	 	qbhExtChannelActivity cbCode,
									 	 	qbhHandle cbInfo,
											qbhHandle* pCbOutValue );

	/*!
	  \brief Constructor
	  \param channame Name of the RAVE channeldef that this module will be driving.
	  \param enable_now	If true, this module is made an active Hub producer when simulation begins.  
						If false, values will not be driven into the Hub until the enable() function
						is called.

	*/
	inline esc_hub_producer_module( const char *channame, 
									bool enable_now=true,
									qbhChannelKind kind=qbhDefChannel, 
									const char *myname=NULL,
									bool requires_activation=false );

	//! Destructor
	inline ~esc_hub_producer_module()
	{}

	inline virtual void initialize();

	inline virtual void pre();
	inline virtual void post();

	/*!
	  \brief Enables this module as a Hub producer

	  If this module was not enabled as a driver in it's constructor, or if it was previously
	  disabled, the enable() function can be used to make this module act as a Hub producer.
	  It will remain a Hub producer until disable() is called.
	*/
	inline void enable()
	{
		if ( !this->is_bound() )
			return;

		qbhError status = qbhOK;

		if ( ! m_enabled )
			status = qbhEnableDriver( this->m_channel_handle, esc_hub::domain(), qbhEmptyHandle );

		if ( status == qbhOK )
			m_enabled = true;
	}

	/*!
	  \brief Disabled this module as a Hub producer.

	  Disabling an esc_hub_producer_module allows other Hub drivers, such as RAVE
	  tests, to drive the Hub channel associated with the module without a driver
	  conflict.  A disabled driver an later be re-enabled using the enable() function.
	*/
	inline void disable()
	{
		if ( this->m_channel_handle != qbhEmptyHandle && m_enabled )
			qbhDisableDriver( this->m_channel_handle, esc_hub::domain(), qbhEmptyHandle );
		
		m_enabled = false;
	}
			
 protected:
	int m_waiting_ack;
	bool m_enable_on_init;
	bool m_enabled;

	inline virtual void	execute_hub_callback( qbhExtChannelActivity cbCode,
											  qbhHandle cbInfo,
											  qbhHandle* pCbOutValue );
	
	inline virtual void	get_value_from_sc( qbhDriverHandle driverHandle,
										   qbhValueHandle* pValueHandle );
	inline virtual void	get_value_from_sc_done( qbhValueHandle valueHandle );
	inline virtual void	return_value_to_hub();

 public:

};


//------------------------------------------------------------------------------
// esc_hub_producer_module::hub_callback
//
// The callback function that is given to the HUB
// when the module is initially registered.  The HUB will
// contact us via this callback function whenever it needs
// to inform us of channel activity.
//------------------------------------------------------------------------------
template< class T >
inline qbhError
esc_hub_producer_module<T>::hub_callback( qbhChannelHandle channelHandle,
													  void* pExtConnection,
													  qbhExtChannelActivity cbCode,
													  qbhHandle cbInfo,
													  qbhHandle* pCbOutValue )
{
	qbhError error = qbhOK;
	
	// Call the execute HUB callback member function:
	((esc_hub_producer_module<T>*)pExtConnection)->execute_hub_callback( cbCode,
																		cbInfo,
																		pCbOutValue );
	return qbhOK;
}


template< class T >
inline
esc_hub_producer_module<T>::esc_hub_producer_module( const char *channame, 
													 bool enable_now,
													 qbhChannelKind kind, 
													 const char *myname,
													 bool requires_activation ) 
	: esc_hub_module<T>(channame,myname,kind,requires_activation), 
	  m_waiting_ack(0), 
	  m_enable_on_init(enable_now),
	  m_enabled(false)
{
}

template< class T >
inline
void esc_hub_producer_module<T>::initialize()
{
	T scType;
	
	// Get the type type handle.
    this->m_channel_type = HubGetType( (char*)&scType );

	qbhError err = qbhRegisterChannel( (char *)this->m_channame_p,
                        this->m_channel_type,
                        this->m_kind,
						qbhInput,
						0, // channel_mux
						0, // channel config
						esc_hub::domain(),
						&esc_hub_producer_module<T>::hub_callback,
						this,
						&this->m_channel_handle );

	if (err == qbhOK )
	{
		if ( m_enable_on_init )
		{
			enable();
		}
	}
	else
	{
		esc_report_error( esc_error, "Failed to register channel '%s' with the Hub: %s\n",
                    this->m_channame_p, qbhErrorString(err) );
	}
}

template< class T >
inline void
esc_hub_producer_module<T>::pre()
{
	// Only wait for demand if there isn't some already.
	if ( ! this->m_demand )
	{
		wait(this->m_event);
	}
    this->m_demand = 0;
}

template< class T >
inline void
esc_hub_producer_module<T>::post()
{
	// Shouldn't be the case
	if ( this->m_channel_handle == qbhEmptyHandle )
		return;

	// Tell the Hub there's something to do now.
	qbhDriverValueAvailable( qbhEmptyHandle,
                            this->m_channel_handle,
							 esc_hub::domain() );
}


//------------------------------------------------------------------------------
// esc_hub_producer_module<T>::get_value_from_sc
//
// Get a value from SystemC.
// The driverHandle is ignored.
//------------------------------------------------------------------------------
template< class T >
inline void
esc_hub_producer_module<T>::get_value_from_sc( qbhDriverHandle driverHandle,
										   qbhValueHandle *valueHandle )
{
	int success = 0;

	if ( this->m_sc_value_available )
	{
		// Create a Hub value handle from the m_sc_value stored by the reading thread.
		HubTransTo( &this->m_sc_value, valueHandle );

		// Mark the value has being no longer available, but keep the value
		// around in both forms until the Hub ack's the value.
        this->m_sc_value_available = 0;
        this->m_unacked_sc_value_handle = *valueHandle;
        this->m_unacked_sc_value = this->m_sc_value;
	}
	else if ( this->m_demand == 0 )
	{
		// Inform the reading thread that there's been demand from the Hub and
		// tell the Hub we haven't got anything for it to read right now.
		// The Hub will come back later and poll.
        this->m_demand = 1;
        this->m_event.notify();
        this->m_unacked_sc_value_handle = qbhEmptyHandle;
		*valueHandle = qbhEmptyHandle;
	}
}


//------------------------------------------------------------------------------
// esc_hub_producer_module<T>::get_value_from_sc_done
//
// Complete the aread() started in get_value_from_sc() to free the driver.
//------------------------------------------------------------------------------
template< class T >
inline void
esc_hub_producer_module<T>::get_value_from_sc_done( qbhValueHandle valueHandle )
{
	// This function is called when a value previously written to the Hub has
	// been ack'd by the Hub.
	// The valueHandle should be the same as the m_unacked_sc_value_handle
	// that was saved during a write, but it will contain any output parameters 
	// filled in by the Hub, so we must do a HubTransTo on it into m_unacked_sc_value 
	// to propagate them back to C++.
	HubTransFrom( this->m_unacked_sc_value_handle,
				  &this->m_unacked_sc_value,
				  -1,
				  trans_no_create );

	// Inform any thread that's waiting for an ack.
	if ( m_waiting_ack )
		this->m_event.notify();

	// Destroy the value handle.
	qbhDestroyHandle( this->m_unacked_sc_value_handle );
    this->m_unacked_sc_value_handle = qbhEmptyHandle;

}


//------------------------------------------------------------------------------
// esc_hub_producer_module<T>::return_value_to_hub
//
// Return a previously gotten value to the hub driver from whom
// it was read.
//
// Returns: Nothing 
//------------------------------------------------------------------------------
template< class T >
inline void
esc_hub_producer_module<T>::return_value_to_hub()
{
}


//------------------------------------------------------------------------------
// esc_hub_producer_module<T>::execute_hub_callback
//
// This function maps HUB callback activity codes to
// member functions that perform the necessary operations.
//------------------------------------------------------------------------------
template< class T >
inline void
esc_hub_producer_module<T>::execute_hub_callback( qbhExtChannelActivity cbCode,
											  qbhHandle cbInfo,
											  qbhHandle* pCbOutValue )
{
	// Analyze the channel activity code and take
	// appropriate action:
	switch( cbCode )
	{
		// A driver has been added to this
		// channel in another domain:
		case qbhDriverAdded:
		{
			// Should be a don't care for esc_hub_producer_module,
			//  b/c no one should ever be calling this
			break;
		}

		// A driver has been removed from this
		// channel in another domain:
		case qbhDriverRemoved:
		{
			// Should be a don't care for esc_hub_producer_module,
			//  b/c no one should ever be calling this
			break;
		}

		// A previously requested driver value is
		// now available:
		case qbhGetValueCompletion:
		{
			// I think this should be a don't care,
			//  b/c this should only be called for values coming out of the hub
			break;
		}

		// A value has been written to the channel
		// in another domain:
		case qbhValueFanout:
		{
			// I think this should be a don't care,
			//  b/c for esc_hub_producer_module, values should never come
			//  from the HUB
			break;
		}
	
		// A value has been requested from a
		// driver in this domain:
		case qbhValueRequested:
		{
			get_value_from_sc( (qbhDriverHandle)cbInfo,
							   (qbhValueHandle*)pCbOutValue );
			break;
		}

		// A value has been acknowledged in another domain:
		case qbhValueAcked:
		{
			get_value_from_sc_done( cbInfo );
			break;
		}

		// A consumer from another domain has been enabled.
		// We need to tell the channel that we'll be a consumer for it.
		// We will remove ourselves as a watcher of writes to the 
		// channel during this time to prevent feedback that the 
		// HUB will provide on its own.
		case qbhConsumerEnabled:
		{
			break;
		}

		// A consumer from another domain has been disabled.
		// Tell the channel we'll no longer be its consumer.
		// Also, re-start listening for data events.
		case qbhConsumerDisabled:
		{
			break;
		}
	}
}

/*!
  \class esc_hub_consumer_base
  \brief This class is for SystemC modules that are Hub consumers.

  Class is templated on T, the class of the value produced, and 
  write_ifaceT, a class with a function write() that takes a value of type T.

  Users should never have to instantiate this class directly.
*/

template < class T, class write_ifaceT >
class esc_hub_consumer_base : public esc_hub_module<T>
{
 public:

	// HUB callback member function
	inline static qbhError	hub_callback( 	qbhChannelHandle channelHandle,
										 	void* pExtConnection,
									 	 	qbhExtChannelActivity cbCode,
									 	 	qbhHandle cbInfo,
											qbhHandle* pCbOutValue );

	/*!
	  \brief Constructor
	  \param channame Name of the RAVE channeldef that this module will be reading.
	  \param target An optional target interface to bind to.
	*/
	inline esc_hub_consumer_base( const char *channame, write_ifaceT* target=0, bool requires_activation=false );
			
	//! Destructor
	inline ~esc_hub_consumer_base()
	{}

	inline virtual void initialize();

	inline void 		pre();
	inline virtual void execute();
	inline void 		post();

 private:
	
	// Private HUB interaction member functions
	inline void			add_ext_driver( qbhDriverHandle driverHandle );
	inline void			remove_ext_driver( qbhDriverHandle driverhandle );
	inline int			get_value_from_hub();
	inline void			get_value_from_hub_done( qbhValueHandle valueHandle );
	inline void			fanout_value( qbhValueHandle valueHandle );

	inline void			execute_hub_callback( qbhExtChannelActivity cbCode,
											  qbhHandle cbInfo,
											  qbhHandle* pCbOutValue );
	

 public:

	sc_port< write_ifaceT > m_out;

 protected:

	qbhDriverHandle		m_hub_driver;
	sc_event			m_value_available_event;

};


//------------------------------------------------------------------------------
// esc_hub_consumer_base::hub_callback
//
// The callback function that is given to the HUB
// when the module is initially registered.  The HUB will
// contact us via this callback function whenever it needs
// to inform us of channel activity.
//------------------------------------------------------------------------------
template< class T, class write_ifaceT >
inline qbhError
esc_hub_consumer_base<T,write_ifaceT>::hub_callback( qbhChannelHandle channelHandle,
									  void* pExtConnection,
									  qbhExtChannelActivity cbCode,
									  qbhHandle cbInfo,
									  qbhHandle* pCbOutValue )
{
	qbhError error = qbhOK;
	
	// Call the execute HUB callback member function:
	((esc_hub_consumer_base<T,write_ifaceT>*)pExtConnection)->execute_hub_callback( cbCode,
																	 cbInfo,
																	 pCbOutValue );
	return qbhOK;
}


template< class T, class write_ifaceT >
inline
esc_hub_consumer_base<T,write_ifaceT>::esc_hub_consumer_base( const char *channame, write_ifaceT* target, bool requires_activation ) :
	esc_hub_module<T>(channame,NULL,qbhDefChannel,requires_activation),
	m_hub_driver(qbhEmptyHandle)
{
	// Bind to the target interface if it's given.
	if ( target )
		m_out(*target);
}

template< class T, class write_ifaceT >
inline
void esc_hub_consumer_base<T,write_ifaceT>::initialize()
{
	T scType;
	
	// Get the type type handle.
    this->m_channel_type = HubGetType( (char*)&scType );

	qbhError err = qbhRegisterChannel( (char *)this->m_channame_p,
                        this->m_channel_type,
						qbhDefChannel,
						qbhInput,
						0, // channel_mux
						0, // channel config
						esc_hub::domain(),
						&esc_hub_consumer_base<T,write_ifaceT>::hub_callback,
						this,
						&this->m_channel_handle );

	if (err == qbhOK )
	{
		// Should eventually be put into an enable() function, with an accompanying
		//  disable() function
		qbhEnableConsumer( this->m_channel_handle, esc_hub::domain() );
	}
	else
	{
		esc_report_error( esc_error, "Failed to register channel '%s' with the Hub: %s\n",
                this->m_channame_p, qbhErrorString(err) );
	}
}

template< class T, class write_ifaceT >
inline void
esc_hub_consumer_base<T,write_ifaceT>::pre()
{
	// wait for the driver to be added
	if ( m_hub_driver == qbhEmptyHandle )
	{
		wait(this->m_event);
	}
	else if ( this->m_demand == 1 )
	{
		wait(m_value_available_event);

		
		T value;
		HubTransFrom( this->m_unacked_sc_value_handle, &value );
        this->m_unacked_sc_value = value;

		m_out->write(this->m_unacked_sc_value);

        this->m_demand = 0;
	}
}

template< class T, class write_ifaceT >
inline void
esc_hub_consumer_base<T,write_ifaceT>::execute()
{
	get_value_from_hub();
}

template< class T, class write_ifaceT >
inline void
esc_hub_consumer_base<T,write_ifaceT>::post()
{
}

template< class T, class write_ifaceT >
inline void
esc_hub_consumer_base<T,write_ifaceT>::add_ext_driver( qbhDriverHandle driverHandle )
{
	if ( m_hub_driver == qbhEmptyHandle )
	{
		m_hub_driver = driverHandle;
        this->m_event.notify();
	}
}

template< class T, class write_ifaceT >
inline void
esc_hub_consumer_base<T,write_ifaceT>::remove_ext_driver( qbhDriverHandle driverHandle )
{
	m_hub_driver = qbhEmptyHandle;
}


////////////////////////////////////////////////////////////////////////////////
//
// esc_hub_consumer_base::execute_hub_callback
//
// This function maps HUB callback activity codes to
// member functions that perform the necessary operations.
//
////////////////////////////////////////////////////////////////////////////////
template< class T, class write_ifaceT >
inline void
esc_hub_consumer_base<T,write_ifaceT>::execute_hub_callback( qbhExtChannelActivity cbCode,
											  qbhHandle cbInfo,
											  qbhHandle* pCbOutValue )
{
	// Analyze the channel activity code and take
	// appropriate action:
	switch( cbCode )
	{
		// A driver has been added to this
		// channel in another domain:
		case qbhDriverAdded:
		{
			add_ext_driver( (qbhDriverHandle)cbInfo );

			break;
		}

		// A driver has been removed from this
		// channel in another domain:
		case qbhDriverRemoved:
		{
			remove_ext_driver( (qbhDriverHandle)cbInfo );

			break;
		}

		// A previously requested driver value is
		// now available:
		case qbhGetValueCompletion:
		{
			get_value_from_hub_done( *(qbhValueHandle*)pCbOutValue );

			break;
		}

		// A value has been written to the channel
		// in another domain:
		case qbhValueFanout:
		{
			fanout_value( (qbhValueHandle)cbInfo );

			break;
		}
	
		// A value has been requested from a
		// driver in this domain:
		case qbhValueRequested:
		{
			// This is a don't care, because a consumer
			// never has a value requested from it.

			break;
		}

		// A value has been acknowledged in another domain:
		case qbhValueAcked:
		{
			// This is a don't care, because a consumer
			// never has a value requested from it, and
			// therefore there's nothing to ack.

			break;
		}

		// A consumer from another domain has been enabled.
		// We need to tell the channel that we'll be a consumer for it.
		// We will remove ourselves as a watcher of writes to the 
		// channel during this time to prevent feedback that the 
		// HUB will provide on its own.
		case qbhConsumerEnabled:
		{
			break;
		}

		// A consumer from another domain has been disabled.
		// Tell the channel we'll no longer be its consumer.
		// Also, re-start listening for data events.
		case qbhConsumerDisabled:
		{
			break;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
//
// esc_hub_consumer_base::get_value_from_hub
//
// Get a value from a driver behind the HUB.
// If a value is obtained, write it asynchronously back into the channel.
//
// Returns 1 is the value was obtained, 0 if not.
//
////////////////////////////////////////////////////////////////////////////////
template< class T, class write_ifaceT >
inline int
esc_hub_consumer_base<T,write_ifaceT>::get_value_from_hub()
{
	// If there's no registered HUB driver, return 0.
	if ( m_hub_driver == qbhEmptyHandle )
		return 0;

	// If we still have an unack'd value, acknowledge it implicitly
	// because we're trying to get another value.
	if ( this->m_unacked_sc_value_handle != qbhEmptyHandle )
	{
		qbhAckValue( this->m_channel_handle,
					 esc_hub::domain(),
                     this->m_unacked_sc_value_handle );
        this->m_unacked_sc_value_handle = qbhEmptyHandle;
	}

	// Call the HUB CAPI get driver value function.
	// This may produce several results:
	//  1. A return of qbhOK with an m_unacked_sc_value_handle that is not empty.
	//     This indicates that a value has been obtained.  It will be converted
	//	   and returned.
	//  2. A return of qbhOK with an empty m_unacked_sc_value_handle.  This indicates
	//     that no value could be obtained immediately.
	//	3. A return of something other than qbhOK is returned, indicating that
	//     an error has occurred.
	//
	// If no value could be returned immediately, we should try again, only if
	// there has been a change in our m_hub_driver value during the call.  This
	// indicates that there as been a driver change, for example, a test termination,
	// during the call.  In this case, we must re-initiate the request for a value
	// with the new driver since the HUB will not do that.  However, we will never
	// make more than one unsuccessful request for the same driver.  The HUB will
	// poll for us in that case and later call the channel's callback with qbhGetValueCompletion
	// when a value is available.

	// if we don't already have an outstanding request for a value
	if ( this->m_demand == 0 )
	{
		qbhDriverHandle used_driver = qbhEmptyHandle;
		int got_value = 0;
		while ( !got_value && ( used_driver != m_hub_driver ) && ( qbhEmptyHandle != m_hub_driver ) )
		{
			used_driver = m_hub_driver;
			qbhError error = qbhGetDriverValue( m_hub_driver,
                                                this->m_channel_handle,
												esc_hub::domain(),
                                                &this->m_unacked_sc_value_handle );
			
			got_value = ( (error == qbhOK) && (this->m_unacked_sc_value_handle != qbhEmptyHandle) );
		}
		if ( got_value )
		{
			T value;
			HubTransFrom( this->m_unacked_sc_value_handle, &value );
            this->m_unacked_sc_value = value;
			
			// This could be bad, because we need to keep the value around to ack it
			m_out->write(this->m_unacked_sc_value);
			
			return 1;
		}
	}

    this->m_demand = 1;

	return 0;
}


////////////////////////////////////////////////////////////////////////////////
//
// esc_hub_consumer_base::get_value_from_hub_done
//
// This is called once the HUB has a value that we
// previously requested in the getDriverValue member
// function.  We have been sleeping since that call
// failed to return us a value with error qbhErrorNoValue.
//
////////////////////////////////////////////////////////////////////////////////

template< class T, class write_ifaceT >
inline void
esc_hub_consumer_base<T,write_ifaceT>::get_value_from_hub_done( qbhValueHandle valueHandle )
{
	// Store the handle to be used to collect output params at ack time.
	// Convert the value and write it asynchronously back into the channel.
    this->m_unacked_sc_value_handle = valueHandle;

	m_value_available_event.notify();
}

template< class T, class write_ifaceT >
inline void
esc_hub_consumer_base<T,write_ifaceT>::fanout_value( qbhValueHandle valueHandle )
{
	T value;

	// Send the given value onto the channel:
	HubTransFrom( valueHandle, &value );

	m_out->write( value );

}


/*!
  \class esc_chan_hub_reader
  \brief An esc_chan with a reader behind the Hub.

  An esc_chan_hub_reader allows SystemC module to write values to a 
  channel and have them read by a Hub-based consumer.  Each esc_chan_hub_reader
  instance is given the name of a Hub channel with which it will be associated.
  SystemC code may write to an esc_chan_hub_reader just like any other esc_chan.
  Each write() to the esc_chan_hub_reader will block until a Hub object has
  read the value from the associated Hub channel.
*/
template < class T >
class esc_chan_hub_reader : public esc_hub_producer_module< T >,
								 public esc_chan< T >
{
 public:
	

	/*!
	  \brief Constructor
	  \param channame Name of the channel to drive.
	  \param kind The type of channel.
	 */
	esc_chan_hub_reader( const char *channame, bool enableNow=true, qbhChannelKind kind=qbhDefChannel, bool requires_activation=false )
		: esc_hub_producer_module< T >(channame,enableNow,kind,NULL,requires_activation),
		esc_chan< T >( channame )
	{}

	//! Destructor
	~esc_chan_hub_reader()
	{}

	/*!
	  \brief Perform an aread() on the channel.

	  Should never be called directly by the user.
	*/
	void execute()
	{
		// Will block until a value can be read
		// The value will have a lock on it which we will leave in place until
		// the value is ack'd by the Hub.
        this->m_sc_value = esc_chan<T>::aread();
        this->m_sc_value_available = 1;
	}
	/*!
	  \brief Inform the Hub that a value is available, then
	         wait for an ack from the Hub.

	  Should never be called directly by the user.
	*/
	void post()
	{
		// The base class's post will inform the hub.
		esc_hub_producer_module< T >::post();	

		// Wait until the ack occurs.
        this->m_waiting_ack = 1;
		::wait( this->m_event );						
        this->m_waiting_ack = 0;


		// Unblock the channel.
		this->aread_done();		
							
		// Remove lock that was present when value was read.
		esc_msg_unlock<T>( &this->m_sc_value );			
	}

  private:
	//! \internal
	// Overloaded from sc_interface.  Called when a port is bound to an interface of the esc_chan.
	// Activates the esc_hub_module.
	void register_port( sc_port_base& port_, const char* if_typename_ )
	{
		this->activate();
		esc_chan<T>::register_port( port_, if_typename_ );
	}
};	


/*!
  \class	esc_chan_hub_writer
  \brief	An esc_chan with a writer behind the Hub.

  An esc_chan_hub_writer allows a SystemC module to read values from a 
  channel that have been written by a Hub-based writer.  Each esc_chan_hub_writer
  instance is given the name of a Hub channel with which it will be associated.
  SystemC code may read from an esc_chan_hub_writer just like any other esc_chan.
  Each call to aread() will block until a value is available from the Hub.  The 
  writer behind the Hub will be blocked until the SystemC reader calls aread_done().
*/
template <class T>
class esc_chan_hub_writer 
	: public esc_hub_consumer_base< T, esc_chan_out_if< T > >,
	  public esc_chan<T>
{
 public:
	/*!
	  \brief Constructor
	  \param channame Name of the Hub channel that this module will be reading.
	*/
	inline esc_chan_hub_writer( const char *channame, bool requires_activation=false )
		: esc_hub_consumer_base< T, esc_chan_out_if< T > >( channame, 0, requires_activation ),
			esc_chan<T>( channame )
	{
		// Bind the base class's port to outselves so that writes are done to 
		// the channel we contain.  This step must be done in this constructor
		// rather than in the base class constructor so that the 'this' object
		// is an official esc_chan when the call is made.  Otherwise, the dynamic
		// cast used in the port binding to find the esc_chan_out_if will fail
		// because this object has not yet been constructed.
		m_out(*this);

		this->end_module();
	}
			
	//! Destructor
	inline ~esc_chan_hub_writer()
	{}

 private:

	// HUB callback member function
	inline static qbhError	hub_callback( 	qbhChannelHandle channelHandle,
										 	void* pExtConnection,
									 	 	qbhExtChannelActivity cbCode,
									 	 	qbhHandle cbInfo,
											qbhHandle* pCbOutValue );


	//! \internal
	// Overloaded from sc_interface.  Called when a port is bound to an interface of the esc_chan.
	// Activates the esc_hub_module.
	void register_port( sc_port_base& port_, const char* if_typename_ )
	{
		this->activate();
		esc_chan<T>::register_port( port_, if_typename_ );
	}
};


/*!
  \class esc_hub_watchable
  \brief This class is for SystemC modules that watch Hub channels.

  This class is the same as esc_hub_consumer_base, except it does not register
  as a consumer, doesn't ack values, and only handles qbhValueFanout.
  Also, unlike a consumer, which delivers its resulting value using an sc_port,
  this class uses an esc_chan.

  Class is templated on T, the class of the value produced.
*/
template < class T >
class esc_hub_watchable : public esc_hub_module<T>,
							   public esc_async_chan<T>
{
 public:

	// Hub callback member function
	inline static qbhError	hub_callback( 	qbhChannelHandle channelHandle,
										 	void* pExtConnection,
									 	 	qbhExtChannelActivity cbCode,
									 	 	qbhHandle cbInfo,
											qbhHandle* pCbOutValue );

	/*!
	  \brief Constructor
	  \param channame Name of the RAVE channeldef that this module will be reading.
	  \param kind The type of channel to connect to.
	  \param call_end_module Classes that derive from esc_hub_watchable should pass in false.

	  call_end_module is required because of the constructor used in esc_hub_module, which doesn't use
	  the default sc_module constructor.
	*/
	esc_hub_watchable( const char *channame, qbhChannelKind kind=qbhDefChannel, 
					   bool call_end_module=true, bool requires_activation=false );

	//! Destructor
	~esc_hub_watchable()
	{}

	inline virtual void initialize();

	inline void 		pre();
	inline virtual void execute() {}
	inline void 		post() {}

 private:
	
	// Private HUB interaction member functions
	inline void			fanout_value( qbhValueHandle valueHandle );

	inline void			execute_hub_callback( qbhExtChannelActivity cbCode,
											  qbhHandle cbInfo,
											  qbhHandle* pCbOutValue );

	qbhChannelKind		m_kind;

	//! \internal
	// Overloaded from sc_interface.  Called when a port is bound to an interface of the esc_chan.
	// Activates the esc_hub_module.
	void register_port( sc_port_base& port_, const char* if_typename_ )
	{
		this->activate();
		esc_async_chan<T>::register_port( port_, if_typename_ );
	}
 protected:

};

template< class T >
inline qbhError
esc_hub_watchable<T>::hub_callback( qbhChannelHandle channelHandle,
										 void* pExtConnection,
										 qbhExtChannelActivity cbCode,
										 qbhHandle cbInfo,
										 qbhHandle* pCbOutValue )
{
	qbhError error = qbhOK;
	
	// Call the execute HUB callback member function:
	((esc_hub_watchable<T>*)pExtConnection)->execute_hub_callback( cbCode,
																		cbInfo,
																		pCbOutValue );

	return qbhOK;
}

template< class T >
inline
esc_hub_watchable<T>::esc_hub_watchable( const char *channame, qbhChannelKind kind, bool call_end_module, bool requires_activation )
	: esc_hub_module<T>(channame,NULL,qbhDefChannel,requires_activation),
	  esc_async_chan<T>( channame ),
	  m_kind(kind)
{
	if ( call_end_module )
		this->end_module();
}

template< class T >
inline
void esc_hub_watchable<T>::initialize()
{
	T scType;
	
	// Get the type type handle.
    this->m_channel_type = HubGetType( (char*)&scType );

	qbhError err = qbhRegisterChannel( (char *)this->m_channame_p,
                        this->m_channel_type,
                        this->m_kind,
						qbhInput,
						0, // channel_mux
						0, // channel config
						esc_hub::domain(),
						&esc_hub_watchable<T>::hub_callback,
						this,
                        &this->m_channel_handle );

	if (err != qbhOK )
	{
		esc_report_error( esc_error, "Failed to register channel '%s' with the Hub: %s\n",
                this->m_channame_p, qbhErrorString(err) );
	}
}

template< class T >
inline void
esc_hub_watchable<T>::pre()
{
	// permanently suspend this thread
	sc_module::wait( this->m_event );
}

////////////////////////////////////////////////////////////////////////////////
//
// esc_hub_watchable::execute_hub_callback
//
// This function maps HUB callback activity codes to
// member functions that perform the necessary operations.
//
////////////////////////////////////////////////////////////////////////////////
template< class T >
inline void
esc_hub_watchable<T>::execute_hub_callback( qbhExtChannelActivity cbCode,
												 qbhHandle cbInfo,
												 qbhHandle* pCbOutValue )
{
	// Analyze the channel activity code and take
	// appropriate action:
	switch( cbCode )
	{
		// A driver has been added to this
		// channel in another domain:
		case qbhDriverAdded:
		{
			// This is a don't care.  We only care about qbhFanoutValue

			break;
		}

		// A driver has been removed from this
		// channel in another domain:
		case qbhDriverRemoved:
		{
			// This is a don't care.  We only care about qbhFanoutValue

			break;
		}

		// A previously requested driver value is
		// now available:
		case qbhGetValueCompletion:
		{
			// This is a don't care

			break;
		}

		// A value has been written to the channel
		// in another domain:
		case qbhValueFanout:
		{
			fanout_value( (qbhValueHandle)cbInfo );

			break;
		}
	
		// A value has been requested from a
		// driver in this domain:
		case qbhValueRequested:
		{
			// This is a don't care, because a watcher
			// never has a value requested from it.

			break;
		}

		// A value has been acknowledged in another domain:
		case qbhValueAcked:
		{
			// This is a don't care, because a watcher
			// never has a value requested from it, and
			// therefore there's nothing to ack.

			break;
		}

		// A consumer from another domain has been enabled.
		case qbhConsumerEnabled:
		{
			break;
		}

		// A consumer from another domain has been disabled.
		case qbhConsumerDisabled:
		{
			break;
		}
	}
}

template< class T >
inline void
esc_hub_watchable<T>::fanout_value( qbhValueHandle valueHandle )
{
	T value;

	// Send the given value onto the channel:
	HubTransFrom( valueHandle, &value );

	esc_msg_lock<T>( &value );

	// Write the value to our esc_async_chan base class.  This is a non-blocking call.
	write( value );
}

/*!
  \class esc_hub_watcher
  \brief Watches an esc_watchable and sends the value to the Hub.

  This class is the same as esc_chan_hub_reader except it doesn't register
  as a driver, and it fans the value to the Hub, rather than making the driver
  value available.

  Templated on the datatype watched.
*/
template < class T >
class esc_hub_watcher : esc_hub_object< T >,
						esc_watcher< T >
{
 public:

	/*!
	  \brief Constructor
	  \param channame Name of the RAVE channel to drive
	  \param watchable The esc_watchable to connect to
	*/
	esc_hub_watcher( const char *channame, 
					 esc_watchable< T >* watchable )
		: esc_hub_object< T >( channame, qbhDefChannel ),
		  esc_watcher< T >()
	{
		int events = watchable->notify_events();

		// Get the set of events that Hub requires and the Hub feedback style for these events.
		esc_event_type reg_events;
		m_hub_feedback = esc_hub_feedback_style( events, &reg_events );

		// Register with the watchable.
		watchable->add_watcher( this, reg_events );

		// The base class' initialize() is all we need
        this->initialize();
	}

	//! Destructor
	~esc_hub_watcher()
	{}

	//! Called by the esc_watchable when the value is sent
	virtual void watch_notify( esc_event_type flag, const T* value, esc_handle handle )
	{
		// Paranoia
		if ( this->m_channel_handle == qbhEmptyHandle )
			return;

		if ( value )
		{
            this->m_flag = flag;
            this->m_events = flag;
            this->m_sc_value = *value;
            this->m_sc_value_available = 1;

			qbhValueHandle h;
			HubTransTo( &this->m_sc_value, &h );
            this->m_sc_value_available = 0;
			qbhFanoutValue( this->m_channel_handle,
							esc_hub::domain(),
							h,
							esc_hub_event(this->m_events,m_hub_feedback),
							esc_normalize_to_ps(sc_time_stamp()) );

			qbhDestroyHandle( h );
		}
	}
  protected:
	qbhEventFeedbackType m_hub_feedback;

};

#define ESC_OP_DEFAULT  0x0000	// Default flag values.
#define ESC_OP_UNLOCKED	0x0001	// Op will be created without a lock.


//Forward declaration
template < class T_TX >
class esc_chan_hub_reader;

/*!
  \class esc_hub_master_bfm_block
  \brief Class acts as a master block that communicates with the Hub

  All the knowledge is in the base class.  Templated on opset_tx.
 */
template < class T_TX >
class esc_hub_master_bfm_block : public esc_chan_hub_reader< T_TX >
{
 public:

	/*!
	  \brief Constructor
	  \param channame Name of the channel to drive.
	 */
	esc_hub_master_bfm_block( const char *channame, bool requires_activation=false )
		: esc_chan_hub_reader< T_TX >(channame,false,qbhBfmChannel,requires_activation)
	{ this->end_module(); }

	//! Destructor
	~esc_hub_master_bfm_block()
	{}

	//! Overloaded from esc_chan, will enable the driver before calling esc_chan's aread()
	virtual void awrite( const T_TX& value, int id=-1 )
	{
        this->enable();
		esc_chan< T_TX >::awrite( value, id );
	}
};

/*!
  \class esc_hub_standalone_bfm_block
  \brief Class acts as a standalone block that passes values from the Hub to its esc_chan
*/
template < class T_TX >
class esc_hub_standalone_bfm_block : public esc_hub_watchable< T_TX >
{
 public:

	/*!
	  \brief Constructor
	  \param channame Name of the channel to watch.
	*/
	esc_hub_standalone_bfm_block( const char *channame, bool requires_activation=false )
		: esc_hub_watchable< T_TX >(channame,qbhBfmChannel,false,requires_activation)
	{
        this->end_module();
	}

	//! Destructor
	~esc_hub_standalone_bfm_block()
	{}

};


#endif // BDW_HUB

#endif // ESC_HUB_LINK_HEADER_GUARD__
