#!/bin/bash

#---------------------------------------------
# ---------------------------- usage ----------------------------------
#---------------------------------------------

function usage {
  echo "Usage: clusterbot.sh "
  echo ""
  echo "clusterbot.sh - perform various checks on a Linux cluster"
  echo ""
  echo " -h - display this message"
  exit
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
    if [ ! -d $CB_DATA_DIR ]; then
      mkdir $CB_DATA_DIR
    fi
  fi
  OUTPUT_DIR=$CB_DATA_DIR/output
  FILES_DIR=$CB_DATA_DIR/files
  if [ ! -d $OUTPUT_DIR ]; then
    mkdir $OUTPUT_DIR
    if [ ! -d $OUTPUT_DIR ]; then
      echo "***error: failed to create the directory: $OUTPUT_DIR"
      ERROR=1
    fi
  fi
  if [ ! -d $FILES_DIR ]; then
    mkdir $FILES_DIR
    if [ ! -d $FILES_DIR ]; then
      echo "***error: failed to create the directory: $FILES_DIR"
      ERROR=1
    fi
  fi
  if [ "$ERROR" == "1" ]; then
    return 1
  fi
  rm -f $OUTPUT_DIR/*
  rm -f $FILES_DIR/*
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


SCRIPTDIR=`pwd`
BIN=`dirname "$0"`
if [ "$BIN" == "." ]; then
  BIN=
fi
SCRIPTDIR=$SCRIPTDIR/$BIN

while getopts 'h' OPTION
do
case $OPTION  in
  h)
   usage
   exit
   ;;
esac
done
shift $(($OPTIND-1))

# --------------------- make surer output directories exist  --------------------

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

echo
echo "---------- $CB_HOSTS status - `date` ----------"
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

# --------------------- check infiniband subnet manager --------------------
echo ""
echo "--------------------- infiniband checks -----------------------"

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
    echo "   $CB_HOSTIB_ARG: **Error: subnet manager (opensm) not running on any host"
    echo "      Fix: sudo ssh $CB_HOST_ARG service opensm start   "
  else
    SUBNETCOUNT=`cat  $SUBNETOUT | awk -F':' '{print $1}' | sort -u | wc -l`
    if [ "$SUBNETCOUNT" == "1" ]; then
      echo "   $CB_HOSTIB_ARG: subnet manager (opensm) running on $SUB1"
    else
      echo "   $CB_HOSTIB_ARG: subnet manager (opensm) running on $SUBNETCOUNT hosts"
    fi
  fi
}

SUBNET_CHECK $CB_HOST1 $CB_HOSTIB1
SUBNET_CHECK $CB_HOST2 $CB_HOSTIB2
SUBNET_CHECK $CB_HOST3 $CB_HOSTIB3
SUBNET_CHECK $CB_HOST4 $CB_HOSTIB4

# --------------------- check infiniband speed --------------------

IBSPEED ()
{
  local CB_HOST_ARG=$1
 
  if [ "$CB_HOST_ARG" == "" ]; then
    return
  fi
  CURDIR=`pwd`
  pdsh -t 2 -w $CB_HOST_ARG $CURDIR/ibspeed.sh |& grep -v ssh | sort >& $IBRATE
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
echo ""
IBSPEED $CB_HOSTETH1
IBSPEED $CB_HOSTETH2
IBSPEED $CB_HOSTETH3
IBSPEED $CB_HOSTETH4

# --------------------- run cluster checker --------------------

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
    sort $CLUSTEROUT | grep -v ssh | awk '{print $1 }' | awk -F':' '{print $1}' > $NODEFILE
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

if [ "$CHECK_CLUSTER" != "" ]; then
  echo ""
  echo "--------------------- Intel Cluster Checker -------------------"
  RUN_CLUSTER_CHECK ETH1 $CB_HOSTETH1
  RUN_CLUSTER_CHECK ETH2 $CB_HOSTETH2
  RUN_CLUSTER_CHECK ETH3 $CB_HOSTETH3
  RUN_CLUSTER_CHECK ETH4 $CB_HOSTETH4
fi

# --------------------- check provisioning date --------------------

PROVISION_DATE ()
{
  local CB_HOSTETH_ARG=$1

  if [ "$CB_HOSTETH_ARG" == "" ]; then
    return 0
  fi
  pdsh -t 2 -w $CB_HOSTETH_ARG `pwd`/getrevdate.sh |&  grep -v ssh | sort >  $FSOUT 2>&1

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
    echo "   $CB_HOSTETH_ARG: Systems imaged on $NF0"
  else
    echo "   $CB_HOSTETH_ARG: Systems built on $NF0 except for $FSDOWN"
  fi
}

echo ""
echo "--------------------- system build date check -------------------------"
PROVISION_DATE $CB_HOSTETH1
PROVISION_DATE $CB_HOSTETH2
PROVISION_DATE $CB_HOSTETH3
PROVISION_DATE $CB_HOSTETH4

# --------------------- check number of cores --------------------

CORE_CHECK ()
{
  local CB_HOSTETH_ARG=$1

  if [ "$CB_HOSTETH_ARG" == "" ]; then
    return 0
  fi
  pdsh -t 2 -w $CB_HOSTETH_ARG "grep cpuid /proc/cpuinfo | wc -l" |&  grep -v ssh | sort >  $FSOUT 2>&1

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

echo ""
echo "--------------------- CPU/Memory/Disk checks -------------------------"
CORE_CHECK $CB_HOSTETH1
CORE_CHECK $CB_HOSTETH2
CORE_CHECK $CB_HOSTETH3
CORE_CHECK $CB_HOSTETH4

MEM_DIFF ()
{
  MEM1=$1
  MEM2=$2

  if [ "$MEM1" == "$MEM2" ]; then
    return 0
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

# --------------------- speed check --------------------

SPEED_CHECK ()
{
  local outdir=$1
  local CB_HOST_ARG=$2

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  SPEED_OUT=$outdir/speed_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/getspeed.sh  |& grep -v ssh | sort >& $SPEED_OUT
  speed0=`head -1 $SPEED_OUT | awk '{print $2}'`

  CURDIR=`pwd`
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
    echo "   $CB_HOST_ARG: $speed0"
  else
    echo "   $CB_HOST_ARG: ***Warning: $speed0 except on $SPEED_DIFF "
  fi
}

echo ""
SPEED_CHECK $FILES_DIR $CB_HOSTETH1
SPEED_CHECK $FILES_DIR $CB_HOSTETH2
SPEED_CHECK $FILES_DIR $CB_HOSTETH3
SPEED_CHECK $FILES_DIR $CB_HOSTETH4

# --------------------- memory check --------------------

MEMORY_CHECK ()
{
  local outdir=$1
  local CB_HOST_ARG=$2

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  MEMORY_OUT=$outdir/memory_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/getmem.sh  |& grep -v ssh | sort >& $MEMORY_OUT
  memory0=`head -1 $MEMORY_OUT | awk '{print $2}'`

  CURDIR=`pwd`
  cd $outdir
 
  MEMORY_DIFF=
  while read line 
  do
    hosti=`echo $line | awk '{print $1}' | awk -F':' '{print $1}'`
    memoryi=`echo $line | awk '{print $2}'`
    MEM_DIFF $memory0 $memoryi
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
    echo "   $CB_HOST_ARG: $memory0 MB"
  else
    echo "   $CB_HOST_ARG: ***Warning: $memory0 MB except on $MEMORY_DIFF "
  fi
}

echo ""
MEMORY_CHECK $FILES_DIR $CB_HOSTETH1
MEMORY_CHECK $FILES_DIR $CB_HOSTETH2
MEMORY_CHECK $FILES_DIR $CB_HOSTETH3
MEMORY_CHECK $FILES_DIR $CB_HOSTETH4

# --------------------- check file systems --------------------

pdsh -t 2 -w $CB_HOSTS "df -k -t nfs | tail -n +2 | wc -l" |&  grep -v ssh | sort >& $FSOUT
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

echo ""
if [ "$FSDOWN" == "" ]; then
  echo "   $CB_HOSTS: $NF0 file systems mounted"
else
  echo "   $CB_HOSTS: ***Warning: $NF0 file systems not mounted on $FSDOWN"
  echo "      Fix: sudo pdsh -t 2 -w $CB_HOSTS mount -a"
fi

# --------------------- check slurm --------------------
echo ""
echo "--------------------- slurm checks ----------------------------"

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

# --------------------- check slurm daemon --------------------

CHECK_DAEMON ()
{
 local DAEMON_ARG=$1
 local CB_HOST_ARG=$2

DAEMONOUT=$FILES_DIR/daemon.out.$$

pdsh -t 2 -w $CB_HOST_ARG "ps -el | grep $DAEMON_ARG | wc -l" |&  grep -v ssh | sort >& $DAEMONOUT
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
  echo "   $CB_HOST_ARG: ***Warning: $DAEMON_ARG down on $DAEMONDOWN"
  echo "      Fix: sudo pdsh -t 2 -w $CB_HOST_ARG service $DAEMON_ARG start"
fi
rm -f $DAEMONOUT
}

# --------------------- check slurm rpm --------------------

pdsh -t 2 -w $CB_HOSTS "rpm -qa | grep slurm | grep devel" |& grep -v ssh | sort >& $SLURMRPMOUT
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
  echo "   $CB_HOSTS: ***Warning: $SLURMRPM0 not installed on $SLURMBAD"
  echo "      Fix: ask system administrator to update slurm rpm packages"
fi

# --------------------- check daemons --------------------

echo ""
echo "--------------------- daemon checks ---------------------------"

CHECK_DAEMON slurmd $CB_HOSTS

GANGLIA=`ps -el | grep gmetad`
if [ "$GANGLIA" != "" ]; then
  CHECK_DAEMON gmond $CB_HOSTS
fi

# --------------------- rpm check --------------------

RPM_CHECK ()
{
 local CB_HOST_ARG=$1

if [ "$CB_HOST_ARG" == "" ]; then
  return 0
fi
rm -f $FILES_DIR/rpm*.txt
pdsh -t 2 -w $CB_HOST_ARG `pwd`/getrpms.sh $FILES_DIR >& $SLURMRPMOUT

CURDIR=`pwd`
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
  echo "   $CB_HOST_ARG: rpms are identical"
  return 0
else
  echo "   $CB_HOST_ARG: ***Warning: $host0 rpms are different from those on $RPMDIFF "
  echo "      Fix: reimage host or install updated rpm packages"
  return 1
fi
}

echo ""
echo "--------------------- rpm checks ------------------------------"
RPM_CHECK $CB_HOSTS
if [ "$?" == "1" ]; then
  RPM_CHECK $CB_HOSTETH1
  RPM_CHECK $CB_HOSTETH2
  RPM_CHECK $CB_HOSTETH3
  RPM_CHECK $CB_HOSTETH4
fi

# --------------------- mount check --------------------

MOUNT_CHECK ()
{
  local outdir=$1
  local CB_HOST_ARG=$2
  file=file_mounts

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  FILE_OUT=$outdir/file_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/getmounts.sh $outdir |& grep -v ssh | sort >& $FILE_OUT
  file0=`head -1 $FILE_OUT | awk '{print $2}'`

  CURDIR=`pwd`
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
    echo "   $CB_HOST_ARG: $file (df -k -t nfs) are identical"
    return 0
  else
    echo "   $CB_HOST_ARG: ***Warning: $file (df -k -t nfs) are different on $FILEDIFF "
    return 1
  fi
}

# --------------------- fstab check --------------------

FSTAB_CHECK ()
{
  local outdir=$1
  local CB_HOST_ARG=$2
  file=/etc/fstab

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  FILE_OUT=$outdir/file_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/getfstab.sh $outdir |& grep -v ssh | sort >& $FILE_OUT
  file0=`head -1 $FILE_OUT | awk '{print $2}'`

  CURDIR=`pwd`
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
    echo "   $CB_HOST_ARG: $file is identical"
    return 0
  else
    echo "   $CB_HOST_ARG: ***Warning: $file is different on $FILEDIFF "
    return 1
  fi
}

# --------------------- file check --------------------

FILE_CHECK ()
{
  local file=$1
  local outdir=$2
  local CB_HOST_ARG=$3

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  FILE_OUT=$outdir/file_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/getfile.sh $file $outdir |& grep -v ssh | sort >& $FILE_OUT
  file0=`head -1 $FILE_OUT | awk '{print $2}'`

  CURDIR=`pwd`
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
    echo "   $CB_HOST_ARG: ***Warning: $file is different on $FILEDIFF "
    return 1
  fi
}

# --------------------- host check --------------------

HOST_CHECK ()
{
  local outdir=$1
  local CB_HOST_ARG=$2
  file=/etc/hosts

  if [ "$CB_HOST_ARG" == "" ]; then
    return 0
  fi
  FILE_OUT=$outdir/hosts_out
  pdsh -t 2 -w $CB_HOST_ARG `pwd`/gethost.sh $outdir |& grep -v ssh | sort >& $FILE_OUT
  file0=`head -1 $FILE_OUT | awk '{print $2}'`

  CURDIR=`pwd`
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
    echo "   $CB_HOST_ARG: $file is identical (except for entries containing localhost)"
    return 0
  else
    echo "   $CB_HOST_ARG: ***Warning: $file is different on $FILEDIFF "
    return 1
  fi
}
echo ""
echo "--------------------- file checks ------------------------------"
echo ""
FILE_CHECK /etc/exports $FILES_DIR $CB_HOSTS
if [ "$?" == "1" ]; then
  FILE_CHECK /etc/exports $FILES_DIR $CB_HOSTETH1 
  FILE_CHECK /etc/exports $FILES_DIR $CB_HOSTETH2 
  FILE_CHECK /etc/exports $FILES_DIR $CB_HOSTETH3 
  FILE_CHECK /etc/exports $FILES_DIR $CB_HOSTETH4 
  echo ""
fi

FSTAB_CHECK $FILES_DIR $CB_HOSTS
if [ "$?" == "1" ]; then
  FSTAB_CHECK $FILES_DIR $CB_HOSTETH1 
  FSTAB_CHECK $FILES_DIR $CB_HOSTETH2 
  FSTAB_CHECK $FILES_DIR $CB_HOSTETH3 
  FSTAB_CHECK $FILES_DIR $CB_HOSTETH4 
  echo ""
fi

if [ "$GANGLIA" != "" ]; then
  FILE_CHECK /etc/ganglia/gmond.conf $FILES_DIR $CB_HOSTS
  if [ "$?" == "1" ]; then
    FILE_CHECK /etc/ganglia/gmond.conf $FILES_DIR $CB_HOSTETH1 
    FILE_CHECK /etc/ganglia/gmond.conf $FILES_DIR $CB_HOSTETH2 
    FILE_CHECK /etc/ganglia/gmond.conf $FILES_DIR $CB_HOSTETH3 
    FILE_CHECK /etc/ganglia/gmond.conf $FILES_DIR $CB_HOSTETH4 
    echo ""
  fi
fi

FILE_CHECK /etc/group $FILES_DIR $CB_HOSTS
if [ "$?" == "1" ]; then
  FILE_CHECK /etc/group $FILES_DIR $CB_HOSTETH1 
  FILE_CHECK /etc/group $FILES_DIR $CB_HOSTETH2 
  FILE_CHECK /etc/group $FILES_DIR $CB_HOSTETH3 
  FILE_CHECK /etc/group $FILES_DIR $CB_HOSTETH4 
  echo ""
fi

HOST_CHECK $FILES_DIR $CB_HOSTS
if [ "$?" == "1" ]; then
  HOST_CHECK $FILES_DIR $CB_HOSTETH1 
  HOST_CHECK $FILES_DIR $CB_HOSTETH2 
  HOST_CHECK $FILES_DIR $CB_HOSTETH3 
  HOST_CHECK $FILES_DIR $CB_HOSTETH4 
  echo ""
fi

FILE_CHECK /etc/passwd $FILES_DIR $CB_HOSTS
if [ "$?" == "1" ]; then
  FILE_CHECK /etc/passwd $FILES_DIR $CB_HOSTETH1 
  FILE_CHECK /etc/passwd $FILES_DIR $CB_HOSTETH2 
  FILE_CHECK /etc/passwd $FILES_DIR $CB_HOSTETH3 
  FILE_CHECK /etc/passwd $FILES_DIR $CB_HOSTETH4 
  echo ""
fi

FILE_CHECK /etc/slurm/slurm.conf $FILES_DIR $CB_HOSTS
if [ "$?" == "1" ]; then
  FILE_CHECK /etc/slurm/slurm.conf $FILES_DIR $CB_HOSTETH1 
  FILE_CHECK /etc/slurm/slurm.conf $FILES_DIR $CB_HOSTETH2 
  FILE_CHECK /etc/slurm/slurm.conf $FILES_DIR $CB_HOSTETH3 
  FILE_CHECK /etc/slurm/slurm.conf $FILES_DIR $CB_HOSTETH4 
  echo ""
fi

MOUNT_CHECK $FILES_DIR $CB_HOSTS
if [ "$?" == "1" ]; then
  MOUNT_CHECK $FILES_DIR $CB_HOSTETH1 
  MOUNT_CHECK $FILES_DIR $CB_HOSTETH2 
  MOUNT_CHECK $FILES_DIR $CB_HOSTETH3 
  MOUNT_CHECK $FILES_DIR $CB_HOSTETH4 
  echo ""
fi

STOP_TIME=`date`
echo ""
echo "--------------------- clusterbot complete ------------------------------"
echo "start time: $START_TIME"
echo "stop time: $STOP_TIME"
