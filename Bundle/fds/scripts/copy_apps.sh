#!/bin/bash
app_type=$1
eval dir_from=$2
eval bot_host=$3
error_log=$4

if [ "$app_type" != "fds" ]; then
  app_type="smv"
fi

#---------------------------------------------
#                   CP
#---------------------------------------------

CP ()
{
  local FROMFILE=$1
  rm -f $dir_to/$FROMFILE
  if [[ "$bot_host" != "" ]] && [[ "$bot_host" != "`hostname`" ]]; then
    scp -q $bot_host:$dir_from/$FROMFILE $dir_to/.
  else
    if [ -e $dir_from/$FROMFILE ]; then
      cp $dir_from/$FROMFILE $dir_to/. 
      if [ -e $dir_to/$FROMFILE ]; then
        echo $FROMFILE copied to $dir_to
      else
        echo "" 
        echo ***error: $FROMFILE failed to copy to $dir_to
        echo ""  >> $error_log
        echo ***error: $FROMFILE failed to copy to $dir_to >> $error_log
        return_code=1
      fi
    else
      echo ""
      echo "***error: $dir_from/$FROMFILE does not exist"
      echo "" >> $error_log
      echo "***error: $dir_from/$FROMFILE does not exist" $error_log
      return_code=1
    fi
  fi
}

return_code=0

dir_to=$HOME/.bundle/apps

mkdir -p $dir_to

if [ "$app_type" == "fds" ]; then
  echo
  if [[ "$bot_host" != "" ]] && [[ "$bot_host" != "`hostname`" ]]; then
    echo ***copying fds apps from $dir_from on $bot_host
  else
    echo ***copying fds apps from $dir_from
  fi
  CP fds
  CP fds2ascii
  CP test_mpi
  CP FDS_REVISION
fi

if [ "$app_type" == "smv" ]; then
  echo
  if [[ "$bot_host" != "" ]] && [[ "$bot_host" != "`hostname`" ]]; then
    echo ***copying smokeview apps from $dir_from on $bot_host
  else
    echo ***copying smokeview apps from $dir_from
  fi
  CP background
  CP hashfile
  CP dem2fds
  CP smokediff
  CP smokeview
  CP smokezip
  CP wind2fds
  CP SMV_REVISION
fi
exit $return_code
