#!/bin/bash
opt=$1

if [ "$opt" != "-h" ]; then
  echo "*** updating bot repo"
  git clean -dxf          >& /dev/null
  git remote update       >& /dev/null
  git merge origin/master >& /dev/null
fi
./smvbundle.sh $*

