#!/bin/bash

#---------------------------------------------
#                   MKDIR
#---------------------------------------------

MKDIR ()
{
  local DIR=$1

  if [ ! -d $DIR ]
  then
    mkdir -p $DIR
  fi
}

#---------------------------------------------
#                   CP
#---------------------------------------------

CP ()
{
  local FROMDIR=$1
  local FROMFILE=$2
  local TODIR=$3
  local TOFILE=$4
  if [ ! -e $FROMDIR/$FROMFILE ]; then
    echo "***error: $FROMFILE was not found in $FROMDIR"
  else
    cp $FROMDIR/$FROMFILE $TODIR/$TOFILE
    if [ -e $TODIR/$TOFILE ]; then
      echo "$FROMFILE copied to $TODIR/$TOFILE"
    else
      echo "***error: $FROMFILE could not be copied to $TODIR"
    fi
  fi
}

# ----------------- start of script ------------------------------

if [ "`uname`" == "Darwin" ]; then
  OS=_osx_64
else
  OS=_linux_64
fi

# get repo root name

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
curdir=`pwd`
cd $scriptdir/../..
repo_root=`pwd`
smvrepo=$repo_root/smv
cd $scriptdir

TODIR=$HOME/.bundle
MKDIR $TODIR
MKDIR $TODIR/apps

# copy smokeview files

echo
echo ***copying smokeview  apps
CP $smvrepo/Build/background/intel$OS background$OS $TODIR/apps background
CP $smvrepo/Build/hashfile/intel$OS   hashfile$OS   $TODIR/apps hashfile
CP $smvrepo/Build/smokediff/intel$OS  smokediff$OS  $TODIR/apps smokediff
if [ "$OS" == "_osx_64" ]; then
  CP $smvrepo/Build/smokeview/intel_osx_64      smokeview_osx_64   $TODIR/apps smokeview
  CP $smvrepo/Build/smokeview/intel_osx_q_64    smokeview_osx_q_64 $TODIR/apps smokeview_q
else
  CP $smvrepo/Build/smokeview/intel$OS  smokeview$OS  $TODIR/apps smokeview
fi
CP $smvrepo/Build/smokezip/intel$OS   smokezip$OS   $TODIR/apps smokezip
CP $smvrepo/Build/wind2fds/intel$OS   wind2fds$OS   $TODIR/apps wind2fds
