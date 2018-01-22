#!/bin/bash

echo "*******************************************************"
echo "*******************************************************"
echo " You are about to power down the"
echo " Fire Research Divsion Linux Cluster"
echo ""
echo " press <CTRL> c to abort or any other key to proceed   "
echo "*******************************************************"
echo "*******************************************************"
read val

# define host arrays

source ./SETUP_NODES.sh

# clearing user jobs

for host in blaze $BLAZE_NODES $BURN_NODES $OTHER_NODES
do
echo clearing user jobs on $host
scp -q clear_user_jobs.sh $host:/tmp/.
ssh -q $host bash /tmp/clear_user_jobs.sh
done

# umounting file systems

for host in blaze $BLAZE_NODES $BURN_NODES $OTHER_NODES
do
echo unmounting file systems on $host
ssh -q $host umount -a -t nfs
umount -a -t nfs
done

# powering down

for host in $BLAZE_NODES $BURN_NODES $OTHER_NODES
do
ipmihost=$host-ipmi
echo powering down host: $ipmihost
ipmitool -H $ipmihost -U ADMIN -P ADMIN chassis power off
done

echo Power down complete
echo Now power down blaze by typing:
echo poweroff
