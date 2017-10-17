/*****************************************************************************

                                    ctype.h

    C++ compatible header file.

    $Id: ctype.h,v 1.2 2009-04-07 18:26:40 deg Exp $

*****************************************************************************/

#ifndef _CTYPE_H
#define _CTYPE_H

/*  begin code shared with <cctype> */

extern int isalnum(int);
extern int isalpha(int);
extern int isblank(int);
extern int iscntrl(int);
extern int isdigit(int);
extern int isgraph(int);
extern int islower(int);
extern int isprint(int);
extern int ispunct(int);
extern int isspace(int);
extern int isupper(int);
extern int isxdigit(int);
extern int tolower(int);
extern int toupper(int);

/*  end code shared with <cctype> */

#endif  /* _CTYPE_H */
