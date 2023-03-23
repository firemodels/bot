#!/bin/bash
  DIRLIST="`ls -d $HOME/FireModels*`"
  for DIR in $DIRLIST ; do
    echo
    echo ---------------------------------------------
    BASEDIR=`basename $DIR`
    echo *** $BASEDIR
    echo ---------------------------------------------
    cd $DIR/bot
    git remote update
    git merge origin/master
  done
