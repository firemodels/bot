#!/bin/bash

#---------------------------------------------
#                   USAGE
#---------------------------------------------

function USAGE {
  echo "Usage: clusterbot.sh "
  echo ""
  echo "clusterbot.sh - perform various checks to verify a Linux cluster is working properly. If the -q option"
  echo "                is specified, run test cases on multiple nodes. The test cases are very simple designed"
  echo "                only to verify that communication works between processes.  To run more realistic test"
  echo "                cases, use firebot or smokebot."
  echo ""
  echo " -f - override lock to force clusterbot run"
  echo " -h - display this message"
  echo " -n n - run n cases on each queue [default: $NCASES_PER_QUEUE]"
  if [ "$HAVE_CB_QUEUES" != "" ]; then
    echo " -q q - run test cases where q is one of the queues:"
    echo "        $CB_QUEUE1 $CB_QUEUE2 $CB_QUEUE3 $CB_QUEUE4 $CB_QUEUE5."
    echo "        if q=each then test cases will run using "
    echo "        each of these queues."
  else
    echo " -q q - run test cases using the queue q."
  fi
  echo " -Q  q - same as the -q option except that only test cases are run."
  echo "         Other tests are not performed."
  exit
}

#---------------------------------------------
#                   MKDIR
#---------------------------------------------

MKDIR ()
{
 local dir=$1

 if [ ! -d $dir ]; then
   echo making directory $dir
   mkdir -p $dir
 fi
 if [ ! -d $dir ]; then
   error "***error: failed to create the directory $dir"
   return 0
 fi
 return 1
}

#---------------------------------------------
#                   MAKE_DATA_DIRS
#---------------------------------------------

MAKE_DATA_DIRS()
{
  tempfile=$SCRIPTDIR/temp.$$
  touch $tempfile
  ERROR=
  if [ -e $tempfile ]; then
    rm $tempfile
    CB_DATA_DIR=$SCRIPTDIR
  else
    CB_DATA_DIR=$HOME/.clusterbot
    MKDIR $CB_DATA_DIR
  fi
  OUTPUT_DIR=$CB_DATA_DIR/output
  FDSOUTPUT_DIR=$CB_DATA_DIR/fdsoutput
  FILES_DIR=$CB_DATA_DIR/files
  MKDIR $OUTPUT_DIR
  if [ "$?" == "0" ]; then
    ERROR=1
  fi
  MKDIR $FDSOUTPUT_DIR
  if [ "$?" == "0" ]; then
    ERROR=1
  fi
  MKDIR $FILES_DIR
  if [ "$?" == "0" ]; then
    ERROR=1
  fi
  if [ "$ERROR" == "1" ]; then
    return 1
  fi
  rm -f $OUTPUT_DIR/*
  rm -f $FILES_DIR/*
  rm -f $FDSOUTPUT_DIR/*
  return 0
}

#---------------------------------------------
#                   SETUP_CLCK
#---------------------------------------------

SETUP_CLCK()
{
  out=/tmp/program.out.$$
  clck -v >& $out
  notfound=`cat $out | tail -1 | grep "not found" | wc -l`
  rm $out
  if [ "$notfound" == "1" ] ; then
    echo "***warning: cluster checker, clck, not installed or not in path"
  else
    CHECK_CLUSTER=`which clck`
  fi
  return 0
}

#---------------------------------------------
#                   CHECK_DIR_LIST
#---------------------------------------------

CHECK_DIR_LIST()
{
  local basedir=$1
  local rootdir=$2

  currentdirlist=/tmp/dirlist.$$
  ls -l $basedir/$rootdir | sed '1 d' > $currentdirlist
  
  if [ ! -d $DIRLIST/$rootdir ]; then
    cp $currentdirlist $DIRLIST/$rootdir
  fi
  
  ndiffs=`diff $DIRLIST/$rootdir $currentdirlist | wc -l`
 
  dirdate=`ls -l $DIRLIST/$rootdir | awk '{print $6" "$7" "$8}'`
  if [ "$ndiffs" == "0" ]; then
    echo "   `hostname -s`: $basedir/$rootdir contents have not changed since $dirdate"
  else
    echo "   `hostname -s`: $basedir/$rootdir contents have changed since $dirdate"
  fi
  rm $currentdirlist
}

#---------------------------------------------
#                   CHECK_DAEMON
#---------------------------------------------

CHECK_DAEMON ()
{
 local DAEMON_ARG=$1
 local ERRWARN=$2
 local CB_HOST_ARG=$3

DAEMONOUT=$FILES_DIR/daemon.out.$$

pdsh -t 2 -w $CB_HOST_ARG "ps -el | grep $DAEMON_ARG | wc -l" |&  grep -v ssh | grep -v Connection | sort >& $DAEMONOUT
DAEMONDOWN=
while read line 
do
  host=`echo $line | awk '{print $1}'`
  host=`echo $host | sed 's/.$//'`
  NDAEMON=`echo $line | awk '{print $2}'`
  if [ "$NDAEMON" == "0" ]; then
    DAEMONDOWN="$DAEMONDOWN $host"
  fi
done < $DAEMONOUT

if [ "$DAEMONDOWN" == "" ]; then
  echo "   $CB_HOST_ARG: $DAEMON_ARG running"
else
  echo "   $CB_HOST_ARG: ***$ERRWARN: $DAEMON_ARG down on $DAEMONDOWN"
  echo "      Fix: sudo pdsh -t 2 -w $CB_HOST_ARG service $DAEMON_ARG start"
fi
rm -f $DAEMONOUT
}

#---------------------------------------------
#                   ACCT_CHECK
#---------------------------------------------

ACCT_CHECK ()
{
  local file=$1
  local outdir=$2

  local CB_HOST_ARG=$3

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  FILE_OUT=$outdir/file_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/getfile.sh $file $outdir |& grep -v ssh | grep -v Connection | sort >& $FILE_OUT
  file0=`head -1 $FILE_OUT | awk '{print $2}'`

  local CURDIR=`pwd`
  cd $outdir
 
  FILEDIFF=
  while read line 
  do
    hosti=`echo $line | awk '{print $1}' | awk -F':' '{print $1}'`
    filei=`echo $line | awk '{print $2}'`
    ndiff=`diff $file0 $filei | wc -l`
    if [ "$ndiff" != "0" ]; then
      if [ "$FILEDIFF" == "" ]; then
        FILEDIFF="$hosti"
      else
        FILEDIFF="$FILEDIFF $hosti"
      fi
    fi
  done < $FILE_OUT
  cd $CURDIR

  if [ "$FILEDIFF" == "" ]; then
    echo "   $CB_HOST_ARG: $file is identical"
    return 0
  else
    echo "   $CB_HOST_ARG: ***Error: $file is different on $FILEDIFF "
    echo "         Fix: sudo passsync"
    return 1
  fi
}

#---------------------------------------------
#                   FILE_CHECK
#---------------------------------------------

FILE_CHECK ()
{
  local file=$1
  local ERRWARN=$2
  local INDENT=$3
  local outdir=$4
  local CB_HOST_ARG=$5

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  FILE_OUT=$outdir/file_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/getfile.sh $file $outdir |& grep -v ssh | grep -v Connection | sort >& $FILE_OUT
  file0=`head -1 $FILE_OUT | awk '{print $2}'`

  local CURDIR=`pwd`
  cd $outdir
 
  FILEDIFF=
  while read line 
  do
    hosti=`echo $line | awk '{print $1}' | awk -F':' '{print $1}'`
    filei=`echo $line | awk '{print $2}'`
    ndiff=`diff $file0 $filei | wc -l`
    if [ "$ndiff" != "0" ]; then
      if [ "$FILEDIFF" == "" ]; then
        FILEDIFF="$hosti"
      else
        FILEDIFF="$FILEDIFF $hosti"
      fi
    fi
  done < $FILE_OUT
  cd $CURDIR

  if [ "$FILEDIFF" == "" ]; then
    if [ "$INDENT" == "1" ]; then
      echo "   $CB_HOST_ARG:    $file is identical"
    else
      echo "   $CB_HOST_ARG: $file is identical"
    fi
    return 0
  else
    if [ "$INDENT" == "1" ]; then
      echo "   $CB_HOST_ARG:    ***$ERRWARN: $file is different on $FILEDIFF "
    else
      echo "   $CB_HOST_ARG: ***$ERRWARN: $file is different on $FILEDIFF "
    fi
    return 1
  fi
}

#---------------------------------------------
#                   MOUNT_CHECK
#---------------------------------------------

MOUNT_CHECK ()
{
  local INDENT=$1
  local outdir=$2
  local CB_HOST_ARG=$3

  file="NFS mounts"

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  FILE_OUT=$outdir/file_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/getmounts.sh $outdir |& grep -v ssh | grep -v Connection | sort >& $FILE_OUT
  file0=`head -1 $FILE_OUT | awk '{print $2}'`

  local CURDIR=`pwd`
  cd $outdir
 
  FILEDIFF=
  while read line 
  do
    hosti=`echo $line | awk '{print $1}' | awk -F':' '{print $1}'`
    filei=`echo $line | awk '{print $2}'`
    ndiff=`diff $file0 $filei | wc -l`
    if [ "$ndiff" != "0" ]; then
      if [ "$FILEDIFF" == "" ]; then
        FILEDIFF="$hosti"
      else
        FILEDIFF="$FILEDIFF $hosti"
      fi
    fi
  done < $FILE_OUT
  cd $CURDIR

  if [ "$FILEDIFF" == "" ]; then
    if [ "$INDENT" == "1" ]; then
       echo "   $CB_HOST_ARG:    $file are identical (df -k -t nfs)"
    else
       echo "   $CB_HOST_ARG: $file are identical (df -k -t nfs)"
    fi
    return 0
  else
    if [ "$INDENT" == "1" ]; then
       echo "   $CB_HOST_ARG:    ***Error: $file (df -k -t nfs) are different on $FILEDIFF "
    else
       echo "   $CB_HOST_ARG: ***Error: $file (df -k -t nfs) are different on $FILEDIFF "
    fi
    return 1
  fi
}

#---------------------------------------------
#                   FSTAB_CHECK
#---------------------------------------------

FSTAB_CHECK ()
{
  local outdir=$1
  local INDENT=$2
  local CB_HOST_ARG=$3

  file=/etc/fstab

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  FILE_OUT=$outdir/file_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/getfstab.sh $outdir |& grep -v ssh | grep -v Connection | sort >& $FILE_OUT
  file0=`head -1 $FILE_OUT | awk '{print $2}'`

  local CURDIR=`pwd`
  cd $outdir
 
  FILEDIFF=
  while read line 
  do
    hosti=`echo $line | awk '{print $1}' | awk -F':' '{print $1}'`
    filei=`echo $line | awk '{print $2}'`
    ndiff=`diff -w $file0 $filei | wc -l`
    if [ "$ndiff" != "0" ]; then
      if [ "$FILEDIFF" == "" ]; then
        FILEDIFF="$hosti"
      else
        FILEDIFF="$FILEDIFF $hosti"
      fi
    fi
  done < $FILE_OUT
  cd $CURDIR

  if [ "$FILEDIFF" == "" ]; then
    if [ "$INDENT" == "1" ]; then
      echo "   $CB_HOST_ARG:    $file is identical"
    else
      echo "   $CB_HOST_ARG: $file is identical"
    fi
    return 0
  else
    if [ "$INDENT" == "1" ]; then
       echo "   $CB_HOST_ARG:    ***Error: $file is different on $FILEDIFF "
    else
       echo "   $CB_HOST_ARG: ***Error: $file is different on $FILEDIFF "
    fi
    return 1
  fi
}

#---------------------------------------------
#                   HOST_CHECK
#---------------------------------------------

HOST_CHECK ()
{
  local outdir=$1
  INDENT=$2
  local CB_HOST_ARG=$3

  file=/etc/hosts

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  FILE_OUT=$outdir/hosts_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/gethost.sh $outdir |& grep -v ssh | grep -v Connection | sort >& $FILE_OUT
  file0=`head -1 $FILE_OUT | awk '{print $2}'`

  local CURDIR=`pwd`
  cd $outdir
 
  FILEDIFF=
  while read line 
  do
    hosti=`echo $line | awk '{print $1}' | awk -F':' '{print $1}'`
    filei=`echo $line | awk '{print $2}'`
    ndiff=`diff $file0 $filei | wc -l`
    if [ "$ndiff" != "0" ]; then
      if [ "$FILEDIFF" == "" ]; then
        FILEDIFF="$hosti"
      else
        FILEDIFF="$FILEDIFF $hosti"
      fi
    fi
  done < $FILE_OUT
  cd $CURDIR

  if [ "$FILEDIFF" == "" ]; then
    if [  "$INDENT" == "1" ]; then
       echo "   $CB_HOST_ARG:    $file is identical (except for entries containing localhost)"
    else
       echo "   $CB_HOST_ARG: $file is identical (except for entries containing localhost)"
    fi
    return 0
  else
    if [ "$INDENT" == "1" ]; then
       echo "   $CB_HOST_ARG:    ***Error: $file is different on $FILEDIFF "
    else
       echo "   $CB_HOST_ARG: ***Error: $file is different on $FILEDIFF "
    fi
    return 1
  fi
}

#---------------------------------------------
#                   RPM_CHECK
#---------------------------------------------

RPM_CHECK ()
{
 local INDENT=$1
 local CB_HOST_ARG=$2

if [ "$CB_HOST_ARG" == "" ]; then
  return 0
fi
rm -f $FILES_DIR/rpm*.txt
pdsh -t 2 -w $CB_HOST_ARG `pwd`/getrpms.sh $FILES_DIR >& $SLURMRPMOUT

local CURDIR=`pwd`
cd $FILES_DIR
rpm0=`ls -l rpm*.txt | head -1 | awk '{print $9}'`
host0=`echo $rpm0 | sed 's/.txt$//'`
host0=`echo $host0 | sed 's/^rpm_//'`
RPMDIFF=
for f in rpm*.txt
do
  ndiff=`diff $rpm0 $f | wc -l`
  if [ "$ndiff" != "0" ]; then
    hostdiff=`echo $f | sed 's/.txt$//'`
    hostdiff=`echo $hostdiff | sed 's/^rpm_//'`
    if [ "$RPMDIFF" == "" ]; then
      RPMDIFF="$hostdiff"
    else
      RPMDIFF="$RPMDIFF $hostdiff"
    fi
  fi
done
cd $CURDIR

if [ "$RPMDIFF" == "" ]; then
  if [ "$INDENT" == "1" ]; then
     echo "   $CB_HOST_ARG:    rpms are identical"
  else
     echo "   $CB_HOST_ARG: rpms are identical"
  fi
  return 0
else
  if [ "$INDENT" == "1" ]; then
     echo "   $CB_HOST_ARG:    ***Error: $host0 rpms are different from those on $RPMDIFF "
     echo "         Fix: reimage host or install updated rpm packages"
  else
     echo "   $CB_HOST_ARG: ***Error: $host0 rpms are different from those on $RPMDIFF "
     echo "      Fix: reimage host or install updated rpm packages"
  fi
  return 1
fi
}

#---------------------------------------------
#                   SUBNET_CHECK
#---------------------------------------------

SUBNET_CHECK ()
{
  local CB_HOST_ARG=$1
  local CB_HOSTIB_ARG=$2

  if [ "$CB_HOSTIB_ARG" == "" ]; then
    return
  fi
  if [ "$CB_HOST_ARG" == "" ]; then
    return
  fi
  ssh $CB_HOST_ARG pdsh -t 2 -w $CB_HOST_ARG,$CB_HOSTIB_ARG ps -el |& sort -u | grep opensm  >  $SUBNETOUT 2>&1
  SUB1=`cat  $SUBNETOUT | awk -F':' '{print $1}' | sort -u | awk '{printf "%s%s", $1," " }'`
  if [ "$SUB1" == "" ]; then
    echo "   $CB_HOSTIB_ARG: **Error: opensm not running on any host"
    echo "      Fix: sudo ssh $CB_HOST_ARG service opensm start   "
  else
    SUBNETCOUNT=`cat  $SUBNETOUT | awk -F':' '{print $1}' | sort -u | wc -l`
    if [ "$SUBNETCOUNT" == "1" ]; then
      echo "   $CB_HOSTIB_ARG: opensm running on $SUB1"
    else
      echo "   $CB_HOSTIB_ARG: opensm running on $SUBNETCOUNT hosts"
    fi
  fi
}

#---------------------------------------------
#                   IBSPEED
#---------------------------------------------

IBSPEED ()
{
  local CB_HOST_ARG=$1
 
  if [ "$CB_HOST_ARG" == "" ]; then
    return
  fi
  local CURDIR=`pwd`
  pdsh -t 2 -w $CB_HOST_ARG $CURDIR/ibspeed.sh |& grep -v ssh | grep -v Connection | sort >& $IBRATE
  RATE0=`head -1 $IBRATE | awk '{print $2}'`
  if [ "$RATE0" == "0" ]; then
    return
  fi
  RATEBAD=
  while read line 
  do
    host=`echo $line | awk '{print $1}' | awk -F':' '{print $1}'`
    RATEI=`echo $line | awk '{print $2}'`
    if [ "$RATEI" != "$RATE0" ]; then
      if [ "$RATEI" != "Connection" ]; then
        if [ "$RATEBAD" == "" ]; then
          RATEBAD="$host/$RATEI"
        else
          RATEBAD="$RATEBAD $host/$RATEI"
        fi
      fi
    fi
  done < $IBRATE

  if [ "$RATEBAD" == "" ]; then
    echo "   ${CB_HOST_ARG}-ib: Infiniband data rate is $RATE0 Gb/s"
  else
    echo "   ${CB_HOST_ARG}-ib: ***Warning: Infiniband data rate is $RATE0 Gb/s except on $RATEBAD"
  fi
}

#---------------------------------------------
#                   RUN_CLUSTER_CHECK
#---------------------------------------------

RUN_CLUSTER_CHECK ()
{
  local LOG=$1
  local CB_HOST_ARG=$2

  if [ "$CB_HOST_ARG" != "" ]; then
    NODEFILE=$OUTPUT_DIR/$LOG.hosts
    WARNINGFILE=$OUTPUT_DIR/${LOG}_execution_warnings.log
    OUTFILE=$OUTPUT_DIR/${LOG}.out
    RESULTSFILE=$OUTPUT_DIR/${LOG}_results.out
    pdsh -t 2 -w $CB_HOST_ARG date   >& $CLUSTEROUT
    sort $CLUSTEROUT | grep -v ssh | grep -v Connection | awk '{print $1 }' | awk -F':' '{print $1}' > $NODEFILE
    nup=`wc -l $NODEFILE`
    if [ "$nup" == "0" ]; then
      echo "   $CB_HOST_ARG: ***Error: all hosts are down - cluster checker not run"
    else
      echo "   $CB_HOST_ARG: results in `basename $RESULTSFILE` and `basename $WARNINGFILE`"
      $CHECK_CLUSTER -l error -f $NODEFILE -o $RESULTSFILE >& $OUTFILE
      if [ -e clck_execution_warnings.log ]; then
        mv clck_execution_warnings.log $WARNINGFILE
      fi
    fi
  fi
}

#---------------------------------------------
#                   PROVISION_DATE_CHECK
#---------------------------------------------

PROVISION_DATE_CHECK ()
{
  local CB_HOSTETH_ARG=$1

  if [ "$CB_HOSTETH_ARG" == "" ]; then
    return 0
  fi
  pdsh -t 2 -w $CB_HOSTETH_ARG `pwd`/getrevdate.sh |&  grep -v ssh | grep -v Connection | sort >  $FSOUT 2>&1

  NF0=`head -1 $FSOUT | awk '{print $2}'`
  FSDOWN=
  while read line 
  do
    host=`echo $line | awk '{print $1}'`
    host=`echo $host | sed 's/.$//'`
    NFI=`echo $line | awk '{print $2}'`
    if [ "$NFI" != "$NF0" ]; then
      if [ "$FSDOWN" == "" ]; then
        FSDOWN="$host/$NFI"
      else
        FSDOWN="$FSDOWN $host/$NFI"
      fi
    fi
  done < $FSOUT

  if [ "$FSDOWN" == "" ]; then
    echo "   $CB_HOSTETH_ARG: imaged on $NF0"
  else
    echo "   $CB_HOSTETH_ARG: built on $NF0 except for $FSDOWN"
  fi
}

#---------------------------------------------
#                   CORE_CHECK
#---------------------------------------------

CORE_CHECK ()
{
  local CB_HOSTETH_ARG=$1

  if [ "$CB_HOSTETH_ARG" == "" ]; then
    return 0
  fi
  pdsh -t 2 -w $CB_HOSTETH_ARG "grep cpuid /proc/cpuinfo | wc -l" |&  grep -v ssh | grep -v Connection | sort >  $FSOUT 2>&1

  NF0=`head -1 $FSOUT | awk '{print $2}'`
  FSDOWN=
  while read line 
  do
    host=`echo $line | awk '{print $1}'`
    host=`echo $host | sed 's/.$//'`
    NFI=`echo $line | awk '{print $2}'`
    if [ "$NFI" != "$NF0" ]; then
      if [ "$FSDOWN" == "" ]; then
        FSDOWN="$host/$NFI"
      else
        FSDOWN="$FSDOWN $host/$NFI"
      fi
    fi
  done < $FSOUT

  if [ "$FSDOWN" == "" ]; then
    echo "   $CB_HOSTETH_ARG: $NF0 CPU cores"
  else
    echo "   $CB_HOSTETH_ARG: ***Warning: $NF0 CPU cores except $FSDOWN"
    echo "      Fix: boot into BIOS and disable hyperthreading"
  fi
}

#---------------------------------------------
#                   MEM_DIFF
#---------------------------------------------

MEM_DIFF ()
{
  MEM1=$1
  MEM2=$2
  MIN_MEM=$3

  if [ "$MEM1" == "$MEM2" ]; then
    return 0
  fi
  if [ "$MIN_MEM" != "" ]; then
    if [ $MEM2 -gt $MIN_MEM ]; then
      return 0
    fi
  fi
  DIFF=`echo $((MEM1 - MEM2))`
  if [ "$DIFF" == "1"  ]; then
    return 0
  fi
  DIFF=`echo $((MEM2 - MEM1))`
  if [ "$DIFF" == "1"  ]; then
    return 0
  fi
  return 1
}

#---------------------------------------------
#                   MEMORY_CHECK
#---------------------------------------------

MEMORY_CHECK ()
{
  local outdir=$1
  local CB_HOST_ARG=$2
  local MIN_MEM=$3

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  MEMORY_OUT=$outdir/memory_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/getmem.sh  |& grep -v ssh | grep -v Connection | sort >& $MEMORY_OUT
  memory0=`head -1 $MEMORY_OUT | awk '{print $2}'`

  local CURDIR=`pwd`
  cd $outdir
 
  MEMORY_DIFF=
  while read line 
  do
    hosti=`echo $line | awk '{print $1}' | awk -F':' '{print $1}'`
    memoryi=`echo $line | awk '{print $2}'`
    MEM_DIFF $memory0 $memoryi $MIN_MEM
    if [ "$?" == "1" ]; then
      if [ "$MEMORY_DIFF" == "" ]; then
        MEMORY_DIFF="$hosti/$memoryi"
      else
        MEMORY_DIFF="$MEMORY_DIFF $hosti/$memoryi"
      fi
    fi
  done < $MEMORY_OUT
  cd $CURDIR

  if [ "$MEMORY_DIFF" == "" ]; then
    echo "   $CB_HOST_ARG: $memory0 MB or greater"
  else
    echo "   $CB_HOST_ARG: ***Warning: $memory0 MB or greater except on $MEMORY_DIFF "
  fi
}

#---------------------------------------------
#                   SPEED_CHECK
#---------------------------------------------

SPEED_CHECK ()
{
  local outdir=$1
  local CB_HOST_ARG=$2

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  SPEED_OUT=$outdir/speed_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/getspeed.sh  |& grep -v ssh | grep -v Connection | sort >& $SPEED_OUT
  speed0=`head -1 $SPEED_OUT | awk '{print $2}'`

  local CURDIR=`pwd`
  cd $outdir
 
  SPEED_DIFF=
  while read line 
  do
    hosti=`echo $line | awk '{print $1}' | awk -F':' '{print $1}'`
    speedi=`echo $line | awk '{print $2}'`
    if [ "$speed0" != "$speedi" ]; then
      if [ "$SPEED_DIFF" == "" ]; then
        SPEED_DIFF="$hosti/$speedi"
      else
        SPEED_DIFF="$SPEED_DIFF $hosti/$speedi"
      fi
    fi
  done < $SPEED_OUT
  cd $CURDIR

  if [ "$SPEED_DIFF" == "" ]; then
    echo "   $CB_HOST_ARG: CPU clock rate is $speed0"
  else
    echo "   $CB_HOST_ARG: ***Warning: CPU clock rate is $speed0 except on $SPEED_DIFF "
  fi
}

#---------------------------------------------
#                   IS_HOST_UP
#---------------------------------------------

IS_HOST_UP ()
{
  local ITEM=$1

  for i in $UP_ETH ; do
    if [ "$ITEM" == "$i" ]; then
      return 1
    fi
  done
  return 0
}

#---------------------------------------------
#                   GET_CHID
#---------------------------------------------

GET_CHID ()
{
  local base=$1
  local num=$2

  if [ $num -gt 99 ]; then
    CHID=$base$num
  else
    if [ $num -gt 9 ]; then
      CHID=${base}0$num
    else
      CHID=${base}00$num
    fi
  fi
  echo $CHID
}

#---------------------------------------------
#                   HAVE_JOBS_RUNNING
#---------------------------------------------

HAVE_JOBS_RUNNING ()
{
  local PREFIX=$1

  JOBS_REMAINING=`qstat -a | awk '{print $2 $4 $10}' | grep $(whoami) | grep $PREFIX | grep -v 'C$' | wc -l`
  if [ "$JOBS_REMAINING" == "0" ]; then
    return 0;
  fi
  return 1
}

#---------------------------------------------
#                   WAIT_CASES_END
#---------------------------------------------

WAIT_TEST_CASES_END()
{
  local PREFIX=$1
  local REPORT_STATUS=$2

# Scans job queue and waits for cases to end
  while          [[ `qstat -a | awk '{print $2 $4 $10}' | grep $(whoami) | grep $PREFIX | grep -v 'C$'` != '' ]]; do
    JOBS_REMAINING=`qstat -a | awk '{print $2 $4 $10}' | grep $(whoami) | grep $PREFIX | grep -v 'C$' | wc -l`
    if [ "$REPORT_STATUS" == "1" ]; then
      echo "Waiting for $JOBS_REMAINING test cases to complete."
    fi
    sleep 30
  done
}

#---------------------------------------------
#                   RUN_TEST_CASES
#---------------------------------------------

RUN_TEST_CASES ()
{
  local PREFIX=$1
  local QUEUE=$2

  local CURDIR=`pwd`

  if [ "$QUEUE" == "" ]; then
    return
  fi

# make sure we can find qfds.sh 
  QFDS=
  QFDSDIR=$SCRIPTDIR/../../fds/Utilities/Scripts
  if [ -d $QFDSDIR ]; then
    cd $QFDSDIR
    QFDS=`pwd`/qfds.sh
    if [ ! -e $QFDS ]; then
      QFDS=
    fi
    cd $CURDIR
  fi
  if [ "$QFDS" == "" ]; then
    echo "***error: qfds.sh not found, test cases not run"
    return 1
  fi
  
  cd $FDSOUTPUT_DIR
  for i in `seq 1 $NCASES_PER_QUEUE`; do
    CHID=`GET_CHID ${QUEUE}_ $i`
    ../makecase.sh $CHID $FDSOUTPUT_DIR
    $QFDS -p 24 -j $PREFIX -q $QUEUE $CHID.fds >& /dev/null
  done
  echo "   $NCASES_PER_QUEUE test cases submitted to the $QUEUE queue"
  cd $CURDIR
}

#---------------------------------------------
#                   CHECK_FDS_OUT
#---------------------------------------------

CHECK_FDS_OUT ()
{
  local PREFIX=$1
  local QUEUE=$2

  if [ "$QUEUE" == "" ]; then
    return
  fi

  local CURDIR=`pwd`

  cd $FDSOUTPUT_DIR
  FAIL=0
  for i in `seq 1 $NCASES_PER_QUEUE`; do
    CHID=`GET_CHID ${QUEUE}_ $i`
    OUTFILE=$CHID.out
    if [ -e $OUTFILE ]; then
      CHECK=`tail -10 $OUTFILE | grep successfully | wc -l`
    else
      CHECK=0
    fi
    if [ "$CHECK" == "0" ]; then
      FAIL=$((FAIL+1))
    fi
  done
  if [ "$FAIL" == "0" ]; then
    echo "$QUEUE:   all $NCASES_PER_QUEUE cases ran successfully"
  else
    echo "$QUEUE: ***error: $FAIL out of $NCASES_PER_QUEUE cases failed to run"
  fi
  cd $CURDIR
}

#---------------------------------------------
#                   CHECK_TEST_CASES
#---------------------------------------------

CHECK_TEST_CASES ()
{
  local REPORT_STATUS=$1
  echo ""
  echo "--------------------- check test cases ------------------------------"
  WAIT_TEST_CASES_END $JOBPREFIX $REPORT_STATUS
  if [ "$TEST_QUEUE" == "each" ]; then
    CHECK_FDS_OUT $JOBPREFIX $CB_QUEUE1
    CHECK_FDS_OUT $JOBPREFIX $CB_QUEUE2
    CHECK_FDS_OUT $JOBPREFIX $CB_QUEUE3
    CHECK_FDS_OUT $JOBPREFIX $CB_QUEUE4
    CHECK_FDS_OUT $JOBPREFIX $CB_QUEUE5
  else
    CHECK_FDS_OUT $JOBPREFIX $TEST_QUEUE
  fi
}

#---------------------------------------------
#                   SETUP_QUEUES
#---------------------------------------------

SETUP_QUEUES () {
  TEST_QUEUE=$1
  if [ "$TEST_QUEUE" == "each" ]; then
    if [ "$HAVE_CB_QUEUES" == "" ]; then
      echo "***error: environment variables CB_QUEUE1, CB_QUEUE2, "
      echo "          CB_QUEUE3, CB_QUEUE4 and/or CB_QUEUE5 not defined"
      echo "          use a different queue name"
      exit
    fi
  else
    sinfo | awk 'NR > 2 { print $1 }' | awk -F'*' '{print $1}' | sort -u > /tmp/queues.$$
    have_queue=`grep -w $TEST_QUEUE /tmp/queues.$$ | wc -l`
    rm /tmp/queues.$$
    if [ "$have_queue" == "0" ]; then
      echo "***error: $TEST_QUEUE is an invalid queue"
      exit
     fi
  fi
}

#************************** beginning of script ******************************************

JOBPREFIX=CB_
SCRIPTDIR=`pwd`
BIN=`dirname "$0"`
if [ "$BIN" == "." ]; then
  BIN=
fi
SCRIPTDIR=$SCRIPTDIR/$BIN

TEST_QUEUE=
HAVE_CB_QUEUES=
if [ "$CB_QUEUE1" != "" ]; then
  HAVE_CB_QUEUES=1
fi
if [ "$CB_QUEUE2" != "" ]; then
  HAVE_CB_QUEUES=1
fi
if [ "$CB_QUEUE3" != "" ]; then
  HAVE_CB_QUEUES=1
fi
if [ "$CB_QUEUE4" != "" ]; then
  HAVE_CB_QUEUES=1
fi
if [ "$CB_QUEUE5" != "" ]; then
  HAVE_CB_QUEUES=1
fi

NCASES_PER_QUEUE=20
FORCE_UNLOCK=
ONLY_RUN_TEST_CASES=

while getopts 'fhn:q:Q:' OPTION
do
case $OPTION  in
  f)
   FORCE_UNLOCK=1
   ;;
  h)
   USAGE
   exit
   ;;
  n)
   NCASES="$OPTARG"
   re='^[0-9]+$'
   if ! [[ $NCASES =~ $re ]] ; then
     echo "***error: -n "$OPTARG" not a number"
     exit
   fi 
   NCASES_PER_QUEUE=$NCASES
   ;;
  Q)
   ONLY_RUN_TEST_CASES=1
   SETUP_QUEUES $OPTARG
   ;;
  q)
   SETUP_QUEUES $OPTARG
   ;;
esac
done
shift $(($OPTIND-1))

# --------------------- make sure output directories exist  --------------------

MAKE_DATA_DIRS ||  exit

# --------------------- define file names --------------------

START_TIME=`date`
ETHOUT=$FILES_DIR/ethout.$$
CLUSTEROUT=$FILES_DIR/clusterout.$$
ETHUP=$FILES_DIR/ethup.33
CHECKEROUT=$FILES_DIR/checkerout.$$
FSOUT=$FILES_DIR/fsout.$$
MOUNTOUT=$FILES_DIR/mountout.$$
IBOUT=$FILES_DIR/ibout.$$
SUBNETOUT=$FILES_DIR/subnetout.$$
IBRATE=$FILES_DIR/ibrate.$$
SLURMOUT=$FILES_DIR/slurmout.$$
SLURMRPMOUT=$FILES_DIR/slurmrpmout.$$
DOWN_HOSTS=$FILES_DIR/downhosts.$$
UP_HOSTS=$FILES_DIR/uphosts.$$
LOCK_FILE=$HOME/.clusterbot/lockfile

MKDIR $HOME/.clusterbot
MKDIR $HOME/.clusterbot/dirlist

DIRLIST=$HOME/.clusterbot/dirlist

if [[ "$FORCE_UNLOCK" == "" ]] && [[ -e $LOCK_FILE ]]; then
  echo "***error: another instance of clusterbot.sh is running"
  echo "          If this is not the case, rerun using the -f option"
  exit
fi

touch $LOCK_FILE

# --------------------- setup Intel cluster checker  --------------------

SETUP_CLCK

# --------------------- initial error checking --------------------

ERROR=
if [ "$CB_HOSTS" == "" ]; then
  ERROR=1
  echo "***error: environment variable CB_HOSTS not defined"
fi
if [ "$CB_HOST1" != "" ]; then
  if [ "$CB_HOSTIB1" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB1 must be defined if CB_HOST1 is defined"
  fi
fi
if [ "$CB_HOST2" != "" ]; then
  if [ "$CB_HOSTIB2" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB2 must be defined if CB_HOST2 is defined"
  fi
fi
if [ "$CB_HOST3" != "" ]; then
  if [ "$CB_HOSTIB3" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB3 must be defined if CB_HOST3 is defined"
  fi
fi
if [ "$CB_HOST4" != "" ]; then
  if [ "$CB_HOSTIB4" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB4 must be defined if CB_HOST4 is defined"
  fi
fi
if [ "$ERROR" == "1" ]; then
  exit
fi

# --------------------- run fds test cases --------------------
# (check that they finished ok at the end of the script)

if [ "$ONLY_RUN_TEST_CASES" != "1" ]; then
  echo
  echo "---------- $CB_HOSTS status - `date` ----------"
fi
if [ "$TEST_QUEUE" != "" ]; then
  echo ""
  echo "--------------------- submitting test cases ------------------------------"
  HAVE_JOBS_RUNNING $JOBPREFIX
  if [ "$?" == "1" ]; then
    echo "***error: clusterbot cases are still running"
    echo "          kill these cases or start clusterbot again WITHOUT the -q option"
    exit
  fi
  if [ "$TEST_QUEUE" == "each" ]; then
    RUN_TEST_CASES $JOBPREFIX $CB_QUEUE1
    RUN_TEST_CASES $JOBPREFIX $CB_QUEUE2
    RUN_TEST_CASES $JOBPREFIX $CB_QUEUE3
    RUN_TEST_CASES $JOBPREFIX $CB_QUEUE4
    RUN_TEST_CASES $JOBPREFIX $CB_QUEUE5
  else
    RUN_TEST_CASES $JOBPREFIX $TEST_QUEUE
  fi
fi
if [ "$ONLY_RUN_TEST_CASES" == "1" ]; then
  CHECK_TEST_CASES $ONLY_RUN_TEST_CASES
  STOP_TIME=`date`
  echo ""
  echo "--------------------- clusterbot complete ------------------------------"
  echo "start time: $START_TIME"
  echo "stop time: $STOP_TIME"

  rm $LOCK_FILE
  exit
fi

echo ""
echo "--------------------- network checks --------------------------"
# --------------------- check ethernet --------------------

pdsh -t 2 -w $CB_HOSTS date   >& $ETHOUT
ETHDOWN=`sort $ETHOUT | grep -E 'timed|refused|route' | awk -F':' '{print $1}' | awk '{printf "%s ", $1}'`

if [ "$ETHDOWN" == "" ]; then
  echo "   $CB_HOSTS: Ethernet up"
else
  echo "   $CB_HOSTS: ***Warning: Ethernet down on $ETHDOWN"
fi

# --------------------- check infiniband --------------------

rm -rf $IBOUT
touch $IBOUT
if [[ "$CB_HOST1" != "" ]] && [[ $CB_HOSTIB1 != "" ]]; then
  ssh $CB_HOST1 pdsh -t 2 -w $CB_HOSTIB1 date  >>  $IBOUT 2>&1
fi
if [[ "$CB_HOST2" != "" ]] && [[ $CB_HOSTIB2 != "" ]]; then
  ssh $CB_HOST2 pdsh -t 2 -w $CB_HOSTIB2 date  >>  $IBOUT 2>&1
fi
if [[ "$CB_HOST3" != "" ]] && [[ $CB_HOSTIB3 != "" ]]; then
  ssh $CB_HOST3 pdsh -t 2 -w $CB_HOSTIB3 date  >>  $IBOUT 2>&1
fi
if [[ "$CB_HOST4" != "" ]] && [[ $CB_HOSTIB4 != "" ]]; then
  ssh $CB_HOST4 pdsh -t 2 -w $CB_HOSTIB4 date  >>  $IBOUT 2>&1
fi
IBDOWN=`grep -E 'timed|refused|route'  $IBOUT | grep out | sort | awk -F':' '{print $1}' | awk '{printf "%s ", $1}'`

if [ `cat $IBOUT | wc -l` -ne 0 ]; then
  if [ "$IBDOWN" == "" ]; then
    echo "   $CB_HOSTS: Infiniband up"
  else
    echo "   $CB_HOSTS: ***Warning: Infiniband down on $IBDOWN"
  fi
fi

# --------------------- check for hosts with working ethernet, non-working infiniband  --------------------

UP_ETH=` pdsh -t 2 -w $CB_HOSTS   date |& grep -v ssh  | grep -v Connection | awk -F':' '{print $1}' | sort` 

IB_LIST=
if [ "$IBDOWN" != "" ]; then
  for h in $IBDOWN ; do
    suffix=-ib
    h=${h%$suffix}
    IS_HOST_UP $h
    if [ "$?" == "1" ]; then
      if [ "$IB_LIST" == "" ]; then
        IB_LIST="$h"
      else
        IB_LIST="$IB_LIST $h"
      fi
    fi
  done
fi
if [ "$IB_LIST" != "" ]; then
  echo "   $CB_HOSTS: ***Error: ethernet up and infiniband down on $IB_LIST"
fi

# --------------------- check infiniband subnet manager --------------------
echo ""
echo "--------------------- infiniband checks -----------------------"

SUBNET_CHECK $CB_HOST1 $CB_HOSTIB1
SUBNET_CHECK $CB_HOST2 $CB_HOSTIB2
SUBNET_CHECK $CB_HOST3 $CB_HOSTIB3
SUBNET_CHECK $CB_HOST4 $CB_HOSTIB4

# --------------------- infiniband speed check --------------------

echo ""
IBSPEED $CB_HOSTETH1
IBSPEED $CB_HOSTETH2
IBSPEED $CB_HOSTETH3
IBSPEED $CB_HOSTETH4

# --------------------- run cluster checker --------------------

if [ "$CHECK_CLUSTER" != "" ]; then
  echo ""
  echo "--------------------- Intel Cluster Checker -------------------"
  RUN_CLUSTER_CHECK ETH1 $CB_HOSTETH1
  RUN_CLUSTER_CHECK ETH2 $CB_HOSTETH2
  RUN_CLUSTER_CHECK ETH3 $CB_HOSTETH3
  RUN_CLUSTER_CHECK ETH4 $CB_HOSTETH4
fi

# --------------------- check provisioning date --------------------

echo ""
echo "--------------------- image date check -------------------------"
PROVISION_DATE_CHECK $CB_HOSTETH1
PROVISION_DATE_CHECK $CB_HOSTETH2
PROVISION_DATE_CHECK $CB_HOSTETH3
PROVISION_DATE_CHECK $CB_HOSTETH4

# --------------------- check number of cores --------------------

echo ""
echo "--------------------- CPU checks -------------------------"
CORE_CHECK $CB_HOSTETH1
CORE_CHECK $CB_HOSTETH2
CORE_CHECK $CB_HOSTETH3
CORE_CHECK $CB_HOSTETH4


echo ""
SPEED_CHECK $FILES_DIR $CB_HOSTETH1
SPEED_CHECK $FILES_DIR $CB_HOSTETH2
SPEED_CHECK $FILES_DIR $CB_HOSTETH3
SPEED_CHECK $FILES_DIR $CB_HOSTETH4

echo ""
echo "--------------------- memory check -------------------------"

MEMORY_CHECK $FILES_DIR $CB_HOSTETH1 $CB_MEM1
MEMORY_CHECK $FILES_DIR $CB_HOSTETH2 $CB_MEM2
MEMORY_CHECK $FILES_DIR $CB_HOSTETH3 $CB_MEM3
MEMORY_CHECK $FILES_DIR $CB_HOSTETH4 $CB_MEM4

echo ""
echo "--------------------- disk check -------------------------"

#*** check number of file systems mounted

pdsh -t 2 -w $CB_HOSTS "df -k -t nfs | tail -n +2 | wc -l" |&  grep -v ssh | grep -v Connection | sort >& $FSOUT
cat $FSOUT | awk -F':' '{print $1}' > $UP_HOSTS

NF0=`head -1 $FSOUT | awk '{print $2}'`
FSDOWN=
while read line 
do
  host=`echo $line | awk '{print $1}'`
  host=`echo $host | sed 's/.$//'`
  NFI=`echo $line | awk '{print $2}'`
  if [ "$NFI" != "$NF0" ]; then
    if [ "$FSDOWN" == "" ]; then
      FSDOWN="$host"
    else
      FSDOWN="$FSDOWN $host"
    fi
  fi
done < $FSOUT

if [ "$FSDOWN" == "" ]; then
  echo "   $CB_HOSTS: $NF0 file systems mounted"
else
  echo "   $CB_HOSTS: ***Error: $NF0 file systems not mounted on $FSDOWN"
  echo "      Fix: sudo pdsh -t 2 -w $CB_HOSTS mount -a"
fi

#*** check /etc/exports file

FILE_CHECK /etc/exports Error 0 $FILES_DIR $CB_HOSTS
if [ "$?" == "1" ]; then
  FILE_CHECK /etc/exports Error 1 $FILES_DIR $CB_HOSTETH1 
  FILE_CHECK /etc/exports Error 1 $FILES_DIR $CB_HOSTETH2 
  FILE_CHECK /etc/exports Error 1 $FILES_DIR $CB_HOSTETH3 
  FILE_CHECK /etc/exports Error 1 $FILES_DIR $CB_HOSTETH4 
fi

#*** check /etc/fstab file

FSTAB_CHECK $FILES_DIR 0 $CB_HOSTS
if [ "$?" == "1" ]; then
  FSTAB_CHECK $FILES_DIR 1 $CB_HOSTETH1 
  FSTAB_CHECK $FILES_DIR 1 $CB_HOSTETH2 
  FSTAB_CHECK $FILES_DIR 1 $CB_HOSTETH3 
  FSTAB_CHECK $FILES_DIR 1 $CB_HOSTETH4 
  echo ""
fi

MOUNT_CHECK 0 $FILES_DIR $CB_HOSTS
if [ "$?" == "1" ]; then
  MOUNT_CHECK 1 $FILES_DIR $CB_HOSTETH1 
  MOUNT_CHECK 1 $FILES_DIR $CB_HOSTETH2 
  MOUNT_CHECK 1 $FILES_DIR $CB_HOSTETH3 
  MOUNT_CHECK 1 $FILES_DIR $CB_HOSTETH4 
  echo ""
fi

echo ""
echo "--------------------- slurm checks ----------------------------"

#*** check that slurm is online
pbsnodes -l | awk '{print $1}' | sort -u  > $DOWN_HOSTS
SLURMDOWN=
while read line 
do
  host=`echo $line | awk '{print $1}'`
  if [ "$SLURMDOWN" == "" ]; then
    SLURMDOWN="$host"
  else
    SLURMDOWN="$SLURMDOWN $host"
  fi
done < $DOWN_HOSTS

if [ "$SLURMDOWN" == "" ]; then
  echo "   $CB_HOSTS: slurm online"
else
  echo "   $CB_HOSTS: ***Warning: slurm offline on $SLURMDOWN"
  echo "      Fix: sudo scontrol update nodename=HOST state=resume"
  echo "      This fix can only be applied to a HOST that is up and with"
  echo "      a working ethernet and infiniband network connection."
fi

#*** heck slurm configuration file --------------------

FILE_CHECK /etc/slurm/slurm.conf Error 0 $FILES_DIR $CB_HOSTS
if [ "$?" == "1" ]; then
  FILE_CHECK /etc/slurm/slurm.conf Error 0 $FILES_DIR $CB_HOSTETH1 
  FILE_CHECK /etc/slurm/slurm.conf Error 0 $FILES_DIR $CB_HOSTETH2 
  FILE_CHECK /etc/slurm/slurm.conf Error 0 $FILES_DIR $CB_HOSTETH3 
  FILE_CHECK /etc/slurm/slurm.conf Error 0 $FILES_DIR $CB_HOSTETH4 
  echo ""
fi

#*** check slurm daemon

CHECK_DAEMON slurmd Error $CB_HOSTS

#*** check slurm rpm

pdsh -t 2 -w $CB_HOSTS "rpm -qa | grep slurm | grep devel" |& grep -v ssh | grep -v Connection | sort >& $SLURMRPMOUT
SLURMRPM0=`head -1 $SLURMRPMOUT | awk '{print $2}'`
SLURMBAD=
while read line 
do
  host=`echo $line | awk '{print $1}' | awk -F':' '{print $1}'`
  SLURMRPMI=`echo $line | awk '{print $2}'`
  if [ "$SLURMRPMI" != "$SLURMRPM0" ]; then
    if [ "$SLURMRPMI" != "Connection" ]; then
      if [ "$SLURMBAD" == "" ]; then
        SLURMBAD="$host/$SLURMRPMI"
      else
        SLURMBAD="$SLURMBAD $host/$SLURMRPMI"
      fi
    fi
  fi
done < $SLURMRPMOUT

if [ "$SLURMBAD" == "" ]; then
  echo "   $CB_HOSTS: $SLURMRPM0 installed"
else
  echo "   $CB_HOSTS: ***Error: $SLURMRPM0 not installed on $SLURMBAD"
  echo "      Fix: ask system administrator to update slurm rpm packages"
fi

# --------------------- check daemons --------------------

echo ""
echo "--------------------- daemon check ---------------------------"

GANGLIA=`ps -el | grep gmetad`
if [ "$GANGLIA" != "" ]; then
#*** check ganglia daemon
  CHECK_DAEMON gmond Warning $CB_HOSTS
fi

CHECK_DAEMON chronyd Error $CB_HOSTS

# --------------------- rpm check --------------------

echo ""
echo "--------------------- rpm check ------------------------------"
RPM_CHECK 0 $CB_HOSTS
if [ "$?" == "1" ]; then
  RPM_CHECK 1 $CB_HOSTETH1
  RPM_CHECK 1 $CB_HOSTETH2
  RPM_CHECK 1 $CB_HOSTETH3
  RPM_CHECK 1 $CB_HOSTETH4
fi

echo ""
echo "--------------------- accounting file checks ------------------------------"
ACCT_CHECK /etc/group  $FILES_DIR $CB_HOSTS
ACCT_CHECK /etc/passwd $FILES_DIR $CB_HOSTS

echo ""
echo "--------------------- general file checks ------------------------------"

FILE_CHECK /etc/chrony.conf Error 0 $FILES_DIR $CB_HOSTS
if [ "$?" == "1" ]; then
  FILE_CHECK /etc/chrony.conf Error 1 $FILES_DIR $CB_HOSTETH1 
  FILE_CHECK /etc/chrony.conf Error 1 $FILES_DIR $CB_HOSTETH2 
  FILE_CHECK /etc/chrony.conf Error 1 $FILES_DIR $CB_HOSTETH3 
  FILE_CHECK /etc/chrony.conf Error 1 $FILES_DIR $CB_HOSTETH4 
  echo ""
fi

if [ "$GANGLIA" != "" ]; then
  FILE_CHECK /etc/ganglia/gmond.conf Warning 0 $FILES_DIR $CB_HOSTS
  if [ "$?" == "1" ]; then
    FILE_CHECK /etc/ganglia/gmond.conf Warning 1 $FILES_DIR $CB_HOSTETH1 
    FILE_CHECK /etc/ganglia/gmond.conf Warning 1 $FILES_DIR $CB_HOSTETH2 
    FILE_CHECK /etc/ganglia/gmond.conf Warning 1 $FILES_DIR $CB_HOSTETH3 
    FILE_CHECK /etc/ganglia/gmond.conf Warning 1 $FILES_DIR $CB_HOSTETH4 
    echo ""
  fi
fi

HOST_CHECK $FILES_DIR 0 $CB_HOSTS
if [ "$?" == "1" ]; then
  HOST_CHECK $FILES_DIR 1 $CB_HOSTETH1 
  HOST_CHECK $FILES_DIR 1 $CB_HOSTETH2 
  HOST_CHECK $FILES_DIR 1 $CB_HOSTETH3 
  HOST_CHECK $FILES_DIR 1 $CB_HOSTETH4 
fi

echo ""
echo "--------------------- directory content checks --------------------------"
CHECK_DIR_LIST /etc ssh
CHECK_DIR_LIST /etc slurm

if [[ "$ONLY_RUN_TEST_CASES" != "1" ]] && [[ "$TEST_QUEUE" != "" ]]; then
  CHECK_TEST_CASES 0
fi

STOP_TIME=`date`
echo ""
echo "--------------------- clusterbot complete ------------------------------"
echo "start time: $START_TIME"
echo "stop time: $STOP_TIME"

rm $LOCK_FILE
