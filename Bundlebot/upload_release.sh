#!/bin/bash
#TO_OWNER=firemodels
#TO_REPO=fds
#TO_TAG=FDS-6.8.0
TO_OWNER=gforney
TO_REPO=test7_bundles
TO_TAG=COPY_TEST

echo uploading release
echo OWNER=$TO_OWNER
echo REPO=$TO_REPO
echo TAG=$TO_TAG
echo "------------------"
for file in FILES/*; do
  echo uploading $file
  gh release upload $TO_TAG -R github.com/$TO_OWNER/$TO_REPO $file --clobber
done
