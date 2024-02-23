#!/bin/bash

CURDIR=`pwd`
if [ "$GH_FDS_TAG" == "" ]; then
  echo "***error: GH_FDS_TAG variable not defined"
  exit 1
fi

cd $HOME/.firebot/appslatest
APPSDIR=`pwd`
cd $CURDIR

cd output/Newest_Guides
PUBDIR=`pwd`
cd $CURDIR

cd ../../fds/Manuals
MANDIR=`pwd`
cd $CURDIR

UPLOADINFO ()
{
  DIR=$HOME/.firebot/appslatest
  echo ***Uploading FDS_INFO.txt
  F_HASH=`head -1 $DIR/FDS_HASH`
  F_REVISION=`head -1 $DIR/FDS_REVISION`
  S_HASH=`head -1 $DIR/SMV_HASH`
  S_REVISION=`head -1 $DIR/SMV_REVISION`
  echo "FDS_HASH     $F_HASH"      > $DIR/FDS_INFO.txt
  echo "FDS_REVISION $F_REVISION" >> $DIR/FDS_INFO.txt
  echo "SMV_HASH     $S_HASH"     >> $DIR/FDS_INFO.txt
  echo "SMV_REVISION $S_REVISION" >> $DIR/FDS_INFO.txt
  gh release upload $GH_FDS_TAG $DIR/FDS_INFO.txt -R github.com/$GH_OWNER/$GH_REPO --clobber
  rm -f $DIR/FDS_INFO.txt
}

UPLOADAPP ()
{
  FILE=$1
  if [ -e $APPSDIR/$FILE ]; then
    echo ***Uploading $FILE
    gh release upload $GH_FDS_TAG $APPSDIR/$FILE -R github.com/$GH_OWNER/$GH_REPO --clobber
  else
    echo ***error: $APPSDIR/$FILE not found
  fi
}

UPLOADGUIDE ()
{
  FILE=$1
  FILEnew=${FILE}.pdf
  if [ -e $PUBDIR/$FILEnew ]; then
    echo ***Uploading $FILEnew
    gh release upload $GH_FDS_TAG $PUBDIR/$FILEnew -R github.com/$GH_OWNER/$GH_REPO --clobber
  else
    echo ***error: $PUBDIR/$FILEnew not found
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
UPLOADAPP fds
UPLOADAPP fds_openmp
UPLOADAPP fds2ascii
UPLOADGUIDE FDS_Config_Management_Plan
UPLOADGUIDE FDS_Technical_Reference_Guide
UPLOADGUIDE FDS_User_Guide
UPLOADGUIDE FDS_Validation_Guide
UPLOADGUIDE FDS_Verification_Guide
UPLOADFIGURES FDS_Technical_Reference_Guide FDS_TG
UPLOADFIGURES FDS_User_Guide FDS_UG
UPLOADFIGURES FDS_Validation_Guide FDS_VALG
UPLOADFIGURES FDS_Verification_Guide FDS_VERG
UPLOADINFO
cd $CURDIR
exit 0
