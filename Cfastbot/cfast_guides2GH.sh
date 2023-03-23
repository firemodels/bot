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
    gh release upload $GH_CFAST_TAG $FROMDIR/$FILEnew -R github.com/$GH_OWNER/$GH_REPO --clobber
  fi
}
UPLOADINFO ()
{
  C_HASH=`head -1     $FROMDIR/CFAST_HASH`
  S_HASH=`head -1     $FROMDIR/SMV_HASH`
  C_REVISION=`head -1 $FROMDIR/CFAST_REVISION`
  S_REVISION=`head -1 $FROMDIR/SMV_REVISION`
  echo "CFAST_HASH $C_HASH"          > $FROMDIR/CFAST_INFO
  echo "CFAST_REVISION $C_REVISION" >> $FROMDIR/CFAST_INFO
  echo "SMV_HASH $S_HASH"           >> $FROMDIR/CFAST_INFO
  echo "SMV_REVISION $C_REVISION"   >> $FROMDIR/CFAST_INFO
  gh release upload $GH_CFAST_TAG $FROMDIR/CFAST_INFO -R github.com/$GH_OWNER/$GH_REPO --clobber
  rm -f $FROMDIR/CFAST_INFO
}


if [ -e $TESTBUNDLEDIR ] ; then
  UPLOADGUIDE CFAST_Tech_Ref
  UPLOADGUIDE CFAST_Users_Guide
  UPLOADGUIDE CFAST_Validation_Guide
  UPLOADGUIDE CFAST_Configuration_Guide
  UPLOADGUIDE CFAST_CData_Guide
  UPLOADINFO
  cd $CURDIR
fi
