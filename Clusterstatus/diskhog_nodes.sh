#!/bin/sh -f
source /usr/local/bin/CLUSTERHOSTS.sh

# diskhog
# Kristopher Overholt
# 10/24/2012

# This script checks disk capacity on all nodes
# and sends an email report if any disk is more
# than 90% full.

# Inputs
mailTo="gforney@gmail.com"
logfile=/tmp/diskhog.log
echo > $logfile

# Check all hosts
for host in $cluster_hosts
do
   # Get percentage of all disks on each node
   sizes=`ssh -q $host df -h -l | grep -v tmpfs | awk '{print $5}' | sed 's/%//' | tail -n +2`
   echo sizes=$sizes
   for disk in $sizes; do
      if [ $disk -gt 90 ]; then
         echo "One or more disks on $host is more than 90% full." >> $logfile
         echo $host >> $logfile
         ssh $host df -h | grep -v tmpfs >> $logfile
         echo >> $logfile
         email_flag=1
         break
      else
         continue
      fi
   done
done

# If any node tripped the email flag, then send the results
if [[ $email_flag ]]
then
   mail -s "[DiskHog] Alert: One or more node disks is almost full" $mailTo < $logfile > /dev/null
else
   continue
fi
