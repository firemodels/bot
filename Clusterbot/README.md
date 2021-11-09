## Clusterbot: A script for verifying that a Linux cluster is working properly.

Clusterbot is a verification script that can be run at regular intervals to test various components of a Linux cluster.
To run clusterbot
 1. cd bot/Clusterbot
 2. type: ```./clusterbot.sh```

### Checks/Tests
  For each node:
  1. Verify ethernet and infiniband network connections.  Cases won't run on nodes with bad network connections.  
  2. Check that opensm is running on at least on node in each infiniband subnet.  
  If this check fails, cases will not run because the infiniband network will not work.
  3. Check infiniband network card speed. If network card speeds are different, cases will still run but performance will not be consistent.
  4. Check when nodes were imaged.  Nodes imaged at different times may result in cases failing to run.  Check whether rpms are different.
  5. Check CPU clock rate, memory size, number of cores (hyperthreading is turned off).  Cases will run if these parameters are different.
  6. Check that time is consistent across nodes, chrony.conf is identical, chronyd is running
  7. Check that slurm is online, slurm.conf is identical, slurmd is running, same slurm rpm is installed .  
  Failure of any of these checks can cause cases not to run.
  8. Check rpm's are identical.  Failure of this check can cause cases not to run. For example, if slurm rpms are different on different nodes.
  9. Check group and passwd files are identical.  Failure of this check can cause problems with some people's logins.
  10. Check /etc/ssh and /etc/slurm directories have not changed
  11. Run the Intel cluster checker
  12. Run fds test cases.  20 test cases will run on the queue named q if you run clusterbot.sh with the `-q q` option .  The test
   case is a simple 24 mesh case designed solely to test the communication between MPI processes
   
   ### Clusterbot usage

```
   Usage: run_smokebot.sh [options]

run_clusterbot.sh - perform various checks to verify a Linux cluster is working properly. If the -q option
                is specified, run test cases on multiple nodes. The test cases are very simple designed
                only to verify that communication works between processes.  To run more realistic test
                cases, use firebot or smokebot.

Options:
 -f - override lock to force clusterbot run
 -h - display this message
 -m email_address - send results to email_address
 -n n - run n cases on each queue [default: ]
 -q q - run test cases using the queue q.
 -Q q - same as the -q option except that only test cases are run.
         Other tests are not performed.
```
  


