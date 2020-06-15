#!/bin/bash
FROMDIR=$1
MANDIR=$2

GDRIVE=~/bin/gdrive
CURDIR=`pwd`
# directory containing guides on google drive : FDS-SMV Newest Manuals
MANUAL_PARENT_ID=0B_wB1pJL2bFQUlJwMmNfaHlqME0
FIGURES_PARENT_ID=0B-W-dkXwdHWNOGVsZXNzTjdLek0

UPLOADFILE ()
{
  DIR=$1
  FILE=$2
  cd $DIR
  if [ -e $FILE ]; then
    $GDRIVE list  | grep $FILE | awk '{ system("~/bin/gdrive delete -i " $1)} '
    $GDRIVE upload -p $MANUAL_PARENT_ID -f $FILE
    npubs=`$GDRIVE list  | grep $FILE | wc -l`
    if [ $npubs -eq 0 ]; then
      echo "*** warning: The file $FILE failed to upload to google drive"
    fi
    if [ $npubs -gt 1 ]; then
      echo "*** warning: More than one copy of $FILE exists on google drive"
    fi
  fi
}

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
  if [ -e $HOME/.firebot/pubs ]; then
    cp $tarfile.gz $HOME/.firebot/pubs/.
  fi
  $GDRIVE list  | grep $tarfile.gz | awk '{ system("~/bin/gdrive delete -i " $1)} '
  $GDRIVE upload -p $FIGURES_PARENT_ID -f $tarfile.gz
  npubs=`$GDRIVE list  | grep $tarfile.gz | wc -l`
  if [ $npubs -eq 0 ]; then
    echo "*** warning: The $tarfile.gz failed to upload to google drive"
  fi
  if [ $npubs -gt 1 ]; then
    echo "*** warning: More than one copy of $tarfile.gz exists on google drive"
  fi
}

if [ -e $GDRIVE ] ; then
  UPLOADGUIDE geom_notes
  UPLOADGUIDE FDS_Config_Management_Plan
  UPLOADGUIDE FDS_Technical_Reference_Guide
  UPLOADGUIDE FDS_User_Guide
  UPLOADGUIDE FDS_Validation_Guide
  UPLOADGUIDE FDS_Verification_Guide
  UPLOADFIGURES FDS_Technical_Reference_Guide FDS_TG
  UPLOADFIGURES FDS_User_Guide FDS_UG
  UPLOADFIGURES FDS_Validation_Guide FDS_VALG
  UPLOADFIGURES FDS_Verification_Guide FDS_VERG
  UPLOADFILE $HOME/.firebot/appslatest FDS_HASH
  UPLOADFILE $HOME/.firebot/appslatest FDS_REVISION
  UPLOADFILE $HOME/.firebot/appslatest SMV_HASH
  UPLOADFILE $HOME/.firebot/appslatest SMV_REVISION
  UPLOADFILE SMV_REVISION
  cd $CURDIR
fi
