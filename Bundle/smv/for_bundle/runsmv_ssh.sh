#!/bin/bash
smokeview=$1
DIR=$2
case=$3

cd $DIR
$smokeview -runhtmlscript $case
