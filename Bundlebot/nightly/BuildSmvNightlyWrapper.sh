#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../bundle_lock.sh" || exit 1
while getopts 'ChknuUR' option; do
  case "$option" in
    h|k) exec ./BuildSmvNightly.sh "$@" ;;
  esac
done
bundle_lock_acquire || exit 1

CURDIR=`pwd`
cd ../../Scripts
./update_repos.sh -m -b
cd $CURDIR

./BuildSmvNightly.sh "$@"
