#!/bin/bash
historydir=~/.firebot/history
BODY=
TITLE=Firebot
SOPT=
NHIST=-180

while getopts 'bs' OPTION
do
case $OPTION  in
  b)
   BODY="1"
   ;;
  s)
   historydir=~/.smokebot/history
   TITLE=Smokebot
   SOPT=-s
   ;;
esac
done
shift $(($OPTIND-1))


if [ "$BODY" == "" ]; then
cat << EOF
<!DOCTYPE html>
<html><head><title>$TITLE Build Status</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
<script type="text/javascript">
  google.charts.load('current', {'packages':['corechart']});
EOF

./make_time_plot.sh       $SOPT -n $NHIST -t timelist.out
./make_histogram_plot.sh  $SOPT 

STDDEV=`cat timelist.out | awk -F ',' '{x[NR]=$2; s+=$2; n++} END{a=s/n; for (i in x){ss += (x[i]-a)^2} sd = sqrt(ss/n); print sd}'`
MEAN=`cat timelist.out   | awk -F ',' '{x[NR]=$2; s+=$2; n++} END{a=s/n; print a}'`
MEAN=`printf "%0.0f" $MEAN`
STDDEV_PERCEN=`echo "scale=5; $STDDEV/$MEAN*100 " | bc`

STDDEV=`printf "%0.1f" $STDDEV`
STDDEV_PERCEN=`printf "%0.1f" $STDDEV_PERCEN`


cat << EOF
</script>
</head>
<body>
<h2>$TITLE Summary</h2>
<hr align='left'>
<h3>Status - `date`</h3>
EOF

CURDIR=`pwd`
cd ../Scripts
SCRIPTDIR=`pwd`

cd $CURDIR
cd $historydir
ls -tl *.txt | grep -v compiler | grep -v warning | grep -v error | awk '{system("head "  $9)}' | sort -t ';' -r -n -k 7 | head -1 | \
             awk -F ';' '{cputime="Benchmark time: "$9" s";\
                          host="Host: "$10;\
                          font="<font color=\"#00FF00\">";\
                          if($8=="2")font="<font color=\"#FF00FF\">";\
                          if($8=="3")font="<font color=\"#FF0000\">";\
                          printf("%s %s</font><br>\n",font,$1);\
                          printf("<a href=\"https://github.com/firemodels/fds/commit/%s\">FDS Revision: %s </a><br>\n",$4,$5);\
                          printf("FDS Revision date: %s<br>\n",$2);\
                          if($11!=""&&$12!="")printf("<a href=\"https://github.com/firemodels/smv/commit/%s\">SMV Revision: %s </a><br>\n",$11,$12);\
                          if($9!="")printf("%s <br>\n",cputime);\
                          if($10!="")printf("%s <br>\n",host);\
                          }' 
cd $CURDIR

BASE_TIMEREV=`grep   base    output/fds_timing_summary | awk -F',' '{print $2}'`
CURRENT_TIMEREV=`grep current output/fds_timing_summary | awk -F',' '{print $2}'`

FASTCOUNT=`grep faster       output/fds_timing_summary | awk -F',' '{print $2}'`
FASTSIZE=`grep faster        output/fds_timing_summary | awk -F',' '{print $3}'`
SLOWCOUNT=`grep slower       output/fds_timing_summary | awk -F',' '{print $2}'`
SLOWSIZE=`grep slower        output/fds_timing_summary | awk -F',' '{print $3}'`
ALLCOUNT=`grep total         output/fds_timing_summary | awk -F',' '{print $2}'`
ALLSIZE=`grep total          output/fds_timing_summary | awk -F',' '{print $3}'`

cat << EOF > output/timing_summary
Base: $BASE_TIMEREV
Current: $CURRENT_TIMEREV
slower(count/time): $SLOWCOUNT, $SLOWSIZE s
faster(count/time): $FASTCOUNT, $FASTSIZE s
total(count/ime): $ALLCOUNT, $ALLSIZE s
EOF

cat << EOF
<h3>Time History</h3>

<div id="curve_chart" style="width: 500px; height: 300px"></div>
Mean: $MEAN s <br>

<h3>Time Differences</h3>
<p>Base: $BASE_TIMEREV<br>
Current: $CURRENT_TIMEREV<br>

<table border=on>
<caption>Run Time Changes <br>(Run Times > 60 s)</caption>
<tr><th></th><th>number</th><th>time change (s)</th></tr>
<tr><th>slower</th><td>$SLOWCOUNT</td><td>$SLOWSIZE</td></tr>
<tr><th>faster</th><td>$FASTCOUNT</td><td>-$FASTSIZE</td></tr>
<tr><th>all</th><td>$ALLCOUNT</td><td>$ALLSIZE</td></tr>
</table>

<div id="hist_chart" style="width: 500px; height: 300px"></div>
<h3>Nightly Bundles/Manuals</h3>
<a href="https://github.com/firemodels/test_bundles/releases/tag/FDS_TEST">Nightly Bundles/Manuals</a>

<h3>Status History</h3>

EOF
fi

cd $historydir
ls -tl *.txt | grep -v compiler | grep -v warning | grep -v error | awk '{system("head "  $9)}' | sort -t ';' -r -n -k 7 | head $NHIST | \
             awk -F ';' '{cputime="Benchmark time: "$9" s";\
                          host="Host: "$10;\
                          font="<font color=\"#00FF00\">";\
                          if($8=="2")font="<font color=\"#FF00FF\">";\
                          if($8=="3")font="<font color=\"#FF0000\">";\
                          printf("<p>%s %s</font><br>\n",font,$1);\
                          printf("<a href=\"https://github.com/firemodels/fds/commit/%s\">FDS Revision: %s </a><br>\n",$4,$5);\
                          printf("FDS Revision date: %s<br>\n",$2);\
                          if($11!=""&&$12!="")printf("<a href=\"https://github.com/firemodels/smv/commit/%s\">SMV Revision: %s </a><br>\n",$11,$12);\
                          if($9!="")printf("%s <br>\n",cputime);\
                          if($10!="")printf("%s <br>\n",host);\
                          }' 
cd $CURDIR

if [ "$BODY" == "" ]; then
cat << EOF
<br><br>
<hr align='left'><br>

</body>
</html>
EOF
fi
