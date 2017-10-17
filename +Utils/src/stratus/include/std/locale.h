/*****************************************************************************

                                    locale.h

    C++ compatible header file.

    $Id: locale.h,v 1.2 2009-04-07 18:26:40 deg Exp $

*****************************************************************************/

#ifndef _LOCALE_H
#define _LOCALE_H

/*  begin code shared with <clocale> */

struct lconv {
    char *decimal_point;
    char *thousands_sep;
    char *grouping;
    char *mon_decimal_point;
    char *mon_thousands_sep;
    char *mon_grouping;
    char *positive_sign;
    char *negative_sign;
    char *currency_symbol;
    char frac_digits;
    char p_cs_prededes;
    char n_cs_predeces;
    char p_sep_by_space;
    char n_sep_by_space;
    char p_sign_posn;
    char n_sign_posn;
    char *int_curr_symbol;
    char int_frac_digits;
    char int_p_cs_precedes;
    char int_n_cs_precedes;
    char int_p_sep_by_space;
    char int_n_sep_by_space;
    char int_p_sign_posn;
    char int_n_sign_posn;
};

#ifndef NULL
#define NULL 0
#endif  /* NULL */

#ifndef LC_ALL
#define LC_ALL      6
#endif

#ifndef LC_COLLATE
#define LC_COLLATE  3
#endif

#ifndef LC_CTYPE
#define LC_CTYPE    0
#endif

#ifndef LC_MONETARY
#define LC_MONETARY 4
#endif

#ifndef LC_NUMERIC
#define LC_NUMERIC  1
#endif

#ifndef LC_TIME
#define LC_TIME     2
#endif

extern char *setlocale(int category, const char *locale);
extern struct lconv *localeconv(void);

/*  end code shared with <clocale> */

#endif  /* _LOCALE_H */
