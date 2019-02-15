#!/bin/bash
export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR

source ../scripts/GET_ENV.sh web

../scripts/bundle_generic.sh $fds_version $smv_version $linux_mpi_version

