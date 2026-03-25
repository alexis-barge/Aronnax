import os
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

@pytest.fixture
def backend():
    return MPIBackend(nproc=1, verbose=False)

# ===============
# test backend.py
# ===============
from Aronnax.backend import MPIBackend

@patch("Aronnax.backend.subprocess.Popen")
def test_start_workers(mock_popen):
    backend = MPIBackend(nproc=1)
    backend.start_workers()
    mock_popen.assert_called_once()
    assert backend.process is not None


@patch("Aronnax.backend.subprocess.Popen")
def test_start_workers_already_running(mock_popen):
    backend = MPIBackend()
    backend.process = MagicMock()

    backend.start_workers()
    mock_popen.assert_not_called()


def test_stop_workers():
    backend = MPIBackend()
    process = MagicMock()
    process.poll.return_value = None
    backend.process = process
    backend._send = MagicMock()
    
    backend.stop_workers()
    backend._send.assert_called_once_with({"cmd": "STOP"})
    process.wait.assert_called_once()
    assert backend.process is None


def test_send_without_process(backend):
    with pytest.raises(RuntimeError):
        backend._send({"cmd": "test"})


def test_send_valid_json(backend):
    process = MagicMock()
    process.stdout.readline.side_effect = [ '{"status": "ok"}\n' ]
    backend.process = process
    result = backend._send({"cmd": "test"})
    assert result["status"] == "ok"
    assert backend.process is not None


def test_send_invalid_json_then_valid(backend):
    process = MagicMock()
    process.stdout.readline.side_effect = [ 'not json\n', '{"status": "ok"}\n' ]
    backend.process = process
    result = backend._send({"cmd": "test"})
    assert result["status"] == "ok"


def test_send_worker_dies(backend):
    process = MagicMock()
    process.stdout.readline.return_value = ""
    backend.process = process
    
    backend.stop_workers = MagicMock()
    with pytest.raises(RuntimeError):
        backend._send({"cmd": "test"})

# -- init / advance / finalize / push ... not tested as they are basically embedding _send()
