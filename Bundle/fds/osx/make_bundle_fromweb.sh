#!/bin/bash
export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR

source ../scripts/GET_ENV.sh web

../scripts/bundle_generic.sh $fds_version $smv_version $osx_mpi_version

