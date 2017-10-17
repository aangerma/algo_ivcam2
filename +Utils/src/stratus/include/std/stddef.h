/*****************************************************************************

                                    stddef.h

    C++ compatible header file for use in compiling SystemC.

    $Id: stddef.h,v 1.5 2014-02-23 18:23:33 acg Exp $

*****************************************************************************/

#ifndef _STDDEF_H
#define _STDDEF_H

/*  begin code shared with <cstddef> */

#ifndef _PTRDIFF_T
#define _PTRDIFF_T
typedef int ptrdiff_t;
#endif

#ifndef NULL
#define NULL 0
#endif

#define offsetof(s, m) (size_t)(&(((s *)0)->m))

/*  end code shared with <cstddef> */

#ifndef _GLOBAL_SIZE_T
#define _GLOBAL_SIZE_T
#   if defined(__x86_64) || defined(__EDG__)
        typedef unsigned long size_t;
#   else
        typedef unsigned int size_t;
#   endif
#endif

#endif  /* _STDDEF_H */
