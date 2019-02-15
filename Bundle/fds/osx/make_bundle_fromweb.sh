#!/bin/bash
export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR

source ../scripts/GET_ENV.sh web

export REPO_ROOT=$HOME/$linux_svn_root
export fds_smvroot=$linux_svn_root
export bundlebase=${fds_version}-${smv_version}_osx64
export MPI_VERSION=$osx_mpi_version

../scripts/bundle_generic.sh

