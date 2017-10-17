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

#ifndef ESC_TX_HEADER_GUARD_
#define ESC_TX_HEADER_GUARD_

/*!
  \file esc_tx.h
  \brief Classes and functions for encoded operations
*/

/*!
  \class esc_tx
  \brief Base class for encoded operations.

  Encoded operations (transaction classes) are grouped into sets
  (similar to RAVE, in which ops are grouped into opsets).  Each 
  encoded operation is derived from a base class of which there
  is one per set.  This base class itself is derived from esc_tx.  
*/
class esc_tx : public esc_msg_base
{
  public:
	//! Constructor
	esc_tx( int tag ) : m_tag(tag)
	{}

	//! Returns the tag for this transaction class to identify it within the set.
	int tag()
		{ return m_tag; }
  protected:
	int		m_tag;
};


/*!
  \brief Macro that defines standard name of the encoded operation
  class corresponding to the given interface name.
*/
#define ESC_TX( if_name ) if_name##_tx


#endif
