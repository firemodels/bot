#!/bin/bash
  DIRLIST="`ls -d $HOME/FireModels*`"
  for DIR in $DIRLIST ; do
    BASEDIR=`basename $DIR`
    echo
    echo ---------------------------------------------
    echo "*** $BASEDIR"
    echo ---------------------------------------------
    echo DIR=$DIR
    cd $DIR/bot/Scripts
    ./prune_repos.sh
  done
