#!/usr/bin/env bash

exit_invalid_arguments=-1

check_expression() {
    if [ "${#}" -ne 4 ]; then
        error "Error: invalid usage of check_expression(), 4 arguments are required (context, expression, expression_text, exit_code), <${#}> was/were provided, <${@}>." ${exit_invalid_arguments}
    fi

    context=${1}
    expression=${2}
    expression_text=${3}
    exit_code=${4}

    if [ ! ${2} ]; then
        error "Error: expression evaluated as false in <${context}> for expression <${expression_text}>" ${4}
    fi
}

create_directories() {
    check_expression "create_directories()" $((${#} == 2)) "${#} == 2" ${exit_invalid_arguments}

    array_name=$2[@]
    temporary_directory="${1}"
    test_directories=("${!array_name}")

    if [ ! -e "${temporary_directory}" ]; then
        mkdir "${script_directory}/${temporary_directory}"
    fi

    for item in ${test_directories[@]}; do
        mkdir "${script_directory}/${temporary_directory}/${item}"
    done
}

error() {
    if [ "${#}" -ne 2 ]; then
        echo "Error: invalid usage of error(), 2 arguments are required, ${#} was/were provided."
        return -1
    fi

    error_message=${1}
    exit_code=${2}

    echo "${error_message}" >&2
    exit ${exit_code}
}

script_directory="$(cd "$(dirname "${0:-${PWD}}")" && pwd)"

temporary_directory="test-get-highest-versioned-subdirectory-tmp"
test_directories=(\
"test-fake" \
"test-0.0.1alpha" \
"test-2.5.30" \
"test-9.20.0" \
"test-10.0.1" \
"test-10.3.10" \
"test-10.4.0k" \
"test-10.4.0l" \
"10.4.0m" \
)

create_directories "${temporary_directory}" test_directories

result_simple=$(${script_directory}/get-highest-versioned-subdirectory.sh ${temporary_directory})
expected_result_simple="${temporary_directory}/10.4.0m"

result_filtered=$(${script_directory}/get-highest-versioned-subdirectory.sh ${temporary_directory} "test-")
expected_result_filtered="${temporary_directory}/test-10.4.0l"

rm -rf "${temporary_directory}"

if [ "${result_simple}" != "${expected_result_simple}" ]; then
    echo "Failed: ${0}"
    echo "    Actual:   ${result_simple}"
    echo "    Expected: ${expected_result_simple}"
    exit 1
elif [ "${result_filtered}" != "${expected_result_filtered}" ]; then
    echo "Failed: ${0}"
    echo "    Actual:   ${result_filtered}"
    echo "    Expected: ${expected_result_filtered}"
    exit 1
else
    echo "Passed: ${0}"
    exit 0
fi