#!/bin/bash
# host where firebot was run
FIREBOT_HOST=blaze.el.nist.gov

# dns name where pubs are located
PUB_HOST=blaze.el.nist.gov

# email address where results are sent to
MAILTO=username@xxx.yyy

# base string of intel mpi library
export INTEL_MPI_VERSION=oneapi

# openmpi version (on MAC)
export MPI_VERSION=4.1.0

# directory where openmpi is located (on MAC)
export OPENMPI_DIR=/opt/openmpi410_oneapi_64
