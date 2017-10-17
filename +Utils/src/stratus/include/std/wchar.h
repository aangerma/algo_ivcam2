/*****************************************************************************

                                    wchar.h

    C++ compatible header file for synthesis.

    $Id: wchar.h,v 1.3 2014-02-23 18:23:33 acg Exp $

*****************************************************************************/

#ifndef _WCHAR_H
#define _WCHAR_H

#include <stdarg.h>
#include <stdio.h>
#include <time.h>

#ifndef _GLOBAL_SIZE_T
#define _GLOBAL_SIZE_T
#   if defined(__x86_64) || defined(__EDG__)
        typedef unsigned long size_t;
#   else
        typedef unsigned int size_t;
#   endif
#endif  /* _GLOBAL_SIZE_T */

#ifndef _GLOBAL_WINT_T
#define _GLOBAL_WINT_T
typedef long wint_t;
#endif  /* _GLOBAL_WINT_T */

#ifndef _GLOBAL_MBSTATE_T
#define _GLOBAL_MBSTATE_T
typedef struct { int arr[6]; } mbstate_t;
#endif  /* _GLOBAL_MBSTATE_T */

/*  begin code shared with <cwchar> */

#if __STDC_VERSION__ >= 199901L
#define RESTRICT restrict
#else
#define RESTRICT
#endif  /*__STDC_VERSION__ */

#ifndef __cplusplus
typedef long wchar_t;   /* a keyword in C++ */
#endif  /* __cplusplus */

struct tm;

#ifndef NULL
#define NULL 0
#endif  /* NULL */

#define WCHAR_MIN   (-2147483647-1)
#define WCHAR_MAX   2147483647

#ifndef WEOF
#define WEOF        ((wint_t) (-1))
#endif  /* WEOF */

extern int  fwprintf(FILE * RESTRICT stream,
                     const wchar_t * RESTRICT format, ...);
extern int  fwscanf(FILE* RESTRICT stream,
                    const wchar_t * RESTRICT format, ...);
extern int  swprintf(wchar_t * RESTRICT s,
                     size_t n,
                     const wchar_t * RESTRICT format, ...);
extern int  swscanf(const wchar_t * RESTRICT s,
                    const wchar_t * RESTRICT format, ...);
extern int  vfwprintf(FILE * RESTRICT stream,
                      const wchar_t * RESTRICT format,
                      va_list arg);
extern int  vfwscanf(FILE * RESTRICT stream,
                     const wchar_t * RESTRICT format,
                     va_list arg);
extern int  vswprintf(wchar_t * RESTRICT s,
                      size_t n,
                      const wchar_t * RESTRICT format,
                      va_list arg);
extern int  vswscanf(const wchar_t * RESTRICT s,
                     const wchar_t * RESTRICT format,
                     va_list arg);
extern int  vwprintf(const wchar_t * RESTRICT format, va_list arg);
extern int  vwscanf(const wchar_t * RESTRICT format, va_list arg);
extern int  wprintf(const wchar_t * RESTRICT format, ...);
extern int  wscanf(const wchar_t * RESTRICT format, ...);

extern wint_t       fgetwc(FILE *);
extern wchar_t *    fgetws(wchar_t * RESTRICT s, int n, FILE * RESTRICT stream);
extern wint_t       fputwc(wchar_t c, FILE *stream);
extern int          fputws(const wchar_t * RESTRICT s, 
                           FILE * RESTRICT stream);
extern int          fwide(FILE *stream, int mode);
extern wint_t       getwd(FILE *);
extern wint_t       getwchar(void);
extern wint_t       putwd(wchar_t c, FILE *stream);
extern wint_t       putwchar(wchar_t);
extern wint_t       ungetwc(wint_t c, FILE *stream);

extern double       wcstod(const wchar_t * RESTRICT nptr,
                           wchar_t ** RESTRICT endptr);
extern float        wcstof(const wchar_t * RESTRICT nptr,
                           wchar_t ** RESTRICT endptr);
extern long double  wcstold(const wchar_t * RESTRICT nptr,
                            wchar_t ** RESTRICT endptr);

extern long int     wcstol(const wchar_t * RESTRICT nptr,
                           wchar_t ** RESTRICT endptr,
                           int base);
extern long long int    wcstoll(const wchar_t * RESTRICT nptr,
                                wchar_t ** RESTRICT endptr,
                                int base);
extern unsigned long int    wcstoul(const wchar_t * RESTRICT nptr,
                                    wchar_t ** RESTRICT endptr,
                                    int base);
extern unsigned long long int   wcstoull(const wchar_t * RESTRICT nptr,
                                         wchar_t ** RESTRICT endptr,
                                         int base);

extern wchar_t *    wcscpy(wchar_t * RESTRICT s1, 
                           const wchar_t * RESTRICT s2);
extern wchar_t *    wcsncpy(wchar_t * RESTRICT s1,
                            const wchar_t * RESTRICT s2,
                            size_t n);
extern wchar_t *    wmemcpy(wchar_t * RESTRICT s1,
                            const wchar_t * RESTRICT s2,
                            size_t n);
extern wchar_t *    wmemmove(wchar_t *s1, const wchar_t *s2, size_t n);
extern wchar_t *    wcscat(wchar_t * RESTRICT s1,
                           const wchar_t * RESTRICT s2);
extern wchar_t *    wcsncat(wchar_t * RESTRICT s1,
                            const wchar_t * RESTRICT s2,
                            size_t n);
extern int          wcscmp(const wchar_t *s1, const wchar_t *s2);
extern int          wcscoll(const wchar_t *s1, const wchar_t *s2);
extern int          wcsncmp(const wchar_t *s1, const wchar_t *s2, size_t n);
extern size_t       wcsxfrm(wchar_t * RESTRICT s1,
                            const wchar_t * RESTRICT s2,
                            size_t n);
extern int          wmemcmp(const wchar_t *s1, const wchar_t *s2, size_t n);
extern wchar_t *    wcschr(const wchar_t *s, wchar_t c);
extern size_t       wcscspn(const wchar_t *s1, const wchar_t *s2);
extern wchar_t *    wcspbrk(const wchar_t *s1, const wchar_t *s2);
extern wchar_t *    wcsrchr(const wchar_t *s, wchar_t c);
extern size_t       wcsspn(const wchar_t *s1, const wchar_t *s2);
extern wchar_t *    wcsstr(const wchar_t *s1, const wchar_t *s2);
extern wchar_t *    wcstok(wchar_t * RESTRICT s1,
                           const wchar_t * RESTRICT s2,
                           wchar_t ** RESTRICT ptr);
extern wchar_t *    wmemchr(const wchar_t *s, wchar_t c, size_t n);
extern size_t       wcslen(const wchar_t *);
extern wchar_t *    wmemset(wchar_t *s, wchar_t c, size_t n);

extern size_t       wcsftime(wchar_t * RESTRICT s,
                             size_t maxsize,
                             const wchar_t * RESTRICT format,
                             const struct tm * RESTRICT timeptr);

extern wint_t       btowc(int);
extern int          wctob(wint_t);
extern int          mbsinit(const mbstate_t *);
extern size_t       mbrlen(const char * RESTRICT s,
                           size_t n,
                           mbstate_t * RESTRICT ps);
extern size_t       mbrtowc(wchar_t * RESTRICT pwc,
                            const char * RESTRICT s,
                            size_t n,
                            mbstate_t * RESTRICT ps);
extern size_t       wcrtomb(char * RESTRICT s,
                            wchar_t wc,
                            mbstate_t * RESTRICT ps);
extern size_t       mbsrtowcs(wchar_t * RESTRICT dst,
                              const char ** RESTRICT src,
                              size_t len,
                              mbstate_t * RESTRICT ps);
extern size_t       wcsrtombs(char * RESTRICT dst,
                              const wchar_t ** RESTRICT src,
                              size_t len,
                              mbstate_t * RESTRICT ps);

/*  end code shared with <cwchar> */

#endif  /* _WCHAR_H */
