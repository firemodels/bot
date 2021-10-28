#!/bin/bash

#---------------------------------------------
# ---------------------------- usage ----------------------------------
#---------------------------------------------

function usage {
  echo "Usage: clusterbot.sh "
  echo ""
  echo "clusterbot.sh - peform various checks on a Linux cluster"
  echo ""
  echo " -c - run Intel cluster checker"
  echo " -h - display this message"
  echo " -m - mount file systems on each host"
  echo " -s - restart subnet manager on each infiniband subnet"
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
    echo "***warning: cluster checker, clck, not installd or not in path"
  else
    CHECK_CLUSTER=`which clck`
  fi
  return 0
}


RESTART_SUBNET=
MOUNT_FS=
ERROR=
while getopts 'hms' OPTION
do
case $OPTION  in
  h)
   usage
   exit
   ;;
  m)
   MOUNT_FS=1
   if [ `whoami` != "root" ]; then
     ERROR=1
     echo "***Error: you need to be root to use the -m option"
   fi
   ;;
  s)
   RESTART_SUBNET=1
   if [ `whoami` != "root" ]; then
     ERROR=1
     echo "***Error: you need to be root to use the -s option"
   fi
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

if [ "$MOUNT_FS" == "1" ]; then
  pdsh -t 2 -w $CB_HOSTS mount -a |& grep timed | sort | awk -F':' '{print $1}'>& $MOUNTOUT

  MOUNTDOWN=
  while read line 
  do
    host=`echo $line | awk '{print $1}'`
    MOUNTDOWN="$MOUNTDOWN $host"
  done < $MOUNTOUT

  if [ "$MOUNTDOWN" == "" ]; then
    echo "mount -a succeeded on all hosts in $CB_HOSTS"
  else
    echo "mount -a failed on: $MOUNTDOWN"
  fi
fi

if [ "$RESTART_SUBNET" == "1" ]; then
  if [ "$HAVE_IB" == "1" ]; then
    if [ "$CB_HOST1" != "" ]; then
      echo "restarting the subnet manager opensm on $CB_HOST1"
      ssh $CB_HOST1 systcl opensm restart
    fi
    if [ "$CB_HOST2" != "" ]; then
      echo "restarting the subnet manager opensm on $CB_HOST2"
      ssh $CB_HOST2 systcl opensm restart
    fi
    if [ "$CB_HOST3" != "" ]; then
      echo "restarting the subnet manager opensm on $CB_HOST3"
      ssh $CB_HOST3 systcl opensm restart
    fi
    if [ "$CB_HOST4" != "" ]; then
      echo "restarting the subnet manager opensm on $CB_HOST4"
      ssh $CB_HOST4 systcl opensm restart
    fi
  else
    echo "***Error: infiniband not running on the linux cluser"
  fi
  exit
fi

if [ "$MOUNT_FS" == "1" ]; then
  exit   
fi

echo
echo "--------------- cluster status $CB_HOSTS ---------------"

# --------------------- setup Intel cluster checker  --------------------

SETUP_CLCK

# --------------------- check ethernet --------------------

pdsh -t 2 -w $CB_HOSTS date   >& $ETHOUT
ETHDOWN=`sort $ETHOUT | grep timed | awk -F':' '{print $1}' | awk '{printf "%s%s", $1," " }'`

echo ""
if [ "$ETHDOWN" == "" ]; then
  echo "Ethernet up on all hosts"
  ACCESSIBLE=" "
else
  echo "***Warning: Ethernet down on $ETHDOWN"
  ACCESSIBLE=" accessible "
fi

# --------------------- check infiniband --------------------

if [ "$HAVE_IB" == "1" ]; then
  echo "" > $IBOUT
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
  IBDOWN=`grep timed  ibout | grep out | sort | awk -F':' '{print $1}' | awk '{printf "%s ", $1}'`

  echo ""
  if [ "$IBDOWN" == "" ]; then
    echo "Infiniband up on all${ACCESSIBLE}hosts"
  else
    echo "***Warning: Infiniband down on $IBDOWN"
  fi

# --------------------- check infiniband subnet manager --------------------

SUBNET_CHECK ()
{
  local CB_HOST_ARG=$1
  local CB_HOSTIB_ARG=$2

  if [ "$CB_HOST_ARG" == "" ]; then
    return
  fi
  ssh $CB_HOST_ARG pdsh -t 2 -w $CB_HOST_ARG,$CB_HOSTIB_ARG ps -el |& sort -u | grep opensm  >  $SUBNETOUT 2>&1
  SUB1=`cat  $SUBNETOUT | awk -F':' '{print $1}' | sort -u | awk '{printf "%s%s", $1," " }'`
  echo ""
  if [ "$SUB1" == "" ]; then
    echo "***Error: Subnet manager not running on any hosts in $CB_HOSTIB_ARG"
  else
    echo "Subnet manager for subnet $CB_HOSTIB_ARG running on $SUB1"
  fi
}

if [ "$HAVE_IB" == "1" ]; then
  SUBNET_CHECK $CB_HOST1 $CB_HOSTIB1
  SUBNET_CHECK $CB_HOST2 $CB_HOSTIB2
  SUBNET_CHECK $CB_HOST3 $CB_HOSTIB3
  SUBNET_CHECK $CB_HOST4 $CB_HOSTIB4
fi

# --------------------- check infiniband speed --------------------

  CURDIR=`pwd`
  pdsh -t 2 -w $CB_HOSTS $CURDIR/ibspeed.sh |& grep -v ssh | sort >& $IBRATE
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

  echo ""
  if [ "RATEBAD" == "" ]; then
    echo "Infiniband speed is $RATE0 Gb/s on all${ACCESSIBLE}hosts"
  else
    echo "***Warning: Infiniband speed is $RATE0 Gb/s except on $RATEBAD"
  fi
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
      echo "***Error: all nodes in $CB_HOST_ARG are down - cluster checker not run"
    else
     echo "running Intel cluster checker on $CB_HOST_ARG - results in $RESULTSFILE and $WARNINGFILE"
     $CHECK_CLUSTER -l error -f $NODEFILE -o $RESULTSFILE >& $OUTFILE
     if [ -e clck_execution_warnings.log ]; then
       mv clck_execution_warnings.log $WARNINGFILE
     fi
    fi
  fi
}

if [ "$CHECK_CLUSTER" != "" ]; then
  echo ""
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

  echo ""
  if [ "$FSDOWN" == "" ]; then
    echo "$NF0 cores on each host in $CB_HOSTETH_ARG"
  else
    echo "***Warning: $NF0 cores on all hosts in $CB_HOSTETH_ARG except $FSDOWN"
  fi
}

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

echo ""
if [ "$FSDOWN" == "" ]; then
  echo "$NF0 file systems mounted on all${ACCESSIBLE}hosts"
else
  echo "***Warning: $NF0 file systems not mounted on $FSDOWN"
fi

# --------------------- check slurm --------------------

pbsnodes -l | awk '{print $1}' | sort -u  > $DOWN_HOSTS
SLURMDOWN=
while read line 
do
  host=`echo $line | awk '{print $1}'`
  SLURMDOWN="$SLURMDOWN $host"
done < $DOWN_HOSTS

echo ""
if [ "$SLURMDOWN" == "" ]; then
  echo "Slurm up on all${ACCESSIBLE}hosts"
else
  echo "***Warning: Slurm down on $SLURMDOWN"
fi

# --------------------- check slurm daemon --------------------

pdsh -t 2 -w $CB_HOSTS "ps -el | grep slurmd | wc -l" |&  grep -v ssh | sort >& $SLURMOUT
SLURMDOWN=
while read line 
do
  host=`echo $line | awk '{print $1}'`
  host=`echo $host | sed 's/.$//'`
  NSLURM=`echo $line | awk '{print $2}'`
  if [ "$NSLURM" == "0" ]; then
    SLURMDOWN="$SLURMDOWN $host"
  fi
done < $SLURMOUT

echo ""
if [ "$SLURMDOWN" == "" ]; then
  echo "slurmd running on all${ACCESSIBLE}hosts"
else
  echo "***Warning: slurmd down on $SLURMDOWN"
fi

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

echo ""
if [ "$SLURMBAD" == "" ]; then
  echo "slurm rpm version is $SLURMRPM0 on all${ACCESSIBLE}hosts"
else
  echo "***Warning: $SLURMRPM0 not installed on $SLURMBAD"
fi

# --------------------- cleanup --------------------

rm -f $CLUSTEROUT $DOWN_HOSTS $ETHOUT $FSOUT $IBOUT $IBRATE $MOUNTOUT $SLURMOUT $SLURMRPMOUT $SUBNETOUT $UP_HOSTS 
