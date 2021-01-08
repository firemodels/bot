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
  OS2=_osx
  MPI=mpi
else
  OS=_linux_64
  OS2=_linux
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

# copy fds files

echo
echo ***copying fds apps
CP $fdsrepo/Build/${MPI}_intel$OS               fds_${MPI}_intel$OS $TODIR/apps fds
CP $fdsrepo/Utilities/fds2ascii/intel$OS        fds2ascii$OS        $TODIR/apps fds2ascii
CP $fdsrepo/Utilities/test_mpi/${MPI}_intel$OS2 test_mpi            $TODIR/apps test_mpi
