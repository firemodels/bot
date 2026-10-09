#!/bin/bash
#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo ""
#echo "run_bundlebot.sh usage"
echo ""
echo "This script checks if nightly fds/smv bundles were generated"
echo ""
echo "Options:"
echo "-h - display this message"

if [ "$MAILTO" != "" ]; then
  echo "-m mailto - email address [default: $MAILTO]"
else
  echo "-m mailto - email address"
fi
exit 0
}

while getopts 'hm:' OPTION
do
case $OPTION  in
  h)
   usage
   ;;
  m)
   MAILTO="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))


uploads=fdssmv_uploads.txt
errors=fdssmv_errors.txt
output=output_fdssmv.txt
INFO=FDS_INFO.txt
rm -f $uploads
gh release view FDS_TEST  -R github.com/firemodels/test_bundles | grep nightly_win | awk '{print $2}' >> $uploads
gh release view FDS_TEST  -R github.com/firemodels/test_bundles | grep nightly_lnx | awk '{print $2}' >> $uploads
gh release view FDS_TEST  -R github.com/firemodels/test_bundles | grep nightly_osx | awk '{print $2}' >> $uploads
rm -f $INFO
gh release download FDS_TEST -p $INFO -D .  -R github.com/firemodels/test_bundles
FDS_REVISION=`grep FDS_REVISION $INFO | awk '{print $2}'`
SMV_REVISION=`grep SMV_REVISION $INFO | awk '{print $2}'`
BASE=${FDS_REVISION}_${SMV_REVISION}
FDSWIN=${BASE}_nightly_win
FDSLNX=${BASE}_nightly_lnx
FDSOSX=${BASE}_nightly_osx_arm
rm -f $errors
BUNDLE_STATUS=
if [ `grep $FDSWIN.exe $uploads | wc -l` -eq 0 ]; then
  echo  "***error: $FDSWIN.exe missing" >> $errors
  BUNDLE_STATUS=Windows
fi
if [ `grep $FDSLNX.sh   $uploads  | grep -v sha1 | wc -l` -eq 0 ]; then
  echo  "***error: $FDSLNX.sh missing" >> $errors
  BUNDLE_STATUS="$BUNDLE_STATUS Linux"
fi
if [ `grep $FDSOSX.sh   $uploads  | grep -v sha1 | wc -l` -eq 0 ]; then
  echo  "***error: $FDSOSX.sh missing" >> $errors
  BUNDLE_STATUS="$BUNDLE_STATUS Mac"
fi
if [ "$BUNDLE_STATUS" != "" ]; then
  BUNDLE_STATUS="$BUNDLE_STATUS bundle missing"
fi
echo bundle url: https://github.com/firemodels/test_bundles/releases/tag/FDS_TEST > $output
echo                  >> $output
echo bundles present: >> $output
cat $uploads          >> $output
echo                  >> $output

if [ "$BUNDLE_STATUS" == "" ]; then
  BUNDLE_STATUS="All bundles generated"
fi
if [ -e $errors ]; then
  cat $errors
  echo missing bundles: >> $output
  cat $errors           >> $output
  echo                  >> $output
fi
if [ "$MAILTO" != "" ]; then
  cat $output |  mail -s "$BUNDLE_STATUS" $MAILTO
else
  echo $BUNDLE_STATUS
  cat $output 
fi
