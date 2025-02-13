#!/bin/bash
abort=
CURDIR=`pwd`
FROMDIR=$CURDIR/for_bundle
if [ ! -d $FROMDIR ]; then
  echo ***error: $FROMDIR does not exist
  exit
fi
SMVDIR=../../../smv
if [ ! -d $SMVDIR ]; then
  echo ***error: $SMVDIR does not exist
  exit
fi
cd $SMVDIR
SMVDIR=`pwd`
TODIR=$SMVDIR/Build/for_bundle
if [ ! -d $TODIR ]; then
  echo ***error: $TODIR does not exist
  exit
fi
cd $CURDIR
echo rsync -av --delete $FROMDIR/ $TODIR/
rsync -av --delete $FROMDIR/ $TODIR/
