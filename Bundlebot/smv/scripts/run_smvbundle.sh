#!/bin/bash

echo "*** updating bot repo"
git clean -dxf          >& /dev/null
git remote update       >& /dev/null
git merge origin/master >& /dev/null
./smvbundle.sh $*

