#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "This script outputs an fds or smv repo hash"
echo ""
echo "Options:"
echo "-e - error log [default: $error_log]"
echo "-g - host where firebot was run [default: $firebot_host]"
echo "-G - home directory where firebot was run [default: $firebot_home]"
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
  if [[ "$firebot_host" != "" ]] && [[ "$firebot_host" != "`hostname`" ]]; then
    scp -q $firebot_host:$firebot_home/$FROMFILE $TOFILE
    COPY=1
  else
    if [ -e $firebot_home/$FROMFILE ]; then
      cp $firebot_home/$FROMFILE $TOFILE
      COPY=1
    else
      echo ""                                             >> $error_log
      echo "***error: $firebot_home/$FROMFILE does not exist" >> $error_log
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
firebot_home=\~firebot
firebot_host=`hostname`
error_log=/tmp/get_hash_error_$USER.log
to_dir=/tmp
SHOWPARMS=

while getopts 'e:g:G:hr:v' OPTION
do
case $OPTION  in
  e)
   error_log="$OPTARG"
   ;;
  g)
   firebot_host="$OPTARG"
   ;;
  G)
   firebot_home="$OPTARG"
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
  echo firebot_host="$firebot_host"
  echo error_log="$error_log"
  echo firebot_home="$firebot_home"
  echo to_dir="$to_dir"
  echo repo_type="$repo_type"
  exit 0
fi
if [[ "$firebot_host" != "" ]] && [[ "$firebot_host" != "`hostname`" ]]; then
  firebot_home=$firebot_home
else
  eval firebot_home=$firebot_home
fi
firebot_home=$firebot_home/.firebot/apps

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
