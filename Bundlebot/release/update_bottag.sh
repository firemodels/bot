#!/bin/bash
source config.sh
if [ "$BUNDLE_BOT_TAG" == "" ]; then
  exit
fi
TAGLIST=tags.list
VERSION=`echo $BUNDLE_BOT_TAG | awk -F'-' '{print $2}'`
git tag > $TAGLIST
match=`grep $BUNDLE_BOT_TAG $TAGLIST | wc -l`
if [ $match -eq 1 ]; then
 git tag -d $BUNDLE_BOT_TAG >& /dev/null
fi
git tag -a $BUNDLE_BOT_TAG -m "tag bundle version $VERSION"
rm $TAGLIST
