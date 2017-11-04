#!/usr/bin/env sh

directory=$(dirname "${0}")
test_name_expression="test-.*\.sh"
tests=$(find ${directory} -type f | grep "${test_name_expression}")
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