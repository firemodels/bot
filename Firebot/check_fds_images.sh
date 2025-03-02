#!/bin/bash

#---------------------------------------------
#                   compile_fds_mpi
#---------------------------------------------

compile_fds_mpi()
{
   # Clean and compile FDS MPI
  local FDSDIR=$1
  local FDSEXE=$2
  cd $FDSDIR
  make -f ../makefile clean &> /dev/null
  ./make_fds.sh             &> $OUTPUT_DIR/stage2c
}

#---------------------------------------------
#                   check_compile_fds_mpi
#---------------------------------------------

check_compile_fds_mpi()
{
   # Check for errors in FDS MPI compilation
  local FDSDIR=$1
  local FDSEXE=$2
  cd $FDSDIR
  if [ -x $FDSEXE ]
  then
     FDS_release_success=true
  else
     echo "Errors from Stage 2c - Compile FDS MPI release:" >> $ERROR_LOG
     echo "The program $FDSEXE failed to build."                     >> $ERROR_LOG
     cat $OUTPUT_DIR/stage2c                                         >> $ERROR_LOG
     echo ""                                                         >> $ERROR_LOG
     ABORT_FDS=1
  fi

  # Check for compiler warnings/remarks
  # 'performing multi-file optimizations' and 'generating object file' are part of a normal compile
  # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
  if [[ `grep -E -i 'warning|remark' $OUTPUT_DIR/stage2c | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file'` == "" ]]
  then
     # Continue along
     :
  else
     echo "Warnings from Stage 2c - Compile FDS MPI release:" >> $WARNING_LOG
     grep -A 5 -E -i 'warning|remark' $OUTPUT_DIR/stage2c | grep -v 'pointer not aligned at address' | grep -v ipo | grep -v Referenced | grep -v atom | grep -v 'feupdateenv is not implemented' | grep -v 'performing multi-file optimizations' | grep -v 'generating object file' >> $WARNING_LOG
     echo "" >> $WARNING_LOG
  fi
}

#---------------------------------------------
#                    comple_smv
#---------------------------------------------

compile_smv()
{
   # Clean and compile SMV
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
  else
    smv_errors=1
    echo "Errors from Stage 3c - Compile SMV release:" >> $ERROR_LOG
    cat $OUTPUT_DIR/stage3c                            >> $ERROR_LOG
    echo ""                                            >> $ERROR_LOG
    ABORT_SMV=1
  fi

  # Check for compiler warnings/remarks
  # grep -v 'feupdateenv ...' ignores a known FDS MPI compiler warning (http://software.intel.com/en-us/forums/showthread.php?t=62806)
  if [[ `grep -E -i 'warning' $OUTPUT_DIR/stage3c | grep -v 'was built for newer' | grep -v 18020 | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked'` == "" ]]; then
    # Continue along
    :
  else
    echo "Warnings from Stage 3c - Compile SMV release:" >> $WARNING_LOG
    grep -A 5 -E -i 'warning' $OUTPUT_DIR/stage3c | grep -v 'was built for newer' | grep -v 18020 | grep -v 'feupdateenv is not implemented' | grep -v 'lcilkrts linked' >> $WARNING_LOG
    echo "" >> $WARNING_LOG
  fi
  smv_release_success=true
}

#---------------------------------------------
#                   run_picture_cases
#---------------------------------------------

run_fds_pictures()
{
   # run picture cases

   cd $fdsrepo/Verification/scripts
     echo ./Run_FDS_Cases.sh -p -q $QUEUE -j $JOBPREFIX_RELEASE  > $OUTPUT_DIR/stage5 2>&1
     ./Run_FDS_Cases.sh -p -q $QUEUE -j $JOBPREFIX_RELEASE      >> $OUTPUT_DIR/stage5 2>&1
     echo ""                                                    >> $OUTPUT_DIR/stage5 2>&1

   # Wait for non-benchmark verification cases to end
   wait_cases_release_end verification stage5

#  check whether cases have run 
   cd $fdsrepo/Verification/scripts
   ./Run_FDS_Cases.sh -p -C -j $JOBPREFIX_RELEASE                > $OUTPUT_DIR/stage5_check 2>&1
}


#---------------------------------------------
#                   wait_cases_release_end
#---------------------------------------------

wait_cases_release_end()
{
   CASETYPE=$1
   STAGE=$2

   current_wait_dir=`pwd`

   # Scans squeue and waits for cases to end
   while          [[ `squeue | awk '{print $3 $4 $5}' | grep $(whoami) | grep $JOBPREFIX_RELEASE | grep -v 'CG$'` != '' ]]; do
      JOBS_REMAINING=`squeue | awk '{print $3 $4 $5}' | grep $(whoami) | grep $JOBPREFIX_RELEASE | grep -v 'CG$' | wc -l`
      echo "Waiting for ${JOBS_REMAINING} $CASETYPE cases to complete." >> $OUTPUT_DIR/$STAGE
      TIME_LIMIT_STAGE="5"
      sleep 60
   done
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


#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
#                             beginning of imagebot
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
CURDIR=`pwd`
if [ -e .fds_git ]; then
  cd ../..
  repo=`pwd`
  cd $CURDIR
else
  echo "***error: imagebot not running in the bot/Firebot directory"
  exit 1
fi

QUEUE=firebot
fdsrepo=$repo/fds
smvrepo=$repo/smv
botrepo=$repo/bot
firebotdir=$botrepo/Firebot
OUTPUT_DIR=$firebotdir/output
FDS_SUMMARY_DIR=$fdsrepo/Manuals/FDS_Summary
WARNING_LOG=$OUTPUT_DIR/warnings
ERROR_LOG=$OUTPUT_DIR/errors
FYI_LOG=$OUTPUT_DIR/fyi
JOBPREFIX_RELEASE=IBR_
WEB_DIR=
WEB_ROOT=/opt/www/html
ABORT_FDS=
ABORT_SMV=
ABORT=

smvsize=_64
platform="linux"
platform2="Linux"
SMVCOMPILER=intel
if [ "`uname`" == "Darwin" ] ; then
  platform="osx"
  platform2="OSX"
  SMVCOMPILER=gnu
fi
export platform
MPI_TYPE=impi
COMPILER=intel
FDS_DIR=$fdsrepo/Build/${MPI_TYPE}_${COMPILER}_${platform}
FDS_EXE=fds_${MPI_TYPE}_${COMPILER}_${platform}


#*** parse command line arguments
while getopts 'qw:W:' OPTION
do
case $OPTION in
  q)
   QUEUE="$OPTARG"
   ;;
  w)
   WEB_DIR="$OPTARG"
   ;;
  W)
   WEB_ROOT="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

if [ "$WEB_DIR" != "" ]; then
  WEB_DIR=$WEB_ROOT/WEB_DIR
fi

echo building fds
compile_fds_mpi         $FDS_DIR $FDS_EXE
check_compile_fds_mpi   $FDS_DIR $FDS_EXE

echo building smokeview
compile_smv
check_compile_smv

if [ "$ABORT_FDS" != "" ]; then
  echo "***error: fds failed to build"
  ABORT=1
fi
if [ "$ABORT_SMV" != "" ]; then
  echo "***error: smokeview failed to build"
  ABORT=1
fi


if [ "$ABORT" == "" ]; then
  echo running picture cases
  run_fds_pictures

  echo making pictures
  make_fds_pictures

  echo checking pictures
  check_fds_pictures

  echo making summary
  make_fds_summary
fi



