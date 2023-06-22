#!/bin/bash
output=user_usage.out.$$
infoout=info.out.$$
squeue -r -h -o "%u %t %C" | awk '{print $1, $2, $3}' | grep R | awk '{print $1,$3}' | sort> $output
njobs=`cat $output | wc -l`
if [ $njobs -gt 0 ]; then
awk '{a[$1] += $2} END{for (i in a) print i,a[i]}' $output | sort > $infoout
cat << EOF
<table>
<tr>
<td>
<table border=on>
<tr><th>User</th><th>cores</th></tr>
EOF
  cat $infoout | awk '{sum+=$2;print "<tr><td align=left>",$1,"</td>", "<td align=right>",$2,"</td></tr>"} END{print "<tr><th align=left>Total</th><td align=right>",sum,"</td></tr>"}' 
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
rm $output
