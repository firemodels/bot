#!/bin/bash

#---------------------------------------------
#                   run_picture_cases
#---------------------------------------------

run_fds_pictures()
{
   # run picture cases

   cd $fdsrepo/Verification/scripts
     echo ./Run_FDS_Cases.sh $INTEL2 -b $ONETHREAD -q $QUEUE -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5 2>&1
     ./Run_FDS_Cases.sh -p      -q $QUEUE -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5 2>&1
     echo ""                                                                       >> $OUTPUT_DIR/stage5 2>&1

   # Wait for non-benchmark verification cases to end
   wait_cases_release_end verification stage5

#  check whether cases have run 
   cd $fdsrepo/Verification/scripts
   ./Run_FDS_Cases.sh -p -C -j $JOBPREFIX_RELEASE >> $OUTPUT_DIR/stage5 2>&1
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
QUEUE=batch1

#*** parse command line arguments
while getopts 'q' OPTION
do
case $OPTION in
  q)
   QUEUE="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

run_fds_pictures
make_fds_pictures
check_fds_pictures
make_fds_summary



