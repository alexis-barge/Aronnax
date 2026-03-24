import os
import glob
import shutil
import pytest

# ========
# cleaning
# ========
@pytest.fixture(scope="function",autouse=True)
def clean_tests():
    yield
    for d in glob.glob("TEST_RUN*"):
        shutil.rmtree(d)
    for d in glob.glob("RST_RUN*"):
        shutil.rmtree(d)
    for f in ["namelist_cfg", "namelist_ice_cfg", "namelist_ref" ,"namelist_ice_ref"]:
        os.remove(f)
    if os.path.isdir("__pycache__"):
        shutil.rmtree("__pycache__")


# ==============
# initialization
# ==============
def init_scenario():
    nml_cfg = """
&namrun
    cn_exp = "RST_RUN"
    nn_it000 = 5
    nn_itend = 30
    nn_date0 = 10101
/

&namdom
    rn_Dt = 10800.
/

&namsbc
    nn_fsbc = 2
/
"""

    nml_ice_cfg ="""
&nampar
/
"""

    with open("namelist_cfg", "w") as file:
        file.write(nml_cfg)
    shutil.copy("namelist_cfg", "namelist_ref")

    with open("namelist_ice_cfg", "w") as file:
        file.write(nml_ice_cfg)
    shutil.copy("namelist_ice_cfg", "namelist_ice_ref")

    # dummy restart dir
    os.makedirs("RST_RUN", exist_ok=True)
    shutil.copy("namelist_cfg", "RST_RUN/namelist_cfg.RST_RUN")
    shutil.copy("namelist_ice_cfg", "RST_RUN/namelist_ice_cfg.RST_RUN")
    shutil.copy("namelist_cfg", "RST_RUN/namelist_ref.RST_RUN")
    shutil.copy("namelist_ice_cfg", "RST_RUN/namelist_ice_ref.RST_RUN")
    file_path = os.path.join("RST_RUN", "RST_RUN_00000030_restart.nc")
    with open(file_path, "w") as file:
        file.write("")


# ==================
# test simulation.py
# ==================
from Aronnax.simulation import Run

# -- I : init from None  
def test_init_from_none():
    init_scenario()

    # unique dump dir
    run = Run("TEST_RUN")
    dirs = glob.glob("TEST_RUN*")
    assert len(dirs) == 1
    assert dirs[0] == "TEST_RUN"    

    # nml parser tool
    res = run._nml_itm('nn_date0')
    assert res == 10101
    assert run._nml_itm('nothing') == None
    assert run._cfg['namrun']['nn_date0'] == res

    # check namelist auto modif
    assert run._nml_itm('cn_exp') == 'TEST_RUN'
    assert run._nml_itm('nn_it000') == 1
    assert run._nml_itm('nn_itend') == 198840
    assert run._nml_itm('ln_rstart') == False
    assert run._nml_itm('cn_ocerst_out') == 'restart'
    assert run._nml_itm('cn_icerst_out') == 'restart_ice'
    assert run._nml_itm('cn_ocerst_outdir') == os.path.join( os.getcwd() , "TEST_RUN" )
    assert run._nml_itm('cn_icerst_outdir') == os.path.join( os.getcwd() , "TEST_RUN" )

    # dump without error
    run.dump(False)
    assert os.path.isfile('TEST_RUN/namelist_cfg.TEST_RUN') == True
    assert os.path.isfile('TEST_RUN/namelist_ice_cfg.TEST_RUN') == True
    assert os.path.isfile('TEST_RUN/namelist_ref.TEST_RUN') == True
    assert os.path.isfile('TEST_RUN/namelist_ice_ref.TEST_RUN') == True

    # reset
    run._time = 100.0
    run._ite = 10
    run.reset()
    assert run._ite == 1
    assert run._time == 0.0


# -- II : init from existing Run  
def test_init_from_dir():
    init_scenario()
    run = Run("TEST_RUN")
    run.dump(False)

    # run does not exist
    run.init_from('NO_RUN')
    assert run._nml_itm('cn_ocerst_indir') == None

    # run does not have restart files
    run.init_from('TEST_RUN')
    assert run._nml_itm('cn_ocerst_indir') == None

    # run dir ok
    run.init_from('RST_RUN')
    assert run._nml_itm('cn_exp') == 'TEST_RUN'
    assert run._nml_itm('nn_it000') == 31
    assert run._nml_itm('nn_itend') == 198870
    assert run._nml_itm('ln_rstart') == True
    assert run._nml_itm('cn_ocerst_in') == 'RST_RUN_00000030_restart'
    assert run._nml_itm('cn_icerst_in') == 'RST_RUN_00000030_restart_ice'
    assert run._nml_itm('cn_ocerst_indir') == os.path.join( os.getcwd() , "RST_RUN" )
    assert run._nml_itm('cn_icerst_indir') == os.path.join( os.getcwd() , "RST_RUN" )
    assert run._nml_itm('cn_ocerst_outdir') == os.path.join( os.getcwd() , "TEST_RUN" )
    assert run._nml_itm('cn_icerst_outdir') == os.path.join( os.getcwd() , "TEST_RUN" )

    # reset
    run._time = 100.0
    run._ite = 10
    run.reset()
    assert run._ite == 31
    assert run._time == 0.0


# -- III : error dump
def test_error_dump():
    init_scenario()
    run = Run("TEST_RUN")
    run.dump(True)
    assert os.path.isdir('TEST_RUN.FAILED') == True
    assert os.path.isdir('TEST_RUN') == False


# -- IV : init run that already exist
def test_init_existing_run():
    init_scenario()
    run = Run("TEST_RUN")
    run.dump(False)
    del run

    # Run does not contain results
    run = Run("TEST_RUN")
    dirs = glob.glob("TEST_RUN*")
    assert len(dirs) == 1
    assert dirs[0] == "TEST_RUN"    

    # Run does not contain results but has failed
    run.dump(True)
    run = Run("TEST_RUN")
    dirs = glob.glob("TEST_RUN*")
    assert len(dirs) == 2
    assert dirs[-1] == "TEST_RUN_namesake00"    
    assert run._nml_itm("cn_exp") == "TEST_RUN_namesake00"
    del run

    # Run exists and does contain results
    run = Run("RST_RUN")
    dirs = glob.glob("RST_RUN*")
    assert len(dirs) == 2
    assert dirs[0] == "RST_RUN_namesake00"    


# -- restart iteration
def test_next_restart_ite():
    init_scenario() 
    run = Run("TEST_RUN")

    # OCE only - starting ite
    run._cfg["namsbc"]["nn_ice"] = 0
    assert run.next_restart_ite(1) == 2
    assert run.next_restart_ite(2) == 2
    assert run.next_restart_ite(3) == 3
    assert run.next_restart_ite(10) == 10
    # random ite
    run._ite = 100
    assert run.next_restart_ite(100) == 101
    assert run.next_restart_ite(101) == 101
    assert run.next_restart_ite(120) == 120

    # OCE and ICE - starting ite
    run._ite = 1
    run._cfg["namsbc"]["nn_ice"] = 2
    assert run.next_restart_ite(1) == 4
    assert run.next_restart_ite(2) == 4
    assert run.next_restart_ite(4) == 4
    assert run.next_restart_ite(5) == 6
    assert run.next_restart_ite(6) == 6
    assert run.next_restart_ite(7) == 8
    # random ite
    run._ite = 100
    assert run.next_restart_ite(100) == 104
    assert run.next_restart_ite(101) == 104
    assert run.next_restart_ite(104) == 104
    assert run.next_restart_ite(119) == 120
    assert run.next_restart_ite(120) == 120
    # with different fsbc
    run._ite = 1
    run._cfg["namsbc"]["nn_fsbc"] = 4
    assert run.next_restart_ite(1) == 8
    assert run.next_restart_ite(2) == 8
    assert run.next_restart_ite(8) == 8
    assert run.next_restart_ite(9) == 12
    assert run.next_restart_ite(10) == 12
    assert run.next_restart_ite(13) == 16


# -- format date
def test_format_date():
    init_scenario() 
    run = Run("TEST_RUN")
    assert run.format_date() == '00y00m00d'

    run._time = 86400
    assert run.format_date() == '00y00m01d'
    
    run._time = 24834730
    assert run.format_date() == '00y09m08d'
    
    run._time = 10**9
    assert run.format_date() == '31y08m11d'
