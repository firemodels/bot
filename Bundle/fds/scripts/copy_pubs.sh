#!/bin/bash
bot_type=$1
pdf_from=$2
bot_host=$3

pdf_to=$HOME/.bundle/pubs

mkdir -p $pdf_to

COPY="cp "
if [ "$bot_host" != "" ]; then
  if [ "$bot_host" != "`uname`" ]; then
    COPY="scp $bot_host:"
  fi
fi

if [ "$bot_type" == "firebot" ]; then
  ${COPY}$pdf_from/FDS_Config_Management_Plan.pdf    $pdf_to/.
  ${COPY}$pdf_from/FDS_Technical_Reference_Guide.pdf $pdf_to/.
  ${COPY}$pdf_from/FDS_User_Guide.pdf                $pdf_to/.
  ${COPY}$pdf_from/FDS_Validation_Guide.pdf          $pdf_to/.
  ${COPY}$pdf_from/FDS_Verification_Guide.pdf        $pdf_to/.
fi

if [ "$bot_type" == "smokebot" ]; then
  ${COPY}$pdf_from/SMV_Technical_Reference_Guide.pdf $pdf_to/.
  ${COPY}$pdf_from/SMV_User_Guide.pdf                $pdf_to/.
  ${COPY}$pdf_from/SMV_Verification_Guide.pdf        $pdf_to/.
fi
