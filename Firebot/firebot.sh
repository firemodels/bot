#!/bin/bash

# The Firebot script is part of an automated continuous integration system.
# Consult the FDS Config Management Plan for more information.

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "Verification and validation testing script for FDS"
echo ""
echo "Options"
echo "-b - branch_name - run firebot using branch branch_name"
echo "-c - clean repo"
echo "-F - skip figures and document building stages"
echo "-h - display this message"
echo "-i - use installed version of smokeview"
echo "-L - firebot lite,  run only stages that build a debug fds and run cases with it"
echo "                    (no release fds, no release cases, no matlab, etc)"
echo "-m email_address "
echo "-p pid_file - file containing process id of firebot process "
echo "-q - queue_name - run cases using the queue queue_name"
echo "     default: $QUEUE"
echo "-s - skip matlab and document building stages"
echo "-u - update repo"
echo "-U - upload guides"
exit
}

#---------------------------------------------
#                   CHK_REPO
#---------------------------------------------

CHK_REPO ()
{
  local repodir=$1

  if [ ! -e $repodir ]; then
     echo "***error: the repo directory $repodir does not exist."
     echo "          Aborting firebot."
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
       echo "Found branch $CURRENT_BRANCH. Aborting firebot."
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
         echo -e "Firebot has been running for more than 12 hours in Stage ${TIME_LIMIT_STAGE}. \n\nPlease ensure that there are no problems. \n\nThis is a notification only and does not terminate Firebot." | mail -s "[Firebot@$hostname] Notice: Firebot has been running for more than 12 hours." $mailToFDS > /dev/null
         TIME_LIMIT_EMAIL_NOTIFICATION="sent"
      fi
   fi
}

#---------------------------------------------
#                   set_files_world_readable
#---------------------------------------------

set_files_world_readable()
{
   cd $fdsrepo
   chmod -R go+r *

   cd $smvrepo
   chmod -R go+r *
}

#---------------------------------------------
#                   clean_repo
#---------------------------------------------

clean_repo()
{
  local curdir=`pwd`
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
#                   clean_firebote_metafiles
#---------------------------------------------

clean_firebot_metafiles()
{
   echo "   run directory"
   cd $firebotdir
   MKDIR guides &> /dev/null
   MKDIR $HISTORY_DIR &> /dev/null
   MKDIR $OUTPUT_DIR &> /dev/null
   rm -rf $OUTPUT_DIR/* &> /dev/null
   MKDIR $NEWGUIDE_DIR &> /dev/null
}

#---------------------------------------------
#                   clean_repo2
#---------------------------------------------

clean_repo2()
{
   local reponame=$1
   local branch=$2
   
   # Check to see if FDS repository exists
   if [ -e "$repo" ]; then
      CD_REPO $repo/$reponame $branch || return 1
      echo "   $reponame"
      clean_repo $repo/$reponame $branch || return 1
   else
      echo "firebot repo $repo does not exist" >> $OUTPUT_DIR/stage1 2>&1
      echo "firebot run aborted." >> $OUTPUT_DIR/stage1 2>&1
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
   
   echo "   $reponame" 
   echo Updating $branch on repo $repo/$reponame >> $OUTPUT_DIR/stage1 2>&1
   git fetch origin >> $OUTPUT_DIR/stage1 2>&1
   git merge origin/$branch >> $OUTPUT_DIR/stage1 2>&1
   have_remote=`git remote -v | grep firemodels | wc  -l`
   if [ "$have_remote" -gt "0" ]; then
      git fetch firemodels >> $OUTPUT_DIR/stage1 2>&1
      git merge firemodels/$branch >> $OUTPUT_DIR/stage1 2>&1
   fi

   if [[ "$reponame" == "exp" ]]; then
      echo "Fetching origin." >> $OUTPUT_DIR/stage1 2>&1
      git fetch origin >> $OUTPUT_DIR/stage1 2>&1
      echo "Updating submodules." >> $OUTPUT_DIR/stage1 2>&1
      git submodule foreach git fetch origin >> $OUTPUT_DIR/stage1 2>&1
      git submodule foreach git merge origin/master >> $OUTPUT_DIR/stage1 2>&1
   fi

   if [[ "$reponame" == "fds" ]]; then
      git update-index --refresh
      GIT_REVISION=`git describe --long --dirty`
      GIT_SHORTHASH=`git rev-parse --short HEAD`
      GIT_LONGHASH=`git rev-parse HEAD`
      GIT_DATE=`git log -1 --format=%cd --date=local $GIT_SHORTHASH`
   fi
   return 0
}

#---------------------------------------------
#                   clean_git_checkout
#---------------------------------------------

check_git_checkout()
{
   # Check for GIT errors
   stage1_success=true
}

#---------------------------------------------
#                   archive_compiler_version
#---------------------------------------------

archive_compiler_version()
{
   ifort -V &> "$HISTORY_DIR/${GIT_REVISION}_compiler_info.txt"
}

#---------------------------------------------
#                   inspect_fds_db
#---------------------------------------------

inspect_fds_db()
{
   # Perform OpenMP thread checking (locate deadlocks and data races)
   echo "      inspection"
   cd $fdsrepo/Verification/Thread_Check/
   $fdsrepo/Utilities/Scripts/inspect_openmp.sh  -r $repo thread_check.fds &> $OUTPUT_DIR/stage2a
}

#---------------------------------------------
#                   check_inspect_fds_db
#---------------------------------------------

check_inspect_fds_db()
{
   # Scan for errors in thread checking results
   cd $fdsrepo/Utilities/Scripts
   # grep -v 'Warning: One or more threads in the application accessed ...' ignores a known compiler warning that displays even without errors
      if [[ `grep -i -E 'warning|remark|problem|error' $OUTPUT_DIR/stage2a | grep -v '0 new problem(s) found' | grep -v 'Warning: One or more threads in the application accessed the stack of another thread'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Errors from Stage 2a - Compile and inspect FDS debug:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2a >> $ERROR_LOG
      echo "" >> $ERROR_LOG
      echo "For more details, view the inspector log in the fds/Utilities/Scripts folder" >> $ERROR_LOG
      echo "by using the fds/Utilities/Scripts/inspect_report.sh script." >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   compile_fds_mpi_db
#---------------------------------------------

compile_fds_mpi_db()
{
   # Clean and compile FDS MPI debug
   echo "      MPI debug"
   cd $fdsrepo/Build/mpi_intel_${platform}${size}$IB$DB
   make -f ../makefile clean &> /dev/null
   ./make_fds.sh &> $OUTPUT_DIR/stage2b
}

#---------------------------------------------
#                   check_compile_fds_mpi_db
#---------------------------------------------

check_compile_fds_mpi_db()
{
   # Check for errors in FDS MPI debug compilation
   cd $fdsrepo/Build/mpi_intel_${platform}${size}$IB$DB
   if [ -e "fds_mpi_intel_${platform}${size}$IB$DB" ]
   then
      stage2b_success=true
   else
      echo "Errors from Stage 2b - Compile FDS MPI debug:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2b >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
   if [[ `grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage2b | grep -v atom | grep -v 'feupdateenv is not implemented'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 2b - Compile FDS MPI debug:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage2b | grep -v atom | grep -v 'feupdateenv is not implemented' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   wait_cases_debug_end
#---------------------------------------------

wait_cases_debug_end()
{
   # Scans job queue and waits for cases to end
   if [[ "$QUEUE" == "none" ]]
   then
     while [[ `ps -u $USER -f | fgrep .fds | grep -v grep` != '' ]]; do
        JOBS_REMAINING=`ps -u $USER -f | fgrep .fds | grep -v grep | wc -l`
        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage4
        TIME_LIMIT_STAGE="3"
        check_time_limit
        sleep 30
     done
   else
     while [[ `qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX` != '' ]]; do
        JOBS_REMAINING=`qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX | wc -l`
        echo "Waiting for ${JOBS_REMAINING} ${1} cases to complete." >> $OUTPUT_DIR/stage4
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
   # Start running all FDS verification cases in delayed stop debug mode
   cd $fdsrepo/Verification/scripts
   # Run FDS with delayed stop files (with 1 OpenMP thread and 1 iteration)
   echo Running FDS Verification Cases
   echo "   debug"
   echo 'Running FDS verification cases:' >> $OUTPUT_DIR/stage4
   ./Run_FDS_Cases.sh -o 1 -d -m 1 -q $QUEUE -j $JOBPREFIX >> $OUTPUT_DIR/stage4 2>&1
   echo "" >> $OUTPUT_DIR/stage4 2>&1

   # Wait for all verification cases to end
   wait_cases_debug_end 'verification'

   # Remove all .stop files from Verification directories (recursively)
   cd $fdsrepo/Verification
   find . -name '*.stop' -exec rm -f {} \;
}

#---------------------------------------------
#                   check_cases_debug
#---------------------------------------------

check_cases_debug()
{
   local dir=$1
   local label=$2

   # Scan for and report any errors in FDS cases
   cd $dir

   if [[ `grep -rI 'Run aborted' $OUTPUT_DIR/stage4` == "" ]] && \
      [[ `grep -rI Segmentation *` == "" ]] && \
      [[ `grep -rI ERROR: *` == "" ]] && \
      [[ `grep -rI 'STOP: Numerical' *` == "" ]] && \
      [[ `grep -rI -A 20 forrtl *` == "" ]]
   then
      stage4_success=true
   else
      grep -rI 'Run aborted' $OUTPUT_DIR/stage4 >> $OUTPUT_DIR/stage4_errors
      grep -rI Segmentation * >> $OUTPUT_DIR/stage4_errors
      grep -rI ERROR: * >> $OUTPUT_DIR/stage4_errors
      grep -rI 'STOP: Numerical' * >> $OUTPUT_DIR/stage4_errors
      grep -rI -A 20 forrtl * >> $OUTPUT_DIR/stage4_errors
      
      echo "Errors from Stage 4 - Run ${2} cases - debug mode:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage4_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG

# copy casename.err to casename.err_stage4 for any cases that had errors
      echo "#/bin/bash" > $OUTPUT_DIR/stage4_filelist
      grep err $OUTPUT_DIR/stage4_errors | awk -F'[-:]' '{ print "cp " $dir " /tmp/."}'  | sort -u >> $OUTPUT_DIR/stage4_filelist
      cd $fdsrepo/Verification
      source $OUTPUT_DIR/stage4_filelist
   fi
}

#---------------------------------------------
#                   compile_fds_mpi
#---------------------------------------------

compile_fds_mpi()
{
   # Clean and compile FDS MPI
   echo "      MPI release"
   cd $fdsrepo/Build/mpi_intel_${platform}${size}$IB
   make -f ../makefile clean &> /dev/null
   ./make_fds.sh &> $OUTPUT_DIR/stage2c
}

#---------------------------------------------
#                   check_compile_fds_mpi
#---------------------------------------------

check_compile_fds_mpi()
{
   # Check for errors in FDS MPI compilation
   cd $fdsrepo/Build/mpi_intel_${platform}${size}$IB
   if [ -e "fds_mpi_intel_${platform}${size}$IB" ]
   then
      stage2c_success=true
   else
      echo "Errors from Stage 2c - Compile FDS MPI release:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2c >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   # 'performing multi-file optimizations' and 'generating object file' are part of a normal compile
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
   if [[ `grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage2c | grep -v atom | grep -v 'feupdateenv is not implemented' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 2c - Compile FDS MPI release:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage2c | grep -v atom | grep -v 'feupdateenv is not implemented' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   compile_smv_utilities
#---------------------------------------------

compile_smv_utilities()
{  
   # smokeview libraries
   if [ "$USEINSTALL" == "" ]; then
     echo "   Smokeview"
     echo "      libraries"
     cd $smvrepo/Build/LIBS/intel_${platform}${size}
     echo 'Building Smokeview libraries:' >> $OUTPUT_DIR/stage3a 2>&1
     ./makelibs.sh >> $OUTPUT_DIR/stage3a 2>&1
     echo "" >> $OUTPUT_DIR/stage3a 2>&1
   else
     echo "   Smokeview - using installed smokeview"
   fi
}

#---------------------------------------------
#                   check_smv_utilities
#---------------------------------------------

check_smv_utilities()
{
   # nothing to check
   stage3a_success=true
}

#---------------------------------------------
#                   check_cases_release
#---------------------------------------------

check_cases_release()
{
   local dir=$1

   # Scan for and report any errors in FDS cases
   cd $dir

   if [[ `grep -rI 'Run aborted' $OUTPUT_DIR/stage5` == "" ]] && \
      [[ `grep -rI Segmentation *` == "" ]] && \
      [[ `grep -rI ERROR: *` == "" ]] && \
      [[ `grep -rI 'STOP: Numerical' *` == "" ]] && \
      [[ `grep -rI -A 20 forrtl *` == "" ]]
   then
      stage5_success=true
   else
      grep -rI 'Run aborted' $OUTPUT_DIR/stage5 >> $OUTPUT_DIR/stage5_errors
      grep -rI Segmentation * >> $OUTPUT_DIR/stage5_errors
      grep -rI ERROR: * >> $OUTPUT_DIR/stage5_errors
      grep -rI 'STOP: Numerical' * >> $OUTPUT_DIR/stage5_errors
      grep -rI -A 20 forrtl * >> $OUTPUT_DIR/stage5_errors
      
      echo "Errors from Stage 5 - Run ${2} cases - release mode:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage5_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   wait_cases_release_end
#---------------------------------------------

wait_cases_release_end()
{
   # Scans qstat and waits for cases to end
   if [[ "$QUEUE" == "none" ]]
   then
     while [[ `ps -u $USER -f | fgrep .fds | grep -v grep` != '' ]]; do
        JOBS_REMAINING=`ps -u $USER -f | fgrep .fds | grep -v grep | wc -l`
        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage5
        TIME_LIMIT_STAGE="5"
        check_time_limit
        sleep 60
     done
   else
     while [[ `qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX` != '' ]]; do
        JOBS_REMAINING=`qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX | wc -l`
        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage5
        TIME_LIMIT_STAGE="5"
        check_time_limit
        sleep 60
     done
   fi
}

#---------------------------------------------
#                   run_verification_cases_release
#---------------------------------------------

run_verification_cases_release()
{
   # Start running all FDS verification cases

   echo "   release"
   cd $fdsrepo/Verification/scripts
   # Run FDS with 1 OpenMP thread
   echo 'Running FDS verification cases:' >> $OUTPUT_DIR/stage5
   ./Run_FDS_Cases.sh -o 1 -q $QUEUE -j $JOBPREFIX >> $OUTPUT_DIR/stage5 2>&1
   echo "" >> $OUTPUT_DIR/stage5 2>&1

   # Wait for all verification cases to end
   wait_cases_release_end 'verification'
}

#---------------------------------------------
#                   comple_smv_db
#---------------------------------------------

compile_smv_db()
{
   # Clean and compile SMV debug
   if [ "$USEINSTALL" == "" ]; then
     echo "      debug"
     cd $smvrepo/Build/smokeview/intel_${platform}${size}
     ./make_smv_db.sh &> $OUTPUT_DIR/stage3b
   fi
}

#---------------------------------------------
#                   check_compile_smv_db
#---------------------------------------------

check_compile_smv_db()
{
   # Check for errors in SMV debug compilation
   if [ "$USEINSTALL" == "" ]; then
   cd $smvrepo/Build/smokeview/intel_${platform}${size}
   if [ -e "smokeview_${platform}${size}_db" ]
   then
      stage3b_success=true
   else
      echo "Errors from Stage 3b - Compile SMV debug:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3b >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
   if [[ `grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage3b | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 3b - Compile SMV debug:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage3b | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   else
      stage3b_success=true
   fi
}

#---------------------------------------------
#                    comple_smv
#---------------------------------------------

compile_smv()
{
   # Clean and compile SMV
   if [ "$USEINSTALL" == "" ]; then
     echo "      release"
     cd $smvrepo/Build/smokeview/intel_${platform}${size}
     ./make_smv.sh &> $OUTPUT_DIR/stage3c
   fi
}

#---------------------------------------------
#                   check_compile_smv
#---------------------------------------------

check_compile_smv()
{
   # Check for errors in SMV release compilation
   if [ "$USEINSTALL" == "" ]; then
   cd $smvrepo/Build/smokeview/intel_${platform}${size}
   if [ -e "smokeview_${platform}${size}" ]
   then
      stage3c_success=true
   else
      echo "Errors from Stage 3c - Compile SMV release:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3c >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
   if [[ `grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage3c | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 3c - Compile SMV release:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage3c | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
   stage3c_success=true
   fi
}

#---------------------------------------------
#                   make_fds_pictures
#---------------------------------------------

make_fds_pictures()
{
   # Run Make FDS Pictures script
   echo Generating FDS images
   cd $fdsrepo/Verification/scripts
   ./Make_FDS_Pictures.sh $USEINSTALL &> $OUTPUT_DIR/stage6
}

#---------------------------------------------
#                   check_fds_pictures
#---------------------------------------------

check_fds_pictures()
{
   # Scan for and report any errors in make FDS pictures process
   cd $firebotdir
   if [[ `grep -I -E "Segmentation|Error" $OUTPUT_DIR/stage6` == "" ]]
   then
      stage6_success=true
   else
      grep -I -E -A 5 -B 5 "Segmentation|Error" $OUTPUT_DIR/stage6 > $OUTPUT_DIR/stage6_errors
      
      echo "Errors from Stage 6 - Make FDS pictures:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage6_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Scan for and report any warnings in make FDS pictures process
   cd $firebotdir
   if [[ `grep -I -E "Warning" $OUTPUT_DIR/stage6` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 6 - Make FDS pictures:" >> $WARNING_LOG
      grep -I -E "Warning" $OUTPUT_DIR/stage6 >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   run_matlab_license_test
#---------------------------------------------

run_matlab_license_test()
{
   echo Matlab
   echo "   license test"
   # Run simple test to see if Matlab license is available
   cd $fdsrepo/Utilities/Matlab
   matlab -r "try, disp('Running Matlab License Check'), catch, disp('License Error'), err = lasterror, err.message, err.stack, end, exit" &> $OUTPUT_DIR/stage7_matlab_license
}

#---------------------------------------------
#                   scan_matlab_license_test
#---------------------------------------------

scan_matlab_license_test()
{
   # Check for failed license
   if [[ `grep "License checkout failed" $OUTPUT_DIR/stage7_matlab_license` == "" ]]
   then
      # Continue along
      matlab_success=true
   else
      TIME_LIMIT_STAGE="7"
      check_time_limit
      matlab_success=false
      sleep 300
   fi
}

#---------------------------------------------
#                   check_matlab_license_server
#---------------------------------------------

check_matlab_license_server()
{
   for i in 1 2 3
   do
      run_matlab_license_test
      scan_matlab_license_test
      if [ $matlab_success == true ]; then
         break
      fi
      sleep 300
   done
}

#---------------------------------------------
#                   run_matlab_verification
#---------------------------------------------

run_matlab_verification()
{
   echo "   verification plots"
   # Run Matlab plotting script
   cd $fdsrepo/Utilities/Matlab
   matlab -r "try, disp('Running Matlab Verification script'), FDS_verification_script, catch, disp('Error'), err = lasterror, err.message, err.stack, end, exit" &> $OUTPUT_DIR/stage7a_verification
}

#---------------------------------------------
#                   check_matlab_verification
#---------------------------------------------

check_matlab_verification()
{
   # Scan for and report any errors in Matlab scripts
   cd $firebotdir
   if [[ `grep -B 5 -A 50 "Error" $OUTPUT_DIR/stage7a_verification` == "" ]]
   then
      stage7a_success=true
   else
      echo "Warnings from Stage 7a - Matlab plotting and statistics (verification):" >> $WARNING_LOG
      grep -B 5 -A 50 "Error" $OUTPUT_DIR/stage7a_verification >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   check_verification_stats
#---------------------------------------------

check_verification_stats()
{
   # Check for existence of verification statistics output file
   cd $fdsrepo/Utilities/Matlab
   if [ -e "FDS_verification_scatterplot_output.csv" ]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 7a - Matlab plotting and statistics (verification):" >> $WARNING_LOG
      echo "Error: The verification statistics output file does not exist." >> $WARNING_LOG
      echo "Expected the file Utilities/Matlab/FDS_verification_scatterplot_output.csv" >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi

   # Scan for and report warnings for any verification cases that are outside of their specified error tolerance
   cd $fdsrepo/Utilities/Matlab
   if [[ `grep "Out of Tolerance" FDS_verification_scatterplot_output.csv` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 7a - Matlab plotting and statistics (verification):" >> $WARNING_LOG
      echo "The following cases are outside of their specified error tolerance:" >> $WARNING_LOG
      echo "" >> $WARNING_LOG
      grep "Out of Tolerance" FDS_verification_scatterplot_output.csv | sed G >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi

   # Scan for and report any case warnings in Matlab scripts
   cd $firebotdir
   if [[ `grep "Matlab Warning" $OUTPUT_DIR/stage7a_verification` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 7a - Matlab plotting and statistics (verification):" >> $WARNING_LOG
      grep "Matlab Warning" $OUTPUT_DIR/stage7a_verification >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   run_matlab_validation
#---------------------------------------------

run_matlab_validation()
{
   echo "   validation plots"
   # Run Matlab plotting script
   cd $fdsrepo/Utilities/Matlab
   matlab -r "try, disp('Running Matlab Validation script'), FDS_validation_script, catch, disp('Error'), err = lasterror, err.message, err.stack, end, exit" &> $OUTPUT_DIR/stage7b_validation
}

#---------------------------------------------
#                   check_matlab_validation
#---------------------------------------------

check_matlab_validation()
{
   # Scan for and report any errors in Matlab scripts
   cd $firebotdir
   if [[ `grep -B 5 -A 50 "Error" $OUTPUT_DIR/stage7b_validation` == "" ]]
   then
      stage7b_success=true
   else
      echo "Warnings from Stage 7b - Matlab plotting and statistics (validation):" >> $WARNING_LOG
      grep -B 5 -A 50 "Error" $OUTPUT_DIR/stage7b_validation >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   archive_validateion_stats
#---------------------------------------------

archive_validation_stats()
{
   cd $fdsrepo/Utilities/Matlab

   echo archiving validation stats
   STATS_FILE_BASENAME=FDS_validation_scatterplot_output
   CURRENT_STATS_FILE=$fdsrepo/Utilities/Matlab/${STATS_FILE_BASENAME}.csv

   if [ -e ${CURRENT_STATS_FILE} ]
   then
      # Archive stats to Firebot history
      cp ${CURRENT_STATS_FILE} "$HISTORY_DIR/${GIT_REVISION}_${STATS_FILE_BASENAME}.csv"

   else
      echo "Warnings from Stage 7b - Matlab plotting and statistics (validation):" >> $WARNING_LOG
      echo "Warning: The validation statistics output file does not exist." >> $WARNING_LOG
      echo "Expected the file Utilities/Matlab/FDS_validation_scatterplot_output.csv" >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   make_validation_git_stats
#---------------------------------------------

make_validation_git_stats()
{
   # Output a LaTeX file with a table of the FDS validation sets and their corresponding GIT information
   cd $fdsrepo/Utilities/Scripts
   ./validation_git_stats.sh -r $repo
}

#---------------------------------------------
#                   generate_timing_stats
#---------------------------------------------

generate_timing_stats()
{
   cd $fdsrepo/Utilities/Scripts
   ./fds_timing_stats.sh > fds_timing_stats.csv
   cd $fdsrepo/Utilities/Scripts
   ./fds_timing_stats.sh firebot 1 > fds_benchmarktiming_stats.csv
   TOTAL_FDS_TIMES=`tail -1 fds_benchmarktiming_stats.csv`
}

#---------------------------------------------
#                   archive_timing_stats
#---------------------------------------------

archive_timing_stats()
{
   echo echo archiving timing stats
   cd $fdsrepo/Utilities/Scripts
   cp fds_timing_stats.csv "$HISTORY_DIR/${GIT_REVISION}_timing.csv"
   cp fds_benchmarktiming_stats.csv "$HISTORY_DIR/${GIT_REVISION}_benchmarktiming.csv"
   TOTAL_FDS_TIMES=`tail -1 fds_benchmarktiming_stats.csv`
  if [ "$UPLOADGUIDES" == "1" ]; then
     if [ "$USER" == "firebot" ]; then
        cd $botrepo/Firebot
       ./status_updatepub.sh $repo/webpages $WEBBRANCH
     fi
  fi
}

#---------------------------------------------
#                   check_guide
#---------------------------------------------

check_guide()
{
   local guidelog=$1
   local doc=$2
   local label=$3
   
   # Scan for and report any errors or warnings in build process for guides
   cd $firebotdir
   if [[ `grep -I "successfully" $guidelog` == "" ]]
   then
      # There were errors/warnings in the guide build process
      echo "Warnings from Stage 8 - Build FDS-SMV Guides:" >> $WARNING_LOG
      echo $label >> $WARNING_LOG # Name of guide
      cat $guidelog >> $WARNING_LOG # Contents of log file
      echo "" >> $WARNING_LOG
   else
      # Guide built successfully; there were no errors/warnings
      # Copy guide to Firebot's local website
      if [[ "$UPLOADGUIDES" == "1" ]]; then
        cp $doc /var/www/html/firebot/manuals/
        cp $doc $NEWGUIDE_DIR/.
      fi
   fi
}

#---------------------------------------------
#                   make_fds_user_guide
#---------------------------------------------

make_fds_user_guide()
{
   cd $fdsrepo/Manuals/FDS_User_Guide

   echo Building guides
   echo "  user guide"
   # Build FDS User Guide
   ./make_guide.sh &> $OUTPUT_DIR/stage8_fds_user_guide

   # Check guide for completion and copy to website if successful
   check_guide $OUTPUT_DIR/stage8_fds_user_guide $fdsrepo/Manuals/FDS_User_Guide/FDS_User_Guide.pdf 'FDS User Guide'
}

#---------------------------------------------
#                   make_fds_technical_guide
#---------------------------------------------

make_fds_technical_guide()
{
   cd $fdsrepo/Manuals/FDS_Technical_Reference_Guide

   echo "   technical guide"
   # Build FDS Technical Guide
   ./make_guide.sh &> $OUTPUT_DIR/stage8_fds_technical_guide

   # Check guide for completion and copy to website if successful
   check_guide $OUTPUT_DIR/stage8_fds_technical_guide $fdsrepo/Manuals/FDS_Technical_Reference_Guide/FDS_Technical_Reference_Guide.pdf 'FDS Technical Reference Guide'
}

#---------------------------------------------
#                   make_fds_verification_guide
#---------------------------------------------

make_fds_verification_guide()
{
   cd $fdsrepo/Manuals/FDS_Verification_Guide

   echo "   verification guide"
   # Build FDS Verification Guide
   ./make_guide.sh &> $OUTPUT_DIR/stage8_fds_verification_guide

   # Check guide for completion and copy to website if successful
   check_guide $OUTPUT_DIR/stage8_fds_verification_guide $fdsrepo/Manuals/FDS_Verification_Guide/FDS_Verification_Guide.pdf 'FDS Verification Guide'
}

#---------------------------------------------
#                   make_fds_validation_guide
#---------------------------------------------

make_fds_validation_guide()
{
   cd $fdsrepo/Manuals/FDS_Validation_Guide

   echo "   validation guide"
   # Build FDS Validation Guide
   ./make_guide.sh &> $OUTPUT_DIR/stage8_fds_validation_guide

   # Check guide for completion and copy to website if successful
   check_guide $OUTPUT_DIR/stage8_fds_validation_guide $fdsrepo/Manuals/FDS_Validation_Guide/FDS_Validation_Guide.pdf 'FDS Validation Guide'
}

#---------------------------------------------
#                   make_fds_Config_management_plan
#---------------------------------------------

make_fds_Config_management_plan()
{
   cd $fdsrepo/Manuals/FDS_Config_Management_Plan

   echo "   Config management guide"
   # Build FDS Config Management Plan
   ./make_guide.sh &> $OUTPUT_DIR/stage8_fds_Config_management_plan

   # Check guide for completion and copy to website if successful
   # note: script that uploads pdf to google doens't like the name so it has been shortened to FDS_Config_Management_Plan
   check_guide $OUTPUT_DIR/stage8_fds_Config_management_plan $fdsrepo/Manuals/FDS_Config_Management_Plan/FDS_Config_Management_Plan.pdf 'FDS Config Management Plan'
}

#---------------------------------------------
#                   save_build_status
#---------------------------------------------

save_build_status()
{
   STOP_TIME=$(date)
   STOP_TIME_INT=$(date +%s)
   cd $firebotdir
   # Save status outcome of build to a text file
   if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]
   then
     echo "" >> $ERROR_LOG
     cat $WARNING_LOG >> $ERROR_LOG
     echo "Build failure and warnings;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$FDSBRANCH;$STOP_TIME_INT;3;$TOTAL_FDS_TIMES" > "$HISTORY_DIR/${GIT_REVISION}.txt"
     cat $ERROR_LOG > "$HISTORY_DIR/${GIT_REVISION}_errors.txt"

   # Check for errors only
   elif [ -e $ERROR_LOG ]
   then
      echo "Build failure;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$FDSBRANCH;$STOP_TIME_INT;3;$TOTAL_FDS_TIMES" > "$HISTORY_DIR/${GIT_REVISION}.txt"
      cat $ERROR_LOG > "$HISTORY_DIR/${GIT_REVISION}_errors.txt"

   # Check for warnings only
   elif [ -e $WARNING_LOG ]
   then
      echo "Build success with warnings;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$FDSBRANCH;$STOP_TIME_INT;2;$TOTAL_FDS_TIMES" > "$HISTORY_DIR/${GIT_REVISION}.txt"
      cat $WARNING_LOG > "$HISTORY_DIR/${GIT_REVISION}_warnings.txt"

   # No errors or warnings
   else
      echo "Build success!;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$FDSBRANCH;$STOP_TIME_INT;1;$TOTAL_FDS_TIMES" > "$HISTORY_DIR/${GIT_REVISION}.txt"
   fi
}

#---------------------------------------------
#                   email_build_status
#---------------------------------------------

email_build_status()
{
   cd $firebotdir

   bottype=${1}
   botuser=${1}@$hostname
   
   stop_time=`date`
   echo "" > $TIME_LOG
   echo "-------------------------------" >> $TIME_LOG
   if [ "$FIREBOT_LITE" != "" ]; then
      echo "" >> $TIME_LOG
      echo "Note: only VV cases with debug FDS were run" >> $TIME_LOG
      echo "" >> $TIME_LOG
   fi
   echo "          host: $hostname " >> $TIME_LOG
   echo "            OS: $platform2 " >> $TIME_LOG
   echo "          Repo: $repo " >> $TIME_LOG
   echo "    Start Time: $start_time " >> $TIME_LOG
   echo "     Stop Time: $stop_time " >> $TIME_LOG
   if [ "$UPLOADGUIDES" == "1" ]; then
   echo "Firebot status:  https://pages.nist.gov/fds-smv/firebot_status.html" >> $TIME_LOG
   fi
   echo "-------------------------------" >> $TIME_LOG

   # Check for warnings and errors
   if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]
   then
      cd $firebotdir

     # Send email with failure message and warnings, body of email contains appropriate log file
     cat $ERROR_LOG $TIME_LOG | mail -s "[$botuser] $bottype failure and warnings. Version: ${GIT_REVISION}, Branch: $FDSBRANCH." $mailToFDS > /dev/null

   # Check for errors only
   elif [ -e $ERROR_LOG ]
   then
      # Send email with failure message, body of email contains error log file
      cat $ERROR_LOG $TIME_LOG | mail -s "[$botuser] $bottype failure. Version: ${GIT_REVISION}, Branch: $FDSBRANCH." $mailToFDS > /dev/null

   # Check for warnings only
   elif [ -e $WARNING_LOG ]
   then
      cd $firebotdir

      # Send email with success message, include warnings
      cat $WARNING_LOG $TIME_LOG | mail -s "[$botuser] $bottype success, with warnings. Version: ${GIT_REVISION}, Branch: $FDSBRANCH" $mailToFDS > /dev/null

   # No errors or warnings
   else
#  upload guides to a google drive directory
      cd $firebotdir

      # Send success message with links to nightly manuals
      cat $TIME_LOG | mail -s "[$botuser] $bottype success! Version: ${GIT_REVISION}, Branch: $FDSBRANCH" $mailToFDS > /dev/null
   fi

#  upload guides to a google drive directory
   if [[ "$UPLOADGUIDES" == "1" ]]; then
     $UploadGuides $NEWGUIDE_DIR $fdsrepo/Manuals &> /dev/null
   fi
}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             Primary script execution =
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** setup

# Start firebot timer
START_TIME=$(date +%s)
size=_64

# define run directories
PID_FILE=~/.fdssmvgit/firebot_pid
firebotdir=`pwd`
OUTPUT_DIR="$firebotdir/output"
HISTORY_DIR="$HOME/.firebot/history"
TIME_LOG=$OUTPUT_DIR/timings
ERROR_LOG=$OUTPUT_DIR/errors
WARNING_LOG=$OUTPUT_DIR/warnings
NEWGUIDE_DIR=$OUTPUT_DIR/Newest_Guides

WEBBRANCH=nist-pages
FDSBRANCH=master
SMVBRANCH=master
BRANCH=master

platform="linux"
platform2="Linux"
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  platform2="OSX"
fi

export platform

# Set unlimited stack size
if [ "$platform" == "linux" ] ; then
  ulimit -s unlimited
fi

# Additional definitions
USEINSTALL=
COMPILER=intel
QUEUE=firebot
CLEANREPO=0
UPDATEREPO=0
JOBPREFIX=FB_

DB=_db
IB=
if [ "$FDSNETWORK" == "infiniband" ] ; then
IB=ib
fi

# Load mailing list for status report
source $firebotdir/firebot_email_list.sh

UPLOADGUIDES=0
GIT_REVISION=
SKIPMATLAB=
SKIPFIGURES=
FIREBOT_LITE=

#*** parse command line arguments

while getopts 'b:cFhiLm:p:q:suUv:' OPTION
do
case $OPTION in
  b)
#   BRANCH="$OPTARG"
    echo "***Warning: -b option for specifying a branch is not supported at this time"
   ;;
  c)
   CLEANREPO=1
   ;;
  F)
   SKIPFIGURES=1
   ;;
  h)
   usage;
   ;;
  i)
   USEINSTALL="-r"
   ;;
  L)
   FIREBOT_LITE=1
   ;;
  m)
   mailToFDS="$OPTARG"
   ;;
  p)
   PID_FILE="$OPTARG"
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  s)
   SKIPMATLAB=1
   ;;
  u)
   UPDATEREPO=1
   ;;
  U)
   UPLOADGUIDES=1
   ;;
esac
done
shift $(($OPTIND-1))

#*** make sure firebot is running in correct directory

if [ -e .fds_git ]; then
  cd ../..
  repo=`pwd`
  cd $firebotdir
else
  echo "***error: firebot not running in the bot/Firebot directory"
  echo "          Aborting firebot"
  exit
fi

#*** make sure repos exist and have expected branches

fdsrepo=$repo/fds
CD_REPO $fdsrepo $fdsbranch || exit 1

smvrepo=$repo/smv
CD_REPO $smvrepo $smvbranch || exit 1

botrepo=$repo/bot
CD_REPO $botrepo $botbranch || exit 1
cd $firebotdir

#*** save pid in case we want to kill firebot later

echo $$ > $PID_FILE

#*** check for C/C++ compiler

notfound=
if [ "$COMPILER" == "intel" ]; then
   if [[ "$IFORT_COMPILER" != "" ]] ; then
      source $IFORT_COMPILER/bin/compilervars.sh intel64
   fi
   notfound=`icc -help 2>&1 | tail -1 | grep "not found" | wc -l`
else
   notfound=`gcc -help 2>&1 | tail -1 | grep "not found" | wc -l`
fi
if [ $notfound == 1 ] ; then
  USEINSTALL="-r"
fi

#*** if using the install option, make sure smokeview is installed

notfound=
if [ "$USEINSTALL" != "" ]; then
   notfound=`smokeview -v 2>&1 | tail -1 | grep "not found" | wc -l`
   if [ $notfound == 1 ]; then
      echo "Error: smokeview not found. firebot aborted."
      echo "Error: smokeview not found. firebot aborted." >> $OUTPUT_DIR/stage1 2>&1
      exit
   fi
fi

UploadGuides=$botrepo/Firebot/fds_guides2GD.sh

echo ""
echo "Settings"
echo "--------"
echo "    FDS repo: $fdsrepo"
echo "    SMV repo: $smvrepo"
echo "     Run dir: $firebotdir"
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
echo ""


# Set time limit (43,200 seconds = 12 hours)
TIME_LIMIT=43200
TIME_LIMIT_EMAIL_NOTIFICATION="unsent"

hostname=`hostname`
start_time=`date`

### Stage 1 ###

#*** clean repos
echo "Status"
echo "------"
  echo Cleaning
  clean_firebot_metafiles
if [[ "$CLEANREPO" == "1" ]] ; then
  clean_repo2 exp master || exit 1
  clean_repo2 fds $FDSBRANCH || exit 1
  clean_repo2 out master || exit 1
  clean_repo2 smv $SMVBRANCH || exit 1
fi

#*** update repos

if [[ "$UPDATEREPO" == "1" ]] ; then
  echo Updating
  update_repo exp master || exit 1
  update_repo fds $FDSBRANCH || exit 1
  update_repo out master || exit 1
  update_repo smv $SMVBRANCH || exit 1
else
  echo Repos not updated
fi

check_git_checkout
archive_compiler_version

### Stage 2a ###
echo Building
echo "   FDS"
if [ "$FIREBOT_LITE" == "" ]; then
   inspect_fds_db
   check_inspect_fds_db
fi

### Stage 2b ###
compile_fds_mpi_db
check_compile_fds_mpi_db

if [ "$FIREBOT_LITE" == "" ]; then
### Stage 2c ###
  compile_fds_mpi
  check_compile_fds_mpi

### Stage 3a ###
  compile_smv_utilities
  check_smv_utilities

### Stage 3b ###
  compile_smv_db
  check_compile_smv_db

### Stage 3c ###
  compile_smv
  check_compile_smv
fi

### Stage 4 ###
# Depends on successful FDS debug compile
if [[ $stage2b_success ]] ; then
   run_verification_cases_debug
   check_cases_debug $fdsrepo/Verification 'verification'
fi

if [ "$FIREBOT_LITE" == "" ]; then
# clean debug stage
cd $fdsrepo
if [[ "$CLEANREPO" == "1" ]] ; then
   echo "   cleaning repo"
   clean_repo $fdsrepo/Verification $fdsbranch || exit 1
   clean_repo $fdsrepo/Validation $fdsbranch || exit 1
fi

### Stage 5 ###
# Depends on successful FDS compile
if [[ $stage2c_success ]] ; then
   run_verification_cases_release
   check_cases_release $fdsrepo/Verification 'verification'
fi

### Stage 6 ###
# Depends on successful SMV compile
if [[ "$SKIPFIGURES" == "" ]] ; then
   if [[ $stage3c_success ]] ; then
      make_fds_pictures
      check_fds_pictures
   fi
fi

if [ "$SKIPMATLAB" == "" ] ; then
### Stage 7a ###
   check_matlab_license_server
   if [ $matlab_success == true ]; then
     run_matlab_verification
     check_matlab_verification
     check_verification_stats
   fi

### Stage 7b ###
   check_matlab_license_server
   if [ $matlab_success == true ]; then
     run_matlab_validation
     check_matlab_validation
     archive_validation_stats
     make_validation_git_stats
   fi
fi

### Stage 7c ###
   generate_timing_stats

### Stage 8 ###
if [ "$SKIPMATLAB" == "" ] ; then
   if [ "$SKIPFIGURES" == "" ] ; then
      make_fds_user_guide
      make_fds_verification_guide
      make_fds_technical_guide
      make_fds_validation_guide
      make_fds_Config_management_plan
   fi
fi
fi

### Wrap up and report results ###
set_files_world_readable
save_build_status
if [ "$FIREBOT_LITE" == "" ]; then
  archive_timing_stats
fi
email_build_status 'Firebot'
