#!/bin/bash
fds_version=$1
smv_version=$2
mpi_version=$3
intel_mpi_version=$4
openmpi_dir=$5

export NOPAUSE=1
if [ "$openmpi_dir" != "" ]; then
  export FDS_OPENMPIDIR=$openmpi_dir
fi
args=$0
DIR=$(dirname "${args}")
cd $DIR
./bundle_generic.sh $fds_version $smv_version $mpi_version $intel_mpi_version
