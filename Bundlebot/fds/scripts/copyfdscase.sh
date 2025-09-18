#!/bin/bash
while getopts 'Ad:p:n:o:O:tT:' OPTION
do
case $OPTION  in
  A)
   dummy3="xxx"
   ;;
  d)
   dir="$OPTARG"
   ;;
  n)
   dummy="$OPTARG"
   ;;
  o)
   dummy="$OPTARG"
   ;;
  O)
   dummy="$OPTARG"
   ;;
  p)
   dummy2="$OPTARG"
   ;;
  t)
   dummy3="xxx"
   ;;
  T)
   dummy4="$OPTARG"
   ;;
esac
done
shift $(($OPTIND-1))

in=$1
infile=${in%.*}

cd $dir
if ! [ -d $OUTDIR/$dir ]; then
  mkdir $OUTDIR/$dir
fi

cp $infile.fds $OUTDIR/$dir/.
if [ -e $infile.ini ]; then
  cp $infile.ini $OUTDIR/$dir/.
fi

if [ -e $infile.ssf ]; then
  cp $infile.ssf $OUTDIR/$dir/.
fi
