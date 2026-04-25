#!/usr/bin/env bash

set -e

readarray -t gen_files < <(ls *.tmpl | sed 's/\.tmpl$//')

if [[ "$1" != "" && "$1" != "--dry-run" ]] ; then
    echo "Unknown command $1"
    exit 2
fi

source /external_usb/secrets.sh
for output_file in "${gen_files[@]}" ; do
  input_file="${output_file}.tmpl"

  if [[ "$1" == "--dry-run" ]] ; then
    output_file="$(mktemp)"
  fi

  echo "Filling $output_file from $input_file"

  chmod u+w "$output_file"
  # Substitute any variables. Not secure, but easy.
  eval "cat <<EOF
$(<$input_file)
EOF" > "$output_file"

  if [[ "$1" == "--dry-run" ]] ; then
    diff "$input_file" "$output_file"
    rm "$output_file"
  else
    chmod u=r,g=r "$output_file"
  fi
done

# Kind of a hack to do here, but needs to live somewhere.
ln -sf /etc/config/authorized_keys /etc/dropbear/authorized_keys

