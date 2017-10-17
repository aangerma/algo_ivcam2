/*****************************************************************************

                                    signal.h

    C++ compatible header file.

    $Id: signal.h,v 1.2 2009-04-07 18:26:40 deg Exp $

*****************************************************************************/

#ifndef _SIGNAL_H
#define _SIGNAL_H

/*  begin code shared with <csignal> */

typedef int sig_atomic_t;

typedef void (*__handler)(int);

#ifndef SIG_DFL
#define SIG_DFL (__handler)0
#endif

#ifndef SIG_ERR
#define SIG_ERR (__handler)-1
#endif

#ifndef SIG_IGN
#define SIG_IGN (__handler)1
#endif

#ifndef SIGABRT
#define SIGABRT 6
#endif

#ifndef SIGFPE
#define SIGFPE  8
#endif

#ifndef SIGILL
#define SIGILL  4
#endif

#ifndef SIGINT
#define SIGINT  2
#endif

#ifndef SIGSEGV
#define SIGSEGV 11
#endif

#ifndef SIGTERM
#define SIGTERM 15
#endif

extern __handler    signal(int sig, __handler);
extern int          raise(int sig);

/*  end code shared with <csignal> */

#endif  /* _SIGNAL_H */
