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
  grep -IURl --exclude="*.pdf" --exclude="nohup.out" --exclude-dir=".git"  --exclude-dir="output" $'\r'  > $crlf_temp
  nlines=`cat $crlf_temp | wc -l`
  if [ $nlines -gt 0 ]; then
    echo ""                                                 >> $CRLF_WARNINGS
    echo "$reponame repo text files with dos line endings:" >> $CRLF_WARNINGS
    cat $crlf_temp                                          >> $CRLF_WARNINGS
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
      echo "Warnings from Stage 1 - dos line ending check" >> $WARNING_LOG
      cat $CRLF_WARNINGS                                   >> $WARNING_LOG
      echo ""                                              >> $WARNING_LOG
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
   SMV_REVISION=`git describe --abbrev=7 --long --dirty`
   echo $SMV_REVISION > $repo/fds/Manuals/SMV_REVISION
   subrev=`git describe --abbrev | awk -F '-' '{print $2}'`
   if [ "$subrev" == "" ]; then
     git describe --abbrev | awk -F '-' '{print $1"-0"}' > $LATESTAPPS_DIR/SMV_REVISION
   else
     git describe --abbrev | awk -F '-' '{print $1"-"$2"-"$3}' > $LATESTAPPS_DIR/SMV_REVISION
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
   FDS_REVISION=`git describe --abbrev=7 --long --dirty`
   echo $FDS_REVISION > $repo/fds/Manuals/FDS_REVISION
   subrev=`git describe --abbrev | awk -F '-' '{print $2}'`
   if [ "$subrev" == "" ]; then
     git describe --abbrev | awk -F '-' '{print $1"-0"}' > $LATESTAPPS_DIR/FDS_REVISION
   else
     git describe --abbrev | awk -F '-' '{print $1"-"$2"-"$3}' > $LATESTAPPS_DIR/FDS_REVISION
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
   EXP_REVISION=`git describe --abbrev=7 --long --dirty`
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
   OUT_REVISION=`git describe --abbrev=7 --long --dirty`
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
   FIG_REVISION=`git describe --abbrev=7 --long --dirty`
   return 0
}

#---------------------------------------------
#                   get_bot_revision
#---------------------------------------------

get_bot_revision()
{
   local branch=$1
   CD_REPO $repo/bot $branch || return 1

   BOT_REVISION=`git describe --abbrev=7 --long --dirty`
   return 0
}

#---------------------------------------------
#                   get_cad_revision
#---------------------------------------------

get_cad_revision()
{
   local branch=$1
   CD_REPO $repo/cad $branch || return 1

   CAD_REVISION=`git describe --abbrev=7 --long --dirty`
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
#                   compile_fds_mpi_db
#---------------------------------------------

compile_fds_mpi_db()
{
  local FDSDIR=$1
  local FDSEXE=$2
  local MPTYPE=$3
  if [ "$MPTYPE" != "" ]; then
    MPTYPE="_$MPTYPE"
  fi
   # Clean and compile FDS MPI debug
   echo "      MPI $MPTYPE Intel debug"
   cd $FDSDIR
   make -f ../makefile clean &> /dev/null
   ./make_fds.sh &> $OUTPUT_DIR/stage2b${MPTYPE}
   if [ ! -x $FDSEXE ]; then
     cd $FDSDIR
     make -f ../makefile clean &> /dev/null
     ./make_fds.sh &> $OUTPUT_DIR/stage2b${MPTYPE}
   fi
}

#---------------------------------------------
#                   check_compile_fds_mpi_db
#---------------------------------------------

check_compile_fds_mpi_db()
{
  local FDSDIR=$1
  local FDSEXE=$2
  local MPTYPE=$3
  if [ "$MPTYPE" != "" ]; then
    MPTYPE="_$MPTYPE"
  fi
   # Check for errors in FDS MPI debug compilation
  cd $FDSDIR
  if [ -x $FDSEXE ]
  then
     FDS_debug_success=true
  else
     echo "Errors from Stage 2b$MPTYPE - Compile FDS MPI$MPTYPE debug:"   >> $ERROR_LOG
     echo "The program $FDSEXE failed to build."                          >> $ERROR_LOG
     cat $OUTPUT_DIR/stage2b${MPTYPE}                                     >> $ERROR_LOG
     echo ""                                                              >> $ERROR_LOG
  fi



  START_LINE="Building impi_intel_linux"
  # The awk search for a line starting with Building impi_intel_linux* (either _db or _openmp_db)
  if [[ $(awk -v start="$START_LINE" '$0 ~ "^"start".*db$" {found=1; next} found' "$OUTPUT_DIR/stage2b${MPTYPE}" | \
        grep -E -i 'warning|remark' | \
        grep -v -e mpiifort -e mpiifx -e 'no platform load command' -e 'pointer not aligned at address' \
                -e ipo -e Referenced -e atom -e 'is now deprecated' -e 'feupdateenv is not implemented') == "" ]]; then
        # Continue along. No filtered warnings found.
	:
  else
        echo "Warnings from Stage 2b - Compile FDS MPI debug:" >> "$WARNING_LOG"
        awk -v start="$START_LINE" '$0 ~ "^"start".*db$" {found=1; next} found' "$OUTPUT_DIR/stage2b${MPTYPE}" | \
         grep -A 5 -E -i 'warning|remark' | \
         grep -v -e mpiifort -e mpiifx -e 'no platform load command' -e 'pointer not aligned at address' \
            -e ipo -e Referenced -e atom -e 'is now deprecated' -e 'feupdateenv is not implemented' >> "$WARNING_LOG"
         echo "" >> "$WARNING_LOG"
  fi
}

#---------------------------------------------
#                   compile_fds_mpi_gnu_db
#---------------------------------------------

compile_fds_mpi_gnu_db()
{
  local FDSDIR=$1
  # Clean and compile FDS MPI debug
  compile_gnu=
  if [ "$OPENMPI_INTEL" != "" ]; then
    module unload $OPENMPI_INTEL
  fi
  if [[ "$OPENMPI_GNU" != "" ]] && [[ "$GFORTRAN" != "" ]]; then
    module load $OPENMPI_GNU
    module load $GFORTRAN
    echo "      MPI gfortran debug"
    compile_gnu=1
    cd $FDSDIR
    make -f ../makefile clean &> /dev/null
    ./make_fds.sh &> $OUTPUT_DIR/stage2d
    module unload $OPENMPI_GNU
    module unload $GFORTRAN
  fi
  if [ "$OPENMPI_INTEL" != "" ]; then
    module load $OPENMPI_INTEL
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
     while          [[ `squeue | awk '{print $3 $4 $5}' | grep $(whoami) | grep $JOBPREFIX_DEBUG | grep -v 'CG$'` != '' ]]; do
        JOBS_REMAINING=`squeue | awk '{print $3 $4 $5}' | grep $(whoami) | grep $JOBPREFIX_DEBUG | grep -v 'CG$' | wc -l`
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
   cd $fdsrepo/$VERIFICATION_DEBUG/scripts
   # Run FDS with delayed stop files (with 1 OpenMP thread and 1 iteration)
   echo "Running FDS Verification Cases"
   echo "   debug"
   echo "Running FDS verification cases:"                                           >> $OUTPUT_DIR/stage4 2>&1
   echo ./Run_FDS_Cases.sh $ONETHREAD -d -m 1 $INTEL2 -q $QUEUE -j $JOBPREFIX_DEBUG >> $OUTPUT_DIR/stage4 2>&1
        ./Run_FDS_Cases.sh $ONETHREAD -d -m 1 $INTEL2 -q $QUEUE -j $JOBPREFIX_DEBUG >> $OUTPUT_DIR/stage4 2>&1
   echo ""                                                                          >> $OUTPUT_DIR/stage4 2>&1

   # Wait for all verification cases to end
   wait_cases_debug_end 'verification'

#  check whether cases have run
   ./Run_FDS_Cases.sh -C                                  -j $JOBPREFIX_DEBUG >> $OUTPUT_DIR/stage4 2>&1

   # Remove all .stop files from Verification directories (recursively)
   if [ "$CLONE_REPOS" == "" ]; then
     cd $fdsrepo/$VERIFICATION_DEBUG
     find . -name '*.stop' -exec rm -f {} \;
   fi
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

   if [[ `grep 'Run aborted'     $OUTPUT_DIR/stage4 | grep -v grep`                == "" ]] && \
      [[ `grep Segmentation      */*.err            | grep -v grep`                == "" ]] && \
      [[ `grep ERROR:        */*.err | grep -v grep | grep -v geom_bad `           == "" ]] && \
      [[ `grep ERROR:            */*.out            | grep -v grep | grep -v echo` == "" ]] && \
      [[ `grep 'BAD TERMINATION' */*.log            | grep -v grep`                == "" ]] && \
      [[ `grep forrtl            */*.err            | grep -v grep`                == "" ]]
   then
      cases_debug_success=true
   else
      grep 'Run aborted'          $OUTPUT_DIR/stage4 | grep -v grep                >> $OUTPUT_DIR/stage4_errors
      grep Segmentation           */*.err            | grep -v grep                >> $OUTPUT_DIR/stage4_errors
      grep ERROR:            */*.err  | grep -v grep | grep -v geom_bad            >> $OUTPUT_DIR/stage4_errors
      grep ERROR:                 */*.out            | grep -v grep | grep -v echo >> $OUTPUT_DIR/stage4_errors
      grep -A 2 'BAD TERMINATION' */*.log            | grep -v grep                >> $OUTPUT_DIR/stage4_errors
      grep -A 20 forrtl           */*.err            | grep -v grep                >> $OUTPUT_DIR/stage4_errors

      echo "Errors from Stage 4 - Run ${2} cases - debug mode:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage4_errors >> $ERROR_LOG
      echo "" >> $ERROR_LOG

# copy casename.err to casename.err_stage4 for any cases that had errors
      echo "#/bin/bash" > $OUTPUT_DIR/stage4_filelist
# comment out following line until verified that it works
#      grep err: $OUTPUT_DIR/stage4_errors | awk -F':' '{ print "cp " $1 " /tmp/."}'  | sort -u >> $OUTPUT_DIR/stage4_filelist
      cd $fdsrepo/$VERIFICATION_DEBUG
   fi
}

#---------------------------------------------
#                   compile_fds_mpi
#---------------------------------------------

compile_fds_mpi()
{
   # Clean and compile FDS MPI
  local FDSDIR=$1
  local FDSEXE=$2
  local MPTYPE=$3
  if [ "$MPTYPE" != "" ]; then
    MPTYPE="_$MPTYPE"
  fi
  echo "      MPI $MPTYPE Intel release"
  cd $FDSDIR
  make -f ../makefile clean &> /dev/null
  ./make_fds.sh &> $OUTPUT_DIR/stage2c${MPTYPE}
  if [ ! -x $FDSEXE ]; then
    cd $FDSDIR
    make -f ../makefile clean &> /dev/null
    ./make_fds.sh &> $OUTPUT_DIR/stage2c${MPTYPE}
  fi
}

#---------------------------------------------
#                   check_compile_fds_mpi
#---------------------------------------------

check_compile_fds_mpi()
{
   # Check for errors in FDS MPI compilation
  local FDSDIR=$1
  local FDSEXE=$2
  local MPTYPE=$3
  if [ "$MPTYPE" != "" ]; then
    MPTYPE="_$MPTYPE"
  fi
  cd $FDSDIR
  if [ -x $FDSEXE ]
  then
     FDS_release_success=true
     cp $FDSEXE $LATESTAPPS_DIR/fds${MPTYPE}
  else
     echo "Errors from Stage 2c - Compile FDS MPI${MPTYPE} release:" >> $ERROR_LOG
     echo "The program $FDSEXE failed to build."                     >> $ERROR_LOG
     cat $OUTPUT_DIR/stage2c${MPTYPE}                                >> $ERROR_LOG
     echo ""                                                         >> $ERROR_LOG
  fi

  # Check for compiler warnings/remarks
  # 'performing multi-file optimizations' and 'generating object file' are part of a normal compile
  # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
  if [[ `grep -E -i 'warning|remark' $OUTPUT_DIR/stage2c${MPTYPE} | grep -v 'no platform load command' | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file'` == "" ]]
  then
     # Continue along
     :
  else
     echo "Warnings from Stage 2c - Compile FDS MPI release:" >> $WARNING_LOG
     grep -A 5 -E -i 'warning|remark' $OUTPUT_DIR/stage2c${MPTYPE} | grep -v 'no platform load command' | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file' >> $WARNING_LOG
     echo "" >> $WARNING_LOG
  fi
}


#---------------------------------------------
#                   CP
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
#                   CHECKOUT_REPO
#---------------------------------------------

CHECKOUT_REPO()
{
 local_branch=$1
 local_repo=$2
 local_rev=$3
 local_tag=$4

 cd $local_repo
 if [ "$use_only_tags" == "" ]; then
   git checkout -b $local_branch $local_rev         >> $OUTPUT_DIR/stage1_clone 2>&1
   if [ "$local_tag" != "" ]; then
     git tag -a $local_tag -m "tag for $local_tag"  >> $OUTPUT_DIR/stage1_clone 2>&1
   fi
 else
   git checkout -b $local_branch $local_tag         >> $OUTPUT_DIR/stage1_clone 2>&1
 fi
}

#---------------------------------------------
#                   compile_smv_utilities
#---------------------------------------------

compile_smv_utilities()
{  
# smokeview libraries
  echo "   Smokeview"
  echo "      libraries"
  cd $smvrepo/Build/LIBS/${SMVCOMPILER}_${platform}${smvsize}
  ./make_LIBS.sh >> $OUTPUT_DIR/stage3a 2>&1
  echo "" >> $OUTPUT_DIR/stage3a 2>&1
    
# smokezip:
  echo "      smokezip"
  cd $smvrepo/Build/smokezip/${SMVCOMPILER}_${platform}${smvsize}
  rm -f *.o smokezip_${platform}${smvsize}

  ./make_smokezip.sh >> $OUTPUT_DIR/stage3a 2>&1
  CP smokezip_${platform}${smvsize} $LATESTAPPS_DIR/smokezip
  echo "" >> $OUTPUT_DIR/stage3a 2>&1

# smokediff:
  echo "      smokediff"
  cd $smvrepo/Build/smokediff/${SMVCOMPILER}_${platform}${smvsize}
  rm -f *.o smokediff_${platform}${smvsize}
  ./make_smokediff.sh >> $OUTPUT_DIR/stage3a 2>&1
  CP smokediff_${platform}${smvsize} $LATESTAPPS_DIR/smokediff
  echo "" >> $OUTPUT_DIR/stage3a 2>&1

# background
  echo "      background"
  cd $smvrepo/Build/background/${SMVCOMPILER}_${platform}${smvsize}
  rm -f *.o background_${platform}${smvsize}
  ./make_background.sh >> $OUTPUT_DIR/stage3a 2>&1
  CP background_${platform}${smvsize} $LATESTAPPS_DIR/background

# wind2fds:
  echo "      wind2fds"
  cd $smvrepo/Build/wind2fds/${SMVCOMPILER}_${platform}${smvsize}
  rm -f *.o wind2fds_${platform}${smvsize}
  ./make_wind2fds.sh >> $OUTPUT_DIR/stage3a 2>&1
  CP wind2fds_${platform}${smvsize} $LATESTAPPS_DIR/wind2fds
 echo "" >> $OUTPUT_DIR/stage3a 2>&1

# fds2fed
  if [ -d $smvrepo/Build/fds2fed/${SMVCOMPILER}_${platform}${smvsize} ]; then
    echo "      fds2fed"
    cd $smvrepo/Build/fds2fed/${SMVCOMPILER}_${platform}${smvsize}
    rm -f *.o fds2fed_${platform}${smvsize}
    ./make_fds2fed.sh >> $OUTPUT_DIR/stage3a 2>&1
    CP fds2fed_${platform}${smvsize} $LATESTAPPS_DIR/fds2fed
    echo "" >> $OUTPUT_DIR/stage3a 2>&1
  fi


# hashfile:
  echo "      hashfile"
  cd $smvrepo/Build/hashfile/${SMVCOMPILER}_${platform}${smvsize}
  rm -f *.o hashfile_${platform}${smvsize}
  ./make_hashfile.sh >> $OUTPUT_DIR/stage3a 2>&1
  CP hashfile_${platform}${smvsize} $LATESTAPPS_DIR/hashfile
  echo "" >> $OUTPUT_DIR/stage3a 2>&1

# fds2asci
  echo "      fds2ascii"
  cd $fdsrepo/Utilities/fds2ascii/${COMPILER}_${platform}${size}
  rm -f *.o fds2ascii_${platform}${size}
  ./make_fds2ascii.sh >> $OUTPUT_DIR/stage3a 2>&1
  if [ "$OPENMPTEST" == "" ]; then
    cp fds2ascii_${platform}${size} $LATESTAPPS_DIR/fds2ascii
  else
    cp fds2ascii_${COMPILER}_${platform}${size} $LATESTAPPS_DIR/fds2ascii
  fi
  echo "" >> $OUTPUT_DIR/stage3a 2>&1

# test_mpi
  echo "      test_mpi"
  cd $fdsrepo/Utilities/test_mpi/${MPI_TYPE}_${COMPILER}_${platform}
  rm -f *.o test_mpi
  ./make_test_mpi.sh >> $OUTPUT_DIR/stage3a 2>&1
  cp test_mpi $LATESTAPPS_DIR/test_mpi
  echo "" >> $OUTPUT_DIR/stage3a 2>&1
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
#       check_verification_cases_release
#---------------------------------------------

check_verification_cases_release()
{
   local dir=$1

   # Scan for and report any errors in FDS cases
   cd $dir

   if [[ `grep 'Run aborted'            $OUTPUT_DIR/stage5  | grep -v grep`                    == "" ]] && \
      [[ `grep 'ERROR'                  $OUTPUT_DIR/stage5  | grep -v geom_bad | grep -v grep` == "" ]] && \
      [[ `grep Segmentation             */*.err             | grep -v grep`                    == "" ]] && \
      [[ `grep ERROR:                   */*.err             | grep -v grep | grep -v geom_bad` == "" ]] && \
      [[ `grep ERROR:                   */*.out             | grep -v grep | grep -v echo`     == "" ]] && \
      [[ `grep 'BAD TERMINATION'        */*.log             | grep -v grep`                    == "" ]] && \
      [[ `grep forrtl                   */*.err             | grep -v grep`                    == "" ]]
   then
      cases_debug_success=true
   else
      grep 'Run aborted'                $OUTPUT_DIR/stage5  | grep -v grep                    >> $OUTPUT_DIR/stage5_errors
      grep 'ERROR'                      $OUTPUT_DIR/stage5  | grep -v geom_bad | grep -v grep >> $OUTPUT_DIR/stage5_errors
      grep Segmentation                 */*.err             | grep -v grep                    >> $OUTPUT_DIR/stage5_errors
      grep ERROR:                       */*.err             | grep -v grep | grep -v geom_bad >> $OUTPUT_DIR/stage5_errors
      grep ERROR:                       */*.out             | grep -v grep | grep -v echo     >> $OUTPUT_DIR/stage5_errors
      grep -A 2 'BAD TERMINATION'       */*.log             | grep -v grep                    >> $OUTPUT_DIR/stage5_errors
      grep -A 20 forrtl                 */*.err             | grep -v grep                    >> $OUTPUT_DIR/stage5_errors

      echo "Errors from Stage 5 - Run ${2} cases - release mode:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage5_errors                               >> $ERROR_LOG
      echo ""                                                     >> $ERROR_LOG
   fi
}

#---------------------------------------------
#       check_validation_cases_release
#---------------------------------------------

check_validation_cases_release()
{
   local dir=$1
   local subdir=$2

   # Scan for and report any errors in FDS cases
   cd $dir

   if [[ `grep 'Run aborted'            $OUTPUT_DIR/stage5b | grep -v grep`                    == "" ]] && \
      [[ `grep 'ERROR'                  $OUTPUT_DIR/stage5b | grep -v geom_bad | grep -v grep` == "" ]] && \
      [[ `grep Segmentation             */$subdir/*.err     | grep -v grep`                    == "" ]] && \
      [[ `grep ERROR:                   */$subdir/*.err     | grep -v grep | grep -v geom_bad` == "" ]] && \
      [[ `grep ERROR:                   */$subdir/*.out     | grep -v grep     | grep -v echo` == "" ]] && \
      [[ `grep 'BAD TERMINATION'        */$subdir/*.log     | grep -v grep`                    == "" ]] && \
      [[ `grep forrtl                   */$subdir/*.err     | grep -v grep`                    == "" ]]
   then
      cases_debug_success=true
   else
      grep 'Run aborted'                $OUTPUT_DIR/stage5b | grep -v grep                    >> $OUTPUT_DIR/stage5b_errors
      grep 'ERROR'                      $OUTPUT_DIR/stage5b | grep -v geom_bad | grep -v grep >> $OUTPUT_DIR/stage5b_errors
      grep Segmentation                 */$subdir//*.err    | grep -v grep                    >> $OUTPUT_DIR/stage5b_errors
      grep ERROR:                       */$subdir//*.err    | grep -v grep | grep -v geom_bad >> $OUTPUT_DIR/stage5b_errors
      grep ERROR:                       */$subdir/*.out     | grep -v grep     | grep -v echo >> $OUTPUT_DIR/stage5b_errors
      grep -A 2 'BAD TERMINATION'       */$subdir/*.log     | grep -v grep                    >> $OUTPUT_DIR/stage5b_errors
      grep -A 20 forrtl                 */$subdir/*.err     | grep -v grep                    >> $OUTPUT_DIR/stage5b_errors

      echo "Errors from Stage 5b - Run ${2} cases - release mode:" >> $ERROR_LOG
      cat $OUTPUT_DIR/stage5b_errors                               >> $ERROR_LOG
      echo ""                                                      >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   wait_cases_release_end
#---------------------------------------------

wait_cases_release_end()
{
   CASETYPE=$1
   STAGE=$2

   current_wait_dir=`pwd`
   rm -f $TIMING_ERRORS
   timing_error=

   # Scans squeue and waits for cases to end
   if [[ "$QUEUE" == "none" ]]
   then
     while [[          `ps -u $USER -f | fgrep .fds | grep -v firebot | grep -v grep` != '' ]]; do
        JOBS_REMAINING=`ps -u $USER -f | fgrep .fds | grep -v firebot | grep -v grep | wc -l`

        echo "Waiting for ${JOBS_REMAINING} $CASETYPE cases to complete." >> $OUTPUT_DIR/$STAGE
        TIME_LIMIT_STAGE="$STAGE"
        check_time_limit
        sleep 60
     done
   else
     while          [[ `squeue | awk '{print $3 $4 $5}' | grep $(whoami) | grep $JOBPREFIX_RELEASE | grep -v 'CG$'` != '' ]]; do
        JOBS_REMAINING=`squeue | awk '{print $3 $4 $5}' | grep $(whoami) | grep $JOBPREFIX_RELEASE | grep -v 'CG$' | wc -l`
        echo "Waiting for ${JOBS_REMAINING} $CASETYPE cases to complete." >> $OUTPUT_DIR/$STAGE
        TIME_LIMIT_STAGE="5"
        check_time_limit
        sleep 60
        # look for cases that took too long to run (but don't look again until firebot
        #                                           wraps up if a problem case is found)
        if [[ "$timing_error" == "" ]] && [[ "$HAVE_MAIL" == "1" ]]; then
          cd $botrepo/Scripts
          ./compare_fds_timings.sh >& /dev/null
          if [ -e $TIMING_ERRORS ]; then
            timing_error=1
            cat $TIMING_ERRORS | mail -s "[$botuser] ***error: one or more firebot case runtimes > 2x reference values" $mailToFDS > /dev/null
          fi
          cd $current_wait_dir
        fi
     done
   fi
}

#---------------------------------------------
#                   run_verification_cases_release
#---------------------------------------------

run_VV_cases_release()
{
   # run all FDS verification cases

   if [ "$CHECK_CLUSTER" == "" ]; then
     echo "   release"
   fi
   cd $fdsrepo/Verification/scripts
   # Run FDS with 1 OpenMP thread

   if [[ "$OPENMPTEST" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
     echo "Running FDS benchmark verification cases:"                              >> $OUTPUT_DIR/stage5 2>&1
     echo ./Run_FDS_Cases.sh $INTEL2 -b $ONETHREAD -q $QUEUE -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5 2>&1
     ./Run_FDS_Cases.sh $INTEL2 -b $ONETHREAD      -q $QUEUE -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5 2>&1
     echo ""                                                                       >> $OUTPUT_DIR/stage5 2>&1
   fi

   # Wait for benchmark verification cases to end
# let benchmark and regular cases run at the same time - for now
#   wait_cases_release_end verification stage5

   if [[ "$CHECK_CLUSTER" == "" ]]; then
     cd $fdsrepo/Verification/scripts
     if [[ "$OPENMPTEST" == "" ]]; then
       echo "Running FDS non-benchmark verification cases:"                         >> $OUTPUT_DIR/stage5 2>&1
     else
       echo "Running FDS verification cases:"                                       >> $OUTPUT_DIR/stage5 2>&1
     fi
     echo ./Run_FDS_Cases.sh $INTEL2 $REGULARCASES $ONETHREAD -q $QUEUE -j $JOBPREFIX_RELEASE  >> $OUTPUT_DIR/stage5 2>&1
     cd $fdsrepo/Verification/scripts
     ./Run_FDS_Cases.sh      $INTEL2 $REGULARCASES $ONETHREAD -q $QUEUE -j $JOBPREFIX_RELEASE  >> $OUTPUT_DIR/stage5 2>&1
     echo ""                                                                        >> $OUTPUT_DIR/stage5 2>&1
   fi

   # run all FDS validation cases 1 time step
   RUN_VAL=
   if [[ "$VALIDATION" != "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
     RUN_VAL=1
     echo "Running FDS Validation Cases (1 time step)"
     echo "   release"
     cd $fdsrepo/Validation

     echo 'Running FDS validation cases:'                             >> $OUTPUT_DIR/stage5b 2>&1
     echo ./Run_Serial.sh   -j $JOBPREFIX_RELEASE -m 1 -q $QUEUE      >> $OUTPUT_DIR/stage5b 2>&1
          ./Run_Serial.sh   -j $JOBPREFIX_RELEASE -m 1 -q $QUEUE      >> $OUTPUT_DIR/stage5b 2>&1
     echo ./Run_Parallel.sh -j $JOBPREFIX_RELEASE -m 1 -q $QUEUE      >> $OUTPUT_DIR/stage5b 2>&1
          ./Run_Parallel.sh -j $JOBPREFIX_RELEASE -m 1 -q $QUEUE      >> $OUTPUT_DIR/stage5b 2>&1
     echo ""                                                          >> $OUTPUT_DIR/stage5b 2>&1
   fi

# run validation case in FDS_Val_Cases.sh
   if [[ "$VALIDATION" != "" ]] && [[ "$CHECK_CLUSTER" != "" ]]; then
     RUN_VAL=1
     echo "Running FDS Validation Cases (1 time step)"
     echo "   release"
     cd $fdsrepo/Verification/scripts
     echo ./Run_FDS_Cases.sh -V -j $JOBPREFIX_RELEASE -m 1 -q $QUEUE  >> $OUTPUT_DIR/stage5b 2>&1
          ./Run_FDS_Cases.sh -V -j $JOBPREFIX_RELEASE -m 1 -q $QUEUE  >> $OUTPUT_DIR/stage5b 2>&1
     echo ""                                                          >> $OUTPUT_DIR/stage5b 2>&1
   fi

   if [ "$RUN_VAL" == "1" ]; then
   # Wait for non-benchmark verification cases to end
     wait_cases_release_end validation stage5b
   fi

   # Wait for non-benchmark verification cases to end
   wait_cases_release_end verification stage5

   # run restart cases (after regulcar cases have finished)
   if [[ -e $fdsrepo/Verification/FDS_RESTART_Cases.sh ]] && [[ "$CHECK_CLUSTER" == "" ]] ; then
     echo "   release (restart)"

     echo ""                                        i                        >> $OUTPUT_DIR/stage5 2>&1
     echo 'Running FDS restart verification cases:'                          >> $OUTPUT_DIR/stage5 2>&1
     echo ./Run_FDS_Cases.sh $INTEL2 -r $ONETHREAD -q $QUEUE -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5 2>&1
     cd $fdsrepo/Verification/scripts
          ./Run_FDS_Cases.sh $INTEL2 -r $ONETHREAD -q $QUEUE -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5 2>&1
     echo ""                                                                 >> $OUTPUT_DIR/stage5 2>&1

     # Wait for restart verification cases to end
     wait_cases_release_end verification stage5
   fi

#  check whether cases have run 
if [[ "$CHECK_CLUSTER" == "" ]] ; then
  cd $fdsrepo/Verification/scripts
  echo ./Run_FDS_Cases.sh -C -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5 2>&1
       ./Run_FDS_Cases.sh -C -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5 2>&1
fi

if [[ "$VALIDATION" != "" ]] && [[ "$CHECK_CLUSTER" == "" ]] ; then
  cd $fdsrepo/Validation
  echo ./Run_Serial.sh   -C -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5b 2>&1
       ./Run_Serial.sh   -C -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5b 2>&1
  echo ./Run_Parallel.sh -C -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5b 2>&1
       ./Run_Parallel.sh -C -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5b 2>&1
fi

if [[ "$VALIDATION" != "" ]] && [[ "$CHECK_CLUSTER" != "" ]] ; then
     cd $fdsrepo/Verification/scripts
  echo ./Run_FDS_Cases.sh -V -C -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5b 2>&1
       ./Run_FDS_Cases.sh -V -C -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5b 2>&1
  echo ""                       >> $OUTPUT_DIR/stage5b 2>&1
fi
}

#---------------------------------------------
#                   compile_smv_db
#---------------------------------------------

compile_smv_db()
{
# Clean and compile SMV debug
  echo "      debug"
  cd $smvrepo/Build/smokeview/${SMVCOMPILER}_${platform}${smvsize}
  ./make_smokeview_db.sh &> $OUTPUT_DIR/stage3b
}

#---------------------------------------------
#                   check_compile_smv_db
#---------------------------------------------

check_compile_smv_db()
{
# Check for errors in SMV debug compilation
 cd $smvrepo/Build/smokeview/${COMPILER}_${platform}${smvsize}
 if [ -e "smokeview_${platform}${smvsize}_db" ]; then
   smv_debug_success=true
 else
   echo "Errors from Stage 3b - Compile SMV debug:" >> $ERROR_LOG
   cat $OUTPUT_DIR/stage3b >> $ERROR_LOG
   echo "" >> $ERROR_LOG
 fi

 # Check for compiler warnings/remarks
 # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
 if [[ `grep -E -i 'warning' $OUTPUT_DIR/stage3b | grep -v 'feupdateenv is not implemented' | grep -i -v SUN | grep -i -v generated | grep -i -v cmake | grep -v -i CUDA | grep -i -v VectorArray | grep -v 18020 | grep -v 'was built for newer' | grep -v 'lcilkrts linked'` == "" ]]; then
   # Continue along
   :
 else
   echo "Warnings from Stage 3b - Compile SMV debug:" >> $WARNING_LOG
   grep -A 5 -E -i 'warning' $OUTPUT_DIR/stage3b | grep -v 'feupdateenv is not implemented' | grep -i -v SUN | grep -i -v generated | grep -i -v cmake | grep -v -i CUDA | grep -i -v VectorArray | grep -v 18020 | grep -v 'was built for newer' | grep -v 'lcilkrts linked' >> $WARNING_LOG
   echo "" >> $WARNING_LOG
 fi
}

#---------------------------------------------
#                    comple_smv
#---------------------------------------------

compile_smv()
{
   # Clean and compile SMV
  echo "      release"
  cd $smvrepo/Build/smokeview/${SMVCOMPILER}_${platform}${smvsize}
  echo "" > $OUTPUT_DIR/stage3c 2>&1
  ./make_smokeview.sh >> $OUTPUT_DIR/stage3c 2>&1
}

#---------------------------------------------
#                   check_compile_smv
#---------------------------------------------

check_compile_smv()
{
  # Check for errors in SMV release compilation
  smv_errors=
  cd $smvrepo/Build/smokeview/${SMVCOMPILER}_${platform}${smvsize}
  if [ -e "smokeview_${platform}${smvsize}" ]; then
    smv_release_success=true
    CP smokeview_${platform}${smvsize} $LATESTAPPS_DIR/smokeview
  else
    smv_errors=1
    echo "Errors from Stage 3c - Compile SMV release:" >> $ERROR_LOG
    cat $OUTPUT_DIR/stage3c >> $ERROR_LOG
    echo "" >> $ERROR_LOG
  fi

  # Check for compiler warnings/remarks
  # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
  if [[ `grep -E -i 'warning' $OUTPUT_DIR/stage3c | grep -v 'was built for newer' | grep -i -v SUN | grep -i -v generated | grep -i -v cmake | grep -v -i CUDA | grep -i -v VectorArray | grep -v 18020 | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]; then
    # Continue along
    :
  else
    echo "Warnings from Stage 3c - Compile SMV release:" >> $WARNING_LOG
    grep -A 5 -E -i 'warning' $OUTPUT_DIR/stage3c | grep -v 'was built for newer' | grep -i -v SUN | grep -i -v generated | grep -i -v cmake | grep -v -i CUDA | grep -i -v VectorArray | grep -v 18020 | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
    echo "" >> $WARNING_LOG
  fi
  smv_release_success=true
}

#---------------------------------------------
#                   make_fds_pictures
#---------------------------------------------

make_fds_pictures()
{
   # Run Make FDS Pictures script
   echo Generating FDS images
   cd $fdsrepo/Verification/scripts
   ./Make_FDS_Pictures.sh &> $OUTPUT_DIR/stage6
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
   if [[ `grep -i -I -E "Warning" $OUTPUT_DIR/stage6 | grep -v 'known incorrect'`  == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 6 - Make FDS pictures:" >> $WARNING_LOG
      grep -A 1 -i -I -E "Warning" $OUTPUT_DIR/stage6 | grep -v 'known incorrect' >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
}
#---------------------------------------------
#                   run_python_setup
#---------------------------------------------

run_python_setup()
{
   echo Python
   echo "   setup environment"
   cd $botrepo/Firebot/
   source ./setup_python3.sh > $OUTPUT_DIR/stage7_python_setup 2>&1
}

#---------------------------------------------
#                   check_python_setup
#---------------------------------------------

check_python_setup()
{
   # Check that python environment has been setup
   python_success=true
   if [[ `grep "Error" $OUTPUT_DIR/stage7_python_setup` != "" ]]; then
     python_success=false
   fi
   if [[ `grep "Hello World" $OUTPUT_DIR/stage7_python_setup` == "" ]]; then
     python_success=false
   fi
   if [ $python_success == false ]; then
      echo "Errors from Stage 7 - Python failed to be setup" >> $FYI_LOG
      grep "Error" $OUTPUT_DIR/stage7_python_setup           >> $FYI_LOG
      if [[ `grep "Hello World" $OUTPUT_DIR/stage7_python_setup` == "" ]]; then
        echo "python hello world script failed to run"       >> $FYI_LOG
     fi
   fi
}

#---------------------------------------------
#                   run_python_verification
#---------------------------------------------

run_python_verification()
{
   echo Python verification plots
   cd $fdsrepo/Utilities/Python
   python FDS_verification_script.py > $OUTPUT_DIR/stage7a_python_verification 2>&1
}

#---------------------------------------------
#                   check_python_verification
#---------------------------------------------

check_python_verification()
{
   # Check that python environment has been setup
   python_verification_success=true
   if [[ `grep "Error" $OUTPUT_DIR/stage7a_python_verification` != "" ]]; then
     python_verification_success=false
   fi
   # if [[ `grep "Hello World" $OUTPUT_DIR/stage7a_python_verification` == "" ]]; then
   #   python_verification_success=false
   # fi
   if [ $python_verification_success == false ]; then
     echo "Errors from Stage 7a - Python plotting and statistics (verification):"                 >> $FYI_LOG
     grep -B 5 -A 50 "Error" $OUTPUT_DIR/stage7a_python_verification | tr -cd '\11\12\15\40-\176' >> $FYI_LOG
     echo "" >> $ERROR_LOG
   fi
}

#---------------------------------------------
#                   run_python_validation
#---------------------------------------------

run_python_validation()
{
   echo Python validation plots
   cd $fdsrepo/Utilities/Python
   python hello_world.py > $OUTPUT_DIR/stage7b_python_validation 2>&1
}

#---------------------------------------------
#                   check_python_verification
#---------------------------------------------

check_python_validation()
{
   # Check that python environment has been setup
   python_validation_success=true
   if [[ `grep "Error" $OUTPUT_DIR/stage7b_python_validation` != "" ]]; then
     python_validation_success=false
   fi
   if [[ `grep "Hello World" $OUTPUT_DIR/stage7b_python_validation` == "" ]]; then
     python_validation_success=false
   fi
   if [ $python_validation_success == false ]; then
     echo "Errors from Stage 7b - Python plotting and statistics (validation):" >> $ERROR_LOG
     grep -B 5 -A 50 "Error" $OUTPUT_DIR/stage7b_python_validation | tr -cd '\11\12\15\40-\176' >> $ERROR_LOG
     echo "" >> $ERROR_LOG
    fi
}

#---------------------------------------------
#                   run_matlab_license_test
#---------------------------------------------

run_matlab_license_test()
{
# uncomment following DEBUG lines to generate matlab debug info (and comment matlab line without DEBUG)
#   DEBUG="strace -t -T -f -e trace=network -o $OUTPUT_DIR/stage7_matlab_strace"
   echo Matlab
   echo "   license test"
   # Run simple test to see if Matlab license is available
   cd $fdsrepo/Utilities/Matlab
   date -Iseconds &> $OUTPUT_DIR/stage7_matlab_license
#   $DEBUG matlab -nodisplay -r "try, disp('Running Matlab License Check'), catch, disp('License Error'), err = lasterror, err.message, err.stack, end, exit" >> $OUTPUT_DIR/stage7_matlab_license 2>&1
   date -Iseconds >> $OUTPUT_DIR/stage7_matlab_license 2>&1
   matlab -nodisplay -r "try, disp('Running Matlab License Check'), catch, disp('License Error'), err = lasterror, err.message, err.stack, end, exit" &> $OUTPUT_DIR/stage7_matlab_license
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
   matlab -help  >& /tmp/matlabtest.$$
   notfound=`grep 'command not found' /tmp/matlabtest.$$ | wc -l`
   if [ $notfound -gt 0 ]; then
     module load matlab
   fi
   rm /tmp/matlabtest.$$
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
   echo "   matlab verification plots"
   # Run Matlab plotting script
   cd $fdsrepo/Utilities/Matlab
   matlab -nodisplay -r "try, disp('Running Matlab Verification script'), FDS_verification_script, catch, disp('Error'), err = lasterror, err.message, err.stack, end, exit" &> $OUTPUT_DIR/stage7a_verification
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
#                   check_validation_stats
#---------------------------------------------

check_validation_stats()
{
# fds/Manuals/FDS_Validation_Guide/SCRIPT_FIGURES/ScatterPlots/validation_git_stats.tex
   # Check for existence of verification statistics output file
   cd $fdsrepo/Manuals/FDS_Validation_Guide/SCRIPT_FIGURES/ScatterPlots
   if [ -e "validation_git_stats.tex" ]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 7b - Matlab plotting and statistics (validation):" >> $WARNING_LOG
      echo "Error: The validation statistics output file does not exist." >> $WARNING_LOG
      echo "Expected the file Manuals/FDS_Validation_Guide/SCRIPT_FIGURES/ScatterPlots/validation_git_stats.tex" >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi

   # Scan for the string dirty
   cd $fdsrepo/Manuals/FDS_Validation_Guide/SCRIPT_FIGURES/ScatterPlots
   if [[ `grep "dirty" validation_git_stats.tex` == "" ]]
   then
      # Continue along
      :
   else
      echo "Warnings from Stage 7b - Matlab plotting and statistics (validation):" >> $WARNING_LOG
      echo "The following table entries are dirty:" >> $WARNING_LOG
      echo "" >> $WARNING_LOG
      grep "dirty" validation_git_stats.tex >> $WARNING_LOG
      echo "" >> $WARNING_LOG
   fi
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
  local __var=$3

  DELTA_TIME=`echo $(($time_after-$time_before))`
  TIME_H=`echo $(($DELTA_TIME / 3600 ))`
  TIME_M=`echo $((($DELTA_TIME % 3600 ) / 60))`
  TIME_S=`echo $(($DELTA_TIME % 60 ))`
  if (( "$DELTA_TIME" >= 3600 )) ; then
    DIFF_TIME="${TIME_H}h ${TIME_M}m ${TIME_S}s"
  else
    if (( "$DELTA_TIME" >= 60 )) ; then
      DIFF_TIME="${TIME_M}m ${TIME_S}s"
    else
      DIFF_TIME="${TIME_S}s"
    fi
  fi
  eval ${__var}_DIFF="'${DIFF_TIME}'"
  eval ${__var}_DELTA="'${DELTA_TIME}'"
}

#---------------------------------------------
#                   run_matlab_validation
#---------------------------------------------

run_matlab_validation()
{
   echo "   validation plots"
   # Run Matlab plotting script
   cd $fdsrepo/Utilities/Matlab
   matlab -nodisplay -r "try, disp('Running Matlab Validation script'), FDS_validation_script, catch, disp('Error'), err = lasterror, err.message, err.stack, end, exit" &> $OUTPUT_DIR/stage7b_validation
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
   cad_size=`get_repo_size cad `
   echo $CAD_REVISION,$cad_size  >  "$HISTORY_DIR/${FDS_REVISION}_repo_sizes.csv"
   echo $EXP_REVISION,$exp_size  >> "$HISTORY_DIR/${FDS_REVISION}_repo_sizes.csv"
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
   cd $botrepo/Firebot/Scripts
   ./validation_git_stats.sh -r $repo
}

#---------------------------------------------
#                   generate_timing_stats
#---------------------------------------------

generate_timing_stats()
{
   cd $fdsrepo/Utilities/Scripts
   ./fds_timing_stats.sh           > fds_timing_stats.csv
   TOTAL_FDS_TIMES=`tail -1 fds_timing_stats.csv`
   echo "$TOTAL_FDS_TIMES"     > $LATESTAPPS_DIR/fds_total_time.txt

   cd $fdsrepo/Utilities/Scripts
   ./fds_timing_stats.sh firebot 1 > fds_benchmarktiming_stats.csv
}

#---------------------------------------------
#                   archive_timing_stats
#---------------------------------------------

archive_timing_stats()
{
   echo archiving timing stats
   cd $fdsrepo/Utilities/Scripts
   cp fds_timing_stats.csv "$HISTORY_DIR/${FDS_REVISION}_timing.csv"
   sort -r -k 2 -t  ',' -n fds_timing_stats.csv | head -10 | awk -F',' '{print $1":", $2}' > $OUTPUT_DIR/slow_cases

# output firebot timing info
# The offset below is computed by substituting
# Jan 1, 2016 5 UTC (12 AM EST) into a web form
# found at: http://www.unixtimestamp.com/
   CURRENTDIR=`pwd`
   cd $fdsrepo
   BASETIMESTAMP=1451624400
   gitdate=`git show -s --format=%ct $FDS_SHORTHASH`
   gitdate=`echo "scale=5; $gitdate - $BASETIMESTAMP" | bc`
   gitdate=`echo "scale=5; $gitdate/86400 " | bc`
   cd $CURRENTDIR

   if [ ! -e $HISTORY_DIR/firebot_times.csv ]; then
     echo "day,date,revision,pass/fail,clone,setup,build,debug,release,picture,matlab,manuals,total" > $HISTORY_DIR/firebot_times.csv
     echo ",,,,s,s,s,s,s,s,s,s,s" >> $HISTORY_DIR/firebot_times.csv
   fi
   echo $gitdate,$FDS_DATE,$FDS_REVISION,$firebot_success,$CLONE_DELTA,$SETUP_DELTA,$BUILD_DELTA,$DEBUG_DELTA,$RELEASE_DELTA,$PICTURE_DELTA,$MATLAB_DELTA,$MANUALS_DELTA,$SCRIPT_DELTA >> $HISTORY_DIR/firebot_times.csv

   cp fds_benchmarktiming_stats.csv "$HISTORY_DIR/${FDS_REVISION}_benchmarktiming.csv"
   cp fds_timing_stats.csv          "$HISTORY_DIR/${FDS_REVISION}_timing.csv"
   TOTAL_FDS_TIMES=`tail -1 fds_timing_stats.csv`
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
   local label=$2

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
       cp $doc $PUBS_DIR/.
     fi
   fi
   if [ -e $doc ]; then
     if [ -d $FDS_SUMMARY_DIR/manuals ]; then
       cp $doc $FDS_SUMMARY_DIR/manuals/.
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

   # Check guide for completion
   check_guide $OUTPUT_DIR/stage8_geom_notes 'geom_notes'
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

   # Check guide for completion
   check_guide $OUTPUT_DIR/stage8_fds_user_guide 'FDS User Guide'

   cd $botrepo/Firebot
   ./compare_namelists.sh $OUTPUT_DIR stage8 > $OUTPUT_DIR/stage8_namelist_check
   NAMELIST_NODOC_STATUS=`cat $OUTPUT_DIR/stage8_namelist_check | head -1 | awk -F' ' '{print $1}'`
   if [ "$NAMELIST_NODOC_STATUS" != "0" ]; then
     NAMELIST_NODOC_LOG=$OUTPUT_DIR/stage8_namelists_nodoc.txt
   fi
   NAMELIST_NOSOURCE_STATUS=`cat $OUTPUT_DIR/stage8_namelist_check | tail -1 | awk -F' ' '{print $1}'`
   if [ "$NAMELIST_NOSOURCE_STATUS" != "0" ]; then
     NAMELIST_NOSOURCE_LOG=$OUTPUT_DIR/stage8_namelists_nosource.txt
   fi
}

#---------------------------------------------
#                   copy_fds_user_guide
#---------------------------------------------

copy_fds_user_guide()
{
   cd $fdsrepo/Manuals/FDS_User_Guide
   copy_guide $fdsrepo/Manuals/FDS_User_Guide/FDS_User_Guide.pdf
#   copy_guide $fdsrepo/Manuals/FDS_User_Guide/geom_notes.pdf
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

   # Check guide for completion
   check_guide $OUTPUT_DIR/stage8_fds_technical_guide 'FDS Technical Reference Guide'
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

   # Check guide for completion
   check_guide $OUTPUT_DIR/stage8_fds_verification_guide 'FDS Verification Guide'
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

   # Check guide for completion
   check_guide $OUTPUT_DIR/stage8_fds_validation_guide 'FDS Validation Guide'
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

   # Check guide for completion
   check_guide $OUTPUT_DIR/stage8_fds_Config_management_plan 'FDS Config Management Plan'
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
     firebot_success=0
   fi
   if [[ -e $ERROR_LOG ]]; then
     firebot_success=0
   fi
}

#---------------------------------------------
#                   make_fds_summary
#---------------------------------------------

make_fds_summary()
{
  if [ -d $FDS_SUMMARY_DIR ]; then
    cp $fdsrepo/Manuals/FDS_User_Guide/SCRIPT_FIGURES/*.png         $FDS_SUMMARY_DIR/images/user/.
    cp $fdsrepo/Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/*.png $FDS_SUMMARY_DIR/images/verification/.
    DATE=`date +"%b %d, %Y - %r"`

# compare images

    CURDIR=`pwd`
    cd $botrepo/Firebot
    ./compare_images.sh $FDS_SUMMARY_DIR/images $FDS_SUMMARY_DIR/diffs/images $OUTPUT_DIR/error_images >& $OUTPUT_DIR/stage8_image_compare

# look for fyis
    if [[ `grep '***fyi:' $OUTPUT_DIR/stage8_image_compare` == "" ]]
    then
      # Continue along
      :
    else
      echo "FYIs from Stage 8 - Image comparisons:"     >> $FYI_LOG
      grep '***fyi:' $OUTPUT_DIR/stage8_image_compare   >> $FYI_LOG
    fi

# look for warnings
    if [[ `grep '***warning:' $OUTPUT_DIR/stage8_image_compare` == "" ]]
    then
      # Continue along
      :
    else
      echo "Warnings from Stage 8 - Image comparisons:"     >> $WARNING_LOG
      grep '***warning:' $OUTPUT_DIR/stage8_image_compare   >> $WARNING_LOG
    fi
    
    if [ "$WEB_DIR" != "" ]; then
      if [ -d $WEB_DIR ]; then
        CUR_DIR=`pwd`
        cd $WEB_DIR
        rm -r images manuals diffs *.html
        cp -r $FDS_SUMMARY_DIR/* .
        rm *template.html
        cd $CUR_DIR
        UPDATED_WEB_IMAGES=1
      fi
    fi
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
   if [ "$BUILD_ONLY" == "1" ]; then
     echo "build only apps"                                 >> $TIME_LOG
   fi
   echo "host: $hostname "                                  >> $TIME_LOG
   echo "OS: $platform2 "                                   >> $TIME_LOG
   echo "repo: $repo "                                      >> $TIME_LOG
   echo "queue: $QUEUE "                                    >> $TIME_LOG
   if [ "$IFORT_VERSION" != "" ]; then
      echo "Fortran: $IFORT_VERSION "                       >> $TIME_LOG
   fi
   echo ""                                                  >> $TIME_LOG
   echo "bot: $BOT_REVISION/$BOTBRANCH "    >> $TIME_LOG
   if [ "$CAD_REVISION" != "" ]; then
     echo "cad: $CAD_REVISION/$CADBRANCH  " >> $TIME_LOG
   fi
   if [ "$EXP_REVISION" != "" ]; then
     echo "exp: $EXP_REVISION/$EXPBRANCH "    >> $TIME_LOG
   fi
   echo "fds: $FDS_REVISION/$FDSBRANCH "    >> $TIME_LOG
   if [ "$FIG_REVISION" != "" ]; then
     echo "fig: $FIG_REVISION/$FIGBRANCH "    >> $TIME_LOG
   fi
   if [ "$OUT_REVISION" != "" ]; then
     echo "out: $OUT_REVISION/$OUTBRANCH "    >> $TIME_LOG
   fi
   echo "smv: $SMV_REVISION/$SMVBRANCH "    >> $TIME_LOG
   echo ""                                                  >> $TIME_LOG
   echo "start time: $start_time "                          >> $TIME_LOG
   echo "stop time: $stop_time "                            >> $TIME_LOG
if [ "$CLONE_REPOS" == "" ]; then
   echo "setup repos: $CLONE_DIFF "                         >> $TIME_LOG
else
   echo "clone repos: $CLONE_DIFF "                         >> $TIME_LOG
fi
   echo "setup firebot: $SETUP_DIFF "                       >> $TIME_LOG
   echo "build software: $BUILD_DIFF "                      >> $TIME_LOG
   echo "run cases(debug): $DEBUG_DIFF "                    >> $TIME_LOG
   echo "run cases(release): $RELEASE_DIFF "                >> $TIME_LOG
   echo "make pictures: $PICTURE_DIFF "                     >> $TIME_LOG
   echo "run matlab: $MATLAB_DIFF "                         >> $TIME_LOG
   echo "build guides: $MANUALS_DIFF "                      >> $TIME_LOG
   echo "total: $SCRIPT_DIFF "                              >> $TIME_LOG
   echo ""                                                  >> $TIME_LOG
   if [ "$NAMELIST_NODOC_STATUS" != "" ]; then
     if [ "$NAMELIST_NODOC_STATUS" == "0" ]; then
       echo "undocumented namelist keywords: $NAMELIST_NODOC_STATUS " >> $TIME_LOG
     fi
   else
     NAMELIST_NODOC_LOG=
   fi
   if [ "$NAMELIST_NOSOURCE_STATUS" == "" ]; then
     NAMELIST_NOSOURCE_LOG=
   fi
   if [ "$UPLOADGUIDES" == "1" ]; then
     echo "status:  https://pages.nist.gov/fds-smv/firebot_status.html" >> $TIME_LOG
   fi
   if [[ "$WEB_URL" != "" ]] && [[ "$UPDATED_WEB_IMAGES" != "" ]]; then
     echo "image url: $WEB_URL"  >> $TIME_LOG
     if [ "$WEB_DIR" != "" ]; then
       echo "image dir: $WEB_DIR"  >> $TIME_LOG
     fi
   fi
   if [ "$MAKE_SUMMARY" != "" ]; then
     echo "summary dir: $FDS_SUMMARY_DIR"  >> $TIME_LOG
   fi
   if [[ "$WEB_URL" != "" ]] && [[ "$UPDATED_WEB_IMAGES" != "" ]]; then
     if [ -e $IMAGE_DIFFS ]; then
       NUM_CHANGES=`cat $IMAGE_DIFFS | awk '{print $1}'`
       NUM_ERRORS=`cat $IMAGE_DIFFS | awk '{print $2}'`
       echo "image errors/changes: $NUM_ERRORS/$NUM_CHANGES"  >> $TIME_LOG
     fi
   fi
#  upload guides to github
   get_firebot_success
   is_bot=
   if [ `whoami` == "firebot" ]; then
     is_bot=1
   fi
   if [ `whoami` == "smokebot" ]; then
     is_bot=1
   fi
   if [ `whoami` == "cfast" ]; then
     is_bot=1
   fi
   UPLOAD=
   if [[ "$UPLOADGUIDES" == "1" ]] && [[ "$is_bot"  == "1" ]]; then
     UPLOAD=1
   fi
   if [ "$FORCE_UPLOAD" != "" ]; then
     UPLOAD=1
   fi
   if [ "$UPLOAD" != "" ]; then
     cd $firebotdir
     GITURL=https://github.com/$GH_OWNER/$GH_REPO/releases/tag/$GH_FDS_TAG
     echo "Bundles, Guides, Summary:  $GITURL" >> $TIME_LOG
     $SummaryGH &> $OUTPUT_DIR/stage10_upload_github
     if [[ "$firebot_success" == "1" ]]; then
       $UploadGuidesGH                        &> $OUTPUT_DIR/stage10a_upload_github
       cat $OUTPUT_DIR/stage10a_upload_github >> $OUTPUT_DIR/stage10_upload_github
     fi
   fi
   echo ""                                   >> $TIME_LOG
   if [ -e output/slow_cases ]; then
     echo "cases with longest runtime:"       >> $TIME_LOG
     cat output/slow_cases                   >> $TIME_LOG
     echo ""                                 >> $TIME_LOG
   fi
   if [ -e output/timing_summary ]; then
     cat output/timing_summary               >> $TIME_LOG
     echo ""                                 >> $TIME_LOG
   fi
   if [ -e output/timing_errors ]; then
      echo "***Warning: cases with > 200% increased run-time"        >> $TIME_LOG
      cat output/timing_errors  | awk -F',' '{print $1,$3,"-->",$4}' >> $TIME_LOG
      echo ""                                                        >> $TIME_LOG
      echo ""                                                        >> $WARNING_LOG
      echo "***Warning: cases with > 200% increased run-time"        >> $WARNING_LOG
      cat output/timing_errors  | awk -F',' '{print $1,$3,"-->",$4}' >> $WARNING_LOG
      echo ""                                                        >> $WARNING_LOG
   fi

   echo "HAVE_MAIL=$HAVE_MAIL"
   echo "mailToFDS=$mailToFDS"
   # Check for warnings and errors
   NAMELIST_LOGS="$NAMELIST_NODOC_LOG $NAMELIST_NOSOURCE_LOG"
   if [[ -e $WARNING_LOG && -e $ERROR_LOG ]]
   then
      cd $firebotdir

     # Send email with failure message and warnings, body of email contains appropriate log file
     echo "[$botuser] $bottype failure and warnings. Version: ${FDS_REVISION}, Branch: $FDSBRANCH."
     cat $ERROR_LOG $FYI_LOG $TIME_LOG $NAMELIST_LOGS >& $MAIL_LOG
     if [ "$HAVE_MAIL" == "1" ]; then
       cat $ERROR_LOG $FYI_LOG $TIME_LOG $NAMELIST_LOGS | mail -s "[$botuser] $bottype failure and warnings. Version: ${FDS_REVISION}, Branch: $FDSBRANCH." $mailToFDS > /dev/null
     fi

   # Check for errors only
   elif [ -e $ERROR_LOG ]
   then
      # Send email with failure message, body of email contains error log file
      echo "[$botuser] $bottype failure. Version: ${FDS_REVISION}, Branch: $FDSBRANCH."
      cat $ERROR_LOG $FYI_LOG $TIME_LOG $NAMELIST_LOGS >& $MAIL_LOG
      if [ "$HAVE_MAIL" == "1" ]; then
        cat $ERROR_LOG $FYI_LOG $TIME_LOG $NAMELIST_LOGS | mail -s "[$botuser] $bottype failure. Version: ${FDS_REVISION}, Branch: $FDSBRANCH." $mailToFDS > /dev/null
      fi

   # Check for warnings only
   elif [ -e $WARNING_LOG ]
   then
      cd $firebotdir

      # Send email with success message, include warnings
      echo "[$botuser] $bottype success, with warnings. Version: ${FDS_REVISION}, Branch: $FDSBRANCH"
      cat $WARNING_LOG $FYI_LOG $TIME_LOG $NAMELIST_LOGS >& $MAIL_LOG
      if [ "$HAVE_MAIL" == "1" ]; then
        cat $WARNING_LOG $FYI_LOG $TIME_LOG $NAMELIST_LOGS | mail -s "[$botuser] $bottype success, with warnings. Version: ${FDS_REVISION}, Branch: $FDSBRANCH" $mailToFDS > /dev/null
      fi

   # No errors or warnings
   else
#  upload guides to a google drive directory
      cd $firebotdir

      # Send success message with links to nightly manuals
      firebot_status=0
      cat $TIME_LOG $FYI_LOG $NAMELIST_LOGS >& $MAIL_LOG
      echo "[$botuser] $bottype success! Version: ${FDS_REVISION}, Branch: $FDSBRANCH"
      if [ "$HAVE_MAIL" == "1" ]; then
        cat $TIME_LOG $FYI_LOG $NAMELIST_LOGS | mail -s "[$botuser] $bottype success! Version: ${FDS_REVISION}, Branch: $FDSBRANCH" $mailToFDS > /dev/null
      fi
   fi
   cp $TIME_LOG "$HISTORY_DIR/${FDS_REVISION}_summary.txt"
}

#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             beginning of firebot
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#*** setup

echo $0 $* >> command.firebot


SCRIPT_beg=`GET_TIME`
CLONE_beg=`GET_TIME`
start_time=`date`
# Start firebot timer
START_TIME=$(date +%s)

#*** file descriptors

FDSGNU_DB_DIR=
FDSGNU_DB_EXE=

FDS_OPENMP_DB_EXE=
FDS_OPENMP_DB_DIR=
FDS_DB_EXE=
FDS_DB_DIR=
FDS_OPENMP_EXE=
FDS_OPENMP_DIR=
FDS_EXE=
FDS_DIR=

# define run directories
PID_FILE=~/.fdssmvgit/firesmokebot_pid
firebotdir=`pwd`
export SCRIPTFILES=$firebotdir/scriptfiles
OUTPUT_DIR="$firebotdir/output"
HISTORY_DIR="$HOME/.firebot/history"
TIMING_ERRORS=$OUTPUT_DIR/timing_errors

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
MAIL_LOG=$OUTPUT_DIR/mail_log
FYI_LOG=$OUTPUT_DIR/fyis
NEWGUIDE_DIR=$OUTPUT_DIR/Newest_Guides
MANUALS_DIR=$HOME/.firebot/Manuals
MANUALS_LATEST_DIR=$HOME/.firebot/Manuals_latest
EMAIL_LIST=$HOME/.firebot/firebot_email_list.sh
CRLF_WARNINGS=$OUTPUT_DIR/stage1_crlf_warnings

LATESTAPPS_DIR=$HOME/.firebot/appslatest
APPS_DIR=$HOME/.firebot/apps

PUBS_DIR=$HOME/.firebot/pubs
MKDIR $PUBS_DIR

MKDIR $HOME/.firebot

MKDIR $APPS_DIR
rm -rf $LATESTAPPS_DIR
MKDIR $LATESTAPPS_DIR

WEBBRANCH=nist-pages
FDSBRANCH=master
OUTBRANCH=master
FIGBRANCH=master
CADBRANCH=master
EXPBRANCH=master
SMVBRANCH=master
BOTBRANCH=master
BRANCH=master
BUILD_ONLY=
MANUALS_MATLAB_ONLY=

FDS_release_success=false

#*** determine platform

platform="linux"
platform2="Linux"
SMVCOMPILER=intel
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  platform2="OSX"
  SMVCOMPILER=gnu
fi
export platform

#*** Set unlimited stack size

if [ "$platform" == "linux" ] ; then
  ulimit -s unlimited
fi

#*** set initial values

COMPILER=intel
QUEUE=
CLEANREPO=
UPDATEREPO=
JOBPREFIX_RELEASE=FBR_
JOBPREFIX_DEBUG=FBD_

DB=_db

ARCHIVE_REPO_SIZES=
REPOEMAIL=
UPLOADGUIDES=0
FDS_REVISION=
SMV_REVISION=
INTEL=
INTEL2=
CLONE_REPOS=
CLONE_FDSSMV=
FDS_REV=origin/master
SMV_REV=origin/master
WEB_DIR=
WEB_BASE_DIR=
WEB_ROOT=
UPDATED_WEB_IMAGES=
FORCECLONE=

SKIPMATLAB=
SKIPPICTURES=
SKIPRELEASE=
FDS_TAG=
SMV_TAG=
VALIDATION=
CHECK_CLUSTER=
OPENMPTEST=1
MPI_TYPE=ompi
BOPT=
GITURL=
MAKE_SUMMARY=
CLONEFILE=
BUILD_3RD_PARTY=
FORCE_UPLOAD=

#*** parse command line arguments
while getopts '3b:BcCdDGJm:Mp:q:R:sTuUV:x:X:y:Y:w:W:z' OPTION
do
case $OPTION in
  3)
   BUILD_3RD_PARTY=1
   ;;
  b)
   BOPT=1
   BRANCH="$OPTARG"
   FDSBRANCH=$BRANCH
   SMVBRANCH=$BRANCH
   BOTBRANCH=$BRANCH
   OUTBRANCH=$BRANCH
   FIGBRANCH=$BRANCH
   CADBRANCH=$BRANCH
   EXPBRANCH=$BRANCH
   ;;
  B)
   BUILD_ONLY=1
   ;;
  c)
   CLEANREPO=1
   ;;
  C)
   FORCECLONE="-C"
   ;;
  d)
   SKIPRELEASE=1
   SKIPMATLAB=1
   SKIPPICTURES=1
   ;;
  D)
   OPENMPTEST=
   ;;
  G)
   FORCE_UPLOAD=1
   ;;
  J)
   MPI_TYPE=impi
   INTEL2="-J"
   ;;
  m)
   mailToFDS="$OPTARG"
   ;;
  M)
   MANUALS_MATLAB_ONLY=1
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
   SKIPPICTURES=1
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
  V)
   
   VALIDATION="$OPTARG"
   if [ "$VALIDATION" == "all" ]; then
     CHECK_CLUSTER=
   else
     CHECK_CLUSTER=1
   fi
   ;;
  x)
   FDS_REV="$OPTARG"
   if [ "$FDS_REV" == "latest" ]; then
     UPDATEREPO=1
     FDS_REV=
   fi
   ;;
  X)
   FDS_TAG="$OPTARG"
   ;;
  y)
   SMV_REV="$OPTARG"
   if [ "$SMV_REV" == "latest" ]; then
     UPDATEREPO=1
     SMV_REV=
   fi
   ;;
  Y)
   SMV_TAG="$OPTARG"
   ;;
  w)
   WEB_DIR="$OPTARG"
   ;;
  W)
   WEB_ROOT="$OPTARG"
   ;;
  z)
   CLONEFILE="1"
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$BOPT" != "" ]; then
  UPDATEREPO=
fi  

if [ "$WEB_DIR" != "" ]; then
  WEB_BASE_DIR=$WEB_DIR
  WEB_DIR=$WEB_ROOT/$WEB_DIR
  
  if [ ! -d $WEB_DIR ]; then
    WEB_DIR=
    WEB_BASE_DIR=
  fi
fi
if [ "$WEB_DIR" != "" ]; then
  testfile=$WEB_DIR/test.$$
  touch $testfile >& /dev/null
  if [ -e $testfile ]; then
    if [ "$WEB_URL_BASE" == "" ]; then
      WEB_HOST=`hostname -A | awk '{print $2}'`
      WEB_URL_BASE=http://$WEB_HOST/
    fi
    WEB_URL=$WEB_URL_BASE/$WEB_BASE_DIR
    rm -f $testfile
  else
    WEB_BASE_DIR=
    WEB_DIR=
    WEB_URL=
  fi
fi

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
figrepo=$repo/fig
outrepo=$repo/out
exprepo=$repo/exp
cadrepo=$repo/cad
hyprerepo=$repo/hypre
sundialsrepo=$repo/sundials
libsdir=$repo/libs

if [ "$CLONEFILE" != "" ]; then
  CLONEFILE=$botrepo/Bundlebot/release/config.sh
  if [ ! -x $CLONEFILE ]; then
    echo "***error: $CLONEFILE does not exist or is not executable"
    CLONEFILE=
  fi
fi

if [ "$OPENMPTEST" == "" ]; then
  size=_64
  GNU_MPI=mpi_
  ONETHREAD="-o 1"
  REGULARCASES="-R"
else
  GNU_MPI=ompi_
  ONETHREAD=
  REGULARCASES=
fi
smvsize=_64

GNU_COMPILER=gnu_

FDSGNU_DB_DIR=$fdsrepo/Build/${GNU_MPI}${GNU_COMPILER}${platform}${size}_db
FDSGNU_DB_EXE=

FDS_OPENMP_DB_DIR=$fdsrepo/Build/${MPI_TYPE}_${COMPILER}_${platform}_openmp${size}_db
FDS_OPENMP_DB_EXE=fds_${MPI_TYPE}_${COMPILER}_${platform}_openmp${size}_db

FDS_DB_DIR=$fdsrepo/Build/${MPI_TYPE}_${COMPILER}_${platform}${size}_db
FDS_DB_EXE=fds_${MPI_TYPE}_${COMPILER}_${platform}${size}_db

FDS_OPENMP_DIR=$fdsrepo/Build/${MPI_TYPE}_${COMPILER}_${platform}_openmp${size}
FDS_OPENMP_EXE=fds_${MPI_TYPE}_${COMPILER}_${platform}_openmp${size}

FDS_DIR=$fdsrepo/Build/${MPI_TYPE}_${COMPILER}_${platform}${size}
FDS_EXE=fds_${MPI_TYPE}_${COMPILER}_${platform}${size}

FDS_SUMMARY_DIR=$fdsrepo/Manuals/FDS_Summary
IMAGE_DIFFS=$FDS_SUMMARY_DIR/image_differences

#*** clean repos
echo "Status"
echo "------"
  echo Cleaning bot repo
  clean_firebot_metafiles

#*** write out file when firebot first starts
date > $OUTPUT_DIR/stage0_start 2>&1

#*** clone repos

if [[ "$CLONE_REPOS" != "" ]]; then
  echo Cloning repos
  cd $botrepo/Scripts
  if [ "$DISABLEPUSH" != "" ]; then
    DISABLEPUSH="-D"
  fi
  if [ "$CLONE_FDSSMV" != "" ]; then
   # only clone the fds and smv repos - used when just compiling the fds and smv apps
    ./setup_repos.sh $FORCECLONE -T > $OUTPUT_DIR/stage1_clone 2>&1
  else
   # clone all repos
    ./setup_repos.sh $FORCECLONE -F > $OUTPUT_DIR/stage1_clone 2>&1
  fi
  if [ "$BUILD_3RD_PARTY" != "" ]; then
    echo removing hypre repo    >>   $OUTPUT_DIR/stage1_clone
    rm -rf $hyprerepo           >>   $OUTPUT_DIR/stage1_clone 2>&1
    echo removing sundials repo >>   $OUTPUT_DIR/stage1_clone
    rm -rf $sundialsrepo        >>   $OUTPUT_DIR/stage1_clone 2>&1
    echo removing libsdir       >>   $OUTPUT_DIR/stage1_clone
    rm -rf $libsdir             >>   $OUTPUT_DIR/stage1_clone 2>&1
    ./setup_repos.sh -3         >>   $OUTPUT_DIR/stage1_clone 2>&1
  fi
  if [ "$CLONE_REPOS" != "master" ]; then
    if [ "$CLONEFILE" == "" ]; then
      FDSBRANCH=$CLONE_REPOS
      CHECKOUT_REPO $FDSBRANCH $fdsrepo $FDS_REV $FDS_TAG 

      SMVBRANCH=$CLONE_REPOS
      CHECKOUT_REPO $SMVBRANCH $smvrepo $SMV_REV $SMV_TAG 
    else
      source $CLONEFILE 
      FDSBRANCH=$CLONE_REPOS
      CHECKOUT_REPO $FDSBRANCH $fdsrepo $BUNDLE_FDS_REVISION  $BUNDLE_FDS_TAG 

      SMVBRANCH=$CLONE_REPOS
      CHECKOUT_REPO $SMVBRANCH $smvrepo $BUNDLE_SMV_REVISION  $BUNDLE_SMV_TAG 

      CADBRANCH=$CLONE_REPOS
      CHECKOUT_REPO $CADBRANCH $cadrepo $BUNDLE_CAD_REVISION  $BUNDLE_CAD_TAG 

      EXPBRANCH=$CLONE_REPOS
      CHECKOUT_REPO $EXPBRANCH $exprepo $BUNDLE_EXP_REVISION  $BUNDLE_EXP_TAG 
      
      FIGBRANCH=$CLONE_REPOS
      CHECKOUT_REPO $FIGBRANCH $figrepo $BUNDLE_FIG_REVISION  $BUNDLE_FIG_TAG 

      OUTBRANCH=$CLONE_REPOS
      CHECKOUT_REPO $OUTBRANCH $outrepo $BUNDLE_OUT_REVISION  $BUNDLE_OUT_TAG 
    fi
  fi
  ARCHIVE_REPO_SIZES=1
fi
CLONE_end=`GET_TIME`
GET_DURATION $CLONE_beg $CLONE_end CLONE

SETUP_beg=`GET_TIME`
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

CD_REPO $outrepo $OUTBRANCH || exit 1
if [ "$OUTBRANCH" == "current" ]; then
  cd $outrepo
  OUTBRANCH=`git rev-parse --abbrev-ref HEAD`
fi
cd $outrepo
OUTREPO_HASH=`git rev-parse HEAD`

CD_REPO $cadrepo $CADBRANCH || exit 1
if [ "$CADBRANCH" == "current" ]; then
  cd $cadrepo
  CADBRANCH=`git rev-parse --abbrev-ref HEAD`
fi
cd $cadrepo
CADREPO_HASH=`git rev-parse HEAD`

CD_REPO $figrepo $FIGBRANCH || exit 1
if [ "$FIGBRANCH" == "current" ]; then
  cd $figrepo
  FIGBRANCH=`git rev-parse --abbrev-ref HEAD`
fi
cd $figrepo
FIGREPO_HASH=`git rev-parse HEAD`

CD_REPO $exprepo $EXPBRANCH || exit 1
if [ "$EXPBRANCH" == "current" ]; then
  cd $exprepo
  EXPBRANCH=`git rev-parse --abbrev-ref HEAD`
fi
cd $exprepo
EXPREPO_HASH=`git rev-parse HEAD`

CD_REPO $botrepo $BOTBRANCH || exit 1
if [ "$BOTBRANCH" == "current" ]; then
  cd $botrepo
  BOTBRANCH=`git rev-parse --abbrev-ref HEAD`
fi
cd $botrepo
BOTREPO_HASH=`git rev-parse HEAD`

# if the fds repo is cloned, make a copy of the Verification directory and run fds in debug mode in this directory
if [ "$CLONE_REPOS" != "" ]; then
  cd $fdsrepo
  VERIFICATION_DEBUG=Verification_DB
  cp -r Verification $VERIFICATION_DEBUG
else
  VERIFICATION_DEBUG=Verification
fi

#save apps and pubs in directories under .firebot/$FDSBRANCH

BRANCH_DIR=$HOME/.firebot/$FDSBRANCH
BRANCHPUBS_DIR=$BRANCH_DIR/pubs
BRANCHAPPS_DIR=$BRANCH_DIR/apps
MKDIR $BRANCH_DIR
MKDIR $BRANCHPUBS_DIR
MKDIR $BRANCHAPPS_DIR

cd $firebotdir

#*** save pid in case we want to kill firebot later

echo $$ > $PID_FILE

#*** check for C/C++ compiler

IFORT_VERSION=
notfound=
if [ "$COMPILER" == "intel" ]; then
   notfound=`ifort -help 2>&1 | tail -1 | grep "not found" | wc -l`
   if [ $notfound -eq 0 ]; then
     IFORT_VERSION=`ifort -v 2>&1`
   fi
else
   notfound=`gcc -help 2>&1 | tail -1 | grep "not found" | wc -l`
fi

UploadGuidesGH=$botrepo/Firebot/fds_guides2GH.sh
SummaryGH=$botrepo/Firebot/summary2GH.sh
COPY_FDS_APPS=$botrepo/Firebot/copy_fds_apps.sh
COPY_SMV_APPS=$botrepo/Firebot/copy_smv_apps.sh

echo ""
echo "Settings"
echo "--------"
if [ "$BUILD_ONLY" == "1" ]; then
  echo "Only build apps"
fi
echo "     CAD repo/branch: $cadrepo/$CADBRANCH"
echo "     EXP repo/branch: $exprepo/$EXPBRANCH"
echo "     FDS repo/branch: $fdsrepo/$FDSBRANCH"
echo "     FIG repo/branch: $figrepo/$FIGBRANCH"
echo "     SMV repo/branch: $smvrepo/$SMVBRANCH"
echo "     OUT repo/branch: $outrepo/$OUTBRANCH"
echo ""
echo "      Run dir: $firebotdir"
if [ "$IFORT_VERSION" != "" ]; then
  echo "      Fortran: $IFORT_VERSION"
fi
if [ "$SKIPRELEASE" != "" ]; then
  echo "     Skipping: release cases stage"
fi
if [ "$SKIPPICTURES" != "" ]; then
  echo "     Skipping: picture generation stage"
fi
if [ "$SKIPMATLAB" != "" ]; then
  echo "     Skipping: matlab stage"
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
if [ "$BUILD_ONLY" == "" ]; then
  echo "        queue: $QUEUE"
fi
if [ "$WEB_DIR" != "" ]; then
  echo "      web dir: $WEB_DIR"
fi
if [ "$WEB_URL" != "" ]; then
  echo "          URL: $WEB_URL"
fi
echo ""

# Set time limit (43,200 seconds = 12 hours)
TIME_LIMIT=43200
TIME_LIMIT_EMAIL_NOTIFICATION="unsent"

hostname=`hostname`

touch $FYI_LOG

### Stage 1 ###

echo "Status"
echo "------"
if [[ "$CLONE_REPOS" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
  if [[ "$CLEANREPO" == "1" ]] ; then
    if [ "$BUILD_ONLY" == "" ]; then
      clean_repo2 exp $EXPBRANCH|| exit 1
    fi
    clean_repo2 fds $FDSBRANCH || exit 1
    if [ "$BUILD_ONLY" == "" ]; then
      clean_repo2 fig $FIGBRANCH     || exit 1
      clean_repo2 out $OUTBRANCH || exit 1
    fi 
    clean_repo2 smv $SMVBRANCH || exit 1
  fi
  ARCHIVE_REPO_SIZES=1
fi

#*** update repos
  UPDATING=
  if [[ "$UPDATEREPO" == "1" ]] ; then
# we are not cloning so update
    if [[ "$CLONE_REPOS" == "" ]]; then
      UPDATING=1
      echo Updating
      update_repo fds $FDSBRANCH || exit 1
      if [[ "$CHECK_CLUSTER" == "" ]]; then
        update_repo smv $SMVBRANCH || exit 1
        update_repo fig $FIGBRANCH || exit 1
        update_repo out $OUTBRANCH || exit 1
        update_repo exp $EXPBRANCH || exit 1
      fi
    fi
# we are not cloning fig, out and exp so update them
    if [[ "$CLONE_REPOS" != "" ]] && [[ "$CLONE_FDSSMV" != "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
      UPDATING=1
      echo Updating
      update_repo fig $FIGBRANCH || exit 1
      update_repo out $OUTBRANCH || exit 1
      update_repo exp $EXPBRANCH || exit 1
    fi
  fi
  if [ "$UPDATING" == "" ]; then
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

# comment next line to turn on dos line ending checks
#CHECK_LINES=

if [ "$CHECK_CLUSTER" == "" ]; then
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
fi

get_fds_revision $FDSBRANCH || exit 1
get_smv_revision $SMVBRANCH || exit 1
get_bot_revision $BOTBRANCH || exit 1
if [[ "$BUILD_ONLY" == "" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
  get_exp_revision $EXPBRANCH     || exit 1
  get_fig_revision $FIGBRANCH     || exit 1
  get_out_revision $OUTBRANCH     || exit 1
  get_cad_revision $CADBRANCH     || exit 1
fi

echo | mail >& /tmp/mailtest.$$
notfound=`grep 'command not found' /tmp/mailtest.$$ | wc -l`
HAVE_MAIL=1
if [ $notfound -gt 0 ]; then
  HAVE_MAIL=
fi
rm /tmp/mailtest.$$

# archive repo sizes
# (only if the repos are cloned or cleaned)

if [[ "$BUILD_ONLY" == "" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
  if [ "$ARCHIVE_REPO_SIZES" == "1" ]; then
    archive_repo_sizes
  fi
fi

check_git_checkout
archive_compiler_version

### Stage 2a ###
if [ "$MANUALS_MATLAB_ONLY" == "" ]; then
  echo Building
  echo "   FDS"
fi
SETUP_end=`GET_TIME`
GET_DURATION $SETUP_beg $SETUP_end SETUP

###****** Stage 2b ###

BUILD_beg=`GET_TIME`
if [[ "$BUILD_ONLY" == "" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
  compile_fds_mpi_db         $FDS_DB_DIR $FDS_DB_EXE
  check_compile_fds_mpi_db   $FDS_DB_DIR $FDS_DB_EXE
  if [ "$OPENMPTEST" != "" ]; then 
    compile_fds_mpi_db         $FDS_OPENMP_DB_DIR $FDS_OPENMP_DB_EXE openmp
    check_compile_fds_mpi_db   $FDS_OPENMP_DB_DIR $FDS_OPENMP_DB_EXE openmp
  fi
fi

###*** Stage 2d ###

if [[ "$OPENMPI_GNU" != "" ]] && [[ "$BUILD_ONLY" == "" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then

  compile_fds_mpi_gnu_db       $FDSGNU_DB_DIR
  check_compile_fds_mpi_gnu_db
fi

###*** Stage 2c ###

if [[ "$SKIPRELEASE" == "" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]]; then
  compile_fds_mpi         $FDS_DIR $FDS_EXE
  check_compile_fds_mpi   $FDS_DIR $FDS_EXE
  if [ "$OPENMPTEST" != "" ]; then 
    compile_fds_mpi         $FDS_OPENMP_DIR $FDS_OPENMP_EXE openmp
    check_compile_fds_mpi   $FDS_OPENMP_DIR $FDS_OPENMP_EXE openmp
  fi
fi

###*** Stage 3a ###

if [[ "$SKIPPICTURES" == "" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
  compile_smv_utilities
  check_smv_utilities
fi

if [[ "$MANUALS_MATLAB_ONLY" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
  cd $firebotdir
  $COPY_FDS_APPS > $OUTPUT_DIR/stage3d
fi

###*** Stage 3b ###

if [[ "$SKIPPICTURES" == "" ]] && [[ "$BUILD_ONLY" == "" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
  compile_smv_db
  check_compile_smv_db
fi

###*** Stage 3c ###

if [[ "$SKIPPICTURES" == "" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
  compile_smv
  check_compile_smv
  cd $firebotdir
  $COPY_SMV_APPS >> $OUTPUT_DIR/stage3d
fi
BUILD_end=`GET_TIME`
GET_DURATION $BUILD_beg $BUILD_end BUILD

###*** Stage 4 ###

DEBUG_beg=`GET_TIME`
# Depends on successful FDS debug compile
if [[ $FDS_debug_success ]] && [[ "$BUILD_ONLY" == "" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
   run_verification_cases_debug
   check_cases_debug $fdsrepo/$VERIFICATION_DEBUG 'verification'
fi

if [[ "$CLONE_REPOS" == "" ]] && [[ "$BUILD_ONLY" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
# clean debug stage (only if repos were not cloned)
  cd $fdsrepo
  if [[ "$CLEANREPO" == "1" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]]; then
    echo "   cleaning Verification"
    clean_repo $fdsrepo/$VERIFICATION_DEBUG $FDSBRANCH || exit 1
  fi
fi
DEBUG_end=`GET_TIME`
GET_DURATION $DEBUG_beg $DEBUG_end DEBUG

###*** Stage 5 ###

RELEASE_beg=`GET_TIME`
if [[ "$BUILD_ONLY" == "" ]];  then
# Depends on successful FDS compile
  if [[ $FDS_release_success ]] && [[ "$SKIPRELEASE" == "" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]]; then
    run_VV_cases_release

# this also checks restart cases (using same criteria)
    if [ "$CHECK_CLUSTER" == "" ]; then
      check_verification_cases_release $fdsrepo/Verification
    fi
    if [[ "$VALIDATION" != "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
      check_validation_cases_release $fdsrepo/Validation Current_Results
    fi
    if [[ "$VALIDATION" != "" ]] && [[ "$CHECK_CLUSTER" != "" ]]; then
      check_validation_cases_release $fdsrepo/Validation FDS_Input_Files
    fi
  fi
fi
RELEASE_end=`GET_TIME`
GET_DURATION $RELEASE_beg $RELEASE_end RELEASE

###*** Stage 6 ###
PICTURE_beg=`GET_TIME`
if [[ "$BUILD_ONLY" == "" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then

# Depends on successful SMV compile
  if [[ "$SKIPPICTURES" == "" ]] && [[ $smv_release_success ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]] ; then
    make_fds_pictures
    check_fds_pictures
    make_fds_summary
    MAKE_SUMMARY=1
  fi
PICTURE_end=`GET_TIME`
GET_DURATION $PICTURE_beg $PICTURE_end PICTURE

###*** Stage 7c ###

MATLAB_beg=`GET_TIME`
  generate_timing_stats
  if [ "$SKIPMATLAB" == "" ] ; then

###*** Stage 7a ###

#*** python verification plots

    run_python_setup
    check_python_setup
    if [ $python_success == true ]; then
      run_python_verification
      check_python_verification
    fi

#*** python validation plots
#    only need to setup python once

    if [ $python_success == true ]; then
      run_python_validation
      check_python_validation
    fi

#*** matlab verification plots

    check_matlab_license_server
    if [ $matlab_success == true ]; then
      run_matlab_verification
      check_matlab_verification
      check_verification_stats
    fi

###*** Stage 7b ###

#*** matlab validation plots

    check_matlab_license_server
    if [ $matlab_success == true ]; then
      run_matlab_validation
      check_matlab_validation
      archive_validation_stats
      make_validation_git_stats
      check_validation_stats
    fi
  fi
MATLAB_end=`GET_TIME`
GET_DURATION $MATLAB_beg $MATLAB_end MATLAB

###*** Stage 8 ###

MANUALS_beg=`GET_TIME`
  if [ "$SKIPMATLAB" == "" ] ; then
    make_fds_user_guide
#    make_geom_notes
    make_fds_verification_guide
    make_fds_technical_guide
    make_fds_validation_guide
    make_fds_Config_management_plan
    get_firebot_success

# copy repo manuals to Manualslatest directory whether firebot passes or fails
    rm -rf $MANUALS_LATEST_DIR
    cp -r $fdsrepo/Manuals $MANUALS_LATEST_DIR
    if [[ "$firebot_success" == "1" ]] ; then

# copy repo manuals to Manuals directory only if firebot
      rm -rf $MANUALS_DIR
      cp -r $fdsrepo/Manuals $MANUALS_DIR

# copy to a 2nd location that is accessible via cross mounts
      if [ "$FIREBOT_MANUALS_DIR" != "" ]; then
        if [ ! -d $FIREBOT_MANUALS_DIR ]; then
          mkdir $FIREBOT_MANUALS_DIR
        fi
        rm -rf $FIREBOT_MANUALS_DIR
        cp -r $fdsrepo/Manuals $FIREBOT_MANUALS_DIR
      fi

      cp $LATESTAPPS_DIR/FDS_REVISION $PUBS_DIR/FDS_REVISION
      copy_fds_user_guide
      copy_fds_verification_guide
      copy_fds_technical_guide
      copy_fds_validation_guide
      copy_fds_Config_management_plan
    fi
  fi
fi

###*** archive apps

copy_apps=
get_firebot_success
if [[ "$firebot_success" == "1" ]] && [[ "$CHECK_CLUSTER" == "" ]]; then
  copy_apps=1
fi
if [ "$BUILD_ONLY" == "1" ]; then
  copy_apps=1
fi
if [ "$copy_apps" == "1" ]; then
  rm -f $APPS_DIR/*
  cp $LATESTAPPS_DIR/* $APPS_DIR/.

  rm -f $BRANCHAPPS_DIR/*
  cp $LATESTAPPS_DIR/* $BRANCHAPPS_DIR/.

  if [[ "$BUILD_ONLY" == "" ]]; then
    rm -f $BRANCHPUBS_DIR/*
    cp $PUBS_DIR/*       $BRANCHPUBS_DIR/.
  fi
fi
MANUALS_end=`GET_TIME`
GET_DURATION $MANUALS_beg $MANUALS_end MANUALS
SCRIPT_end=`GET_TIME`
GET_DURATION $SCRIPT_beg $SCRIPT_end SCRIPT

###*** Wrap up and report results ###

set_files_world_readable
save_build_status
if [[ "$BUILD_ONLY" == "" ]] && [[ "$MANUALS_MATLAB_ONLY" == "" ]]  && [[ "$CHECK_CLUSTER" == "" ]]; then
  archive_timing_stats
fi
email_build_status 'Firebot'
echo firebot exit status: $firebot_status
exit $firebot_status
