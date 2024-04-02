#!/bin/bash
# build a release bundle using revision and tags defined in config.sh .
source config.sh
export BUNDLE_SMV_TAG=SMV-6.9.0test
export GH_SMOKEVIEW_TAG=SMOKEVIEW_TEST2

CURDIR=`pwd`
cd ../../../smv
echo ***updating smv repo
git checkout master
git remote update
git merge firemodels/master
git merge origin/master

cd $CURDIR/../smv/scripts
./smvbundle.sh -r -z
