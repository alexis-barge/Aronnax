import os
import pytest
from unittest.mock import MagicMock

# ========
# cleaning
# ========
@pytest.fixture(scope="session",autouse=True)
def clean_tests():
    yield
    if os.path.isdir("__pycache__"):
        shutil.rmtree("__pycache__")

# ===========
# toy backend
# ===========
@pytest.fixture
def backend():
    b = MagicMock()
    b.nproc = 4
    b.process = True
    b.get_local.return_value = "data"
    return b

# =============
# test field.py
# =============
from Aronnax.field import DistributedField

def test_getitem(backend):
    field = DistributedField(backend, "test")
    assert field[0] == "data"


def test_invalid_rank(backend):
    field = DistributedField(backend, "test")
    with pytest.raises(ValueError):
        field[5]


def test_setitem(backend):
    field = DistributedField(backend, "test")
    field[1] = 42

    backend.set_local.assert_called_once_with("test", 1, 42)
