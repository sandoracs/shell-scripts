#!/usr/bin/env bash

if [ "${#}" -ne 1 ]; then
    echo "Usage: ${0} <parent_of_versioned_directories>" >&2
    exit 1
fi

parent_directory="${1%/}"

if [ ! -e "${parent_directory}" ]; then
    echo "Error: parent directory <${parent_directory}> could not be found" >&2
    exit 1
fi

if [ ! -d "${parent_directory}" ]; then
    echo "Error: <${parent_directory}> specified for parent directory is not a directory" >&2
    exit 1
fi

current_versions=(0 0 0)
directories=$(find ${parent_directory} -type d -mindepth 1 -maxdepth 1)
versioned_directory=""
version_expression="[0-9]\+\(\.[0-9]\+\)*"

for directory in ${directories[@]}; do
    directory_name="$(basename ${directory})"
    versioned_directory_match=$(echo "${directory_name}" | grep ".*${version_expression}.*")

    if [ "${directory_name}" == "${versioned_directory_match}" ]; then
        version=$(echo "${directory_name}" | grep -o "${version_expression}")
        versions=(${version//./ })

        subversion_index=0
        for subversion in "${versions[@]}"; do
            if [ ${current_versions[subversion_index]} -gt ${subversion} ]; then
                break
            elif [ ${current_versions[subversion_index]} -lt ${subversion} ]; then
                current_versions=("${versions[@]}")
                versioned_directory="${directory}"

                break
            fi

            subversion_index=$(expr ${subversion_index} + 1)
        done
    fi
done

if [ "$versioned_directory" == "" ]; then
    echo "Error: could not find any properly versioned directory in $parent_directory" >&2
    exit 1
fi

echo "$versioned_directory"