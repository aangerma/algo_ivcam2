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
///////////////////////////////////////////////////////////////////////
//
// esc_cleanup.cc: This is the backup esc_cleanup() function that will
//					only get called if the user doesn't define a
//					esc_cleanup() of their own.
//					This function must be in its own .cc so that the symbol
//					will only get pulled in if doesn't already exist.
//					This function is called from the default library
//					callback function when qbhUnloadTime is passed in.
//					Users can define this function to cleanup their
//					SystemC design at the end of the simulation
//
// Author: Andrew Fairley
// Created: June 19, 2002
// Copyright(c) 2002 Forte Design Systems
//
///////////////////////////////////////////////////////////////////////


#if PROFILE != 1
// We need to make sure we're getting the user's esc_cleanup for static linking.
void esc_cleanup()
{
	// Intentionally blank, and it is not an error to enter this function.
}
#endif
