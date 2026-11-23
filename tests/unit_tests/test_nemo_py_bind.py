import os
import shutil
import pytest
import numpy as np

# ========
# cleaning
# ========
@pytest.fixture(scope="session",autouse=True)
def clean_tests():
    yield
    if os.path.isdir("__pycache__"):
        shutil.rmtree("__pycache__")


# ================
# test nemo_y_bind
# ================
from Aronnax import test_nemo_py_bind as nemo_py_bind

def test_nemo_init():
    try:
        it0, date = nemo_py_bind.nemo_init(0.0)
    except Exception as e:
        assert isinstance(e, TypeError)

    it0, date = nemo_py_bind.nemo_init(0)
    assert it0 == 5
    assert date == '00010105'


def test_nemo_advance():
    try:
        info, date = nemo_py_bind.nemo_advance(5,10.,1)
    except Exception as e:
        assert isinstance(e, TypeError)

    info, date = nemo_py_bind.nemo_advance(5,10,1)
    assert info == 0
    assert date == 123456
    
    info, date = nemo_py_bind.nemo_advance(5,10,0)
    assert info == 1
    assert date == 456789
    
    info, date = nemo_py_bind.nemo_advance(5,10,2)
    assert info == -1
    assert date == -1
    
    info, date = nemo_py_bind.nemo_advance(2,55,0)
    assert info == -1
    assert date == -1


def test_nemo_finalization():
    err = nemo_py_bind.nemo_finalization()
    assert err == 0


def test_get_val():
    try:
        val = nemo_py_bind.nemo_get_val(5)
    except Exception as e:
        assert isinstance(e, TypeError)
    
    val = nemo_py_bind.nemo_get_val('t')
    assert val.shape == (100,50,10)
    assert np.all(val == 5.0)
    
    val = nemo_py_bind.nemo_get_val('s')
    assert val.shape == (200,100,20)
    assert np.all(val == 10.0)

    val = nemo_py_bind.nemo_get_val('t0')
    assert val.shape == (5,5,1)
    assert np.all(val == -1.0)


def test_set_val():
    try:
        val = nemo_py_bind.nemo_get_val(10.0)
    except Exception as e:
        assert isinstance(e, TypeError)
    
    val = nemo_py_bind.nemo_get_val('t')
    val = val*2.0
    res = nemo_py_bind.nemo_set_val('t',val)
    assert res == 1
    
    val = val*2.0
    res = nemo_py_bind.nemo_set_val('t',val)
    assert res == 0

    try:
        res = nemo_py_bind.nemo_set_val('s',val)
    except Exception as e:
        assert isinstance(e, TypeError)

    val = nemo_py_bind.nemo_get_val('s')
    val = val*4.0
    try:
        res = nemo_py_bind.nemo_set_val('t',val)
    except Exception as e:
        assert isinstance(e, TypeError)

