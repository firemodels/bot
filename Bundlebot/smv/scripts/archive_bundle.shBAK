#!/bin/bash
bundle=$1

platform="Linux"
if [ "`uname`" == "Darwin" ]; then
  platform="OSX"
fi

upload_dir=$HOME/.bundle/uploads
fromdir=$upload_dir/$bundle/smvbin
todir=$HOME/.bundle/google_test

if [ ! -d $fromdir ]; then
  echo ***error: The directory $fromdir does not exist
  exit
fi
if [ ! -d $todir ]; then
  mkdir $todir
fi

if [ -d $todir/smvbin ]; then
  rm -rf $todir/smvbin
fi
cp -r $fromdir $todir/smvbin
if [ -d $todir/smvbin ]; then
  echo "  $platform Smokeview copied to $todir/smvbin"
else
  echo "***error: smokeview copy to $todir/smvbin failed"
fi
