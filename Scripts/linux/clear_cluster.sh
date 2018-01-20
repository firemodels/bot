#!/bin/bash
echo "#!/bin/bash" > kill_jobs.sh
ps -el | awk '{if(NR>1&&$3>1000){print "kill -9",$4}}' >> kill_jobs.sh
chmod +x kill_jobs.sh
