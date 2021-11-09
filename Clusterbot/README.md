# Clusterbot: A script for verifying that a Linux cluster is working properly.

Clusterbot is a verification script that can be run at regular intervals to test various components of a Linux cluster.
To run clusterbot
 1. cd bot/Clusterbot
 2. type: ```./clusterbot.sh```

### Checks/Tests
  For each node:
  1. Verify ethernet and infiniband network connections
  2. Check that opensm is running on at least on node in each infiniband subnet
  3. Check infiniband network card speed
  4. Check when nodes were imaged
  5. Check CPU clock rate, memory size, number of cores
  6. Check time is consistent, chrony.conf is identical, chronyd is running
  7. Check slurm - slurm is online, slurm.conf is identical, slurmd is running, same slurm rpm is installed  
  8. Check rpm's are identical
  9. Check group an passwd files are identical
  10. Check /etc/ssh and /etc/slurm directories have not changed

  Run the Intel cluster checker

