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

#ifndef ESC_RAN_HEADER_GUARD__
#define ESC_RAN_HEADER_GUARD__

#if BDW_HUB

/*!
  \file esc_ran.h
  \brief This file defines the interfaces of the esc_ran_dist and esc_ran_gen classes, which provide random number generation services.

  For more information about how to use random distributions in SystemC, refer to the ESC User's Guide.
*/

#include "qbhCapi.h"
#include "capicosim.h"


//------------------------------------------------------------------------------
// esc_ran_dist class interface
//------------------------------------------------------------------------------

//! Enumeration of the random distribution types
enum esc_ran_dist_type
{
	crd_ran_none = 0,		//!< No distribution
	crd_ran_uniform = 1,	//!< Uniform distribution
	crd_ran_exponential = 2,//!< Exponential distribution
	crd_ran_normal = 3,		//!< Normal (Gaussian) distribution
	crd_ran_chisq = 4,		//!< Chi-squared distribution
	crd_ran_gamma = 5,		//!< Gamma distribution
	crd_ran_poisson = 6,	//!< Poisson distribution
	crd_ran_discrete = 7	//!< Discrete distribution
};

/*!
  \class esc_ran_dist
  \brief Base class for random number distribution classes
*/
class esc_ran_dist 
{
public:


	/*!
	  \brief Constructor
	  \param name The name of a distribution in this or another domain
	*/
	inline esc_ran_dist( char* name ):
		m_name( strdup(name) ),
		m_handle( esc_empty_handle )
		{
			initialize();
		}

	/*!
	  \brief Constructor
	  \param type The type of distribution
	*/
	inline esc_ran_dist( esc_ran_dist_type type,
					  double param=0.0,
					  double scale=0.0, 
					  double* prob_array=(double*)0,
					  unsigned probs=0 ):
	m_name( (char*)0 ),
	m_type( type ),
	m_param( param ),
	m_scale( scale ),
	m_prob_array( prob_array ),
	m_probs( probs ),
	m_handle( esc_empty_handle )
		{
			initialize();
		}

	//! Destructor
	inline ~esc_ran_dist()
	{
		if( m_name )
			delete m_name;
		if ( m_handle != esc_empty_handle )
			qbhDestroyHandle( m_handle );
		m_handle = esc_empty_handle;
	}

	/*!
	  \brief Accessor for the distribution handle
	  \return The handle of the distribution
	*/
	inline qbhRanDefHandle	get_handle() const { return m_handle; }
	/*!
	  \brief Accessor for the value of the distribution parameter
	  \return The distribution parameter value
	*/
	inline double			get_param() const { return m_param; }
	/*!
	  \brief Accessor for the distribution probability array
	  \return The distribution probability array
	*/
	inline double*			get_prob_array() const { return m_prob_array; }
	/*!
	  \brief Accessor for the probabilty array size
	  \return The size of the probabilty array
	 */
	inline unsigned			get_probs() const { return m_probs; }
	/*!
	  \brief Accessor for the distribution scale
	  \return The distribution scale
	*/
	inline double			get_scale() const { return m_scale; }
	/*!
	  \brief Accessor for the distribution type
	  \return The distribution type
	 */
	inline esc_ran_dist_type	get_type() const { return m_type; }

protected:

	// Protected member functions:
	inline void initialize()
	{
		// If the distribution of the given name has already 
		// been defined in another domain, use that handle:
		if( m_name )
		{
			m_last_error = qbhFindRanDist( m_name, &m_handle );
			if ( m_last_error != qbhOK )
				esc_report_error( esc_error, "Failed to initialize esc_ran_dist '%s': %s\n", m_name, qbhErrorString( m_last_error ) );
		}

		// Otherwise, create a new random distribution object:
		else	
		{
			// Get a HUB handle for this object:
			m_last_error = qbhCreateRanDist( m_name,
											 (unsigned)m_type,
											 m_param,
											 m_scale,
											 m_prob_array,
											 m_probs,
											 &m_handle );
			if ( m_last_error != qbhOK )
				esc_report_error( esc_error, "Failed to initialize esc_ran_dist '%s': %s\n", m_name, qbhErrorString( m_last_error ) );
		}
	}

	// Attributes
	char*				m_name;			// Dist name
	esc_ran_dist_type	m_type;			// Distribution type
	double				m_param;		// Distribution parameter value
	double				m_scale;		// Distribution scale value
	double*				m_prob_array;	// Distribution probability array
	unsigned			m_probs;		// Size of probability array
	qbhRanDefHandle		m_handle;		// HUB handle for this dist instance
	qbhError			m_last_error;	// Error holder
};

//------------------------------------------------------------------------------
// esc_ran_dist derived class interfaces
//------------------------------------------------------------------------------

/*!
  \class esc_ran_dist_uniform
  \brief Uniform Distribution
 */
class esc_ran_dist_uniform: public esc_ran_dist
{
public:

	/*!
	  \brief Constructor
	  \param name The name of a distribution in this or another domain
	*/
	esc_ran_dist_uniform( char* name ):
		esc_ran_dist( name )
	{}
	//! Constructor
	esc_ran_dist_uniform( double scale=0.0 ):
		esc_ran_dist( crd_ran_uniform, scale )
	{}
};

/*!
  \class esc_ran_dist_exponential
  \brief Exponential Distribution
*/
class esc_ran_dist_exponential: public esc_ran_dist
{
public:

	/*!
	  \brief Constructor
	  \param name The name of a distribution in this or another domain
	*/
	esc_ran_dist_exponential( char* name ):
		esc_ran_dist( name )
	{}
	//! Constructor
	esc_ran_dist_exponential( double scale=0.0 ):
		esc_ran_dist( crd_ran_exponential, scale )
	{}
};

/*!
  \class esc_ran_dist_normal
  \brief Normal Distribution
 */
class esc_ran_dist_normal: public esc_ran_dist
{
public:

	/*!
	  \brief Constructor
	  \param name The name of a distribution in this or another domain
	*/
	esc_ran_dist_normal( char* name ):
		esc_ran_dist( name )
	{}
	//! Constructor
	esc_ran_dist_normal( double scale=0.0 ):
		esc_ran_dist( crd_ran_normal, scale )
	{}
};

/*!
  \class esc_ran_dist_chisq
  \brief Chi Squared Distribution
 */
class esc_ran_dist_chisq: public esc_ran_dist
{
public:

	/*!
	  \brief Constructor
	  \param name The name of a distribution in this or another domain
	*/
	esc_ran_dist_chisq( char* name ):
		esc_ran_dist( name )
	{}
	//! Constructor
	esc_ran_dist_chisq( double param=0.0,
					double scale=0.0 ):
		esc_ran_dist( crd_ran_chisq, param, scale )
	{}
};

/*!
  \class esc_ran_dist_gamma
  \brief Gamma Distribution
 */
class esc_ran_dist_gamma: public esc_ran_dist
{
public:

	/*!
	  \brief Constructor
	  \param name The name of a distribution in this or another domain
	*/
	esc_ran_dist_gamma( char* name ):
		esc_ran_dist( name )
	{}
	//! Constructor
	esc_ran_dist_gamma( double param=0.0,
					double scale=0.0 ):
		esc_ran_dist( crd_ran_gamma, param, scale )
	{}
};

/*!
  \class esc_ran_dist_poisson
  \brief Poisson Distribution
 */
class esc_ran_dist_poisson: public esc_ran_dist
{
public:

	/*!
	  \brief Constructor
	  \param name The name of a distribution in this or another domain
	*/
	esc_ran_dist_poisson( char* name ):
		esc_ran_dist( name )
	{}
	//! Constructor
	esc_ran_dist_poisson( double param=0.0,
					  double scale=0.0 ):
		esc_ran_dist( crd_ran_poisson, param, scale )
	{}
};

/*!
  \class esc_ran_dist_discrete
  \brief Discrete Distribution
 */
class esc_ran_dist_discrete: public esc_ran_dist
{
public:

	/*!
	  \brief Constructor
	  \param name The name of a distribution in this or another domain
	*/
	esc_ran_dist_discrete( char* name ):
		esc_ran_dist( name )
	{}
	/*!
	  \brief Constructor
	  \param prob_array An array of doubles, can contain any number of doubles, but their sum must equal 1
	  \param probs The number of elements in the array prob_array
	*/
	esc_ran_dist_discrete( double* prob_array=(double*)0,
					   unsigned probs=0 ):
		esc_ran_dist( crd_ran_discrete, 0.0, 0.0, prob_array, probs )
	{}
};

/*!
  \brief Accessor for the global ranbase.
  \return The current global ranbase value.
*/
inline unsigned	esc_get_ranbase()
{
	int rb;
	qbhGetRanbase( &rb );
	return rb;
}


/*!
  \brief Allows setting the global ranbase.
  \param new_base The new global ranbase value as an unsigned

  Sets the HUB's current ranbase value.  
  The seeding of all subsequently-constructed rangen instances
  connected to the HUB will be affected by the new ranbase.
*/
inline void	esc_set_ranbase( unsigned new_base )
{
	qbhSetRanbase( new_base );
}


/*!
  \class esc_ran_gen
  \brief Class for random number generation

  Templated on the data type that it will be producing.

  For more information about how to generate random values using esc_ran_gen,
  refer to the ESC User's Guide.
*/
template< class T >
class esc_ran_gen 
{
public:

	/*!
	  \brief Constructor
	  \param dist Reference to a random distribution object
	  \param seed_index A seed index
	 */
	inline esc_ran_gen( const esc_ran_dist& dist,
					 unsigned seed_index ):
	m_dist_handle( dist.get_handle() ),
	m_seed_index( seed_index ),
	m_seed_str( (char*)0 )
	{
		initialize();
	}

	/*!
	  \brief Constructor
	  \param dist Reference to a random distribution object
	  \param seed_str A string from which a seed will be generated.  
	  If seed_str is omitted, then a seed will be chosen automatically, but there is no
	  guarantee that the same seed will be used in a future execution.
	 */
	inline esc_ran_gen( const esc_ran_dist& dist,
					 const char* seed_str=0 ):
	m_dist_handle( dist.get_handle() ),
	m_seed_index( 0 ),
	m_seed_str( strdup( seed_str ? seed_str : sc_get_curr_simcontext()->gen_unique_name("esc_ran_gen") ) )
	{
		initialize();
	}

	/*!
	  \brief Constructor
	  \param seed_str A string from which a seed will be generated.
	  If seed_str is omitted, then a seed will be chosen automatically, but there is no
	  guarantee that the same seed will be used in a future execution.
	 */
	inline esc_ran_gen( const char* seed_str=0 ):
	m_seed_index( 0 ),
	m_seed_str( strdup( seed_str ? seed_str : sc_get_curr_simcontext()->gen_unique_name("esc_ran_gen") ) )
	{
		esc_ran_dist_uniform dist;
		m_dist_handle = dist.get_handle();
		initialize();
	}

	//! Destructor
	inline ~esc_ran_gen()
	{
		if( m_seed_str != (char*)0 )
			free(m_seed_str);
	}

	// Member functions
	/*!
	  \brief Accessor for the distribution handle
	  \return The distribution handle
	 */
	qbhRanDefHandle			get_dist_handle()
							{ return m_dist_handle; }
	/*!
	  \brief Accessor for the generation handle
	  \return The generation handle
	*/
	qbhRanGenHandle			get_gen_handle()
							{ return m_gen_handle; }
	/*!
	  \brief Accessor for the seed string
	  \return The seed string
	 */
	char*					get_seed()
							{ return m_seed_str; }
	/*!
	  \brief Accessor for the type handle
	  \return The handle for the value type
	 */
	qbhTypeHandle			get_type_handle()
							{ return m_type_handle; }

	// Random number member functions
	/*!
	  \brief Generates a random value
	  \return The generated value
	*/
	inline T				generate();

	/*!
	  \brief Generate a random integer value within a given range.
	  \param lower_bound The lower bound
	  \param upper_bound The upper bound
	  \return The generated integer value
	*/
	inline int				generate( int lower_bound,
									  int upper_bound );

	/*! 
	  \brief	Cast operator

	  The cast operator allows a random generator to be used where a value
	  of type T is required, resulting in a random value being generated.

	  For example:
	  \code
	  esc_ran_gen<int> ranints("ranints");
	  int ranval = ranints;
	  \endcode
	  In this example, a random integer value will be generated and assigned
	  to the variable 'ranval'.
	*/
							operator T ()
							{ return generate(); }
private:

	// Private member functions
	// Initialize this object by getting a valid HUB handle for
	// a random generator value type.
	inline void			initialize()
	{
		T sc_type;

		// Get the HUB type handle:
		m_type_handle = HubGetType( &sc_type );

		// Get a HUB handle for this object:
		m_last_error = qbhCreateRanGen( m_dist_handle,
										m_seed_index,
										m_seed_str,
										&m_gen_handle );
		if ( m_last_error != qbhOK )
			esc_report_error( esc_error, "Failed to initialize esc_ran_gen: %s\n", qbhErrorString( m_last_error ) );
	}


	// Attributes
	qbhRanDefHandle		m_dist_handle;	// HUB handle for our dist type 
	qbhRanGenHandle		m_gen_handle;	// HUB handle for this gen instance
	qbhError			m_last_error;	// Error holder
	unsigned			m_seed_index;	// Seed index
	char*				m_seed_str;		// Seed string
	qbhTypeHandle		m_type_handle;	// HUB type handle for this value type
};

//------------------------------------------------------------------------------
// esc_ran_gen class implementation
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// esc_ran_gen::generate
//
// Generate a random value.
//------------------------------------------------------------------------------
template< class T >
inline T
esc_ran_gen<T>::generate()
{
	qbhValueHandle value_handle;
	T ran_value;

	// Get a random value of the given type:
	m_last_error = qbhGetRandomValue( m_gen_handle,
									  m_type_handle,
									  0,
									  0,
									  &value_handle );

	// Convert the value from a hub type to a SystemC type:
	HubTransFrom( value_handle, &ran_value );

	qbhDestroyHandle( value_handle );

	// Return the random value:
	return ran_value;
}

//------------------------------------------------------------------------------
// esc_ran_gen::generate
//
// Generate a random integer value within a given range.
//------------------------------------------------------------------------------
template <>
inline int 
esc_ran_gen<int>::generate( int lower_bound, int upper_bound )
{
	int ran_value;

	// If both bounds are 0, return 0:
	if( !lower_bound && !upper_bound )
	{ return 0; }

	// Get a random value of the given type:
	else
	{
		m_last_error = qbhGetRandomIntValue( m_gen_handle,
											  lower_bound,
											  upper_bound,
											  &ran_value );
	}

	// Return the random value:
	return ran_value;
}

//------------------------------------------------------------------------------
// esc_ran_gen::generate
//
// Generate an error message if this function is called on a data
// type other than integer.
//------------------------------------------------------------------------------
template< class T >
inline int 
esc_ran_gen<T>::generate( int lower_bound, int upper_bound )
{
	esc_report_error( esc_error, "ERROR: esc_ran_gen::generate() called with bounds for\na data type other than integer.\n");

	return 0;
}

#endif

#endif
