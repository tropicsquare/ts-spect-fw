#! /bin/bash

tests=("cmd_decode" "sha512" "x25519_kpair_gen" )

declare -i ret_val=0

for test in ${tests[@]}; do
    echo "Running test $test"
    ./test_$test.py
    if [ $? -eq 0 ]; then
        echo "Test $test passed"
    else
        ret_val=$((ret_val + 1))
        echo "Test $test failed"
    fi
done

echo "Failed $ret_val"

exit $ret_val