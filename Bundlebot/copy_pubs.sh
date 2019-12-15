#!/bin/bash
pub_type=$1
bot_host=$3
error_log=$4

if [[ "$bot_host" != "" ]] && [[ `hostname` != "$bot_host" ]]; then
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

  if [[ "$bot_host" != "" ]] && [[ `hostname` != "$bot_host" ]]; then
    scp -q $bot_host:$pdf_from/$FROMFILE $pdf_to/.
  else
    if [ -e $pdf_from/$FROMFILE ]; then
      cp $pdf_from/$FROMFILE $pdf_to/.
      if [ -e $pdf_to/$FROMFILE ]; then
        echo $FROMFILE copied to $pdf_to
      else
        echo "" >> $error_log
        echo "***error: $FROMFILE failed to copy to $pdf_to" >> $error_log
        echo ""
        echo "***error: $FROMFILE failed to copy to $pdf_to"
        return_code=1
      fi
    else
      echo "" >> $error_log
      echo "***error: $pdf_from/$FROMFILE does not exist" >> $error_log
      echo ""
      echo "***error: $pdf_from/$FROMFILE does not exist"
      return_code=1
    fi
  fi
}

return_code=0

pdf_to=$HOME/.bundle/pubs

mkdir -p $pdf_to

if [ "$pub_type" == "fds" ]; then
  echo ""
  if [[ "$bot_host" != "" ]] ; then
    echo ***copying fds pubs from $pdf_from on $bot_host
  else
    echo ***copying fds pubs from $pdf_from
  fi
  CP FDS_Config_Management_Plan.pdf
  CP FDS_Technical_Reference_Guide.pdf
  CP FDS_User_Guide.pdf
  CP FDS_Validation_Guide.pdf
  CP FDS_Verification_Guide.pdf
fi

if [ "$pub_type" == "smv" ]; then
  echo ""
  if [[ "$bot_host" != "" ]] ; then
    echo ***copying smokeview pubs from $pdf_from on $bot_host
  else
    echo ***copying smokeview pubs from $pdf_from
  fi
  CP SMV_Technical_Reference_Guide.pdf
  CP SMV_User_Guide.pdf
  CP SMV_Verification_Guide.pdf
fi
exit $return_code
