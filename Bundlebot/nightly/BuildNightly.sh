#!/bin/bash

#---------------------------------------------
#                   GET_TIME
#---------------------------------------------

GET_TIME(){
  echo $(date +"%s")
}

#---------------------------------------------
#                   GET_DURATION
#---------------------------------------------

GET_DURATION(){
  local time_before=$1
  local time_after=$2
  local __var=$3

  DELTA_TIME=`echo $(($time_after-$time_before))`
  TIME_H=`echo $(($DELTA_TIME / 3600 ))`
  TIME_M=`echo $((($DELTA_TIME % 3600 ) / 60))`
  TIME_S=`echo $(($DELTA_TIME % 60 ))`
  if (( "$DELTA_TIME" >= 3600 )) ; then
    DIFF_TIME="${TIME_H}h ${TIME_M}m ${TIME_S}s"
  else
    if (( "$DELTA_TIME" >= 60 )) ; then
      DIFF_TIME="${TIME_M}m ${TIME_S}s"
    else
      DIFF_TIME="${TIME_S}s"
    fi
  fi
  eval ${__var}_DIFF="'${DIFF_TIME}'"
  eval ${__var}_DELTA="'${DELTA_TIME}'"
}

#---------------------------------------------
#                   USAGE
#---------------------------------------------

function USAGE {
echo ""
echo "BuildNightly.sh usage"
echo ""
echo "This script builds FDS and Smokeview apps and generates a bundle using either the"
echo "specified fds and smv repo revisions or revisions from the latest firebot pass."
echo ""
echo "Options:"
echo "-B - install bundle after it is built"
echo "-c - bundle without warning about cloning/erasing fds and smv repos"
echo "-C - build apps using current revision"
echo "-d - build debug version of smokeview"
echo "-f - force this script to run"
echo "-h - display this message"
echo "-I - only build installer, assume repos are already cloned and apps are already built"
echo "-k - kill BuildNightly.sh and all of its child processes"
if [ "$MAILTO" != "" ]; then
  echo "-m mailto - email address [default: $MAILTO]"
else
  echo "-m mailto - email address"
fi
if [ "$GH_OWNER" == "" ]; then
  GH_OWNER_LABEL=""
else
  GH_OWNER_LABEL="[default: $GH_OWNER]"
fi
if [ "$GH_REPO" == "" ]; then
  GH_REPO_LABEL=""
else
  GH_REPO_LABEL="[default: $GH_REPO]"
fi
echo "-o - specify GH_OWNER when building a bundle. $GH_OWNER_LABEL"
echo "-r - specify GH_REPO when building a bundle. $GH_REPO_LABEL"
echo "-R - clone repos naming the branch release (without -R branches"
echo "     are named nightly)"
echo "-u - upload bundle to github.com/`whoami`/test_bundles/releases/tag/FDS_TEST"
echo "-U - upload bundle to github.com/firemodels/test_bundles/releases/tag/FDS_TEST"
exit 0
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

#-------------------- start of script ---------------------------------

TIME_beg=`GET_TIME`
CURDIR=`pwd`
commands=$0

#*** define some directory locations

SCRIPTDIR=$(dirname "${commands}")
cd $SCRIPTDIR
SCRIPTDIR=`pwd`

BUNDLEDIR=$HOME/.bundle/bundles

cd ../../..
GITROOT=`pwd`

#*** determine platform script is running on

if [ "`uname`" == "Darwin" ] ; then
  PLATFORM=osx
else
  PLATFORM=lnx
fi

UPLOADBUNDLE=

#***define mpi environment used to build bundle

if [ `IS_PROGRAM_INSTALLED mpirun` -eq 0 ]; then
  echo ***error: mpi environment not defined
  exit
fi

export BUNDLE_FDSCOMPILER=intel
export BUNDLE_SMVCOMPILER=intel
export BUNDLE_MPITYPE="INTELMPI"
IS_INTEL=`mpirun --version | head -1 | grep Intel| wc -l`
if [[ "${PLATFORM}" == "osx" ]]; then
  BUNDLE_SMVCOMPILER=gnu
  if [[ $IS_INTEL -eq 0 ]]; then
    export BUNDLE_MPITYPE="OPENMPI"
  else
    echo "***error: Intel mpi not supported on a Mac"
    exit
  fi
  if [ "`uname -m`" == "arm64" ] ; then
    MPI_LABEL=_arm
    BUNDLE_FDSCOMPILER=gnu
  else
    MPI_LABEL=
    BUNDLE_FDSCOMPILER=intel
  fi
else
  if [[ $IS_INTEL -eq 0 ]]; then
    export BUNDLE_MPITYPE="OPENMPI"
    MPI_LABEL=
  else
    export BUNDLE_MPITYPE="INTELMPI"
    MPI_LABEL=
  fi
fi

OPENMPI_BIN=
INTELMPI_BIN=
if [ "${BUNDLE_MPITYPE}" == "INTELMPI" ]; then
  export INTELMPI_BIN=`dirname "$(which mpirun)"`  
fi
if [ "${BUNDLE_MPITYPE}" == "OPENMPI" ]; then
  export OPENMPI_BIN=`dirname "$(which mpirun)"`
fi

#define BUNDLE_MAILTO in .bashrc
if [ "$BUNDLE_MAILTO" != "" ]; then
  MAILTO=$BUNDLE_MAILTO
fi

#***get branch names

cd $GITROOT/bot
BOTBRANCH=`git branch --show-current`
BOTREVISION=`git describe --dirty --long`

if [ -d $GITROOT/fds ]; then
  cd $GITROOT/fds
else
  echo ***error: fds repo does not exist
  exit
fi
FDSBRANCH=`git branch --show-current`
FDSREVISION=`git describe --dirty --long`

if [ -d $GITROOT/smv ]; then
  cd $GITROOT/smv
else
  echo ***error: smv repo does not exist
  exit
fi
SMVBRANCH=`git branch --show-current`
SMVREVISION=`git describe --dirty --long`

#*** define output directory

cd $SCRIPTDIR/output
OUTPUTDIR=`pwd`
git clean -dxf

cd $SCRIPTDIR

LOCKFILE=$HOME/.bundle/bundle_lock
mkdir -p $HOME/.bundle

MAILTO=
if [ "$BUNDLE_EMAIL" != "" ]; then
  MAILTO=$BUNDLE_EMAIL
fi

PROCEED=
FORCE=
RELEASE=
BUNDLETYPE=nightly
FDS_TAG=
SMV_TAG=
INSTALL=
export TEST_VIRUS=
USE_CURRENT=
ONLY_INSTALLER=
PIDFILE=$SCRIPTDIR/BuildNightly.pid
SCAN_BUNDLE=1
SMVDBG=

#*** parse parameters

while getopts 'BcCdfhkIm:no:r:RTuU' OPTION
do
case $OPTION  in
  B)
   INSTALL="-B"
   ;;
  c)
   PROCEED=1
   ;;
  C)
   USE_CURRENT=1
   ;;
  d)
   SMVDBG=_db
   ;;
  f)
   FORCE="-f"
   ;;
  h)
   USAGE
   ;;
  I)
   ONLY_INSTALLER=1
   ;;
  k)
   if [ -e $PIDFILE ]; then
     PID=`head -1 $PIDFILE`
     echo ***killing process ID $PID and all of its child processes
     kill -9 -- -$PID
     rm -f $PIDFILE
     rm -f $LOCKFILE
   else
     echo ***warning: BuildNightly.sh is not running
   fi
   exit
   ;;
  m)
   MAILTO="$OPTARG"
   ;;
  n)
   SCAN_BUNDLE=0
   ;;
  o)
   export GH_OWNER="$OPTARG"
   ;;
  r)
   export GH_REPO="$OPTARG"
   ;;
  R)
   BUNDLETYPE=release
   ;;
  T)
   TEST_VIRUS=1
   ;;
  u)
   GHUPLOADOWNER=`whoami` 
   UPLOADBUNDLE=1
   ;;
  U)
   UPLOADBUNDLE=1
   ;;
esac
done
shift $(($OPTIND-1))

echo $$ > $PIDFILE

#*** define hash and revisions

if [ "$BUNDLETYPE" == "nightly" ]; then
  FDS_TAG=
  SMV_TAG=
  if [ "$USE_CURRENT" == "" ]; then
    $GITROOT/bot/Bundlebot/nightly/getGHfile.sh FDS_INFO.txt
  else
    $SCRIPTDIR/make_info.sh  >      FDS_INFO.txt
  fi
  FDS_HASH=`grep FDS_HASH  FDS_INFO.txt | awk '{print $2}'`
  SMV_HASH=`grep SMV_HASH  FDS_INFO.txt | awk '{print $2}'`
  FDS_REVISION=`grep FDS_REVISION  FDS_INFO.txt | awk '{print $2}'`
  SMV_REVISION=`grep SMV_REVISION  FDS_INFO.txt | awk '{print $2}'`
fi

# email address
MAILTO_ARG=$MAILTO
if [ "$MAILTO" != "" ]; then
  MAILTO="-m $MAILTO"
fi

echo ""
echo "------------------------------------------------------------"
echo "               bundle type: $BUNDLETYPE"
echo "              bot revision: $BOTREVISION/$BOTBRANCH"
echo "              fds revision: $FDSREVISION/$FDSBRANCH"
echo "              smv revision: $SMVREVISION/$SMVBRANCH"
echo "                  MPI type: ${BUNDLE_MPITYPE}"

if [ "$INTELMPI_BIN" != "" ]; then
  echo "   Intel mpi bin directory: $INTELMPI_BIN"
  if [ -e $INTELMPI_BIN/mpirun ]; then
    echo "         Intel mpi version: `$INTELMPI_BIN/mpirun -version | head -1`"
  fi
fi
echo "              fds compiler: $BUNDLE_FDSCOMPILER"
echo "        smokeview compiler: $BUNDLE_SMVCOMPILER"
if [ "$OPENMPI_BIN" != "" ]; then
  echo "     Openmpi bin directory: $OPENMPI_BIN"
  if [ -e $OPENMPI_BIN/mpirun ]; then
    echo "           Openmpi version: `$OPENMPI_BIN/mpirun -V | head -1`"
  fi
fi
if [ "$MAILTO" != "" ]; then
  echo "                     EMAIL: $MAILTO_ARG"
fi
echo "------------------------------------------------------------"
echo ""

if [ -e $LOCKFILE ]; then
  if [ "$FORCE" == "" ]; then
    echo "$0 already running."
    echo "If this is not the case, rerun using the -f option"
    exit
  fi
fi
touch $LOCKFILE

if [[ "$PROCEED" == "" ]] && [[ "$USE_CURRENT" == "" ]]; then
  echo ""
  echo "------------------------------------------------------------"
  echo "------------------------------------------------------------"
  echo "You are about to erase and then clone the fds and smv repos."
  echo "Press any key to continue or <CTRL> c to abort."
  echo "To avoid this warning, use the -c option on the command line"
  echo "------------------------------------------------------------"
  echo "------------------------------------------------------------"
  read val
fi

#*** update webpages repos

if [[ -d $GITROOT/webpages ]] && [[ "$ONLY_INSTALLER" == "" ]]; then
  echo "*** updating webpages repo"
  cd $GITROOT/webpages
  get fetch origin              > $OUTPUTDIR/update_webpages 2&>1
  git merge origin/nist-pages  >> $OUTPUTDIR/update_webpages 2&>1
fi


if [ "$ONLY_INSTALLER" == "" ]; then

#*** clone 3rd party repos

  cd $CURDIR/../../Scripts
  if [ "$USE_CURRENT" == "" ]; then
    echo "*** cloning hypre"
    ./setup_repos.sh -K hypre > $OUTPUTDIR/clone_hypre 2&>1 &
    pid_clonehypre=$!

    echo "*** cloning sundials"
    ./setup_repos.sh -K sundials > $OUTPUTDIR/clone_sundials 2&>1 &
    pid_clonesundials=$!
  fi

  cd $CURDIR
  pid_clonefds=
  pid_clonesmv=
  pid_cloneall=
  if [ "$BUNDLETYPE" == "nightly" ]; then
    if [ "$USE_CURRENT" == "" ]; then

#*** a nightly bundle - clone fds and smv repos

      echo "*** cloning fds"
      ./clone_repo.sh -F -N -r $FDS_HASH > $OUTPUTDIR/clone_fds 2&>1 &
      pid_clonefds=$!

      echo "*** cloning smv"
      ./clone_repo.sh -S -N -r $SMV_HASH > $OUTPUTDIR/clone_smv 2&>1 &
      pid_clonesmv=$!
    fi
  else

#*** a release bundle - clone all repos except for bot

    echo "*** cloning all repos "
    ./clone_all_repos.sh  $OUTPUTDIR > $OUTPUTDIR/clone_all 2&>1 &
    pid_cloneall=$!
  fi

  if [ "$pid_clonesmv" != "" ]; then
    wait $pid_clonesmv
    echo "*** smv cloned"
  fi
  if [ "$pid_cloneall" != "" ]; then
    wait $pid_cloneall
    echo all repos clone complete
  fi
  ./make_smvapps.sh $SMVDBG &
  pid_smvapps=$!

  if [ "$pid_clonehypre" != "" ]; then
    wait $pid_clonehypre
    echo "*** hypre cloned"
  fi

  if [ "$pid_clonesundials" != "" ]; then
    wait $pid_clonesundials
    echo "*** sundials cloned"
  fi

  if [ "$pid_clonefds" != "" ]; then
    wait $pid_clonefds
    echo "*** fds cloned"
  fi

  ./make_fdsapps.sh

  wait $pid_smvapps
fi

if [ "$BUNDLETYPE" != "nightly" ]; then
  FDS_TAG="$BUNDLE_FDS_TAG"
  SMV_TAG="$BUNDLE_SMV_TAG"
fi

echo $FDS_HASH     > $GITROOT/bot/Bundlebot/nightly/apps/FDS_HASH
echo $SMV_HASH     > $GITROOT/bot/Bundlebot/nightly/apps/SMV_HASH
echo $FDS_REVISION > $GITROOT/bot/Bundlebot/nightly/apps/FDS_REVISION
echo $SMV_REVISION > $GITROOT/bot/Bundlebot/nightly/apps/SMV_REVISION

cd $CURDIR

#*** define github parameters

if [ "$BUNDLETYPE" == "release" ]; then
  releasetype="release"
  GHOWNER=`whoami`
  GHUPLOADOWNER=`whoami`
else
  releasetype="nightly"
  GHOWNER=firemodels
  if [ "$GHUPLOADOWNER" == "" ]; then
    GHUPLOADOWNER=firemodels
  fi
fi


if [ "$FDS_TAG" != "" ]; then
  FDS_REVISION=$FDS_TAG
fi
if [ "$SMV_TAG" != "" ]; then
  SMV_REVISION=$SMV_TAG
fi


BUNDLE_PREFIX=
BUNDLE_PREFIX_ARG="null"
UNDERSCORE=
if [ "$BUNDLETYPE" == "nightly" ]; then
  BUNDLE_PREFIX="nightly"
  BUNDLE_PREFIX_ARG="nightly"
  UNDERSCORE=_
fi

return_code=0
error_log=$SCRIPTDIR/output/error_nightly.log
./copy_pubs.sh fds $releasetype $SCRIPTDIR/pubs $GHOWNER $error_log || return_code=1
./copy_pubs.sh smv $releasetype $SCRIPTDIR/pubs $GHOWNER $error_log || return_code=1

if [ "$return_code" == "1" ]; then
  cat $error_log
  echo ""
  echo "bundle generation aborted"
  rm -f $LOCKFILE
  exit 1
fi

#*** get fds and smv repo revision used to build apps

FDSREV=$FDS_REVISION
if [ "$FDS_REVISION" == "" ]; then
  if [ -e $SCRIPTDIR/apps/FDS_REVISION ]; then
    FDSREV=`cat $SCRIPTDIR/apps/FDS_REVISION`
  else
    FDSREV=fdstest
  fi
fi

SMVREV=$SMV_REVISION
if [ "$SMV_REVISION" == "" ]; then
  if [ -e $SCRIPTDIR/apps/SMV_REVISION ]; then
    SMVREV=`cat $SCRIPTDIR/apps/SMV_REVISION`
  else
    SMVREV=smvtest
  fi
fi

cd ../../..
REPO_ROOT=`pwd`

cd $SCRIPTDIR
installer_base=${FDSREV}_${SMVREV}
installer_base_platform=${installer_base}_${BUNDLE_PREFIX}$UNDERSCORE${PLATFORM}${MPI_LABEL}
csvlog=${installer_base_platform}.csv
htmllog=${installer_base_platform}_manifest.html

#*** build apps, assemble bundle components, build bundle

cd $SCRIPTDIR
echo "*** building installer"
./assemble_bundle.sh $FDSREV $SMVREV ${BUNDLE_PREFIX_ARG} ${SCAN_BUNDLE} ${MPI_LABEL}
assemble_bundle_status=$?

echo "*** virus scan summary"
if [ -e $OUTPUTDIR/$csvlog ]; then
  grep -v OK$ $OUTPUTDIR/$csvlog | grep -v ^$ | grep -v SUMMARY
else
  echo virus scanner not available, bundle was not scanned
fi

#*** upload bundle

if [[ "$UPLOADBUNDLE" == "1" ]]; then
  if [[ $assemble_bundle_status -eq 0 ]]; then
    echo "*** uploading installer"
    
    FILELIST=`gh release view FDS_TEST  -R github.com/$GHUPLOADOWNER/test_bundles | grep SMV | grep FDS | grep ${PLATFORM}${MPI_LABEL} | awk '{print $2}'`
    for file in $FILELIST ; do
      gh release delete-asset FDS_TEST $file -R github.com/$GHUPLOADOWNER/test_bundles -y
    done

    echo gh release upload FDS_TEST $BUNDLEDIR/${installer_base_platform}.sh -R github.com/$GHUPLOADOWNER/test_bundles  --clobber
         gh release upload FDS_TEST $BUNDLEDIR/${installer_base_platform}.sh -R github.com/$GHUPLOADOWNER/test_bundles  --clobber
    if [ -e $OUTPUTDIR/$htmllog ]; then
      echo gh release upload FDS_TEST $OUTPUTDIR/$htmllog                       -R github.com/$GHUPLOADOWNER/test_bundles  --clobber
           gh release upload FDS_TEST $OUTPUTDIR/$htmllog                       -R github.com/$GHUPLOADOWNER/test_bundles  --clobber
    fi
    if [ "${PLATFORM}" == "lnx" ]; then
      cd $REPO_ROOT/fds
      FDS_SHORT_HASH=`git rev-parse --short HEAD`
      cd $SCRIPTDIR
      ./setreleasetitle.sh fds $FDS_SHORT_HASH $GHOWNER
    fi
  else
    echo ***error: virus detected in bundle, bundle not uploaded
  fi
fi

#*** install bundle (if option set)

LATESTBUNDLE=$BUNDLEDIR/FDS_SMV_latest_${PLATFORM}${MPI_LABEL}.sh
BUNDLEBASE=$BUNDLEDIR/${installer_base_platform}
if [ -e ${BUNDLEBASE}.sh ]; then
  rm -f  $LATESTBUNDLE
  ln -s ${BUNDLEBASE}.sh $LATESTBUNDLE
fi
cp $REPO_ROOT/bot/Bundlebot/nightly/autoinstall.txt $BUNDLEDIR/.
#don't remove bundle directory
if [ "$INSTALL" != "" ]; then
  cd $BUNDLEDIR
  cat autoinstall.txt | bash $LATESTBUNDLE >& $HOME/.bundle/bundle_lnx_nightly_install.log
fi
rm -f $LOCKFILE 
rm -f $PIDFILE
TIME_end=`GET_TIME`
GET_DURATION $TIME_beg $TIME_end TIME
echo Time: $TIME_DIFF
echo Time: $TIME_DIFF > $OUTPUTDIR/time.log

