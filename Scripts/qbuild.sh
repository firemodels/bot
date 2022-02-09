#!/bin/bash

# ---------------------------- usage ----------------------------------

function usage {
  echo "Usage: qbuild.sh [-d dir ][-q queue]"
  echo ""
  echo "qbuild.sh builds FDS"
  echo ""
  echo " -d dir - directory where fds is built"
  echo " -h   - show this message"
  echo " -q q - name of queue. [default: batch]"
  echo " -v   - show script"
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
showscript=

#*** read in parameters from command line

while getopts 'd:hq:v' OPTION
do
case $OPTION  in
  d)
   builddir="$OPTARG"
   ;;
  h)
   usage
   exit
   ;;
  q)
   queue="$OPTARG"
   ;;
  v)
   showscript=1
   ;;
esac
done
shift $(($OPTIND-1))

if [ ! -d $builddir ]; then
  echo "***error director $builddir does not exist"
  exit
fi
cd $builddir
fulldir=`pwd`

outerr=$fulldir/fdsbuild.err
outlog=$fulldir/fdsbuild.log

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

echo
echo \`date\`
echo "     Directory: \`pwd\`"
echo "          Host: \`hostname\`"
echo "----------------" >> $qlog
echo "started fds build at \`date\`"  >> $qlog
cd $fulldir
./make_fds.sh                         >> $qlog
echo "finished fds build at \`date\`" >> $qlog
EOF

#*** output script file to screen if -v option was selected

if [ "$showscript" == "1" ]; then
  cat $scriptfile
  echo
  exit
fi

#*** output info to screen
  echo "submitted at `date`"                                      > $qlog
  echo "          Input dir:$builddir"                     | tee -a $qlog
  echo "              Queue:$queue"                        | tee -a $qlog

#*** run script

echo 
chmod +x $scriptfile

$QSUB $scriptfile | tee -a $qlog
cat $scriptfile            > $scriptlog
echo "#$QSUB $scriptfile" >> $scriptlog
rm $scriptfile
