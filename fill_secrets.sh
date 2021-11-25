#!/bin/bash

gen_files=(
  wireless
  ddns
)

source secrets.sh
for gen_file in "${gen_files[@]}" ; do
  eval "cat <<EOF
$(<$gen_file.tmpl)
EOF" > "$gen_file"
  chmod u=r,g=r "$gen_file"
done
