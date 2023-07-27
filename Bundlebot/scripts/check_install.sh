#!/bin/bash
INSTALLDIR=$1

CURRENTDATE=`date +"%b %d, %Y"`
FDSDATE=`$INSTALLDIR/fds |& grep Compilation | awk -F':' '{print $2}' | awk '{print $1,$2,$3}'`
if [ "$CURRENTDATE" != "$FDSDATE" ]; then
  echo "FDS compilation date: $FDSDATE, Current date: $CURRENTDATE ." | mail -s "Warning: nightly fds bundle not installed today" $BUNDLE_EMAIL
fi
