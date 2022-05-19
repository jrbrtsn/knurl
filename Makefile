baseDir := $(HOME)/src
libsDir := $(baseDir)/lib
projectName := knurl
versions := debug  release
#libraries := libname
cc_exe := knurl
install_dir := $(HOME)/bin
link_version := $(shell date  +%Y-%m-%d_%H:%M:%S)


########################################
# Set up sources & libraries here.     #
########################################

ifeq ($(exe),knurl)
src := knurl.c
libs :=  m
endif

local_codeflags +=  \
   -std=gnu99 \
   -Wreturn-type \
   -Wformat \
   -Wchar-subscripts \
   -Wparentheses -Wcast-qual \
   -Wmissing-declarations \

local_ldflags += -L$(libsDir)/$(version)

########################################
# Set up custom compile flags here.    #
########################################
ifeq ($(version),debug)
local_cppflags += -D_DEBUG -DDEBUG
local_codeflags += -g2 -O0
endif

ifeq ($(version),release)
local_cppflags += -DNDEBUG
local_codeflags += -g0 -O3
endif

makefile := Makefile
ifndef version
.PHONY : all clean tidy install uninstall debug release
all :  debug release
debug  :
	@$(MAKE) version=debug exe=knurl mainType=CC --no-builtin-rules -f $(makefile) --no-print-directory
release  :
	@$(MAKE) version=release exe=knurl mainType=CC --no-builtin-rules -f $(makefile) --no-print-directory
install : release
	@strip release/knurl
	@[ $(install_dir)_foo = _foo ] || cp release/knurl $(install_dir)/
	@[ -e install.sh ] && INSTALLDIR=$(install_dir) INSTALLTYPE=$(install_type) sudo -E ./install.sh
uninstall :
clean :
	$(RM) -r $(versions) core *.bak *.tab.h *.tab.c *.yy.c *.yy.h
tidy :
	$(RM) $(foreach vs, $(versions), $(vs)/*.o $(vs)/*.d) core *.bak
endif
.DELETE_ON_ERROR :

ifdef version
roots := \
 $(patsubst %.cc, %, $(filter %.cc, $(src)))\
 $(patsubst %.cxx, %, $(filter %.cxx, $(src)))\
 $(patsubst %.cpp, %, $(filter %.cpp, $(src)))\
 $(patsubst %.C, %, $(filter %.C, $(src)))\
 $(patsubst %.c, %, $(filter %.c, $(src)))\
 $(patsubst %.f, %, $(filter %.f, $(src)))\
 $(patsubst %.for, %, $(filter %.for, $(src)))\
 $(patsubst %.sal, %, $(filter %.sal, $(src)))\
 $(patsubst %.asm, %, $(filter %.asm, $(src)))\
 $(patsubst %.h, qt_%, $(filter %.h, $(src)))

yacc_roots := $(patsubst %.y, %.tab, $(filter %.y, $(src)))
lex_roots := $(patsubst %.l, %.yy, $(filter %.l, $(src)))
obj := $(patsubst %, $(version)/%.o, $(roots) $(yacc_roots) $(lex_roots))
dep := $(patsubst %, $(version)/%.d, $(roots) $(yacc_roots) $(lex_roots))


ifdef exe #>>>>>>>>>>>> We are building an executable <<<<<<<<<<<<<<<<

ifndef mainType
$(version)/$(exe) : $(obj)
	@echo 'THE VARIABLE "mainType" MUST BE DEFINED TO: CXX or CC or FC'
endif

ifeq ($(mainType),CXX)
$(version)/$(exe) : $(obj)
	$(CXX) $(LDFLAGS) $(local_ldflags) $(obj) $(patsubst %, -l%, $(libs)) -o $@
endif # ifeq CXX

ifeq ($(mainType),CC)
$(version)/$(exe) : $(obj)
	$(CC) $(LDFLAGS) $(local_ldflags) $(obj) $(patsubst %, -l%, $(libs)) -o $@
endif # ifeq CC

ifeq ($(mainType),FC)
$(version)/$(exe) : $(obj)
	$(FC) $(LDFLAGS) $(local_ldflags) $(obj) $(patsubst %, -l%, $(libs)) -o $@
endif # ifeq FC
endif # ifdef exe


ifdef library #>>>>>>>>>>>> We are building a library <<<<<<<<<<<<<<<<
ifeq ($(libType),STATIC)
ifdef libsDir
$(libsDir)/$(version)/lib$(library).a : $(version)/lib$(library).a
	@[ -d $(libsDir)/$(version) ] || mkdir -p $(libsDir)/$(version)
	@ln -f -s `pwd`/$(version)/lib$(library).a $(libsDir)/$(version)/lib$(library).a

endif # ifdef libsDir

$(version)/lib$(library).a : $(obj)
	$(AR) $(ARFLAGS) $@ $(obj)
endif # ifeq STATIC

ifeq ($(libType),SHARED)
ifdef libsDir
$(libsDir)/$(version)/lib$(library) : $(version)/lib$(library)
	@[ -d $(libsDir)/$(version) ] || mkdir -p $(libsDir)/$(version)
	@ln -f -s `pwd`/$(version)/lib$(library) $(libsDir)/$(version)/lib$(library)

endif # ifdef libsDir
$(version)/lib$(library) : $(obj)
	g++ -shared -Wl,-soname,lib$(library) -o $@ $(obj)

local_codeflags += -fno-strength-reduce -fPIC
endif # ifeq SHARED

endif # ifdef library
#>>>>>>>>>>>>>>>>>>>> Finished library specific stuff <<<<<<<<<<<<<<<<<

# yacc stuff
yacc_h_output := $(patsubst %, %.h, $(yacc_roots))
yacc_c_output := $(patsubst %, %.c, $(yacc_roots))
yacc_output := $(yacc_h_output) $(yacc_c_output)

%.tab.c : %.y
	bison -d $< 
%.tab.h : %.y
	bison -d $< 

# lex stuff
lex_h_output := $(patsubst %, %.h, $(lex_roots))
lex_c_output := $(patsubst %, %.c, $(lex_roots))
lex_output := $(lex_h_output) $(lex_c_output)

%.yy.c: %.l
	flex -o $*.yy.c --header-file=$*.yy.h $< 
%.yy.h: %.l
	flex -o $*.yy.c --header-file=$*.yy.h $< 

# Make sure the build directory exists
$(dep) : | $(version)

$(version) :
	@mkdir $(version)

# Dependency files rule
$(dep) : $(yacc_output) $(lex_output)

### Recipes to build .d files ###
# This script used to fixup the dependency output from GCC
define sed_dep_fixup_cmd
sed -E 's#^$(notdir $*).o[ :]+#$(version)/$*.o $(version)/$*.d : #'
endef

# C++ has 4 different accepted source file suffixes. Sheesh!
define recipe_cxx_dep
@set -e; [ -d $(@D) ] || mkdir -p $(@D) \
; $(CXX) -M $(CPPFLAGS) $(local_cxxflags) $(local_cppflags) $< \
| $(sed_dep_fixup_cmd) > $@
endef
$(version)/%.d: %.cc
	@$(recipe_cxx_dep)
$(version)/%.d: %.cxx
	@$(recipe_cxx_dep)
$(version)/%.d: %.cpp
	@$(recipe_cxx_dep)
$(version)/%.d: %.C
	@$(recipe_cxx_dep)

$(version)/%.d: %.c
	@set -e; [ -d $(@D) ] || mkdir -p $(@D) \
	; $(CC) -M $(CPPFLAGS) $(local_cppflags) $< \
	| $(sed_dep_fixup_cmd) > $@

$(version)/%.d: %.f
	@echo $(patsubst %.f, $(version)/%.o, $<) : $< > $@

$(version)/%.d: %.for
	@echo $(patsubst %.for, $(version)/%.o, $<) : $< > $@

$(version)/qt_%.d: %.h
	@echo $(patsubst %.h, $(version)/qt_%.cxx, $<) : $< > $@

$(version)/%.d: %.sal
	@echo $(patsubst %.sal, $(version)/%.s, $<) : $< > $@

$(version)/%.d: %.asm
	@echo $(patsubst %.asm, $(version)/%.s, $<) : $< > $@

# The .d files contain specific prerequisite dependencies
-include $(patsubst %, $(version)/%.d, $(roots) $(yacc_roots) $(lex_roots))

# Recipes to build object files
define recipe_cxx_compile
$(CXX) -c $(CXXFLAGS) $(local_cxxflags) $(local_codeflags) $(CPPFLAGS) $(local_cppflags)
endef
$(version)/%.o: %.cc
	$(recipe_cxx_compile) $< -o $@
$(version)/%.o: %.cxx
	$(recipe_cxx_compile) $< -o $@
$(version)/%.o: %.cpp
	$(recipe_cxx_compile) $< -o $@
$(version)/%.o: %.C
	$(recipe_cxx_compile) $< -o $@

$(version)/%.o: %.c
	$(CC) -c $(CCFLAGS) $(local_codeflags) $(CPPFLAGS) $(local_cppflags) $< -o $@

$(version)/%.o: %.f
	$(FC) -c $(FFLAGS) $(local_codeflags) $< -o $@
$(version)/%.o: %.for
	$(FC) -c $(FFLAGS) $(local_codeflags) $< -o $@

$(version)/qt_%.o: %.h
	$(QTDIR)/bin/moc $< -o $(version)/qt_$*.cxx
	$(CXX) -c $(CXXFLAGS) $(local_cxxflags) $(local_codeflags) $(CPPFLAGS) $(local_cppflags) $(version)/qt_$*.cxx -o $(version)/qt_$*.o

endif # version
