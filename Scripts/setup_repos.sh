#!/bin/bash

function usage {
echo "Create repos used by cfast, fds and/or smokview"
echo ""
echo "Options:"
echo "-a - setup all available repos: "
echo "    $allrepos"
echo "-c - setup repos used by cfastbot: "
echo "    $cfastrepos"
echo "-f - setup repos used by firebot: "
echo "    $fdsrepos"
echo "-F - setup repos used by firebot (erase each repo first): "
echo "    $firebotrepos"
echo "-G - only clone fds repo (erase first)"
echo "-H repo - only clone repo (erase first)"
echo "-h - display this message"
echo "-s - setup repos used by smokebot: "
echo "    $smvrepos"
echo "-S - setup repos used by smokebot (erase each repo first): "
echo "    $smvrepos"
echo "-t - append test to repo name, do not erase if repo exists"
echo "-T - only setup fds and smv repos (erase each repo first)"
echo "-U - only setup smv repo (erase each repo first)"
echo "-v - setup openvkl repo"
echo "-w - setup wiki and webpage repos cloned from firemodels"
exit
}

SETUP_REMOTE ()
{
  local repo_dir=$1

  basedir=`basename $repo_dir`
  if [ "$basedir" == "test7_bundles" ]; then
    exit
  fi
  cd $repo_dir
  if [ "$GITUSER" == "firemodels" ]; then
     ndisable=`git remote -v | grep DISABLE | wc -l`
     if [ $ndisable -eq 0 ]; then
        echo disabling push access to firemodels
        git remote set-url --push origin DISABLE
     fi
  else
     if [ "$repo" == "openvkl" ]; then
       CENTRAL=openvkl
     else
       CENTRAL=firemodels
     fi
     have_central=`git remote -v | awk '{print $1}' | grep $CENTRAL | wc -l`
     if [ $have_central -eq 0 ]; then
        echo setting up remote tracking with $CENTRAL
        git remote add $CENTRAL ${GITHEADER}$CENTRAL/$repo.git
        git remote update
     fi
     ndisable=`git remote -v | grep DISABLE | wc -l`
     if [ $ndisable -eq 0 ]; then
       echo "   disabling push access to $CENTRAL"
       git remote set-url --push $CENTRAL DISABLE
     else
       echo "   push access to $CENTRAL already disabled"
     fi
  fi
}

CURDIR=`pwd`

fdsrepos="cad exp fds fig out smv test_bundles test7_bundles"
fdssmvrepos="fds smv"
smvonlyrepos="smv"
firebotrepos="cad exp fds fds-smv fig out smv test_bundles"
smvrepos="cfast fds fig smv test_bundles test7_bundles"
vklrepos="openvkl"
cfastrepos="cfast exp fig smv test_bundles test7_bundles"
allrepos="cad cfast cor exp fds fig out radcal smv test_bundles test7_bundles"
wikiwebrepos="fds.wiki fds-smv"
repos=$fdsrepos
eraserepos=
FORCECLONE=
APPENDTEST=

FMROOT=
WIKIWEB=
if [ -e ../.gitbot ]; then
   cd ../..
   FMROOT=`pwd`
else
   echo "***Error: this script must be run from the bot/Scripts directory"
   exit
fi

while getopts 'abcCfFGH:hsStTUvw' OPTION
do
case $OPTION  in
  a)
   repos=$allrepos;
   ;;
  c)
   repos=$cfastrepos;
   ;;
  C)
   FORCECLONE=1;
   ;;
  f)
   repos=$fdsrepos;
   ;;
  F)
   repos=$firebotrepos;
   eraserepos=1
   ;;
  G)
   repos=fds;
   eraserepos=1;
   ;;
  H)
   repos="$OPTARG";
   if [ "$repos" != "smv" ]; then
     repos="fds"
   fi
   eraserepos=1;
   ;;
  h)
   usage;
   ;;
  s)
   repos=$smvrepos;
   ;;
  S)
   repos=$smvrepos;
   ;;
  t)
   APPENDTEST=_test
   eraserepos=
   ;;
  T)
   repos=$fdssmvrepos;
   eraserepos=1
   ;;
  U)
   repos=$smvonlyrepos;
   eraserepos=1
   ;;
  v)
   repos=$vklrepos;
   ;;
  w)
   repos=$wikiwebrepos;
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$APPENDTEST" != "" ]; then
  eraserepos=
fi

cd $FMROOT/bot
GITHEADER=`git remote -v | grep origin | head -1 | awk  '{print $2}' | awk -F ':' '{print $1}'`
if [ "$GITHEADER" == "git@github.com" ]; then
   GITHEADER="git@github.com:" 
   GITUSER=`git remote -v | grep origin | head -1 | awk -F ':' '{print $2}' | awk -F\/ '{print $1}'`
else
   GITHEADER="https://github.com/"
   GITUSER=`git remote -v | grep origin | head -1 | awk -F '.' '{print $2}' | awk -F\/ '{print $2}'`
fi
echo GITHEADER=$GITHEADER
echo GITUSER=$GITUSER

if [ "$eraserepos" == "" ]; then
  if [ "$FORCECLONE" == "" ]; then
    echo "You are about to clone the repos: $repos"
  else
    echo "You are cloning the repos: $repos"
  fi
  if [ "$WIKIWEB" == "1" ]; then
     echo "from git@github.com:firemodels into the directory: $FMROOT"
  else
     echo "from $GITHEADER$GITUSER into the directory: $FMROOT"
  fi
  if [ "$FORCECLONE" == "" ]; then
    echo ""
    echo "Press any key to continue or <CTRL> c to abort."
    echo "Type $0 -h for other options"
    read val
  fi
fi

for repo in $repos
do 
  echo
  repo_out=$repo$APPENDTEST
  WIKIWEB=

  cd $FMROOT

  echo "----------------------------------------------"
  if [ "$repo" == "fds.wiki" ]; then
     repo_out=wikis
     WIKIWEB=1
  fi
  if [ "$repo" == "fds-smv" ]; then
     repo_out=webpages
     WIKIWEB=1
  fi
  repo_dir=$FMROOT/$repo_out
  if [ "$eraserepos" == "" ]; then
    if [ -e $repo_dir ]; then
       echo "   For repo $repo, the directory $repo_dir already exists"
       continue;
    fi
  fi

  echo repo: $repo_out
  if [ "$eraserepos" == "1" ]; then
    if [ -e $repo_out ]; then
      echo removing $repo_out
      rm -rf $repo_out
      if [ -e $repo_out ]; then
         echo "***error: the directory $repo_out failed to be removed"
      fi
    fi
  fi
  if [ "$WIKIWEB" == "1" ]; then
     cd $FMROOT
     git clone ${GITHEADER}firemodels/$repo.git $repo_out
     if [ ! -d $repo_out ]; then
        echo "***error: clone of $repo.git to $repo_out failed"
     fi
     continue
  fi

  AT_GITHUB=`git ls-remote $GITHEADER$GITUSER/$repo.git 2>&1 > /dev/null | grep ERROR | wc -l`
  if [ $AT_GITHUB -gt 0 ]; then
     echo "***Error: The repo $GITHEADER$GITUSER/$repo.git was not found."
     continue;
  fi 
  
  RECURSIVE=
  if [ "$repo" == "exp" ]; then
     RECURSIVE=--recursive
  fi
  git clone $RECURSIVE $GITHEADER$GITUSER/$repo.git $repo_out
  if [ ! -d $repo_out ]; then
    echo "***error: clone of $repo.git to $repo_out failed"
  fi

  SETUP_REMOTE $repo_dir

done
cd $CURDIR
