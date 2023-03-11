#!/bin/bash

CURDIR=`pwd`

FROMDIR=~cfast/.cfastbot/pubs

cd ../../$GH_REPO
TESTBUNDLEDIR=`pwd`
gh repo set-default $GH_OWNER/$GH_REPO
cd $CURDIR

UPLOADGUIDE ()
{
  FILE=$1
  FILEnew=${FILE}.pdf
  if [ -e $FROMDIR/$FILEnew ]; then
    cd $TESTBUNDLEDIR
    echo ***Uploading $FILEnew
    gh release upload $GH_CFAST_TAG $FROMDIR/$FILEnew --clobber
  fi
}
UPLOADHASH ()
{
  FILE=$1
  if [ -e $FROMDIR/$FILE ]; then
    cd $TESTBUNDLEDIR
    HASHFILE=${FILE}_CB
    FULLHASHFILE=/tmp/${HASHFILE}
    cp $FROMDIR/$FILE $FULLHASHFILE
    echo ***Uploading $HASHFILE
    gh release upload $GH_CFAST_TAG $FULLHASHFILE --clobber
    rm $FULLHASHFILE
  fi
}


if [ -e $TESTBUNDLEDIR ] ; then
  UPLOADGUIDE CFAST_Tech_Ref
  UPLOADGUIDE CFAST_Users_Guide
  UPLOADGUIDE CFAST_Validation_Guide
  UPLOADGUIDE CFAST_Configuration_Guide
  UPLOADGUIDE CFAST_CData_Guide
  UPLOADHASH SMV_HASH
  UPLOADHASH CFAST_HASH
  UPLOADHASH SMV_REVISION
  UPLOADHASH CFAST_REVISION
  cd $CURDIR
fi
