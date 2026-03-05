#!/bin/bash

CURDIR=`pwd`
cd ../../..
GITROOT=`pwd`
cd $CURDIR

#-----------------------------------
#          GETREVISION
#-----------------------------------

GETREVISION(){
  REPO=$1
  cd $REPO
  REVISION=`git describe`
  echo "$REVISION" | awk -F'-' '{
    last_index=NF; 
    for(i=1;i<NF;i++) { 
        printf "%s%s", $i, (i<NF-1?"-":"") 
    } 
    printf "\n"
  }'
}

#-----------------------------------
#          GETHASH
#-----------------------------------

GETHASH(){
  REPO=$1
  cd $REPO
  REVISION=`git describe`
  echo "$REVISION" | awk -F'-' '{print $NF}'
}

cat << EOF  
FDS_HASH     `GETHASH     $GITROOT/fds`
FDS_REVISION `GETREVISION $GITROOT/fds`
SMV_HASH     `GETHASH     $GITROOT/smv`
SMV_REVISION `GETREVISION $GITROOT/smv`
EOF

