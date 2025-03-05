#!/bin/bash
source config.sh
if [ "$BUNDLE_BOT_TAG" == "" ]; then
  exit
fi
VERSION=`echo $BUNDLE_BOT_TAG | awk -F'-' '{print $2}'`
git tag -f -a $BUNDLE_BOT_TAG -m "tag bundle version $VERSION"
