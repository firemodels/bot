#!/bin/bash
HOST=`hostname -s`
if [ ! -d $HOME/.rpms ]; then
  mkdir $HOME/.rpms
fi
rpm -qa | sort > $HOME/.rpms/rpm_${HOST}.txt
