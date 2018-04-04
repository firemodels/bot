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
echo "-C - commit validationbot output results"
echo "-D - specify validation case list file"
echo "-F - skip figures and document building stages"
echo "-h - display this message"
echo "-i - use installed version of smokeview"
echo "-I - use development version of FDS"
echo "-J - use Intel MPI version of FDS"
echo "-L - firebot lite,  run only stages that build a debug fds and run cases with it"
echo "                    (no release fds, no release cases, no matlab, etc)"
echo "-m email_address "
echo "-p pid_file - file containing process id of firebot process "
echo "-P - commit and push validationbot outut results (not implemented)"
echo "-q - queue_name - run cases using the queue queue_name"
echo "     default: $QUEUE"
echo "-Q - queue_name - run OpenMP cases using the queue queue_name"
echo "-s - skip matlab and document building stages"
echo "-S - show validation case list"
echo "-T - build bundle"
echo "-u - update repo"
echo "-U - upload guides"
echo "-V n - run Firebot in validation mode with a specified number "
echo "       of processes dedicated to validation."
exit
}

#---------------------------------------------
#                   PROCESS
#---------------------------------------------

PROCESS()
{
  local case=$1
  local curdir=`pwd`

  cd $fdsrepo/Validation/$case
  ./Process_Output.sh

  if [ "$commit" == "1" ]; then
    cd $outrepo/$case/FDS_Output_Files
    git add *.csv *.txt
    git commit -m "validationbot: commit $case results"
  fi
  if [ "$push" == "1" ]; then
    cd $outrepo/$case/FDS_Output_Files
    echo pushing updated $case results to github repo
    # git push origin master
  fi
  cd $curdir
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
      echo "firebot repo $repo does not exist." >> $OUTPUT_DIR/stage1 2>&1
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
   if [ $have_remote -gt 0 ]; then
      git fetch firemodels >> $OUTPUT_DIR/stage1 2>&1
      git merge firemodels/$branch >> $OUTPUT_DIR/stage1 2>&1
   fi

   if [[ "$reponame" == "exp" ]]; then
      echo "Fetching origin." >> $OUTPUT_DIR/stage1 2>&1
      git fetch origin >> $OUTPUT_DIR/stage1 2>&1
      echo "Updating submodules." >> $OUTPUT_DIR/stage1 2>&1
      git submodule foreach git fetch origin >> $OUTPUT_DIR/stage1 2>&1
      git submodule foreach git merge origin/master >> $OUTPUT_DIR/stage1 2>&1
      git status -uno  >> $OUTPUT_DIR/stage1 2>&1
   fi

   if [[ "$reponame" == "smv" ]]; then
      git update-index --refresh
      SMV_REVISION=`git describe --long --dirty`
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
   if [ -e $OUTPUT_DIR/stage1 ]; then
     if [[ `grep -i -E 'modified' $OUTPUT_DIR/stage1` == "" ]]
     then
        # Continue along
        :
     else
        echo "Warnings from Stage 1 - Update repos" >> $WARNING_LOG
        echo "" >> $WARNING_LOG
        grep -A 5 -B 5 -i -E 'modified' $OUTPUT_DIR/stage1 >> $WARNING_LOG
        echo "" >> $WARNING_LOG
     fi
   fi
   git_checkout_success=true
}

#---------------------------------------------
#                   archive_compiler_version
#---------------------------------------------

archive_compiler_version()
{
   ifort -V &> "$HISTORY_DIR/${GIT_REVISION}_compiler_info.txt"
}

#---------------------------------------------
#                   inspect_fds
#---------------------------------------------

inspect_fds()
{
   # Perform OpenMP thread checking (locate deadlocks and data races)
   echo "      inspection"
   cd $fdsrepo/Verification/Thread_Check/
   ./inspect_openmp.sh  thread_check.fds &> $OUTPUT_DIR/stage2a
}

#---------------------------------------------
#                   check_inspect_fds
#---------------------------------------------

check_inspect_fds()
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
      echo "For more details, cd to Verification/Thread_Check and view results in the " >> $ERROR_LOG
      echo "inspect_results directory after running the inspect_report.sh script." >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   compile_fds_mpi_db
#---------------------------------------------

compile_fds_mpi_db()
{
   # Clean and compile FDS MPI debug
   echo "      MPI Intel debug"
   cd $fdsrepo/Build/${INTEL}mpi_intel_${platform}${size}$DB
   make -f ../makefile clean &> /dev/null
   ./make_fds.sh &> $OUTPUT_DIR/stage2b
}

#---------------------------------------------
#                   check_compile_fds_mpi_db
#---------------------------------------------

check_compile_fds_mpi_db()
{
   # Check for errors in FDS MPI debug compilation
   cd $fdsrepo/Build/${INTEL}mpi_intel_${platform}${size}$DB
   if [ -e "fds_${INTEL}mpi_intel_${platform}${size}$DB" ]
   then
      FDS_debug_success=true
   else
      echo "Errors from Stage 2b - Compile FDS MPI debug:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2b >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
   if [[ `grep -E 'warning|remark' $OUTPUT_DIR/stage2b | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 2b - Compile FDS MPI debug:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage2b | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   compile_fds_mpi_gnu_db
#---------------------------------------------

compile_fds_mpi_gnu_db()
{
   # Clean and compile FDS MPI debug
   echo "      MPI gfortran debug"
   cd $fdsrepo/Build/mpi_gnu_${platform}${size}$DB
   make -f ../makefile clean &> /dev/null
   ./make_fds.sh &> $OUTPUT_DIR/stage2d
}

#---------------------------------------------
#                   check_compile_fds_mpi_gnu_db
#---------------------------------------------

check_compile_fds_mpi_gnu_db()
{
   # Check for errors in FDS MPI debug compilation
   cd $fdsrepo/Build/mpi_gnu_${platform}${size}$DB
   if [ -e "fds_mpi_gnu_${platform}${size}$DB" ]
   then
      FDS_debug_success=true
   else
      echo "Errors from Stage 2d - Compile gnu Fortran FDS MPI debug:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2d >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   if [[ `grep -i -E 'warning|remark' $OUTPUT_DIR/stage2d | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 2d - Compile gnu Fortran FDS MPI debug:" >> $WARNING_LOG
      grep -i -A 5 -E 'warning|remark' $OUTPUT_DIR/stage2d | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   show_validation_list
#---------------------------------------------

show_validation_list()
{
   valdir=`pwd`
   cd $fdsrepo/Utilities/Scripts

   # List and sort validation sets in the fds/Validation/Process_All_Output.sh 
   # script based on the modification date of the FDS_Output_Files. The result
   # is an array of the validation sets ordered from oldest to newest.
   ./make_validation_caselist.sh
   cd $valdir
}

#---------------------------------------------
#                   get_validation_set_list
#---------------------------------------------

get_validation_list()
{
   validation_list_file=$1
   
   valdir=`pwd`
   cd $fdsrepo/Utilities/Scripts

   # List and sort validation sets in the fds/Validation/Process_All_Output.sh 
   # script based on the modification date of the FDS_Output_Files. The result
   # is an array of the validation sets ordered from oldest to newest.
   VALIDATION_SETS=(` cat $validation_list_file | awk -F"!" '{print $1}'`)
   cd $valdir
}

#---------------------------------------------
#                   generate_validation_list
#---------------------------------------------

generate_validation_list()
{
   valdir=`pwd`
   cd $fdsrepo/Utilities/Scripts

   # List and sort validation sets in the fds/Validation/Process_All_Output.sh 
   # script based on the modification date of the FDS_Output_Files. The result
   # is an array of the validation sets ordered from oldest to newest.
   VALIDATION_SETS=(` ./make_validation_caselist.sh | awk -F"!" '{print $1}'`)
   cd $valdir
}

#---------------------------------------------
#                   commit_validation_results
#---------------------------------------------

commit_validation_results()
{
   echo "Summary"
   echo "-------"
   for SET in ${CURRENT_VALIDATION_SETS[*]}
   do
      # Copy new FDS files from Current_Results to FDS_Output_Files using Process_Output.sh 
      # script for the validation set

     PROCESS "$SET"
   done

   # cd to GIT root
   cd $fdsrepo
}

#---------------------------------------------
#                   wait_cases_debug_end
#---------------------------------------------

wait_cases_debug_end()
{
   # Scans job queue and waits for cases to end
   if [[ "$QUEUE" == "none" ]]
   then
     while [[          `ps -u $USER -f | fgrep .fds | grep -v firebot | grep -v grep` != '' ]]; do
        JOBS_REMAINING=`ps -u $USER -f | fgrep .fds | grep -v firebot | grep -v grep | wc -l`
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
   ./Run_FDS_Cases.sh -o 1 -d -m 1 $INTEL2 -q $QUEUE >> $OUTPUT_DIR/stage4 2>&1
   echo "" >> $OUTPUT_DIR/stage4 2>&1

   # Wait for all verification cases to end
   wait_cases_debug_end 'verification'

   # Remove all .stop files from Verification directories (recursively)
   cd $fdsrepo/Verification
   find . -name '*.stop' -exec rm -f {} \;
}

#---------------------------------------------
#                   check_current_utilization
#---------------------------------------------

check_current_utilization()
{
   # This function is used to determine if the number of current processes currently in use is greater than the
   # number of specified maximum processes. If so, then no more cases are launched (LAUNCH_MORE_CASES=0).

   sleep 60

   # Reports the number of nodes currently in use by current user
   NJOBS=`qstat -u $(whoami) | wc -l`
   NUM_CURRENT_PROCESSES=0
   if [ $NJOBS -gt 0 ]; then
     NUM_CURRENT_PROCESSES=`qstat -u $(whoami) | sed 1,5d | awk '{print $7}' | paste -sd+ | bc`
   fi
   if [ $NUM_CURRENT_PROCESSES -gt $MAX_VALIDATION_PROCESSES ]; then
      LAUNCH_MORE_CASES=0
   fi
}

#---------------------------------------------
#                   run_validation_cases_debug
#---------------------------------------------

run_validation_cases_debug()
{
   #  =============================================
   #  = Run FDS validation cases for current sets =
   #  =============================================

   # Initialize array of current validation sets to run
   CURRENT_VALIDATION_SETS=()
   echo Running FDS Validation Cases
   echo "   debug"

   for SET in ${VALIDATION_SETS[*]}
   do
      # Check to see if maximum number of validation processes are in use
      if [ $LAUNCH_MORE_CASES -eq 0 ]; then
         break
      fi

      cd $fdsrepo/Validation/"$SET"

      # Submit FDS validation cases and wait for them to start
      echo "Running FDS validation cases for ${SET}:" >> $OUTPUT_DIR/stage4
      echo "" >> $OUTPUT_DIR/stage4 2>&1
      ./Run_All.sh -y -b -m 1 -q $QUEUE >> $OUTPUT_DIR/stage4 2>&1

      CURRENT_VALIDATION_SETS+=($SET)

      check_current_utilization
   done

   # Wait for validation cases to end
   wait_cases_debug_end 'validation'
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
      [[ `grep -rI forrtl *` == "" ]]
   then
      cases_debug_success=true
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
      grep err $OUTPUT_DIR/stage4_errors | awk -F':' '{ print "cp " $1 " /tmp/."}'  | sort -u >> $OUTPUT_DIR/stage4_filelist
      if [ "$FIREBOT_MODE" == "verification" ] ; then
        cd $fdsrepo/Verification
      else
        cd $fdsrepo/Validation
      fi
      source $OUTPUT_DIR/stage4_filelist

      # If errors encountered in validation mode, then email status and exit
      if [ "$FIREBOT_MODE" == "validation" ] ; then
         email_build_status 'Validationbot'
         set_files_world_readable
         exit
      fi
   fi
}

#---------------------------------------------
#                   compile_fds_mpi
#---------------------------------------------

compile_fds_mpi()
{
   # Clean and compile FDS MPI
   echo "      MPI Intel release"
   echo "" > $OUTPUT_DIR/stage2c
   if [ "$debug_mode" == "" ]; then
     cd $fdsrepo/Build/${INTEL}mpi_intel_${platform}${size}$DV
     make -f ../makefile clean &> /dev/null
     ./make_fds.sh &> $OUTPUT_DIR/stage2c
   fi
}

#---------------------------------------------
#                   check_compile_fds_mpi
#---------------------------------------------

check_compile_fds_mpi()
{
   # Check for errors in FDS MPI compilation
   cd $fdsrepo/Build/${INTEL}mpi_intel_${platform}${size}$DV
   if [ -e "fds_${INTEL}mpi_intel_${platform}${size}$DV" ]
   then
      FDS_release_success=true
   else
      echo "Errors from Stage 2c - Compile FDS MPI release:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage2c >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi

   # Check for compiler warnings/remarks
   # 'performing multi-file optimizations' and 'generating object file' are part of a normal compile
   # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
   if [[ `grep -E 'warning|remark' $OUTPUT_DIR/stage2c | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file'` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 2c - Compile FDS MPI release:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage2c | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file' >> $WARNING_LOG
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
     ./make_LIBS.sh >> $OUTPUT_DIR/stage3a 2>&1
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
   smv_utilities_success=true
}

#---------------------------------------------
#                   check_validation_cases
#---------------------------------------------

check_validation_cases()
{
  case=$1

  cd $fdsrepo/Validation/$case
  nfds=0
  if [ -d Current_Results ]; then
    nfds=`ls -l Current_Results/*.fds 2> /dev/null | wc -l`
  fi
  if [ $nfds -eq 0 ]; then
     exit
  fi
  nout=`ls -l Current_Results/*.out 2> /dev/null | wc -l`
  nsuccess=`grep successfully Current_Results/*.out 2> /dev/null | wc -l`
  if [ $nfds -gt $nout ]; then
    if [ "$nout" == "0" ]; then
      echo "***error: $nfds $case cases were run but none finished" >> $VALIDATION_ERROR_LOG
    else
      echo "***error: $nfds $case cases were run but only $nout finished" >> $VALIDATION_ERROR_LOG
    fi
    validation_cases="false"
  else
    if [ $nout -gt $nsuccess ]; then
      if [ $nsuccess -gt 0 ]; then
        echo "***error: $nfds $case cases were run but only $nsuccess finished successfully" >> $VALIDATION_ERROR_LOG
      else
        echo "***error: $nfds $case cases were run but none finished successfully" >> $VALIDATION_ERROR_LOG
      fi
      validation_cases="false"
    fi
  fi
  if [ $nout -gt 0 ] && [ $nout -gt $nsuccess ]; then
    cd $fdsrepo/Validation/$case/Current_Results
    grep STOP *.out | grep -v successfully | awk -F':' '{print $1 }' | awk -F'.' '{print "***error: " $1".fds did not finish successfully." }' >> $VALIDATION_ERROR_LOG
    validation_cases="false"
  fi
}

#---------------------------------------------
#                   check_cases_release
#---------------------------------------------

check_cases_release()
{
   local dir=$1
   local status=$2

   # Scan for and report any errors in FDS cases
   cd $dir

   validation_cases="true"
   if [ "$FIREBOT_MODE" == "validation" ] ; then
      if [ "$status" == "final" ]; then
        for SET in ${CURRENT_VALIDATION_SETS[*]}
        do
           check_validation_cases $SET
        done
      fi
   fi
   if [[ `grep -rI 'Run aborted' $OUTPUT_DIR/stage5` == "" ]] && \
      [[ `grep -rI Segmentation *` == "" ]] && \
      [[ `grep -rI ERROR: *` == "" ]] && \
      [[ `grep -rI 'STOP: Numerical' *` == "" ]] && \
      [[ `grep -rI forrtl *` == "" ]] && \
      [[ "$validation_cases" == "true" ]]
   then
      cases_release_success=true
   else
      grep -rI 'Run aborted' $OUTPUT_DIR/stage5 >> $OUTPUT_DIR/stage5_errors
      grep -rI Segmentation * >> $OUTPUT_DIR/stage5_errors
      grep -rI ERROR: * >> $OUTPUT_DIR/stage5_errors
      grep -rI 'STOP: Numerical' * >> $OUTPUT_DIR/stage5_errors
      grep -rI -A 20 forrtl * >> $OUTPUT_DIR/stage5_errors
      if [ "$FIREBOT_MODE" == "validation" ] ; then
         if [ -e $VALIDATION_ERROR_LOG ]; then
            cat $VALIDATION_ERROR_LOG >> $OUTPUT_DIR/stage5_errors
         fi
      fi

      echo "Errors from Stage 5 - Run ${2} cases - release mode:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage5_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG

      # If errors encountered in validation mode, then email status and exit
      if [ "$FIREBOT_MODE" == "validation" ] ; then
         email_build_status 'Validationbot'
         # Stop all Validationbot cases in queue system
         qdel all >& /dev/null
         set_files_world_readable
         exit
      fi
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
     while [[          `ps -u $USER -f | fgrep .fds | grep -v firebot | grep -v grep` != '' ]]; do
        JOBS_REMAINING=`ps -u $USER -f | fgrep .fds | grep -v firebot | grep -v grep | wc -l`

        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage5
        TIME_LIMIT_STAGE="5"
        check_time_limit
        if [ "$FIREBOT_MODE" == "validation" ] ; then
          check_cases_release $fdsrepo/Validation 'interim'
          sleep 240
        fi
        sleep 60
     done
   else
     while [[ `qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX` != '' ]]; do
        JOBS_REMAINING=`qstat -a | awk '{print $2 $4}' | grep $(whoami) | grep $JOBPREFIX | wc -l`
        echo "Waiting for ${JOBS_REMAINING} verification cases to complete." >> $OUTPUT_DIR/stage5
        TIME_LIMIT_STAGE="5"
        check_time_limit
        if [ "$FIREBOT_MODE" == "validation" ] ; then
           check_cases_release $fdsrepo/Validation 'interim'
           sleep 30
        fi
        sleep 30
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
   echo 'Running FDS benchmark verification cases:' >> $OUTPUT_DIR/stage5
   ./Run_FDS_Cases.sh $INTEL2 $DV2 -b -o 1 -q $QUEUEBENCH >> $OUTPUT_DIR/stage5 2>&1
   echo "" >> $OUTPUT_DIR/stage5 2>&1

   # Wait for benchmark verification cases to end
# let benchmark and regular cases run at the same time - for now
#   wait_cases_release_end 'verification'

   echo 'Running FDS non-benchmark verification cases:' >> $OUTPUT_DIR/stage5
   ./Run_FDS_Cases.sh $INTEL2 $DV2 -R -o 1 -q $QUEUE >> $OUTPUT_DIR/stage5 2>&1
   echo "" >> $OUTPUT_DIR/stage5 2>&1

   # Wait for non-benchmark verification cases to end
   wait_cases_release_end 'verification'
}

#---------------------------------------------
#                   run_validation_cases_release
#---------------------------------------------

run_validation_cases_release()
{
   #  ===================================
   #  = Run selected FDS validation set =
   #  ===================================
   echo "   release"

   for SET in ${CURRENT_VALIDATION_SETS[*]}
   do
      cd $fdsrepo/Validation/"$SET"

      # Start running FDS validation cases
      echo "Running FDS validation cases:" >> $OUTPUT_DIR/stage5
      echo "Validation Set: ${SET}" >> $OUTPUT_DIR/stage5
      echo "" >> $OUTPUT_DIR/stage5 2>&1
      ./Run_All.sh -y $DV2 -q $QUEUE >> $OUTPUT_DIR/stage5 2>&1
      echo "" >> $OUTPUT_DIR/stage5 2>&1
   done

   # Wait for validation cases to end
   wait_cases_release_end 'validation'
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
     ./make_smokeview_db.sh &> $OUTPUT_DIR/stage3b
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
    if [ -e "smokeview_${platform}${size}_db" ]; then
      smv_debug_success=true
    else
      echo "Errors from Stage 3b - Compile SMV debug:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3b >> $ERROR_LOG
      echo "" >> $ERROR_LOG
    fi

    # Check for compiler warnings/remarks
    # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
    if [[ `grep -E 'warning|remark' $OUTPUT_DIR/stage3b | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]; then
      # Continue along
      :
    else
      echo "Warnings from Stage 3b - Compile SMV debug:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage3b | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
    fi
  else
    smv_debug_success=true
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
     ./make_smokeview.sh &> $OUTPUT_DIR/stage3c
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
    if [ -e "smokeview_${platform}${size}" ]; then
      smv_release_success=true
    else
      echo "Errors from Stage 3c - Compile SMV release:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3c >> $ERROR_LOG
      echo "" >> $ERROR_LOG
    fi

    # Check for compiler warnings/remarks
    # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
    if [[ `grep -E 'warning|remark' $OUTPUT_DIR/stage3c | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]; then
      # Continue along
      :
    else
      echo "Warnings from Stage 3c - Compile SMV release:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage3c | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
    fi
    smv_release_success=true
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
      fds_pictures_success=true
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
      grep -A 1 -I -E "Warning" $OUTPUT_DIR/stage6 >> $WARNING_LOG
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
   SKIPMATLAB="1"
   for i in 1 2 3 4
   do
      run_matlab_license_test
      scan_matlab_license_test
      if [ $matlab_success == true ]; then
         SKIPMATLAB=
         break
      fi
      sleep 300
   done
   if [ "$SKIPMATLAB" == "1" ]; then
      echo "Error from Stage 7 - Matlab failed to be checked out" >> $ERROR_LOG
   fi
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
   if [[ `grep "Error" $OUTPUT_DIR/stage7a_verification` == "" ]]
   then
      matlab_verification_success=true
   else
      echo "Warnings from Stage 7a - Matlab plotting and statistics (verification):" >> $WARNING_LOG
      grep -B 5 -A 50 "Error" $OUTPUT_DIR/stage7a_verification | tr -cd '\11\12\15\40-\176' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   check_verification_stats
#---------------------------------------------

check_verification_stats()
{
   # Check for existence of verification statistics output file
   cd $fdsrepo/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/Scatterplots
   if [ -e "FDS_verification_scatterplot_output.csv" ]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 7a - Matlab plotting and statistics (verification):" >> $WARNING_LOG
      echo "Error: The verification statistics output file does not exist." >> $WARNING_LOG
      echo "Expected the file Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/Scatterplots/FDS_verification_scatterplot_output.csv" >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi

   # Scan for and report warnings for any verification cases that are outside of their specified error tolerance
   cd $fdsrepo/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/Scatterplots
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
   if [[ `grep "Error" $OUTPUT_DIR/stage7b_validation` == "" ]]
   then
      matlab_validation_succcess=true
   else
      echo "Warnings from Stage 7b - Matlab plotting and statistics (validation):" >> $WARNING_LOG
      grep -B 5 -A 50 "Error" $OUTPUT_DIR/stage7b_validation | tr -cd '\11\12\15\40-\176' >> $WARNING_LOG
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
   CURRENT_STATS_FILE=$fdsrepo/Manuals/FDS_Validation_Guide/SCRIPT_FIGURES/ScatterPlots/${STATS_FILE_BASENAME}.csv

   if [ -e ${CURRENT_STATS_FILE} ]
   then
      # Archive stats to Firebot history
      cp ${CURRENT_STATS_FILE} "$HISTORY_DIR/${GIT_REVISION}_${STATS_FILE_BASENAME}.csv"

   else
      echo "Warnings from Stage 7b - Matlab plotting and statistics (validation):" >> $WARNING_LOG
      echo "Warning: The validation statistics output file does not exist." >> $WARNING_LOG
      echo "Expected the file Manuals/FDS_Validation_Guide/SCRIPT_FIGURES/ScatterPlots/FDS_validation_scatterplot_output.csv" >> $WARNING_LOG
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
      cp $doc $SAVEGUIDE_DIR/.
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
#                   make_bundle
#---------------------------------------------

make_bundle()
{
   cd $fdsrepo/
   export FDS_VERSION=`git describe --long --dirty | awk -F'-' '{print $1"-"$2}'`

   cd $smvrepo/
   export SMV_VERSION=`git describe --long --dirty | awk -F'-' '{print $1"-"$2}'`

   echo " make bundle"
   # making a bundle
   cd $fdsrepo/Build/Bundle
   export NOPAUSE=1
   ./make_bundle.sh &> $OUTPUT_DIR/stage9_make_bundle
}

#---------------------------------------------
#                   save_build_status
#---------------------------------------------

save_build_status()
{
   HOST=`hostname -s`
   STOP_TIME=$(date)
   STOP_TIME_INT=$(date +%s)
   cd $firebotdir
   # Save status outcome of build to a text file
   if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]
   then
     echo "" >> $ERROR_LOG
     cat $WARNING_LOG >> $ERROR_LOG
     echo "Build failure and warnings;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$FDSBRANCH;$STOP_TIME_INT;3;$TOTAL_FDS_TIMES;$HOST" > "$HISTORY_DIR/${GIT_REVISION}.txt"
     cat $ERROR_LOG > "$HISTORY_DIR/${GIT_REVISION}_errors.txt"

   # Check for errors only
   elif [ -e $ERROR_LOG ]
   then
      echo "Build failure;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$FDSBRANCH;$STOP_TIME_INT;3;$TOTAL_FDS_TIMES;$HOST" > "$HISTORY_DIR/${GIT_REVISION}.txt"
      cat $ERROR_LOG > "$HISTORY_DIR/${GIT_REVISION}_errors.txt"

   # Check for warnings only
   elif [ -e $WARNING_LOG ]
   then
      echo "Build success with warnings;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$FDSBRANCH;$STOP_TIME_INT;2;$TOTAL_FDS_TIMES;$HOST" > "$HISTORY_DIR/${GIT_REVISION}.txt"
      cat $WARNING_LOG > "$HISTORY_DIR/${GIT_REVISION}_warnings.txt"

   # No errors or warnings
   else
      echo "Build success!;$GIT_DATE;$GIT_SHORTHASH;$GIT_LONGHASH;${GIT_REVISION};$FDSBRANCH;$STOP_TIME_INT;1;$TOTAL_FDS_TIMES;$HOST" > "$HISTORY_DIR/${GIT_REVISION}.txt"
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
   echo "           host: $hostname " >> $TIME_LOG
   echo "             OS: $platform2 " >> $TIME_LOG
   echo "           repo: $repo " >> $TIME_LOG
   echo "          queue: $QUEUE " >> $TIME_LOG
if [ "$QUEUE" != "$QUEUEBENCH" ]; then
   echo "benchmark queue: $QUEUEBENCH " >> $TIME_LOG
fi
   echo "   fds revision: $GIT_REVISION " >> $TIME_LOG
   echo "  smv rewvision: $SMV_REVISION " >> $TIME_LOG
if [ "$IFORT_VERSION" != "" ]; then
   echo "        Fortran: $IFORT_VERSION " >> $TIME_LOG
fi
   if [ "$FIREBOT_MODE" == "validation" ] ; then
      echo "Validation Set(s): ${CURRENT_VALIDATION_SETS[*]} " >> $TIME_LOG
   fi
   echo "     start time: $start_time " >> $TIME_LOG
   echo "      stop time: $stop_time " >> $TIME_LOG
   if [ "$UPLOADGUIDES" == "1" ]; then
   echo " Firebot status:  https://pages.nist.gov/fds-smv/firebot_status.html" >> $TIME_LOG
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
#                             beginning of firebot
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** setup

# Start firebot timer
START_TIME=$(date +%s)
size=_64

# define run directories
PID_FILE=~/.fdssmvgit/firebot_pid
firebotdir=`pwd`
export SCRIPTFILES=$firebotdir/scriptfiles
OUTPUT_DIR="$firebotdir/output"
HISTORY_DIR="$HOME/.firebot/history"
TIME_LOG=$OUTPUT_DIR/timings
ERROR_LOG=$OUTPUT_DIR/errors
VALIDATION_ERROR_LOG=$OUTPUT_DIR/validation_errors
WARNING_LOG=$OUTPUT_DIR/warnings
NEWGUIDE_DIR=$OUTPUT_DIR/Newest_Guides
SAVEGUIDE_DIR=$HOME/.firebot/pubs

MKDIR $HOME/.firebot
MKDIR $HOME/.firebot/pubs

#*** Firebot mode (verification or validation)
FIREBOT_MODE="verification"

WEBBRANCH=nist-pages
FDSBRANCH=master
SMVBRANCH=master
BRANCH=master

#*** determine platform

platform="linux"
platform2="Linux"
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  platform2="OSX"
fi
export platform

#*** Set unlimited stack size

if [ "$platform" == "linux" ] ; then
  ulimit -s unlimited
fi

#*** set initial values

USEINSTALL=
COMPILER=intel
QUEUE=firebot
CLEANREPO=0
UPDATEREPO=0
if [ "$JOBPREFIX" == "" ]; then
  export JOBPREFIX=FB_
fi
commit=
push=

DB=_db

# Load mailing list for status report
source $firebotdir/firebot_email_list.sh

UPLOADGUIDES=0
GIT_REVISION=
SKIPMATLAB=
SKIPFIGURES=
FIREBOT_LITE=
caselistfile=""
showcaselist=
debug_mode=
DV=
DV2=
INTEL=
INTEL2=
QUEUEBENCH=
BUILD_BUNDLE=

#*** parse command line arguments

while getopts 'b:cCdD:FhIiJLm:p:Pq:Q:sSTuUV:' OPTION
do
case $OPTION in
  b)
#   BRANCH="$OPTARG"
    echo "***Warning: -b option for specifying a branch is not supported at this time"
   ;;
  c)
   CLEANREPO=1
   ;;
  C)
   commit=1
   ;;
  d)
   debug_mode=1
   ;;
  D)
    caselistfile="$OPTARG"
   ;;
  F)
   SKIPFIGURES=1
   ;;
  h)
   usage;
   ;;
  I)
   DV="_dv"
   DV2="-u"
   ;;
  i)
   USEINSTALL="-r"
   ;;
  J)
   INTEL=i
   INTEL2="-J"
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
  P)
   push=1
   ;;
  q)
   QUEUE="$OPTARG"
   ;;
  Q)
   QUEUEBENCH="$OPTARG"
   ;;
  s)
   SKIPMATLAB=1
   ;;
  S)
   showcaselist="1"
   ;;
  T)
   BUILD_BUNDLE="1"
   ;;
  u)
   UPDATEREPO=1
   ;;
  U)
   UPLOADGUIDES=1
   ;;
  V)
   FIREBOT_MODE="validation"
   QUEUE=batch
   MAX_VALIDATION_PROCESSES="$OPTARG"
   LAUNCH_MORE_CASES=1
   export JOBPREFIX=VB_
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

if [[ "$QUEUE" == "none" ]] && [[ -e $SCRIPTFILES ]]; then
  rm -f $SCRIPTFILES
fi

if [ "$QUEUEBENCH" == "" ]; then
  QUEUEBENCH=$QUEUE
fi

if [ "$caselistfile" != "" ]; then
  if [ ! -e $caselistfile ]; then
     echo "***error: $caselistfile does not exist."
     echo "aborting firebot"
     exit
  fi
  casedir=$(dirname "${caselistfile}")
  casename=$(basename "${caselistfile}")
  ccurdir=`pwd`
  cd $casedir
  casedir=`pwd`
  caselistfile=$casedir/$casename
  cd $ccurdir
fi

if [ "$push" == "1" ]; then
  commit=1
fi

# don't push yet
push=

#*** make sure repos exist and have expected branches

fdsrepo=$repo/fds
CD_REPO $fdsrepo $fdsbranch || exit 1

smvrepo=$repo/smv
CD_REPO $smvrepo $smvbranch || exit 1

botrepo=$repo/bot
CD_REPO $botrepo $botbranch || exit 1

if [ "$FIREBOT_MODE" == "validation" ]; then
  outrepo=$repo/out
  CD_REPO $outrepo master || exit 1
fi

cd $firebotdir

#*** save pid in case we want to kill firebot later

echo $$ > $PID_FILE

if [ "$showcaselist" == "1" ]; then
  show_validation_list
  exit
fi

#*** check for C/C++ compiler

IFORT_VERSION=
notfound=
if [ "$COMPILER" == "intel" ]; then
   if [[ "$IFORT_COMPILER" != "" ]] ; then
      source $IFORT_COMPILER/bin/compilervars.sh intel64
   fi
   notfound=`ifort -help 2>&1 | tail -1 | grep "not found" | wc -l`
   if [ $notfound -eq 0 ]; then
     IFORT_VERSION=`ifort -v 2>&1`
   fi
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

notfound=
if [ "QUEUE" == "none" ]; then
   notfound=`background -v 2>&1 | tail -1 | grep "not found" | wc -l`
   if [ $notfound == 1 ]; then
      echo "Error: The program background was not found.  firebot aborted"
      echo "       Add the directory containing fds and smokeview to your path"
      echo "       (same directory containing fds and smokeview)"
      echo "Error: background not found. firebot aborted." >> $OUTPUT_DIR/stage1 2>&1
      exit
   fi
fi

UploadGuides=$botrepo/Firebot/fds_guides2GD.sh

echo ""
echo "Settings"
echo "--------"
echo "     FDS repo: $fdsrepo"
echo "     SMV repo: $smvrepo"
echo "      Run dir: $firebotdir"
if [ "$IFORT_VERSION" != "" ]; then
  echo "      Fortran: $IFORT_VERSION"
fi
if [ "$CLEANREPO" == "1" ]; then
  echo "  clean repos: yes"
else
  echo "  clean repos: no"
fi
if [ "$UPDATEREPO" == "1" ]; then
  echo " update repos: yes"
else
  echo " update repos: no"
fi
if [ "$FIREBOT_MODE" == "validation" ]; then
  echo "validationbot: $MAX_VALIDATION_PROCESSES processes"
fi
echo ""


# Set time limit (43,200 seconds = 12 hours)
TIME_LIMIT=43200
TIME_LIMIT_EMAIL_NOTIFICATION="unsent"

# Disable time limit email for validation bot
if [ "$FIREBOT_MODE" == "validation" ] ; then
   TIME_LIMIT_EMAIL_NOTIFICATION="sent"
fi

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
  clean_repo2 fig master || exit 1
  clean_repo2 out master || exit 1
  clean_repo2 smv $SMVBRANCH || exit 1
fi

#*** update repos

if [[ "$UPDATEREPO" == "1" ]] ; then
  echo Updating
  update_repo exp master || exit 1
  update_repo fds $FDSBRANCH || exit 1
  update_repo fig master || exit 1
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
# if something goes wrong with the openmp inspector
# comment the following 6 lines (including 'if' and and 'fi'  lines
#if [ "$FIREBOT_MODE" == "verification" ] ; then
#  if [ "$FIREBOT_LITE" == "" ]; then
#    inspect_fds
#    check_inspect_fds
#  fi
#fi

### Stage 2b ###
compile_fds_mpi_db
check_compile_fds_mpi_db

### Stage 2d ###
if [ "$OPENMPI_GNU" != "" ]; then
  compile_fds_mpi_gnu_db
  check_compile_fds_mpi_gnu_db
fi

if [ "$FIREBOT_LITE" == "" ]; then
### Stage 2c ###
  compile_fds_mpi
  check_compile_fds_mpi

### Stage 3a ###
  if [ "$FIREBOT_MODE" == "verification" ] ; then
    compile_smv_utilities
    check_smv_utilities

### Stage 3b ###
    compile_smv_db
    check_compile_smv_db

### Stage 3c ###
    compile_smv
    check_compile_smv
  fi
fi

### Stage 4 ###

if [ "$FIREBOT_MODE" == "validation" ] ; then
  if [ "$caselistfile" == "" ]; then
    generate_validation_list
  else
    get_validation_list $caselistfile
  fi
fi

# Depends on successful FDS debug compile
if [[ $FDS_debug_success ]] ; then
  if [[ "$FIREBOT_MODE" == "verification" ]] ; then
     run_verification_cases_debug
     check_cases_debug $fdsrepo/Verification 'verification'
  else
     run_validation_cases_debug
     check_cases_debug $fdsrepo/Validation 'validation'
  fi
fi

if [ "$FIREBOT_LITE" == "" ]; then
# clean debug stage
  cd $fdsrepo
  if [[ "$CLEANREPO" == "1" ]] ; then
     if [[ "$FIREBOT_MODE" == "verification" ]] ; then
        echo "   cleaning Verification"
        clean_repo $fdsrepo/Verification $fdsbranch || exit 1
     else
        echo "   cleaning Validation"
        clean_repo $fdsrepo/Validation $fdsbranch || exit 1
     fi
  fi

### Stage 5 ###
# Depends on successful FDS compile
  if [[ $FDS_release_success ]] ; then
    if [[ "$FIREBOT_MODE" == "verification" ]] ; then
       run_verification_cases_release
       check_cases_release $fdsrepo/Verification 'final'
    else
       run_validation_cases_release
       check_cases_release $fdsrepo/Validation 'final'
       if [[ $cases_debug_success && $cases_release_success ]] ; then
         commit_validation_results
       fi
    fi
  fi

### Stage 6 ###
# Depends on successful SMV compile
  if [ "$FIREBOT_MODE" == "verification" ]; then
    if [[ "$SKIPFIGURES" == "" ]] ; then
      if [[ $smv_release_success ]] ; then
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
fi

### Stage 9 ###
if [ "$BUILD_BUNDLE" == "1" ]; then
  make_bundle
fi

### Wrap up and report results ###
set_files_world_readable
if [ "$FIREBOT_MODE" == "verification" ]; then
  save_build_status
  if [ "$FIREBOT_LITE" == "" ]; then
    archive_timing_stats
  fi
  email_build_status 'Firebot'
else
  email_build_status 'Validationbot'
fi
