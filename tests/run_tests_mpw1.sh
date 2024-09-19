#! /bin/bash

echo "*************************************************" 
echo "*  Compile MPW1 Firmware"
echo "*************************************************" 

make -C .. compile_mpw1
make -C .. compile_boot_mpw1

tests=(\
    "mpw1"
)

declare -i ret_val=0

echo ${1}

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

exit $ret_val
