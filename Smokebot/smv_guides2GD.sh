#!/bin/bash
FROMDIR=$1
MANDIR=$2

GDRIVE=~/bin/gdrive
CURDIR=`pwd`
# directory containing guides on google drive : FDS-SMV Newest Manuals
MANUAL_PARENT_ID=0B_wB1pJL2bFQUlJwMmNfaHlqME0
FIGURES_PARENT_ID=0B-W-dkXwdHWNOGVsZXNzTjdLek0
MANIDS=$HOME/.smokebot/smv_guides_ids.sh
if [ -e $MANIDS ]; then
  source $MANIDS
fi

UPLOADGUIDE ()
{
  cd $FROMDIR
  FILE=$1
  FILEnew=${FILE}.pdf
  if [ -e $FILEnew ]; then
    $GDRIVE list  | grep $FILEnew | awk '{ system("~/bin/gdrive delete -i " $1)} '
    $GDRIVE upload -p $MANUAL_PARENT_ID -f $FILEnew
    npubs=`$GDRIVE list  | grep $FILEnew | wc -l`
    if [ $npubs -eq 0 ]; then
      echo "*** warning: The guide $FILEnew failed to upload to google drive"
    fi
    if [ $npubs -gt 1 ]; then
      echo "*** warning: More than one copy of $FILEnew exists on google drive"
    fi
    if [ -e $HOME/.smokebot/pubs ]; then
      cp $FILEnew $HOME/.smokebot/pubs/.
    fi
  fi
}
UPLOADFIGURES ()
{
  DIRECTORY=$1
  FILE=$2
  cd $MANDIR/$DIRECTORY/SCRIPT_FIGURES
  tarfile=${FILE}_figures.tar
  rm -f ../$tarfile
  rm -f ../$tarfile.gz
  tar cvf ../$tarfile . &> /dev/null
  cd ..
  gzip $tarfile
  $GDRIVE list  | grep $tarfile.gz | awk '{ system("~/bin/gdrive delete -i " $1)} '
  $GDRIVE upload -p $FIGURES_PARENT_ID -f $tarfile.gz
  if [ -e $HOME/.smokebot/pubs ]; then
    cp $tarfile.gz $HOME/.smokebot/pubs/.
  fi
}

if [ -e $GDRIVE ] ; then
  cd $FROMDIR
  UPLOADGUIDE SMV_User_Guide
  UPLOADGUIDE SMV_Technical_Reference_Guide
  UPLOADGUIDE SMV_Verification_Guide
  UPLOADGUIDE SMV_Summary
  UPLOADFIGURES SMV_User_Guide SMV_UG
  UPLOADFIGURES SMV_Verification_Guide SMV_VG
  cd $CURDIR
fi
