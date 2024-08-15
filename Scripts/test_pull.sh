#!/bin/sh
id=$1
repo=$2

if [ "$repo" == "" ]; then
  repo=smv
fi

CURDIR=`pwd`
cd ../../$repo


git fetch firemodels pull/$id/head:test_$id
git branch -a
git checkout test_$id

