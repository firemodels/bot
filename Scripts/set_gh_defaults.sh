#!/bin/bash
REPODIR=$1
GHDEFAULT=$2

cd $REPODIR
gh repo set_default $GHDEFAULT
