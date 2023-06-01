BASE_DIR = ${shell pwd}
COMPILER = ${TS_REPO_ROOT}/compiler/build/src/apps/spect_compiler
ISS = ${TS_REPO_ROOT}/compiler/build/src/apps/spect_iss

MEM_GEN = ${TS_REPO_ROOT}/scripts/gen_mem_files.py
RNG_GEN = ${TS_REPO_ROOT}/scripts/gen_rng_hex.py

RELEASE_DIR = release

FW_BASE_ADDR = 0x8000

TEST = ${BASE_DIR}/tests/dummy

const_rom:
	${MEM_GEN} data/const_rom_config.yml

data_ram_in_const:
	${MEM_GEN} data/data_ram_in_const_config.yml

rng:
	${RNG_GEN} data/rng_data.yml

ops_constants:
	./gen_spect_ops_constants.py spect_ops_config.yml

compile: const_rom ops_constants
	${COMPILER} --hex-format=1 --hex-file=${BASE_DIR}/main.hex \
	--first-address=${FW_BASE_ADDR} \
	--dump-program=${BASE_DIR}/dump/program_dump.s \
	--dump-symbols=${BASE_DIR}/dump/symbols_dump.s \
	${BASE_DIR}/main.s > ${BASE_DIR}/log/compile.log

run: compile
	${ISS} --instruction-mem=${BASE_DIR}/main.hex \
	--const-rom=${BASE_DIR}/data/const_rom.hex \
	--data-ram-in=${BASE_DIR}/data/data_ram_in.hex \
	--data-ram-out=${BASE_DIR}/data/out.hex \
	--grv-hex=${BASE_DIR}/data/grv.hex \
	--shell --cmd-file=${BASE_DIR}/iss_cmd_file > ${BASE_DIR}/log/iss.log

release: data_ram_in_const ops_constants
	rm -r ${BASE_DIR}/${RELEASE_DIR}
	mkdir ${RELEASEDIR}
	mkdir ${RELEASEDIR}/log
	mkdir ${RELEASEDIR}/dump
	cp ${BASE_DIR}/data/data_ram_in_const.hex ${RELEASE_DIR}/data_ram_in_const.hex
	${COMPILER} --hex-format=1 --hex-file=${RELEASE_DIR}/main.hex \
	--first-address=${FW_BASE_ADDR} \
	--dump-program=${RELEASE_DIR}/dump/program_dump.s \
	--dump-symbols=${RELEASE_DIR}/dump/symbols_dump.s \
	${BASE_DIR}/main.s > ${RELEASE_DIR}/log/compile.log
