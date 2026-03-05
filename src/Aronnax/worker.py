# worker.py
import sys
import traceback
import json
import pickle
import base64

from mpi4py import MPI
from . import nemo_py_bind

comm = MPI.COMM_WORLD
rank = comm.Get_rank()

memory = {}

def send_response(obj,speaker=0):
    """ Sends structured JSON responses """
    if rank == speaker:
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

        cmd = comm.bcast(cmd, root=0)

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


            elif cmd["cmd"] == "get_local":
                if cmd["key"] in memory.keys():
                    val = memory[cmd["key"]]
                else:
                    val = nemo_py_bind.nemo_get_val(cmd["varname"])
                    memory.update({ cmd["key"] : val })

                payload = None
                if rank == cmd["rank"]:
                    payload = base64.b64encode( pickle.dumps(val, protocol=pickle.HIGHEST_PROTOCOL) ).decode()
                
                send_response({"status": "ok", "result" : payload}, speaker=cmd["rank"])


            elif cmd["cmd"] == "purge":
                memory.pop(cmd["key"], None)
                send_response({"status": "ok"})


            #elif cmd["cmd"] == "set":
            #    nemo_py_bind.nemo_set_val(cmd["varname"], cmd["val"])
            #    send_response({"status": "ok"})


        except Exception:
            send_response({"status": "error", "traceback": traceback.format_exc()})

    MPI.Finalize()

if __name__ == "__main__":
    main()
