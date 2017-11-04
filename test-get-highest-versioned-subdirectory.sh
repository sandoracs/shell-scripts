#!/usr/bin/env bash

test_directory="test-get-highest-versioned-subdirectory-tmp"

if [ ! -e "${test_directory}" ]; then
    mkdir "./${test_directory}"
fi

test_cases=(\
"test-0.0.1alpha" \
"test-2.5.30" \
"test-9.20.0" \
"test-10.0.1" \
"test-10.3.10" \
"test-10.4.0" \
)

for item in ${test_cases[@]}; do
    mkdir "./${test_directory}/${item}"
done

result=$(./get-highest-versioned-subdirectory.sh ${test_directory})
rm -rf "${test_directory}"

if [ "${result}" != "${test_directory}/test-10.4.0" ]; then
    echo "Failed: ${0}"
    echo "    Actual:   ${result}"
    echo "    Expected: ${test_directory}/test-10.4.0"
    exit 1
else
    echo "Passed: ${0}"
    exit 0
fi