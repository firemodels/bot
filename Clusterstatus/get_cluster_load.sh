#!/bin/bash

# -------------------- get_host ---------------------------

get_host ()
{
base=$1
ipnum=$2
if [ $ipnum -gt 99 ]; then
  host=$base$ipnum
else
  if [ $ipnum -gt 9 ]; then
    host=${base}0$ipnum
  else
    host=${base}00$ipnum
  fi
fi
echo $host
}

QUEUE=batch
beg=1
end=36

getnodes ()
{
beg=1
end=36
QUEUE=$1
if [ "$QUEUE" == "batch" ]; then
  beg=1
  end=36
fi
if [ "$QUEUE" == "batch2" ]; then
  beg=37
  end=72
fi
if [ "$QUEUE" == "batch3" ]; then
  beg=73
  end=108
fi
if [ "$QUEUE" == "batch4" ]; then
  beg=133
  end=144
fi
if [ "$QUEUE" == "smokebot" ]; then
  beg=109
  end=132
fi
if [ "$QUEUE" == "firebot" ]; then
  beg=109
  end=132
fi
}


getload ()
{
QUEUE=$1
getnodes $QUEUE
HOSTS=
for i in `seq $beg $end ` ; do
  HOST=`get_host blaze $i`
  if [ "$i" == "$beg" ]; then
    HOSTS="$HOSTS $HOST"
  else
    HOSTS="$HOSTS, $HOST"
  fi
done

OUTFILE=/tmp/dsh.out.$$
dsh -f -e "cat /proc/loadavg " -w $HOSTS  >& $OUTFILE
total=`cat $OUTFILE | awk '{SUM+=$2}END{print SUM}'`
rm $OUTFILE
}

getload batch
echo queue=$QUEUE load=$total
getload batch2
echo queue=$QUEUE load=$total
getload batch3
echo queue=$QUEUE load=$total
getload firebot
echo queue=$QUEUE load=$total
getload batch4
echo queue=$QUEUE load=$total
