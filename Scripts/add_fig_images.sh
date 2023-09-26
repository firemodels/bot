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

cd ../..
REPOROOT=`pwd`
if [ "`hostname -s`" == "blaze" ]; then
  TODIR=$REPOROOT/fig/smv/Reference_Figures/Default
else
  TODIR=$REPOROOT/fig/smv/Reference_Figures/Other
fi
FROMBASE=$REPOROOT/smv/Manuals/SMV_Summary/diffs/base
#FROMBASE=/var/www/html/`whoami`/$HTMLBASE/diffs/base
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

