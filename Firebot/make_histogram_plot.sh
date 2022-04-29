#!/bin/bash
SOPT=
fopt=

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

if [ "$fopt" == "" ]; then
  if [ "$SOPT" == "" ]; then
    timefile=`ls -rtlm ~firebot/.firebot/history/*timing*csv | grep -v bench | tail -1 | awk -F',' '{print $1}'`
  else
    timefile=`ls -rtlm ~smokebot/.smokebot/history/*timing*csv | grep -v bench | tail -1 | awk -F',' '{print $1}'`
  fi
fi

cat << EOF
      google.charts.setOnLoadCallback(drawHistogram);

      function drawHistogram() {
        var data = google.visualization.arrayToDataTable([
          ['time (s)'],
EOF

cat $timefile | head -n -2 | awk -F ',' '{if (NR!=1)  {printf("[%s],\n",$2) }}' | grep -v -F [],

#          histogram: { lastBucketPercentile: 5 }
cat << EOF
        ]);

        var options = {
          title: '',
          curveType: 'line',
          legend: { position: 'right' },
          colors: ['black'],
          pointSize: 5,
          hAxis:{ title: 'time (s)'},
          vAxis:{ title: 'number', scaleType: 'mirrorLog'},
          histogram: { lastBuucketPercentil: 10},
        };
        options.legend = 'none';

        var chart = new google.visualization.Histogram(document.getElementById('hist_chart'));

        chart.draw(data, options);
      }

EOF
