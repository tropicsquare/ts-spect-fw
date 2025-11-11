#!/bin/bash

file=${TS_REPO_ROOT}/src/main.s

opts=(
    DEBUG_OPS
    IN_SRC_EN
    OUT_SRC_EN
)

for opts in "${opts[@]}"; do
    if grep -Fxq ".define ${opts}" "$file"; then
        echo -e "\033[0;31mSome debug options are enabled. This is not allowed for release!\033[0m"
        exit 1
    fi
done

exit 0