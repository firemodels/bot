#!/bin/bash
LINES=4000
LOADFILE=$HOME/.cluster_status/load_spark-login.csv
TIMELENGTH=7.0
./make_plots.sh $LINES $LOADFILE $TIMELENGTH
