// *****************************************************************************
// *****************************************************************************
// ctos_flex_channels_utils.h
//
// This file contains the definitions of safety and reset check macros.
// *****************************************************************************
// *****************************************************************************
//                Copyright (c) 2012 Cadence Design Systems, Inc.
//                           All Rights Reserved.
// *****************************************************************************
// *****************************************************************************

#ifndef CYNW_FLEX_CHANNELS_UTILS_H
#define CYNW_FLEX_CHANNELS_UTILS_H


#ifndef STRATUS
#define FLEX_CHANNELS_PROTOCOL(s)
#define FLEX_CHANNELS_LABEL(s)
#else
#define FLEX_CHANNELS_PROTOCOL(s)   FLEX_ ## s :
// FLEX_CHANNELS_LABELS is just regular labels.
#define FLEX_CHANNELS_LABEL(s)      s :
#endif


// ****************************************************************************
// The safety macros are to check that initiator functions which should not
// be called more than once per cycle, are not. 

#define FLEX_CHANNELS_SAFETY_DECL \
    sc_signal<bool> __FLEX_CHANNELS_SAFETY_sig; \
    bool            __FLEX_CHANNELS_SAFETY_var;

#define FLEX_CHANNELS_SAFETY_CTOR \
      __FLEX_CHANNELS_SAFETY_sig ("__FLEX_CHANNELS_SAFETY_sig") \

#ifndef STRATUS

#define FLEX_CHANNELS_SAFETY_RESET  \
    __FLEX_CHANNELS_SAFETY_var = 0; \
    __FLEX_CHANNELS_SAFETY_sig = 0; \

#define FLEX_CHANNELS_SAFETY_CHECK(STR) \
    bool __FLEX_CHANNELS_SAFETY__assert_called_only_once  = (__FLEX_CHANNELS_SAFETY_var==__FLEX_CHANNELS_SAFETY_sig); \
    if (!__FLEX_CHANNELS_SAFETY__assert_called_only_once) { \
        cout << "(" << sc_time_stamp() << "): " << name() \
             << ": ERROR: function " << STR \
             << " can only be called once in a cycle" \
             << endl; \
        sc_report_handler::report(SC_FATAL, "/FLEX_CHANNELS", std::string(std::string("function call ")+std::string(name())+std::string(".")+std::string(STR)+std::string(" cannot be called more than once in a given cycle.")).c_str(), __FILE__, __LINE__); \
    } \
    __FLEX_CHANNELS_SAFETY_var = !__FLEX_CHANNELS_SAFETY_var;\
    __FLEX_CHANNELS_SAFETY_sig = !__FLEX_CHANNELS_SAFETY_sig;\


#define FLEX_CHANNELS_CAN_SAFETY_CHECK(STR1,STR2) \
    bool __FLEX_CHANNELS_SAFETY__assert_called_only_once  = (__FLEX_CHANNELS_SAFETY_var==__FLEX_CHANNELS_SAFETY_sig); \
    if (!__FLEX_CHANNELS_SAFETY__assert_called_only_once) { \
        cout << "(" << sc_time_stamp() << "): " << name() \
             << ": WARNING: function " << STR1 \
             << " called after " << STR2 << " in same cycle will return incorrect value." \
             << endl; \
        sc_report_handler::report(SC_WARNING, "/FLEX_CHANNELS", \
            std::string(std::string("calling function ") \
                +std::string(name())+std::string(".")+std::string(STR1) \
                +std::string(" after calling ") \
                +std::string(name())+std::string(".")+std::string(STR2) \
                +std::string(" in same cycle will cause ") \
                +std::string(name())+std::string(".")+std::string(STR2) \
                +std::string(" to return an incorrect value (this is because the channel updates are be visible only at the next cycle).")).c_str(), __FILE__, __LINE__); \
    } \

#else 

#define FLEX_CHANNELS_SAFETY_RESET
#define FLEX_CHANNELS_SAFETY_CHECK(STR)

#endif


// ****************************************************************************
// The reset macros are to check that when an initiator is used, it has been 
// reset beforehand.

#define FLEX_CHANNELS_RESET_CHECK_DECL \
    bool __FLEX_CHANNELS_RESET_CHECK_var;

#define FLEX_CHANNELS_RESET_CHECK_CTOR \
      __FLEX_CHANNELS_RESET_CHECK_var (0)

#ifndef STRATUS

// These macros check that the reset function has been called.
#define FLEX_CHANNELS_RESET_CALLED \
    __FLEX_CHANNELS_RESET_CHECK_var = 1; \

#define FLEX_CHANNELS_RESET_CHECK \
    if (!__FLEX_CHANNELS_RESET_CHECK_var) { \
        cout << "(" << sc_time_stamp() << "): " << name() \
             << ": ERROR: reset function has not been called." << endl; \
        sc_report_handler::report(SC_FATAL, "/FLEX_CHANNELS", std::string(std::string("reset function has not been called for initiator ")+std::string(name())+std::string(".")).c_str(), __FILE__, __LINE__); \
    }


#else 

#define FLEX_CHANNELS_RESET_CALLED
#define FLEX_CHANNELS_RESET_CHECK
#define FLEX_CHANNELS_CAN_SAFETY_CHECK(STR1,STR2) 

#endif

#endif

