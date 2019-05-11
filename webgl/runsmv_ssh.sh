#!/bin/bash
command=$1
DIR=$2
case=$3
cd $DIR
$command -runscript $case

