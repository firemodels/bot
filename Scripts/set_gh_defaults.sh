#!/bin/bash
REPOROOT=$1
REPO=$2
REPOUSER=$3

cd $REPOROOT/$REPO
gh repo set-default $REPOUSER/$REPO
gh repo set-default $REPOUSER/$REPO -v

