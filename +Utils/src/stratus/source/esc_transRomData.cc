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
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* esc_transRomData.cc
*		Translate a ROM data file from one format to another.
*		The result will have one value per line with no whitespace,
*		punctiation, or comments other than newline characters.
*
*		Copyright  2008  Forte Design Systems
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* $Id: esc_transRomData.cc,v 1.6 2012-07-19 20:52:58 sbs Exp $
*
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **/


/* * * * * * * * * * * * * * *  Included Files * * * * * * * * * * * * * * * */

# include "cynthhl.h"


/* * * * * * * * * * * * * *  Entity Definitions * * * * * * * * * * * * * * */

# define	WORD_WIDTH 1024


/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* help
*   Print information about how to run this program and exit.
*
*   Accepts:
*     int status: a value to pass to exit
*   Returns:
*     No, it doesn't (void).
*   Side Effects:
*     Prints to stdout and terminates execution with the given status value.
*/
static void
help( int status ) {
  cout << endl
       << "Use: esc_transRomData <arguments>\n"
       << endl
       << "esc_transRomData reads the indicated ROM data file into a ROM of the\n"
       << "indicated size, then writes the values into the indicated output\n"
       << "file in the indicated format - one value per line. (values may have leading\n"
       << "zeros.)\n"
       << endl
       << "All of the command line options are required but they may be\n"
       << "given in any order.\n";
  cout << endl
       << "  --depth <unsigned int>\n"
       << "        Specifies the number of words in the array to be\n"
       << "        initialized.\n"
       << endl
       << "  --inputFile <file_name>\n"
       << "        Specifies the data file to read.\n"
       << endl
       << "  --inputFormat [1234]\n"
       << "        Indicates whether the input data file contains numbers represented \n"
       << "        in binary (1), double [floating point] (2), decimal (3),\n"
       << "        or hexadecimal (4) notation.\n"
       << endl
       << "  --outputFile <file_name>\n"
       << "        Specifies the file into which to write the normalized\n"
       << "        data.\n"
       << endl
       << "  --outputFormat [1234]\n"
       << "        Indicates whether the output data file should contains numbers\n"
       << "        represented in binary (1), double [floating point] (2), decimal (3),\n"
       << "        or hexadecimal (4) notation.\n"
       << endl
       << "  --width <unsigend int>\n"
       << "        Specifies the bit width of the words in the array.\n"
       << "        Must not be greater than 64.\n"
       << endl;

  exit( status );
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* sc_main
*
*   Accepts:
*     
*   Returns:
*     
*   Side Effects:
*     
*/
int
sc_main( int argc, char* argv[] ) {
    int	error = 0;

    int	depth = -1;
    char*	inputFile = NULL;
    int	inputFormat = -1;
    char* outputFile = NULL;
    int	outputFormat = -1;
    int	width = -1;

    /* Process the command line arguments. */
    int i;
    for ( i = 1;  i < argc-1;  i++ ) {
        if ( 0 == strcmp( argv[i], "--depth" ) ) {
            i += sscanf( argv[i+1], "%u", &depth );
        } else if ( 0 == strcmp( argv[i], "--inputFile" ) ) {
            inputFile = strdup( argv[++i] );
        } else if ( 0 == strcmp( argv[i], "--inputFormat" ) ) {
            i += sscanf( argv[i+1], "%d", &inputFormat );
        } else if ( 0 == strcmp( argv[i], "--outputFile" ) ) {
            outputFile = strdup( argv[++i] );
        } else if ( 0 == strcmp( argv[i], "--outputFormat" ) ) {
            i += sscanf( argv[i+1], "%d", &outputFormat );
        } else if ( 0 == strcmp( argv[i], "--width" ) ) {
            i += sscanf( argv[i+1], "%u", &width );
        } else {
            /* Ignore */
        }
    }

    if ( -1 == depth ) {
        cerr << "\nERROR: Missing depth specification.\n";
        error++;
    } else {
        //cout << "depth =      " << depth << endl;
    }
    if ( NULL == inputFile ) {
        cerr << "\nERROR: Missing inputFile specification.\n";
        error++;
    } else {
        //cout << "inputFile =   " << inputFile << endl;
    }
    if ( -1 == inputFormat ) {
        cerr << "\nERROR: Missing inputFormat specification.\n";
        error++;
    } else {
        //cout << "inputFormat = " << inputFormat << endl;
    }
    if ( NULL == outputFile ) {
        cerr << "\nERROR: Missing output file specification.\n";
        error++;
    } else {
        //cout << "outputFile =   " << outputFile << endl;
    }
    if ( -1 == outputFormat ) {
        cerr << "\nERROR: Missing outputFormat specification.\n";
        error++;
    } else {
        //cout << "outputFormat = " << outputFormat << endl;
    }
    if ( -1 == width ) {
        cerr << "\nERROR: Missing width specification.\n";
        error++;
    } else if ( WORD_WIDTH < width ) {
        cerr << "\nERROR: Unable to process data widths greater than " << WORD_WIDTH << endl;
        error++;
    } else {
        //cout << "width =      " << width << endl;
    }
    if ( 0 != error ) {
        help( error );
    }
    
    /*
    * Now, create an array of the given dimensions and initialize it from the
    * named data file.
    */ {
        sc_biguint<WORD_WIDTH> mem[depth];
        HLS_INITIALIZE_ROM( sc_biguint<WORD_WIDTH>, mem,
                            (HLS::HLS_ROM_FORMAT) inputFormat, inputFile,
                            "esc_transRomData" );

        ofstream	outStream( outputFile );
        int i;

        sc_biguint<WORD_WIDTH> mask = sc_biguint<WORD_WIDTH>( std::string( "0bus" ).append( width, '1' ).c_str() );
        int		wantLen;
        if ( HLS::HLS_BIN == outputFormat ) {
            wantLen = width;
        } else if ( HLS::HLS_HEX == outputFormat ) {
            wantLen = (int) ceil( width / 4.0 );
        }

        for ( i = 0;  i < depth;  i++ ) {
            int			strLen;
            std::string		strVal;
            sc_biguint<WORD_WIDTH> val = mem[i] & mask;
            switch ( outputFormat ) {
              case HLS::HLS_BIN:
              case HLS::HLS_HEX:
                if ( HLS::HLS_BIN == outputFormat ) {
                    strVal = val.to_string( SC_BIN_US, false );
                } else {
                    strVal = val.to_string( SC_HEX_US, false );
                }
                strLen = strVal.length();
                if ( wantLen < strLen ) {
                    strVal = strVal.substr( strLen - wantLen, std::string::npos );
                }
                outStream << strVal << endl;
                break;

              case HLS::HLS_DBL:
                outStream << val.to_double() << endl;
                break;

              case HLS::HLS_DEC:
                if ( 64 < width ) {
                    outStream << "\"" << val.to_string( SC_DEC, true ) << "\"" << endl;
                } else {
                    outStream << val.to_string( SC_DEC, false ) << endl;
                }
                break;

              default:
                cerr << "\nERROR: Illegal output format specifcation, '" << outputFormat
                     << "'\n";
                help( 1 );
                break;
            }
        }
    }

    exit( 0 );
}
