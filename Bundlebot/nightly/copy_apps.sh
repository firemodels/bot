#!/bin/bash
app_type=$1
eval dir_from=$2
error_log=$3

platform="linux"
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
fi



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
  if [ -e $dir_from/$FROMFILE ]; then
    cp $dir_from/$FROMFILE $dir_to/. 
    if [ -e $dir_to/$FROMFILE ]; then
      echo "   $FROMFILE copied to $dir_to"
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
}

return_code=0

dir_to=$HOME/.bundle/apps

mkdir -p $dir_to

if [ "$app_type" == "fds" ]; then
  echo
  echo ***copying fds apps from $dir_from
  CP fds
  CP fds_openmp
  CP fds2ascii
  CP test_mpi
  CP FDS_REVISION
fi

if [ "$app_type" == "smv" ]; then
  echo
  echo ***copying smokeview apps from $dir_from
  CP background
  CP hashfile
  CP smokediff
  CP pnginfo
  CP fds2fed
  CP smokeview
  CP smokezip
  CP wind2fds
  CP SMV_REVISION
fi
exit $return_code
