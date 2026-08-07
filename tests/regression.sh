#! /bin/bash

echo "*************************************************"
echo "*  Compile Firmware"
echo "*************************************************"

make -C .. compile

declare -i ret_val=0

for test in test_*.py; do
    ./$test
    if [ $? -ne 0 ]; then
        ret_val=$((ret_val + 1))
    fi
done

echo "Failed $ret_val"

exit $ret_val
