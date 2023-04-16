#!/bin/bash
TO_OWNER=gforney
TO_REPO=test7_bundles
TO_TAG=COPY_TEST
TO_TITLE="FDS/Smokeview release title"

echo upload release
echo OWNER=$TO_OWNER
echo REPO=$TO_REPO
echo TAG=$TO_TAG
echo TITLE=$TO_TITLE
gh release edit $TO_TAG -t "$TO_TITLE" -R github.com/$TO_OWNER/$TO_REPO
gh release upload $TO_TAG FILES/* -R github.com/$TO_OWNER/$TO_REPO --clobber
