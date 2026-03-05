#!/bin/bash
FROMDIR=$1
TODIR=$2

if [ ! -d $FROMDIR ]; then
  echo ***error: directory $FROMDIR does not exist
  exit
fi
if [ ! -d $TODIR ]; then
  echo ***error: directory $TODIR does not exist
  exit
fi
if [ -d $TODIR/openmpi ]; then
  rm -rf $TODIR/openmpi
fi
mkdir $TODIR/openmpi
cd $FROMDIR
if [ -e $TODIR/openmpi.tar ]; then
  rm -f $TODIR/openmpi.tar
fi
tar cvf $TODIR/openmpi.tar .
cd $TODIR/openmpi
tar xvf $TODIR/openmpi.tar
rm $TODIR/openmpi.tar
