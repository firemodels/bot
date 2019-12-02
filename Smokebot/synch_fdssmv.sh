#!/bin/bash
acct=$1
branch=$2
host=$3

#---------------------------------------------
#                   CP
#---------------------------------------------

CP ()
{
  local FROMDIR=$1
  local FROMFILE=$2
  local TOFILE=$3

  rm -f $TOFILE
  if [[ "$host" != "" ]] && [[ "$host" != "`hostname`" ]]; then
    scp -q $host:$FROMDIR/$FROMFILE $TOFILE
  else
    eval FROMDIR=$FROMDIR
    if [ -e $FROMDIR/$FROMFILE ]; then
      cp $FROMDIR/$FROMFILE $TOFILE 
    else
      echo "***error: $FROMDIR/$FROMFILE does not exist"
      return 1
    fi
  fi
  if [ ! -e $TOFILE ]; then
    echo ***error: $FROMFILE failed to copy to $TOFILE
    return 1
  fi
  return 0
}

if [ "$branch" == "" ]; then
  echo "***error: branch name not specified"
  return 1
fi

curdir=`pwd`
scriptdir=`dirname "$0"`
cd $scriptdir/../../fds
fdsrepo=`pwd`

cd $curdir
cd $scriptdir/../../smv
smvrepo=`pwd`

FDS_HASH_FILE=/tmp/FDS_HASH.$$
SMV_HASH_FILE=/tmp/SMV_HASH.$$

eval CP \$acct/.firebot/apps FDS_HASH $FDS_HASH_FILE || exit 1
eval CP \$acct/.firebot/apps SMV_HASH $SMV_HASH_FILE || exit 1

FDS_HASH=`cat $FDS_HASH_FILE`
SMV_HASH=`cat $SMV_HASH_FILE`
rm -f $FDS_HASH_FILE
rm -f $SMV_HASH_FILE

if [ "$FDS_HASH" != "" ]; then
  cd $fdsrepo
  git checkout master >& /dev/null
  if [ "$branch" != "master" ]; then
    git branch -d $branch >& /dev/null
  fi
  git checkout $FDS_HASH >& /dev/null
  echo fds repo: checking $FDS_HASH and naming the branch $branch
  git checkout -b $branch >& /dev/null
fi

if [ "$SMV_HASH" != "" ]; then
  cd $smvrepo
  git checkout master >& /dev/null
  if [ "$branch" != "master" ]; then
    git branch -d $branch >& /dev/null
  fi
  git checkout $SMV_HASH >& /dev/null
  echo smv repo: checking $SMV_HASH and naming the branch $branch
  git checkout -b $branch >& /dev/null
fi

cd $curdir
return 0
