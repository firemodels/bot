#!/bin/bash
chid=$1
outdir=$2
TERMINAL=$3

fdscase=$chid.fds

if [ "$TERMINAL" != "" ]; then
  outdir=/tmp
fi
cat << EOF > $outdir/$fdscase
&HEAD CHID='$chid',TITLE='cluster test case $num' /

&MESH IJK=8,8,8, XB=0.0,0.8,0.0,0.8,0.0,0.8, MULT_ID='mesh'/
&MULT ID='mesh', DX=0.8, DY=0.8, DZ=0.8, I_UPPER=1, J_UPPER=1, K_UPPER=5 /

&DUMP SMOKE3D=F /

&TIME T_END=1. /  Total simulation time

&VENT MB='XMIN', SURF_ID='OPEN' /
&VENT MB='XMAX', SURF_ID='OPEN' /
&VENT MB='YMIN', SURF_ID='OPEN' /
&VENT MB='YMAX', SURF_ID='OPEN' /
&VENT MB='ZMAX', SURF_ID='OPEN' /

&TAIL /
EOF
if [ "$TERMINAL" != "" ]; then
  cat $outdir/$fdscase
  rm $outdir/$fdscase
fi
