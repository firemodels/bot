#!/bin/bash
FILE=/shared/admin/quota.csv
if [ ! -e $FILE ]; then
 exit
fi
cat << EOF
<table border=on>
<tr><th>userid</th><th>Disk Usage</th></tr>
EOF
cat $FILE | grep -v NIST | grep -v NAME | awk -F',' '{print $2," ",$1}'  | grep -v B$ | grep -v K$ | grep -v M$ | sort -hr | head -10 | awk -F' ' '{print "<tr><td>",$2,"</td><td>",$1,"</td></tr>"}'
cat << EOF
</table>
EOF
