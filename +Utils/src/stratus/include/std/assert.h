/*****************************************************************************

                                    assert.h

    C++ compatible header file for use in compiling SystemC.

    $Id: assert.h,v 1.3 2005-06-15 22:55:13 deg Exp $

*****************************************************************************/

#undef assert

#ifdef NDEBUG

#define assert(e) ((void) 0)

#else /* NDEBUG */

#define assert(e) ((void)((e) || \
 (printf("%s:%u: assertion failure\n", __FILE__, __LINE__), abort(), 0)))

#endif /* NDEBUG */
