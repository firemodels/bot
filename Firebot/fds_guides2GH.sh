#!/bin/bash
SUFFIX=$1
if [ "$SUFF" != "" ]; then
  SUFFIX=_$SUFFIX
fi

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
  SUFF=$1

  FDSINFO=FDS_INFO${SUFF}.txt
  DIR=$HOME/.firebot/appslatest
  echo ***Uploading $FDSINFO
  F_HASH=`head -1 $DIR/FDS_HASH`
  F_REVISION=`head -1 $DIR/FDS_REVISION`
  S_HASH=`head -1 $DIR/SMV_HASH`
  S_REVISION=`head -1 $DIR/SMV_REVISION`
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
  SUFF=$2
  FILEnew=${FILE}.pdf
  if [ -e $PUBDIR/$FILEnew ]; then
    if [ "$SUFF" != "" ]; then
      FILEnew=${FILE}${SUFF}.pdf
      cp $PUBDIR/${FILE}.pdf $PUBDIR/$FILEnew
    fi
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
  SUFF=$3

  TARHOME=$HOME/.firebot/pubs
  if [ ! -e $HOME/.firebot ]; then
    mkdir $HOME/.firebot
  fi
  if [ ! -e $HOME/.firebot/pubs ]; then
    mkdir $HOME/.firebot/pubs
  fi
  cd $MANDIR/$DIRECTORY/SCRIPT_FIGURES
  tarfile=${FILE}_figures$SUFF.tar
  rm -f $TARHOME/$tarfile
  rm -f $TARHOME/$tarfile.gz
  tar cvf $TARHOME/$tarfile . &> /dev/null
  cd $TARHOME
  gzip $tarfile
  echo ***Uploading $tarfile.gz
  gh release upload $GH_FDS_TAG $TARHOME/$tarfile.gz -R github.com/$GH_OWNER/$GH_REPO --clobber
}
UPLOADGUIDE FDS_Config_Management_Plan    $SUFFIX
UPLOADGUIDE FDS_Technical_Reference_Guide $SUFFIX
UPLOADGUIDE FDS_User_Guide                $SUFFIX
UPLOADGUIDE FDS_Validation_Guide          $SUFFIX
UPLOADGUIDE FDS_Verification_Guide        $SUFFIX
UPLOADFIGURES FDS_Technical_Reference_Guide FDS_TG   $SUFFIX
UPLOADFIGURES FDS_User_Guide                FDS_UG   $SUFFIX
UPLOADFIGURES FDS_Validation_Guide          FDS_VALG $SUFFIX
UPLOADFIGURES FDS_Verification_Guide        FDS_VERG $SUFFIX
UPLOADINFO $SUFFIX
cd $CURDIR
exit 0
