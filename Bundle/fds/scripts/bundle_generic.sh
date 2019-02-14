#!/bin/bash

GUIDE_DIR=$HOME/.bundle/pubs
SMV_DIR=$HOME/.bundle/BUNDLE/smv
FDS_DIR=$HOME/.bundle/BUNDLE/fds

# determine directory repos reside under

scriptdir=`dirname "$(readlink -f "$0")"`
curdir=`pwd`
cd $scriptdir/../../../..
REPO_ROOT=`pwd`
cd $curdir


INSTALLDIR=FDS/FDS6

# this script is called by make_bundle.sh located in bot/Bundle/fds/linux or osx

errlog=/tmp/errlog.$$

# -------------------- CP -------------------

CP ()
{
  local FROMDIR=$1
  local FROMFILE=$2
  local TODIR=$3
  local TOFILE=$4
  local ERR=
  if [ ! -e $FROMDIR/$FROMFILE ]; then
    echo "***error: the file $FROMFILE was not found in $FROMDIR" >> $errlog
    echo "***error: the file $FROMFILE was not found in $FROMDIR"
    ERR="1"
    if [ "$NOPAUSE" == "" ]; then
      read val
    fi
  else
    cp $FROMDIR/$FROMFILE $TODIR/$TOFILE
  fi
  if [ -e $TODIR/$TOFILE ]; then
    echo "$FROMFILE copied to $TODIR/$TOFILE"
  else
    if [ "ERR" == "" ]; then
      echo "***error: $FROMFILE could not be copied from $FROMDIR to $TODIR" >> $errlog
      echo "***error: $FROMFILE could not be copied from $FROMDIR to $TODIR"
      if [ "$NOPAUSE" == "" ]; then
        read val
      fi
    fi
  fi
}

# -------------------- UNTAR -------------------

UNTAR ()
{
  local FROMDIR=$1
  local FROMFILE=$2
  local TODIR=$3
  local TODIR2=$4
  local ERR=
  if [ ! -e $FROMDIR/$FROMFILE ]; then
    echo "***error: the file $FROMFILE was not found in $FROMDIR" >> $errlog
    echo "***error: the file $FROMFILE was not found in $FROMDIR"
    ERR="1"
    if [ "$NOPAUSE" == "" ]; then
      read val
    fi
  else
    curdir=`pwd`
    cd $TODIR
    tar xvf $FROMDIR/$FROMFILE
    cd $curdir
  fi
  if [ -e $TODIR/$TODIR2 ]; then
    echo "$FROMFILE untar'd"
  else
    if [ "$ERR" == "" ]; then
      echo "***error: $FROMFILE not untar'd to bundle" >> $errlog
      echo "***error: $FROMFILE not untar'd to bundle"
      if [ "$NOPAUSE" == "" ]; then
        read val
      fi
    fi
  fi
}

# -------------------- CP2 -------------------

CP2 ()
{
  local FROMDIR=$1
  local FROMFILE=$2
  local TODIR=$3
  local TOFILE=$FROMFILE
  ERR=
  if [ ! -e $FROMDIR/$FROMFILE ]; then
    echo "***error: the file $FROMFILE was not found in $FROMDIR" >> $errlog
    echo "***error: the file $FROMFILE was not found in $FROMDIR"
    ERR="1"
    if [ "$NOPAUSE" == "" ]; then
      read val
    fi
  else
    cp $FROMDIR/$FROMFILE $TODIR/$TOFILE
  fi
  if [ -e $TODIR/$TOFILE ]; then
    echo "$FROMFILE copied"
  else
    if [ "$ERR" == "" ]; then
      echo "***error: $FROMFILE could not be copied to $TODIR" >> $errlog
      echo "***error: $FROMFILE could not be copied to $TODIR"
      if [ "$NOPAUSE" == "" ]; then
        read val
      fi
    fi
  fi
}

# -------------------- CPDIR -------------------

CPDIR ()
{
  local FROMDIR=$1
  local TODIR=$2
  local ERR=
  if [ ! -e $FROMDIR ]; then
    echo "***error: the directory $FROMDIR does not exist" >> $errlog
    echo "***error: the directory $FROMDIR does not exist"
    ERR="1"
    if [ "$NOPAUSE" == "" ]; then
      read val
    fi
  else
    echo "*******************************"
    echo copying directory from $FROMDIR to $TODIR
    echo "*******************************"
    cp -r $FROMDIR $TODIR
  fi
  if [ -e $TODIR ]; then
    echo "$FROMDIR copied"
  else
    if [ "$ERR" == "" ]; then
      echo "***error: the directory $FROMDIR could not copied to $TODIR" >> $errlog
      echo "***error: the directory $FROMDIR could not copied to $TODIR"
      if [ "$NOPAUSE" == "" ]; then
        read val
      fi
    fi
  fi
}

# -------------------- CPDIRFILES -------------------

CPDIRFILES ()
{
  local FROMDIR=$1
  local TODIR=$2
  local ERR=
  if [ ! -d $FROMDIR ]; then
    echo "***error: the directory $FROMDIR does not exist" >> $errlog
    echo "***error: the directory $FROMDIR does not exist"
    ERR="1"
    if [ "$NOPAUSE" == "" ]; then
      read val
    fi
  else
    echo "*******************************"
    echo copying files from directory $FROMDIR to $TODIR
    echo "*******************************"
    cp $FROMDIR/* $TODIR/.
  fi
  if [ -e $TODIR ]; then
    echo "$FROMDIR copied"
  else
    if [ "$ERR" == "" ]; then
      echo "***error: unable to copy $FROMDIR to $TODIR" >> $errlog
      echo "***error: unable to copy $FROMDIR to $TODIR"
      if [ "$NOPAUSE" == "" ]; then
        read val
      fi
    fi
  fi
}

# determine OS

if [ "`uname`" == "Darwin" ]; then
  FDSOS=_osx_64
  OS=_osx
  PLATFORM=OSX64
else
  FDSOS=_linux_64
  OS=_linux
  PLATFORM=LINUX64
fi


smvscriptdir=$REPO_ROOT/smv/scripts
uploaddir=$HOME/.bundle/uploads
bundledir=$bundlebase
webpagesdir=$REPO_ROOT/webpages
fds_bundle=$REPO_ROOT/bot/Bundle/fds/for_bundle
smv_bundle=$REPO_ROOT/bot/Bundle/smv/for_bundle
texturedir=$smv_bundle/textures
makeinstaller=$REPO_ROOT/bot/Bundle/fds/scripts/make_installer.sh

fds_cases=$REPO_ROOT/fds/Verification/FDS_Cases.sh
fds_benchamrk_cases=$REPO_ROOT/fds/Verification/FDS_Benchmark_Cases.sh
smv_cases=$REPO_ROOT/smv/Verification/scripts/SMV_Cases.sh
wui_cases=$REPO_ROOT/smv/Verification/scripts/WUI_Cases.sh
copyfdscase=$REPO_ROOT/fds/Utilities/Scripts/copyfdscase.sh
copycfastcase=$REPO_ROOT/fds/Utilities/Scripts/copycfastcase.sh
FDSExamplesDirectory=$REPO_ROOT/fds/Verification
SMVExamplesDirectory=$REPO_ROOT/smv/Verification

cd $uploaddir
rm -rf $bundlebase
mkdir $bundledir
mkdir $bundledir/bin
mkdir $bundledir/bin/hash
mkdir $bundledir/Documentation
mkdir $bundledir/Examples
mkdir $bundledir/bin/textures

echo ""
echo "--- copying programs ---"
echo ""

# smokeview

CP $SMV_DIR background $bundledir/bin background
CP $SMV_DIR smokeview  $bundledir/bin smokeview
CP $SMV_DIR smokediff  $bundledir/bin smokediff
CP $SMV_DIR smokezip   $bundledir/bin smokezip
CP $SMV_DIR dem2fds    $bundledir/bin dem2fds
CP $SMV_DIR wind2fds   $bundledir/bin wind2fds
CP $SMV_DIR hashfile   $bundledir/bin hashfile

CURDIR=`pwd`
cd $bundledir/bin
hashfile background > hash/background.sha1
hashfile smokeview  > hash/smokeview.sha1
hashfile smokediff  > hash/smokediff.sha1
hashfile smokezip   > hash/smokezip.sha1
hashfile dem2fds    > hash/dem2fds.sha1
hashfile wind2fds   > hash/wind2fds.sha1
hashfile hashfile   > hash/hashfile.sha1
cd $CURDIR

CP $smvscriptdir jp2conv.sh $bundledir/bin jp2conv.sh
CPDIR $texturedir $bundledir/bin

# FDS 

CP $FDS_DIR fds       $bundledir/bin fds
CP $FDS_DIR fds2ascii $bundledir/bin fds2ascii
CP $FDS_DIR test_mpi  $bundledir/bin test_mpi

CURDIR=`pwd`
cd $bundledir/bin
hashfile fds       > hash/fds.sha1
hashfile fds2ascii > hash/fds2ascii.sha1
hashfile test_mpi  > hash/test_mpi.sha1
cd $CURDIR

if [ "$MPI_VERSION" != "INTEL" ]; then
  if [ "$PLATFORM" == "LINUX64" ]; then
    openmpifile=openmpi_${MPI_VERSION}_linux_64.tar.gz
  fi
  if [ "$PLATFORM" == "OSX64" ]; then
    openmpifile=openmpi_${MPI_VERSION}_osx_64.tar.gz
  fi
fi

echo ""
echo "--- copying configuration files ---"
echo ""

CP $smv_bundle smokeview.ini    $bundledir/bin smokeview.ini
CP $smv_bundle volrender.ssf    $bundledir/bin volrender.ssf
CP $smv_bundle objects.svo      $bundledir/bin objects.svo
if [ "$MPI_VERSION" == "INTEL" ]; then
  UNTAR $HOME/fire-notes/INSTALL/LIBS/RUNTIME/MPI_INTEL19U1 INTEL19u1linux.tar.gz $bundledir/bin INTEL
else
  CP $OPENMPI_DIR $openmpifile  $bundledir/bin $openmpifile
fi

echo ""
echo "--- copying documentation ---"
echo ""
CP2 $GUIDE_DIR FDS_Config_Management_Plan.pdf    $bundledir/Documentation
CP2 $GUIDE_DIR FDS_Technical_Reference_Guide.pdf $bundledir/Documentation
CP2 $GUIDE_DIR FDS_User_Guide.pdf                $bundledir/Documentation
CP2 $GUIDE_DIR FDS_Validation_Guide.pdf          $bundledir/Documentation
CP2 $GUIDE_DIR FDS_Verification_Guide.pdf        $bundledir/Documentation
CP2 $GUIDE_DIR SMV_User_Guide.pdf                $bundledir/Documentation
CP2 $GUIDE_DIR SMV_Technical_Reference_Guide.pdf $bundledir/Documentation
CP2 $GUIDE_DIR SMV_Verification_Guide.pdf        $bundledir/Documentation

if [[ "$OS_LIB_DIR" != "" ]] && [[ -e $OS_LIB_DIR ]]; then
  echo ""
  echo "--- copying run time libraries ---"
  echo ""
  mkdir $bundledir/bin/LIB64
  CPDIRFILES $OS_LIB_DIR $bundledir/bin/LIB64
fi

echo ""
echo "--- copying release notes ---"
echo ""

CP $webpagesdir FDS_Release_Notes.htm $bundledir/Documentation FDS_Release_Notes.html
CP $webpagesdir smv_readme.html       $bundledir/Documentation SMV_Release_Notes.html


# CP2 $fds_bundle readme_examples.html $bundledir/Examples

export OUTDIR=$uploaddir/$bundledir/Examples
export QFDS=$copyfdscase
export RUNTFDS=$copyfdscase
export RUNCFAST=$copycfastcase

echo ""
echo "--- copying example files ---"
echo ""
cd $FDSExamplesDirectory
$fds_cases
$fds_benchmark_cases
cd $SMVExamplesDirectory
$wui_cases
$smv_cases
rm -rf $OUTDIR/Immersed_Boundary_Method

cd $curdir

echo ""
echo "--- building archive ---"
echo ""
rm -rf $uploaddir/$bundlebase.tar
rm -rf $uploaddir/$bundlebase.tar.gz
cd $uploaddir/$bundlebase
tar cf ../$bundlebase.tar --exclude='*.csv' .
echo Compressing archive
gzip    ../$bundlebase.tar
echo Creating installer
cd ..
bundlepath=`pwd`/$bundlebase.sh
$makeinstaller -i $bundlebase.tar.gz -d $INSTALLDIR $bundlebase.sh

cat $bundledir/bin/hash/*.sha1 >  $bundlebase.sha1
hashfile $bundlebase.sh        >> $bundlebase.sha1

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
echo installer located at:
echo $bundlepath
