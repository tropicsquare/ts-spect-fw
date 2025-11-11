#! /bin/bash

tests=(\
    "clear" \
    "x25519_full_sc" \
    "ecc_key_gen_store"  \
    "ecc_key_read" \
    "ecc_key_erase" \
    "ecdsa_sign" \
    "eddsa_sequence" \
    "eddsa_full_setup" \
    "ecdsa_full_setup" \
)

declare -i ret_val=0

echo ${1}

export TS_SPECT_FW_TEST_RELEASE=""

for test in ${tests[@]}; do
    ./test_$test.py
    if [ $? -ne 0 ]; then
        ret_val=$((ret_val + 1))
    fi
done

echo "Failed $ret_val"

unset TS_SPECT_FW_TEST_RELEASE

exit $ret_val