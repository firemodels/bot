#!/usr/bin/env bash

# Usage: ./script.sh input.txt
# Each line of input:
# /full/path/to/file<spaces>some text string

set -euo pipefail

input_file="${1:-/dev/stdin}"

while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Split into filename and text (first whitespace run)
    file_path="${line%%[[:space:]]*}"
    text="${line#"$file_path"}"
    text="${text#"${text%%[![:space:]]*}"}"  # trim leading spaces

    if [[ ! -f "$file_path" ]]; then
        echo "ERROR: file not found: $file_path" >&2
        continue
    fi

    sha256=$(sha256sum "$file_path" | awk '{print $1}')

    # Output: filename,sha256,text
    printf '%s,%s,%s\n' "$file_path" "$sha256" "$text"
done < "$input_file"
