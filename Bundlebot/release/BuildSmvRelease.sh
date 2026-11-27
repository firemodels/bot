#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../bundle_lock.sh" || exit 1
# build a release bundle using revision and tags defined in config.sh .
if [[ ${1:-} == -h || ${1:-} == -k ]]; then
  exec bash "$(dirname "$0")/../nightly/BuildSmvNightly.sh" "$1"
fi
bundle_lock_acquire || exit 1
source config.sh

cd ../nightly
./BuildSmvNightly.sh -R -U
