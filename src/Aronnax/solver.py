# Aronnax modules
from .api import FortranBackend

__all__ = ['NEMO']

class NEMO: 
    """
    This class ..

    Attributes
    ----------

    """

    def __init__(self, total_ite=0, total_time=0.0, config='ORCA1', debug=False):
        self._backend = FortranBackend()
        self.initialized = False
        self.total_ite = total_ite
        self.total_time = total_time
        self.config = config
        self.debug = debug
        self.error = False

    def is_running(self):
        """ Is NEMO program currently running """
        return self.initialized

    def __str__(self):
        if not self.error: 
           return f"NEMO.{self.config} OK -- Current iteration: {self.total_ite} and simulation time: {self.total_time}"
        else: 
           return f"NEMO.{self.config} FAILED -- Current iteration: {self.total_ite} and simulation time: {self.total_time}"

    def __del__(self):
        """ Fully stops NEMO and its worker """
        if self.initialized:
            self._backend.finalize()
            self.initialized = False
        if self._backend.process != None:
            self._backend.stop()

    def start(self):
        """ Start NEMO initialization """
        if self._backend.process == None:
            self._backend.start()

        if not self.initialized:
            self.total_ite = self._backend.init()
            self.initialized = True
            self.error = False

    def finish(self):
        """ Finalization routines: terminates NEMO program and the worker """
        if self.initialized:
            self._backend.finalize()
            self.initialized = False
        self._backend.stop()

    #def restart(self):
        # Get required variables for restart
        # ...
        # Terminate current NEMO execution
        #self.finish()
        # 
        # Restart nemo with new inputs
        # self.seg += 1
        # seg_name = self.config + '.' + str(self.seg)
        #self.__init__(seg_name, self.total_ite, self.total_time)

    def advance(self, ite=1, step=0.0):
        """ Advance NEMO time loop. """
        if self.initialized and not self.error:
            info = self._backend.advance(self.total_ite, self.total_ite + ite - 1, 0.0)

            # Check errors
            if info != 0:
                self.error = True
                print(f"Simulation failed - check messages in ocean.output")
                if not self.debug:
                    self.finish()
            else:
                self.total_time += ite*step
                self.total_ite += ite
                print(f"Time advancement reached iteration: {self.total_ite} and total simulation time: {self.total_time}")

    def get(self,varname):
        if self.initialized:
            print(f"Get {varname} at {self}")
            return self._backend.get(varname)

    def set(self,varname,val):
        if self.initialized and not self.error:
            print(f"Set {varname} at {self}")
            self._backend.set(varname,val)
