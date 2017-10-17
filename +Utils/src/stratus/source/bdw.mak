###########################################################
# Makefile to be included by BDW/ESC projects.
# For definitions of the variables that can be set to 
# affect this Makefile, see Makefile.sample
###########################################################


# Get the GCC Major Version from BDW_PLATFORM
BDW_GCC_MAJOR_VER = $(shell echo $(BDW_PLATFORM) | cut -d "." -f 3 | sed -e s/gcc//)
BDW_GCC_TARGET = $(shell gcc -dumpmachine | cut -d "-" -f 1)
BDW_SC_VERSION = $(shell echo $(BDW_PLATFORM) | cut -d "." -f 2 | sed -e s/SC//)

ifeq ($(BDW_64BITMODE),)
export BDW_64BITMODE
	ifeq ($(BDW_GCC_TARGET),x86_64)
		BDW_64BITMODE = 1
	else
		BDW_64BITMODE = 0
	endif
endif

ifeq ($(BDW_CCDEP),)
	BDW_CCDEP = g++
endif

############################################################
# Using Cadence NC Systemc requires an overrride of BDW_CC
# and BDW_LINK
############################################################
ifeq ($(BDW_NCSC_GCCVER),)
	BDW_NCSC_GCCVER = 4.1
endif
ifeq ($(BDW_NCSC), 1)
	BDW_INCISIVE_INFO := $(shell bdw_incisive_info)
ifeq ($(word 1,$(BDW_INCISIVE_INFO)), ERROR:)
else
	export BDW_INCISIVE_HOME := $(word 1, $(BDW_INCISIVE_INFO))
	BDW_INCISIVE_NEWLIB := $(word 2, $(BDW_INCISIVE_INFO))
	BDW_INCISIVE_INC := $(word 3, $(BDW_INCISIVE_INFO))
	BDW_INCISIVE_GCCARCH := $(word 4, $(BDW_INCISIVE_INFO))
endif
ifeq ($(BDW_64BITMODE), 1)
	export BDW_CC = ncsc -GCC_VERS $(BDW_NCSC_GCCVER) -64bit -manual -CFlags
	export BDW_LINK = $(BDW_INCISIVE_HOME)/tools/cdsgcc/gcc/$(BDW_NCSC_GCCVER)/bin/g++
	export BDW_CCDEP = $(BDW_INCISIVE_HOME)/tools/cdsgcc/gcc/$(BDW_NCSC_GCCVER)/bin/g++
	export BDW_NCSC_SYSTEMC_DIR = $(BDW_INCISIVE_HOME)/tools/systemc/lib/64bit/gnu
	export BDW_NCSC_SCV_DIR = $(BDW_INCISIVE_HOME)/tools/tbsc/lib/64bit/gnu
	export BDW_NCSC_INC_DIR = $(BDW_INCISIVE_HOME)/tools/systemc/include_pch
else
	export BDW_CC = ncsc -GCC_VERS $(BDW_NCSC_GCCVER) -manual -CFlags
	export BDW_LINK = $(BDW_INCISIVE_HOME)/tools/systemc/gcc/$(BDW_NCSC_GCCVER)/bin/g++
	export BDW_CCDEP = $(BDW_INCISIVE_HOME)/tools/systemc/gcc/$(BDW_NCSC_GCCVER)/bin/g++
	export BDW_NCSC_SYSTEMC_DIR = $(BDW_INCISIVE_HOME)/tools/systemc/lib/gnu
	export BDW_NCSC_SCV_DIR = $(BDW_INCISIVE_HOME)/tools/tbsc/lib/gnu
endif
endif

############################################################
# Using Mentor Vista requires an override of BDW_CC and BDW_LINK.
# and setting VISTA_SYSTEMC_VERSION and VISTA_GCC_VERSION to
# the right versions to be compatible with BDW_PLATFORM
############################################################
ifeq ($(BDW_VISTA),1)
	export BDW_CC = vista_c++
	export BDW_LINK = vista_c++
	export BDW_CCDEP = vista_c++

	ifeq ($(BDW_SC_VERSION),21)
		export VISTA_SYSTEMC_VERSION = 2.1v1
		BDW_VISTA_SYSTEMC = 21v1
	else
		export VISTA_SYSTEMC_VERSION = 2.2
		BDW_VISTA_SYSTEMC = 22
	endif
	ifeq ($(BDW_GCC_MAJOR_VER),3)
		export VISTA_GCC_VERSION = 3.3.5
		BDW_VISTA_GCC = 335
	else
		export VISTA_GCC_VERSION = 4.1.2
		BDW_VISTA_GCC = 412
	endif

	export BDW_VISTA_PATH = $(dir $(shell which vista) )/..

endif

############################################################
# setup stuff for Verilator trace files
############################################################
BDW_VERILATED_VCD := $(shell bdw_verilator_version vcd)

ifeq ($(BDW_VERILATED_VCD),1)
	BDW_VERILATOR_TRACE_OBJS = $(BDW_OBJDIR)/verilated_vcd_sc.o $(BDW_OBJDIR)/verilated_vcd_c.o
	BDW_VERILATED_VCD_DEF = -DUSE_VERILATED_VCD
else
	BDW_VERILATOR_TRACE_OBJS =
	BDW_VERILATED_VCD_DEF =
endif

############################################################
# Library and include subdirectories in a Novas installation 
# depend on SystemC and gcc versions.
############################################################
ifeq ($(BDW_WRITEFSDB), 1)
	export BDW_NOVAS_LIB_DIR := $(shell bdw_find_novas_install -systemc)
	export BDW_NOVAS_INC_DIR := $(shell bdw_find_novas_install -systemc_inc)
	ifeq ($(BDW_NCSC),1)
		export BDW_NOVAS_NCSC_VER := $(shell bdw_find_novas_install -ncscver)
	endif
# make sure the novas dirs are included first so we get the right headers
# since we have a copy in our $(STRATUS_HOME)/share/stratus/include directory
	ifeq ($(BDW_NCSC),1)
		BDW_INCLUDE = -I${BDW_NOVAS_INC_DIR} -DBDW_NCSC_VER=${BDW_NOVAS_NCSC_VER}
	else
		BDW_INCLUDE = -I${BDW_NOVAS_INC_DIR} -DBDW_NCSC_VER=0
	endif
else
	BDW_INCLUDE =
endif

ifeq ($(BDW_LOADHUB), 1)
	BDW_TARGETSUF=.x
else
	ifeq ($(BDW_ARCHIVELIB), 1)
		BDW_TARGETSUF=.a
	else
		ifeq ($(BDW_SHAREDLIB), 0)
			BDW_TARGETSUF=.x
		else
			BDW_TARGETSUF=.so
		endif
	endif
endif

BDW_INCLUDE	+=	-I${STRATUS_HOME}/share/stratus/include
BDW_CCFLAGS_TAIL =	-c ${BDW_CCOPTIONS} ${BDW_EXTRA_CCFLAGS} 
HUBSYNCOUTLANG = sc
ifeq ($(BDW_USEHUB), 1)
	HUB_OPT = -DBDW_HUB=1
endif
ifeq ($(BDW_USEVECTOR), 1)
	ifneq ($(SRCOS), win32)
		BDW_VECTOR_OPT = -DTRANS_VECTOR=1
	endif
endif

ifeq ($(BDW_DOCDIR), )
	BDW_DOCDIR		=	html
endif
ifeq ($(BDW_DOCTITLE), )
	BDW_DOCTITLE	=	"Hubsync-generated"
endif

ifeq ($(BDW_OBJDIR), )
	ifneq ($(BDW_COWARE), 1)
		ifneq ($(BDW_VISTA), 1)
			BDW_OBJDIR = .
		else
			BDW_OBJDIR = ./vista
		endif
	else
		BDW_OBJDIR = ./coware
	endif
endif

export BDW_GENDEPS		?= 1

BDW_OBJS		= $(addprefix $(BDW_OBJDIR)/, $(addsuffix .o, $(basename $(notdir $(BDW_SOURCES)))))
BDW_DEPS		= $(BDW_OBJS:.o=.d)

BDW_PERL = perl

ifeq ($(findstring CLEAN,$(MAKECMDGOALS)),)
	ifeq ($(findstring clean,$(MAKECMDGOALS)),)
		ifeq ($(findstring help,$(MAKECMDGOALS)),)
			ifeq ($(BDW_GENDEPS), 1)
				ifneq ($(BDW_DEPS), )
					-include $(BDW_DEPS)
				endif
			endif
		endif
	endif
endif

all			:	${BDW_BUILDTARGET} 


include		${STRATUS_HOME}/share/stratus/source/target.mak

ifeq ($(SRCOS), sunos5)
	BDW_SYSTEMC_LIBDIR = lib-gccsparcOS5
else 
ifeq ($(SRCOS), linux)
ifeq ($(BDW_64BITMODE),1)
	LIBDIR_NAME = lib/64bit
	BDW_SYSTEMC_LIBDIR = lib-linux64
	BDW_NOVASPLATFORM = LINUX64
else
	LIBDIR_NAME = lib
	BDW_SYSTEMC_LIBDIR = lib-linux
	BDW_NOVASPLATFORM = LINUX_GNU_32
endif
endif
endif

ifeq ($(BDW_DEBUG),1)
	BDW_USE_DEBUG_SYSTEMC = $(shell if [ -f "${SYSTEMC}/${BDW_SYSTEMC_LIBDIR}/libsystemc_debug.a" ] ; then echo "1"; else echo "0"; fi)
else
	BDW_USE_DEBUG_SYSTEMC = 0
endif

ifeq ($(BDW_DEBUG),1)
	BDW_USE_DEBUG_ESC = $(shell if [ -f "${STRATUS_HOME}/tools.${STRATUS_PLATFORM}/stratus/$(LIBDIR_NAME)/libesc_debug.a" ] ; then echo "1"; else echo "0"; fi)
else
	BDW_USE_DEBUG_ESC = 0
endif

BDW_HAS_SCV = $(shell if [ -f "${SYSTEMC}/${BDW_SYSTEMC_LIBDIR}/libscv.a" ] ; then echo "1"; else echo "0"; fi)
ifeq ($(BDW_HAS_SCV),1)
	BDW_SCV_LIB = -lscv
else
	BDW_SCV_LIB=
endif

ifeq ($(BDW_USE_SCV),) 
	BDW_USE_SCV=$(BDW_HAS_SCV)
endif

ifeq ($(SRCOS), win32)

	ifeq (${BDW_DEBUG}, 1)
		BDW_DEBUG_OPT	=	-Zi
		BDW_DEBUG_LINK	=	-DEBUG
	endif
	BDW_INCLUDE	+=	-I$(SYSTEMC)/include
	BDW_SYSTEMC_OPT	=	/Zm250 /ML /W3 /GR /GX /D_CONSOLE=1 /D_MBCS=1 /YX /DSC_FORK_NO_TEMP_SPCL=1
	ifeq (${BDW_CC}, )
		BDW_CC			=	cl.exe
	endif
	BDW_CCFLAGS_TAIL +=	/nologo ${BDW_INCLUDE} -DWIN32 ${BDW_SYSTEMC_OPT} ${BDW_DEBUG_OPT} ${HUB_OPT} $(BDW_VECTOR_OPT)
	BDW_CCASCPP		=	-TP
	BDW_COUT		=	/Fo
	ifeq (${BDW_LINK}, )
		BDW_LINK		=	link
	endif
	BDW_LINKARGS	=	$(DEBUG_LINK) /NODEFAULTLIB:LIBCMT.LIB
	ifeq ($(BDW_SHAREDLIB), 0)
		BDW_SHLIBFLAG	=	
	else
		BDW_SHLIBFLAG	=	-dll
	endif
	BDW_ARCHLIBS	=	
	BDW_LINKOUT		=	-out:
	HUBSYNC			=	${STRATUS_HOME}/bin/hubsync.exe
	BDW_HUBLIBS		=	${STRATUS_HOME}/tools.${STRATUS_PLATFORM}/stratus/$(LIBDIR_NAME)/hub.lib
	ifeq ($(BDW_SYSTEMCDEBUG), 1)
		BDW_HUBLIBS   +=  $(BDW_SYSTEMC)/msvc60/systemc/Debug/systemc.lib
	else
		BDW_HUBLIBS   +=  $(BDW_SYSTEMC)/msvc60/systemc/Release/systemc.lib
	endif
	ifeq ($(ESC_LIBNAME), )
		ESC_LIBNAME	=	libesc.lib
	endif
	ifneq ($(ESC_LIBNAME), )
	  BDW_HUBLIBS	+=	$(STRATUS_HOME)/tools.${STRATUS_PLATFORM}/stratus/$(LIBDIR_NAME)/$(ESC_LIBNAME)
	endif
	ifeq ($(ESC_USEHUB), 1)
		ifeq ($(ESC_USEVECTOR), 1)
			HUB_OPT +=	-GX
		endif
	endif
    BDW_AR = lib /nologo /out:
else
	# UNIX build.
	ifneq ($(BDW_COWARE), 1)
		ifneq ($(BDW_VISTA), 1)
			ifneq ($(BDW_NCSC), 1)
				BDW_INCLUDE	+=	-I$(SYSTEMC)/include
				ifneq ($(wildcard $(SYSTEMC)/include/tlm/*.h),)
					BDW_INCLUDE	+=	-I$(SYSTEMC)/include/tlm
				endif
			else
				BDW_INCLUDE += -I$(BDW_INCISIVE_HOME)/tools/systemc/include
				ifneq ($(wildcard $(BDW_INCISIVE_HOME)/tools/systemc/include/tlm2/*.h),)
					BDW_INCLUDE	+=	-I$(BDW_INCISIVE_HOME)/tools/systemc/include/tlm2
				else
					ifneq ($(wildcard $(BDW_INCISIVE_HOME)/tools/systemc/include/tlm/*.h),)
						BDW_INCLUDE	+=	-I$(BDW_INCISIVE_HOME)/tools/systemc/include/tlm
					endif
				endif
				BDW_INCLUDE += -I$(BDW_INCISIVE_HOME)/tools/tbsc/include
				ifeq ($(BDW_NCSC_GCCVER),4.1)
					BDW_INCLUDE += -I$(BDW_INCISIVE_INC)
				endif
			endif
		else
            # Include the OSCI headers for Vista so that Vista can find the TLM headers.
			ifeq ($(wildcard $(BDW_VISTA_PATH)/generic/tlm*),)
				BDW_INCLUDE +=  -I$(BDW_VISTA_PATH)/systemc-$(BDW_VISTA_SYSTEMC)-gcc$(BDW_VISTA_GCC)/include
			else 
				BDW_INCLUDE +=  -with-tlm1.0
			endif
		endif
	else
		BDW_INCLUDE	+=	-I${COWAREHOME}/common/include -I${COWAREHOME}/common/include/tlm
	endif
	SYSTEMC_OPT	=	-O3 -D_MBCS=1 -DSC_FORK_NO_TEMP_SPCL=0
	HUBSYNC		=	${STRATUS_HOME}/bin/hubsync
	ifeq ($(BDW_GCC_VERSION),)
		BDW_GCC_VERSION	:= $(shell gcc --version)
	endif
#
# For gcc 3.x, we need an extra define to resolve ambiguous operator overloads.
#
	ifneq ($(BDW_GCC_VERSION),2.95.3)
		BDW_CCFLAGS_TAIL += -DSC_FX_EXCLUDE_OTHER
	endif

	ifeq ($(SRCOS), linux)
		#  Build for Linux using gcc
		ifneq ($(BDW_64BITMODE),1)
			BDW_CCFLAGS_TAIL += -m32
		endif
		ifeq ($(BDW_WRITEFSDB), 1)
			ifeq ($(BDW_HAS_SCV),1) 
				BDW_FSDB_SCV_LIB = -l scv_tr_fsdb
				BDW_NCSC_FSDBLIBS = $(BDW_NOVAS_LIB_DIR)/libscv_tr_fsdb.so 
			endif
			BDW_HUBLIBS = -L ${STRATUS_HOME}/tools.${STRATUS_PLATFORM}/$(LIBDIR_NAME) \
						  -L ${STRATUS_HOME}/tools.${STRATUS_PLATFORM}/stratus/$(LIBDIR_NAME) \
			  -Wl,-Bdynamic -Wl,-rpath=${BDW_NOVAS_LIB_DIR} -L ${BDW_NOVAS_LIB_DIR} -l fsdbSC \
			  $(BDW_FSDB_SCV_LIB) $(BDW_ESC_LIBS) ${BDW_NOVAS_INST_DIR}/share/FsdbWriter/${BDW_NOVASPLATFORM}/libnffw.a 
			BDW_NCSC_FSDBLIBS += $(BDW_NOVAS_INST_DIR)/share/FsdbWriter/$(BDW_NOVASPLATFORM)/libnffw.a \
								 $(BDW_NOVAS_LIB_DIR)/libfsdbSC.so
		else
			BDW_HUBLIBS		=	-L ${STRATUS_HOME}/tools.${STRATUS_PLATFORM}/$(LIBDIR_NAME) \
								-L ${STRATUS_HOME}/tools.${STRATUS_PLATFORM}/stratus/$(LIBDIR_NAME) $(BDW_ESC_LIBS)
		endif
		ifeq (${BDW_DEBUG}, 1)
			BDW_DEBUG_OPT	=	-g
		endif
		ifneq ($(BDW_COWARE), 1) 
			ifeq ($(BDW_PRECOMP_ESC),1)
				ifneq ($(BDW_VISTA), 1)
					ifneq ($(BDW_NCSC), 1)
						ifeq ($(BDW_USE_DEBUG_ESC),1)
							BDW_ESC_LIBS = -lesc_debug
						else
							BDW_ESC_LIBS = -lesc
						endif
					else
						BDW_ESC_LIBS = -lescncsc
					endif
				else
					BDW_ESC_LIBS = -lescvista
				endif
			else
				BDW_ESC_LIBS =
			endif
		else
			ifeq ($(BDW_PRECOMP_ESC),1)
				BDW_ESC_LIBS = -lesccoware -lnffr -lnffw -llmgr_nomt_pic -lcrvs_pic -lFNPload_pic -llmgr_dongle_stub_pic -lsb_pic -lnsys -ltcl8.4 -lxml2 $(STRATUS_HOME)/tools.${STRATUS_PLATFORM}/stratus/$(LIBDIR_NAME)/lm_new_pic.o
			else
				BDW_ESC_LIBS = -lnffr -lnffw -llmgr_nomt_pic -lcrvs_pic -lFNPload_pic -llmgr_dongle_stub_pic -lsb_pic -lnsys -ltcl8.4 -lxml2 $(STRATUS_HOME)/tools.${STRATUS_PLATFORM}/stratus/$(LIBDIR_NAME)/lm_new_pic.o
			endif
		endif
		ifeq (${BDW_PROFILE}, 1)
			BDW_PROFILE_OPT	=	-pg -DPROFILE=1
		endif
		ifeq (${BDW_CC}, )
			BDW_CC			=	g++
		endif
		BDW_CCFLAGS_TAIL +=	-fPIC ${BDW_INCLUDE} ${BDW_DEBUG_OPT} ${HUB_OPT} ${PROFILE_OPT} $(VECTOR_OPT) 
		BDW_CCASCPP		=
		ifeq (${BDW_LINK}, )
			BDW_LINK		=	g++
		endif
		BDW_SHLIBFLAG	=	-shared -Wl,-Bsymbolic
		BDW_EXELINKFLAG =	-Wl,--export-dynamic
		ifneq ($(BDW_64BITMODE),1)
			BDW_SHLIBFLAG += -m32
			BDW_EXELINKFLAG += -m32
		endif
		ifeq ($(BDW_SHAREDLIB), 0)
			BDW_LINKARGS +=	$(BDW_EXELINKFLAG)
		else
			BDW_LINKARGS +=	$(BDW_SHLIBFLAG)
			BDW_LINKOUTFILTER = 2>&1 | ${BDW_PERL} ${STRATUS_HOME}/tools.${STRATUS_PLATFORM}/stratus/lib/hub_link_filter.pl
		endif
		BDW_COUT		=	-o #
		ifneq ($(BDW_COWARE), 1)
			ifneq ($(BDW_VISTA), 1)
				ifneq ($(BDW_NCSC), 1)
					ifeq ($(BDW_USE_DEBUG_SYSTEMC),1)
						SYSTEMC_LIB = -L ${SYSTEMC}/${BDW_SYSTEMC_LIBDIR} $(BDW_SCV_LIB) -lsystemc_debug 
					else
						SYSTEMC_LIB = -L ${SYSTEMC}/${BDW_SYSTEMC_LIBDIR} $(BDW_SCV_LIB) -lsystemc 
					endif
				else
				    ifeq ($(BDW_INCISIVE_NEWLIB),1)
						SYSTEMC_LIB = ${BDW_NCSC_SYSTEMC_DIR}/libscBootstrap_sh.so ${BDW_NCSC_SYSTEMC_DIR}/libncscCoroutines_sh.so ${BDW_NCSC_SYSTEMC_DIR}/libsystemc_sh.so ${BDW_NCSC_SCV_DIR}/libscv.so ${BDW_NCSC_SYSTEMC_DIR}/libncsctlm2_sh.so
					else
						SYSTEMC_LIB = ${BDW_NCSC_SYSTEMC_DIR}/libncscCoSim_sh.so ${BDW_NCSC_SYSTEMC_DIR}/libncscCoroutines_sh.so ${BDW_NCSC_SYSTEMC_DIR}/libsystemc_sh.so ${BDW_NCSC_SCV_DIR}/libscv.so ${BDW_NCSC_SYSTEMC_DIR}/libncsctlm2_sh.so
					endif
				endif
				BDW_HUBLIBS += ${SYSTEMC_LIB}
			else
				SYSTEMC_LIB = -L $(BDW_VISTA_PATH)/systemc-$(BDW_VISTA_SYSTEMC)-gcc$(BDW_VISTA_GCC)/lib-pic-linux $(BDW_SCV_LIB) -lsystemc
				BDW_HUBLIBS += ${SYSTEMC_LIB}
				BDW_CCFLAGS_TAIL += -DBDW_VISTA
			endif
		else
			SYSTEMC_LIB = -L ${COWAREHOME}/common/lib $(BDW_SCV_LIB) -lsystemc 
			BDW_HUBLIBS += ${SYSTEMC_LIB}
			BDW_CCFLAGS_TAIL	+= -DBDW_COWARE
		endif
		BDW_LDRELOC		=	-r
		BDW_ARCHLIBS	=	-lm -lcrypt -ldl
		BDW_LINKOUT		=	-o #
		ifneq ($(BDW_64BITMODE),1)
			BDW_LINKARGS += -m32
		endif

		#  end linux section
	endif
	ifeq ($(BDW_SHAREDLIB), 0)
		BDW_HUBLIBS	+=	-lhubexec -lhub 
	else
		ifeq ($(BDW_NCSC), 1)
			BDW_HUBLIBS	+=	-lhubexec -lhub
		endif
	endif
	BDW_HUBLIBS += -lbdw_st
    BDW_AR = ar r #
endif

#BDW_CCFLAGS_TAIL +=  -DDATE="`date -u +%m%d%H`"
ifneq ($(BDW_USE_SCV),)
	BDW_CCFLAGS_TAIL +=  -DBDW_USE_SCV=$(BDW_USE_SCV)
endif

BDW_CCFLAGS += $(BDW_CCFLAGS_TAIL)

# disable builtin default rules for .o files so ours will be used
%.o : %.c

%.o : %.cc

%.o : %.cpp

# Now our rules for .o files with dependency checking.

%.o			:	%.c 
ifeq ($(BDW_NCSC),1)
			${BDW_CC} "${BDW_COUT}$@ ${BDW_CCFLAGS}" $<
else
			${BDW_CC} ${BDW_COUT}$@ ${BDW_CCFLAGS} $<
endif

%.o			:	%.cc
ifeq ($(BDW_NCSC),1)
			${BDW_CC} "-TP ${BDW_COUT}$@ ${BDW_CCFLAGS}" $<
else
			${BDW_CC} -TP ${BDW_COUT}$@ ${BDW_CCFLAGS} $<
endif

%.o			:	%.cpp
ifeq ($(BDW_NCSC),1)
			${BDW_CC} "${BDW_COUT}$@ ${BDW_CCFLAGS}" $<
else
			${BDW_CC} ${BDW_COUT}$@ ${BDW_CCFLAGS} $<
endif

%.o			:	%.rav
			${HUBSYNC} $< -c -o$(HUBSYNCOUTLANG) $(@:.o=.cc)
			${BDW_CC} -TP ${BDW_COUT}$@ ${BDW_CCFLAGS} $(<:.rav=.cc)

%.h			:	%.rav
			${HUBSYNC} $< -o$(HUBSYNCOUTLANG) $@

%.d			: %.cc
			@echo "Generating dependencies for "$<
			@set -e; $(BDW_CCDEP) -MM -MG $(BDW_CCFLAGS) $< | sed 's|\($*\)\.o[ :]*|\1.o $@ : |' $(BDW_DEP_FILTER) > $@

%.d			: %.cpp
			@echo "Generating dependencies for "$<
			@set -e; $(BDW_CCDEP) -MM -MG $(BDW_CCFLAGS) $< | sed 's|\($*\)\.o[ :]*|\1.o $@ : |' $(BDW_DEP_FILTER) > $@

%.d			: %.c
			@echo "Generating dependencies for "$<
			@set -e; $(BDW_CCDEP) -MM -MG $(BDW_CCFLAGS) $< | sed 's|\($*\)\.o[ :]*|\1.o $@ : |' $(BDW_DEP_FILTER) > $@

${BDW_OBJDIR}/%.o	:	%.c
			@if [ ! -d ${BDW_OBJDIR} ]; then mkdir -p ${BDW_OBJDIR}; fi
ifeq ($(BDW_NCSC),1)
			${BDW_CC} "${BDW_COUT}$@ ${BDW_CCFLAGS}" $<
else
			${BDW_CC} ${BDW_COUT}$@ ${BDW_CCFLAGS} $<
endif

${BDW_OBJDIR}/%.o	:	%.cc
			@if [ ! -d ${BDW_OBJDIR} ]; then mkdir -p ${BDW_OBJDIR}; fi
ifeq ($(BDW_NCSC),1)
			${BDW_CC} "-TP ${BDW_COUT}$@ ${BDW_CCFLAGS}" $<
else
			${BDW_CC} -TP ${BDW_COUT}$@ ${BDW_CCFLAGS} $<
endif

${BDW_OBJDIR}/%.o	:	%.cpp
			@if [ ! -d ${BDW_OBJDIR} ]; then mkdir -p ${BDW_OBJDIR}; fi
ifeq ($(BDW_NCSC),1)
			${BDW_CC} "${BDW_COUT}$@ ${BDW_CCFLAGS}" $<
else
			${BDW_CC} ${BDW_COUT}$@ ${BDW_CCFLAGS} $<
endif

${BDW_OBJDIR}/%.o	:	%.rav
			@if [ ! -d ${BDW_OBJDIR} ]; then mkdir -p ${BDW_OBJDIR}; fi
			${HUBSYNC} $< -c -o$(HUBSYNCOUTLANG) $(@:.o=.cc)
			${BDW_CC} -TP ${BDW_COUT}$@ ${BDW_CCFLAGS} $(<:.rav=.cc)

${BDW_OBJDIR}/%.h	:	%.rav
			@if [ ! -d ${BDW_OBJDIR} ]; then mkdir -p ${BDW_OBJDIR}; fi
			${HUBSYNC} $< -o$(HUBSYNCOUTLANG) $@

${BDW_OBJDIR}/%.d	: %.cc
			@if [ ! -d ${BDW_OBJDIR} ]; then mkdir -p ${BDW_OBJDIR}; fi
			@echo "Generating dependencies for "$<
			@set -e; $(BDW_CCDEP) -MM -MG $(BDW_CCFLAGS) $< | sed 's|\($*\)\.o[ :]*|${BDW_OBJDIR}/\1.o $@ : |'  $(BDW_DEP_FILTER) > $@

${BDW_OBJDIR}/%.d	: %.cpp
			@if [ ! -d ${BDW_OBJDIR} ]; then mkdir -p ${BDW_OBJDIR}; fi
			@echo "Generating dependencies for "$<
			@set -e; $(BDW_CCDEP) -MM -MG $(BDW_CCFLAGS) $< | sed 's|\($*\)\.o[ :]*|${BDW_OBJDIR}/\1.o $@ : |'  $(BDW_DEP_FILTER) > $@

${BDW_OBJDIR}/%.d	: %.c
			@if [ ! -d ${BDW_OBJDIR} ]; then mkdir -p ${BDW_OBJDIR}; fi
			@echo "Generating dependencies for "$<
			@set -e; $(BDW_CCDEP) -MM -MG $(BDW_CCFLAGS) $< | sed 's|\($*\)\.o[ :]*|${BDW_OBJDIR}/\1.o $@ : |'  $(BDW_DEP_FILTER) > $@

#
# verilor trace file build rules
#
$(BDW_OBJDIR)/verilated_vcd_sc.o : $(VERILATOR_ROOT)/include/verilated_vcd_sc.cpp
	@if [ ! -d ${BDW_OBJDIR} ]; then mkdir -p ${BDW_OBJDIR}; fi
ifeq ($(BDW_NCSC),1)
	${BDW_CC} "${BDW_COUT}$@ ${BDW_CCFLAGS} -DUSE_STD_STRING -DSYSTEMC_VERSION=20070314" $<
else
	${BDW_CC} ${BDW_COUT}$@ ${BDW_CCFLAGS} $<
endif

$(BDW_OBJDIR)/verilated_vcd_c.o : $(VERILATOR_ROOT)/include/verilated_vcd_c.cpp
	@if [ ! -d ${BDW_OBJDIR} ]; then mkdir -p ${BDW_OBJDIR}; fi
ifeq ($(BDW_NCSC),1)
	${BDW_CC} "${BDW_COUT}$@ ${BDW_CCFLAGS} -DUSE_STD_STRING -DSYSTEMC_VERSION=20070314" $<
else
	${BDW_CC} ${BDW_COUT}$@ ${BDW_CCFLAGS} $<
endif


ifneq ($(BDW_ARCHIVELIB), 1)
${BDW_BUILDTARGET}	:	${BDW_OBJS} 
					${BDW_LINK} ${BDW_LINKARGS} $(BDW_LDFLAGS) \
						${BDW_OBJS} \
						${BDW_LINKOUT}$@ \
						${BDW_HUBLIBS} \
						${BDW_ARCHLIBS} \
						${BDW_LINKOUTFILTER}
else
${BDW_BUILDTARGET}	:	${BDW_OBJS}
					${AR}${BDW_BUILDTARGET} $^

endif
ifeq ($(BDW_DOCGEN), 1)
			@echo "Building documentation"
			-@if [ ! -d $(BDW_DOCDIR) ] ; then mkdir $(BDW_DOCDIR) ; fi
			-@for f in $(BDW_HOME)/etc/forte*; do cp $$f $(BDW_DOCDIR); done
			-@cp $(BDW_HOME)/etc/dot_clear.gif $(BDW_DOCDIR)
			-@cp $(BDW_HOME)/source/Doxyfile.cfg $(BDW_DOCDIR)
			-@chmod 666 $(BDW_DOCDIR)/*
			-@sed 's:DOCFILES:$(BDW_DOCFILES):g' $(BDW_DOCDIR)/Doxyfile.cfg > $(BDW_DOCDIR)/Doxyfile.cfg.tmp
			-@sed 's:DOCDIR:$(BDW_DOCDIR):g' $(BDW_DOCDIR)/Doxyfile.cfg.tmp > $(BDW_DOCDIR)/Doxyfile.cfg.tmp2
			-@sed 's:DOCTITLE:$(BDW_DOCTITLE):g' $(BDW_DOCDIR)/Doxyfile.cfg.tmp2 > $(BDW_DOCDIR)/Doxyfile.cfg
			-@rm $(BDW_DOCDIR)/Doxyfile.cfg.tmp $(BDW_DOCDIR)/Doxyfile.cfg.tmp2
			-@$(BDW_HOME)/bin/doxygen $(BDW_DOCDIR)/Doxyfile.cfg
endif

docs:
# If $(BDW_DOCDIR) == docs, this command will only execute if the docs directory does not exist
			@echo "Building documentation"
			-@if [ ! -d $(BDW_DOCDIR) ] ; then mkdir $(BDW_DOCDIR) ; fi
			-@for f in $(BDW_HOME)/etc/forte*; do cp $$f $(BDW_DOCDIR); done
			-@cp $(BDW_HOME)/etc/dot_clear.gif $(BDW_DOCDIR)
			-@cp $(BDW_HOME)/source/Doxyfile.cfg $(BDW_DOCDIR)
			-@chmod 666 $(DOCDIR)/*
			-@sed 's:DOCFILES:$(BDW_DOCFILES):g' $(BDW_DOCDIR)/Doxyfile.cfg > $(BDW_DOCDIR)/Doxyfile.cfg.tmp
			-@sed 's:DOCDIR:$(BDW_DOCDIR):g' $(BDW_DOCDIR)/Doxyfile.cfg.tmp > $(BDW_DOCDIR)/Doxyfile.cfg.tmp2
			-@sed 's:DOCTITLE:$(BDW_DOCTITLE):g' $(BDW_DOCDIR)/Doxyfile.cfg.tmp2 > $(BDW_DOCDIR)/Doxyfile.cfg
			-@rm $(BDW_DOCDIR)/Doxyfile.cfg.tmp $(BDW_DOCDIR)/Doxyfile.cfg.tmp2
			-@$(BDW_HOME)/bin/doxygen $(BDW_DOCDIR)/Doxyfile.cfg
