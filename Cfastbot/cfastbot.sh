#!/bin/bash
# CFASTbot
# This script runs the CFAST verification/validation suite 
# on the latest revision of the repository.

#---------------------------------------------
#                   CHK_REPO
#---------------------------------------------

CHK_REPO ()
{
  local repodir=$1
  
  if [ ! -e $repodir ]; then
     echo "***error: the repo directory $repodir does not exist."
     echo "          Aborting cfastbot."
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
  if [ "$branch" != "" ]; then
     CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
     if [ "$CURRENT_BRANCH" != "$branch" ]; then
       echo "***error: was expecting branch $branch in repo $repodir."
       echo "Found branch $CURRENT_BRANCH. Aborting cfastbot."
       return 1
     fi
  fi
  return 0
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
    mkdir $DIR
  fi
}

#---------------------------------------------
#                   is_changed
#---------------------------------------------

is_changed()
{
   local trigger_file=$1
   local trigger_save=$2
 
   if [ ! -e $trigger_save ]; then
      touch $trigger_save
   fi
   
   THIS_REVISION=`git log --abbrev-commit $trigger_file | head -1 | awk '{print $2}'`
   LAST_REVISION=`cat $trigger_save`
   
   if [[ $THIS_REVISION == $LAST_REVISION ]] ; then
      IS_CHANGED=
   else
      IS_CHANGED=1
      echo $THIS_REVISION>$trigger_save
   fi
   
}

#---------------------------------------------
#                   run_auto
#---------------------------------------------

run_auto()
{
   CFAST_SOURCE=$cfastrepo/Source/CFAST
   git_CFASTSOURCELOG=$GITSTATUS_DIR/cfast_source_log
   MESSAGE_FILE=$GITSTATUS_DIR/message
   partial=
   
   TRIGGER=$cfastrepo/Source/CFAST
   git_TRIGGER=$GITSTATUS_DIR/cfast_source_revision
   TRIGGERONLY=$cfastrepo/Source/CFAST/skipmatlab_trigger.txt
   git_TRIGGERONLY=$GITSTATUS_DIR/cfastonly_source_revision
   
   CD_REPO $CFAST_SOURCE $cfastbranch || return 1
   git fetch origin &> /dev/null
   git merge origin/$cfastbranch &> /dev/null
   have_remote=`git remote -v | awk '{print $1}' | grep firemodels | wc  -l`
   if [ "$have_remote" != "0" ]; then
      git fetch firemodels &> /dev/null
      git merge firemodels/$cfastbranch &> /dev/null
   fi

   is_changed $TRIGGER $git_TRIGGER
   if [ "$IS_CHANGED" == "" ]; then
      exit
   fi

   THIS_AUTHOR=`git log . | head -2 | tail -1 | awk '{print $2}'`

   git log . | head -5 | tail -1 > $git_CFASTSOURCELOG
  
   if [[ $THIS_REVISION == $LAST_REVISION ]] ; then
      exit
   fi

   is_changed $TRIGGERONLY $git_TRIGGERONLY
   if [ "$IS_CHANGED" == "1" ]; then
      SKIP=1
      partial=1
   fi

   rm -f $MESSAGE_FILE

   echo -e "CFAST source directory has changed. $LAST_REVISION->$THIS_CFASTSOURCE($THIS_AUTHOR)" >> $MESSAGE_FILE
   cat $git_CFASTSOURCELOG >> $MESSAGE_FILE

   echo -e "CFASTbot run initiated." >> $MESSAGE_FILE
   if [ "$partial" == "" ]; then
     cat $MESSAGE_FILE | mail -s "CFASTbot run initiated" $mailTo &> /dev/null
   else
     cat $MESSAGE_FILE | mail -s "CFASTbot run initiated (skip matlab/doc stages)" $mailTo &> /dev/null
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
         echo -e "CFASTbot has been running for more than 3 hours in Stage ${TIME_LIMIT_STAGE}. \n\nPlease ensure that there are no problems. \n\nThis is a notification only and does not terminate CFASTbot." | mail -s "CFASTbot Notice: CFASTbot has been running for more than 3 hours." $mailTo &> /dev/null
         TIME_LIMIT_EMAIL_NOTIFICATION="sent"
      fi
   fi
}

#---------------------------------------------
#                   set_files_world_readable
#---------------------------------------------

set_files_world_readable()
{
   CD_REPO $cfastrepo $cfastbranch || return 1
   chmod -R go+r *
   
   CD_REPO $smvrepo $smvbranch || return 1
   chmod -R go+r *

   return 0
}

#---------------------------------------------
#                   clean_cfastbot_history
#---------------------------------------------

clean_cfastbot_history()
{
   # Clean cfastbot metafiles
   echo "Cleaning"
   echo "   cfastbot results directory"
   cd $CFASTBOT_RUNDIR
   rm -rf $OUTPUT_DIR/* &> /dev/null
}

#---------------------------------------------
#                   clean_repo
#---------------------------------------------

clean_repo()
{
  local repo=$1
  local branch=$2
  
  curdir=`pwd`
  CD_REPO $repo $branch || return 1
  git clean -dxf &> /dev/null
  git add . &> /dev/null
  git reset --hard HEAD &> /dev/null
  cd $curdir
  return 0
}

#---------------------------------------------
#                   clean_repo2
#---------------------------------------------

clean_repo2()
{
   local repo=$1
   local branch=$2

   CD_REPO $reponame/$repo || return 1

   IS_DIRTY=`git describe --long --dirty | grep dirty | wc -l`
   if [ "$IS_DIRTY" == "1" ]; then
     echo "The repo $reponame/$repo has uncommitted changes."
     echo "Commit or revert these changes or re-run"
     echo "cfastbot without the -c (clean) option"
     return 1
   fi
   echo "   $repo"
   clean_repo $reponame/$repo $branch || return 1
   return 0
}

#---------------------------------------------
#                   update_repo
#---------------------------------------------

update_repo()
{
   local repo=$1
   local branch=$2
   
   
   CD_REPO $reponame/$repo $branch || return 1

   if [[ "$repo" == "cfast" ]]; then
      GIT_REVISION=`git describe --long --dirty`
      GIT_SHORTHASH=`git rev-parse --short HEAD`
      GIT_LONGHASH=`git rev-parse HEAD`
      GIT_DATE=`git log -1 --format=%cd --date=local $GIT_SHORTHASH`
   fi

   echo "Updating branch $branch" >> $OUTPUT_DIR/stage1 2>&1
   git fetch origin >> $OUTPUT_DIR/stage1 2>&1
   git merge origin/$branch >> $OUTPUT_DIR/stage1 2>&1
   have_remote=`git remote -v | awk '{print $1}' | grep firemodels | wc  -l`
   if [ "$have_remote" -gt "0" ]; then
      git fetch firemodels >> $OUTPUT_DIR/stage1 2>&1
      git merge firemodels/$branch >> $OUTPUT_DIR/stage0 2>&1
   fi
   return 0
}

#---------------------------------------------
#                   check_git_checkout
#---------------------------------------------

check_git_checkout()
{
   # Check for git errors
   stage1_success=true
}

#---------------------------------------------
#                   compile_cfast_db
#---------------------------------------------

compile_cfast_db()
{
   # Build debug CFAST
   echo "Building"
   echo "   cfast"
   echo "      debug"
   CD_REPO $cfastrepo/Build/CFAST/${compiler}_${platform}${size}_db $cfastbranch || return 1
   make -f ../makefile clean &> /dev/null
   ./make_cfast.sh &> $OUTPUT_DIR/stage2a
   return 0
 }

#---------------------------------------------
#                   check_compile_cfast_db
#---------------------------------------------

check_compile_cfast_db()
{
   # Check for errors in CFAST debug compilation
   CD_REPO $cfastrepo/Build/CFAST/${compiler}_${platform}${size}_db $cfastbranch || return 1
   if [ -e "cfast7_${platform}${size}_db" ]
   then
      stage2a_success=true
   else
      echo "Errors from Stage 2a - Compile CFAST debug:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2a >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   if [[ `grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2a` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 2a - Compile CFAST debug:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2a >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   compile_cfast
#---------------------------------------------

compile_cfast()
{ 
   # Build release CFAST
   echo "      release"
   CD_REPO $cfastrepo/Build/CFAST/${compiler}_${platform}${size} $cfastbranch || return 1
   make -f ../makefile clean &> /dev/null
   ./make_cfast.sh &> $OUTPUT_DIR/stage2b
}

#---------------------------------------------
#                   check_compile_cfast
#---------------------------------------------

check_compile_cfast()
{
   # Check for errors in CFAST release compilation
   CD_REPO $cfastrepo/Build/CFAST/${compiler}_${platform}${size} $cfastbranch || return 1
   if [[ -e "cfast7_${platform}${size}" ]]
   then
      stage2b_success=true
   else
      echo "Errors from Stage 2b - Compile CFAST:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2b >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   if [[ `grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2b` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 2b - Compile CFAST release:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2b >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   return 0
}

#---------------------------------------------
#                   compile_csmv_utilities
#---------------------------------------------

compile_smv_utilities()
{
   if [ "$USEINSTALL" == "" ]; then
   # smokeview libraries
     CD_REPO $smvrepo/Build/LIBS/${compiler}_${platform}${size} $smvbranch || return 1
     echo 'Building Smokeview libraries' >> $OUTPUT_DIR/stage3a 2>&1
     echo "   smokeview libraries"
     ./makelibs.sh >> $OUTPUT_DIR/stage3a 2>&1

   # background
     if [ "$QUEUE" == "none" ]; then
       cd $smvrepo/Build/background/${compiler}_${platform}${size}
       echo '   background'
       echo 'Compiling background' >> $OUTPUT_DIR/stage3a 2>&1
       ./make_background.sh >> $OUTPUT_DIR/stage3a 2>&1
     fi
   else
     echo "   smokeview libraries - not built, using installed smokview"
     if [ "$QUEUE" == "none" ]; then
       echo "   background - not built, using installed smokeview"
       echo "Using installed smokeview, libraries not built" >> $OUTPUT_DIR/stage3a 2>&1
     fi
   fi
   return 0
}

#---------------------------------------------
#                   check_smv_utilities
#---------------------------------------------

check_smv_utilities()
{
   if [ "$USEINSTALL" == "" ]; then
     # Check for errors in SMV utilities compilation
     stage3a_success="1"
     if [ "$QUEUE" == "none" ]; then
       if [ ! -e "$smvrepo/Build/background/${compiler}_${platform}${size}/background" ]; then
         stage3a_success="0"
       fi
     fi
     if [ "$stage3asuccess" == "0" ]; then
        echo "error building background"
        echo "Errors from Stage 2c - building background:" >> $ERROR_LOG
        cat $OUTPUT_DIR/stage3a >> $ERROR_LOG
        echo "" >> $ERROR_LOG
     fi
   else
     stage3a_success="1"
     if [ "$QUEUE" == "none" ]; then
       is_file_installed background stage3a
     fi
     if [ "$stage3asuccess" == "0" ]; then
        echo "background not installed"
        echo "Errors from Stage 2c - background not installed:" >> $ERROR_LOG
        cat $OUTPUT_DIR/stage3a >> $ERROR_LOG
        echo "" >> $ERROR_LOG
     fi
   fi
   return 0
}

#---------------------------------------------
#                   compile_smv_db
#---------------------------------------------

compile_smv_db()
{
   # Clean and compile SMV DB
   if [ "$USEINSTALL" == "" ]; then
     echo "   smokeview"
     echo "      debug"
     CD_REPO $smvrepo/Build/smokeview/${compiler}_${platform}${size} || return 1
     ./make_smv_db.sh &> $OUTPUT_DIR/stage3b
   else
     echo "   smokeview"
     echo "      debug - not built, using installed smokeview"
   fi
   return 0
}

#---------------------------------------------
#                   check_compile_smv_db
#---------------------------------------------

check_compile_smv_db()
{
   # Check for errors in SMV DB compilation
   if [ "$USEINSTALL" == "" ]; then
     CD_REPO $smvrepo/Build/smokeview/${compiler}_${platform}${size} $smvbranch || return 1
     if [ -e "smokeview_${platform}${size}_db" ]
     then
        stage3b_success=true
     else
        echo "Errors from Stage 2d - Compile SMV DB:" >> $ERROR_LOG
        cat $OUTPUT_DIR/stage3b >> $ERROR_LOG
        echo "" >> $ERROR_LOG
     fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
     if [[ `grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage3b | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]
     then
        # Continue along
        :
     else
        echo "Stage 2d warnings:" >> $WARNING_LOG
        grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage3b | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
        echo "" >> $WARNING_LOG
     fi
   fi
   return 0
}

#---------------------------------------------
#                   compile_smv
#---------------------------------------------

compile_smv()
{
   # Clean and compile SMV
   if [ "$USEINSTALL" == "" ]; then
     echo "      release"
     CD_REPO $smvrepo/Build/smokeview/${compiler}_${platform}${size} $smvbranch || return 1
     ./make_smv.sh &> $OUTPUT_DIR/stage3c
   else
     echo "      release - not built, using installed smokeview"
   fi
   return 0
}

#---------------------------------------------
#                   check_compkile_smv
#---------------------------------------------

check_compile_smv()
{
   # Check for errors in SMV release compilation
   if [ "$USEINSTALL" == "" ]; then
     CD_REPO $smvrepo/Build/smokeview/${compiler}_${platform}${size} $smvbrach || return 1
     if [ -e "smokeview_${platform}${size}" ]
     then
        stage3c_success=true
     else
        echo smokeview not found
        echo "Errors from Stage 2e - Compile SMV release:" >> $ERROR_LOG
        cat $OUTPUT_DIR/stage3c >> $ERROR_LOG
        echo "" >> $ERROR_LOG
     fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
     if [[ `grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage3c | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]
     then
        # Continue along
        :
     else
        echo "Stage 2e warnings:" >> $WARNING_LOG
        grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage3c | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
        echo "" >> $WARNING_LOG
     fi
   else
     is_file_installed smokeview stage3c 
     if [ "$stage3c_success" == "0" ] ; then
        echo "smokeview not installed"
        echo "Errors from Stage 2e - smokeview not installed:" >> $ERROR_LOG
        cat $OUTPUT_DIR/stage1b >> $ERROR_LOG
        echo "" >> $ERROR_LOG
     fi
   fi
   return 0
}

#---------------------------------------------
#                   wait_vv_cases_debug_start
#---------------------------------------------

wait_vv_cases_debug_start()
{
   # Scans qstat and waits for V&V cases to start
   while [[ `qstat -a | grep $(whoami) | grep -v grep | grep $JOBPREFIX | grep Q` != '' ]]; do
      JOBS_REMAINING=`qstat -a | grep $(whoami) | grep -v grep | grep $JOBPREFIX | grep Q | wc -l`
      echo "Waiting for ${JOBS_REMAINING} V&V cases to start." >> $OUTPUT_DIR/stage4
      TIME_LIMIT_STAGE="4"
      check_time_limit
      sleep 30
   done
}

#---------------------------------------------
#                   wait_vv_cases_debug_end
#---------------------------------------------

wait_vv_cases_debug_end()
{
   # Scans qstat and waits for V&V cases to end
   if [[ "$QUEUE" == "none" ]]
   then
     while [[ `ps -u $USER -f | fgrep .in | fgrep cfast | grep -v grep` != '' ]]; do
        JOBS_REMAINING=`ps -u $USER -f | fgrep .in | fgrep cfast | grep -v grep | wc -l`
        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage4
        TIME_LIMIT_STAGE="4"
        check_time_limit
        sleep 30
     done
   else
     while [[ `qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX` != '' ]]; do
        JOBS_REMAINING=`qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX | wc -l`
        echo "Waiting for ${JOBS_REMAINING} ${1} cases to complete." >> $OUTPUT_DIR/stage4
        TIME_LIMIT_STAGE="4"
        check_time_limit
        sleep 30
     done
   fi
}

#---------------------------------------------
#                   run_vv_cases_debug
#---------------------------------------------

run_vv_cases_debug()
{
   CD_REPO $cfastrepo/Validation/scripts $cfastbranch || return 1

   #  =======================
   #  = Run all cfast cases =
   #  =======================

   # Submit CFAST V&V cases
   echo 'Running CFAST V&V cases'
   echo '   debug'
   echo 'Running CFAST V&V cases' >> $OUTPUT_DIR/stage4 2>&1
   ./Run_CFAST_Cases.sh -I $compiler -S $smvrepo $USEINSTALL2 -m 2 -d -j $JOBPREFIX -q $QUEUE >> $OUTPUT_DIR/stage4 2>&1
   if [ "$QUEUE" != "none" ]; then
     wait_vv_cases_debug_start
   fi

   # Wait for V&V cases to end
   wait_vv_cases_debug_end
   return 0
}

#---------------------------------------------
#                   check_vv_cases_debug
#---------------------------------------------

check_vv_cases_debug()
{
   # Scan and report any errors in CFAST Verification cases
   CD_REPO $cfastrepo/Verification $cfastbranch || return 1

   if [[ `grep 'Run aborted' -riI --include *.log --include *.err ${OUTPUT_DIR}/stage4` == "" ]] && \
      [[ `grep -F "***Error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -F "***Fatal error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -A 20 forrtl -riI --include *.log --include *.err *` == "" ]]
   then
      :
   else
      grep 'Run aborted' -riI --include *.log --include *.err $OUTPUT_DIR/stage4 >> $OUTPUT_DIR/stage4_errors
      grep -F "***Error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage4_errors
      grep -F "***Fatal error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage4_errors
      grep -A 20 forrtl -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage4_errors
      
      echo "Errors from Stage 4 - Run V&V cases (debug mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage4_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_CFAST_FAILED=1
   fi

   # Scan and report any errors in CFAST Validation cases
   CD_REPO $cfastrepo/Validation $cfastbranch || return 1

   if [[ `grep 'Run aborted' -riI --include *.log --include *.err ${OUTPUT_DIR}/stage4` == "" ]] && \
      [[ `grep -F "***Error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -F "***Fatal error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -A 20 forrtl -riI --include *.log --include *.err *` == "" ]]
   then
      :
   else
      grep 'Run aborted' -riI --include *.log --include *.err $OUTPUT_DIR/stage4 >> $OUTPUT_DIR/stage4_errors
      grep -F "***Error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage4_errors
      grep -F "***Fatal error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage4_errors
      grep -A 20 forrtl -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage4_errors
      
      echo "Errors from Stage 4 - Run V&V cases (debug mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage4_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_CFAST_FAILED=1
   fi

   #  =====================
   #  = Remove case files =
   #  =====================

   # Remove all unversioned case files from V&V directories (recursively)
   if [ "$CLEANREPO" == "1" ]; then
     CD_REPO $cfastrepo/Verification $cfastbranch || return 1
     git clean -dxf &> /dev/null

     CD_REPO $cfastrepo/Validation $cfastbranch || return 1
     git clean -dxf &> /dev/null
   fi
   return 0
}

#---------------------------------------------
#                   wait_vv_cases_release_start
#---------------------------------------------

wait_vv_cases_release_start()
{
   # Scans qstat and waits for V&V cases to start
   while [[ `qstat -a | grep $(whoami) | grep -v grep | grep $JOBPREFIX | grep Q` != '' ]]; do
      JOBS_REMAINING=`qstat -a | grep $(whoami) | grep -v grep | grep $JOBPREFIX | grep Q | wc -l`
      echo "Waiting for ${JOBS_REMAINING} V&V cases to start." >> $OUTPUT_DIR/stage5
      TIME_LIMIT_STAGE="5"
      check_time_limit
      sleep 30
   done
}

#---------------------------------------------
#                  wait_vv_cases_release_end
#---------------------------------------------

wait_vv_cases_release_end()
{
   # Scans qstat and waits for V&V cases to end
   if [[ "$QUEUE" == "none" ]]
   then
     while [[ `ps -u $USER -f | fgrep .in | fgrep cfast | grep -v grep` != '' ]]; do
        JOBS_REMAINING=`ps -u $USER -f | fgrep .in | fgrep cfast | grep -v grep | wc -l`
        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage5
        TIME_LIMIT_STAGE="5"
        check_time_limit
        sleep 30
     done
   else
     while [[ `qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX` != '' ]]; do
        JOBS_REMAINING=`qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX | wc -l`
        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage5
        TIME_LIMIT_STAGE="5"
        check_time_limit
        sleep 30
     done
   fi
}

#---------------------------------------------
#                   run_vv_cases_release
#---------------------------------------------

run_vv_cases_release()
{
   # Start running all CFAST V&V cases
   CD_REPO $cfastrepo/Validation/scripts $cfastbranch || return 1
   echo '   release'
   echo 'Running CFAST V&V cases' >> $OUTPUT_DIR/stage5 2>&1
   ./Run_CFAST_Cases.sh -I $compiler -S $smvrepo $USEINSTALL2 -j $JOBPREFIX -q $QUEUE >> $OUTPUT_DIR/stage5 2>&1
   if [ "$QUEUE" != "none" ]; then
     wait_vv_cases_release_start
   fi

   # Wait for all V&V cases to end
   wait_vv_cases_release_end
   return 0
}

#---------------------------------------------
#                   check_vv_cases_release
#---------------------------------------------

check_vv_cases_release()
{
   # Scan and report any errors in CFAST Verificaion cases
   CD_REPO $cfastrepo/Verification $cfastbranch || return 1

   if [[ `grep 'Run aborted' -riI --include *.log --include *.err ${OUTPUT_DIR}/stage5` == "" ]] && \
      [[ `grep -F "***Error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -F "***Fatal error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -A 20 forrtl -riI --include *.log --include *.err *` == "" ]]
   then
      :
   else
      grep 'Run aborted' -riI --include *.log --include *.err $OUTPUT_DIR/stage5 >> $OUTPUT_DIR/stage5_errors
      grep -F "***Error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage5_errors
      grep -F "***Fatal error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage5_errors
      grep -A 20 forrtl -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage5_errors
      
      echo "Errors from Stage 5 - Run V&V cases (release mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage5_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_CFAST_FAILED=1
   fi

   # Scan and report any errors in CFAST Validation cases
   cd $cfastrepo/Validation

   if [[ `grep 'Run aborted' -riI --include *.log --include *.err ${OUTPUT_DIR}/stage5` == "" ]] && \
      [[ `grep -F "***Error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -F "***Fatal error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -A 20 forrtl -riI --include *.log --include *.err *` == "" ]]
   then
      :
   else
      grep 'Run aborted' -riI --include *.log --include *.err $OUTPUT_DIR/stage5 >> $OUTPUT_DIR/stage5_errors
      grep -F "***Error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage5_errors
      grep -F "***Fatal error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage5_errors
      grep -A 20 forrtl -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage5_errors
      
      echo "Errors from Stage 5 - Run V&V cases (release mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage5_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_CFAST_FAILED=1
   fi
   return 0
}

#---------------------------------------------
#                   is_file_sintalled
#---------------------------------------------

is_file_installed()
{
  local program=$1
  local stage=$2
  
  prognotfound=`$program -help | tail -1 | grep "not found" | wc -l`
  if [ "$prognotfound" == "1" ] ; then
    ${stage}_success="0"
    echo "***error: the $program is not installed" >> $OUTPUT_DIR/$stage
  fi
}

#---------------------------------------------
#                   make_cfast_pictures
#---------------------------------------------

make_cfast_pictures()
{
   echo "Generating smokeview images"
   CD_REPO cd $cfastrepo/Validation/scripts $cfastbranch || return 1
   ./Make_CFAST_Pictures.sh -I $COMPILER $USEINSTALL 2>&1 | grep -v FreeFontPath &> $OUTPUT_DIR/stage6

   return 0
}

#---------------------------------------------
#                   check_cfast_pictures
#---------------------------------------------

check_cfast_pictures()
{
   # Scan and report any errors in make SMV pictures process
   cd $CFASTBOT_RUNDIR
   if [[ `grep -B 50 -A 50 "Segmentation" -I $OUTPUT_DIR/stage6` == "" && `grep -F "*** Error" -I $OUTPUT_DIR/stage6` == "" ]]
   then
      stage6_success=true
   else
      cp $OUTPUT_DIR/stage6  $OUTPUT_DIR/stage6_errors
      echo "Errors from Stage 6 - Make CFAST pictures (release mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage6 >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   run_matlab_license_test
#---------------------------------------------

run_matlab_license_test()
{
   echo "V&V"
   echo "   matlab license test"
   # Run simple test to see if Matlab license is available
   CD_REPO $cfastrepo/Utilities/Matlab $cfastbranch || return 1
   matlab -logfile licmat.log -nodesktop -noFigureWindows -r "try, disp('Running Matlab License Check'), catch, disp('License Error'), err = lasterror, err.message, err.stack, end, exit" &> $OUTPUT_DIR/stage7a_matlab_license

   return 0
}

#---------------------------------------------
#                   scan_matlab_license_test
#---------------------------------------------

scan_matlab_license_test()
{
   # Check for failed license
   if [[ `grep "License checkout failed" $OUTPUT_DIR/stage7a_matlab_license` == "" ]]
   then
      # Continue along
      :
   else
      TIME_LIMIT_STAGE="7"
      check_time_limit
      # Wait 5 minutes until retry
      sleep 300
      check_matlab_license_server || return 1
   fi
   return 0
}

#---------------------------------------------
#                   check_matlab_license_server
#---------------------------------------------

check_matlab_license_server()
{
   run_matlab_license_test || return 1
   scan_matlab_license_test || return 1
   return 0
}

#---------------------------------------------
#                   compile_vvcalc
#---------------------------------------------

compile_vvcalc()
{ 
   # Build release vvcalc
   echo "   build VandV_Calcs" 
   CD_REPO $cfastrepo/Build/VandV_Calcs/${compiler}_${platform}${size} $cfastbranch || return 1
   make -f ../makefile clean &> /dev/null
   ./make_vv.sh &> $OUTPUT_DIR/stage7c

   return 0
}

#---------------------------------------------
#                   check_compile_vvcalc
#---------------------------------------------

check_compile_vvcalc()
{
   CD_REPO $cfastrepo/Build/VandV_Calcs/${compiler}_${platform}${size} $cfastbranch || return 1
   if [[ -e "VandV_Calcs_${platform}${size}" ]]
   then
      stage7c_success=true
   else
      echo "Errors from Stage 7b - Compile VandV_Calcs:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage7c >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   if [[ `grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage7c` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 7b - Compile VV calcs:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage7c >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   return 0
}

#---------------------------------------------
#                   run_matlab_verification
#---------------------------------------------

run_matlab_verification()
{
   echo "   Verification"
   echo "      make plots"
   # Run Matlab plotting script
   CD_REPO $cfastrepo/Utilities/Matlab $cfastbranch || return 1

   matlab -logfile vermat.log -nodesktop -noFigureWindows -r "try, disp('Running Matlab Verification script'), CFAST_verification_script, catch, disp('Error'), err = lasterror, err.message, err.stack, end, exit" &> $OUTPUT_DIR/stage7b_verification
   return 0
}

#---------------------------------------------
#                   check_matlab_verification
#---------------------------------------------

check_matlab_verification()
{
   # Scan and report any errors in Matlab scripts
   cd $CFASTBOT_RUNDIR

   if [[ `grep -A 50 "Error" $OUTPUT_DIR/stage7b_verification` == "" ]]
   then
      stage7b_success=true
   else
      grep -A 50 "Error" $OUTPUT_DIR/stage7b_verification >> $OUTPUT_DIR/stage7b_warnings

      echo "Warnings from Stage 7c - Matlab plotting (verification):" >> $WARNING_LOG
      cat $OUTPUT_DIR/stage7b_warnings >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   run_matlab_validation
#---------------------------------------------

run_matlab_validation()
{
   
   echo "   Validation"
   echo "      run VandV_Calcs"
   CD_REPO $cfastrepo/Validation $cfastbranch || return 1
   ../Build/VandV_Calcs/${compiler}_${platform}${size}/VandV_Calcs_${platform}${size} CFAST_Pressure_Correction_inputs.csv &> /dev/null
   cp pressures.csv LLNL_Enclosure/LLNL_pressures.csv
   ../Build/VandV_Calcs/${compiler}_${platform}${size}/VandV_Calcs_${platform}${size} CFAST_Temperature_Profile_inputs.csv &> /dev/null
   cp profiles.csv Steckler_Compartment/.
   ../Build/VandV_Calcs/${compiler}_${platform}${size}/VandV_Calcs_${platform}${size} CFAST_Heat_Flux_Profile_inputs.csv &> /dev/null
   cp flux_profiles.csv Fleury_Heat_Flux/.
   
   echo "      make plots"
   # Run Matlab plotting script
   cd $cfastrepo/Utilities/Matlab
   matlab -logfile valmat.log -nodesktop -noFigureWindows -r "try, disp('Running Matlab Validation script'), CFAST_validation_script, catch, disp('Error'), err = lasterror, err.message, err.stack, end, exit" &> $OUTPUT_DIR/stage7d_validation
   return 0
}

#---------------------------------------------
#                   check_matlab_validation
#---------------------------------------------

check_matlab_validation()
{
   # Scan and report any errors in Matlab scripts
   cd $CFASTBOT_RUNDIR
   if [[ `grep -A 50 "Error" $OUTPUT_DIR/stage7d_validation` == "" ]]
   then
      stage7d_success=true
   else
      grep -A 50 "Error" $OUTPUT_DIR/stage7d_validation >> $OUTPUT_DIR/stage7d_warnings

      echo "Warnings from Stage 7d - Matlab plotting and statistics (validation):" >> $WARNING_LOG
      cat $OUTPUT_DIR/stage7d_warnings >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   check_validation_stats
#---------------------------------------------

check_validation_stats()
{
   CD_REPO $cfastrepo/Utilities/Matlab $cfastbranch || return 1

   STATS_FILE_BASENAME=CFAST_validation_scatterplot_output

   BASELINE_STATS_FILE=$cfastrepo/Utilities/Matlab/${STATS_FILE_BASENAME}_baseline.csv
   CURRENT_STATS_FILE=$cfastrepo/Utilities/Matlab/${STATS_FILE_BASENAME}.csv

   if [ -e ${CURRENT_STATS_FILE} ]
   then
      if [[ `diff -u <(sed 's/"//g' ${BASELINE_STATS_FILE}) <(sed 's/"//g' ${CURRENT_STATS_FILE})` == "" ]]
      then
         # Continue along
         :
      else
         echo "Warnings from Stage 7b - Matlab plotting and statistics (validation):" >> $VALIDATION_STATS_LOG
         echo "-------------------------------" >> $VALIDATION_STATS_LOG
         echo "Validation statistics are different from baseline statistics." >> $VALIDATION_STATS_LOG
         echo "Baseline validation statistics vs. Revision ${GIT_REVISION}:" >> $VALIDATION_STATS_LOG
         echo "-------------------------------" >> $VALIDATION_STATS_LOG
         head -n 1 ${BASELINE_STATS_FILE} >> $VALIDATION_STATS_LOG
         echo "" >> $VALIDATION_STATS_LOG
         diff -u <(sed 's/"//g' ${BASELINE_STATS_FILE}) <(sed 's/"//g' ${CURRENT_STATS_FILE}) >> $VALIDATION_STATS_LOG
         echo "" >> $VALIDATION_STATS_LOG
      fi
   else
      echo "Warnings from Stage 6c - Matlab plotting and statistics (validation):" >> $WARNING_LOG
      echo "Error: The validation statistics output file does not exist." >> $WARNING_LOG
      echo "Expected the file Utilities/Matlab/CFAST_validation_scatterplot_output.csv" >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   return 0
}

#---------------------------------------------
#                   archive_validation_stats
#---------------------------------------------

archive_validation_stats()
{
   CD_REPO $cfastrepo/Utilities/Matlab $cfastbranch || return 1

   if [ -e ${CURRENT_STATS_FILE} ] ; then
      # Copy to CFASTbot history
      cp ${CURRENT_STATS_FILE} "$HISTORY_DIR/${STATS_FILE_BASENAME}_${GIT_REVISION}.csv"

      # Copy to web results
      if [ "$UPLOAD" == "1" ]; then
        cp ${CURRENT_STATS_FILE} /var/www/html/cfastbot/manuals/Validation_Statistics/${STATS_FILE_BASENAME}_${GIT_REVISION}.csv
        chmod +w /var/www/html/cfastbot/manuals/Validation_Statistics/${STATS_FILE_BASENAME}_${GIT_REVISION}.csv
      fi
   fi
   return 0
}

#---------------------------------------------
#                   check_guide
#---------------------------------------------

check_guide()
{
   local logfile=$1
   local docdir=$2
   local docfile=$3
   local docname=$4
   
   # Scan and report any errors or warnings in build process for guides
   cd $CFASTBOT_RUNDIR
   if [[ `grep -I "succeeded" $logfile` != "" ]] && [[ -e $docdir/$docfile ]]; then
      # Guide built succeeded; there were no errors/warnings
      # Copy guide to CFASTbot's local website
      if [ "$UPLOAD" == "1" ]; then
         cp $docdir/$docfile /var/www/html/cfastbot/manuals/CFAST_$docfile
         chmod +w /var/www/html/cfastbot/manuals/CFAST_$docfile
      fi
   else
      # There were errors/warnings in the guide build process
      echo "Warnings from Stage 7 - Build CFAST Guides:" >> $WARNING_LOG
      echo $docname >> $WARNING_LOG # Name of guide
      if [ ! -e $docdir/$docfile ]; then
         echo The guide $docname failed to be built >> $WARNING_LOG
         echo "" >> $WARNING_LOG
      fi 
      cat $logfile >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   make_cfast_tech_guide
#---------------------------------------------

make_cfast_tech_guide()
{
   # Build CFAST Tech Guide
   echo Building CFAST Tech guide
   CD_REPO $cfastrepo/Manuals/Tech_Ref $cfastbranch || return 1
   ./make_guide.sh &> $OUTPUT_DIR/stage8_cfast_tech_guide

   # Check guide for completion and copy to website if successful
   check_guide $OUTPUT_DIR/stage8_cfast_tech_guide $cfastrepo/Manuals/Tech_Ref Tech_Ref.pdf 'CFAST Technical Reference Guide'
   return 0
}

#---------------------------------------------
#                   make_cfast_user_guide
#---------------------------------------------

make_cfast_user_guide()
{
   # Build CFAST User Guide
   echo Building CFAST User guide
   CD_REPO $cfastrepo/Manuals/Users_Guide $cfastbranch || return 1
   ./make_guide.sh &> $OUTPUT_DIR/stage8_cfast_user_guide

   # Check guide for completion and copy to website if successful
   check_guide $OUTPUT_DIR/stage8_cfast_user_guide $cfastrepo/Manuals/Users_Guide Users_Guide.pdf 'CFAST Users Guide'
   return 0
}

#---------------------------------------------
#                   make_cfast_vv_guide
#---------------------------------------------

make_cfast_vv_guide()
{
   # Build CFAST Tech Guide
   echo Building CFAST VV guide
   CD_REPO $cfastrepo/Manuals/Validation_Guide $cfastbranch || return 1
   ./make_guide.sh &> $OUTPUT_DIR/stage8_cfast_vv_guide

   # Check guide for completion and copy to website if successful
   check_guide $OUTPUT_DIR/stage8_cfast_vv_guide $cfastrepo/Manuals/Validation_Guide Validation_Guide.pdf 'CFAST Verification and Validation Guide'
   return 0
}

#---------------------------------------------
#                   make_cfast_config_guide
#---------------------------------------------

make_cfast_config_guide()
{
   # Build CFAST Configuration Guide
   echo Building CFAST Configuration guide
   CD_REPO $cfastrepo/Manuals/Configuration_Guide $cfastbranch || return 1
   ./make_guide.sh &> $OUTPUT_DIR/stage8_cfast_config_guide

   # Check guide for completion and copy to website if successful
   check_guide $OUTPUT_DIR/stage8_cfast_config_guide $cfastrepo/Manuals/Configuration_Guide Configuration_Guide.pdf 'CFAST Configuration Guide'
   return 0
}

#---------------------------------------------
#                   save_build_status
#---------------------------------------------

save_build_status()
{
   cd $CFASTBOT_RUNDIR
   # Save status outcome of build to a text file
   if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]
   then
     cat "" >> $ERROR_LOG
     cat $WARNING_LOG >> $ERROR_LOG
     echo "Build failure and warnings for Revision ${GIT_REVISION}." > "$HISTORY_DIR/${GIT_REVISION}.txt"
     cat $ERROR_LOG > "$HISTORY_DIR/${GIT_REVISION}_errors.txt"
     touch $OUTPUT_DIR/status_errors_and_warnings

   # Check for errors only
   elif [ -e $ERROR_LOG ]
   then
      echo "Build failure for Revision ${GIT_REVISION}." > "$HISTORY_DIR/${GIT_REVISION}.txt"
      cat $ERROR_LOG > "$HISTORY_DIR/${GIT_REVISION}_errors.txt"
      touch $OUTPUT_DIR/status_errors

   # Check for warnings only
   elif [ -e $WARNING_LOG ]
   then
      echo "Revision ${GIT_REVISION} has warnings." > "$HISTORY_DIR/${GIT_REVISION}.txt"
      cat $WARNING_LOG > "$HISTORY_DIR/${GIT_REVISION}_warnings.txt"
      touch $OUTPUT_DIR/status_warnings

   # No errors or warnings
   else
      echo "Build success! Revision ${GIT_REVISION} passed all build tests." > "$HISTORY_DIR/${GIT_REVISION}.txt"
      touch $OUTPUT_DIR/status_success
   fi
}

#---------------------------------------------
#                   email_build_status
#---------------------------------------------

email_build_status()
{
   echo $THIS_CFAST_FAILED>$CFAST_STATUS_FILE
   stop_time=`date`
   if [[ $SKIP_git_UPDATE_AND_PROPFIX ]] ; then
      echo "CFASTbot was invoked with the -s option (SKIP_git_UPDATE_AND_PROPFIX)." >> $TIME_LOG
      echo "Skipping git revert, update, and property fix operations." >> $TIME_LOG
      echo "The current git revision is ${GIT_REVISION}" >> $TIME_LOG
   fi
   echo "-------------------------------" >> $TIME_LOG
   echo "Host: $hostname " >> $TIME_LOG
   echo "Start Time: $start_time " >> $TIME_LOG
   echo "Stop Time: $stop_time " >> $TIME_LOG
   if [[ "$UPLOAD" == "1" ]]; then
      echo "-------------------------------" >> $TIME_LOG
      echo "Manuals (private): http://blaze.nist.gov/cfastbot/manuals" >> $TIME_LOG
      echo "Manuals  (public): https://goo.gl/jR6uSj" >> $TIME_LOG
      echo "-------------------------------" >> $TIME_LOG
   fi
   if [[ $THIS_REVISION != $LAST_CFASTSOUCEgit ]] ; then
     cat $git_CFASTSOURCELOG >> $TIME_LOG
   fi
   cd $CFASTBOT_RUNDIR
   # Check for warnings and errors
   if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]
   then
     cat $TIME_LOG >> $ERROR_LOG
     cat $TIME_LOG >> $WARNING_LOG
     # Send email with failure message and warnings, body of email contains appropriate log file
     mail -s "CFASTbot build failure and warnings on ${hostname}. Revision ${GIT_REVISION}." $mailTo < $ERROR_LOG &> /dev/null

   # Check for errors only
   elif [ -e $ERROR_LOG ]
   then
     cat $TIME_LOG >> $ERROR_LOG
      # Send email with failure message, body of email contains error log file
      mail -s "CFASTbot build failure on ${hostname}. Revision ${GIT_REVISION}." $mailTo < $ERROR_LOG &> /dev/null

   # Check for warnings only
   elif [ -e $WARNING_LOG ]
   then
     cat $TIME_LOG >> $WARNING_LOG
      # Send email with success message, include warnings
      mail -s "CFASTbot build success with warnings on ${hostname}. Revision ${GIT_REVISION}." $mailTo < $WARNING_LOG &> /dev/null

   # No errors or warnings
   else
      # Send empty email with success message
      mail -s "CFASTbot build success on ${hostname}! Revision ${GIT_REVISION}." $mailTo < $TIME_LOG &> /dev/null
   fi

   # Send email notification if validation statistics have changed.
   if [ -e $VALIDATION_STATS_LOG ]
   then
      mail -s "CFASTbot notice. Validation statistics have changed for Revision ${GIT_REVISION}." $mailTo < $VALIDATION_STATS_LOG &> /dev/null      
   fi
   if [[ "$UPLOADGUIDES" == "1" ]]; then
     if [ -e $UploadGuides ]; then
        $UploadGuides $NEWGUIDE_DIR $cfastrepo/Manuals > /dev/null
     fi
   fi
}

size=_64


#  ===================
#  = Input variables =
#  ===================

mailTo="gforney@gmail.com, rpeacoc@nist.gov"

CFASTBOT_RUNDIR="`pwd`"

PID_FILE=~/.cfastgit/cfastbot_pid
OUTPUT_DIR=$CFASTBOT_RUNDIR/output
HISTORY_DIR=$CFASTBOT_RUNDIR/history
ERROR_LOG=$OUTPUT_DIR/errors
TIME_LOG=$OUTPUT_DIR/timings
WARNING_LOG=$OUTPUT_DIR/warnings
NEWGUIDE_DIR=$OUTPUT_DIR/NEW_GUIDES
VALIDATION_STATS_LOG=$OUTPUT_DIR/statistics
GITSTATUS_DIR=~/.cfastbot
BRANCH=master

echo ""
echo "Settings"
echo "--------"
echo "    Run dir: $CFASTBOT_RUNDIR"
MKDIR $OUTPUT_DIR
MKDIR $HISTORY_DIR
MKDIR $GITSTATUS_DIR

# define repo names (default)

cd ../..
reponame=`pwd`
cfastrepo=$repoanme/cfast
smvrepo=$reponame/smv
cd $CFAST_RUNDIR

COMPILER=intel
QUEUE=smokebot
RUNAUTO=
UPDATEREPO=
CLEANREPO=0
SKIP=
MATLABEXE=
UPLOAD=
USEINSTALL=
USEINSTALL2=
CCnotfound=

if [[ "$IFORT_COMPILER" != "" ]] ; then
  source $IFORT_COMPILER/bin/compilervars.sh intel64
fi

while getopts 'achiI:m:Mp:q:r:suU' OPTION
do
case $OPTION in
   a)
     RUNAUTO="y"
     ;;
  c)
   CLEANREPO=1
   ;;
  h)
   usage;
   ;;
  i)
   USEINSTALL="-i"
   USEINSTALL2="-u"
   ;;
  I)
   compiler="$OPTARG"
   ;;
  m)
   mailTo="$OPTARG"
   ;;
  M)
   MATLABEXE=1
   ;;
  p)
   PID_FILE="$OPTARG"
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  r)
   reponame="$OPTARG"
   cfastrepo=$reponame/cfast
   smvrepo=$reponame/smv
   ;;
  s)
   SKIP=1
   ;;
  u)
   UPDATEREPO=1
   ;;
  U)
   UPLOAD=1
   ;;
esac
done
shift $(($OPTIND-1))

echo $$ > $PID_FILE

if [ "$USEINSTALL" == "" ]; then
  CCnotfound=`icc -help 2>&1 | tail -1 | grep "not found" | wc -l`
fi

if [[ $CCnotfound -eq 0 ]] && [[ "$USEINSTALL" == "" ]]; then
  USEINSTALL=
  USEINSTALL2=
else
  USEINSTALL="-i"
  USEINSTALL2="-u"
fi

if [ -e $cfastrepo ]; then
echo " cfast repo: $cfastrepo"
else
echo " cfast repo: $cfastrepo ***error does not exist"
fi
if [ -e $smvrepo ]; then
echo "   SMV repo: $smvrepo"
else
echo "   SMV repo: $smvrepo ***error does not exist"
fi

platform="linux"
platform2="Linux"
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  platform2="OSX"
fi
export platform

echo "   platform: $platform2"
echo "   compiler: $compiler"

# Set unlimited stack size
if [ "$platform" == "linux" ] ; then
  ulimit -s unlimited
fi

if [ "$SKIP" == "1" ]; then
   MATLABEXE=
   echo "     matlab: skipping matlab and document building stages"
else
   if [ "$MATLABEXE" != "" ]; then
     echo "     matlab: using matlab script generated exe's"
   else
     echo "     matlab: using matlab"
   fi
fi

if [ "$UPLOAD" == "1" ]; then
  MKDIR $NEWGUIDE_DIR
fi

cd

THIS_CFAST_FAILED=0
CFAST_STATUS_FILE=$GITSTATUS_DIR/cfast_status
LAST_CFAST_FAILED=0
if [ -e $CFAST_STATUS_FILE ] ; then
   LAST_CFAST_FAILED=`cat $CFAST_STATUS_FILE`
fi

export JOBPREFIX=CB_
UploadGuides=$cfastrepo/Utilities/cfastbot/upload_guides.sh

#  ==============================================
#  = CFASTbot timing and notification mechanism =
#  ==============================================

# This routine checks the elapsed time of CFASTbot.
# If CFASTbot runs more than 3 hours, an email notification is sent.
# This is a notification only and does not terminate CFASTbot.
# This check runs during Stages 3 and 5.

# Start CFASTbot timer
START_TIME=$(date +%s)

# Set time limit
TIME_LIMIT=10800
TIME_LIMIT_EMAIL_NOTIFICATION="unsent"


# if -a option is invoked, only proceed running CFASTbot if the smokeview or CFAST source has changed

if [[ "$RUNAUTO" == "y" ]] ; then
  run_auto
fi

#  ============================
#  = Primary script execution =
#  ============================

hostname=`hostname`
start_time=`date`

echo ""
echo "cfastbot progress"
echo "-----------------"
### Clean up on start ###
clean_cfastbot_history

### Stage 1 ###
if [ "$CLEANREPO" == "1" ]; then
  clean_repo2 cfast $cfastbranch || exit 1
  clean_repo2 smv $smvbranch || exit 1
else
  echo Repos not cleaned
fi

if [ "$UPDATEREPO" == "1" ]; then
  echo Updating
  update_repo cfast $cfastbranch || exit 1
  update_repo smv $smvbranch || exit 1
else
  echo Repos not updated
fi
check_git_checkout

### Stage 2a ###
compile_cfast_db || exit 1
check_compile_cfast_db || exit 1

### Stage 2b ###
compile_cfast || exit 1
check_compile_cfast || exit 1

### Stage 2c ###
compile_smv_utilities || exit 1
check_smv_utilities || exit 1

### Stage 2d ###
compile_smv_db || exit 1
check_compile_smv_db || exit 1

### Stage 2e ###
compile_smv || exit 1
check_compile_smv || exit 1

### Stage 3 ###
if [[ $stage2a_success ]] ; then
   run_vv_cases_debug || exit 1
   check_vv_cases_debug || exit 1
fi

### Stage 4 ###
if [[ $stage2b_success ]] ; then
   run_vv_cases_release || exit 1
   check_vv_cases_release || exit 1
fi

### Stage 5 ###
if [[ $stage2b_success && $stage3c_success ]] ; then
   make_cfast_pictures || exit 1
   check_cfast_pictures
fi

### Stage 6a ###
if [[ "$SKIP" == "" ]]; then
  if [ "$MATLABEXE" == "" ]; then
    check_matlab_license_server || exit 1
    run_matlab_verification || exit 1
    check_matlab_verification
  fi
fi

### Stage 6b ###
if [[ "$SKIP" == "" ]]; then
  if [ "$MATLABEXE" == "" ]; then
    compile_vvcalc || exit 1
    check_compile_vvcalc || exit 1
  fi
fi

### Stage 6c ###
if [[ "$SKIP" == "" ]]; then
  if [ "$MATLABEXE" == "" ]; then
    run_matlab_validation || exit 1
    check_matlab_validation
    check_validation_stats || exit 1
    archive_validation_stats || exit 1
  fi
fi

### Stage 7 ###
if [[ "$SKIP" == "" ]]; then
  make_cfast_tech_guide || exit 1
  make_cfast_user_guide || exit 1
  make_cfast_vv_guide || exit 1
  make_cfast_config_guide || exit 1
fi

### Report results ###
set_files_world_readable || exit 1
save_build_status
email_build_status
echo cfastbot complete
