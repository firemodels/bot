#!/bin/bash
BASE_DIR=$1
NEW_DIR=$2
DIFF_DIR=$3

FYI=fyi
# to flag image differences as warning's, uncomment the following line
#FYI=warning
METRIC=rmse
METRIC_LABEL="Root Mean Square Error (rmse)"
HAVE_USER_DIFFS=
HAVE_VER_DIFFS=

TOLERANCE=0.2
HEIGHT=200
WIDTH=200

#*** setup directories

CURDIR=`pwd`
if [ "$BASE_DIR" == "" ]; then
  BASE_DIR=../../fig/compare/smokebot/images/
  cd $BASE_DIR
  BASE_DIR=`pwd`
  cd $CURDIR
fi

FDS_REPO=../../fds
cd $FDS_REPO
FDS_REPO=`pwd`

cd $CURDIR
SMV_REPO=../../smv
cd $SMV_REPO
SMV_REPO=`pwd`

cd $CURDIR
if [ "$NEW_DIR" == "" ]; then
  NEW_DIR=$SMV_REPO/Manuals/SMV_Summary/images/
  cd $NEW_DIR
  NEW_DIR=`pwd`
  cd $CURDIR
fi

if [ "$DIFF_DIR" == "" ]; then
  DIFF_DIR=$SMV_REPO/Manuals/SMV_Summary/diffs/images/
  cd $DIFF_DIR
  DIFF_DIR=`pwd`
  cd $CURDIR
fi

SUMMARY_DIR=$SMV_REPO/Manuals/SMV_Summary/
cd $SUMMARY_DIR
SUMMARY_DIR=`pwd`
cd $CURDIR

HTML_DIFF=$SUMMARY_DIR/index.html

#*** setup revision strings

cd $FDS_REPO
FDS_REVISION=`git describe --long --dirty`

cd $CURDIR/../../fig
FIG_REPO=`pwd`

FIG_USER_FDS_REVISION_FILE=$FIGREPO/compare/smokebot/images/user/FDS_REVISION
FIG_VER_FDS_REVISION_FILE=$FIGREPO/compare/smokebot/images/verification/FDS_REVISION
FIG_USER_SMV_REVISION_FILE=$FIGREPO/compare/smokebot/images/user/SMV_REVISION
FIG_VER_SMV_REVISION_FILE=$FIGREPO/compare/smokebot/images/verification/SMV_REVISION

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

cd SMV_REPO
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
DIFFS=
for f in $NEW_DIR/$SUBDIR/*.png; do
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
        echo "***$FYI: The image $base has changed. $METRIC error=$diff > $TOLERANCE"
        touch $diff_file_changed
        DIFFS=1
      fi
    fi
  fi
  if [[ ! -e $from_file ]]; then
    echo "***$FYI: The base image $from_file does not exist."
    echo "            Copy $to_file to the fig repo"
  fi
done
if [ "$SUBDIR" == "user" ]; then
  HAVE_USER_DIFFS=$DIFFS
else
  HAVE_VER_DIFFS=$DIFFS
fi
}

#---------------------------------------------------------
#*** OUTPUT_LINKS
#---------------------------------------------------------

OUTPUT_LINKS ()
{
local SUBDIR=$1
local OPTION=$2
LINK1="[<a href="#userdiffs">User Guide Image Differences</a>]"
LINK2="[<a href="#verificationdiffs">Verification Guide Image Differences</a>]"
LINK3="[<a href="#userall">User Guide Images</a>]"
LINK4="[<a href="#verificationall">Verification Guides Images</a>]"
if [[ "$SUBDIR" == "user" ]] && [[ "$OPTION" == "all" ]]; then
  LINK3=
fi
if [[ "$SUBDIR" == "user" ]] && [[ "$OPTION" != "all" ]]; then
  LINK1=
fi
if [[ "$SUBDIR" == "verification" ]] && [[ "$OPTION" == "all" ]]; then
  LINK4=
fi
if [[ "$SUBDIR" == "verification" ]] && [[ "$OPTION" != "all" ]]; then
  LINK2=
fi
if [ "$HAVE_USER_DIFFS" == "" ]; then
  LINK1=
fi
if [ "$HAVE_VER_DIFFS" == "" ]; then
  LINK2=
fi
cat << EOF >> $HTML_DIFF
<p>$LINK1$LINK2$LINK3$LINK4
EOF
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

if [ "$OPTION" == "all" ]; then
  SUFFIX=Images
else
  SUFFIX="Image Differences"
fi

TITLE="$GUIDE Guide $SUFFIX"

  cat << EOF >> $HTML_DIFF
<a name="$SUBDIR$OPTION">
<h2>$TITLE</h2>
EOF

OUTPUT_LINKS $SUBDIR $OPTION

DIFF_TITLE=
if [ "$OPTION" != "all" ]; then
DIFF_TITLE="<th align=left>Difference<br>white: where two images are the same<br>red: where two images are different</th>"
fi
if [ "$REV2" != "" ]; then
  REV1="$REV1<br>$REV2"
fi
  cat << EOF >> $HTML_DIFF
<p><table border=on>
<tr>
<th align=left>Base<br>$REV1</th>
<th align=left>Current<br>$FDS_REVISION<br>$SMV_REVISION</th>$DIFF_TITLE</tr>
EOF
  for f in `ls $DIFF_DIR/$SUBDIR/*.png`; do
    base=`basename $f .png`
    pngfile=$base.png
    changefile=$base.png.changed
    metricfile=$base.png.metric

    if [[ ! -e $DIFF_DIR/$SUBDIR/$changefile ]] && [[ "$OPTION" != "all" ]]; then
      continue;
    fi
    ERROR=`cat $DIFF_DIR/$SUBDIR/$metricfile`
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
<td><a href="diffs/base/$SUBDIR/$pngfile"><img $SIZE src=diffs/base/$SUBDIR/$pngfile></a></td>
<td><a href="images/$SUBDIR/$pngfile"><img $SIZE src=images/$SUBDIR/$pngfile></a></td>
EOF
if [[ "$OPTION" != "all" ]] && [[ -e $DIFF_DIR/$SUBDIR/$changefile ]]; then
cat << EOF >> $HTML_DIFF
<td align=center><a href="diffs/images/$SUBDIR/$pngfile"><img $SIZE src=diffs/images/$SUBDIR/$pngfile></a></td>
</tr>
<tr><th colspan=3>^ $pngfile - $METRIC=$ERROR ^</th></tr>
EOF
else
cat << EOF >> $HTML_DIFF
<tr>
EOF
cat << EOF >> $HTML_DIFF
<th colspan=2>^ $pngfile - $METRIC=$ERROR ^</th>
EOF
cat << EOF >> $HTML_DIFF
</tr>
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
if [ "$HAVE_USER_DIFFS" == "1" ]; then
  HAVE_DIFFS=1
fi
if [ "$HAVE_VER_DIFFS" == "1" ]; then
  HAVE_DIFFS=1
fi

#*** output html header

DATE=`date`
cat << EOF  > $HTML_DIFF
<html>
<head>
<TITLE>Smokebot Images</TITLE>
</HEAD>
<BODY BGCOLOR="#FFFFFF" >
<h2>Smokebot Images - $DATE</h2>

<table>
<tr><th align=left>FDS revision:</th><td> $FDS_REVISION</td></tr>
<tr><th align=left>FDS repo:</th><td>$FDS_REPO</td></tr>
<tr><th align=left>SMV revision:</th><td> $SMV_REVISION</td></tr>
<tr><th align=left>SMV repo:</th><td>$SMV_REPO</td></tr>
<tr><th align=left>SMV revision:</th><td> $SMV_REVISION</td></tr>
<tr><th align=left>Metric:</th><td> ${METRIC_LABEL}</td></tr>
<tr><th align=left>Tolerance:</th><td> $TOLERANCE</td></tr>
</table>
EOF

OUTPUT_LINKS 

cat << EOF  >> $HTML_DIFF
<p><hr>
EOF


#*** output differences if any

if [ "$HAVE_DIFFS" == "1" ]; then

if [ "$HAVE_USER_DIFFS" == "1" ]; then
  OUTPUT_HTML user         User         diffs $FIG_USER_FDS_REVISION $FIG_USER_SMV_REVISION
fi
if [ "$HAVE_VER_DIFFS" == "1" ]; then
  OUTPUT_HTML verification Verification diffs $FIG_VER_FDS_REVISION  $FIG_VER_SMV_REVISION
fi
else
cat << EOF  >> $HTML_DIFF
<p>None
EOF
fi


#*** output all images

OUTPUT_HTML user         User         all $FIG_USER_FDS_REVISION $FIG_USER_SMV_REVISION
OUTPUT_HTML verification Verification all $FIG_VER_FDS_REVISION  $FIG_VER_SMV_REVISION

LINK1="[<a href="#userdiffs">User Image Guide Differences</a>]"
LINK2="[<a href="#verificationdiffs">Verification Guide Image Differences</a>]"
LINK3="[<a href="#userall">User Guide Images</a>]"
LINK4="[<a href="#verificationall">Verification Guides Images</a>]"
if [[ "$HAVE_USER_DIFFS" == "" ]]; then
  LINK1=
fi
if [[ "$HAVE_VER_DIFFS" == "" ]]; then
  LINK2=
fi
cat << EOF  >> $HTML_DIFF
<p><hr>
</BODY>
</HTML>
EOF



if [ "$HAVE_DIFFS" == "" ]; then
  echo no images have changed
else
  echo image differences summarized in $HTML_DIFF
fi

