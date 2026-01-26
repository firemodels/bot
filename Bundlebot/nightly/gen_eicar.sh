#!/bin/bash
OUTPUT=$1
TEST=$2
if [ "$OUTPUT" == "" ]; then
  echo ***error: specify an output file
  exit
fi
# if TEST is null then OUTPUT will contain the eicar test string
# if TEST contains a string then it will not (ie will not be quarantined by a virus scanner)
cat << EOF > $OUTPUT
${TEST}X5O!P%@AP[4\PZX54(P^)7CC)7}\$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!\$H+H*${TEST}
EOF
