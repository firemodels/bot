#!/bin/bash
bundle=$1
upload_dir=$HOME/.bundle/uploads
SMVBINDIR=smvbin

bundledir=$upload_dir/$upload_dir
todir=$upload_dir/google_test

if [ ! -d $upload_dir ]; then
  echo "***error: The directory $upload_dir does not exist"
  exit
fi
if [ ! -d $upload_dir/$bundle/smvbin ]; then
  echo ***error: The directory $upload_dir/$bundle/smvbin does not exist
  exit
fi
if [ ! -d $upload_dir/google_test ]; then
  mkdir $upload_dir/google_test
fi

if [ -d $upload_dir/google_test/$SMVBINDIR ]; then
  rm -rf $upload_dir/google_test/$SMVBINDIR
fi
cp -r $upload_dir/$bundle/smvbin $upload_dir/google_test/$SMVBINDIR
if [ -d $upload_dir/google_test/$SMVBINDIR ]; then
  echo The directory $upload_dir/google_test/$SMVBINDIR was creaetd
else
  echo "***error: $upload_dir/google_test/$SMVBINDIR was not copied"
fi
