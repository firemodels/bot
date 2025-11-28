#!/bin/bash
# build a release bundle using revision and tags defined in config.sh .
source config.sh

cd ../nightly
./BuildSmvNightly.sh -R -U
