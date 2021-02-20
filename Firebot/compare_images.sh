#!/bin/bash
BASE_DIR=$1
NEW_DIR=$2
DIFF_DIR=$3

METRIC=rmse
HAVE_USER_DIFFS=
HAVE_VER_DIFFS=

TOLERANCE=0.2
HEIGHT=300

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
SUMMARY_DIR=../../fds/Manuals/FDS_Summary/
cd $SUMMARY_DIR
SUMMARY_DIR=`pwd`
cd $CURDIR

HTML_DIFF=$SUMMARY_DIR/fds_diffs.html

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

#*** generate user guide differences

SUBDIR=user
echo ""
echo Comparing images in directories:
echo "  $BASE_DIR/$SUBDIR "
echo "  $NEW_DIR/$SUBDIR"
echo ""
for f in $BASE_DIR/$SUBDIR/*.png; do
  base=`basename $f`
  from_file=$BASE_DIR/$SUBDIR/$base
  to_file=$NEW_DIR/$SUBDIR/$base
  diff_file=$DIFF_DIR/$SUBDIR/$base
  diff_file_changed=$DIFF_DIR/$SUBDIR/$base.changed
  rm -f $diff_file
  rm -f $diff_file_changed
  if [[ -e $from_file ]] && [[ -e $to_file ]]; then
    diff=`compare -metric $METRIC $from_file $to_file $diff_file |& awk -F'('  '{printf $2}' | awk -F')' '{printf $1}i'`
    if [[ "$diff" != "0" ]] && [[ ! $diff == *"e"* ]]; then
      iftest=`echo "${diff} > ${TOLERANCE}" | bc`
      if [ 1 -eq $iftest ]; then
        echo "***warning: image $base has changedi. error criteria=$diff > $TOLERANCE"
        touch $diff_file_changed
        HAVE_USER_DIFFS=1
      fi
    fi
  fi
done

#*** generate verificaiton guide differences

SUBDIR=verification
echo ""
echo Comparing images in directories:
echo "  $BASE_DIR/$SUBDIR "
echo "  $NEW_DIR/$SUBDIR"
echo ""
for f in $BASE_DIR/$SUBDIR/*.png; do
  base=`basename $f`
  from_file=$BASE_DIR/$SUBDIR/$base
  to_file=$NEW_DIR/$SUBDIR/$base
  diff_file=$DIFF_DIR/$SUBDIR/$base
  diff_file_changed=$DIFF_DIR/$SUBDIR/$base.changed
  rm -f $diff_file
  rm -f $diff_file_changed
  if [[ -e $from_file ]] && [[ -e $to_file ]]; then
    diff=`compare -metric $METRIC $from_file $to_file $diff_file |& awk -F'('  '{printf $2}' | awk -F')' '{printf $1}i'`
    if [[ "$diff" != "0" ]] && [[ ! $diff == *"e"* ]]; then
      iftest=`echo "${diff} > ${TOLERANCE}" | bc`
      if [ 1 -eq $iftest ]; then
        echo "***warning: image $base has changedi. error criteria=$diff > $TOLERANCE"
        touch $diff_file_changed
        HAVE_VER_DIFFS=1
      fi
    fi
  fi
done

HAVE_DIFFS=
if [ "$HAVE_USER_DIFFS" != "" ]; then
  HAVE_DIFFS=1
fi
if [ "$HAVE_VER_DIFFS" != "" ]; then
  HAVE_DIFFS=1
fi

HMTL_DIFF=$SUMMARY_DIR/fds_diffs.html

#*** output html header

if [ "$HAVE_DIFFS" != "" ]; then
  cat $SUMMARY_DIR/diff_header.html   > $HTML_DIFF
fi

#*** output User guide image differences

if [ "$HAVE_USER_DIFFS" ]; then
  SUBDIR=user
  cat << EOF >> $HTML_DIFF
<h2>FDS User Guide Image Differences<h2>
<table border=on>
<tr><th rowspan=2>File Name</th><th colspan=3 align=center>Images</th></tr>
<th>Base</th><th>Current</th><th>Difference</th></tr>
EOF
  for f in `ls $DIFF_DIR/$SUBDIR/*.changed`; do
    pngfile=`basename $f .changed`
    cp $BASE_DIR/$SUBDIR/$pngfile $SUMMARY_DIR/diffs/base/$SUBDIR/.
cat << EOF >> $HTML_DIFF
<tr>
<th>$pngfile:</th>
<td><img height=$HEIGHT src=diffs/base/$SUBDIR/$pngfile></td>
<td><img height=$HEIGHT src=images/$SUBDIR/$pngfile></td>
<td><img height=$HEIGHT src=diffs/images/$SUBDIR/$pngfile></td>
</tr>
EOF
  done
cat << EOF >> $HTML_DIFF
</table>
EOF
fi

#*** output Verification guide image differences

if [ "$HAVE_VER_DIFFS" ]; then
  SUBDIR=verification
  cat << EOF >> $HTML_DIFF
<h2>FDS Verification Guide Image Differences<h2>
<table border=on>
<tr><th rowspan=2>File Name</th><th colspan=3 align=center>Images</th></tr>
<th>Base</th><th>Current</th><th>Difference</th></tr>
EOF
  for f in `ls $DIFF_DIR/$SUBDIR/*.changed`; do
    pngfile=`basename $f .changed`
    cp $BASE_DIR/$SUBDIR/$pngfile $SUMMARY_DIR/diffs/base/$SUBDIR/.
cat << EOF >> $HTML_DIFF
<tr>
<th>$pngfile:</th>
<td><img height=$HEIGHT src=diffs/base/$SUBDIR/$pngfile></td>
<td><img height=$HEIGHT src=images/$SUBDIR/$pngfile></td>
<td><img height=$HEIGHT src=diffs/images/$SUBDIR/$pngfile></td>
</tr>
EOF
  done
cat << EOF >> $HTML_DIFF
</table>
EOF
fi

if [ "$HAVE_DIFFS" != "" ]; then
  cat $SUMMARY_DIR/diff_trailer.html   >> $HTML_DIFF
fi

if [ "$HAVE_DIFFS" == "" ]; then
  echo no images have changed
else
  echo changed images in $HTML_DIFF
fi
