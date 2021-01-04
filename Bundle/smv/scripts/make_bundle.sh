#!/bin/bash
FDSEDITION=FDS6

edition=$1
revision=$2
REMOTESVNROOT=$3
PLATFORMHOST=$4
SVNROOT=~/$5

smvbin=smvbin

errlog=/tmp/smv_errlog.$$

TEST=
RELEASE=
if [ "$edition" == "test" ]; then
  TEST=test_
else
  RELEASE=
fi

platform="linux"
platform2="LINUX"
platform3="lnx"
if [ "`uname`" == "Darwin" ]
then
  platform="osx"
  platform2="OSX"
  platform3="osx"
fi

SCP ()
{
  HOST=$1
  FROMDIR=$2
  FROMFILE=$3
  TODIR=$4
  TOFILE=$5

  scp $HOST\:$FROMDIR/$FROMFILE $TODIR/$TOFILE 2>/dev/null
  if [ -e $TODIR/$TOFILE ]; then
    echo "$TOFILE copied from $HOST"
  else
    echo "***error: the file $TOFILE failed to copy from: ">>$errlog
    echo "$HOST:$FROMDIR/$FROMFILE">>$errlog
    echo "">>$errlog
  fi
}

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


BACKGROUNDDIR=$REMOTESVNROOT/smv/Build/background/intel_${platform}_64
SMVDIR=$REMOTESVNROOT/smv/Build/smokeview/intel_${platform}_64
SMVDIRNOQ=$REMOTESVNROOT/smv/Build/smokeview/intel_${platform}_noq_64
GNUSMVDIR=$REMOTESVNROOT/smv/Build/smokeview/gnu_${platform}_64
SMZDIR=$REMOTESVNROOT/smv/Build/smokezip/intel_${platform}_64
SMDDIR=$REMOTESVNROOT/smv/Build/smokediff/intel_${platform}_64
WIND2FDSDIR=$REMOTESVNROOT/smv/Build/wind2fds/intel_${platform}_64
HASHFILEDIR=$REMOTESVNROOT/smv/Build/hashfile/intel_${platform}_64
FLUSHFILEDIR=$REMOTESVNROOT/smv/Build/flush/intel_${platform}_64
FORBUNDLE=$SVNROOT/bot/Bundle/smv/for_bundle
WEBGLDIR=$SVNROOT/bot/Bundle/smv/for_bundle/webgl
UTILSCRIPTDIR=$SVNROOT/smv/Utilities/Scripts
PLATFORMDIR=$RELEASE$revision\_${platform3}
UPDATER=$SVNROOT/bot/Bundle/smv/scripts//make_updater.sh
uploads=$HOME/.bundle/uploads
flushfile=$SVNROOT/smv/Build/flush/intel_${platform}_64/flush_${platform}_64

cd $uploads

rm -rf $PLATFORMDIR
mkdir -p $PLATFORMDIR
mkdir -p $PLATFORMDIR/bin
mkdir -p $PLATFORMDIR/bin/hash
mkdir -p $PLATFORMDIR/$smvbin
mkdir -p $PLATFORMDIR/$smvbin/hash
mkdir -p $PLATFORMDIR/Documentation

echo ""
echo "---- copying files ----"
echo ""
CPDIR $FORBUNDLE/textures $PLATFORMDIR/bin/textures

cp $FORBUNDLE/*.png $PLATFORMDIR/$smvbin/.
cp $FORBUNDLE/*.po $PLATFORMDIR/$smvbin/.

CP $FORBUNDLE       objects.svo       $PLATFORMDIR/$smvbin objects.svo
CP $FORBUNDLE       smokeview.ini     $PLATFORMDIR/$smvbin smokeview.ini
CP $FORBUNDLE       volrender.ssf     $PLATFORMDIR/$smvbin volrender.ssf
CP $FORBUNDLE       smokeview.html    $PLATFORMDIR/$smvbin smokeview.html
CP $FORBUNDLE/webvr smokeview_vr.html $PLATFORMDIR/$smvbin smokeview_vr.html
CP $WEBGLDIR        runsmv_ssh.sh     $PLATFORMDIR/$smvbin runsmv_ssh.sh
CP $WEBGLDIR        smv2html.sh       $PLATFORMDIR/$smvbin smv2html.sh
CP $UTILSCRIPTDIR   slice2html.sh     $PLATFORMDIR/$smvbin slice2html.sh
CP $UTILSCRIPTDIR   slice2mp4.sh      $PLATFORMDIR/$smvbin slice2mp4.sh

SCP $PLATFORMHOST $BACKGROUNDDIR background_${platform}_64 $PLATFORMDIR/$smvbin background
if [ "$platform" == "osx" ]; then
  SCP $PLATFORMHOST $SMVDIR       smokeview_${platform}_${TEST}64       $PLATFORMDIR/$smvbin smokeview_q
  SCP $PLATFORMHOST ${SMVDIRNOQ}  smokeview_${platform}_${TEST}noq_64   $PLATFORMDIR/$smvbin smokeview
else
  SCP $PLATFORMHOST $SMVDIR        smokeview_${platform}_${TEST}64  $PLATFORMDIR/$smvbin smokeview
fi
if [ "$edition" == "test" ]; then
  SCP $PLATFORMHOST $GNUSMVDIR     smokeview_${platform}_${TEST}64p $PLATFORMDIR/$smvbin smokeview_gnu
  if [ -e $PLATFORMDIR/$smvbin/smokeview_gnu ]; then
    SCP $PLATFORMHOST $FORBUNDLE     smokeview_p                      $PLATFORMDIR/$smvbin smokeview_p
  fi
fi
SCP $PLATFORMHOST $SMDDIR        smokediff_${platform}_64         $PLATFORMDIR/$smvbin smokediff
SCP $PLATFORMHOST $SMZDIR        smokezip_${platform}_64          $PLATFORMDIR/$smvbin smokezip
SCP $PLATFORMHOST $WIND2FDSDIR   wind2fds_${platform}_64          $PLATFORMDIR/$smvbin wind2fds
SCP $PLATFORMHOST $HASHFILEDIR   hashfile_${platform}_64          $PLATFORMDIR/$smvbin hashfile
SCP $PLATFORMHOST $FLUSHFILEDIR  flush_${platform}_64             $PLATFORMDIR/$smvbin flush

CURDIR=`pwd`
cd $PLATFORMDIR/$smvbin
HASHFILE=$HOME/$HASHFILEDIR/hashfile_${platform}_64
$HASHFILE background > background.sha1
$HASHFILE smokediff  > smokediff.sha1
$HASHFILE smokeview  > smokeview.sha1
$HASHFILE smokezip   > smokezip.sha1
$HASHFILE wind2fds   > wind2fds.sha1
$HASHFILE hashfile   > hashfile.sha1
cat *.sha1 > $uploads/$PLATFORMDIR.sha1
cd $CURDIR

rm -f $PLATFORMDIR.tar $PLATFORMDIR.tar.gz
cd $PLATFORMDIR
echo ""
echo "---- building installer ----"
echo ""
tar cvf ../$PLATFORMDIR.tar .
cd ..
gzip $PLATFORMDIR.tar
$UPDATER ${platform2} $revision $PLATFORMDIR.tar.gz $PLATFORMDIR.sh FDS/$FDSEDITION
$HASHFILE $PLATFORMDIR.sh > $PLATFORMDIR.sh.sha1
cat $PLATFORMDIR.sh.sha1 >> $uploads/$PLATFORMDIR.sha1
rm $PLATFORMDIR.sh.sha1

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
