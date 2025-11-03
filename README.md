# Nautilus

**!! The project is currently at early development stage and may not work properly !!**

```
Just as the legendary submarine Nautilus carried Captain Nemo through the uncharted depths of the oceans,
this project carries the NEMO ocean model into the world of Python.
```

**Nautilus** is Python wrapper for the ocean General Circulation Model NEMO v5.0.1 - configuration ORCA1. It provides an interface to progress the Fortran main time loop, and get or set variables used by the Fortran to or from the Python environment.

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

Once NEMO is compiled, go in the ORCA1 config directory:

```bash
cd nemo_v5.0.1/cfgs/<ORCA1-CONFIG>
```

Clone a copy of the Nautilus repository:

```bash
git clone https://github.com/alexis-barge/Nautilus.git
```

Install package:

```bash
cd Nautilus
pip install .
```

#### Development installation

Nautilus can be compiled locally with no installation in packages site for development purposes:

```bash
cd Nautilus
make dev
```

#### Clean up 

```bash
make clean      # remove compiled objects and build directories
make veryclean  # clean and uninstall Nautilus package
```
