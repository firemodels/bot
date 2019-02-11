#!/bin/bash
pubhost=$1
pubhome=$2
pub_todir=$3

source ../scripts/GET_ENV.sh

mkdir -p $pub_todir
pubdir=$pubhome/.firebot/pubs
scp -q $pubhost\:$pubdir/FDS_Config_Management_Plan.pdf    $pub_todir/.
scp -q $pubhost\:$pubdir/FDS_Technical_Reference_Guide.pdf $pub_todir/.
scp -q $pubhost\:$pubdir/FDS_User_Guide.pdf                $pub_todir/.
scp -q $pubhost\:$pubdir/FDS_Validation_Guide.pdf          $pub_todir/.
scp -q $pubhost\:$pubdir/FDS_Verification_Guide.pdf        $pub_todir/.
