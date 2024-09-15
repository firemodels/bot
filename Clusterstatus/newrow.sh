#!/bin/bash
host=$1
temp_webpage=$2

if [ "$host" == "spark010" ]; then
  export newrow=2
  export count=2
cat << EOF >> $temp_webpage
<tr><th>batch2:</th>
EOF
fi
if [ "$host" == "spark019" ]; then
  export newrow=2
  export count=2
cat << EOF >> $temp_webpage
<tr><th>batch3:</th>
EOF
fi
if [ "$host" == "spark028" ]; then
  export newrow=2
  export count=2
cat << EOF >> $temp_webpage
<tr><th>batch4:</th>
EOF
fi
