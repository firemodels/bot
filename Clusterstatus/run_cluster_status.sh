#!/bin/bash
if [ "$CB_BASE" == "" ]; then
  exit
fi  
if [ "$CB_BEG" == "" ]; then
  exit
fi  
if [ "$CB_END" == "" ]; then
  exit
fi  
./cluster_status.sh none $CB_BASE $CB_BEG $CB_END
