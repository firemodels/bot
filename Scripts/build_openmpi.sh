#!/bin/bash
CURDIR=`pwd`
OPENMPI=~/OPENMPI
if [ ! -e $OPENMPI ]; then
  mkdir $OPENMPI
fi

#compiler=intel
compiler=intel16
#compiler=intel17

MPIIN=1.8.4
#MPIIN=2.0.1
TAR=openmpi-$MPIIN.tar.gz
MPIIN_DIR=openmpi-$MPIIN

#MPIOUT=openmpi_64
MPIOUT=openmpi_i16_64ib
#MPIOUT=openmpi201_64ib

HAVE_IB=`echo $MPIOUT | grep 64ib | wc -l`

MAKEINSTALL=$MPIOUT/MAKEINSTALL.sh
SUMMARY=$MPIOUT/SUMMARY
CONFIGURE=$MPIOUT/CONFIGURE_MAKE.sh

cd $OPENMPI
rm -rf $MPIOUT

if [ -e $TAR ]; then
  tar xvf $TAR > /dev/null
else
  echo $TAR does not exist.
  echo script aborted
  cd $CURDIR
  exit
fi
mv $MPIIN_DIR $MPIOUT

cat << EOF > $CONFIGURE
#!/bin/bash

source /opt/$compiler/bin/compilervars.sh intel64

./configure --prefix /shared/$MPIOUT \\
  CC=icc CXX=icpc F77=ifort FC=ifort CFLAGS="-m64 -O2" CXXFLAGS="-m64 -O2" \\
  FFLAGS="-m64 -O2" FCFLAGS="-m64 -O2" LDFLAGS=-m64 \\
  --with-tm=/usr/local/torque \\
  --enable-mpirun-prefix-by-default \\
EOF

if [ "$HAVE_IB" != "0" ]; then
cat << EOF >> $CONFIGURE
  --with-verbs=/user --with-verbs-libdir=/usr/lib64 \\
EOF
fi

cat << EOF >> $CONFIGURE
  --enable-static --disable-shared | tee CONFIGURE.out

make | tell MAKE.out
EOF

chmod +x $CONFIGURE

cat << EOF > $MAKEINSTALL
#!/bin/bash

source /opt/$compiler/bin/compilervars.sh intel64

make install
EOF
chmod +x $MAKEINSTALL

cat << EOF > $SUMMARY
   compiler: /opt/$compiler
      MPIIN: $MPIIN
mpi library: /shared/$MPIOUT
EOF
cd $MPIOUT
./CONFIGURE_MAKE.sh
