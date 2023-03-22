#!/bin/bash

CURDIR=`pwd`
if [ "$GH_FDS_TAG" == "" ]; then
  echo "***error: GH_FDS_TAG variable not defined"
  exit 1
fi

cd output/Newest_Guides
FROMDIR=`pwd`
cd $CURDIR

cd ../../fds/Manuals
MANDIR=`pwd`
cd $CURDIR

UPLOADHASH ()
{
  DIR=$HOME/.firebot/appslatest
  FILE=$1
  if [ -e $DIR/$FILE ]; then
    echo ***Uploading $FILE
    gh release upload $GH_FDS_TAG $DIR/$FILE -R github.com/$GH_OWNER/$GH_REPO --clobber
    suffix=`head -1 $DIR/$FILE`
    FILE2=${FILE}_MANUALS_$suffix
    cp $DIR/$FILE $DIR/$FILE2
    gh release upload $GH_FDS_TAG $DIR/$FILE2 -R github.com/$GH_OWNER/$GH_REPO --clobber
    rm -f $DIR/$FILE2
  fi
}

UPLOADGUIDE ()
{
  FILE=$1
  FILEnew=${FILE}.pdf
  if [ -e $FROMDIR/$FILEnew ]; then
    echo ***Uploading $FILEnew
    gh release upload $GH_FDS_TAG $FROMDIR/$FILEnew -R github.com/$GH_OWNER/$GH_REPO --clobber
  fi
}
UPLOADFIGURES ()
{
  DIRECTORY=$1
  FILE=$2
  TARHOME=$HOME/.firebot/pubs
  if [ ! -e $HOME/.firebot ]; then
    mkdir $HOME/.firebot
  fi
  if [ ! -e $HOME/.firebot/pubs ]; then
    mkdir $HOME/.firebot/pubs
  fi
  cd $MANDIR/$DIRECTORY/SCRIPT_FIGURES
  tarfile=${FILE}_figures.tar
  rm -f $TARHOME/$tarfile
  rm -f $TARHOME/$tarfile.gz
  tar cvf $TARHOME/$tarfile . &> /dev/null
  cd $TARHOME
  gzip $tarfile
  echo ***Uploading $tarfile.gz
  gh release upload $GH_FDS_TAG $TARHOME/$tarfile.gz -R github.com/$GH_OWNER/$GH_REPO --clobber
}
  FILELIST=`gh release view $GH_FDS_TAG  -R github.com/$GH_OWNER/$GH_REPO | grep FDS_HASH | awk '{print $2}'`
  for file in $FILELIST ; do
    gh release delete-asset $GH_FDS_TAG $file -R github.com/$GH_OWNER/$GH_REPO -y
  done
  FILELIST=`gh release view $GH_FDS_TAG  -R github.com/$GH_OWNER/$GH_REPO | grep FDS_REVISION | awk '{print $2}'`
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

UPLOADGUIDE FDS_Config_Management_Plan
UPLOADGUIDE FDS_Technical_Reference_Guide
UPLOADGUIDE FDS_User_Guide
UPLOADGUIDE FDS_Validation_Guide
UPLOADGUIDE FDS_Verification_Guide
UPLOADFIGURES FDS_Technical_Reference_Guide FDS_TG
UPLOADFIGURES FDS_User_Guide FDS_UG
UPLOADFIGURES FDS_Validation_Guide FDS_VALG
UPLOADFIGURES FDS_Verification_Guide FDS_VERG
UPLOADHASH FDS_HASH
UPLOADHASH FDS_REVISION
UPLOADHASH SMV_HASH
UPLOADHASH SMV_REVISION
cd $CURDIR
exit 0
