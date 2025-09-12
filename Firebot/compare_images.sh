#!/bin/bash
NEW_DIR=$1
DIFF_DIR=$2
ERROR_DIR=$3
TOLERANCE=$4

CURDIR=`pwd`

if [ ! -e $ERROR_DIR ]; then
  mkdir $ERROR_DIR
fi

BASEDIR=`basename $CURDIR`
if [ "$BASEDIR" == "Firebot" ]; then
  BOT_SUMMARY=fds/Manuals/FDS_Summary
  BOT_TYPE=firebot
  BOT_TITLE=Firebot
  PROG=fds
fi
if [ "$BASEDIR" == "Smokebot" ]; then
  BOT_SUMMARY=smv/Manuals/SMV_Summary
  BOT_TYPE=smokebot
  BOT_TITLE=Smokebot
  PROG=smv
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
METRIC_LABEL="Root Mean Square Error"
HAVE_USER_DIFFS=0
HAVE_VER_DIFFS=0
HAVE_USER_ERRORS=0
HAVE_VER_ERRORS=0

if [ "$TOLERANCE" == "" ]; then
  TOLERANCE=0.1
fi
HEIGHT_UNCHANGED=200
WIDTH_UNCHANGED=200
HEIGHT_CHANGED=250
WIDTH_CHANGED=250
HOSTNAME=`hostname -s`

# add manuals

ADD_FDS_MANUALS=
if [[ "$BASEDIR" == "Firebot" ]] && [[ "$GH_FDS_TAG" != "" ]] && [[ "$GH_OWNER" != "" ]] && [[ "$GH_REPO" != "" ]]; then
  ADD_FDS_MANUALS=1
fi
ADD_SMOKEVIEW_MANUALS=
if [[ "$BASEDIR" == "Smokebot" ]] && [[ "$GH_SMOKEVIEW_TAG" != "" ]] && [[ "$GH_OWNER" != "" ]] && [[ "$GH_REPO" != "" ]]; then
  ADD_SMOKEVIEW_MANUALS=1
fi

#*** setup directories

CURDIR=`pwd`
if [ "$BOT_TYPE" == "firebot" ]; then
  REFERENCE_DIR=../../fig/fds/Reference_Figures
else
  if [ "$SMOKEBOT_COMPARE" == "other" ]; then
    REFERENCE_DIR=../../fig/smv/Reference_Figures/Other
  else
    REFERENCE_DIR=../../fig/smv/Reference_Figures/Default
  fi
fi
cd $REFERENCE_DIR
REFERENCE_DIR=`pwd`

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
PNGINFO=$SMV_REPO/Build/pnginfo/intel_linux_64/pnginfo_linux_64

cd $CURDIR
if [ "$NEW_DIR" == "" ]; then
  NEW_DIR=../../$BOT_SUMMARY/images/
  cd $NEW_DIR
  NEW_DIR=`pwd`
  cd $CURDIR
fi

if [ "$ERROR_DIR" == "" ]; then
  ERROR_DIR=../../$BOT_SUMMARY/diffs/errors/
  if [ ! -d $ERROR_DIR ]; then
    mkdir $ERROR_DIR
  fi
  cd $ERROR_DIR
  ERROR_DIR=`pwd`
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
IMAGE_DIFFS=$SUMMARY_DIR/image_differences

cd $CURDIR

HTML_DIFF=$SUMMARY_DIR/index.html

#*** setup revision strings

cd $CURDIR/../../fds
FDS_REVISION=`git describe --abbrev=7 --long --dirty`
FDS_BRANCH=`git branch --show-current`

cd $CURDIR/../../fig
FIGREPO=`pwd`
FIG_REVISION=`git describe --abbrev=7 --long --dirty`
FIG_BRANCH=`git branch --show-current`

FIG_USER_FDS_REVISION_FILE=$FIGREPO/$PROG/FDS_REVISION
FIG_VER_FDS_REVISION_FILE=$FIGREPO/$PROG/FDS_REVISION
FIG_USER_SMV_REVISION_FILE=$FIGREPO/$PROG/SMV_REVISION
FIG_VER_SMV_REVISION_FILE=$FIGREPO/$PROG/SMV_REVISION

FIG_USER_FDS_REVISION=`git describe --abbrev=7 --dirty --long`
FIG_USER_SMV_REVISION=
if [[ -e $FIG_USER_FDS_REVISION_FILE ]] && [[ -e $FIG_USER_SMV_REVISION_FILE ]]; then
  FIG_USER_FDS_REVISION=`head -1 $FIG_USER_FDS_REVISION_FILE`
  FIG_USER_SMV_REVISION=`head -1 $FIG_USER_SMV_REVISION_FILE`
fi

FIG_VER_FDS_REVISION=`git describe --abbrev=7 --dirty --long`
FIG_VER_SMV_REVISION=
if [[ -e $FIG_VER_FDS_REVISION_FILE ]] && [[ -e $FIG_VER_SMV_REVISION_FILE ]]; then
  FIG_VER_FDS_REVISION=`head -1 $FIG_VER_FDS_REVISION_FILE`
  FIG_VER_SMV_REVISION=`head -1 $FIG_VER_SMV_REVISION_FILE`
fi

cd $CURDIR/../../smv
SMV_REVISION=`git describe --abbrev=7 --long --dirty`
SMV_BRANCH=`git branch --show-current`

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
      if [ ! -d $DIR ]; then
        echo "***error: directory $DIR does not exist"
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
echo "  $REFERENCE_DIR "
echo "  $NEW_DIR/$SUBDIR"
echo ""

ERROR_SUBDIR=$ERROR_DIR/$SUBDIR
rm -r -f $ERROR_SUBDIR
mkdir $ERROR_SUBDIR
DIFFS=0
IMAGE_ERRORS=0
rm -f $NEW_DIR/$SUBDIR/blur*.png
file_list=$DIFF_DIR/$SUBDIR/file_list
rm -f $file_list
for f in $NEW_DIR/$SUBDIR/*.png; do
  FUZZ="-fuzz 1%"
  FUZZ=

  BLUR="-blur 0x2"

  REDUCE="-channel B -depth 7 +channel"
  REDUCE="-channel B -depth 7 "
  REDUCE=

  base=`basename $f`
  blur_base=blur_$base
  from_file=$REFERENCE_DIR/$base
  blur_from_file=$REFERENCE_DIR/$blur_base
  to_file=$NEW_DIR/$SUBDIR/$base
  blur_to_file=$NEW_DIR/$SUBDIR/$blur_base
  diff_file=$DIFF_DIR/$SUBDIR/$base
  diff_file_changed=$DIFF_DIR/$SUBDIR/$base.changed
  diff_file_metric=$DIFF_DIR/$SUBDIR/$base.metric
  rm -f $diff_file $diff_file_changed $diff_file_metric
  if [[ -e $from_file ]] && [[ -e $to_file ]]; then
    cp $from_file ${from_file}_full
    convert $from_file $BLUR $REDUCE $blur_from_file
    cp $to_file ${to_file}_full
    convert $to_file   $BLUR $REDUCE $blur_to_file
    if [ -e $PNGINFO ]; then
      from_info_file=$NEW_DIR/$SUBDIR/${base}_from.info
      to_info_file=$NEW_DIR/$SUBDIR/${base}_to.info
      $PNGINFO ${from_file}_full      > $from_info_file
      $PNGINFO ${to_file}_full        > $to_info_file
    fi
    diff=`compare -metric $METRIC $blur_from_file $blur_to_file $diff_file |& awk -F'('  '{printf $2}' | awk -F')' '{printf $1}i'`
    composite $blur_from_file $blur_to_file -compose difference /tmp/diff.$$.png

    convert /tmp/diff.$$.png -channel RGB -negate $diff_file
    rm -f /tmp/diff.$$.png

    rm -f $blur_from_file $blur_to_file
    if [[ $diff == *"e"* ]]; then
      diff=$(printf "%.6f" $diff)
    fi
    if (( $(echo "$diff < 0.01" | bc -l) )); then
      diff=0
    fi
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
        cp $f $ERROR_SUBDIR/.
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
#*** REDUCE_IMAGES
#---------------------------------------------------------

REDUCE_IMAGES ()
{
cd $SUMMARY_DIR
rm -f images/*.png
mogrify -resize 200x200 images/user/*.png
mogrify -resize 200x200 images/verification/*.png
mogrify -resize 200x200 diffs/base/user/*.png
mogrify -resize 200x200 diffs/base/verification/*.png
mogrify -resize 200x200 diffs/images/user/*.png
mogrify -resize 200x200 diffs/images/verification/*.png
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
LINK5="<a href="#manuals">[Guides]</a>"
if [[ "$SUBDIR" == "manuals" ]]; then
  LINK5="[Guides]"
fi
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
cat << EOF >> $HTML_DIFF
$LINK1$LINK3$LINK2$LINK4$LINK5
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
    from_info_file=$SUMMARY_DIR/images/user/${pngfile}_from.info
    to_info_file=  $SUMMARY_DIR/images/user/${pngfile}_to.info
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
<th align=center>|Current - Base|</th></tr>
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
    SIZE_CONVERT=${HEIGHT}x${WIDTH}
    COMPARE=`echo $ERROR'>'$TOLERANCE | bc -l`
    STYLE=
    if [ "$COMPARE" == "1" ]; then
      STYLE="style=\"color:red\""
    fi
    cp $REFERENCE_DIR/$pngfile $SUMMARY_DIR/diffs/base/$SUBDIR/.
    IMAGE_HEIGHT=`identify -format '%h' $REFERENCE_DIR/$pngfile`
    IMAGE_WIDTH=`identify -format '%w' $REFERENCE_DIR/$pngfile`
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
<td align=center><img $SIZE src=diffs/base/$SUBDIR/$pngfile>
<br>$pngfile
EOF
if [ -e $from_info_file ]; then
cat $from_info_file >> $HTML_DIFF
fi
echo "</td>" >> $HTML_DIFF
else
cat << EOF >> $HTML_DIFF
<tr>
<td><img $SIZE src=diffs/base/$SUBDIR/$pngfile>
EOF
if [ -e $from_info_file ]; then
cat $from_info_file >> $HTML_DIFF
fi
echo "</td>" >> $HTML_DIFF
fi

COLSPAN=
if [ "$START_REST" != "2" ]; then
  COLSPAN="colspan=2"
  cat << EOF >> $HTML_DIFF
<td><img $SIZE src=images/$SUBDIR/$pngfile>
EOF
if [ -e $to_info_file ]; then
cat $to_info_file >> $HTML_DIFF
fi
cat << EOF >> $HTML_DIFF
</td>
<td><img $SIZE src=diffs/images/$SUBDIR/$pngfile></td>
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

CHECK_DIR $REFERENCE_DIR 1
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
<TITLE>$BOT_TITLE Summary</TITLE>
</HEAD>
<BODY BGCOLOR="#FFFFFF" >
<h2>$BOT_TITLE Summary - $DATE</h2>

<table>
<tr><th align=left>FDS revision:</th>     <td> $FDS_REVISION/$FDS_BRANCH  </td></tr>
<tr><th align=left>SMV revision:</th>     <td> $SMV_REVISION/$SMV_BRANCH  </td></tr>
<tr><th align=left>Fig revision:</th>     <td> $FIG_REVISION/$FIG_BRANCH  </td></tr>
<tr><th align=left>Root:</th>             <td> $REPO                      </td></tr>
<tr><th align=left>Metric/Tolerance:</th> <td> ${METRIC_LABEL}/$TOLERANCE </td></tr>
<tr><th align=left>Differences/Errors:</th>     <td> $HAVE_DIFFS/$HAVE_ERRORS   </td></tr>
EOF
if [ "$ADD_FDS_MANUALS" != "" ]; then
cat << EOF  >> $HTML_DIFF
<tr><th align=left>Bundles/Guides/Figures:</th><td><a href="https://github.com/$GH_OWNER/$GH_REPO/releases/tag/$GH_FDS_TAG">https://github.com/$GH_OWNER/$GH_REPO/releases/tag/$GH_FDS_TAG</a></td></tr>
EOF
fi
if [ "$ADD_SMOKEVIEW_MANUALS" != "" ]; then
cat << EOF  >> $HTML_DIFF
<tr><th align=left>Bundles/Guides/Figures:</th><td><a href="https://github.com/$GH_OWNER/$GH_REPO/releases/tag/$GH_SMOKEVIEW_TAG">https://github.com/$GH_OWNER/$GH_REPO/releases/tag/$GH_SMOKEVIEW_TAG</a></td></tr>
EOF
fi
cat << EOF  >> $HTML_DIFF
</table>
EOF

#*** output all images

OUTPUT_HTML user         User         $FIG_USER_FDS_REVISION $FIG_USER_SMV_REVISION
OUTPUT_HTML verification Verification $FIG_VER_FDS_REVISION  $FIG_VER_SMV_REVISION
cat << EOF >> $HTML_DIFF
<h2 id="manuals">Guides</h2>
EOF
OUTPUT_LINKS manuals
if [ "$BASEDIR" == "Smokebot" ]; then
cat << EOF  >> $HTML_DIFF
<ul>
<li><a href="manuals/SMV_User_Guide.pdf">Smokeview User Guide</a>
<li><a href="manuals/SMV_Verification_Guide.pdf">Smokeview Verification Guide</a>
<li><a href="manuals/SMV_Technical_Reference_Guide.pdf">Smokeview Technical Reference Guide</a>
</ul>
EOF
fi
if [ "$BASEDIR" == "Firebot" ]; then
cat << EOF  >> $HTML_DIFF
<ul>
<li><a href="manuals/FDS_Config_Management_Plan.pdf">FDS Configuration Management Plan</a>
<li><a href="manuals/FDS_Technical_Reference_Guide.pdf">FDS Technical Reference Guide</a>
<li><a href="manuals/FDS_User_Guide.pdf">FDS User Guide</a>
<li><a href="manuals/FDS_Validation_Guide.pdf>FDS Validation Guide</a>
<li><a href="manuals/FDS_Verification_Guide.pdf>FDS Verification Guide</a>
</ul>
EOF
fi

cat << EOF  >> $HTML_DIFF
<p><hr>
</BODY>
</HTML>
EOF

REDUCE_IMAGES

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
echo $HAVE_DIFFS $HAVE_ERRORS > $IMAGE_DIFFS

