#!/bin/bash
# build a release bundle using revision and tags defined in config.sh .
source config.sh
export GH_SMOKEVIEW_TAG=SMOKEVIEW_TEST2

# uncomment and edit following lines if building a test bundle.
# otherwise use settings in config.sh
# export BUNDLE_SMV_REVISION=9ce553208
# export BUNDLE_SMV_TAG=SMV-6.9.1test

CURDIR=`pwd`
cd ../../../smv
echo ***updating smv repo
git checkout master
git remote update
git merge firemodels/master
git merge origin/master

cd $CURDIR/../smv/scripts
./smvbundle.sh -r -z
