#!/bin/bash

if [ ! -e .smv_git ]; then
  echo "***error: the script $0 needs to run in the bot/Firebot directory"
  echo "          $0 aborted"
  exit 1
fi

# SMV UG directory
mandir=../../smv/Manuals/SMV_User_Guide/
# smv source directory
smv_dir=../../smv/Source/smokeview

 grep MatchINI $smv_dir/readsmv.c          | awk -F'"' '{ print $2}' |                                             sort -u > smv_ini.out
 grep hitemini $mandir/SMV_User_Guide.tex  | awk -F'{' '{ print $2}' | awk -F'}' '{ print $1}' | sed 's/\\_/_/g' | sort -u > man_ini.out

 git diff --no-index smv_ini.out man_ini.out  >& diff.out
# cat diff.out | grep ^- | sed 's/^-//g' 
 
 cat diff.out | grep ^+ | sed 's/^+//g' 
