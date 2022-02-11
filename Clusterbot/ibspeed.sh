#!/bin/bash
if [ -e /usr/sbin/ibstatus ]; then
  /usr/sbin/ibstatus | grep -E 'state|rate' | grep -v phys | grep -A 1 ACTIVE | tail -1 | awk '{print $2}'
else
  echo 0
fi
