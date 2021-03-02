#!/bin/bash
FROMDIR=$1

GDRIVE=~/bin/gdrive
CURDIR=`pwd`
# directory id's containing guides, figures and hashes on google drive
MANUAL_PARENT_ID=0B_wB1pJL2bFQUlJwMmNfaHlqME0

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
      echo "*** warning: The summary $FILEnew failed to upload to google drive"
    fi
    if [ $npubs -gt 1 ]; then
      echo "*** warning: More than one copy of $FILEnew exists on google drive"
    fi
  fi
}

if [ -e $GDRIVE ] ; then
  UPLOADSUMMARY FDS_Summary
  cd $CURDIR
fi
