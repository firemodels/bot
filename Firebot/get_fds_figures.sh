#!/bin/bash

CURDIR=`pwd`
if [ "$GH_FDS_TAG" == "" ]; then
  echo "***error: GH_FDS_TAG variable not defined"
  exit 1
fi

DOWNLOADFIGURES ()
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
