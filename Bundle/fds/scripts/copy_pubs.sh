#!/bin/bash
bot_type=$1
pdf_from=$2
bot_host=$3

#---------------------------------------------
#                   CP
#---------------------------------------------

CP ()
{
  local FROMFILE=$1
  if [[ "$bot_host" != "" ]] && [[ "$bot_host" != "`hostname`" ]]; then
    scp $bot_host:$pdf_from/$FROMFILE $pdf_to/.
    echo $FROMFILE copied to $pdf_to
  else
    cp $pdf_from/$FROMFILE $pdf_to/.
  fi
  echo $FROMFILE copied to $pdf_to
}

pdf_to=$HOME/.bundle/pubs

mkdir -p $pdf_to

if [ "$bot_type" == "firebot" ]; then
  echo
  echo ***copying fds pubs
  CP FDS_Config_Management_Plan.pdf
  CP FDS_Technical_Reference_Guide.pdf
  CP FDS_User_Guide.pdf
  CP FDS_Validation_Guide.pdf
  CP FDS_Verification_Guide.pdf
fi

if [ "$bot_type" == "smokebot" ]; then
  echo
  echo ***copying smokeview pubs
  CP SMV_Technical_Reference_Guide.pdf
  CP SMV_User_Guide.pdf
  CP SMV_Verification_Guide.pdf
fi
