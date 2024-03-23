#!/bin/bash
FROM_OWNER=gforney
FROM_REPO=test7_bundles
FROM_TAG=FDS_TEST

rm -f FILES/*
echo downloading release
echo OWNER=$FROM_OWNER
echo REPO=$FROM_REPO
echo TAG=$FROM_TAG
gh release download $FROM_TAG -R github.com/$FROM_OWNER/$FROM_REPO -D FILES --clobber
