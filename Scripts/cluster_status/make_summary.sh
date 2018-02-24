#!/bin/bash
TIMELENGTH=7.0

if [ "$1" == "" ]; then
  webpage=/var/www/html/summary.html
else
  webpage=$1
fi
# set TEMP_IP to blank if you don't have a temperature sensor
if [ "$2" == "" ]; then
  TEMP_IP=129.6.159.193/temp
else
  if [ "$2" == "null" ]; then
    TEMP_IP=
  else
    TEMP_IP=$2
  fi
fi

# up nodes
nodefile=/tmp/nodefile.$$
pbsnodes -l free | awk '{print $1}'          >  $nodefile
pbsnodes -l job-exclusive | awk '{print $1}' >> $nodefile
pbsnodes -l job-sharing | awk '{print $1}'   >> $nodefile
pbsnodes -l busy | awk '{print $1}'          >> $nodefile
pbsnodes -l time-shared | awk '{print $1}'   >> $nodefile
UP_HOSTS=`sort -u $nodefile`

# add down/offline nodes to up nodes to get all nodes
pbsnodes -l | awk '{print $1}' >> $nodefile
ALL_HOSTS=`sort -u $nodefile`
rm -rf $nodefile

logdir=$HOME/.cluster_status
temp_webpage=summary.html
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
    temp=`cat temp| awk -F'|' '{print $(2)'}`
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
  decdate=`echo "scale=5; $d + $h/24.0 + $m/(60*24) + $s/(3600*24)" | bc`
  fulldate=`date "+%D %R:%S"`
}

# ---------------------------- add_load ----------------------------------
function add_load {
host=$1
if [ -e $updir/$host ]; then
  load=`cat $updir/$host`
  if [ "$load" == "" ]; then
    load=0.0
  fi
  total_load="$( bc <<<"$total_load + $load" )"
fi
}

get_decdate
get_temp

# compute total load
total_load=0.0
for host in $UP_HOSTS
do
add_load $host
done
echo "$decdate,$total_load,$temp" >> $loadfile

cat << EOF > $temp_webpage
<!DOCTYPE html>
<meta http-equiv="refresh" content="300">
<html>
<head>
    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
      google.charts.load('current', {'packages':['corechart']});
EOF
# temperature plot

if [ "TEMP_IP" != "" ]; then
cat << EOF >> $temp_webpage
      google.charts.setOnLoadCallback(drawTempPlot);
      function drawTempPlot() {
        var data = google.visualization.arrayToDataTable([
          ['days since Jan 1', 'temperature (F)'],
EOF

lasttime=`cat $loadfile | tail -1 | awk -F',' '{print $1}'`
firsttime="$( bc <<<"$lasttime - $TIMELENGTH" )"
cat $loadfile | awk -v firsttime="$firsttime" -F',' '{if($1>firsttime) { printf("[%s,%s],\n",$1,$3) }}'  >> $temp_webpage

cat << EOF >> $temp_webpage
        ]);

        var options = {
          title: '',
          curveType: 'line',
          legend: { position: 'right' },
          colors: ['black'],
          hAxis:{ title: 'Day'},
          vAxis:{ title: 'Temperature \xB0F'}
        };
        options.legend = 'none';

        var chart = new google.visualization.LineChart(document.getElementById('temp_plot'));

        chart.draw(data, options);
      }
EOF
fi

# begin load plot

cat << EOF >> $temp_webpage
      google.charts.setOnLoadCallback(drawLoadPlot);
      function drawLoadPlot() {
        var data = google.visualization.arrayToDataTable([
          ['days since Jan 1', 'load'],
EOF

cat $loadfile | awk -v firsttime="$firsttime" -F',' '{if($1>firsttime) { printf("[%s,%s],\n",$1,$2) }}'  >> $temp_webpage

cat << EOF >> $temp_webpage
        ]);

        var options = {
          title: '',
          curveType: 'line',
          legend: { position: 'right' },
          colors: ['black'],
          hAxis:{ title: 'Day'},
          vAxis:{ title: 'Load'}
        };
        options.legend = 'none';

        var chart = new google.visualization.LineChart(document.getElementById('load_plot'));

        chart.draw(data, options);
      }
EOF
# end load plot

cat << EOF >> $temp_webpage
    </script>
<title>$cluster_host Cluster Status - $currentdate</title>
</head>
<body>
<h2>$cluster_host cluster status - $currentdate</h2>
EOF

cat << EOF >> $temp_webpage
<h3>
Load: $total_load<br>
EOF
if [ "$TEMP_IP" != "" ]; then
cat << EOF >> $temp_webpage
Temperature: $temp &deg;F
EOF
fi
cat << EOF >> $temp_webpage
</h3>
EOF

# ---------------------------- host_down_entry ----------------------------------
function host_down_entry {
if [ -e $updir/$host ]; then
  continue
fi
count=$((count+1))
newrow=$((count%6))
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
if [ -e $updir/$host ]; then
  load=`cat $updir/$host`
  if [ "$load" == "" ]; then
    continue
  fi
  if (( $(echo "$load <  1.00" | bc -l) )); then
    continue
  fi
else
  continue
fi
count=$((count+1))
}

# ---------------------------- host_entry ----------------------------------
function host_entry {
if [ -e $updir/$host ]; then
  load=`cat $updir/$host`
  if [ "$load" == "" ]; then
    continue
  fi
  if (( $(echo "$load <  1.00" | bc -l) )); then
    continue
  fi
else
  continue
fi
count=$((count+1))
newrow=$((count%6))
if [ $newrow -eq 1 ]; then
  echo "<tr>" >> $temp_webpage
fi

load=`cat $updir/$host`

if (( $(echo "$load >  5.99" | bc -l) )); then
  bgcolor=#ff0000
else
  if (( $(echo "$load >  1.99" | bc -l) )); then
    bgcolor=#ffff00
  else
    bgcolor=#ffffff
  fi
fi

cat << EOF >> $temp_webpage
<td bgcolor="$bgcolor"><font color="black">$host $load</font></td>
EOF

if [ $newrow -eq 0 ]; then
  echo "</tr>" >> $temp_webpage
fi
}

num_downhosts=`ls -l $downdir | wc -l`
if [ $num_downhosts -gt 1 ]; then
cat << EOF >> $temp_webpage
<h3>Nodes down</h3>
<table border=on>
EOF

count=0
newrow=0
for host in $ALL_HOSTS
do
host_down_entry
done

if [ $newrow -ne 0 ]; then
  echo "</tr>" >> $temp_webpage
fi
cat << EOF >> $temp_webpage
</table>
EOF
fi

# count entries
count=0
for host in $UP_HOSTS
do
host_count_entry
done

# output cluster load

if [ $count -gt 0 ]; then
cat << EOF >> $temp_webpage
<h3>Nodes up (load>1)</h3>
<table border=on>
<tr>
<td bgcolor="#ffffff">1.0 &le; load &lt; 2.0</td>
<td bgcolor="#ffff00">2.0 &le; load &lt; 6.0</td>
<td bgcolor="#ff0000">load &ge; 6.0</td>
</tr>
</table>
EOF
fi

cat << EOF >> $temp_webpage
<p><table border=on>
EOF

# output individual blaze entries

count=0
newrow=0
for host in $UP_HOSTS
do
host_entry
done
if [ $newrow -ne 0 ]; then
  echo "</tr>" >> $temp_webpage
fi
cat << EOF >> $temp_webpage
</table>
EOF

cat << EOF >> $temp_webpage
<h3>History</h3>
<div id="load_plot" style="width: 750px; height: 200px"></div>
EOF
if [ "$TEMP_IP" != "" ]; then
cat << EOF >> $temp_webpage
<div id="temp_plot" style="width: 750px; height: 200px"></div><br>
EOF
fi

cat << EOF >> $temp_webpage
</body>
</html>
EOF
cp $temp_webpage $webpage
rm $temp_webpage
