#!/bin/bash
temp_webpage=$1
cat << EOF >> $temp_webpage
<th>batch:</th>
EOF
