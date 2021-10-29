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
#                   is_clck_installed
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


ERROR=
RPMCHECK=
FIX=
while getopts 'hr' OPTION
do
case $OPTION  in
  h)
   usage
   exit
   ;;
  r)
   RPMCHECK=1
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$ERROR" == "1" ]; then
  exit
fi


# --------------------- define file names --------------------

ETHOUT=/tmp/ethout.$$
CLUSTEROUT=/tmp/clusterout.$$
ETHUP=/tmp/ethup.33
CHECKEROUT=/tmp/checkerout.$$
FSOUT=/tmp/fsout.$$
MOUNTOUT=/tmp/mountout.$$
IBOUT=/tmp/ibout.$$
SUBNETOUT=/tmp/subnetout.$$
IBRATE=/tmp/ibrate.$$
SLURMOUT=/tmp/slurmout.$$
SLURMRPMOUT=/tmp/slurmrpmout.$$
DOWN_HOSTS=/tmp/downhosts.$$
UP_HOSTS=/tmp/uphosts.$$

# --------------------- setup Intel cluster checker  --------------------

SETUP_CLCK

# --------------------- initial error checking --------------------

ERROR=
if [ "$CB_HOSTS" == "" ]; then
  ERROR=1
  echo "***error: environment variable CB_HOSTS not defined"
fi
if [ "$CB_HOST1" != "" ]; then
  HAVE_IB=1
  if [ "$CB_HOSTIB1" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB1 must be defined if CB_HOST1 is defined"
  fi
fi
if [ "$CB_HOST2" != "" ]; then
  HAVE_IB=1
  if [ "$CB_HOSTIB2" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB2 must be defined if CB_HOST2 is defined"
  fi
fi
if [ "$CB_HOST3" != "" ]; then
  HAVE_IB=1
  if [ "$CB_HOSTIB3" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB3 must be defined if CB_HOST3 is defined"
  fi
fi
if [ "$CB_HOST4" != "" ]; then
  HAVE_IB=1
  if [ "$CB_HOSTIB4" == "" ]; then
    ERROR=1
    echo "***error: CB_HOSTIB4 must be defined if CB_HOST4 is defined"
  fi
fi
if [ "$ERROR" == "1" ]; then
  exit
fi

echo
echo "---------- Linux Cluster Status: $CB_HOSTS ----------"
echo ""
echo "--------------------- network checks --------------------------"
# --------------------- check ethernet --------------------

pdsh -t 2 -w $CB_HOSTS date   >& $ETHOUT
ETHDOWN=`sort $ETHOUT | grep -E 'timed|refused|route' | awk -F':' '{print $1}' | awk '{printf "%s ", $1}'`

if [ "$ETHDOWN" == "" ]; then
  echo "   $CB_HOSTS: Ethernet up on each host"
else
  echo "   $CB_HOSTS: ***Warning: Ethernet down on $ETHDOWN"
fi

# --------------------- check infiniband --------------------

if [ "$HAVE_IB" == "1" ]; then
  rm -rf $IBOUT
  touch $IBOUT
  if [ "$CB_HOST1" != "" ]; then
    ssh $CB_HOST1 pdsh -t 2 -w $CB_HOSTIB1 date  >>  $IBOUT 2>&1
  fi
  if [ "$CB_HOST2" != "" ]; then
    ssh $CB_HOST2 pdsh -t 2 -w $CB_HOSTIB2 date  >>  $IBOUT 2>&1
  fi
  if [ "$CB_HOST3" != "" ]; then
    ssh $CB_HOST3 pdsh -t 2 -w $CB_HOSTIB3 date  >>  $IBOUT 2>&1
  fi
  if [ "$CB_HOST4" != "" ]; then
    ssh $CB_HOST4 pdsh -t 2 -w $CB_HOSTIB4 date  >>  $IBOUT 2>&1
  fi
  IBDOWN=`grep -E 'timed|refused|route'  $IBOUT | grep out | sort | awk -F':' '{print $1}' | awk '{printf "%s ", $1}'`

  if [ "$IBDOWN" == "" ]; then
    echo "   $CB_HOSTS: Infiniband up on each host"
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

  if [ "$CB_HOST_ARG" == "" ]; then
    return
  fi
  ssh $CB_HOST_ARG pdsh -t 2 -w $CB_HOST_ARG,$CB_HOSTIB_ARG ps -el |& sort -u | grep opensm  >  $SUBNETOUT 2>&1
  SUB1=`cat  $SUBNETOUT | awk -F':' '{print $1}' | sort -u | awk '{printf "%s%s", $1," " }'`
  if [ "$SUB1" == "" ]; then
    echo "   $CB_HOSTIB_ARG: **Error: subnet manager not running on any host"
    echo "      To fix: ssh $CB_HOST_ARG service opensm start   "
    FIX=1
  else
    echo "   $CB_HOSTIB_ARG: subnet manager running on $SUB1"
  fi
}

if [ "$HAVE_IB" == "1" ]; then
  SUBNET_CHECK $CB_HOST1 $CB_HOSTIB1
  SUBNET_CHECK $CB_HOST2 $CB_HOSTIB2
  SUBNET_CHECK $CB_HOST3 $CB_HOSTIB3
  SUBNET_CHECK $CB_HOST4 $CB_HOSTIB4
fi

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
  RATEBAD=
  while read line 
  do
    host=`echo $line | awk '{print $1}' | awk -F':' '{print $1}'`
    RATEI=`echo $line | awk '{print $2}'`
    if [ "$RATEI" != "$RATE0" ]; then
      if [ "$RATEI" != "Connection" ]; then
        RATEBAD="$RATEBAD $host/$RATEI"
      fi
    fi
  done < $IBRATE

   if [ "$RATEBAD" == "" ]; then
    echo "   ${CB_HOST_ARG}-ib: Infiniband - $RATE0 Gb/s  on each host"
  else
    echo "   ${CB_HOST_ARG}-ib: ***Warning: Infiniband - $RATE0 Gb/s on each host except $RATEBAD"
  fi
}
if [ "$HAVE_IB" == "1" ]; then
  echo ""
  IBSPEED $CB_HOSTETH1
  IBSPEED $CB_HOSTETH2
  IBSPEED $CB_HOSTETH3
  IBSPEED $CB_HOSTETH4
fi

# --------------------- run cluster checker --------------------

RUN_CLUSTER_CHECK ()
{
  local LOG=$1
  local CB_HOST_ARG=$2

  if [ "$CB_HOST_ARG" != "" ]; then
    NODEFILE=output/$LOG.hosts
    WARNINGFILE=output/${LOG}_execution_warnings.log
    OUTFILE=output/${LOG}.out
    RESULTSFILE=output/${LOG}_results.out
    pdsh -t 2 -w $CB_HOST_ARG date   >& $CLUSTEROUT
    sort $CLUSTEROUT | grep -v ssh | awk '{print $1 }' | awk -F':' '{print $1}' > $NODEFILE
    nup=`wc -l $NODEFILE`
    if [ "$nup" == "0" ]; then
      echo "   $CB_HOST_ARG: ***Error: all nodes are down - cluster checker not run"
    else
      echo "   $CB_HOST_ARG: results in $RESULTSFILE and $WARNINGFILE"
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
      FSDOWN="$FSDOWN $host/$NFI"
    fi
  done < $FSOUT

  if [ "$FSDOWN" == "" ]; then
    echo "   $CB_HOSTETH_ARG: $NF0 cores on each host"
  else
    echo "   $CB_HOSTETH_ARG: ***Warning: $NF0 cores on each host except $FSDOWN"
    echo "      To fix: boot into BIOS and disable hyperthreading"
    FIX=1
  fi
}

echo ""
echo "--------------------- CPU/Disk checks -------------------------"
CORE_CHECK $CB_HOSTETH1
CORE_CHECK $CB_HOSTETH2
CORE_CHECK $CB_HOSTETH3
CORE_CHECK $CB_HOSTETH4

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
    FSDOWN="$FSDOWN $host"
  fi
done < $FSOUT

if [ "$FSDOWN" == "" ]; then
  echo "   $CB_HOSTS: $NF0 file systems mounted on each host"
else
  echo "   $CB_HOSTS: ***Warning: $NF0 file systems not mounted on $FSDOWN"
  echo "      To fix: run mount -a on each host using:"
  echo "           pdsh -t 2 -w $CB_HOSTS mount -a"
  FIX=1
fi

# --------------------- check slurm --------------------
echo ""
echo "--------------------- Slurm checks ----------------------------"

pbsnodes -l | awk '{print $1}' | sort -u  > $DOWN_HOSTS
SLURMDOWN=
while read line 
do
  host=`echo $line | awk '{print $1}'`
  SLURMDOWN="$SLURMDOWN $host"
done < $DOWN_HOSTS

if [ "$SLURMDOWN" == "" ]; then
  echo "   $CB_HOSTS: Slurm up on each host"
else
  echo "   $CB_HOSTS: ***Warning: Slurm offline on $SLURMDOWN"
  echo "      To fix:  scontrol update nodename=HOST state=resume"
  echo "      This fix can only be applied to a HOST that is up and with a working ethernet and infiniband network connection."
  FIX=1
fi

# --------------------- check slurm daemon --------------------

CHECK_DAEMON ()
{
 local DAEMON_ARG=$1
 local CB_HOST_ARG=$2

DAEMONOUT=/tmp/daemon.out.$$

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
  echo "   $CB_HOST_ARG: $DAEMON_ARG running on each host"
else
  echo "   $CB_HOST_ARG: ***Warning: $DAEMON_ARG down on $DAEMONDOWN"
  echo "      To fix:  pdsh -t 2 -w $CB_HOST_ARG service $DAEMON_ARG start"
  FIX=1
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
      SLURMBAD="$SLURMBAD $host/$SLURMRPMI"
    fi
  fi
done < $SLURMRPMOUT

if [ "$SLURMBAD" == "" ]; then
  echo "   $CB_HOSTS: $SLURMRPM0 installed on each host"
else
  echo "   $CB_HOSTS: ***Warning: $SLURMRPM0 not installed on $SLURMBAD"
  echo "      To fix: ask system administrator to update slurm rpm packages"
  FIX=1
fi

# --------------------- check daemons --------------------

echo ""
echo "--------------------- daemon checks ---------------------------"

CHECK_DAEMON slurmd $CB_HOSTS

GANGLIA=`ps -el | grep gmetad`
if [ "$GANGLIA" != "" ]; then
  CHECK_DAEMON gmond $CB_HOSTS
fi

RPM_CHECK ()
{
 local CB_HOST_ARG=$1

if [ "$CB_HOST_ARG" == "" ]; then
  return 0
fi
rm -f $HOME/.rpms/rpm*.txt
pdsh -t 2 -w $CB_HOST_ARG `pwd`/getrpms.sh >& $SLURMRPMOUT

CURDIR=`pwd`
cd $HOME/.rpms
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
    RPMDIFF="$RPMDIFF $hostdiff"
  fi
done
cd $CURDIR

if [ "$RPMDIFF" == "" ]; then
  echo "   $CB_HOST_ARG: rpms the same on each host"
else
  echo "   $CB_HOST_ARG: ***Warning: $host0 rpms different from those on $RPMDIFF "
fi
}

if [ "$RPMCHECK" != "" ]; then
  echo ""
  echo "--------------------- rpm checks ------------------------------"
  RPM_CHECK $CB_HOSTETH1
  RPM_CHECK $CB_HOSTETH2
  RPM_CHECK $CB_HOSTETH3
  RPM_CHECK $CB_HOSTETH4
  RPM_CHECK $CB_HOSTS
fi

if [ "$FIX" != "" ]; then
  echo ""
  echo "***Important:  all fixes must be applied as root. ***"
fi



# --------------------- cleanup --------------------

rm -f $CLUSTEROUT $DOWN_HOSTS $ETHOUT $FSOUT $IBOUT $IBRATE $MOUNTOUT $SLURMOUT $SLURMRPMOUT $SUBNETOUT $UP_HOSTS 
