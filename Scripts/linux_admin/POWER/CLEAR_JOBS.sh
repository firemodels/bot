#!/bin/bash

echo "*******************************************************"
echo "*******************************************************"
echo " You are about to clear jobs on all nodes"
echo ""
echo " press <CTRL> c to abort or any other key to proceed   "
echo "*******************************************************"
echo "*******************************************************"
read val

# setup nodes

source CLUSTER_NODES/SETUP_NODES.sh

# power up other nodes

for host in blaze $OTHER_NODES $BLAZE_NODES $BURN_NODES
do
echo clearing user jobs on $host
scp CLUSTER_NODES/clear_user_jobs.sh $host\:/tmp/clear_user_jobs.sh
ssh -q $host bash /tmp/clear_user_jobs.sh
sleep 1
done

echo complete
