SRC_DIR = ${TS_REPO_ROOT}/src
FIT_DIR = ${TS_REPO_ROOT}/fit
BUILD_DIR_MPW1 = ${TS_REPO_ROOT}/build_mpw1
BUILD_DIR = ${TS_REPO_ROOT}/build
RELEASE_DIR = ${TS_REPO_ROOT}/release
BOOT_DIR = ${TS_REPO_ROOT}/release_boot

COMPILER = spect_compiler
ISS = spect_iss

MEM_GEN = ${TS_REPO_ROOT}/scripts/gen_mem_files.py
OPS_GEN = ${TS_REPO_ROOT}/scripts/gen_spect_ops_constants.py

FW_PARITY = 2 	# even
FW_BASE_ADDR = 0x8000

clear:
	rm -rf ${BUILD_DIR_1}
	mkdir ${BUILD_DIR_1}
	rm -rf ${BUILD_DIR}
	mkdir ${BUILD_DIR}

const_rom:
	${MEM_GEN} ${TS_REPO_ROOT}/data/const_rom_config.yml
	mv ${TS_REPO_ROOT}/data/constants_layout.s ${SRC_DIR}/mem_layouts/constants_layout.s

data_ram_in_const:
	${MEM_GEN} ${TS_REPO_ROOT}/data/data_ram_in_const_config.yml
	mv ${TS_REPO_ROOT}/data/constants_data_in_layout.s ${SRC_DIR}/mem_layouts/constants_data_in_layout.s

data_ram_in_const_boot:
	${MEM_GEN} ${TS_REPO_ROOT}/data/data_ram_in_const_boot_config.yml
	mv ${TS_REPO_ROOT}/data/constants_layout.s ${SRC_DIR}/mem_layouts/constants_layout.s

ops_constants:
	${OPS_GEN} ${TS_REPO_ROOT}/spect_ops_config.yml

compile: clear const_rom ops_constants
	rm -rf ${BUILD_DIR_1}
	mkdir ${BUILD_DIR_1}
	${COMPILER} --hex-format=1 --hex-file=${BUILD_DIR}/main.hex \
	--first-address=${FW_BASE_ADDR} \
	--parity=${FW_PARITY} \
	--dump-program=${BUILD_DIR}/program_dump.s \
	--dump-symbols=${BUILD_DIR}/symbols_dump.s \
	${SRC_DIR}/main.s > ${BUILD_DIR}/compile.log

release: const_rom ops_constants
	rm -rf ${RELEASE_DIR}
	mkdir ${RELEASE_DIR}
	mkdir ${RELEASE_DIR}/dump
	cp ${TS_REPO_ROOT}/data/constants.hex ${RELEASE_DIR}/constants.hex

	${COMPILER} --hex-format=1 --hex-file=${RELEASE_DIR}/spect_app.hex \
	--first-address=${FW_BASE_ADDR} \
	--parity=${FW_PARITY} \
	--dump-program=${RELEASE_DIR}/dump/program_dump_app.s \
	--dump-symbols=${RELEASE_DIR}/dump/symbols_dump_app.s \
	${SRC_DIR}/main.s > ${RELEASE_DIR}/compile_app.log

	${COMPILER} --hex-format=1 --hex-file=${RELEASE_DIR}/spect_debug.hex \
	--first-address=${FW_BASE_ADDR} \
	--parity=${FW_PARITY} \
	--dump-program=${RELEASE_DIR}/dump/program_dump_debug.s \
	--dump-symbols=${RELEASE_DIR}/dump/symbols_dump_debug.s \
	${SRC_DIR}/main_debug.s > ${RELEASE_DIR}/compile_debug.log

release_boot_mpw1: data_ram_in_const_boot ops_constants
	rm -rf ${BOOT_DIR}/mpw1
	mkdir ${BOOT_DIR}/mpw1
	mkdir ${BOOT_DIR}/mpw1/dump
	cp ${TS_REPO_ROOT}/data/constants.hex ${BOOT_DIR}/mpw1/constants.hex
	${COMPILER} --isa-version=1 --hex-format=1 --hex-file=${BOOT_DIR}/mpw1/spect_boot_mpw1.hex \
	--first-address=${FW_BASE_ADDR} \
	--parity=${FW_PARITY} \
	--dump-program=${BOOT_DIR}/mpw1/dump/program_dump.s \
	--dump-symbols=${BOOT_DIR}/mpw1/dump/symbols_dump.s \
	${SRC_DIR}/boot_main.s > ${BOOT_DIR}/mpw1/compile.log
	make const_rom

release_boot_mpw2: const_rom ops_constants
	rm -rf ${BOOT_DIR}/mpw2
	mkdir ${BOOT_DIR}/mpw2
	mkdir ${BOOT_DIR}/mpw2/dump
	cp ${TS_REPO_ROOT}/data/constants.hex ${BOOT_DIR}/mpw2/constants.hex
	${COMPILER} --isa-version=2 --hex-format=1 --hex-file=${BOOT_DIR}/mpw2/spect_boot_mpw2.hex \
	--first-address=${FW_BASE_ADDR} \
	--parity=${FW_PARITY} \
	--dump-program=${BOOT_DIR}/mpw2/dump/program_dump.s \
	--dump-symbols=${BOOT_DIR}/mpw2/dump/symbols_dump.s \
	${SRC_DIR}/boot_main.s > ${BOOT_DIR}/mpw2/compile.log

release_all: release release_boot_mpw1 release_boot_mpw2

compile_mpw1: data_ram_in_const
	rm -rf ${BUILD_DIR_MPW1}
	mkdir ${BUILD_DIR_MPW1}
	${COMPILER} --hex-format=1 --hex-file=${BUILD_DIR_MPW1}/main_mpw1.hex \
	--isa-version=1 \
	--first-address=${FW_BASE_ADDR} \
	--dump-program=${BUILD_DIR_MPW1}/program_dump.s \
	--dump-symbols=${BUILD_DIR_MPW1}/symbols_dump.s \
	${SRC_DIR}/mpw1/main_mpw1.s > ${BUILD_DIR_MPW1}/compile.log

fit_sources = x25519_nomask x25519_scalar_mask x25519_z_mask x25519_z_scalar_mask

release_fit: data_ram_in_const
	${MEM_GEN} ${TS_REPO_ROOT}/data/data_ram_in_const_config.yml
	mv ${TS_REPO_ROOT}/data/data_ram_in_const_layout.s ${FIT_DIR}/data_ram_in_const_layout.s
	mv ${TS_REPO_ROOT}/data/data_ram_in_const.hex ${FIT_DIR}/data_ram_in_const.hex
	$(foreach src, ${fit_sources}, ${COMPILER} --hex-format=1 --hex-file=${FIT_DIR}/${src}.hex --first-address=${FW_BASE_ADDR} ${FIT_DIR}/${src}.s > ${FIT_DIR}/log/${src}.compile.log;)

fit_test_data:
	${MEM_GEN} ${FIT_DIR}/x25519_test_input.yml

FIT_RUN_S = dummy
FIT_RUN_IN = dummy

fit_run:
	${ISS} --program=${FIT_DIR}/${FIT_RUN_S}.s --first-address=0x8000 --const-rom=${FIT_DIR}/data_ram_in_const.hex \
	--data-ram-out=${FIT_DIR}/${FIT_RUN_S}.out.hex --data-ram-in=${FIT_DIR}/${FIT_RUN_IN}.hex > ${FIT_DIR}/${FIT_RUN_S}.run.log
