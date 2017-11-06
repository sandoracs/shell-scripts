#!/usr/bin/env bash

exit_invalid_arguments=-1
exit_parent_not_existing=-2
exit_parent_not_a_directory=-3

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

check_input() {
    check_expression "check_input()" $((${#} == 1)) "${#} == 1" ${exit_invalid_arguments}

    parent_directory=${1}

    if [ ! -e "${parent_directory}" ]; then
        error "Error: parent directory <${parent_directory}> could not be found" ${exit_parent_not_existing}
    fi

    if [ ! -d "${parent_directory}" ]; then
        error "Error: <${parent_directory}> specified for parent directory is not a directory" ${exit_parent_not_a_directory}
    fi
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

get_versioned_directory() {
    check_expression "get_versioned_directory()" $((${#} == 2)) "${#} == 2" ${exit_invalid_arguments}

    parent_directory="${1%/}"
    prefix_filter="${2}"

    current_prefix=""
    current_suffix=""
    current_versions=(0 0 0)
    directories=$(find ${parent_directory} -type d -mindepth 1 -maxdepth 1)
    versioned_directory=""
    version_expression="[0-9]\+\(\.[0-9]\+\)*"

    for directory in ${directories[@]}; do
        directory_name="$(basename ${directory})"
        versioned_directory_match=$(echo "${directory_name}" | grep ".*${version_expression}.*")

        if [ "${directory_name}" == "${versioned_directory_match}" ]; then
            version=$(echo "${directory_name}" | grep -o "${version_expression}")

            prefix=$(echo "${directory_name}" | grep -o ".*${version_expression}")
            prefix=(${prefix//${version}/})

            suffix=$(echo "${directory_name}" | grep -o "${version_expression}.*")
            suffix=(${suffix//${version}/})

            versions=(${version//./ })

            if [ "${prefix_filter}" != "" ] && [ "${prefix}" != "${prefix_filter}" ]; then
                continue
            fi

            subversion_index=0
            version_comparison_result=0
            for subversion in "${versions[@]}"; do
                if [ ${current_versions[subversion_index]} -gt ${subversion} ]; then
                    version_comparison_result=1
                    break
                elif [ ${current_versions[subversion_index]} -lt ${subversion} ]; then
                    current_prefix="${prefix}"
                    current_suffix="${suffix}"
                    current_versions=("${versions[@]}")
                    versioned_directory="${directory}"

                    version_comparison_result=2
                    break
                fi

                subversion_index=$(expr ${subversion_index} + 1)
            done

            if [ ${version_comparison_result} -eq 0 ] && [ "${current_suffix}" \< "${suffix}" ]; then
                current_prefix="${prefix}"
                current_suffix="${suffix}"
                current_versions=("${versions[@]}")
                versioned_directory="${directory}"
            fi
        fi
    done

    if [ "${versioned_directory}" == "" ]; then
        echo "Error: could not find any properly versioned directory in ${parent_directory}" >&2
        exit 1
    fi

    echo "${versioned_directory}"
}

check_expression "${0}" $((${#} >= 1)) "${#} >= 1" ${exit_invalid_arguments}

parent_directory="${1}"
prefix_filter=""

if [ ${#} > 1 ]; then
    prefix_filter="${2}"
fi

check_input ${parent_directory}

get_versioned_directory ${parent_directory} ${prefix_filter}