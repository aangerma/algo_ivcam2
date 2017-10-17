/*****************************************************************************

                                    setjmp.h

    C++ compatible header file.

    $Id: setjmp.h,v 1.2 2009-04-07 18:26:40 deg Exp $

*****************************************************************************/

#ifndef _SETJMP_H
#define _SETJMP_H

/*  begin code shared with <csetjmp> */

typedef int jmp_buf[12];

extern int  setjmp(jmp_buf);
extern void longjmp(jmp_buf, int);

/*  end code shared with <csetjmp> */

#endif  /* _SETJMP_H */
