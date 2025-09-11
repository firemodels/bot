#!/bin/bash
CUR_DIR=`pwd`
SMV_REPO=../../smv
cd $SMV_REPO/Manuals
MANDIR=`pwd`
cp $MANDIR/SMV_User_Guide/SCRIPT_FIGURES/*.png         $MANDIR/SMV_Summary/images/user
cp $MANDIR/SMV_Technical_Reference_Guide/SCRIPT_FIGURES/*.png    $MANDIR/SMV_Summary/images/user
cp $MANDIR/SMV_Verification_Guide/SCRIPT_FIGURES/*.png $MANDIR/SMV_Summary/images/verification
