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

source CLUSTER_NODES/SETUP_NODES.sh

# powering down

for host in $BLAZE_NODES $BURN_NODES $OTHER_NODES
do
ipmihost=$host-ipmi
echo powering down host: $ipmihost
ipmitool -H $ipmihost -U ADMIN -P ADMIN chassis power off
done

echo Power down complete
