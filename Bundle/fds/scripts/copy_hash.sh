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

CP FDS_HASH $dir_to/FDS_HASH.$$
CP SMV_HASH $dir_to/SMV_HASH.$$

if [ "$return_code" != "0" ]; then
  exit $return_code
fi

FDS_HASH=`cat $dir_to/FDS_HASH.$$`
SMV_HASH=`cat $dir_to/SMV_HASH.$$`
rm -f $dir_to/FDS_HASH.$$ $dir_to/SMV_HASH.$$

echo FDS_HASH=$FDS_HASH
echo SMV_HASH=$SMV_HASH

exit $return_code
