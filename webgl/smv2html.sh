#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "Usage:"
echo "$0 [options] casename"
echo ""
echo "Options:"
echo "-d dir      - directory containing case"
echo "-h          - display this message"
echo "-H hostname - host name"
echo "-v          - show command that will be run"
exit
}


source $HOME/smv_setup.sh
DIR=.
hostname=
showcommandline=
SMOKEVIEW=smokeview

#*** parse command line options

while getopts 'd:e:hH:v' OPTION
do
case $OPTION  in
  d)
   DIR="$OPTARG"
   ;;
  e)
   SMOKEVIEW="$OPTARG"
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

thishost=`hostname`
if [[ "$hostname" != "" ]] && [[ "$thishost" != "$hostname" ]]; then
  SSH="ssh -q $hostname "
else
  SSH=
  scriptdir=$HOME/$scriptdir
fi

ECHO=
if [ "$showcommandline" == "1" ]; then
  ECHO="echo "
fi

$ECHO $SSH  $scriptdir/runsmv_ssh.sh $SMOKEVIEW $DIR $casename
