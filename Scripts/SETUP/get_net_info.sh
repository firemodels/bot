#!/bin/bash
echo gateway=`ip route | grep default | awk '{print $3}'`
echo bcast=`ifconfig | grep Bcast | awk '{print $3}' | awk -F':' '{print $2}'`
echo ip=`ifconfig | grep Bcast | awk '{print $2}' | awk -F':' '{print $2}'`
echo mask=`ifconfig | grep Bcast | awk '{print $4}' | awk -F':' '{print $2}'`
echo dns=`cat /etc/resolv.conf | grep nameserver | awk '{print $2}' `
