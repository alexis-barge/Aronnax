# external modules
import mpi4py 
mpi4py.rc.finalize = False
from mpi4py import MPI

__all__ = []

# MPI infos
class Paral:
    """
    This class contains MPI variables.

    Attributes
    ----------
    GLOBAL_COMM : mpi4py.MPI.Intracomm
        Communicator of all cores
    GLOBAL_RANK : int
        Rank number of cores in GLOBAL_COMM
    MASTER : int
        Output rank

    """
    NEMO_COMM = MPI.COMM_WORLD
    RANK = NEMO_COMM.Get_rank()
    MASTER = 0
