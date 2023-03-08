#!/bin/bash
REPODIR=$1
GHDEFAULT=$2

cd $REPODIR
gh repo set-default $GHDEFAULT
