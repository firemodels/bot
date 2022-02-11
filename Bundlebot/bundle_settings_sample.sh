#!/bin/bash
# host where firebot was run
FIREBOT_HOST=blaze.el.nist.gov

# dns name where pubs are located
PUB_HOST=blaze.el.nist.gov

# email address where results are sent to
MAILTO=username@xxx.yyy

# compiler settings for FDS 6.7.6 and smokeview 6.7.16 release

# base string of intel mpi library
export INTEL_MPI_VERSION=oneapi

# tar file where Intel mpi files are located (for the  LInux systems)
#export INTELMPI_TARFILE=$HOME/.bundle/BUNDLE_MPI/LINUX/INTELoneapilinux_64.tar.gz

# openmpi version (on MAC)
export MPI_VERSION=4.1.0

# directory where openmpi is located (on MAC)
export OPENMPI_DIR=/opt/openmpi410_oneapi_64

# tar file where openmpi ffiles are located (for the  MAC)
#export OPENMPI_TARFILE=$HOME/.bundle/BUNDLE_MPI/OSX/openmpi_4.1.0_osx_64_oneapi_64.tar.gz
