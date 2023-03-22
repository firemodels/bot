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
UPLOADHASH ()
{
  FILE=$1
  if [ -e $FROMDIR/$FILE ]; then
    cd $TESTBUNDLEDIR
    suffix=`head -1 $FROMDIR/$FILE`
    FILE2=$FILE$suffix
    cp $FROMDIR/$FILE $FROMDIR/$FILE2
    echo ***Uploading $FILE
    gh release upload $GH_CFAST_TAG $FROMDIR/$FILE -R github.com/$GH_OWNER/$GH_REPO --clobber
    echo ***Uploading $FILE2
    gh release upload $GH_CFAST_TAG $FROMDIR/$FILE2 -R github.com/$GH_OWNER/$GH_REPO --clobber
    rm -f $FROMDIR/$FILE2
  fi
}


if [ -e $TESTBUNDLEDIR ] ; then
  FILELIST=`gh release view $GH_FDS_TAG  -R github.com/$GH_OWNER/$GH_REPO | grep CFAST_HASH | awk '{print $2}'`
  for file in $FILELIST ; do
    gh release delete-asset $GH_FDS_TAG $file -R github.com/$GH_OWNER/$GH_REPO -y
  done
  FILELIST=`gh release view $GH_FDS_TAG  -R github.com/$GH_OWNER/$GH_REPO | grep CFAST_REVISION | awk '{print $2}'`
  for file in $FILELIST ; do
    gh release delete-asset $GH_FDS_TAG $file -R github.com/$GH_OWNER/$GH_REPO -y
  done
  FILELIST=`gh release view $GH_FDS_TAG  -R github.com/$GH_OWNER/$GH_REPO | grep SMV_HASH | awk '{print $2}'`
  for file in $FILELIST ; do
    gh release delete-asset $GH_FDS_TAG $file -R github.com/$GH_OWNER/$GH_REPO -y
  done
  FILELIST=`gh release view $GH_FDS_TAG  -R github.com/$GH_OWNER/$GH_REPO | grep SMV_REVISION | awk '{print $2}'`
  for file in $FILELIST ; do
    gh release delete-asset $GH_FDS_TAG $file -R github.com/$GH_OWNER/$GH_REPO -y
  done

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
