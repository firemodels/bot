#!/bin/bash
# build a release bundle using revision and tags defined in config.sh .
source config.sh
export BUILDING_release=1

CURDIR=`pwd`
cd ../../../smv
echo ***updating smv repo
git checkout master
git remote update
git merge firemodels/master
git merge origin/master

cd $CURDIR/../smv/scripts
./make_smvbundle.sh -r -z
