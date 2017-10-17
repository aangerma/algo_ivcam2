/**************************************************************************
**
** This file is part of the Cynthesizer (TM) software product and is protected 
** by law including United States copyright laws, international treaty 
** provisions, and other applicable laws.
**
** Copyright (c) 2012 Forte Design Systems and / or its subsidiary(-ies).  All
rights reserved.
** Copyright (c) 2015 Cadence Design Systems, Inc. All rights reserved worldwide.
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

#ifndef ESC_COSIM_HEADER_GUARD__
#define ESC_COSIM_HEADER_GUARD__

#ifndef  HUB_USE_DYNAMIC_PRODCESSES
#if SYSTEMC_VERSION >= 20120701
#define HUB_USE_DYNAMIC_PRODCESSES 1
#else
#define HUB_USE_DYNAMIC_PRODCESSES 0
#endif
#endif

#if defined(STRATUS_HLS) && !defined(cynthhl_h_INCLUDED)
#include "cynthhl.h"
#endif

//! Specifies the type of trace file
enum esc_trace_t {
	esc_trace_vcd=0,	//! Verilog VCD trace
	esc_trace_fsdb=1,	//! Novas FSDB trace
	esc_trace_scv=2,	//! SCV transaction logging
	esc_trace_off=3,	//! Tracing is off.
};

//! Specifies the direction to link a SystemC signal with a signal in another domain
enum esc_link_direction_t {
	esc_link_none=0,	//! No direction specified.
	esc_link_in=1,		//! Drive the SystemC signal from an external domain
	esc_link_out=2,		//! Drive an external signal from a SystemC signal
	esc_link_inout=3	//! Signals from either domain drive the other - ** NOT CURRENTLY SUPPORTED **
};

#if BDW_WRITEFSDB == 1
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102
#define topString std::string("sc_main.")
#include "fsdb_nc_mix.h"
#else
#include "fsdb_trace_file.h"
#endif
#endif

#if BDW_HUB
#if __GNUC__ < 3
#include <stdio.h>
#else
#include <iostream>
#endif
#include "qbhCapi.h"
#include "capicosim.h"


							/*!
							  \internal
							  \brief Creates an esc_signal_sc_bit
							  \return The new esc_signal_sc_bit, owned by the calling function
							*/
inline
esc_signal< sc_bit > *	alloc_esc_sig( sc_signal < sc_bit > *sig );

							/*!
							  \internal
							  \brief Creates an esc_signal_char
							  \return The new esc_signal_char, owned by the calling function
							*/
inline
esc_signal< char > *	alloc_esc_sig( sc_signal < char > *sig );

							/*!
							  \internal
							  \brief Creates an esc_signal_char
							  \return The new esc_signal_char, owned by the calling function
							*/
inline
esc_signal< unsigned char > *	alloc_esc_sig( sc_signal < unsigned char > *sig );

							/*!
							  \internal
							  \brief Creates an esc_signal_bool
							  \return The new esc_signal_bool, owned by the calling function
							*/
inline
esc_signal< bool > *	alloc_esc_sig( sc_signal < bool > *sig );

							/*!
							  \internal
							  \brief Creates an esc_signal_double
							  \return The new esc_signal_double, owned by the calling function
							*/
inline
esc_signal< double > *	alloc_esc_sig( sc_signal < double > *sig );

							/*!
							  \internal
							  \brief Creates an esc_signal_int
							  \return The new esc_signal_int, owned by the calling function
							*/
inline
esc_signal< int > *		alloc_esc_sig( sc_signal < int > *sig );

							/*!
							  \internal
							  \brief Creates an esc_signal_sc_int
							  \return The new esc_signal_sc_int, owned by the calling function
							*/
template< int W >
inline
esc_signal< sc_int< W > >*alloc_esc_sig( sc_signal < sc_int < W > > *sig );

							/*!
							  \internal
							  \brief Creates an esc_signal_sc_uint
							  \return The new esc_signal_sc_uint, owned by the calling function
							*/
template< int W >
inline
esc_signal< sc_uint< W > >* alloc_esc_sig( sc_signal < sc_uint < W > > *sig );

							/*!
							  \internal
							  \brief Creates an esc_signal_sc_bigint
							  \return The new esc_signal_sc_bigint, owned by the calling function
							*/
template< int W >
inline
esc_signal< sc_bigint< W > >* alloc_esc_sig( sc_signal < sc_bigint < W > > *sig );

							/*!
							  \internal
							  \brief Creates an esc_signal_sc_biguint
							  \return The new esc_signal_sc_biguint, owned by the calling function
							*/
template< int W >
inline
esc_signal< sc_biguint< W > >* alloc_esc_sig( sc_signal < sc_biguint < W > > *sig );

							/*!
							  \internal
							  \brief Creates an esc_signal_sc_time
							  \return The new esc_signal_sc_time, owned by the calling function
							*/
inline
esc_signal< sc_time > *alloc_esc_sig( sc_signal < sc_time > *sig );

							/*!
							  \internal
							  \brief Creates an esc_signal_cynw_string
							  \return The new esc_signal_cynw_string, owned by the calling function
							*/
inline
esc_signal< cynw_string > *alloc_esc_sig( sc_signal < cynw_string > *sig );

/*!
  \file esc_cosim.h
  \brief Classes and functions for SystemC-Hub cosimulation.
*/

extern void esc_enable_cosim();

extern void esc_multiple_writers_warning();

template< class T >
class esc_hdl_probe
{
 public:
	esc_hdl_probe( const char* ext_path, const char* ext_domain=NULL ) : 
		m_tried_connect(false), m_handle(qbhEmptyHandle), m_sig_p(NULL)
	{
		m_ext_path = strdup( ext_path );
		m_ext_domain = ( ext_domain ? strdup(ext_domain) : 0 );
	}
	~esc_hdl_probe()
	{
		free(m_ext_path);
		if ( m_ext_domain ) 
			free( m_ext_domain );
	}

	T read()
	{
		T retval;

		if ( connected() )
		{
			qbhValueRecord *val = m_sig_p->valrec();
			qbhGetSignalValue( m_handle, esc_hub::domain(), &val );

			m_sig_p->set( *val, &retval );
		}
		return retval;
	}

	void write( const T& val )
	{
		if ( connected() )
		{
			m_sig_p->get(&val);

			qbhSetSignalValue( m_handle, esc_hub::domain(), m_sig_p->valrec(), 0.0 );
		}
	}

	operator T()
	{
		return read();
	}

	esc_hdl_probe<T>&	operator = ( const T& val )
	{
		write( val );
		return *this;
	}

 protected:
	bool				m_tried_connect;
	T					m_val;
	qbhNetlistHandle	m_handle;
	esc_signal< T > *	m_sig_p;
	char *				m_ext_path;
	char *				m_ext_domain;

	//! \internal
	// Attempts a connection once.  
	// Designed to avoid connection until access is required.
	inline bool connected()
	{
		if ( !m_tried_connect )
		{
			m_tried_connect = true;
			qbhError err = qbhNetlistFind( (char*)m_ext_path, (char*)m_ext_domain, qbhEmptyHandle, &m_handle, qbhNetlistSignal );
			if ( err == qbhOK )
			{
				m_sig_p = alloc_esc_sig( (sc_signal< T > *)NULL );
			}
			else
			{
				esc_report_error( esc_error, "esc_hdl_probe: Failed to find HDL signal: %s\n",
								  m_ext_path );
			}
		}
		return (m_handle != qbhEmptyHandle); 
	}
};

/*!
  \internal
  \brief Un-templated virtual base class for esc_signal.
*/
class esc_signal_base
{
  public:
	virtual ~esc_signal_base() {}
};

/*!
  \internal
  \brief Base class for signals that are read from or written to other domains in the Hub.

  Classes for a particular type must derive from this class.
*/
template < class T >
class esc_signal
	: public esc_signal_base
{
 public:
	typedef T data_type;

	virtual ~esc_signal< T >() {}
	/*!
	  \brief Returns the name of this signal
	*/
	virtual const char* name()=0;
	/*!
	  \brief Returns the qbhValueRecordType for this signal
	*/
	virtual qbhValueRecordType type()=0;
	/*!
	  \brief This method returns the value of its target variable
	*/
	virtual void get( const T* val=NULL, qbhValueRecord* vr=0 )=0;
	/*!
	  \brief This method retunrs the width in bits of its target variable
	*/
	virtual int get_bit_width()=0;
	/*!
	  \brief This method returns the value change event associated with its target variable
	*/
	virtual const sc_event& get_event()=0;
	/*!
	  \brief This method sets the value of the target variable to the supplied value

	*/
	virtual void set( qbhValueRecord &val, T *in=NULL )=0;
	/*!
	  \brief This method returns the qbhValueRecord buffer used to communicate with the Hub.

	*/
	qbhValueRecord *valrec() { return p_valrec; }

	virtual bool isClock()
		{ return false; }

protected:
	qbhValueRecord *p_valrec;
};

/*!
  \internal
  \brief Class for sc_signal<sc_bigint<W>> that gets read from or written to other domains in the Hub.
*/
template< int W >
class esc_signal_sc_bigint : public esc_signal< sc_bigint< W > >
{

 public:
	esc_signal_sc_bigint( sc_signal<sc_bigint<W> >& target=*(sc_signal<sc_bigint<W> >*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);

		int w = W > 0 ? W : 1;
		v_nWords = ( ( W - 1 ) / 32 ) + 1;
        this->p_valrec->v_value.v_long_abval.bits =
			(qbhABVal *)malloc( v_nWords * sizeof(qbhABVal) );
        this->p_valrec->v_value.v_long_abval.length = w;
	}

	~esc_signal_sc_bigint()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
		{ return qbhLongABValType; }

	virtual void		get( const sc_bigint< W >* val=NULL, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		for (int i = 0; i < v_nWords; ++i)
		{
			int low = i << 5;
			int high = low + 31;
			if ( W - 1 < high)
				high = W - 1;
			sc_bigint<32> slice;

			if ( m_target_p )
				slice = m_target_p->read().range( high, low );
			else if ( val )
				slice = val->range( high, low );

            vr->v_value.v_long_abval.bits[i].aval = slice.to_int();
            vr->v_value.v_long_abval.bits[i].bval = 0;
		}
	}

	virtual int			get_bit_width()
		{ return W; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, sc_bigint< W >* in=NULL )
	{
		sc_bigint<W> toWrite;
		bool setOK = false;

		switch (val.tag)
		{
		case qbhLongABValType:
			{
				for (int i = 0; i < v_nWords; ++i)
				{
					int low = i << 5;
					int high = low + 31;
					if ( W - 1 < high)
						high = W - 1;

					toWrite.range(high, low) = val.v_value.v_long_abval.bits[i].aval;
				}
				setOK = true;
				break;
			}
		case qbhABValType:
			{
				if (W <= 32)
				{
					toWrite = val.v_value.v_abval.bits.aval;
					setOK = true;
				}
				break;
			}
		case qbhBitValType:
			{
				if (W == 1)
				{
					toWrite = (val.v_value.v_bit == '1');
					setOK = true;
				}
				break;
			}
		default:
			break;
		}

		if (setOK)
		{
			if ( m_target_p )
				m_target_p->write(toWrite);
			if ( in )
				*in = toWrite;
		}
	}

  protected:
  	sc_signal<sc_bigint<W> >* m_target_p;   // SystemC target variable.
	int v_nWords;
};

/*!
  \internal
  \brief Class for sc_signal<sc_biguint<W>> that get read from or written to other domains in the Hub.
*/
template< int W >
class esc_signal_sc_biguint : public esc_signal< sc_biguint< W > >
{
 public:
	esc_signal_sc_biguint( sc_signal<sc_biguint<W> >& target=*(sc_signal<sc_biguint<W> >*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);

		int w = W > 0 ? W : 1;
		v_nWords = ( ( W - 1 ) / 32 ) + 1;
        this->p_valrec->v_value.v_long_abval.bits =
			(qbhABVal *)malloc( v_nWords * sizeof(qbhABVal) );
        this->p_valrec->v_value.v_long_abval.length = w;
	}

	~esc_signal_sc_biguint()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
		{ return qbhLongABValType; }

	virtual void		get( const sc_biguint< W >* val=NULL, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		for (int i = 0; i < v_nWords; ++i)
		{
			int low = i << 5;
			int high = low + 31;
			if ( W - 1 < high)
				high = W - 1;
			sc_biguint<32> slice;

			if ( m_target_p )
				slice = m_target_p->read().range( high, low );
			else if ( val )
				slice = val->range( high, low );

            vr->v_value.v_long_abval.bits[i].aval = slice.to_int();
            vr->v_value.v_long_abval.bits[i].bval = 0;
		}
	}

	virtual int			get_bit_width()
		{ return W; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, sc_biguint< W > *in=NULL )
	{
		sc_biguint<W> toWrite;
		bool setOK = false;

		switch (val.tag)
		{
		case qbhLongABValType:
			{
				for (int i = 0; i < v_nWords; ++i)
				{
					int low = i << 5;
					int high = low + 31;
					if ( W - 1 < high)
						high = W - 1;

					toWrite.range(high, low) = val.v_value.v_long_abval.bits[i].aval;
				}
				setOK = true;
				break;
			}
		case qbhABValType:
			{
				if (W <= 32)
				{
					toWrite = val.v_value.v_abval.bits.aval;
					setOK = true;
				}
				break;
			}
		case qbhBitValType:
			{
				if (W == 1)
				{
					toWrite = (val.v_value.v_bit == '1');
					setOK = true;
				}
				break;
			}
		default:
			break;
		}

		if (setOK)
		{
			if ( m_target_p )
				m_target_p->write(toWrite);
			if ( in )
				*in = toWrite;
		}
	}

  protected:
  	sc_signal<sc_biguint<W> >* m_target_p;   // SystemC target variable
	int v_nWords;
};

/*!
  \internal
  \brief Class for sc_signal<sc_int<W>> that get read from or written to other domains in the Hub.
*/
template< int W >
class esc_signal_sc_int : public esc_signal< sc_int< W > >
{
 public:
	esc_signal_sc_int( sc_signal<sc_int<W> >& target=*(sc_signal<sc_int<W> >*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);

		if ( W <= 1 )
		{
			v_nWords = 1;
		}
		else if ( W <= 32)
		{
            this->p_valrec->v_value.v_abval.length = W;
			v_nWords = 1;
		}
		else
		{
			v_nWords = ( ( W - 1 ) / 32 ) + 1;
            this->p_valrec->v_value.v_long_abval.bits =
				(qbhABVal *)malloc( v_nWords * sizeof(qbhABVal) );
            this->p_valrec->v_value.v_long_abval.length = W;
		}
	}

	~esc_signal_sc_int()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
	{
		if ( W <= 1 )
			return qbhBitValType;
		else if ( W <= 32 )
			return qbhABValType;
		else
			return qbhLongABValType;
	}

	virtual void		get( const sc_int< W >* val=NULL, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		if ( W <= 1 )
		{
			int v=0;
			if ( m_target_p )
				v = m_target_p->read().to_int();
			else if ( val )
				v = val->to_int();

            vr->v_value.v_bit = (v & 1) ? '1' : '0';
		}
		else if ( W <= 32)
		{
			int v = 0;
			if ( m_target_p )
				v = m_target_p->read().to_int();
			else if ( val )
				v = val->to_int();

            vr->v_value.v_abval.bits.aval = v;
            vr->v_value.v_abval.bits.bval = 0;
		}
		else
			for (int i = 0; i < v_nWords; ++i)
			{
				int low = i << 5;
				int high = low + 31;
				if ( W - 1 < high)
					high = W - 1;
				sc_int<32> slice;

				if ( m_target_p )
					slice = m_target_p->read().range( high, low );
				else if ( val )
					slice = val->range( high, low );

                vr->v_value.v_long_abval.bits[i].aval = slice.to_int();
                vr->v_value.v_long_abval.bits[i].bval = 0;
			}
	}

	virtual int			get_bit_width()
		{ return W; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, sc_int< W > *in=NULL )
	{
		sc_int<W> toWrite;
		bool setOK = false;

		switch (val.tag)
		{
		case qbhLongABValType:
			{
				for (int i = 0; i < v_nWords; ++i)
				{
					int low = i << 5;
					int high = low + 31;
					if ( W - 1 < high)
						high = W - 1;

					toWrite.range(high, low) = val.v_value.v_long_abval.bits[i].aval;
				}
				setOK = true;
				break;
			}
		case qbhABValType:
			{
				if (W <= 32)
				{
					toWrite = val.v_value.v_abval.bits.aval;
					setOK = true;
				}
				break;
			}
		case qbhBitValType:
			{
				if (W == 1)
				{
					toWrite = (val.v_value.v_bit == '1');
					setOK = true;
				}
				break;
			}
		default:
			break;
		}

		if (setOK)
		{
			if ( m_target_p )
				m_target_p->write(toWrite);
			if ( in )
				*in = toWrite;
		}
	}

  protected:
  	sc_signal<sc_int<W> >* m_target_p;	// SystemC target variable.
	int v_nWords;
};

/*!
  \internal
  \brief Class for sc_signal<sc_uint<W>> that get read from or written to other domains in the Hub.
*/
template< int W >
class esc_signal_sc_uint : public esc_signal< sc_uint< W > >
{
 public:
	esc_signal_sc_uint( sc_signal<sc_uint<W> >& target=*(sc_signal<sc_uint<W> >*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);

		if ( W <= 1 )
		{
			v_nWords = 1;
		}
		else if ( W <= 32)
		{
            this->p_valrec->v_value.v_abval.length = W;
			v_nWords = 1;
		}
		else
		{
			v_nWords = ( ( W - 1 ) / 32 ) + 1;
            this->p_valrec->v_value.v_long_abval.bits =
				(qbhABVal *)malloc( v_nWords * sizeof(qbhABVal) );
            this->p_valrec->v_value.v_long_abval.length = W;
		}
	}

	~esc_signal_sc_uint()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
	{
		if ( W <= 1 )
			return qbhBitValType;
		else if ( W <= 32 )
			return qbhABValType;
		else
			return qbhLongABValType;
	}

	virtual void		get( const sc_uint< W >* val=NULL, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		if ( W <= 1 )
		{
			unsigned int v = 0;
			if ( m_target_p )
				v = m_target_p->read().to_uint();
			else if ( val )
				v = val->to_uint();
            vr->v_value.v_bit = (v & 1) ? '1' : '0';
		}
		else if ( W <= 32)
		{
			unsigned int v = 0;
			if ( m_target_p )
				v = m_target_p->read().to_uint();
			else if ( val )
				v = val->to_uint();

            vr->v_value.v_abval.bits.aval = v;
            vr->v_value.v_abval.bits.bval = 0;
		}
		else
			for (int i = 0; i < v_nWords; ++i)
			{
				int low = i << 5;
				int high = low + 31;
				if ( W - 1 < high)
					high = W - 1;
				sc_uint<32> slice;
				if ( m_target_p )
					slice = m_target_p->read().range( high, low );
				else if ( val )
					slice = val->range( high, low );

                vr->v_value.v_long_abval.bits[i].aval = slice.to_uint();
                vr->v_value.v_long_abval.bits[i].bval = 0;
			}
	}

	virtual int			get_bit_width()
		{ return W; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, sc_uint<W> *in=NULL )
	{
		sc_uint<W> toWrite;
		bool setOK = false;

		switch (val.tag)
		{
		case qbhLongABValType:
			{
				for (int i = 0; i < v_nWords; ++i)
				{
					int low = i << 5;
					int high = low + 31;
					if ( W - 1 < high)
						high = W - 1;

					toWrite.range(high, low) = val.v_value.v_long_abval.bits[i].aval;
				}
				setOK = true;
				break;
			}
		case qbhABValType:
			{
				if (W <= 32)
				{
					toWrite = val.v_value.v_abval.bits.aval;
					setOK = true;
				}
				break;
			}
		case qbhBitValType:
			{
				if (W == 1)
				{
					toWrite = (val.v_value.v_bit == '1');
					setOK = true;
				}
				break;
			}
		default:
			break;
		}

		if (setOK)
		{
			if ( m_target_p )
				m_target_p->write(toWrite);
			if ( in )
				*in = toWrite;
		}
	}

  protected:
  	sc_signal<sc_uint<W> >* m_target_p;	// SystemC target variable.
	int v_nWords;
};


enum esc_clk_edge
{
	esc_alledge = 0,
	esc_posedge = 1,
	esc_negedge = 2
};

/*!
  \internal
  \brief Class for checking whether an esc_signal and its external counterpart are synchronized.
*/
template< class T >
class esc_synchronizer
{
public:

	static const unsigned int max_edges = 100;

	esc_synchronizer( const char *name,
					  const char *extName,
					  esc_clk_edge checkEdges=esc_alledge,
					  int nEdges=2 ) :
		p_name( name ), p_extName(0), m_nEdges( nEdges ),
		m_checkEdges( checkEdges ), m_cHandle( qbhEmptyHandle )
	{
		if ( extName != NULL )
		{
			p_extName = new char[ strlen(extName) + 1 ];
			strcpy( p_extName, extName );
		}
		else
			p_extName = NULL;
	}

	~esc_synchronizer()
	{
		delete p_extName;
	}

	void add_external_event( const T& value, sc_time time )
	{
		if ( m_cHandle == qbhEmptyHandle )
			return;

		if ( time == sc_time( 0, SC_NS ) )
			return;

		if ( m_externalValues.size() >= esc_synchronizer::max_edges )
		{
			esc_report_error( esc_error, "For sc_signal '%s' %d external values have been produced but only %d SystemC values.\n\
Please check that your clock is connected correctly\n\
and that you have not started simulation before elaboration",
							  p_name,
							  m_externalValues.size(),
							  m_systemcValues.size() );
			return;
		}

		switch ( (unsigned char)value )
		{
		case '1':
			if ( m_checkEdges == esc_negedge )
				return;
			break;
		case '0':
			if ( m_checkEdges == esc_posedge )
				return;
			break;
		default:
			break;
		}

		m_externalValues.push_back( value );
		m_externalTimes.push_back( time );

		check_sync();
	}

	void add_systemc_event( const T& value, sc_time time )
	{
		if ( m_cHandle == qbhEmptyHandle )
			return;

		if ( time == sc_time( 0, SC_NS ) )
			return;

		if ( m_systemcValues.size() >= esc_synchronizer::max_edges )
		{
			if ( m_externalValues.size() == 0 )
			{
				esc_report_error( esc_fatal, "A cosimulation connection has been made for signal '%s', but no activity has\n\
been detected in Verilog.  There may be an error in the organization of your\n\
SystemC design.  Please be sure you have created your SystemC design in an\n\
esc_elaborate() function, and that you call sc_start() only from sc_main() and\n\
not from esc_elaborate()",p_name );
                return;
			}
			else
				esc_report_error( esc_error, "For sc_signal '%s' %d SystemC values have been produced but only %d external values.\n\
Please check that your clock is connected correctly\n\
and that you have not started simulation before elaboration.",
							  p_name,
							  m_systemcValues.size(),
							  m_externalValues.size() );
			return;
		}

		switch ( (unsigned char)value )
		{
		case '1':
			if ( m_checkEdges == esc_negedge )
				return;
			break;
		case '0':
			if ( m_checkEdges == esc_posedge )
				return;
			break;
		default:
			break;
		}

		m_systemcValues.push_back( value );
		m_systemcTimes.push_back( time );

		check_sync();
	}

	void check_sync()
	{
		if ( ( m_externalValues.size() < m_nEdges )
			 || ( m_systemcValues.size() < m_nEdges ) )
		{
			return;
		}

		for (unsigned int i = 0; i < m_nEdges; ++i)
			if ( ( m_externalValues[i] != m_systemcValues[i] )
				 || ( m_externalTimes[i] != m_systemcTimes[i] ) )
			{
				esc_report_error( esc_error,
								  "External clock %s is not in sync with sc_clock %s.  If you have specified a start_time parameter for your sc_clock, there must be a matching startTime command in your project file",
								  p_extName,
								  p_name );
				break;
			}

		qbhRemoveSignalChangeCallback( m_cHandle );
		m_cHandle = qbhEmptyHandle;
	}

	bool receiving_external_events() { return m_cHandle != qbhEmptyHandle; }

	const char*					p_name;
	char*						p_extName;
	unsigned int				m_nEdges; // the number SystemC edges left to check
	esc_clk_edge				m_checkEdges; // which edges to check
	esc_vector<T>				m_externalValues;
	esc_vector<T>				m_systemcValues;
	esc_vector<sc_time>			m_externalTimes;
	esc_vector<sc_time>			m_systemcTimes;
	qbhCallbackHandle			m_cHandle; // the callback handle
};

#if HUB_USE_DYNAMIC_PRODCESSES
class esc_signal_sc_clock_base
{
  public:
	esc_signal_sc_clock_base()
	{}
	virtual ~esc_signal_sc_clock_base()
	{}
	void spawn();
	virtual void update_synchronizer()=0;
  protected:
	sc_process_handle m_thread;
};
#endif

/*!
  \internal
  \brief Class for sc_clock that either drives or is driven by other domains in the Hub.
*/
class esc_signal_sc_clock : public esc_signal < sc_clock >
#if HUB_USE_DYNAMIC_PRODCESSES
	, public esc_signal_sc_clock_base
#else
	, public sc_module
#endif
{
 public:
	SC_HAS_PROCESS(esc_signal_sc_clock);

	esc_signal_sc_clock( sc_clock& target=*(sc_clock*)0,
						 esc_synchronizer< bool > *synchronizer=NULL, 
						 sc_module_name in_name=sc_module_name(sc_gen_unique_name("esc_signal_sc_clock")) )
		: 
#if !HUB_USE_DYNAMIC_PRODCESSES
		  sc_module( in_name ),
#endif
		  p_synchronizer(synchronizer)
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);

		if ( synchronizer != NULL )
		{
#if !HUB_USE_DYNAMIC_PRODCESSES
			SC_THREAD(update_synchronizer);
#else
			spawn();
#endif
		}
	}

	~esc_signal_sc_clock()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
		{ return qbhBitValType; }

	virtual void		get( const sc_clock* val=NULL, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		if ( m_target_p )
			vr->v_value.v_bit = m_target_p->read() ? '1' : '0';
		else if ( val )
			vr->v_value.v_bit = (*val) ? '1' : '0';
	}

	virtual int			get_bit_width()
		{ return 1; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, sc_clock *in=NULL )
		{
			if ( ( ! m_target_p ) || ( ! p_synchronizer ) || ( !&val && !in ) )
				return;

			// SystemC doesn't support non-solid bits, and val is already in
			// the right encoding for the SystemC domain.
			bool setval = val.v_value.v_bit == '1';

			p_synchronizer->add_external_event( setval, sc_time_stamp() );

			// Can't set the value of an sc_clock
			//*in = m_setval;
		}

	void update_synchronizer()
	{
		while ( 1 )
		{
			wait( m_target_p->value_changed_event() );

			p_synchronizer->add_systemc_event( m_target_p->read(), sc_time_stamp() );

			if ( ! p_synchronizer->receiving_external_events() )
				return;
		}
	}

	bool isClock()
		{ return true; }

	// protected:
  	sc_clock*		 m_target_p;		// SystemC target variable.
	esc_synchronizer< bool > *p_synchronizer;	// object that checks SystemC/external sychronization
};

/*!
  \internal
  \brief Class for sc_signal<sc_bit> that get read from or written to other domains in the Hub.
*/
class esc_signal_sc_bit : public esc_signal< sc_bit >
{
 public:
	esc_signal_sc_bit( sc_signal<sc_bit >& target=*(sc_signal<sc_bit>*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);
	}

	~esc_signal_sc_bit()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
		{ return qbhBitValType; }

	virtual void		get( const sc_bit* val=NULL, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		if ( m_target_p )
			vr->v_value.v_bit = m_target_p->read().to_char();
		else if ( val )
			vr->v_value.v_bit = val->to_char();
	}

	virtual int			get_bit_width()
		{ return 1; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, sc_bit *in=NULL )
		{
			if ( &val && val.tag != type())
				return;

			// SystemC doesn't support non-solid bits.
			char c = val.v_value.v_bit == '1' ? '1' : '0';

			if ( m_target_p )
				m_target_p->write( sc_bit(c) );
			if ( in )
				*in = c;
		}

  protected:
  	sc_signal<sc_bit>* m_target_p;	// SystemC target variable.
};

/*!
  \internal
  \brief Class for sc_signal<char> that get read from or written to other domains in the Hub.
*/
class esc_signal_char : public esc_signal< char >
{
 public:
	esc_signal_char( sc_signal< char >& target=*(sc_signal< char >*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);
	}

	~esc_signal_char()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
		{ return qbhByteValType; }

	virtual void		get( const char* val=NULL, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		if ( m_target_p )
			vr->v_value.v_byte = m_target_p->read();
		else if ( val )
			vr->v_value.v_byte = *val;
	}

	virtual int			get_bit_width()
		{ return 8; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, char*in =NULL )
		{
			switch (val.tag)
			{
			case qbhByteValType:
				if ( m_target_p )
					m_target_p->write( val.v_value.v_byte );
				if ( in )
					*in = val.v_value.v_byte;
				break;
			case qbhIntValType:
				if ( m_target_p )
					m_target_p->write( val.v_value.v_int );
				if ( in )
					*in = val.v_value.v_int;
				break;
			default:
				break;
			}
		}

  protected:
  	sc_signal<char>* m_target_p;	// SystemC target variable.
};

/*!
  \internal
  \brief Class for sc_signal<unsigned char> that get read from or written to other domains in the Hub.
*/
class esc_signal_unsigned_char : public esc_signal< unsigned char >
{
 public:
	esc_signal_unsigned_char( sc_signal< unsigned char >& target=*(sc_signal< unsigned char >*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);
	}

	~esc_signal_unsigned_char()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
		{ return qbhByteValType; }

	virtual void		get( const unsigned char* val=NULL, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		if ( m_target_p )
			vr->v_value.v_byte = m_target_p->read();
		else if ( val )
			vr->v_value.v_byte = *val;
	}

	virtual int			get_bit_width()
		{ return 8; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, unsigned char*in =NULL )
		{
			switch (val.tag)
			{
			case qbhByteValType:
				if ( m_target_p )
					m_target_p->write( val.v_value.v_byte );
				if ( in )
					*in = val.v_value.v_byte;
				break;
			case qbhIntValType:
				if ( m_target_p )
					m_target_p->write( val.v_value.v_int );
				if ( in )
					*in = val.v_value.v_int;
				break;
			default:
				break;
			}
		}

  protected:
  	sc_signal<unsigned char>* m_target_p;	// SystemC target variable.
};

/*!
  \internal
  \brief Class for sc_signal<bool> that get read from or written to other domains in the Hub.
*/
class esc_signal_bool : public esc_signal< bool >
{
 public:
	esc_signal_bool( sc_signal< bool >& target=*(sc_signal< bool >*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);
	}

	~esc_signal_bool()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
		{ return qbhBitValType; }

	virtual void		get( const bool *val=NULL, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		if ( m_target_p )
			vr->v_value.v_bit = m_target_p->read() ? '1' : '0';
		else if ( val )
			vr->v_value.v_bit = (*val ? '1' : '0');
	}

	virtual int			get_bit_width()
		{ return 1; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, bool *in=NULL )
		{
			if (val.tag != type())
				return;

			if ( m_target_p )
				m_target_p->write( val.v_value.v_bit == '1' ? true : false );
			if ( in )
				*in = ( val.v_value.v_bit == '1' ? true : false );
		}

  protected:
  	sc_signal<bool>* m_target_p;	// SystemC target variable.
};

/*!
  \internal
  \brief Class for sc_signal<double> that get read from or written to other domains in the Hub.
*/

class esc_signal_double : public esc_signal< double >
{
 public:
	esc_signal_double( sc_signal< double >& target=*(sc_signal< double >*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);
	}

	~esc_signal_double()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
		{ return qbhRealValType; }

	virtual void		get( const double* val, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		if ( m_target_p )
			vr->v_value.v_real = m_target_p->read();
		else if ( val )
			vr->v_value.v_real = *val;
	}

	virtual int			get_bit_width()
		{ return 64; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, double *in )
		{
			if (val.tag != type())
				return;

			if ( m_target_p )
				m_target_p->write( val.v_value.v_real );
			if ( in )
				*in = val.v_value.v_real;
		}

  protected:
  	sc_signal<double>* m_target_p;	// SystemC target variable.
};

/*!
  \internal
  \brief Class for sc_signal<sc_time> that get read from or written to other domains in the Hub.
*/
inline void sc_trace( sc_trace_file* tf,
					  const sc_time& object,
					  const cynw_string& name )
{
	/* Intentionally blank. Tracing for sc_time is not supported. */
	/* We need an implementation to compile sc_signal<sc_time>. */
}

class esc_signal_sc_time : public esc_signal< sc_time >
{
 public:
	esc_signal_sc_time( sc_signal< sc_time >& target=*(sc_signal< sc_time >*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);
	}

	~esc_signal_sc_time()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
		{ return qbhTimeValType; }

	virtual void		get( const sc_time* val, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		if ( m_target_p )
			vr->v_value.v_time = m_target_p->read().to_seconds() * 1.0e12;
		else if ( val )
			vr->v_value.v_time = val->to_seconds() * 1.0e12;
	}

	virtual int			get_bit_width()
		{ return 64; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, sc_time* in=NULL )
		{
			switch (val.tag)
			{
			case qbhTimeValType:
				{
					sc_time toWrite( val.v_value.v_time, SC_PS);
					if ( m_target_p )
						m_target_p->write( toWrite );
					else if ( in )
						*in = toWrite;
				}
				break;
			case qbhRealValType:
				{
					sc_time toWrite( val.v_value.v_real, SC_PS);
					if ( m_target_p )
						m_target_p->write( toWrite );
					else if ( in )
						*in = toWrite;
				}
				break;
			default:
				break;
			}
		}

  protected:
  	sc_signal<sc_time>* m_target_p;	// SystemC target variable.
};

/*!
  \internal
  \brief Class for sc_signal<cynw_string> that get read from or written to other domains in the Hub.
*/
inline void sc_trace( sc_trace_file* tf,
					  const cynw_string& object,
					  const cynw_string& name )
{
	/* Intentionally blank. Tracing for cynw_string is not supported. */
	/* We need an implementation to compile sc_signal<cynw_string>. */
}

class esc_signal_cynw_string : public esc_signal< cynw_string >
{
 public:
	esc_signal_cynw_string( sc_signal< cynw_string >& target = *(sc_signal< cynw_string >*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);
	}

	~esc_signal_cynw_string()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
		{ return qbhStringValType; }

	virtual void		get( const cynw_string*val=NULL, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		if ( vr->v_value.v_string != NULL )
			free(vr->v_value.v_string);
		if ( m_target_p )
			vr->v_value.v_string = strdup( m_target_p->read().c_str() );
		else if ( val )
			vr->v_value.v_string = strdup( val->c_str() );
	}

	virtual int			get_bit_width()
		{ return 8*64; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, cynw_string*in=NULL )
		{
			switch (val.tag)
			{
			case qbhStringValType:
				{	
					const char *s = val.v_value.v_string == NULL ? "" :
						val.v_value.v_string;
					cynw_string toWrite( s );
					if ( m_target_p )
						m_target_p->write( toWrite );
					if ( in )
						*in = toWrite;
				}
				break;
			case qbhABValType:
				{
					unsigned nBits = val.v_value.v_abval.length;
					unsigned nChars = ( (nBits - 1) >> 3) + 1;
					if (nChars > 4)
						nChars = 4;
					unsigned aval = val.v_value.v_abval.bits.aval;

					unsigned char c[5];
					for (unsigned int i = 0; i < nChars;)
					{
						char b = ( aval & 0x7f000000 ) >> 24;
						// This string might be null-terminated before where
						// HDL thinks the end of string is. Deal with it.
						aval <<= 8;
						if ( b == 0)
						{
							--nChars;
							continue;
						}
						c[i++] = b;
					}
					c[nChars] = 0;

					cynw_string toWrite( (char *)c );
					if ( m_target_p )
						m_target_p->write( toWrite );
					if ( in )
						*in = toWrite;
				}
				break;
			case qbhLongABValType:
				{
					if (val.v_value.v_long_abval.bits == NULL)
						return;

					unsigned nBits = val.v_value.v_abval.length;
					unsigned nChars = ( (nBits - 1) >> 3) + 1;
					int nWords = nBits ? ( ( nBits - 1 ) >> 5) + 1 : 0;

					char *buf = new char[nChars + 1];
					char *s = buf;

					unsigned nToConvert = nChars;
					for (int j = nWords - 1; j >= 0; --j)
					{
						int aval = val.v_value.v_long_abval.bits[j].aval;

						unsigned nCharsThisWord = nToConvert > 3 ? 4 : nToConvert;
						for (unsigned int i = 0; i < nCharsThisWord;)
						{
							char b = ( aval & 0x7f000000 ) >> 24;
							// This string might be null-terminated before where
							// HDL thinks the end of string is. Deal with it.
							aval <<= 8;
							if ( b == 0)
							{
								--nCharsThisWord;
								continue;
							}
							*s++ = b;
						}

						nToConvert -= 4;
					}
					*s = '\0';

					cynw_string toWrite( buf );
					if ( m_target_p )
						m_target_p->write( toWrite );
					if ( in )
						*in = toWrite;

					delete buf;
				}
				break;
			case qbhBitvecValType:
				{	
					if (val.v_value.v_bitvec.bits == NULL)
						return;

					int len = val.v_value.v_bitvec.length;
					char *buf = new char[len+1];

					// Do not assume null termination.
					char *c = val.v_value.v_bitvec.bits;
					for (int i = 0; i < len; ++i, ++c)
						buf[i] = *c;
					buf[len] = '\0';

					cynw_string toWrite( buf );
					if ( m_target_p )
						m_target_p->write( toWrite );
					if ( in )
						*in = toWrite;

					delete buf;
				}
				break;
			default:
				return;
			}
		}

  protected:
  	sc_signal<cynw_string>* m_target_p;	// SystemC target variable.
};

/*!
  \internal
  \brief Class for sc_signal<int> that get read from or written to other domains in the Hub.
*/
class esc_signal_int : public esc_signal< int >
{
 public:
	esc_signal_int( sc_signal< int >& target=*(sc_signal< int >*)0 )
	{
		m_target_p = &target;
		qbhAllocValRec(type(), 1, &this->p_valrec);
	}

	~esc_signal_int()
	{
		qbhUnlockValRec(this->p_valrec, 1);
	}

	virtual const char* name()
		{ return m_target_p->name(); }

	virtual qbhValueRecordType type()
		{ return qbhIntValType; }

	virtual void		get( const int *val=NULL, qbhValueRecord* vr=0 )
	{
		if (!vr) 
			vr = this->p_valrec;
		if ( m_target_p )
			vr->v_value.v_int = m_target_p->read();
		else if ( val )
			vr->v_value.v_int = *val;
	}

	virtual int			get_bit_width()
		{ return 32; }

	virtual const sc_event&	get_event()
		{ return ( m_target_p ? m_target_p->value_changed_event() : *(sc_event*)NULL ); }

	virtual void		set( qbhValueRecord &val, int*in=NULL )
		{
			if (val.tag != type())
				return;

			if ( m_target_p )
				m_target_p->write( val.v_value.v_int );
			if ( in )
				*in = val.v_value.v_int;
		}

  protected:
  	sc_signal<int>* m_target_p;	// SystemC target variable.
};

#if HUB_USE_DYNAMIC_PRODCESSES
class esc_signal_sc_master_base
{
  public:
	esc_signal_sc_master_base()
	{}
	virtual ~esc_signal_sc_master_base()
	{}
	
	void spawn( const sc_event* e );

	virtual void changed()=0;
  protected:
	sc_process_handle m_method;
};
#endif

/*!
  \internal
  \brief Class is for a module that helps drive signals in another domain across the Hub.

  The code for driving a signal in another domain from an sc_signal in SystemC should
  look something like the following:

  \code sc_signal<sc_bit> *sig = new sc_signal<sc_bit>();
Not shown: Connect the signal to a module
esc_signal_sc_bit *esc_sig = new esc_signal_sc_bit( *sig );
esc_signal_sc_master *esc_master
	= new esc_signal_sc_master( "sig_driver", esc_sig, "verilog", "testbench/sig_driven_from_sc" );
  \endcode

  Note - users should only ever need to use esc_link_signals()
*/
template < class T >
class esc_signal_sc_master 
#if HUB_USE_DYNAMIC_PRODCESSES
  : public esc_signal_sc_master_base
#else
  : public sc_module
#endif
{
 public:
	SC_HAS_PROCESS(esc_signal_sc_master);

	/*!
	  \brief Constructor
	  \param name The name of the module
	  \param sig Pointer to the esc_signal
	  \param otherDomain (optional) The name of the domain to be driven
	  \param otherSigPath The path to the signal in otherDomain to be driven.  Must be domain-prefixed if otherDomain is unspecified
	*/
	esc_signal_sc_master( sc_module_name mod_name, esc_signal< T > *sig, 
						  char *otherDomain, char *otherSigPath, int causesExec=0,
						  int causesValChange=1, esc_clk_edge clkedges=esc_alledge, double input_delay=0.0 )
	:
#if !HUB_USE_DYNAMIC_PRODCESSES
	  sc_module(), // no need for end_module() with this constructor
#endif
	  p_sig(sig),
	  m_nHandle(qbhEmptyHandle),
	  m_causesExec(causesExec),
	  m_causesValChange(causesValChange),
	  m_clkedges(clkedges),
	  m_input_delay(input_delay)
#if HUB_USE_DYNAMIC_PRODCESSES
	  ,p_name(strdup(mod_name))
#endif
	{
		if ( causesValChange 
			 && 
			 qbhNetlistFind( otherSigPath, otherDomain, qbhEmptyHandle, 
							 &m_nHandle, qbhNetlistSignal ) != qbhOK )
		{
			esc_report_error( esc_error, "esc_signal_sc_master: qbhNetlistFind failed: %s\n",
							  otherSigPath);
		}
		else
		{
#if !HUB_USE_DYNAMIC_PRODCESSES
			SC_METHOD(changed);
			sensitive << p_sig->get_event();
#else
			spawn( &(p_sig->get_event()) );
#endif

		}
	}

	/*!
	  \internal
	  \brief This function is called from the delayed callback.  Only used with sc_clocks, it just calls changed().

	  Merely a placeholder.  During cosimulation, a callback is made using this function to make sure
	  the simulator suspends execution and allows SystemC to run.
	*/
	static qbhError static_changed( void *userData )
	{
		return qbhOK;
	}

	/*!
	  \internal
	  \brief This function is executed when the sc_signal changes, and drives the signal in the other domain
	*/
	void changed()
	{
		p_sig->get();

		// send it to the Hub 
        if ( p_sig->valrec() && m_nHandle != qbhEmptyHandle
             && qbhSetSignalValue( m_nHandle, esc_hub::domain(), p_sig->valrec(), m_input_delay ) != qbhOK )
			esc_report_error( esc_error, "ERROR: esc_signal_sc_master qbhSetSignalValue failed\n");
		else if ( m_causesExec == 1 )
		{
			// When SystemC is driving a clock in Verilog, it will need to request a delayed callback
			// because otherwise Verilog won't know to stop and give SystemC/Hub a chance to run

			double delta = 0;
			sc_clock *clk = ((esc_signal_sc_clock*)p_sig)->m_target_p;

			// We're always sensitive to all value changes on the channel, so always check the edge
			switch ( m_clkedges )
			{
			case esc_posedge:
				if ( clk->read() )	// posedge
				{
					delta = esc_normalize_to_ps(clk->period());
				}
				break;
			case esc_negedge:
				if ( ! clk->read() )// negedge
				{
					delta = esc_normalize_to_ps(clk->period());
				}
				break;
			case esc_alledge:
				if ( clk->read() )	// posedge
				{
					delta = clk->duty_cycle() * esc_normalize_to_ps(clk->period());
				}
				else				// negedge
				{
					delta = (1 - clk->duty_cycle()) * esc_normalize_to_ps(clk->period());
				}
				break;
			}

			// if there is an initial edge at time 0, it will try to make two callback reqs
			if ( delta > 0 )
			{
				// assumes delta is in ps
				if ( qbhRequestDelayedCallback( delta, esc_signal_sc_master::static_changed, this ) != qbhOK )
					esc_report_error( esc_error, "ERROR: Couldn't call qbhRequestDelayedCallback in %s\n",name());
			}
		}
	}

	esc_signal< T > *	p_sig;
	qbhNetlistHandle	m_nHandle; // the netlist handle
	int					m_causesExec; // is == 1 if a change causes SystemC to execute
	int					m_causesValChange; // is == 1 if a change in SystemC sets a signal in the Hub
	esc_clk_edge		m_clkedges; // only relevant for sc_clocks, determines what edges it should be sensitive to
	double				m_input_delay; // The delay when signals are set.
#if HUB_USE_DYNAMIC_PRODCESSES
	char*				p_name;
	const char*			name() { return p_name; }
#endif
};

/* Non-templated base class for esc_signal_hub_master
 */
class esc_signal_hub_master_base
{
  public:
	esc_signal_hub_master_base()
	{
		m_hub_masters.push_back( this );
	}
	virtual ~esc_signal_hub_master_base() {}
	static esc_vector<esc_signal_hub_master_base*> m_hub_masters;
	static void initialize_hub_masters()
	{
		for ( unsigned int i=0; i < m_hub_masters.size(); i++ ) 
		{
				m_hub_masters[i]->initialize();
		}
	}
	virtual void initialize()=0;
};

/*!
  \internal
  \brief Class is for a module that helps drive sc_signals in this domain from another domain across the Hub.

  The code for driving an sc_signal in SystemC from a signal in another domain should
  look something like the following:

  \code sc_signal<sc_bit> *sig = new sc_signal<sc_bit>();
Not shown: Connect the signal to a module
esc_signal_sc_bit *esc_sig = new esc_signal_sc_bit( *sig );
esc_signal_hub_master *esc_master
	= new esc_signal_hub_master( "sig_driver", esc_sig, "verilog", "testbench/sig_to_sc" );
*/
template < class T >
class esc_signal_hub_master : 
#if !HUB_USE_DYNAMIC_PRODCESSES
	public sc_module, 
#endif
	public esc_signal_hub_master_base
{
 public:
	SC_HAS_PROCESS(esc_signal_hub_master);

	/*!
	  \brief Constructor
	  \param name The name of the module
	  \param sig Pointer to the esc_signal
	  \param otherDomain (optional) The name of the domain that drives the sc_signal
	  \param otherSigPath The path to the signal in otherDomain that drives.  Must be domain-prefixed if otherDomain is unspecified
	 */
	esc_signal_hub_master( sc_module_name name, 
						   esc_signal< T > *sig, 
						   char *otherDomain, 
						   char *otherSigPath )
	: 
#if !HUB_USE_DYNAMIC_PRODCESSES
	  sc_module(), // no need for end_module() with this constructor
#endif
	  p_sig(sig),
	  m_nHandle(qbhEmptyHandle),
	  m_cHandle(qbhEmptyHandle)
	{
		// Get the qbhNetlistHandle for otherSigPath
		if ( qbhNetlistFind( otherSigPath, otherDomain, qbhEmptyHandle, &m_nHandle, qbhNetlistSignal ) != qbhOK )
			esc_report_error( esc_error,
							  "esc_signal_hub_master: qbhNetlistFind failed: %s:%s\n",
							  otherDomain,otherSigPath);
		// Register the signal change callback
		else if ( qbhRegisterSignalChangeCallback( m_nHandle,
												   esc_hub::domain(),
												   esc_signal_hub_master::changed,
												   this, sig->isClock(), &m_cHandle ) != qbhOK )
			esc_report_error( esc_error,
							  "esc_signal_hub_master: qbhRegisterSignalChangeCallback failed: %s:%s\n",
							  otherDomain,otherSigPath);
#if 0 // Causes multiple driver problems.
		else
		{
			SC_THREAD( init_signal_thread );
		}
#endif
	}

	/*!
	  \internal
	  \brief Function for initializing signals. It should never need to be explicitly called. We need this because stratus_hls optimizes some signal as assigns, which means we won't be notified of changes.
	 */
	void init_signal_thread()
	{
		esc_signal_hub_master::changed( m_nHandle, this, NULL );
	}

	void initialize()
	{
		esc_signal_hub_master::changed( m_nHandle, this, NULL );
	}
	
	/*!
	  \internal
	  \brief Callback used when registering a signalChangeCallback with the Hub
	  \param userData is the esc_signal_hub_master associated with the signal
	  \param value is an optionally null value to which the signal has changed.

	  This function will get called by the hub each time a signal value changes.
	  If value is not NULL, it will get the new value from the Hub, and set its
	  signal value.
	*/
	static qbhError changed( qbhNetlistHandle hNet,
							 void* userData,
							 qbhValueRecord *value )
	{
		esc_signal_hub_master *sig = (esc_signal_hub_master*)userData;
		qbhError status = qbhOK;

		if (value == NULL)
		{
			qbhValueRecord *val = NULL;
			status = qbhGetSignalValue( hNet, esc_hub::domain(), &val );

			if ( status == qbhOK )
				sig->p_sig->set(*val);

			qbhUnrefValRec( val );
		}
		else
			sig->p_sig->set(*value);
	
		return status;
	}

	esc_signal<T> *		p_sig;
	qbhNetlistHandle	m_nHandle; // the netlist handle
	qbhCallbackHandle	m_cHandle; // the callback handle
};

/*!
  \brief Links an sc_signal or sc_clock with a signal in another Hub domain.
  \param direction The direction to link a SystemC signal with a signal in another domain
  \param int_path The name of the sc_signal or sc_clock
  \param ext_path The domain-prefixed name of the signal in another Hub domain
  \param ext_domain (optional) The name of the external domain, if not specified in ext_path
  \return Non-zero on success.
*/
int esc_link_signals( esc_link_direction_t direction, const char* int_path, 
					  const char* ext_path, const char* ext_domain=NULL, double input_delay=0.0 );

/*!
  \brief Links the specified sc_clock with a signal in another Hub domain.
  \param direction The direction to link a SystemC signal with a signal in another domain
  \param clk The sc_clock to be linked
  \param ext_path The domain-prefixed name of the signal in another Hub domain
  \param ext_domain (optional) The name of the external domain, if not specified in ext_path
  \return Non-zero on success
*/
int esc_link_signals( esc_link_direction_t direction, sc_clock* clk, 
					  const char* ext_path, const char* ext_domain=NULL, double input_delay=0.0 );

/*!
  \brief Links the specified int_object with a signal in another Hub domain.
  \param direction The direction to link a SystemC signal with a signal in another domain
  \param int_object A pointer to the interal signal to be registered
  \param sig A pointer to the esc_signal created for int_object
  \param ext_path The domain-prefixed name of the signal in another Hub domain
  \param ext_domain (optional) The name of the external domain, if not specified in ext_path
  \return Non-zero on success.
*/
template < class T >
int esc_link_signals( esc_link_direction_t direction, sc_object* int_object, 
					  esc_signal< T >* int_sig, const char* ext_path, const char* ext_domain=NULL, double input_delay=0.0 )
{
	if ( !int_object || !int_sig || !ext_path || !*ext_path )
		return 0;

	int retval = 1;

	if ( direction == esc_link_out )
	{
		esc_signal_sc_master< T > *esc_master 
			= new esc_signal_sc_master< T >( sc_gen_unique_name("esc_object"), int_sig, 
											 (char*)ext_domain, (char*)ext_path, 0, 1, esc_alledge, input_delay );
		retval = (esc_master != NULL);
	}
	else
	{
		esc_signal_hub_master< T > *esc_master 
			= new esc_signal_hub_master< T >( sc_gen_unique_name("esc_object"), int_sig, 
											  (char*)ext_domain, (char*)ext_path );
		retval = (esc_master != NULL);
	}

	return retval;
}

/*!
  \brief Reads from file to connect internal and external signals.

  \param filename The name of the file that contains the list of signals

  This function reads a file that should contain three entries per line.
  These three strings are esc_link_direction_t value (as a string), internal_path and external_path,
  and the other esc_link_signals is called on them.

  The three strings should be separated by a space, and "" are allowed.

  Ex:
  \code
  esc_link_in path/in/systemc/clk path/in/simulator/clk
  ...
  \endcode

*/
extern int esc_link_signals( const char *filename );

/*!
  \brief Links the specified int_signal with a signal in another Hub domain.
  \param direction The direction to link a SystemC signal with a signal in another domain
  \param int_signal A pointer to the interal signal to be registered
  \param ext_path The domain-prefixed name of the signal in another Hub domain
  \param ext_domain (optional) The name of the external domain, if not specified in ext_path
  \param input_delay The delay to insert on the signal each time its set.
  \return Non-zero on success.
*/
template <class T>
int esc_link_signals( esc_link_direction_t direction, sc_signal<T>* int_signal,
					  const char* ext_path, const char* ext_domain=NULL, double input_delay=0.0 )
{
	return esc_link_signals( direction, int_signal, 
							 alloc_esc_sig(int_signal), 
							 ext_path, ext_domain, input_delay );
}

/*!
  \internal
  \brief Concatenate an external domain, module path, and signal name into one new string.
  \param ext_domain The name of the external domain
  \param module_path The path to the module containing the signal in the external domain
  \param signal_name The SystemC signal name -- we only use the leaf of this
  \return Allocates a string
*/
char *esc_make_path( const char *ext_domain,
					 const char *module_path,
					 const char *signal_name );

/*!
  \brief Links the specified in_port with a signal in another Hub domain.
  \param in_port A pointer to the input port to be registered
  \param module_path The path to the module containing the signal in the external domain
  \param ext_domain The name of the external domain
  \param use_port_name If true, uses the name of the port given, otherwise, uses the name of the attached signal.
  \param input_delay The delay to insert on the signal each time its set.
  \return Non-zero on success.
*/
template <class T>
int esc_link_signals( sc_in<T>* in_port,
					  const char* module_path, const char* ext_domain,
					  bool use_port_name=false, double inputDelay=0.0 )
{
	// Find the attached signal and use its name as the name of the signal to find
	// in the HDL module.
	sc_signal_in_if<T> *inif = (*in_port)[0];
	if (inif == NULL)
	{
		esc_report_error( esc_error, "ERROR: esc_link_signals(%s, %s, %s) failed: sc_in port not bound\n",
						 in_port->name(), module_path, ext_domain);
		return 0;
	}

	sc_signal<T> *insig = dynamic_cast<sc_signal<T>*>(inif);
	if (insig == NULL)
	{
		sc_clock *inclk = dynamic_cast<sc_clock*>(inif);
		if (inclk == NULL)
		{
			esc_report_error( esc_error, "ERROR: esc_link_signals(%s, %s, %s) failed: sc_in port is not linked to sc_signal or sc_clock\n",
							 in_port->name(), module_path, ext_domain);
			return 0;
		}

		char *ext_path = esc_make_path( ext_domain, module_path, 
										(use_port_name ? in_port->basename() : inclk->basename() ) );
		int success = esc_link_signals( esc_link_in, inclk, ext_path );
		delete ext_path;

		return success;
	}

	char *ext_path = esc_make_path( ext_domain, module_path, 
									(use_port_name ? in_port->basename() : insig->basename() ) );
	int success = esc_link_signals( esc_link_out, insig, 
									alloc_esc_sig( insig ), 
									ext_path, NULL, inputDelay );
	delete ext_path;

	return success;
}

/*!
  \brief Links the specified out_port with a signal in another Hub domain.
  \param out_port A pointer to the input port to be registered
  \param module_path The path to the module containing the signal in the external domain
  \param ext_domain The name of the external domain
  \param use_port_name If true, uses the name of the port given, otherwise, uses the name of the attached signal.
  \return Non-zero on success.
*/
template <class T>
int esc_link_signals( sc_out<T>* out_port,
					  const char* module_path, const char* ext_domain,
					  bool use_port_name=false )
{
	sc_signal_out_if<T> *outif = (*out_port)[0];
	if (outif == NULL)
	{
		esc_report_error(esc_error, "ERROR: esc_link_signals(%s, %s, %s) failed: sc_out port not bound\n",
						 out_port->name(), module_path, ext_domain);
		return 0;
	}

	sc_signal<T> *outsig = dynamic_cast<sc_signal<T>*>(outif);
	if (outsig == NULL)
	{
		esc_report_error(esc_error, "ERROR: esc_link_signals(%s, %s, %s) failed: sc_out port is not linked to sc_signal\n",
						 out_port->name(), module_path, ext_domain );
		return 0;
	}
	char *ext_path = esc_make_path( ext_domain, module_path, 
									(use_port_name ? out_port->basename() : outsig->basename() ) );
	int success = esc_link_signals( esc_link_in, outsig, 
									alloc_esc_sig( outsig ), 
									ext_path );
	delete ext_path;

	return success;
}

/*!
 \brief Fills in parameters for a generated HDL clock.
 \param clock sc_clock from which to extract the parameter values.
 \param start_time The start time for the clock.
 \param module_path The path to the module containing the signal in the external domain
 \param ext_domain The name of the external domain
 \param clk_name The name of the clock signal.  
 \return Non-zero on success.
*/

int esc_link_clockgen( sc_clock *clock, const sc_time& start_time,
					   const char* module_path, const char* ext_domain, 
					   const char* clk_name="CLK" );

/*!
 \brief Fills in parameters for a generated HDL clock.
 \param clock sc_in<bool> port from which to extract the parameter values.
 \param start_time The start time for the clock.
 \param module_path The path to the module containing the signal in the external domain
 \param ext_domain The name of the external domain
 \param clk_name The name of the clock signal.  
 \return Non-zero on success.
*/

inline int esc_link_clockgen( sc_in< bool >* clock, const sc_time& start_time,
							   const char* module_path, const char* ext_domain, 
							   const char* clk_name="CLK" )
{
	sc_signal_in_if< bool > *clock_inif = (*clock)[0];
	sc_clock *clock_module = dynamic_cast<sc_clock*>(clock_inif);
	if ( clock_module == NULL )
		return 0;
#if ( SYSTEMC_VERSION >= 20050714 )
	if ( (start_time > sc_time(0,SC_NS)) && (start_time != clock_module->start_time()) )
	{
		esc_report_error( esc_error,
						  "Clock start time %lg ns from project file conflicts with start time %lg ns from sc_clock %s.\nUsing value from clock.\n",
						  start_time.to_seconds() * 1.0e9,
						  clock_module->start_time().to_seconds() * 1.0e9, clock_module->name() );

	}
	return esc_link_clockgen( clock_module, clock_module->start_time(),
							  module_path, ext_domain, clk_name );
#else
	return esc_link_clockgen( clock_module, start_time, module_path, ext_domain, clk_name );
#endif
}


/*!	\class	esc_linked_signal
	\brief	An sc_signal<T> that can be easily linked to an HDL signal for Hub cosim.

	An esc_linked_signal is a subclass of sc_signal that supports linking to HDL
	signals for hub-based cosimulation using member functions.  All methods that can
	be used on an sc_signal<T> can be used on an esc_linked_signal<T>.

	All of the functions supported by the esc_linked_signal class can be achieved using
	an ordinary sc_signal and one of the esc_link_signals function overloads.  This class
	is a convenience class that allows linking information to be specified when the
	signal is instantiated.

	In the following example, two SystemC signals, X and Y are linked to their equivalents
	in Verilog, "testbench/X" and "testbench/Y".  Signal X is an input into SystemC from
	Verilog, and signal Y is an output from SystemC to Verilog.  All of the linking information
	is supplied when the signals are instantiated.

	\code
	SC_MODULE(Top) {
		esc_linked_signal< bool >			X;	// Single bit linked signal.
		esc_linked_signal< sc_uint<16> >	Y;	// 16-bit linked signal.

		SC_CTOR(Top) :
			X( "X", esc_link_in, "testbench/X" ),	// Link from HDL.
			Y( "Y", esc_link_out, "testbench/Y" )	// Link to HDL.
		{
			SC_METHOD(main);
			sensitive << X;		// Execute when X changes.
		}

		// Called whenever X changes in Verilog.
		void main()
		{
			// Write a new value to Y in HDL.
			Y = Y.read() + 1;
		}
	};
	\endcode

 */
template <class T>
class esc_linked_signal
	: public sc_signal<T>
{
  public:
	/*	\brief	Constructor specifying all linking information.
	 *
	 *			When this form of constructor is used, linking is performed immediately.
	 *			If there are linking errors, an error message will be generated, and
	 *			the status() method will return the value that was returned from
	 *			the link() method.
	 *
	 *	\param	name	The name that will be given to the underlying sc_signal<T>.
	 *	\param	dir		The direction for linking.  See the link() method for details.
	 *	\param	ext_path	The path to the sibling signal in the HDL simulator.
	 *	\param	ext_domain	An optional domain name in which the external signal may be found.
	 */
	esc_linked_signal( const char* name, esc_link_direction_t dir, const char* ext_path, const char* ext_domain=NULL ) :
		sc_signal<T>( name ),
		m_dir(esc_link_none),
		m_ext_path( strdup( ext_path ) ),
		m_ext_domain( ext_domain ? strdup(m_ext_domain) : 0 ),
		m_status(-1)
	{
		m_status = link( dir );
	}
	
	/* \brief	Constructor specifying all linking information except direction.
	 *
	 *			When this form of constructor is used, linking is not performed until
	 *			link(), link_in(), or link_out() is called.
	 *
	 *	\param	name	The name that will be given to the underlying sc_signal<T>.
	 *	\param	ext_path	The path to the sibling signal in the HDL simulator.
	 *	\param	ext_domain	An optional domain name in which the external signal may be found.
	 */
	esc_linked_signal( const char* name, const char* ext_path, const char* ext_domain=NULL ) :
		sc_signal<T>( name ),
		m_dir(esc_link_none),
		m_ext_path( strdup( ext_path ) ),
		m_ext_domain( ext_domain ? strdup(m_ext_domain) : 0 ),
		m_status(-1)
	{
	}
	
	//! Destructor.
	~esc_linked_signal()
	{
		free( m_ext_path );
		if ( m_ext_domain )
			free( m_ext_domain );
	}

	/*!	\brief	Links the esc_linked_signal to a signal in HDL with the given direction.
	 *	\param	dir	The direction of the link.  Allowable values are:
	 *
	 *			\li	esc_link_in	Changes made to the sibling signal in the HDL simulator
	 *								will be propagated to the esc_linked_signal.
	 *
	 *			\li	esc_link_out	Changes on the the esc_linked_signal made from
	 *									SystemC will be propagated to the sibling signal
	 *									in the HDL simulator.
	 *
	 *
	 *	This function should be called only when the direction was not specified 
	 *	when the esc_linked_signal was instantiated.
	 *
	 *	\return 1 for success, 0 for failure.  An error message will be emitted on failure.
	 */
	int link( esc_link_direction_t dir )
	{
		m_dir = dir;
		if ( esc_link_signals( m_dir, (sc_signal<T>*)this, m_ext_path, m_ext_domain ) )
			m_status = 1;
		else
			m_status = 0;
		return status();
	}

	//! \brief Convenience function for linking with a direciton of esc_link_in.
	int link_in() { return link( esc_link_in ); }

	//! \brief Convenience function for linking with a direciton of esc_link_out.
	int link_out() { return link( esc_link_out ); }

	//! \brief Gives the direction specified, or esc_link_none if none has been given.
	esc_link_direction_t direction() { return m_dir; }

	//! \brief Gives the external path specified in the constructor.
	const char *ext_path() { return m_ext_path; }

	//! \brief Gives the external path specified in the constructor.
	const char *ext_domain() { return m_ext_domain; }

	/*! \brief Gives the current linking status.  Values are:
		\li	-1 : No link has yet been attempted.
		\li	 0 : Linking has been attempted and has failed.
		\li	 1 : Linking has been performed successfully.

	 */
	 int status() { return m_status; }
  protected:
	esc_link_direction_t m_dir;
	char *m_ext_path;
	char *m_ext_domain;
	int m_status;
};

/*!
  \brief Used when SystemC is slaved to the Hub to let SystemC execute.
  \param clk The sc_clock that is used to determine the time of the callbacks
  \param clkedge The edges that the function should be sensitive to
  \param first_edge_time_ps The time of the first edge in ps
  \param module_path The path to the module containing the signal in the external domain
  \param ext_domain The name of the external domain
  \param ext_clock_name The leaf name of the clock signal
  \return Non-zero on success

  Use of this function will set callbacks so that the Hub periodically allows SystemC to execute.
*/
int esc_hub_register_clock( sc_clock* clk, 
							esc_clk_edge clkedge=esc_alledge, 
							double first_edge_time_ps=0,
							const char *module_path=NULL,
							const char *ext_domain=NULL,
							const char *ext_clock_name=NULL );

/*!
 \brief	Ends a co-simulation started with qbStartCosim from Verilog or VHDL.
  \return Non-zero on success
 Co-simulations between SystemC and Verilog or VHDL using the Hub can be started
 using the qbStartCosim verilog task or VHDL procedure.  qbStartCosim will not
 return to it's calling thread until esc_end_cosim() is called from C++.  After 
 qbStartCosim  has returned, the simulator can be stopped from Verilog or VHDL
 code.  

 esc_end_cosim() does not stop stimulation directly. Rather, after
 qbStartCosim  has returned, the simulator can be stopped from Verilog or VHDL
 code. 
 */
int esc_end_cosim();

/*!
  \brief Returns the clock period for a given module in the current simulation configuration.
  \return The clock period for a given module for the current simulation configuration.
  \param module The name of the module to look up; if NULL, will use the first module it can find in the current project.
  \param default_period Returned as the clock period if no non-behavioral configurations of the module can be found.
 */
double esc_config_clock_period( const char *module, double default_period );

/*!
  \brief Returns the clock period for the current simulation configuration.
  \return The clock period for the current simulation configuration.
  \param default_period Returned as the clock period if no non-behavioral module configurations can be found.
 */
double esc_config_clock_period( double default_period );

/*
  \brief Sets the current global SystemC trace file for wrappers to log to.
*/
void esc_set_trace_file( sc_trace_file *trace_file, esc_trace_t traceType=esc_trace_vcd );

/*!
  \brief Open a global VCD trace file for this simulation. Will replace any currently open global VCD trace file.
  \param file_name the root name of the VCD to create.
 */
void esc_open_vcd_trace( const char *file_name = "systemc" );


/*!
  \brief Close a global VCD trace file for this simulation. If it's been closed already, this is a no-op.
 */
void esc_close_vcd_trace();

/*!
  \internal
  \brief Returns a pointer to the VCD trace file that we've opened, if any.
 */
sc_trace_file *esc_vcd_trace_file();

/*!
  \internal
  \brief Returns a pointer to the VCD trace file that we've opened. If none has been opened, it will open one with a default name.
 */
sc_trace_file *esc_get_vcd_trace_file();

/*!
  \internal
  \brief We maintain a pointer in libesc.a to the function that opens an FSDB file
  instead of actually defining it in libesc.a because we need to be able to build
  libesc.a without FSDB headers. Each wrapper instance sets this pointer to its
  FSDB-opening function at static constructor time. It doesn't matter what order
  these constructors are called in because the definitions of the FSDB-opening functions
  in the wrappers are identical.
 */

typedef void (*pvf_filename)(const char *file_name);

/*!
  \internal
  \brief Saves a pointer to the wrapper-provided function for opening FSDB files.
  \param fsdb_opener is a pointer to the function that opens FSDB files.
 */
void esc_set_open_fsdb_trace( pvf_filename fsdb_opener );

/*!
  \internal
  \brief Saves a pointer to the wrapper-provided function for opening FSDB SCV files.
  \param fsdb_scv_opener is a pointer to the function that opens FSDB SCV files.
 */
void esc_set_open_fsdb_scv_trace( pvf_filename fsdb_scv_opener );

/*!
  \internal
  \brief Returns a pointer to the FSDB trace file that we've opened, if any.
 */
sc_trace_file *esc_fsdb_trace_file();

/*!
  \internal
  \brief Returns a pointer to the FSDB trace file that we've opened. If none has been opened, it will open one with a default name.
 */
sc_trace_file *esc_get_fsdb_trace_file();

/*!
  \brief Returns the type of tracing currently enabled

  Returns one of:
	esc_trace_vcd		If VCD tracing is on.
	esc_trace_fsdb		If FSDB tracing is on.
	esc_trace_off 		If neither kind of tracing is on.
 */
esc_trace_t esc_trace_type();

/*!
  \brief Returns a pointer to the trace file that we've opened, if any.
  \param traceType the format of the trace file we've opened
 */
sc_trace_file *esc_trace_file( esc_trace_t traceType=esc_trace_type() );

/*!
  \brief Returns a pointer to the trace file that we've opened, if any. If none has been opened, it will open one with a default name.
  \param traceType the format of the trace file we've opened
 */
sc_trace_file *esc_get_trace_file( esc_trace_t traceType=esc_trace_type() );


#ifndef BDW_NO_CYNTH
/*!
  \brief Adds the signal for the specified export to the currently open trace file.
  \param ex_port A pointer to the input port to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T>
int esc_trace_signal( sc_export< sc_signal_in_if<T> >* ex_port, const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102  && BDW_WRITEFSDB == 1
    std::string hName = topString + std::string(ex_port->name());
    fsdbDumpSC(0,hName.c_str());
    return 1;
#endif

	if ( esc_get_trace_file( traceType ) == NULL )
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: no trace file is open\n",
						 ex_port->name() );
		return 0;
	}

	// Find the attached signal and use its name as the name of the signal to find
	// in the HDL module.
	sc_signal_in_if<T> *inif = ex_port->operator->();

	if (inif == NULL)
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: sc_in port not bound\n",
						 ex_port->name() );
		return 0;
	}

	sc_signal<T> *insig = dynamic_cast<sc_signal<T>*>(inif);
	if (insig == NULL)
	{
		sc_clock *inclk = dynamic_cast<sc_clock*>(inif);
		if (inclk == NULL)
		{
			esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: sc_in port is not linked to sc_signal or sc_clock\n",
							 ex_port->name() );
			return 0;
		}

		if ( sigName == NULL )
			sigName = inclk->basename();

#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
        if ( traceType == esc_trace_fsdb )
            fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), *inclk, sigName );
        else
#endif
            sc_trace( esc_get_trace_file( traceType ), *inclk, sigName );

		return 1;
	}

	if ( sigName == NULL )
		sigName = insig->basename();
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
    if ( traceType == esc_trace_fsdb )
        fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), *insig, sigName );
    else
#endif
        sc_trace( esc_get_trace_file( traceType ), *insig, sigName );

	return 1;
}
#endif

/*!
  \brief Adds the signal for the specified port to the currently open trace file.
  \param in_port A pointer to the input port to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T>
int esc_trace_signal( sc_in<T>* in_port, const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102  && BDW_WRITEFSDB == 1
    std::string hName = topString + std::string(in_port->name());
    fsdbDumpSC(0,hName.c_str());
    return 1;
#endif

	if ( esc_get_trace_file( traceType ) == NULL )
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: no trace file is open\n",
						 in_port->name() );
		return 0;
	}

	// Find the attached signal and use its name as the name of the signal to find
	// in the HDL module.
	sc_signal_in_if<T> *inif = (*in_port)[0];
	if (inif == NULL)
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: sc_in port not bound\n",
						 in_port->name() );
		return 0;
	}

	sc_signal<T> *insig = dynamic_cast<sc_signal<T>*>(inif);
	if (insig == NULL)
	{
		sc_clock *inclk = dynamic_cast<sc_clock*>(inif);
		if (inclk == NULL)
		{
			esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: sc_in port is not linked to sc_signal or sc_clock\n",
							 in_port->name() );
			return 0;
		}

		if ( sigName == NULL )
			sigName = inclk->basename();

#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
        if ( traceType == esc_trace_fsdb )
            fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), *inclk, sigName );
        else
#endif
            sc_trace( esc_get_trace_file( traceType ), *inclk, sigName );

		return 1;
	}

	if ( sigName == NULL )
		sigName = insig->basename();
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
    if ( traceType == esc_trace_fsdb )
        fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), *insig, sigName );
    else
#endif
        sc_trace( esc_get_trace_file( traceType ), *insig, sigName );

	return 1;
}

/*!
  \brief Adds the signal for the specified port to the currently open trace file.
  \param inout_port A pointer to the input/output port to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T>
int esc_trace_signal( sc_inout<T>* inout_port, const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
    std::string hName = topString + std::string(inout_port->name());
    fsdbDumpSC(0,hName.c_str());
    return 1;
#endif

	if ( esc_get_trace_file( traceType ) == NULL )
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: no trace file is open\n",
						 inout_port->name() );
		return 0;
	}

	// Find the attached signal and use its name as the name of the signal to find
	// in the HDL module.
	// sc_inout interfaces are derived from sc_in interfaces.
	sc_signal_in_if<T> *inif = (sc_signal_in_if<T> *)(*inout_port)[0];
	if (inif == NULL)
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: sc_inout port not bound\n",
						 inout_port->name() );
		return 0;
	}

	sc_signal<T> *insig = dynamic_cast<sc_signal<T>*>(inif);
	if (insig == NULL)
	{
		sc_clock *inclk = dynamic_cast<sc_clock*>(inif);
		if (inclk == NULL)
		{
			esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: sc_inout port is not linked to sc_signal or sc_clock\n",
							 inout_port->name() );
			return 0;
		}

		if ( sigName == NULL )
			sigName = inclk->basename();

#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
        if ( traceType == esc_trace_fsdb )
            fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), *inclk, sigName );
        else
#endif
            sc_trace( esc_get_trace_file( traceType ), *inclk, sigName );

		return 1;
	}

	if ( sigName == NULL )
		sigName = insig->basename();
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
    if ( traceType == esc_trace_fsdb )
        fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), *insig, sigName );
    else
#endif
        sc_trace( esc_get_trace_file( traceType ), *insig, sigName );

	return 1;
}

/*!
  \brief Adds the signals for the specified array of ports to the currently open trace file.
  \param in_port A pointer to the array of input ports to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T, int N>
int esc_trace_signal( sc_in<T> (*in_port)[N], const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102  && BDW_WRITEFSDB == 1
        std::string hName = topString + std::string((*in_port)[i].name());
        fsdbDumpSC(0,hName.c_str());
#else
		sprintf( buf, "_%d", i );
		sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
        if ( traceType == esc_trace_fsdb )
            fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*in_port)[i], hier );
        else
#endif
            sc_trace( esc_get_trace_file( traceType ), (*in_port)[i], hier );
#endif
	}

	return 1;
}

template <class T, int N>
int esc_trace_signal( sc_signal<T> (*in_sig)[N], const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
        std::string hName = topString + std::string((*in_sig)[i].name());
        fsdbDumpSC(0,hName.c_str());
#else
		sprintf( buf, "_%d", i );
		sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
        if ( traceType == esc_trace_fsdb )
            fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*in_sig)[i], hier );
        else
#endif
            sc_trace( esc_get_trace_file( traceType ), (*in_sig)[i], hier );
#endif
	}

	return 1;
}

/*!
  \brief Adds the signals for the specified array of ports to the currently open trace file.
  \param inout_port A pointer to the array of input ports to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T, int N>
int esc_trace_signal( sc_inout<T> (*inout_port)[N], const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
        std::string hName = topString + std::string((*inout_port)[i].name());
        fsdbDumpSC(0,hName.c_str());
#else
		sprintf( buf, "_%d", i );
		sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
        if ( traceType == esc_trace_fsdb )
            fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*inout_port)[i], hier );
        else
#endif
            sc_trace( esc_get_trace_file( traceType ), (*inout_port)[i], hier );
#endif
	}

	return 1;
}

/*!
  \brief Adds the signals for the specified 2D array of ports to the currently open trace file.
  \param in_port A pointer to the 2D array of input ports to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T, int N, int M>
int esc_trace_signal( sc_in<T> (*in_port)[N][M],
		      const char *sigName=NULL,
		      esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
        std::string hName = topString + std::string((*in_port)[i][j].name());
        fsdbDumpSC(0,hName.c_str());
#else
			sprintf( buf, "_%d_%d", i, j );
			sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
            if ( traceType == esc_trace_fsdb )
                fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*in_port)[i][j], hier );
            else
#endif
                sc_trace( esc_get_trace_file( traceType ), (*in_port)[i][j], hier );
#endif
		}
	}

	return 1;
}

template <class T, int N, int M>
int esc_trace_signal( sc_signal<T> (*in_sig)[N][M],
		      const char *sigName=NULL,
		      esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
        std::string hName = topString + std::string((*in_sig)[i][j].name());
        fsdbDumpSC(0,hName.c_str());
#else
			sprintf( buf, "_%d_%d", i, j );
			sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
            if ( traceType == esc_trace_fsdb )
                fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*in_sig)[i][j], hier );
            else
#endif
                sc_trace( esc_get_trace_file( traceType ), (*in_sig)[i][j], hier );
#endif
		}
	}

	return 1;
}

/*!
  \brief Adds the signals for the specified 2D array of ports to the currently open trace file.
  \param in_port A pointer to the 2D array of inout ports to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T, int N, int M>
int esc_trace_signal( sc_inout<T> (*in_port)[N][M],
		      const char *sigName=NULL,
		      esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
        std::string hName = topString + std::string((*in_port)[i][j].name());
        fsdbDumpSC(0,hName.c_str());
#else
			sprintf( buf, "_%d_%d", i, j );
			sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
            if ( traceType == esc_trace_fsdb )
                fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*in_port)[i][j], hier );
            else
#endif
                sc_trace( esc_get_trace_file( traceType ), (*in_port)[i][j], hier );
#endif
		}
	}

	return 1;
}

template <class T, int N, int M, int CYN_O>
int esc_trace_signal( sc_in<T> (*in_port)[N][M][CYN_O],
		      const char *sigName=NULL,
		      esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
			for ( unsigned k = 0; k < CYN_O; ++k )
			{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
                std::string hName = topString + std::string((*in_port)[i][j][k].name());
                fsdbDumpSC(0,hName.c_str());
#else
				sprintf( buf, "_%d_%d_%d", i, j, k );
				sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
                if ( traceType == esc_trace_fsdb )
                    fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*in_port)[i][j][k], hier );
                else
#endif
                    sc_trace( esc_get_trace_file( traceType ), (*in_port)[i][j][k], hier );
#endif
			}
		}
	}

	return 1;
}

template <class T, int N, int M, int CYN_O>
int esc_trace_signal( sc_signal<T> (*in_sig)[N][M][CYN_O],
		      const char *sigName=NULL,
		      esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
			for ( unsigned k = 0; k < CYN_O; ++k )
			{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
                std::string hName = topString + std::string((*in_sig)[i][j][k].name());
                fsdbDumpSC(0,hName.c_str());
#else
				sprintf( buf, "_%d_%d_%d", i, j, k );
				sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
                if ( traceType == esc_trace_fsdb )
                    fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*in_sig)[i][j][k], hier );
                else
#endif
                    sc_trace( esc_get_trace_file( traceType ), (*in_sig)[i][j][k], hier );
#endif
			}
		}
	}

	return 1;
}


template <class T, int N, int M, int CYN_O>
int esc_trace_signal( sc_inout<T> (*in_port)[N][M][CYN_O],
		      const char *sigName=NULL,
		      esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
			for ( unsigned k = 0; k < CYN_O; ++k )
			{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
                std::string hName = topString + std::string((*in_port)[i][j][k].name());
                fsdbDumpSC(0,hName.c_str());
#else
				sprintf( buf, "_%d_%d_%d", i, j, k );
				sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
                if ( traceType == esc_trace_fsdb )
                    fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*in_port)[i][j][k], hier );
                else
#endif
                    sc_trace( esc_get_trace_file( traceType ), (*in_port)[i][j][k], hier );
#endif
			}
		}
	}

	return 1;
}

template <class T, int N, int M, int CYN_O, int CYN_P>
int esc_trace_signal( sc_in<T> (*in_port)[N][M][CYN_O][CYN_P],
		      const char *sigName=NULL,
		      esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
			for ( unsigned k = 0; k < CYN_O; ++k )
			{
				for ( unsigned l = 0; l < CYN_P; ++l )
				{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
                    std::string hName = topString + std::string((*in_port)[i][j][k][l].name());
                    fsdbDumpSC(0,hName.c_str());
#else
					sprintf( buf, "_%d_%d_%d_%d", i, j, k, l );
					sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
                    if ( traceType == esc_trace_fsdb )
                        fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*in_port)[i][j][k][l], hier );
                    else
#endif
                        sc_trace( esc_get_trace_file( traceType ), (*in_port)[i][j][k][l], hier );
#endif
				}
			}
		}
	}

	return 1;
}

template <class T, int N, int M, int CYN_O, int CYN_P>
int esc_trace_signal( sc_signal<T> (*in_sig)[N][M][CYN_O][CYN_P],
		      const char *sigName=NULL,
		      esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
			for ( unsigned k = 0; k < CYN_O; ++k )
			{
				for ( unsigned l = 0; l < CYN_P; ++l )
				{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
                    std::string hName = topString + std::string((*in_sig)[i][j][k][l].name());
                    fsdbDumpSC(0,hName.c_str());
#else
					sprintf( buf, "_%d_%d_%d_%d", i, j, k, l );
					sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
                    if ( traceType == esc_trace_fsdb )
                        fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*in_sig)[i][j][k][l], hier );
                    else
#endif
                        sc_trace( esc_get_trace_file( traceType ), (*in_sig)[i][j][k][l], hier );
#endif
				}
			}
		}
	}

	return 1;
}

template <class T, int N, int M, int CYN_O, int CYN_P>
int esc_trace_signal( sc_inout<T> (*in_port)[N][M][CYN_O][CYN_P],
		      const char *sigName=NULL,
		      esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
			for ( unsigned k = 0; k < CYN_O; ++k )
			{
				for ( unsigned l = 0; l < CYN_P; ++l )
				{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
                    std::string hName = topString + std::string((*in_port)[i][j][k][l].name());
                    fsdbDumpSC(0,hName.c_str());
#else
					sprintf( buf, "_%d_%d_%d_%d", i, j, k, l );
					sc_string hier = sc_string( sigName ) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
                    if ( traceType == esc_trace_fsdb )
                        fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*in_port)[i][j][k][l], hier );
                    else
#endif
                        sc_trace( esc_get_trace_file( traceType ), (*in_port)[i][j][k][l], hier );
#endif
				}
			}
		}
	}

	return 1;
}

#ifndef BDW_NO_CYNTH
/*!
  \brief Adds the signal for the specified port to the currently open trace file.
  \param ex_port A pointer to the output port to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T>
int esc_trace_signal( sc_export< sc_signal_out_if<T> >* ex_port, const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
    std::string hName = topString + std::string(ex_port->name());
    fsdbDumpSC(0,hName.c_str());
    return 1;
#endif

	if ( esc_get_trace_file( traceType ) == NULL )
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: no trace file is open\n",
						 ex_port->name() );
		return 0;
	}

	// Find the attached signal and use its name as the name of the signal to find
	// in the HDL module.
	sc_signal_out_if<T> *outif = ex_port->operator->();
	if (outif == NULL)
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: sc_out port not bound\n",
						 ex_port->name() );
		return 0;
	}

	sc_signal<T> *outsig = dynamic_cast<sc_signal<T>*>(outif);
	if (outsig == NULL)
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: sc_out port is not linked to sc_signal\n",
						  ex_port->name() );
		return 0;
	}

	if ( sigName == NULL )
		sigName = outsig->basename();

#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
    if ( traceType == esc_trace_fsdb )
        fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), *outsig, sigName );
    else
#endif
        sc_trace( esc_get_trace_file( traceType ), *outsig, sigName );

	return 1;
}
#endif

/*!
  \brief Adds the signal for the specified port to the currently open trace file.
  \param out_port A pointer to the output port to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T>
int esc_trace_signal( sc_out<T>* out_port, const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
    std::string hName = topString + std::string(out_port->name());
    fsdbDumpSC(0,hName.c_str());
    return 1;
#endif

	if ( esc_get_trace_file( traceType ) == NULL )
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: no trace file is open\n",
						 out_port->name() );
		return 0;
	}

	// Find the attached signal and use its name as the name of the signal to find
	// in the HDL module.
	sc_signal_out_if<T> *outif = (*out_port)[0];
	if (outif == NULL)
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: sc_out port not bound\n",
						 out_port->name() );
		return 0;
	}

	sc_signal<T> *outsig = dynamic_cast<sc_signal<T>*>(outif);
	if (outsig == NULL)
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: sc_out port is not linked to sc_signal\n",
						  out_port->name() );
		return 0;
	}

	if ( sigName == NULL )
		sigName = outsig->basename();

#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
    if ( traceType == esc_trace_fsdb )
        fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), *outsig, sigName );
    else
#endif
        sc_trace( esc_get_trace_file( traceType ), *outsig, sigName );

	return 1;
}


/*!
  \brief Adds the signals for the specified array of ports to the currently open trace file.
  \param out_port A pointer to the array of output ports to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T, int N>
int esc_trace_signal( sc_out<T> (*out_port)[N], const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
        std::string hName = topString + std::string((*out_port)[i].name());
        fsdbDumpSC(0,hName.c_str());
#else
		sprintf( buf, "_%d", i );
		sc_string hier = sc_string( sigName) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
        if ( traceType == esc_trace_fsdb )
            fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*out_port)[i], hier );
        else
#endif
            sc_trace( esc_get_trace_file( traceType ), (*out_port)[i], hier );
#endif
	}

	return 1;
}

/*!
  \brief Adds the signals for the specified 2D array of ports to the currently open trace file.
  \param out_port A pointer to the 2D array of output ports to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T, int N, int M>
int esc_trace_signal( sc_out<T> (*out_port)[N][M], const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
            std::string hName = topString + std::string((*out_port)[i][j].name());
            fsdbDumpSC(0,hName.c_str());
#else
			sprintf( buf, "_%d_%d", i, j );
			sc_string hier = sc_string( sigName) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
            if ( traceType == esc_trace_fsdb )
                fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*out_port)[i][j], hier );
            else
#endif
                sc_trace( esc_get_trace_file( traceType ), (*out_port)[i][j], hier );
#endif
		}
	}

	return 1;
}

template <class T, int N, int M, int CYN_O>
int esc_trace_signal( sc_out<T> (*out_port)[N][M][CYN_O], const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
			for ( unsigned k = 0; k < CYN_O; ++k )
			{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
                std::string hName = topString + std::string((*out_port)[i][j][k].name());
                fsdbDumpSC(0,hName.c_str());
#else
				sprintf( buf, "_%d_%d_%d", i, j, k );
				sc_string hier = sc_string( sigName) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
                if ( traceType == esc_trace_fsdb )
                    fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*out_port)[i][j][k], hier );
                else
#endif
                    sc_trace( esc_get_trace_file( traceType ), (*out_port)[i][j][k], hier );
#endif
			}
		}
	}

	return 1;
}

template <class T, int N, int M, int CYN_O, int CYN_P>
int esc_trace_signal( sc_out<T> (*out_port)[N][M][CYN_O][CYN_P], const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

	char buf[32];
	for ( unsigned i = 0; i < N; ++i )
	{
		for ( unsigned j = 0; j < M; ++j )
		{
			for ( unsigned k = 0; k < CYN_O; ++k )
			{
				for ( unsigned l = 0; l < CYN_P; ++l )
				{
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
                    std::string hName = topString + std::string((*out_port)[i][j][k][l].name());
                    fsdbDumpSC(0,hName.c_str());
#else
					sprintf( buf, "_%d_%d_%d_%d", i, j, k, l );
					sc_string hier = sc_string( sigName) + sc_string( buf );
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
                    if ( traceType == esc_trace_fsdb )
                        fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), (*out_port)[i][j][k][l], hier );
                    else
#endif
                        sc_trace( esc_get_trace_file( traceType ), (*out_port)[i][j][k][l], hier );
#endif
				}
			}
		}
	}

	return 1;
}

/*!
  \brief Adds the signal to the currently open trace file.
  \param sig A pointer to the signal to be traced
  \param sigName the name of the signal as it will appear in the trace file
  \param traceType the format of the trace file we've opened
  \return Non-zero on success.
*/
template <class T>
int esc_trace_signal( sc_signal<T>* sig, const char *sigName=NULL, esc_trace_t traceType=esc_trace_vcd )
{
	if (traceType == esc_trace_off)
		return 0;

#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER > 102 && BDW_WRITEFSDB == 1
    std::string hName = topString + std::string(sig->name());
    fsdbDumpSC(0,hName.c_str());
    return 1;
#endif

	if ( esc_get_trace_file( traceType ) == NULL )
	{
		esc_report_error( esc_error, "ERROR: esc_trace_signal(%s) failed: no trace file is open\n",
						 sig->name() );
		return 0;
	}

	if ( sigName == NULL )
		sigName = sig->basename();
#if defined(NC_SYSTEMC) && defined(BDW_NCSC_VER) && BDW_NCSC_VER <= 102 && BDW_WRITEFSDB == 1
    if ( traceType == esc_trace_fsdb )
        fsdb_trace( (fsdb_trace_file*)(esc_get_trace_file( traceType )), *sig, sigName );
    else
#endif
        sc_trace( esc_get_trace_file( traceType ), *sig, sigName );

	return 1;
}

/*
	esc_signal_wrapper<T>
	
	The esc_signal_wrapper<T> class provides a mechanism for instantiating an esc_signal_wrapper
	subclass appropriate for a given type.  It will be a subclass of an esc_signal subclass, so it
    can be used in place of an esc_signal class.

    If no specialization is available for the type, it defaults to subclassing esc_signal_bool.
    The member funciton "bool good()" will return true for all specializations, and false for
    the base template, so it can be used to determine whether a specialization was available.
 */
template <class T>
class esc_signal_wrapper
  : public esc_signal_bool
{
  public:
    bool good() { return false; }
};

template <int W>
class esc_signal_wrapper< sc_bigint<W> > : public esc_signal_sc_bigint<W>
{
  public:
	bool good() { return true; }
};

template <int W>
class esc_signal_wrapper< const sc_bigint<W> > : public esc_signal_sc_bigint<W>
{
  public:
	bool good() { return true; }
};

template <int W>
class esc_signal_wrapper< sc_biguint<W> > : public esc_signal_sc_biguint<W>
{
  public:
	bool good() { return true; }
};

template <int W>
class esc_signal_wrapper< const sc_biguint<W> > : public esc_signal_sc_biguint<W>
{
  public:
	bool good() { return true; }
};

template <int W>
class esc_signal_wrapper< sc_int<W> > : public esc_signal_sc_int<W>
{
  public:
	bool good() { return true; }
};

template <int W>
class esc_signal_wrapper< const sc_int<W> > : public esc_signal_sc_int<W>
{
  public:
	bool good() { return true; }
};

template <int W>
class esc_signal_wrapper< sc_uint<W> > : public esc_signal_sc_uint<W>
{
  public:
	bool good() { return true; }
};

template <int W>
class esc_signal_wrapper< const sc_uint<W> > : public esc_signal_sc_uint<W>
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< sc_clock > : public esc_signal_sc_clock
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< const sc_clock > : public esc_signal_sc_clock
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< sc_bit > : public esc_signal_sc_bit
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< const sc_bit > : public esc_signal_sc_bit
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< char > : public esc_signal_char
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< const char > : public esc_signal_char
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< unsigned char > : public esc_signal_unsigned_char
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< const unsigned char > : public esc_signal_unsigned_char
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< bool > : public esc_signal_bool
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< const bool > : public esc_signal_bool
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< double > : public esc_signal_double
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< const double > : public esc_signal_double
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< sc_time > : public esc_signal_sc_time
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< const sc_time > : public esc_signal_sc_time
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< cynw_string > : public esc_signal_cynw_string
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< const cynw_string > : public esc_signal_cynw_string
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< int > : public esc_signal_int
{
  public:
	bool good() { return true; }
};

template <>
class esc_signal_wrapper< const int > : public esc_signal_int
{
  public:
	bool good() { return true; }
};

inline
esc_signal< sc_bit > *	alloc_esc_sig( sc_signal < sc_bit > *sig )
						{ return new esc_signal_sc_bit( *sig ); }

inline
esc_signal< char > *	alloc_esc_sig( sc_signal < char > *sig )
						{ return new esc_signal_char( *sig ); }

inline
esc_signal< unsigned char > *	alloc_esc_sig( sc_signal < unsigned char > *sig )
						{ return new esc_signal_unsigned_char( *sig ); }

inline
esc_signal< bool > *	alloc_esc_sig( sc_signal < bool > *sig )
						{ return new esc_signal_bool( *sig ); }

inline
esc_signal< double > *	alloc_esc_sig( sc_signal < double > *sig )
						{ return new esc_signal_double( *sig ); }

inline
esc_signal< int > *		alloc_esc_sig( sc_signal < int > *sig )
						{ return new esc_signal_int( *sig ); }

template< int W >
inline
esc_signal< sc_int< W > >*alloc_esc_sig( sc_signal < sc_int < W > > *sig )
						{ return new esc_signal_sc_int< W >( *sig ); }

template< int W >
inline
esc_signal< sc_uint< W > >* alloc_esc_sig( sc_signal < sc_uint < W > > *sig )
						{ return new esc_signal_sc_uint< W >( *sig ); }

template< int W >
inline
esc_signal< sc_bigint< W > >* alloc_esc_sig( sc_signal < sc_bigint < W > > *sig )
						{ return new esc_signal_sc_bigint< W >( *sig ); }

template< int W >
inline
esc_signal< sc_biguint< W > >* alloc_esc_sig( sc_signal < sc_biguint < W > > *sig )
						{ return new esc_signal_sc_biguint< W >( *sig ); }

inline
esc_signal< sc_time > *alloc_esc_sig( sc_signal < sc_time > *sig )
						{ return new esc_signal_sc_time( *sig ); }

inline
esc_signal< cynw_string > *alloc_esc_sig( sc_signal < cynw_string > *sig )
						{ return new esc_signal_cynw_string( *sig ); }

/*
	esc_instruction_func_dispatcher
	
	The esc_instruction_func_dispatcher class is designed to work in conjunction with CYN_MAP_INSTRUCTION,
	CYN_CONFIG_INSTRUCTION, CYN_BIND_INPUT, and CYN_BIND_OUTPUT to provide a mechanism for executing
	instruction functions in behavioral models.
 */
class esc_instruction_func_dispatcher
{
  public:
    esc_instruction_func_dispatcher( const char* iname )
      : m_error(qbhOK), m_instr(0), m_instrName(0), n_ports(0), n_params(0), n_ports_alloc(0), n_params_alloc(0),
        m_params(0), m_ports(0), m_sigs(0), m_valrecs(0), m_done_output(false)
    {
		if (iname)
		{
			m_instrName = new char[strlen(iname)+1];
			strcpy( m_instrName, iname );
		}
    }

    ~esc_instruction_func_dispatcher()
    {
		delete [] m_instrName;
		qbhFreeNameValuePairs(m_params);
		qbhFreeNameValuePairs(m_ports);
		esc_signal_base** s = m_sigs;
		while ( s && *s ) delete *s++;
		delete [] m_sigs;
		delete [] m_valrecs;
    }

	const char* instr_name()
		{ return (m_instrName ? m_instrName : ""); }

    void init()
    {
		// Initialize for an execution.
		n_ports = 0;
		m_done_output = false;
    }


    template <class T>
    bool add_port( T& p, const char* name, bool is_input )
    {
		bool good = (m_error == qbhOK);

		if ( !m_instr && good ) 
		{
			// We're initializing, so create a new port, sig, and valrec entry.
			if (n_ports_alloc <= (n_ports+1) ) 
			{
				// Realloc m_ports, m_sigs, and m_valrecs.
				int new_n = n_ports ? n_ports*2 : 16;
				qbhNameValuePair** new_ports = new qbhNameValuePair*[new_n];
				esc_signal_base** new_sigs = new esc_signal_base*[new_n];
				qbhValueRecord** new_valrecs = new qbhValueRecord*[new_n];
				if (n_ports)
				{
					memcpy( new_ports, m_ports, sizeof(qbhNameValuePair**) * n_ports );
					delete [] m_ports;
					memcpy( new_sigs, m_sigs, sizeof(esc_signal_base**) * n_ports );
					delete [] m_sigs;
					memcpy( new_valrecs, m_valrecs, sizeof(qbhValueRecord**) * n_ports );
					delete [] m_valrecs;
				}
				m_ports = new_ports;
				m_sigs = new_sigs;
				m_valrecs = new_valrecs;
				n_ports_alloc = new_n;
			}
			m_ports[ n_ports ] = qbhCreateNameValuePair( name, (is_input ? "input" : "output") );
			m_ports[ n_ports+1 ] = 0;
			
			esc_signal_wrapper<T>* new_sig = new esc_signal_wrapper< T >;
			m_sigs[ n_ports ] = new_sig;
			m_sigs[ n_ports+1 ] = 0;
		
			m_valrecs[ n_ports ] = new_sig->valrec();
			m_valrecs[ n_ports+1 ] = 0;
		
		
			// Returns true if there was an esc_signal specialization available.
			good = new_sig->good();
		}
		
		if (good)
		{
			if (is_input)
			{
				// Check that no input was specified after an output.
				if (m_done_output)
				{
					good = false;
					esc_report_error( esc_error, "ERROR: Input %s specified after an output\n", name );
				} else {
					// Copy p into the associated sig.
					// We do a dynamic cast to get the esc_signal class.
					esc_signal_wrapper<T>* sig = dynamic_cast< esc_signal_wrapper<T>* >( m_sigs[n_ports] );
					sig->get( &p );
				}
			} else {
				// If this is the first output, execute the function.
				if (!m_done_output)
				{
					good = exec();
				}
				if (good)
				{
					// Copy signal value into p.
					esc_signal_wrapper<T>* sig = dynamic_cast< esc_signal_wrapper<T>* >( m_sigs[n_ports] );
					sig->set( *m_valrecs[n_ports], (typename esc_signal_wrapper<T>::data_type *)&p );
				}
			}
		}

		n_ports++;
		return good;
	}

    void add_param( const char* name, const char* value )
    {
		// Only collect params before configuration
		if ( !m_instr && (m_error == qbhOK) )
		{
			if (n_params_alloc <= (n_params+1) ) 
			{
				// Realloc m_params, m_sigs, and m_valrecs.
				int new_n = n_params ? n_params*2 : 16;
				qbhNameValuePair** new_params = new qbhNameValuePair*[new_n];
				if (n_params)
				{
					memcpy( new_params, m_params, sizeof(qbhNameValuePair**) * n_params );
					delete [] m_params;
				}
				m_params = new_params;
				n_params_alloc = new_n;
		
			}
			m_params[ n_params ] = qbhCreateNameValuePair( name, value );
			m_params[ n_params+1 ] = 0;

			n_params++;
		}
    }
    void add_param( const char* name, int value )
	{
		char buf[16];
		sprintf( buf, "%d", value );
		add_param( name, buf );
	}

    bool exec()
    {
		bool good = (m_error == qbhOK);

		if ( !m_instr && good ) 
		{
			qbhProjectHandle hProj;
			good = (qbhOK == (m_error = qbhGetCurrentProject( &hProj )));
			if (!good)
				good = (qbhOK == (m_error = qbhOpenProject( getenv("BDW_PROJECT_FILE"), &hProj ) ) );
			if (!good)
			{
				esc_report_error( esc_error, "ERROR: Could not open project to get instruction function for %s.\n", instr_name() );
			} else {
				good = (qbhOK == (m_error = qbhGetInstructionFunction( hProj, instr_name(), m_params, m_ports, &m_instr )));
				if (!good)
					esc_report_error( esc_error, "ERROR: Could not get instruction function for %s\n", instr_name() );
				}
			}

		if (good)
		{
			// Call the instruction function.
			// This will use input values stored in m_valrecs, and store its outputs in m_valrecs.
			good = (qbhOK == (m_error = qbhCallInstructionFunction( m_instr, m_valrecs )));
		}
		if (!good)
			sc_stop();

		return good;
    }

  protected:
	qbhError m_error;
    qbhInstructionHandle m_instr;
    char* m_instrName;
    int n_ports;
    int n_params;
    int n_ports_alloc;
    int n_params_alloc;
    qbhNameValuePair** m_params;
    qbhNameValuePair** m_ports;
    esc_signal_base** m_sigs;
    qbhValueRecord** m_valrecs;
	bool m_done_output;
};

//
// Utility class that defines a temporary attribute value spec, and then
// removes it when the variable is destructed.
//
class esc_temp_attrib_value
{
  public:
	esc_temp_attrib_value( esc_temp_attrib_value* other )
		: m_attrib(other->m_attrib), h_proj(other->h_proj), m_proxied(other)
	{
		// Proxy for a longer-lived value.
		// Pushes its handle, and pops it when its deleted.
		qbhPushTempAttribValue( h_proj, m_attrib );
	}

	esc_temp_attrib_value( const char* spec, double value, int count )
		: m_attrib(0), h_proj(0), m_proxied(0)
	{
		if (count == 0)
		{
			char buf[32];
			sprintf( buf, "%g", value );
			define_attrib( spec, buf );
		}
	}
	esc_temp_attrib_value( const char* spec, int value, int count )
		: m_attrib(0), h_proj(0), m_proxied(0)
	{
		if (count == 0)
		{
			char buf[32];
			sprintf( buf, "%d", value );
			define_attrib( spec, buf );
		}
	}
	esc_temp_attrib_value( const char* spec, const char* value, int count )
		: m_attrib(0), h_proj(0), m_proxied(0)
	{
		if (count == 0)
			define_attrib( spec, value );
	}
	~esc_temp_attrib_value()
	{
		if (m_attrib) 
		{
			if (m_proxied)
				qbhPopTempAttribValue( h_proj, m_attrib );
			else
				qbhDeleteTempAttribValue( h_proj, m_attrib );
		}
	}

  protected:
	qbhHandle m_attrib;
	qbhProjectHandle h_proj;
	esc_temp_attrib_value* m_proxied;

	void define_attrib( const char* spec, const char* value )
	{
		bool good = (qbhOK == qbhGetCurrentProject( &h_proj ));
		if (!good)
			good = (qbhOK == qbhOpenProject( getenv("BDW_PROJECT_FILE"), &h_proj ) );

		if (good)
			m_attrib = qbhAddTempAttribValue( h_proj, spec, value );
		else
			m_attrib = 0;
	}
};

/*!
  \brief Returns true if the current project has any kind of tracing
  turned on with the logOptions command in the project file.
*/

bool esc_trace_is_enabled( esc_trace_t traceType=esc_trace_vcd );

#if defined(__GNUC__)

#define ESC_DO_TRACE_SIGNAL( sig, nsig, eiu ) \
  esc_trace_signal( &sig, nsig.name(), esc_trace_type() );
  
#elif defined(STRATUS_HLS) && defined(cynthhl_h_INCLUDED)

#define ESC_DO_TRACE_SIGNAL( sig, nsig, eiu ) \
  CYN_PRESERVE( sig, eiu );
  
#else

#define ESC_DO_TRACE_SIGNAL( sig, nsig, eiu ) 

#endif


#else // BDW_HUB
inline bool esc_trace_is_enabled( esc_trace_t traceType=esc_trace_vcd ) 
{
  return false;
}

inline double esc_config_clock_period( const char *module, double default_period )
{
  return default_period;
}

inline double esc_config_clock_period( double default_period )
{
  return default_period;
}

inline void esc_set_trace_file( sc_trace_file *trace_file, esc_trace_t traceType=esc_trace_vcd )
{}

inline void esc_open_vcd_trace( const char *file_name = "systemc" )
{}

inline void esc_close_vcd_trace()
{}

inline sc_trace_file *esc_vcd_trace_file()
{
  return 0;
}

inline sc_trace_file *esc_get_vcd_trace_file()
{
  return 0;
}

typedef void (*pvf_filename)(const char *file_name);

inline void esc_set_open_fsdb_trace( pvf_filename fsdb_opener )
{
}

inline void esc_set_open_fsdb_scv_trace( pvf_filename fsdb_scv_opener )
{
}

inline sc_trace_file *esc_fsdb_trace_file()
{
  return 0;
}

inline sc_trace_file *esc_get_fsdb_trace_file()
{
  return 0;
}

inline esc_trace_t esc_trace_type()
{
  return esc_trace_off;
}

inline sc_trace_file *esc_trace_file( esc_trace_t traceType=esc_trace_type() )
{
  return 0;
}

inline sc_trace_file *esc_get_trace_file( esc_trace_t traceType=esc_trace_type() )
{
  return 0;
}

#if defined(STRATUS_HLS) && defined(cynthhl_h_INCLUDED)

#define ESC_DO_TRACE_SIGNAL( sig, nsig, eiu ) \
  CYN_PRESERVE( sig, eiu );

#else

#define ESC_DO_TRACE_SIGNAL( sig, nsig, eiu ) 

#endif

#endif // BDW_HUB

template <typename T>
void esc_trace( sc_signal<T> &sig, bool even_if_no_use_def=false )
{
  ESC_DO_TRACE_SIGNAL( sig, sig, even_if_no_use_def );
}

template <class T, int N>
void esc_trace( sc_signal<T> (&sig)[N], bool even_if_no_use_def=false)
{
  ESC_DO_TRACE_SIGNAL( sig, sig[0], even_if_no_use_def );
}

template <class T, int N, int M>
void esc_trace( sc_signal<T> (&sig)[N][M], bool even_if_no_use_def=false )
{
  ESC_DO_TRACE_SIGNAL( sig, sig[0][0], even_if_no_use_def );
}

template <class T, int N, int M, int CYN_O>
void esc_trace( sc_signal<T> (&sig)[N][M][CYN_O], bool even_if_no_use_def=false )
{
  ESC_DO_TRACE_SIGNAL( sig, sig[0][0][0], even_if_no_use_def );
}

template <class T, int N, int M, int CYN_O, int CYN_P>
void esc_trace( sc_signal<T> (&sig)[N][M][CYN_O][CYN_P], bool even_if_no_use_def=false )
{
  ESC_DO_TRACE_SIGNAL( sig, sig[0][0][0][0], even_if_no_use_def );
}


#endif // ESC_COSIM_HEADER_GUARD__
