#!/usr/bin/env bash

script_directory="$(cd "$(dirname "${0:-${PWD}}")" && pwd)"
test_name_expression="test-.*\.sh"
tests=$(find ${script_directory} -type f | grep "${test_name_expression}")
testCount=${#tests[@]}

successful=0
for test in ${tests[@]}; do
    result=$(${test})
    echo "${result}"

    if [ "${result:0:6}" == "Passed" ]; then
        successful=$(expr ${successful} + 1)
    fi
done

failed=$(expr ${testCount} - ${successful})
success_percentage=$(expr ${successful} / ${testCount} \* 100)

echo "Successful: ${successful}, failed: ${failed}, success percentage: ${success_percentage}%"

if [ ${failed} -gt 0 ]; then
    exit 1
fi

exit 0