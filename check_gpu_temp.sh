#!/bin/bash

################################
# check_gpu_temp.sh
#
# Usage: check_gpu_temp.sh 
#
# Sample from /etc/nagios/nrpe.cfg:
# command[check_gpu_temp]=/datastore/serverdepot/bin/check_gpu_temp.sh
#
################################



# Exit codes:
# 0 = all listed services OK (OK)
OK=0
OKmsg="OK"
# 1 = one or more listed services are not OK (WARN)
WARN=1
WARNmsg="WARNING"
# 2 = one or more listed services are not OK (CRIT)
CRIT=2
CRITmsg="CRITICAL"
# 3 = no services listed (UNK)
UNK=3
UNKmsg="UNKNOWN"


result=$OK
temp=$(nvidia-smi -q | grep "GPU Current Temp" | awk '{print $5}')

if [[ $temp > 66 && $temp < 79 ]] ; then
	result=$WARN
elif [[ $temp > 79 ]]; then
	result=$CRIT
fi

case "$result" in
	"$OK")
		echo "$OKmsg: Temperature=${temp}C"
		exit $OK
		;;
	"$WARN")
		echo "$WARNmsg: Temperature=${temp}C"
		exit $WARN
		;;
	"$CRIT")
		echo "$CRITmsg: Temperature=${temp}C"
		exit $CRIT
		;;
	*)
		echo "$UNKmsg: Unknown exit state"
		exit $UNK
esac
