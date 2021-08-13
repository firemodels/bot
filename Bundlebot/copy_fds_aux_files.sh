#!/bin/bash
FROMBASEDIR=$1
TOBASEDIR=$2

#---------------------------------------------
#                   CP
#---------------------------------------------

CP ()
{
  local FROMDIR=$1
  local FROMFILE=$2

  return_code=0
  if [ ! -e $FROMBASEDIR ]; then
    echo ""
    echo "***error: source base directory $FROMBASEDIR does not exist"
    return_code=1
  fi
  if [ ! -e $TOBASEDIR ]; then
    echo ""
    echo "***error: destination base directory $TOBASEDIR does not exist"
    return_code=1
  fi
  if [ ! -e $FROMBASEDIR/$FROMDIR/$FROMFILE ]; then
    echo "***error: $FROMFILE does not exist in $FROMBASEDIR/$FROMDIR"
    return_code=1
  fi
  if [ ! -e $TOBASEDIR/$FROMDIR ]; then
    echo "***error: destination directory $TOBASEDIR/$FROMDIR does not exist"
    return_code=1
  fi
  if ["$return_code" == "1" ]; then
    return 1
  fi
  echo copying $FROMFILE from $FROMBASEDIR/$FROMDIR to $TOBASEDIR/$FROMDIR
  cp $FROMBASEDIR/$FROMDIR/$FROMFILE $TOBASEDIR/$FROMDIR/$FROMFILE
  if [ ! -e $TOBASEDIR/$FROMDIR/$FROMFILE ]; then
    echo ***error: $FROMFILE failed to copy to $TOBASEDIR/$FROMDIR
    return 1
  fi
  return 0
}

CP Fires upholstery_matl.tpl
CP Fires gypsum_walls.tpl
CP Fires couch2_devices.dat
