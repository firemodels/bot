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

# setup nodes

source ./SETUP_NODES.sh

# power up other nodes

for host in $OTHER_NODES
do
ipmihost=$host-ipmi
echo powering up host: $ipmihost
ipmitool -H $ipmihost -U ADMIN -P ADMIN power on
sleep 1
done

echo pause for 5 minutes to let $OTHER_NODES come up
sleep 300

echo mount all file systems on blaze
mount -a

for host in $OTHER_NODES
do
echo mount all file systems on $host
ssh $host mount -a
done

for host in $BLAZE_NODES $BURN_NODES
do
ipmihost=$host-ipmi
echo powering up host: $ipmihost
ipmitool -H $ipmihost -U ADMIN -P ADMIN chassis power on
sleep 1
done

echo pause for 5 minutes to let blaze and burn compute nodes come up
sleep 300

for host in $BLAZE_NODES $BURN_NODES
do
echo mount all file systems on $host
ssh $host mount -a
done

echo power up complete
