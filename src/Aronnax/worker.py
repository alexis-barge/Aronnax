# external modules
from multiprocessing import Process, Queue
import traceback

__all__ = []

def worker_loop(task_queue, result_queue):
    """ 
    Isolated Python process: loads and run the NEMO Fortran lib. 

    """
    from mpi4py import MPI
    from . import nemo_py_bind

    comm = MPI.COMM_WORLD

    while True:
        task = task_queue.get()

        if task["cmd"] == "STOP":
            break

        try:
            if task["cmd"] == "init":
                first_ite = nemo_py_bind.nemo_init(comm.py2f())
                result_queue.put({"status": "ok", "result": first_ite})

            elif task["cmd"] == "advance":
                info = nemo_py_bind.nemo_advance(task["ite_start"],task["ite_end"],task["stp"])
                result_queue.put({"status": "ok", "result": info})

            elif task["cmd"] == "get":
                val = nemo_py_bind.nemo_get_val(task["varname"])
                result_queue.put({"status": "ok", "result": val})

            elif task["cmd"] == "set":
                nemo_py_bind.nemo_set_val(task["varname"],task["val"])
                result_queue.put({"status": "ok"})
                
            elif task["cmd"] == "finalize":
                nemo_py_bind.nemo_finalization()
                result_queue.put({"status": "ok"})

        except Exception as e:
            result_queue.put({
                "status": "error",
                "traceback": traceback.format_exc()
            })


