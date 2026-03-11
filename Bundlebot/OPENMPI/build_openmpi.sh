#!/bin/bash

FILE=openmpi-5.0.10.tar.gz
DIR=`basename $FILE .tar.gz`
if [ ! -e $FILE ]; then
  echo "*** downloading $FILE"
  wget https://download.open-mpi.org/release/open-mpi/v5.0/$FILE
fi
if [ -e $FILE ]; then
  if [ -d $DIR ]; then
    echo "*** removing $DIR"
    rm -r $DIR
  fi
  echo "*** unpacking $FILE to $DIR"
  tar xvf $FILE >& /dev/null
else
  echo "***error: $FILE does not exist"
  exit
fi

cd $DIR
echo "*** configuring openmpi"
./configure --prefix /opt/openmpi509 \
  CC=clang CXX=clang++ F77=ifort FC=ifort \
  CFLAGS="-O2 " \
  CXXFLAGS="-O2 " \
  FFLAGS="-O2 " FCFLAGS="-O2" \
   LDFLAGS="-framework CoreFoundation" \
  --without-tm \
  --without-psm\
  --enable-mpirun-prefix-by-default \
  --without-verbs \
  --enable-static --disable-shared | tee CONFIGURE.out

echo "*** building openmpi"
make -j 4

