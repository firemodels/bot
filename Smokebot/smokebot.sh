#!/bin/bash

# The Smokebot script is part of an automated continuous integration system.
# Consult the FDS Config Management Plan for more information.

#---------------------------------------------
#                   CHK_REPO
#---------------------------------------------

CHK_REPO ()
{
  local repodir=$1
  
  if [ ! -e $repodir ]; then
     echo "***error: the repo directory $repodir does not exist."
     echo "          Aborting smokebot."
     return 1
  fi
  return 0
}

#---------------------------------------------
#                   CD_REPO
#---------------------------------------------

CD_REPO ()
{
  local repodir=$1
  local branch=$2
  
  CHK_REPO $repodir || return 1

  cd $repodir
  if [ "$branch" != "current" ]; then
    if [ "$branch" != "" ]; then
       CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
       if [ "$CURRENT_BRANCH" != "$branch" ]; then
         echo "***error: was expecting branch $branch in repo $repodir."
         echo "Found branch $CURRENT_BRANCH. Aborting smokebot."
         return 1
       fi
    fi
  fi
  return 0
}

#---------------------------------------------
#                   run_auto
#---------------------------------------------

run_auto()
{
  local option=$1
  
  GIT_STATUS_DIR=~/.smokebot

  SMV_SOURCE_DIR=$smvrepo/Source
  GIT_SMV_REVISION_FILE=$GIT_STATUS_DIR/smv_revision
  GIT_SMV_LOG_FILE=$GIT_STATUS_DIR/smv_log

  FDS_SOURCE_DIR=$fdsrepo/Source
  GIT_FDS_REVISION_FILE=$GIT_STATUS_DIR/fds_revision
  GIT_FDS_LOG_FILE=$GIT_STATUS_DIR/FDS_log

  ROOT_DIR=$smvrepo/Verification
  GIT_ROOT_REVISION_FILE=$GIT_STATUS_DIR/root_revision
  GIT_ROOT_LOG_FILE=$GIT_STATUS_DIR/ROOT_log

  MESSAGE_FILE=$GIT_STATUS_DIR/message

  MKDIR $GIT_STATUS_DIR

  if [[ "$UPDATEREPO" == "1" ]] ; then
    update_repo smv $SMVBRANCH || return 1
    update_repo fig master     || return 1
    update_repo fds $FDSBRANCH || return 1
  fi

# get info for smokeview source directory
  cd $SMV_SOURCE_DIR
  THIS_SMVAUTHOR=`git log . | head -2 | tail -1 | awk '{print $2}'`
  if [ ! -e $GIT_SMV_REVISION_FILE ]; then
    touch $GIT_SMV_REVISION_FILE
  fi
  THIS_SMV_REVISION=`git log --abbrev-commit . | head -1 | awk '{print $2}'`
  LAST_SMV_REVISION=`cat $GIT_SMV_REVISION_FILE`
  git log . | head -5 | tail -1 > $GIT_SMV_LOG_FILE

# get info for FDS source directory
  cd $FDS_SOURCE_DIR
  THIS_FDSAUTHOR=`git log . | head -2 | tail -1 | awk '{print $2}'`
  if [ ! -e $GIT_FDS_REVISION_FILE ]; then
    touch $GIT_FDS_REVISION_FILE
  fi
  THIS_FDS_REVISION=`git log --abbrev-commit . | head -1 | awk '{printf $2}'`
  LAST_FDS_REVISION=`cat $GIT_FDS_REVISION_FILE`
  git log . | head -5 | tail -1 > $GIT_FDS_LOG_FILE

# get info for ROOT directory
  cd $ROOT_DIR
  THIS_ROOTAUTHOR=`git log . | head -2 | tail -1 | awk '{print $2}'`
  THIS_ROOT_REVISION=`git log --abbrev-commit . | head -1 | awk '{printf $2}'`
  LAST_ROOT_REVISION=`cat $GIT_ROOT_REVISION_FILE`
  git log . | head -5 | tail -1 > $GIT_ROOT_LOG_FILE

  if [ "$option" == "" ]; then
    if [[ $THIS_SMV_REVISION == $LAST_SMV_REVISION && $THIS_FDS_REVISION == $LAST_FDS_REVISION &&  $THIS_ROOT_REVISION == $LAST_ROOT_REVISION ]] ; then
      return 1
    fi
  fi
  if [ "$option" == "smv" ]; then
    if [[ $THIS_SMV_REVISION == $LAST_SMV_REVISION ]] ; then
      return 1
    fi
  fi

  rm -f $MESSAGE_FILE
  if [ "$option" == "" ]; then
    SOURCE_CHANGED=
    if [[ $THIS_SMV_REVISION != $LAST_SMV_REVISION ]] ; then
      SOURCE_CHANGED=1
      echo $THIS_SMV_REVISION>$GIT_SMV_REVISION_FILE
      echo -e "smokeview source has changed. $LAST_SMV_REVISION->$THIS_SMV_REVISION($THIS_SMVAUTHOR)" >> $MESSAGE_FILE
      cat $GIT_SMV_LOG_FILE >> $MESSAGE_FILE
    fi
    if [[ $THIS_FDS_REVISION != $LAST_FDS_REVISION ]] ; then
      SOURCE_CHANGED=1
      echo $THIS_FDS_REVISION>$GIT_FDS_REVISION_FILE
      echo -e "FDS source has changed. $LAST_FDS_REVISION->$THIS_FDS_REVISION($THIS_FDSAUTHOR)" >> $MESSAGE_FILE
      cat $GIT_FDS_LOG_FILE >> $MESSAGE_FILE
    fi
    if [ "$SOURCE_CHANGED" == "" ]; then
      if [[ $THIS_ROOT_REVISION != $LAST_ROOT_REVISION ]] ; then
        echo $THIS_ROOT_REVISION>$GIT_ROOT_REVISION_FILE
        echo -e "smv repo has changed. $LAST_ROOT_REVISION->$THIS_ROOT_REVISION($THIS_ROOTAUTHOR)" >> $MESSAGE_FILE
        cat $GIT_ROOT_LOG_FILE >> $MESSAGE_FILE
      fi
    fi
  fi
  if [ "$option" == "smv" ]; then
    if [[ $THIS_SMV_REVISION != $LAST_SMV_REVISION ]] ; then
      echo $THIS_SMV_REVISION>$GIT_SMV_REVISION_FILE
      echo -e "smokeview source has changed. $LAST_SMV_REVISION->$THIS_SMV_REVISION($THIS_SMVAUTHOR)" >> $MESSAGE_FILE
      cat $GIT_SMV_LOG_FILE >> $MESSAGE_FILE
    fi
  fi
  echo -e "Smokebot run initiated." >> $MESSAGE_FILE
  cat $MESSAGE_FILE | mail -s "smokebot run initiated" $mailTo > /dev/null
  return 0
}

#---------------------------------------------
#                   GET_TIM
#---------------------------------------------

GET_TIME(){
  echo $(date +"%s")
}

#---------------------------------------------
#                   GET_DURATION
#---------------------------------------------

GET_DURATION(){
  local time_before=$1
  local time_after=$2
  
  DIFF_TIME=`echo $(($time_after-$time_before))`
  TIME_H=`echo $(($DIFF_TIME / 3600 ))`
  TIME_M=`echo $((($DIFF_TIME % 3600 ) / 60))`
  TIME_S=`echo $(($DIFF_TIME % 60 ))`
  if (( "$DIFF_TIME" >= 3600 )) ; then
    echo "${TIME_H}h ${TIME_M}m ${TIME_S}s"
  else
    if (( "$DIFF_TIME" >= 60 )) ; then
      echo "${TIME_M}m ${TIME_S}s"
    else
      echo "${TIME_S}s"
    fi
  fi
}

#---------------------------------------------
#                   MKDIR
#---------------------------------------------

MKDIR ()
{
  local DIR=$1
  
  if [ ! -d $DIR ]
  then
    echo Creating directory $DIR
    mkdir -p $DIR
  fi
}

#---------------------------------------------
#                   check_time_limit
#---------------------------------------------

check_time_limit()
{
   if [ "$TIME_LIMIT_EMAIL_NOTIFICATION" == "sent" ]
   then
      # Continue along
      :
   else
      CURRENT_TIME=$(date +%s)
      ELAPSED_TIME=$(echo "$CURRENT_TIME-$START_TIME"|bc)

      if [ $ELAPSED_TIME -gt $TIME_LIMIT ]
      then
         echo -e "smokebot has been running for more than 12 hours in Stage ${TIME_LIMIT_STAGE}. \n\nPlease ensure that there are no problems. \n\nThis is a notification only and does not terminate smokebot." | mail -s "smokebot Notice: smokebot has been running for more than 12 hours." $mailTo > /dev/null
         TIME_LIMIT_EMAIL_NOTIFICATION="sent"
      fi
   fi
}

#---------------------------------------------
#                   set_files_world_readable
#---------------------------------------------

set_files_world_readable()
{
   CD_REPO $smvrepo $SMVBRANCH || return 1
   chmod -R go+r *

   CD_REPO $fdsrepo $FDSBRANCH || return 1
   chmod -R go+r *

   return 0
}

#---------------------------------------------
#                   clean_repo
#---------------------------------------------

clean_repo()
{
  curdir=`pwd`
  local dir=$1
  local branch=$2
  
  CD_REPO $dir $branch || return 1
  git clean -dxf &> /dev/null
  git add . &> /dev/null
  git reset --hard HEAD &> /dev/null
  cd $curdir
  return 0
}

#---------------------------------------------
#                   clean_smokebot_history
#---------------------------------------------

clean_smokebot_history()
{
   
   # Clean Smokebot metafiles
   MKDIR $smokebotdir > /dev/null
   cd $smokebotdir
   MKDIR guides > /dev/null
   MKDIR $HISTORY_DIR > /dev/null
   MKDIR $OUTPUT_DIR > /dev/null
   rm -rf $OUTPUT_DIR/* > /dev/null
   MKDIR $NEWGUIDE_DIR > /dev/null
   chmod 775 $NEWGUIDE_DIR
}

#---------------------------------------------
#                   compile_cfast
#---------------------------------------------

compile_cfast()
{
   cd $SMOKEBOT_HOME_DIR

    # Build CFAST
    echo "Building"
    echo "   release cfast"
    cd $cfastrepo/Build/CFAST/${COMPILER}_${platform}_64
    rm -f cfast7_${platform}_64
    make --makefile ../makefile clean &> /dev/null
    ./make_cfast.sh >> $OUTPUT_DIR/stage1a 2>&1

   # Check for errors in CFAST compilation
   cd $cfastrepo/Build/CFAST/${COMPILER}_${platform}_64
   if [ -e "cfast7_${platform}_64" ]
   then
      stage0_success=true
   else
      echo "Errors from Stage 0 - CFAST:" >> $ERROR_LOG
      echo "CFAST failed to compile" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage1a >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_CFAST_FAILED=1
   fi
}

#---------------------------------------------
#                   clean_repo2
#---------------------------------------------

clean_repo2()
{
   local repodir=$1
   local branch=$2
   
   # Check to see if FDS repository exists
   updateclean=
   if [ -e "$repo" ]
   then
      if [ "$CLEANREPO" == "1" ]; then
        CD_REPO $repo/$repodir $branch || return 1
        git update-index --refresh
        IS_DIRTY=`git describe --long --dirty | grep dirty | wc -l`
        if [ "$IS_DIRTY" == "1" ]; then
          echo "The repo $repo/$repodir has uncommitted changes."
          echo "Commit or revert these changes or re-run"
          echo "smokebot without the -c (clean) option"
          return 1
        fi
        clean_repo $repo/$repodir || return 1
        updateclean="1"
      fi
   else
      echo "The repo directory $repo does not exist." >> $OUTPUT_DIR/stage0 2>&1
      echo "Aborting smokebot" >> $OUTPUT_DIR/stage0 2>&1
      return 1
   fi
   return 0
}

#---------------------------------------------
#                   update_repo
#---------------------------------------------

update_repo()
{
   local reponame=$1
   local branch=$2
   
   CD_REPO $repo/$reponame $branch || return 1
   
   if [[ "$reponame" == "smv" ]]; then
      git update-index --refresh
      GIT_REVISION=`git describe --long --dirty`
      GIT_SHORTHASH=`git rev-parse --short HEAD`
      GIT_LONGHASH=`git rev-parse HEAD`
      GIT_DATE=`git log -1 --format=%cd --date=local $GIT_SHORTHASH`
   fi
   if [[ "$reponame" == "fds" ]]; then
      git update-index --refresh
      FDS_REVISION=`git describe --long --dirty`
   fi
   if [[ "$reponame" == "cfast" ]]; then
      git update-index --refresh
      CFAST_REVISION=`git describe --long --dirty`
   fi

   cd $repo/$reponame
   git update-index --refresh
   IS_DIRTY=`git describe --long --dirty | grep dirty | wc -l`
   if [ "$IS_DIRTY" == "1" ]; then
     echo "The repo $repo/$reponame has uncommitted changes."
     echo "Commit or revert these changes or re-run"
     echo "smokebot without the -u (update) option"
     return 1
   fi
   echo "Updating branch $branch."   >> $OUTPUT_DIR/stage0 2>&1
   git remote update                 >> $OUTPUT_DIR/stage0 2>&1
   git merge origin/$branch          >> $OUTPUT_DIR/stage0 2>&1
   have_firemodels=`git remote -v | awk '{print $1}' | grep firemodels | wc  -l`
   if [ "$have_firemodels" != "0" ]; then
      git merge firemodels/$branch   >> $OUTPUT_DIR/stage0 2>&1
      need_push=`git status -uno | head -2 | grep -v nothing | wc -l`
      if [ $need_push -gt 1 ]; then
        echo "warning: firemodels commits to $reponame repo need to be pushed to origin" >> $OUTPUT_DIR/stage0 2>&1
        git status -uno | head -2 | grep -v nothing                                 >> $OUTPUT_DIR/stage0 2>&1
      fi

   fi
   return 0
}

#---------------------------------------------
#                   check_update_repo
#---------------------------------------------

check_update_repo()
{
   # Check for GIT errors
   if [ -e $OUTPUT_DIR/stage0 ]; then
     if [[ `grep -i -E 'warning|modified' $OUTPUT_DIR/stage0` == "" ]]
     then
        # Continue along
        :
     else
        echo "warnings from Stage 0 - Update repos"                >> $WARNING_LOG
        echo ""                                                    >> $WARNING_LOG
        grep -A 5 -B 5 -i -E 'warning|modified' $OUTPUT_DIR/stage0 >> $WARNING_LOG
        echo ""                                                    >> $WARNING_LOG
     fi
   fi
}

#---------------------------------------------
#                   compile_fds_mpi_db
#---------------------------------------------

compile_fds_mpi_db()
{
   # Clean and compile mpi FDS debug
   echo "   debug FDS"
   cd $fdsrepo/Build/${INTEL}mpi_${COMPILER}_${platform}_64$DB
   rm -f fds_${INTEL}mpi_${COMPILER}_${platform}_64$DB
   make --makefile ../makefile clean &> /dev/null
   ./make_fds.sh &> $OUTPUT_DIR/stage1b
}

#---------------------------------------------
#                   check_compile_fds_mpi_db
#---------------------------------------------

check_compile_fds_mpi_db()
{
   # Check for errors in FDS debug compilation
   cd $fdsrepo/Build/${INTEL}mpi_${COMPILER}_${platform}_64$DB
   if [ -e "fds_${INTEL}mpi_${COMPILER}_${platform}_64$DB" ]
   then
      stage1b_fdsdb_success=true
   else
      echo "Errors from Stage 1b - Compile FDS MPI debug:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage1b >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_FDS_FAILED=1
   fi

   # Check for compiler warnings/remarks
   if [[ `grep -E 'warning|remark' $OUTPUT_DIR/stage1b| grep -v 'pointer not aligned at address' | grep -v Referenced | grep -v ipo | grep -v 'find atom' | grep -v 'feupdateenv is not implemented'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Stage 1b warnings:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage1b | grep -v 'pointer not aligned at address' | grep -v Referenced | grep -v ipo | grep -v 'find atom' | grep -v 'feupdateenv is not implemented'>> $WARNING_LOG
      echo "" >> $WARNING_LOG
   # if the executable does not exist then an email has already been sent
      if [ -e "fds_${INTEL}mpi_${COMPILER}_${platform}_64$DB" ] ; then
        THIS_FDS_FAILED=1
      fi
   fi
}

#---------------------------------------------
#                   compile_fds_mpi_gnu_db
#---------------------------------------------

compile_fds_mpi_gnu_db()
{
   # Clean and compile FDS MPI debug
   compile_gnu=
   if [ "$OPENMPI_INTEL" != "" ]; then
     if [ "$OPENMPI_GNU" != "" ]; then
       compile_gnu=1
       module unload $OPENMPI_INTEL
       module load $OPENMPI_GNU
       echo "   MPI gfortran debug"
       cd $fdsrepo/Build/mpi_gnu_${platform}_64$DB
       make -f ../makefile clean &> /dev/null
       ./make_fds.sh &> $OUTPUT_DIR/stage1d
       module unload $OPENMPI_GNU
       module load $OPENMPI_INTEL
     fi
   fi
}

#---------------------------------------------
#                   check_compile_fds_mpi_gnu_db
#---------------------------------------------
check_compile_fds_mpi_gnu_db()
{
# force a pass until gfortran can compile a routine with the findloc routine
        FDS_debug_success=true
}

check_compile_fds_mpi_gnu_dbORIG()
{
   # Check for errors in FDS MPI debug compilation
   if [ "$compile_gnu" == "1" ]; then
     cd $fdsrepo/Build/mpi_gnu_${platform}_64$DB
     if [ -e "fds_mpi_gnu_${platform}_64$DB" ]
     then
        FDS_debug_success=true
     else
        echo "Errors from Stage 1d - Compile gnu Fortran FDS MPI debug:" >> $ERROR_LOG
        cat $OUTPUT_DIR/stage1d >> $ERROR_LOG
        echo "" >> $ERROR_LOG
     fi

   # Check for compiler warnings/remarks
     if [[ `grep -i -E 'warning|remark' $OUTPUT_DIR/stage1d | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented'` == "" ]]
     then
      # Continue along
      :
     else
        echo "Warnings from Stage 1d - Compile gnu Fortran FDS MPI debug:" >> $WARNING_LOG
        grep -i -A 5 -E 'warning|remark' $OUTPUT_DIR/stage1d | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented' >> $WARNING_LOG
        echo "" >> $WARNING_LOG
     fi
   fi
}


#---------------------------------------------
#                   wait_verification_cases_debug_end
#---------------------------------------------

wait_verification_cases_debug_end()
{
   # Scans qstat and waits for verification cases to end
   if [[ "$SMOKEBOT_QUEUE" == "none" ]]
   then
     while [[          `ps -u $USER -f | fgrep .fds | grep -v smokebot | grep -v grep` != '' ]]; do
        JOBS_REMAINING=`ps -u $USER -f | fgrep .fds | grep -v smokebot | grep -v grep | wc -l`

        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage3a
        TIME_LIMIT_STAGE="3"
        check_time_limit
        sleep 30
     done
   else
     while [[ `qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX` != '' ]]; do
        JOBS_REMAINING=`qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX | wc -l`
        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage3a
        TIME_LIMIT_STAGE="3"
        check_time_limit
        sleep 30
     done
   fi
}

#---------------------------------------------
#                   run_verification_cases_debug
#---------------------------------------------

run_verification_cases_debug()
{
   #  ======================
   #  = Remove .stop files =
   #  ======================

   # Remove all .stop and .err files from Verification directories (recursively)
   if [ "$CLEANREPO" == "1" ]; then
     echo "Verification cases"
     echo "   cleaning"
     cd $smvrepo/Verification
     clean_repo $smvrepo/Verification
   fi

   #  =====================
   #  = Run all SMV cases =
   #  =====================

   echo "   running (debug mode)"
   cd $smvrepo/Verification/scripts

   # Submit SMV verification cases and wait for them to start
   echo 'Running SMV verification cases:' >> $OUTPUT_DIR/stage3a 2>&1
   ./Run_SMV_Cases.sh $INTEL2 $YOPT -c $cfastrepo -I $COMPILER $USEINSTALL2 -m 2 -d -q $SMOKEBOT_QUEUE >> $OUTPUT_DIR/stage3a 2>&1
}

#---------------------------------------------
#                   check_verification_cases_debug
#---------------------------------------------

check_verification_cases_debug()
{
   # Wait for SMV verification cases to end
   wait_verification_cases_debug_end

   # Scan and report any errors in FDS verification cases
   cd $smvrepo/Verification

   if [[ `grep -rIi 'Run aborted' $OUTPUT_DIR/stage3a` == "" ]] && \
      [[ `grep -rIi 'Segmentation' Visualization/* WUI/* ` == "" ]] && \
      [[ `grep -rI 'ERROR:' Visualization/* WUI/* ` == "" ]] && \
      [[ `grep -rIi 'STOP: Numerical' Visualization/* WUI/* ` == "" ]] && \
      [[ `grep -rIi 'forrtl' Visualization/* WUI/* ` == "" ]]
   then
      stage3a_success=true
   else
      grep -rIi 'Run aborted' $OUTPUT_DIR/stage3a > $OUTPUT_DIR/stage3a_errors
      grep -rIi 'Segmentation' Visualization/* WUI/*  >> $OUTPUT_DIR/stage3a_errors
      grep -rI 'ERROR:' Visualization/* WUI/*  >> $OUTPUT_DIR/stage3a_errors
      grep -rIi 'STOP: Numerical' -rIi Visualization/* WUI/* >> $OUTPUT_DIR/stage3a_errors
      grep -rIi -A 20 'forrtl' Visualization/* WUI/*  >> $OUTPUT_DIR/stage3a_errors
      
      echo "Errors from Stage 3a - Run verification cases (debug mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3a_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_FDS_FAILED=1
   fi
   if [[ `grep 'Warning' -rI $OUTPUT_DIR/stage3a` == "" ]] 
   then
      no_warnings=true
   else
      echo "Stage 3a warnings:" >> $WARNING_LOG
      grep 'Warning' -rI $OUTPUT_DIR/stage3a >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   compile_fds_mpi
#---------------------------------------------

compile_fds_mpi()
{
   # Clean and compile FDS
   echo "Building release FDS"
   cd $fdsrepo/Build/${INTEL}mpi_${COMPILER}_${platform}_64
   rm -f fds_${INTEL}mpi_${COMPILER}_${platform}_64
   make --makefile ../makefile clean &> /dev/null
   ./make_fds.sh &> $OUTPUT_DIR/stage1c
}

#---------------------------------------------
#                   check_compile_fds_mpi
#---------------------------------------------

check_compile_fds_mpi()
{
   # Check for errors in FDS compilation
   cd $fdsrepo/Build/${INTEL}mpi_${COMPILER}_${platform}_64
   if [ -e "fds_${INTEL}mpi_${COMPILER}_${platform}_64" ]
   then
      stage1c_fdsrel_success=true
   else
      echo "Errors from Stage 1c - Compile FDS release:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage1c >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   # 'performing multi-file optimizations' and 'generating object file' are part of a normal compile
   if [[ `grep -E 'warning|remark' $OUTPUT_DIR/stage1c | grep -v 'pointer not aligned at address' | grep -v Referenced | grep -v ipo | grep -v 'find atom' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file'| grep -v 'feupdateenv is not implemented'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Stage 1c warnings:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage1c | grep -v 'pointer not aligned at address' | grep -v Referenced | grep -v ipo | grep -v 'find atom' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file'| grep -v 'feupdateenv is not implemented' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   compile_smv_utilities
#---------------------------------------------

compile_smv_utilities()
{
   echo "Building"
   echo "   smokeview utilities"
   echo "" > $OUTPUT_DIR/stage2a
   if [ "$haveCC" == "1" ] ; then
   # smokeview libraries
     echo "      libraries"
     cd $smvrepo/Build/LIBS/${COMPILER}_${platform}_64
     echo 'Building Smokeview libraries:' >> $OUTPUT_DIR/stage2a 2>&1
     ./make_LIBS.sh >> $OUTPUT_DIR/stage2a 2>&1

   # smokezip:
     echo "      smokezip"
     cd $smvrepo/Build/smokezip/${COMPILER}_${platform}_64
     rm -f *.o smokezip_${platform}_64

     echo 'Compiling smokezip:' >> $OUTPUT_DIR/stage2a 2>&1
     ./make_smokezip.sh >> $OUTPUT_DIR/stage2a 2>&1
     echo "" >> $OUTPUT_DIR/stage2a 2>&1
   
   # smokediff:
     echo "      smokediff"
     cd $smvrepo/Build/smokediff/${COMPILER}_${platform}_64
     rm -f *.o smokediff_${platform}_64
     echo 'Compiling smokediff:' >> $OUTPUT_DIR/stage2a 2>&1
     ./make_smokediff.sh >> $OUTPUT_DIR/stage2a 2>&1
     echo "" >> $OUTPUT_DIR/stage2a 2>&1
   
   # background
     echo "      background"
     cd $smvrepo/Build/background/${COMPILER}_${platform}_64
     rm -f *.o background_${platform}_64
     echo 'Compiling background:' >> $OUTPUT_DIR/stage2a 2>&1
     ./make_background.sh >> $OUTPUT_DIR/stage2a 2>&1

   # dem2fds
     echo "      dem2fds"
     cd $smvrepo/Build/dem2fds/${COMPILER}_${platform}_64
     rm -f *.o dem2fds
     echo 'Compiling dem2fds:' >> $OUTPUT_DIR/stage2a 2>&1
     ./make_dem2fds.sh >> $OUTPUT_DIR/stage2a 2>&1
   
  # wind2fds:
     echo "      wind2fds"
     cd $smvrepo/Build/wind2fds/${COMPILER}_${platform}_64
     rm -f *.o wind2fds_${platform}_64
     echo 'Compiling wind2fds:' >> $OUTPUT_DIR/stage2a 2>&1
     ./make_wind2fds.sh >> $OUTPUT_DIR/stage2a 2>&1
    echo "" >> $OUTPUT_DIR/stage2a 2>&1
   else
     echo "Warning: smokeview and utilities not built - C compiler not available" >> $OUTPUT_DIR/stage2a 2>&1
   fi
}

#---------------------------------------------
#                   is_file_installed
#---------------------------------------------

is_file_installed()
{
  local program=$1
  
  notfound=`$program -help | tail -1 | grep "not found" | wc -l`
  if [ "$notfound" == "1" ] ; then
    stage2a_success="0"
    echo "***error: $program not installed" >> $OUTPUT_DIR/stage2a
  fi
}

#---------------------------------------------
#                   compare_common_files
#---------------------------------------------

compare_common_files()
{
   fdsdir=$1
   smvdir=$2
   file=$3
   fds_file=$fdsrepo/$fdsdir/$file
   smv_file=$smvrepo/$smvdir/$file
   notexist=
   if ! [ -e $fds_file ]; then
     echo "Warnings Stage 2d" >> $WARNING_LOG
     echo "***warning: The fds repo file, $fds_file, does not exist" >> $WARNING_LOG
     notexist=1
   fi
   if ! [ -e $smv_file ]; then
     echo "Warnings Stage 2d" >> $WARNING_LOG
     echo "***warning: The smv repo file, $smv_file, does not exist" >> $WARNING_LOG
     notexist=1
   fi
   if [ "$notexist" == "" ]; then
     ndiffs=`diff $smv_file $fds_file | wc -l`
     if [ $ndiffs -gt 0 ]; then
       echo "" >> $WARNING_LOG
       echo "Warnings Stage 2d" >> $WARNING_LOG
       echo "***warning: The fds repo version of $file is out of synch with the smv repo version" >> $WARNING_LOG
     fi
   fi
}

#---------------------------------------------
#                   check_common_files
#---------------------------------------------

check_common_files()
{
   compare_common_files Source Source/smokeview gsmv.f90
}

#---------------------------------------------
#                   check_smv_utilities
#---------------------------------------------

check_smv_utilities()
{
   if [ "$haveCC" == "1" ] ; then
     # Check for errors in SMV utilities compilation
     cd $smvrepo
     if [ -e "$smvrepo/Build/smokezip/${COMPILER}_${platform}_64/smokezip_${platform}_64" ]  && \
        [ -e "$smvrepo/Build/smokediff/${COMPILER}_${platform}_64/smokediff_${platform}_64" ]  && \
        [ -e "$smvrepo/Build/wind2fds/${COMPILER}_${platform}_64/wind2fds_${platform}_64" ]  && \
        [ -e "$smvrepo/Build/dem2fds/${COMPILER}_${platform}_64/dem2fds_${platform}_64" ]  && \
        [ -e "$smvrepo/Build/background/${COMPILER}_${platform}_64/background_${platform}_64" ]
     then
        stage2a_success="1"
     else
        stage2a_success="0"
        echo "Errors from Stage 2a - Compile SMV utilities:" >> $ERROR_LOG
        cat $OUTPUT_DIR/stage2a >> $ERROR_LOG
        echo "" >> $ERROR_LOG
     fi
   else
     stage2a_success="1"
     is_file_installed smokeview
     is_file_installed smokezip
     is_file_installed smokediff
     is_file_installed wind2fds
     is_file_installed dem2fds
     is_file_installed background
     if [ "$stage2a_success" == "0" ] ; then
        echo "Errors from Stage 2a - Smokeview and utilities:" >> $ERROR_LOG
        stage2a_success="1"
        cat $OUTPUT_DIR/stage2a >> $ERROR_LOG
        echo "" >> $ERROR_LOG
     fi
   fi
}

#---------------------------------------------
#                   wait_verification_cases_release_end
#---------------------------------------------

wait_verification_cases_release_end()
{
   # Scans qstat and waits for verification cases to end
   if [[ "$SMOKEBOT_QUEUE" == "none" ]]
   then
     while [[          `ps -u $USER -f | fgrep .fds | grep -v smokebot | grep -v grep` != '' ]]; do
        JOBS_REMAINING=`ps -u $USER -f | fgrep .fds | grep -v smokebot | grep -v grep | wc -l`

        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage3b
        TIME_LIMIT_STAGE="5"
        check_time_limit
        sleep 60
     done
   else
     while [[ `qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX` != '' ]]; do
        JOBS_REMAINING=`qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX | wc -l`
        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage3b
        TIME_LIMIT_STAGE="5"
        check_time_limit
        sleep 60
     done
   fi
}

#---------------------------------------------
#                   run_verification_cases_relase
#---------------------------------------------

run_verification_cases_release()
{
   #  ======================
   #  = Remove .stop files =
   #  ======================

   # Remove all .stop and .err files from Verification directories (recursively)
   echo "Verification cases"
   if [ "$CLEANREPO" == "1" ]; then
     echo "   cleaning"
     cd $smvrepo/Verification
     clean_repo $smvrepo/Verification
   fi
   echo "   running (release mode)"
   # Start running all SMV verification cases
   cd $smvrepo/Verification/scripts
   echo 'Running SMV verification cases:' >> $OUTPUT_DIR/stage3b 2>&1
   ./Run_SMV_Cases.sh $INTEL2 $YOPT -c $cfastrepo -I $COMPILER $USEINSTALL2 $RUN_OPENMP -q $SMOKEBOT_QUEUE >> $OUTPUT_DIR/stage3b 2>&1
}

#---------------------------------------------
#                   check_verification_cases_release
#---------------------------------------------

check_verification_cases_release()
{
   # Wait for all verification cases to end
   wait_verification_cases_release_end

   # Scan and report any errors in FDS verification cases
   cd $smvrepo/Verification

   if [[ `grep -rIi 'Run aborted' $OUTPUT_DIR/stage3b` == "" ]] && \
      [[ `grep -rIi 'Segmentation' Visualization/* WUI/* ` == "" ]] && \
      [[ `grep -rI 'ERROR:' Visualization/* WUI/*  ` == "" ]] && \
      [[ `grep -rIi 'STOP: Numerical' Visualization/* WUI/*  ` == "" ]] && \
      [[ `grep -rIi  'forrtl' Visualization/* WUI/*  ` == "" ]]
   then
      stage3b_success=true
   else
      grep -rIi 'Run aborted' $OUTPUT_DIR/stage3b > $OUTPUT_DIR/stage3b_errors
      grep -rIi 'Segmentation' Visualization/* WUI/*  >> $OUTPUT_DIR/stage3b_errors
      grep -rI 'ERROR:' Visualization/* WUI/*  >> $OUTPUT_DIR/stage3b_errors
      grep -rIi 'STOP: Numerical' Visualization/* WUI/*  >> $OUTPUT_DIR/stage3b_errors
      grep -rIi -A 20 'forrtl' Visualization/* WUI/*  >> $OUTPUT_DIR/stage3b_errors

      echo "Errors from Stage 3b - Run verification cases (release mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3b_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_FDS_FAILED=1
   fi

      
   if [[ `grep 'Warning' -rI $OUTPUT_DIR/stage3b` == "" ]] 
   then
      no_warnings=true
   else
      echo "Stage 3b warnings:" >> $WARNING_LOG
      grep 'Warning' -rI $OUTPUT_DIR/stage3b >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   compile_smv_db
#---------------------------------------------

compile_smv_db()
{
   if [ "$haveCC" == "1" ] ; then
   # Clean and compile SMV debug
     echo "   smokeview"
     echo "      debug"
     cd $smvrepo/Build/smokeview/${COMPILER}_${platform}_64
     rm -f smokeview_${platform}${TEST}_64_db
     ./make_smokeview_db.sh $TESTFLAG &> $OUTPUT_DIR/stage2b
   fi
}

#---------------------------------------------
#                   check_compile_smv_db
#---------------------------------------------

check_compile_smv_db()
{
   if [ "$haveCC" == "1" ] ; then
   # Check for errors in SMV debug compilation
   cd $smvrepo/Build/smokeview/${COMPILER}_${platform}_64
   if [ -e "smokeview_${platform}${TEST}_64_db" ]
   then
      stage2b_success=true
   else
      echo "Errors from Stage 2b - Compile SMV debug:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2b >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
   if [[ `grep -E 'warning|remark' $OUTPUT_DIR/stage2b | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Stage 6a warnings:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage2b | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   fi
}

#---------------------------------------------
#                   make_smv_pictures_db
#---------------------------------------------

make_smv_pictures_db()
{
   # Run Make SMV Pictures script (debug mode)
   echo "making smokeview images"
   cd $smvrepo/Verification/scripts
   ./Make_SMV_Pictures.sh $YOPT -q $SMOKEBOT_QUEUE -I $COMPILER $USEINSTALL -d 2>&1 &> $OUTPUT_DIR/stage4a_orig
   grep -v FreeFontPath $OUTPUT_DIR/stage4a_orig > $OUTPUT_DIR/stage4a
}

#---------------------------------------------
#                   check_smv_pictures_db
#---------------------------------------------

check_smv_pictures_db()
{
   # Scan and report any errors in make SMV pictures process
   echo "   checking"
   cd $smokebotdir
   if [[ `grep -I -E "Segmentation|Error" $OUTPUT_DIR/stage4a` == "" ]]
   then
      stage4a_success=true
   else
      cp $OUTPUT_DIR/stage4a $OUTPUT_DIR/stage4a_errors

      echo "Errors from Stage 4a - Make SMV pictures (debug mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage4a_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Scan for and report any warnings in make SMV pictures process
   cd $smokebotdir
   if [[ `grep -I -E "Warning" $OUTPUT_DIR/stage4a` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 6b - Make SMV pictures (debug mode):" >> $WARNING_LOG
      grep -I -E "Warning" $OUTPUT_DIR/stage4a >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   compile_smv
#---------------------------------------------

compile_smv()
{
   if [ "$haveCC" == "1" ] ; then
   # Clean and compile SMV
     echo "      release"
     cd $smvrepo/Build/smokeview/${COMPILER}_${platform}_64
     rm -f smokeview_${platform}${TEST}_64
     ./make_smokeview.sh $TESTFLAG &> $OUTPUT_DIR/stage2c
   fi
}

#---------------------------------------------
#                   check_compile_smv
#---------------------------------------------

check_compile_smv()
{
   if [ "$haveCC" == "1" ] ; then
   # Check for errors in SMV release compilation
   cd $smvrepo/Build/smokeview/${COMPILER}_${platform}_64
   if [ -e "smokeview_${platform}${TEST}_64" ]
   then
      stage2c_smv_success=true
   else
      echo "Errors from Stage 2c - Compile SMV release:" >> $ERROR_LOG
      echo "The program smokeview_${platform}${TEST}_64 does not exist."
      cat $OUTPUT_DIR/stage2c >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
   if [[ `grep -E 'warning|remark' $OUTPUT_DIR/stage2c | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Stage 6c warnings:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage2c | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   fi
}

#---------------------------------------------
#                   make_smv_pictures
#---------------------------------------------

make_smv_pictures()
{
   # Run Make SMV Pictures script (release mode)
   echo Generating images 
   cd $smvrepo/Verification/scripts
   ./Make_SMV_Pictures.sh $YOPT -q $SMOKEBOT_QUEUE -I $COMPILER $TESTFLAG $USEINSTALL 2>&1 &> $OUTPUT_DIR/stage4b_orig
   grep -v FreeFontPath $OUTPUT_DIR/stage4b_orig &> $OUTPUT_DIR/stage4b
}

#---------------------------------------------
#                   check_smv_pictures
#---------------------------------------------

check_smv_pictures()
{
   # Scan and report any errors in make SMV pictures process
   cd $smokebotdir
   echo "   checking"
   if [[ `grep -I -E "Segmentation|Error" $OUTPUT_DIR/stage4b` == "" ]]
   then
      stage4b_smvpics_success=true
   else
      cp $OUTPUT_DIR/stage4b  $OUTPUT_DIR/stage4b_errors

      echo "Errors from Stage 4 - Make SMV pictures (release mode):" >> $ERROR_LOG
      grep -B 5 -A 5 -I -E "Segmentation|Error" $OUTPUT_DIR/stage4b >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi
   if [[ `grep -I -E "Warning" $OUTPUT_DIR/stage4b` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 4b - Make SMV pictures (release mode):" >> $WARNING_LOG
      grep -A 2 -I -E "Warning" $OUTPUT_DIR/stage4b >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   if [ ! "$web_DIR" == "" ]; then
     if [ -d "$WEBFROM_DIR" ]; then
       CURDIR=`pwd`
       cd $web_DIR
       rm -rf images
       rm -rf manuals
       rm index.html
       cd $WEBFROM_DIR
       cp -r * $web_DIR/.
       cd $CURDIR
     fi
   fi

}

#---------------------------------------------
#                   make_smv_movies
#---------------------------------------------

make_smv_movies()
{
   cd $smvrepo/Verification
   scripts/Make_SMV_Movies.sh -q $SMOKEBOT_QUEUE $TEST 2>&1  &> $OUTPUT_DIR/stage4c
}

#---------------------------------------------
#                   check_smv_movies
#---------------------------------------------

check_smv_movies()
{
   cd $smokebotdir
   echo make smokeview movies
   if [[ `grep -I -E "Segmentation|Error" $OUTPUT_DIR/stage4c` == "" ]]
   then
      stage4c_success=true
   else
      cp $OUTPUT_DIR/stage4c  $OUTPUT_DIR/stage4c_errors

      echo "Errors from Stage 4c - Make SMV movies " >> $ERROR_LOG
      cat $OUTPUT_DIR/stage4c >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Scan for and report any warnings in make SMV pictures process
   cd $smokebotdir
   if [[ `grep -I -E "Warning" $OUTPUT_DIR/stage4c` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 6e - Make SMV movies (release mode):" >> $WARNING_LOG
      grep -I -E "Warning" $OUTPUT_DIR/stage4c >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   if [ ! "$web_DIR" == "" ]; then
     if [ -d "$WEBFROM_DIR" ]; then 
       CURDIR=`pwd`
       cd $web_DIR
       rm -rf *
       cd $WEBFROM_DIR
       cp -r * $web_DIR/.
       cd $CURDIR
     fi
   fi

}

#---------------------------------------------
#                   generate_timing_stats
#---------------------------------------------

generate_timing_stats()
{
   echo "Timing stats"
   echo "   generating"
   cd $smvrepo/Verification/scripts/
   export QFDS="$smvrepo/Verification/scripts/copyout.sh"
   export RUNCFAST="$smvrepo/Verification/scripts/copyout.sh"
   export RUNTFDS="$smvrepo/Verification/scripts/copyout.sh"

   cd $smvrepo/Verification
   scripts/SMV_Cases.sh

   cd $smvrepo/Utilities/Scripts
   ./fds_timing_stats.sh smokebot > smv_timing_stats.csv
   cd $smvrepo/Utilities/Scripts
   ./fds_timing_stats.sh smokebot 1 > smv_benchmarktiming_stats.csv
   TOTAL_SMV_TIMES=`tail -1 smv_benchmarktiming_stats.csv`
}

#---------------------------------------------
#                   archive_timing_stats
#---------------------------------------------

archive_timing_stats()
{
  echo "   archiving"
  cd $smvrepo/Utilities/Scripts
  cp smv_timing_stats.csv "$HISTORY_DIR/${GIT_REVISION}_timing.csv"
  cp smv_benchmarktiming_stats.csv "$HISTORY_DIR/${GIT_REVISION}_benchmarktiming.csv"
  TOTAL_SMV_TIMES=`tail -1 smv_benchmarktiming_stats.csv`
  if [[ "$UPLOADRESULTS" == "1" ]] && [[ "$USER" == "smokebot" ]]; then
    cd $botrepo/Smokebot
    ./smvstatus_updatepub.sh $repo/webpages $WEBBRANCH
  fi
  if [ ! "$web_DIR" == "" ]; then
    cd $botrepo/Smokebot
    ./make_smv_summary.sh > $web_DIR/index.html
  fi
}

#---------------------------------------------
#                   check_guide
#---------------------------------------------

check_guide()
{
   local stage=$1
   local directory=$2
   local document=$3
   local label=$4

   # Scan and report any errors in build process for guides

   SMOKEBOT_MAN_DIR=
   if [ ! "$web_DIR" == "" ]; then
     if [ -d $web_DIR/manuals ]; then
       SMOKEBOT_MAN_DIR=$web_DIR/manuals
     fi
   fi

   cd $smokebotdir
   if [[ `grep -I "successfully" $stage` == "" ]]; then
      echo "Errors from Stage 5 - Build Smokeview Guides:" >> $ERROR_LOG
      echo $label >> $ERROR_LOG
      cat $stage >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   else
     if [ ! "$SMOKEBOT_MAN_DIR" == "" ]; then
       cp $directory/$document $SMOKEBOT_MAN_DIR/.
     fi
     if [ -d $SMV_SUMMARY/manuals ] ; then
       cp $directory/$document $SMV_SUMMARY/manuals/.
     fi
     cp $directory/$document $NEWGUIDE_DIR/.
     cp $directory/$document $SAVEGUIDE_DIR/.
     chmod 664 $NEWGUIDE_DIR/$document
     chmod 664 $SAVEGUIDE_DIR/$document
   fi

   # Check for LaTeX warnings (undefined references or duplicate labels)
   if [[ `grep -E "undefined|multiply defined|multiply-defined" -I ${stage}` == "" ]]
   then
      # Continue along
      :
   else
      echo "Stage 5 warnings:" >> $WARNING_LOG
      echo $label >> $WARNING_LOG
      cat $stage >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   make_guide
#---------------------------------------------

make_guide()
{
   local document=$1
   local directory=$2
   local label=$3

   cd $directory
  
   ./make_guide.sh &> $OUTPUT_DIR/stage5_$document

   # Check guide for completion and copy to website if successful
   check_guide $OUTPUT_DIR/stage5_$document $directory $document.pdf $label
}

#---------------------------------------------
#                   save_build_status
#---------------------------------------------

save_build_status()
{
   HOST=`hostname -s`
   STOP_TIME=$(date)
   STOP_TIME_INT=$(date +%s)
   cd $smokebotdir
   # Save status outcome of build to a text file
   if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]
   then
     echo "***Warnings:" >> $ERROR_LOG
     cat $WARNING_LOG >> $ERROR_LOG
     echo "   build failure and warnings for version: ${GIT_REVISION}, branch: $SMVBRANCH."
     echo "Build failure and warnings;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$SMVBRANCH;$STOP_TIME_INT;3;$TOTAL_SMV_TIMES;$HOST" > "$HISTORY_DIR/${GIT_REVISION}.txt"
     cat $ERROR_LOG > "$HISTORY_DIR/${GIT_REVISION}_errors.txt"

   # Check for errors only
   elif [ -e $ERROR_LOG ]
   then
      echo "   build failure for version: ${GIT_REVISION}, branch: $SMVBRANCH."
      echo "Build failure;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$SMVBRANCH;$STOP_TIME_INT;3;$TOTAL_SMV_TIMES;$HOST" > "$HISTORY_DIR/${GIT_REVISION}.txt"
      cat $ERROR_LOG > "$HISTORY_DIR/${GIT_REVISION}_errors.txt"

   # Check for warnings only
   elif [ -e $WARNING_LOG ]
   then
      echo "   build success with warnings for version: ${GIT_REVISION}, branch: $SMVBRANCH."
      echo "Build success with warnings;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$SMVBRANCH;$STOP_TIME_INT;2;$TOTAL_SMV_TIMES;$HOST" > "$HISTORY_DIR/${GIT_REVISION}.txt"
      cat $WARNING_LOG > "$HISTORY_DIR/${GIT_REVISION}_warnings.txt"

   # No errors or warnings
   else
      echo "   build success for version: ${GIT_REVISION}, branch: $SMVBRANCH."
      echo "Build success!;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$SMVBRANCH;$STOP_TIME_INT;1;$TOTAL_SMV_TIMES;$HOST" > "$HISTORY_DIR/${GIT_REVISION}.txt"
   fi
}

#---------------------------------------------
#                   email_build_status
#---------------------------------------------

email_build_status()
{
   if [[ "$THIS_FDS_FAILED" == "1" ]] ; then
     mailTo="$mailToFDS"
   fi
   if [[ "$THIS_CFAST_FAILED" == "1" ]] ; then
     mailTo="$mailToCFAST"
   fi
   echo $THIS_FDS_FAILED>$FDS_STATUS_FILE
   stop_time=`date`
   IFORT_VERSION=`ifort -v 2>&1`
   echo "----------------------------------------------" > $TIME_LOG
   echo "                host: $hostname " >> $TIME_LOG
   echo "                  OS: $platform2" >> $TIME_LOG
   echo "                repo: $repo" >> $TIME_LOG
   echo "               queue: $SMOKEBOT_QUEUE" >> $TIME_LOG
   echo "  fds version/branch: $FDS_REVISION/$FDSBRANCH" >> $TIME_LOG
   echo "  smv version/branch: $GIT_REVISION/$SMVBRANCH" >> $TIME_LOG
   echo "cfast version/branch: $CFAST_REVISION/$CFASTBRANCH" >> $TIME_LOG
if [ "$IFORT_VERSION" != "" ]; then
   echo "              Fortran: $IFORT_VERSION " >> $TIME_LOG
fi
   echo "          start time: $start_time " >> $TIME_LOG
   echo "           stop time: $stop_time " >> $TIME_LOG
   echo "               setup: $DIFF_PRELIM" >> $TIME_LOG
   echo "      build software: $DIFF_BUILDSOFTWARE" >> $TIME_LOG
   echo "           run cases: $DIFF_RUNCASES" >> $TIME_LOG
   echo "       make pictures: $DIFF_MAKEPICTURES" >> $TIME_LOG
   if [ "$MAKEMOVIES" == "1" ]; then
     echo "         make movies: $DIFF_MAKEMOVIES" >> $TIME_LOG
   fi
   echo "         make guides: $DIFF_MAKEGUIDES" >> $TIME_LOG
   echo "               total: $DIFF_SCRIPT_TIME" >> $TIME_LOG
   echo "   benchmark time(s): $TOTAL_SMV_TIMES" >> $TIME_LOG
   echo "   FDS revisions: old: $LAST_FDS_REVISION new: $THIS_FDS_REVISION" >> $TIME_LOG
   echo "   SMV revisions: old: $LAST_SMV_REVISION new: $THIS_SMV_REVISION" >> $TIME_LOG
  SOURCE_CHANGED=
  if [[ $THIS_SMV_REVISION != $LAST_SMV_REVISION ]] ; then
    SOURCE_CHANGED=1
    cat $GIT_SMV_LOG_FILE >> $TIME_LOG
  fi
  if [[ $THIS_FDS_REVISION != $LAST_FDS_REVISION ]] ; then
    SOURCE_CHANGED=1
    cat $GIT_FDS_LOG_FILE >> $TIME_LOG
  fi
  if [ "$SOURCE_CHANGED" != "" ]; then
    if [[ $THIS_ROOT_REVISION != $LAST_ROOT_REVISION ]] ; then
      cat $GIT_ROOT_LOG_FILE >> $TIME_LOG
    fi
  fi
   cd $smokebotdir
   # Check for warnings and errors
   if [ ! "$WEB_URL" == "" ]; then
     echo "     Smokebot summary: $WEB_URL" >> $TIME_LOG
   fi
   if [ "$UPLOADRESULTS" == "1" ]; then
     echo "      Smokebot status: https://pages.nist.gov/fds-smv/smokebot_status.html" >> $TIME_LOG
   fi
   echo "-------------------------------" >> $TIME_LOG
   if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]; then
     # Send email with failure message and warnings, body of email contains appropriate log file
     cat $ERROR_LOG $TIME_LOG | mail -s "smokebot failure and warnings on ${hostname}. ${GIT_REVISION}, $SMVBRANCH" $mailTo > /dev/null

   # Check for errors only
   elif [ -e $ERROR_LOG ]; then
      # Send email with failure message, body of email contains error log file
      cat $ERROR_LOG $TIME_LOG | mail -s "smokebot failure on ${hostname}. ${GIT_REVISION}, $SMVBRANCH" $mailTo > /dev/null

   # Check for warnings only
   elif [ -e $WARNING_LOG ]; then
     # Send email with success message, include warnings
     cat $WARNING_LOG $TIME_LOG | mail -s "smokebot success with warnings on ${hostname}. ${GIT_REVISION}, $SMVBRANCH" $mailTo > /dev/null

   # No errors or warnings
   else
# upload guides to a google drive directory
      if [ "$UPLOADRESULTS" == "1" ]; then
        cd $smokebotdir
        $UploadGuides $NEWGUIDE_DIR $smvrepo/Manuals &> /dev/null
        $UploadWEB                  $smvrepo/Manuals $MAKEMOVIES &> /dev/null
      fi

      # Send success message with links to nightly manuals
      cat $TIME_LOG | mail -s "smokebot success on ${hostname}. ${GIT_REVISION}, $SMVBRANCH" $mailTo > /dev/null
   fi
}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             beginning of smokebot.sh
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** define initial values

YOPT=-Y
smokebotdir=`pwd`
OUTPUT_DIR="$smokebotdir/output"
HISTORY_DIR="$HOME/.smokebot/history"
EMAIL_LIST="$HOME/.smokebot/smokebot_email_list.sh"
TIME_LOG=$OUTPUT_DIR/timings
ERROR_LOG=$OUTPUT_DIR/errors
WARNING_LOG=$OUTPUT_DIR/warnings
GUIDE_DIR=$OUTPUT_DIR/guides
STAGE_STATUS=$OUTPUT_DIR/stage_status
NEWGUIDE_DIR=$OUTPUT_DIR/Newest_Guides
web_DIR=
WEB_URL=
SMOKEBOT_LITE=
export SCRIPTFILES=$smokebotdir/scriptfiles

WEBBRANCH=nist-pages
FDSBRANCH=master
SMVBRANCH=master
CFASTBRANCH=master
BOTBRANCH=master

SMOKEBOT_QUEUE=smokebot
MAKEMOVIES=0
RUNAUTO=
RUNDEBUG="1"
OPENMP=
RUN_OPENMP=
TESTFLAG=
TEST=
CLEANREPO=0
UPDATEREPO=0
mailTo=
UPLOADRESULTS=
COMPILER=intel
PID_FILE=~/.fdssmvgit/firesmokebot_pid
INTEL=
SKIP=
SAVEGUIDE_DIR=$HOME/.smokebot/pubs

#*** parse command line options

while getopts 'aAb:cI:JLm:Mo:q:r:SstuUw:W:' OPTION
do
case $OPTION in
  a)
   RUNAUTO="y"
   ;;
  A)
   RUNAUTO="Y"
   ;;
  b)
   SMVBRANCH="$OPTARG"
   if [ "$SMVBRANCH" == "current" ]; then
     FDSBRANCH="current"
     CFASTBRANCH="current"
     BOTBRANCH="current"
   fi
   ;;
  c)
   CLEANREPO=1
   ;;
  I)
   COMPILER="$OPTARG"
   ;;
  J)
   INTEL=i
   INTEL2="-J"
   ;;
  L)
   SMOKEBOT_LITE=1
   ;;
  m)
   mailTo="$OPTARG"
   ;;
  M)
   MAKEMOVIES="1"
   ;;
  o)
   nthreads="$OPTARG"
   OPENMP=openmp_
   RUN_OPENMP="-o $nthreads"
   ;;
  q)
   SMOKEBOT_QUEUE="$OPTARG"
   ;;
  s)
   RUNDEBUG="0"
   ;;
  S)
   SKIP=1
   ;;
  t)
   TESTFLAG="-t"
   TEST="_test"
   ;;
  U)
   UPLOADRESULTS=1
   ;;
  u)
   UPDATEREPO=1
   ;;
  w)
   web_DIR="$OPTARG"
   ;;
  W)
   WEB_URL="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

#*** make sure smokebot is running in the right directory

if [ -e .smv_git ]; then
  cd ../..
  repo=`pwd`
  cd $smokebotdir
else
  echo "***error: smokebot not running in the bot/Smokebot directory"
  echo "          Aborting smokebot"
  exit 1
fi

if [[ "$SMOKEBOT_QUEUE" == "none" ]] && [[ -e $SCRIPTFILES ]]; then
  rm -f $SCRIPTFILES
fi

if [ "$SMOKEBOT_QUEUE" == "none" ]; then
  notfound=`background -v 2>&1 | tail -1 | grep "not found" | wc -l`
  if [ $notfound -eq 1 ]; then
    echo "Error: The program background was not found.  smokebot aborted"
    echo "       Add the directory containing background to your path"
    echo "       (same directory containing fds and smokeview)"
    exit
  fi
fi

#*** create pub directory

MKDIR $HOME/.smokebot
MKDIR $HOME/.smokebot/pubs

#*** make sure repos needed by smokebot exist

botrepo=$repo/bot
CD_REPO $botrepo $BOTBRANCH || exit 1
if [ "$BOTBRANCH" == "current" ]; then
  cd $botrepo
  BOTBRANCH=`git rev-parse --abbrev-ref HEAD`
fi

cfastrepo=$repo/cfast
CD_REPO $cfastrepo $CFASTBRANCH || exit 1
if [ "$CFASTBRANCH" == "current" ]; then
  cd $cfastrepo
  CFASTBRANCH=`git rev-parse --abbrev-ref HEAD`
fi

fdsrepo=$repo/fds
CD_REPO $fdsrepo $FDSBRANCH || exit 1
if [ "$FDSBRANCH" == "current" ]; then
  cd $fdsrepo
  FDSBRANCH=`git rev-parse --abbrev-ref HEAD`
fi


smvrepo=$repo/smv
CD_REPO $smvrepo $SMVBRANCH ||  exit 1
if [ "$SMVBRANCH" == "current" ]; then
  cd $smvrepo
  SMVBRANCH=`git rev-parse --abbrev-ref HEAD`
fi

cd $smokebotrundir

#*** save pid if -k option (kill smokebot) is used lateer

echo $$ > $PID_FILE

# if -a option is invoked, only proceed running smokebot if the
# smokeview or FDS source has changed

if [[ $RUNAUTO == "y" ]] ; then
  run_auto || exit 1
fi
if [[ $RUNAUTO == "Y" ]] ; then
  run_auto smv || exit 1
fi

#*** if one of WEB_URL or web_DIR exist then both should exist
#    if web_DIR exists then it must be writable

if [ "$WEB_URL" == "" ]; then
  web_DIR=
fi
if [ "$web_DIR" == "" ]; then
  WEB_URL=
else
  if [ -d $web_DIR ]; then
    testfile=$web_DIR/test.$$
    touch $testfile >& /dev/null
    if [ -e $testfile ]; then
      rm $testfile
    else
      web_DIR=
      WEB_URL=
    fi
  else
    web_DIR=
    WEB_URL=
  fi
fi

if [ "$COMPILER" == "intel" ]; then
  if [[ "$IFORT_COMPILER" != "" ]] ; then
    source $IFORT_COMPILER/bin/compilervars.sh intel64
  fi 
  notfound=`icc -help 2>&1 | tail -1 | grep "not found" | wc -l`
else
  notfound=`gcc -help 2>&1 | tail -1 | grep "not found" | wc -l`
fi
if [ "$notfound" == "1" ] ; then
  export haveCC="0"
  USEINSTALL="-i"
  USEINSTALL2="-u"
else
  export haveCC="1"
  USEINSTALL=
  USEINSTALL2=
fi

DB=_db

platform="linux"
platform2="Linux"
if [ "`uname`" == "Darwin" ]
then
  platform="osx"
  platform2="OSX"
fi
export platform

echo ""
echo "Smokebot Settings"
echo "-----------------"
echo "    FDS repo: $fdsrepo"
echo "  FDS branch: $FDSBRANCH"
echo "    SMV repo: $smvrepo"
echo "  SMV branch: $SMVBRANCH"
echo "  CFAST repo: $cfastrepo"
echo "CFAST branch: $CFASTBRANCH"
echo "    bot repo: $botrepo"
echo "  bot branch: $BOTBRANCH"
echo "     Run dir: $smokebotdir"
if [ "$CLEANREPO" == "1" ]; then
  echo " clean repos: yes"
else
  echo " clean repos: no"
fi
if [ "$UPDATEREPO" == "1" ]; then
  echo "update repos: yes"
else
  echo "update repos: no"
fi
if [ ! "$web_DIR" == "" ]; then
  echo "     web dir: $web_DIR"
fi
if [ ! "$WEB_URL" == "" ]; then
  echo "         URL: $WEB_URL"
fi
echo ""

cd

export SMV_SUMMARY="$smvrepo/Manuals/SMV_Summary"
WEBFROM_DIR="$smvrepo/Manuals/SMV_Summary"

UploadGuides=$botrepo/Smokebot/smv_guides2GD.sh
UploadWEB=$botrepo/Smokebot/smv_web2GD.sh

THIS_FDS_AUTHOR=
THIS_FDS_FAILED=0
THIS_CFAST_FAILED=0
FDS_STATUS_FILE=$smvrepo/FDS_status
LAST_FDS_FAILED=0
if [ -e $FDS_STATUS_FILE ] ; then
  LAST_FDS_FAILED=`cat $FDS_STATUS_FILE`
fi

# Load mailing list for status report
if [ "$mailTo" == "" ]; then
  if [ -e $EMAIL_LIST ]; then
    source $EMAIL_LIST
    mailTo=$mailToSMV
    if [[ "$LAST_FDS_FAILED" == "1" ]] ; then
      mailTo=$mailToFDS
    fi
  fi
fi
if [ "$mailTo" == "" ]; then
  mailTo=`git config user.email`
fi
if [ "$mailTo" == "" ]; then
  mailTo=`whoami`@`hostname`
fi
if [ "$mailToSMV" == "" ]; then
  mailToSMV=$mailTo
fi
if [ "$mailToFDS" == "" ]; then
  mailToFDS=$mailTo
fi
if [ "$mailToCFAST" == "" ]; then
  mailToCFAST=$mailTo
fi

export JOBPREFIX=SB_

#  =============================================
#  = Smokebot timing and notification mechanism =
#  =============================================

# This routine checks the elapsed time of Smokebot.
# If Smokebot runs more than 12 hours, an email notification is sent.
# This is a notification only and does not terminate Smokebot.
# This check runs during Stages 3 and 5.

# Start timer
START_TIME=$(date +%s)

# Set time limit (43,200 seconds = 12 hours)
TIME_LIMIT=43200
TIME_LIMIT_EMAIL_NOTIFICATION="unsent"


SCRIPT_TIME_beg=`GET_TIME`
PRELIM_beg=`GET_TIME`
echo "" > $STAGE_STATUS
hostname=`hostname`
start_time=`date`
clean_smokebot_history

### Stage 0 repo operatoins ###
echo "Run Status"
echo "----------"
if [ "$CLEANREPO" == "1" ]; then
  echo Cleaning
  echo "   cfast"
  clean_repo2 cfast master || exit 1
  echo "   fds"
  clean_repo2 fds $FDSBRANCH || exit 1
  echo "   fig"
  clean_repo2 fig master || exit 1
  echo "   smv"
  clean_repo2 smv $SMVBRANCH || exit 1
else
  echo Repos not cleaned
fi

if [ "$UPDATEREPO" == "1" ]; then
  echo "Updating"
  echo "   cfast"
  update_repo cfast $CFASTBRANCH || exit 1
  echo "   fds"
  update_repo fds $FDSBRANCH || exit 1
  echo "   fig"
  update_repo fig master     || exit 1
  echo "   smv"
  update_repo smv $SMVBRANCH || exit 1
else
  echo Repos not updated
fi

check_update_repo

PRELIM_end=`GET_TIME`
DIFF_PRELIM=`GET_DURATION $PRELIM_beg $PRELIM_end`
echo "Preliminary: $DIFF_PRELIM" >> $STAGE_STATUS

### Stage 1 build cfast and FDS ###
BUILDSOFTWARE_beg=`GET_TIME`
compile_cfast
compile_fds_mpi_db
check_compile_fds_mpi_db
if [ "$OPENMPI_GNU" != "" ]; then
  compile_fds_mpi_gnu_db
  check_compile_fds_mpi_gnu_db
fi

### Stage 2 build smokeview ###
compile_smv_utilities
check_smv_utilities
check_common_files

if [[ $stage1b_fdsdb_success && "$RUNDEBUG" == "1" ]] ; then
   run_verification_cases_debug
fi

if [ "$SMOKEBOT_LITE" == "" ]; then
if [[ $stage1b_fdsdb_success ]] ; then
   compile_fds_mpi
   check_compile_fds_mpi
fi
fi
if [[ $stage1b_fdsdb_success && "$RUNDEBUG" == "1" ]] ; then
   check_verification_cases_debug
fi
RUNCASES_beg=`GET_TIME`
if [ "$SMOKEBOT_LITE" == "" ]; then
  if [[ $stage1c_fdsrel_success ]] ; then
     run_verification_cases_release
  fi
fi

### Stage 2 build smokeview ###
compile_smv_db
check_compile_smv_db

if [ "$SMOKEBOT_LITE" == "" ]; then
  compile_smv
  check_compile_smv
fi

BUILDSOFTWARE_end=`GET_TIME`
DIFF_BUILDSOFTWARE=`GET_DURATION $BUILDSOFTWARE_beg $BUILDSOFTWARE_end`
echo "Build Software: $DIFF_BUILDSOFTWARE" >> $STAGE_STATUS

### Stage 3 run verification cases ###

if [ "$SMOKEBOT_LITE" == "" ]; then
  if [[ $stage1c_fdsrel_success ]] ; then
     check_verification_cases_release
  fi
fi
RUNCASES_end=`GET_TIME`
DIFF_RUNCASES=`GET_DURATION $RUNCASES_beg $RUNCASES_end`
echo "Run cases: $DIFF_RUNCASES" >> $STAGE_STATUS

### Stage 4 generate images ###
MAKEPICTURES_beg=`GET_TIME`
if [[ "$SMOKEBOT_LITE" == "" ]] && [[ "$SKIP" == "" ]]; then
  if [[ $stage1c_fdsrel_success && $stage2c_smv_success ]] ; then
    make_smv_pictures
    check_smv_pictures
  fi
fi
MAKEPICTURES_end=`GET_TIME`
DIFF_MAKEPICTURES=`GET_DURATION $MAKEPICTURES_beg $MAKEPICTURES_end`
echo "Make pictures: $DIFF_MAKEPICTURES" >> $STAGE_STATUS

if [[ "$SMOKEBOT_LITE" == "" ]] && [[ "$SKIP" == "" ]]; then
  if [ "$MAKEMOVIES" == "1" ]; then
    MAKEMOVIES_beg=`GET_TIME`
 
    make_smv_movies
    check_smv_movies

    MAKEMOVIES_end=`GET_TIME`
    DIFF_MAKEMOVIES=`GET_DURATION $MAKEMOVIES_beg $MAKEMOVIES_end`
    echo "Make movies: $DIFF_MAKEMOVIES" >> $STAGE_STATUS
  fi
fi

if [[ "$SMOKEBOT_LITE" == "" ]] && [[ "$SKIP" == "" ]]; then
  if [[ $stage1c_fdsrel_success ]] ; then
    generate_timing_stats
  fi
fi

### Stage 5 build documents ###
MAKEGUIDES_beg=`GET_TIME`
if [[ "$SMOKEBOT_LITE" == "" ]] && [[ "$SKIP" == "" ]]; then
  if [[ $stage1c_fdsrel_success && $stage4b_smvpics_success ]] ; then
     echo Making guides
     if [ "$YOPT" == "" ]; then
       echo "   geometry notes"
       make_guide geom_notes $fdsrepo/Manuals/FDS_User_Guide geometry_notes
     fi
     echo "   user"
     make_guide SMV_User_Guide                $smvrepo/Manuals/SMV_User_Guide                SMV_User_Guide
     echo "   technical"
     make_guide SMV_Technical_Reference_Guide $smvrepo/Manuals/SMV_Technical_Reference_Guide SMV_Technical_Reference_Guide
     echo "   verification"
     make_guide SMV_Verification_Guide        $smvrepo/Manuals/SMV_Verification_Guide        SMV_Verification_Guide
  else
     echo Errors found, not building guides
  fi
fi

MAKEGUIDES_end=`GET_TIME`
DIFF_MAKEGUIDES=`GET_DURATION $MAKEGUIDES_beg $MAKEGUIDES_end`
echo "Make guides: $DIFF_MAKEGUIDES" >> $STAGE_STATUS

SCRIPT_TIME_end=`GET_TIME`
DIFF_SCRIPT_TIME=`GET_DURATION $SCRIPT_TIME_beg $SCRIPT_TIME_end`
echo "Total time: $DIFF_SCRIPT_TIME" >> $STAGE_STATUS

### Report results ###
echo Reporting results
set_files_world_readable || exit 1
save_build_status
 
if [ "$SMOKEBOT_LITE" == "" ]; then
  if [[ $stage1c_fdsrel_success ]] ; then
    archive_timing_stats
  fi
fi
echo "   emailing results"
email_build_status
