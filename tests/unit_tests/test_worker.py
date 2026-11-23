import os
import json
import shutil
import pytest
from unittest.mock import MagicMock, patch

# ========
# cleaning
# ========
@pytest.fixture(scope="session",autouse=True)
def clean_tests():
    yield
    if os.path.isdir("__pycache__"):
        shutil.rmtree("__pycache__")


# ==============
# test worker.py
# ==============
from Aronnax import worker

# only test communication protocol (JSON reception on 0 + broadcast , JSON response) between ranks 

def test_rank0_broadcasts_command():
    fake_comm = MagicMock()
    fake_comm.bcast.side_effect = lambda cmd, root: cmd

    with patch.object(worker, "comm", fake_comm), \
         patch.object(worker, "rank", 0), \
         patch("sys.stdin.readline", side_effect=[ json.dumps({"cmd": "STOP"}) + "\n" ]), \
         patch("builtins.print") as mock_print:

        worker.main()

    # check broadcast call and JSON response
    assert fake_comm.bcast.called
    mock_print.assert_called_with(json.dumps({"status": "ok"}), flush=True)


def test_send_response_specific_rank():
    with patch.object(worker, "rank", 2), \
         patch("builtins.print") as mock_print:

        worker.send_response({"status": "ok"}, speaker=2)

    mock_print.assert_called_once()


def test_send_response_not_speaker():
    with patch.object(worker, "rank", 1), \
         patch("builtins.print") as mock_print:

        worker.send_response({"status": "ok"}, speaker=0)

    mock_print.assert_not_called()


def test_non_root_receives_broadcast():
    cmd = {"cmd": "STOP"} 
    fake_comm = MagicMock()
    fake_comm.bcast.return_value = cmd

    with patch.object(worker, "comm", fake_comm), \
         patch.object(worker, "rank", 1), \
         patch("builtins.print") as mock_print, \
         patch("Aronnax.worker.MPI.Finalize"):

        try:
            worker.main()
        except Exception:
            pass

    # check rank != 0 got command - no JSON response since speaker=0 by default
    fake_comm.bcast.assert_called_with(None, root=0)
    mock_print.assert_not_called()

