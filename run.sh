#! /bin/bash

RUNDIR=$TS_REPO_ROOT/spect_fw
SPECT_APPS_PATH=$TS_REPO_ROOT/compiler/build/src/apps

cd $TS_REPO_ROOT/scripts
./gen_mem_files.py $RUNDIR/data/const_rom_config.yml
./gen_mem_files.py $RUNDIR/data/data_ram_in_config.yml
./gen_grv_hex.py $RUNDIR/data/random_data.yml

cd $SPECT_APPS_PATH

./spect_compiler --hex-format=1 --hex-file=$RUNDIR/main.hex \
--dump-program=$RUNDIR/dump/program_dump.s \
--dump-symbols=$RUNDIR/dump/symbols_dump \
$RUNDIR/main.s > $RUNDIR/log/compile.log

./spect_iss --instruction-mem=$RUNDIR/main.hex \
--const-rom=$RUNDIR/data/const_rom.hex \
--data-ram-in=$RUNDIR/data/data_ram_in.hex \
--data-ram-out=$RUNDIR/data/out.hex \
--grv-hex=$RUNDIR/data/grv.hex > $RUNDIR/log/iss.log


