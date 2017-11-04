#!/usr/bin/env sh

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <parent_of_versioned_directories>" >&2
  exit 1
fi

parent_directory="$1"

if [ ! -e "$parent_directory" ]; then
  echo "Error: parent directory <$parent_directory> could not be found" >&2
  exit 1
fi

if [ ! -d "$parent_directory" ]; then
  echo "Error: <$parent_directory> specified for parent directory is not a directory" >&2
  exit 1
fi

versioned_directory="0.0.0"
for directory in $(find $parent_directory -type d -mindepth 1 -maxdepth 1); do
    if [[ "$(basename ${directory})" =~ ([0-9]\.[0-9]\.[0-9][a-zA-Z]*) ]] &&
            [ $versioned_directory < "${directory}" ]; then
        versioned_directory="${directory}"
    fi
done

if [ "$versioned_directory" == "0.0.0" ]; then
    echo "Error: could not find any properly versioned directory in $parent_directory" >&2
    exit 1
fi

echo "$versioned_directory"