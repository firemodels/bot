#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "update base images in fig repo"
echo ""
echo "Options:"
echo "-h - display this message"
echo "-r - repository root [default: $FROM_ROOT]"
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
FDS_REVISION=`git describe --dirty --long`

echo getting smv repo revision
cd $FROM_ROOT/smv
SMV_REVISION=`git describe --dirty --long`

FIG_DIR=$TO_ROOT/fig/compare/$BOT_TYPE/images

echo copying $USER_GUIDE figures
cp $FROM_ROOT/$PROG/Manuals/$USER_GUIDE/SCRIPT_FIGURES/*.png $FIG_DIR/user/.
echo $FDS_REVISION > $FIG_DIR/user/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/user/SMV_REVISION

echo copying $VER_GUIDE guide figures
cp $FROM_ROOT/$PROG/Manuals/$VER_GUIDE/SCRIPT_FIGURES/*.png $FIG_DIR/verification/.
echo $FDS_REVISION > $FIG_DIR/verification/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/verification/SMV_REVISION




