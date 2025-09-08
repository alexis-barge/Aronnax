# =====================================
# Makefile to build NEMO Python wrapper
# =====================================
WRAPPER_HOME := $(shell pwd)
ARCH_FCM     := $(WRAPPER_HOME)/../arch_nemo.fcm
ARCH         := arch_nemo.mk

NEMO_LIB     := libnemo.so

export SRC_DIR      = $(WRAPPER_HOME)/src/nemo_interface
export OBJ_DIR      = $(WRAPPER_HOME)/build/fortran
export INC_DIR      = $(WRAPPER_HOME)/build/include
export LIB_DIR      = $(WRAPPER_HOME)/build/lib
export PY_DIR       = $(WRAPPER_HOME)/build/python
export NEMO_INC_DIR = $(WRAPPER_HOME)/../inc
export NEMO_OBJ_DIR = $(WRAPPER_HOME)/../obj

NEMO_OBJ = $(wildcard $(NEMO_OBJ_DIR)/*.o)
OBJ = nemo_mod.o nemo_c_interface.o 

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

build: dirs PY_NEMO
	@echo "      > Compilation successful"
	@echo "   -------------------------------"


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

dirs:
	@mkdir -p $(LIB_DIR) $(OBJ_DIR) $(INC_DIR) $(PY_DIR)	


## ---------------------------------------
## Compilation of NEMO as shared library
## ---------------------------------------
$(NEMO_LIB): $(OBJ)
	$(FC) -shared $(FFLAGS) -o $(LIB_DIR)/$@ $(addprefix $(OBJ_DIR)/,$^) $(NEMO_OBJ) $(USER_LIB)
	@echo "      > DONE shared NEMO"
	@echo "   -------------------------------"

%.o: $(SRC_DIR)/%.f90
	$(FC) $(FFLAGS) -c $< -o $(OBJ_DIR)/$@ -J $(INC_DIR) -I $(NEMO_INC_DIR) -I $(INC_DIR) $(USER_INC)


## ---------------------------------------
## Compilation of shared-NEMO Python layer
## ---------------------------------------
PY_NEMO: $(NEMO_LIB)
	@echo "   >>> Compile Python layer"
	python3 setup.py build_ext --build-lib=$(LIB_DIR) --build-temp=$(PY_DIR)


## ---------------------------------------
## Cleaning
## ---------------------------------------
clean:
	-rm -f $(ARCH) src/py_src/*.c 
	-rm -rf $(LIB_DIR) $(OBJ_DIR) $(INC_DIR) $(PY_DIR) build
