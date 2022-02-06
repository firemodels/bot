#!/bin/bash
REPO1=$1
REPO2=$2
CURDIR=`pwd`
if [ "$REPO1" == "firebot" ]; then
  REPO1=~firebot/FireModels_clone
fi
if [ "$REPO1" == "smokebot" ]; then
  REPO1=~smokebot/FireModels_central
fi
if [ "$REPO2" == "" ]; then
  cd ../..
  REPO2=`pwd`
  cd $CURDIR
fi
abort=
if [ ! -d $REPO1 ]; then
  echo "***error: $REPO1 does not exist"
  abort=1
fi
if [ ! -d $REPO2 ]; then
  echo "***error: $REPO2 does not exist"
  abort=1
fi
if [ "$abort" != "" ]; then
  exit
fi

REPOS="bot fds fig smv exp out"
echo ""
echo "comparing $REPOS repos in:"
echo REPO1=$REPO1
echo REPO2=$REPO2
for dir in bot fds fig smv exp out; do
echo ""
if [[ -d $REPO1/$dir ]] && [[ -d $REPO2/$dir ]]; then
  cd $REPO1/$dir
  git describe --dirty --long
  cd $REPO2/$dir
  git describe --dirty --long
else
  if [ ! -d $REPO1/$dir ]; then
    echo "***errror: the directory $REPO1/$dir does not exist"
  fi
  if [ ! -d $REPO2/$dir ]; then
    echo "***errror: the directory $REPO2/$dir does not exist"
  fi
fi
done
