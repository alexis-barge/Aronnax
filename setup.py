from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy
import os

LIB_DIR = os.environ.get("LIB_DIR", "build/lib")

extensions = [
    Extension(
        "pyNEMO",                                      # name of Cython module to generate
        sources=["src/py_src/pyNEMO.pyx"],             # Cython code
        libraries=["nemo"],                            # NEMO Fortran lib name (no 'lib' prefix lib or .a/.so suffix)
        library_dirs=[LIB_DIR],                        # NEMO lib location
        runtime_library_dirs=[LIB_DIR],                # compiled Cython module
        include_dirs=[numpy.get_include()],            # include numpy headers
        extra_compile_args=["-O3", "-fPIC"],           # C compiler flags
        extra_link_args=["-Wl,-rpath,$ORIGIN/../lib"], # linker options, if required
        language="c",                                  # language to generate
    )
]

setup(
    name="wrapper",
    ext_modules=cythonize(extensions, language_level=3),
)
