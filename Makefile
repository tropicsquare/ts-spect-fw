SRC_DIR = ${TS_REPO_ROOT}/src
BUILD_DIR = ${TS_REPO_ROOT}/build
RELEASE_DIR = ${TS_REPO_ROOT}/release

COMPILER = spect_compiler
ISS = spect_iss

SDK = ${TS_REPO_ROOT}/modules/ts-spect-sdk

MEM_GEN = ${SDK}/scripts/gen_mem_files.py
OPS_GEN_S = ${SDK}/scripts/gen_spect_ops_constants_s.py
OPS_GEN_C = ${SDK}/scripts/gen_spect_ops_constants_c.py

CONST_ROM_DATA = ${SDK}/data
ROM_VERSION = ${DEFAULT_CONST_ROM}

ISA_VERSION=2
FW_PARITY = 2 	# even
FW_BASE_ADDR = 0x8000

MAIN=main.s

FW_VERSION=`git describe --dirty`

############################################################################################################
#		Environment check
############################################################################################################
ifndef TS_REPO_ROOT
	$(error TS_REPO_ROOT not set!)
endif

pre_release_check:
	./scripts/check_debug_opt_off.sh
	@if [ "$(ROM_VERSION)" = "devel" ]; then \
		echo -e "\033[0;31mERROR: ROM_VERSION must not be 'devel' for release builds!\033[0m"; \
		exit 1; \
	fi

############################################################################################################
#		Clear
############################################################################################################

clear:
	rm -rf ${BUILD_DIR}
	rm -f ${SRC_DIR}/mem_layouts/constants_layout.s
	rm -f ${SRC_DIR}/constants/spect_ops_constants.s

############################################################################################################
#		Generating necessary files
############################################################################################################

const_rom:
	$(info == Building Const ROM =================================================)
	$(info Const ROM version: $(ROM_VERSION))
	${MEM_GEN} \
	--cfg=${CONST_ROM_DATA}/spect_const_rom_${ROM_VERSION}.yml

ops_constants:
	$(info == Building Ops Constants =============================================)
	${OPS_GEN_S} \
	--cfg=${TS_REPO_ROOT}/spect_ops_config.yml \
	--file=${SRC_DIR}/constants/spect_ops_constants.s
	mv ${CONST_ROM_DATA}/spect_const_rom_${ROM_VERSION}_layout.s ${SRC_DIR}/mem_layouts/constants_layout.s

############################################################################################################
#		Compile APP FW to build directory
############################################################################################################

compile: const_rom ops_constants

	$(info == Compile ============================================================)
	rm -rf ${BUILD_DIR}
	mkdir ${BUILD_DIR}

	mv ${CONST_ROM_DATA}/spect_const_rom_${ROM_VERSION}.hex32 ${BUILD_DIR}/spect_const_rom.hex32

	${COMPILER} \
	--isa-version=${ISA_VERSION} \
	--hex-format=1 \
	--hex-file=${BUILD_DIR}/main.hex32 \
	--first-address=${FW_BASE_ADDR} \
	--parity=${FW_PARITY} \
	--dump-program=${BUILD_DIR}/program_dump.s \
	--dump-symbols=${BUILD_DIR}/symbols_dump.s \
	${SRC_DIR}/${MAIN} \
	> ${BUILD_DIR}/compile.log

	${OPS_GEN_C} --cfg=${TS_REPO_ROOT}/spect_ops_config.yml --file=${BUILD_DIR}/spect_ops_constants.h

release: pre_release_check const_rom ops_constants

	$(info == Release ============================================================)
	rm -rf ${RELEASE_DIR}
	mkdir ${RELEASE_DIR}
	mkdir ${RELEASE_DIR}/dump

	mv ${CONST_ROM_DATA}/spect_const_rom_${ROM_VERSION}.hex32 ${RELEASE_DIR}/spect_const_rom_code-${ROM_VERSION}.hex32
	ln -s ./spect_const_rom_code-${ROM_VERSION}.hex32 ${RELEASE_DIR}/spect_const_rom_code-${ROM_VERSION}.hex
	ln -s ./spect_app-${FW_VERSION}.hex32 ${RELEASE_DIR}/spect_app-${FW_VERSION}.hex

	${COMPILER} \
	--isa-version=${ISA_VERSION} \
	--hex-format=1 \
	--hex-file=${RELEASE_DIR}/spect_app-${FW_VERSION}.hex32 \
	--first-address=${FW_BASE_ADDR} \
	--parity=${FW_PARITY} \
	--dump-program=${RELEASE_DIR}/dump/program_dump_app.s \
	--dump-symbols=${RELEASE_DIR}/dump/symbols_dump_app.s \
	${SRC_DIR}/${MAIN} \
	> ${RELEASE_DIR}/compile.log

	${OPS_GEN_C} --cfg=${TS_REPO_ROOT}/spect_ops_config.yml --file=${RELEASE_DIR}/spect_ops_constants.h
