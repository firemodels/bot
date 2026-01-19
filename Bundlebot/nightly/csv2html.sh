#!/bin/bash
INPUT=$1
INPUTTEMP=${INPUT}.$$
TITLE="${INPUT%.*}"
TITLE=`echo $TITLE |  sed 's/.*FDS-/FDS-/'`
OUTPUT="${INPUT%.*}"
OUTPUT=${OUTPUT}_manifest.html
sed 's/: OK/OK/g' $INPUT > $INPUTTEMP

cat << EOF > $OUTPUT
<html><head><title>$TITLE Manifest</title>
<h1>$TITLE Manifest</h1>
<table border=on>
<tr><th>file</th><th>sha256 hash</th><th>virus status</th></th></tr>
EOF
awk -F, '{
    if ($0 ~ /SCAN SUMMARY/) exit
    printf "<tr>"
    for (i=1; i<=NF; i++) printf "<td>%s</td>", $i
    print "</tr>"
}' < $INPUTTEMP >> $OUTPUT
cat << EOF >> $OUTPUT
<pre>
EOF
awk '{
    if ($0 ~ /SCAN SUMMARY/) start=1
    if (start) print
}' < $INPUTTEMP >> $OUTPUT

cat << EOF >> $OUTPUT
</pre>
</table>
</html>
EOF

