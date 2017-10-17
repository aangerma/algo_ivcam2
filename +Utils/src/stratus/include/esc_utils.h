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

#ifndef ESC_UTILS_HEADER_GUARD__
#define ESC_UTILS_HEADER_GUARD__

/*!
  \file esc_utils.h
  \brief This file defines helper functions, classes, and defines for ESC.
*/

/*! 
  \brief Provides printf functionality through the Hub if it is present

  The esc_printf function is identical to the system printf() function,
  except that if the Hub is part of the current execution environment, 
  the output is routed through the Hub.  If the Hub is executing in a logic
  simulator, this results in the message being routed out of the logic
  simulator's transcript.  If the Hub is not present, then the system printf() 
  is called.
*/
#if BDW_HUB
#define esc_printf qbhPrintf
#else
#define esc_printf printf
#endif

/*!
  \brief Used to determine the ESC version.
  \return A const char* of the form "ESC version - X.XX"

  The version of the compiled ESC library can be determined by executing
  the following command:
  <br>
  \code
  cd $QBDIR/lib ; strings libesc.<ext> | grep "ESC version"
  \endcode
*/
const char* esc_version();

/*!
  \brief Converts an sc_time to double with picosecond time units
  \param t An sc_time with any time unit that will be converted
  \return A double that represents the sc_time in picoseconds

  All times sent to or from the Hub must be in picoseconds.  This function
  can be useful when sending a time as a parameter to RAVE, or to a BFM
  in HDL.
*/
inline
double esc_normalize_to_ps( const sc_time &t )
{
	// Means that sc_set_time_resolution() can't be greater than 1 SC_PS
	// Must be done to determine what time resolution is currently in use
	static double ref = sc_time(1, SC_PS).to_double();

	double retval=t.to_double();

	retval /= ref;

	return retval;
}

/*!
  \brief Converts an sc_time to double with picosecond time units
  \param t An sc_time with any time unit that will be converted
  \return A douple that represents the sc_time in picoseconds

  All times sent to or from the Hub must be in picoseconds.  This function
  can be useful when sending a time as a parameter to RAVE, or to a BFM
  in HDL.
*/
inline
double esc_normalize_to_ps( sc_time &t )
{
	return esc_normalize_to_ps( (const sc_time &)t );
}

typedef unsigned short esc_event_type; /*! Datatype for combinations of ESC_*_EVENTs */
#define ESC_NO_EVENT			0x0000	/*!< Indicates that there is no relevant event. */
#define ESC_CHANGED_EVENT		0x0001	/*!< Indicates that a duration-free value change event. */
#define ESC_WRITE_START_EVENT	0x0002	/*!< Indicates the start of a write operation with duration. */
#define ESC_WRITE_END_EVENT		0x0004	/*!< Indicates the end of a write operation with duration. */
#define ESC_READ_START_EVENT	0x0008	/*!< Indicates the start of a read operation with duration.  */
#define ESC_READ_END_EVENT		0x0010	/*!< Indicates the end of a read operation with duration.  */
#define ESC_ALL_EVENTS			(ESC_CHANGED_EVENT | ESC_WRITE_START_EVENT | ESC_WRITE_END_EVENT | ESC_READ_START_EVENT | ESC_READ_END_EVENT) /*!< Indicates all possible events, often used as a default value. */

//! A convenience macro that gives the current SystemC time as a string.
#if ( defined(SC_API_VERSION_STRING) || defined(BDW_COWARE) )
#define ESC_CUR_TIME_STR ( sc_time_stamp().to_string().c_str() )
#else
#define ESC_CUR_TIME_STR ( (const char *)sc_time_stamp().to_string() )
#endif

#if BDW_HUB || defined STRATUS
extern "C" {
extern char* esc_realtime();
}
#else
inline char* esc_realtime()
{
  return (char*)ESC_CUR_TIME_STR;
}
#endif

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
void esc_close_open_loggers();


#if TRANS_VECTOR

#include <vector>	// Needs access to STL vector

#endif // TRANS_VECTOR

/*!
  \class esc_vector
  \brief A templated vector class.

  This class can be used in place of std::vector<> on win32, where SystemC and VC60 won't
  allow use of the STL.  This class is only included if TRANS_VECTOR is not defined.
*/
template < class T >
class esc_vector
{
 public:
	typedef T* iterator;
	typedef const T* const_iterator;

					/*!
					  \brief Contructor
					  \param capacity The initial size of the vector
					*/
					esc_vector( unsigned int capacity = 10 )
						{
							m_data_p	= new T[capacity];
							m_capacity	= 10;
							m_size		= 0;
						}

					/*!
					  \brief Constructor
					  \param other Another esc_vector that should have its contents copied into the new esc_vector
					*/
					esc_vector( const esc_vector<T>& other )
						{
							m_data_p	= 0;
							m_capacity	= 0;
							m_size		= 0;

							*this = other;
						}

					//! Destructor
					~esc_vector()
						{
							delete[] m_data_p;
						}

					/*!
					  \brief Sets the contents of this esc_vector to the contents of the other esc_vector
					  \param other The other esc_vector that will be copied into this esc_vector
					*/
	esc_vector<T> & operator=( const esc_vector<T>& other )
						{
							if ( this == &other )             // same
								;
							else if ( other.capacity() > capacity() ) // other is larger
							{
								reserve( other.capacity() );
								for( int i=0;i<other.m_size;i++ )
									m_data_p[i] = other.m_data_p[i];
								m_size = other.m_size;
							}
							else if ( other.capacity() <= capacity() ) // other is smaller
							{
								clear();
								for( int i=0;i<other.m_size;i++ )
									m_data_p[i] = other.m_data_p[i];
								m_size = other.m_size;
							}

							return *this;
						}			

						/*!
						  \brief Will increase the size of the vector if necessary
						  \param capacity Makes sure the esc_vector has at least this number of entries
						*/
	void			reserve( unsigned int capacity )
						{
							if ( capacity > m_capacity )
							{
								T* data = new T[capacity];
								if ( m_capacity > 0 )
								{
									memcpy( data, m_data_p, m_capacity*sizeof(T) );
									delete[] m_data_p;
								}
								m_capacity = capacity;
								m_data_p = data;
							}
						}

						/*!
						  \brief Used to determine the number of entries in the esc_vector
						  \return An unsigned int representing the number of entries
						*/
	unsigned int	capacity() const
						{ return m_capacity; }

						/*!
						  \brief Used to iterate through the elements of the vector
						  \return An iterator pointing to the first element in the esc_vector
						*/
	iterator		begin()
						{ return (iterator) m_data_p; }

						/*!
						  \brief Used to iterate through the elements of the vector
						  \return A const_iterator pointing to the first element in the esc_vector
						*/
	const_iterator	begin() const
						{ return (const_iterator) m_data_p; }

						/*!
						  \brief Used to determine the end of the esc_vector
						  \return An iterator pointing to the element after the last entry in the esc_vector
						*/
	iterator		end()
						{ return (iterator)(m_data_p + m_size); }

						/*!
						  \brief Used to determine the end of the esc_vector
						  \return A const_iterator pointing to the element after the last entry in the esc_vector
						*/
	const_iterator	end() const
						{ return (const_iterator)(m_data_p + m_size); }

	// UNIMPLEMENTED
	void			resize( unsigned int size, const T& = T() )
						{}

						/*!
						  \brief Returns the number of elements used in the esc_vector
						  \return An unsigned int representing the number of elements used
						*/
	unsigned int	size() const
						{ return m_size; }

	// UNIMPLEMENTED
	unsigned int	max_size() const
						{ return 30000; }

						/*!
						  \brief Used to determine whether the esc_vector has any elements used
						  \return A bool that is true if the esc_vector has no elements used
						*/
	bool			empty() const
						{ return size() == 0; }

						/*!
						  \brief Returns a reference to the element at the specified index
						  \param index The index of the element to return
						  \return A reference to the element at the specified index
						*/
	T&				at( unsigned int index )
						{
							if ( index >= m_size )
							{ 
								// should throw an exception
								
								return *(T*)NULL;
							}

							return m_data_p[index];
						}

						/*!
						  \brief Returns a const reference to the element at the specified index
						  \param index The index of the element to return
						  \return A const reference to the element at the specified index
						*/
	const T&		at( unsigned int index ) const
						{
							if ( index >= m_size )
							{ 
								// should throw an exception
								
								return *(T*)NULL;
							}

							return m_data_p[index];
						}

						/*!
						  \brief Returns a reference to the element at the specified index
						  \param index The index of the element to return
						  \return A reference to the element at the specified index
						*/
	T&				operator[]( unsigned int index )
						{ 
							if ( index >= m_size )
							{
								if ( index + 1 > m_capacity )
									reserve( index + 11 );
								m_size = index + 1;
							}
							return m_data_p[index];
						}

						/*!
						  \brief Returns a const reference to the element at the specified index
						  \param index The index of the element to return
						  \return A const reference to the element at the specified index
						*/
	const T&		operator[]( unsigned int index ) const
						{ return *(const T*)&operator[](index); }


						/*!
						  \brief Used to iterate through the elements of the vector
						  \return An iterator pointing to the first element in the esc_vector
						*/
	iterator		front()
						{ return (iterator) begin(); }

						/*!
						  \brief Used to iterate through the elements of the vector
						  \return A const_iterator pointing to the first element in the esc_vector
						*/
	const_iterator	front() const
						{ return (const_iterator) begin(); }

						/*!
						  \brief Used to determine the end of the esc_vector
						  \return An iterator pointing to the element after the last entry in the esc_vector
						*/
	iterator		back()
						{ return (iterator)(end()-1); }

						/*!
						  \brief Used to determine the end of the esc_vector
						  \return A const_iterator pointing to the element after the last entry in the esc_vector
						*/
	const_iterator	back() const
						{ return (const_iterator)(end()-1); }

						/*!
						  \brief Pushes the specified element to the back of the list
						  \param item The element to be added
						*/
	void			push_back( T item )
						{
							if ( m_size == m_capacity )
								reserve( m_size + 11 );
							m_data_p[m_size++] = item;
						}

						/*!
						  \brief Removes the last element in the list
						*/
	void			pop_back()
						{
							m_size--;
						}

	// UNIMPLEMENTED
	void			assign( iterator first, iterator last )
						{}

	// UNIMPLEMENTED
	void			assign( unsigned int number, T item )
						{}

						/*!
						  \brief Inserts the specified item before the specified element
						  \param iter The reference element
						  \param item The element to be added
						  \return An iterator pointing to the added element
						*/
	iterator		insert( iterator iter, T item )
					{ 
						if ( empty() || (iter == end()) )
						{
							push_back( item );
							m_size++;
							return back();
						}
						else
						{
							reserve( m_size+1 );
							memmove( iter+1, iter, (end()-iter)*sizeof(T) );
							*iter = item;
							m_size++;
							return iter;
						}
					}

	// UNIMPLEMENTED
	void			insert( iterator iter, unsigned int number, T item )
						{}

	// UNIMPLEMENTED
	void			insert( iterator iter, const_iterator first, const_iterator last )
						{}

						/*!
						  \brief Remove the specified element
						  \param iter The element to be removed
						*/
	void			erase( iterator iter )
					{
						if ( iter == back() )
							pop_back();
						else
						{
							memmove( iter, iter+1, (end()-iter)*sizeof(T) );
							m_size--;
						}
					}
	// UNIMPLEMENTED
	void			erase( iterator first, iterator last )
						{}

						//! Remove all the elements.  Makes the size 0, but leaves capacity unchanged
	void			clear()
						{
							m_size = 0;
						}

	// UNIMPLEMENTED
	bool			_Eq( const esc_vector<T> &other ) const
						{
							return 0;
						}

	// UNIMPLEMENTED
	bool			_Lt( const esc_vector<T> &other ) const
						{
							return 0;
						}

 private:
	unsigned int	m_capacity;
	unsigned int	m_size;
	T *				m_data_p;
};

#endif // ESC_UTILS_HEADER_GUARD__
