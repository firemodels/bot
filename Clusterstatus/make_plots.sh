#!/bin/bash
NLINES=$1
LOADFILE=$2
TIMELENGTH=$3
TYPE=$4

TEMP_IP=$STATUS_TEMP_IP
lasttime=`cat $LOADFILE | tail -1 | awk -F',' '{print $1}'`
firsttime="$( bc <<<"$lasttime - $TIMELENGTH" )"

echo "" 
if [ "TEMP_IP" != "" ]; then
# ---------------------------------------------------------------
# begin temperature plot
cat << EOF
      google.charts.setOnLoadCallback(drawTempPlot$TYPE);
      function drawTempPlot$TYPE() {
        var data = google.visualization.arrayToDataTable([
          ['days since Jan 1', 'temperature (F)'],
EOF

cat $LOADFILE | tail -$NLINES | awk -v firsttime="$firsttime" -F',' '{if($1>firsttime) { printf("[%s,%s],\n",$1,$3) }}' 

cat << EOF 
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
        var chart = new google.visualization.LineChart(document.getElementById('temp_plot$TYPE'));
        chart.draw(data, options);
      }
EOF
fi

# ---------------------------------------------------------------
# begin cluster load plot

cat << EOF 
      google.charts.setOnLoadCallback(drawLoadPlot$TYPE);
      function drawLoadPlot$TYPE() {
        var data = google.visualization.arrayToDataTable([
          ['days since Jan 1', 'load'],
EOF

cat $LOADFILE | tail -$NLINES | awk -v firsttime="$firsttime" -F',' '{if($1>firsttime) { printf("[%s,%s],\n",$1,$6) }}' 

cat << EOF 
        ]);
        var options = {
          title: '',
          curveType: 'line',
          legend: { position: 'right' },
          colors: ['black'],
          hAxis:{ title: 'Day'},
	  vAxis:{ title: 'total cluster load'}
        };
        options.legend = 'none';
        var chart = new google.visualization.LineChart(document.getElementById('load_plot$TYPE'));
        chart.draw(data, options);
      }
EOF

# ---------------------------------------------------------------
# begin head load plot

cat << EOF 
      google.charts.setOnLoadCallback(drawHeadLoadPlot$TYPE);
      function drawHeadLoadPlot$TYPE() {
        var data = google.visualization.arrayToDataTable([
          ['days since Jan 1', 'load'],
EOF

cat $LOADFILE | tail -$NLINES | awk -v firsttime="$firsttime" -F',' '{if($1>firsttime) { printf("[%s,%s],\n",$1,$4) }}' 

cat << EOF 
        ]);
        var options = {
          title: '',
          curveType: 'line',
          legend: { position: 'right' },
          colors: ['black'],
          hAxis:{ title: 'Day'},
	  vAxis:{ title: '$CB_HEAD load'}
        };
        options.legend = 'none';
        var chart = new google.visualization.LineChart(document.getElementById('load_headplot$TYPE'));
        chart.draw(data, options);
      }
EOF

# ---------------------------------------------------------------
# begin login load plot

cat << EOF
      google.charts.setOnLoadCallback(drawLoginLoadPlot$TYPE);
      function drawLoginLoadPlot$TYPE() {
        var data = google.visualization.arrayToDataTable([
          ['days since Jan 1', 'load'],
EOF

cat $LOADFILE | tail -$NLINES | awk -v firsttime="$firsttime" -F',' '{if($1>firsttime) { printf("[%s,%s],\n",$1,$5) }}' 

cat << EOF 
        ]);
        var options = {
          title: '',
          curveType: 'line',
          legend: { position: 'right' },
          colors: ['black'],
          hAxis:{ title: 'Day'},
	  vAxis:{ title: '$CB_LOGIN load'}
        };
        options.legend = 'none';
        var chart = new google.visualization.LineChart(document.getElementById('load_loginplot$TYPE'));
        chart.draw(data, options);
      }
EOF
