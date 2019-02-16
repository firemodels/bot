#!/bin/bash
export NOPAUSE=1
args=$0
DIR=$(dirname "${args}")
cd $DIR

if [ -e $BUNDLE_HOME/FDS_SMV_ENVpc.sh ]; then
  source $BUNDLE_HOME/FDS_SMV_ENVpc.sh
else
  echo "***error: parameter file $BUNDLE_HOME/FDS_SMV_ENVpc.sh"
  echo "          does not exist"
fi

../scripts/bundle_generic.sh $fds_version $smv_version $osx_mpi_version

