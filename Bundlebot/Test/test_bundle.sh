#!/bin/bash
RUN_FDS()
{
P=$1
O=$2
INPUT=$3
  export OMP_NUM_THREADS=$O
  FDS=fds
  if [ "$O" != "1" ]; then
    FDS=fds_openmp
  fi
  echo "MPI processes: $P, OpenMP threads: $O program: $FDS"
  mpiexec -n $P $FDS   $INPUT >& ${INPUT}.out
  success=`grep success ${INPUT}.out | wc -l`
  if [ $success -eq 1 ]; then
    echo "   $INPUT completed successfully"
  else
    echo "   $INPUT failed"
  fi
}

have_mpiexec=`which mpiexec      | wc -l`
have_fds=`which fds              | wc -l`
have_fdsopenmp=`which fds_openmp | wc -l`
have_smokeview=`which smokeview  | wc -l`
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
if [ $have_smokeview -eq 0 ]; then
  echo "***error: smokeview not in path"
  error=1
fi
if [ "$error" != "" ]; then
  echo " setup bash environment so FDS and smokeview are in you path"
  exit
fi

echo "Verify paths below are what you expect"
echo ""
echo "   mpiexec path: `which mpiexec`"
echo "       fds path: `which fds`"
echo "fds_openmp path: `which fds_openmp`"
echo " smokeview path: `which smokeview`"

echo ""
echo "***Press any key to view fds version info or <CTRL> c to abort."
read val

echo "" | fds

echo ""
echo "***Press any key to view fds_openmp version info or <CTRL> c to abort."
read val

echo "" | fds_openmp

echo ""
echo "***Press any key to view smokeview version info or <CTRL> c to abort."
read val

smokeview -v

echo ""
echo "***Press any key to view mpiexec version info or <CTRL> c to abort."
read val

mpiexec -V

echo ""
echo "***Press any key to run test cases or <CTRL> c to abort"
read val

RUN_FDS 1 1 test01a.fds
RUN_FDS 1 4 test01b.fds
RUN_FDS 4 1 test04a.fds
RUN_FDS 4 2 test04b.fds
RUN_FDS 4 2 test04c.fds
