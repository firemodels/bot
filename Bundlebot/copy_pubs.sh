#!/bin/bash
pub_type=$1
bot_host=$3
error_log=$4

if [ "$bot_host" == "" ]; then
  bot_host=`hostname`
fi
if [ `hostname` != "$bot_host" ]; then
  pdf_from=$2
else
  eval pdf_from=$2
fi

if [ "$pub_type" != "fds" ]; then
  pub_type="smv"
fi

#---------------------------------------------
#                   CP
#---------------------------------------------

CP ()
{
  local FROMFILE=$1
  rm -f $pdf_to/$FROMFILE

  echo "copying $FROMFILE on $bot_host to $pdf_to"
  scp -q $bot_host:$pdf_from/$FROMFILE $pdf_to/.
  if [ ! -e $pdf_to/$FROMFILE ]; then
    echo "" >> $error_log
    echo "***error: $FROMFILE failed to copy to $pdf_to" >> $error_log
    echo ""
    echo "***error: $FROMFILE failed to copy to $pdf_to"
    return 1
  fi
  return 0
}

pdf_to=$HOME/.bundle/pubs

mkdir -p $pdf_to

if [ "$pub_type" == "fds" ]; then
  echo ""
  echo ***copying fds pubs from $pdf_from on $bot_host
  CP FDS_Config_Management_Plan.pdf         || exit 1
  CP FDS_Technical_Reference_Guide.pdf      || exit 1
  CP FDS_User_Guide.pdf                     || exit 1
  CP FDS_Validation_Guide.pdf               || exit 1
  CP FDS_Verification_Guide.pdf             || exit 1
fi

if [ "$pub_type" == "smv" ]; then
  echo ""
  echo ***copying smokeview pubs from $pdf_from on $bot_host
  CP SMV_Technical_Reference_Guide.pdf      || exit 1
  CP SMV_User_Guide.pdf                     || exit 1
  CP SMV_Verification_Guide.pdf             || exit 1
fi
exit $return_code
