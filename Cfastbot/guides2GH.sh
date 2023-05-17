#!/bin/bash

CURDIR=`pwd`

FROMDIR=~cfast/.cfastbot/Manuals

UPLOADGUIDE ()
{
  FILE=$1
  FILEnew=${FILE}/${FILE}.pdf
  if [ -e $FROMDIR/$FILEnew ]; then
    cd $TESTBUNDLEDIR
    echo ***Uploading $FILEnew
    gh release upload $GH_CFAST_TAG $FROMDIR/$FILEnew -R github.com/$GH_OWNER/$GH_REPO --clobber
  else
    echo $FROMDIR/$FILEnew does not exist
  fi
}
UPLOADINFO ()
{
  C_HASH=`head -1     $FROMDIR/CFAST_HASH`
  S_HASH=`head -1     $FROMDIR/SMV_HASH`
  C_REVISION=`head -1 $FROMDIR/CFAST_REVISION`
  S_REVISION=`head -1 $FROMDIR/SMV_REVISION`
  echo "CFAST_HASH     $C_HASH"      > $FROMDIR/CFAST_INFO.txt
  echo "CFAST_REVISION $C_REVISION" >> $FROMDIR/CFAST_INFO.txt
  echo "SMV_HASH       $S_HASH"     >> $FROMDIR/CFAST_INFO.txt
  echo "SMV_REVISION   $S_REVISION" >> $FROMDIR/CFAST_INFO.txt
  gh release upload $GH_CFAST_TAG $FROMDIR/CFAST_INFO.txt -R github.com/$GH_OWNER/$GH_REPO --clobber
}


UPLOADGUIDE CFAST_Tech_Ref
UPLOADGUIDE CFAST_Users_Guide
UPLOADGUIDE CFAST_Validation_Guide
UPLOADGUIDE CFAST_Configuration_Guide
UPLOADGUIDE CFAST_CData_Guide
UPLOADINFO
