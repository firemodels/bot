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

cd ../../test_bundles
TESTBUNDLEDIR=`pwd`
cd $CURDIR
if [ ! -e $TESTBUNDLEDIR ]; then
   echo "***error: $TESTBUNDLEDIR does not exist"
   exit 1
fi

UPLOADHASH ()
{
  DIR=$HOME/.firebot/appslatest
  FILE=$1
  if [ -e $DIR/$FILE ]; then
    cd $TESTBUNDLEDIR
    echo ***Uploading $FILE
    gh release upload $GH_FDS_TAG $DIR/$FILE --clobber
  fi
}

UPLOADGUIDE ()
{
  FILE=$1
  FILEnew=${FILE}.pdf
  if [ -e $FROMDIR/$FILEnew ]; then
    cd $TESTBUNDLEDIR
    echo ***Uploading $FILEnew
    gh release upload $GH_FDS_TAG $FROMDIR/$FILEnew --clobber
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
  cd $TESTBUNDLEDIR
  echo ***Uploading $tarfile.gz
  gh release upload $GH_FDS_TAG $TARHOME/$tarfile.gz --clobber
}

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
