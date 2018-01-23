#!/bin/bash

#define host arrays

export BLAZE1=`cat blaze1_nodes`
export BLAZE2=`cat blaze2_nodes`
export BLAZE3=`cat blaze3_nodes`
export BLAZE4=`cat blaze4_nodes`
export BURN1=`cat burn1_nodes`
export OTHER_NODES=`cat other_nodes`

#export BLAZE_NODES="$BLAZE1 $BLAZE2 $BLAZE3 $BLAZE4"
export BLAZE_NODES="$BLAZE1"

export BURN_NODES="$BURN1"

export ALL_NODES="$BLAZE_NODES $BURN_NODES $OTHER_NODES"

