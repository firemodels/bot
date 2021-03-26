#!/bin/bash
BASE_DIR=$1
NEW_DIR=$2
DIFF_DIR=$3

CURDIR=`pwd`

BASEDIR=`basename $CURDIR`
if [ "$BASEDIR" == "Firebot" ]; then
  BOT_SUMMARY=fds/Manuals/FDS_Summary
  BOT_TYPE=firebot
  BOT_TITLE=FDS
  HOME=
fi
if [ "$BASEDIR" == "Smokebot" ]; then
  BOT_SUMMARY=smv/Manuals/SMV_Summary
  BOT_TYPE=smokebot
  BOT_TITLE=Smokeview
  HOME=1
fi
if [ "$BOT_SUMMARY" == "" ]; then
  echo "***error: compare_images.sh must be run in the Firebot or Smokebot directory"
  exit
fi

# to flag image differences as fyi's, use the following line
#FYI=fyi

# to flag image differences as warning's, use the following line
FYI=warning

METRIC=rmse
METRIC_LABEL="Root Mean Square Error (rmse)"
HAVE_USER_DIFFS=0
HAVE_VER_DIFFS=0
HAVE_USER_ERRORS=0
HAVE_VER_ERRORS=0

TOLERANCE=0.2
HEIGHT_UNCHANGED=200
WIDTH_UNCHANGED=200
HEIGHT_CHANGED=250
WIDTH_CHANGED=250

#*** setup directories

CURDIR=`pwd`
if [ "$BASE_DIR" == "" ]; then
  BASE_DIR=../../fig/compare/$BOT_TYPE/images/
  cd $BASE_DIR
  BASE_DIR=`pwd`
fi

cd $CURDIR
REPO=../..
cd $REPO
REPO=`pwd`

cd $CURDIR
FDS_REPO=../../fds
cd $FDS_REPO
FDS_REPO=`pwd`

cd $CURDIR
SMV_REPO=../../smv
cd $SMV_REPO
SMV_REPO=`pwd`

cd $CURDIR
if [ "$NEW_DIR" == "" ]; then
  NEW_DIR=../../$BOT_SUMMARY/images/
  cd $NEW_DIR
  NEW_DIR=`pwd`
  cd $CURDIR
fi

if [ "$DIFF_DIR" == "" ]; then
  DIFF_DIR=../../$BOT_SUMMARY/diffs/images/
  cd $DIFF_DIR
  DIFF_DIR=`pwd`
fi
if [ -d $DIFF_DIR ]; then
  cd $DIFF_DIR
  git clean -dxf >& /dev/null
fi

cd $CURDIR
SUMMARY_DIR=../../$BOT_SUMMARY/
cd $SUMMARY_DIR
SUMMARY_DIR=`pwd`
cd $CURDIR

if [ "$BASEDIR" == "Firebot" ]; then
  HTML_DIFF=$SUMMARY_DIR/index.html
else
  HTML_DIFF=$SUMMARY_DIR/diffs.html
fi

#*** setup revision strings

cd $CURDIR/../../fds
FDS_REVISION=`git describe --long --dirty`

cd $CURDIR/../../fig
FIGREPO=`pwd`

FIG_USER_FDS_REVISION_FILE=$FIGREPO/compare/$BOT_TYPE/images/user/FDS_REVISION
FIG_VER_FDS_REVISION_FILE=$FIGREPO/compare/$BOT_TYPE/images/verification/FDS_REVISION
FIG_USER_SMV_REVISION_FILE=$FIGREPO/compare/$BOT_TYPE/images/user/SMV_REVISION
FIG_VER_SMV_REVISION_FILE=$FIGREPO/compare/$BOT_TYPE/images/verification/SMV_REVISION

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
IMAGE_ERRORS=0
rm -f $NEW_DIR/$SUBDIR/blur*.png
file_list=$DIFF_DIR/$SUBDIR/file_list
rm -f $file_list
for f in $NEW_DIR/$SUBDIR/*.png; do
  base=`basename $f`
  blur_base=blur_$base
  from_file=$BASE_DIR/$SUBDIR/$base
  blur_from_file=$BASE_DIR/$SUBDIR/$blur_base
  to_file=$NEW_DIR/$SUBDIR/$base
  blur_to_file=$NEW_DIR/$SUBDIR/$blur_base
  diff_file=$DIFF_DIR/$SUBDIR/$base
  diff_file_changed=$DIFF_DIR/$SUBDIR/$base.changed
  diff_file_metric=$DIFF_DIR/$SUBDIR/$base.metric
  rm -f $diff_file $diff_file_changed $diff_file_metric
  if [[ -e $from_file ]] && [[ -e $to_file ]]; then
    convert $from_file -blur 0x2 $blur_from_file
    convert $to_file   -blur 0x2 $blur_to_file
    diff=`compare -metric $METRIC $blur_from_file $blur_to_file $diff_file |& awk -F'('  '{printf $2}' | awk -F')' '{printf $1}i'`
    rm -f $blur_from_file $blur_to_file
    if [ "$diff" == "" ]; then
      diff=0
    fi
    echo $diff > $diff_file_metric
    echo $base $diff >> $file_list
    if [[ "$diff" != "0" ]] && [[ ! $diff == *"e"* ]]; then
      iftest=`echo "${diff} > ${TOLERANCE}" | bc`
      if [ 1 -eq $iftest ]; then
        echo "***$FYI: The image $base has changed. $METRIC error=$diff > $TOLERANCE"
        touch $diff_file_changed
        IMAGE_ERRORS=$((IMAGE_ERRORS + 1))
      fi
    fi
    if [[ "$diff" != "0" ]]; then
      DIFFS=$((DIFFS + 1))
    fi
  fi
  if [[ ! -e $from_file ]]; then
    echo "***$FYI: The base image $from_file does not exist."
    echo "            Copy $to_file to the fig repo"
  fi
done
if [ "$SUBDIR" == "user" ]; then
  HAVE_USER_DIFFS=$DIFFS
  HAVE_USER_ERRORS=$IMAGE_ERRORS
else
  HAVE_VER_DIFFS=$DIFFS
  HAVE_VER_ERRORS=$IMAGE_ERRORS
fi
}

#---------------------------------------------------------
#*** OUTPUT_LINKS
#---------------------------------------------------------

OUTPUT_LINKS ()
{
local SUBDIR=$1
local OPTION=$2
LINK1="<a href="#userdiffs">[Changed User Guide Images]</a>"
LINK2="<a href="#verificationdiffs">[Changed Verification Guide Images]</a>"
LINK3="<a href="#userall">[Unchanged User Guide Images]</a>"
LINK4="<a href="#verificationall">[Unchanged Verification Guide Images]</a>"
if [[ "$SUBDIR" == "user" ]] && [[ "$OPTION" == "all" ]]; then
  LINK3="[Unchanged User Guide Images]"
fi
if [[ "$SUBDIR" == "user" ]] && [[ "$OPTION" != "all" ]]; then
  LINK1="[Changed User Guide Images]"
fi
if [[ "$SUBDIR" == "verification" ]] && [[ "$OPTION" == "all" ]]; then
  LINK4="[Unchanged Verification Guide Images]"
fi
if [[ "$SUBDIR" == "verification" ]] && [[ "$OPTION" != "all" ]]; then
  LINK2="[Changed Verification Guide Images]"
fi
if [ "$HAVE_USER_DIFFS" == "0" ]; then
  LINK1=
fi
if [ "$HAVE_VER_DIFFS" == "0" ]; then
  LINK2=
fi
if [ "$HOME" != "" ]; then
cat << EOF >> $HTML_DIFF
<a href="index.html">[Home]</a>
EOF
fi
cat << EOF >> $HTML_DIFF
$LINK1$LINK3$LINK2$LINK4
EOF
}

#---------------------------------------------------------
#*** output html
#---------------------------------------------------------

OUTPUT_HTML ()
{
SUBDIR=$1
GUIDE=$2
REV1=$3
REV2=$4

SUFFIX=Images

DIFF_TITLE=
if [ "$REV2" != "" ]; then
  REV1="$REV1<br>$REV2"
fi
file_list=$DIFF_DIR/$SUBDIR/file_list
FILELIST=`sort -k2,2nr  -k1,1 $file_list | awk '{print $1}'`
  START_DIFF=0
  START_REST=0
  let counter=0
  table_size=4
  for f in $FILELIST; do
    base=`basename $f .png`
    pngfile=$base.png
    changefile=$base.png.changed
    metricfile=$base.png.metric

    ERROR=`cat $DIFF_DIR/$SUBDIR/$metricfile`
    if [ "$ERROR" == "0" ]; then
      if [ "$START_REST" == "0" ]; then
        START_REST=1
      fi
    else
      if [ "$START_DIFF" == "0" ]; then
        START_DIFF=1
      fi
    fi

    if [ "$START_DIFF" == "1" ]; then
  cat << EOF >> $HTML_DIFF
<a name="${SUBDIR}diffs">
<h2>Changed $GUIDE Guide Images</h2>
EOF
OUTPUT_LINKS $SUBDIR diffs
  cat << EOF >> $HTML_DIFF
<p><table border=on>
<tr>
<th align=center>Base</th>
<th align=center>Current</th>
</tr>
EOF
      START_DIFF=2
    fi
    
    if [ "$START_REST" == "1" ]; then
      if [ "$START_DIFF" == "2" ]; then
        cat << EOF >> $HTML_DIFF
</table>
EOF
      fi
  cat << EOF >> $HTML_DIFF
<a name="${SUBDIR}all">
<h2>Unchanged $GUIDE Guide Images</h2>
EOF
OUTPUT_LINKS $SUBDIR all
  cat << EOF >> $HTML_DIFF
<p><table border=on>
EOF
      START_REST=2
    fi
    if [ "$START_REST" == "2" ]; then
      HEIGHT=$HEIGHT_UNCHANGED
      WIDTH=$WIDTH_UNCHANGED
    else
      HEIGHT=$HEIGHT_CHANGED
      WIDTH=$WIDTH_CHANGED
    fi
    COMPARE=`echo $ERROR'>'$TOLERANCE | bc -l`
    STYLE=
    if [ "$COMPARE" == "1" ]; then
      STYLE="style=\"color:red\""
    fi
    cp $BASE_DIR/$SUBDIR/$pngfile $SUMMARY_DIR/diffs/base/$SUBDIR/.
    IMAGE_HEIGHT=`identify -format '%h' $BASE_DIR/$SUBDIR/$pngfile`
    IMAGE_WIDTH=`identify -format '%w' $BASE_DIR/$SUBDIR/$pngfile`
    if [ $IMAGE_HEIGHT -gt $IMAGE_WIDTH ]; then
      SIZE="height=$HEIGHT"
    else
      SIZE="width=$WIDTH"
    fi

if [ "$START_REST" == "2" ]; then
  let counter=counter+1
  counter=$(($counter%$table_size))
  if [ $counter -eq 1 ]; then
    cat << EOF >> $HTML_DIFF
<tr>
EOF
  fi
  cat << EOF >> $HTML_DIFF
<td align=center><a href="diffs/base/$SUBDIR/$pngfile"><img $SIZE src=diffs/base/$SUBDIR/$pngfile></a>
<br>$pngfile</td>
EOF
else
cat << EOF >> $HTML_DIFF
<tr>
<td><a href="diffs/base/$SUBDIR/$pngfile"><img $SIZE src=diffs/base/$SUBDIR/$pngfile></a></td>
EOF
fi

COLSPAN=
if [ "$START_REST" != "2" ]; then
  COLSPAN="colspan=2"
  cat << EOF >> $HTML_DIFF
<td><a href="images/$SUBDIR/$pngfile"><img $SIZE src=images/$SUBDIR/$pngfile></a></td>
EOF
fi

ENDROW=
if [ "$START_REST" != "2" ]; then
  ENDROW=1
fi
if [[ "$START_REST" == "2" ]] && [[ $counter -eq 0 ]]; then
  ENDROW=1
fi
if [ "$ENDROW" == "1" ]; then
  cat << EOF >> $HTML_DIFF
</tr>
EOF
fi

if [ "$START_REST" != "2" ]; then
  cat << EOF >> $HTML_DIFF
<tr>
<th $COLSPAN>^ $pngfile, $METRIC=<span $STYLE>$ERROR</span> ^</th>
</tr>
EOF
fi
  done
cat << EOF >> $HTML_DIFF
</table>
EOF
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

HAVE_DIFFS=$((HAVE_USER_DIFFS+HAVE_VER_DIFFS))
HAVE_ERRORS=$((HAVE_USER_ERRORS+HAVE_VER_ERRORS))

#*** output html header

DATE=`date`
cat << EOF  > $HTML_DIFF
<html>
<head>
<TITLE>$BOT_TITLE User, Verification Guide Images</TITLE>
</HEAD>
<BODY BGCOLOR="#FFFFFF" >
<h2>$BOT_TITLE User, Verification Guide Images - $DATE</h2>

<table>
<tr><th align=left>Current:</th>   <td> $FDS_REVISION         </td><td>$SMV_REVISION</td></tr>
<tr><th align=left>Base:</th>     <td> $FIG_USER_FDS_REVISION</td><td>$FIG_USER_SMV_REVISION</td></tr>
<tr><th align=left>Root:</th>     <td> $REPO                 </td></tr>
<tr><th align=left>Metric:</th>   <td> ${METRIC_LABEL}       </td></tr>
<tr><th align=left>Tolerance:</th><td> $TOLERANCE            </td></tr>
</table>
EOF

#*** output all images

OUTPUT_HTML user         User         $FIG_USER_FDS_REVISION $FIG_USER_SMV_REVISION
OUTPUT_HTML verification Verification $FIG_VER_FDS_REVISION  $FIG_VER_SMV_REVISION

cat << EOF  >> $HTML_DIFF
<p><hr>
</BODY>
</HTML>
EOF



if [ "$HAVE_DIFFS" == "0" ]; then
  echo no images have changed
else
  echo $HAVE_DIFFS images have changed
  if [ "$HAVE_ERRORS" == "0" ]; then
    echo "no images exceed the error tolerance of $TOLERANCE"
  else
    echo "***warning: $HAVE_ERRORS images exceed the error tolerance of $TOLERANCE"
  fi
  echo image differences summarized in $HTML_DIFF
fi
echo $HAVE_DIFFS $HAVE_ERRORS > image_differences

