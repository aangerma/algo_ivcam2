/*****************************************************************************

                                    string.h

    C++ compatible header file for compiling SystemC.

    $Id: string.h,v 1.5 2014-02-23 18:23:33 acg Exp $

*****************************************************************************/

#ifndef _STRING_H
#define _STRING_H

/*  types */

#ifndef _GLOBAL_SIZE_T
#define _GLOBAL_SIZE_T
#   if defined(__x86_64) || defined(__EDG__)
        typedef unsigned long size_t;
#   else
        typedef unsigned int size_t;
#   endif
#endif /* _GLOBAL_SIZE_T */

/*  functions */

extern char *strchr(const char *s, int c);
extern char *strpbrk(const char *s1, const char *s2);
extern char *strrchr(const char *s, int c);
extern char *strstr(const char *s1, const char *s2);
extern void *memchr(const void *s, int c, size_t n);

/*  begin code shared with <cstring> */

/*  macros */

#ifndef NULL
#define NULL 0
#endif /* NULL */

/*  functions */

extern void *memcpy(void *s1, const void *s2, size_t n);
extern void *memmove(void *s1, const void *s2, size_t n);
extern char *strcpy(char *s1, const char *s2);
extern char *strncpy(char *s1, const char *s2, size_t n);

extern char *strcat(char *s1, const char *s2);
extern char *strncat(char *s1, const char *s2, size_t n);

extern int memcmp(const void *s1, const void *s2, size_t n);
extern int strcmp(const char *s1, const char *s2);
extern int strcoll(const char *s1, const char *s2);
extern int strncmp(const char *s1, const char *s2, size_t n);
extern size_t strxfrm(char *s1, const char *s2, size_t n);

extern size_t strcspn(const char *s1, const char *s2);
extern size_t strspn(const char *s1, const char *s2);
extern char *strtok(char *s1, const char *s2);

extern void *memset(void *s, int c, size_t n);
extern char *strerror(int errnum);
extern size_t strlen(const char *s);

/*  end code shared with <cstring> */

#endif /* _STRING_H */
