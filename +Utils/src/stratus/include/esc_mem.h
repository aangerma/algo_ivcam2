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

#ifndef ESC_MEM_HEADER_GUARD__
#define ESC_MEM_HEADER_GUARD__

/*!
  \file esc_mem.h
  \brief Classes and functions for Hub memory access

  For more information about how to use memories in SystemC, refer to the ESC User's Guide.
*/

/*!
  \class esc_mem_tx
  \brief Container class for information about a memory transaction

  Templated on the word size, and the access datatype - sc_uint<>/sc_biguint<>/etc
*/
template < class T_WORD >
class esc_mem_tx
{
 public:
	/*!
	  \brief Constructor
	  \param addr The address index
	  \param val The value at the specified index
	*/
							esc_mem_tx( unsigned int addr, T_WORD &val)
								: address( addr ),
								value( val )
							{
							}

	//! Destructor
							~esc_mem_tx()
							{
							}

	unsigned int			address;
	T_WORD &				value;
};



template <class T>
class esc_watchable;

/*!
  \class esc_addressable_if
  \brief Interface for bus and memory accesses.

  Provides read and write operations using integer addressed and an arbitrary data type.
*/
template < class T_WORD >
class esc_addressable_if :	virtual public sc_interface
{
 public:
							/*!
							  \brief Determines whether an address in memory is fully initialized
							  \param address The address to read from
							  \return Non-zero if the address has been initialized.
							*/
	virtual int				is_initialized(unsigned int address)=0;

							/*!
							  \brief Reads from the memory
							  \param address The address to read from
						   	  \param word The value to return.  
							  \return The value read from the address.
							*/
	virtual T_WORD			read( unsigned int address )=0;

							/*! 
							  \brief Writes to the memory
							  \param address The address to write to
							  \param The word to write
							*/
	virtual void			write(unsigned int address, T_WORD value)=0;

};

/*!
  \class esc_addressable_proxy
  \brief Proxy class to forward calls to an esc_addressable_if.

  Deriving from both an esc_memory class and sc_module causes conflicts,
  so sc_modules that wish to provide an esc_addressable_if can inherit from
  this class and own a subclass of esc_addressable_if.  This class will
  forward calls it receives to a given esc_addressable_if.
*/
template < class T_WORD >
class esc_addressable_proxy :	virtual public esc_addressable_if<T_WORD>
{
 public:
							esc_addressable_proxy( esc_addressable_if<T_WORD>& i ) 
								: m_if(i)
							{}

	virtual int				is_initialized(unsigned int address) 
							{
								return m_if.is_initialized( address );
							}

	virtual T_WORD			read( unsigned int address )
							{
								return m_if.read( address );
							}

	virtual void			write(unsigned int address, T_WORD value)
							{
								m_if.write( address, value );
							}
 protected:
	esc_addressable_if<T_WORD>&	m_if;

};

template < class T_WORD >
class esc_memory;

/*!
  \internal
  \brief class is used to allow accesses to memory using mem[addr] = val and val = mem[addr]

  Users will never explicitly use this class
*/
template < class T_WORD >
class esc_mem_accessor
{
 public:
							esc_mem_accessor( esc_memory< T_WORD > *mem, unsigned int addr )
								: m_mem(mem), m_addr(addr)
							{
							}

							~esc_mem_accessor()
							{
								
							}

							operator T_WORD ()
							{
								m_val = m_mem->read( m_addr );

								return m_val;
							}

	T_WORD &				operator=( const T_WORD& other )
							{
								m_mem->write( m_addr, other );

								return (T_WORD&)other;
							}

 private:
	T_WORD					m_val;
	esc_memory< T_WORD > *	m_mem;
	unsigned int			m_addr;
	
};

/*!
  \class esc_memory
  \brief Base class for memories

  Provides read and write operations
*/
template < class T_WORD >
class esc_memory :	public esc_watchable < esc_mem_tx < T_WORD > >,
					public esc_addressable_if< T_WORD >,
					virtual public sc_object
{
 public:
							/*!
							  \brief Constructor
							  \param _address_size The size of the address space
							  \param channame The name of the channel to connect to
							*/
							esc_memory( unsigned int _address_size, const char* channame )
								: esc_watchable< esc_mem_tx< T_WORD > > ( this ),
								sc_object( channame ),
								m_address_size(_address_size)
							{
							}

							//! Destructor
							~esc_memory()
							{
							}

							//! Alows use of mem[addr] = val and val = mem[addr]
	virtual esc_mem_accessor < T_WORD > operator[]( unsigned int address )
							{
								return esc_mem_accessor< T_WORD >( this, address );
							}

							/*!
							  \brief Determines whether an address in memory is fully initialized
							  \param address The address to read from
							  \return Non-zero if the address has no Xs or Zs
							*/
	virtual int				is_initialized(unsigned int address)
							{
								return 0;
							}

							/*!
							  \brief Reads from the esc_hub_memory
							  \param address The address to read from
							  \return The value read from the address.
							*/
	virtual T_WORD			read( unsigned int address )
							{
							}

							/*! 
							  \brief Writes to the esc_hub_memory
							  \param address The address to write to
							  \param The word to write
							*/
	virtual void			write(unsigned int address, T_WORD value)
							{
							}

							//! Used to access the size of the address space
	unsigned int			address_size()
							{
								return m_address_size;
							}
  protected:
	unsigned int			m_address_size;
};


#if BDW_HUB

/*!
  \class esc_hub_memory
  \brief Can be used to connect to an external (Hub/hdl) memory

  Templated on the access datatype - sc_uint<>/sc_biguint<>/etc

  esc_hub_memory connects to an external memory using a channel in RAVE that is
  connected to a memory either in RAVE, or in an HDL simulation.  If 
  'hubsync -ch' is run on a RAVE file that has such a channel, it will
  automatically generate an esc_hub_memory for the channel, and the name of the
  esc_hub_memory instance will be the name of the RAVE channel.

  Because esc_hub_memory is derived from esc_watchable, other objects can watch
  this memory, and receive notifications when the memory is accessed.  The only
  exception to this rule is the use of at(), which is potentially the wrong
  type for the esc_mem_tx.

  ** The user must ensure that T_WORD is a data type that can support at least
  the word size of the memory.
*/
template < class T_WORD >
class esc_hub_memory : public esc_memory< T_WORD >
{
 public:
							/*!
							  \brief Constructor
							  \param channame The name of the channel to connect to
							  \param _address_size The size of the address space
							*/
							esc_hub_memory( unsigned int _address_size, const char* channame )
								: esc_memory< T_WORD > ( _address_size, channame ),
								  m_word_size(-1),
								  m_bitvec(NULL),
								  m_tried_connect(false),
								  m_channel_handle( qbhEmptyHandle )
							{ 
								m_channame = strdup( channame );
								m_val_p = new T_WORD ();
							}

							//! Destructor
							~esc_hub_memory()
							{
								delete m_val_p;
								if ( m_bitvec )
									free(m_bitvec);
								free(m_channame);
							}

							/*!
							  \brief Determines whether an address in memory is fully initialized
							  \param address The address to read from
							  \return Non-zero if the address has no Xs or Zs
							*/
	int						is_initialized(unsigned int address)
							{
								if ( !connected() )
									return 0;

								int veclen = word_size() + 1;
								int retval = 0;

								qbhError status = qbhIndexedGetBitVectorValue( m_channel_handle,
																			   address,
																			   m_bitvec,
																			   &veclen );

								if ( status == qbhOK )
								{
									retval = 1;
									for ( int i=0; retval && i<veclen-1; i++ )
									{
										if ( m_bitvec[i] != '0' && m_bitvec[i] != '1' )
											retval = 0;
									}
								}

								return retval;
							}

							/*!
							  \brief Reads from the esc_hub_memory
							  \param address The address to read from
							  \return The value read from the address.
							*/
	T_WORD					read( unsigned int address )
							{
								if ( !connected() )
									return;

								T_WORD word;
								esc_handle h = this->notify_read_start();

								HubTransFrom( m_channel_handle,
											  &word,
											  address );

								esc_mem_tx< T_WORD > tx(address,word);

								notify_read_end( &tx, h );
								return word;
							}

							/*!
							  \brief Reads from the esc_hub_memory
							  \param address The address to read from
							  \param word The value to return.  Bits that are X or Z are NOT converted.
							  \return Used only to make the signature unique when the memory is templated on sc_lv
							*/
	template < int WSIZE >
	void					at( unsigned int address, sc_lv< WSIZE > &word )
							{
								if ( ! &word || !connected() )
									return;

								HubTransFrom( m_channel_handle,
											  &word,
											  address );
							}

							/*! 
							  \brief Writes to the esc_hub_memory
							  \param address The address to write to
							  \param The word to write
							*/
	void					write(unsigned int address, T_WORD value)
							{
								if ( !connected() )
									return;
								esc_mem_tx< T_WORD > tx(address,value);
									
								esc_handle h = notify_write_start( &tx );

								HubTransTo( (T_WORD*)&value,
											&m_channel_handle,
											address );

								notify_write_end( &tx, h );
							}

	qbhChannelHandle		channel_handle()
							{ return m_channel_handle; }

							//! Returns the word size
	int						word_size()
							{ return m_word_size > 0 ? m_word_size : calc_word_size(); }

	int						calc_word_size()
							{
								if ( !connected() )
									return 0;
								qbhType type;
								qbhTypeHandle type_handle;  // type of the memory
								qbhTypeHandle element_type; // type of the word
								qbhGetChannelType( m_channel_handle, &type_handle, &type );
								qbhIndexedGetValueType( type_handle, 0, NULL, &element_type, NULL );
								qbhGetArraySize( element_type, &m_word_size );

								if ( m_word_size > 0 && !m_bitvec )
									m_bitvec = (char*)malloc(sizeof(char)*(m_word_size+1));

								return m_word_size;
							}

 protected:

	qbhChannelHandle		m_channel_handle; 
	T_WORD *				m_val_p;
	int						m_word_size;
	char *					m_bitvec;
	bool					m_tried_connect;
	char *					m_channame;

	//! \internal
	// Attempts a connection once.  
	// Designed to avoid connection until access is required.
	inline bool connected()
	{
		if ( !m_tried_connect )
		{
			m_tried_connect = true;
			
			qbhError err = qbhRegisterChannel( (char*)m_channame,
								HubGetType( m_val_p ),
								qbhMemoryChannel,
								qbhInput,
								0,		// channel_mux
								0,		// channel_config
								esc_hub::domain(),
								&esc_hub_memory<T_WORD>::hub_callback,
								this,
								&m_channel_handle );

			if ( err != qbhOK )
			{
				esc_report_error( esc_error, "esc_hub_memory: Failed to channel : %s\n\t%s\n",
								  m_channame, qbhErrorString( err )  );
				m_channel_handle = qbhEmptyHandle; 
			}
		}
		return (m_channel_handle != qbhEmptyHandle); 
	}

	//! \internal
	//! Called when activity occurs on the channel in the Hub.
	inline static qbhError	hub_callback( 	qbhChannelHandle channelHandle,
										 	void* user_data_p,
									 	 	qbhExtChannelActivity cbCode,
									 	 	qbhHandle cbInfo,
											qbhHandle* pCbOutValue )
	{
		qbhError error = qbhOK;

		if ( cbCode == qbhValueFanout )
		{
			// A value has been read from or written to the memory.
			esc_hub_memory<T_WORD>* hub_mem = (esc_hub_memory<T_WORD>*)user_data_p;

			// INCOMPLETE!
		}												
		return qbhOK;
	}
											  
};


#endif // BDW_HUB

/*!
  \class esc_sparse_memory
  \brief Can be used as a sparse memory in SystemC

  Templated on the access datatype - sc_uint<>/sc_biguint<>/etc
*/
template < class T_WORD >
class esc_sparse_memory : public esc_memory< T_WORD >
{
 public:
	typedef sc_phash<unsigned int, T_WORD*> hash_t;

	static int				compare_int_void(const void* a, const void* b)
							{
								unsigned long ia = (unsigned long)a;
								unsigned long ib = (unsigned long)b;
								if ( ia < ib )
									return -1;
								else if ( ia > ib )
									return 1;
								else
									return 0;
							}


							/*!
							  \brief Constructor
							  \param channame The name of the channel to connect to
							  \param _address_size The size of the address space
							*/
							esc_sparse_memory( unsigned int _address_size, const char *name=0 )
								: esc_memory< T_WORD >( _address_size, name )
							{
							    m_mem_hash = new hash_t;
								m_mem_hash->set_hash_fn(default_int_hash_fn);
								m_mem_hash->set_cmpr_fn(compare_int_void);
							}

							//! Destructor
							~esc_sparse_memory()
							{
								typename hash_t::iterator it(m_mem_hash);
								for ( ; !it.empty(); it++) {
									T_WORD* val = it.contents();
									delete val;
								}
								delete m_mem_hash;
							}

							/*!
							  \brief Determines whether an address in memory is fully initialized
							  \param address The address to read from
							  \return Non-zero if the address has no Xs or Zs
							*/
	int						is_initialized(unsigned int address)
							{
								return m_mem_hash->contains( address );
							}

							/*!
							  \brief Reads from the esc_sparse_memory
							  \param address The address to read from
							  \return The value read from the address.
							*/
	T_WORD					read( unsigned int address )
							{
								esc_handle h = this->notify_read_start();
								
								T_WORD word;
								T_WORD* word_p = 0;
								if ( !m_mem_hash->lookup( address, &word_p ) )
								{
									T_WORD* new_val = new T_WORD(0);
									m_mem_hash->insert( address, new_val );
									word = *new_val;
								}
								else
									word = *word_p;

								esc_mem_tx< T_WORD > tx( address, word );

								notify_read_end( &tx, h );

								return word;
							}

							/*! 
							  \brief Writes to the esc_sparse_memory
							  \param address The address to write to
							  \param The word to write
							*/
	void					write(unsigned int address, T_WORD value)
							{
								esc_mem_tx< T_WORD > tx(address,value);

								esc_handle h = notify_write_start( &tx );
								T_WORD* old_val;
								if ( m_mem_hash->lookup( address, &old_val ) )
									delete old_val;
								T_WORD* new_val = new T_WORD(value);
								m_mem_hash->insert( address, new_val );

								notify_write_end( &tx, h );
							}

 private:
    hash_t*					m_mem_hash;
};

#endif // ESC_MEM_HEADER_GUARD__
