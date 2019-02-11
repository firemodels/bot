#!/bin/bash
pubhost=$1
pubhome=$2
pub_todir=$3

source ../scripts/GET_ENV.sh

mkdir -p $pub_todir
pubdir=$pubhome/.smokebot/pubs
scp -q $pubhost\:$pubdir/SMV_Technical_Reference_Guide.pdf $pub_todir/.
scp -q $pubhost\:$pubdir/SMV_User_Guide.pdf                $pub_todir/.
scp -q $pubhost\:$pubdir/SMV_Verification_Guide.pdf        $pub_todir/.
