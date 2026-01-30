#!/bin/bash
PROGRAM=$1

if [ -e $PROGRAM ]; then
  echo signing $PROGRAM
  gpg --output $PROGRAM.sig --armor --detach-sig $PROGRAM
  echo verifying $PROGRAM
  gpg --verify $PROGRAM.sig $PROGRAM
else
  echo ***error: $PROGRAM does not exist
fi
