/*****************************************************************************

                                    wctype.h

    C++ compatible header file for synthesis.

    $Id: wctype.h,v 1.2 2009-04-07 18:26:40 deg Exp $

*****************************************************************************/

#ifndef _WCTYPE_H
#define _WCTYPE_H

#ifndef _GLOBAL_WINT_T
#define _GLOBAL_WINT_T
typedef long wint_t;
#endif  /* _GLOBAL_WINT_T */

/*  begin code shared with <cwctype> */

typedef unsigned int wctrans_t;
typedef int wctype_t;

#ifndef WEOF
#define WEOF        ((wint_t) (-1))
#endif  /* WEOF */

extern int          iswalnum(wint_t);
extern int          iswalpha(wint_t);
extern int          iswblank(wint_t);
extern int          iswcntrl(wint_t);
extern int          iswdigit(wint_t);
extern int          iswgraph(wint_t);
extern int          iswlower(wint_t);
extern int          iswprint(wint_t);
extern int          iswpunct(wint_t);
extern int          iswspace(wint_t);
extern int          iswupper(wint_t);
extern int          iswxdigit(wint_t);
extern int          iswctype(wint_t, wctype_t);
extern wctype_t     wctype(const char *);
extern wint_t       towlower(wint_t);
extern wint_t       towupper(wint_t);
extern wint_t       towctrans(wint_t, wctrans_t);
extern wctrans_t    wctrans(const char *);

/*  end code shared with <cwctype> */

#endif  /* _WCTYPE_H */
