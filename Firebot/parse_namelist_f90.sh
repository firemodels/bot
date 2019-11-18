#!/bin/bash
input_dir=$1
cat $input_dir/*.f90 | sed ':a;N;$!ba;s/&\n/ /g' | tr -d ' ' | grep ^NAMELIST | awk -F'/' '{print "/"$2"/,"$3}'  | awk -F',' '{for(i=2; i<=NF; i++){print $1$i}}' | sort
