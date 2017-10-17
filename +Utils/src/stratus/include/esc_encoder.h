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

#ifndef ESC_ENCODER_HEADER_GUARD__
#define ESC_ENCODER_HEADER_GUARD__


/*!	\file esc_encoder.h
 *	\brief	Base classes to support operation encoder classes.
 */


/*!
 * \brief Interface used to access all clients of encoded transactions.
 */
template <class T_TXREF>
class esc_tx_write_if : virtual public sc_interface
{
  public:
	virtual void write_tx( T_TXREF tx )=0;
};

/*!
 * \brief Default target class for the inline target of an esc_encoder.
 *
 *	If no specific interface is given to an esc_encoder as a target
 *	class, the esc_encoder_target class is used as a default.  The esc_encoder
 *	will forward encoded operations to its target by calling the write(esc_tx*) 
 *	function.  This is designed to transparently support channel classes that
 *	have a function with such a signature.  The esc_encoder_target class implements 
 *	the write(esc_tx*) function by calling the write_tx(esc_tx*) function from the
 *	esc_tx_write_if.
 */
template <class T_TXREF>
class esc_encoder_target : public esc_tx_write_if<T_TXREF>
{
  public:
	inline void write( T_TXREF tx )
	{
		write_tx( tx );
	}
};


/*!
 * \brief Base class for all interface encoders.
 *
 * Each derived class implements each function in the target interface 
 * by encoding the function call and its parameters as operation object, 
 * and then calls the base class write_tx() which forwards the call 
 * on to the target.  If the target's write_tx() function blocks, then
 * the original interface call will block as well.
 *
 * The template parameter TT is the type of the target interface.
 * This interface must implement a function with the following
 * signature:
 *		void write( T_TXREF );
 * where T_TXREF is the reference form of the esc_tx subclass used to encode the 
 * operations.  This makes the class compatible with may channel classes that 
 * have data-oriented write() functions.
 *
 * If the TT template parameter is omitted, it defaults to esc_encoder_target.
 * If the default esc_encoder_target<T_TXREF> is used, then the target class should
 * be derived from esc_encoder_target<T_TXREF>, and should also implement the write_tx(T_TXREF)
 * method from the esc_tx_write_if<T_TXREF> interface.  This method will be called with each
 * transaction object after it is encoded.
 */
template <class T_TXREF, class TT = esc_encoder_target<T_TXREF> >
class esc_encoder 
{
  public:
    //! Constructor - users should never need to explicitly call the constructor
	esc_encoder( TT* target=0 ) : m_target_p(target), m_start_time(esc_unset_time)
	{}

    //! Sets the target, useful if it wasn't passed in to the constructor
	inline void set_target( TT* target )
	{
		m_target_p = target;
	}

	//! Sets the start time to be encoded into the next transaction.
    void set_start_time( sc_time new_start_time )
    { m_start_time = ((new_start_time == esc_unset_time) ? sc_time(0,SC_PS) : new_start_time) ; }

	//! Sets the start time for the next encoded transaction to the current time.
    void set_start_time()
	{ set_start_time( sc_get_curr_simcontext()->time_stamp() ); }

	//! True if a start time has been set for the next transaction.
    bool has_start_time()
    { return (m_start_time != esc_unset_time); } 

	//! Start time to be used for the next transaction.
    sc_time start_time()
    { return m_start_time; }

	//! Clear the start time so that one will not be incorporated into the next transaction.
    void clear_start_time()
    { m_start_time = esc_unset_time; }

  protected:
	TT*	m_target_p;	// Target of the write operation.
    sc_time m_start_time;       // Time of transaction start.

	inline void write_tx( T_TXREF tx )
	{
		// Do main write.
		if ( m_target_p )
		{
			m_target_p->write( tx );
		}
	}
};

//! Declares an operation encoder class for the given interface.
#define IF_ENCODER_CLASS(ifname) \
	/*! \class ifname##_encoder */ \
	template <class TT=esc_encoder_target< ifname##_tx* > > \
	class ifname##_encoder : public ifname##_if, public esc_encoder<ifname##_tx*,TT>
	

//! Defines the constructor for the operation encoder class for the given interface.
#define IF_ENCODER_CTOR(ifname) \
  public: \
	ifname##_encoder( TT *_target=0 ) : esc_encoder<ifname##_tx*,TT>(_target) \
	{}


#endif
