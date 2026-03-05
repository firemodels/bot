#!/bin/bash
fds_version=$1
smv_version=$2
NIGHTLY=$3
MPITYPE=$4
LABEL=$5
scan_bundle=$6

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

UPLOAD_DIR=$HOME/.bundle/bundles

INSTALLDIR=FDS/FDS6
errlog=$SCRIPTDIR/output/errlog

# determine directory repos reside under

curdir=`pwd`
cd $SCRIPTDIR/../../..
REPO_ROOT=`pwd`
cd $curdir

if [ "`uname`" == "Darwin" ]; then
  platform=osx
  bundlebase=${fds_version}_${smv_version}_${NIGHTLY}osx$LABEL
else
  platform=linux
  bundlebase=${fds_version}_${smv_version}_${NIGHTLY}lnx$LABEL
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
  if [ "$TOFILE" == "" ]; then
    TOFILE=$FROMFILE
  fi
  if [ ! -e $FROMDIR/$FROMFILE ]; then
    echo "***error: the file $FROMFILE was not found in $FROMDIR" >> $errlog
    echo "***error: the file $FROMFILE was not found in $FROMDIR"
    ERR="1"
  else
    cp $FROMDIR/$FROMFILE $TODIR/$TOFILE
  fi
  if [ -e $TODIR/$TOFILE ]; then
    echo "      from: $FROMFILE"
    echo "        to: $TODIR/$TOFILE"
  else
    if [ "ERR" == "" ]; then
      echo "***error: $FROMFILE could not be copied from $FROMDIR to $TODIR" >> $errlog
      echo "***error: $FROMFILE could not be copied from $FROMDIR to $TODIR"
    fi
  fi
}

# -------------------- is_file_installed -------------------

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
  else
    cp $FROMDIR/$FROMFILE $TODIR/$TOFILE
  fi
  if [ -e $TODIR/$TOFILE ]; then
    echo "*** $FROMFILE copied"
  else
    if [ "$ERR" == "" ]; then
      echo "***error: $FROMFILE could not be copied to $TODIR" >> $errlog
      echo "***error: $FROMFILE could not be copied to $TODIR"
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
  else
    echo "*** copying directory"
    echo "      from:$FROMDIR"
    echo "        to:$TODIR"
    cp -r $FROMDIR $TODIR
  fi
  if [ ! -e $TODIR ]; then
    if [ "$ERR" == "" ]; then
      echo "***error: the directory $FROMDIR could not copied to $TODIR" >> $errlog
      echo "***error: the directory $FROMDIR could not copied to $TODIR"
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
  else
    echo "*** copying files"
    echo "   from: $FROMDIR to $TODIR"
    echo "     to: $TODIR"
    cp $FROMDIR/* $TODIR/.
  fi
  if [ -e $TODIR ]; then
    echo "$FROMDIR copied"
  else
    if [ "$ERR" == "" ]; then
      echo "***error: unable to copy $FROMDIR to $TODIR" >> $errlog
      echo "***error: unable to copy $FROMDIR to $TODIR"
    fi
  fi
}

# -------------------- start of script -------------------

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

mkdir -p $bundledir/Documentation
mkdir -p $bundledir/Examples

mkdir $fdsbindir

mkdir -p $smvbindir/colorbars
mkdir -p $smvbindir/textures

# smokeview apps

echo "*** copying smv app files"
FILELIST="background smokeview  smokediff  pnginfo fds2fed smokezip wind2fds"
for file in $FILELIST ; do
  CP $APPS_DIR $file $smvbindir
done

CURDIR=`pwd`

CPDIR $colorbarsdir $smvbindir
CP $smvscriptdir jp2conv.sh $smvbindir
CPDIR $texturedir $smvbindir

# FDS apps

echo "*** copying fds app files"
cd $fdsbindir
FILELIST="fds fds2ascii test_mpi"
if [ "$MPITYPE" == "INTELMPI" ]; then
  FILELIST="$FILELIST fds_openmp"
fi
for file in $FILELIST ; do
  CP $APPS_DIR $file $fdsbindir
done

echo "*** copying mpi files"
if [ "$MPITYPE" == "INTELMPI" ]; then
    mkdir -p $fdsbindir/intelmpi/bin
    mkdir -p $fdsbindir/intelmpi/lib
    mkdir -p $fdsbindir/intelmpi/prov
    echo "*** copying mpi bin files"
    FILELIST="cpuinfo hydra_bstrap_proxy hydra_nameserver hydra_pmi_proxy impi_info mpiexec mpiexec.hydra mpirun"
    for file in $FILELIST ; do
      CP ${INTELMPI_BIN} $file $fdsbindir/intelmpi/bin
    done

    PROVDIR=${INTELMPI_BIN}/../opt/mpi/libfabric/lib/prov
    if [ -d $PROVDIR ]; then
      CDIR=`pwd`
      cd $PROVDIR
      PROVDIR=`pwd`
      cd $PDIR
      echo "*** copying mpi providence files"
      FILELIST="libefa-fi.so libmlx-fi.so libpsm3-fi.so libpsmx2-fi.so librxm-fi.so libshm-fi.so libtcp-fi.so libverbs-1.12-fi.so libverbs-1.1-fi.so"
      for file in $FILELIST ; do
        CP $PROVDIR $file $fdsbindir/intelmpi/prov
      done
    else
      echo "*** error: providence directory, $PROVDIR, does not exist"
    fi
    echo "*** copying mpi shared files"
    $SCRIPTDIR/copy_shared.sh                      $fdsbindir/intelmpi/lib

    FABRICDIR=${INTELMPI_BIN}/../opt/mpi/libfabric/lib
    if [ -d $FABRICDIR ]; then
      CDIR=`pwd`
      cd $FABRICDIR
      FABRICDIR=`pwd`
      cd $CDIR
      echo "*** copying mpi fabric files"
      mkdir -p $fdsbindir/intelmpi/lib
      CP ${FABRICDIR} libfabric.so   $fdsbindir/intelmpi/lib
      CP ${FABRICDIR} libfabric.so.1 $fdsbindir/intelmpi/lib
    else
      echo "*** error: fabric directory, $FABRICDIR, does not exist"
    fi

else
  if [[ "$PLATFORM" == "OSX64" ]] && [[ -d ${OPENMPI_BIN} ]]; then
    if [ -d $fdsbindir/openmpi ]; then
      rm -r $fdsbindir/openmpi
    fi
    mkdir -p $fdsbindir/openmpi/bin
    CP ${OPENMPI_BIN}         mpirun   $fdsbindir/openmpi/bin
    CP ${OPENMPI_BIN}         prterun  $fdsbindir/openmpi/bin

    echo "*** copying mpi shared files"
    mkdir -p $fdsbindir/openmpi/lib
    $SCRIPTDIR/copy_shared.sh          $fdsbindir/openmpi/lib $fdsbindir/openmpi/bin

    echo "*** copying mpi help file"
    mkdir -p $fdsbindir/openmpi/share
    CPDIR ${OPENMPI_BIN}/../share/pmix         $fdsbindir/openmpi/share/pmix
    CPDIR ${OPENMPI_BIN}/../share/prte         $fdsbindir/openmpi/share/prte
    CPDIR ${OPENMPI_BIN}/../share/openmpi      $fdsbindir/openmpi/share/openmpi
  fi
fi

CURDIR=`pwd`

echo "*** copying configuration files"

FILELIST="smokeview.ini volrender.ssf objects.svo .smokeview_bin"
for file in $FILELIST ; do
  CP $smv_bundle $file  $smvbindir
done

if [ "$PLATFORM" == "LINUX64" ]; then
  CP $utilscriptdir slice2html.sh   $smvbindir
  CP $utilscriptdir slice2mp4.sh    $smvbindir
fi

echo "*** copying documentation"
FILELIST="FDS_Config_Management_Plan.pdf FDS_Technical_Reference_Guide.pdf FDS_User_Guide.pdf FDS_Validation_Guide.pdf FDS_Verification_Guide.pdf SMV_User_Guide.pdf SMV_Technical_Reference_Guide.pdf SMV_Verification_Guide.pdf"
for file in $FILELIST ; do
  CPPUB $GUIDE_DIR $file $bundledir/Documentation
done

echo "*** copying release notes"

CP $webpagesdir FDS_Release_Notes.htm $bundledir/Documentation FDS_Release_Notes.html
CP $webpagesdir SMV_Release_Notes.htm $bundledir/Documentation SMV_Release_Notes.html

export OUTDIR=$bundledir/Examples
export QFDS=$copyfdscase
export RUNTFDS=$copyfdscase
export RUNCFAST=$copycfastcase

echo "*** copying example files"
cd $FDSExamplesDirectory
$fds_cases
#$fds_benchmark_cases
cd $SMVExamplesDirectory
$wui_cases
$smv_cases
rm -rf $OUTDIR/Immersed_Boundary_Method

# scan for viruses

if [ "$scan_bundle" == "1" ]; then
clam_status=`IS_PROGRAM_INSTALLED clamscan`
if [ $clam_status -eq 1 ]; then
  scanlog=$SCRIPTDIR/output/${bundlebase}_log.txt
  vscanlog=$SCRIPTDIR/output/${bundlebase}.log
  htmllog=$SCRIPTDIR/output/${bundlebase}_manifest.html
  csvlog=$SCRIPTDIR/output/${bundlebase}.csv
 
  if [ "$TEST_VIRUS" != "" ]; then
    $SCRIPTDIR/gen_eicar.sh $bundledir/eicar.com
  fi

  echo "*** scanning $bundlebase for viruses/malware"
  clamscan -r $UPLOAD_DIR/$bundlebase > $scanlog 2>&1
  sed 's/.*FDS-/FDS-/' $scanlog      > $vscanlog
  echo "*** adding sha256 hashes"
  $SCRIPTDIR/add_sha256.sh $vscanlog > $csvlog
  sed -i.bak '/SCAN SUMMARY/,$d; s|FDS.*SMV[^/]*/||g'     $csvlog
  sort -f -o $csvlog $csvlog
  sed -n '/SCAN SUMMARY/,$p' $vscanlog >> $csvlog
  $SCRIPTDIR/csv2html.sh                                  $csvlog
  if [ -e $SCRIPTDIR/output/${bundlebase}_manifest.html ]; then
    CP $SCRIPTDIR/output ${bundlebase}_manifest.html $bundledir/Documentation Manifest.html
  fi
  ninfected=`grep 'Infected files' $vscanlog | awk -F: '{print $2}'`
  if [ "$ninfected" == "" ]; then
    ninfected=0
  fi
  if [[ $ninfected -eq 0 ]]; then
    echo "*** no viruses found in $UPLOAD_DIR/$bundlebase"
  else
    returncode=1
    echo "***error: $ninfected files found with a virus and/or malware in $UPLOAD_DIR/$bundlebase"
  fi
else
  echo "***warning: clamscan not found"
  echo "***         bundle will not be scanned for viruses or malware"
fi
fi

echo "*** building bundle"
rm -rf $UPLOAD_DIR/$bundlebase.tar
rm -rf $UPLOAD_DIR/$bundlebase.tar.gz
cd $UPLOAD_DIR
tar cf $bundlebase.tar --exclude='*.csv' $bundlebase
echo "*** compressing bundle"
gzip    $bundlebase.tar
echo "*** creating installer"
bundlepathdir=`pwd`
bundlepath=`pwd`/$bundlebase.sh

$MAKEINSTALLER -i $bundlebase.tar.gz -b $custombase -d $INSTALLDIR -f $fds_version -s $smv_version $bundlebase.sh

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
echo "*** installer located at: $bundlepath"
exit $returncode
