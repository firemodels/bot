#!/bin/bash
version=oneapiU3
TODIR=/tmp/INTEL

TARFILE=$HOME/.bundle/BUNDLE/MPI/INTEL${version}linux_64.tar

if [ -e $TODIR ]; then
  rm -rf $TODIR
fi
rm -f $TARFILE
rm -f ${TARFILE}.gz

FROMROOT=/opt/intel/oneapi/mpi/latest
TOROOT=$TODIR

#---------------------------------------------
#                   CP
#---------------------------------------------

CP ()
{
  FROMDIR=$1
  TODIR=$2
  FILE=$3
  FULLFILE=$FROMDIR/$FILE
  if [ -e $FULLFILE ]; then
    cp $FULLFILE $TOROOT/$TODIR/.
    echo "$FULLFILE copied"
  else
    echo "***error: $FULLFILE does not exist"
  fi
}



mkdir $TOROOT
mkdir $TOROOT/bin
mkdir $TOROOT/lib
mkdir $TOROOT/prov
echo $version > $TODIR/version

cp $FROMROOT/bin/hydra_bstrap_proxy $TOROOT/bin/.

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
cd /tmp
echo
echo ***creating compressed tar file: $TARFILE
tar cvf $TARFILE  INTEL
gzip $TARFILE
cd $CURDIR
