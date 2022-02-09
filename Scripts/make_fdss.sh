#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
  echo "Usage: makefdss.sh [-d dir ][-q queue]"
  echo ""
  echo "qbuild.sh builds FDS"
  echo ""
  echo " -c casename.fds - path of fds case to run"
#  echo " -d dir - root directory where fdss are built [default: $CURDIR/TESTDIR]"
  echo " -e entry - makefile entry used to build fds [default: $MAKE]"
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
CURDIR=`pwd`
QUEUE=batch
REVISIONS=revisions.txt
MAKEENTRY=impi_intel_linux_64
TESTDIR=TESTDIR
CASENAME=
SKIPBUILD=
SKIPRUN=

#*** read in parameters from command line

while getopts 'c:d:e:hi:q:r:sS' OPTION
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
  h)
   usage
   exit
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

ABORT=
# make sure revision file exists
if [ ! -e $REVISONS  ]; then
  echo "***error: revision file, $REVISIONS, does not exist"
  ABORT=1
fi

# make sure test directory exists
if [ ! -d $TESTDIR ]; then
  mkdir $TESTDIR
  if [ ! -d $TESTDIR ]; then
    echo "***error: failed to create directory $TESTDIR"
    ABORT=1
  fi
fi


# make sure fds repo exists
FDSREPO=$CURDIR/../../fds
if [ ! -d $FDSREPO ]; then
  echo "***error: fds repo does not exist"
  ABORT=1
fi

# make sure makefile entry exists
if [ ! -d $FDSREPO/Build/$MAKE ]; then
  echo "***error: makefile entry $MAKE does not existt"
  ABORT=1
fi

# if casename.fds is specified, make sure it exists
if [ "$CASENAME" != "" ]; then
  if [ ! -e $CASENAME ]; then
    echo "***error: the fds casename, $CASENAME, does not exist"
    ABORT=1
  fi
fi
if [ "$SKIPRUN" == "" ]; then
  if [ "$CASENAME" == "" ]; then
    echo "***error: the fds casename file not specified."
    ABORT=1
  fi
fi


if [ "$ABORT" != "" ]; then
  exit
fi

# clean directory where fdss are built
cd $TESTDIR
TESTDIR=`pwd`

# generate list of commits
cd $CURDIR
COMMITS=`cat $REVISIONS | awk -F';' '{print $1}'`
count=1
JOBPREFIX=BFDS_

#*** build fds for each revision in commit file
if [ "$SKIPBUILD" == "" ]; then
cd $COMMITDIR
git clean -dxf
for commit in $COMMITS; do
  cd $FDSREPO
  git checkout master >& /dev/null
  COMMITDIR=$TESTDIR/${count}_$commit
  mkdir $COMMITDIR
  git checkout $commit >& /dev/null
  cp -r $FDSREPO/Source $COMMITDIR/Source
  cp -r $FDSREPO/Build  $COMMITDIR/Build
  rm $COMMITDIR/Build/$MAKEENTRY/*.o
  rm $COMMITDIR/Build/$MAKEENTRY/*.mod
  rm $COMMITDIR/Build/$MAKEENTRY/fds*
  cd $CURDIR
  echo ""
  echo building fds using sequence_revision: ${count}_$commit, makefile entry:  $MAKEENTRY
  ./qbuild.sh -j $JOBPREFIX${count}_$commit -d $COMMITDIR/Build/$MAKEENTRY
  count=$((count+1))
done
cd $FDSREPO
git checkout master >& /dev/null
wait_build_end
echo fdss have been built
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
    qfds.sh -j $JOBPREFIX${count}_$commit -e $FDSEXE $CASENAME
  fi
  count=$((count+1))
done
wait_run_end
echo $CASENAME cases have completed
fi
