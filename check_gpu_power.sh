#!/bin/bash

################################
# check_gpu_power.sh
#
# Usage: check_gpu_power.sh 
#
# Sample from /etc/nagios/nrpe.cfg:
# command[check_gpu_temp]=/datastore/serverdepot/bin/check_gpu_power.sh
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
power=$(nvidia-smi -q | grep "Power Draw" | awk '{print $4}')
power_warning_check=$(echo "$power 195 234" | awk '{if ($1 > $2 && $1 < $3) print $1; else print 0}')
power_critical_check=$(echo "$power 234" | awk '{if ($1 > $2) print $1; else print 0}')

if [[ $power_warning_check > 0 ]] ; then
	result=$WARN
elif [[ $power_critical_check > 0 ]]; then
	result=$CRIT
fi

case "$result" in
	"$OK")
		echo "$OKmsg: Power Draw=${power}W"
		exit $OK
		;;
	"$WARN")
		echo "$WARNmsg: Power Draw=${power}W"
		exit $WARN
		;;
	"$CRIT")
		echo "$CRITmsg: Power Draw=${power}W"
		exit $CRIT
		;;
	*)
		echo "$UNKmsg: Unknown exit state"
		exit $UNK
esac
