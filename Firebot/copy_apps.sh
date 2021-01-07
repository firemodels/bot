#!/bin/bash
type=$1

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

# get repo root name

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
curdir=`pwd`
cd $scriptdir/../..
repo_root=`pwd`
fdsrepo=$repo_root/fds
smvrepo=$repo_root/smv
cd $scriptdir

TODIR=$HOME/.bundle
MKDIR $TODIR
MKDIR $TODIR/apps

# copy smokeview files

if [ "$type" == "smv" ]; then
  echo
  echo ***copying smokeview  apps
  CP $smvrepo/Build/background/intel$OS background$OS $TODIR/apps background
  CP $smvrepo/Build/hashfile/intel$OS   hashfile$OS   $TODIR/apps hashfile
  CP $smvrepo/Build/smokediff/intel$OS  smokediff$OS  $TODIR/apps smokediff
  if [ "$OS" == "osx_64" ]; then
    CP $smvrepo/Build/smokeview/intel_osx_64      smokeview_osx_64   $TODIR/apps smokeview
    CP $smvrepo/Build/smokeview/intel_osx_q_64    smokeview_osx_q_64 $TODIR/apps smokeview_q
  else
    CP $smvrepo/Build/smokeview/intel$OS  smokeview$OS  $TODIR/apps smokeview
  fi
  CP $smvrepo/Build/smokezip/intel$OS   smokezip$OS   $TODIR/apps smokezip
  CP $smvrepo/Build/wind2fds/intel$OS   wind2fds$OS   $TODIR/apps wind2fds
fi

# copy fds files

if [ "$type" == "fds" ]; then
  echo
  echo ***copying fds apps
  CP $fdsrepo/Build/${MPI}_intel$OS               fds_${MPI}_intel$OS $TODIR/apps fds
  CP $fdsrepo/Utilities/fds2ascii/intel$OS        fds2ascii$OS        $TODIR/apps fds2ascii
  CP $fdsrepo/Utilities/test_mpi/${MPI}_intel$OS2 test_mpi            $TODIR/apps test_mpi
fi
