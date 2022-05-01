#!/bin/bash
SOPT=
fopt=
timefile=../Scripts/fds_timing_diffs

while getopts 'f:s' OPTION
do
case $OPTION  in
  s)
  SOPT=-s
   ;;
  f)
  timefile=$OPTARG
  fopt=1
   ;;
esac
done
shift $(($OPTIND-1))

cat << EOF
      google.charts.setOnLoadCallback(drawHistogram);

      function drawHistogram() {
        var data = google.visualization.arrayToDataTable([
          ['relative time difference'],
EOF

cat $timefile | awk -F ',' '{printf("[%s],\n",$1)}' 

#          histogram: { lastBucketPercentile: 5 }
cat << EOF
        ]);

        var options = {
          title: '',
          curveType: 'line',
          legend: { position: 'right' },
          colors: ['black'],
          pointSize: 5,
          hAxis:{ title: 'relative time percentage difference'},
          vAxis:{ title: 'number', scaleType: 'mirrorLog'},
          histogram: { lastBuucketPercentil: 10},
        };
        options.legend = 'none';

        var chart = new google.visualization.Histogram(document.getElementById('hist_chart'));

        chart.draw(data, options);
      }

EOF
