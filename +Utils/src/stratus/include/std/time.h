/*****************************************************************************

                                    time.h

    C++ compatible header file for synthesis.

    $Id: time.h,v 1.3 2014-02-23 18:23:33 acg Exp $

*****************************************************************************/

#ifndef _TIME_H
#define _TIME_H

#ifndef _GLOBAL_SIZE_T
#define _GLOBAL_SIZE_T
#   if defined(__x86_64) || defined(__EDG__)
        typedef unsigned long size_t;
#   else
        typedef unsigned int size_t;
#   endif
#endif  /* _GLOBAL_SIZE_T */

/*  begin code shared with <ctime> */

#if __STDC_VERSION__ >= 199901L
#define RESTRICT restrict
#else
#define RESTRICT
#endif  /* __STDC_VERSION__ */

#ifndef NULL
#define NULL 0
#endif  /* NULL */

#define CLOCKS_PER_SEC 1000000

typedef long clock_t;

typedef long time_t;

struct tm {
    int tm_sec;
    int tm_min;
    int tm_hour;
    int tm_mday;
    int tm_mon;
    int tm_year;
    int tm_wday;
    int tm_yday;
    int tm_isdst;
};

extern clock_t      clock(void);
extern double       difftime(time_t, time_t);
extern time_t       mktime(struct tm *);
extern time_t       time(time_t *);
extern char *       asctime(const struct tm *);
extern char *       ctime(const time_t *);
extern struct tm *  gmtime(const time_t *);
extern struct tm *  localtime(const time_t *);
extern size_t       strftime(char * RESTRICT s,
                             size_t maxsize,
                             const char * RESTRICT format,
                             const struct tm * RESTRICT timeptr);

/*  end code shared with <ctime> */

#endif  /* _TIME_H */
