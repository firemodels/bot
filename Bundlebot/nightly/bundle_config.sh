#!/bin/bash
if [ "`uname`" == "Darwin" ] ; then

#*** OSX parameters

  export FDS_OPENMPIDIR=/opt/openmpi415_oneapi22u3
  intel_mpi_version=oneapi22u3
  mpi_version=4.1.5
  openmpi_dir=/opt/openmpi415_oneapi22u3
else
  intel_mpi_version=oneapi1p6
  mpi_version_linux=INTEL
fi

export INTEL_MPI_VERSION=oneapi1p6
export MPI_VERSION=INTEL

export bundle_hostname=blaze.el.nist.gov
export bundle_firebot_home=/home2/smokevis2/firebot
export bundle_firebot_repohome=/home2/smokevis2/firebot/FireModels_clone
export bundle_smokebot_home=/home2/smokevis2/smokebot
