#!/bin/bash

# Prepare config compilation
echo "CREATE CONFIG"
touch ../work_cfgs.txt
if ! grep -q "C1D_PAPA32 OCE" ../work_cfgs.txt; then
    echo "C1D_PAPA32 OCE" >> ../work_cfgs.txt
fi
cp arch-C1D_PAPA32_GCC.fcm ../../arch/

# Check if NEMO is compiled
echo "COMPILE NEMO"
if [ ! -d "EXP00" ]; then
    echo "   - EXP00 does not exist, compile"
    ../../makenemo -m C1D_PAPA32_GCC -r C1D_PAPA32 -n C1D_PAPA32
else
    if [ ! -L "EXP00/nemo" ]; then
    echo "   - NEMO not compiled, compile"
        ../../makenemo -m C1D_PAPA32_GCC -r C1D_PAPA32 -n C1D_PAPA32
    fi
    echo "   - Already done" 
fi

# Define, create execution directory and move there
echo "RUN DIR"
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$CONFIG_DIR/EXP00/RUN" ]; then
    echo "    - Reset"
    rm -r $CONFIG_DIR/EXP00/RUN
else
    echo "    - Create"
fi
mkdir -p $CONFIG_DIR/EXP00/RUN
cd $CONFIG_DIR/EXP00/RUN


# Get input namelist  and xml files
for file in $CONFIG_DIR/EXP00/*namelist*_ref $CONFIG_DIR/EXP00/*namelist*_cfg $CONFIG_DIR/EXP00/*.xml
do
    cp $file . || exit 3
done


# Get Aronnax script
echo "ARONNAX"
cp $CONFIG_DIR/test_aronnax.py . || exit 4
echo "DONE PREP"
