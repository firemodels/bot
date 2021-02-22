#!/bin/bash
BASE_DIR=$1
NEW_DIR=$2
DIFF_DIR=$3

METRIC=rmse
HAVE_USER_DIFFS=
HAVE_VER_DIFFS=

TOLERANCE=0.2
HEIGHT=450
WIDTH=450

#*** setup directories

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

HTML_DIFF=$SUMMARY_DIR/diffs/index.html

#*** setup revision strings

cd $CURDIR/../../fds
FDS_REVISION=`git describe --long --dirty`

cd $CURDIR/../../fig
FIGREPO=`pwd`

FIG_USER_FDS_REVISION_FILE=$FIGREPO/compare/firebot/images/user/FDS_REVISION
FIG_VER_FDS_REVISION_FILE=$FIGREPO/compare/firebot/images/verification/FDS_REVISION
FIG_USER_SMV_REVISION_FILE=$FIGREPO/compare/firebot/images/user/SMV_REVISION
FIG_VER_SMV_REVISION_FILE=$FIGREPO/compare/firebot/images/verification/SMV_REVISION

FIG_USER_FDS_REVISION=`git describe --dirty --long`
FIG_USER_SMV_REVISION=
if [[ -e $FIG_USER_FDS_REVISION_FILE ]] && [[ -e $FIG_USER_SMV_REVISION_FILE ]]; then
  FIG_USER_FDS_REVISION=`head -1 $FIG_USER_FDS_REVISION_FILE`
  FIG_USER_SMV_REVISION=`head -1 $FIG_USER_SMV_REVISION_FILE`
fi

FIG_VER_FDS_REVISION=`git describe --dirty --long`
FIG_VER_SMV_REVISION=
if [[ -e $FIG_VER_FDS_REVISION_FILE ]] && [[ -e $FIG_VER_SMV_REVISION_FILE ]]; then
  FIG_VER_FDS_REVISION=`head -1 $FIG_VER_FDS_REVISION_FILE`
  FIG_VER_SMV_REVISION=`head -1 $FIG_VER_SMV_REVISION_FILE`
fi

cd $CURDIR/../../smv
SMV_REVISION=`git describe --long --dirty`

cd $CURDIR

#---------------------------------------------------------
# make sure directory exists
#---------------------------------------------------------

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

#---------------------------------------------------------
# find differnences
#---------------------------------------------------------

FIND_DIFFS ()
{
SUBDIR=$1
echo ""
echo Comparing images in directories:
echo "  $BASE_DIR/$SUBDIR "
echo "  $NEW_DIR/$SUBDIR"
echo ""
DIFFS=0
for f in $BASE_DIR/$SUBDIR/*.png; do
  base=`basename $f`
  from_file=$BASE_DIR/$SUBDIR/$base
  to_file=$NEW_DIR/$SUBDIR/$base
  diff_file=$DIFF_DIR/$SUBDIR/$base
  diff_file_changed=$DIFF_DIR/$SUBDIR/$base.changed
  diff_file_metric=$DIFF_DIR/$SUBDIR/$base.metric
  rm -f $diff_file $diff_file_changed $diff_file_metric
  if [[ -e $from_file ]] && [[ -e $to_file ]]; then
    diff=`compare -metric $METRIC $from_file $to_file $diff_file |& awk -F'('  '{printf $2}' | awk -F')' '{printf $1}i'`
    echo $diff > $diff_file_metric
    if [[ "$diff" != "0" ]] && [[ ! $diff == *"e"* ]]; then
      iftest=`echo "${diff} > ${TOLERANCE}" | bc`
      if [ 1 -eq $iftest ]; then
        echo "***warning: image $base has changedi. error criteria=$diff > $TOLERANCE"
        touch $diff_file_changed
        DIFFS=1
      fi
    fi
  fi
done
if [ "$SUBDIR" == "user" ]; then
  HAVE_USER_DIFFS=$DIFFS
else
  HAVE_VER_DIFFS=$DIFFS
fi
}

#---------------------------------------------------------
#*** output html
#---------------------------------------------------------

OUTPUT_HTML ()
{
SUBDIR=$1
GUIDE=$2
OPTION=$3
REV1=$4
REV2=$5

TITLE="FDS $GUIDE Guide"

  cat << EOF >> $HTML_DIFF
<h3>$TITLE</h3>
EOF

DIFF_TITLE=
if [ "$OPTION" != "all" ]; then
DIFF_TITLE="<th>Difference</th>"
fi
if [ "$REV2" != "" ]; then
  REV1="$REV1<br>$REV2"
fi
  cat << EOF >> $HTML_DIFF
<table border=on>
<tr>
<th>Base<br>$REV1</th>
<th>Current<br>$FDS_REVISION<br>$SMV_REVISION</th>$DIFF_TITLE</tr>
EOF
  for f in `ls $DIFF_DIR/$SUBDIR/*.png`; do
    base=`basename $f .png`
    pngfile=$base.png
    changefile=$base.png.changed
    metricfile=$base.png.metric

    if [[ ! -e $DIFF_DIR/$SUBDIR/$changefile ]] && [[ "$OPTION" != "all" ]]; then
      continue;
    fi
    METRIC=`cat $DIFF_DIR/$SUBDIR/$metricfile`
    cp $BASE_DIR/$SUBDIR/$pngfile $SUMMARY_DIR/diffs/base/$SUBDIR/.
    IMAGE_HEIGHT=`identify -format '%h' $BASE_DIR/$SUBDIR/$pngfile`
    IMAGE_WIDTH=`identify -format '%w' $BASE_DIR/$SUBDIR/$pngfile`
    if [ $IMAGE_HEIGHT -gt $IMAGE_WIDTH ]; then
      SIZE="height=$HEIGHT"
    else
      SIZE="width=$WIDTH"
    fi

cat << EOF >> $HTML_DIFF
<tr>
<td><img $SIZE src=base/$SUBDIR/$pngfile></td>
<td><img $SIZE src=../images/$SUBDIR/$pngfile></td>
EOF
if [[ "$OPTION" != "all" ]] && [[ -e $DIFF_DIR/$SUBDIR/$changefile ]]; then
cat << EOF >> $HTML_DIFF
<td align=center><img $SIZE src=images/$SUBDIR/$pngfile></td>
</tr>
<tr><th colspan=3>$pngfile - $METRIC</th></tr>
EOF
else
cat << EOF >> $HTML_DIFF
<tr><th colspan=2>$pngfile - $METRIC</th></tr>
EOF
fi

  done
cat << EOF >> $HTML_DIFF
</table>
EOF
if [ "$HAVE_USER_DIFFS" == "" ]; then
  cat << EOF >> $HTML_DIFF
<p>No images have changed
EOF
fi
}

# make sure the Imagemagic utility compare is on this system

ABORT=
notfound=`compare --version 2>&1 | tail -1 | grep "not found" | wc -l`
if [ $notfound -ne 0 ]; then
  echo "Image comparison program, compare, not in path"
  ABORT=1
fi

CHECK_DIR $BASE_DIR 1
CHECK_DIR $NEW_DIR 1
if [ "$ABORT" != "" ]; then
  exit
fi

#*** generate user guide differences

FIND_DIFFS user

#*** generate verificaiton guide differences

FIND_DIFFS verification

HAVE_DIFFS=
if [ "$HAVE_USER_DIFFS" != "" ]; then
  HAVE_DIFFS=1
fi
if [ "$HAVE_VER_DIFFS" != "" ]; then
  HAVE_DIFFS=1
fi

#*** output html header

DATE=`date`
cat << EOF  > $HTML_DIFF
<html>
<head>
<TITLE>FDS User/Verificaiton Guide Images</TITLE>
</HEAD>
<BODY BGCOLOR="#FFFFFF" >
<h2>FDS User/Verification Guide Images - $DATE</h2>
<h3>
FDS revision: $FDS_REVISION<br>
SMV revision: $SMV_REVISION<br>
Metric      : $METRIC<br>
Tolerance   : $TOLERANCE
</h3>

<p><hr>
EOF


#*** output differences if any

if [ "$HAVE_DIFFS" == "1" ]; then
cat << EOF  >> $HTML_DIFF
<h2>Differences</h2>
EOF

if [ "$HAVE_USER_DIFFS" == "1" ]; then
  OUTPUT_HTML user         User         diffs $FIG_USER_FDS_REVISION $FIG_USER_SMV_REVISION
fi
if [ "$HAVE_VER_DIFFS" == "1" ]; then
  OUTPUT_HTML verification Verification diffs $FIG_VER_FDS_REVISION  $FIG_VER_SMV_REVISION
fi
fi


#*** output all images

cat << EOF  >> $HTML_DIFF
<h2>Images</h2>
EOF
OUTPUT_HTML user         User         all $FIG_USER_FDS_REVISION $FIG_USER_SMV_REVISION
OUTPUT_HTML verification Verification all $FIG_VER_FDS_REVISION  $FIG_VER_SMV_REVISION

cat $SUMMARY_DIR/diff_trailer.html   >> $HTML_DIFF

if [ "$HAVE_DIFFS" == "" ]; then
  echo no images have changed
else
  echo changed images in $HTML_DIFF
fi

