#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "Usage:
echo "smv_web.sh [options] casename
echo ""
echo "Options:"
echo "-d dir      - directory contain case"
echo "-h          - display this message"
echo "-H hostname - host name"
echo "-v          - show command that will be run"
exit
}


DIR=.
hostname=
showcommandline=

#*** parse command line options

while getopts 'd:hH:v' OPTION
do
case $OPTION  in
  d)
   DIR="$OPTARG"
   ;;
  h)
   usage
   ;;
  H)
   hostname="$OPTARG"
   ;;
  v)
   showcommandline=1
   ;;
esac
done
shift $(($OPTIND-1))
casename=$1

DIR="cd $DIR"

thishost=`hostname`
SSH=
if [ "$hostname" != "" ]; then
  if [ "$thishost" != "$hostname" ]; then
    SSH="ssh -q $hostname "
  fi
fi

ECHO=
if [ "$showcommandline" == "1" ]; then
  ECHO="echo "
fi

$ECHO $SSH \( $DIR \; smokeview -runscript $casename \)





