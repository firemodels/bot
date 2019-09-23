#!/bin/bash

uploads=$HOME/.bundle/uploads
if [ -e $uploads ]; then
  cd $uploads
  rm -rf upload
  echo cleaning $uploads
  mkdir upload
else
 echo ***error: upload directory does not exist
fi
