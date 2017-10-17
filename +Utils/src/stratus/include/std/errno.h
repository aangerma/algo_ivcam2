/*****************************************************************************

                                    errno.h

    C++ compatible header file.

    $Id: errno.h,v 1.2 2009-04-07 18:26:40 deg Exp $

*****************************************************************************/

#ifndef _ERRNO_H
#define _ERRNO_H

/*  begin code shared with <cerrno> */

#ifndef EDOM
#define EDOM    33
#endif

#ifndef EILSEQ
#define EILSEQ  88
#endif

#ifndef ERANGE
#define ERANGE  34
#endif

extern int errno;

/*  end code shared with <cerrno> */

#endif  /* _ERRNO_H */
