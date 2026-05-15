#!/bin/bash
CURDIR=`pwd`
if [ "$GH_FDS_TAG" == "" ]; then
  echo "***error: GH_FDS_TAG variable not defined"
  exit 1
fi

cd ../../fds
FDSREPO=`pwd`

MANDIR=$FDSREPO/Manuals
cd $CURDIR

cd $CURDIR/../../smv
SMVREPO=`pwd`

UPLOADINFO ()
{
  FDSINFO=FDS_INFO$.txt
  DIR=$HOME/.firebot
  echo ***Uploading $FDSINFO
  cd $FDSREPO
  F_HASH=`git rev-parse --short HEAD`
  F_REVISION=`git describe --abbrev=7 --long --dirty`
  cd $SMVREPO
  S_HASH=`git rev-parse --short HEAD`
  S_REVISION=`git describe --abbrev=7 --long --dirty`
  echo "FDS_HASH     $F_HASH"      > $DIR/$FDSINFO
  echo "FDS_REVISION $F_REVISION" >> $DIR/$FDSINFO
  echo "SMV_HASH     $S_HASH"     >> $DIR/$FDSINFO
  echo "SMV_REVISION $S_REVISION" >> $DIR/$FDSINFO
  gh release upload $GH_FDS_TAG $DIR/$FDSINFO -R github.com/$GH_OWNER/$GH_REPO --clobber
  rm -f $DIR/$FDSINFO
}

UPLOADGUIDE ()
{
  FILE=$1
  FULLFILE=$MANDIR/$FILE/${FILE}.pdf
  if [ -e $FULLFILE ]; then
    echo ***Uploading $FILE
    gh release upload $GH_FDS_TAG $FULLFILE -R github.com/$GH_OWNER/$GH_REPO --clobber
  else
    echo ***error: $FULLFILE not found
  fi
}

UPLOADFIGURES ()
{
  DIRECTORY=$1
  FILE=$2

  TARHOME=$HOME/.firebot
  mkdir -p $TARHOME
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
UPLOADFIGURES FDS_User_Guide                FDS_UG
UPLOADFIGURES FDS_Validation_Guide          FDS_VALG
UPLOADFIGURES FDS_Verification_Guide        FDS_VERG
UPLOADINFO
cd $CURDIR
exit 0
