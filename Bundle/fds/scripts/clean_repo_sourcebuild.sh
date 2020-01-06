#!/bin/bash

CURDIR=`pwd`
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
GITROOT=$SCRIPTDIR/../../../..
cd $GITROOT
GITROOT=`pwd`

cd $GITROOT/fds/Source
echo cleaning $GITROOT/fds/Source
git clean -dxf

cd $GITROOT/fds/Build
echo cleaning $GITROOT/fds/Build
git clean -dxf

cd $GITROOT/smv/Source
echo cleaning $GITROOT/smv/Source
git clean -dxf

cd $GITROOT/smv/Build
echo cleaning $GITROOT/smv/Build
git clean -dxf

cd $CURDIR
