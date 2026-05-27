#!/bin/bash

CURDIR=`pwd`
cd bundles

#------------------------------
SIGN_FILES()
#------------------------------
{
EXT=$1

echo
echo ---------------------------
echo signing $EXT files
echo ---------------------------

for file in *.$EXT
do
  echo
  echo signing $file
  rm -f $file.sig
  gpg --output $file.sig --armor --detach-sig $file
  echo
  echo verifying $file
  gpg --verify $file.sig $file
done
}

SIGN_FILES sh
SIGN_FILES pdf
SIGN_FILES tar.gz
SIGN_FILES tar

