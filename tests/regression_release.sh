#! /bin/bash

declare -i ret_val=0

export TS_SPECT_FW_TEST_RELEASE=""

for test in test_*.py; do
    ./$test
    if [ $? -ne 0 ]; then
        ret_val=$((ret_val + 1))
    fi
done

unset TS_SPECT_FW_TEST_RELEASE

echo "Failed $ret_val"

exit $ret_val
