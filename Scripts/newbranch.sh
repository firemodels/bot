#!/bin/bash
branch=$1
repo=$2

if [[ "$branch" == "" ]] && [[ "$repo" == "" ]]; then
  echo "Usage: newbranch.sh branch repo"
  echo " create a branch in repo repo."
  echo ""
  echo " branch - branch to be created"
  echo " repo   - repo branch is created in (default: smv)"
  exit
fi

CURDIR=`pwd`

cd ../.. || exit 1
GITROOT=`pwd`

cd "$CURDIR" || exit 1

if [ "$repo" == "" ]; then
  repo=smv
fi
repodir=$GITROOT/$repo
if [ ! -d $repodir ]; then
  echo "***error: repo $repodir does not exist"
  exit 1
fi
if [ "$branch" == "" ]; then
  echo "***error: branch not specified"
  exit 1
fi

if ! push_urls=$(git -C "$repodir" remote get-url --push --all origin) || [[ -z "$push_urls" ]]; then
  echo "***error: Could not determine the origin push URL for $repodir." >&2
  exit 1
fi
if grep -Eiq '^([[:alpha:]][[:alnum:]+.-]*://([^/]*@)?github\.com(:[0-9]+)?/|([^/@]+@)?github\.com:)firemodels/' <<< "$push_urls"; then
  echo "WARNING: origin pushes to FireModels on GitHub. To create and publish the branch manually, run:"
  printf 'git -C %q checkout -b %q firemodels/master\n' "$repodir" "$branch"
  printf 'git -C %q push -u origin %q\n' "$repodir" "$branch"
  exit 1
fi

echo "Do you wish to create the branch: $branch in repo: $repo "
echo "Press any key to continue or <CTRL> c to abort."
read val

cd "$repodir" || exit 1
git checkout -b $branch firemodels/master
git push -u origin $branch


