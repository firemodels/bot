#!/bin/bash
webdir=$1
webpage=$2

# get directory this (and checkurl.sh) script is run in
args=$0

curdir=`pwd`
DIR=$(dirname "${args}")
cd $DIR
DIR=`pwd`

links=/tmp/links.$$
results=/tmp/results.$$

cd $webdir
sed -n 's/.*href="\([^"]*\).*/\1/p' $webpage  | grep http > $links
$DIR/check_url.sh $links | grep -v 200 | grep -v 302 | grep -v '301 Moved Permanently' > $results
nresults=`cat $results | wc -l`
if [ $nresults -gt 0 ]; then
  echo "***error: $nresults broken links in $webpage:"
  cat $results
else
  echo all links in $webpage are good
fi
rm -f $links
rm -f $results
cd $curdir
