#!/bin/sh

CURDIR=`pwd`
cd ../../smv


git fetch firemodels pull/$1/head:test_$1
git branch -a