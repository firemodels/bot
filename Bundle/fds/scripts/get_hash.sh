#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "This script outputs an fds or smv repo hash"
echo ""
echo "Options:"
echo "-b - host where firebot was run" [default: $bot_host]"
echo "-e - error log [default: $error_log]"
echo "-f - from directory [default: $from_dir]"
echo "-h - display this message"
echo "-r - repo type fds or  smv [default: $repotype]"
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
    scp -q $bot_host:$dir_from/$FROMFILE $TOFILE
    COPY=1
  else
    if [ -e $dir_from/$FROMFILE ]; then
      cp $dir_from/$FROMFILE $TOFILE
      COPY=1
    else
      echo ""
      echo "***error: $dir_from/$FROMFILE does not exist"
      echo ""                                             >> $error_log
      echo "***error: $dir_from/$FROMFILE does not exist" >> $error_log
      return_code=1
    fi
  fi
  if [ "$COPY" == "1" ]; then
    if [ ! -e $TOFILE ]; then
      echo "" 
      echo ***error: $FROMFILE failed to copy to $TOFILE
      echo ""  >> $error_log
      echo ***error: $FROMFILE failed to copy to $TOFILE >> $error_log
      return_code=1
    fi
  fi
}

repotype=fds
from_dir=\~firebot
bot_host=`hostname`
error_log=/tmp/get_hash_error_$USER.log
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
   repotype="$OPTARG"
   if [ "$repotype" != "fds" ]; then
     repotype="smv"
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
  echo error_log="$bot_host"
  echo from_dir="$bot_host"
  echo repo_type="$repo_type"
  exit 0
fi
if [[ "$bot_host" != "" ]] && [[ "$bot_host" != "`hostname`" ]]; then
  dir_from=$2
else
  eval dir_from=$2
fi

return_code=0

dir_to=/tmp

if [ "$repotype" == "fds" ]; then
  CP FDS_HASH $dir_to/FDS_HASH.$$ || exit 1
  cat $dir_to/FDS_HASH.$$
  rm -f $dir_to/FDS_HASH.$$
fi

if [ "$repotype" == "smv" ]; then
  CP SMV_HASH $dir_to/SMV_HASH.$$ || exit 1
  cat $dir_to/SMV_HASH.$$
  rm -f $dir_to/SMV_HASH.$$
fi

exit 0
