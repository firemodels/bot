#!/bin/bash

# ---------------------------- usage ----------------------------------

function usage {
  if [ "$use_intel_mpi" == "1" ]; then
    MPI=impi
  else
    MPI=mpi
  fi
  echo "Usage: qbuild.sh [-d dir ][-q queue]"
  echo ""
  echo "qbuild.sh builds FDS"
  echo ""
  echo " -h   - show ptions"
  echo " -d dir - build directory"
  echo " -q q - name of queue. [default: batch]"
  echo "input_file - input file"
  exit
}

#*** get directory containing qbuild.sh

QBUILD_PATH=$(dirname `which $0`)
CURDIR=`pwd`
cd $QFDS_PATH
QFDS_DIR=`pwd`
cd $CURDIR

#*** define toplevel of the repos

FDSROOT=~/FDS-SMV
if [ "$FIREMODELS" != "" ]; then
  FDSROOT=$FIREMODELS
fi

#*** read in parameters from command line

while getopts 'd:hq:' OPTION
do
case $OPTION  in
  d)
   dir="$OPTARG"
   ;;
  h)
   usage
   exit
   ;;
  q)
   queue="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

cat << EOF >> $scriptfile
#SBATCH -J $JOBPREFIX$infile
#SBATCH -e $outerr
#SBATCH -o $outlog
#SBATCH --partition=$queue
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
EOF
if [ "$EMAIL" != "" ]; then
    cat << EOF >> $scriptfile
#SBATCH --mail-user=$EMAIL
#SBATCH --mail-type=ALL
EOF
fi

if [ "$walltimestring_slurm" != "" ]; then
      cat << EOF >> $scriptfile
#SBATCH $walltimestring_slurm

EOF
fi

if [[ "$MODULES" != "" ]]; then
  cat << EOF >> $scriptfile
export MODULEPATH=$MODULEPATH
module purge
module load $MODULES
EOF
fi

cat << EOF >> $scriptfile

cd $fulldir
echo
echo \`date\`
EOF

cat << EOF >> $scriptfile
echo "     Directory: \`pwd\`"
echo "          Host: \`hostname\`"
echo "----------------" >> $qlog
echo "started running at \`date\`" >> $qlog
EOF

cat << EOF >> $scriptfile
echo "finished running at \`date\`" >> $qlog
EOF

#*** output script file to screen if -v option was selected

if [ "$showinput" == "1" ]; then
  cat $scriptfile
  echo
  exit
fi

#*** output info to screen
echo "submitted at `date`"                          > $qlog
if [ "$queue" != "none" ]; then
if [ "$OPENMPCASES" == "" ]; then
  echo "         Input file:$in"             | tee -a $qlog
if [ "$casedir" != "" ]; then
  echo "          Input dir:$casedir"             | tee -a $qlog
fi
else
  echo "         Input files:"               | tee -a $qlog
for i in `seq 1 $OPENMPCASES`; do
  echo "            ${files[$i]}"            | tee -a $qlog
done
fi
  echo "         Executable:$exe"            | tee -a $qlog
  if [ "$OPENMPI_PATH" != "" ]; then
    echo "            OpenMPI:$OPENMPI_PATH" | tee -a $qlog
  fi
  if [ "$use_intel_mpi" != "" ]; then
    echo "           Intel MPI"              | tee -a $qlog
  fi

#*** output modules used when fds is run
  if [[ "$MODULES" != "" ]] && [[ "$MODULES_OUT" == "" ]]; then
    echo "            Modules:$MODULES"                    | tee -a $qlog
  fi
  echo "   Resource Manager:$RESOURCE_MANAGER"             | tee -a $qlog
  echo "              Queue:$queue"                        | tee -a $qlog
fi

#*** run script

echo 
chmod +x $scriptfile

if [ "$queue" != "none" ]; then
  $QSUB $scriptfile | tee -a $qlog
else
  $QSUB $scriptfile
fi
if [ "$queue" != "none" ]; then
  cat $scriptfile > $scriptlog
  echo "#$QSUB $scriptfile" >> $scriptlog
  rm $scriptfile
fi
