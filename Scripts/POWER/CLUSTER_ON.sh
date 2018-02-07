#!/bin/bash

echo "*******************************************************"
echo "*******************************************************"
echo " You are about to power up the"
echo " Fire Research Divsion Linux Cluster"
echo ""
echo " press <CTRL> c to abort or any other key to proceed   "
echo "*******************************************************"
echo "*******************************************************"
read val

# setup nodes

source CLUSTER_NODES/SETUP_NODES.sh

# power up other nodes

for host in $OTHER_NODES $BLAZE_NODES $BURN_NODES
do
ipmihost=$host-ipmi
echo powering up host: $ipmihost
ipmitool -H $ipmihost -U ADMIN -P ADMIN power on
sleep 1
done

echo power up complete
