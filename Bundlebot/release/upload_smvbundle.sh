#!/bin/bash
export BUILD_release=1
cd ../nightly
./update_smvbundle.sh $*
