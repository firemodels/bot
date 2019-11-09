#!/bin/bash

bot_host=$2
error_log=$3

if [[ "$bot_host" != "" ]] && [[ "$bot_host" != "`hostname`" ]]; then
  dir_from=$1
else
  eval dir_from=$1
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

echo
if [[ "$bot_host" != "" ]] && [[ "$bot_host" != "`hostname`" ]]; then
  echo ***copying fds repo revision from $dir_from on $bot_host
else
  echo ***copying fds repo revision from $dir_from
fi
CP FDS_REVISION

echo
if [[ "$bot_host" != "" ]] && [[ "$bot_host" != "`hostname`" ]]; then
  echo ***copying smv repo revision from $dir_from on $bot_host
else
  echo ***copying smv repo revision from $dir_from
fi
CP SMV_REVISION
exit $return_code
