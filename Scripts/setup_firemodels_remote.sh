#!/bin/bash

GITHEADER=`git remote -v | grep origin | head -1 | awk  '{print $2}' | awk -F ':' '{print $1}'`
if [ "$GITHEADER" == "git@github.com" ]; then
   GITHEADER="git@github.com:" 
   GITUSER=`git remote -v | grep origin | head -1 | awk -F ':' '{print $2}' | awk -F\/ '{print $1}'`
else
   GITHEADER="https://github.com/"
   GITUSER=`git remote -v | grep origin | head -1 | awk -F '.' '{print $2}' | awk -F\/ '{print $2}'`
fi
if [ "$GITUSER" == "firemodels" ]; then
   ndisable=`git remote -v | grep DISABLE | wc -l`
    if [ $ndisable -eq 0 ]; then
       echo disabling push access to firemodels
       git remote set-url --push origin DISABLE
    fi
else
   have_central=`git remote -v | awk '{print $1}' | grep firemodels | wc -l`
   if [ $have_central -eq 0 ]; then
      echo setting up remote tracking with firemodels
      git remote add firemodels ${GITHEADER}firemodels/$repo.git
      git remote update
   fi
   ndisable=`git remote -v | grep DISABLE | wc -l`
   if [ $ndisable -eq 0 ]; then
     echo "   disabling push access to firemodels"
     git remote set-url --push firemodels DISABLE
   else
     echo "   push access to firemodels already disabled"
   fi
fi
