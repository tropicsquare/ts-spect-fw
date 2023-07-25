#! /bin/bash

echo "*************************************************" 
echo "  Compile Firmware"
echo "*************************************************" 
cd ..
make compile
cd tests

tests=("sha512" "x25519_full_sc" ecc_key_gen "eddsa_verify")

declare -i ret_val=0

for test in ${tests[@]}; do
    echo "*************************************************" 
    echo "  Running test $test"
    echo "*************************************************" 
    ./test_$test.py
    if [ $? -ne 0 ]; then
        ret_val=$((ret_val + 1))
    fi
done

echo "Failed $ret_val"

exit $ret_val