#!/bin/bash
acct=$1
host=$2
branch=$3

#---------------------------------------------
#                   CP
#---------------------------------------------

CP ()
{
  local FROMDIR=$1
  local FROMFILE=$2
  local TODIR=$3
  local TOFILE=$4

  rm -f $TODIR/$TOFILE
  if [[ "$host" != "" ]] && [[ "$host" != "`hostname`" ]]; then
    scp -q $host:$FROMDIR/$FROMFILE $TODIR/$TOFILE
  else
    if [ -e $FROMDIR/$FROMFILE ]; then
      cp $FROMDIR/$FROMFILE $TODIR/TOFILE 
      if [ -e $TODIR/$TOFILE ]; then
        echo $FROMFILE copied to $TODIR
      else
        echo "" 
        echo ***error: $FROMFILE failed to copy to $TODIR
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



eval ls $acct
