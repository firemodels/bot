#!/bin/bash
qstatout=qstat.out.$$
infoout=info.out.$$
qstat -a | awk 'NR>5' | awk '{print $2," ",$7}' | sort > $qstatout
njobs=`cat $qstatout | wc -l`
if [ $njobs -gt 0 ]; then
awk '{a[$1] += $2} END{for (i in a) print i,a[i]}' $qstatout | sort > $infoout
cat << EOF
<table>
<tr>
<td>
<table border=on>
<tr><th>User</th><th>cores</th></tr>
EOF
  cat $infoout | awk '{print "<tr><td>",$1,"</td>", "<td align=right>",$2,"</td></tr>"}' 
cat << EOF
</table>
</td>
<td></td>
<td>
EOF
if [ -e queues.html ]; then
cat queues.html 
fi
cat << EOF
</td></tr>
</table>
EOF
rm -f $infoout
fi
rm $qstatout
