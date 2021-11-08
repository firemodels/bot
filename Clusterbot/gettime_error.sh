#!/bin/bash

TIME_ERROR=`chronyc tracking | grep System | awk '{print $4}'`
IS_NEG=`echo "$TIME_ERROR < 0.0" | bc -l`
if [ "$IS_NEG" == "1" ]; then
  TIME_ERROR=`echo "-1.0 * $TIME_ERROR" | bc -l`
fi
echo $TIME_ERROR $TIME
