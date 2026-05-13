#!/bin/bash
host=$1
temp_webpage=$2

if [ "$host" == "blaze037" ]; then
  export newrow=2
  export count=2
cat << EOF >> $temp_webpage
<tr><th>batch2:</th>
EOF
fi
if [ "$host" == "blaze073" ]; then
  export newrow=2
  export count=2
cat << EOF >> $temp_webpage
<tr><th>batch3:</th>
EOF
fi
if [ "$host" == "blaze109" ]; then
  export newrow=2
  export count=2
cat << EOF >> $temp_webpage
<tr><th>firebot:</th>
EOF
fi
if [ "$host" == "blaze127" ]; then
  export newrow=2
  export count=2
cat << EOF >> $temp_webpage
<tr><th>batch4:</th>
EOF
fi
