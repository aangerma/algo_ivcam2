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

#ifndef ESC_HUB_HEADER_GUARD__
#define ESC_HUB_HEADER_GUARD__

#if BDW_HUB

#include "qbhCapi.h"
#include "capicosim.h"
#include "esc_ran.h"

#if SYSTEMC_VERSION < 20070314
#define SC_FIND_OBJECT(name) sc_get_curr_simcontext()->find_object( (name) )
#else
#define SC_FIND_OBJECT(name) sc_find_object(name)
#endif

#define ESC_SIM_STOPPED (sc_get_curr_simcontext()->sim_status() == SC_SIM_USER_STOP) 

/*! 
  \file esc_hub.h
  \brief Classes and functions for SystemC-Hub integration
*/

/*!
  \internal 
  \class esc_cb_elem
  \brief Only relevant when the Hub is slaved to SystemC.  Holds function and data for a callback.

  Each call to domain_schedule_cb with qbhDomainScheduleAfterTime will create one of these.
  The user doesn't directly use this class.

*/
class esc_cb_elem
{
 public:

	esc_cb_elem( qbhEventCallback func, void *data )
		: m_callbackFunc(func), m_callbackData(data), m_next(0) {}

	qbhEventCallback		m_callbackFunc;	// function to call on the HUB
	void *					m_callbackData; // data to pass back into m_callbackFunc
	esc_cb_elem *			m_next;			// next element, within an esc_time_cb_elem, they are unsorted
};

/*!
  \internal
  \class esc_cb_elem
  \brief Only relevant when the Hub is slaved to SystemC.  Holds a time and a list of esc_cb_elems.

  This class is used to keep a list of the callbacks into the HUB,
	and the time at which they should occur.
  The user doesn't directly use this class.
*/

class esc_timed_cb_elem
{
 public:

	// time must be in ps
	esc_timed_cb_elem( double time, esc_cb_elem *elem=NULL )
		: m_time(time), m_cb_elem(elem), m_next(0) {}

	double					m_time;		// absolute time of the HUB callback in ps
	esc_cb_elem *			m_cb_elem;	// first callback element at this time
	esc_timed_cb_elem *		m_next;		// next element, sorted by time
};

template < class T >
class esc_signal;
class esc_tx_logger;

/*!
  \internal
  \brief Default libdef callback
*/
extern "C" ESC_EXPORT void hub_libdef_default_callback( qbhLibraryCallbackReason cbr );


/*! 
  \internal
  \class esc_hub
  \brief The SystemC-Hub verification class.

  All functions in this class are marked as internal because the user should never
  have to instantiate an esc_hub, and should never have to interact with the class
  directly.
*/
class esc_hub : public sc_module
{
 public:

	SC_HAS_PROCESS(esc_hub);

							esc_hub( int is_master );
							~esc_hub();

							/*!
							  \internal 
							  \brief The main function for the sc_module.
							  
							  When the Hub is slaved to SystemC, this function will handle
							  the callbacks for the Hub, which needs control explicitly
							  returned to it.
							*/
	void					main();

							/*!
							  \internal
							  \brief Determines whether the Hub has been initialized.
							  \return Non-zero if the Hub has been initialized.
							*/
	static int				is_inited() { return m_inited; }

							/*!
							  \internal
							  \brief sc_modules that need to wait until just after initialization can wait on this event

							  If the user has an sc_module driving a SystemC bfm, and the SystemC example is
							  loaded from the Hub, using this event will be necessary to ensure the bfm isn't 
							  driven before the bfm has been connected to the Hub.
							*/
	sc_event &				init_event() { return m_init_event; }

							/*!
							  \internal
							  \brief Returns true iff there's a current domain without side effects.
							*/
	static bool				has_domain() { return m_current_p != NULL; }

							/*!
							  \internal
							  \brief Returns the current esc_hub.

							  There should be only one esc_hub per simulation, this function will
							  create one if it does not already exist.
							*/
	static esc_hub *        current()
								{ return ( m_current_p ? m_current_p : (m_current_p=new esc_hub(1)) ); }
							/*!
							  \internal
							  \brief Returns the handle for the SystemC domain.
							*/
	static qbhDomainHandle 	domain()
								{ return current()->m_domain_handle; }

							/*!
							  \internal
							  \brief Loads the HUB as the master to the calling domain.
							  
							  Sets the execute style to cooperative if the program is already 
							  registered with the HUB.

							  \return Non-zero on success.
							*/
	static int              hubconnect();

							/*!
							  \internal
							  \brief Loads the HUB as a slave to the calling program.

							  Sets the execution style to master if the program is already 
							  registered with the HUB.

							  \return Non-zero on success.
							*/
	static int              load();

							/*!
							  \internal
							  \brief Starts the Hub after test have been loaded and before they are run.
							  \return Non-zero on success.
							*/
	static int				start()
								{
									return (qbhInit( domain() ) == qbhOK); 
								}

	// Non-static member functions
							/*!
							  \internal
							  \brief Used to determine whether SystemC has been registered with the Hub.
							  \return Non-zero if SystemC has been registered.
							*/
	int						is_registered()
								{ return (m_domain_handle != qbhEmptyHandle); }

							/*!
							  \internal
							  \brief Called automatically when an esc_tx_logger is opened
							  \param logger The logger to add to the list
							  
							  Used to maintain a list of open loggers so that if a logger
							  isn't deleted at the end of simulation, it will be closed.
							  This prevents creating a corrupt tdb file.
							*/
	static void				add_open_logger( esc_tx_logger *logger )
							{
								m_open_loggers.push_back(logger);
							}

							/*!
							  \internal
							  \brief Called automatically when an esc_tx_logger is closed
							  \param logger The logger to remove from the list
							  
							  Used to maintain a list of open loggers so that if a logger
							  isn't deleted at the end of simulation, it will be closed.
							  This prevents creating a corrupt tdb file.
							*/
	static void				remove_open_logger( esc_tx_logger *logger )
							{
								esc_tx_logger **iter=NULL;
								bool done = false;
								for( iter = m_open_loggers.begin(); 
									 !done && iter!=m_open_loggers.end(); 
									 iter++ )
								{
									if ( *iter == logger )
									{
										m_open_loggers.erase( iter );
										done = true;
									}
								}
							}

							/*!
							  \internal
							  \brief Closes all open esc_loggers.
  
							  If a tdb file is being written to, but is never closed, the tdb cannot be opened.
							  sc_loggers will automatically close themselves if they are deleted, however, 
							  if esc_loggers are created on the free store, they may not get a chance to be
							  deleted, and therefore closed.

							  This function should never be called by the user, unless the user has written
							  a user-defined libdef callback function.
							*/
	static void				close_all_open_loggers();

	static int				m_systemc_is_master;		// Non-zero if SystemC registers as a master domain
    static int              m_num_reged_tests_and_srcs;
	static qbhValRecEncodingInfo *m_info;
	static esc_vector<esc_tx_logger*> m_open_loggers;	// list is maintained so that we can ensure 
														// all loggers are closed at the end of simulation

							/*!
							  \internal
							  \brief Registration function for qbhDomainNameActivity.

							  userData is a esc_hub.  This function calls domain_name_cb() on it.
							*/
	static qbhError			static_domain_name_cb( qbhDomainHandle			hDomain,
												   void*					userData,
												   qbhDomainNameActivity	code,
												   qbhHandle				inHandle,
												   qbhHandle*				outHandle,
												   char *					name,
												   qbhNetlistNodeType		kind );

							/*!
							  \internal
							  \brief Registration function for qbhDomainValueActivity.

							  userData is a esc_hub.  This function calls domain_name_cb() on it.
							*/
	static qbhError			static_domain_value_cb( qbhDomainHandle			hDomain,
													void*					userData,
													qbhDomainNameActivity	code,
													qbhHandle				inHandle,
													qbhHandle*				outHandle );

							/*!
							  \internal
							  \brief Registration function for qbhDomainExecActivity.
							  
							  userData is a esc_hub.  This function calls domain_exec_cb() on it.
							*/
	static qbhError			static_domain_exec_cb(	qbhDomainHandle 		d,
													void* 					userData,
													qbhDomainExecActivity	code,
													double 					inTime,
													double* 				outTime );

							/*!
							  \internal
							  \brief Registration function for qbhDomainScheduleActivity.
							  
							  userData is a esc_hub.  This function calls domain_schedule_cb() on it.
							*/
	static qbhError			static_domain_schedule_cb(	qbhDomainHandle 		d,
														void* 					userData,
														qbhDomainScheduleActivity	code,
														double					time, // in ps
														qbhEventCallback		callbackFunc,
														void *					callbackData );

							/*!
							  \internal
							  \brief Return a pseudo-random from the global generator.

							  Creates a generator if it doesn't yet exist.
							*/
	static int				rand();

							/*!
							  \internal
							  \brief Return a pseudo-random from the global generator.

							  Creates a generator if it doesn't yet exist.
							  Replaces the current one if it does.
							*/
	static void				srand( unsigned int seed );

 private:
	int                     register_domain( int is_master );
	void					init();
	void					add( esc_cb_elem *elem, double time );
	
	qbhError				domain_name_cb( qbhDomainHandle			hDomain,
											qbhDomainNameActivity	code,
											qbhHandle				inHandle,
											qbhHandle*				outHandle,
											char *					name,
											qbhNetlistNodeType		kind );

	qbhError				domain_value_cb( qbhDomainHandle		hDomain,
											 qbhDomainNameActivity	code,
											 qbhHandle				inHandle,
											 qbhHandle*				outHandle );

	qbhError				domain_exec_cb(	qbhDomainHandle 		d,
											qbhDomainExecActivity	code,
											double 					inTime,
											double* 				outTime );

	qbhError				domain_schedule_cb( qbhDomainHandle 		d,
												qbhDomainScheduleActivity	code,
												double					time,
												qbhEventCallback		callbackFunc,
												void *					callbackData );

	void					exec_sc_now();

 private:
	// Private data members
	static esc_hub *		m_current_p;	// Static pointer to shared esc_hub object

	static int				m_inited;		// only used when SystemC is slaved to the Hub
	static esc_ran_gen< int > *	m_ran_gen;	// global random generator

	qbhDomainHandle			m_domain_handle;// HUB handle for the SystemC domain

	esc_timed_cb_elem *		m_cb_list;		// list of callback elements, sorted by time

	sc_event				m_interrupt_event; // interrupts the wait of the callbacks	

	sc_event				m_init_event;	// modules that need to wait until everything has been set up 
											// can wait on this event
};

/*! 
  \brief Registers the domain and performs general setup in order for SystemC to be slaved to the Hub.
  \return Non-zero on success.

  This function should not be called if the Hub is slaved to SystemC (ie SystemC is built as a
  standalone executable.)
*/
int esc_connect();

/*! 
  \brief Loads the Hub.  The Hub must be loaded in order to interact with it.
  \return Non-zero on success.
*/
extern int esc_load();

/*! 
  \brief Starts the Hub.
  \return Non-zero on success.
*/
int esc_start();

/*!
  \brief A convenience function for slaving the Hub to SystemC.

  This function can be used to replace all of the following:
  esc_load(), esc_start().

  \return Non-zero on success.
*/
int esc_initialize();

/*!
  \brief A convenience function for slaving the Hub to SystemC with cmd line args.

  This function can be used to replace all of the following:
  esc_load(), esc_start().

  \param argc The number of cmd line args
  \param argv The array of pointers to char strings of cmd line args
  \return Non-zero on success.
*/
int esc_initialize( int argc, char* argv[] );


/*!
  \class esc_sim_log
  \brief A class for encapsulating XML-format BDW simulation logs.
 */
class esc_sim_log
{
public:
	static esc_sim_log *cur_sim_log;

	//! Constructor -- without path, use default from command line.
	esc_sim_log( const char* path=0 );
	//! Destructor
	~esc_sim_log();

	/*!
	  \brief Closes the log file.
	 */
	void close();

	/*!
	  \brief Opens the log file from the path supplied.
	 */
	bool open();
	/*!
	  \brief Log a message with one of the condition codes to the log file.
	  \param module name of the module that issued the message.
	  \param conditionCode one of esc_note, esc_warning, esc_error, or esc_fatal.
	  \param formatStr format string for the message
	  \return true if the operation succeeded
	 */
	bool log_message( const char *moduleName, int conditionCode,
					  const char *formatStr, ... );
	bool log_message_no_varargs( const char *moduleName, int conditionCode,
								 const char *buf );
	/*!
	  \brief Log a setting of some tag to the log file.
	  \param name the XML tag in the log file
	  \param value the value associated 
	  \return true if the operation succeeded
	 */
	bool log_setting( const char *name, const char *value );
	/*!
	  \brief Mark this log file as having passed a test.
	  \return true if the operation succeeded
	 */
	bool log_pass();
	/*!
	  \brief Mark this log file as having failed a test.
	  \return true if the operation succeeded
	 */
	bool log_fail();
	/*!
	  \brief Log a latency computed by simulation.
	  \param module name of the module that issued the message.
	  \param latency the latency in clock cycles
	  \param label an optional name for this latency
	  \return true if the operation succeeded
	 */
	bool log_latency( const char* module, unsigned long latency, const char* label=0 );
	/*!
	  \brief Log a latency computed by simulation.
	  \param module name of the module that issued the message.
	  \param min_latency the minimum latency in clock cycles
	  \param max_latency the maximum latency in clock cycles
	  \param mean_latency the mean latency in clock cycles
	  \param label an optional name for this latency
	  \return true if the operation succeeded
	 */
	bool log_latency( const char* module, unsigned long min_latency,
					  unsigned long max_latency, double mean_latency,
					  const char* label=0 );
	/*!
	  \brief Log the representation for one instance of a simulated module
	  \param module name of the module being instantiated.
	  \param instance_path the SystemC instance path of the instance.
	  \param representation the BDW representation enum (RTL C++, RTL Verilog, etc.) for this instance
	  \return true if the operation succeeded
	*/
	bool log_representation( const char* module,
							 const char* instance_path,
							 int representation );
	
public:
	char *				p_path;
	qbhSimLogHandle		m_simLog;
};

/*!
  \brief Open the XML simulation log file at the given path.
  \param path path to the log file. If none is given, use the one from the command line.
  \return true if the operation succeeded
 */
bool esc_open_log( const char *path=0 );

/*!
  \brief Open the XML simulation log file using the command line and write execution information to it. Meant to be called from an HDL cosimulation.
  \return true if the operation succeeded
 */
bool esc_start_log();

/*!
  \brief Close the simulation log file.
 */
void esc_close_log();

/*!
  \brief Log a message with one of the condition codes to the current simulation log file.
  \param moduleName name of the module that issued the message.
  \param conditionCode one of esc_note, esc_warning, esc_error, or esc_fatal.
  \param formatStr format string for the message
  \return true if the operation succeeded
*/
bool esc_log_message(  const char *moduleName, int conditionCode,
					   const char *formatStr, ... );

/*!
  \internal
  \brief Log a setting of some tag to the current simulation log file.
  \param name the XML tag in the log file
  \param value the value associated 
  \return true if the operation succeeded
*/
bool esc_log_setting( const char *name, const char *value );

/*!
  \brief Mark the current simulation log file as having passed a test.
  \return true if the operation succeeded
*/
bool esc_log_pass();

/*!
  \brief Mark the current simulation log file as having failed a test.
  \return true if the operation succeeded
*/
bool esc_log_fail();

/*!
  \brief Log a measured latency in the current simulation log.
  \param module name of the module that issued the message.
  \param latency the latency in clock cycles
  \param label an optional name for this latency
  \return true if the operation succeeded
*/
bool esc_log_latency( const char* module, unsigned long latency, const char* label=0 );

/*!
  \brief Log a measured latency in the current simulation log.
  This latency is for the entire simulation, not a specific module.
  \param latency the latency in clock cycles
  \param label an optional name for this latency
  \return true if the operation succeeded
*/
inline bool esc_log_latency( unsigned long latency, const char* label=0 )
	{ return esc_log_latency( 0, latency, label ); }

/*!
  \brief Log a measured latency in the current simulation log.
  \param module name of the module that issued the message.
  \param min_latency the minimum latency in clock cycles
  \param max_latency the maximum latency in clock cycles
  \param mean_latency the mean latency in clock cycles
  \param label an optional name for this latency
  \return true if the operation succeeded
*/
bool esc_log_latency( const char* module, unsigned long min_latency,
				  unsigned long max_latency, double mean_latency,
				  const char* label=0 );

/*!
  \brief Log a measured latency in the current simulation log.
  This latency is for the entire simulation, not a specific module.
  \param min_latency the minimum latency in clock cycles
  \param max_latency the maximum latency in clock cycles
  \param mean_latency the mean latency in clock cycles
  \param label an optional name for this latency
  \return true if the operation succeeded
*/
inline bool esc_log_latency( unsigned long min_latency,
				  unsigned long max_latency, double mean_latency,
				  const char* label=0 )
	{ return esc_log_latency( 0, min_latency, max_latency, mean_latency, label ); }

/*!
  \brief Log the representation for one instance of a simulated module
  \param module name of the module being instantiated.
  \param instance_path the SystemC instance path of the instance.
  \param representation the BDW representation enum (RTL C++, RTL Verilog, etc.) for this instance
  \return true if the operation succeeded
*/
bool esc_log_representation( const char* module,
							 const char* instance_path,
							 int representation );

/*!
 \brief	Gives the command line argument at the given index.

 \param index	The index of the argument to be accessed.  For a standalone program, 
 index 0 gives the name of the executable file and index 1 is the first argument value.
 For a co-simulation, index 0 is an empty string, and index 1 is the first value
 in the "argv" option string.

 The esc_argv() function gives the command-line argument at the given index 
 for either a standalone SystemC program execution, or a Hub-based co-simulation.
 The purpose of the esc_argv() function is to allow command line arguments to be 
 accessed through a common function for either standalone or co-simulation executino.

 The values returned by esc_argv() come from one of the following two sources:

 \li In a standalone SystemC program, the argv value passed to sc_main and from there to sc_initialize().  

 \li In a co-simulation, the arguments specified by the 'argv' option with either the +hubSetOption+ Verilog command line argument, or the hubSetOption() call from HDL.

 For example, if a standalone SystemC program, if the sc_main() function looks like this:

 \code
 int sc_main( int argc, char *argv[] )
 {
 	esc_initialize( argc, argv );
	esc_elaborate();
	sc_start(0);
 }
 \endcode

 Then the values given the argv array passed to sc_main can be accessed at any time using esc_argv().

 In a co-simulation, if values are passed to a Verilog simulation on the command line as follows:

 \code
 vsim +hubSetOption+argv="-out file1 -x"
 \endcode

 Then the individual arguments given for the argv option can be accessed using the esc_argv() function.  In the above example, "argv(1)" gives "file1".

 Clearly, the argv() function is not required for access to command line arguments in a 
 standalone SystemC program, however, by using it, the same SystemC program 
 supports access to command line arguments specified for a co-simulation.

 */
inline const char* esc_argv( int index )
{
	return qbhArgv(index);
}

/*!
 \brief	Gives the entire set of command line arguments.

 The esc_argv() function gives the command-line argument at the given index 
 for either a standalone SystemC program execution, or a Hub-based co-simulation.
 See esc_argv(int) for details on how to specify the arguments given by esc_argv().

 Unlike esc_argv(int), esc_argv() returns an array of strings rather than a string
 at a particular index.  This makes it suitable for direct replacement of the argv
 parameter in an existing C program.
 */
inline const char** esc_argv()
{
	return (const char**)qbhArgvAll();
}

/*!
 \brief	Gives the number of command line arguments.

 The esc_argc() function returns the number of command line parameters passed 
 to either a standalone SystemC program or a co-simulation.  See esc_argv() for
 details.
 */
inline int esc_argc()
{
	return qbhArgc();
}

/*!
 \brief	True if SystemC is running as a slave to the Hub.

 During a standalone SystemC program execution, esc_is_slave() will return false.
 During a co-simulation, or any other execution scenario in which SystemC is 
 slaved to the Hub, esc_is_slave() returns true.
 */
inline bool esc_is_slave()
{
	return !esc_hub::m_systemc_is_master;
}

/*!
 \brief	Ends either a standalone or a a co-simulation.

 If a co-simulation is running, and SystemC has been loaded as a slave shared
 library, then esc_end_cosim() is called.  Otherwise, sc_stop() is called.
 */
void esc_stop();

/*!
  \brief Used to determine when both SystemC and the Hub have been initialized
  \return The sc_event that will be triggered when everything has been initialized (ie post sc_initialize()).
*/
sc_event &esc_init_event();


/*! \internal
 */
int esc_init_exceptions();

/*! 
  \brief Returns the value of a Hub define.
  \param define_name The name of the Hub define to return.
  \return The value of the define if it exists, 0 if not.

  Hub \em defines are name/value pairs that can be specified in several ways:

  \li Using +qbDefine+name=value or +hubSetOption+name=value on the Verilog simulator command line.

  \li Using qbDefine(name,value) or hubDefine(name,value) from a Verilog or VHDL program.

  \li Using a -Dname=value on the hubexec command line.

  \li Using a -Dname=value on a standalone SystemC program command line.  

  \li Using a 'define name = "value";' statement in a RAVE program.

  This function returns the value of such a define if it exists.  

  For a standalone SystemC program, the argc and argv values passed to sc_main 
  must be passed to esc_initialize() in order for the -D command line arguments
  to be available via esc_get_hub_define().  Using esc_get_hub_define() to get
  options into a standalone SystemC program allows the same program to more easily
  support both standalone execution and co-simulation.  The esc_argv() function 
  provides another similar method.
 */
const char *esc_get_hub_define( const char *define_name );

template <class T>
class esc_watchable;
template <class T>
class esc_watcher;

/*!
  \class esc_hub_namespace
  \brief Can be used to traverse the namespace of any domain
*/
class esc_hub_namespace
{
 public:
							/*!
							  \brief Constructor
							  \param domainName The name of the domain to traverse, capitalization is ignored
							*/
							esc_hub_namespace(const char* domainName )
								{
									if ( domainName && *domainName )
										m_domainName_p = strdup(domainName);
									else
										m_domainName_p = NULL;
								}
							//! Destructor
							~esc_hub_namespace()
								{
									if ( m_domainName_p )
										free(m_domainName_p);
								}

							/*!
							  \brief Finds the named element in the namespace.
							  \param name The full name of the element to find.  Should not be domain-prefixed.
							  \return A qbhNetlistHandle for the named element, or qbhEmptyHandle if it fails.

							  The returned qbhNetlistHandle can be used with the qbhNetlist*() functions
							  defined in capicosim.h, and can be used to further iterate through the namespace.
							*/
	qbhNetlistHandle		find( char *name )
								{
									qbhNetlistHandle retval = qbhEmptyHandle;
									qbhError status = qbhOK;

									if ( name && *name )
										status = qbhNetlistFind( name, m_domainName_p, 
																 qbhEmptyHandle, &retval, qbhNetlistUnknown );

									if ( status == qbhOK )
										return retval;
									else
									{
										esc_report_error( esc_error, "Couldn't find element named: %s", name );
										return qbhEmptyHandle;
									 }
								}

							/*!
							  \brief Returns the topmost node in the namespace.
							  \return The handle for the topmost node, or qbhEmptyHandle if there was a problem.
							*/
	qbhNetlistHandle 		top()
								{
									qbhNetlistHandle retval = qbhEmptyHandle;
									qbhError status = qbhOK;
									if ( m_domainName_p )
										status = qbhNetlistGetTop( m_domainName_p, &retval );

									if ( status != qbhOK )
										retval = qbhEmptyHandle;
			
									return retval;
								}

							/*!
							  \brief Returns the next topmost node in the namespace.
							  \return The handle for the next topmost node, or qbhEmptyHandle if there wasn't one.
							*/
	qbhNetlistHandle		next_top(qbhNetlistHandle sibling)
								{
									qbhNetlistHandle retval = sibling;
									qbhError status = qbhOK;
									if ( m_domainName_p )
										status = qbhNetlistSibling( qbhEmptyHandle, &retval );

									if ( status != qbhOK )
										retval = qbhEmptyHandle;

									return retval;
								}

							/*!
							  \brief Returns the first child of the given node
							  \param parent The qbhNetlistHandle of the parent node
							  \return The handle of the first child, or qbhEmptyHandle if there were no children.
							*/
	qbhNetlistHandle 		child(qbhNetlistHandle parent)
								{
									qbhNetlistHandle retval = qbhEmptyHandle;
									qbhError status = qbhOK;
									if ( m_domainName_p )
										status = qbhNetlistChild( parent, &retval );

									if ( status != qbhOK )
										retval = qbhEmptyHandle;
			
									return retval;
								}

							/*!
							  \brief Returns the parent of the given node
							  \param child The qbhNetlistHandle of the child node
							  \return the handle of the parent, or qbhEmptyHandle if there is no parent
							*/
	qbhNetlistHandle 		parent(qbhNetlistHandle child)
								{
									qbhNetlistHandle retval = qbhEmptyHandle;
									qbhError status = qbhOK;
									if ( m_domainName_p )
										status = qbhNetlistParent( child, &retval );

									if ( status != qbhOK )
										retval = qbhEmptyHandle;

									return retval;
								}

							/*!
							  \brief Returns the next sibling of the given node.
							  \param parent The parent of the two siblings
							  \param sibling The child of parent, and reference for the next sibling.
							  \return The next sibling, or qbhEmptyHandle if there are no further siblings.
							*/
	qbhNetlistHandle 		sibling(qbhNetlistHandle parent, qbhNetlistHandle sibling)
								{
									qbhNetlistHandle retval = sibling;
									qbhError status = qbhOK;
									if ( m_domainName_p )
										status = qbhNetlistSibling( parent, &retval );

									if ( status != qbhOK )
										retval = qbhEmptyHandle;

									return retval;
								}

							/*!
							  \brief Iterates through the entire namespace, and dumps the name, path and type for each node.
							  \param filename The name of the file to dump to.  Defaults to namespace.log.
							*/
	void					dump( const char *filename="namespace.log" )
								{
									FILE *logfile = fopen(filename, "w");
									if ( !logfile )
									{
										esc_report_error( esc_error, "Problem opening %s\n", filename );
										return;
									}

									qbhNetlistHandle node=qbhEmptyHandle;

									// Retrieves the first top-level node
									node = top();
			
									sc_plist<qbhNetlistHandle> stack;


									// Add all the top-level nodes to the stack
									while ( node != qbhEmptyHandle )
									{
										stack.push_front(node);
										
										// next_top() will return null when there are no further nodes
										node = next_top( node );
									}

									// Visit all the nodes in the tree
									while ( !stack.empty() )
									{
										node = stack.pop_front();
										qbhNetlistHandle iter = qbhEmptyHandle;

										if ( node != qbhEmptyHandle )
										{
											char *name=NULL;
											char *path=NULL;
											qbhNetlistNodeType nodetype = qbhNetlistUnknown;
											qbhTypeHandle datatype = qbhEmptyHandle;
											
											// Refer to capicosim.h for a list of functions that 
											//   can be called with a qbhNetlistHandle
											qbhNetlistGetName( node, &name );
											qbhNetlistGetPath( node, &path );
											qbhNetlistGetType( node, &nodetype, &datatype );
					
											if ( datatype == qbhEmptyHandle )
												fprintf(logfile,"Name:%s\tPath:%s\tType:%d\n",name,path,nodetype );
											else
											{
												qbhTypeInfoStruct info_struct;
												qbhGetTypeInfo( datatype, &info_struct );
												fprintf(logfile,"Name:%s\tPath:%s\tType:%d\tDatatype:%s\n",
														name,path,nodetype,info_struct.name );
											}
										}

										// child() returns the first child of the specified node
										iter = child( node );

										while( iter != qbhEmptyHandle )
										{
											stack.push_front(iter);

											// sibling() returns the next sibling of the specified node
											iter = sibling( node, iter );
										}
									}
									fclose(logfile);
								}

 protected:
	char *					m_domainName_p;
};

/*!
  \brief Return a pseudo-random number from a global, platform-independent generator.

  Creates the generator if it doesn't yet exist.
 */
int esc_rand( void );

/*!
  \brief Seed the global, platform-independent pseudo-random number generator.

  Creates the generator if it doesn't yet exist.
  If the generator has already been created, it will be replaced with a new one with
  the given seed.
 */
void esc_srand( unsigned int seed );

void esc_log_wrapper_inst( const char* modName ) ;

#else

/*
 * Declarations of esc functions are here without HUB defined for bdw_extract.
 * For a description of each function please see above.
 */
inline int esc_start() {return 0;}
inline int esc_initialize() {return 0;}
inline int esc_initialize( int argc, char* argv[] ) {return true;}
inline bool esc_open_log( const char *path=0 ) {return true;}
inline bool esc_start_log() {return true;}
inline void esc_close_log() {}
inline bool esc_log_message(  const char *moduleName, int conditionCode,
					   const char *formatStr, ... ) {return true;}
inline bool esc_log_setting( const char *name, const char *value ) {return true;}
inline bool esc_log_pass() {return true;}
inline bool esc_log_fail() {return true;}
inline bool esc_log_latency( const char* module, unsigned long latency, const char* label=0 ) {return true;}
inline bool esc_log_latency( const char* module, unsigned long min_latency,
				  unsigned long max_latency, double mean_latency,
				  const char* label=0 ) {return true;}
inline bool esc_log_representation( const char* module,
							 const char* instance_path,
							 int representation ) {return true;}

inline const char* esc_argv( int index )
{
	return "";
}

inline const char** esc_argv()
{
	static const char** s = {0};
	return s;
}

inline int esc_argc()
{
	return 0;
}

inline bool esc_is_slave()
{
	return false;
}
inline void esc_stop() 
{
	sc_stop();
}

inline int esc_rand(void) {return 0;}
inline void esc_srand(unsigned int seed) {}

inline void esc_log_wrapper_inst( const char* modName ) {}

inline int esc_init_exceptions() {return 0;}
#endif

extern bool esc_elaboration_errors;

#endif
