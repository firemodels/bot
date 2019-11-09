#!/bin/bash
# hashtype from_dir bot_host error_log

hashtype=$1
if [ "$hashtype" != "fds" ]; then
  hashtype="smv"
fi
if [[ "$bot_host" != "" ]] && [[ "$bot_host" != "`hostname`" ]]; then
  dir_from=$2
else
  eval dir_from=$2
fi
bot_host=$3
error_log=$4

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

return_code=0

dir_to=/tmp

if [ "$hashtype" == "fds" ]; then
  CP FDS_HASH $dir_to/FDS_HASH.$$ || exit 1
  cat $dir_to/FDS_HASH.$$
  rm -f $dir_to/FDS_HASH.$$
fi

if [ "$hashtype" == "smv" ]; then
  CP SMV_HASH $dir_to/SMV_HASH.$$ || exit 1
  cat $dir_to/SMV_HASH.$$
  rm -f $dir_to/SMV_HASH.$$
fi

exit 0
