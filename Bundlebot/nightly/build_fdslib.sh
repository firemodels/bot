#!/bin/bash
BUILDLIB=$1
if [ "$BUILDLIB" != "hypre" ]; then
  BUILDLIB="sundials"
fi

cd ../../../fds/Build/Scripts

# Decide compilers
source ../Scripts/set_compilers.sh

# Set FIREMODELS environment variable if it is not already exists.
if [ -z "${FIREMODELS}" ]; then
    export FIREMODELS="$(readlink -f "$(pwd)/../../../")"
fi 

if [ "$BUILDLIB" == "hypre" ]; then
   # build hypre
   source ../Scripts/HYPRE/build_hypre.sh confmake.sh true
else
   # build sundials
   source ../Scripts/SUNDIALS/build_sundials.sh confmake.sh true
fi

