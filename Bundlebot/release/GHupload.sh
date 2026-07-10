#!/bin/bash
GHTAG=$1
FROMDIR=$2
for file in $DIR/*; do
  echo uploading $file
  echo gh release upload $GHTAG $file  -R github.com/firemodels/fds --clobber
done
