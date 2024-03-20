SRC_DIR = ${TS_REPO_ROOT}/src
FIT_DIR = ${TS_REPO_ROOT}/fit
BUILD_DIR_MPW1 = ${TS_REPO_ROOT}/build_mpw1
BUILD_DIR = ${TS_REPO_ROOT}/build
RELEASE_DIR = ${TS_REPO_ROOT}/release
MPW1_BOOT_DIR = ${TS_REPO_ROOT}/build_mpw1_boot

COMPILER = spect_compiler
ISS = spect_iss

MEM_GEN = ${TS_REPO_ROOT}/scripts/gen_mem_files.py
OPS_GEN = ${TS_REPO_ROOT}/scripts/gen_spect_ops_constants.py

ISA_VERSION=2
FW_PARITY = 2 	# even
FW_BASE_ADDR = 0x8000

FW_VERSION=`git describe --dirty`

############################################################################################################
#		Environment check
############################################################################################################

check_env:
	printenv TS_REPO_ROOT

############################################################################################################
#		Clear
############################################################################################################

clear: check_env
	rm -rf ${BUILD_DIR_MPW1}
	rm -rf ${BUILD_DIR}
	rm -rf ${MPW1_BOOT_DIR}
	rm -rf ${RELEASE_DIR}
	rm -f ${TS_REPO_ROOT}/data/*.hex
	rm -f ${SRC_DIR}/mem_layouts/constants_layout.s
	rm -f ${SRC_DIR}/constants/spect_ops_constants.s

############################################################################################################
#		Generating necessary files
############################################################################################################

const_rom:
	${MEM_GEN} ${TS_REPO_ROOT}/data/const_rom_config.yml
	mv ${TS_REPO_ROOT}/data/constants_layout.s ${SRC_DIR}/mem_layouts/constants_layout.s

data_ram_in_const:
	${MEM_GEN} ${TS_REPO_ROOT}/data/data_ram_in_const_config.yml
	mv ${TS_REPO_ROOT}/data/constants_data_in_layout.s ${SRC_DIR}/mem_layouts/constants_data_in_layout.s

data_ram_in_const_boot:
	${MEM_GEN} ${TS_REPO_ROOT}/data/data_ram_in_const_boot_config.yml
	mv ${TS_REPO_ROOT}/data/constants_data_in_boot_layout.s ${SRC_DIR}/mem_layouts/constants_layout.s

ops_constants:
	${OPS_GEN} ${TS_REPO_ROOT}/spect_ops_config.yml

############################################################################################################
#		Compile APP FW to build directory
############################################################################################################

compile: check_env const_rom ops_constants
	rm -rf ${BUILD_DIR}
	mkdir ${BUILD_DIR}
	mv ${TS_REPO_ROOT}/data/constants.hex ${BUILD_DIR}/constants.hex
	${COMPILER} --isa-version=${ISA_VERSION} --hex-format=1 --hex-file=${BUILD_DIR}/main.hex \
	--first-address=${FW_BASE_ADDR} \
	--parity=${FW_PARITY} \
	--dump-program=${BUILD_DIR}/program_dump.s \
	--dump-symbols=${BUILD_DIR}/symbols_dump.s \
	${SRC_DIR}/main.s > ${BUILD_DIR}/compile.log

############################################################################################################
#		Final APP+BOOT FW Release
############################################################################################################

release: check_env const_rom ops_constants
	rm -rf ${RELEASE_DIR}
	mkdir ${RELEASE_DIR}
	mkdir ${RELEASE_DIR}/dump
	mkdir ${RELEASE_DIR}/log
	mv ${TS_REPO_ROOT}/data/constants.hex ${RELEASE_DIR}/spect_const_rom_code-${FW_VERSION}.hex

	${COMPILER} --isa-version=2 --hex-format=1 --hex-file=${RELEASE_DIR}/spect_app-${FW_VERSION}.hex \
	--first-address=${FW_BASE_ADDR} \
	--parity=${FW_PARITY} \
	--dump-program=${RELEASE_DIR}/dump/program_dump_app.s \
	--dump-symbols=${RELEASE_DIR}/dump/symbols_dump_app.s \
	${SRC_DIR}/main.s > ${RELEASE_DIR}/log/compile_app.log

	${COMPILER} --isa-version=2 --hex-format=1 --hex-file=${RELEASE_DIR}/spect_boot-${FW_VERSION}.hex \
	--first-address=${FW_BASE_ADDR} \
	--parity=${FW_PARITY} \
	--dump-program=${RELEASE_DIR}/dump/program_dump_boot.s \
	--dump-symbols=${RELEASE_DIR}/dump/symbols_dump_boot.s \
	${SRC_DIR}/boot_main.s > ${RELEASE_DIR}/log/compile_boot.log

############################################################################################################
#		MPW1 FW (APP+BOOT)
############################################################################################################

compile_mpw1: check_env data_ram_in_const
	rm -rf ${BUILD_DIR_MPW1}
	mkdir ${BUILD_DIR_MPW1}
	mv ${TS_REPO_ROOT}/data/constants_data_in.hex ${BUILD_DIR_MPW1}/constants.hex
	${COMPILER} --hex-format=1 --hex-file=${BUILD_DIR_MPW1}/main_mpw1.hex \
	--isa-version=1 \
	--first-address=${FW_BASE_ADDR} \
	--dump-program=${BUILD_DIR_MPW1}/program_dump.s \
	--dump-symbols=${BUILD_DIR_MPW1}/symbols_dump.s \
	${SRC_DIR}/mpw1/main_mpw1.s > ${BUILD_DIR_MPW1}/compile.log

compile_boot_mpw1: check_env data_ram_in_const_boot ops_constants
	rm -rf ${MPW1_BOOT_DIR}
	mkdir ${MPW1_BOOT_DIR}
	mkdir ${MPW1_BOOT_DIR}/dump
	mv ${TS_REPO_ROOT}/data/constants_data_in_boot.hex ${MPW1_BOOT_DIR}/constants.hex
	${COMPILER} --isa-version=1 --hex-format=1 --hex-file=${MPW1_BOOT_DIR}/spect_boot_mpw1.hex \
	--first-address=${FW_BASE_ADDR} \
	--parity=${FW_PARITY} \
	--dump-program=${MPW1_BOOT_DIR}/dump/program_dump.s \
	--dump-symbols=${MPW1_BOOT_DIR}/dump/symbols_dump.s \
	${SRC_DIR}/boot_main.s > ${MPW1_BOOT_DIR}/compile.log
