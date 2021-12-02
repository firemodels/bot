#!/bin/bash
scriptname=$1
NCASES_PER_QUEUE=$2
SHOW_EMAIL_HELP=$3

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
echo " -f - override lock to force clusterbot run"
echo " -F - fast checks"
echo " -h - display this message"
if [ "$SHOW_EMAIL_HELP" == "1" ]; then
  echo " -m email_address - send results to email_address"
fi
echo " -n n - run n cases on each queue [default: $NCASES_PER_QUEUE]"
echo " -q q - run test cases using the queue q."
echo " -Q q - same as the -q option except that only test cases are run."
echo "         Other tests are not performed."
echo " -r - check file contents readable only by root.  If this option is not"
echo "      used, only the file size and modification date are checked.  You"
echo "      need to have sudo priviledges to use this option."
echo " -u - update archive files"
