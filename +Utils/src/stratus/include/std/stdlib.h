/*****************************************************************************

                                    stdlib.h

    C++ compatible header file for use in compiling SystemC.

    $Id: stdlib.h,v 1.5 2014-02-23 18:23:33 acg Exp $

*****************************************************************************/

#ifndef _STDLIB_H
#define _STDLIB_H

#ifndef _GLOBAL_SIZE_T
#define _GLOBAL_SIZE_T
#   if defined(__x86_64) || defined(__EDG__)
        typedef unsigned long size_t;
#   else
        typedef unsigned int size_t;
#   endif
#endif /* _GLOBAL_SIZE_T */

/*  begin code shared with <cstdlib> */

/*  macros */

enum { EXIT_SUCCESS=0, EXIT_FAILURE=1, RAND_MAX=32767 };

extern unsigned char    __ctype[];
#define MB_CUR_MAX      __ctype[520]

#ifndef NULL
#define NULL 0
#endif /* NULL */

/*  types */

typedef struct {
        int     quot;
        int     rem;
} div_t;

typedef struct {
        long    quot;
        long    rem;
} ldiv_t;

/*  functions */

extern void abort(void);
extern int atexit(void (*)(void));
extern void exit(int);
extern char *getenv(const char *);
extern int system(const char *);

extern void *calloc(size_t nelem, size_t elsize);
extern void free(void *);
extern void *malloc(size_t);
extern void *realloc(void *, size_t);

extern double atof(const char *);
extern int atoi(const char *);
extern long int atol(const char *);
extern double strtod(const char *, char **);
extern long int strtol(const char *, char **, int);
extern unsigned long strtoul(const char *, char **, int);

extern int mbtowc(wchar_t *, const char *, size_t);
extern int mblen(const char *, size_t);
extern int wctomb(char *, wchar_t);

extern size_t mbstowcs(wchar_t *, const char *, size_t);
extern size_t wcstombs(char *, const wchar_t *, size_t);

extern void *bsearch(const void *key,
                     const void *base,
                     size_t nel,
                     size_t size,
                     int (*compar)(const void *, const void *));
extern void qsort(void *base,
                  size_t nel,
                  size_t width,
                  int (*compar)(const void *, const void *));

extern int abs(int);
extern div_t div(int numer, int denom);
extern long int labs(long);
extern ldiv_t ldiv(long int numer, long int denom);

extern int rand(void);
extern void srand(unsigned int);

/*  end code shared with <cstdlib> */

#endif /* _STDLIB_H */
