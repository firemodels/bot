#!/bin/bash

uploads=$HOME/.bundle/uploads
if [ -e $uploads ]; then
  rm -rf $uploads
  echo cleaning $uploads on `hostname`
  mkdir $uploads
else
 echo ***error: upload directory does not exist
 mkdir -p $uploads
fi
