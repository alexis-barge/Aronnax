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
    def __init__(self, config="MY_NEMO_CFG", debug=False, nproc=1, verbose=True):

        self._backend = MPIBackend(nproc=nproc, verbose=verbose)
        self._config = config
        self.debug = debug
        self._error = False
        self.fields = []
        self._segment = 0
        self.run = Run(self._config + ".seg0" + str(self._segment))
        # Warning -- debug mode marche pas en parallele


    def __del__(self):
        """ Properly stops NEMO workers """
        self.finish()


    def __str__(self):
        status = "ONLINE" if self.is_running() else "OFFLINE"
        err = " - OK " if not self._error else " - FAILED: check ocean.output logs"
        message = ( f"Run {self.run._label}: {status}{err}\n"
                    f"    - Current iteration: {self.run._ite}\n"
                    f"    - Simulated time: {self.run.format_date()}\n"
                    f"    - Current date: {self.run._date} from {self.run._date0}"
                  )
        return message


    def is_running(self):
        """ Is NEMO program currently running """
        return self._backend.process is not None


    def run_from(self, previous_run, fork=None):
        """ ... """
        if not self._error and not self.is_running():
            
            if fork is not None:
                self._config = fork
                self._segment = 0
            
            self.run = Run(self._config + ".seg0" + str(self._segment))
            self.run.init_from(previous_run)


    def set_next_run(self):
        """ ... """
        if not self._error and not self.is_running():
            self._segment += 1
            self.run_from(self.run._label)


    def start(self):
        """ Start NEMO initialization """
        if not self.is_running():
            self.run.reset()
            self.run._write_all_nml()
            
            # NEMO workers
            try:
                self._backend.start_workers()
                self.run._ite, self.run._date = self._backend.init()
                self._error = False
                self.run._lock = True
            except Exception as e:
                print(e)

            # Print status
            print(self)


    def finish(self,write_restart=False):
        """ Finalization routines: terminates NEMO program and the worker """
        if self.is_running():
            # write restart 
            if write_restart:
                self.advance(write_restart=write_restart)
       
            # stop workers
            try:
                self._backend.finalize()
            except Exception as e:
                print(e)
            self._backend.stop_workers()
        
        # dump run
        self.run.dump(self._error)
        self.run._lock = False


    def restart(self):
        """ Restart ...  """
        # terminate NEMO with dump
        self.finish(write_restart=True)

        # configure next run
        self.set_next_run()
        
        # reset NEMO
        if not self._error:
            self.start()


    def advance(self, ite=0, years=0, months=0, days=0, write_restart=False):
        """ Advance NEMO time loop. """
        
        if self.is_running() and not self._error:
            # number of iteration
            total_time = years*365.0*86400.0 + months*31.0*86400.0 + days*86400.0
            if total_time == 0.0 and ite == 0:
                total_ite = 1
            else:
                total_ite = int(ite) + int(total_time / self.run._step)
            final_ite = self.run._ite + total_ite - 1

            # adjust for restart
            if write_restart:
                final_ite = self.run.next_restart_ite(final_ite)
                total_ite = final_ite - self.run._ite + 1

            # compute
            try:
                info, date = self._backend.advance(self.run._ite, final_ite, int(write_restart))
            except Exception as e:
                print(e)
                info = 1

            # check status
            if info != 0:
                self._error = True
                self.finish() if not self.debug else None
            else:
                self.run._time += total_ite * self.run._step 
                self.run._ite += total_ite
                self.run._date = date

                # clear field memory
                for fld in self.fields:
                    fld.free() if not fld.save else None
            
        # print status
        print(self)
        if write_restart and self._error:
            print(f"    - Restart procedure aborted")
        elif write_restart:
            print(f"    - Restart procedure successful")


    def field(self,varname,save=False):
        """
        ...

        """
        if self.is_running():
            self.fields.append( DistributedField(self._backend, varname, save) )
            return self.fields[-1]
