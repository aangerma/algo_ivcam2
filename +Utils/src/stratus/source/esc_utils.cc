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
///////////////////////////////////////////////////////////////////////
//
// esc_hub.cc: This file defines utility functions used by SystemC.
//
// Author: Andrew Fairley
// Created: July 1, 2002
// Copyright(c) 2002 Forte Design Systems
//
///////////////////////////////////////////////////////////////////////

// Defining these files in the cc means the version can be found in the library
#include "esc.h"

static const char esc_version_string[] = "Stratus version - " MY_VERSION "  (" esc_xstr(BDW_DATE) ")";

const char* esc_version()
{ return esc_version_string; }


#if BDW_HUB

void esc_close_open_loggers()
{
	esc_hub::close_all_open_loggers();
}

char* esc_realtime()
{
  return (char*)ESC_CUR_TIME_STR;
}

#else

void esc_close_open_loggers()
{

}

char* esc_realtime()
{
  return "";
}
#endif // BDW_HUB

