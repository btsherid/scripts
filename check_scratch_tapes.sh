#!/bin/bash

################################
# check_services.sh
#
# Usage: check_cluster.sh
#
# Sample from /etc/nagios/nrpe.cfg:
# command[check_cluster]=/datastore/serverdepot/bin/check_cluster.sh
#
################################



# Exit codes:
# 0 = All cluster nodes are in a good state (OK)
OK=0
OKmsg="OK"
# 1 = TBD (WARN)
WARN=1
WARNmsg="WARNING"
# 2 = One or more cluster nodes are down (CRIT)
CRIT=2
CRITmsg="CRITICAL"
# 3 = Cluster state not known (UNK)
UNK=3
UNKmsg="UNKNOWN"


result=$OK

scratch_tapes="$(/datastore/serverdepot/netbackup/bin/scratch-tape-report.sh | grep 000_00004_TLD | awk '{print $NF}')"

if [ "$scratch_tapes" -lt "10" ]; then
	result=$WARN
fi

if [ "$scratch_tapes" -lt "5" ]; then
	result=$CRIT
fi


case "$result" in
	"$OK")
		echo -e "$OKmsg: $scratch_tapes scratch tapes"
		exit $OK
		;;
	"$WARN")
		echo "$WARNmsg: $scratch_tapes scratch tapes"
		exit $WARN
		;;
	"$CRIT")
		echo -e "$CRITmsg: $scratch_tapes scratch tapes"
		exit $CRIT
		;;
	*)
		echo "$UNKmsg: Number of scratch tapes is unknown."
		exit $UNK
esac
