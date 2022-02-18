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
echo "-R acct - saved manuals are in acct home directory "
exit 0
}

CURDIR=`pwd`
cd ../..
TO_ROOT=`pwd`
cd $CURDIR
FROM_ROOT=$TO_ROOT
FROM_MANUALS=

#*** parse options

while getopts 'hr:R:' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
  r)
   FROM_ROOT="$OPTARG"
   ;;
  R)
   FROM_MANUALS="$OPTARG"
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
if [ "$FROM_MANUALS" != "" ]; then
  if [ "$BOT_TYPE" == "firebot" ]; then
    FROM_MANUALS=$FROM_MANUALS/.firebot/Manuals
  fi
  if [ "$BOT_TYPE" == "smokebot" ]; then
    FROM_MANUALS=$FROM_MANUALS/.smokebot/Manuals
  fi
  if [ ! -d $FROM_MANUALS ]; then
    echo "***error: directory $FROM_MANUALS does not exist"
    ERROR=1
  fi
fi

if  [ "$FROM_MANUALS" == "" ]; then
  if [ ! -d  $FROM_ROOT/fds ]; then
    echo "***error: $FROM_ROOT/fds does not exist"
    ERROR=1
  fi

  if [ ! -d  $FROM_ROOT/smv ]; then
    echo "***error: $FROM_ROOT/smv does not exist"
    ERROR=1
  fi
fi

if [ ! -d  $TO_ROOT/fig ]; then
  echo "***error: $TO_ROOT/fig does not exist"
  ERROR=1
fi

if [ "$ERROR" == "1" ]; then
  exit
fi

echo getting fds repo revision
if [ "$FROM_MANUALS" == "" ]; then
  cd $FROM_ROOT/fds
  FDS_REVISION=`git describe --dirty --long`
  FROM_USER=$FROM_ROOT/$PROG/Manuals/$USER_GUIDE
  FROM_VER=$FROM_ROOT/$PROG/Manuals/$VER_GUIDE
else
  FDS_REVISION=`cat $FROM_MANUALS/FDS_REVISION`
  FROM_USER=$MANUALS_DIR/$USER_GUIDE
  FROM_VER=$MANUALS_DIR/$VER_GUIDE
fi

echo getting smv repo revision
if [ "$FROM_MANUALS" == "" ]; then
  cd $FROM_ROOT/smv
  SMV_REVISION=`git describe --dirty --long`
else
  SMV_REVISION=`cat $FROM_MANUALS/SMV_REVISION`
fi

FIG_DIR=$TO_ROOT/fig/compare/$BOT_TYPE/images

echo copying $USER_GUIDE figures
cp $FROM_USER/SCRIPT_FIGURES/*.png $FIG_DIR/user/.
echo $FDS_REVISION > $FIG_DIR/user/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/user/SMV_REVISION

echo copying $VER_GUIDE guide figures
cp $FROM_VER/SCRIPT_FIGURES/*.png $FIG_DIR/verification/.
echo $FDS_REVISION > $FIG_DIR/verification/FDS_REVISION
echo $SMV_REVISION > $FIG_DIR/verification/SMV_REVISION




