#! /bin/bash

tests=(\
    "boot_sequence" \
    "x25519_full_sc" \
    "ecc_key_gen"  \
    "ecc_key_read" \
    "ecc_key_erase" \
    "ecdsa_sign" \
    "eddsa_sequence" \
    "x25519_dbg" \
    "eddsa_dbg" \
    "ecdsa_dbg" \
)

declare -i ret_val=0

echo ${1}

#export TS_SPECT_FW_TEST_DONT_DUMP=""
export TS_SPECT_FW_TEST_RELEASE=""

for test in ${tests[@]}; do
    echo "*************************************************" 
    echo "*  Running test $test"
    echo "*************************************************" 
    ./test_$test.py
    if [ $? -ne 0 ]; then
        ret_val=$((ret_val + 1))
    fi
done

echo "Failed $ret_val"

#unset -f TS_SPECT_FW_TEST_DONT_DUMP
unset -f TS_SPECT_FW_TEST_RELEASE

exit $ret_val