# Modules
from nemo_py_interface import *
from mpi4py import MPI

# Init parallelization
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()
