#!/bin/bash
LINES=$1
PLOTFILE=$2
LOADFILE=$3
TIMELENGTH=$4

TEMP_IP=$STATUS_TEMP_IP

# begin temperature plot

echo "" > $PLOTFILE
if [ "TEMP_IP" != "" ]; then
cat << EOF >> $PLOTFILE
      google.charts.setOnLoadCallback(drawTempPlot);
      function drawTempPlot() {
        var data = google.visualization.arrayToDataTable([
          ['days since Jan 1', 'temperature (F)'],
EOF

lasttime=`cat $LOADFILE | tail -1 | awk -F',' '{print $1}'`
firsttime="$( bc <<<"$lasttime - $TIMELENGTH" )"
cat $LOADFILE | tail -$LINES | awk -v firsttime="$firsttime" -F',' '{if($1>firsttime) { printf("[%s,%s],\n",$1,$3) }}'  >> $PLOTFILE

cat << EOF >> $PLOTFILE
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
# end temperature plot

# begin cluster load plot

cat << EOF >> $PLOTFILE
      google.charts.setOnLoadCallback(drawLoadPlot);
      function drawLoadPlot() {
        var data = google.visualization.arrayToDataTable([
          ['days since Jan 1', 'load'],
EOF

cat $LOADFILE | tail -$LINES | awk -v firsttime="$firsttime" -F',' '{if($1>firsttime) { printf("[%s,%s],\n",$1,$6) }}'  >> $PLOTFILE

cat << EOF >> $PLOTFILE
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

        var chart = new google.visualization.LineChart(document.getElementById('load_plot'));

        chart.draw(data, options);
      }
EOF
# end cluster load plot

# begin head load plot

cat << EOF >> $PLOTFILE
      google.charts.setOnLoadCallback(drawHeadLoadPlot);
      function drawHeadLoadPlot() {
        var data = google.visualization.arrayToDataTable([
          ['days since Jan 1', 'load'],
EOF

cat $LOADFILE | tail -$LINES | awk -v firsttime="$firsttime" -F',' '{if($1>firsttime) { printf("[%s,%s],\n",$1,$4) }}'  >> $PLOTFILE

cat << EOF >> $PLOTFILE
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

        var chart = new google.visualization.LineChart(document.getElementById('load_headplot'));

        chart.draw(data, options);
      }
EOF

# end head load plot

# begin login load plot

cat << EOF >> $PLOTFILE
      google.charts.setOnLoadCallback(drawLoginLoadPlot);
      function drawLoginLoadPlot() {
        var data = google.visualization.arrayToDataTable([
          ['days since Jan 1', 'load'],
EOF

cat $LOADFILE | tail -$LINES | awk -v firsttime="$firsttime" -F',' '{if($1>firsttime) { printf("[%s,%s],\n",$1,$5) }}'  >> $PLOTFILE

cat << EOF >> $PLOTFILE
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

        var chart = new google.visualization.LineChart(document.getElementById('load_loginplot'));

        chart.draw(data, options);
      }
EOF

# end login load plot
