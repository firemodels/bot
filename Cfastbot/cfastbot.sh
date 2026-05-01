#!/bin/bash
cur_dir=`pwd`
# CFASTbot
# This script runs the CFAST verification/validation suite 

#---------------------------------------------
#                   VERIFY_REPO_BRANCH
#---------------------------------------------

VERIFY_REPO_BRANCH ()
{
  local repodir=$1
  local branch=$2
  
  if [ ! -e $repodir ]; then
     echo "***error: the repo directory $repodir does not exist."
     echo "          Aborting cfastbot."
     return 1
  fi

  cd $repodir
  if [[ "$branch" != "current" ]] && [[ "$branch" != "" ]]; then
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
   
   TRIGGER=$cfastrepo/Source/CFAST
   git_TRIGGER=$GITSTATUS_DIR/cfast_source_revision
   TRIGGERONLY=$cfastrepo/Source/CFAST/skiplab_trigger.txt
   git_TRIGGERONLY=$GITSTATUS_DIR/cfastonly_source_revision

   if [ "$CFASTBRANCH" != "current" ]; then
     cd $CFAST_SOURCE
     git fetch origin &> /dev/null
     git merge origin/$CFASTBRANCH &> /dev/null
     have_remote=`git remote -v | awk '{print $1}' | grep firemodels | wc  -l`
     if [ "$have_remote" != "0" ]; then
        git fetch firemodels &> /dev/null
        git merge firemodels/$CFASTBRANCH &> /dev/null
     fi
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

   rm -f $MESSAGE_FILE

   echo -e "CFAST source directory has changed. $LAST_REVISION->$THIS_CFASTSOURCE($THIS_AUTHOR)" >> $MESSAGE_FILE
   cat $git_CFASTSOURCELOG >> $MESSAGE_FILE

   echo -e "CFASTbot run initiated." >> $MESSAGE_FILE
   cat $MESSAGE_FILE | mail $REPLYTO -s "CFASTbot run initiated" $mailTo &> /dev/null
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
         echo -e "CFASTbot has been running for more than 3 hours in Stage ${TIME_LIMIT_STAGE}. \n\nPlease ensure that there are no problems. \n\nThis is a notification only and does not terminate CFASTbot." | mail $REPLYTO -s "CFASTbot Notice: CFASTbot has been running for more than 3 hours." $mailTo &> /dev/null
         TIME_LIMIT_EMAIL_NOTIFICATION="sent"
      fi
   fi
}

#---------------------------------------------
#                   set_files_world_readable
#---------------------------------------------

set_files_world_readable()
{
   cd $cfastrepo
   chmod -R go+r *
   
   cd $smvrepo
   chmod -R go+r *

   cd $exprepo
   chmod -R go+r *

   return 0
}

#---------------------------------------------
#                   check_compile_cfast_db
#---------------------------------------------

check_compile_cfast_db()
{
   # Check for errors in CFAST debug compilation
   cd $cfastrepo/Build/CFAST/intel_${platform}_db
   if [ -e "cfast7_${platform}_db" ]
   then
      stage2_build_cfast_debug_success=true
   else
      echo "Errors from Stage 2 - Compile CFAST debug:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2_build_cfast_debug >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   if [[ `grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2_build_cfast_debug` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 2 - Compile CFAST debug:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2_build_cfast_debug >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   check_compile_cfast
#---------------------------------------------

check_compile_cfast()
{
   # Check for errors in CFAST release compilation
   cd $cfastrepo/Build/CFAST/intel_${platform}
   if [[ -e "cfast7_${platform}" ]]
   then
      stage2_build_cfast_release_success=true
   else
      echo "Errors from Stage 2 - Compile CFAST release:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2_build_cfast_release >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   if [[ `grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2_build_cfast_release` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 2 - Compile CFAST release:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2_build_cfast_release >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   return 0
}

#---------------------------------------------
#                   check_compile_smv_db
#---------------------------------------------

check_compile_smv_db()
{
   # Check for errors in SMV DB compilation
   cd $smvrepo/Build/smokeview/intel_${platform}
   if [ -e "smokeview_${platform}_db" ]
   then
      stage2_build_smv_debug_success=true
   else
      echo "Errors from Stage 2 - Compile SMV DB:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2_build_smv_debug >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
   if [[ `grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2_build_smv_debug | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Stage build_smv_debug warnings:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2_build_smv_debug | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
   fi
   return 0
}

#---------------------------------------------
#                   check_compile_smv
#---------------------------------------------

check_compile_smv()
{
   # Check for errors in SMV release compilation
   cd $smvrepo/Build/smokeview/intel_${platform}
   if [ -e "smokeview_${platform}" ]
   then
      stage2_build_smv_release_success=true
   else
      echo smokeview not found
      echo "Errors from Stage 2 - Compile SMV release:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2_build_smv_release >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
   if [[ `grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2_build_smv_release | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Stage build_smv_release warnings:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' ${OUTPUT_DIR}/stage2_build_smv_release | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   return 0
}

#---------------------------------------------
#                   wait_vv_cases_debug_start
#---------------------------------------------

wait_vv_cases_debug_start()
{
   # Scans job queue and waits for V&V cases to start
   while [[          `squeue -o "%.18j %.8u %.2t" | awk '{print $1 $2 $3}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$'` != '' ]]; do
      JOBS_REMAINING=`squeue -o "%.18j %.8u %.2t" | awk '{print $1 $2 $3}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$' | wc -l`
      echo "Waiting for ${JOBS_REMAINING} V&V cases to start." >> $OUTPUT_DIR/stage3_run_debug
      TIME_LIMIT_STAGE="3 run debug cases"
      check_time_limit
      sleep 30
   done
}

#---------------------------------------------
#                   wait_vv_cases_debug_end
#---------------------------------------------

wait_vv_cases_debug_end()
{
  # Scans job queue and waits for V&V cases to end
  while [[          `squeue -o "%.18j %.8u %.2t" | awk '{print $1 $2 $3}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$'` != '' ]]; do
     JOBS_REMAINING=`squeue -o "%.18j %.8u %.2t" | awk '{print $1 $2 $3}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$' | wc -l`
     echo "Waiting for ${JOBS_REMAINING} ${1} cases to complete." >> $OUTPUT_DIR/stage3_run_debug
     TIME_LIMIT_STAGE="3 run debug cases"
     check_time_limit
     sleep 30
  done
}

#---------------------------------------------
#                   run_vv_cases_debug
#---------------------------------------------

run_vv_cases_debug()
{
   cd $cfastrepo/Validation/scripts

   #  =======================
   #  = Run all cfast cases =
   #  =======================

   # Submit CFAST V&V cases
   echo 'Running CFAST V&V cases'
   echo '   debug'
   echo 'Running CFAST V&V cases' >> $OUTPUT_DIR/stage3_run_debug 2>&1
   ./Run_CFAST_Cases.sh -I intel -S $smvrepo -m 2 -d -j $JOBPREFIX -q $QUEUE >> $OUTPUT_DIR/stage3_run_debug 2>&1
   wait_vv_cases_debug_start

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
   cd $cfastrepo/Verification

   if [[ `grep 'Run aborted' -riI --include *.log --include *.err ${OUTPUT_DIR}/stage3_run_debug` == "" ]] && \
      [[ `grep -F "***Error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -F "***Fatal error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -A 20 forrtl -riI --include *.log --include *.err *` == "" ]]
   then
      :
   else
      grep 'Run aborted' -riI --include *.log --include *.err $OUTPUT_DIR/stage3_run_debug >> $OUTPUT_DIR/stage3_run_debug_errors
      grep -F "***Error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_debug_errors
      grep -F "***Fatal error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_debug_errors
      grep -A 20 forrtl -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_debug_errors
      
      echo "Errors from Stage 3 - Run V&V cases (debug mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3_run_debug_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_CFAST_FAILED=1
   fi

   # Scan and report any errors in CFAST Validation cases
   cd $cfastrepo/Validation

   if [[ `grep 'Run aborted' -riI --include *.log --include *.err ${OUTPUT_DIR}/stage3_run_debug` == "" ]] && \
      [[ `grep -F "***Error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -F "***Fatal error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -A 20 forrtl -riI --include *.log --include *.err *` == "" ]]
   then
      :
   else
      grep 'Run aborted' -riI --include *.log --include *.err $OUTPUT_DIR/stage3_run_debug >> $OUTPUT_DIR/stage3_run_debug_errors
      grep -F "***Error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_debug_errors
      grep -F "***Fatal error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_debug_errors
      grep -A 20 forrtl -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_debug_errors
      
      echo "Errors from Stage 3 - Run V&V cases (debug mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3_run_debug_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_CFAST_FAILED=1
   fi

   #  =====================
   #  = Remove case files =
   #  =====================

   cd $cfastrepo/Verification
   git clean -dxf &> /dev/null

   cd $cfastrepo/Validation
   git clean -dxf &> /dev/null
   return 0
}

#---------------------------------------------
#                   wait_vv_cases_release_start
#---------------------------------------------

wait_vv_cases_release_start()
{
   # Scans job queue and waits for V&V cases to start
   while [[          `squeue -o "%.18j %.8u %.2t" | awk '{print $1 $2 $3}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$'` != '' ]]; do
      JOBS_REMAINING=`squeue -o "%.18j %.8u %.2t" | awk '{print $1 $2 $3}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$' | wc -l`
      echo "Waiting for ${JOBS_REMAINING} V&V cases to start." >> $OUTPUT_DIR/stage3_run_release
      TIME_LIMIT_STAGE="3 run release cases"
      check_time_limit
      sleep 30
   done
}

#---------------------------------------------
#                  wait_vv_cases_release_end
#---------------------------------------------

wait_vv_cases_release_end()
{
  # Scans job queue and waits for V&V cases to end
  while [[          `squeue -o "%.18j %.8u %.2t" | awk '{print $1 $2 $3}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$'` != '' ]]; do
     JOBS_REMAINING=`squeue -o "%.18j %.8u %.2t" | awk '{print $1 $2 $3}' | grep $(whoami) | grep $JOBPREFIX | grep -v 'C$' | wc -l`
     echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage3_run_release
     TIME_LIMIT_STAGE="3 run release cases"
     check_time_limit
     sleep 30
  done
}

#---------------------------------------------
#                   run_vv_cases_release
#---------------------------------------------

run_vv_cases_release()
{
   # Start running all CFAST V&V cases
   cd $cfastrepo/Validation/scripts
   echo '   release'
   echo 'Running CFAST V&V cases' >> $OUTPUT_DIR/stage3_run_release 2>&1
   ./Run_CFAST_Cases.sh -I intel -S $smvrepo -j $JOBPREFIX -q $QUEUE >> $OUTPUT_DIR/stage3_run_release 2>&1
   wait_vv_cases_release_start

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
   cd $cfastrepo/Verification

   if [[ `grep 'Run aborted' -riI --include *.log --include *.err ${OUTPUT_DIR}/stage3_run_release` == "" ]] && \
      [[ `grep -F "***Error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -F "***Fatal error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -A 20 forrtl -riI --include *.log --include *.err *` == "" ]]
   then
      :
   else
      grep 'Run aborted' -riI --include *.log --include *.err $OUTPUT_DIR/stage3_run_release >> $OUTPUT_DIR/stage3_run_release_errors
      grep -F "***Error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_release_errors
      grep -F "***Fatal error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_release_errors
      grep -A 20 forrtl -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_release_errors
      
      echo "Errors from Stage 3 - Run V&V cases (release mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3_run_release_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_CFAST_FAILED=1
   fi

   # Scan and report any errors in CFAST Validation cases
   cd $cfastrepo/Validation

   if [[ `grep 'Run aborted' -riI --include *.log --include *.err ${OUTPUT_DIR}/stage3_run_release` == "" ]] && \
      [[ `grep -F "***Error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -F "***Fatal error" -riI --include *.log --include *.err *` == "" ]] && \
      [[ `grep -A 20 forrtl -riI --include *.log --include *.err *` == "" ]]
   then
      :
   else
      grep 'Run aborted' -riI --include *.log --include *.err $OUTPUT_DIR/stage3_run_release >> $OUTPUT_DIR/stage3_run_release_errors
      grep -F "***Error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_release_errors
      grep -F "***Fatal error" -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_release_errors
      grep -A 20 forrtl -riI --include *.log --include *.err * >> $OUTPUT_DIR/stage3_run_release_errors
      
      echo "Errors from Stage 3 - Run V&V cases (release mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3_run_release_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      THIS_CFAST_FAILED=1
   fi
   return 0
}

#---------------------------------------------
#                   check_cfast_pictures
#---------------------------------------------

check_cfast_pictures()
{
   # Scan and report any errors in make SMV pictures process
   cd $cfastbotdir
   if [[ `grep -B 10 -A 10 "Segmentation" -I $OUTPUT_DIR/stage4_make_pictures` == "" && `grep -F "*** Error" -I $OUTPUT_DIR/stage4_make_pictures` == "" ]]
   then
      stage4_make_pictures_success=true
   else
      cp $OUTPUT_DIR/stage4_make_pictures  $OUTPUT_DIR/stage4_make_pictures_errors
      echo "Errors from Stage 4 - Make CFAST pictures (release mode):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage4_make_pictures >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   check_python_verification
#---------------------------------------------

check_python_verification()
{
   # Scan and report any errors in Python scripts
   cd $cfastbotdir

   if [[ `grep -A 50 "Error" $OUTPUT_DIR/stage5_run_python_verification` == "" ]]
   then
      stage5_run_python_verification_success=true
   else
      grep -A 50 "Error" $OUTPUT_DIR/stage5_run_python_verification >> $OUTPUT_DIR/stage5_run_python_verification_errors

      echo "Warnings from Stage 5 - Python plotting (verification):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage5_run_python_verification_errors | tr -cd '\11\12\15\40-\176' >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   check_python_validation
#---------------------------------------------

check_python_validation()
{
   # Scan and report any errors in Python scripts
   cd $cfastbotdir
   if [[ `grep -A 50 "Error" $OUTPUT_DIR/stage5_run_python_validation` == "" ]]
   then
      stage5_run_python_validation_success=true
   else
      grep -A 50 "Error" $OUTPUT_DIR/stage5_run_python_validation >> $OUTPUT_DIR/stage5_run_python_validation_errors

      echo "Errors from Stage 5 - Python plotting and statistics (validation):" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage5_run_python_validation_errors |  tr -cd '\11\12\15\40-\176' >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   check_validation_stats
#---------------------------------------------

check_validation_stats()
{
   cd $cfastrepo/Utilities/Python

   STATS_FILE_BASENAME=validation_scatterplot_output

   BASELINE_STATS_FILE=$cfastrepo/Manuals/CFAST_Validation_Guide/SCRIPT_FIGURES/Scatterplots/${STATS_FILE_BASENAME}_baseline.csv
   CURRENT_STATS_FILE=$cfastrepo/Manuals/CFAST_Validation_Guide/SCRIPT_FIGURES/Scatterplots/${STATS_FILE_BASENAME}.csv

   if [ -e ${CURRENT_STATS_FILE} ]
   then
      if [[ `diff -u <(sed 's/"//g' ${BASELINE_STATS_FILE}) <(sed 's/"//g' ${CURRENT_STATS_FILE})` == "" ]]
      then
         # Continue along
         :
      else
         echo "Warnings from stage 5 - Python plotting and statistics (validation):" >> $VALIDATION_STATS_LOG
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
      echo "Warnings from stage 5 - Python plotting and statistics (validation):" >> $WARNING_LOG
      echo "Error: The validation statistics output file does not exist." >> $WARNING_LOG
      echo "Expected the file /Manuals/CFAST_Validation_Guide/SCRIPT_FIGURES/Scatterplots/validation_scatterplot_output.csv" >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   return 0
}

#---------------------------------------------
#                   archive_validation_stats
#---------------------------------------------

archive_validation_stats()
{
   cd $cfastrepo/Utilities/Python

   if [ -e ${CURRENT_STATS_FILE} ] ; then
      # Copy to CFASTbot history
      cp ${CURRENT_STATS_FILE} "$HISTORY_DIR/${STATS_FILE_BASENAME}_${GIT_REVISION}.csv"
   fi
   cd $cfastrepo/Validation/scripts
   if [ -e gettime.sh ]; then
     TIMEFILE=$HISTORY_DIR/${GIT_REVISION}_timing.csv
     ./Run_CFAST_Cases.sh -t | grep -v submitted > $TIMEFILE
     total_time=`cat $TIMEFILE | awk -F',' '{ SUM += $2} END { print SUM }'`
     echo $total_time >> $TIMEFILE
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
   cd $cfastbotdir
   if [[ `grep -I "succeeded" $logfile` != "" ]] && [[ -e $docdir/$docfile ]]; then
      # Guide built succeeded; there were no errors/warnings
      # Copy guide to CFASTbot's local website
      dummy=1
   else
      # There were errors/warnings in the guide build process
      echo "Warnings from Stage 6 - Build CFAST Guides:" >> $WARNING_LOG
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
#                   CHECKOUT_REPO
#---------------------------------------------

CHECKOUT_REPO()
{
 local_branch=$1
 local_repo=$2
 local_rev=$3
 local_tag=$4

 cd $local_repo
 TAGEXISTS=
 if git rev-parse $local_tag >/dev/null 2>&1; then
  TAGEXISTS=1
 fi

 echo "******************"                             >> $OUTPUT_DIR/stage1_setup_clone 2>&1
 echo repo: $local_repo                                >> $OUTPUT_DIR/stage1_setup_clone 2>&1
 echo git checkout -b $local_branch $local_rev         >> $OUTPUT_DIR/stage1_setup_clone 2>&1
 git checkout -b $local_branch $local_rev              >> $OUTPUT_DIR/stage1_setup_clone 2>&1

 if [ "$TAGEXISTS" == "" ]; then
   echo creating tag $local_tag for repo $local_repo   >> $OUTPUT_DIR/stage1_setup_clone 2>&1
   git tag -f -a $local_tag -m "tag for $local_tag"    >> $OUTPUT_DIR/stage1_setup_clone 2>&1
 else
   echo tag $local_tag already exists                  >> $OUTPUT_DIR/stage1_setup_clone 2>&1
 fi

 echo git checkout $local_tag                          >> $OUTPUT_DIR/stage1_setup_clone 2>&1
 git checkout $local_tag                               >  /dev/null                2>&1
}

#---------------------------------------------
#                   save_build_status
#---------------------------------------------

save_build_status()
{
   cd $cfastbotdir
   # Save status outcome of build to a text file
   if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]
   then
     echo "" >> $ERROR_LOG
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
   IFORT_VERSION=`ifx -v 2>&1`
   if [[ $SKIP_git_UPDATE_AND_PROPFIX ]] ; then
      echo "CFASTbot was invoked with the -s option (SKIP_git_UPDATE_AND_PROPFIX)." >> $TIME_LOG
      echo "Skipping git revert, update, and property fix operations." >> $TIME_LOG
      echo "The current git revision is ${GIT_REVISION}" >> $TIME_LOG
   fi
   echo ""                                     >> $TIME_LOG
   echo "Host: $hostname "                     >> $TIME_LOG
   echo "repo: $cfastrepo "                    >> $TIME_LOG
   echo "Fortran: $IFORT_VERSION "             >> $TIME_LOG
   echo ""                                     >> $TIME_LOG
   echo "$BOT_REVISION "                       >> $TIME_LOG
   echo "$CFAST_REVISION "                     >> $TIME_LOG
   echo "$EXP_REVISION "                       >> $TIME_LOG
   echo "$FDS_REVISION "                       >> $TIME_LOG
   echo "$SMV_REVISION "                       >> $TIME_LOG
   echo ""                                     >> $TIME_LOG
   echo "Start Time: $start_time "             >> $TIME_LOG
   echo "Stop Time: $stop_time "               >> $TIME_LOG
   if [ "$total_time" != "" ]; then
     echo "Run Time: $total_time"              >> $TIME_LOG
   fi
   if [[ $THIS_REVISION != $LAST_CFASTSOUCEgit ]] ; then
     cat $git_CFASTSOURCELOG >> $TIME_LOG
   fi
   cd $cfastbotdir
   # Check for warnings and errors
   if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]
   then
     cat $TIME_LOG >> $WARNING_LOG
     # Send email with failure message and warnings, body of email contains appropriate log file
     cat $ERROR_LOG $TIME_LOG | mail $REPLYTO -s "CFASTbot build failure and warnings on ${hostname}. Revision ${GIT_REVISION}." $mailTo &> /dev/null
     cat $TIME_LOG | mail $REPLYTO -s "CFASTbot build failure and warnings on ${hostname}. Revision ${GIT_REVISION}." $mailTo &> /dev/null

   # Check for errors only
   elif [ -e $ERROR_LOG ]
   then
      # Send email with failure message, body of email contains error log file
      cat $ERROR_LOG $TIME_LOG | mail $REPLYTO -s "CFASTbot build failure on ${hostname}. Revision ${GIT_REVISION}." $mailTo &> /dev/null
      cat $TIME_LOG | mail $REPLYTO -s "CFASTbot build failure on ${hostname}. Revision ${GIT_REVISION}." $mailTo &> /dev/null

   # Check for warnings only
   elif [ -e $WARNING_LOG ]
   then
      # Send email with success message, include warnings
      cat $WARNING_LOG $TIME_LOG | mail $REPLYTO -s "CFASTbot build success with warnings on ${hostname}. Revision ${GIT_REVISION}." $mailTo &> /dev/null
      cat $TIME_LOG | mail $REPLYTO -s "CFASTbot build success with warnings on ${hostname}. Revision ${GIT_REVISION}." $mailTo &> /dev/null

   # No errors or warnings
   else
      if [[ "$UPLOAD" == "1" ]] && [[ -e $GUIDES2GH ]]; then
         cd $cfastbotdir
         $GUIDES2GH $cfastrepo/Manuals >& $OUTPUT_DIR/stage7_upload
         GITURL=https://github.com/$GH_OWNER/$GH_REPO/releases/tag/$GH_CFAST_TAG
         echo ""                >> $TIME_LOG
         echo "Guides: $GITURL" >> $TIME_LOG
      fi
      # Send empty email with success message
      cat $TIME_LOG | mail $REPLYTO -s "CFASTbot build success on ${hostname}! Revision ${GIT_REVISION}." $mailTo &> /dev/null
   fi

   # Send email notification if validation statistics have changed.
   if [ -e $VALIDATION_STATS_LOG ]
   then
      mail $REPLYTO -s "CFASTbot notice. Validation statistics have changed for Revision ${GIT_REVISION}." $mailTo < $VALIDATION_STATS_LOG &> /dev/null      
   fi
}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             start of script
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


#  ===================
#  = Input variables =
#  ===================

cfastbotdir="`pwd`"

GITSTATUS_DIR=$HOME/.cfastbot
EMAIL_LIST=$HOME/.cfastbot/cfastbot_email_list.sh
PID_FILE=$GITSTATUS_DIR/cfastbot_pid
OUTPUT_DIR=$cfastbotdir/output
HISTORY_DIR=$GITSTATUS_DIR/history
ERROR_LOG=$OUTPUT_DIR/errors
TIME_LOG=$OUTPUT_DIR/timings
WARNING_LOG=$OUTPUT_DIR/warnings
NEWGUIDE_DIR=$OUTPUT_DIR/NEW_GUIDES
VALIDATION_STATS_LOG=$OUTPUT_DIR/statistics

echo ""
echo "Settings"
echo "--------"
echo "    Run dir: $cfastbotdir"
mkdir -p $OUTPUT_DIR
mkdir -p $GITSTATUS_DIR
mkdir -p $HISTORY_DIR
touch $OUTPUT_DIR/stage0_start

#*** make sure cfastbot is running in the correct directory

if [ -e .cfast_git ]; then
  cd ../..
  reporoot=`pwd`
  cd $cfastbotdir
else
  echo "***error: firebot not running in the bot/Firebot directory"
  echo "          Aborting firebot"
  exit
fi

botrepo=$reporoot/bot
cfastrepo=$reporoot/cfast
fdsrepo=$reproot/fds
smvrepo=$reporoot/smv
exprepo=$reporoot/exp

botbranch=master
expbranch=master

cd $cfastbotdir

QUEUE=
RUNAUTO=
UPLOAD=
GITURL=
BRANCH=
CONFIG=
CLONEREPOS=

while getopts 'aCF:hm:p:q:r:U' OPTION
do
case $OPTION in
  a)
    RUNAUTO="y"
    ;;
  C)
    CLONEREPOS=1
    ;;
  F)
   CONFIG="$OPTARG"
   ;;
  h)
   usage;
   ;;
  m)
   mailTo="$OPTARG"
   ;;
  p)
   PID_FILE="$OPTARG"
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  r)
   reporoot="$OPTARG"
   cfastrepo=$reporoot/cfast
   exprepo=$reporoot/exp
   fdsrepo=$reporoot/fds
   smvrepo=$reporoot/smv
   ;;
  U)
   UPLOAD=1
   ;;
esac
done
shift $(($OPTIND-1))

#*** building a bundle so update all repos using repo info in config.sh
if [ "$CONFIG" != "" ]; then
   cd $botrepo/Scripts
  ./update_repos.sh -m
fi

#*** cloning repos so only update bot repo
if [ "$CLONEREPOS" != "" ]; then
  cd $botrepo/Scripts
  ./update_repos.sh -b
fi


echo $$ > $PID_FILE

if [ -e $EMAIL_LIST ]; then
  source $EMAIL_LIST
fi

REPLYTO=
if [ "$replyToCFAST" != "" ]; then
  REPLYTO="-S replyto=\"$replyToCFAST\""
fi

if [ "$mailTo" == "" ]; then
  if [ "$mailToCFAST" != "" ]; then
    mailTo=$mailToCFAST
  fi
fi

if [ "$mailTo" == "" ]; then
  mailTo=`git config user.email`
fi

if [ "$mailTo" == "" ]; then
  mailTo=`whoami`@`hostname`
fi

# define repo names, make sure they exist


# 3 cases
# 1.  use current repo branches
# 2.  clone repos use master
# 3.  use branches defined config.sh ($CONFIG) - for bundling

botbranch=current
VERIFY_REPO_BRANCH $botrepo $botbranch || exit 1

if [ "$CONFIG" == "" ]; then
  if [ "$CLONEREPOS" == "" ]; then
    cd $reporoot/bot/Scripts
    CFASTBRANCH=current
    SMVBRANCH=current
    expbranch=current
    fdsbranch=current
  else
    cd $reporoot/bot/Scripts
    ./setup_repos.sh -B
    CFASTBRANCH=master
    SMVBRANCH=master
    expbranch=master
    fdsbranch=master
  fi
  #*** verify repos exist
  VERIFY_REPO_BRANCH $cfastrepo $CFASTBRANCH || exit 1
  VERIFY_REPO_BRANCH $smvrepo   $SMVBRANCH   || exit 1
  VERIFY_REPO_BRANCH $exprepo   $expbranch   || exit 1
  VERIFY_REPO_BRANCH $fdsrepo   $fdsbranch   || exit 1
else
  source $CONFIG
  this_dir=`pwd`
  cd $thisdir
  CHECKOUT_REPO release $cfastrepo $BUNDLE_CFAST_REVISION  $BUNDLE_CFAST_TAG
  CHECKOUT_REPO release $exprepo   $BUNDLE_EXP_REVISION    $BUNDLE_EXP_TAG
  CHECKOUT_REPO release $smvrepo   $BUNDLE_SMV_REVISION    $BUNDLE_SMV_TAG
fi

cd $cfastbotdir

notfound=`ifx -help 2>&1 | tail -1 | grep "not found" | wc -l`
if [ "$notfound" == "1" ] ; then
  echo "***error: ifx compiler not found"
  exit
fi

ABORT=
if [ -e $cfastrepo ]; then
  echo " cfast repo: $cfastrepo"
else
  echo "***error:  cfast repo: $cfastrepo does not exist"
  ABORT=1
fi
if [ -e $exprepo ]; then
  echo "   exp repo: $exprepo"
else
  echo "***error:  exp repo: $exprepo does not exist"
  ABORT=1
fi
if [ -e $fdsrepo ]; then
  echo "   fds repo: $fdsrepo"
else
  echo "***error:  fds repo: $fdsrepo does not exist"
  ABORT=1
fi
if [ -e $smvrepo ]; then
  echo "   smv repo: $smvrepo"
else
  echo "***error:  smv repo: $smvrepo does not exist"
  ABORT=1
fi
if [ "$ABORT" != "" ]; then
  exit
fi

platform="linux"
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
fi
export platform

echo "   platform: $platform"
echo "   compiler: intel"

# Set unlimited stack size
if [ "$platform" == "linux" ] ; then
  ulimit -s unlimited
fi

if [ "$UPLOAD" == "1" ]; then
  mkdir -p $NEWGUIDE_DIR
fi

cd

THIS_CFAST_FAILED=0
CFAST_STATUS_FILE=$GITSTATUS_DIR/cfast_status
LAST_CFAST_FAILED=0
if [ -e $CFAST_STATUS_FILE ] ; then
   LAST_CFAST_FAILED=`cat $CFAST_STATUS_FILE`
fi

export JOBPREFIX=cb_
GUIDES2GH=$cfastbotdir/guides2GH.sh

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
TIME_LIMIT=14400
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
echo "Status"
echo "------"
### Clean up on start ###
echo "Cleaning"
echo "   cfastbot results directory"
cd $cfastbotdir
rm -rf $OUTPUT_DIR/* &> /dev/null

### Stage 1 ###

cd $reporoot/bot
BOT_REVISION=`git describe --abbrev=7 --dirty --long`

cd $reporoot/exp
EXP_REVISION=`git describe --abbrev=7 --dirty --long`

cd $reporoot/fds
FDS_REVISION=`git describe --abbrev=7 --dirty --long`

cd $reporoot/cfast
CFAST_REVISION=`git describe --abbrev=7 --dirty --long`
CFAST_SHORTHASH=`git rev-parse --short HEAD`
# CFAST_REV same as CFAST_REVISION without the hash on the end
CFAST_REV=`git describe | sed 's/-g[0-9a-f]*$//'`

cd $reporoot/smv
SMV_REVISION=`git describe --abbrev=7 --dirty --long`
SMV_SHORTHASH=`git rev-parse --short HEAD`
# SMV_REV same as SMV_REVISION without the hash on the end
SMV_REV=`git describe | sed 's/-g[0-9a-f]*$//'`

cd $cur_dir

### Stage 2 ###

#*** build cfast debug cfast
echo "Building"
echo "   cfast"
echo "      Intel debug"
cd $cfastrepo/Build/CFAST/intel_${platform}_db
make -f ../makefile clean &> /dev/null
./make_cfast.sh &> $OUTPUT_DIR/stage2_build_cfast_debug
check_compile_cfast_db || exit 1

#*** build release cfast
echo "      release"
cd $cfastrepo/Build/CFAST/intel_${platform}
make -f ../makefile clean &> /dev/null
./make_cfast.sh &> $OUTPUT_DIR/stage2_build_cfast_release
check_compile_cfast || exit 1

#*** build smokeview libraries
cd $smvrepo/Build/LIBS/intel_${platform}
echo 'Building Smokeview libraries' >> $OUTPUT_DIR/stage2_build_smv_util 2>&1
echo "   smokeview libraries"
./make_LIBS.sh >> $OUTPUT_DIR/stage2_build_smv_util 2>&1

#*** build debug smokeview
echo "   smokeview"
echo "      debug"
cd $smvrepo/Build/smokeview/intel_${platform}
./make_smokeview_db.sh &> $OUTPUT_DIR/stage2_build_smv_debug
check_compile_smv_db || exit 1

#*** build release smokeview
echo "      release"
cd $smvrepo/Build/smokeview/intel_${platform}
./make_smokeview.sh &> $OUTPUT_DIR/stage2_build_smv_release
check_compile_smv || exit 1

### Stage 3 ###

#*** run cases - debug
if [[ $stage2_build_cfast_debug_success ]] ; then
   run_vv_cases_debug || exit 1
   check_vv_cases_debug || exit 1
fi

#*** run cases - release
if [[ $stage2_build_cfast_release_success ]] ; then
   run_vv_cases_release || exit 1
   check_vv_cases_release || exit 1
fi

### Stage 4 ###
if [[ $stage2_build_cfast_release_success && $stage2_build_smv_release_success ]] ; then
   echo "Generating smokeview images"
   cd $cfastrepo/Validation/scripts
   ./Make_CFAST_Pictures.sh -I intel 2>&1 | grep -v FreeFontPath &> $OUTPUT_DIR/stage4_make_pictures
   check_cfast_pictures
fi

### stage 5 - python verification ###
  echo Python
  echo "   setup environment"
  cd $botrepo/Firebot/
  source ./setup_python.sh > $OUTPUT_DIR/stage5_python_setup 2>&1
  echo "   Verification"
  echo "      make plots"
   # Run Python plotting script
  cd $cfastrepo/Utilities/Python

  python CFAST_verification_script.py &> $OUTPUT_DIR/stage5_run_python_verification
  check_python_verification

#*** run python validation
  echo "   Validation"
  echo "      run VandV_Calcs"
  cd $cfastrepo/Validation
  python VandV_Calcs.py CFAST_Pressure_Correction_inputs.csv &> /dev/null
  python VandV_Calcs.py CFAST_Temperature_Profile_inputs.csv &> /dev/null
  python VandV_Calcs.py CFAST_Heat_Flux_Profile_inputs.csv &> /dev/null
   
  echo "      make plots"
  # Run Python plotting script
  cd $cfastrepo/Utilities/Python
  python CFAST_validation_script.py &> $OUTPUT_DIR/stage5_run_python_validation

  check_python_validation
  check_validation_stats || exit 1
  archive_validation_stats || exit 1

### Stage 6 ###
  echo Building CFAST Tech guide
  cd $cfastrepo/Manuals/CFAST_Tech_Ref
  ./make_guide.sh &> $OUTPUT_DIR/stage6_cfast_tech_guide
  check_guide $OUTPUT_DIR/stage6_cfast_tech_guide $cfastrepo/Manuals/CFAST_Tech_Ref CFAST_Tech_Ref.pdf 'CFAST Technical Reference Guide'

  echo Building CFAST User guide
  cd $cfastrepo/Manuals/CFAST_Users_Guide
  ./make_guide.sh &> $OUTPUT_DIR/stage6_cfast_user_guide
  check_guide $OUTPUT_DIR/stage6_cfast_user_guide $cfastrepo/Manuals/CFAST_Users_Guide CFAST_Users_Guide.pdf 'CFAST Users Guide'

  echo Building CFAST VV guide
  cd $cfastrepo/Manuals/CFAST_Validation_Guide
  ./make_guide.sh &> $OUTPUT_DIR/stage6_cfast_vv_guide
  check_guide $OUTPUT_DIR/stage6_cfast_vv_guide $cfastrepo/Manuals/CFAST_Validation_Guide CFAST_Validation_Guide.pdf 'CFAST Verification and Validation Guide'

  echo Building CFAST Configuration guide
  cd $cfastrepo/Manuals/CFAST_Configuration_Guide
  ./make_guide.sh &> $OUTPUT_DIR/stage6_cfast_config_guide
  check_guide $OUTPUT_DIR/stage6_cfast_config_guide $cfastrepo/Manuals/CFAST_Configuration_Guide CFAST_Configuration_Guide.pdf 'CFAST Configuration Guide'

  echo Building CData guide
  cd $cfastrepo/Manuals/CFAST_CData_Guide
  ./make_guide.sh &> $OUTPUT_DIR/stage6_cdata_guide
  check_guide $OUTPUT_DIR/stage6_cdata_guide $cfastrepo/Manuals/CFAST_CData_Guide CFAST_CData_Guide.pdf 'CData Guide'

#*** output hashes needed for bundling
  VERSION_LATEST=$HOME/.cfastbot/VERSION_LATEST
  mkdir -p ${VERSION_LATEST}
  echo $CFAST_SHORTHASH > ${VERSION_LATEST}/CFAST_HASH
  echo $SMV_SHORTHASH   > ${VERSION_LATEST}/SMV_HASH
  echo $CFAST_REV       > ${VERSION_LATEST}/CFAST_REVISION
  echo $SMV_REV         > ${VERSION_LATEST}/SMV_REVISION

### Report results ###
set_files_world_readable || exit 1
save_build_status

### save version info if cfastbot passed ###
if [[ ! -e $ERROR_LOG ]] && [[ ! -e $WARNING_LOG ]]; then
  VERSION=$HOME/.cfastbot/VERSION
  mkdir -p ${VERSION}
  rm -f ${VERSION}/*
  cp ${VERSION_LATEST}/*                                                        ${VERSION}/.
  cp $cfastrepo/Manuals/CFAST_CData_Guide/CFAST_CData_Guide.pdf                 ${VERSION}/.
  cp $cfastrepo/Manuals/CFAST_Configuration_Guide/CFAST_Configuration_Guide.pdf ${VERSION}/.
  cp $cfastrepo/Manuals/CFAST_Validation_Guide/CFAST_Validation_Guide.pdf       ${VERSION}/.
  cp $cfastrepo/Manuals/CFAST_Users_Guide/CFAST_Users_Guide.pdf                 ${VERSION}/.
  cp $cfastrepo/Manuals/CFAST_Tech_Ref/CFAST_Tech_Ref.pdf                       ${VERSION}/.
fi
email_build_status
echo cfastbot complete

 

