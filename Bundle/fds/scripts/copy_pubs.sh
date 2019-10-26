#!/bin/bash
pub_type=$1
pdf_from=$2
bot_host=$3

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
    cp $pdf_from/$FROMFILE $pdf_to/.
  fi
  if [ -e $pdf_to/$FROMFILE ]; then
    echo $FROMFILE copied to $pdf_to
  else
    echo ***error: $FROMFILE failed to copy to $pdf_to
    return_code=1
  fi
}

return_code=0

pdf_to=$HOME/.bundle/pubs

mkdir -p $pdf_to

if [ "$pub_type" == "fds" ]; then
  echo
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
  echo
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
