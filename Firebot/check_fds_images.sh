#!/bin/bash

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
   ./Run_FDS_Cases.sh -p -C -j $JOBPREFIX_RELEASE               >> $OUTPUT_DIR/stage5 2>&1
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
botrepo=$repo/bot
firebotdir=$botrepo/Firebot
OUTPUT_DIR=$firebotdir/output
FDS_SUMMARY_DIR=$fdsrepo/Manuals/FDS_Summary
WARNING_LOG=$OUTPUT_DIR/warnings
ERROR_LOG=$OUTPUT_DIR/errors
FYI_LOG=$OUTPUT_DIR/fyi
JOBPREFIX_RELEASE=IBR_
WEB_DIR=
WEB_ROOT=/var/www/html

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

run_fds_pictures
make_fds_pictures
check_fds_pictures
make_fds_summary



