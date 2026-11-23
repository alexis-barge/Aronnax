# C1D_PAPA32

Modified version of standard [C1D_PAPA](https://doi.org/10.5194/gmd-8-69-2015) [NEMO](https://www.nemo-ocean.eu/) test case. 
It is used to deploy a light NEMO config for Aronnax non-regressive and operating tests.

**Modifications:**
  - vertical grid discretized over 32 depth levels
  - vertical domain defined up to 200m depth
  - new time step: 1800s

**Content:**
- Directory follows standard structure of a NEMO config.
- ``FORCING`` contains input files (domain and surface forcing)
- ``test_aronnax.py`` is the Aronnax full-chain testing procedure

**Requirements:**
- [NEMO_v5.0.1](https://forge.nemo-ocean.eu/nemo/nemo/-/releases/5.0.1)
- [XIOS2](https://gitlab.in2p3.fr/ipsl/projets/xios-projects/xios/-/tree/XIOS2?ref_type=heads) compiled with Position Idependent Code flag (``-fPIC`` or equivalent depending on your compiler)

**Run test case:**
- Copy whole directory ``C1D_PAPA32`` in NEMO_v5.0.1 config directory ``nemo_v5.0.1/cfgs``
- The arch file ``arch-C1D_PAPA32_GCC.fcm`` is pre-filled for GH CI workflow and Aronnax container. Adapt with your computing environment if necessary.
- Run ``deploy.sh``
- Install Aronnax ``NEMO_BLD=/PATH/TO/nemo_v5.0.1/cfgs/C1D_PAPA32  pip install .``
- Go in ``nemo_v5.0.1/cfgs/C1D_PAPA32/EXP00/RUN`` and run ``test_aronnax.py`` script.
