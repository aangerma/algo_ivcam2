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

#ifndef ESC_MSG_HEADER_GUARD__
#define ESC_MSG_HEADER_GUARD__

/*!
  \file esc_msg.h
  \brief Bases classes for reference counted messages.
*/

//! Internal definition of unset time in ESC
#define esc_unset_time (sc_time( -1.0 , SC_SEC))

#ifndef ESC_DEBUG_LOCK
//! If set to 1 on the command line, debugs calls to esc_msg_lock()/esc_msg_unlock()
#define ESC_DEBUG_LOCK 0
#endif

/*!
  \class esc_primitive_msg
  \brief Non-templated base class for messages that supports storage of transaction start times.
*/
class esc_primitive_msg {

  public:

    //! Constructor
    inline esc_primitive_msg() : m_start_time(esc_unset_time)
    {}

	//! Returns whether or not it has a start time
    bool has_start_time()
    { return (m_start_time != esc_unset_time); } 

	//! Returns the start time
    sc_time start_time()
    { return m_start_time; }

	//! Sets the start time
    void set_start_time( sc_time new_start_time )
    { m_start_time = ((new_start_time == esc_unset_time) ? sc_time(0,SC_PS) : new_start_time) ; }

	//! Clears the start time
    void clear_start_time()
    { m_start_time = esc_unset_time; }

  private:
    sc_time         m_start_time;       // Time of transaction start.
};


/*!
  \class esc_msg
  \brief Wrapper template to make arbitrary data types into message classes.
*/
template< class T >
class esc_msg : public esc_primitive_msg {

  public:

    //! Constructor
    inline esc_msg()
    {}

	/*!
	  \brief Constructor
	  \param value The value to use as a message class
	*/
    inline esc_msg( const T& value ):
        m_value( value )
    {}

	/*!
	  \brief Cast operator
	  \return The stored value - not valid if not set
	*/
    inline operator T& () 
    { return m_value; } 

	/*!
	  \brief Sets the internal value
	  \param value The new value
	*/
    inline void operator = ( const T& value ) 
    { m_value = value; }

  private:

    // Attributes
    T   m_value;
};

/*!
  \class esc_msg_base
  \brief Base class to be used for classes that desire reference counted message behavior.

  When the lock count transitions to 0, the object will be deleted.  
*/
class esc_msg_base : public esc_primitive_msg {
  protected:
    int         m_lock_count;  // # of holders of this object instance.

  public:
	/*!
	  \brief Constructor
	  \param initial_locks The number of initial locks to add
	*/
    inline esc_msg_base( int initial_locks = 0 ):
        m_lock_count( initial_locks )
    {}
    
	//! Destructor
    virtual ~esc_msg_base()
    {
#if ESC_DEBUG_LOCK
		fprintf(stderr,"%s: DESTRUCTOR: addr: 0x%x\n",
				ESC_CUR_TIME_STR, this );
#endif
	}

	/*!
	  \brief Adds lock(s) to the object
	  \param n_locks The number of locks to add
	*/
    inline void lock( int n_locks = 1 ) 
    { 
#if ESC_DEBUG_LOCK
		fprintf(stderr,"%s: LOCK: addr: 0x%x\n",
				ESC_CUR_TIME_STR, (this));
#endif
        m_lock_count += n_locks; 
    }
    
	/*!
	  \brief Remove locks from the object
	  \param n_unlocks The number of locks to remove
	  \param dont_delete If non-zero, will never delete the object in this function

	  If the number of locks is at or below zero, and dont_delete is 0,
	  the object will be deleted
	*/
    inline void unlock( int n_unlocks = 1, int dont_delete=0 ) 
    { 
#if ESC_DEBUG_LOCK
		fprintf(stderr,"%s: UNLOCK: addr: 0x%x\n",
				ESC_CUR_TIME_STR, (this));
#endif
        m_lock_count -= n_unlocks;
        if ( m_lock_count <= 0 && !dont_delete ) delete this;
    }
};

/*!	
  \brief Fallback implementation of esc_msg_lock

  The esc_msg_lock function is called in applications where a lock should logically
  be applied to an object, but where that objects has a type given by a template
  parameter.  This templated function supplies a fallback implementation that does
  nothing.  This serves types for which locking and unlocking is meaningless such
  as intrinsic values.  

  Note that an overload must be supplied for each specific class on which this function
  will be called.  It is not sufficient to supply an overload for esc_msg_base,
  because the C++ function template instantiation algorithms will chose this fallback
  function rather than one for a base class.  For example, if class my_msg is derived
  from esc_msg_base, an esc_msg_lock() function must be supplied for my_msg as follows:
	
  \code
  void esc_msg_lock( my_msg** msg ) 
  {
      (*msg)->lock();
  }
  \endcode
*/
template <class T>
inline void esc_msg_lock( T const * msg )
{
#if ESC_DEBUG_LOCK
	fprintf(stderr,"%s: FALLBACK LOCK: addr: 0x%x type %s\n",
			ESC_CUR_TIME_STR, (*msg), typeid(*msg).name());
#endif
}

/*!
  \brief Fallback implementation of esc_msg_unlock

  Similar to esc_msg_unlock, but for the unlock operation.
*/
template <class T>
inline void esc_msg_unlock( T const * msg )
{
#if ESC_DEBUG_LOCK
	fprintf(stderr,"%s: FALLBACK UNLOCK: addr: 0x%x type %s\n",
			ESC_CUR_TIME_STR, (*msg), typeid(*msg).name());
#endif
}

//! Convenience macro that declares an esc_msg_lock and esc_msg_unlock function for an esc_msg subclass.
#define esc_declare_lock_unlock( msg_class )                                         \
	template <>                                                                      \
	inline void esc_msg_lock< msg_class * >( msg_class * const * msg)				\
	{  (( msg_class *)*msg)->lock(1); }												\
	template <>                                                                     \
	inline void esc_msg_unlock< msg_class * >( msg_class * const * msg)				\
	{  (( msg_class *)*msg)->unlock(1);	}

#endif
