#!/bin/bash

#---------------------------------------------
#                   USAGE
#---------------------------------------------

function USAGE {
  echo "Usage: sshbot.sh "
  echo ""
  echo "clusterbot.sh - perform various checks to verify a Linux cluster is working properly. If the -q option"
  echo "                is specified, run test cases on multiple nodes. The test cases are very simple designed"
  echo "                only to verify that communication works between processes.  To run more realistic test"
  echo "                cases, use firebot or smokebot."
  echo ""
  echo " -f - override lock to force clusterbot run"
  echo " -h - display this message"
  exit
}

#---------------------------------------------
#                   MKDIR
#---------------------------------------------

MKDIR ()
{
 local dir=$1

 if [ ! -d $dir ]; then
   mkdir -p $dir
 fi
 if [ ! -d $dir ]; then
   error "***Error: failed to create the directory $dir"
   return 0
 fi
 return 1
}

#---------------------------------------------
#                   MAKE_DATA_DIRS
#---------------------------------------------

MAKE_DATA_DIRS()
{
  tempfile=$SCRIPTDIR/temp.$$
  touch $tempfile
  ERROR=
  if [ -e $tempfile ]; then
    rm $tempfile
    CB_DATA_DIR=$SCRIPTDIR
  else
    CB_DATA_DIR=$HOME/.clusterbot
    MKDIR $CB_DATA_DIR
  fi
  OUTPUT_DIR=$CB_DATA_DIR/output
  FDSOUTPUT_DIR=$CB_DATA_DIR/fdsoutput
  FILES_DIR=$CB_DATA_DIR/files
  MKDIR $OUTPUT_DIR
  if [ $? -eq 0 ]; then
    ERROR=1
  fi
  MKDIR $FDSOUTPUT_DIR
  if [ $? -eq 0 ]; then
    ERROR=1
  fi
  MKDIR $FILES_DIR
  if [ $? -eq 0 ]; then
    ERROR=1
  fi
  if [ "$ERROR" == "1" ]; then
    return 1
  fi
  rm -f $OUTPUT_DIR/*
  rm -f $FILES_DIR/*
  rm -f $FDSOUTPUT_DIR/*
  return 0
}

#---------------------------------------------
#                   CHECK_SSHD_CONFIG
#---------------------------------------------

CHECK_SSHD_CONFIG ()
{
  local file=sshdT_config
  local filesave=${file}.save
  local fullfile=/tmp/${file}.$$
 
  rm -f /tmp/fullfile.$$ 
  sshd -T >&  /tmp/fullfile.$$
  check=`grep 'Permission denied' /tmp/fullfile.$$ | wc -l`
  rm /tmp/fullfile.$$
  if [ $check -gt 0 ]; then
    echo "***Error: `whoami` does not have permission to run the command sshd -T"
    return 
  fi

 
  sshd -T | sort >&  $fullfile
  if [ ! -e $ARCHIVEDIR/$filesave ]; then
    cp $fullfile $ARCHIVEDIR/$filesave
  fi

  diffs=`diff $ARCHIVEDIR/$filesave $fullfile | wc -l`
  dirdate=`ls -l $ARCHIVEDIR/$filesave | awk '{print $6" "$7" "$8}'`
 
  if [ $diffs -eq 0 ]; then
    echo "   `hostname -s`: sshd configuration parameters, generated by sshd -T, have not changed since they were archived at $ARCHIVEDIR/$filesave on $dirdate"
  else
    echo "   `hostname -s`: ***warning: sshd configuration parameters, generated by sshd -T, have changed since they were archived at $ARCHIVEDIR/$filesave on $dirdate"
  fi
  rm $fullfile
}

#---------------------------------------------
#                   CHECK_FILE_ROOT
#---------------------------------------------

CHECK_FILE_ROOT ()
{
  local fullfile=$1
  local file=`basename $fullfile`
  local filesave=${file}.save
  local fileenc=${file}.enc

  if [ ! -e $fullfile ]; then
    echo "***Error: $fullfile does not exist"
    return
  fi

  rm -f /tmp/filetemp.$$ 
  cat $fullfile >& /tmp/filetemp.$$
  check=`grep 'Permission denied' /tmp/filetemp.$$ | wc -l`
  if [ $check -eq 0 ]; then
    rm -f /tmp/filetemp.$$ 
  else
    echo "***Error: `whoami` does not have permission to examine the file $fullfile"
    return
  fi
  
  if [ ! -e $ARCHIVEDIR/$filesave ]; then
    cp $fullfile $ARCHIVEDIR/$filesave
  fi

  diffs=`diff $ARCHIVEDIR/$filesave $fullfile | wc -l`
 
  dirdate=`ls -l $ARCHIVEDIR/$filesave | awk '{print $6" "$7" "$8}'`
  if [ $diffs -eq 0 ]; then
    echo "   `hostname -s`: $fullfile contents have not changed since a copy was archived at $ARCHIVEDIR/$filesave on $dirdate"
  else
    echo "   `hostname -s`: ***Warning: $fullfile contents have changed since a copy was archived at $ARCHIVEDIR/$filesave on $dirdate"
  fi
}

#************************** beginning of script ******************************************

#*** find platform script is running on

platform="linux"
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
fi

SCRIPTDIR=`pwd`
BIN=`dirname "$0"`
if [ "$BIN" == "." ]; then
  BIN=
fi
SCRIPTDIR=$SCRIPTDIR/$BIN

FORCE_UNLOCK=

while getopts 'fh' OPTION
do
case $OPTION  in
  f)
   FORCE_UNLOCK=1
   ;;
  h)
   USAGE
   exit
   ;;
esac
done
shift $(($OPTIND-1))

# --------------------- make sure output directories exist  --------------------

MAKE_DATA_DIRS ||  exit

# --------------------- define file names --------------------

LOCK_FILE=$HOME/.clusterbot/lockfile

MKDIR $HOME/.clusterbot

ARCHIVEDIR=$HOME/.clusterbot/archive
MKDIR $ARCHIVEDIR


if [[ "$FORCE_UNLOCK" == "" ]] && [[ -e $LOCK_FILE ]]; then
  echo "***Error: another instance of sshbot.sh is running"
  echo "          If this is not the case, rerun using the -f option"
  exit
fi

touch $LOCK_FILE

CHECK_FILE_ROOT /etc/ssh/sshd_config
if [ "$platform" == "linux" ]; then
  CHECK_SSHD_CONFIG
fi

rm $LOCK_FILE
