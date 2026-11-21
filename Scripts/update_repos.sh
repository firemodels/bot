#!/bin/bash
allrepos="bot cad cfast cor exp fds fig out radcal smv test_bundles"
updaterepos=$allrepos
otherrepos="webpages wikis"
BRANCH=master
CHECKOUT_MASTER=
STATUS_ONLY=
PAUSE=10
push_warnings=()

function usage {
echo "Update the repos $allrepos if they exist"
echo ""
echo "Options:"
echo "-b - update only bot repo"
echo "-h - display this message"
echo "-m - checkout master branch before updating"
echo "-s - run git status -uno without updating"
echo "-w - update only webpages and wikis repos"
exit
}

FMROOT=
WEBWIKI_ONLY=
if [ -e ../.gitbot ]; then
   cd ../..
   FMROOT=`pwd`
else
   echo "***error: this script must be run from the bot/Scripts directory"
   exit
fi

while getopts 'bhmsw' OPTION
do
case $OPTION  in
  b)
   updaterepos=bot
   ;;
  h)
   usage;
   ;;
  m)
   CHECKOUT_MASTER=1
   ;;
  s)
   STATUS_ONLY=1
   ;;
  w)
   WEBWIKI_ONLY=1
   ;;
esac
done
shift $(($OPTIND-1))

UPDATE_REPO ()
{
  local repo=$1
  repodir=$FMROOT/$repo
  if [ -z "$STATUS_ONLY" ]; then
    echo pausing $PAUSE s
    sleep $PAUSE
  fi

  echo "------------- $repo -------------------------------------------"
  if [ ! -e $repodir ]; then
     echo "Skipping, $repo does not exist"
     return
  fi
  if [ -n "$STATUS_ONLY" ]; then
     git -C "$repodir" status -uno
     return
  fi
  cd $repodir
  if [ "$CHECKOUT_MASTER" != "" ]; then
    git checkout master
  fi 
  CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
  if [ "$BRANCH" != "$CURRENT_BRANCH" ]; then
    echo "Skipping, found branch $CURRENT_BRANCH, expecting branch $BRANCH"
    return
  fi
  echo ""
  echo "***  updating from origin"
  echo "     branch: $BRANCH"
  echo "     dir: $repodir"

  git remote update
  git merge origin/$BRANCH
  have_central=`git remote -v | awk '{print $1}' | grep firemodels | wc  -l`
  if [ "$have_central" -gt "0" ]; then
     echo ""
     echo "*** updating from firemodels"
     echo "    branch: $BRANCH"
     echo "    dir: $repodir"
     git merge firemodels/$BRANCH
     ahead=`git status -uno | grep ahead | wc -l`
     if [ "$ahead" -gt "0" ]; then
        local push_command
        printf -v push_command 'git -C %q push origin %q' "$repodir" "$BRANCH"
        local push_warning="WARNING: A git push is required to sync $repo origin/$BRANCH with firemodels/$BRANCH."
        printf '%s\n' "" "$push_warning" "$push_command"
        push_warnings+=("" "$push_warning" "$push_command")
     fi
  fi
  if [[ "$repo" == "exp" ]]; then
     git submodule foreach git remote update
     git submodule foreach git merge origin/master
  fi
}

UPDATE_REPO2 ()
{
  local repo=$1
  repodir=$FMROOT/$repo
  if [ -z "$STATUS_ONLY" ]; then
    echo pausing $PAUSE s
    sleep $PAUSE
  fi

  if [ ! -e $repodir ]; then
     return
  fi
  echo "------------- $repo -------------------------------------------"
  if [ -n "$STATUS_ONLY" ]; then
     git -C "$repodir" status -uno
     return
  fi
  cd $repodir
  if [ "$CHECKOUT_MASTER" != "" ]; then
    git checkout master
  fi 
  BRANCH=`git rev-parse --abbrev-ref HEAD`
  echo ""
  echo "***  updating from firemodels"
  echo "     branch: $BRANCH"
  echo "     dir: $repodir"
  echo ""
  git fetch origin
  git merge origin/$BRANCH
  git status -uno
}

if [ "$WEBWIKI_ONLY" == "" ]; then
  for repo in $updaterepos
  do 
    echo
    UPDATE_REPO $repo
  done
else
  for repo in $otherrepos
  do 
    echo
    UPDATE_REPO2 $repo
  done
fi
if [ -n "$STATUS_ONLY" ]; then
  echo status complete
else
  echo update complete
fi
if [ "${#push_warnings[@]}" -gt 0 ]; then
  printf '%s\n' "${push_warnings[@]}"
fi
