#!/bin/bash

CURDIR=`pwd`

FROMDIR=~smokebot/.smokebot/pubs

cd ../../smv/Manuals
MANDIR=`pwd`
cd $CURDIR

UPLOADSUMMARY ()
{
  DIRECTORY=SMV_Summary
  TARHOME=$HOME/.smokebot/pubs
  if [ ! -e $HOME/.smokebot ]; then
    mkdir $HOME/.smokebot
  fi
  if [ ! -e $HOME/.smokebot/pubs ]; then
    mkdir $HOME/.smokebot/pubs
  fi
  cd $MANDIR
  tarfile=SMV_Summary.tar
  rm -f $TARHOME/$tarfile
  rm -f $TARHOME/$tarfile.gz
  tar cvf $tarfile SMV_Summary  &> /dev/null
  cd $TARHOME
  gzip $tarfile
  cd $TESTBUNDLEDIR
  echo ***Uploading $tarfile.gz
  gh release upload $GH_SMOKEVIEW_TAG $TARHOME/$tarfile.gz -R github.com/$GH_OWNER/$GH_REPO --clobber
}

if [ -e $TESTBUNDLEDIR ] ; then
  UPLOADSUMMARY
  cd $CURDIR
fi
