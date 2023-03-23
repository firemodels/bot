#!/bin/bash
  DIRLIST="`ls -d $HOME/FireModels*`"
  for DIR in $DIRLIST ; do
    echo
    echo ---------------------------------------------
    BASEDIR=`basename $DIR`
    echo ***Updating repos in $BASEDIR
    echo ---------------------------------------------
    cd $DIR/smv
    git branch -a
  done
