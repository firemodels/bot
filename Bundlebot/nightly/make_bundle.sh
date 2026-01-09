#!/bin/bash
fds_version=$1
smv_version=$2
MPI_VERSION=$3
INTEL_COMP_VERSION=$4
UPLOAD_DIR_ARG=$5
NIGHTLY=$6

returncode=0
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ "$NIGHTLY" == "null" ]; then
  NIGHTLY=
fi
if [ "$NIGHTLY" != "" ]; then
  NIGHTLY="${NIGHTLY}_"
fi

# this script assumes that fds and smokeview apps have been copied into APPS_DIR
# and that fds and smokeview manuals have been copied into GUIDE_DIR

GUIDE_DIR=$SCRIPTDIR/pubs
APPS_DIR=$SCRIPTDIR/apps

# mpi files located into MPI_DIR
MPI_DIR=$HOME/.bundle/BUNDLE/MPI

# bundle copied into UPLOAD_DIR
if [ "$UPLOAD_DIR_ARG" == "" ]; then
  UPLOAD_DIR=$HOME/.bundle/uploads
else
  UPLOAD_DIR=$UPLOAD_DIR_ARG
fi

INSTALLDIR=FDS/FDS6
errlog=$SCRIPTDIR/output/errlog
scanlog=$SCRIPTDIR/output/scanlog

# determine directory repos reside under

curdir=`pwd`
cd $SCRIPTDIR/../../..
REPO_ROOT=`pwd`
cd $curdir

FDSREPODATE=`$REPO_ROOT/bot/Scripts/get_repo_info.sh $REPO_ROOT/fds 1`
FDSREPODATE=${FDSREPODATE}_
FDSREPODATE=

if [ "`uname`" == "Darwin" ] ; then
  platform=osx
  bundlebase=${fds_version}_${smv_version}_${FDSREPODATE}${NIGHTLY}osx
else
  platform=linux
  bundlebase=${fds_version}_${smv_version}_${FDSREPODATE}${NIGHTLY}lnx
fi
custombase=${fds_version}_${smv_version}

# create upload directory if it doesn't exist

if [ ! -e $UPLOAD_DIR ]; then
  mkdir $UPLOAD_DIR
fi

# create apps directory if it doesn't exist

if [ ! -e $APPS_DIR ]; then
  mkdir $APPS_DIR
fi

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
  local FROMFILE=$1
  local TODIR=$2
  local TODIR2=$3
  local ERR=
  if [ ! -e $FROMFILE ]; then
    echo "***error: $FROMFILE was not found" >> $errlog
    echo "***error: $FROMFILE was not found"
    ERR="1"
    if [ "$NOPAUSE" == "" ]; then
      read val
    fi
  else
    curdir=`pwd`
    cd $TODIR
    echo "untarring: $FROMFILE"
    echo "       to: $TODIR"
    tar xvf $FROMFILE
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

# -------------------- is_file_installed -------------------

IS_PROGRAM_INSTALLED()
{
  program=$1
  notfound=`$program -help 2>&1 | tail -1 | grep "not found" | wc -l`
  if [ "$notfound" == "1" ] ; then
    echo "***warning: $program not installed"
    return 0
  fi
  return 1
}

# -------------------- CPPUB -------------------

CPPUB ()
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
fds_bundle=$REPO_ROOT/fds/Build/for_bundle
smv_bundle=$REPO_ROOT/smv/Build/for_bundle
smvscriptdir=$REPO_ROOT/smv/scripts
utilscriptdir=$REPO_ROOT/smv/Utilities/Scripts
botscriptdir=$REPO_ROOT/bot/Scripts

colorbarsdir=$smv_bundle/colorbars
texturedir=$smv_bundle/textures
MAKEINSTALLER=$REPO_ROOT/bot/Bundlebot/nightly/make_installer.sh

fds_cases=$REPO_ROOT/fds/Verification/FDS_Cases.sh
fds_benchmark_cases=$REPO_ROOT/fds/Verification/FDS_Benchmark_Cases.sh
smv_cases=$REPO_ROOT/smv/Verification/scripts/SMV_Cases.sh
wui_cases=$REPO_ROOT/smv/Verification/scripts/WUI_Cases.sh
copyfdscase=$REPO_ROOT/bot/Bundlebot/fds/scripts/copyfdscase.sh
copycfastcase=$REPO_ROOT/bot/Bundlebot/fds/scripts/copycfastcase.sh
FDSExamplesDirectory=$REPO_ROOT/fds/Verification
SMVExamplesDirectory=$REPO_ROOT/smv/Verification

cd $UPLOAD_DIR
rm -rf $bundlebase

mkdir $bundledir
mkdir $bundledir/Documentation
mkdir $bundledir/Examples

mkdir $fdsbindir

mkdir -p $smvbindir
mkdir $smvbindir/colorbars
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
CP $APPS_DIR pnginfo    $smvbindir pnginfo
CP $APPS_DIR fds2fed    $smvbindir fds2fed
CP $APPS_DIR smokezip   $smvbindir smokezip
CP $APPS_DIR wind2fds   $smvbindir wind2fds

# qpdf --empty --pages FDS_User_Guide.pdf  3-3 -- out.pdf

cat << EOF >> $MANIFEST
</body>
</html>
EOF

CURDIR=`pwd`

CPDIR $colorbarsdir $smvbindir
CP $smvscriptdir jp2conv.sh $smvbindir jp2conv.sh
CPDIR $texturedir $smvbindir

# FDS 

echo ""
echo "--- fds apps/scripts ---"
echo ""
cd $fdsbindir
CP $APPS_DIR    fds        $fdsbindir fds
CP $APPS_DIR    fds_openmp $fdsbindir fds_openmp
CP $APPS_DIR    fds2ascii  $fdsbindir fds2ascii
CP $APPS_DIR    test_mpi   $fdsbindir test_mpi

echo ""
echo "--- copying mpi ---"
echo ""
openmpifile=
if [ "$MPI_VERSION" == "INTEL" ]; then
  intelmpifile=$MPI_DIR/INTEL${INTEL_COMP_VERSION}linux.tar.gz
  if [ "$INTELMPI_TARFILE" != "" ]; then
    intelmpifile=$INTELMPI_TARFILE
  fi
  UNTAR $intelmpifile $fdsbindir INTEL
  MPIEXEC=$fdsbindir/INTEL/bin/mpiexec
else
  if [ "$PLATFORM" == "LINUX64" ]; then
    openmpifile=$MPI_DIR/openmpi_${MPI_VERSION}_linux_${INTEL_COMP_VERSION}.tar.gz
  fi
  if [ "$PLATFORM" == "OSX64" ]; then
    openmpifile=$MPI_DIR/openmpi_${MPI_VERSION}_osx_${INTEL_COMP_VERSION}.tar.gz
  fi
  if [ "$OPENMPI_TARFILE" != "" ]; then
    openmpifile=$OPENMPI_TARFILE
  fi
#  CP $MPI_DIR $openmpifile  $fdsbindir $openmpifile
  UNTAR $openmpifile $fdsbindir openmpi
  MPIEXEC=$fdsbindir/openmpi/bin/mpiexec
fi

TOMANIFESTFDS  $fdsbindir/fds        fds
TOMANIFESTMPI  $MPIEXEC              mpiexec
TOMANIFESTSMV  $smvbindir/smokeview  smokeview

TOMANIFESTSMV  $smvbindir/background background
TOMANIFESTLIST $fdsbindir/fds2ascii  fds2ascii
TOMANIFESTSMV  $smvbindir/smokediff  smokediff
TOMANIFESTSMV  $smvbindir/pnginfo    pnginfo
TOMANIFESTSMV  $smvbindir/fds2fed    fds2fed
TOMANIFESTSMV  $smvbindir/smokezip   smokezip
TOMANIFESTLIST $fdsbindir/test_mpi   test_mpi
TOMANIFESTSMV  $smvbindir/wind2fds   wind2fds

CURDIR=`pwd`

echo ""
echo "--- copying configuration files ---"
echo ""

CP $smv_bundle smokeview.ini  $smvbindir smokeview.ini
CP $smv_bundle volrender.ssf  $smvbindir volrender.ssf
CP $smv_bundle objects.svo    $smvbindir objects.svo
CP $smv_bundle smokeview.html $smvbindir smokeview.html
CP $smv_bundle .smokeview_bin $smvbindir .smokeview_bin

if [ "$PLATFORM" == "LINUX64" ]; then
  CP $utilscriptdir slice2html.sh   $smvbindir slice2html.sh
  CP $utilscriptdir slice2mp4.sh    $smvbindir slice2mp4.sh
fi

echo ""
echo "--- copying documentation ---"
echo ""
CPPUB $GUIDE_DIR FDS_Config_Management_Plan.pdf    $bundledir/Documentation
CPPUB $GUIDE_DIR FDS_Technical_Reference_Guide.pdf $bundledir/Documentation
CPPUB $GUIDE_DIR FDS_User_Guide.pdf                $bundledir/Documentation
CPPUB $GUIDE_DIR FDS_Validation_Guide.pdf          $bundledir/Documentation
CPPUB $GUIDE_DIR FDS_Verification_Guide.pdf        $bundledir/Documentation
CPPUB $GUIDE_DIR SMV_User_Guide.pdf                $bundledir/Documentation
CPPUB $GUIDE_DIR SMV_Technical_Reference_Guide.pdf $bundledir/Documentation
CPPUB $GUIDE_DIR SMV_Verification_Guide.pdf        $bundledir/Documentation

echo ""
echo "--- copying release notes ---"
echo ""

CP $webpagesdir FDS_Release_Notes.htm $bundledir/Documentation FDS_Release_Notes.html
CP $webpagesdir SMV_Release_Notes.htm $bundledir/Documentation SMV_Release_Notes.html

export OUTDIR=$bundledir/Examples
export QFDS=$copyfdscase
export RUNTFDS=$copyfdscase
export RUNCFAST=$copycfastcase

echo ""
echo "--- copying example files ---"
echo ""
cd $FDSExamplesDirectory
$fds_cases
#$fds_benchmark_cases
cd $SMVExamplesDirectory
$wui_cases
$smv_cases
rm -rf $OUTDIR/Immersed_Boundary_Method

if [ `IS_PROGRAM_INSTALLED clamscan` -eq 1 ]; then
  echo ""
  echo "--- scanning archive for viruses/malware ---"
  echo "" 
  clamscan -r $UPLOAD_DIR/$bundlebase > $scanlog 2>&1
  ninfected=`grep Infected $scanlog | awk -F: '{print $2}'`
  if [ $ninfected -neq 0 ]; then
    returncode=1
    cat $scanlog
    echo
    echo "***error: $ninfected files found with a virus and/or malware in $UPLOAD_DIR/$bundlebase"
  fi
else
  echo ***warning: bundle willl not be scanned for viruses or malware
fi

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
$MAKEINSTALLER -i $bundlebase.tar.gz -b $custombase -d $INSTALLDIR -f $fds_version -s $smv_version -m $MPI_VERSION $OPENMPIFILE $bundlebase.sh

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
echo installer located at: $bundlepath
cp $MANIFEST $bundlepathdir/${bundlebase}_manifest.html
exit $returncode
