# external modules
from multiprocessing import Process, Queue
from .worker import worker_loop

__all__ = []

class FortranBackend:

    def __init__(self):
        self.task_queue = Queue()
        self.result_queue = Queue()
        self.process = None
        self.start()

    def start(self):
        """ Start a clean worker """
        # Empty queues
        while not self.task_queue.empty():
            self.task_queue.get_nowait()
        while not self.result_queue.empty():
            self.result_queue.get_nowait()
    
        # Start process
        self.process = Process(
            target = worker_loop,
            args = (self.task_queue, self.result_queue),
            daemon=True
        )
        self.process.start()

    def stop(self):
        """ Stop the worker. /!\ kills everything within  """
        if self.process is not None:
            self.task_queue.put({"cmd": "STOP"})
            self.process.join()
            self.process = None

    def restart(self):
        """ Restart the worker """
        self.stop()
        self.start()

    def init(self):
        self.task_queue.put({"cmd":"init"})
        result = self.result_queue.get()

        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Low level error stopped or killed NEMO."))

        return result["result"]


    def advance(self, ite_start, ite_end, stp):
        self.task_queue.put({"cmd":"advance", "ite_start" : ite_start, "ite_end" : ite_end, "stp" : stp})
        result = self.result_queue.get()

        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Low level error stopped or killed NEMO."))

        return result["result"]

    def get(self, varname):
        self.task_queue.put({"cmd":"get", "varname" : varname})
        result = self.result_queue.get()
    
        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Low level error stopped or killed NEMO."))

        return result["result"]

    def set(self,varname,val):
        self.task_queue.put({"cmd":"set", "varname" : varname, "val" : val})
        result = self.result_queue.get()

        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Low level error stopped or killed NEMO."))

    def finalize(self):
        self.task_queue.put({"cmd": "finalize"})
        result = self.result_queue.get()

        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Low level error stopped or killed NEMO."))

