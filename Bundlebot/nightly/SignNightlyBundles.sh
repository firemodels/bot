#!/bin/bash

CURDIR=`pwd`
cd bundles

for file in *.sh
do
  echo signing $file
  gpg --output $file.sig --detach-sig $file
done

