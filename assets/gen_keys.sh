#! /usr/bin/env bash

# Copyright 2018-2020 Artem B. Smirnov
# Licensed under the Apache License, Version 2.0

# Use: gen_keys.sh <FULL_NAME> <EMAIL_ADDRESS> <GPG_PASSPHRASE>

# https://stackoverflow.com/questions/4437573/bash-assign-default-value
: ${FULL_NAME:=${1}}
: ${EMAIL_ADDRESS:=${2}}
: ${GPG_PASSPHRASE:=${3}}

gen_batch() {

  [[ -z $1 ]] && exit 1;
  [[ -z $2 ]] && exit 1;
  [[ -z $3 ]] && exit 1;

  cat << EOF > /opt/gpg_batch
%echo Generating a GPG key, might take a while
Key-Type: RSA
Key-Length: 4096
Subkey-Type: ELG-E
Subkey-Length: 1024
Name-Real: ${1}
Name-Comment: Aptly Repo Signing
Name-Email: ${2}
Expire-Date: 0
Passphrase: ${3}
%pubring /opt/aptly/aptly.pub
%secring /opt/aptly/aptly.sec
%commit
%echo done
EOF
}

# If the repository GPG keypair doesn't exist, create it.
if [[ ! -f /opt/aptly/aptly.sec ]] || [[ ! -f /opt/aptly/aptly.pub ]]; then
  echo "Generating new GPG keys"
  cp -a /dev/urandom /dev/random

  # Generate GPG config for generating new keypair
  gen_batch ${FULL_NAME} ${EMAIL_ADDRESS} ${GPG_PASSPHRASE}

  # If your system doesn't have a lot of entropy this may, take a long time
  # Google how-to create "artificial" entropy if this gets stuck
  gpg --batch --gen-key /opt/gpg_batch

  # Remove batch after generating keypair
  rm /opt/gpg_batch
else
  echo "No need to generate new GPG keys"
fi

# If the repository public key doesn't exist, export it.
if [[ ! -d /opt/aptly/public ]] || [[ ! -f /opt/aptly/public/aptly_repo_signing.key ]]; then
  echo "Export the GPG public key"
  mkdir -p /opt/aptly/public
  gpg --export --armor > /opt/aptly/public/aptly_repo_signing.key
else
  echo "No need to export GPG keys"
fi
