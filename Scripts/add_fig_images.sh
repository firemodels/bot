#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "add modified fig images to fig repo"
echo ""
echo "Options:"
echo "-h - display this message"
echo "-b - html base [default: $HTMLBASE]"
exit 0
}
HTMLBASE=clonef

#*** parse options

while getopts 'hb:' OPTION
do
case $OPTION  in
  h)
   usage;
   ;;
  b)
   HTMLBASE="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

CURDIR=`pwd`
TODIR=../../fig/smv/Reference_Figures
cd $TODIR
TODIR=`pwd`
FROMBASE=/var/www/html/`whoami`/$HTMLBASE/diffs/base
cd $FROMBASE/user
USERFILES=`ls *.png`
cd $FROMBASE/verification
VERFILES=`ls *.png`
cd $TODIR
for f in $USERFILES
do
git add $f
done
for f in $VERFILES
do
git add $f
done
git clean -dxf

