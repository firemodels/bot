#!/bin/bash
bot_type=$1

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
  OS2=_osx
  PLATFORM=OSX64
  MPI=mpi
else
  OS=_linux_64
  OS2=_linux
  PLATFORM=LINUX64
  MPI=impi
fi

copyfds=1
copysmv=1

if [ "$bot_type" == "smokebot" ]; then
  copyfds=
fi
if [ "$bot_type" == "firebot" ]; then
  copysmv=
fi

# get repo root name

scriptdir=`dirname "$(readlink "$0")"`
curdir=`pwd`
cd $scriptdir/../../../..
repo_root=`pwd`
fdsrepo=$repo_root/fds
smvrepo=$repo_root/smv
cd $scriptdir

TODIR=$HOME/.bundle/BUNDLE

# copy smokeview files

if [ "$copysmv" == "1" ]; then
  MKDIR $TODIR/smv
  rm -f $TODIR/smv/*
  echo
  echo ***copying smokeview  apps
  CP $smvrepo/Build/background/intel$OS background   $TODIR/smv background
  CP $smvrepo/Build/dem2fds/intel$OS    dem2fds$OS   $TODIR/smv dem2fds
  CP $smvrepo/Build/hashfile/intel$OS   hashfile$OS  $TODIR/smv hashfile
  CP $smvrepo/Build/smokediff/intel$OS  smokediff$OS $TODIR/smv smokediff
  CP $smvrepo/Build/smokeview/intel$OS  smokeview$OS $TODIR/smv smokeview
  CP $smvrepo/Build/smokezip/intel$OS   smokezip$OS  $TODIR/smv smokezip
  CP $smvrepo/Build/wind2fds/intel$OS   wind2fds$OS  $TODIR/smv wind2fds
fi

# copy fds files

if [ "$copyfds" == "1" ]; then
  echo
  echo ***copying fds apps
  MKDIR $TODIR/fds
  rm -f $TODIR/fds/*
  CP $fdsrepo/Build/${MPI}_intel$OS               fds_${MPI}_intel$OS $TODIR/fds fds
  CP $fdsrepo/Utilities/fds2ascii/intel$OS        fds2ascii$OS        $TODIR/fds fds2ascii
  CP $fdsrepo/Utilities/test_mpi/${MPI}_intel$OS2 test_mpi            $TODIR/fds test_mpi
fi
  
