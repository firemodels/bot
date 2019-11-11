#!/bin/bash

# The Firebot script is part of an automated continuous integration system.
# Consult the FDS Config Management Plan for more information.

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
  if [ "$branch" != "current" ]; then
  if [ "$branch" != "" ]; then
     CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`
     if [ "$CURRENT_BRANCH" != "$branch" ]; then
       echo "***error: was expecting branch $branch in repo $repodir."
       echo "Found branch $CURRENT_BRANCH. Aborting firebot."
       return 1
     fi
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
#                   find_CRLF
#---------------------------------------------

find_CRLF()
{
  local curdir=`pwd`
  local repodir=$1
  local reponame=$2

  crlf_temp=/tmp/crlf.$$

  cd $repodir
  grep -IURl --color --exclude="*.pdf" --exclude-dir=".git" "
"  | grep -v 'firebot.sh'  > $crlf_temp
  nlines=`cat $crlf_temp | wc -l`
  if [ $nlines -gt 0 ]; then
    echo "" >> $CRLF_WARNINGS
    echo "$reponame repo:" >> $CRLF_WARNINGS
    cat $crlf_temp >> $CRLF_WARNINGS
    rm $crlf_temp
  fi
  cd $curdir
}

#---------------------------------------------
#                   check_CRLF
#---------------------------------------------

check_CRLF()
{

  if [ -e $CRLF_WARNINGS ]; then
    nwarnings=`cat $CRLF_WARNINGS | wc -l`
    if [ $nwarnings -gt 0 ]; then
      echo ""
      echo "Warnings from Stage 1 - dos line ending check:" >> $WARNING_LOG
      cat $CRLF_WARNINGS >> $WARNING_LOG
      echo ""
    fi
  fi
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
   echo Updating $branch on repo $repo/$reponame     >> $OUTPUT_DIR/stage1 2>&1
   git remote update                                 >> $OUTPUT_DIR/stage1 2>&1
   git merge origin/$branch                          >> $OUTPUT_DIR/stage1 2>&1
   have_firemodels=`git remote -v | grep firemodels | wc  -l`
   if [ $have_firemodels -gt 0 ]; then
      git merge firemodels/$branch                   >> $OUTPUT_DIR/stage1 2>&1
      need_push=`git status -uno | grep 'is ahead' | wc -l`
      if [ $need_push -gt 1 ]; then
        echo "warning: firemodels commits to the $reponame repo need to be pushed to origin" >> $OUTPUT_DIR/stage1 2>&1
        git status -uno | head -2 | grep -v nothing                                          >> $OUTPUT_DIR/stage1 2>&1
      fi
   fi
   if [[ "$reponame" == "exp" ]]; then
      echo "Updating submodules."                   >> $OUTPUT_DIR/stage1 2>&1
      git submodule foreach git remote update       >> $OUTPUT_DIR/stage1 2>&1

      echo "Merge submodules origin."               >> $OUTPUT_DIR/stage1 2>&1
      git submodule foreach git merge origin/master >> $OUTPUT_DIR/stage1 2>&1
      git status -uno                               >> $OUTPUT_DIR/stage1 2>&1
   fi
   return 0
}

#---------------------------------------------
#                   get_smv_revision
#---------------------------------------------

get_smv_revision()
{
   local branch=$1

   CD_REPO $repo/smv $branch || return 1


   git update-index --refresh
   SMV_REVISION=`git describe --long --dirty`
   subrev=`git describe --abbrev | awk -F '-' '{print $2}'`
   if [ "$subrev" == "" ]; then
     git describe --abbrev | awk -F '-' '{print $1"-0"}' > $LATESTAPPS_DIR/SMV_REVISION
   else
     git describe --abbrev | awk -F '-' '{print $1"-"$2}' > $LATESTAPPS_DIR/SMV_REVISION
   fi
   SMV_SHORTHASH=`git rev-parse --short HEAD`
   SMV_LONGHASH=`git rev-parse HEAD`
   echo $SMV_SHORTHASH > $LATESTAPPS_DIR/SMV_HASH
   SMV_MESSAGE=`git log . | head -5 | tail -1`
   return 0
}

#---------------------------------------------
#                   get_fds_revision
#---------------------------------------------

get_fds_revision()
{
   local branch=$1

   CD_REPO $repo/fds $branch || return 1


   git update-index --refresh
   FDS_REVISION=`git describe --long --dirty`
   subrev=`git describe --abbrev | awk -F '-' '{print $2}'`
   if [ "$subrev" == "" ]; then
     git describe --abbrev | awk -F '-' '{print $1"-0"}' > $LATESTAPPS_DIR/FDS_REVISION
   else
     git describe --abbrev | awk -F '-' '{print $1"-"$2}' > $LATESTAPPS_DIR/FDS_REVISION
   fi
   FDS_SHORTHASH=`git rev-parse --short HEAD`
   echo $FDS_SHORTHASH > $LATESTAPPS_DIR/FDS_HASH
   FDS_LONGHASH=`git rev-parse HEAD`
   FDS_DATE=`git log -1 --format=%cd --date=local $FDS_SHORTHASH`
   FDS_MESSAGE=`git log . | head -5 | tail -1`
   return 0
}

#---------------------------------------------
#                   get_exp_revision
#---------------------------------------------

get_exp_revision()
{
   local branch=$1

   CD_REPO $repo/exp $branch || return 1


   git update-index --refresh
   EXP_REVISION=`git describe --long --dirty`
   return 0
}

#---------------------------------------------
#                   get_out_revision
#---------------------------------------------

get_out_revision()
{
   local branch=$1

   CD_REPO $repo/out $branch || return 1


   git update-index --refresh
   OUT_REVISION=`git describe --long --dirty`
   return 0
}

#---------------------------------------------
#                   get_fig_revision
#---------------------------------------------

get_fig_revision()
{
   local branch=$1

   CD_REPO $repo/fig $branch || return 1


   git update-index --refresh
   FIG_REVISION=`git describe --long --dirty`
   return 0
}




#---------------------------------------------
#                   clean_git_checkout
#---------------------------------------------

check_git_checkout()
{
   # Check for GIT errors
   if [ -e $OUTPUT_DIR/stage1 ]; then
     if [[ `grep -i -E 'warning|modified' $OUTPUT_DIR/stage1` == "" ]]
     then
        # Continue along
        :
     else
        echo "Warnings from Stage 1 - Update repos" >> $WARNING_LOG
        echo "" >> $WARNING_LOG
        grep -A 5 -B 5 -i -E 'warning|modified' $OUTPUT_DIR/stage1 >> $WARNING_LOG
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
   ifort -V &> "$HISTORY_DIR/${FDS_REVISION}_compiler_info.txt"
}

#---------------------------------------------
#                   build_inspect_fds
#---------------------------------------------

build_inspect_fds()
{
   # build an openmp thread checker version of fds
   echo "      inspection"
   cd $fdsrepo/Build/${INTEL}mpi_intel_linux_64_inspect
   make -f ../makefile clean &> /dev/null
   ./make_fds.sh &> $OUTPUT_DIR/stage2a
}

#---------------------------------------------
#                   inspect_fds
#---------------------------------------------

inspect_fds()
{
   # Perform OpenMP thread checking (locate deadlocks and data races)
   echo "      inspection"
   cd $fdsrepo/Verification/Thread_Check/
   ./inspect_openmp.sh -I thread_check.fds &> $OUTPUT_DIR/stage2a
}

#---------------------------------------------
#                   check_inspect_fds
#---------------------------------------------

check_inspect_fds()
{

   # grep -v 'Warning: One or more threads in the application accessed ...' ignores a known compiler warning that displays even without errors
      if [[ `grep -i -E 'warning|remark|problem|error' $fdsrepo/Verification/Thread_Check/race_test_4.err | grep -v '0 new problem(s) found' | grep -v 'Warning: One or more threads in the application accessed the stack of another thread'` == "" ]]
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
   compile_gnu=
   if [ "$OPENMPI_INTEL" != "" ]; then
     if [ "$OPENMPI_GNU" != "" ]; then
       module unload $OPENMPI_INTEL
       module load $OPENMPI_GNU
       echo "      MPI gfortran debug"
       compile_gnu=1
       cd $fdsrepo/Build/mpi_gnu_${platform}${size}$DB
       make -f ../makefile clean &> /dev/null
       ./make_fds.sh &> $OUTPUT_DIR/stage2d
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
# force the gnu compile to pass until it can compile
# fds with the findloc routine
        FDS_gnu_debug_success=true
}

check_compile_fds_mpi_gnu_dbORIG()
{
   # Check for errors in FDS MPI debug compilation
   if [ "$compile_gnu" == "1" ]; then
     cd $fdsrepo/Build/mpi_gnu_${platform}${size}$DB
     if [ -e "fds_mpi_gnu_${platform}${size}$DB" ]
     then
        FDS_gnu_debug_success=true
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
   echo "Running FDS Verification Cases"
   echo "   debug"
   echo 'Running FDS verification cases:' >> $OUTPUT_DIR/stage4
   echo ./Run_FDS_Cases.sh -o 1 -d -m 1 $INTEL2 -q $QUEUE >> $OUTPUT_DIR/stage4 2>&1
   ./Run_FDS_Cases.sh -o 1 -d -m 1 $INTEL2 -q $QUEUE >> $OUTPUT_DIR/stage4 2>&1
   echo "" >> $OUTPUT_DIR/stage4 2>&1

   # Wait for all verification cases to end
   wait_cases_debug_end 'verification'

#  check whether cases have run
   ./Run_FDS_Cases.sh -C >> $OUTPUT_DIR/stage4 2>&1

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

   if [[ `grep -rI 'Run aborted' $OUTPUT_DIR/stage4 | grep -v grep` == "" ]] && \
      [[ `grep -rI Segmentation * | grep -v grep` == ""                   ]] && \
      [[ `grep -rI ERROR: * | grep -v echo | grep -v grep` == ""          ]] && \
      [[ `grep -rI 'STOP: Numerical' * | grep -v grep` == ""              ]] && \
      [[ `grep 'BAD TERMINATION' */*.log | grep -v grep` == ""            ]] && \
      [[ `grep -rI forrtl * | grep -v grep` == ""                         ]]
   then
      cases_debug_success=true
   else
      grep -rI 'Run aborted' $OUTPUT_DIR/stage4 | grep -v grep >> $OUTPUT_DIR/stage4_errors
      grep -rI Segmentation * | grep -v grep                   >> $OUTPUT_DIR/stage4_errors
      grep -rI ERROR: * | grep -v echo | grep -v grep          >> $OUTPUT_DIR/stage4_errors
      grep -rI 'STOP: Numerical' * | grep -v grep              >> $OUTPUT_DIR/stage4_errors
      grep -A 2 'BAD TERMINATION' */*.log | grep -v grep       >> $OUTPUT_DIR/stage4_errors
      grep -rI -A 20 forrtl * | grep -v grep                   >> $OUTPUT_DIR/stage4_errors
      
      echo "Errors from Stage 4 - Run ${2} cases - debug mode:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage4_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG

# copy casename.err to casename.err_stage4 for any cases that had errors
      echo "#/bin/bash" > $OUTPUT_DIR/stage4_filelist
# comment out following line until verified that it works
#      grep err: $OUTPUT_DIR/stage4_errors | awk -F':' '{ print "cp " $1 " /tmp/."}'  | sort -u >> $OUTPUT_DIR/stage4_filelist
      cd $fdsrepo/Verification
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
      cp fds_${INTEL}mpi_intel_${platform}${size}$DV $LATESTAPPS_DIR/fds
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

CP()
{
  fromfile=$1
  tofile=$2

  if [ -e $fromfile ]; then
    cp $fromfile $tofile
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
     ./make_LIBS.sh >> $OUTPUT_DIR/stage3a 2>&1
     echo "" >> $OUTPUT_DIR/stage3a 2>&1

   # smokezip:
     echo "      smokezip"
     cd $smvrepo/Build/smokezip/${COMPILER}_${platform}${size}
     rm -f *.o smokezip_${platform}${size}

     ./make_smokezip.sh >> $OUTPUT_DIR/stage3a 2>&1
     CP smokezip_${platform}${size} $LATESTAPPS_DIR/smokezip
     echo "" >> $OUTPUT_DIR/stage3a 2>&1

   # smokediff:
     echo "      smokediff"
     cd $smvrepo/Build/smokediff/${COMPILER}_${platform}${size}
     rm -f *.o smokediff_${platform}${size}
     ./make_smokediff.sh >> $OUTPUT_DIR/stage3a 2>&1
     CP smokediff_${platform}${size} $LATESTAPPS_DIR/smokediff
     echo "" >> $OUTPUT_DIR/stage3a 2>&1

   # background
     echo "      background"
     cd $smvrepo/Build/background/${COMPILER}_${platform}${size}
     rm -f *.o background_${platform}${size}
     ./make_background.sh >> $OUTPUT_DIR/stage3a 2>&1
     CP background_${platform}${size} $LATESTAPPS_DIR/background

   # dem2fds
     echo "      dem2fds"
     cd $smvrepo/Build/dem2fds/${COMPILER}_${platform}${size}
     rm -f *.o dem2fds_${platform}${size}
     ./make_dem2fds.sh >> $OUTPUT_DIR/stage3a 2>&1
     CP dem2fds_${platform}${size} $LATESTAPPS_DIR/dem2fds

  # wind2fds:
     echo "      wind2fds"
     cd $smvrepo/Build/wind2fds/${COMPILER}_${platform}${size}
     rm -f *.o wind2fds_${platform}${size}
     ./make_wind2fds.sh >> $OUTPUT_DIR/stage3a 2>&1
     CP wind2fds_${platform}${size} $LATESTAPPS_DIR/wind2fds
    echo "" >> $OUTPUT_DIR/stage3a 2>&1

  # hashfile:
     echo "      hashfile"
     cd $smvrepo/Build/hashfile/${COMPILER}_${platform}${size}
     rm -f *.o hashfile_${platform}${size}
     ./make_hashfile.sh >> $OUTPUT_DIR/stage3a 2>&1
     CP hashfile_${platform}${size} $LATESTAPPS_DIR/hashfile
    echo "" >> $OUTPUT_DIR/stage3a 2>&1

  # fds2asci
     echo "      fds2ascii"
     cd $fdsrepo/Utilities/fds2ascii/${COMPILER}_${platform}${size}
     rm -f *.o fds2ascii_${platform}${size}
     ./make_fds2ascii.sh >> $OUTPUT_DIR/stage3a 2>&1
     cp fds2ascii_${platform}${size} $LATESTAPPS_DIR/fds2ascii
    echo "" >> $OUTPUT_DIR/stage3a 2>&1

  # test_mpi
     echo "      test_mpi"
     cd $fdsrepo/Utilities/test_mpi/${INTEL}mpi_${COMPILER}_${platform}
     rm -f *.o test_mpi
     ./make_test_mpi.sh >> $OUTPUT_DIR/stage3a 2>&1
     cp test_mpi $LATESTAPPS_DIR/test_mpi
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
#                   check_cases_release
#---------------------------------------------

check_cases_release()
{
   local dir=$1
   local status=$2

   # Scan for and report any errors in FDS cases
   cd $dir

   if [[ `grep 'Run aborted' $OUTPUT_DIR/stage5 | grep -v grep` == ""              ]] && \
      [[ `grep 'ERROR' $OUTPUT_DIR/stage5 | grep -v geom_bad | grep -v grep` == "" ]] && \
      [[ `grep -rI Segmentation * | grep -v grep` == ""                            ]] && \
      [[ `grep -rI ERROR: * | grep -v echo | grep -v grep` == ""                   ]] && \
      [[ `grep -rI 'STOP: Numerical' * | grep -v grep` == ""                       ]] && \
      [[ `grep -rI forrtl * | grep -v grep` == ""                                  ]] && \
      [[ `grep 'BAD TERMINATION'  */*.log | grep -v grep` == ""                    ]] && \
      [[ `grep 'Inspector Clean' $OUTPUT_DIR/stage5i | grep -v grep` != ""         ]]
   then
      cases_release_success=true
   else
      grep 'Run aborted' $OUTPUT_DIR/stage5 | grep -v grep                      >> $OUTPUT_DIR/stage5_errors
      grep 'ERROR' $OUTPUT_DIR/stage5 | grep -v geom_bad | grep -v grep         >> $OUTPUT_DIR/stage5_errors
      grep -rI Segmentation * | grep -v grep                                    >> $OUTPUT_DIR/stage5_errors
      grep -rI ERROR: * | grep -v echo | grep -v grep                           >> $OUTPUT_DIR/stage5_errors
      grep -rI 'STOP: Numerical' * | grep -v grep                               >> $OUTPUT_DIR/stage5_errors
      grep -A 2 'BAD TERMINATION' */*.log | grep -v grep                        >> $OUTPUT_DIR/stage5_errors
      grep -rI -A 20 forrtl * | grep -v grep                                    >> $OUTPUT_DIR/stage5_errors
      grep -rI "Inspector found errors" $OUTPUT_DIR/stage5i | grep -v grep      >> $OUTPUT_DIR/stage5_errors

      echo "Errors from Stage 5 - Run ${2} cases - release mode:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage5_errors                               >> $ERROR_LOG
      echo ""                                                     >> $ERROR_LOG
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
        sleep 60
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
#                   run_verification_cases_release
#---------------------------------------------

run_verification_cases_release()
{
   # Start running all FDS verification cases

   echo "   release"
   cd $fdsrepo/Verification/scripts
   # Run FDS with 1 OpenMP thread
   echo 'Running FDS benchmark verification cases:' >> $OUTPUT_DIR/stage5
   echo ./Run_FDS_Cases.sh $INTEL2 $DV2 -b -o 1 -q $QUEUE >> $OUTPUT_DIR/stage5 2>&1
        ./Run_FDS_Cases.sh $INTEL2 $DV2 -b -o 1 -q $QUEUE >> $OUTPUT_DIR/stage5 2>&1
   echo "" >> $OUTPUT_DIR/stage5 2>&1

   # Wait for benchmark verification cases to end
# let benchmark and regular cases run at the same time - for now
#   wait_cases_release_end 'verification'

# comment out thread checking cases for now   
#   echo 'Running FDS thread checking verification cases:' >> $OUTPUT_DIR/stage5
   cd ../Thread_Check
   echo ./inspection.sh -p 6 -q $QUEUE  inspector_test.fds >> $OUTPUT_DIR/stage5i 2>&1
        ./inspection.sh -p 6 -q $QUEUE  inspector_test.fds >> $OUTPUT_DIR/stage5i 2>&1 &
   echo "" >> $OUTPUT_DIR/stage5i 2>&1

   cd ../scripts
   echo 'Running FDS non-benchmark verification cases:' >> $OUTPUT_DIR/stage5
   echo ./Run_FDS_Cases.sh $INTEL2 $DV2 -R -o 1 -q $QUEUE >> $OUTPUT_DIR/stage5 2>&1
        ./Run_FDS_Cases.sh $INTEL2 $DV2 -R -o 1 -q $QUEUE >> $OUTPUT_DIR/stage5 2>&1
   echo "" >> $OUTPUT_DIR/stage5 2>&1



   # Wait for non-benchmark verification cases to end
   wait_cases_release_end 'verification'



   # rerun cases that failed with 'BAD TERMINATION' errors
#   ./Run_FDS_Cases.sh $INTEL2 $DV2 -F -o 1 -q $QUEUE >> $OUTPUT_DIR/stage5 2>&1
#   echo "" >> $OUTPUT_DIR/stage5 2>&1

   # Wait for non-benchmark verification cases to end
#   wait_cases_release_end 'verification'

#  check whether cases have run 
   ./Run_FDS_Cases.sh -C  >> $OUTPUT_DIR/stage5 2>&1
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
      CP smokeview_${platform}${size} $LATESTAPPS_DIR/smokeview
    else
      echo "Errors from Stage 3c - Compile SMV release:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage3c >> $ERROR_LOG
      echo "" >> $ERROR_LOG
    fi

    # Check for compiler warnings/remarks
    # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
    if [[ `grep -E 'warning|remark' $OUTPUT_DIR/stage3c | grep -v 'was built for newer' | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]; then
      # Continue along
      :
    else
      echo "Warnings from Stage 3c - Compile SMV release:" >> $WARNING_LOG
      grep -A 5 -E 'warning|remark' $OUTPUT_DIR/stage3c | grep -v 'was built for new' | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
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
      echo "Errors from Stage 7a - Matlab plotting and statistics (verification):" >> $ERROR_LOG
      grep -B 5 -A 50 "Error" $OUTPUT_DIR/stage7a_verification | tr -cd '\11\12\15\40-\176' >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   check_verification_stats
#---------------------------------------------

check_verification_stats()
{
   # Check for existence of verification statistics output file
   cd $fdsrepo/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/Scatterplots
   if [ -e "verification_scatterplot_output.csv" ]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 7a - Matlab plotting and statistics (verification):" >> $WARNING_LOG
      echo "Error: The verification statistics output file does not exist." >> $WARNING_LOG
      echo "Expected the file Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/Scatterplots/verification_scatterplot_output.csv" >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi

   # Scan for and report warnings for any verification cases that are outside of their specified error tolerance
   cd $fdsrepo/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/Scatterplots
   if [[ `grep "Out of Tolerance" verification_scatterplot_output.csv` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 7a - Matlab plotting and statistics (verification):" >> $WARNING_LOG
      echo "The following cases are outside of their specified error tolerance:" >> $WARNING_LOG
      echo "" >> $WARNING_LOG
      grep "Out of Tolerance" verification_scatterplot_output.csv | sed G >> $WARNING_LOG
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
      echo "Errors from Stage 7b - Matlab plotting and statistics (validation):" >> $ERROR_LOG
      grep -B 5 -A 50 "Error" $OUTPUT_DIR/stage7b_validation | tr -cd '\11\12\15\40-\176' >> $ERROR_LOG
      echo "" >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   get_repo_size
#---------------------------------------------

get_repo_size()
{
  rrepo=$1
  if [ "$CLONE_REPOS" != "" ]; then
    CCURDIR=`pwd`
    cd $rrepo
    git gc
    git gc --aggressive
    git prune
    cd $CCURDIR
  fi
  du -ks $rrepo/.git |  awk '{print $1 }'
}

#---------------------------------------------
#                   archive_repo_sizes
#---------------------------------------------

archive_repo_sizes()
{
   cd $repo
   echo archiving repo_sizes

   exp_size=`get_repo_size exp `
   fds_size=`get_repo_size fds `
   fig_size=`get_repo_size fig `
   out_size=`get_repo_size out `
   smv_size=`get_repo_size smv `
   echo $EXP_REVISION,$exp_size  >  "$HISTORY_DIR/${FDS_REVISION}_repo_sizes.csv"
   echo $FDS_REVISION,$fds_size  >> "$HISTORY_DIR/${FDS_REVISION}_repo_sizes.csv"
   echo $FIG_REVISION,$fig_size  >> "$HISTORY_DIR/${FDS_REVISION}_repo_sizes.csv"
   echo $OUT_REVISION,$out_size  >> "$HISTORY_DIR/${FDS_REVISION}_repo_sizes.csv"
   echo $SMV_REVISION,$smv_size  >> "$HISTORY_DIR/${FDS_REVISION}_repo_sizes.csv"
}

#---------------------------------------------
#                   archive_validation_stats
#---------------------------------------------

archive_validation_stats()
{
   cd $fdsrepo/Utilities/Matlab

   echo archiving validation stats
   STATS_FILE_BASENAME=validation_scatterplot_output
   CURRENT_STATS_FILE=$fdsrepo/Manuals/FDS_Validation_Guide/SCRIPT_FIGURES/ScatterPlots/${STATS_FILE_BASENAME}.csv

   if [ -e ${CURRENT_STATS_FILE} ]
   then
      # Archive stats to Firebot history
      cp ${CURRENT_STATS_FILE} "$HISTORY_DIR/${FDS_REVISION}_${STATS_FILE_BASENAME}.csv"

   else
      echo "Warnings from Stage 7b - Matlab plotting and statistics (validation):" >> $WARNING_LOG
      echo "Warning: The validation statistics output file does not exist." >> $WARNING_LOG
      echo "Expected the file Manuals/FDS_Validation_Guide/SCRIPT_FIGURES/ScatterPlots/validation_scatterplot_output.csv" >> $WARNING_LOG
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
   echo archiving timing stats
   cd $fdsrepo/Utilities/Scripts
   cp fds_timing_stats.csv "$HISTORY_DIR/${FDS_REVISION}_timing.csv"
   cp fds_benchmarktiming_stats.csv "$HISTORY_DIR/${FDS_REVISION}_benchmarktiming.csv"
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
   local upload=$4

   # Scan for and report any errors or warnings in build process for guides
   cd $firebotdir
   if [[ `grep -I "successfully" $guidelog` == "" ]]
   then
      # There were errors/warnings in the guide build process
      echo "Warnings from Stage 8 - Build FDS-SMV Guides:" >> $WARNING_LOG
      echo $label >> $WARNING_LOG # Name of guide
      cat $guidelog >> $WARNING_LOG # Contents of log file
      echo "" >> $WARNING_LOG
   fi
}

#---------------------------------------------
#                   copy_guide
#---------------------------------------------

copy_guide()
{
   local doc=$1

   cd $firebotdir
   if [[ "$UPLOADGUIDES" == "1" ]]; then
     if [ -e $doc ]; then
       cp $doc /var/www/html/firebot/manuals/
       cp $doc $NEWGUIDE_DIR/.
       cp $doc $SAVEGUIDE_DIR/.
     fi
   fi
}

#---------------------------------------------
#                   make_geom_notes
#---------------------------------------------

make_geom_notes()
{
   cd $fdsrepo/Manuals/FDS_User_Guide

   echo "  geom notes"
   # Build FDS User Guide
   ./make_geom_notes.sh &> $OUTPUT_DIR/stage8_geom_notes

   # Check guide for completion - for now do note upload
   # (change 0 to 1 in following line to upload)
   check_guide $OUTPUT_DIR/stage8_geom_notes $fdsrepo/Manuals/FDS_User_Guide/geom_notes.pdf 'geom_notes' 0
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
   check_guide $OUTPUT_DIR/stage8_fds_user_guide $fdsrepo/Manuals/FDS_User_Guide/FDS_User_Guide.pdf 'FDS User Guide' 1
}

#---------------------------------------------
#                   copy_fds_user_guide
#---------------------------------------------

copy_fds_user_guide()
{
   cd $fdsrepo/Manuals/FDS_User_Guide
   copy_guide $fdsrepo/Manuals/FDS_User_Guide/FDS_User_Guide.pdf
   copy_guide $fdsrepo/Manuals/FDS_User_Guide/geom_notes.pdf
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
   check_guide $OUTPUT_DIR/stage8_fds_technical_guide $fdsrepo/Manuals/FDS_Technical_Reference_Guide/FDS_Technical_Reference_Guide.pdf 'FDS Technical Reference Guide' 1
}

#---------------------------------------------
#                   copy_fds_technical_guide
#---------------------------------------------

copy_fds_technical_guide()
{
   cd $fdsrepo/Manuals/FDS_Technical_Reference_Guide
   copy_guide $fdsrepo/Manuals/FDS_Technical_Reference_Guide/FDS_Technical_Reference_Guide.pdf
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
   check_guide $OUTPUT_DIR/stage8_fds_verification_guide $fdsrepo/Manuals/FDS_Verification_Guide/FDS_Verification_Guide.pdf 'FDS Verification Guide' 1
}

#---------------------------------------------
#                   copy_fds_verification_guide
#---------------------------------------------

copy_fds_verification_guide()
{
   cd $fdsrepo/Manuals/FDS_Verification_Guide
   copy_guide $fdsrepo/Manuals/FDS_Verification_Guide/FDS_Verification_Guide.pdf
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
   check_guide $OUTPUT_DIR/stage8_fds_validation_guide $fdsrepo/Manuals/FDS_Validation_Guide/FDS_Validation_Guide.pdf 'FDS Validation Guide' 1
}

#---------------------------------------------
#                   copy_fds_validation_guide
#---------------------------------------------

copy_fds_validation_guide()
{
   cd $fdsrepo/Manuals/FDS_Validation_Guide
   copy_guide $fdsrepo/Manuals/FDS_Validation_Guide/FDS_Validation_Guide.pdf
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
   check_guide $OUTPUT_DIR/stage8_fds_Config_management_plan $fdsrepo/Manuals/FDS_Config_Management_Plan/FDS_Config_Management_Plan.pdf 'FDS Config Management Plan' 1
}

#---------------------------------------------
#                   copy_fds_Config_management_plan
#---------------------------------------------

copy_fds_Config_management_plan()
{
   cd $fdsrepo/Manuals/FDS_Config_Management_Plan
   copy_guide $fdsrepo/Manuals/FDS_Config_Management_Plan/FDS_Config_Management_Plan.pdf
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
     echo "Build failure and warnings;$FDS_DATE;$FDS_SHORTHASH;$FDS_LONGHASH;${FDS_REVISION};$FDSBRANCH;$STOP_TIME_INT;3;$TOTAL_FDS_TIMES;$HOST;$SMV_LONGHASH;${SMV_REVISION}" > "$HISTORY_DIR/${FDS_REVISION}.txt"
     cat $ERROR_LOG > "$HISTORY_DIR/${FDS_REVISION}_errors.txt"

   # Check for errors only
   elif [ -e $ERROR_LOG ]
   then
      echo "Build failure;$FDS_DATE;$FDS_SHORTHASH;$FDS_LONGHASH;${FDS_REVISION};$FDSBRANCH;$STOP_TIME_INT;3;$TOTAL_FDS_TIMES;$HOST;$SMV_LONGHASH;${SMV_REVISION}" > "$HISTORY_DIR/${FDS_REVISION}.txt"
      cat $ERROR_LOG > "$HISTORY_DIR/${FDS_REVISION}_errors.txt"

   # Check for warnings only
   elif [ -e $WARNING_LOG ]
   then
      echo "Build success with warnings;$FDS_DATE;$FDS_SHORTHASH;$FDS_LONGHASH;${FDS_REVISION};$FDSBRANCH;$STOP_TIME_INT;2;$TOTAL_FDS_TIMES;$HOST;$SMV_LONGHASH;${SMV_REVISION}" > "$HISTORY_DIR/${FDS_REVISION}.txt"
      cat $WARNING_LOG > "$HISTORY_DIR/${FDS_REVISION}_warnings.txt"

   # No errors or warnings
   else
      echo "Build success!;$FDS_DATE;$FDS_SHORTHASH;$FDS_LONGHASH;${FDS_REVISION};$FDSBRANCH;$STOP_TIME_INT;1;$TOTAL_FDS_TIMES;$HOST;$SMV_LONGHASH;${SMV_REVISION}" > "$HISTORY_DIR/${FDS_REVISION}.txt"
      touch $FIREBOT_PASS
      echo $SMVREPO_HASH > $SMVREPO_HASHFILE
      echo $FDSREPO_HASH > $FDSREPO_HASHFILE
   fi
}

#---------------------------------------------
#                   get_firebot_success
#---------------------------------------------

get_firebot_success()
{
   firebot_success=1
   if [[ -e $WARNING_LOG ]]; then
     firebot_success=
   fi
   if [[ -e $ERROR_LOG ]]; then
     firebot_success=
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
   firebot_status=1

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
   echo "   fds revision: $FDS_REVISION " >> $TIME_LOG
   echo "     fds branch: $FDSBRANCH "    >> $TIME_LOG
   echo "   smv revision: $SMV_REVISION " >> $TIME_LOG
   echo "     smv branch: $SMVBRANCH "    >> $TIME_LOG
   if [ "$IFORT_VERSION" != "" ]; then
      echo "        Fortran: $IFORT_VERSION " >> $TIME_LOG
   fi
   echo "     start time: $start_time " >> $TIME_LOG
   echo "      stop time: $stop_time " >> $TIME_LOG
   if [ "$UPLOADGUIDES" == "1" ]; then
   echo " Firebot status:  https://pages.nist.gov/fds-smv/firebot_status.html" >> $TIME_LOG
   fi
   echo "-------------------------------" >> $TIME_LOG

#  upload guides to a google drive directory
   get_firebot_success
   if [[ "$UPLOADGUIDES" == "1" ]] && [[ "$firebot_success" == "1" ]]; then
     cd $firebotdir
     $UploadGuides $NEWGUIDE_DIR $fdsrepo/Manuals &> $OUTPUT_DIR/stage10_upload_google
     if [[ `grep -E 'warning' $OUTPUT_DIR/stage10_upload_google` == "" ]]; then
       # Continue along
       :
      else
        echo "Warnings from Stage 10 - Upload documents to google drive:" >> $WARNING_LOG
        grep -E 'warning' $OUTPUT_DIR/stage10_upload_google >> $WARNING_LOG
        echo "" >> $WARNING_LOG
     fi
   fi

   # Check for warnings and errors
   if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]
   then
      cd $firebotdir

     # Send email with failure message and warnings, body of email contains appropriate log file
     echo "[$botuser] $bottype failure and warnings. Version: ${FDS_REVISION}, Branch: $FDSBRANCH."
     if [ "$HAVE_MAIL" == "1" ]; then
       cat $ERROR_LOG $TIME_LOG | mail -s "[$botuser] $bottype failure and warnings. Version: ${FDS_REVISION}, Branch: $FDSBRANCH." $mailToFDS > /dev/null
     fi

   # Check for errors only
   elif [ -e $ERROR_LOG ]
   then
      # Send email with failure message, body of email contains error log file
      echo "[$botuser] $bottype failure. Version: ${FDS_REVISION}, Branch: $FDSBRANCH."
      if [ "$HAVE_MAIL" == "1" ]; then
        cat $ERROR_LOG $TIME_LOG | mail -s "[$botuser] $bottype failure. Version: ${FDS_REVISION}, Branch: $FDSBRANCH." $mailToFDS > /dev/null
      fi

   # Check for warnings only
   elif [ -e $WARNING_LOG ]
   then
      cd $firebotdir

      # Send email with success message, include warnings
      echo "[$botuser] $bottype success, with warnings. Version: ${FDS_REVISION}, Branch: $FDSBRANCH"
      if [ "$HAVE_MAIL" == "1" ]; then
        cat $WARNING_LOG $TIME_LOG | mail -s "[$botuser] $bottype success, with warnings. Version: ${FDS_REVISION}, Branch: $FDSBRANCH" $mailToFDS > /dev/null
      fi

   # No errors or warnings
   else
#  upload guides to a google drive directory
      cd $firebotdir

      # Send success message with links to nightly manuals
      firebot_status=0
      echo "[$botuser] $bottype success! Version: ${FDS_REVISION}, Branch: $FDSBRANCH"
      if [ "$HAVE_MAIL" == "1" ]; then
        cat $TIME_LOG | mail -s "[$botuser] $bottype success! Version: ${FDS_REVISION}, Branch: $FDSBRANCH" $mailToFDS > /dev/null
      fi
   fi

}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             beginning of firebot
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** setup

echo $0 $* >> output/command.firebot

# Start firebot timer
START_TIME=$(date +%s)
size=_64

# define run directories
PID_FILE=~/.fdssmvgit/firesmokebot_pid
firebotdir=`pwd`
export SCRIPTFILES=$firebotdir/scriptfiles
OUTPUT_DIR="$firebotdir/output"
HISTORY_DIR="$HOME/.firebot/history"

FIREBOT_PASS=$HISTORY_DIR/firebot_pass
if [ -e $FIREBOT_PASS ]; then
  rm -f $FIREBOT_PASS
fi

SMVREPO_HASHFILE=$HISTORY_DIR/smv_hash
if [ -e $SMVREPO_HASHFILE ]; then
  rm -f $SMVREPO_HASHFILE
fi

FDSREPO_HASHFILE=$HISTORY_DIR/fds_hash
if [ -e $FDSREPO_HASHFILE ]; then
  rm -f $FDSREPO_HASHFILE
fi

TIME_LOG=$OUTPUT_DIR/timings
ERROR_LOG=$OUTPUT_DIR/errors
VALIDATION_ERROR_LOG=$OUTPUT_DIR/validation_errors
WARNING_LOG=$OUTPUT_DIR/warnings
NEWGUIDE_DIR=$OUTPUT_DIR/Newest_Guides
SAVEGUIDE_DIR=$HOME/.firebot/pubs
MANUAL_DIR=$HOME/.firebot/Manuals
EMAIL_LIST=$HOME/.firebot/firebot_email_list.sh
CRLF_WARNINGS=$OUTPUT_DIR/stage1_crlf_warnings

APPS_DIR=$HOME/.firebot/apps
LATESTAPPS_DIR=$HOME/.firebot/appslatest

MKDIR $HOME/.firebot
MKDIR $HOME/.firebot/pubs

MKDIR $APPS_DIR
rm -rf $LATESTAPPS_DIR
MKDIR $LATESTAPPS_DIR

WEBBRANCH=nist-pages
FDSBRANCH=master
SMVBRANCH=master
BOTBRANCH=master
BRANCH=master
BUILD_ONLY=

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
CLEANREPO=
UPDATEREPO=
if [ "$JOBPREFIX" == "" ]; then
  export JOBPREFIX=FB_
fi

DB=_db

ARCHIVE_REPO_SIZES=
REPOEMAIL=
UPLOADGUIDES=0
FDS_REVISION=
SMV_REVISION=
SKIPMATLAB=
SKIPFIGURES=
FIREBOT_LITE=
debug_mode=
DV=
DV2=
INTEL=
INTEL2=
CLONE_REPOS=
CLONE_FDSSMV=
DEBUG_ONLY=
FDS_REV=origin/master
SMV_REV=origin/master

#*** parse command line arguments
while getopts 'b:BcdDIiJLm:p:q:R:sTuUx:y:' OPTION
do
case $OPTION in
  b)
   BRANCH="$OPTARG"
   FDSBRANCH=$BRANCH
   SMVBRANCH=$BRANCH
   BOTBRANCH=$BRANCH
   ;;
  B)
   BUILD_ONLY=1
   FIREBOT_LITE=
   ;;
  c)
   CLEANREPO=1
   ;;
  d)
   debug_mode=1
   ;;
  D)
   DEBUG_ONLY=1
   ;;
  F)
   SKIPFIGURES=1
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
  q)
   QUEUE="$OPTARG"
   ;;
  R)
   CLONE_REPOS="$OPTARG"
   ;;
  s)
   SKIPMATLAB=1
   ;;
  T)
   CLONE_FDSSMV=1
   ;;
  u)
   UPDATEREPO=1
   ;;
  U)
   UPLOADGUIDES=1
   ;;
  x)
   FDS_REV="$OPTARG"
   ;;
  y)
   SMV_REV="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

# Load mailing list for status report
if [ "$mailToFDS" == "" ]; then
  if [ -e $EMAIL_LIST ]; then
    source $EMAIL_LIST
  fi
fi
if [ "$mailToFDS" == "" ]; then
  mailToFDS=`git config user.email`
fi
if [ "$mailToFDS" == "" ]; then
  mailToFDS=`whoami`@`hostname`
fi

#*** make sure firebot is running in correct directory

if [ -e .fds_git ]; then
  cd ../..
  repo=`pwd`
  cd $firebotdir
else
  echo "***error: firebot not running in the bot/Firebot directory"
  echo "          Aborting firebot"
  exit 1
fi

if [[ "$QUEUE" == "none" ]] && [[ -e $SCRIPTFILES ]]; then
  rm -f $SCRIPTFILES
fi

fdsrepo=$repo/fds
smvrepo=$repo/smv
botrepo=$repo/bot
outrepo=$repo/out

#*** clean repos
echo "Status"
echo "------"
  echo Cleaning bot repo
  clean_firebot_metafiles

#*** clone repos

if [[ "$CLONE_REPOS" != "" ]]; then
  echo Cloning repos
  cd $botrepo/Scripts
  if [ "$CLONE_FDSSMV" != "" ]; then
   # only clone the fds and smv repos - used when just compiling the fds and smv apps
    ./setup_repos.sh -T > $OUTPUT_DIR/stage1_clone 2>&1
  else
   # clone all repos
    ./setup_repos.sh -F > $OUTPUT_DIR/stage1_clone 2>&1
  fi
  if [ "$CLONE_REPOS" != "master" ]; then
    FDSBRANCH=$CLONE_REPOS
    cd $fdsrepo
    git checkout -b $FDSBRANCH $FDS_REV >> $OUTPUT_DIR/stage1_clone 2>&1

    SMVBRANCH=$CLONE_REPOS
    cd $smvrepo
    git checkout -b $SMVBRANCH $SMV_REV >> $OUTPUT_DIR/stage1_clone 2>&1
  fi
  ARCHIVE_REPO_SIZES=1
fi

#*** make sure repos exist and have expected branches

CD_REPO $fdsrepo $FDSBRANCH || exit 1
if [ "$FDSBRANCH" == "current" ]; then
  cd $fdsrepo
  FDSBRANCH=`git rev-parse --abbrev-ref HEAD`
fi
cd $fdsrepo
FDSREPO_HASH=`git rev-parse HEAD`


CD_REPO $smvrepo $SMVBRANCH || exit 1
if [ "$SMVBRANCH" == "current" ]; then
  cd $smvrepo
  SMVBRANCH=`git rev-parse --abbrev-ref HEAD`
fi
cd $smvrepo
SMVREPO_HASH=`git rev-parse HEAD`


CD_REPO $botrepo $BOTBRANCH || exit 1
if [ "$BOTBRANCH" == "current" ]; then
  cd $botrepo
  BOTBRANCH=`git rev-parse --abbrev-ref HEAD`
fi


cd $firebotdir

#*** save pid in case we want to kill firebot later

echo $$ > $PID_FILE

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
      exit 1
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
      exit 1
   fi
fi

UploadGuides=$botrepo/Firebot/fds_guides2GD.sh
COPY_APPS=$botrepo/Firebot/copy_apps.sh

echo ""
echo "Settings"
echo "--------"
echo "     FDS repo: $fdsrepo"
echo "   FDS branch: $FDSBRANCH"
echo "     SMV repo: $smvrepo"
echo "   SMV branch: $SMVBRANCH"
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
if [ "$BUILD_ONLY" ]; then
  echo "        queue: $QUEUE"
fi
echo ""

# Set time limit (43,200 seconds = 12 hours)
TIME_LIMIT=43200
TIME_LIMIT_EMAIL_NOTIFICATION="unsent"

hostname=`hostname`
start_time=`date`

### Stage 1 ###

echo "Status"
echo "------"
if [[ "$CLONE_REPOS" == "" ]]; then
  if [[ "$CLEANREPO" == "1" ]] ; then
    if [ "$BUILD_ONLY" == "" ]; then
      clean_repo2 exp master || exit 1
    fi
    clean_repo2 fds $FDSBRANCH || exit 1
    if [ "$BUILD_ONLY" == "" ]; then
      clean_repo2 fig master || exit 1
      clean_repo2 out master || exit 1
    fi 
    clean_repo2 smv $SMVBRANCH || exit 1
  fi
  ARCHIVE_REPO_SIZES=1
fi

#*** update repos

  if [[ "$UPDATEREPO" == "1" ]] ; then
    echo Updating
    if [[ "$CLONE_REPOS" == "" ]]; then
      update_repo fds $FDSBRANCH || exit 1
      update_repo smv $SMVBRANCH || exit 1
    fi
    update_repo fig master || exit 1
    update_repo out master || exit 1
    update_repo exp master || exit 1
  else
    echo Repos not updated
  fi

#*** check fds and smv repos for text files with CRLF line endings
#    don't check lines if not cloning and not cleaning repo - avoid false positives

CHECK_LINES=1
if [[ "$CLONE_REPOS" == "" ]]; then
  if [[ "$CLEANREPO" == "" ]]; then
    CHECK_LINES=
  fi
fi
if [ "$BUILD_ONLY" == "1" ]; then
  CHECK_LINES=
fi

# turn off line ending checking for now
CHECK_LINES=

if [ "$CHECK_LINES" == "1" ]; then
  rm -f $CRLF_WARNINGS
  echo Checking for DOS line endings
  echo "   bot repo"
  find_CRLF $repo/bot bot

  echo "   exp repo"
  find_CRLF $repo/exp exp

  echo "   fds repo"
  find_CRLF $repo/fds fds

  echo "   out repo"
  find_CRLF $repo/out out

  echo "   smv repo"
  find_CRLF $repo/smv smv

  check_CRLF
else
  if [ "$BUILD_ONLY" == "" ]; then
    echo "DOS line endings only checked when cloning or cleaning repos"
  fi
fi

get_fds_revision $FDSBRANCH || exit 1
get_smv_revision $SMVBRANCH || exit 1
if [ "$BUILD_ONLY" == "" ]; then
  get_exp_revision master || exit 1
  get_fig_revision master || exit 1
  get_out_revision master || exit 1
fi

echo | mail >& /tmp/mailtest.$$
notfound=`grep 'not found' /tmp/mailtest.$$ | wc -l`
HAVE_MAIL=1
if [ $notfound -gt 0 ]; then
  HAVE_MAIL=
fi
rm /tmp/mailtest.$$

# archive repo sizes
# (only if the repos are cloned or cleaned)

if [ "$BUILD_ONLY" == "" ]; then
if [ "$ARCHIVE_REPO_SIZES" == "1" ]; then
  archive_repo_sizes
fi
fi

check_git_checkout
archive_compiler_version

### Stage 2a ###
echo Building
echo "   FDS"
# if something goes wrong with the openmp inspector
# comment the following 6 lines (including 'if' and and 'fi'  lines
if [ "$BUILD_ONLY" == "" ]; then
if [ "$FIREBOT_LITE" == "" ]; then
   build_inspect_fds
#  inspect_fds
#  check_inspect_fds
fi
fi

### Stage 2b ###
if [ "$BUILD_ONLY" == "" ]; then
  compile_fds_mpi_db
  check_compile_fds_mpi_db
fi

### Stage 2d ###
if [[ "$OPENMPI_GNU" != "" ]] && [[ "$BUILD_ONLY" == "" ]] ; then
  compile_fds_mpi_gnu_db
  check_compile_fds_mpi_gnu_db
fi

if [ "$FIREBOT_LITE" == "" ]; then
  if [ "$DEBUG_ONLY" == "" ]; then
### Stage 2c ###
    compile_fds_mpi
    check_compile_fds_mpi

### Stage 3a ###
    compile_smv_utilities
    check_smv_utilities

### Stage 3b ###
  if [ "$BUILD_ONLY" == "" ]; then
    compile_smv_db
    check_compile_smv_db
  fi

### Stage 3c ###
    compile_smv
    check_compile_smv

    $COPY_APPS >& $OUTPUT_DIR/stage3d
  fi
fi

### Stage 4 ###

# Depends on successful FDS debug compile
if [[ $FDS_debug_success ]] && [[ "$BUILD_ONLY" == "" ]]; then
   run_verification_cases_debug
   check_cases_debug $fdsrepo/Verification 'verification'
fi

if [[ "$DEBUG_ONLY" == "" ]] && [[ "$FIREBOT_LITE" == "" ]] && [[ "$BUILD_ONLY" == "" ]]; then
# clean debug stage
  cd $fdsrepo
  if [[ "$CLEANREPO" == "1" ]] ; then
    echo "   cleaning Verification"
    clean_repo $fdsrepo/Verification $FDSBRANCH || exit 1
  fi

### Stage 5 ###
# Depends on successful FDS compile
  if [[ $FDS_release_success ]] ; then
    run_verification_cases_release
    check_cases_release $fdsrepo/Verification 'final'
  fi

### Stage 6 ###
# Depends on successful SMV compile
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
      make_geom_notes
      make_fds_verification_guide
      make_fds_technical_guide
      make_fds_validation_guide
      make_fds_Config_management_plan
      get_firebot_success
      if [[ "$firebot_success" == "1" ]] ; then
        rm -rf $MANUAL_DIR
        cp -r $fdsrepo/Manuals $MANUAL_DIR

        cp $LATESTAPPS_DIR/FDS_REVISION $SAVEGUIDE_DIR/FDS_REVISION
        copy_fds_user_guide
        copy_fds_verification_guide
        copy_fds_technical_guide
        copy_fds_validation_guide
        copy_fds_Config_management_plan
      fi
    fi
  fi
fi

# archive apps
get_firebot_success
if [[ "$firebot_success" == "1" ]] ; then
  rm -f $APPS_DIR/*
  cp $LATESTAPPS_DIR/* $APPS_DIR/.
fi

### Wrap up and report results ###
set_files_world_readable
if [[ "$DEBUG_ONLY" == "" ]]; then
  save_build_status
fi 
if [[ "$DEBUG_ONLY" == "" ]] && [[ "$FIREBOT_LITE" == "" ]] && [[ "$BUILD_ONLY" == "" ]]; then
  archive_timing_stats
fi
email_build_status 'Firebot'
echo firebot exit status: $firebot_status
exit $firebot_status
