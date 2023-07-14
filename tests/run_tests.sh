#! /bin/bash

tests=("curve25519_rpg" "ed25519_rpg" "sha512" "eddsa_verify" "cmd_decode")

declare -i ret_val=0

for test in ${tests[@]}; do
    ./test_$test.py
    if [ $? -eq 0 ]; then
        echo passed
    else
        ret_val=$((ret_val + 1))
        echo failed
    fi
done

echo "Failed $ret_val"

exit $ret_val