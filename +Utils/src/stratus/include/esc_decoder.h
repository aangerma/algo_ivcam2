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

#ifndef ESC_DECODER_HEADER_GUARD__
#define ESC_DECODER_HEADER_GUARD__

/*!	\file esc_decoder.h
 *	\brief	Base classes to support operation decoder classes.
 */

//! Enumeration used to specify threading options for decoded operations.
enum esc_decoder_thread_style
{
	esc_thread_inline,		//! Methods will run in the thread that calls write_tx.
	esc_thread_pipelined,	//! Methods will run in their own threads.  write_tx thread blocked until tx_done() called.
	esc_thread_orphan		//! Methods will run in their own thread.  write_tx will not be blocked.
};

/*!
 * \brief	Base class for all interface decoders.
 *
 * An interface decoder accepts encoded transactions and calls the corresponding 
 * interface method on a specified interface.  Derived classes are responsible
 * for calling decoding operations and calling the appropriate
 * function on the target interface.  esc_decoder derived classes can either
 * be created by hand, or automatically by hubsync.  
 *
 * The naming convention for esc_decoder derived classes is <ifname_base>_decoder.  
 * For example, for an interface names \em my_if, the decoder class would be
 * names \em my_decoder.
 *
 * An esc_decoder offers control over which threads decoded operations will be run in.
 * This option affects how long the thread that calls write_tx will be blocked.  The 
 * thread_style contructor parameter gives control over threading as follows:
 *
 * \li \em esc_thread_inline	The thread that calls write_tx will be blocked until the method
 *								called in the target interface returns.
 *
 * \li \em esc_thread_pipelined	The thread that calls write_tx will be blocked until the 
 *								method called in the target interface calls tx_done().
 *
 * \li \em esc_thread_orphan	The thread that calls write_tx will not be blocked.
 * 
 *
 *	The write_tx() method can be called directly by applications that instantiate an esc_decoder
 *	subclass.  It is also called as part of the operation of various classes that include
 *	an esc_encoder.  For example, the esc_chan_txin port class includes an esc_decoder.  For
 *	that class, the time during which write_tx() is blocked gives the time between an aread()
 *	and aread_done() call on the channel's read interface.
 *
 *	The template parameter T_IF is the interface being served.
 *	The template parameter T_TXREF is the reference form of the esc_tx subclass used to 
 *	encode the operations.  
 */
template <class T_IF,class T_TXREF>
class esc_decoder : 
	public esc_tx_write_if<T_TXREF>
{
  public:
    typedef T_TXREF                      data_type;

	/*! \brief Constructor
	 *	\param target	Specifies the interface on which methods will be called for decoded transactions.
	 *	\param threading	Specifies the threading style that will be used for methods called on the target interface.
	 *
	 *	An esc_decoder is configured with a target implementation of the T_IF interface and
	 * 	a threading style.  The target interface can be re-configured later using set_target().
	 *	A threading_style of esc_thread_pipelined can only be used if the object is created during
	 *	elaboration time since an sc_event must be employed.  Also, if the threading style is
	 *	either esc_thread_pipelined or esc_thread_orphan, the threads are created dynamically using
	 *	the sc_fork library.  The global thread pool must have been initialized using thread_pool::init() 
	 *	to use these options.
	 */
	esc_decoder( T_IF* target=0, esc_decoder_thread_style threading=esc_thread_inline ) 
		: m_target_p(target), m_threading(threading), m_event_p(0)
	{
		// Error check on threading usage.
		if ( ( (( m_threading == esc_thread_pipelined ) || ( m_threading == esc_thread_orphan ) ))
		   ) // && !thread_pool::global_thread_pool )
		{
			esc_report_error( esc_fatal, "Attempt to instantiate esc_decoder with a dynamic threading option with no thread pool.  Use thread_pool::init()." );
		}
		// Setup an event for use with pipelining if required.
		if ( m_threading == esc_thread_pipelined ) 
		{
			if ( sc_get_curr_simcontext()->is_running() )
			{ 
				// This can only be done during elaboration.
				// Fall back to inline.
				esc_report_error( esc_error, "Attempt to instantiate esc_decoder with a pipelined threading option after elaboration." );
				m_threading = esc_thread_inline;
			}
			else
			{
				m_event_p = new sc_event;
			}
		}
	}

	~esc_decoder()
	{
		delete m_event_p;
	}

	//! Allows the target interface to be set or changed after the object has been constructed.
	inline void set_target( T_IF* target )
	{
		m_target_p = target;
	}

	//! Returns the current target interface or NULL if none has been set.
	inline T_IF* target() const
	{
		return m_target_p;
	}

	/*! \brief	Causes a transaction to be decoded.
	 *	\param tx	The transaction object to be decoded.
	 *
	 *	The write_tx method will cause the given transaction to be decoded and the appropraite
	 *	method called on the target interaface.  When the calling thread will be un-blocked
	 *	depends on the thread_style parameter given in the constructor.
	 */
	inline void write_tx( data_type tx )
	{
		switch ( m_threading )
		{
			case esc_thread_inline:
				// Dispatch to the target function directly, blocking the caller until it completes.
				decode_tx( tx );
				break;

			case esc_thread_pipelined:
				if ( m_event_p )
				{
					// Spawn the event and wait for it to either finish or call tx_done().
#if 0
					int rslt;
		   			sc_join_handle h = sc_spawn_method( &rslt, this, &esc_decoder<T_IF,T_TXREF>::decode_tx, tx );
					if ( !h.done_flag() )
					{
						wait( h.done_event() | *m_event_p );
					}
#endif
				}
				break;

			case esc_thread_orphan:
				// Spawn the thread as an orphan.
#if 0
				int rslt;
	   			sc_join_handle h = sc_spawn_method( sc_spawn_options(0,true), &rslt, this, &esc_decoder<T_IF,T_TXREF>::decode_tx, tx );
#endif
				break;
		}
	}

	/*!	\brief	Indicates that write_tx should return from a pipelined transaction.
	 *	Methods in the target interface can call this method to indicate that the
	 *	invoking thread that called write_tx can be un-blocked.  The target method,
	 *	which is executing in its own thread, can continue as long as is necessary.
	 *	This method only has an effect if the esc_decoder was constructed with
	 *	the esc_thread_pipelined threading style.  
	 */
	 inline void tx_done()
	 {
		if ( m_event_p )
			m_event_p->notify();
	 }

	//! Gives the specified threading style for this decoder.
	esc_decoder_thread_style threading_style()
	{
		return m_threading;
	}

  protected:
	T_IF*	m_target_p;						// Target that implements interface.
	esc_decoder_thread_style m_threading;	// Threading style for interface functions.
	sc_event* m_event_p;					// Event used to implement pipelining.

	// Implemented by derived classes to decode the op 
	virtual int decode_tx( data_type tx )=0;

};

//! Declares an interface decoder class for the given interface.
#define IF_DECODER_CLASS(ifname) \
	/*! \class ifname##_decoder */ \
	class ifname##_decoder : public esc_decoder<ifname##_if,ifname##_tx*>
	
//! Defines a constructor for an interface decoder class for the given interface.
#define IF_DECODER_CTOR(ifname) \
  public: \
	ifname##_decoder( ifname##_if* target=0, esc_decoder_thread_style threading=esc_thread_inline ) \
		: esc_decoder<ifname##_if,ifname##_tx*>( target, threading ) \
	{}


#endif
