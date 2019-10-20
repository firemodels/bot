#!/bin/bash
app_type=$1
dir_from=$2
bot_host=$3

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
    cp $dir_from/$FROMFILE $dir_to/.
  fi
  if [ -e $dir_to/$FROMFILE ]; then
    echo $FROMFILE copied to $dir_to
  else
    echo ***error: $FROMFILE failed to copy to $dir_to
    return_code=1
  fi
}

return_code=0

dir_to=$HOME/.bundle/$app_type

mkdir -p $dir_to

if [ "$app_type" == "fds" ]; then
  echo
  echo ***copying fds apps
  CP fds
  CP fds2ascii
  CP test_mpi
fi

if [ "$app_type" == "smv" ]; then
  echo
  echo ***copying smokeview apps
  CP background
  CP dem2fds
  CP smokediff
  CP smokeview
  CP smokezip
  CP wind2fds
fi
exit $return_code
