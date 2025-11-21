#!/bin/bash
# build a release bundle using revision and tags defined in config.sh .
source config.sh
export BUILDING_release=1

cd ../nightly
./BuildSmvNightly.sh
