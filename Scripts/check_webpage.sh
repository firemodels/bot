#!/bin/bash
webpage=$1

# get directory this (and checkurl.sh) script is run in
args=$0
DIR=$(dirname "${args}")
cd $DIR
DIR=`pwd`


links=/tmp/links.$$
results=/tmp/results.$$

sed -n 's/.*href="\([^"]*\).*/\1/p' $webpage  | grep http > $links
$DIR/checkurl.sh $links | grep -v 200 | grep -v 302 > $results
nresults=`cat $results | wc -l`
if [ "$nresults" == "0" ]; then
  echo all links in $webpage are good
else
  echo "***error: $nresults broken links in $webpage:"
  cat $results
fi
rm -f $links
rm -f $results
