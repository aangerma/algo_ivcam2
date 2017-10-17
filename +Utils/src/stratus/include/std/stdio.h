/*****************************************************************************

                                    stdio.h

    C++ compatible header file for use in compiling [Extended] SystemC.

    $Id: stdio.h,v 1.5 2014-02-23 18:23:33 acg Exp $

*****************************************************************************/

#ifndef STDIO_H
#define STDIO_H

#include <stdarg.h>

#ifndef _GLOBAL_SIZE_T
#define _GLOBAL_SIZE_T
#   if defined(__x86_64) || defined(__EDG__)
        typedef unsigned long size_t;
#   else
        typedef unsigned int size_t;
#   endif
#endif /* _GLOBAL_SIZE_T */

/*  begin code shared with <cstdio> */

/*****************************************************************************

                                    macros

*****************************************************************************/

#define BUFSIZ          1024
#define FILENAME_MAX    1024
#define FOPEN_MAX       20
#define L_tmpnam        25

#ifndef EOF
#define EOF             (-1)
#endif  /* EOF */

#ifndef NULL
#define NULL 0
#endif /* NULL */

#define SEEK_CUR        1
#define SEEK_END        2
#define SEEK_SET        0

#define TMP_MAX         17576

#define _IOFBF          0000    /* full buffered */
#define _IOLBF          0100    /* line buffered */
#define _IONBF          0004    /* not buffered */

/*  
 *  these definitions are nonsense, but they make exporting __iob unnecessary
 */

#define stdin   (FILE *)0
#define stdout  (FILE *)0
#define stderr  (FILE *)0

/*****************************************************************************

                                    types

*****************************************************************************/

struct FILE {
    size_t          _cnt;
    unsigned char   *_ptr;
    unsigned char   *_base;
    unsigned char   _flag;
    unsigned char   _file;
    unsigned        _orientation:2;
    unsigned        _filler:6;
};

typedef long long fpos_t;

/*****************************************************************************

                                    functions

*****************************************************************************/

extern void     clearerr(FILE *);
extern int      fclose(FILE *);
extern int      feof(FILE *);
extern int      ferror(FILE *);
extern int      fflush(FILE *);
extern int      fgetc(FILE *);
extern int      fgetpos(FILE *, fpos_t *);
extern char     *fgets(char *, int, FILE *);
extern FILE     *fopen(const char *, const char *);
extern int      fprintf(FILE *, const char *, ...);
extern int      fputc(int, FILE *);
extern int      fputs(const char *, FILE *);
extern size_t   fread(void *, size_t, size_t, FILE *);
extern FILE     *freopen(const char *, const char *, FILE *);
extern int      fscanf(FILE *, const char *, ...);
extern int      fseek(FILE *, long, int);
extern int      fsetpos(FILE *, const fpos_t *);
extern long     ftell(FILE *);
extern size_t   fwrite(const void *, size_t, size_t, FILE *);
extern int      getc(FILE *);
extern int      getchar(void);
extern char     *gets(char *);
extern void     perror(const char *);
extern int      printf(const char *, ...);
extern int      putc(int, FILE *);
extern int      putchar(int);
extern int      puts(const char *);
extern int      remove(const char *);
extern int      rename(const char *, const char *);
extern void     rewind(FILE *);
extern int      scanf(const char *, ...);
extern void     setbuf(FILE *, char *);
extern int      setvbuf(FILE *, char *, int, size_t);
extern int      sprintf(char *, const char *, ...);
extern int      sscanf(const char *, const char *, ...);
extern FILE     *tmpfile(void);
extern char     *tmpnam(char *);
extern int      ungetc(int, FILE *);
extern int      vfprintf(FILE *, const char *, va_list);
extern int      vprintf(const char *, va_list);
extern int      vsprintf(char *, const char *, va_list);

/*  end code shared with <cstdio> */

#endif /* STDIO_H */
