#!/bin/bash

# setup nodes

source ./SETUP_NODES.sh

for host in blaze $OTHER_NODES $BLAZE_NODES $BURN_NODES
do
echo $host
ssh $host date
done
echo
echo complete
