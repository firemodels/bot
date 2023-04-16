#!/bin/bash
TO_OWNER=gforney
TO_REPO=test7_bundles
TO_TAG=COPY_TEST

echo upload release
echo OWNER=$TO_OWNER
echo REPO=$TO_REPO
echo TAG=$TO_TAG
gh release upload $TO_TAG FILES/* -R github.com/$TO_OWNER/$TO_REPO --clobber
