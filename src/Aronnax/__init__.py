"""
Aronnax
=======

Aronnax is a Python wrapper for the ocean General Circulation Model NEMO v5.0.1.
It provides an interface to progress the Fortran main time loop, and get or set
variables used by the Fortran core to or from the Python environment.

* Copyright (c) 2025 IGE-OPERA-OCEAN
    Aronnax is released under ...
    See the `LICENSE <https://github.com/...>`_ file for details.

"""

# export package
from .driver import *
from .backend import *
from .field import *
from .simulation import *
