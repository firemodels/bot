#!/bin/bash
INSTALLDIR=$1

CURRENTDATE=`date +"%b %d, %Y"`
FDSDATE=`$INSTALLDIR/fds |& grep Compilation | awk -F':' '{print $2}' | awk '{print $1,$2,$3}'`
if [ "$CURRENTDATE" != "$FDSDATE" ]; then
  if [ "$BUNDLE_EMAIL" != "" ]; then
    echo "FDS compilation date: $FDSDATE, Current date: $CURRENTDATE ." | mail -s "Warning: nightly fds bundle not installed today" $BUNDLE_EMAIL
  else
    echo "***Warning: The environment variable BUNDLE_EMAIL is not defined"
  fi
fi
