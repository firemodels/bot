This directory contains scripts for creating a summary web page detailing Linux cluster usage.

# Environment Variables

Environment variables used to characterize the cluster examined by the cluster status scripts.

```
export CB_BASE=spark
export CB_BEG=1
export CB_END=36
export CB_HOSTS=spark[001-036]
export CB_LOGIN=spark-login
export CB_HEAD=spark-head

STATUS_MAILTO=username@email_server
STATUS_WEBPAGE=/opt/www/html/smokebot/summary.html
STATUS_TEMP_IP=129.6.159.193/temp
```

# Usage

To run the cluster status script cd to `bot/Clusterstatus` and type `./run_cluster_status.sh`


