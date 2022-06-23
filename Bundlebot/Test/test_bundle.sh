#!/bin/bash
QFDS="../../../fds/Utilities/Scripts/qfds.sh -j BUN"
RUN_FDS()
{
P=$1
O=$2
INPUT=$3
if [ "`uname`" == "Darwin" ]; then
  export OMP_NUM_THREADS=$O
  FDS=fds
  if [ "$O" != "1" ]; then
    FDS=fds_openmp
  fi
  mpiexec -n $P $FDS $INPUT
else
  $QFDS -i -o $O -p $P $INPUT
fi
}

if [ "`uname`" == "Darwin" ]; then
  have_mpiexec=`which mpiexec      | wc -l`
  have_fds=`which fds              | wc -l`
  have_fdsopenmp=`which fds_openmp | wc -l`
  error=
  if [ $have_mpiexec -eq 0 ]; then
    echo "***error: mpiexec not in path"
    error=1
  fi
  if [ $have_fds -eq 0 ]; then
    echo "***error: fds not in path"
    error=1
  fi
  if [ $have_fdsopenmp -eq 0 ]; then
    echo "***error: fds_openmp not in path"
    error=1
  fi
  if [ "$error" != "" ]; then
    exit
  fi
fi

RUN_FDS 1 1 test01a.fds
RUN_FDS 1 4 test01b.fds
RUN_FDS 4 1 test04a.fds
RUN_FDS 4 2 test04b.fds
