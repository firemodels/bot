#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "This script copies figures from a firebot run to this repo."
echo ""
echo "Options:"
echo "-d dir - directory where figures are located [default: $HOSTDIR]"
echo "-h - display this message"
echo "-H host - host where files are located [default: $HOST]"
echo "-s - show settings"
echo "-v - copy validation and verifiction figures"
echo "-V user - add user@ before hostname, needed for VPN connections when"
echo "          the username on this host is different than the remote host"
exit 0
}

CURDIR=`pwd`
cd ../../fds
fdsrepo=`pwd`
cd $CURDIR

HOST=blaze.el.nist.gov
HOSTDIR=/home2/smokevis2/firebot/FireModels_clone/fds/
COPY_VALVER_FIGS=
USE_SSH=
VPNUSER=`whoami`
SHOW_SETTINGS=
# set firebot host to burn
#HOST=burn.el.nist.gov
#HOSTDIR=/home4/firebot/FireModels_clone/fds/

while getopts 'd:hH:svV:' OPTION
do
case $OPTION  in
  d)
   HOSTDIR=$OPTARG
   ;;
  h)
   usage;
   ;;
  H)
   HOST=$OPTARG
   ;;
  s)
   SHOW_SETTINGS=1
   ;;
  v)
   COPY_VALVER_FIGS=1
   ;;
  V)
   VPNUSER=$OPTARG
   ;;
esac
done
shift $(($OPTIND-1))

# use ssh if this host is not the host where files are copied from
thishost=`hostname`
if [ "$thishost" != "$HOST" ]; then
  USE_SSH=1
  HOST="${VPNUSER}@$HOST"
fi

echo "----------------------------------------------"
echo "        user@host: $HOST"
echo "        from repo: $HOSTDIR"
if [ "$COPY_VALVER_FIGS" == "1" ]; then
  echo "copy val/ver figs: yes"
else
  echo "copy val/ver figs: no"
fi
echo "----------------------------------------------"
if [ "$SHOW_SETTINGS" == "1" ]; then
  exit 0
fi

# shouldn't have to change lines below

if [ "$USE_SSH" == "" ]; then
  CP=cp
  FIREBOTROOT=$HOSTDIR
else
  CP="scp -q"
  FIREBOTROOT=$HOST:$HOSTDIR
fi

FIREBOTMANS=$FIREBOTROOT/Manuals/
FIREBOTVER=$FIREBOTROOT/Verification/
FIREBOTVAL=$FIREBOTROOT/Validation/
FBTG=$FIREBOTMANS/FDS_Technical_Reference_Guide/
FBUG=$FIREBOTMANS/FDS_User_Guide/
FBVG=$FIREBOTMANS/FDS_Verification_Guide/
FBVAL=$FIREBOTMANS/FDS_Validation_Guide/
BASEDIR=$fdsrepo/Manuals

# Copy Tech Guide Figures
$CP $FBTG/SCRIPT_FIGURES/* $BASEDIR/FDS_Technical_Reference_Guide/SCRIPT_FIGURES/
echo Tech Guide Figures Copied

# Copy User's Guide Figures
$CP $FBUG/SCRIPT_FIGURES/* $BASEDIR/FDS_User_Guide/SCRIPT_FIGURES/
echo Users Guide Figures Copied

if [ "$COPY_VALVER_FIGS" == "1" ]; then
# Copy Verification Guide Figures
  $CP $FBVG/SCRIPT_FIGURES/*.pdf $BASEDIR/FDS_Verification_Guide/SCRIPT_FIGURES/.
  $CP $FBVG/SCRIPT_FIGURES/*.png $BASEDIR/FDS_Verification_Guide/SCRIPT_FIGURES/.
  $CP $FBVG/SCRIPT_FIGURES/*.tex $BASEDIR/FDS_Verification_Guide/SCRIPT_FIGURES/.
  $CP $FBVG/SCRIPT_FIGURES/Scatterplots/*.tex $BASEDIR/FDS_Verification_Guide/SCRIPT_FIGURES/Scatterplots/.
  echo Verification Figures Copied

# Copy Validation Guide Figures
  cp -R $FBVAL/SCRIPT_FIGURES/* $BASEDIR/FDS_Validation_Guide/SCRIPT_FIGURES/ &> /dev/null

  rsync -r --exclude=*.git $FBVAL/SCRIPT_FIGURES/* $BASEDIR/FDS_Validation_Guide/SCRIPT_FIGURES/
  echo Validation Guide Figures Copied

# Copy Verification Results
  rsync -v -r --include '*/' --include '*_git.txt' --include '*.csv' --include '*.prt5' --include '*.err' --exclude '*' $FIREBOTVER/* $BASEDIR/../Verification/
  
  $CP $FIREBOTVER/Miscellaneous/mesh_transformation.smv $BASEDIR/../Verification/Miscellaneous/.
  echo Verification Results Copied

# Copy Validation Results
  rsync -v -r --include '*/' --include '*_git.txt' --include '*.csv' --exclude '*' $FIREBOTVAL/* $BASEDIR/../Validation/
  echo Validation Results Copied
fi
