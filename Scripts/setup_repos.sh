#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CURDIR=`pwd`
cd $SCRIPTDIR/../../bot
BOTREPO=`pwd`
cd $CURDIR

function usage {
echo "Create repos used by cfast, fds and/or smokview"
echo ""
echo "Options:"
echo "-3 - setup 3rd part repos:"
echo "    $thirdpartyrepos"
echo "-a - setup all available repos: "
echo "    $allrepos"
echo "-A - setup all available repos (erase each repo first): "
echo "    $allrepos"
echo "-B - setup repos used by cfast (erase each repo first): "
echo "    $cfastrepos"
echo "-c - setup repos used by cfastbot: "
echo "    $cfastbotrepos"
echo "-D - enable access to firemodels (ie allow git push)"
echo "-f - setup repos used by firebot: "
echo "    $fdsrepos"
echo "-F - setup repos used by firebot (erase each repo first): "
echo "    $firebotrepos"
echo "-G - only clone fds repo (erase first)"
echo "-H repo - only clone repo (erase first)"
echo "-h - display this message"
echo "-R - erase repos first"
echo "-s - setup repos used by smokebot: "
echo "    $smvrepos"
echo "-S - setup repos used by smokebot (erase each repo first): "
echo "    $smvrepos"
echo "-t - append test to repo name, do not erase if repo exists"
echo "-T - only setup fds and smv repos (erase each repo first)"
echo "-U - only setup smv repo (erase each repo first)"
echo "-w - setup wiki and webpage repos cloned from firemodels"
exit
}

SETUP_REMOTE ()
{
  local repo_dir=$1

  basedir=`basename $repo_dir`
  cd $repo_dir
  CENTRAL=firemodels
  if [ "$repo" == "hypre" ]; then
    CENTRAL=hypre-space
  fi
  if [ "$repo" == "sundials" ]; then
    CENTRAL=LLNL
  fi
  if [ "$repo" == "ompi" ]; then
    CENTRAL=open-mpi
  fi
  if [ "$GITUSER" == "firemodels" ]; then
     if [ "$DISABLEPUSH" != "" ]; then
       ndisable=`git remote -v | grep DISABLE | wc -l`
       if [ $ndisable -eq 0 ]; then
          echo disabling push access to $CENTRAL
          git remote set-url --push origin DISABLE
       fi
     fi
  else
     have_central=`git remote -v | awk '{print $1}' | grep $CENTRAL | wc -l`
     if [ $have_central -eq 0 ]; then
        echo setting up remote tracking with $CENTRAL
        git remote add $CENTRAL ${GITHEADER}$CENTRAL/$repo.git
        git remote update
     fi
     if [ "$DISABLEPUSH" != "" ]; then
       ndisable=`git remote -v | grep DISABLE | wc -l`
       if [ $ndisable -eq 0 ]; then
         echo "   disabling push access to $CENTRAL"
         git remote set-url --push $CENTRAL DISABLE
       else
         echo "   push access to $CENTRAL already disabled"
       fi
     fi
  fi
}

#------------------- start of script ---------------------------

CURDIR=`pwd`

configrepos="cad exp fds fig out smv"
fdsrepos="cad exp fds fig out smv test_bundles"
thirdpartyrepos="hypre sundials"
#thirdpartyrepos="hypre sundials ompi"
fdssmvrepos="fds smv"
smvonlyrepos="smv"
fdsonlyrepos="fds"
firebotrepos="cad exp fds fds-smv fig out smv test_bundles"
smvrepos="cfast fds fig smv test_bundles"
cfastbotrepos="cfast exp fig smv test_bundles"
cfastrepos="cfast exp smv"
allrepos="cad cfast cor exp fds fig out radcal smv test_bundles"
wikiwebrepos="fds.wiki fds-smv"
repos=$fdsrepos
eraserepos=
FORCECLONE=
APPENDTEST=
DISABLEPUSH=1

FMROOT=
WIKIWEB=
if [ -e ../.gitbot ]; then
   cd ../..
   FMROOT=`pwd`
else
   echo "***Error: this script must be run from the bot/Scripts directory"
   exit
fi

while getopts '3aABbcCDefFGH:hsRStTUVw' OPTION
do
case $OPTION  in
  3)
   repos=$thirdpartyrepos;
   ;;
  a)
   repos=$allrepos;
   ;;
  A)
   repos=$allrepos;
   eraserepos=1
   ;;
  b)
   repos=$configrepos
   eraserepos=1
   CONFIG_REPOS=1
   ;;
  B)
   repos=$cfastrepos;
   eraserepos=1
   ;;
  c)
   repos=$cfastbotrepos;
   ;;
  C)
   FORCECLONE=1;
   ;;
  D)
   DISABLEPUSH=
   ;;
  e)
   eraserepos=1
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
  R)
   eraserepos=1
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
  V)
   repos=$fdsonlyrepos;
   eraserepos=1
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
if [ "$CONFIG_REPOS" != "" ]; then
  source $BOTREPO/Bundlebot/release/config.sh
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

  GITOWNER=$GITUSER
  if [ "$GITUSER" == "firemodels" ]; then
    if [ "$repo" == "hypre" ]; then
      GITOWNER=hypre-space
    fi
    if [ "$repo" == "sundials" ]; then
      GITOWNER=LLNL
    fi
    if [ "$repo" == "ompi" ]; then
      GITOWNER=open-mpi
    fi
  fi

  AT_GITHUB=`git ls-remote $GITHEADER$GITOWNER/$repo.git 2>&1 > /dev/null | grep ERROR | wc -l`
  if [ $AT_GITHUB -gt 0 ]; then
     echo "***Error: The repo $GITHEADER$GITOWNER/$repo.git was not found."
     continue;
  fi 
  
  RECURSIVE=
  if [ "$repo" == "exp" ]; then
     RECURSIVE=--recursive
  fi
  if [ "$repo" != "bot" ]; then
    git clone $RECURSIVE $GITHEADER$GITOWNER/$repo.git $repo_out
    if [ ! -d $repo_out ]; then
      echo "***error: clone of $repo.git to $repo_out failed"
    fi
  fi
  if [ "$CONFIG_REPOS" != "" ]; then
    if [ "$repo" == "cad" ]; then
      TAG=$BUNDLE_CAD_TAG
      REVISION=$BUNDLE_CAD_REVISION
    fi
    if [ "$repo" == "exp" ]; then
      TAG=$BUNDLE_EXP_TAG
      REVISION=$BUNDLE_EXP_REVISION
    fi
    if [ "$repo" == "fds" ]; then
      TAG=$BUNDLE_FDS_TAG
      REVISION=$BUNDLE_FDS_REVISION
    fi
    if [ "$repo" == "fig" ]; then
      TAG=$BUNDLE_FIG_TAG
      REVISION=$BUNDLE_FIG_REVISION
    fi
    if [ "$repo" == "out" ]; then
      TAG=$BUNDLE_OUT_TAG
      REVISION=$BUNDLE_OUT_REVISION
    fi
    if [ "$repo" == "smv" ]; then
      TAG=$BUNDLE_SMV_TAG
      REVISION=$BUNDLE_SMV_REVISION
    fi
#    REPO="${repo^^}"
    if [[ "$TAG" != "" ]] && [[ "$REVISION" != "" ]] && [[ -d $repo_out ]]; then
      cd $repo_out
      echo git checkout -b release $REVISION
      git checkout -b release $REVISION
      echo git tag -a $TAG -m "tag for $TAG"
      git tag -a $TAG -m "tag for $TAG"
    fi
  fi
  SETUP_REMOTE $repo_dir
done
cd $CURDIR
