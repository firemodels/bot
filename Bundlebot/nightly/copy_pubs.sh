#!/bin/bash
pub_type=$1
error_log=$2

GH_TAG=$GH_FDS_TAG
if [ "$pub_type" != "fds" ]; then
  pub_type="smv"
  GH_TAG=$GH_SMOKEVIEW_TAG
fi

#---------------------------------------------
#                   CP
#---------------------------------------------

CP ()
{
  local FROMFILE=$1
  rm -f $pdf_to/$FROMFILE

  echo "   copying $FROMFILE to $pdf_to"
  gh release download $GH_TAG -p $FROMFILE -R github.com/$GH_OWNER/$GH_REPO -D $pdf_to --clobber
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
  echo ***copying fds pubs from github.com/$GH_OWNER/$GH_REPO using tag: $GH_TAG
  CP FDS_Config_Management_Plan.pdf         || exit 1
  CP FDS_Technical_Reference_Guide.pdf      || exit 1
  CP FDS_User_Guide.pdf                     || exit 1
  CP FDS_Validation_Guide.pdf               || exit 1
  CP FDS_Verification_Guide.pdf             || exit 1
fi

if [ "$pub_type" == "smv" ]; then
  echo ""
  echo ***copying smokeview pubs from github.com/$GH_OWNER/$GH_REPO using tag: $GH_TAG
  CP SMV_Technical_Reference_Guide.pdf      || exit 1
  CP SMV_User_Guide.pdf                     || exit 1
  CP SMV_Verification_Guide.pdf             || exit 1
fi
exit $return_code
