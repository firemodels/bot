#!/bin/bash
scriptname=$1
NCASES_PER_QUEUE=$2
SHOW_EMAIL_HELP=$3
EMAIL=$4

#---------------------------------------------
# ---------------------------- USAGE ----------------------------------
#---------------------------------------------

echo "Usage: $scriptname [options]"
echo ""
echo "$scriptname - perform various checks to verify a Linux cluster is working properly. If the -q option"
echo "                is specified, run test cases on multiple nodes. The test cases are very simple designed"
echo "                only to verify that communication works between processes.  To run more realistic test"
echo "                cases, use firebot or smokebot."
echo ""
echo "Options:"
echo " -C - do not run Intel cluster checker"
echo " -f - override lock to force clusterbot run"
echo " -h - display this message"
if [ "$SHOW_EMAIL_HELP" == "1" ]; then
  if [ "$EMAIL" != "" ]; then
    EMAIL="{default: $EMAIL]"
  fi
  echo " -m email_address - send results to email_address $EMAIL"
  echo " -M - only send an email if there are errors or warnings"
fi
echo " -n n - run n cases on each queue [default: $NCASES_PER_QUEUE]"
echo " -N - only perform network checks"
echo " -P password - check ipmi interface using password"
echo " -q q - run test cases using the queue q."
echo " -Q q - same as the -q option except that only test cases are run."
echo "         Other tests are not performed."
echo " -u - update archive files"
echo " -U username - check ipmi interface using username"
