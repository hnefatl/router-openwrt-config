#!/bin/bash

gen_files=(ddns network)

if [[ "$1" != "" && "$1" != "--dry-run" ]] ; then
    echo "Unknown command $1"
    exit 2
fi

source secrets.sh
for source_file in "${gen_files[@]}" ; do
  echo "$source_file"
  output_file="$source_file"
  if [[ "$1" == "--dry-run" ]] ; then
    output_file="$(mktemp)"
  fi

  chmod u+w "$output_file"
  eval "cat <<EOF
$(<$source_file.tmpl)
EOF" > "$output_file"

  if [[ "$1" == "--dry-run" ]] ; then
    diff "$source_file" "$output_file" || exit 1
  else
    chmod u=r,g=r "$output_file"
  fi
done
