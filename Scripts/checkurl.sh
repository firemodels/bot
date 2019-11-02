#!/bin/bash
while read -ru 4 LINE; do
  read -r REP < <(exec curl -IsS "$LINE" 2>&1)
  echo "$LINE: $REP"
done 4< "$1"
