/*****************************************************************************

                                    stdarg.h

    C++ compatible header file for synthesis.

    $Id: stdarg.h,v 1.2 2009-04-07 18:26:40 deg Exp $

*****************************************************************************/

#ifndef _STDARG_H
#define _STDARG_H

/*  begin code shared with <cstdarg> */

#define va_arg(list, mode) \
        ((mode *)(list = (void *)((char *)list + sizeof (mode))))[-1]

#define va_end(list) (void)0

#define va_start(list, name) (void) (list = (void *)((char *)&name + \
        ((sizeof (name) + (sizeof (int) - 1)) & ~(sizeof (int) - 1))))

/*  end code shared with <cstdarg> */

#ifndef _GLOBAL_VA_LIST
#define _GLOBAL_VA_LIST
typedef void *va_list;
#endif  /* _GLOBAL_VA_LIST */

#endif  /* _STDARG_H */
