#!/bin/bash
  DIRLIST="`ls -d $HOME/FireModels*`"
  for DIR in $DIRLIST ; do
    echo
    echo ---------------------------------------------
    BASEDIR=`basename $DIR`
    echo "*** $BASEDIR"
    echo ---------------------------------------------
    echo -- fds branches
    cd $DIR/fds
    git branch -a
    echo -- smv branches
    cd $DIR/smv
    git branch -a
  done
