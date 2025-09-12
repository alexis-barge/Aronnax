# pyNEMO

```
!! The project is currently at early development stage and may not work properly !!
```

**PyNEMO** is a Python wrapper for the ocean General Circulation Model NEMO v5.0.1 - configuration ORCA1.

### Prerequisites
- NEMO [v5.0.1](https://forge.nemo-ocean.eu/nemo/nemo/-/releases)
- Python ≥ 3.10
- MPI implementation
- Fortran compiler
- make


## Installation

[XIOS](https://forge.ipsl.fr/ioserver) must be compiled with ```-fPIC``` flag first (or equivalent depending on your compiler). For instance:

```bash
cat XIOS/arch/arch-XIOS.fcm
  %CCOMPILER      mpicc -fPIC
  %FCOMPILER      mpif90 -fPIC

```

### 1. Compile NEMO-ORCA1 as executable

Get a copy of [NEMO_v5.0.1](https://forge.nemo-ocean.eu/nemo/nemo/-/releases) and set up the ORCA1 config following NEMO [standard procedure](https://sites.nemo-ocean.io/user-guide/install.html#)

Compile NEMO formally with ``./makenemo`` script and ```-fPIC``` flag (or equivalent depending on your compiler). For instance:

```bash
cat nemo_v5.0.1/arch/arch-NEMO.fcm
  %FCFLAGS      -fPIC # ... ...

```

### 2. Install Python wrapper

Once NEMO is compiled, go in `BLD` directory of your ORCA1 config:

```bash
cd nemo_v5.0.1/cfgs/<ORCA1-CONFIG>/BLD
```

Clone a copy of pyNEMO repository:

```bash
git clone https://github.com/alexis-barge/pyNEMO.git
```

Install package:

```bash
cd pyNEMO
pip install .
```

#### Development installation

pyNEMO can be compiled locally with no installation in packages site for development purposes:

```bash
cd pyNEMO
make dev
```

#### Clean up 

```bash
make clean      # remove compiled objects and build directories
make veryclean  # clean and uninstall pyNEMO package
```
