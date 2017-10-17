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

#ifndef ESC_DISPATCHER_HEADER_GUARD__
#define ESC_DISPATCHER_HEADER_GUARD__

/*!	\file esc_dispatcher.h
 *
 *	\brief Support for inter-thread dispatching of operations.
 */

/*! \brief	Implements an operation dispatcher for a given interface.
 *
 *	The principle of execution for an operation dispatcher is:
 *
 *	\li	A dispatcher is instantiated and configured with a pointer to an
 *		object that implements the interface served by the dispatcher.
 *
 *	\li	The dispatcher itself implements the same interface.  Clients call
 *		functions in the dispatcher's implementation.
 *
 *	\li	When a function is called in the dispatcher's interface, the thread
 *		owned by the dispatcher is triggered as soon as it is no longer busy.
 *		
 *	\li	The dispatcher's thread then calls on the target interface the same 
 *		interface function that was originally called on the dispatcher.
 *		
 *	The dispatcher essientially performs interface operations in its own
 *	thread on the target interface.
 *
 *	A dispatcher must be instantiated with the following template parameters:
 *
 *	\param	T_TX	The reference form of the encoded operation class for the 
 *					interface being served.
 */
template< class T_TX >
class esc_dispatcher  : 
	public sc_module, 
	public T_TX::encoder_t, 
	public esc_encoder_target<typename T_TX::tx_ref_t>
{
  public:

	typedef typename T_TX::encoder_t	encoder_type;
	typedef typename T_TX::decoder_t	decoder_type;
	typedef typename T_TX::if_t			if_type;

	SC_HAS_PROCESS(esc_dispatcher);

	//! Constructor.
	esc_dispatcher( sc_string if_name, if_type *target ) 
#if ( defined(SC_API_VERSION_STRING) || defined(BDW_COWARE) )
// CnSC v2005.2.0 and OSCI SystemC 2.1v1 typedef
// sc_string to std::string, which doesn't
// have a cast operator to const char *.
		: sc_module( (if_name + "_dispatcher").c_str() ),
#else
		: sc_module( if_name + "_dispatcher" ),
#endif
			encoder_type( this ),
			m_decoder(m_target_p),
			m_target_p(target), m_tx_p(0), 
			m_busy(1)
	{
		SC_THREAD(main);
		end_module();
	}
	/*! \brief	Main thread.  
	 *
	 *	Executes once each time the write_tx() function is called.
	 *	This function and the write_tx() function are synchronized with
	 *	a two-event handshake.  For each iteration, an encoded operation 
	 *	is decoded on the decoder object which results in a function
	 *	call being made on the target interface.
	 */
	void main()
	{
		while(1) 
		{
			m_done.notify();
			m_busy = 0;
			wait(m_start);
			m_busy = 1;
			m_decoder.decode_tx( m_tx_p );
			m_tx_p = 0;
		}		
	}

  protected:
	if_type* m_target_p;
	T_TX* m_tx_p;
	decoder_type m_decoder;
	sc_event m_start;
	sc_event m_done;
	int m_busy;


	/*! \brief	Called by the encoder object when a new arrives.  
	 *
	 *	\param	op	A newly encoded operation that is to be proxied 
	 *				to the dispatcher's thread.
	 *
	 *	When a client calls an operation in the dispatcher's interface,
	 *	the write_tx() function is called after the operation has been 
	 *	encoded.  This function will block, and by proxy the calling client
	 *	will be blocked, until the dispatcher's thread has completed any
	 *	predecing operation, and then completed the requested operation.  
	 *	After the thread becomes available, it is triggered so it 
	 *	can decode and execute the encoded operation.
	 *
	 *	INCOMPLETE: Doesn't deal with case where request comes in when there's
	 *	already a pending request.  Should they be queued?  Should new ones
	 *	be rejected?  Also, should there be an option regarding whether 
	 *	the caller must wait until the operation he has launched has completed?
	 */
	void write_tx( T_TX* tx )
	{
		// Wait until thread is available.
		if ( m_busy || m_tx_p )
			wait( m_done );

		// Start the operation on the thread.
		m_tx_p = tx;
		m_start.notify();

		// Wait until the operation completes.
		wait( m_done );
	}

};

#endif
