import os
import glob
import shutil

# Clean before testing
for d in glob.glob("C1D_PAPA32*"):
    shutil.rmtree(d)
if os.path.exists("__ARONNAX_TEST_SUCCESSFUL.txt"):
    os.remove("__ARONNAX_TEST_SUCCESSFUL.txt")

# Test import
# -----------
import Aronnax
assert 'cfgs/C1D_PAPA32' in Aronnax.__nemo_bld__

# ====================================
#   I. Single run without restart OK
# ====================================
# Driver creation
solver = Aronnax.NEMO(config="C1D_PAPA32_TEST", nproc=1, verbose=False)
assert os.path.isdir("C1D_PAPA32_TEST.seg00")
assert solver.is_running() == False

# Worker start and finish
solver.start()
assert solver.is_running() == True
assert solver.run._lock == True

solver.finish()
assert solver.is_running() == False
assert solver.run._lock == False

# Advance default
solver.advance()
assert solver.run._ite == 1
assert solver.run._time == 0.0

solver.start()
solver.advance()
assert solver.run._ite == 2
assert solver.run._time == 1800.0

# Advance with ite
solver.advance(ite=10)
assert solver.run._ite == 12
assert solver.run._time == 19800.0

# Advance with days - months - years - everything
solver.advance(days=10)
assert solver.run._ite == 492
assert solver.run._time == 883800.0
solver.advance(months=2)
assert solver.run._ite == 3468
assert solver.run._time == 6240600.0
solver.advance(years=0.3)
assert solver.run._ite == 8724
assert solver.run._time == 15701400.0
solver.advance(days=3,months=1,years=0.2)
assert solver.run._ite == 13860
assert solver.run._time == 24946200.0
# format date
assert solver.run.format_date() == '00y09m09d'

# Get
t_mon = solver.field('t')
t_freeze = solver.field('t', save=True)
sal = solver.field('s')
assert sal[0].shape == (5,5,32)
assert sal[0][0,0,0] > 30.0
assert t_mon[0][0,0,0] < 7.0
assert t_mon[0][0,0,0] == t_freeze[0][0,0,0]

# freeze vs monitoring
solver.advance(months=1)
assert t_mon[0][0,0,0] != t_freeze[0][0,0,0]

# reload
t_freeze.reload()
assert t_mon[0][0,0,0] == t_freeze[0][0,0,0]

# apply
double = lambda x: x*2
t_freeze.apply( double , [t_mon], impose=False)
assert t_freeze[0][0,0,0] > 7.0

# del - check dump
del solver
assert os.path.isfile('C1D_PAPA32_TEST.seg00/C1D_PAPA32_TEST.seg00_1d_20100615_20780720_grid_T.nc') == True
assert os.path.isfile('C1D_PAPA32_TEST.seg00/namelist_cfg.C1D_PAPA32_TEST.seg00') == True
assert os.path.isfile('C1D_PAPA32_TEST.seg00/namelist_ref.C1D_PAPA32_TEST.seg00') == True
assert os.path.isfile('C1D_PAPA32_TEST.seg00/namelist_ice_cfg.C1D_PAPA32_TEST.seg00') == True
assert os.path.isfile('C1D_PAPA32_TEST.seg00/namelist_ice_ref.C1D_PAPA32_TEST.seg00') == True
assert os.path.isfile('C1D_PAPA32_TEST.seg00/ocean.output.C1D_PAPA32_TEST.seg00') == True


# =======================
#   II. Single run FAIL
# =======================
# Driver creation - run exists
solver = Aronnax.NEMO(config="C1D_PAPA32_TEST", nproc=1, verbose=False)
assert os.path.isdir("C1D_PAPA32_TEST.seg00_namesake00")

# Set
solver.start()
uu = solver.field('u')
solver.advance(months=2)
uu[0] = uu[0]*1000.0

# Error happens
solver.advance(months=2)
assert uu[0] == None
assert solver._error == True
assert os.path.isdir("C1D_PAPA32_TEST.seg00_namesake00.FAILED")

# Free error - increment namesake
solver.start()
assert os.path.isdir("C1D_PAPA32_TEST.seg00_namesake01")
del solver

# =====================================
#   III. Three-times run with restart
# =====================================
# Driver creation - reuse previous namesake
solver = Aronnax.NEMO(config="C1D_PAPA32_TEST", nproc=1, verbose=False)
assert solver.run._label == "C1D_PAPA32_TEST.seg00_namesake01"

# restart manually
solver.start()
solver.advance(months=1)
solver.finish(write_restart=True)
assert solver.is_running() == False
assert os.path.isfile("C1D_PAPA32_TEST.seg00_namesake01/C1D_PAPA32_TEST.seg00_namesake01_00001490_restart.nc") == True

solver.set_next_run()
assert os.path.isdir("C1D_PAPA32_TEST.seg01")

solver.start()
assert solver.run._ite == 1491
assert solver.run._time == 0.0

# automatic restart
solver.advance(months=2)
solver.restart()
assert os.path.isfile("C1D_PAPA32_TEST.seg01/C1D_PAPA32_TEST.seg01_00004468_restart.nc") == True
assert os.path.isdir("C1D_PAPA32_TEST.seg02")
assert solver.run._ite == 4469
solver.finish()


# =============================
#   IV. Cold run from restart
# =============================
# Driver creation
solver = Aronnax.NEMO(config="C1D_PAPA32_FORK_A", nproc=1, verbose=False)

# Start from empty run
solver.run_from("C1D_PAPA32_TEST.seg00")
assert solver.run._ite == 1

# Start from previous run ok
solver.run_from("C1D_PAPA32_TEST.seg01")
assert os.path.isdir("C1D_PAPA32_FORK_A.seg00")
assert solver.run._ite == 4469

# Compute run and dump
solver.start()
solver.advance(days=20,write_restart=True)
solver.finish()

# Rewind and fork
solver.run_from("C1D_PAPA32_TEST.seg00_namesake01", fork="C1D_PAPA32_FORK_B")
assert os.path.isdir("C1D_PAPA32_FORK_B.seg00")
assert solver.run._ite == 1491
del solver

# When implmented: print simulation tree
# ...

# =================== #
#   TEST SUCCESSFUL
# =================== #
open("__ARONNAX_TEST_SUCCESSFUL.txt", "w").close()
