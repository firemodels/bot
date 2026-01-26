#!/bin/bash

if [ "`uname`" == "Darwin" ]; then
  SHA256PROG="shasum -a 256"
else
  SHA256PROG=sha256sum
fi

BASE=$HOME/.bundle/bundles

set -euo pipefail

input_file="${1:-/dev/stdin}"

while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Split into filename and text (first whitespace run)
    file_path="${line%%[[:space:]]*}"
    file_path=${file_path%:}
    full_file_path=$BASE/$file_path
    text="${line#"$file_path"}"
    text="${text#"${text%%[![:space:]]*}"}"  # trim leading spaces

    if [[ ! -f "$full_file_path" ]]; then
#        echo "ERROR: file not found: $file_path" >&2
        printf '%s\n' "$line" 
        continue
    fi

    sha256=$($SHA256PROG "$full_file_path" | awk '{print $1}')

    # Output: filename,sha256,text
    printf '%s,%s,%s\n' "$file_path" "$sha256" "$text"
done < "$input_file"
