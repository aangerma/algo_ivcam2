#
#	This Makefile builds the esc and systemc verification class libraries.
#
#	Usage is:
#		make		Builds the esc library and places it in $BDW_HOME/lib
#		make clean	Removes build targets to prepare for a fresh build.
#

BDW_PROJECT 	=   libesc
BDW_SOURCES     =   esc_utils.o esc_hub.o esc_cosim.o esc_type.o esc_elab.o esc_cleanup.o esc_watcher.o

ifeq ($(BDW_DEBUG), )
  BDW_DEBUG		=	0
endif

BDW_USEHUB		=	0
BDW_USEVECTOR	=	0
BDW_USEHUB		=	1
BDW_GENDEPS		=	0

include target.mak

#
# Include bdw.mak for cross-platform build support.
#
include		${STRATUS_SHARE}/source/bdw.mak

ifeq ($(SRCOS), win32)
  ESC_LIBNAME = libesc.lib
  ESCCOWARE_LIBNAME =
  ESCVISTA_LIBNAME =
else
  ifeq ($(BDW_DEBUG),0)
	  ESC_LIBNAME = libesc.a
  else
	  ESC_LIBNAME = libesc_debug.a
  endif
  ESCCOWARE_LIBNAME = libesccoware.a
  ESCVISTA_LIBNAME = libescvista.a
  ESCNCSC_LIBNAME = libescncsc.a
endif

ifeq ($(SRCOS), win32)
  AR = lib /nologo /out:
  AR_TABLE = lib /list
  AR_EXTRACT = lib /extract
else
  AR_TABLE = ar t
  AR_EXTRACT = ar x
  AR = ar r #
endif

ifeq ($(BDW_64BITMODE),1)
LIBDIR_NAME = lib64
BINDIR_NAME = bin64
TR_LINKARG = 
else
LIBDIR_NAME = lib
BINDIR_NAME = bin
TR_LINKARG = -m32
endif

all :
ifneq ($(SYSTEMC), )
	@echo "Building ESC using SYSTEMC - $(SYSTEMC)"
ifeq ($(DEBUG), 1)
	@echo "libesc will include debugging symbols"
else
	@echo "libesc will not include debugging symbols"
endif
	-@$(MAKE) esc --no-print-directory BDW_COWARE=0
else
	@echo "SYSTEMC not set - skipping build of ESC."
endif
ifneq ($(COWAREHOME), )
	@echo "Building ESC for Coware using COWAREHOME - $(COWAREHOME)"
ifeq ($(DEBUG), 1)
	@echo "libesccoware will include debugging symbols"
else
	@echo "libesccoware will not include debugging symbols"
endif
	-@$(MAKE) esc --no-print-directory BDW_COWARE=1
else
	@echo "COWAREHOME not set - skipping build of ESC for Coware."
endif
ifeq ($(BDW_VISTA), 1)
	@echo "Building ESC for Vista using BDW_VISTA_PATH - $(BDW_VISTA_PATH)"
ifeq ($(DEBUG), 1)
	@echo "libescvista will include debugging symbols"
else
	@echo "libescvista will not include debugging symbols"
endif
	-@$(MAKE) esc --no-print-directory BDW_COWARE=0 BDW_VISTA=1 
else
	@echo "BDW_VISTA not set - skipping build of ESC for Vista."
endif
ifneq ($(SYSTEMC), )
	@echo "Building esc_transRomData"
	-@$(MAKE) $(BDW_HOME)/$(BINDIR_NAME)/esc_transRomData
else
	@echo "SYSTEMC not set - skipping build of esc_transRomData"
endif

ifeq ($(BDW_COWARE), 1)
esc : $(BDW_HOME)/$(LIBDIR_NAME)/$(ESCCOWARE_LIBNAME)
else
ifeq ($(BDW_VISTA), 1)
esc : $(BDW_HOME)/$(LIBDIR_NAME)/$(ESCVISTA_LIBNAME)
else
ifeq ($(BDW_NCSC), 1)
esc : $(BDW_HOME)/$(LIBDIR_NAME)/$(ESCNCSC_LIBNAME)
else
esc : $(BDW_HOME)/$(LIBDIR_NAME)/$(ESC_LIBNAME)
endif
endif
endif

ifneq ($(CYNTH_HOME),)
BDW_CCFLAGS             += -I${CYNTH_HOME}/include
else
BDW_CCFLAGS             += -DBDW_NO_CYNTH=1
endif



$(ESC_LIBNAME): $(BDW_OBJS)
	$(AR)$(ESC_LIBNAME) $(BDW_OBJS)

LIBBDW_OBJS = $(shell $(AR_TABLE) $(BDW_HOME)/$(LIBDIR_NAME)/libbdw.a)
LIBHUB_OBJS = $(shell $(AR_TABLE) $(BDW_HOME)/$(LIBDIR_NAME)/libhub.a)

$(ESCCOWARE_LIBNAME): $(BDW_OBJS) $(BDW_HOME)/$(LIBDIR_NAME)/libbdw.a $(BDW_HOME)/$(LIBDIR_NAME)/libhub.a
	$(AR_EXTRACT) $(BDW_HOME)/$(LIBDIR_NAME)/libbdw.a
	$(AR_EXTRACT) $(BDW_HOME)/$(LIBDIR_NAME)/libhub.a
	$(AR)$(ESCCOWARE_LIBNAME) $(BDW_OBJS) $(LIBBDW_OBJS) $(LIBHUB_OBJS)

$(ESCVISTA_LIBNAME): $(BDW_OBJS)
	$(AR)$(ESCVISTA_LIBNAME) $(BDW_OBJS)

$(ESCNCSC_LIBNAME): $(BDW_OBJS)
	$(AR)$(ESCNCSC_LIBNAME) $(BDW_OBJS)

$(BDW_HOME)/$(LIBDIR_NAME)/$(ESC_LIBNAME) : $(ESC_LIBNAME)
	cp $(ESC_LIBNAME) $(BDW_HOME)/$(LIBDIR_NAME)

$(BDW_HOME)/$(LIBDIR_NAME)/$(ESCCOWARE_LIBNAME) : $(ESCCOWARE_LIBNAME)
	cp $(ESCCOWARE_LIBNAME) $(BDW_HOME)/$(LIBDIR_NAME)

$(BDW_HOME)/$(LIBDIR_NAME)/$(ESCVISTA_LIBNAME) : $(ESCVISTA_LIBNAME)
	cp $(ESCVISTA_LIBNAME) $(BDW_HOME)/$(LIBDIR_NAME)

$(BDW_HOME)/$(LIBDIR_NAME)/$(ESCNCSC_LIBNAME) : $(ESCNCSC_LIBNAME)
	cp $(ESCNCSC_LIBNAME) $(BDW_HOME)/$(LIBDIR_NAME)

  
transRomData : $(STRATUS_BIN_BIT_DIR)/esc_transRomData

$(STRATUS_BIN_BIT_DIR)/esc_transRomData : esc_transRomData
	cp $< $@

esc_transRomData : esc_transRomData.cc
ifeq ($(BDW_OS_DIR),)
	$(BDW_LINK) $(TR_LINKARG) $< -o $@ -I $(CYNTH_HOME)/include -I $(SYSTEMC)/include $(SYSTEMC_LIB)
else
	$(BDW_LINK) $(TR_LINKARG) $< -o $@ -I $(CYNTH_HOME)/include -I $(FORTE_TOOLS)/$(BDW_OS_DIR)/include -I $(SYSTEMC)/include $(SYSTEMC_LIB)
endif
#	set
#	echo $(BDW_LINK) $< -o $@ -I $(CYNTH_HOME)/include -I $(SYSTEMC)/include $(SYSTEMC_LIB)

cleancommon : 
	rm -f *.o *.so *.exp *.ilk *.pdb *.pch esc_transRomData

clean : cleancommon
ifeq ($(BDW_COWARE), 1)
	rm -rf $(ESCCOWARE_LIBNAME) $(BDW_HOME)/$(LIBDIR_NAME)/$(ESCCOWARE_LIBNAME) coware
else
ifneq ($(BDW_VISTA_PATH), )
	rm -rf $(ESCVISTA_LIBNAME) $(BDW_HOME)/$(LIBDIR_NAME)/$(ESCVISTA_LIBNAME) vista
else
ifneq ($(BDW_NCSC), )
	rm -f $(ESC_LIBNAME) $(BDW_HOME)/$(LIBDIR_NAME)/$(ESCNCSC_LIBNAME)
else
	rm -f $(ESC_LIBNAME) $(BDW_HOME)/$(LIBDIR_NAME)/$(ESC_LIBNAME)
endif
endif
endif

clean_all : cleancommon
	rm -rf $(ESCCOWARE_LIBNAME) $(BDW_HOME)/$(LIBDIR_NAME)/$(ESCCOWARE_LIBNAME) coware
	rm -rf $(ESCVIST_LIBNAME) $(BDW_HOME)/$(LIBDIR_NAME)/$(ESCVIST_LIBNAME) vist
	rm -f $(ESC_LIBNAME) $(BDW_HOME)/$(LIBDIR_NAME)/$(ESC_LIBNAME)
