#!/bin/bash
fds_version=$1
smv_version=$2
MPI_VERSION=$3
INTEL_COMP_VERSION=$4
UPLOAD_DIR_ARG=$5
NIGHTLY=$6

if [ "$NIGHTLY" == "null" ]; then
  NIGHTLY=
fi
if [ "$NIGHTLY" != "" ]; then
  NIGHTLY="${NIGHTLY}_"
fi

# this script assumes that fds and smokeview apps have been copied into APPS_DIR
# manuals have been copied into GUIDE_DIR

GUIDE_DIR=$HOME/.bundle/pubs
APPS_DIR=$HOME/.bundle/apps

# mpi files located into MPI_DIR
MPI_DIR=$HOME/.bundle/BUNDLE/MPI

# bundle copied into UPLOAD_DIR
if [ "$UPLOAD_DIR_ARG" == "" ]; then
  UPLOAD_DIR=$HOME/.bundle/uploads
else
  UPLOAD_DIR=$UPLOAD_DIR_ARG
fi

INSTALLDIR=FDS/FDS6
errlog=/tmp/errlog.$$

if [ "`uname`" == "Darwin" ] ; then
  platform=osx
  bundlebase=${fds_version}_${smv_version}_${NIGHTLY}osx
else
  platform=linux
  bundlebase=${fds_version}_${smv_version}_${NIGHTLY}lnx
fi
custombase=${fds_version}_${smv_version}

# determine directory repos reside under

scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

curdir=`pwd`
cd $scriptdir/../..
REPO_ROOT=`pwd`
cd $curdir

# create upload directory if it doesn't exist

if [ ! -e $UPLOAD_DIR ]; then
  mkdir $UPLOAD_DIR
fi

# create apps directory if it doesn't exist

if [ ! -e $APPS_DIR ]; then
  mkdir $APPS_DIR
fi

# this script is called by make_bundle.sh located in bot/Bundle/fds/linux or osx

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
    echo "utarring: $FROMFILE"
    echo "    from: $FROMDIR"
    echo "      to: $TODIR"
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

# -------------------- TOMANIFESTSMV -------------------

TOMANIFESTLIST ()
{
  local prog=$1
  local desc=$2

  echo "<p><hr><p>"                 >> $MANIFEST
  if [ -e $prog ]; then
    echo "$desc is present"         >> $MANIFEST
  else
    echo "$desc is absent<br>"      >> $MANIFEST
    echo "$prog"                    >> $MANIFEST
  fi
  echo "<br>"                       >> $MANIFEST
}

# -------------------- TOMANIFESTSMV -------------------

TOMANIFESTSMV ()
{
  local prog=$1
  local desc=$2

  echo "<p><hr><p>"                 >> $MANIFEST
  if [ -e $prog ]; then
    echo "<pre>"                    >> $MANIFEST
    $prog -v                        >> $MANIFEST
    echo "</pre>"                   >> $MANIFEST
  else
    echo "$desc is absent<br>"      >> $MANIFEST
    echo "$prog"                    >> $MANIFEST
  fi
  echo "<br>"                       >> $MANIFEST
}

# -------------------- TOMANIFESTFDS -------------------

TOMANIFESTFDS ()
{
  local prog=$1
  local desc=$2

  echo "<p><hr><p>"                 >> $MANIFEST
  if [ -e $prog ]; then
    echo "<pre>"                    >> $MANIFEST
    echo "" | $prog                 >> $MANIFEST 2>&1
    echo "</pre>"                   >> $MANIFEST
  else
    echo "$desc is absent<br>"      >> $MANIFEST
    echo "$prog"                    >> $MANIFEST
  fi
  echo "<br>"                       >> $MANIFEST
}

# -------------------- TOMANIFESTMPI -------------------

TOMANIFESTMPI ()
{
  local prog=$1
  local desc=$2

  echo "<p><hr><p>"                 >> $MANIFEST
  if [ -e $prog ]; then
    echo "<pre>"                    >> $MANIFEST
    echo ""                         >> $MANIFEST
    echo $desc                      >> $MANIFEST
    $prog --version                  >> $MANIFEST 2>&1
    echo "</pre>"                   >> $MANIFEST
  else
    echo "$desc is absent<br>"      >> $MANIFEST
    echo "$prog"                    >> $MANIFEST
  fi
  echo "<br>"                       >> $MANIFEST
}

# determine OS

if [ "`uname`" == "Darwin" ]; then
  FDSOS=_osx
  OS=_osx
  PLATFORM=OSX64
else
  FDSOS=_lnx
  OS=_lnx
  PLATFORM=LINUX64
fi

bundledir=$UPLOAD_DIR/$bundlebase
smvbindir=$bundledir/smvbin
fdsbindir=$bundledir/bin

webpagesdir=$REPO_ROOT/webpages
fds_bundle=$REPO_ROOT/bot/Bundle/fds/for_bundle
smv_bundle=$REPO_ROOT/bot/Bundle/smv/for_bundle
webgldir=$REPO_ROOT/bot/Bundle/smv/for_bundle/webgl
smvscriptdir=$REPO_ROOT/smv/scripts
utilscriptdir=$REPO_ROOT/smv/Utilities/Scripts

texturedir=$smv_bundle/textures
makeinstaller=$REPO_ROOT/bot/Bundlebot/make_installer.sh

fds_cases=$REPO_ROOT/fds/Verification/FDS_Cases.sh
fds_benchamrk_cases=$REPO_ROOT/fds/Verification/FDS_Benchmark_Cases.sh
smv_cases=$REPO_ROOT/smv/Verification/scripts/SMV_Cases.sh
wui_cases=$REPO_ROOT/smv/Verification/scripts/WUI_Cases.sh
copyfdscase=$REPO_ROOT/bot/Bundle/fds/scripts/copyfdscase.sh
copycfastcase=$REPO_ROOT/bot/Bundle/fds/scripts/copycfastcase.sh
FDSExamplesDirectory=$REPO_ROOT/fds/Verification
SMVExamplesDirectory=$REPO_ROOT/smv/Verification

cd $UPLOAD_DIR
rm -rf $bundlebase

mkdir $bundledir
mkdir $bundledir/Documentation
mkdir $bundledir/Examples

mkdir $fdsbindir
mkdir $fdsbindir/hash

mkdir -p $smvbindir
mkdir -p $smvbindir/hash
mkdir $smvbindir/textures

#
# initialize manifest file
MANIFEST=$bundledir/Documentation/manifest.html
BUNDLE_DATE=`date +"%b %d, %Y - %r"`
cat << EOF > $MANIFEST
<html>

<head>
<TITLE>Manifest - $bundlebase - $BUNDLE_DATE</TITLE>
</HEAD>
<BODY BGCOLOR="#FFFFFF" >
<h2>Manifest - $bundlebase - $BUNDLE_DATE</h2>
EOF

echo ""
echo "--- smv apps ---"
echo ""

# smokeview

CP $APPS_DIR background $smvbindir background
CP $APPS_DIR smokeview  $smvbindir smokeview
CP $APPS_DIR smokediff  $smvbindir smokediff
CP $APPS_DIR smokezip   $smvbindir smokezip
CP $APPS_DIR wind2fds   $smvbindir wind2fds
CP $APPS_DIR hashfile   $smvbindir hashfile

# qpdf --empty --pages FDS_User_Guide.pdf  3-3 -- out.pdf

cat << EOF >> $MANIFEST
</body>
</html>
EOF

CURDIR=`pwd`
cd $smvbindir
$APPS_DIR/hashfile background > hash/background.sha1
$APPS_DIR/hashfile smokeview  > hash/smokeview.sha1
$APPS_DIR/hashfile smokediff  > hash/smokediff.sha1
$APPS_DIR/hashfile smokezip   > hash/smokezip.sha1
$APPS_DIR/hashfile wind2fds   > hash/wind2fds.sha1
$APPS_DIR/hashfile hashfile   > hash/hashfile.sha1
cd $CURDIR

CP $smvscriptdir jp2conv.sh $smvbindir jp2conv.sh
CPDIR $texturedir $smvbindir

# FDS 

echo ""
echo "--- fds apps/scripts ---"
echo ""
cd $fdsbindir
CP $APPS_DIR    fds       $fdsbindir fds
CP $APPS_DIR    fds2ascii $fdsbindir fds2ascii
CP $APPS_DIR    test_mpi  $fdsbindir test_mpi
CP $fds_bundle  fds.sh    $bundledir fds.sh

echo ""
echo "--- copying mpi ---"
echo ""
openmpifile=
if [ "$MPI_VERSION" == "INTEL" ]; then
  intelmpifile=INTEL${INTEL_COMP_VERSION}linux_64.tar.gz
  UNTAR $MPI_DIR $intelmpifile $fdsbindir INTEL
  MPIEXEC=$fdsbindir/INTEL/bin/mpiexec
else
  if [ "$PLATFORM" == "LINUX64" ]; then
    openmpifile=openmpi_${MPI_VERSION}_linux_64_${INTEL_COMP_VERSION}.tar.gz
  fi
  if [ "$PLATFORM" == "OSX64" ]; then
    openmpifile=openmpi_${MPI_VERSION}_osx_64_${INTEL_COMP_VERSION}.tar.gz
  fi
#  CP $MPI_DIR $openmpifile  $fdsbindir $openmpifile
  UNTAR $MPI_DIR $openmpifile $fdsbindir openmpi_64
  MPIEXEC=$fdsbindir/openmpi_64/bin/mpiexec
fi

TOMANIFESTFDS  $fdsbindir/fds        fds
TOMANIFESTMPI  $MPIEXEC              mpiexec
TOMANIFESTSMV  $smvbindir/smokeview  smokeview

TOMANIFESTSMV  $smvbindir/background background
TOMANIFESTLIST $fdsbindir/fds2ascii  fds2ascii
TOMANIFESTSMV  $smvbindir/hashfile   hashfile
TOMANIFESTSMV  $smvbindir/smokediff  smokediff
TOMANIFESTSMV  $smvbindir/smokezip   smokezip
TOMANIFESTLIST $fdsbindir/test_mpi   test_mpi
TOMANIFESTSMV  $smvbindir/wind2fds   wind2fds

CURDIR=`pwd`
cd $fdsbindir
$APPS_DIR/hashfile fds       > hash/fds.sha1
$APPS_DIR/hashfile fds2ascii > hash/fds2ascii.sha1
$APPS_DIR/hashfile test_mpi  > hash/test_mpi.sha1
cd $CURDIR

echo ""
echo "--- copying configuration files ---"
echo ""

CP $smv_bundle smokeview.ini  $smvbindir smokeview.ini
CP $smv_bundle volrender.ssf  $smvbindir volrender.ssf
CP $smv_bundle objects.svo    $smvbindir objects.svo
CP $smv_bundle smokeview.html $smvbindir smokeview.html

# smokeview to html conversion scripts

CP $webgldir      runsmv_ssh.sh $smvbindir runsmv_ssh.sh
CP $webgldir      smv2html.sh   $smvbindir smv2html.sh

if [ "$PLATFORM" == "LINUX64" ]; then
  CP $utilscriptdir slice2html.sh   $smvbindir slice2html.sh
  CP $utilscriptdir slice2mp4.sh    $smvbindir slice2mp4.sh
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

echo ""
echo "--- copying release notes ---"
echo ""

CP $webpagesdir FDS_Release_Notes.htm $bundledir/Documentation FDS_Release_Notes.html
CP $webpagesdir smv_readme.html       $bundledir/Documentation SMV_Release_Notes.html

export OUTDIR=$bundledir/Examples
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
rm -rf $UPLOAD_DIR/$bundlebase.tar
rm -rf $UPLOAD_DIR/$bundlebase.tar.gz
cd $UPLOAD_DIR/$bundlebase
tar cf ../$bundlebase.tar --exclude='*.csv' .
echo Compressing archive
gzip    ../$bundlebase.tar
echo Creating installer
cd ..
bundlepathdir=`pwd`
bundlepath=`pwd`/$bundlebase.sh

OPENMPIFILE=
if [ "$openmpifile" != "" ]; then
  OPENMPIFILE="-M $openmpifile"
fi
$makeinstaller -i $bundlebase.tar.gz -b $custombase -d $INSTALLDIR -m $MPI_VERSION $OPENMPIFILE $bundlebase.sh

cat $fdsbindir/hash/*.sha1         > $bundlebase.sha1
cat $smvbindir/hash/*.sha1         > $bundlebase.sha1
$APPS_DIR/hashfile $bundlebase.sh >> $bundlebase.sha1

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
cp $MANIFEST $bundlepathdir/${bundlebase}_manifest.html
