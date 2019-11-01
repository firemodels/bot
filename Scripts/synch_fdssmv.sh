#!/bin/bash
acct=$1
host=$2
branch=$3

eval acct=$acct

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
    if [ -e $FROMDIR/$FROMFILE ]; then
      cp $FROMDIR/$FROMFILE $TOFILE 
      if [ -e $TOFILE ]; then
        echo $FROMFILE copied to $TOFILE
      else
        echo "" 
        echo ***error: $FROMFILE failed to copy to $TOFILE
        return_code=1
      fi
    else
      echo ""
      echo "***error: $FROMDIR/$FROMFILE does not exist"
      return_code=1
    fi
  fi
}

return_code=0

curdir=`pwd`
scriptdir=`dirname "$0"`
cd $scriptdir/../../fds
fdsrepo=`pwd`

cd $curdir
cd $scriptdir/../../smv
smvrepo=`pwd`

FDS_HASH_FILE=/tmp/FDS_HASH.$$
SMV_HASH_FILE=/tmp/SMV_HASH.$$

eval CP \$acct/.firebot/apps FDS_HASH $FDS_HASH_FILE
eval CP \$acct/.firebot/apps SMV_HASH $SMV_HASH_FILE

FDS_HASH=`cat $FDS_HASH_FILE`
SMV_HASH=`cat $SMV_HASH_FILE`

echo FDS_HASH=$FDS_HASH
echo SMV_HASH=$SMV_HASH

rm -f $FDS_HASH_FILE
rm -f $SMV_HASH_FILE
