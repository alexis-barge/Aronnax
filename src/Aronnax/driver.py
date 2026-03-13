# Aronnax modules
from .backend import MPIBackend
from .field import DistributedField
from .simulation import Run 

__all__ = ['NEMO']

class NEMO: 
    """
    This class ..

    Attributes
    ----------

    """

    def __init__(self, config='ORCA1', debug=False, nproc=1, verbose=True):

        self._backend = MPIBackend(nproc=nproc, verbose=verbose)
        self._config = config
        self.debug = debug
        self._error = False
        self.fields = []
        self._segment = 0
        self._run = Run(config + ".seg0" + str(self._segment))


    def __del__(self):
        """ Properly stops NEMO and the workers """
        self.finish()


    def __str__(self):
        status = "ONLINE" is self.is_running() else "OFFLINE"
        err = " - OK " if not self._error else " - FAILED: check ocean.output logs"
        message = f"Run {self._run._label}: {status}{err}\n"           \   
                + f"    - Current iteration: {self._run._ite}\n"        \ 
                + f"    - Simulated time: {self._run.format_date()}\n" \
                + f"    - Current date: {self._run.date} from {self._run.date0}"
        return message


    def is_running(self):
        """ Is NEMO program currently running """
        return self._backend.process is not None


    def start_from(self, previous_run):
        if self.is_running() is not None:
            self._run.copy_from(previous_run)


    def set_run(self, run_to_set):
        if self.is_running() is not None:
            self._run = run_to_set


    def start(self):
        """ Start NEMO initialization """
        if not self.is_running():
            self._run._lock = True
            self._run._write_all_nml()
            self._backend.start_workers()
            _, self._run._date = self._backend.init()
            self._error = False


    def finish(self,write_restart=False):
        """ Finalization routines: terminates NEMO program and the worker """
        if self.is_running():
            self._run._lock = False
            self._backend.finalize()
            self._backend.stop_workers()
            if write_restart:
                self._run.dump()


    def restart(self):
        """ Restart ...  """
        # terminate NEMO with dump
        self.finish(write_restart=True)

        # configure next run
        self._segment += 1 
        previous_label = self._run._label
        self._run._label = self._config + ".seg0" + str(self._segment)
        self._run.start_from(previous_label)
        
        # reset NEMO
        self.start()


    def advance(self, ite=0, years=0, months=0, days=0):
        """ Advance NEMO time loop. """
        
        if self.is_running() and not self._error:
            # number of iteration
            total_time = years*365.0*86400.0 + months*31.0*86400.0 + days*86400.0
            if total_time == 0.0 and ite == 0:
                total_ite = 1
            else:
                total_ite = int(ite) + int(total_time / self._run._step)

            # compute
            try:
                info, date = self._backend.advance(self._run._ite, self._run._ite + total_ite - 1)
            except:
                info = 1

            # check status
            if info != 0:
                self._error = True
                self.finish() if not self.debug else None
            else:
                self._run._ite += ite
                self._run._time += total_ite*self._run._step 
                self._run._date = date

                # clear field memory
                for fld in self.fields:
                    fld.free() if not fld.save else None
            
            print(self)


    def field(self,varname,save=False):
        if self.is_running():
            self.fields.append( DistributedField(self._backend, varname, save) )
            return self.fields[-1]
