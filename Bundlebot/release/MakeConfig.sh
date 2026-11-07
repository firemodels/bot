#!/bin/bash
# This script builds the configuration scripts used to build bundles
# A positional base_tag also sets the default SMV and CFAST tags.
# Usage: ./MakeConfig.sh [base_tag | -f base_tag | -b base_tag] [-o BASH|DOS] [-c cfast_tag] [-s smv_tag]

base_tag=6.11.2test
cfast_tag=8.0.0test
smv_tag=6.11.3test
OS=

if [ "$#" -gt 0 ] && [[ "$1" != -* ]]; then
  version=$1
  shift
  set -- -f "$version" -s "$version" -c "$version" "$@"
fi

while getopts ':b:c:f:o:s:' OPTION
do
  case "$OPTION" in
    b|f) base_tag=$OPTARG ;;
    c) cfast_tag=$OPTARG ;;
    s) smv_tag=$OPTARG ;;
    o) OS=$OPTARG ;;
    *)
      echo "Usage: $0 [base_tag | -f base_tag | -b base_tag] [-o BASH|DOS] [-c cfast_tag] [-s smv_tag]" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "$base_tag" ] || [ "$#" -ne 0 ]; then
  echo "Usage: $0 [base_tag | -f base_tag | -b base_tag] [-o BASH|DOS] [-c cfast_tag] [-s smv_tag]" >&2
  exit 1
fi

if [ "$smv_tag" == "" ]; then
  smv_tag=$base_tag
fi
if [ "$cfast_tag" == "" ]; then
  cfast_tag=$base_tag
fi

if [ "$OS" == "" ]; then
  BOTVERSION=`git describe --dirty --long`
  BOTHASH=`git rev-parse --short HEAD`
  export BOTVERSION BOTHASH
  ./MakeConfig.sh -b "$base_tag" -c "$cfast_tag" -s "$smv_tag" -o BASH > config.sh
  cp config.sh history/config_${base_tag}.sh
  ./MakeConfig.sh -b "$base_tag" -c "$cfast_tag" -s "$smv_tag" -o DOS  > config.bat
  cp config.bat history/config_${base_tag}.bat
  exit
fi
ERROR=1
if [ "$OS" == "DOS" ]; then
  ERROR=
fi
if [ "$OS" == "BASH" ]; then
  ERROR=
fi
if [ "$ERROR" != "" ]; then
  echo "***Error: found OS option $OS must be BASH, DOS or BOTH"
  exit
fi
if [ "$OS" == "BASH" ]; then
  HEAD="#!/bin/bash"
  COMMENT="#"
  EXPORT="export"
else
  HEAD="@echo off"
  COMMENT="::"
  EXPORT="set"
fi
export HEAD COMMENT EXPORT

repos="bot cad cfast exp fds fig out smv"
CURDIR=`pwd`
gitroot=$CURDIR/../../..
cd $gitroot
gitroot=`pwd`
cd $CURDIR

cat << EOF
$HEAD
$COMMENT This scripts defines revisions and tags for a bundle.
$COMMENT It is run by other BUILD scripts to define the environment.
$COMMENT ----------------------------
$COMMENT repo environment variables

EOF

for repo in $repos
do
cd $gitroot/$repo
REPOVERSION=`git describe --dirty --long`
HASH=`git rev-parse --short HEAD`
if [ "$repo" == "bot" ]; then
  REPOVERSION=$BOTVERSION
  HASH=$BOTHASH
fi
REPO=$(echo "$repo" | awk '{print toupper($0)}')
if [ "$repo" == "smv" ]; then
  TAG=$REPO-${smv_tag}
else
  if [ "$repo" == "cfast" ]; then
    TAG=$REPO-${cfast_tag}
  else
    TAG=$REPO-${base_tag}
  fi
fi
cat << EOF
$COMMENT $REPOVERSION
$EXPORT BUNDLE_${REPO}_HASH=$HASH
$EXPORT BUNDLE_${REPO}_TAG=$TAG

EOF
done
