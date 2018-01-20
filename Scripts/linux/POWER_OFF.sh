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

# -------------------- get_host ---------------------------

get_host ()
{
base=$1
ipnum=$2
if [ $ipnum -gt 99 ]; then
  host=$base$ipnum
else
  if [ $ipnum -gt 9 ]; then
    host=${base}0$ipnum
  else
    host=${base}00$ipnum
  fi
fi
echo $host
}

#define host arrays

for i in `seq 1 35`; do
  BLAZE1[$i]=`get_host blaze $i`
done
for i in `seq 36 71`; do
  BLAZE2[$i]=`get_host blaze $i`
done
for i in `seq 72 107`; do
  BLAZE3[$i]=`get_host blaze $i`
done
for i in `seq 108 119`; do
  BLAZE4[$i]=`get_host blaze $i`
done
for i in `seq 1 36`; do
  BURN1[$i]=`get_host burn $i`
done

OTHER_NODES=(burn firestore blaze-head smokevis firevis)

#ALL_NODES=("${BLAZE1[@]}" "${BLAZE2[@]}" "${BLAZE3[@]}" "${BLAZE4[@]}" "${BURN1[@]}" "${OTHER_NODES[@]}")
ALL_NODES=("${BLAZE1[@]}" "${OTHER_NODES[@]}")

for host in "${ALL_NODES[@]}"
do
ipmihost=$host-ipmi
echo powering down host: $ipmihost
#ipmitool -H $ipmihost -U ADMIN -P ADMIN power off
done
