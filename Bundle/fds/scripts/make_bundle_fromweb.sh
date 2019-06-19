#!/bin/bash
fds_version=$1
smv_version=$2
mpi_version=$3

export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR
./bundle_generic.sh $fds_version $smv_version $mpi_version
