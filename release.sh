#! /bin/bash

BASEDIR=$TS_REPO_ROOT/spect_fw
RELEASEDIR=$TS_REPO_ROOT/spect_fw/release
SPECT_APPS_PATH=$TS_REPO_ROOT/compiler/build/src/apps

rm -rf $RELEASEDIR

mkdir $RELEASEDIR
mkdir $RELEASEDIR/log
mkdir $RELEASEDIR/dump

cd $TS_REPO_ROOT/scripts
./gen_mem_files.py $BASEDIR/data/data_ram_in_const_config.yml
#./gen_mem_files.py $RUNDIR/data/data_ram_in_config.yml
./gen_mem_files.py $BASEDIR/data/eddsa_verify_data_in.yml
./gen_grv_hex.py $BASEDIR/data/random_data.yml

cp $BASEDIR/data/data_ram_in_const.hex $RELEASEDIR/data_ram_in_const.hex

cd $SPECT_APPS_PATH

./spect_compiler --hex-format=1 --hex-file=$RELEASEDIR/main.hex \
--first-address=0x8000 \
--dump-program=$RELEASEDIR/dump/program_dump.s \
--dump-symbols=$RELEASEDIR/dump/symbols_dump \
$BASEDIR/main.s > $RELEASEDIR/log/compile.log