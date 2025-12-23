#!/bin/bash
FDSEDITION=FDS6

edition=$1
revision=$2
GITROOT=~/$3

smvbin=smvbin

errlog=/tmp/smv_errlog.$$

TEST=
RELEASE=
if [ "$edition" == "test" ]; then
  TEST=_test
else
  RELEASE=
fi

platform="linux"
platform2="LINUX"
platform3="lnx"
COMPILER=intel
if [ "`uname`" == "Darwin" ]
then
  platform="osx"
  platform2="OSX"
  platform3="osx"
  COMPILER=gnu
fi

CP ()
{
  FROMDIR=$1
  FROMFILE=$2
  TODIR=$3
  TOFILE=$4
  if [ ! -e $FROMDIR/$FROMFILE ]; then
    echo "***error: the file $FROMFILE does not exist"
  else
    cp $FROMDIR/$FROMFILE $TODIR/$TOFILE
  fi
  if [ -e $TODIR/$TOFILE ]; then
    echo "$TOFILE copied"
  else
    echo "***error: the file $TOFILE failed to copy from $FROMDIR/$FROMFILE">>$errlog
    echo "">>$errlog
  fi
}

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
    echo "$TODIR copied"
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
WEBGLDIR=$GITROOT/smv/Build/for_bundle/webgl
UTILSCRIPTDIR=$GITROOT/smv/Utilities/Scripts
PLATFORMDIR=$RELEASE$revision\_${platform3}
MAKEINSTALLER=$GITROOT/bot/Bundlebot/nightly/make_smv_installer.sh
uploads=$HOME/.bundle/uploads
uploadscp=.bundle/uploads
flushfile=$GITROOT/smv/Build/flush/${COMPILER}_${platform}/flush_${platform}

if [ ! -e $HOME/.bundle ]; then
  mkdir $HOME/.bundle
fi
if [ ! -e $uploads ]; then
  mkdir $uploads
fi

cd $uploads

rm -rf $PLATFORMDIR
mkdir -p $PLATFORMDIR
mkdir -p $PLATFORMDIR/bin
mkdir -p $PLATFORMDIR/$smvbin
mkdir -p $PLATFORMDIR/Documentation

echo ""
echo "---- copying files ----"
echo ""
CPDIR $FORBUNDLE/textures  $PLATFORMDIR/bin/textures
CPDIR $FORBUNDLE/colorbars $PLATFORMDIR/bin/colorbars

cp $FORBUNDLE/*.png $PLATFORMDIR/$smvbin/.
#cp $FORBUNDLE/*.po $PLATFORMDIR/$smvbin/.

CP $FORBUNDLE       objects.svo       $PLATFORMDIR/$smvbin objects.svo
CP $FORBUNDLE       smokeview.ini     $PLATFORMDIR/$smvbin smokeview.ini
CP $FORBUNDLE       volrender.ssf     $PLATFORMDIR/$smvbin volrender.ssf
CP $FORBUNDLE       smokeview.html    $PLATFORMDIR/$smvbin smokeview.html
CP $WEBGLDIR        runsmv_ssh.sh     $PLATFORMDIR/$smvbin runsmv_ssh.sh
CP $WEBGLDIR        smv2html.sh       $PLATFORMDIR/$smvbin smv2html.sh
CP $UTILSCRIPTDIR   slice2html.sh     $PLATFORMDIR/$smvbin slice2html.sh
CP $UTILSCRIPTDIR   slice2mp4.sh      $PLATFORMDIR/$smvbin slice2mp4.sh
CP $FORBUNDLE       .smokeview_bin    $PLATFORMDIR/$smvbin .smokeview_bin

CP  $BACKGROUNDDIR background_${platform} $PLATFORMDIR/$smvbin background
if [ "$platform" == "osx" ]; then
  CP  $SMVDIR       smokeview_${platform}${TEST}       $PLATFORMDIR/$smvbin smokeview
else
  CP  $SMVDIR        smokeview_${platform}${TEST}      $PLATFORMDIR/$smvbin smokeview
fi
CP  $SMDDIR        smokediff_${platform}         $PLATFORMDIR/$smvbin smokediff
CP  $PNGINFODIR    pnginfo_${platform}           $PLATFORMDIR/$smvbin pnginfo
CP  $FDS2FEDDIR    fds2fed_${platform}           $PLATFORMDIR/$smvbin fds2fed
CP  $SMZDIR        smokezip_${platform}          $PLATFORMDIR/$smvbin smokezip
CP  $WIND2FDSDIR   wind2fds_${platform}          $PLATFORMDIR/$smvbin wind2fds
CP  $FLUSHFILEDIR  flush_${platform}             $PLATFORMDIR/$smvbin flush

CURDIR=`pwd`

rm -f $PLATFORMDIR.tar $PLATFORMDIR.tar.gz
cd $PLATFORMDIR
echo ""
echo "---- building installer ----"
echo ""
tar cvf ../$PLATFORMDIR.tar .
cd ..
gzip $PLATFORMDIR.tar
$MAKEINSTALLER ${platform2} $revision $PLATFORMDIR.tar.gz $PLATFORMDIR.sh FDS/$FDSEDITION
echo "$PLATFORMDIR.sh   copied to $uploads on `hostname`"

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
