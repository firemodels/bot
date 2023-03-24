#!/bin/bash
  DIRLIST="`ls -d $HOME/FireModels*`"
  for DIR in $DIRLIST ; do
    BASEDIR=`basename $DIR`
    echo
    echo ---------------------------------------------
    echo "*** $BASEDIR"
    echo ---------------------------------------------
    cd $DIR/bot/Scripts
    ./update_repos.sh
  done
