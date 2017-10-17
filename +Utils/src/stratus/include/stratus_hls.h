/**************************************************************************
*
*  Copyright (c) 2015, Cadence Design Systems. All Rights Reserved.
*
*  This file contains confidential information that may not be
*  distributed under any circumstances without the written permision
*  of Cadence Design Systems.
*
***************************************************************************/
#ifndef stratus_hls_h_INCLUDED
#define stratus_hls_h_INCLUDED

#if defined STRATUS  &&  ! defined CYN_DONT_SUPPRESS_MSGS
#pragma cyn_suppress_msgs NOTE
#endif  // STRATUS  &&  CYN_DONT_SUPPRESS_MSGS

#if defined STRATUS 
#pragma hls_ip_def
#endif  

#include    "systemc.h"
#include    <ctype.h>
#include    "hls_enums.h"

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* Directives appear as external function declarations with no body to
* synthesis tools, and as inline functions with empty bodies for behavioral
* simulation.
*/

#define     HLS_INLINE_DECL static inline void

#if defined( STRATUS_HLS ) || defined( BDW_EXTRACT )

#define     HLS_DIR_BODY ;
#define     HLS_DIR_DECL    extern void

#else       

#define     HLS_DIR_BODY {}
#define     HLS_DIR_DECL    HLS_INLINE_DECL

#endif  

/* Package all of this in a namespace. */
namespace   HLS {

#if defined( STRATUS_HLS ) || defined( BDW_EXTRACT )

/* 
* Time values that will be replaced during synthesis with values to be used for the synthesis job.
*/
extern double               HLS_CLOCK_PERIOD;
extern double               HLS_FU_CLOCK_PERIOD;
extern double               HLS_REG_SETUP_TIME;
extern double               HLS_REG_DELAY;
extern double               HLS_REAL_CLOCK_PERIOD;
extern double               HLS_CYCLE_SLACK_VALUE;
extern int                  HLS_DPOPT_WITH_ENABLE;
extern HLS_RESET_TYPE_KIND  HLS_RESET_TYPE;

/* 
* HLS_INITIATION_INTERVAL will be replaced with the initiation interval from 
* a HLS_PIPELINE_LOOP * directive in a loop in which it is contained.  It will
* always be 0 in gcc.
*/
extern int HLS_INITIATION_INTERVAL;

#else  // STRATUS_HLS  ||  BDW_EXTRACT

#define  HLS_INITIATION_INTERVAL 0
#define  HLS_CLOCK_PERIOD 0.
#define  HLS_FU_CLOCK_PERIOD 0.
#define  HLS_REG_SETUP_TIME 0.
#define  HLS_REG_DELAY 0.
#define  HLS_REAL_CLOCK_PERIOD 0.
#define  HLS_CYCLE_SLACK_VALUE 0.
#define  HLS_DPOPT_WITH_ENABLE 0
#define  HLS_RESET_TYPE 0

#endif // STRATUS_HLS || BDW_EXTRACT
//
// HLS_ASSUME_STABLE
// 
HLS_DIR_DECL    _HLS_ASSUME_STABLE( 
                                    HLS::HLS_ASSUME_STABLE_OPTIONS  option,
                                    const void*     io,
                                    const char*     label )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_ASSUME_STABLE(  const HLS_T1&   io,
                                    const char*     label = "" ) {
                    _HLS_ASSUME_STABLE( HLS::HLS_ASSUME_STABLE_DEFAULT, (void*) &io, (char*) label );
                }

template<typename HLS_T1>
HLS_INLINE_DECL HLS_ASSUME_STABLE(  HLS::HLS_ASSUME_STABLE_OPTIONS  option,
                                    const HLS_T1&   io,
                                    const char*     label = "" ) {
                    _HLS_ASSUME_STABLE( HLS::HLS_ASSUME_STABLE_DEFAULT, (void*) &io, (char*) label );
                }

HLS_DIR_DECL    _HLS_ASSUME_STABLE_RANGE( 
                                    HLS::HLS_ASSUME_STABLE_OPTIONS  option,
                                    const void*     first_io,
                                    const void*     last_io,
                                    const char*     label )
                    HLS_DIR_BODY

template<typename HLS_T1, typename HLS_T2>
HLS_INLINE_DECL HLS_ASSUME_STABLE(  const HLS_T1&   first_io,
                                    const HLS_T2&   last_io,
                                    const char*     label ) {
                    _HLS_ASSUME_STABLE_RANGE( HLS::HLS_ASSUME_STABLE_DEFAULT, (void*) &first_io , (void*) &last_io, (char*) label );
                }

template<typename HLS_T1, typename HLS_T2>
HLS_INLINE_DECL HLS_ASSUME_STABLE(  HLS::HLS_ASSUME_STABLE_OPTIONS  option,
                                    const HLS_T1&   first_io,
                                    const HLS_T2&   last_io,
                                    const char*     label ) {
                    _HLS_ASSUME_STABLE_RANGE( option, (void*) &first_io , (void*) &last_io, (char*) label );
                }

//
// HLS_CONSTRAIN_ARRAY_MAX_DISTANCE
//
HLS_DIR_DECL    _HLS_CONSTRAIN_ARRAY_MAX_DISTANCE( 
                                    const void*     array,
                                    int             distance,
                                    const char*     label )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_CONSTRAIN_ARRAY_MAX_DISTANCE(   const HLS_T1&   array,
                                                    int             distance = -1, 
                                                    const char*     label = "" ) {
                    _HLS_CONSTRAIN_ARRAY_MAX_DISTANCE( (void*) &array , distance, (char*) label );
                }
HLS_DIR_DECL    _HLS_CONSTRAIN_ARRAY_MAX_DISTANCE( 
                                    const void*     port1,
                                    const void*     port2,
                                    int             distance,
                                    const char*     label )
                    HLS_DIR_BODY

template<typename HLS_T1, typename HLS_T2>
HLS_INLINE_DECL HLS_CONSTRAIN_ARRAY_MAX_DISTANCE(   const HLS_T1&   port1,
                                                    const HLS_T2&   port2,
                                                    int             distance, 
                                                    const char*     label = "" ) {
                    _HLS_CONSTRAIN_ARRAY_MAX_DISTANCE( (void*) &port1 , (void*) &port2, distance, (char*) label );
                }

//
// HLS_CONSTRAIN_LATENCY
// 
HLS_DIR_DECL    _HLS_CONSTRAIN_LATENCY( int             min_lat,
                                        int             max_lat,
                                        const char*     label )
                    HLS_DIR_BODY

HLS_INLINE_DECL HLS_CONSTRAIN_LATENCY(  int             min_lat=0, 
                                        int             max_lat=-1,
                                        const char*     label="" ) {
            _HLS_CONSTRAIN_LATENCY( min_lat, max_lat, label ); 
          }

HLS_INLINE_DECL HLS_CONSTRAIN_LATENCY(  const char* label ) {
            _HLS_CONSTRAIN_LATENCY( 0, -1, label ); 
          }

//
// HLS_BREAK_PROTOCOL
// 
HLS_DIR_DECL    _HLS_BREAK_PROTOCOL(    int             min_lat,
                                        int             max_lat,
                                        const char*     label )
                    HLS_DIR_BODY

HLS_INLINE_DECL HLS_BREAK_PROTOCOL(     int             min_lat=0, 
                                        int             max_lat=-1,
                                        const char*     label="" ) {
            _HLS_BREAK_PROTOCOL( min_lat, max_lat, label ); 
          }

HLS_INLINE_DECL HLS_BREAK_PROTOCOL(     const char*     label ) {
            _HLS_BREAK_PROTOCOL( 0, -1, label ); 
          }



//
// HLS_COALESCE_LOOP
// 
HLS_DIR_DECL    HLS_COALESCE_LOOP(   HLS::HLS_UNROLL_OPTIONS
                                                    option = HLS::CONSERVATIVE,
                                    const char*     label="" )
                    HLS_DIR_BODY

//
// HLS_DEFINE_ACCESS_PATTERN
//
HLS_DIR_DECL    _HLS_DEFINE_ACCESS_PATTERN( 
                                    const void*     array,
                                    const char*     pattern,
                                    const char*     label )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_DEFINE_ACCESS_PATTERN(   const HLS_T1&   array,
                                             const char*     pattern,
                                             const char*     label = "" ) {
                    _HLS_DEFINE_ACCESS_PATTERN( (void*) &array , pattern, label );
                }
//
// HLS_DEFINE_PROTOCOL
// 
HLS_DIR_DECL    HLS_DEFINE_PROTOCOL(const char*     label = "" )
                    HLS_DIR_BODY

//
// HLS_SET_IS_DEFAULT_PROTOCOL
// 
HLS_DIR_DECL    HLS_SET_IS_DEFAULT_PROTOCOL(HLS::HLS_UNROLL_OPTIONS        option = HLS::ON )
                    HLS_DIR_BODY

//
// HLS_DEFINE_FLOATING_PROTOCOL
// 

#if defined(STRATUS)
HLS_DIR_DECL    _HLS_DEFINE_FLOATING_PROTOCOL(  double              setup,
                                                double              delay,
                                                int                 ii,
                                                void*               context,
                                                unsigned            flags,
                                                ... )
                    HLS_DIR_BODY
#else
#define         _HLS_DEFINE_FLOATING_PROTOCOL(  setup, delay, ii, context, flags, ... )
#endif

template <typename T>
HLS_INLINE_DECL HLS_DEFINE_FLOATING_PROTOCOL(   double              setup,
                                                double              delay,
                                                int                 ii,
                                                void*               context,
                                                unsigned            flags,
                                                T                   address,
                                                const char*         name ) {
                    _HLS_DEFINE_FLOATING_PROTOCOL( setup, delay, ii, context, flags, address, name );
                }


// HLS_DEFINE_STALL_LOOP
// 
HLS_DIR_DECL    HLS_DEFINE_STALL_LOOP(  HLS::HLS_UNROLL_OPTIONS     option,
                    const char*         label = "", void* context=0 )
                    HLS_DIR_BODY

//
// HLS_REMOVE_CONTROL
// 
HLS_DIR_DECL    HLS_REMOVE_CONTROL(     HLS::HLS_UNROLL_OPTIONS     option,
                                        const char*                 label = "" )
                    HLS_DIR_BODY

HLS_DIR_DECL    HLS_REMOVE_CONTROL(     const char*                 label = "" )
                    HLS_DIR_BODY

//
// HLS_COVERAGE_POINT
// 
HLS_DIR_DECL    HLS_COVERAGE_POINT(   const char* label )
                    HLS_DIR_BODY

//
// HLS_NAME
// 
HLS_DIR_DECL    HLS_NAME(               const char* label = "" )
                    HLS_DIR_BODY

//
// HLS_CONSTRAIN_REGION
// 
HLS_DIR_DECL    HLS_CONSTRAIN_REGION(   int         minlat,
                                        int         maxlat = -1,
                                        double      input_delay = -1.0,
                                        double      max_delay = -1.0 )
                    HLS_DIR_BODY

//
// HLS_DPOPT_REGION
// 
HLS_DIR_DECL    _HLS_DPOPT_REGION(      unsigned    flags,
                                        const char* name )
                    HLS_DIR_BODY

HLS_INLINE_DECL HLS_DPOPT_REGION(       unsigned    flags = HLS::REGION_DEFAULT,
                                        const char* name = "dpopt",
                                        const char* legacy_str = "" ) {
                    _HLS_DPOPT_REGION( flags, name );
                }

HLS_INLINE_DECL HLS_DPOPT_REGION(       const char* name ) {
                    _HLS_DPOPT_REGION( HLS::REGION_DEFAULT, name );
                }

//
// HLS_FLATTEN_ARRAY
// 
HLS_DIR_DECL    _HLS_FLATTEN_ARRAY(     const void* array,
                                        HLS::HLS_FLATTEN_OPTIONS
                                                    option = HLS::DEFAULT_FLATTEN )
                    HLS_DIR_BODY

HLS_INLINE_DECL HLS_FLATTEN_ARRAY(      const void* array,
                                        HLS::HLS_FLATTEN_OPTIONS
                                                    option = HLS::DEFAULT_FLATTEN ) {
                    _HLS_FLATTEN_ARRAY( array, option );
                }

HLS_INLINE_DECL HLS_FLATTEN_ARRAY(      const void* array,
                                        const char* legacy_str ) {
                    _HLS_FLATTEN_ARRAY( array,  HLS::DEFAULT_FLATTEN );
                }

//
// HLS_INITIALIZE_ROM
// 
HLS_DIR_DECL    _HLS_INITIALIZE_ROM(    const void* array,
                                        HLS::HLS_ROM_FORMAT 
                                                    format,
                                        const char* file )
                    HLS_DIR_BODY

//
// HLS_END_INITIALIZE_ROM
// 
HLS_DIR_DECL    HLS_END_INITIALIZE_ROM()
                    HLS_DIR_BODY

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
*
* ROM initialization directives have different implementations for
*   stratus_hls, stratus_vlg, and "other" (e.g. g++).
*/
#if defined STRATUS_HLS

#define     HLS_INITIALIZE_ROM( type, array, dt, file_name, required_str )      \
          _HLS_INITIALIZE_ROM( (array), (dt), (file_name) );\
          cyn_rom_interp_init< type, sizeof(array)/sizeof(type) >(  \
            (const type*) (array), (dt), (file_name), (required_str)\
          );                                  \
          CYN_ROM_INIT_END()

  

#elif   defined STRATUS_VLG

#define     HLS_INITIALIZE_ROM( type, array, dt, file_name, required_str )\
          extern void cyn_rom_init( int,    \
                        char*, const void* );   \
          cyn_rom_init( (dt), (file_name), (array) )

#else

#define     HLS_INITIALIZE_ROM( type, array, dt, file_name, required_str )     \
          cyn_rom_init<type>( sizeof( array ), (const type*) (array),\
                      (dt), (file_name),             \
                      (required_str), __FILE__, __LINE__ )
#endif


//
// HLS_MAP_INVERT_DIMENSIONS
// 
HLS_DIR_DECL    HLS_INVERT_DIMENSIONS(  const void* array )
                    HLS_DIR_BODY

//
// HLS_MAP_ARRAY_INDEXES
// 
HLS_DIR_DECL    HLS_MAP_ARRAY_INDEXES(  const void* array,
                                        HLS::HLS_INDEX_MAPPING_OPTIONS
                                                    option = HLS::COMPACT )
                    HLS_DIR_BODY

//
// HLS_MESSAGE
// 
HLS_DIR_DECL    HLS_MESSAGE(            int         msg_num,
                                        const char* str = "" )
                    HLS_DIR_BODY

//
// HLS_MAP_TO_MEMORY
// 
HLS_DIR_DECL    _HLS_MAP_TO_MEMORY(     const void*     array,
                                        const char*     mem_type,
                                        const void*     clk )
                    HLS_DIR_BODY

HLS_INLINE_DECL HLS_MAP_TO_MEMORY(      const void*     array,
                                        const char*     mem_type = "" ) {
                    _HLS_MAP_TO_MEMORY( array, mem_type, 0 );
        }

template <typename T>
HLS_INLINE_DECL HLS_MAP_TO_MEMORY(      const void*     array,
                                        const char*     mem_type,
                                        T&              clk ) {
                    _HLS_MAP_TO_MEMORY( array, mem_type, &clk );
        }

//
// HLS_MAP_TO_REG_BANK
// 
HLS_DIR_DECL    HLS_MAP_TO_REG_BANK(    const void*     array )
                    HLS_DIR_BODY

//
// HLS_PRESERVE_IO_SIGNALS
// 
HLS_DIR_DECL    HLS_PRESERVE_IO_SIGNALS(void)
                    HLS_DIR_BODY

//
// HLS_PIPELINE_LOOP
//
HLS_DIR_DECL    _HLS_PIPELINE_LOOP( HLS::HLS_PIPELINE_OPTIONS   
                                                        type,
                                    int                 ii,
                                    const char*         label )
                    HLS_DIR_BODY

HLS_INLINE_DECL HLS_PIPELINE_LOOP(  HLS::HLS_PIPELINE_OPTIONS   
                                                        type,
                                    int                 ii = 1,
                                    const char*         label = "" ) {
                    _HLS_PIPELINE_LOOP( type, ii, label );
                }

HLS_INLINE_DECL HLS_PIPELINE_LOOP(  const char*         label ) {
                    _HLS_PIPELINE_LOOP( HLS::HARD_STALL, 1, label );
                }

//
// HLS_SET_IS_VOLATILE
// 
HLS_DIR_DECL    _HLS_SET_IS_VOLATILE( const void*    io,
                                      bool           always )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_SET_IS_VOLATILE( const HLS_T1&   io,
                                     bool            always = true ) {
                    _HLS_SET_IS_VOLATILE( &io, always );
                }

//
// HLS_PRESERVE_SIGNAL
// 

HLS_DIR_DECL    _HLS_PRESERVE_SIGNAL(   void*   port,
                                        bool    always )
                    HLS_DIR_BODY

#if defined( STRATUS_HLS ) 

template<class T>
HLS_INLINE_DECL HLS_PRESERVE_SIGNAL( sc_signal<T>& sig, bool always=true ) {
                    _HLS_PRESERVE_SIGNAL( (void*)&sig, always );
                    HLS_SET_IS_VOLATILE( sig, always );
                }

template <class T, int HLS_N>
HLS_INLINE_DECL HLS_PRESERVE_SIGNAL( sc_signal<T> (&sig)[HLS_N], bool always=true) {
                    _HLS_PRESERVE_SIGNAL( sig, always );
                    HLS_SET_IS_VOLATILE( sig, always );
                }

template <class T, int HLS_N, int HLS_M>
HLS_INLINE_DECL HLS_PRESERVE_SIGNAL( sc_signal<T> (&sig)[HLS_N][HLS_M], bool always=true ) {
                    _HLS_PRESERVE_SIGNAL( sig, always );
                    HLS_SET_IS_VOLATILE( sig, always );
                }

template <class T, int HLS_N, int HLS_M, int HLS_O>
HLS_INLINE_DECL HLS_PRESERVE_SIGNAL( sc_signal<T> (&sig)[HLS_N][HLS_M][HLS_O], bool always=true ) {
                    _HLS_PRESERVE_SIGNAL( sig, always );
                    HLS_SET_IS_VOLATILE( sig, always );
                }

template <class T, int HLS_N, int HLS_M, int HLS_O, int HLS_P>
HLS_INLINE_DECL HLS_PRESERVE_SIGNAL( sc_signal<T> (&sig)[HLS_N][HLS_M][HLS_O][HLS_P], bool always=true ) {
                    _HLS_PRESERVE_SIGNAL( sig, always );
                    HLS_SET_IS_VOLATILE( sig, always );
                }


#else

template<class T>
HLS_INLINE_DECL HLS_PRESERVE_SIGNAL( T& v, bool always=true) {}

#endif

template<typename HLS_T1>
HLS_INLINE_DECL HLS_PRESERVE_SIGNAL(const HLS_T1&   io,
                                    bool            always = true ) {
                    _HLS_PRESERVE_SIGNAL( (void*) &io , always );
                }

//
// HLS_SCHEDULE_REGION
// 
HLS_DIR_DECL    _HLS_SCHEDULE_REGION(   unsigned    flags,
										int         ii,
                                        const char* name )
                    HLS_DIR_BODY

HLS_INLINE_DECL HLS_SCHEDULE_REGION(    unsigned    flags = HLS::REGION_DEFAULT,
										int         ii = 0,
                                        const char* name = "" ) {
                    _HLS_SCHEDULE_REGION( flags, ii, name );
                }

HLS_INLINE_DECL HLS_SCHEDULE_REGION(    const char* name ) {
                    _HLS_SCHEDULE_REGION( HLS::REGION_DEFAULT, 0, name );
                }

//
// HLS_SEPARATE_ARRAY
// 
HLS_DIR_DECL    HLS_SEPARATE_ARRAY( const void*     array,
                                    int             ndims = 1 )
                    HLS_DIR_BODY

//
// HLS_SET_ASYNC_RESET
// 
HLS_DIR_DECL    _HLS_SET_ASYNC_RESET(const void*    signal,
                                     bool           active_high )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_SET_ASYNC_RESET(const HLS_T1&   signal,
                                    bool            active_high = false ) {
                    _HLS_SET_ASYNC_RESET( &signal, active_high );
                }

//
// HLS_SET_CLOCK_PERIOD
// 

HLS_DIR_DECL    _HLS_SET_CLOCK_PERIOD(  const void* signal,
                                        double      period )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_SET_CLOCK_PERIOD(   const HLS_T1&   signal,
                                        double          period ) {
                    _HLS_SET_CLOCK_PERIOD( &signal, period );
                }

//
// HLS_SET_CYCLE_SLACK
// 
HLS_DIR_DECL    HLS_SET_CYCLE_SLACK(    double      time,
                                        const char* label = "" )
                    HLS_DIR_BODY

//
// HLS_SET_DEFAULT_INPUT_DELAY
// 
HLS_DIR_DECL    HLS_SET_DEFAULT_INPUT_DELAY(    double      delay,
                                                const char* label = "" )
                    HLS_DIR_BODY

//
// HLS_SET_DEFAULT_OUTPUT_OPTIONS
// 
HLS_DIR_DECL    HLS_SET_DEFAULT_OUTPUT_OPTIONS( HLS::HLS_OUTPUT_OPTIONS
                                                        option = HLS::SYNC_HOLD )
                    HLS_DIR_BODY

//
// HLS_SET_DEFAULT_OUTPUT_DELAY
// 
HLS_DIR_DECL    HLS_SET_DEFAULT_OUTPUT_DELAY(   double  delay )
                    HLS_DIR_BODY

//
// HLS_SET_INPUT_DELAY
// 
HLS_DIR_DECL    _HLS_SET_INPUT_DELAY(   const void* input,
                                        double      delay )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_SET_INPUT_DELAY(    const HLS_T1&   signal,
                                        double          delay,
                                        const char*     label = "" ) {
                    _HLS_SET_INPUT_DELAY( &signal, delay );
                }

//
// HLS_SET_OUTPUT_DELAY
// 
HLS_DIR_DECL    _HLS_SET_OUTPUT_DELAY(  const void*    output,
                                        double          delay )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_SET_OUTPUT_DELAY(   const HLS_T1&   output,
                                        double          delay ) {
                    _HLS_SET_OUTPUT_DELAY( &output, delay );
                }

//
// HLS_SET_OUTPUT_OPTIONS
// 
HLS_DIR_DECL    _HLS_SET_OUTPUT_OPTIONS( const void*    output,
                                        HLS::HLS_OUTPUT_OPTIONS
                                                        option )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_SET_OUTPUT_OPTIONS( const HLS_T1&   output,
                                        HLS::HLS_OUTPUT_OPTIONS
                                                        option = HLS::SYNC_HOLD,
                                        const char*     legacy_str = "" ) {
                    _HLS_SET_OUTPUT_OPTIONS( &output, option );
                }

//
// HLS_SET_ARE_BOUNDED
// 
HLS_DIR_DECL    _HLS_SET_ARE_BOUNDED( const void*    io1,
                                      const void*    io2,
                                      const char*    label )
                    HLS_DIR_BODY

template<typename HLS_T1, typename HLS_T2>
HLS_INLINE_DECL HLS_SET_ARE_BOUNDED( const HLS_T1&   io1,
                                     const HLS_T2&   io2,
                                     const char*     label = "" ) {
                    _HLS_SET_ARE_BOUNDED( &io1, &io2, label );
                }

//
// HLS_SET_IS_BOUNDED
// 
HLS_DIR_DECL    _HLS_SET_IS_BOUNDED( const void*    io,
                                     const char*    label )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_SET_IS_BOUNDED( const HLS_T1&   io,
                                    const char*     label = "" ) {
                    _HLS_SET_IS_BOUNDED( &io, label );
                }

//
// HLS_SET_STALL_VALUE
// 
HLS_DIR_DECL    _HLS_SET_STALL_VALUE( const void*   output,
                                      int           value,
                                      bool          is_global,
                                      void*         skip,
                                      void*         goes_with )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_SET_STALL_VALUE( const HLS_T1&  io,
                                     int            value,
                                     bool           is_global = true,
                                     void*          skip = 0,
                                     void*          goes_with = 0 ) {
                    _HLS_SET_STALL_VALUE( &io, value, is_global, skip, goes_with );
                }
//
// HLS_SET_SYNC_RESET
// 
HLS_DIR_DECL    _HLS_SET_SYNC_RESET(const void*     signal,
                                     bool           active_high )
                    HLS_DIR_BODY

template<typename HLS_T1>
HLS_INLINE_DECL HLS_SET_SYNC_RESET(const HLS_T1&    signal,
                                    bool            active_high = false ) {
                    _HLS_SET_SYNC_RESET( &signal, active_high );
                }

//
//  HLS_UNROLL_LOOP
//

HLS_DIR_DECL    _HLS_UNROLL_LOOP( HLS::HLS_UNROLL_OPTIONS 
                                                    option,
                                 int                count,
                                 const char*        label )
                    HLS_DIR_BODY

HLS_DIR_DECL    _HLS_UNROLL_LOOP( HLS::HLS_UNROLL_OPTIONS 
                                                    option,
                                 const char*        label )
                    HLS_DIR_BODY


HLS_INLINE_DECL HLS_UNROLL_LOOP( HLS::HLS_UNROLL_OPTIONS 
                                                    option,
                                 int                count,
                                 const char*        label="" ) {
                    _HLS_UNROLL_LOOP( option, count, label );
        }

HLS_INLINE_DECL HLS_UNROLL_LOOP( HLS::HLS_UNROLL_OPTIONS 
                                                    option = HLS::ON,
                                 const char*        label="" ) {
                    _HLS_UNROLL_LOOP( option, label );
        }


HLS_INLINE_DECL HLS_UNROLL_LOOP( const char*        label ) {
                    _HLS_UNROLL_LOOP( HLS::ON, label );
        }


};

#if defined( STRATUS_HLS ) || defined( STRATUS_VLG ) || defined( BDW_EXTRACT )

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* Definitions when Stratus tools are running, but not when g++ is compiling files.
*/
#define     HLS_INLINE_MODULE int hls_inline_module

#define     HLS_EXTERNAL_MODULE int hls_external_module

#define     HLS_SYNTHESIZE_MODULE int hls_synthesize_module

#define     HLS_METAPORT int hls_meta_port

#define     HLS_EXPOSE_PORT( on_off, port ) \
                HLS_EXPOSE_PORTS( on_off, port, port )

#define     HLS_EXPOSE_PORTS( on_off, start, end ) \
                hls_enum<on_off> hls_expose_ports_##start##_HLS_SEP_##end

#define     HLS_CAT_NAMES( n1, n2 ) n1

#define     HLS_SET_IS_RESET_BLOCK( label ) \
                    HLS_REMOVE_CONTROL( OFF, "hls_reset_block_" label ); \
                    HLS_DEFINE_PROTOCOL("hls_reset_block_" label )

#define      HLS_BREAK_LOOP( label ) { \
                    HLS_DEFINE_PROTOCOL("hls_break_loop" label ); \
                    wait(); }

#define      HLS_CREATE_STATE( label ) { \
                    HLS_DEFINE_PROTOCOL("hls_create_state" label ); \
                    wait(); }


HLS_DIR_DECL    HLS_SUPPRESS_MSG_SYM( unsigned int msgId, /* sym */ ... )
          HLS_DIR_BODY

#else // defined( STRATUS_HLS ) || defined( STRATUS_VLG ) || defined( BDW_EXTRACT )

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* Definitions when g++ is compiling files, but not when Stratus tools are running.
*/

#define     HLS_INLINE_MODULE
#define     HLS_EXTERNAL_MODULE
#define     HLS_SYNTHESIZE_MODULE
#define     HLS_METAPORT
#define     HLS_EXPOSE_PORTS( on_off, start, end )
#define     HLS_EXPOSE_PORT( on_off, port )
#define     HLS_SUPPRESS_MSG_SYM( id, sym, ... )
#define     HLS_SET_IS_RESET_BLOCK( label )
#define     HLS_BREAK_LOOP( label )
#define     HLS_CREATE_STATE( label )

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
* A convenience macro that can be used to build a name from two char* 
* strings.  A common application is for the formation of name strings
* for member ports in metaports where the metaport class is not an sc_module.
*/
#define     HLS_CAT_NAMES( n1, n2 ) \
                ( (n1 && *n1) ? ((const char*)n1 + std::string("_" n2)).c_str() : (const char*)n2 )

#endif // defined( STRATUS_HLS ) || defined( STRATUS_VLG ) || defined( BDW_EXTRACT )

#ifndef DONT_USE_NAMESPACE_HLS
using namespace HLS;
#endif

#endif // stratus_hls_h_INCLUDED
