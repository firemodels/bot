#!/bin/bash

#---------------------------------------------
#                   usage
#---------------------------------------------

function usage {
echo "Create an openmpi library"
echo ""
echo "Options:"
echo "-c - compiler [default: $compiler]"
echo "-d - directory containing mpi [default: $MPIROOT]"
echo "-e - ethernet"
echo "-h - display this message"
echo "-i - infiniband (default)"
echo "-l - library name [default: $MPIOUT]"
echo "-m - mpi distribution [default: $MPIIN]"
echo "-r - build library"
echo "-y - answer yes to all questions"
exit
}

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
MPIINNODOT=`echo "${MPIIN//./}"`

IB=
IB=ib

MPIOUT=openmpi${MPIINNODOT}_64$IB
MPILIB=

MPIROOT=/shared

BUILDMPI=
PAUSE=1

while getopts 'c:d:ehil:m:ry' OPTION
do
case $OPTION  in
  c)
   compiler="$OPTARG"
   ;;
  d)
   MPIROOT="$OPTARG"
   ;;
  e)
   IB=
   ;;
  h)
   usage
   exit
   ;;
  i)
   IB=ib
   ;;
  l)
   MPILIB="$OPTARG"
   ;;
  m)
   MPIIN="$OPTARG"
   ;;
  r)
   BUILDMPI=1
   ;;
  y)
   PAUSE=
   ;;
esac
done
shift $(($OPTIND-1))

TAR=openmpi-$MPIIN.tar.gz
MPIINNODOT=`echo "${MPIIN//./}"`
MPIIN_DIR=openmpi-$MPIIN

MPIOUT=openmpi${MPIINNODOT}_64$IB
#MPIOUT=openmpi_64$IB
if [ "$MPILIB" != "" ]; then
  MPIOUT=$MPILIB
fi

SUMMARY=/tmp/SUMMARY.$$
SUMMARY2=$OPENMPI/$MPIOUT/SUMMARY

echo
cat << EOF > $SUMMARY
Summary
        compiler: /opt/$compiler
mpi distribution: $TAR
    mpi location: $MPIROOT/$MPIOUT
EOF
if [ "$IB" != "" ]; then
echo "      infiniband: yes" >> $SUMMARY
else
echo "      infiniband: no" >> $SUMMARY
fi

if [ "$PAUSE" == "" ]; then
  echo
  echo "Press any key to continue or <CTRL> c to abort."
  echo "Type $0 -h for other options"
  read val
fi


HAVE_IB=`echo $MPIOUT | grep 64ib | wc -l`

MAKEINSTALL=$MPIOUT/MAKEINSTALL.sh
CONFIGURE=$MPIOUT/CONFIGURE_MAKE.sh

cd $OPENMPI
rm -rf $MPIOUT

if [ ! -e $TAR ]; then
  echo $TAR does not exist.
  echo script aborted
  cd $CURDIR
  exit
fi

tar xvf $TAR > /dev/null
mv $MPIIN_DIR $MPIOUT
mv $SUMMARY $SUMMARY2

cat << EOF > $CONFIGURE
#!/bin/bash

source /opt/$compiler/bin/compilervars.sh intel64

./configure --prefix /$MPIROOT/$MPIOUT \\
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
  --enable-static --disable-shared | tee CONFIG_STATUS.out

make | tee MAKE_STATUS.out
EOF

chmod +x $CONFIGURE

cat << EOF > $MAKEINSTALL
#!/bin/bash

source /opt/$compiler/bin/compilervars.sh intel64

make install
EOF
chmod +x $MAKEINSTALL

if [ "$BUILDMPI" == "1" ]; then
  cd $MPIOUT
  ./CONFIGURE_MAKE.sh
else
  echo ""
  echo "openmpi build and install scripts generated in "
  echo $OPENMPI/$MPIOUT
fi
