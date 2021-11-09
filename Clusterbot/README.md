# Clusterbot: A script for verifying that a Linux cluster is working properly.

Clusterbot is a verification script that can be run at regular intervals to test various components of a Linux cluster.
To run clusterbot
 1. cd bot/Clusterbot
 2. type: ```./clusterbot.sh```

### Checks/Tests
  For each node:
  1. Verify ethernet and infiniband network connections
  2. Check that opensm is running on at least on node in each infiniband subnet.  
  If this check fails, case won't run.
  4. Check infiniband network card speed. If network card speeds are different, case will still run but performance will not be consistent.
  5. Check when nodes were imaged.  
  6. Check CPU clock rate, memory size, number of cores (hyperthreading is turned off).
  7. Check time is consistent, chrony.conf is identical, chronyd is running
  8. Check slurm - slurm is online, slurm.conf is identical, slurmd is running, same slurm rpm is installed .  
  Failure of any of these checks can cause cases not to run.
  10. Check rpm's are identical.  Failure of this check can cause cases not to run.
  11. Check group an passwd files are identical.  Failure of this check can cause problems with some people's logins.
  12. Check /etc/ssh and /etc/slurm directories have not changed

  Run the Intel cluster checker
  


