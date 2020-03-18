#!/bin/bash

################################
# check_cluster_scratch.sh
#
# Usage: check_cluster_scratch.sh
#
# Sample from /etc/nagios/nrpe.cfg:
# command[check_cluster]=/datastore/serverdepot/bin/check_cluster_scratch.sh
#
################################



# Exit codes:
# 0 = All cluster nodes are in a good state (OK)
OK=0
OKmsg="OK"
# 1 = One or more cluster nodes timed out (WARN) 
WARN=1
WARNmsg="WARNING"
# 2 = One or more cluster nodes have more then 50% disk space used (CRIT)
CRIT=2
CRITmsg="CRITICAL"
# 3 = Cluster state not known (UNK)
UNK=3
UNKmsg="UNKNOWN"


result=$OK
status_output=""
nodes_timed_out=""
nodes_crit=""

#Get list of node names
nodes=$(grep -v 127.0.0.1 /etc/hosts | grep -v headnode | tail -n+10 | awk '{print $2}' | awk -F '.' '{print $1}' | sort -u)
perf_data_formatting=";;;;"
perf_data=""

for i in $nodes
do
node_scratch=$(timeout 20 /opt/stack/bin/stack run host command="ls /datastore/scratch" $i)
node_scratch_problem=$(echo $node_scratch | grep "cannot access")
node_scratch_access="1"

if [ -z "$node_scratch" ]; then
	 nodes_timed_out="$nodes_timed_out $i"
elif [ ! -z "$node_scratch_problem" ]; then
	nodes_crit="$nodes_crit $i"
	node_scratch_access="0"
fi

perf_data="$perf_data $i=$node_scratch_access$perf_data_formatting"
done

if [ ! -z "$nodes_timed_out" ]; then
        result=$WARN
fi

if [ ! -z "$nodes_crit" ]; then
	result=$CRIT
fi

case "$result" in
	"$OK")
		echo -e "$OKmsg: Cluster /datastore/scratch access is good.|$perf_data"
		exit $OK
		;;
	"$WARN")
		echo "$WARNmsg: Nodes timed out: $nodes_timed_out|$perf_data"
		exit $WARN
		;;
	"$CRIT")
		echo -e "$CRITmsg: /datastore/scratch access problem: $nodes_crit Nodes timed out: $nodes_timed_out|$perf_data"
		exit $CRIT
		;;
	*)
		echo "$UNKmsg: Cluster status is unknown."
		exit $UNK
esac
