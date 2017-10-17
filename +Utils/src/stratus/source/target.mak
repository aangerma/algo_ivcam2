  
HOST			:= $(shell uname)
OSNUM			:= $(shell uname -m)

ifeq ($(HOST), Linux)
  SRCOS			= linux
else
ifeq ($(HOST), SunOS)
  SRCOS			= sunos5
  OSVER			= $(shell uname -r)
endif
endif
