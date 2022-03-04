#!/bin/bash
if [ -d TESTDIR ]; then
  cd TESTDIR
  rm -rf */.git
  git clean -dxf
else
  echo ***error:: TESTDIR does not exist
fi
