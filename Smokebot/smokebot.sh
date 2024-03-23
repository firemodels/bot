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
  GIT_SMV_REVISION_FILE=$GIT_STATUS_DIR/smv_revision_$SMVBRANCH
  GIT_SMV_LOG_FILE=$GIT_STATUS_DIR/smv_log

  FDS_SOURCE_DIR=$fdsrepo/Source
  GIT_FDS_REVISION_FILE=$GIT_STATUS_DIR/fds_revision_$FDSBRANCH
  GIT_FDS_LOG_FILE=$GIT_STATUS_DIR/FDS_log

  ROOT_DIR=$smvrepo/Verification
  GIT_ROOT_REVISION_FILE=$GIT_STATUS_DIR/root_revision_$SMVBRANCH
  GIT_ROOT_LOG_FILE=$GIT_STATUS_DIR/ROOT_log

  MESSAGE_FILE=$GIT_STATUS_DIR/message

  MKDIR $GIT_STATUS_DIR

  if [[ "$UPDATEREPO" == "1" ]] ; then
    update_repo smv $SMVBRANCH || return 1
    update_repo fig $FIGBRANCH || return 1
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
  if [ ! -e $GIT_ROOT_REVISION_FILE ]; then
    touch $GIT_ROOT_REVISION_FILE
  fi
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
  if [ "$HAVEMAIL" != "" ]; then
    cat $MESSAGE_FILE | mail $REPLYTO -s "smokebot run initiated" $mailTo > /dev/null
  fi
  return 0
}

#---------------------------------------------
#                   GET_TIME
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

      if [[ "$HAVEMAIL" != "" ]] && [[ $ELAPSED_TIME -gt $TIME_LIMIT ]]; then
         echo -e "smokebot has been running for more than 12 hours in Stage ${TIME_LIMIT_STAGE}. \n\nPlease ensure that there are no problems. \n\nThis is a notification only and does not terminate smokebot." | mail $REPLYTO -s "smokebot Notice: smokebot has been running for more than 12 hours." $mailTo > /dev/null
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
   MKDIR guides               > /dev/null
   MKDIR $HISTORY_DIR_ARCHIVE > /dev/null
   MKDIR $OUTPUT_DIR          > /dev/null
   rm -rf $OUTPUT_DIR/*       > /dev/null
   MKDIR $NEWGUIDE_DIR        > /dev/null
   chmod 775 $NEWGUIDE_DIR
}

#---------------------------------------------
#                   compile_cfast
#---------------------------------------------

compile_cfast()
{
   cd $SMOKEBOT_HOME_DIR

    # Build CFAST
    echo "   release cfast"
    cd $cfastrepo/Build/CFAST/${COMPILER}_${platform}_64
    rm -f cfast7_${platform}_64
    make --makefile ../makefile clean &> /dev/null
    ./make_cfast.sh >> $OUTPUT_DIR/stage1a_cfast 2>&1
}

#---------------------------------------------
#                   check_compile_cfast_db
#---------------------------------------------

check_compile_cfast()
{
   # Check for errors in CFAST compilation
   cd $cfastrepo/Build/CFAST/${COMPILER}_${platform}_64
   if [ -e "cfast7_${platform}_64" ]
   then
      stage0_success=true
   else
      echo "Errors from Stage 1a - CFAST:" >> $ERROR_LOG
      echo "CFAST failed to compile"      >> $ERROR_LOG
      cat $OUTPUT_DIR/stage1a_cfast             >> $ERROR_LOG
      echo ""                             >> $ERROR_LOG
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
        IS_DIRTY=`git describe --abbrev=7 --long --dirty | grep dirty | wc -l`
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
   fi
   if [[ "$reponame" == "fds" ]]; then
      git update-index --refresh
   fi
   if [[ "$reponame" == "cfast" ]]; then
      git update-index --refresh
   fi

   cd $repo/$reponame
   git update-index --refresh
   IS_DIRTY=`git describe --abbrev=7 --long --dirty | grep dirty | wc -l`
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
      need_push=`git status -uno | head -2 | grep -v nothing | grep -v 'Your branch' | grep -v '^$' | wc -l`
      if [ $need_push -gt 1 ]; then
        echo "warning: firemodels commits to $reponame repo need to be pushed to origin" >> $OUTPUT_DIR/stage0 2>&1
        git status -uno | head -2 | grep -v nothing                                      >> $OUTPUT_DIR/stage0 2>&1
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
  local FDSDIR=$1
  local FDSEXE=$2
  local MPTYPE=$3

   # Clean and compile mpi FDS debug
   echo "   debug fds $MPTYPE"
   cd $FDSDIR
   rm -f $FDSEXE
   echo ""                     > $OUTPUT_DIR/stage1b_fds_dbg$MPTYPE
   echo $FDSDIR               >> $OUTPUT_DIR/stage1b_fds_dbg$MPTYPE
   $botrepo/Scripts/build_fds.sh $OUTPUT_DIR/stage1b_fds_dbg$MPTYPE &
}

#---------------------------------------------
#                   check_compile_fds_mpi_db
#---------------------------------------------

check_compile_fds_mpi_db()
{
  local FDSDIR=$1
  local FDSEXE=$2
  local MPTYPE=$3
   # Check for errors in FDS debug compilation
   cd $FDSDIR
   if [ -e $FDSEXE ]; then
      stage_fdsdb_success=true
   else
      echo "Errors from Stage 1b$MPTYPE - Compile FDS MPI$MPTYPE debug:"   >> $ERROR_LOG
      cat $OUTPUT_DIR/stage1b_fds_dbg$MPTYPE                                       >> $ERROR_LOG
      echo ""                                                              >> $ERROR_LOG
      THIS_FDS_FAILED=1
      compile_errors=1
   fi

   # Check for compiler warnings/remarks
   if [ -e $OUTPUT_DIR/stage1b_fds_dbg ]; then
   if [[ `grep -i -E 'warning|remark' $OUTPUT_DIR/stage1b_fds_dbg| grep -v mpiifort -v | grep -v 'pointer not aligned at address' | grep -v Referenced | grep -v ipo | grep -v 'find atom' | grep -v 'feupdateenv is not implemented'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Stage 1b warnings:" >> $WARNING_LOG
      grep -A 5 -i -E 'warning|remark' $OUTPUT_DIR/stage1b_fds_dbg$MPTYPE | grep -v mpiifort | grep -v 'pointer not aligned at address' | grep -v Referenced | grep -v ipo | grep -v 'find atom' | grep -v 'feupdateenv is not implemented'>> $WARNING_LOG
      echo "" >> $WARNING_LOG
   # if the executable does not exist then an email has already been sent
      if [ ! -e $FDSEXE ] ; then
        THIS_FDS_FAILED=1
      fi
      compile_errors=1
   fi
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
     echo "Verification"
     echo "   clean Verification directory"
     cd $smvrepo/Verification
     clean_repo $smvrepo/Verification
   fi
   rm -rf $smvrepo/Verification_dbg
   cp -r $smvrepo/Verification $smvrepo/Verification_dbg

   #  =====================
   #  = Run all SMV cases =
   #  =====================

   echo "   run cases using debug FDS"
   cd $smvrepo/Verification_dbg/scripts

   # Submit SMV verification cases and wait for them to start
   echo 'Running SMV verification cases:' >> $OUTPUT_DIR/stage3a_vv_dbg 2>&1
   RUNOPT=-Y
   RUNOPT="$RUNOPT"
   COMPOPT=
   if [ "$COMPILER" == "gnu" ]; then
     COMPOPT=-C
   fi
   ./Run_SMV_Cases.sh $INTEL2 $RUNOPT $COMPOPT -c $cfastrepo $USEINSTALL2 -j $JOBPREFIXD -m 2 -d -q $QUEUE >> $OUTPUT_DIR/stage3a_vv_dbg 2>&1 
}

#---------------------------------------------
#                   check_verification_cases_debug
#---------------------------------------------

check_verification_cases_debug()
{
   # Scan and report any errors in FDS verification cases
   cd $smvrepo/Verification_dbg

   if [[ `grep -rIi 'Run aborted' $OUTPUT_DIR/stage3a_vv_dbg` == "" ]] && \
      [[ `grep -rIi 'Segmentation' Visualization/* WUI/* ` == "" ]] && \
      [[ `grep -rI  'ERROR:' Visualization/* WUI/* ` == "" ]] && \
      [[ `grep -rIi 'STOP: Numerical' Visualization/* WUI/* ` == "" ]] && \
      [[ `grep -rIi 'forrtl' Visualization/* WUI/* ` == "" ]]
   then
      stage3a_vv_dbg_success=true
   else
      grep -rIi 'Run aborted' $OUTPUT_DIR/stage3a_vv_dbg > $OUTPUT_DIR/stage3a_vv_dbg_errors
      grep -rIi 'Segmentation' Visualization/* WUI/*  >> $OUTPUT_DIR/stage3a_vv_dbg_errors
      grep -rI  'ERROR:' Visualization/* WUI/*  >> $OUTPUT_DIR/stage3a_vv_dbg_errors
      grep -rIi 'STOP: Numerical' -rIi Visualization/* WUI/* >> $OUTPUT_DIR/stage3a_vv_dbg_errors
      grep -rIi -A 20 'forrtl' Visualization/* WUI/*  >> $OUTPUT_DIR/stage3a_vv_dbg_errors
      
      echo "Errors from Stage 3a - Run verification cases (debug mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3a_vv_dbg_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_FDS_FAILED=1
   fi
   if [[ `grep 'Warning' -irI $OUTPUT_DIR/stage3a_vv_dbg | grep -v 'SPEC' | grep -v 'Sum of'` == "" ]] && \
      [[ `grep 'Warning' -irI Visualization/* WUI/*      | grep -v 'SPEC' | grep -v 'Sum of'` == "" ]]
   then
      no_warnings=true
   else
      echo "Stage 3b warnings:" >> $WARNING_LOG
      grep 'Warning' -irI $OUTPUT_DIR/stage3a_vv_dbg | grep -v 'SPEC' | grep -v 'Sum of' >> $WARNING_LOG
      grep 'Warning' -irI Visualization/* WUI/*      | grep -v 'SPEC' | grep -v 'Sum of' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   compile_fds_mpi
#---------------------------------------------

compile_fds_mpi()
{
  local FDSDIR=$1
  local FDSEXE=$2
  local MPTYPE=$3

   # Clean and compile FDS
   echo "   release fds $MPTYPE"
   cd $FDSDIR
   rm -f $FDSEXE
   echo ""                     > $OUTPUT_DIR/stage1c_fds_rls$MPTYPE
   echo $FDSDIR               >> $OUTPUT_DIR/stage1c_fds_rls$MPTYPE
   $botrepo/Scripts/build_fds.sh $OUTPUT_DIR/stage1c_fds_rls$MPTYPE &
}

#---------------------------------------------
#                   wait_compile_end
#---------------------------------------------

wait_compile_end()
{
   local compile_dir=$1
   sleep 5
   while [[  -e $compile_dir/compiling    ]]; do
      sleep 5
   done
}

#---------------------------------------------
#                   check_compile_fds_mpi
#---------------------------------------------

check_compile_fds_mpi()
{
  local FDSDIR=$1
  local FDSEXE=$2
  local MPTYPE=$3

   # Check for errors in FDS compilation
   cd $FDSDIR
   if [ -e $FDSEXE ]
   then
      stage_ver_release_success=true
   else
      echo "Errors from Stage 1c$MPTYPE - Compile FDS MPI$MPYPE release:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage1c_fds_rls$MPTYPE >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      compile_errors=1
   fi

   # Check for compiler warnings/remarks
   # 'performing multi-file optimizations' and 'generating object file' are part of a normal compile
   if [ -e $OUTPUT_DIR/stage1c_fds_rls$MPTYPE ]; then
   if [[ `grep -i -E 'warning|remark' $OUTPUT_DIR/stage1c_fds_rls$MPTYPE | grep -v 'pointer not aligned at address' | grep -v Referenced | grep -v ipo | grep -v 'find atom' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file'| grep -v 'feupdateenv is not implemented'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Stage 1c warnings:" >> $WARNING_LOG
      grep -A 5 -i -E 'warning|remark' $OUTPUT_DIR/stage1c_fds_rls$MPTYPE | grep -v 'pointer not aligned at address' | grep -v Referenced | grep -v ipo | grep -v 'find atom' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file'| grep -v 'feupdateenv is not implemented' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
      compile_errors=1
   fi
   fi
}

#---------------------------------------------
#                   compile_smv_utilities
#---------------------------------------------

compile_smv_utilities()
{
   echo "" > $OUTPUT_DIR/stage2a_smvutil
   if [ "$haveCC" == "1" ] ; then
   # smokeview libraries
     echo "   libraries"
     cd $smvrepo/Build/LIBS/${COMPILER}_${platform}_64
     echo 'Building Smokeview libraries:' >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     ./make_LIBS.sh >> $OUTPUT_DIR/stage2a_smvutil 2>&1

   # smokezip:
     echo "   smokezip"
     cd $smvrepo/Build/smokezip/${COMPILER}_${platform}_64
     rm -f *.o smokezip_${platform}_64

     echo 'Compiling smokezip:' >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     ./make_smokezip.sh >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     echo "" >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     cp smokezip_${platform}_64 $LATESTAPPS_DIR/smokezip

   # smokediff:
     echo "   smokediff"
     cd $smvrepo/Build/smokediff/${COMPILER}_${platform}_64
     rm -f *.o smokediff_${platform}_64
     echo 'Compiling smokediff:' >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     ./make_smokediff.sh >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     echo "" >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     cp smokediff_${platform}_64 $LATESTAPPS_DIR/smokediff

   # background
     echo "   background"
     cd $smvrepo/Build/background/${COMPILER}_${platform}_64
     rm -f *.o background_${platform}_64
     echo 'Compiling background:' >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     ./make_background.sh >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     cp background_${platform}_64 $LATESTAPPS_DIR/background

   # hashfile
     echo "   hashfile"
     cd $smvrepo/Build/hashfile/${COMPILER}_${platform}_64
     rm -f *.o hashfile_${platform}_64
     echo 'Compiling hashfile:' >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     ./make_hashfile.sh >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     cp hashfile_${platform}_64 $LATESTAPPS_DIR/hashfile

  # wind2fds:
     echo "   wind2fds"
     cd $smvrepo/Build/wind2fds/${COMPILER}_${platform}_64
     rm -f *.o wind2fds_${platform}_64
     echo 'Compiling wind2fds:' >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     ./make_wind2fds.sh >> $OUTPUT_DIR/stage2a_smvutil 2>&1
    echo "" >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     cp wind2fds_${platform}_64 $LATESTAPPS_DIR/wind2fds
   else
     echo "Warning: smokeview and utilities not built - C compiler not available" >> $OUTPUT_DIR/stage2a_smvutil 2>&1
     compile_errors=1
   fi
}

#---------------------------------------------
#                   is_file_installed
#---------------------------------------------

is_file_installed()
{
  local program=$1
  
  notfound=`$program -help |& tail -1 | grep "not found" | wc -l`
  if [ "$notfound" == "1" ] ; then
    stage2a_smvutil_success="0"
    echo "***error: $program not installed" >> $OUTPUT_DIR/stage2a_smvutil
  fi
}

#---------------------------------------------
#                   compare_fds_smv_common_files
#---------------------------------------------

compare_fds_smv_common_files()
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
       echo "***warning: The fds and smv versions of $file are out of synch" >> $WARNING_LOG
     fi
   fi
}

#---------------------------------------------
#                   check_common_files
#---------------------------------------------

check_common_files()
{
  # only compare files if latest repo revisions are checkout out
  if [ "$CHECKOUT" == "" ]; then
    compare_fds_smv_common_files Manuals/Bibliography Manuals/Bibliography BIBLIO_FDS_general.tex
    compare_fds_smv_common_files Manuals/Bibliography Manuals/Bibliography BIBLIO_FDS_mathcomp.tex
    compare_fds_smv_common_files Manuals/Bibliography Manuals/Bibliography BIBLIO_FDS_refs.tex
    compare_fds_smv_common_files Manuals/Bibliography Manuals/Bibliography authors.tex
    compare_fds_smv_common_files Manuals/Bibliography Manuals/Bibliography disclaimer.tex
  fi
}

#---------------------------------------------
#                   check_smv_utilities
#---------------------------------------------

check_smv_utilities()
{
   SMOKEZIP="$smvrepo/Build/smokezip/${COMPILER}_${platform}_64/smokezip_${platform}_64"
   SMOKEDIFF="$smvrepo/Build/smokediff/${COMPILER}_${platform}_64/smokediff_${platform}_64"
   WIND2FDS="$smvrepo/Build/wind2fds/${COMPILER}_${platform}_64/wind2fds_${platform}_64"
   BACKGROUND="$smvrepo/Build/background/${COMPILER}_${platform}_64/background_${platform}_64"
   if [ "$haveCC" == "1" ] ; then
     # Check for errors in SMV utilities compilation
     cd $smvrepo
     if [ -e "$SMOKEZIP" ]    && \
        [ -e "$SMOKEDIFF" ]  && \
        [ -e "$WIND2FDS" ]    && \
        [ -e "$BACKGROUND" ]
     then
        stage_utilities_success="1"
     else
        stage_utilities_success="0"
        echo "Errors from Stage 2c - Compile SMV utilities:" >> $ERROR_LOG
        if [ ! -e "$SMOKEZIP" ]; then
          echo ""
          echo "error: smokezip failed to compile"           >> $ERROR_LOG
          echo "       $SMOKEZIP does not exist"             >> $ERROR_LOG
        fi
        if [ ! -e "$SMOKEDIFF" ]; then
          echo ""
          echo "error: smokediff failed to compile"          >> $ERROR_LOG
          echo "       $SMOKEDIFF does not exist"            >> $ERROR_LOG
        fi 
        if [ ! -e "$WIND2FDS" ]; then
          echo ""
          echo "error: wind2fds failed to compile"           >> $ERROR_LOG
          echo "       $WIND2FDS does not exist"             >> $ERROR_LOG
        fi 
        if [ ! -e "$BACKGROUND" ]; then
          echo ""
          echo "error: background failed to compile"         >> $ERROR_LOG
          echo "       $BACKGROUND does not exist"           >> $ERROR_LOG
        fi
        cat $OUTPUT_DIR/stage2c_smv_rls                              >> $ERROR_LOG
        echo ""                                              >> $ERROR_LOG
        compile_errors=1
     fi
   else
     stage_utilities_success="1"
     is_file_installed smokeview
     is_file_installed smokezip
     is_file_installed smokediff
     is_file_installed wind2fds
     is_file_installed background
     if [ "$stage_utilities_success" == "0" ] ; then
        echo "Errors from Stage 2c - Smokeview and utilities:" >> $ERROR_LOG
        stage_utilities_success="1"
        cat $OUTPUT_DIR/stage2c_smv_rls                                >> $ERROR_LOG
        echo ""                                                >> $ERROR_LOG
        compile_errors=1
     fi
   fi
}

#---------------------------------------------
#                   wait_verification_cases_end
#---------------------------------------------

wait_verification_cases_end()
{
   stage=$1
   stagelimit=$2
   prefix=$3
   # Scans qstat and waits for verification cases to end
   if [[ "$QUEUE" == "none" ]]
   then
     while [[          `ps -u $USER -f | fgrep .fds | grep -v smokebot | grep -v grep` != '' ]]; do
        JOBS_REMAINING=`ps -u $USER -f | fgrep .fds | grep -v smokebot | grep -v grep | wc -l`

        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/$stage
        TIME_LIMIT_STAGE=$stagelimit
        check_time_limit
        sleep 30
     done
   else
     while           [[ `qstat -a | awk '{print $2 $4 $10}' | grep $(whoami) | grep $prefix | grep -v 'C$'` != '' ]]; do
        JOBS_REMAINING=`qstat -a | awk '{print $2 $4 $10}' | grep $(whoami)  | grep $prefix | grep -v 'C$' | wc -l`
        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/$stage
        TIME_LIMIT_STAGE=$stagelimit
        check_time_limit
        sleep 30
     done
   fi
}

#---------------------------------------------
#                   run_verification_cases_release
#---------------------------------------------

run_verification_cases_release()
{
   #  ======================
   #  = Remove .stop files =
   #  ======================

   echo "   run cases using release FDS"
   # Start running all SMV verification cases
   cd $smvrepo/Verification/scripts
   echo 'Running SMV verification cases:' >> $OUTPUT_DIR/stage3b_vv_rls 2>&1
   RUNOPT=-Y
   RUNOPT="$RUNOPT"
   COMPOPT=
   if [ "$COMPILER" == "gnu" ]; then
     COMPOPT=-C
   fi
   ./Run_SMV_Cases.sh $INTEL2 $RUNOPT $COMPOPT -c $cfastrepo -j $JOBPREFIXR $USEINSTALL2 -q $QUEUE >> $OUTPUT_DIR/stage3b_vv_rls 2>&1
   ./Run_RESTART_Cases.sh -q $QUEUE                                                                >> $OUTPUT_DIR/stage3b_vv_rls 2>&1
}

#---------------------------------------------
#                   check_verification_cases_release
#---------------------------------------------

check_verification_cases_release()
{
   # Scan and report any errors in FDS verification cases
   cd $smvrepo/Verification

   if [[ `grep -rIi 'Run aborted' $OUTPUT_DIR/stage3b_vv_rls` == "" ]] && \
      [[ `grep -rIi 'Segmentation' Visualization/* WUI/* ` == "" ]] && \
      [[ `grep -rI  'ERROR:' Visualization/* WUI/*  ` == "" ]] && \
      [[ `grep -rIi 'STOP: Numerical' Visualization/* WUI/*  ` == "" ]] && \
      [[ `grep -rIi  'forrtl' Visualization/* WUI/*  ` == "" ]]
   then
      stage3b_vv_rls_success=true
   else
      grep -rIi 'Run aborted' $OUTPUT_DIR/stage3b_vv_rls  > $OUTPUT_DIR/stage3b_vv_rls_errors
      grep -rIi 'Segmentation' Visualization/* WUI/*     >> $OUTPUT_DIR/stage3b_vv_rls_errors
      grep -rI  'ERROR:' Visualization/* WUI/*           >> $OUTPUT_DIR/stage3b_vv_rls_errors
      grep -rIi 'STOP: Numerical' Visualization/* WUI/*  >> $OUTPUT_DIR/stage3b_vv_rls_errors
      grep -rIi -A 20 'forrtl' Visualization/* WUI/*     >> $OUTPUT_DIR/stage3b_vv_rls_errors

      echo "Errors from Stage 3b - Run verification cases (release mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3b_vv_rls_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_FDS_FAILED=1
   fi

      
   if [[ `grep 'Warning' -irI $OUTPUT_DIR/stage3b_vv_rls | grep -v 'SPEC' | grep -v 'Sum of'` == "" ]] && \
      [[ `grep 'Warning' -irI Visualization/* WUI/*      | grep -v 'SPEC' | grep -v 'Sum of'` == "" ]]
   then
      no_warnings=true
   else
      echo "Stage 3b warnings:" >> $WARNING_LOG
      grep 'Warning' -irI $OUTPUT_DIR/stage3b_vv_rls | grep -v 'SPEC' | grep -v 'Sum of' >> $WARNING_LOG
      grep 'Warning' -irI Visualization/* WUI/*      | grep -v 'SPEC' | grep -v 'Sum of' >> $WARNING_LOG
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
     echo "   debug smokeview"
     cd $smvrepo/Build/smokeview/${COMPILER}_${platform}_64
     rm -f smokeview_${platform}_64_db
     ./make_smokeview_db.sh $SANITIZE &> $OUTPUT_DIR/stage2b_smv_dbg
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
    if [ -e "smokeview_${platform}_64_db" ]
    then
       stage2b_smv_dbg_success=true
    else
      echo "Errors from Stage 2b - Compile SMV debug:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2b_smv_dbg                          >> $ERROR_LOG
      echo ""                                          >> $ERROR_LOG
      compile_errors=1
    fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
    if [[ `grep -i -E 'warning|remark' $OUTPUT_DIR/stage2b_smv_dbg | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]
    then
      # Continue along
      :
    else
      echo "Stage 2b warnings:" >> $WARNING_LOG
      grep -A 5 -i -E 'warning|remark' $OUTPUT_DIR/stage2b_smv_dbg | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
      compile_errors=1
    fi
  fi
}

#---------------------------------------------
#                   compile_smv
#---------------------------------------------

compile_smv()
{
   if [ "$haveCC" == "1" ] ; then
   # Clean and compile SMV
     echo "   release smokeview"
     cd $smvrepo/Build/smokeview/${COMPILER}_${platform}_64
     rm -f smokeview_${platform}_64
     ./make_smokeview.sh $SANITIZE  &> $OUTPUT_DIR/stage2c_smv_rls
   fi
}

#---------------------------------------------
#                   check_compile_smv
#---------------------------------------------

check_compile_smv()
{
  if [ "$haveCC" == "1" ]; then
   # Check for errors in SMV release compilation
    cd $smvrepo/Build/smokeview/${COMPILER}_${platform}_64
    if [ -e "smokeview_${platform}_64" ]; then
      cp smokeview_${platform}_64 $LATESTAPPS_DIR/smokeview
      stage2c_smv_rls_smv_success=true
    else
      echo "Errors from Stage 2c - Compile SMV release:"           >> $ERROR_LOG
      echo "The program smokeview_${platform}_64 does not exist."  >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2c_smv_rls                                      >> $ERROR_LOG
      echo ""                                                      >> $ERROR_LOG
      compile_errors=1
    fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
    if [[ `grep -i -E 'warning|remark' $OUTPUT_DIR/stage2c_smv_rls | grep -v 'feupdateenv is not implemented' | grep -v 'was built for newer' | grep -v 'lcilkrts linked'` == "" ]]
    then
      # Continue along
      :
    else
      echo "Stage 2c warnings:" >> $WARNING_LOG
      grep -A 5 -i -E 'warning|remark' $OUTPUT_DIR/stage2c_smv_rls | grep -v 'feupdateenv is not implemented' | grep -v 'was built for newer' | grep -v 'lcilkrts linked' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
      compile_errors=1
    fi
  fi
}

#---------------------------------------------
#                   make_smv_pictures
#---------------------------------------------

make_smv_pictures()
{
   # Run Make SMV Pictures script (release mode)
   echo Generating
   echo "   images"
   cd $smvrepo/Verification/scripts
   RUNOPT=-Y
   COMPOPT=
   if [ "$COMPILER" == "gnu" ]; then
     COMPOPT=-C
   fi
   ./Make_SMV_Pictures.sh $RUNOPT $COMPOPT -q $QUEUE -j SMV_ $USEINSTALL 2>&1 &> $OUTPUT_DIR/stage4a_picts
   grep -v FreeFontPath $OUTPUT_DIR/stage4a_picts | grep -v libpng &> $OUTPUT_DIR/stage4b_picts
}

#---------------------------------------------
#                   check_smv_pictures
#---------------------------------------------

check_smv_pictures()
{
   # Scan and report any errors in make SMV pictures process
   grep -I -E -i Segmentation $smvrepo/Verification/Visualization/*.err >> $OUTPUT_DIR/stage4b_picts
   grep -I -E -i Segmentation $smvrepo/Verification/WUI/*.err           >> $OUTPUT_DIR/stage4b_picts
   cd $smokebotdir
   echo "   checking"
   if [[ `grep -I -E -i "Segmentation|Error" $OUTPUT_DIR/stage4b_picts` == "" ]]
   then
      stage4b_picts_smvpics_success=true
   else
      cp $OUTPUT_DIR/stage4b_picts  $OUTPUT_DIR/stage4b_picts_errors

      echo "Errors from Stage 4a - Make SMV pictures (release mode):" >> $ERROR_LOG
      grep -B 5 -A 5 -I -E -i "Segmentation|Error"  $OUTPUT_DIR/stage4b_picts  >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi
   if [[ `grep -I -E -i "Warning" $OUTPUT_DIR/stage4b_picts` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 4a - Make SMV pictures (release mode):" >> $WARNING_LOG
      grep -A 2 -I -E -i "Warning" $OUTPUT_DIR/stage4b_picts                     >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   make_smv_movies
#---------------------------------------------

make_smv_movies()
{
   echo "   movies"
   cd $smvrepo/Verification
   scripts/Make_SMV_Movies.sh -q $QUEUE 2>&1  &> $OUTPUT_DIR/stage4c_mp4
}

#---------------------------------------------
#                   check_smv_movies
#---------------------------------------------

check_smv_movies()
{
   cd $smokebotdir
   echo "   checking"
   if [[ `grep -I -E -i "Segmentation|Error" $OUTPUT_DIR/stage4c_mp4` == "" ]]
   then
      stage4c_mp4_success=true
   else
      echo "Errors from Stage 4c - Make SMV movies "                    >> $ERROR_LOG
      grep -B 1 -A 1 -I -E -i "Segmentation|Error"  $OUTPUT_DIR/stage4c_mp4 >  $OUTPUT_DIR/stage4c_mp4_errors
      grep -B 1 -A 1 -I -E -i "Segmentation|Error"  $OUTPUT_DIR/stage4c_mp4 >> $ERROR_LOG
      echo ""                                                           >> $ERROR_LOG
   fi

   # Scan for and report any warnings in make SMV pictures process
   cd $smokebotdir
   if [[ `grep -I -E -i "Warning" $OUTPUT_DIR/stage4c_mp4` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 4b - Make SMV movies (release mode):" >> $WARNING_LOG
      grep -I -E -i "Warning" $OUTPUT_DIR/stage4c_mp4                     >> $WARNING_LOG
      echo ""                                                         >> $WARNING_LOG
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
  cp smv_timing_stats.csv          "$HISTORY_DIR_ARCHIVE/${SMV_REVISION}_timing.csv"
  cp smv_benchmarktiming_stats.csv "$HISTORY_DIR_ARCHIVE/${SMV_REVISION}_benchmarktiming.csv"
  sort -r -k 2 -t  ',' -n smv_timing_stats.csv | head -10 | awk -F',' '{print $1":", $2}' > $OUTPUT_DIR/slow_cases
  TOTAL_SMV_TIMES=`tail -1 smv_benchmarktiming_stats.csv`
  if [[ "$UPLOADRESULTS" == "1" ]] && [[ "$USER" == "smokebot" ]]; then
    cd $botrepo/Smokebot
    ./smvstatus_updatepub.sh $repo/webpages $WEBBRANCH
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
   if [ "$WEB_DIR" != "" ]; then
     if [ -d $WEB_ROOT/$WEB_DIR/manuals ]; then
       SMOKEBOT_MAN_DIR=$WEB_ROOT/$WEB_DIR/manuals
     fi
   fi

   cd $smokebotdir
   if [[ `grep -I "successfully" $stage` == "" ]]; then
      echo "Errors from Stage 5 - Build Smokeview Guides:" >> $ERROR_LOG
      echo $label >> $ERROR_LOG
      cat $stage >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   else
     if [ "$SMOKEBOT_MAN_DIR" != "" ]; then
       cp $directory/$document $SMOKEBOT_MAN_DIR/.
     fi
     chmod 664 $directory/$document
     cp $directory/$document $SMV_SUMMARY_DIR/manuals/.
     cp $directory/$document $NEWGUIDE_DIR/.
     cp $directory/$document $LATESTPUBS_DIR/$document
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
     echo "   build failure and warnings for version: ${SMV_REVISION}, branch: $SMVBRANCH."
     echo "Build failure and warnings;$SMV_DATE;$SMV_SHORTHASH;$SMV_LONGHASH;${SMV_REVISION};$SMVBRANCH;$STOP_TIME_INT;3;$TOTAL_SMV_TIMES;$HOST" > "$HISTORY_DIR_ARCHIVE/${SMV_REVISION}.txt"
     cat $ERROR_LOG > "$HISTORY_DIR_ARCHIVE/${SMV_REVISION}_errors.txt"

   # Check for errors only
   elif [ -e $ERROR_LOG ]
   then
      echo "   build failure for version: ${SMV_REVISION}, branch: $SMVBRANCH."
      echo "Build failure;$SMV_DATE;$SMV_SHORTHASH;$SMV_LONGHASH;${SMV_REVISION};$SMVBRANCH;$STOP_TIME_INT;3;$TOTAL_SMV_TIMES;$HOST" > "$HISTORY_DIR_ARCHIVE/${SMV_REVISION}.txt"
      cat $ERROR_LOG > "$HISTORY_DIR_ARCHIVE/${SMV_REVISION}_errors.txt"

   # Check for warnings only
   elif [ -e $WARNING_LOG ]
   then
      echo "   build success with warnings for version: ${SMV_REVISION}, branch: $SMVBRANCH."
      echo "Build success with warnings;$SMV_DATE;$SMV_SHORTHASH;$SMV_LONGHASH;${SMV_REVISION};$SMVBRANCH;$STOP_TIME_INT;2;$TOTAL_SMV_TIMES;$HOST" > "$HISTORY_DIR_ARCHIVE/${SMV_REVISION}.txt"
      cat $WARNING_LOG > "$HISTORY_DIR_ARCHIVE/${SMV_REVISION}_warnings.txt"

   # No errors or warnings
   else
      echo "   build success for version: ${SMV_REVISION}, branch: $SMVBRANCH."
      echo "Build success!;$SMV_DATE;$SMV_SHORTHASH;$SMV_LONGHASH;${SMV_REVISION};$SMVBRANCH;$STOP_TIME_INT;1;$TOTAL_SMV_TIMES;$HOST" > "$HISTORY_DIR_ARCHIVE/${SMV_REVISION}.txt"
   fi
}

#---------------------------------------------
#                   save_manuals_dir
#---------------------------------------------

save_manuals_dir()
{
  if [[ ! -e $WARNING_LOG && ! -e $ERROR_LOG ]]
  then
    echo "   archiving Manuals directory"
    rm -rf $MANUAL_DIR_ARCHIVE
    cp -r $smvrepo/Manuals $MANUAL_DIR_ARCHIVE
    if [ "$MAKEMOVIES" == "1" ]; then
      echo "   archiving Manuals directory (movies)"
      rm -rf $MOVIEMANUAL_DIR_ARCHIVE
      cp -r $smvrepo/Manuals $MOVIEMANUAL_DIR_ARCHIVE
    fi
    rm -rf $PUBS_DIR
    cp  -r $LATESTPUBS_DIR $PUBS_DIR
  fi
}

#---------------------------------------------
#                   email_compile_errors
#---------------------------------------------

email_compile_errors()
{
  SMOKEBOT_LOG=/tmp/smokebot_log.$$
  if [[ -e $ERROR_LOG ]]; then
    echo "" > $SMOKEBOT_LOG
  fi
  if [[ -e $WARNING_LOG ]]; then
    echo "" > $SMOKEBOT_LOG
  fi

  if [[ -e $ERROR_LOG ]]; then
    echo "----------------------------------------------" >> $SMOKEBOT_LOG
    echo "---------------- errors ----------------------" >> $SMOKEBOT_LOG
    echo "----------------------------------------------" >> $SMOKEBOT_LOG
    cat $ERROR_LOG >> $SMOKEBOT_LOG
  fi 
  if [[ -e $WARNING_LOG ]]; then
    echo "----------------------------------------------" >> $SMOKEBOT_LOG
    echo "---------------- warnings --------------------" >> $SMOKEBOT_LOG
    echo "----------------------------------------------" >> $SMOKEBOT_LOG
    cat $WARNING_LOG >> $SMOKEBOT_LOG
  fi 

  if [[ "$HAVEMAIL" != "" ]] && [[ -e $SMOKEBOT_LOG ]]; then
    cat $SMOKEBOT_LOG | mail $REPLYTO -s "smokebot compile errors and/or warnings on ${hostname}. ${SMV_REVISION}, $SMVBRANCH" $mailToSMV > /dev/null
    rm -f $SMOKEBOT_LOG
  fi
}

#---------------------------------------------
#                   email_build_status
#---------------------------------------------

email_build_status()
{
  if [ "$RUNAUTO" == "" ]; then
    if [[ "$THIS_FDS_FAILED" == "1" ]] ; then
      mailTo="$mailToFDS"
    fi
    if [[ "$THIS_CFAST_FAILED" == "1" ]] ; then
      mailTo="$mailToCFAST"
    fi
  fi
  echo $THIS_FDS_FAILED>$FDS_STATUS_FILE
  stop_time=`date`
  if [ "$COMPILER" == "intel" ]; then
    IFORT_VERSION=`ifort -v 2>&1`
  else
    IFORT_VERSION=`gfortran --version | head -1`
  fi
  echo "----------------------------------------------"      > $TIME_LOG
  echo "host/OS: $hostname/$platform2"                      >> $TIME_LOG
  echo "repo: $repo"                                        >> $TIME_LOG
  echo "queue: $QUEUE"                             >> $TIME_LOG
  echo "$BOT_REVISION/$BOTBRANCH"                           >> $TIME_LOG
  echo "$CFAST_REVISION/$CFASTBRANCH"                       >> $TIME_LOG
  echo "$FDS_REVISION/$FDSBRANCH"                           >> $TIME_LOG
  echo "$FIG_REVISION/$FIGBRANCH"                           >> $TIME_LOG
  echo "$SMV_REVISION/$SMVBRANCH"                           >> $TIME_LOG
  if [ "$IFORT_VERSION" != "" ]; then
    echo "Fortran: $IFORT_VERSION "                         >> $TIME_LOG
  fi
  echo ""                                                   >> $TIME_LOG
  echo "start time: $start_time "                           >> $TIME_LOG
  echo "stop time: $stop_time "                             >> $TIME_LOG
  if [ "$CLONE_REPOS" == "" ]; then
    echo "setup repos: $DIFF_CLONE"                         >> $TIME_LOG
  else
    echo "clone repos: $DIFF_CLONE"                         >> $TIME_LOG
  fi
  echo "setup smokebot: $DIFF_SETUP"                        >> $TIME_LOG
  echo "build software: $DIFF_BUILDSOFTWARE"                >> $TIME_LOG
  echo "run cases: $DIFF_RUN_CASES"                         >> $TIME_LOG
  echo "make pictures: $DIFF_MAKEPICTURES"                  >> $TIME_LOG
  if [ "$MAKEMOVIES" == "1" ]; then
    echo "make movies: $DIFF_MAKEMOVIES"                    >> $TIME_LOG
  fi
if [ "$DIFF_MAKEGUIDES" != "" ]; then
  echo "build guides: $DIFF_MAKEGUIDES"                     >> $TIME_LOG
fi
if [ "$DIFF_COMPAREIMAGES" != "" ]; then
  echo "compare images: $DIFF_COMPAREIMAGES"                >> $TIME_LOG
fi
  echo "total: $DIFF_SCRIPT_TIME"                           >> $TIME_LOG
  echo "benchmark time(s): $TOTAL_SMV_TIMES"                >> $TIME_LOG
  echo ""                                                   >> $TIME_LOG
  DISPLAY_FDS_REVISION=
  DISPLAY_SMV_REVISION=
  if [ "$RUNAUTO" != "" ]; then
    DISPLAY_FDS_REVISION=1
    DISPLAY_SMV_REVISION=1
  fi
  if [ "$DISPLAY_FDS_REVISION" == "1" ]; then
    echo "FDS revisions: old: $LAST_FDS_REVISION new: $THIS_FDS_REVISION" >> $TIME_LOG
  fi
  if [ "$DISPLAY_SMV_REVISION" == "1" ]; then
    echo "SMV revisions: old: $LAST_SMV_REVISION new: $THIS_SMV_REVISION" >> $TIME_LOG
  fi
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
  if [ "$NAMELIST_NODOC_STATUS" != "" ]; then
    if [ "$NAMELIST_NODOC_STATUS" == "0" ]; then
     echo "undocumented namelist keywords: $NAMELIST_NODOC_STATUS" >> $TIME_LOG
    fi
  else
    NAMELIST_NODOC_LOG=
  fi
  if [ "$NAMELIST_NOSOURCE_STATUS" == "" ]; then
    NAMELIST_NOSOURCE_LOG=
  fi
  cd $smokebotdir
  echo ""  >> $TIME_LOG
  # Check for warnings and errors
  if [[ "$WEB_URL" != "" ]] && [[ "$UPDATED_WEB_IMAGES" == "1" ]]; then
    if [ -e $IMAGE_DIFFS ]; then
      NUM_CHANGES=`cat $IMAGE_DIFFS | awk '{print $1}'`
      NUM_ERRORS=`cat $IMAGE_DIFFS | awk '{print $2}'`
      echo "images: $WEB_URL, errors/changes: $NUM_ERRORS/$NUM_CHANGES"  >> $TIME_LOG
    else
      echo "images: $WEB_URL" >> $TIME_LOG
    fi
  fi
  if [[ "$WEB_URL" == "" ]]; then
    if [ -e $IMAGE_DIFFS ]; then
      NUM_CHANGES=`cat $IMAGE_DIFFS | awk '{print $1}'`
      NUM_ERRORS=`cat $IMAGE_DIFFS | awk '{print $2}'`
      echo "images errors/changes: $NUM_ERRORS/$NUM_CHANGES"  >> $TIME_LOG
    fi
  fi
  if [ "$UPLOADRESULTS" == "1" ]; then
    echo "status: https://pages.nist.gov/fds-smv/smokebot_status.html" >> $TIME_LOG
    is_bot=
    if [ `whoami` == "firebot" ]; then
      is_bot=1
    fi
    if [ `whoami` == "cfast" ]; then
      is_bot=1
    fi
    if [ `whoami` == "smokebot" ]; then
      is_bot=1
    fi
    if [[ "$is_bot" == "1" ]]; then
      GITURL=https://github.com/$GH_OWNER/$GH_REPO/releases/tag/$GH_SMOKEVIEW_TAG
      echo "Bundles/Guides/Figures: $GITURL"  >> $TIME_LOG
      echo  "***output guides, figures and image summary to Github"             > output/stage_GHupload
      echo  ""                                                  >> output/stage_GHupload
      $UploadSummaryGH                                          &>> output/stage_GHupload
      if [[ ! -e $WARNING_LOG ]] && [[ ! -e $ERROR_LOG ]]; then
        $UploadGuidesGH                                          &>> output/stage_GHupload
      fi
    fi
  fi
  echo ""                                  >> $TIME_LOG
  if [ -e $OUTPUT_DIR/slow_cases ]; then
    echo "cases with longest runtime:"     >> $TIME_LOG
    cat $OUTPUT_DIR/slow_cases             >> $TIME_LOG
    echo ""                                >> $TIME_LOG
  fi
  NAMELIST_LOGS="$NAMELIST_NODOC_LOG $NAMELIST_NOSOURCE_LOG"
  if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]; then
    # Send email with failure message and warnings, body of email contains appropriate log file
    SUBJECT="smokebot failure and warnings on ${hostname}. ${SMV_REVISION}, $SMVBRANCH"
    if [ "$HAVEMAIL" != "" ]; then
      cat $ERROR_LOG $TIME_LOG $NAMELIST_LOGS | mail $REPLYTO -s "$SUBJECT" $mailTo > /dev/null
    fi
    cat $ERROR_LOG $TIME_LOG $NAMELIST_LOGS > $FULL_LOG

  # Check for errors only
  elif [ -e $ERROR_LOG ]; then
    # Send email with failure message, body of email contains error log file
    SUBJECT="smokebot failure on ${hostname}. ${SMV_REVISION}, $SMVBRANCH"
    if [ "$HAVEMAIL" != "" ]; then
      cat $ERROR_LOG $TIME_LOG $NAMELIST_LOGS | mail $REPLYTO -s "$SUBJECT" $mailTo > /dev/null
    fi
    cat $ERROR_LOG $TIME_LOG $NAMELIST_LOGS > $FULL_LOG

  # Check for warnings only
  elif [ -e $WARNING_LOG ]; then
     # Send email with success message, include warnings
    SUBJECT="smokebot success with warnings on ${hostname}. ${SMV_REVISION}, $SMVBRANCH"
    if [ "$HAVEMAIL" != "" ]; then
      cat $WARNING_LOG $TIME_LOG $NAMELIST_LOGS | mail $REPLYTO -s "$SUBJECT" $mailTo > /dev/null
    fi
    cat $WARNING_LOG $TIME_LOG $NAMELIST_LOGS > $FULL_LOG

  # No errors or warnings
  else
# upload guides to a google drive directory
    if [ "$UPLOADRESULTS" == "1" ]; then
      cd $smokebotdir
      echo  "***output guides to Github"  &> output/stage_upload
      echo  ""                            &>> output/stage_upload
      $UploadWEB                  $smvrepo/Manuals $MAKEMOVIES &>> output/stage_upload
    fi

      # Send success message with links to nightly manuals

    SUBJECT="smokebot success on ${hostname}. ${SMV_REVISION}, $SMVBRANCH"
    if [ "$HAVEMAIL" != "" ]; then
      cat $TIME_LOG $NAMELIST_LOGS | mail $REPLYTO -s "$SUBJECT" $mailTo > /dev/null
    fi
    cat $TIME_LOG $NAMELIST_LOGS > $FULL_LOG

# save apps that were built for bundling

    rm -f $APPS_DIR/*
    cp $LATESTAPPS_DIR/* $APPS_DIR/.

    rm -f $BRANCHAPPS_DIR/*
    cp $LATESTAPPS_DIR/* $BRANCHAPPS_DIR/.

    rm -f $BRANCHPUBS_DIR/*
    cp $LATESTPUBS_DIR/* $BRANCHPUBS_DIR/.
  fi
  if [ "$HAVEMAIL" == "" ]; then
    cat $FULL_LOG
    echo ""
    echo "smokebot status: $SUBJECT"
  fi
}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             beginning of smokebot.sh
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** define initial values

SCRIPT_TIME_beg=`GET_TIME`
CLONE_beg=`GET_TIME`
smokebotdir=`pwd`
OUTPUT_DIR="$smokebotdir/output"
HISTORY_DIR_ARCHIVE="$HOME/.smokebot/history"
MANUAL_DIR_ARCHIVE=$HOME/.smokebot/Manuals
MOVIEMANUAL_DIR_ARCHIVE=$HOME/.smokebot/MovieManuals

LATESTPUBS_DIR=$HOME/.smokebot/pubs_latest
PUBS_DIR=$HOME/.smokebot/pubs

EMAIL_LIST="$HOME/.smokebot/smokebot_email_list.sh"
TIME_LOG=$OUTPUT_DIR/timings
ERROR_LOG=$OUTPUT_DIR/errors
FULL_LOG=$OUTPUT_DIR/full_log
WARNING_LOG=$OUTPUT_DIR/warnings
FYI_LOG=$OUTPUT_DIR/fyis
STAGE_STATUS=$OUTPUT_DIR/stage_status
NEWGUIDE_DIR=$OUTPUT_DIR/Newest_Guides
WEB_DIR=
WEB_ROOT=
UPDATED_WEB_IMAGES=
export SCRIPTFILES=$smokebotdir/scriptfiles

WEBBRANCH=nist-pages
FDSBRANCH=master
SMVBRANCH=master
CFASTBRANCH=master
BOTBRANCH=master
FIGBRANCH=master

QUEUE=smokebot
MAKEMOVIES=0
RUNAUTO=
CLEANREPO=0
UPDATEREPO=0
mailTo=
UPLOADRESULTS=
COMPILER=intel
PID_FILE=~/.fdssmvgit/firesmokebot_pid
HTML2PDF=wkhtmltopdf
CLONE_REPOS=
FDS_REV=origin/master
SMV_REV=origin/master
FDS_TAG=
SMV_TAG=
CHECKOUT=
SANITIZE=
compile_errors=
GITURL=
CACHE_DIR=
HAVEMAIL=`which mail |& grep -v 'no mail'`

#*** save pid so -k option (kill smokebot) may be used lateer

echo $$ > $PID_FILE

#*** parse command line options

while getopts 'aAb:cCDJm:Mq:R:s:SuUw:W:x:X:y:Y:' OPTION
do
case $OPTION in
  a)
   RUNAUTO="a"
   ;;
  A)
   RUNAUTO="A"
   ;;
  b)
   SMVBRANCH="$OPTARG"
   if [ "$SMVBRANCH" == "current" ]; then
     FDSBRANCH="current"
     CFASTBRANCH="current"
     BOTBRANCH="current"
     FIGBRANCH="current"
   fi
   ;;
  c)
   CLEANREPO=1
   ;;
  C)
   FORCECLONE="-C"
   ;;
  D)
   COMPILER=gnu
   MPI_TYPE=ompi
   export OMP_NUM_THREADS=1
   ;;
  J)
   MPI_TYPE=impi
   INTEL2="-J"
   ;;
  m)
   mailTo="$OPTARG"
   ;;
  M)
   MAKEMOVIES="1"
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  R)
   CLONE_REPOS="$OPTARG"
   ;;
  s)
   CACHE_DIR="$OPTARG"
   ;;
  S)
   SANITIZE=-S
   ;;
  u)
   UPDATEREPO=1
   ;;
  U)
   UPLOADRESULTS=1
   ;;
  w)
   WEB_DIR="$OPTARG"
   ;;
  W)
   WEB_ROOT="$OPTARG"
   ;;
  x)
   FDS_REV="$OPTARG"
   CHECKOUT=1
   ;;
  X)
   FDS_TAG="$OPTARG"
   ;;
  y)
   SMV_REV="$OPTARG"
   CHECKOUT=1
   ;;
  Y)
   SMV_TAG="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$CLONE_REPOS" != "" ]; then
  if [ "$CLONE_REPOS" != "release" ]; then
    if [ "$CLONE_REPOS" != "test" ]; then
      CLONE_REPO="master"
    fi
  fi
fi

ABORT=
if [ "$CACHE_DIR" != "" ]; then
  if [ ! -d $CACHE_DIR ]; then
    echo "***error: cache directory $CACHE_DIR does not exist"
    exit
  fi
  CUR_DIR=`pwd`
  cd $CACHE_DIR
  CACHE_DIR=`pwd`
  cd $CUR_DIR
  if [ ! -d $CACHE_DIR/Build ]; then
    echo "***error: cache directory $CACHE_DIR/Build does not exist"
    ABORT=1
  fi
  if [ ! -d $CACHE_DIR/WUI ]; then
    echo "***error: cache directory $CACHE_DIR/WUI does not exist"
    ABORT=1
  fi
  if [ ! -d $CACHE_DIR/Visualization ]; then
    echo "***error: cache directory $CACHE_DIR/Visualization does not exist"
    ABORT=1
  fi
fi
if [ "$ABORT" != "" ]; then
  exit
fi

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

if [[ "$QUEUE" == "none" ]] && [[ -e $SCRIPTFILES ]]; then
  rm -f $SCRIPTFILES
fi

#*** create pub directory

MKDIR $HOME/.smokebot
MKDIR $PUBS_DIR
rm -rf $LATESTPUBS_DIR
MKDIR $LATESTPUBS_DIR

APPS_DIR=$HOME/.smokebot/apps
LATESTAPPS_DIR=$HOME/.smokebot/apps_latest

MKDIR $APPS_DIR
rm -rf $LATESTAPPS_DIR
MKDIR $LATESTAPPS_DIR

botrepo=$repo/bot
cfastrepo=$repo/cfast
fdsrepo=$repo/fds
smvrepo=$repo/smv
figrepo=$repo/fig

size=
GNU_MPI=ompi_

platform="linux"
platform2="Linux"
if [ "`uname`" == "Darwin" ]
then
  platform="osx"
  platform2="OSX"
fi
export platform

FDSGNU_DB_DIR=$fdsrepo/Build/${GNU_MPI}${GNU_COMPILER}${platform}${size}_db
FDSGNU_DB_EXE=

FDS_DB_DIR=$fdsrepo/Build/${MPI_TYPE}_${COMPILER}_${platform}${size}_db
FDS_DB_EXE=fds_${MPI_TYPE}_${COMPILER}_${platform}${size}_db

FDS_DIR=$fdsrepo/Build/${MPI_TYPE}_${COMPILER}_${platform}${size}
FDS_EXE=fds_${MPI_TYPE}_${COMPILER}_${platform}${size}

# clean smokebot output files

clean_smokebot_history

#*** write out file when firebot first starts
date > $OUTPUT_DIR/stage0_start 2>&1

if [[ "$CLONE_REPOS" != "" ]]; then
  echo Cloning repos
  cd $botrepo/Scripts

# only clone fds and smv repos
   # clone all repos
    ./setup_repos.sh -F $FORCECLONE              > $OUTPUT_DIR/stage1_clone 2>&1
  if [[ "$CLONE_REPOS" != "master" ]]; then
    FDSBRANCH=$CLONE_REPOS
    cd $fdsrepo
    git checkout -b $FDSBRANCH $FDS_REV          >> $OUTPUT_DIR/stage1_clone 2>&1
    if [ "$FDS_TAG" != "" ]; then
      git tag -a $FDS_TAG -m "tag for $FDS_TAG"  >> $OUTPUT_DIR/stage1_clone 2>&1
    fi

    SMVBRANCH=$CLONE_REPOS
    cd $smvrepo
    git checkout -b $SMVBRANCH $SMV_REV          >> $OUTPUT_DIR/stage1_clone 2>&1
    if [ "$SMV_TAG" != "" ]; then
      git tag -a $SMV_TAG -m "tag for $SMV_TAG"  >> $OUTPUT_DIR/stage1_clone 2>&1
    fi
  fi
fi

#*** make sure repos needed by smokebot exist

CD_REPO $botrepo $BOTBRANCH || exit 1
if [ "$BOTBRANCH" == "current" ]; then
  cd $botrepo
  BOTBRANCH=`git rev-parse --abbrev-ref HEAD`
fi

CD_REPO $cfastrepo $CFASTBRANCH || exit 1
if [ "$CFASTBRANCH" == "current" ]; then
  cd $cfastrepo
  CFASTBRANCH=`git rev-parse --abbrev-ref HEAD`
fi

CD_REPO $fdsrepo $FDSBRANCH || exit 1
if [ "$FDSBRANCH" == "current" ]; then
  cd $fdsrepo
  FDSBRANCH=`git rev-parse --abbrev-ref HEAD`
fi

CD_REPO $smvrepo $SMVBRANCH ||  exit 1
if [ "$SMVBRANCH" == "current" ]; then
  cd $smvrepo
  SMVBRANCH=`git rev-parse --abbrev-ref HEAD`
fi

CD_REPO $figrepo $FIGBRANCH ||  exit 1
if [ "$FIGBRANCH" == "current" ]; then
  cd $figrepo
  FIGBRANCH=`git rev-parse --abbrev-ref HEAD`
fi

#save apps and pubs in directories under .smokebot/$SMVBRANCH
BRANCH_DIR=$HOME/.smokebot/$SMVBRANCH
BRANCHPUBS_DIR=$BRANCH_DIR/pubs
BRANCHAPPS_DIR=$BRANCH_DIR/apps
MKDIR $BRANCH_DIR
MKDIR $BRANCHPUBS_DIR
MKDIR $BRANCHAPPS_DIR

# if -a option is invoked, only proceed running smokebot if the
# smokeview or FDS source has changed

if [[ $RUNAUTO != "" ]] ; then
  runoption=""
  if [ "$RUNAUTO" == "A" ]; then
    runoption="smv"
  fi
  run_auto $runoption || exit 1
fi

if [ "$WEB_DIR" != "" ]; then
  if [ -d $WEB_ROOT/$WEB_DIR ]; then
    testfile=$WEB_ROOT/$WEB_DIR/test.$$
    touch $testfile >& /dev/null
    if [ -e $testfile ]; then
      rm $testfile
    else
      WEB_DIR=
    fi
  else
    WEB_DIR=
  fi
fi
if [ "$WEB_DIR" != "" ]; then
  WEB_HOST=`hostname -A | awk '{print $2}'`
  WEB_URL=http://$WEB_HOST/$WEB_DIR
else
  WEB_URL=
fi

if [[ "$IFORT_COMPILER" != "" ]] ; then
  source $IFORT_COMPILER/bin/compilervars.sh intel64
fi 
if [ "$COMPILER" == "gnu" ]; then
  notfound=`gcc -help 2>&1 | tail -1 | grep "not found" | wc -l`
else
  notfound=`icx -help 2>&1 | tail -1 | grep "not found" | wc -l`
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

echo ""
echo "Smokebot Settings"
echo "-----------------"
echo "    bot repo;branch: $botrepo;$BOTBRANCH"
echo "  CFAST repo;branch: $cfastrepo;$CFASTBRANCH"
echo "    FDS repo;branch: $fdsrepo;$FDSBRANCH"
echo "    FIG repo;branch: $figrepo;$FIGBRANCH"
echo "    SMV repo;branch: $smvrepo;$SMVBRANCH"
echo "      run directory: $smokebotdir"
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
if [ "$WEB_DIR" != "" ]; then
  echo "     web dir: $WEB_ROOT/$WEB_DIR"
fi
if [ "$WEB_URL" != "" ]; then
  echo "         URL: $WEB_URL"
fi
echo ""

cd

SMV_SUMMARY_DIR=$smvrepo/Manuals/SMV_Summary
IMAGE_DIFFS=$SMV_SUMMARY_DIR/image_differences

UploadGuidesGH=$botrepo/Smokebot/smv_guides2GH.sh
UploadSummaryGH=$botrepo/Smokebot/smv_summary2GH.sh
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

if [ -e $EMAIL_LIST ]; then
  source $EMAIL_LIST
fi

# define reply to address to prevent bounced emails when doing a reply all to smokebot's status emails

REPLYTO=
if [ "$replyToSMV" != "" ]; then
  REPLYTO="-S replyto=\"$replyToSMV\""
fi

if [ "$mailTo" == "" ]; then
  if [ -e $EMAIL_LIST ]; then
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

JOBPREFIXR=SBR_
JOBPREFIXD=SBD_

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


echo "" > $STAGE_STATUS
hostname=`hostname`
start_time=`date`

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
  clean_repo2 fig $FIGBRANCH || exit 1
  echo "   smv"
  clean_repo2 smv $SMVBRANCH || exit 1
else
  echo Repos not cleaned
fi

if [ "$UPDATEREPO" == "1" ]; then
  echo "Updating"
  echo "   cfast"
  update_repo cfast $CFASTBRANCH || exit 1
  if [ "$CLONE_REPOS" == "" ]; then
    echo "   fds"
    update_repo fds $FDSBRANCH || exit 1
  else
    echo "   fds (cloned - not updating)"
  fi
  echo "   fig"
  update_repo fig $FIGBRANCH   || exit 1
  if [ "$CLONE_REPOS" == "" ]; then
    echo "   smv"
    update_repo smv $SMVBRANCH || exit 1
  else
    echo "   smv (cloned - not updating)"
  fi
else
  echo Repos not updated
fi

check_update_repo

CLONE_end=`GET_TIME`
DIFF_CLONE=`GET_DURATION $CLONE_beg $CLONE_end`
if [ "$CLONE_REPOS" == "" ]; then
  echo "Setup repos: $DIFF_CLONE" >> $STAGE_STATUS
else
  echo "Cone repos: $DIFF_CLONE" >> $STAGE_STATUS
fi

#define repo revisions
SETUP_beg=`GET_TIME`

rm -f $FYI_LOG
touch $FYI_LOG
cd $cfastrepo
CFAST_REVISION=`git describe --abbrev=7 --long --dirty`

cd $fdsrepo
FDS_REVISION=`git describe --abbrev=7 --long --dirty`

cd $figrepo
FIG_REVISION=`git describe --abbrev=7 --long --dirty`

cd $botrepo
BOT_REVISION=`git describe --abbrev=7 --long --dirty`

# copy smv revision and hash to the latest pubs and apps directory
cd $smvrepo

SMV_REVISION=`git describe --abbrev=7 --long --dirty`
SMV_SHORTHASH=`git rev-parse --short HEAD`
SMV_LONGHASH=`git rev-parse HEAD`
SMV_DATE=`git log -1 --format=%cd --date=local $SMV_SHORTHASH`

echo $FDS_REVISION > $smvrepo/Manuals/FDS_REVISION
echo $SMV_REVISION > $smvrepo/Manuals/SMV_REVISION

subrev=`git describe --abbrev | awk -F '-' '{print $2}'`
if [ "$subrev" == "" ]; then
  git describe --abbrev | awk -F '-' '{print $1"-0"}' > $LATESTAPPS_DIR/SMV_REVISION
else
  git describe --abbrev | awk -F '-' '{print $1"-"$2"-"$3}' > $LATESTAPPS_DIR/SMV_REVISION
fi
git rev-parse --short HEAD > $LATESTAPPS_DIR/SMV_HASH

cp $LATESTAPPS_DIR/SMV_REVISION $LATESTPUBS_DIR/SMV_REVISION
cp $LATESTAPPS_DIR/SMV_HASH     $LATESTPUBS_DIR/SMV_HASH

SETUP_end=`GET_TIME`
DIFF_SETUP=`GET_DURATION $SETUP_beg $SETUP_end`
echo "Setup smokebot: $DIFF_SETUP" >> $STAGE_STATUS

#----------------------------- Stage 1 build cfast and FDS     --------------------------------------

BUILDSOFTWARE_beg=`GET_TIME`

#stage1B
echo "Building"

if [ "$CACHE_DIR" == "" ]; then
  touch              $FDS_DB_DIR/compiling
  touch              $FDS_DIR/compiling
  compile_fds_mpi_db $FDS_DB_DIR        $FDS_DB_EXE
  compile_fds_mpi    $FDS_DIR           $FDS_EXE
else
  echo "   debug fds(from cache)"
  echo "   release fds(from cache)"
  if [ ! -d $fdsrepo ]; then
    echo "*error: repo $fdsrepo does not exist"
    exit
  fi
  rm -rf $fdsrepo/Build
  cp -r $CACHE_DIR/Build $fdsrepo/.
fi

# stage1A
compile_cfast
check_compile_cfast

#----------------------------- Stage 2 build smokeview     --------------------------------------

#stage2a_smvutil
compile_smv_utilities
check_smv_utilities

#stage2b_smv_dbg
compile_smv_db
check_compile_smv_db

#stage2c_smv_rls
compile_smv
check_compile_smv

#stage2d_common_files
check_common_files

if [ "$CACHE_DIR" == "" ]; then
  wait_compile_end   $FDS_DB_DIR
  wait_compile_end   $FDS_DIR
fi
check_compile_fds_mpi_db  $FDS_DB_DIR        $FDS_DB_EXE
check_compile_fds_mpi     $FDS_DIR           $FDS_EXE

BUILDSOFTWARE_end=`GET_TIME`
DIFF_BUILDSOFTWARE=`GET_DURATION $BUILDSOFTWARE_beg $BUILDSOFTWARE_end`
echo "Build Software: $DIFF_BUILDSOFTWARE" >> $STAGE_STATUS

### report errors right away if they are found

if [ "$compile_errors" == "1" ]; then
  email_compile_errors
fi

#----------------------------- Stage 3 run verification case     --------------------------------------

#stage3a_vv_dbg begin
RUN_CASES_beg=`GET_TIME`
RUN_CASES=
if [ $stage_fdsdb_success ]; then
   if [ "$CACHE_DIR" == "" ]; then
     run_verification_cases_debug
     RUN_CASES=1
   fi
fi

#stage3b_vv_rls
if [[ $stage_ver_release_success ]]; then
  if [ "$CACHE_DIR" == "" ]; then
    run_verification_cases_release
    RUN_CASES=1
  else
     if [ ! -d $smvrepo ]; then
       echo "***error: $smvrepo does not exist"
       exit
     fi
     rm -rf $smvrepo/Verification/WUI
     rm -rf $smvrepo/Verification/Visualization
     cp -r $CACHE_DIR/WUI           $smvrepo/Verification/.
     cp -r $CACHE_DIR/Visualization $smvrepo/Verification/.
  fi
fi

if [ "$RUN_CASES" != "" ]; then
  wait_verification_cases_end stage3a_vv_dbg 3a $JOBPREFIXD
  wait_verification_cases_end stage3b_vv_rls 3b $JOBPREFIXR
  if [ -e $smvrepo/Verification/scripts/RESTART2_Cases.sh ]; then
    cd $smvrepo/Verification/scripts
    ./RESTART2_Cases.sh $JOBPREFIXR
    wait_verification_cases_end stage3c_vv_restart 3c $JOBPREFIXR
  fi
fi

if [ "$CACHE_DIR" == "" ]; then
  if [ $stage_fdsdb_success ]; then
     check_verification_cases_debug
  fi
  if [[ $stage_ver_release_success ]]; then
    check_verification_cases_release
  fi
fi

RUN_CASES_end=`GET_TIME`
DIFF_RUN_CASES=`GET_DURATION $RUN_CASES_beg $RUN_CASES_end`
echo "Run cases: $DIFF_RUN_CASES" >> $STAGE_STATUS

#----------------------------- Stage 4 generate images and movies     --------------------------------------

### Stage 4a generate images

MAKEPICTURES_beg=`GET_TIME`
if [[ $stage_ver_release_success ]] ; then
  make_smv_pictures
  check_smv_pictures
fi
MAKEPICTURES_end=`GET_TIME`
DIFF_MAKEPICTURES=`GET_DURATION $MAKEPICTURES_beg $MAKEPICTURES_end`
echo "Make pictures: $DIFF_MAKEPICTURES" >> $STAGE_STATUS

if [ "$MAKEMOVIES" == "1" ]; then
  MAKEMOVIES_beg=`GET_TIME`

### Stage 4b generate movies

  make_smv_movies
  check_smv_movies

  MAKEMOVIES_end=`GET_TIME`
  DIFF_MAKEMOVIES=`GET_DURATION $MAKEMOVIES_beg $MAKEMOVIES_end`
  echo "Make movies: $DIFF_MAKEMOVIES" >> $STAGE_STATUS
fi

if [[ $stage_ver_release_success ]] ; then
  generate_timing_stats
fi

#----------------------------- Stage 5 generate manuals     --------------------------------------

if [[ $stage_ver_release_success ]] ; then
   MAKEGUIDES_beg=`GET_TIME`
   echo Making guides
   echo "   user"
   make_guide SMV_User_Guide                $smvrepo/Manuals/SMV_User_Guide                SMV_User_Guide
   echo "   technical"
   make_guide SMV_Technical_Reference_Guide $smvrepo/Manuals/SMV_Technical_Reference_Guide SMV_Technical_Reference_Guide
   echo "   verification"
   make_guide SMV_Verification_Guide        $smvrepo/Manuals/SMV_Verification_Guide        SMV_Verification_Guide

   if [ -d $SMV_SUMMARY_DIR ]; then
     DATE=`date +"%b %d, %Y - %r"`

     sed "s/&&DATE&&/$DATE/g"                $SMV_SUMMARY_DIR/templates/movies_template.html  | \
     sed "s/&&FDS_BUILD&&/$FDS_REVISION/g"                                          | \
     sed "s/&&SMV_BUILD&&/$SMV_REVISION/g" > $SMV_SUMMARY_DIR/movies.html

     MAKEGUIDES_end=`GET_TIME`
     DIFF_MAKEGUIDES=`GET_DURATION $MAKEGUIDES_beg $MAKEGUIDES_end`
     echo "Make guides: $DIFF_MAKEGUIDES" >> $STAGE_STATUS

# copy images to be compared to summary directory
     COMPAREIMAGES_beg=`GET_TIME`
     cp $smvrepo/Manuals/SMV_User_Guide/SCRIPT_FIGURES/*.png         $SMV_SUMMARY_DIR/images/user/.
     cp $smvrepo/Manuals/SMV_Verification_Guide/SCRIPT_FIGURES/*.png $SMV_SUMMARY_DIR/images/verification/.
     cd $botrepo/Smokebot
     ./remove_images.sh $SMV_SUMMARY_DIR/images

# compare images generated by this smokebot run with a base set in the fig repo
     TOLERANCE=0.2
     cd $botrepo/Smokebot
   echo Comparing images
     ../Firebot/compare_images.sh $SMV_SUMMARY_DIR/images $SMV_SUMMARY_DIR/diffs/images $OUTPUT_DIR/error_images $TOLERANCE >& $OUTPUT_DIR/stage5_image_compare
     COMPAREIMAGES_end=`GET_TIME`
     DIFF_COMPAREIMAGES=`GET_DURATION $COMPAREIMAGES_beg $COMPAREIMAGES_end`
     echo "Comparing images: $DIFF_COMPAREIMAGES" >> $STAGE_STATUS

     UPDATED_WEB_IMAGES=1

# look for fyis
     if [[ `grep '***fyi:' $OUTPUT_DIR/stage5_image_compare` == "" ]]; then
       # Continue along
       :
     else
       echo "FYIs from Stage 5 - Image comparisons:"     >> $FYI_LOG
       grep '***fyi:' $OUTPUT_DIR/stage5_image_compare   >> $FYI_LOG
     fi

# look for warnings
     if [[ `grep '***warning:' $OUTPUT_DIR/stage5_image_compare` == "" ]]; then
       # Continue along
       :
     else
       echo "Warnings from Stage 5 - Image comparisons:"     >> $WARNING_LOG
       grep '***warning:' $OUTPUT_DIR/stage5_image_compare   >> $WARNING_LOG
     fi
       
     if [ "$WEB_DIR" != "" ]; then
       WEB_DIR_OLD=${WEB_DIR}_old
       rm -rf $WEB_ROOT/$WEB_DIR_OLD
       if [ -d $WEB_ROOT/$WEB_DIR ]; then
         mv $WEB_ROOT/$WEB_DIR $WEB_ROOT/$WEB_DIR_OLD
       fi
       mkdir $WEB_ROOT/$WEB_DIR
       cp -r $SMV_SUMMARY_DIR/* $WEB_ROOT/$WEB_DIR/.
       rm -f $WEB_ROOT/$WEB_DIR/*template.html
     fi
   fi

   notfound=`$HTML2PDF -V 2>&1 | tail -1 | grep "not found" | wc -l`
   if [ $notfound -eq 0 ]; then
     if [ -e  $smvrepo/Manuals/SMV_Summary/diffs.html ]; then
       $HTML2PDF --enable-local-file-access $smvrepo/Manuals/SMV_Summary/diffs.html $smvrepo/Manuals/SMV_Summary/SMV_Diffs.pdf
       cp $smvrepo/Manuals/SMV_Summary/SMV_Diffs.pdf $NEWGUIDE_DIR/.
     fi
   fi
else
   echo Errors found, not building guides
fi

cd $botrepo/Firebot
   echo Compare namelists
./compare_namelists.sh $OUTPUT_DIR stage5 > $OUTPUT_DIR/stage5_namelist_check
NAMELIST_NODOC_STATUS=`cat $OUTPUT_DIR/stage5_namelist_check | head -1 | awk -F' ' '{print $1}'`
if [ "$NAMELIST_NODOC_STATUS" != "0" ]; then
  NAMELIST_NODOC_LOG=$OUTPUT_DIR/stage5_namelists_nodoc.txt
fi
NAMELIST_NOSOURCE_STATUS=`cat $OUTPUT_DIR/stage5_namelist_check | tail -1 | awk -F' ' '{print $1}'`
if [ "$NAMELIST_NOSOURCE_STATUS" != "0" ]; then
  NAMELIST_NOSOURCE_LOG=$OUTPUT_DIR/stage5_namelists_nosource.txt
fi


SCRIPT_TIME_end=`GET_TIME`
DIFF_SCRIPT_TIME=`GET_DURATION $SCRIPT_TIME_beg $SCRIPT_TIME_end`
echo "Total time: $DIFF_SCRIPT_TIME" >> $STAGE_STATUS

### Report results ###
echo Reporting results
set_files_world_readable || exit 1
save_build_status

save_manuals_dir
if [[ $stage_ver_release_success ]] ; then
  archive_timing_stats
fi
if [ "$HAVEMAIL" != "" ]; then
  echo "   emailing results"
fi
email_build_status
