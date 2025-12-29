#!/bin/bash
if [ "$1" == "release" ]; then
  type=
else
  type=_db
fi

# -------------------------------------------------------------

BUILDFDS()
{
  cd $fdsrepo/Build/impi_intel_linux${type}
  echo cleaning `pwd`
  git clean -dxf >& /dev/null
  ./make_fds.sh bot  >> $COMPILELOG 2>&1
}

# -------------------------------------------------------------

CHECK_BUILDFDS()
{
  if [ ! -e $fdsrepo/Build/impi_intel_linux${type}/fds_impi_intel_linux${type} ]; then
    echo "***error: The program fds_impi_intel_linux${type} failed to build"
    echo "***error: The program fds_impi_intel_linux failed to build"  >> $ERRORLOG 2>&1
  else
    echo $fdsrepo/Build/impi_intel_linux/fds_impi_intel_linux$type built
  fi
}

#--------------------- start of script -------------------------------

CURDIR=`pwd`

outputdir=$CURDIR/output
ERRORLOG=$CURDIR/output/fdserror.log
COMPILELOG=$outputdir/compile_fds${type}.log

echo > $COMPILELOG

cd ../..
REPOROOT=`pwd`

cd $REPOROOT/fds
fdsrepo=`pwd`

cd $REPOROOT/bot
botrepo=`pwd`

cd $CURDIR

# build fds apps
echo building fds$type
BUILDFDS

CHECK_BUILDFDS

cd $CURDIR
