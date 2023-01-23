#!/bin/bash
SOPT=
NHIST=-180

while getopts 'n:st:' OPTION
do
case $OPTION  in
  n)
  NHIST=$OPTARG
   ;;
  s)
  SOPT=-s
   ;;
  t)
  timelist=$OPTARG
   ;;
esac
done
shift $(($OPTIND-1))

cat << EOF
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {
        var data = google.visualization.arrayToDataTable([
          ['Days since Jan 1, 2016', 'Benchmark Time (s)'],
EOF

./make_timelist.sh $SOPT | sort -n -k 1 -t , | tail $NHIST > $timelist

cat timelist.out | awk -F ',' '{ printf("[%s,%s],\n",$1,$2) }'

cat << EOF
        ]);

        var options = {
          title: '',
          curveType: 'line',
          legend: { position: 'right' },
          colors: ['black'],
          pointSize: 5,
          hAxis:{ title: 'Day'},
          vAxis:{ title: 'Time (s)'}
        };
        options.legend = 'none';

        var chart = new google.visualization.LineChart(document.getElementById('curve_chart'));

        chart.draw(data, options);
      }
EOF
