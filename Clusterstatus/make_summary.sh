#!/bin/bash
HOST_BASE=spark
HOST_BEG=1
HOST_END=36

logdir=$HOME/.cluster_status
lockfile=$logdir/lockfile_make_summary
if [ -e $lockfile ]; then
  echo "***error: make_summary.sh script already running"
  echo " exiting"
  exit
fi
touch $lockfile

TIMELENGTH=7.0
HOSTS_PER_ROW=5

webpage=$1
if [ "$webpage" == "" ]; then
  if [ "$STATUS_WEBPAGE" == "" ]; then
    webpage=/var/www/html/summary.html
  else
    webpage=$STATUS_WEBPAGE
  fi
fi

TEMP_IP=$2

if [[ "$TEMP_IP" == "" ]] && [[ "$STATUS_TEMP_IP" != "" ]]; then
  TEMP_IP=$STATUS_TEMP_IP
fi

allnodes=/tmp/allnodes.$$
downnodes=/tmp/downnodes.$$
upnodes=/tmp/upnodes.$$
./Get_Host_Status.sh $HOST_BASE $HOST_BEG $HOST_END $allnodes $downnodes $upnodes

UP_HOSTS=`cat $upnodes`
ALL_HOSTS=`cat $allnodes`

rm -rf $allnodes
rm -rf $upnodes
rm -rf $downnodes

temp_webpage=summary.html
webdir=${webpage%/*}

temp_webpage_day=$webdir/summary_day.html
temp_webpage_week=$webdir/summary_week.html

currentdate=`date "+%b %d %Y %R:%S"`
cluster_host=`hostname -s`
updir=$logdir/up
downdir=$logdir/down
loadfile=$logdir/load_${cluster_host}.csv

# ---------------------------- get_temp ----------------------------------
get_temp()
{
  if [ "$TEMP_IP" != "" ]; then
    CURDIR=`pwd`
    cd $logdir
    rm -f temp
    wget -o test.out $TEMP_IP
    if [ -e temp ]; then
    temp=`cat temp| awk -F'|' '{print $(2)'}`
    fi
    rm -f test.out temp
    cd $CURDIR
  fi
}

# ---------------------------- get_decdate ----------------------------------
get_decdate()
{
  d=`date "+%j"`
  h=`date "+%k"`
  m=`date "+%M"`
  s=`date "+%S"`
  OFFSET=366.0
  decdate=`echo "scale=5; $OFFSET + $d + $h/24.0 + $m/(60*24) + $s/(3600*24)" | bc`
  fulldate=`date "+%D %R:%S"`
}

get_decdate
get_temp
if [ "$temp" == "" ]; then
  temp=67.1234
fi

login_mem=`top -b -n 1 | head -4 | tail -1 | awk '{print $8}'`
head_load=`ssh $CB_HEAD cat /proc/loadavg | awk '{print $3}'`
head_load1=`ssh $CB_HEAD cat /proc/loadavg | awk '{print $1}'`
head_load5=`ssh $CB_HEAD cat /proc/loadavg | awk '{print $2}'`
login_load=`cat /proc/loadavg | awk '{print $3}'`
login_load1=`cat /proc/loadavg | awk '{print $1}'`
login_load5=`cat /proc/loadavg | awk '{print $2}'`
total_load=`pdsh -t 1 -w $CB_HOSTS cat /proc/loadavg | awk '{print $3}' | awk  '{sum+=$1;}END{print sum;}'`

echo "$decdate,$total_load,$temp,$head_load,$login_load,$total_load,$login_mem" >> $loadfile

cat << EOF > $temp_webpage
<!DOCTYPE html>
<meta http-equiv="refresh" content="300">
<html>
<head>
    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
EOF

./make_plots.sh  300 $loadfile 7.0 day  >> $temp_webpage
./make_plots.sh 4000 $loadfile 7.0 week >> $temp_webpage

cat << EOF >> $temp_webpage
</script>
<title>$cluster_host Cluster Status - $currentdate</title>
</head>
<body>
EOF
if [ "$TEMP_IP" != "" ]; then
cat << EOF >> $temp_webpage
<hr>
<h2>$CB_BASE cluster status - $currentdate - $temp &deg;F</h2>
EOF
else
cat << EOF >> $temp_webpage
<hr>
<h2>$CB_BASE cluster status - $currentdate</h2>
EOF
fi

./get_user_usage.sh $head_load $login_load >> $temp_webpage

# ---------------------------- host_down_entry ----------------------------------
function host_down_entry {
if [ -e $updir/$host ]; then
  continue
fi
count=$((count+1))
newrow=$((count%$HOSTS_PER_ROW))
if [ $newrow -eq 1 ]; then
  echo "<tr>" >> $temp_webpage
fi
  cat << EOF >> $temp_webpage
  <td bgcolor="#000000"><font color="white">$host</font></td>
EOF
if [ $newrow -eq 0 ]; then
  echo "</tr>" >> $temp_webpage
fi
}

# ---------------------------- host_count_entry ----------------------------------
function host_count_entry {
skip=
if [ -e $updir/$host ]; then
  load=`cat $updir/$host`
  if [ "$load" == "" ]; then
    skip=1
  fi
  if (( $(echo "$load < 0.00" | bc -l) )); then
    skip=1
  fi
else
  skip=1
fi
if [ "$skip" == "" ]; then
  count=$((count+1))
fi
}

# ---------------------------- host_entry ----------------------------------
function host_entry {
if [ -e $updir/$host ]; then
  load=`cat $updir/$host`
  if [ "$load" == "" ]; then
    continue
  fi
  if (( $(echo "$load < 0.00" | bc -l) )); then
    continue
  fi
else
   load=0.0
#  continue
fi
count=$((count+1))
newrow=$((count%$HOSTS_PER_ROW))

if [ -e ./newrow.sh ]; then
  source ./newrow.sh $host $temp_webpage
fi

if [ $newrow -eq 1 ]; then
  echo "<tr>" >> $temp_webpage
  if [ "$BEGIN" == "1" ]; then
    if [ -e ./firstqueue.sh ]; then
      source ./firstqueue.sh $temp_webpage
      count=2
    fi
  fi
fi

if [ -e $updir/$host ]; then
load=`cat $updir/$host`
else
load=0.0
fi

if (( $(echo "$load >  47.99" | bc -l) )); then
  bgcolor=#ff0000
else
  if (( $(echo "$load >  15.99" | bc -l) )); then
    bgcolor=#ffff00
  else
    if (( $(echo "$load >  0.99" | bc -l) )); then
      bgcolor=#33ffff
    else
      bgcolor=#ffffff
    fi
  fi
fi

if [ -e $downdir/$host ]; then
  bgcolor=#000000
cat << EOF >> $temp_webpage
<td bgcolor="$bgcolor"><font color="white">$host</font></td>
EOF
else
cat << EOF >> $temp_webpage
<td bgcolor="$bgcolor"><font color="black">$host $load</font></td>
EOF
fi

if [ $newrow -eq 0 ]; then
  echo "</tr>" >> $temp_webpage
fi
}

# count entries
count=0
for host in $UP_HOSTS
do
host_count_entry
done

# output cluster load

if [ $count -gt 0 ]; then
cat << EOF >> $temp_webpage
<p>
<table border=on>
<tr>
<td bgcolor="#ffffff">load &lt; 1.0</td>
<td bgcolor="#33ffff">1.0 &le; load &lt; 16.0</td>
<td bgcolor="#ffff00">16.0 &le; load &lt; 48.0</td>
<td bgcolor="#ff0000">load &ge; 48.0</td>
<td bgcolor="#000000"><font color="white">Down</font></td>
</tr>
</table>
EOF
fi

cat << EOF >> $temp_webpage
<p><table border=on>
EOF

# output individual node entries

count=0
newrow=0
BEGIN=1
#for host in $UP_HOSTS
for host in $ALL_HOSTS
do
host_entry
BEGIN=0
done
if [ $newrow -ne 0 ]; then
  echo "</tr>" >> $temp_webpage
fi
cat << EOF >> $temp_webpage
</table>
EOF

cp $temp_webpage $temp_webpage_day
cp $temp_webpage $temp_webpage_week

# week plots
cat << EOF >> $temp_webpage_week
<p><a href="summary_day.html">[Hourly Plots]</a>
[Daily Plots]
EOF
if [ "$TEMP_IP" != "" ]; then
cat << EOF >> $temp_webpage_week
<div id="temp_plotweek" style="width: 750px; height: 200px"></div><br>
EOF
fi
cat << EOF >> $temp_webpage_week
<div id="load_plotweek"      style="width: 750px; height: 200px"></div>
<div id="load_headplotweek"  style="width: 750px; height: 200px"></div>
<div id="load_loginplotweek" style="width: 750px; height: 200px"></div>
<div id="mem_loginplotweek"  style="width: 750px; height: 200px"></div>
</body>
</html>
EOF

# day plots
cat << EOF >> $temp_webpage_day
<p>[Hourly Plots]
<a href="summary.html">[Daily Plots]</a>
EOF
if [ "$TEMP_IP" != "" ]; then
cat << EOF >> $temp_webpage_day
<div id="temp_plotday" style="width: 750px; height: 200px"></div><br>
EOF
fi
cat << EOF >> $temp_webpage_day
<div id="load_plotday"      style="width: 750px; height: 200px"></div>
<div id="load_headplotday"  style="width: 750px; height: 200px"></div>
<div id="load_loginplotday" style="width: 750px; height: 200px"></div>
<div id="mem_loginplotday"  style="width: 750px; height: 200px"></div>
</body>
</html>
EOF
mv $temp_webpage_week $webpage
rm $temp_webpage
rm $lockfile
