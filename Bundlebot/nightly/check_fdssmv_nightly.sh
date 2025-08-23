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
output=output.txt
INFO=FDS_INFO.txt
rm -f $uploads
gh release view FDS_TEST  -R github.com/firemodels/test_bundles | grep test_win | awk '{print $2}' >> $uploads
gh release view FDS_TEST  -R github.com/firemodels/test_bundles | grep test_lnx | awk '{print $2}' >> $uploads
gh release view FDS_TEST  -R github.com/firemodels/test_bundles | grep test_osx | awk '{print $2}' >> $uploads
rm -f $INFO
gh release download FDS_TEST -p $INFO -D .  -R github.com/firemodels/test_bundles
FDS_REVISION=`grep FDS_REVISION $INFO | awk '{print $2}'`
SMV_REVISION=`grep SMV_REVISION $INFO | awk '{print $2}'`
BASE=${FDS_REVISION}_${SMV_REVISION}
FDSWIN=${BASE}_test_win
FDSLNX=${BASE}_test_lnx
FDSOSX=${BASE}_test_osx
rm -f $errors
if [ `grep $FDSWIN.exe $uploads | wc -l` -eq 0 ]; then
  echo  "***error: $FDSWIN.exe missing" >> $errors
fi
if [ `grep $FDSWIN.sha1 $uploads | wc -l` -eq 0 ]; then
  echo  "***error: $FDSWIN.sha1 missing" >> $errors
fi
if [ `grep $FDSLNX.sh   $uploads  | grep -v sha1 | wc -l` -eq 0 ]; then
  echo  "***error: $FDSLNX.sh missing" >> $errors
fi
if [ `grep $FDSLNX.sha1 $uploads  | wc -l` -eq 0 ]; then
  echo  "***error: $FDSLNX.sha1 missing" >> $errors
fi
if [ `grep $FDSOSX.sh   $uploads  | grep -v sha1 | wc -l` -eq 0 ]; then
  echo  "***error: $FDSOSX.sh missing" >> $errors
fi
if [ `grep $FDSOSX.sha1 $uploads  | wc -l` -eq 0 ]; then
  echo  "***error: $FDSOSX.sha1 missing" >> $errors
fi
echo bundle url: https://github.com/firemodels/test_bundles/releases/tag/FDS_TEST > $output
echo                  >> $output
echo bundles present: >> $output
cat $uploads          >> $output
echo                  >> $output
if [ -e $errors ]; then
  cat $errors
  echo missing bundles: >> $output
  cat $errors           >> $output
  echo                  >> $output
  if [ "$MAILTO" != "" ]; then
    cat $output | mail -s "***error: one or more FDS/Smokeview nightly bundles were not generated" $MAILTO
  fi
else
  if [ "$MAILTO" != "" ]; then
    cat $output | mail -s "All FDS/Smokeview nightly bundles were generated" $MAILTO
  else
    echo All FDS/Smokeview nightly bundles were generated
  fi
fi
