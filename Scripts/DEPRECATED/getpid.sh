#!/bin/bash
user=`whoami`
uid=`id -u $user`
ps -el | grep $uid | grep $1 | grep -v getpid | grep -v grep | awk '{print $2}'
