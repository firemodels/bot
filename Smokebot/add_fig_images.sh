#!/bin/bash
HTMLBASE=clonef
CURDIR=`pwd`
TODIR=../../fig/smv/Reference_Figures
cd $TODIR
TODIR=`pwd`
FROMBASE=/var/www/html/`whoami`/$HTMLBASE/diffs/base
cd $FROMBASE/user
USERFILES=`ls *.png`
cd $FROMBASE/verification
VERFILES=`ls *.png`
cd $TODIR
for f in $USERFILES
do
git add $f
done
for f in $VERFILES
do
git add $f
done
git checkout *.png

