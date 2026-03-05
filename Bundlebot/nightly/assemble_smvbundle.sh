#!/bin/bash
FDSEDITION=FDS6

revision=$1
GITROOT=~/$2
LABEL=$3
scan_bundle=$4

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"

smvbin=smvbin

errlog=/tmp/smv_errlog.$$

platform="linux"
platform2="LINUX"
COMPILER=intel
if [ "`uname`" == "Darwin" ]
then
  platform="osx"
  platform2="OSX"
  COMPILER=gnu
fi

# -------------------- CP -------------------

CP ()
{
  FROMDIR=$1
  FROMFILE=$2
  TODIR=$3
  TOFILE=$4
  if [ "$TOFILE" == "" ]; then
    TOFILE=$FROMFILE
  fi

  if [ ! -e $FROMDIR/$FROMFILE ]; then
    echo "***error: the file $FROMFILE does not exist"
  else
    cp $FROMDIR/$FROMFILE $TODIR/$TOFILE
  fi
  if [ -e $TODIR/$TOFILE ]; then
    echo "*** $TOFILE copied"
  else
    echo "***error: the file $TOFILE failed to copy from $FROMDIR/$FROMFILE">>$errlog
    echo "">>$errlog
  fi
}

# -------------------- IS_PROGRAM_INSTALLED -------------------

IS_PROGRAM_INSTALLED()
{
  program=$1
  notfound=`$program -help 2>&1 | tail -1 | grep "not found" | wc -l`
  if [ $notfound -eq 0 ] ; then
    echo 1
  else
    echo 0
  fi
  exit
}

# -------------------- CPDIR -------------------

CPDIR ()
{
  FROMDIR=$1
  TODIR=$2
  if [ ! -e $FROMDIR ]; then
    echo "***error: the directory $FROMDIR does not exist"
  else
    cp -r $FROMDIR $TODIR
  fi
  if [ -e $TODIR ]; then
    echo "*** $TODIR copied"
  else
    echo "***error: the directory $TODIR failed to copy from $FROMDIR">>$errlog
    echo "">$errlog
  fi
}


BACKGROUNDDIR=$GITROOT/smv/Build/background/${COMPILER}_${platform}
SMVDIR=$GITROOT/smv/Build/smokeview/${COMPILER}_${platform}
SMVDIRQ=$GITROOT/smv/Build/smokeview/${COMPILER}_${platform}_q
SMZDIR=$GITROOT/smv/Build/smokezip/${COMPILER}_${platform}
SMDDIR=$GITROOT/smv/Build/smokediff/${COMPILER}_${platform}
PNGINFODIR=$GITROOT/smv/Build/pnginfo/${COMPILER}_${platform}
FDS2FEDDIR=$GITROOT/smv/Build/fds2fed/${COMPILER}_${platform}
WIND2FDSDIR=$GITROOT/smv/Build/wind2fds/${COMPILER}_${platform}
FLUSHFILEDIR=$GITROOT/smv/Build/flush/${COMPILER}_${platform}
FORBUNDLE=$GITROOT/smv/Build/for_bundle
SMVSCRIPTDIR=$GITROOT/smv/scripts
UTILSCRIPTDIR=$GITROOT/smv/Utilities/Scripts
PLATFORMDIR=$revision\_${LABEL}
MAKEINSTALLER=$GITROOT/bot/Bundlebot/nightly/make_smv_installer.sh
UPLOADDIR=$HOME/.bundle/bundles
flushfile=$GITROOT/smv/Build/flush/${COMPILER}_${platform}/flush_${platform}

if [ ! -d $UPLOADDIR ]; then
  mkdir -p $UPLOADDIR
fi

cd $UPLOADDIR

rm -rf $PLATFORMDIR
mkdir -p $PLATFORMDIR/$smvbin

echo 
echo "***copying files"
echo 
CPDIR $FORBUNDLE/textures  $PLATFORMDIR/smvbin/textures
CPDIR $FORBUNDLE/colorbars $PLATFORMDIR/smvbin/colorbars

cp $FORBUNDLE/*.png $PLATFORMDIR/$smvbin/.
#cp $FORBUNDLE/*.po $PLATFORMDIR/$smvbin/.

CP $FORBUNDLE       objects.svo       $PLATFORMDIR/$smvbin
CP $FORBUNDLE       smokeview.ini     $PLATFORMDIR/$smvbin
CP $FORBUNDLE       volrender.ssf     $PLATFORMDIR/$smvbin
CP $UTILSCRIPTDIR   slice2html.sh     $PLATFORMDIR/$smvbin
CP $UTILSCRIPTDIR   slice2mp4.sh      $PLATFORMDIR/$smvbin
CP $FORBUNDLE       .smokeview_bin    $PLATFORMDIR/$smvbin
CP $SMVSCRIPTDIR    jp2conv.sh        $PLATFORMDIR/$smvbin

CP  $BACKGROUNDDIR background_${platform} $PLATFORMDIR/$smvbin background
if [ "$platform" == "osx" ]; then
  CP  $SMVDIR       smokeview_${platform}       $PLATFORMDIR/$smvbin smokeview
else
  CP  $SMVDIR        smokeview_${platform}      $PLATFORMDIR/$smvbin smokeview
fi
CP  $SMDDIR        smokediff_${platform}         $PLATFORMDIR/$smvbin smokediff
CP  $PNGINFODIR    pnginfo_${platform}           $PLATFORMDIR/$smvbin pnginfo
CP  $FDS2FEDDIR    fds2fed_${platform}           $PLATFORMDIR/$smvbin fds2fed
CP  $SMZDIR        smokezip_${platform}          $PLATFORMDIR/$smvbin smokezip
CP  $WIND2FDSDIR   wind2fds_${platform}          $PLATFORMDIR/$smvbin wind2fds
CP  $FLUSHFILEDIR  flush_${platform}             $PLATFORMDIR/$smvbin flush

CURDIR=`pwd`

# scan for viruses

if [ "$scan_bundle" == "1" ]; then
  clam_status=`IS_PROGRAM_INSTALLED clamscan`
  if [ $clam_status -eq 1 ]; then
    scanlog=$SCRIPTDIR/output/${PLATFORMDIR}_log.txt
    vscanlog=$SCRIPTDIR/output/${PLATFORMDIR}.log
    htmllog=$SCRIPTDIR/output/${PLATFORMDIR}_manifest.html
    csvlog=$SCRIPTDIR/output/${PLATFORMDIR}.csv
    bundledir=$HOME/.bundle/bundles/${PLATFORMDIR}
  
 
    if [ "$TEST_VIRUS" != "" ]; then
      $SCRIPTDIR/gen_eicar.sh $bundledir/eicar.com
    fi

    echo ""
    echo "*** scanning $PLATFORMDIR for viruses/malware"
    echo "" 
    clamscan -r $UPLOADDIR/$PLATFORMDIR > $scanlog 2>&1
    sed 's/.*SMV-/SMV-/' $scanlog      > $vscanlog
    echo ""
    echo "*** adding sha256 hashes"
    echo "" 
    $SCRIPTDIR/add_sha256.sh $vscanlog > $csvlog
    sed -i.bak '/SCAN SUMMARY/,$d; s|.*SMV[^/]*/||g'     $csvlog
    sort -f -o $csvlog $csvlog
    sed -n '/SCAN SUMMARY/,$p' $vscanlog >> $csvlog
    $SCRIPTDIR/csv2html.sh                                  $csvlog SMV
    if [ -e $SCRIPTDIR/output/${PLATFORMDIR}_manifest.html ]; then
      CP $SCRIPTDIR/output ${PLATFORMDIR}_manifest.html $bundledir/smvbin SmvManifest.html
      CP $SCRIPTDIR/output ${PLATFORMDIR}_manifest.html $UPLOADDIR ${PLATFORMDIR}_manifest.html
   fi
    ninfected=`grep 'Infected files' $vscanlog | awk -F: '{print $2}'`
    if [ "$ninfected" == "" ]; then
      ninfected=0
    fi
    if [[ $ninfected -eq 0 ]]; then
      echo "*** no viruses were found in $UPLOAD_DIR/$PLATFORMDIR"
    else
      returncode=1
      echo "***error: $ninfected files found with a virus and/or malware in $UPLOAD_DIR/$PLATFORMDIR"
    fi
  else
    echo "***warning: clamscan not found"
    echo "            bundle will not be scanned for viruses or malware"
  fi
fi

rm -f $PLATFORMDIR.tar $PLATFORMDIR.tar.gz
echo ""
echo "*** building installer"
echo ""
tar cvf $PLATFORMDIR.tar $PLATFORMDIR
gzip $PLATFORMDIR.tar
$MAKEINSTALLER ${platform2} $revision $PLATFORMDIR.tar.gz $PLATFORMDIR.sh FDS/$FDSEDITION
echo "    `hostname`:$UPLOADDIR/$PLATFORMDIR.sh"

if [ -e $errlog ]; then
  numerrs=`cat $errlog | wc -l `
  if [ $numerrs -gt 0 ]; then
    echo ""
    echo "----------------------------------------------------------------"
    echo "---------------- bundle generation errors ----------------------"
    cat $errlog
    echo "----------------------------------------------------------------"
    echo "----------------------------------------------------------------"
    echo ""
  fi
  rm $errlog
fi
 
