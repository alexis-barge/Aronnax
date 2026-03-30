import subprocess
import os
import shutil
from setuptools import setup, Extension, find_packages
from setuptools.command.build_ext import build_ext
from setuptools.command.build_py import build_py as _build_py
from Cython.Build import cythonize
import numpy


class BuildExtWithMake(build_ext):
    """
    Custom build_ext:
    - compile libnemo.so with Makefile
    - copy libnemo.so into the *build/lib*/Aronnax/ folder (not src/)
    - then build the Cython extension
    """
    def run(self):
        # Reset
        if os.path.isfile("build/arch_nemo.mk"):
            os.remove("build/arch_nemo.mk")

        # build dir
        lib_dir = os.path.abspath("build/lib")
        os.makedirs(lib_dir, exist_ok=True)

        # Compile libnemo.so and libnemo_test.so with Makefile
        subprocess.check_call(["make", f"LIB_DIR={lib_dir}"], env=os.environ.copy(), cwd=os.path.join( os.getcwd() , "src"))

        # Compile Cython wrapper
        super().run()

        # Add libnemo.so in Aronnax package
        build_Aronnax_dir = os.path.join(self.build_lib, "Aronnax")
        os.makedirs(build_Aronnax_dir, exist_ok=True)
        shutil.copy2(os.path.join(lib_dir, "libnemo.so"), build_Aronnax_dir)
        shutil.copy2(os.path.join(lib_dir, "libnemo_test.so"), build_Aronnax_dir)
        
        # Add NEMO config path in Aronnax package
        nemo_bld = os.environ.get("NEMO_BLD", f"{os.path.dirname(os.getcwd())}")
        build_info_file = os.path.join(build_Aronnax_dir, "build_info.py")
        with open(build_info_file, "w") as f:
            f.write(f'__nemo_bld__ = "{nemo_bld}"\n')


# Cython compilation
extensions = [
    # production
    Extension(
        "Aronnax.nemo_py_bind",                     
        sources=["src/py_bind/nemo_py_bind.pyx"],  
        libraries=["nemo"],                        
        library_dirs=["build/lib"],                
        runtime_library_dirs=["$ORIGIN"],
        include_dirs=[numpy.get_include()],
        extra_compile_args=["-O3", "-fPIC"],
        extra_link_args=["-Wl,-rpath,$ORIGIN"],
        language="c",
    ),
    # test
    Extension(
        "Aronnax.test_nemo_py_bind",
        sources=["src/py_bind/test_nemo_py_bind.pyx"],  
        libraries=["nemo_test"],                   
        library_dirs=["build/lib"],
        runtime_library_dirs=["$ORIGIN"],
        include_dirs=[numpy.get_include()],
        extra_compile_args=["-O3", "-fPIC"],
        extra_link_args=["-Wl,-rpath,$ORIGIN"],
        language="c",
    )
]

# Cythonize extensions
cythonized_extensions = cythonize(
    extensions,
    language_level="3",
    build_dir="build/python",
)

# pyNENO package (include Cython wrapper and shared-NEMO)
setup(
    name="Aronnax",
    version="0.5.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    ext_modules=cythonized_extensions,
    cmdclass={"build_ext": BuildExtWithMake,},
    options={"egg_info": {"egg_base": "build/python"}},
    package_data={"Aronnax": ["*.so"]},
    include_package_data=True,
)

