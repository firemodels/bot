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

#---------------------------------------------
#                   SCANVIRUSLOG
#---------------------------------------------

SCANVIRUSLOG(){
  PLATFORM=$1
  SCANLOGFILE=$2
  ninfected=`grep 'Infected files' $SCANLOGFILE | awk -F: '{print $2}'`
  if [ "$ninfected" == "" ]; then
    ninfected=0
  fi
  if [[ $ninfected -ne 0 ]]; then
    echo "***error: $ninfected files found with a virus and/or malware in $SCANLOGFILE$" >> $SCANERRORLOG
    grep -v OK$ $SCANLOGFILE                                                             >> $SCANERRORLOG
  fi
  echo $PLATFORM summary:                                  >> $SCANSUMMARY
  grep -v OK$ $SCANLOGFILE | grep -v ^$ | grep -v SUMMARY  >> $SCANSUMMARY
  echo ""                                                  >> $SCANSUMMARY
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


SCANERRORLOG=scan_errors.txt
SCANSUMMARY=scan_summary.txt
uploads=fdssmv_uploads.txt
errors=fdssmv_errors.txt
output=output_fdssmv.txt
INFO=FDS_INFO.txt
rm -f $uploads
rm -f $SCANERRORLOG
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
FDSOSX=${BASE}_nightly_osx
rm -f $errors
if [ `grep $FDSWIN.exe $uploads | wc -l` -eq 0 ]; then
  echo  "***error: $FDSWIN.exe missing" >> $errors
fi
if [ `grep $FDSLNX.sh   $uploads  | grep -v sha1 | wc -l` -eq 0 ]; then
  echo  "***error: $FDSLNX.sh missing" >> $errors
fi
if [ `grep $FDSOSX.sh   $uploads  | grep -v sha1 | wc -l` -eq 0 ]; then
  echo  "***error: $FDSOSX.sh missing" >> $errors
fi
echo bundle url: https://github.com/firemodels/test_bundles/releases/tag/FDS_TEST > $output
echo                  >> $output
echo bundles present: >> $output
cat $uploads          >> $output
echo                  >> $output

rm -f $SCANSUMMARY
#copy virus logs 
if [[ "$OSX_BUNDLE_HOST" != "" ]] && [[ "$OSX_BOT_HOME" != "" ]]; then
  scp -q $OSX_BUNDLE_HOST:$OSX_BOT_HOME/Bundlebot/nightly/output/scanlog output/scanlog_osx  > /dev/null
  SCANVIRUSLOG OSX output/scanlog_osx
fi
cp output/scanlog output/scanlog_linux
SCANVIRUSLOG Linux output/scanlog

VIRUS_STATUS="No Linux/OSX viruses found"
if [[ -s $SCANERRORLOG ]]; then
  VIRUS_STATUS="***error: viruses found"
fi
BUNDLE_STATUS="All bundles generated"
if [ -e $errors ]; then
  cat $errors
  echo missing bundles: >> $output
  cat $errors           >> $output
  echo                  >> $output
fi
if [ "$MAILTO" != "" ]; then
  cat $output $SCANSUMMARY |  mail -s "$VIRUS_STATUS, $BUNDLE_STATUS" $MAILTO
else
  echo $VIRUS_STATUS, $BUNDLE_STATUS
  cat $output $SCANSUMMARY 
fi
