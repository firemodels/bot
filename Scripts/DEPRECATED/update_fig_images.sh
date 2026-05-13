#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "update base images in fig repo"
echo ""
echo "Options:"
echo "-h - display this message"
echo "-r repo_root - repository root [default: $FROM_ROOT]"
exit 0
}

CURDIR=`pwd`
cd ../..
TO_ROOT=`pwd`
cd $CURDIR
FROM_ROOT=$TO_ROOT

#*** parse options

while getopts 'hr:' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
  r)
   FROM_ROOT="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

BASEDIR=`basename $CURDIR`
if [ "$BASEDIR" == "Firebot" ]; then
  BOT_TYPE=firebot
  VER_GUIDE=FDS_Verification_Guide
  USER_GUIDE=FDS_User_Guide
  PROG=fds
fi
if [ "$BASEDIR" == "Smokebot" ]; then
  BOT_TYPE=smokebot
  VER_GUIDE=SMV_Verification_Guide
  USER_GUIDE=SMV_User_Guide
  PROG=smv
fi

ERROR=

if [ ! -d  $FROM_ROOT/fds ]; then
  echo "***error: $FROM_ROOT/fds does not exist"
  ERROR=1
fi

if [ ! -d  $FROM_ROOT/smv ]; then
  echo "***error: $FROM_ROOT/smv does not exist"
  ERROR=1
fi

if [ ! -d  $TO_ROOT/fig ]; then
  echo "***error: $TO_ROOT/fig does not exist"
  ERROR=1
fi

if [ "$ERROR" == "1" ]; then
  exit
fi

echo getting fds repo revision
cd $FROM_ROOT/fds
FDS_REVISION=`git describe --abbrev=7 --dirty --long`
FROM_USER=$FROM_ROOT/$PROG/Manuals/$USER_GUIDE
FROM_VER=$FROM_ROOT/$PROG/Manuals/$VER_GUIDE

echo getting smv repo revision
cd $FROM_ROOT/smv
SMV_REVISION=`git describe --abbrev=7 --dirty --long`

if [ "$PROG" == "fds" ]; then
  FIG_DIR=$TO_ROOT/fig/fds/Reference_Figures
fi
if [ "$PROG" == "smv" ]; then
  if [ "$HOST_DEFAULT" != "" ]; then
    FIG_DIR=$TO_ROOT/fig/smv/Reference_Figures/Default
  else
    FIG_DIR=$TO_ROOT/fig/smv/Reference_Figures/Other
  fi
fi

FROM_USER_DIR=$FROM_USER/SCRIPT_FIGURES
FROM_VER_DIR=$FROM_VER/SCRIPT_FIGURES

#*** copying user user gide images
if [ -d $FROM_USER_DIR ]; then
  nfiles=`ls -Al $FROM_USER_DIR/*.png | wc -l`
  if [ $nfiles -gt 0 ]; then
    cp $FROM_USER_DIR/*.png $FIG_DIR/.
  fi
  echo $FDS_REVISION > $FIG_DIR/FDS_REVISION
  echo $SMV_REVISION > $FIG_DIR/SMV_REVISION
  echo $nfiles user images copied to $FIG_DIR
else
  echo ***error: directory $FROM_USER_DIR does not exist
fi

# copying verification guide images

if [ -d $FROM_VER_DIR ]; then
  nfiles=`ls -Al $FROM_VER_DIR/*.png | wc -l`
  if [ $nfiles -gt 0 ]; then
    cp $FROM_VER_DIR/*.png $FIG_DIR/.
  fi
  echo $FDS_REVISION > $FIG_DIR/FDS_REVISION
  echo $SMV_REVISION > $FIG_DIR/SMV_REVISION
  echo $nfiles user images copied to $FIG_DIR
else
  echo ***error: directory $FROM_VER_DIR does not exist
fi
