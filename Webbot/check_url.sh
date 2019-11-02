#!/bin/bash
webpage=$1

sed -n 's/.*href="\([^"]*\).*/\1/p' $webpage | grep http | while read -ru 4 LINE; do
  read -r REP < <(exec curl -IsS "$LINE" 2>&1)
  echo "$LINE: $REP"
done 4< "$1"
