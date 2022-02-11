#!/bin/bash
version=oneapiU4

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

FROMROOT=/opt/intel/oneapi/mpi/latest
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
  CP /opt/intel/oneapi/compiler/latest/linux/compiler/lib/intel64_lin lib libiomp5.so
  CP /opt/intel/oneapi/mpi/latest/lib                                 lib libmpifort.so.12
  CP /opt/intel/oneapi/mpi/latest/lib/release                         lib libmpi.so.12 
  CP /opt/intel/oneapi/mpi/latest/libfabric/lib                       lib libfabric.so.1

echo
echo ***copying bin files
  CP /opt/intel/oneapi/mpi/latest/bin bin  hydra_bstrap_proxy
  CP /opt/intel/oneapi/mpi/latest/bin bin  hydra_nameserver
  CP /opt/intel/oneapi/mpi/latest/bin bin  hydra_pmi_proxy
  CP /opt/intel/oneapi/mpi/latest/bin bin  mpirun
  CP /opt/intel/oneapi/mpi/latest/bin bin  mpiexec.hydra 
  CP /opt/intel/oneapi/mpi/latest/bin bin  mpiexec
  CP /opt/intel/oneapi/mpi/latest/bin bin  cpuinfo
  CP /opt/intel/oneapi/mpi/latest/bin bin  impi_info

echo
echo ***copying prov files
  CP /opt/intel/oneapi/mpi/latest/libfabric/lib/prov prov  libefa-fi.so
  CP /opt/intel/oneapi/mpi/latest/libfabric/lib/prov prov  libmlx-fi.so
  CP /opt/intel/oneapi/mpi/latest/libfabric/lib/prov prov  libpsmx2-fi.so
  CP /opt/intel/oneapi/mpi/latest/libfabric/lib/prov prov  librxm-fi.so
  CP /opt/intel/oneapi/mpi/latest/libfabric/lib/prov prov  libshm-fi.so
  CP /opt/intel/oneapi/mpi/latest/libfabric/lib/prov prov  libsockets-fi.so

CURDIR=`pwd`
cd $INTELDIR
echo
echo ***creating tar file: $TARROOT
tar cvf $TARFILE  INTEL >& /dev/null
echo ***compressing tar file: ${TARROOT}.gz
gzip $TARFILE
echo ***complete
cd $CURDIR
