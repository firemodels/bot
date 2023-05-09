#!/bin/bash

REPOROOT=~firebot/FireModels_clone
FROMDIR=$REPOROOT/fds/Verification/Complex_Geometry
EXT_DIR=output/ext_fds_dir
EXT_DOC=output/ext_fds_doc
GIT_OUT=output/gitout
FDSUG=$REPOROOT/fds/Manuals/FDS_User_Guide/FDS_User_Guide.tex
ls -l $FROMDIR | sed 1,1d - | grep -v drwx | awk '{print $NF}' | awk -F'.' '{print $NF}' | sort -u > $EXT_DIR
grep -E 'fdsext|smvext|qfdsext|ignoreext' $FDSUG | awk '{print $NF}' | sort -u > $EXT_DOC
git diff --no-index $EXT_DIR  $EXT_DOC > $GIT_OUT
ndoc=`grep ^- $GIT_OUT | sed 's/^-//g'  | grep -v  output | wc -l`
if [ $ndoc -gt 0 ]; then
  echo The following extentions are not documented
  grep ^- $GIT_OUT | sed 's/^-//g'  | grep -v  output
else
  echo All extensions found in the directory $FROMDIR
  echo were found in %fdsext, %smvext or %qfdsext lines in the document:
  echo $FDSUG
fi
ndir=`grep ^+ $GIT_OUT | sed 's/^+//g'  | grep -v  output | wc -l`
if [ $ndir -gt 0 ]; then
  echo the following extensions are documented but not found in $FROMDIR
  grep ^+ $GIT_OUT | sed 's/^+//g'  | grep -v  output
fi
