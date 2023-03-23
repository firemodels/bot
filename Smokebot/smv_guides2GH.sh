#!/bin/bash

CURDIR=`pwd`

FROMDIR=~smokebot/.smokebot/pubs

cd ../../smv/Manuals
MANDIR=`pwd`
cd $CURDIR

UPLOADINFO ()
{
  DIR=$HOME/.smokebot/apps
  S_HASH=`head -1     $DIR/SMV_HASH`
  S_REVISION=`head -1 $DIR/SMV_REVISION`
  echo "SMV_HASH          $S_HASH" > $DIR/SMV_INFO
  echo "SMV_REVISION $S_REVISION" >> $DIR/SMV_INFO
  echo ***Uploading SMV_INFO
  gh release upload $GH_SMOKEVIEW_TAG $DIR/SMV_INFO -R github.com/$GH_OWNER/$GH_REPO --clobber
  rm -f $DIR/SMV_INFO
}

UPLOADGUIDE ()
{
  FILE=$1
  FILEnew=${FILE}.pdf
  if [ -e $FROMDIR/$FILEnew ]; then
    cd $TESTBUNDLEDIR
    echo ***Uploading $FILEnew
    gh release upload $GH_SMOKEVIEW_TAG $FROMDIR/$FILEnew -R github.com/$GH_OWNER/$GH_REPO --clobber
  fi
}

UPLOADFIGURES ()
{
  DIRECTORY=$1
  FILE=$2
  TARHOME=$HOME/.smokebot/pubs
  if [ ! -e $HOME/.smokebot ]; then
    mkdir $HOME/.smokebot
  fi
  if [ ! -e $HOME/.smokebot/pubs ]; then
    mkdir $HOME/.smokebot/pubs
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
  gh release upload $GH_SMOKEVIEW_TAG $TARHOME/$tarfile.gz -R github.com/$GH_OWNER/$GH_REPO --clobber
}

if [ -e $TESTBUNDLEDIR ] ; then
  UPLOADGUIDE SMV_Technical_Reference_Guide
  UPLOADGUIDE SMV_User_Guide
  UPLOADGUIDE SMV_Verification_Guide
  UPLOADFIGURES SMV_User_Guide SMV_UG
  UPLOADFIGURES SMV_Verification_Guide SMV_VG
  UPLOADINFO
  cd $CURDIR
fi
