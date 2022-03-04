#!/bin/bash

# ---------------------------- usage ----------------------------------

function usage {
  echo "Usage: qbuild.sh [-d dir ][-q queue]"
  echo ""
  echo "qbuild.sh builds FDS"
  echo ""
  echo " -d dir - directory where fds is built"
  echo " -D     - debug smokeview build"
  echo " -h   - show this message"
  echo " -j prefix  - specif a job prefix"
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
JOBPREFIX=fds_build

#*** define toplevel of the repos

FDSROOT=~/FDS-SMV
if [ "$FIREMODELS" != "" ]; then
  FDSROOT=$FIREMODELS
fi
showscript=
QUEUE=batch
DB=
DEBUG=" "

#*** read in parameters from command line

while getopts 'd:Dhj:q:v' OPTION
do
case $OPTION  in
  d)
   builddir="$OPTARG"
   ;;
  D)
   DB="_db"
   DEBUG=" debug "
   ;;
  h)
   usage
   exit
   ;;
  j)
   JOBPREFIX="$OPTARG"
   ;;
  q)
   QUEUE="$OPTARG"
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

outerr=$fulldir/build.err
outlog=$fulldir/build.log
qlog=$fulldir/build.qlog
scriptlog=$fulldir/build.scriptlog

commandline=`echo $* | sed 's/-V//' | sed 's/-v//'`
scriptfile=`mktemp /tmp/script.$$.XXXXXX`

cat << EOF > $scriptfile
#!/bin/bash
# $0 $commandline
#SBATCH -J $JOBPREFIX
#SBATCH -e $outerr
#SBATCH -o $outlog
#SBATCH --partition=$QUEUE
#SBATCH --ntasks=1
#SBATCH --nodes=1
# #SBATCH --exclusive
#SBATCH --cpus-per-task=4
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
echo "----------------"
export LD_LIBRARY_PATH=/lib64:\$LD_LIBRARY_PATH
cd $fulldir
EOF
if [ -e $fulldir/make_fds.sh ]; then
cat << EOF >> $scriptfile
echo "started fds build at \`date\`"
./make_fds.sh
echo "finished fds build at \`date\`"
EOF
fi
if [ -e $fulldir/make_smokeview$DB.sh ]; then
cat << EOF >> $scriptfile
echo "started$DEBUGsmokeview build at \`date\`"
./make_smokeview$DB.sh
echo "finished$DEBUGsmokeview build at \`date\`"
EOF
fi

#*** output script file to screen if -v option was selected

if [ "$showscript" == "1" ]; then
  cat $scriptfile
  echo
  exit
fi

#*** run script

chmod +x $scriptfile

QSUB="sbatch -p $QUEUE --ignore-pbs"
$QSUB $scriptfile        >& /dev/null 
cat $scriptfile            > $scriptlog
echo "#$QSUB $scriptfile" >> $scriptlog
rm $scriptfile
