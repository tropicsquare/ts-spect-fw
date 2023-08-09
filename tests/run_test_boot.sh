#! /bin/bash

declare -i ret_val=0

export TS_SPECT_FW_TEST_DONT_DUMP=""

./test_boot_sequence.py
if [ $? -ne 0 ]; then
    ret_val=$((ret_val + 1))
fi

echo "Failed $ret_val"

unset -f TS_SPECT_FW_TEST_DONT_DUMP

exit $ret_val