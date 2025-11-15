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


uploads=smv_uploads.txt
errors=smv_errors.txt
output=output_smv.txt
INFO=SMV_INFO.txt
rm -f $uploads
gh release view SMOKEVIEW_TEST  -R github.com/firemodels/test_bundles | grep _win | awk '{print $2}' >> $uploads
gh release view SMOKEVIEW_TEST  -R github.com/firemodels/test_bundles | grep _lnx | awk '{print $2}' >> $uploads
gh release view SMOKEVIEW_TEST  -R github.com/firemodels/test_bundles | grep _osx | awk '{print $2}' >> $uploads
rm -f $INFO
gh release download SMOKEVIEW_TEST -p $INFO     -D .  -R github.com/firemodels/test_bundles
SMV_REVISION=`grep SMV_REVISION $INFO | awk '{print $2}'`
SMV_HASH=`grep SMV_HASH $INFO | awk '{print $2}'`
SMV_HASH=g${SMV_HASH:0:7}
BASE=${SMV_REVISION}-${SMV_HASH}
SMVWIN=${BASE}_win
SMVLNX=${BASE}_lnx
SMVOSX=${BASE}_osx
rm -f $errors
if [ `grep "$SMVWIN.exe" $uploads | wc -l` -eq 0 ]; then
  echo  "***error: $SMVWIN.exe missing" >> $errors
fi
if [ `grep $SMVLNX.sh   $uploads  | grep -v sha1 | wc -l` -eq 0 ]; then
  echo  "***error: $SMVLNX.sh missing" >> $errors
fi
if [ `grep $SMVOSX.sh   $uploads  | grep -v sha1 | wc -l` -eq 0 ]; then
  echo  "***error: $SMVOSX.sh missing" >> $errors
fi
echo "bundle url: https://github.com/firemodels/test_bundles/releases/tag/SMOKEVIEW_TEST" > $output
echo                  >> $output
echo bundles present: >> $output
cat $uploads          >> $output
echo                  >> $output
if [ -e $errors ]; then
  cat $errors
  if [ "$MAILTO" != "" ]; then
    cat $errors >> $output
    cat $output | mail -s "***error: one or more Smokeview nightly bundles were not generated" $MAILTO
  fi
else
  if [ "$MAILTO" != "" ]; then
    cat $output | mail -s "All Smokeview nightly bundles were generated" $MAILTO
  else
    echo All Smokeview nightly bundles were generated
  fi
fi
