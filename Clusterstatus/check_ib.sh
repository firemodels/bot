#!/bin/bash

if [ ! -e nodes_down_last ]; then
  touch nodes_down_last
fi

ssh -q blaze001 dsh -N BLAZE1_IB -f -e date >& nodes
grep "couldn't connect" nodes | awk '{print $5}' | awk -F':' '{print $1}' | sort > nodes_down
ssh -q blaze037 dsh -N BLAZE2_IB -f -e date >& nodes
grep "couldn't connect" nodes | awk '{print $5}' | awk -F':' '{print $1}' | sort >> nodes_down
ssh -q blaze073 dsh -N BLAZE3_IB -f -e date >& nodes
grep "couldn't connect" nodes | awk '{print $5}' | awk -F':' '{print $1}' | sort >> nodes_down
ssh -q blaze109 dsh -N BLAZE4_IB -f -e date >& nodes
grep "couldn't connect" nodes | awk '{print $5}' | awk -F':' '{print $1}' | sort >> nodes_down
ssh -q burn001 dsh -N BURN_IB -f -e date >& nodes
grep "couldn't connect" nodes | awk '{print $5}' | awk -F':' '{print $1}' | sort >> nodes_down

ndiff=`diff nodes_down nodes_down_last | wc -l`
nnodes=`cat nodes_down | wc -l`
if [[ "$nnodes" != "0" ]] && [[ "$ndiff" != "0" ]]; then
  mail -s "ib down on $nnodes nodes" gforney@gmail.com < nodes_down > /dev/null
fi

cp nodes_down nodes_down_last
