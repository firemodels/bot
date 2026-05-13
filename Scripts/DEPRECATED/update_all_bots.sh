#!/bin/bash
  DIRLIST="`ls -d $HOME/FireModels*`"
  for DIR in $DIRLIST ; do
    BASEDIR=`basename $DIR`
    echo
    echo ---------------------------------------------
    echo "*** $BASEDIR"
    echo ---------------------------------------------
    echo DIR=$DIR
    cd $DIR/bot
    git remote update
    git merge origin/master
  done
