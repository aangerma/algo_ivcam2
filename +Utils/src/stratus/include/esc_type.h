/**************************************************************************
**
** This file is part of the Cynthesizer (TM) software product and is protected 
** by law including United States copyright laws, international treaty 
** provisions, and other applicable laws.
**
** Copyright (c) 2013 Forte Design Systems and / or its subsidiary(-ies).  All
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

#ifndef ESC_TYPE_HEADER_GUARD__
#define ESC_TYPE_HEADER_GUARD__

#include "capicosim.h"
#include "esc.h"

/*!
  \file esc_type.h
  \brief Classes and functions for SystemC type registration

  If you have an sc_signal<> that you would like to drive a signal in HDL, or
  to be driven by a signal in HDL, the data type that sc_signal<> is templated
  on must be registered with a call to hub_register_signal_type().  If this data
  type is itself templated ( such as sc_uint< 8 > ), then you should use
  hub_register_signal_type_1().

  esc_type.cc registers a large number of the basic C++ and SytemC data types.
  You only need to use the hub_register_signal_type() macros if you want to
  drive/have driven an sc_signal<> that is templated on a data type not in this list.


  If you want to watch an esc_watchable<> (esc_chan<> is derived from esc_watchable<>),
  the data type of the esc_watchable<> must be registered.  TDB and CSV loggers operate
  by watching esc_watchable<>s, if you want to log data from any esc_watchable<> or
  esc_chan<>, it's data type must also be registered.  Registration occurs with a
  call to hub_register_watchable_type(), if the data type is templated, use
  hub_register_watchable_type_1().  If the data type you are registering is a record,
  use hub_register_watchable_record_type().

  esc_type.cc registers a large number of the basic C++ and SystemC data types.
  As well, hubsync will generate all needed registration functions for records that
  it generates SystemC code for.  You only need to use the hub_register_watchable_type()
  macros if you are using a data type that does not exist in esc_type.cc, or
  hubsync-generated code.
*/

/*!
  \internal
  \brief This function is called from esc_hub.cc and
  creates a dependency between esc_hub.o and esc_type.o
*/
extern void esc_register_types();


#if BDW_HUB

/*!
  \internal
  \class esc_type_params
  \brief This struct can be passed into an esc_type_func to provide extra parameters.

  This struct is used when linking signals in SystemC with signals in another Hub domain.
*/
struct esc_type_params
{
	esc_link_direction_t direction;		// direction of the link
	char *				extern_path;	// domain-prefixed path for external signal
	char *				extern_domain;	// name of external domain, if extern_path doesn't include it
	qbhEntityInfo *		info;			// Used with esc_type to determine the datatype of an sc_signal
};

typedef unsigned short  esc_reg_type;
#define esc_link		1
#define esc_type		2
#define esc_watch		4
#define esc_log			8
/* The following lists must be mutually exclusive */
#define esc_watchable_list ( esc_watch | esc_log )
#define esc_signal_list ( esc_link | esc_type )

/*!
  \internal
  \class esc_interpreter
  \brief This is the base class for interpreting objects based on their type.

  This class will never have to be instantiated or used by the user.

  There exists one class derived from esc_interpreter per action sent into
  esc_type_handler::determine_type(), and it is the exec() call on the
  derived class that performs a specific function.
*/
template< class T >
class esc_interpreter
{
 public:

	esc_interpreter()  {}
	~esc_interpreter() {}

	virtual int exec( T* val, void* params )=0;
};

/*!
  \internal
  \class esc_link_interpreter
  \brief This class is used to link signals between SystemC and the Hub using only their char* name

  This class will never have to be instantiated or used by the user.
*/
template< class T >
class esc_link_interpreter : public esc_interpreter<T>
{
 public:

							esc_link_interpreter() {}
							~esc_link_interpreter() {}

	/*!
	  \return Non-zero on success
	*/
	virtual int				exec( T* val, void* params )
							{
								int retval = 0;
								esc_type_params *tp = (esc_type_params*)params;

								if ( tp )
								{
									retval = esc_link_signals( tp->direction, val, 
															   alloc_esc_sig(val), 
															   tp->extern_path, tp->extern_domain );
								}

								return retval;
							}
};

#if SYSTEMC_VERSION <= 20020405
/*!
  \internal
  \class esc_type_interpreter
  \brief This class is used to determine the Hub type of an sc_signal

  This class will never have to be instantiated or used by the user.
*/
template< class T >
class esc_type_interpreter : public esc_interpreter<T>
{
 public:

							esc_type_interpreter() {}
							~esc_type_interpreter() {}

	/*!
	  \return Non-zero on success
	*/
	virtual int				exec( T* val, void* params )
							{
								esc_type_params *tp = (esc_type_params*)params;

								if ( tp && tp->info )
								{
									tp->info->type = HubGetType( &val->get_data_ref() );
								}
								return 1;
							}
};

template< class T >
class esc_hub_watcher;

/*!
  \internal
  \class esc_watch_interpreter
  \brief

  This class will never have to be instantiated or used by the user.
*/
template< class T >
class esc_watch_interpreter : public esc_interpreter<T>
{
 public:

	esc_watch_interpreter() {}
	~esc_watch_interpreter() {}

	virtual int exec( T* val, void* params )
	{
		char *channame = (char*)params;

		return create_watcher( channame, val, val->get_data_ref() );
	}

	template < class dataT >
	int	create_watcher( char* channame, T* val, const dataT & data_type )
	{
		esc_watchable< dataT >* watchable = dynamic_cast< esc_watchable< dataT >* >(val);
		if ( watchable )
		{
			esc_hub_watcher< dataT >* watcher = new esc_hub_watcher< dataT >( channame, watchable );
			return 1;
		}
		else
			return 0;
	}
};

#endif

#if 0
class esc_csv_logger;

/*!
  \internal
  \class esc_log_interpreter
  \brief

  This class will never have to be instantiated or used by the user.
*/
template< class T >
class esc_log_interpreter : public esc_interpreter<T>
{
 public:

							esc_log_interpreter() {}
							~esc_log_interpreter() {}

	/*!
	  \return Non-zero on success
	*/
	virtual int				exec( T* val, void* params );
};

template< class T>
int	esc_log_interpreter<T>::exec( T* val, void* params )
{
	int retval = 0;

	esc_tx_logger* logger = (esc_tx_logger*)params;

	T *watchable_obj = dynamic_cast< T* >( val );
	if ( watchable_obj )
	{
		esc_csv_logger* clogger = dynamic_cast< esc_csv_logger* >(logger);
		//if ( clogger )
		//{ clogger->add( watchable_obj ); retval = 1; }
	}

	return retval;
}
#endif
/*!
  \internal
  \class esc_type_fp
  \brief This struct is used when types are registered with the Hub.

  There is one instance per type, and the function m_func is used to convert an instance
  of sc_object* into a derived class of the specified type if possible.

  An instance of this struct is created from the macro hub_register_type(), the linked
  list is stored in esc_type_handler.
*/
struct esc_type_fp
{
	int (*m_func)( sc_object* obj, int action, void* params );
	esc_type_fp *			m_next;
};

typedef int (esc_type_func)( sc_object *obj, int action, void* params );

/*!
  \internal
  \class esc_type_handler
  \brief Class is used to perform type-specific functions from the functions that are registered with it

  Calls to hub_register_signal_type() result in the creation of a function that can
  identify the specified type.  These functions use dynamic_cast<> to test the type 
  of a sc_object*, and if successful, will cast to that type, and call 
  esc_interpreter<>::exec() on it.  After the function has been defined, it will be 
  registered via a call to esc_type_handler::register_type. During execution,
  a call to esc_type_handler::determine_type() can be called with an object, and a
  particular action.  There exists one class derived from esc_interpreter per action,
  and it is an instance of this derived class that will have exec() called on it.
  It is the exec() call that will actually do something meaningful with the sc_object*
  once its type has been determined.
*/
class esc_type_handler
{
 public:
						esc_type_handler() {}
						~esc_type_handler() {}

						/*!
						  \internal
						  \brief Registers a function in the list of functions that can determine the type of a sc_object*
						  \param tf The function to be registered
						  \param types Should be the full set of esc_reg_types that this function can handle

						  There should only be one function registered per type.
						*/
	static int			register_type( esc_type_func *tf, esc_reg_type types )
						{
							if ( types & esc_link )
							{
								esc_type_fp *new_type = new esc_type_fp;
								new_type->m_func	  = tf;
								new_type->m_next	  = NULL;

								if ( !m_link_functions )
									m_link_functions = new_type;
								else
								{ // append
									esc_type_fp *iter = m_link_functions;
									
									while( iter && iter->m_next ) iter = iter->m_next;

									iter->m_next = new_type;
								}
							}
							if ( types & esc_type )
							{
								esc_type_fp *new_type = new esc_type_fp;
								new_type->m_func	  = tf;
								new_type->m_next	  = NULL;

								if ( !m_type_functions )
									m_type_functions = new_type;
								else
								{ // append
									esc_type_fp *iter = m_type_functions;
									
									while( iter && iter->m_next ) iter = iter->m_next;

									iter->m_next = new_type;
								}
							}
							if ( types & esc_watch )
							{
								esc_type_fp *new_type = new esc_type_fp;
								new_type->m_func	  = tf;
								new_type->m_next	  = NULL;

								if ( !m_watch_functions )
									m_watch_functions = new_type;
								else
								{ // append
									esc_type_fp *iter = m_watch_functions;
									
									while( iter && iter->m_next ) iter = iter->m_next;

									iter->m_next = new_type;
								}
							}
							if ( types & esc_log )
							{
								esc_type_fp *new_type = new esc_type_fp;
								new_type->m_func	  = tf;
								new_type->m_next	  = NULL;

								if ( !m_log_functions )
									m_log_functions = new_type;
								else
								{ // append
									esc_type_fp *iter = m_log_functions;

									while( iter && iter->m_next ) iter = iter->m_next;

									iter->m_next = new_type;
								}
							}

							return 0;
						}

						/*!
						  \internal
						  \brief Determines the type of the specified sc_object*, and performs a specified action using esc_interpreter
						  \param obj The object that has an undetermined type
						  \param action Should be a single esc_reg_type to be performed
						  \param params Optional parameters that will be passed into the esc_interpreter
						  \return Non-zero if the type was determined

						  !!!!Warning!!!!
						  This function calls functions that use dynamic_cast<>().  If the action
						  passed into this function is an element of esc_watchable_list, then obj -must-
						  be a pointer to an element derived from esc_watchable.  If the action is an element
						  of esc_signal_list, then obj -must- be a pointer to an element derived from sc_signal.
						  There is no way to check data types once in this function.
						*/
	static int			determine_type( sc_object* obj, esc_reg_type action, void* params )
						{
							int success = 0;
							esc_type_fp **head = NULL;
							esc_type_fp *iter = NULL;
							esc_type_fp *prev = NULL;

							if ( action & esc_link )
								head = &m_link_functions;
							else if ( action & esc_type )
								head = &m_type_functions;
							else if ( action & esc_watch )
								head = &m_watch_functions;
							else if ( action & esc_log )
								head = &m_log_functions;

							iter = *head;

							// Find the function that can interpret the type
							while ( iter && !success )
							{
								success = iter->m_func( obj, action, params );
								if ( ! success )
								{
									prev = iter;
									iter = iter->m_next;
								}
							}

							// If we were successful, move the matching
							//   function to the front of the list
							if ( success && iter != *head )
							{
								prev->m_next = iter->m_next;
								iter->m_next = *head;
								*head = iter;
							}

							return success;
						}

 protected:
	static esc_type_fp *m_link_functions;		// Registered type casting functions
	static esc_type_fp *m_type_functions;		// Registered type casting functions
	static esc_type_fp *m_watch_functions;		// Registered type casting functions
	static esc_type_fp *m_log_functions;		// Registered type casting functions
};
#if 0
/*!
  \brief Registers an esc_watchable< type > that allows use of esc_tx_logger::add(char* objname)
  \param type The type to be registered.
  \param uniquename Uniquely identify the type, can be the name of the type

  \code
  hub_register_watchable_type( my_record*, my_record );
  \endcode

  In order to use esc_csv_logger::add(char*), 
  the type must be registered.  This is exactly the same form as 
  hub_register_watchable_type(), but also defines a HubGetType(), which may
  already be defined for non-hubsync generated types.
*/
#define hub_register_watchable_record_type( type, uniquename )                 \
		qbhTypeHandle HubGetType( type const * v ) { return qbhEmptyHandle; }  \
		hub_register_watchable_type( type, uniquename );

/*!
  \brief Registers an esc_watchable< type > that allows use of esc_tx_logger::add(char* objname)
  \param type The type to be registered.
  \param uniquename Uniquely identify the type, can be the name of the type

  \code
  hub_register_watchable_type( my_record*, my_record );
  \endcode

  In order to use esc_csv_logger::add(char*), 
  the type must be registered.
*/
// The function definitions alloc_esc_sig and esc_link_sigs will never be
// called, but must exist to satisfy templated functions
#define hub_register_watchable_type( type, uniquename )                                     \
        esc_signal< type > *alloc_esc_sig( esc_watchable < type > *sig, type const * val )  \
            { return NULL; }                                                                \
        int esc_link_signals( esc_link_direction_t direction, esc_watchable < type >* int_object, \
                              esc_signal< type  >* int_sig, const char* ext_path, const char* ext_domain) \
            { return 0; }                                                                   \
        int uniquename##_esc_watchable_reg_func( sc_object *obj, int action, void* params ) \
        {                                                                                   \
            int success = 0;                                                                \
            esc_watchable < type > * post_cast = NULL ;                                     \
            if ( esc_watchable_for( obj, &post_cast ) )                                     \
            {                                                                               \
                int i = 0;                                                                  \
                esc_interpreter< esc_watchable < type > > *interp = NULL;                   \
                if ( action == esc_log ) interp = new esc_log_interpreter < esc_watchable < type > >(); \
                else if ( action == esc_watch ) interp = new esc_watch_interpreter < esc_watchable < type > >(); \
                if (interp)                                                                 \
                    i = interp->exec( post_cast, params );                                  \
                delete interp;                                                              \
                success = i;                                                                \
            }                                                                               \
            return success;                                                                 \
        }                                                                                   \
        static int uniquename##_esc_watchable_reg_value                                     \
            = esc_type_handler::register_type( uniquename##_esc_watchable_reg_func, esc_watchable_list );

/*!
  \brief Registers an esc_watchable< type < t1 > > that allows use of esc_tx_logger::add(char* objname)
  \param type The type to be registered.
  \param uniquename A name to uniquely id this string. (Can be a repeat of the type.)
  \param t1 The type that 'type' is templated on 

  This macro provides the same functionality as hub_register_watchable_type(),
  but is used with types that are templated.

  In order to use esc_csv_logger::add(char*), 
  the type must be registered.
*/
#define hub_register_watchable_type_1( type, uniquename, t1 )	\
        esc_signal< type < t1 > > *alloc_esc_sig( esc_watchable < type < t1 > > *sig, type < t1 > const * val )	\
            { return NULL; }                                                                \
        int esc_link_signals( esc_link_direction_t direction, esc_watchable < type < t1 > >* int_object,\
                              esc_signal < type < t1 > >* int_sig, const char* ext_path, const char* ext_domain)\
            { return 0; }                                                                   \
        int uniquename##_##t1##_esc_watchable_reg_func( sc_object *obj, int action, void* params ) \
        {                                                                                   \
            int success = 0;                                                                \
            esc_watchable < type < t1 > > * post_cast = NULL;                               \
            if ( esc_watchable_for( obj, &post_cast ) )                                     \
            {                                                                               \
                int i = 0;                                                                  \
                esc_interpreter< esc_watchable < type < t1 > > > *interp = NULL;            \
                if ( action == esc_log ) interp = new esc_log_interpreter < esc_watchable < type < t1 > > >(); \
                else if ( action == esc_watch ) interp = new esc_watch_interpreter < esc_watchable < type < t1 > > >(); \
                if (interp)                                                                 \
                    i = interp->exec( post_cast, params );                                  \
                delete interp;                                                              \
                success = i;                                                                \
            }                                                                               \
            return success;                                                                 \
        }                                                                                   \
        static int uniquename##_##t1##_esc_watchable_reg_value                              \
            = esc_type_handler::register_type( uniquename##_##t1##_esc_watchable_reg_func, esc_watchable_list );

/*!
  \brief Registers an sc_signal< type > that allows use of simplified functions.
  \param type The type to be registered.
  \param uniquename A const char* name to uniquely identify the type, can the the name of the type as a string.

  This macro allows use of esc_link_signals(esc_link_direction_t,char*,char*,char*), 
  esc_link_signals(char* filename), and to allow returning type information to the Hub.

  There are several types that are already registered in esc_type.cc.  If the 
  user does not plan to execute the simulation using the Hub, registration of
  types is not necessary.
*/
#define hub_register_signal_type( type, uniquename )                                        \
        int uniquename##_sc_signal_reg_func( sc_object *obj, int action, void* params )     \
        {                                                                                   \
            int success = 0;                                                                \
            sc_object *base = (sc_object*)obj;                                              \
            sc_signal < type > * post_cast = NULL;                                          \
            if ( (post_cast = dynamic_cast< sc_signal < type > * >(base)) != NULL )         \
            {                                                                               \
                int i = 0;                                                                  \
                esc_interpreter< sc_signal < type > > *interp = NULL;                       \
                if ( action == esc_link ) interp = new esc_link_interpreter < sc_signal < type > >(); \
                else if ( action == esc_type ) interp = new esc_type_interpreter < sc_signal < type > >(); \
                else if ( action == esc_log ) interp = new esc_log_interpreter < sc_signal < type > >(); \
                if (interp)                                                                 \
                    i = interp->exec( post_cast, params );                                  \
                delete interp;                                                              \
                success = i;                                                                \
            }                                                                               \
            return success;                                                                 \
        }                                                                                   \
        static int uniquename##_sc_signal_reg_value                                         \
                = esc_type_handler::register_type( uniquename##_sc_signal_reg_func, esc_signal_list );

/*!
  \brief Registers an sc_signal< type < t1 > > that allows use of simplified functions.
  \param type The type to be registered.
  \param uniquename A const char* name to uniquely identify the type, can the the name of the type as a string.
  \param t1 The type that 'type' is templated on.

  This macro provides the same functionality as hub_register_signal_type(),
  but is used with types that are templated.

  This macro allows use of esc_link_signals(esc_link_direction_t,char*,char*,char*), 
  esc_link_signals(char* filename), and to allow returning type information to the Hub.

  There are several types that are already registered in esc_type.cc.  If the 
  user does not plan to execute the simulation using the Hub, registration of
  types is not necessary.
*/
#define hub_register_signal_type_1( type, uniquename, t1 )                                  \
        int uniquename##_##t1##_sc_signal_reg_func( sc_object *obj, int action, void* params ) \
        {                                                                                   \
            int success = 0;                                                                \
            sc_object *base = (sc_object*)obj;                                              \
            sc_signal < type < t1 > > * post_cast = NULL;                                   \
            if ( (post_cast = dynamic_cast< sc_signal < type < t1 > > * >(base)) != NULL )  \
            {                                                                               \
                int i = 0;                                                                  \
                esc_interpreter< sc_signal < type < t1 > > > *interp = NULL;                \
                if ( action == esc_link ) interp = new esc_link_interpreter < sc_signal < type < t1 > > >(); \
                else if ( action == esc_type ) interp = new esc_type_interpreter < sc_signal < type < t1 > > >(); \
                else if ( action == esc_log ) interp = new esc_log_interpreter < sc_signal < type < t1 > > >(); \
                if (interp)                                                                 \
                    i = interp->exec( post_cast, params );                                  \
                delete interp;                                                              \
                success = i;                                                                \
            }                                                                               \
            return success;                                                                 \
        }                                                                                   \
        static int uniquename##_##t1##_sc_signal_reg_value =                                \
            esc_type_handler::register_type( uniquename##_##t1##_sc_signal_reg_func, esc_signal_list );

#endif
#endif // BDW_HUB


#endif // ESC_TYPE_HEADER_GUARD__

