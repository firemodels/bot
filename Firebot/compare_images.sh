#!/bin/bash
BASE_DIR=$1
NEW_DIR=$2
DIFF_DIR=$3

TOLERANCE=0.2

CURDIR=`pwd`
if [ "$BASE_DIR" == "" ]; then
  BASE_DIR=../../fig/compare//firebot/images/
  cd $BASE_DIR
  BASE_DIR=`pwd`
  cd $CURDIR
fi
if [ "$NEW_DIR" == "" ]; then
  NEW_DIR=../../fds/Manuals/FDS_Summary/images/
  cd $NEW_DIR
  NEW_DIR=`pwd`
  cd $CURDIR
fi
if [ "$DIFF_DIR" == "" ]; then
  DIFF_DIR=../../fds/Manuals/FDS_Summary/diffs/images/
  cd $DIFF_DIR
  DIFF_DIR=`pwd`
  cd $CURDIR
fi

CHECK_DIR ()
{
 local DIR=$1
 local CHECKSUB=$2

  if [ ! -d $DIR ]; then
    echo "***error: directory $DIR does not exist"
    ABORT=1
  else
    if [ "$CHECKSUB" != "" ]; then
      if [ ! -d $DIR/user ]; then
        echo "***error: directory $DIR/user does not exist"
        ABORT=1
      fi
      if [ ! -d $DIR/verification ]; then
        echo "***error: directory $DIR/verification does not exist"
        ABORT=1
      fi
    fi
  fi
}

ABORT=

notfound=`compare --version 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -ne 0 ]; then
  echo "Image comparison program, compare, not in path"
  ABORT=1
fi
CHECK_DIR $BASE_DIR 1
CHECK_DIR $NEW_DIR 1
CHECK_DIR $DIFF_DIR
if [ "$ABORT" != "" ]; then
  exit
fi

SUBDIR=user
echo ""
echo Comparing images in directories $BASE_DIR/$SUBDIR and $NEW_DIR/$SUBDIR
for f in $BASE_DIR/$SUBDIR/*.png; do
  base=`basename $f`
  from_file=$BASE_DIR/$SUBDIR/$base
  to_file=$NEW_DIR/$SUBDIR/$base
  diff_file=$DIFF_DIR/$SUBDIR/$base
  rm -f $diff_file
  if [ -e $from_file ]; then
    if [ -e $to_file ]; then
      diff=`compare -metric rmse $from_file $to_file $diff_file |& awk -F'('  '{printf $2}' | awk -F')' '{printf $1}i'`
      if [[ "$diff" != "0" ]] && [[ ! $diff == *"e"* ]]; then
        iftest=`echo "${diff} > ${TOLERANCE}" | bc`
        if [ 1 -eq $iftest ]; then
          echo "***warning: image $base has changedi. rmse=$diff > $TOLERANCE"
        fi
      fi
    fi
  fi
done

SUBDIR=verification
echo ""
echo Comparing images in directories $BASE_DIR/$SUBDIR and $NEW_DIR/$SUBDIR
for f in $BASE_DIR/$SUBDIR/*.png; do
  base=`basename $f`
  from_file=$BASE_DIR/$SUBDIR/$base
  to_file=$NEW_DIR/$SUBDIR/$base
  diff_file=$DIFF_DIR/$SUBDIR/$base
  rm -f $diff_file
  if [ -e $from_file ]; then
    if [ -e $to_file ]; then
      diff=`compare -metric rmse $from_file $to_file $diff_file |& awk -F'('  '{printf $2}' | awk -F')' '{printf $1}i'`
      if [[ "$diff" != "0" ]] && [[ ! $diff == *"e"* ]]; then
        iftest=`echo "${diff} > ${TOLERANCE}" | bc`
        if [ 1 -eq $iftest ]; then
          echo "***warning: image $base has changedi. rmse=$diff > $TOLERANCE"
        fi
      fi
    fi
  fi
done
echo complete
