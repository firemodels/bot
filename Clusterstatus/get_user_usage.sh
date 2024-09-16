#!/bin/bash
head_load=$1
login_load=$2
qstatout=qstat.out.$$
infoout=info.out.$$
#qstat -a | grep -v Q | awk 'NR>4' | awk '{print $2," ",$7}' | sort > $qstatout
qstat -a | awk 'NR>5' | awk '{print $2," ",$7," ",$10}' | grep -v Q | grep -v C | awk '{print $1," ",$2}' | sort > $qstatout
njobs=`cat $qstatout | wc -l`
awk '{a[$1] += $2} END{for (i in a) print i,a[i]}' $qstatout | sort > $infoout
cat << EOF
<table>
<tr>
<td valign=top>
<table border=on>
EOF
if [ $njobs -gt 0 ]; then
cat << EOF
<tr><th>User</th><th>cores</th></tr>
EOF
  cat $infoout | awk '{sum+=$2;print "<tr><td align=left>",$1,"</td>", "<td align=right>",$2,"</td></tr>"} END{print "<tr><th>Total</th><td align=right>",sum,"</td></tr>"}' 
else
cat << EOF
<tr><th>User</th><th>cores</th></tr>
<tr><td align=left>none</td><td align=right>0</td></tr>
<tr><th>Total</td><td align=right>0</td></tr>
EOF
fi
cat << EOF
<tr></tr>
<tr></tr>
<tr><th>Host</th><th>load</th></tr>
<tr><th>$CB_HEAD</th><td align=right>$head_load</td></tr>
<tr><th>$CB_LOGIN</th><td align=right>$login_load</td></tr>
</table>
EOF
cat << EOF
</td>
<td></td>
EOF

if [ -e queues.html ]; then
cat << EOF
<td valign=top>
EOF
cat queues.html 
cat << EOF
</td>
EOF
fi
cat << EOF
</tr>
</table>
EOF
rm -f $infoout
rm $qstatout
