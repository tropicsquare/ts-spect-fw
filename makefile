FW_DIR = ${TS_REPO_ROOT}/spect_fw
SRC_DIR = ${FW_DIR}/src
FIT_DIR = ${FW_DIR}/fit
BUILD_DIR = ${FW_DIR}/build
TEST_DIR = ${BUILD_DIR}/build

COMPILER = ${TS_REPO_ROOT}/compiler/build/src/apps/spect_compiler
ISS = ${TS_REPO_ROOT}/compiler/build/src/apps/spect_iss

MEM_GEN = ${TS_REPO_ROOT}/scripts/gen_mem_files.py
RNG_GEN = ${TS_REPO_ROOT}/scripts/gen_rng_hex.py

RELEASE_DIR = release

FW_BASE_ADDR = 0x8000

TEST = dummy

const_rom:
	${MEM_GEN} ${FW_DIR}/data/const_rom_config.yml
	mv ${FW_DIR}/data/const_rom_leyout.s ${SRC_DIR}/mem_leyouts/const_rom_leyout.s

data_ram_in_const:
	${MEM_GEN} ${FW_DIR}/data/data_ram_in_const_config.yml
	mv ${FW_DIR}/data/data_ram_in_const_leyout.s ${SRC_DIR}/mem_leyouts/data_ram_in_const_leyout.s

rng:
	${RNG_GEN} ${FW_DIR}/data/rng_data.yml

ops_constants:
	${FW_DIR}/gen_spect_ops_constants.py ${FW_DIR}/spect_ops_config.yml

compile: const_rom ops_constants
	${COMPILER} --hex-format=1 --hex-file=${BUILD_DIR}/main.hex \
	--first-address=${FW_BASE_ADDR} \
	--dump-program=${BUILD_DIR}/program_dump.s \
	--dump-symbols=${BUILD_DIR}/symbols_dump.s \
	${SRC_DIR}/main.s > ${BUILD_DIR}/compile.log

release: data_ram_in_const ops_constants
	rm -rf ${FW_DIR}/${RELEASE_DIR}
	mkdir ${FW_DIR}/${RELEASE_DIR}
	mv ${FW_DIR}/data/data_ram_in_const.hex ${RELEASE_DIR}/data_ram_in_const.hex
	${COMPILER} --hex-format=1 --hex-file=${RELEASE_DIR}/main.hex \
	--first-address=${FW_BASE_ADDR} \
	--dump-program=${RELEASE_DIR}/program_dump.s \
	--dump-symbols=${RELEASE_DIR}/symbols_dump.s \
	${SRC_DIR}/main.s > ${RELEASE_DIR}/compile.log

fit_sources = x25519_nomask x25519_scalar_mask x25519_z_mask x25519_z_scalar_mask

release_fit: data_ram_in_const
	${MEM_GEN} ${FW_DIR}/data/data_ram_in_const_config.yml
	mv ${FW_DIR}/data/data_ram_in_const_leyout.s ${FIT_DIR}/data_ram_in_const_leyout.s
	mv ${FW_DIR}/data/data_ram_in_const.hex ${FIT_DIR}/data_ram_in_const.hex
	$(foreach src, ${fit_sources}, ${COMPILER} --hex-format=1 --hex-file=${FIT_DIR}/${src}.hex --first-address=${FW_BASE_ADDR} ${FIT_DIR}/${src}.s > ${FIT_DIR}/log/${src}.compile.log;)

fit_test_data:
	${MEM_GEN} ${FIT_DIR}/x25519_test_input.yml

FIT_RUN_S = dummy
FIT_RUN_IN = dummy

fit_run:
	${ISS} --program=${FIT_DIR}/${FIT_RUN_S}.s --first-address=0x8000 --const-rom=${FIT_DIR}/data_ram_in_const.hex \
	--data-ram-out=${FIT_DIR}/${FIT_RUN_S}.out.hex --data-ram-in=${FIT_DIR}/${FIT_RUN_IN}.hex > ${FIT_DIR}/${FIT_RUN_S}.run.log
