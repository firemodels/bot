!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
  echo "Usage: revbot.sh [options] [casename.fds]"
  echo "       revbot.sh builds fds for a set of revisions found in a revision file."
  echo "       It then runs casename.fds for each fds that was built. If casename.fds"
  echo "       was not specified then only the fdss are built. The revision file"
  echo "       is generated using the script get_revisions.sh.  git checkout revisions"
  echo "       are performed on a copy of the fds repo cloned by this script.  So revbot.sh"
  echo "       will not effect the fds repo you normally work with."
  echo ""
  echo "Options:"
  echo ""
  echo " -d dir - root directory where fdss are built [default: $TESTDIR]"
  echo " -f   - force cloning of the fds_test repo"
  echo " -F   - use existing fds_test repo"
if [ "$EMAIL" != "" ]; then
  echo " -m email_address - send results to email_address [default: $EMAIL]"
else
  echo " -m email_address - send results to email_address"
fi
  echo " -N n - specify maximum number of fdss to build [default: $MAXN]"
  echo " -n n - number of MPI processes per node used when running cases [default: 1]"
  echo " -p p - number of MPI processes used when runnng cases [default: 1] "
  echo " -r revfile - file containing list of revisions used to build fds [default: $REVISIONS]"
  echo "              The revfile is built by the get_revisions.sh script"
  echo " -h   - show this message"
  echo " -q q - name of batch queue used to build fdss and to run cases. [default: batch]"
  echo " -r repo - repo can be fds or smv. [default: $REPO}.  If smv the revbot.sh only builds"
  echo "           smokeview, it does not run or view cases"
  echo " -s   - skip the build step (fdss were built eariler)"
  echo " -T type - build fds using type dv (impi_intel_linux_64_dv) or type db (impi_intel_linux_64_db)"
  echo "           makefile entries. If -T is not specified then fds is built using the release"
  echo "           (impi_intel_linux_64) makefile entry."
  exit
}

#---------------------------------------------
#                   wait_build_end
#---------------------------------------------

wait_build_end()
{
   while          [[ `qstat -a | awk '{print $2 $4 $10}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$'` != '' ]]; do
      JOBS_REMAINING=`qstat -a | awk '{print $2 $4 $10}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$' | wc -l`
      echo "Waiting for ${JOBS_REMAINING} compilations to complete."
      sleep 30
   done
}

#---------------------------------------------
#                   wait_run_end
#---------------------------------------------

wait_run_end()
{
   while          [[ `qstat -a | awk '{print $2 $4 $10}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$'` != '' ]]; do
      JOBS_REMAINING=`qstat -a | awk '{print $2 $4 $10}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$' | wc -l`
      echo "Waiting for ${JOBS_REMAINING} cases to complete."
      sleep 30
   done
}
start_time=`date`
CURDIR=`pwd`
qopt=
REVISIONS=${REPO}_revisions.txt
MAKEENTRY=impi_intel_linux_64
CASENAME=
SKIPBUILD=
SKIPRUN=
MAXN=10
FORCECLONE=
USEEXISTING=
DEBUG=
TYPE=
popt=
nopt=
REPO=fds
SMVDEBUG=

#define bot repo location
BOTREPO=$CURDIR/../../bot
cd $BOTREPO
BOTREPO=`pwd`

EMAIL=
if [ "$REV_MAILTO" != "" ]; then
  EMAIL=$REV_MAILTO
fi

OUTPUTDIR=$CURDIR/output
TESTDIR=$CURDIR/TESTDIR
SCRIPTDIR=$BOTREPO/Scripts
SUMMARYFILE=$OUTPUTDIR/summary

cd $OUTPUTDIR
git clean -dxf >& /dev/null
cd $CURDIR

echo "" > $OUTPUTDIR/stage0
echo "" > $OUTPUTDIR/stage1
echo "" > $OUTPUTDIR/stage2

cd $CURDIR

#*** read in parameters from command line

while getopts 'd:DfFhm:n:N:p:q:r:sT:' OPTION
do
case $OPTION  in
  d)
   TESTDIR="$OPTARG"
   ;;
  D)
   DEBUG=1
   ;;
  f)
   FORCECLONE=1
   ;;
  F)
   USEEXISTING=1
   ;;
  h)
   usage
   exit
   ;;
  m)
   EMAIL="$OPTARG"
   ;;
  n)
   nopt="-n $OPTARG"
   ;;
  N)
   MAXN="$OPTARG"
   ;;
  p)
   popt="-p $OPTARG"
   ;;
  q)
   qopt="-q $OPTARG"
   ;;
  r)
   REPO="$OPTARG"
   ;;
  s)
   SKIPBUILD=1
   ;;
  T)
   TYPE="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

CASENAME=$1
ABORT=

if [[ "$REPO" != "fds" ]] && [[ "$REPO" != "smv" ]]; then
  echo "***error: this script only runs using the fds or smv repos" ]; then
  ABORT=1
fi 
if [ "$REPO" == "smv" ]; then
  SKIPRUN=1
  REVISIONS=${REPO}_revisions.txt
  if [ "$CASENAME" != "" ]; then
    echo "***warning: $CASENAME will be ignored when running this script with the smv repo"
    CASENAME=
  fi
fi

if [ "$CASENAME" == "" ]; then
  SKIPRUN=1
fi

if [ "$USEEXISTING" == "1" ]; then
  if [ "$FORCECLONE" == "1" ]; then
    echo "***error: cannot speciy both -f and -F options"
    ABORT=1
  fi
fi

#make sure only db or dv is used with the -T option with fds repos
if [[ "$REPO" == "fds" ]] && [[ "$TYPE" != "" ]]; then
  if [[ "$TYPE" != "dv" ]] && [[ "$TYPE" != "db" ]]; then
    echo "***error: only dv or db can be specified with the -T option"
    echo            "when the using the fds repo"
    TYPE=
    ABORT=1
  fi
fi

#make sure only db used with the -T option with smv repos
if [[ "$REPO" == "smv" ]] && [[ "$TYPE" != "" ]]; then
  if [[ "$TYPE" != "db" ]]; then
    echo "***error: only db can be specified with the -T option"
    echo "          when using the smv repo"
    TYPE=
    ABORT=1
  fi
fi

if [ "$REPO" == "fds" ]; then
  if [ "$TYPE" == "dv" ]; then
    MAKEENTRY=impi_intel_linux_64_dv
  fi
  if [ "$TYPE" == "db" ]; then
    MAKEENTRY=impi_intel_linux_64_db
  fi
  BUILDDIR=Build/$MAKEENTRY
fi
if [ "$REPO" == "smv" ]; then
  MAKEENTRY=intel_linux_64
  BUILDDIR=Build/smokeview/$MAKEENTRY
  if [ "$TYPE" == "db" ]; then
    SMVDEBUG="-D"
  fi
fi

# make sure revision file exists
if [ ! -e $REVISIONS  ]; then
  echo "***error: revision file, $REVISIONS, does not exist"
  ABORT=1
else
  NL=`cat $REVISIONS | wc -l`
  if [ $NL -gt $MAXN ]; then
    echo "***error: number of entries=$NL in $REVISIONS greater than $MAXN."
    echo "          Either specify a larger number with -n or"
    echo "          reduce the number of entries in $REVISIONS ."
    ABORT=1
  fi
fi

# make sure test directory exists
if [ ! -d $TESTDIR ]; then
  mkdir $TESTDIR
  if [ ! -d $TESTDIR ]; then
    echo "***error: failed to create directory $TESTDIR"
    ABORT=1
  fi
fi

# if casename.fds is specified, make sure it exists
if [ "$CASENAME" != "" ]; then
  if [ ! -e $CASENAME ]; then
    echo "***error: The fds input file, $CASENAME, does not exist"
    ABORT=1
  fi
fi

if [ "$CASENAME" != "" ]; then
  CASE=${CASENAME%.*}
  BASECASENAME=`basename $CASENAME`
fi

#abort script if any of the above tests failed
if [ "$ABORT" != "" ]; then
  exit
fi

# make sure test fds repo exists
TESTREPO=$CURDIR/../../${REPO}_test

if [ -d $TESTREPO ]; then
  cd $TESTREPO
  TESTREPO=`pwd`
  if [ "$USEEXISTING" == "" ]; then
    if [ "$FORCECLONE" == "1" ]; then
      cd $CURDIR
      echo cloning $REPO into ${REPO}_test
      rm -rf $TESTREPO 
      cd $SCRIPTDIR
      ./setup_repos.sh -G -t -C >> $OUTPUTDIR/stage0 2>&1
      cd $CURDIR
    else
      echo "***error: The repo ${REPO}_test exists. Erase $TESTREPO"
      echo "          or use the -f option to force cloning"
      echo "          or the -F option to use the existing ${REPO}_test repo"
      ABORT=1
    fi
  fi 
else
  cd $SCRIPTDIR
  echo cloning ${REPO} into ${REPO}_test
  ./setup_repos.sh -G -t -C >> $OUTPUTDIR/stage0 2>&1
  cd $CURDIR
fi

if [ ! -d $TESTREPO ]; then
  echo "***error: The repo $TESTREPO does not exist."
  ABORT=1
fi

# make sure makefile entry exists
if [ "$REPO" == "fds" ]; then
  if [ ! -d $TESTREPO/Build/$MAKEENTRY ]; then
    echo "***error: The makefile entry $MAKEENTRY does not exist"
    ABORT=1
  fi
fi
if [ "$REPO" == "smv" ]; then
  if [ ! -d $TESTREPO/Build/smokeview/$MAKEENTRY ]; then
    echo "***error: The makefile entry $MAKEENTRY does not exist"
    ABORT=1
  fi
fi

#abort script if any of the above tests failed
if [ "$ABORT" != "" ]; then
  exit
fi

cd $TESTREPO
TESTREPO=`pwd`

cd $TESTDIR
TESTDIR=`pwd`

# generate list of commits
cd $CURDIR
COMMITS=`cat $REVISIONS | awk -F';' '{print $1}'`
count=0
JOBPREFIX=B${repo}_

#*** build fds for each revision in commit file
if [ "$SKIPBUILD" == "" ]; then
  cd $TESTDIR
  git clean -dxf >& /dev/null
  for commit in $COMMITS; do
    count=$((count+1))
    cd $TESTREPO
    git checkout master  >> $OUTPUTDIR/stage1 2>&1
    git checkout $commit >> $OUTPUTDIR/stage1 2>&1
    echo " --------------------------------------------------------------" >> $OUTPUTDIR/stage1
    echo " --------------- checking out $commit -------------------------" >> $OUTPUTDIR/stage1
    echo " --------------------------------------------------------------" >> $OUTPUTDIR/stage1
    COMMITDIR=$TESTDIR/${count}_$commit
    mkdir $COMMITDIR
    cp -r $TESTREPO/Source $COMMITDIR/Source
    cp -r $TESTREPO/Build  $COMMITDIR/Build
    cd $CURDIR
    echo ""
    DATE=`grep $commit $CURDIR/$REVISIONS | awk -F';' '{print $3}'`
    echo "building $REPO using $MAKEENTRY($commit/$DATE)"
    if [ "$DEBUG" == "" ]; then
      $CURDIR/qbuild.sh $SMVDEBUG -j $JOBPREFIX${count}_$commit -d $COMMITDIR/$BUILDDIR $qopt
    else
      echo "$CURDIR/qbuild.sh $SMVDEBUG -j $JOBPREFIX${count}_$commit -d $COMMITDIR/$BUILDDIR $qopt"
    fi
  done
  cd $TESTREPO
  echo " --------------------------------------------------------------" >> $OUTPUTDIR/stage1
  echo " --------------- checking out master  -------------------------" >> $OUTPUTDIR/stage1
  echo " --------------------------------------------------------------" >> $OUTPUTDIR/stage1
  git checkout master >> $OUTPUTDIR/stage1 2>&1
  echo ""
  wait_build_end
  build_time=`date`

  BADBUILD=
  count=0
  compiles=0
  for commit in $COMMITS; do
    count=$((count+1))
    COMMITDIR=$TESTDIR/${count}_$commit
    if [ "$REPO" == "fds" ]; then
      EXE=$COMMITDIR/$BUILDDIR/fds_$MAKEENTRY
    else
      EXE=$COMMITDIR/$BUILDDIR/smokeview_$MAKEENTRY
    fi
    if [ ! -e $EXE ]; then
      echo "***error: $EXE did not compile"
      echo "***error: $EXE did not compile" >> $OUTPUTDIR/stage1
      BADBUILD=1
    else
      compiles=$((compiles+1))
    fi
  done
  if [ "$BADBUILD" == "" ]; then
    echo "all programs were built successfully"
  fi
fi
total_compiles=$count

#run case for each fds that was built
if [ "$SKIPRUN" == "" ]; then
  echo ""
  JOBPREFIX=RFDS_
  count=0
  for commit in $COMMITS; do
    count=$((count+1))
    cd $CURDIR
    ABORT=
    COMMITDIR=$TESTDIR/${count}_$commit
    FDSEXE=$COMMITDIR/Build/$MAKEENTRY/fds_$MAKEENTRY
    if [ ! -d $COMMITDIR ]; then
      echo "***error: $COMMITDIR does not exist"
      echo "***error: $COMMITDIR does not exist" >> $OUTPUTDIR/stage2
      ABORT=1
    fi
    if [ ! -e $FDSEXE ]; then
      if [ -d $COMMITDIR ]; then
        echo "***error: $FDSEXE does not exist"
        echo "***error: $FDSEXE does not exist" >> $OUTPUTDIR/stage2
      fi
      ABORT=1
    fi
    if [ "$ABORT" == "" ]; then
      cp $CASENAME $COMMITDIR/.
      cd $COMMITDIR
      DATE=`grep $commit $CURDIR/$REVISIONS | awk -F';' '{print $3}'`
      echo "running fds built using $MAKEENTRY($commit/$DATE)"
      if [ "$DEBUG" == "" ]; then
        qfds.sh -j $JOBPREFIX${count}_$commit -e $FDSEXE $BASECASENAME $popt $nopt $qopt >> $OUTPUTDIR/stage2 2>&1
      else
        echo "qfds.sh -j $JOBPREFIX${count}_$commit -e $FDSEXE $BASECASENAME $popt $nopt $qopt"
      fi
    fi
  done
  echo ""
  wait_run_end
  BADRUN=
  count=0
  runs=0
  for commit in $COMMITS; do
    count=$((count+1))
    COMMITDIR=$TESTDIR/${count}_$commit
    OUTFILE=$COMMITDIR/${CASE}.out
    IS_SUCCESS=0
    if [ -e $OUTFILE ]; then
      IS_SUCCESS=`tail -1 $OUTFILE | grep successfully | wc -l`
    fi
    if [ $IS_SUCCESS -eq 0 ]; then
      BADRUN=1
      echo "The case in $COMMITDIR failed to finish"
    else
      runs=$((runs+1))
    fi
  done
  total_runs=$count
  if [ "$BADRUN" == "" ]; then
    echo "All $CASENAME cases finished successfully"
  fi
fi
stop_time=`date`
echo "start time: $start_time "  > $SUMMARYFILE
echo "build time: $build_time " >> $SUMMARYFILE
echo " stop time: $stop_time "  >> $SUMMARYFILE
if [ "$SKIPBUILD" == "" ]; then
  echo "$compiles out of $total_compiles compiles succeeded "  >> $SUMMARYFILE
fi
if [ "$SKIPRUN" == "" ]; then
  echo "$runs out of $total_runs runs succeeded "  >> $SUMMARYFILE
fi
echo "" >> $SUMMARYFILE
grep error $OUTPUTDIR/stage0 >> $SUMMARYFILE
grep error $OUTPUTDIR/stage1 >> $SUMMARYFILE
grep error $OUTPUTDIR/stage2 >> $SUMMARYFILE
echo ""
cat $SUMMARYFILE
if [ "$EMAIL" != "" ]; then
  cat $SUMMARYFILE | mail -s "`hostname -s`: revbot summary" $EMAIL
fi
