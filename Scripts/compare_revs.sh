#!/bin/bash
REPO1=$1
REPO2=$2
if [ "$REPO1" == "firebot" ]; then
  REPO1=~firebot/FireModels_clone
fi
if [ "$REPO1" == "smokebot" ]; then
  REPO1=~smokebot/FireModels_central
fi
if [ "$REPO2" == "" ]; then
  REPO2=$HOME/FireModels_clonef
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
