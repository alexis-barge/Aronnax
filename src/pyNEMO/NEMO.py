# pyNEMO modules
from .worker import Paral
# NEMO interface
from nemo_py_bind import *

__all__ = ['NEMO']

class NEMO: 
    """
    This class ..
    NEMO is a protected singleton

    Attributes
    ----------

    """
    _instance = None

    def __new__(cls,*args,**kwargs)
        if not cls._instance:
            cls._instance = super(NEMO, cls).__new__(cls)
            cls._instance.initialized = False
        return cls._instance

    def __init__(self, total_ite=0, total_time=0.0, config='ORCA1'):
        """ Starts NEMO, skip if already. """
        if not self.initialized:
            self.initialized = True
            self.total_ite = total_ite
            self.total_time = total_time
            self.config = config

            # Start NEMO
            self.total_ite = nemo_init(Paral.GLOBAL_COMM.py2f())

    def is_running(self):
        """ Is NENO program currently running. """
        return self.initialized

    def __str__(self):
        if Paral.RANK == Paral.MASTER:
            return f"NEMO.{self.config} -- Current iteration: {self.total_ite} and simulation time: {self.total_time}"
        else:
            return f""

    def finish(self):
        """ Finalization routines - terminates NEMO program. """
        nemo_finalization()
        self.initialized = False

    def restart(self):
        # Get required variables for restart
        # ...
        # Terminate current NEMO execution
        self.finish()
        # 
        # Restart nemo with new inputs
        # self.seg += 1
        # seg_name = self.config + '.' + str(self.seg)
        #self.__init__(seg_name, self.total_ite, self.total_time)


    def advance(self, ite=1, step=0.0):
        """ Advance NEMO time loop. """
        info = nemo_advance(self.total_ite, self.total_ite + ite - 1, 0.0)
        self.total_time += ite*step
        self.total_ite += ite

        # Check errors
        if info /= 0:
            self.finish()
            if Paral.RANK == Paral.MASTER:
                print(f"Simulation failed - check messages in ocean.output")

