# =====================================
# Makefile to build NEMO Python wrapper
# =====================================
WRAPPER_HOME := $(shell pwd)
ARCH_FCM     := $(WRAPPER_HOME)/../BLD/arch_nemo.fcm
CPP_FCM      := $(WRAPPER_HOME)/../BLD/cpp.fcm
ARCH         := arch_nemo.mk

NEMO_LIB     := libnemo.so
TEST_LIB     := libnemo_test.so

export SRC_DIR      = $(WRAPPER_HOME)/src/c_bind
export OBJ_DIR      = $(WRAPPER_HOME)/build/fortran
export INC_DIR      = $(WRAPPER_HOME)/build/include
export LIB_DIR      = $(WRAPPER_HOME)/build/lib
export PY_DIR       = $(WRAPPER_HOME)/build/python
export NEMO_INC_DIR = $(WRAPPER_HOME)/../BLD/inc
export NEMO_OBJ_DIR = $(WRAPPER_HOME)/../BLD/obj

NEMO_OBJ = $(wildcard $(NEMO_OBJ_DIR)/*.o)
OBJ = nemo_api.o utils.o nemo_c_bind.o 
TEST_OBJ = test_nemo_c_bind.o

###########################################
###########################################
-include $(ARCH)

all: $(ARCH)
	@if [ ! -f $(ARCH) ]; then \
		$(MAKE) --no-print-directory all; \
	else \
		echo "   >>> Compile shared NEMO library"; \
		echo "   -------------------------------"; \
		$(MAKE) --no-print-directory build; \
	fi

build: dirs $(NEMO_LIB) $(TEST_LIB)


## ---------------------------------------
## Compilation environment
## ---------------------------------------
$(ARCH): $(ARCH_FCM)
	@echo "   >>> Copy NEMO arch file"
	@sed -E \
	   -e '/^%[A-Za-z0-9_]+[[:space:]]*$$/d' \
	   -e 's/^%([A-Za-z0-9_]+)[[:space:]]+(.*)/\1 = \2/' \
	   -e 's/%([A-Za-z0-9_]+)/$$(\1)/g' \
	   $< > $@
	@echo "   >>> Extracting CPP keys"
	@awk '/fppkeys/ { printf "CPP_KEYS ="; for(i=2;i<=NF;i++) printf " -D%s", $$i; printf "\n"; }' $(CPP_FCM) >> $@

dirs:
	@mkdir -p $(LIB_DIR) $(OBJ_DIR) $(INC_DIR) $(PY_DIR)	


## ---------------------------------------
## Compilation of NEMO as shared library
## ---------------------------------------
$(NEMO_LIB): $(OBJ)
	$(FC) -shared $(FFLAGS) -o $(LIB_DIR)/$@ $(addprefix $(OBJ_DIR)/,$^) $(NEMO_OBJ) $(USER_LIB)
	@echo "      > DONE shared NEMO"
	@echo "   -------------------------------"

$(TEST_LIB): $(TEST_OBJ)
	$(FC) -shared $(FFLAGS) -o $(LIB_DIR)/$@ $(addprefix $(OBJ_DIR)/,$^)
	@echo "      > DONE test compilation"
	@echo "   -------------------------------"

%.o: $(SRC_DIR)/%.f90
	$(FC) -$(CPP) $(CPP_KEYS) $(FFLAGS) -c $< -o $(OBJ_DIR)/$@ -J $(INC_DIR) -I $(NEMO_INC_DIR) -I $(INC_DIR) $(USER_INC)


## ---------------------------------------------------
## Compilation of shared-NEMO Python layer in dev mode
## ---------------------------------------------------
dev: dirs
	@echo "   >>> Compile in dev mode"
	python3 setup.py build_ext --build-lib=$(LIB_DIR) --build-temp=$(PY_DIR)
	@echo "      > DONE dev compilation"
	@echo "      > Copy following lines in your Python script:"
	@echo "import sys"
	@echo "sys.path.insert(0,'$(LIB_DIR)/Aronnax')"
	@echo "from nemo_py_bind import *"
	@echo "   -------------------------------"


## ---------------------------------------
## Cleaning
## ---------------------------------------
veryclean: clean
	pip uninstall Aronnax -y

clean:
	-rm -f $(ARCH) src/*.so *.sh 
	-rm -rf $(LIB_DIR) $(OBJ_DIR) $(INC_DIR) $(PY_DIR) build
