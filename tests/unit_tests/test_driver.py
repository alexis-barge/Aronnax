import os
import glob
import shutil
import pytest
import unittest
from unittest.mock import MagicMock, patch

# ========
# cleaning
# ========
@pytest.fixture(scope="function",autouse=True)
def clean_tests():
    yield
    for d in glob.glob("TEST*"):
        shutil.rmtree(d)
    if os.path.isdir("__pycache__"):
        shutil.rmtree("__pycache__")


# ==============
# test driver.py
# ==============
from Aronnax.driver import NEMO

@patch("Aronnax.driver.MPIBackend")
@patch("Aronnax.driver.Run")
class TestNEMOInit(unittest.TestCase):

    def test_init(self, MockRun, MockBackend):
        nemo = NEMO(config="TEST", nproc=4)

        MockBackend.assert_called_once_with(nproc=4, verbose=True)
        MockRun.assert_called_once()
        assert nemo._config == "TEST"
        assert nemo._segment == 0
        assert nemo._error is False


@patch("Aronnax.driver.MPIBackend")
@patch("Aronnax.driver.Run")
def test_is_running(MockRun, MockBackend):
    backend_instance = MockBackend.return_value
    backend_instance.process = None

    nemo = NEMO()
    assert not nemo.is_running()
    
    backend_instance.process = "fake_process"
    assert nemo.is_running()


@patch("Aronnax.driver.MPIBackend")
@patch("Aronnax.driver.Run")
def test_start(MockRun, MockBackend):
    backend = MockBackend.return_value
    run = MockRun.return_value
    backend.process = None
    backend.init.return_value = (10, "2020-01-01")

    nemo = NEMO()
    nemo.start()

    backend.start_workers.assert_called_once()
    backend.init.assert_called_once()
    assert nemo.run._ite == 10
    assert nemo.run._date == "2020-01-01"
    assert nemo._error is False


@patch("Aronnax.driver.MPIBackend")
@patch("Aronnax.driver.Run")
def test_advance(MockRun, MockBackend):
    backend = MockBackend.return_value
    run = MockRun.return_value
    backend.process = True
    backend.advance.return_value = (0, "2020-01-02")

    run._ite = 0
    run._step = 1
    run._time = 0
    nemo = NEMO()
    nemo._backend = backend
    nemo.run = run

    nemo.advance(ite=5)
    backend.advance.assert_called_once()
    assert nemo.run._ite > 0


@patch("Aronnax.driver.MPIBackend")
@patch("Aronnax.driver.Run")
def test_advance_error(MockRun, MockBackend):
    backend = MockBackend.return_value
    run = MockRun.return_value
    backend.process = True
    # return error
    backend.advance.return_value = (1, None)

    nemo = NEMO()
    nemo._backend = backend
    nemo.run = run

    nemo.advance(ite=1)
    assert nemo._error is True


@patch("Aronnax.driver.DistributedField")
@patch("Aronnax.driver.MPIBackend")
@patch("Aronnax.driver.Run")
def test_field(MockRun, MockBackend, MockField):
    backend = MockBackend.return_value
    backend.process = True

    nemo = NEMO()
    nemo._backend = backend

    fld = nemo.field("temp")
    MockField.assert_called_once_with(backend, "temp", False)
    assert fld in nemo.fields

