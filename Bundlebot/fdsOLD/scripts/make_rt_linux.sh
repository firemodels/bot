#!/bin/bash
version=2025.0
MPIROOT=/shared/intel/oneapi/mpi/2021.14
COMPROOT=/shared/intel/oneapi/compiler/2025.0

if [ "$version" == "" ]; then
  echo ***error: version undefined, edit $0 to define version
  exit
fi

INTELDIR=$HOME/.bundle
TODIR=$INTELDIR/INTEL

TARBASE=$HOME/.bundle/BUNDLE/MPI/
TARROOT=INTEL${version}linux_64.tar
TARFILE=$TARBASE/$TARROOT

if [ -e $TODIR ]; then
  rm -rf $TODIR
fi
rm -f $TARFILE
rm -f ${TARFILE}.gz

#---------------------------------------------
#                   CP
#---------------------------------------------

CP ()
{
  FROMDIR=$1
  TODIR=$2
  FILE=$3
  if [ -e $FROMDIR/$FILE ]; then
    cp $FROMDIR/$FILE $TOROOT/$TODIR/$FILE
    if [ -e $TOROOT/$TODIR/$FILE ]; then
      echo $FILE copied
    else
      echo $FILE failed to copy
    fi
  else
    echo "***error: $FROMDIR/$FILE does not exist"
  fi
}

TOROOT=$TODIR
mkdir $TOROOT
mkdir $TOROOT/bin
mkdir $TOROOT/lib
mkdir $TOROOT/prov

echo
echo ***copying version info
echo $version > $TODIR/version

echo
echo ***copying lib files
  CP $COMPROOT/lib          lib libiomp5.so
  CP $COMPROOT/lib          lib libintlc.so.5
  CP $COMPROOT/lib          lib libimf.so
  CP $MPIROOT/lib           lib libmpifort.so.12
  CP $MPIROOT/lib/release   lib libmpi.so.12 
  CP $MPIROOT/lib           lib libmpi.so
  CP $MPIROOT/libfabric/lib lib libfabric.so.1

echo
echo ***copying bin files
  CP $MPIROOT/bin bin  hydra_bstrap_proxy
  CP $MPIROOT/bin bin  hydra_nameserver
  CP $MPIROOT/bin bin  hydra_pmi_proxy
  CP $MPIROOT/bin bin  mpirun
  CP $MPIROOT/bin bin  mpiexec.hydra 
  CP $MPIROOT/bin bin  mpiexec
  CP $MPIROOT/bin bin  cpuinfo
  CP $MPIROOT/bin bin  impi_info

echo
echo ***copying prov files
  CP $MPIROOT/libfabric/lib/prov prov  libefa-fi.so
  CP $MPIROOT/libfabric/lib/prov prov  libmlx-fi.so
  CP $MPIROOT/libfabric/lib/prov prov  libpsm3-fi.so
  CP $MPIROOT/libfabric/lib/prov prov  libpsmx2-fi.so
  CP $MPIROOT/libfabric/lib/prov prov  librxm-fi.so
  CP $MPIROOT/libfabric/lib/prov prov  libshm-fi.so
  CP $MPIROOT/libfabric/lib/prov prov  libtcp-fi.so
  CP $MPIROOT/libfabric/lib/prov prov  libverbs-1.12-fi.so
  CP $MPIROOT/libfabric/lib/prov prov  libverbs-1.1-fi.so

CURDIR=`pwd`
cd $INTELDIR
echo
echo ***creating tar file: $TARROOT
tar cvf $TARFILE  INTEL >& /dev/null
echo ***compressing tar file: ${TARROOT}.gz in $TARBASE
gzip $TARFILE
echo ***complete
cd $CURDIR
