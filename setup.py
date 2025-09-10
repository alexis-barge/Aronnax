import subprocess
import os
from setuptools import setup, Extension, find_packages
from setuptools.command.build_ext import build_ext
from Cython.Build import cythonize
import numpy


class BuildExtWithMake(build_ext):
    """ 
    Custom build_ext that ensures libnemo.so is built with Makefile before compiling Cython extensions. 

    """
    def run(self):
        # Compilation directory
        lib_dir = os.environ.get("LIB_DIR") or "build/lib"
        os.makedirs(lib_dir, exist_ok=True)
        self.build_lib = lib_dir

        # Building directory
        temp_dir = os.environ.get("PY_DIR") or "build/python"
        os.makedirs(temp_dir, exist_ok=True)
        self.build_temp = temp_dir

        # Compile libnemo.so with Makefile, then Cython wrapper
        subprocess.check_call(["make", f"LIB_DIR={lib_dir}"])
        super().run()


extensions = [
    Extension(
        "nemo_py_bind",                       # fully qualified module name
        sources=["src/py_bind/nemo_py_bind.pyx"],    # Cython source
        libraries=["nemo"],                          # link against libnemo.so
        library_dirs=["build/lib"],
        runtime_library_dirs=["build_lib"],
        include_dirs=[numpy.get_include()],
        extra_compile_args=["-O3", "-fPIC"],
        extra_link_args=["-Wl,-rpath,$ORIGIN"],
        language="c",
    )
]

cythonized_extensions = cythonize(
    extensions,
    language_level="3",
    build_dir="build/python",
)

setup(
    name="pyNEMO",
    version="0.1.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},  
    ext_modules=cythonized_extensions,
    cmdclass={"build_ext": BuildExtWithMake},
    options={
        "egg_info": {"egg_base": "build/python"},
    },
)
