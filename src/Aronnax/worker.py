# worker.py
import sys
import traceback
import json
from mpi4py import MPI
from . import nemo_py_bind

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

def broadcast_command(cmd):
    return comm.bcast(cmd, root=0)

def send_response(obj):
    """ Rank 0 sends structured JSON responses """
    if rank == 0:
        print(json.dumps(obj), flush=True)

def main():

    while True:
        
        if rank == 0:
            line = sys.stdin.readline()
            if not line:
                cmd = {"cmd": "STOP"}
            else:
                cmd = json.loads(line.strip())
        else:
            cmd = None

        cmd = broadcast_command(cmd)

        if cmd["cmd"] == "STOP":
            send_response({"status": "ok"})
            break

        try:
            if cmd["cmd"] == "init":
                first_ite = nemo_py_bind.nemo_init(comm.py2f())
                send_response({"status": "ok", "result": first_ite})

            elif cmd["cmd"] == "advance":
                info = nemo_py_bind.nemo_advance(cmd["ite_start"], cmd["ite_end"], cmd["stp"])
                send_response({"status": "ok", "result": info})

            elif cmd["cmd"] == "finalize":
                nemo_py_bind.nemo_finalization()
                send_response({"status": "ok"})

            elif cmd["cmd"] == "get":
                val = nemo_py_bind.nemo_get_val(cmd["varname"])
                send_response({"status": "ok", "result": val})

            elif cmd["cmd"] == "set":
                nemo_py_bind.nemo_set_val(cmd["varname"], cmd["val"])
                send_response({"status": "ok"})

        except Exception:
            send_response({"status": "error", "traceback": traceback.format_exc()})

    MPI.Finalize()

if __name__ == "__main__":
    main()
