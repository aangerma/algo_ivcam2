/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/
#ifndef cynrom_h_INCLUDED
#define cynrom_h_INCLUDED


#if defined STRATUS  &&  ! defined CYN_DONT_SUPPRESS_MSGS
#pragma cyn_suppress_msgs INFO
#endif	// STRATUS  &&  CYN_DONT_SUPPRESS_MSGS

#if defined STRATUS 
#pragma hls_ip_def
#endif	

/* We can't use any of this with stratus_vlg */
#if ! defined CYNLIB  &&  ! defined STRATUS_VLG

#include <systemc.h>
#include <ctype.h>

/* Add the following to the CYN namespace */
namespace CYN {

#ifdef	STRATUS_HLS

extern double
cyn_rom_str_2_dbl( HLS::HLS_ROM_FORMAT dt, const char* str,
		   const char* dirStr, const char* fileName, int index,
		   const char* origStr );
extern uint64
cyn_rom_str_2_ULL( HLS::HLS_ROM_FORMAT dt, const char* str,
		   const char* dirStr, const char* fileName, int index,
		   const char* origStr );

extern char*
cyn_rom_str_2_str( HLS::HLS_ROM_FORMAT dt, const char* str,
		   const char* dirStr, const char* fileName, int index,
		   const char* origStr );
#else	// STRATUS_HLS

static double
cyn_rom_str_2_dbl( HLS::HLS_ROM_FORMAT dt, const char* str,
		   const char* dirStr, const char* fileName, int lineNum,
		   const char* origStr );

static uint64
cyn_rom_str_2_ULL( HLS::HLS_ROM_FORMAT dt, const char* str, 
		   const char* dirStr, const char* fileName, int lineNum,
		   const char* origStr );

static char*
cyn_rom_str_2_str( HLS::HLS_ROM_FORMAT dt, const char* str,
		   const char* dirStr, const char* fileName, int lineNum,
		   const char* origStr );


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Converting a string into a double value.
*/
static double
cyn_rom_str_2_dbl( HLS::HLS_ROM_FORMAT dt, const char* str,
		   const char* dirStr, const char* fileName, int lineNum,
		   const char* origStr ) {
  if ( HLS::HLS_FLT != dt ) {
    return (double) cyn_rom_str_2_ULL( dt, str, dirStr, fileName, lineNum,
				   origStr );
  }
  double	dval;
  const char*		formatStr = "%lf";
  const char*		typeStr = "floating point";
  int		numRead = sscanf( str, formatStr, &dval );
  if ( 1 != numRead ) {
    fprintf( stderr,
	     "ERROR: at HLS_INITIALIZE_ROM( \"%s\" ) (a)\n"
	     "         Badly formed %s value in %s, line %d:\n\n"
	     "             %s%s\n"
	     "         Substituting 0 (zero).\n",
	     dirStr, typeStr, fileName, lineNum, origStr,
	     ( strchr( origStr, '\n' ) ? "" : "\n" ) );
    dval = 0.0;
  }
  return dval;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Converting a string into an "properly formatted" string.
* The caller is responsible for freeing the returned string.
*/
static inline char*
cyn_rom_str_2_str( HLS::HLS_ROM_FORMAT dt, const char* str,
		   const char* dirStr, const char* fileName, int lineNum,
		   const char* origStr ) {
    const char*	accept = "_";
    const char*	formatStr = "error";
    bool	isSigned = false;
    const char*	typeStr = "unknown kind of";
  switch ( dt ) {
    case HLS::HLS_BIN: {
      accept    = "01";
      formatStr = "0bus";
      isSigned  = false;
      typeStr   = "binary";
    } break;

    case HLS::HLS_DEC: {
      accept    = "0123456789";
      formatStr = "0d";
      isSigned  = true;
      typeStr   = "decimal";
    } break;

    case HLS::HLS_FLT: {
      fprintf( stderr,
	       "ERROR: at HLS_INITIALIZE_ROM( \"%s\" ) (b)\n"
	       "	Internal error. Cannot convert floating point data\n"
	       "	to a string.\n",
	       dirStr );
      exit(1);
    } break;

    case HLS::HLS_HEX: {
      accept    = "0123456789AaBbCcDdEeFf";
      formatStr = "0xus";
      isSigned  = false;
      typeStr   = "hexadecimal";
    } break;

    default: {
      fprintf( stderr, "ERROR: in HLS_INITIALIZE_ROM( \"%s\" ) (c)\n"
		       "       Unexpected data type, %d.\n",
		       dirStr, dt );
      exit(1);
    } break;
  }
  const char   *p = str;
  char	       *buf = (char*) calloc( strlen( str ) + 10, 1 );
  char	       *q = buf;
  bool		quoted = false;
  if ( '"' == *p ) {  
      p++;
      quoted = true;
  }
  if ( isSigned  &&  strchr( "+-", *p ) ) {
      *q++ = *p++;
  }

  int	formatLen = strlen( formatStr );
  if ( 0 == strncmp( formatStr, p, formatLen ) ) {
      p += formatLen;
  }
  strcat( q, formatStr ); q += formatLen;
  while ( *p  &&  strchr( accept, *p ) ) {
    *q++ = *p++;
  }

  int	numRead = ( '\0' == *p || isspace( (int) *p ) || ( quoted  &&  '"' == *p ) )  ?  1  :  0;

  if ( 1 != numRead ) {
    fprintf( stderr,
	     "ERROR: at HLS_INITIALIZE_ROM( \"%s\" ) (d)\n"
	     "         Badly formed %s value in %s, line %d:\n\n"
	     "             %s%s\n"
	     "         Substituting 0 (zero).\n",
	     dirStr, typeStr, fileName, lineNum, origStr,
	     ( strchr( origStr, '\n' ) ? "" : "\n" ) );
    sprintf( buf, "%s0", formatStr );
  }
  return buf;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Converting a string into an integral value.
*/
static uint64
cyn_rom_str_2_ULL( HLS::HLS_ROM_FORMAT dt, const char* str,
		   const char* dirStr, const char* fileName, int lineNum,
		   const char* origStr ) {
  uint64	val = 0;
  const char*		formatStr = "error";
  const char*		typeStr = "unknown kind of";
  switch ( dt ) {
    case HLS::HLS_BIN: {
      formatStr = "binary";
      typeStr = "binary";
    } break;

    case HLS::HLS_DEC: {
      formatStr = "%llu";
      typeStr = "decimal";
    } break;

    case HLS::HLS_FLT: {
        return (uint64) cyn_rom_str_2_dbl( dt, str, dirStr, fileName, lineNum, origStr );
    } // break;

    case HLS::HLS_HEX: {
      formatStr = "%llx";
      typeStr = "hexadecimal";
    } break;

    default: {
      fprintf( stderr, "ERROR: in HLS_INITIALIZE_ROM( \"%s\" ) (e)\n"
		       "       Unexpected data type, %d.\n",
		       dirStr, dt );
      exit(1);
    } break;
  }
  int numRead;
  if ( HLS::HLS_BIN == dt ) {
    const char* p = str;
    while ( '0' == *p  ||  '1' == *p ) {
      val = ( val << 1 ) | (uint64) ( '1' == *p );
      p++;
    }
    numRead = ( '\0' == *p  ||  isspace( (int) *p ) )  ?  1  :  0;
  } else {
    numRead = sscanf( str, formatStr, &val );
  }
  if ( 1 != numRead ) {
    fprintf( stderr,
	     "ERROR: at HLS_INITIALIZE_ROM( \"%s\" ) (f)\n"
	     "         Badly formed %s value in %s, line %d:\n\n"
	     "             %s%s\n"
	     "         Substituting 0 (zero).\n",
	     dirStr, typeStr, fileName, lineNum, origStr,
	     ( strchr( origStr, '\n' ) ? "" : "\n" ) );
    val = 0LL;
  }
  return val;
}
#endif	// STRATUS_HLS

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Template functions for converting a string into a data value.
*/
template< typename TT > class
	cyn_rom_str_2_type;

#define CYN_STR_2_INTEGRAL( TTT )					\
	template<> class						\
	cyn_rom_str_2_type< TTT > {					\
	  public:							\
	    static TTT							\
	      str_2_type( HLS::HLS_ROM_FORMAT dt, const char* str,	\
			  const char* dirStr, const char* fileName,	\
			  int lineNum, const char* origStr ) {		\
		return (TTT) cyn_rom_str_2_ULL( dt, str, dirStr,	\
						fileName, lineNum,	\
						origStr );		\
	      }								\
	}

CYN_STR_2_INTEGRAL( char );
CYN_STR_2_INTEGRAL( signed char );
CYN_STR_2_INTEGRAL( unsigned char );
CYN_STR_2_INTEGRAL( short int );
CYN_STR_2_INTEGRAL( unsigned short int );
CYN_STR_2_INTEGRAL( int );
CYN_STR_2_INTEGRAL( unsigned int );
CYN_STR_2_INTEGRAL( long int );
CYN_STR_2_INTEGRAL( unsigned long int );
CYN_STR_2_INTEGRAL( int64 );
CYN_STR_2_INTEGRAL( uint64 );

template< typename TT > class
	cyn_rom_str_2_type {
  public:
    static TT
      str_2_type( HLS::HLS_ROM_FORMAT dt, const char* str,
		  const char* dirStr, const char* fileName,
		  int lineNum, const char* origStr ) {
	if ( HLS::HLS_FLT != dt ) {
	  return (TT) cyn_rom_str_2_ULL( dt, str, dirStr, fileName,
					 lineNum, origStr );
	} else {
	  return (TT) cyn_rom_str_2_dbl( dt, str, dirStr, fileName,
					 lineNum, origStr );
	}
      }
};

template< int W > class
cyn_rom_str_2_type< sc_int<W> > {
  public:
    static sc_int<W>
      str_2_type( HLS::HLS_ROM_FORMAT dt, const char* str,
		  const char* dirStr, const char* fileName,
		  int lineNum, const char* origStr ) {
	return (sc_int<W>) cyn_rom_str_2_ULL( dt, str, dirStr, fileName,
					  lineNum, origStr );
      }
};

template< int W > class
cyn_rom_str_2_type< sc_uint<W> > {
  public:
    static sc_uint<W>
      str_2_type( HLS::HLS_ROM_FORMAT dt, const char* str,
		  const char* dirStr, const char* fileName,
		  int lineNum, const char* origStr ) {
	return (sc_uint<W>) cyn_rom_str_2_ULL( dt, str, dirStr, fileName,
					       lineNum, origStr );
      }
};

template< int W > class
cyn_rom_str_2_type< sc_bigint<W> > {
  public:
    static sc_bigint<W>
      str_2_type( HLS::HLS_ROM_FORMAT dt, const char* str,
		  const char* dirStr, const char* fileName,
		  int lineNum, const char* origStr ) {
	if ( HLS::HLS_FLT != dt ) {
	  return (sc_bigint<W>) cyn_rom_str_2_str( dt, str, dirStr, fileName,
						   lineNum, origStr );
	} else {
	  return (sc_bigint<W>) cyn_rom_str_2_dbl( dt, str, dirStr, fileName,
						   lineNum, origStr );
	}
      }
};

template< int W > class
cyn_rom_str_2_type< sc_biguint<W> > {
  public:
    static sc_biguint<W>
      str_2_type( HLS::HLS_ROM_FORMAT dt, const char* str,
		  const char* dirStr, const char* fileName,
		  int lineNum, const char* origStr ) {
	if ( HLS::HLS_FLT != dt ) {
            return (sc_biguint<W>) cyn_rom_str_2_str( dt, str, dirStr, fileName,
                                                      lineNum, origStr );
	} else {
            return (sc_biguint<W>) cyn_rom_str_2_dbl( dt, str, dirStr, fileName,
                                                      lineNum, origStr );
	}
      }
};

/*
template< int V, int W, int X, int Y, int Z > class
cyn_rom_str_2_type< cynw_fixed<V,W,X,Y,Z> > {
  public:
    static cynw_fixed<V,W,X,Y,Z>
      str_2_type( HLS::HLS_ROM_FORMAT dt, const char* str,
		  const char* dirStr, const char* fileName,
		  int lineNum, const char* origStr ) {
	cynw_fixed<V,W,X,Y,Z>	cwfx;
	switch ( dt ) {
	  case HLS::HLS_BIN: {
	    cwfx() = cyn_rom_str_2_str( dt, str, dirStr, fileName, lineNum,
					origStr );
	  } break;

	  case HLS::HLS_DEC:
	  case HLS::HLS_HEX: {
	    cwfx = cyn_rom_str_2_ULL( dt, str, dirStr, fileName, lineNum,
				      origStr );
	  } break;

	  case HLS::HLS_FLT: {
	    cwfx = cyn_rom_str_2_dbl( dt, str, dirStr, fileName, lineNum,
				      origStr );
	  } break;

	  default: {
	    fprintf( stderr, "ERROR: in HLS_INITIALIZE_ROM( \"%s\" ) (g)\n"
			     "       Unexpected data type, %d.\n",
			     dirStr, dt );
	    exit(1);
	  } break;
	}
	return cwfx;
      }
};

template< int V, int W, int X, int Y, int Z > class
cyn_rom_str_2_type< cynw_ufixed<V,W,X,Y,Z> > {
  public:
    static cynw_ufixed<V,W,X,Y,Z>
      str_2_type( HLS::HLS_ROM_FORMAT dt, const char* str,
		  const char* dirStr, const char* fileName,
		  int lineNum, const char* origStr ) {
	cynw_ufixed<V,W,X,Y,Z>	cwufx;
	switch ( dt ) {
	  case HLS::HLS_BIN: {
	    cwufx() = cyn_rom_str_2_str( dt, str, dirStr, fileName, lineNum,
					 origStr );
	  } break;

	  case HLS::HLS_DEC:
	  case HLS::HLS_HEX: {
	    cwufx = cyn_rom_str_2_ULL( dt, str, dirStr, fileName, lineNum,

				       origStr );
	  } break;

	  case HLS::HLS_FLT: {
	    cwufx = cyn_rom_str_2_dbl( dt, str, dirStr, fileName, lineNum,
				       origStr );
	  } break;

	  default: {
	    fprintf( stderr, "ERROR: in HLS_INITIALIZE_ROM( \"%s\" ) (h)\n"
			     "       Unexpected data type, %d.\n",
			     dirStr, dt );
	    exit(1);
	  } break;
	}
	return cwufx;
      }
};
*/

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Template function for interpretted implementation of HLS_INITIALIZE_ROM
*/
template< typename T, unsigned int NUM_ELS > void
cyn_rom_interp_init( const T array[NUM_ELS], int dt,
		     const char* file_name, const char* dirStr ) {
  for ( unsigned int i = 0;  i < NUM_ELS;  i++ ) {
    CYN_UNROLL( HLS::ON, NUM_ELS, dirStr );
    (const_cast<T*>( array ))[i]
      = cyn_rom_str_2_type<T>::str_2_type( (HLS::HLS_ROM_FORMAT)dt, NULL, dirStr, file_name, i, NULL );
  }
}


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Template function for behavioral implementation of HLS_INITIALIZE_ROM
*/
template< typename T > inline void
cyn_rom_init( unsigned int array_size, const T* array, 
	      int idt, const char* file_name, 
	      const char* dirStr, const char* srcFile, int srcLine ) {
  HLS::HLS_ROM_FORMAT dt = (HLS::HLS_ROM_FORMAT)idt;
  switch ( dt ) {
    case HLS::HLS_BIN:    case HLS::HLS_DEC:
    case HLS::HLS_FLT:    case HLS::HLS_HEX: {
      /* do nothing */
    } break;

    default: {
      fprintf( stderr,
	       "ERROR: at HLS_INITIALIZE_ROM( \"%s\" ) (i)\n"
	       "ERROR:   Bad data type code, %d.\n",
	       dirStr, dt );
      exit(1);
    } break;
  }

  FILE*		fp = fopen( file_name, "r" );
  int		numEls;
  if ( ! fp ) {
    fprintf( stderr, 
	     "ERROR: at %s line %d\n"
	     "       HLS_INITIALIZE_ROM( \"%s\" ) (j)\n"
	     "       Unable to open ROM initialization file, \"%s\", for reading.\n",
	     srcFile ? srcFile : "<unknown file>", srcLine, dirStr,
	     file_name );

    return;
  }

  /* Determine the number of elements in array. */
    numEls = array_size / sizeof( T );

   /* Read the file, filtering out insignificant text. */ {
    typedef enum { NO_COMM, SLASH_SLASH_COMM, SLASH_STAR_COMM }
		CommType;

    char	buf1[1025], buf2[1025];
    int		count = 0;
    CommType	inComm = NO_COMM;
    int		lineNum = 1;
    bool	posted = false;
  
    while ( fgets( buf1, sizeof( buf1 ), fp ) ) {

      /* Remove comments and '_'s and translate 'x's and 'z's */ {
	char* p = buf2;
	char* q = buf1;
	while ( *q ) {
	  if ( SLASH_SLASH_COMM == inComm  ) {
	    while ( *q  &&  '\n' != *q ) q++;
	    if ( *q ) {
	      q++;
	      inComm = NO_COMM;
	    }
	  } else if ( SLASH_STAR_COMM == inComm ) {
	    while ( *q  &&  ! ( '*' == *(q-1)  &&  '/' == *q ) ) q++;
	    if ( *q ) {
	      q++;
	      inComm = NO_COMM;
	    }
	  } else {
	    switch ( *q ) {
	      case '/': {
		if ( '/' == *(q+1) ) {
		  q += 2;
		  inComm = SLASH_SLASH_COMM;
		} else if ( '*' == *(q+1) ) {
		  /* skip over the comment. */
		  q += 2;
		  inComm = SLASH_STAR_COMM;
		} else {
		  *p++ = *q++;
		}
	      } break;

	      case '_': {
		/* skip */
		q++;
	      } break;

	      case 'x':  case 'X':
	      case 'z':  case 'Z': {
		if ( ! posted ) {
		  fprintf( stderr,
	       		   "WARNING: at HLS_INITIALIZE_ROM( \"%s\" )\n"
			   "         'x's and 'z's in the data file, %s, line %d,\n"
			   "         are translated as '0's (zeros).\n",
			   dirStr, file_name, lineNum );
		  posted = true;
		}
		*p++ = '0';
		q++;
	      } break;

	      default: {
		*p++ = *q++;
	      } break;
	    }
	  }
	}
	*p = '\0';
      }

      /* Build new expression list entries from the values in buf2. */ {
	char*		p = buf2;

	while ( *p  &&  isspace( (int) *p ) ) p++;

	while ( *p ) {
	  if ( *p == '@' ) {
	    fprintf( stderr,
		     "ERROR: at HLS_INITIALIZE_ROM( \"%s\" ) (k)\n"
		     "         Addresses in the data file, %s, line %d,\n"
		     "         are not supported.\n",
		     dirStr, file_name, lineNum );
	    break;
	  } else {
	    if ( count < numEls ) {
	      (const_cast<T*>( array ))[count]
		= cyn_rom_str_2_type<T>::str_2_type( dt, p, dirStr, file_name,
						     lineNum, buf1 );
	    }

	    /* advance over a token. */
	      while ( *p  &&  ! isspace( (int) *p ) ) p++;
	      while ( *p  &&  isspace( (int) *p ) ) p++;

	    count++;
	  }
	}
      }

      if ( strchr( buf1, '\n' ) ) lineNum++;	
    }

    if ( count > numEls ) {
      fprintf( stderr,
	       "WARNING: at HLS_INITIALIZE_ROM( \"%s\" )\n"
	       "         %s contains %d more values (%d)\n"
	       "         than the array has elements (%d).\n"
	       "         The extra values are ignored.\n",
	       dirStr, file_name, count - numEls, count, numEls );
    } else if ( count < numEls ) {
      fprintf( stderr,
	       "ERROR: at HLS_INITIALIZE_ROM( \"%s\" ) (l)\n"
	       "         %s contains %d fewer values (%d)\n"
	       "         than the array has elements (%d).\n"
	       "         The remaining elements are set to zero.\n",
	       dirStr, file_name, numEls - count, count, numEls );

      /* Fill with zeros. */
	while ( count < numEls ) {
	  (const_cast<T*>( array ))[count] = 0;
	  count++;
	}
    }
  }
  fclose( fp );
}

};	/* namespace CYN */

#endif	/* CYNLIB  ||  STRATUS_VLG */
#endif	/* cynrom_h_INCLUDED */
