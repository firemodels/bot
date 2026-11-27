#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../bundle_lock.sh" || exit 1
force=
while getopts 'BcCfhkIm:no:r:RTuU' option; do
  case "$option" in
    h|k) exec ./BuildNightly.sh "$@" ;;
    f) force=-f ;;
    \?) exit 1 ;;
  esac
done
bundle_lock_acquire "" "$force" || exit 1

CURDIR=`pwd`
cd ../../Scripts
./update_repos.sh -m -b
cd $CURDIR

./BuildNightly.sh "$@"
