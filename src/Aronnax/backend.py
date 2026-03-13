# external modules
import subprocess
import json
import cloudpickle
import pickle
import base64
import sys
import os

class MPIBackend:

    def __init__(self, nproc=1, verbose=True):
        self.nproc = nproc
        self.process = None
        if verbose:
            self.log_stream = sys.stdout 
        else: 
            self.log_stream = open(os.devnull, 'w')

    def start_workers(self):
        if self.process is not None:
            return
       
        # sequential, srun or mpirun
        if self.nproc == 1:
            start_cmd = [ "python3", "-m", "Aronnax.worker" ]
        else:
            mpi_cmd = "srun" if "SLURM_JOB_ID" in os.environ else "mpirun"
            start_cmd = [ mpi_cmd, "-n", str(self.nproc), "python3", "-m", "Aronnax.worker" ]

        self.process = subprocess.Popen(
            start_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=self.log_stream,
            text=True
        )

    def stop_workers(self):
        if self.process is not None:
            if self.process.poll() is None:
                self._send({"cmd": "STOP"})
            self.process.wait()
            self.process = None

    def _send(self, cmd):
        if self.process is None:
            raise RuntimeError("Worker is not running")

        self.process.stdin.write(json.dumps(cmd) + "\n")
        self.process.stdin.flush()

        # Messages from workers
        while True:
            line = self.process.stdout.readline()
            if not line:
                self.stop_workers()
                raise RuntimeError("Worker died unexpectedly.")

            line = line.strip()

            # Redirect other logs
            if not line.startswith("{"):
                print(line, file=self.log_stream)
                continue

            # Worker feedbacks (JSON)
            try:
                return json.loads(line)
            except json.JSONDecodeError:
                print(f"Invalid JSON from worker: {line}", file=self.log_stream)
                continue


    def init(self):
        result = self._send({"cmd": "init"})

        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Worker could not run 'init'"))
        return result["first_ite"], result["date"]

    def advance(self, ite_start, ite_end, stp):
        result = self._send({"cmd": "advance", "ite_start": ite_start, "ite_end": ite_end, "stp": stp})
        
        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Worker could not run 'advance'"))
        return result["result"]

    def finalize(self):
        result = self._send({"cmd": "finalize"})
        
        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Worker could not run 'finalize'"))

    def pull(self, varname, varid):
        result = self._send({"cmd": "pull", "varname": varname, "key": varid})

        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Worker could not run 'pull'"))

    def get_local(self, varname, rank, varid):
        result = self._send({"cmd": "get_local", "varname": varname, "rank": rank, "key": varid})

        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Worker could not run 'get_local'"))

        data = base64.b64decode(result["result"])
        return pickle.loads(data)

    def push(self, varname, varid):
        result = self._send({"cmd": "push", "varname": varname, "key": varid})

        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Worker could not run 'push'"))

    def set_local(self, varname, rank, val):
        payload = base64.b64encode( pickle.dumps(val, protocol=pickle.HIGHEST_PROTOCOL) ).decode()
        result = self._send({"cmd": "set_local", "varname": varname, "rank": rank, "val": payload})

        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Worker could not run 'set_local'"))

    def apply(self, func, varid, arg_fields):
        payload = base64.b64encode(cloudpickle.dumps(func)).decode()

        result = self._send({"cmd": "apply", "key": varid, "func": payload, "args": [f.id for f in arg_fields] })

        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Worker could not run 'apply'"))

    def purge(self, varid):
        result = self._send({"cmd" : "purge", "key" : varid})

        if result["status"] == "error":
            raise RuntimeError(result.get("traceback", "Worker could not run 'purge'"))


