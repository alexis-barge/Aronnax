### Python wrapper for ocean General Circulation Model NEMO

# Installation & Development

## Prerequisites
- Python ≥ 3.9  
- A working Fortran compiler (e.g. `gfortran`)  
- `make` available in your environment  
- Dependencies: `numpy`, `Cython`, `mpi4py` (automatically handled by `pip`)  

## Installation

To build and install **pyNEMO** (including the Fortran shared library and the Cython wrapper):

```bash
pip install .S
