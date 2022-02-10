#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
  echo "Usage: revbot.sh [-d dir ][-q queue]"
  echo ""
  echo "revbot"
  echo ""
  echo " -c casename.fds - path of fds case to run"
#  echo " -d dir - root directory where fdss are built [default: $CURDIR/TESTDIR]"
  echo " -f   - force cloning of the fds_test repo"
  echo " -F   - use existing fds_test repo"
  echo " -e entry - makefile entry used to build fds [default: $MAKE]"
  echo " -n n     - specify maximum number of fdss to build [default: $MAXN]"
  echo " -r revs - file containing revisions used to build fds [default: $REVISIONS]"
  echo " -h   - show this message"
  echo " -q q - name of queue used to build fdss. [default: $QUEUE]"
  echo " -s   - skip build step"
  echo " -S   - skip run cases step"
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
QUEUE=batch
REVISIONS=revisions.txt
MAKEENTRY=impi_intel_linux_64
CASENAME=
SKIPBUILD=
SKIPRUN=
MAXN=10
FORCECLONE=
USEEXISTING=

#define bot repo location
BOTREPO=$CURDIR/../../bot
cd $BOTREPO
BOTREPO=`pwd`

OUTPUTDIR=$CURDIR/output
TESTDIR=$CURDIR/TESTDIR
SCRIPTDIR=$BOTREPO/Scripts

cd $OUTPUTDIR
git clean -dxf >& /dev/null
cd $CURDIR

echo "" > $OUTPUTDIR/stage0
echo "" > $OUTPUTDIR/stage1
echo "" > $OUTPUTDIR/stage2

cd $CURDIR

#*** read in parameters from command line

while getopts 'c:d:e:fFhi:n:q:r:sS' OPTION
do
case $OPTION  in
  c)
   CASENAME="$OPTARG"
   ;;
  d)
   TESTDIR="$OPTARG"
   ;;
  e)
   MAKEENTRY="$OPTARG"
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
  n)
   MAXN="$OPTARG"
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  r)
   REVISIONS="$OPTARG"
   ;;
  s)
   SKIPBUILD=1
   ;;
  S)
   SKIPRUN=1
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$USEEXISTING" == "1" ]; then
  if [ "$FORCECLONE" == "1" ]; then
    echo "***error: cannot speciy both -f and -F options"
    usage
    exit
  fi
fi

ABORT=
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
    echo "***error: The fds casename, $CASENAME, does not exist"
    ABORT=1
  fi
fi

if [ "$CASENAME" != "" ]; then
  CASE=${CASENAME%.*}
fi

if [ "$SKIPRUN" == "" ]; then
  if [ "$CASENAME" == "" ]; then
    echo "***error: the fds casename file not specified."
    ABORT=1
  fi
fi

#abort script if any of the above tests failed
if [ "$ABORT" != "" ]; then
  exit
fi

# make sure test fds repo exists
FDSREPO=$CURDIR/../../fds_test
if [ -d $FDSREPO ]; then
  cd $FDSREPO
  FDSREPO=`pwd`
  if [ "$USEEXISTING" == "" ]; then
    if [ "$FORCECLONE" == "1" ]; then
      cd $CURDIR
      echo cloning fds into fds_test
      rm -rf $FDSREPO 
      $SCRIPTDIR/setup_repos.sh -G -t -C >> $OUTPUTDIR/stage0
    else
      echo "***error: The repo fds_test exists. Erase $FDSREPO"
      echo "          or use the -f option to force cloning"
      echo "          or the -F option to use the existing fds_test repo"
      ABORT=1
    fi
  fi 
else
  cd $CURDIR
  echo cloning fds into fds_test
  $SCRIPTDIR/setup_repos.sh -G -t -C >> $OUTPUT/stage0
fi

if [ ! -d $FDSREPO ]; then
  echo "***error: The repo $FDSREPO does not exist."
  ABORT=1
fi

# make sure makefile entry exists
if [ ! -d $FDSREPO/Build/$MAKEENTRY ]; then
  echo "***error: The makefile entry $MAKEENTRY does not existt"
  ABORT=1
fi

#abort script if any of the above tests failed
if [ "$ABORT" != "" ]; then
  exit
fi

cd $FDSREPO
FDSREPO=`pwd`

cd $CURDIR
cd $TESTDIR
TESTDIR=`pwd`

# generate list of commits
cd $CURDIR
COMMITS=`cat $REVISIONS | awk -F';' '{print $1}'`
count=1
JOBPREFIX=BFDS_

#*** build fds for each revision in commit file
if [ "$SKIPBUILD" == "" ]; then
  cd $TESTDIR
  git clean -dxf
  for commit in $COMMITS; do
    cd $FDSREPO
    git checkout master >> $OUTPUTDIR/stage1
    COMMITDIR=$TESTDIR/${count}_$commit
    mkdir $COMMITDIR
    git checkout $commit >> $OUTPUTDIR/stage1
    cp -r $FDSREPO/Source $COMMITDIR/Source
    cp -r $FDSREPO/Build  $COMMITDIR/Build
    rm -f $COMMITDIR/Build/$MAKEENTRY/*.o
    rm -f $COMMITDIR/Build/$MAKEENTRY/*.mod
    rm -f $COMMITDIR/Build/$MAKEENTRY/fds*
    cd $CURDIR
    echo ""
    DATE=`grep $commit $REVISIONS | awk -F';' '{print $3}'`
    echo "building fds using $MAKEENTRY($commit/$DATE)"
    $CURDIR/qbuild.sh -j $JOBPREFIX${count}_$commit -d $COMMITDIR/Build/$MAKEENTRY
    count=$((count+1))
  done
  cd $FDSREPO
  git checkout master >> $OUTPUTDIR/stage1
  wait_build_end

  BADBUILD=
  count=1
  for commit in $COMMITS; do
    COMMITDIR=$TESTDIR/${count}_$commit
    FDSEXE=$COMMITDIR/Build/$MAKEENTRY/fds_$MAKEENTRY
    if [ ! -e $FDSEXE ]; then
      echo "***error: $FDSEXE does not exist"
      BADBUILD=1
    fi
    count=$((count+1))
  done
  if [ "$BADBUILD" == "1" ]; then
    echo "all fdss were built successfully"
  fi
fi

#run case for each fds that was built
if [ "$SKIPRUN" == "" ]; then
  JOBPREFIX=RFDS_
  count=1
  for commit in $COMMITS; do
    cd $CURDIR
    ABORT=
    COMMITDIR=$TESTDIR/${count}_$commit
    FDSEXE=$COMMITDIR/Build/$MAKEENTRY/fds_$MAKEENTRY
    if [ ! -d $COMMITDIR ]; then
      echo "***error: $COMMITDIR does not exist"
      ABORT=1
    fi
    if [ ! -e $FDSEXE ]; then
      if [ -d $COMMITDIR ]; then
        echo "***error: $FDSEXE does not exist"
      fi
      ABORT=1
    fi
    if [ "$ABORT" == "" ]; then
      cp $CASENAME $COMMITDIR/.
      cd $COMMITDIR
      echo "running fds built using $MAKEENTRY($commit/$DATE)"
      qfds.sh -j $JOBPREFIX${count}_$commit -e $FDSEXE $CASENAME >> $OUTPUTDIR/stage2
    fi
    count=$((count+1))
  done
  wait_run_end
  BADRUN=
  count=1
  for commit in $COMMITS; do
    COMMITDIR=$TESTDIR/${count}_$commit
    OUTFILE=$COMMITDIR/${CASE}.out
    IS_SUCCESS=0
    if [ -e $OUTFILE]; then
      IS_SUCCESS=`tail -1 $OUTFILE | grep successfully | wc -l`
    fi
    if [ $IS_SUCCESS -eq 0 ]; then
      BADRUN=1
      echo "$COMMITDIR case failed tot finish"
    fi
    count=$((count+1))
  done
  if "$BADRUN" == "" ]; then
    echo "All $CASENAME cases finished successfully"
  fi
fi
stop_time=`date`
echo "start time: $start_time " 
echo " stop time: $stop_time "
