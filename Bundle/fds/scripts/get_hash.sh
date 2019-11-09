#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "This script outputs an fds or smv repo hash"
echo ""
echo "Options:"
echo "-b - host where firebot was run [default: $bot_host]"
echo "-e - error log [default: $error_log]"
echo "-f - from directory [default: $from_dir]"
echo "-h - display this message"
echo "-r - repo type fds or  smv [default: $repo_type]"
echo "-v - show parameters used to build bundle (the bundle is not generated)"
exit 0
}

#---------------------------------------------
#                   CP
#---------------------------------------------

CP ()
{
  local FROMFILE=$1
  local TOFILE=$2
  COPY=
  if [[ "$bot_host" != "" ]] && [[ "$bot_host" != "`hostname`" ]]; then
    scp -q $bot_host:$from_dir/$FROMFILE $TOFILE
    COPY=1
  else
    if [ -e $from_dir/$FROMFILE ]; then
      cp $from_dir/$FROMFILE $TOFILE
      COPY=1
    else
      echo ""                                             >> $error_log
      echo "***error: $from_dir/$FROMFILE does not exist" >> $error_log
      return_code=1
    fi
  fi
  if [ "$COPY" == "1" ]; then
    if [ ! -e $TOFILE ]; then
      echo ""  >> $error_log
      echo ***error: $FROMFILE failed to copy to $TOFILE >> $error_log
      return_code=1
    fi
  fi
}

repo_type=fds
from_dir=\~firebot
bot_host=`hostname`
error_log=/tmp/get_hash_error_$USER.log
to_dir=/tmp
SHOWPARMS=

while getopts 'b:e:f:hr:v' OPTION
do
case $OPTION  in
  b)
   bot_host="$OPTARG"
   ;;
  e)
   error_log="$OPTARG"
   ;;
  f)
   from_dir="$OPTARG"
   ;;
  h)
   usage
   ;;
  r)
   repo_type="$OPTARG"
   if [ "$repo_type" != "fds" ]; then
     repo_type="smv"
   fi
   ;;
  v)
   SHOWPARMS=1
   ;;
  \?)
  echo "***error: unknown option entered. aborting script"
  exit 1
esac
done
shift $(($OPTIND-1))

if [ "$SHOWPARMS" == "1" ]; then
  echo bot_host="$bot_host"
  echo error_log="$error_log"
  echo from_dir="$from_dir"
  echo to_dir="$to_dir"
  echo repo_type="$repo_type"
  exit 0
fi
if [[ "$bot_host" != "" ]] && [[ "$bot_host" != "`hostname`" ]]; then
  from_dir=$from_dir
else
  eval from_dir=$from_dir
fi
from_dir=$from_dir/.firebot/apps

return_code=0

if [ "$repo_type" == "fds" ]; then
  CP FDS_HASH $to_dir/FDS_HASH.$$ || exit 1
  cat $to_dir/FDS_HASH.$$
  rm -f $to_dir/FDS_HASH.$$
fi

if [ "$repo_type" == "smv" ]; then
  CP SMV_HASH $to_dir/SMV_HASH.$$ || exit 1
  cat $to_dir/SMV_HASH.$$
  rm -f $to_dir/SMV_HASH.$$
fi

exit 0
