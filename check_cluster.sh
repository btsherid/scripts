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
status_output=""
nodes_down=""

#Get list of unique states that cluster nodes are in at the present momemnt.
node_states=$(sinfo --long -N | tail -n+3 | awk '{print $4}' | sort -u | grep -Ev '~|#|@|\*|\$' | tr "\n" " ")

#Get a count of the total nodes
node_count=$(sinfo --long -N | tail -n+3 | awk '{print $1}' | sort -u | wc -l)

#Get the number of nodes in every possible state
allocated=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "allocated" | grep -v "allocated+" | wc -l)
allocated_plus=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "allocated+" | wc -l)
completing=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "completing" | wc -l)
down=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "down" | wc -l)
drained=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "drained" | wc -l)
draining=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "draining" | wc -l)
error=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "error" | wc -l)
fail=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "fail" | wc -l)
failing=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "failing" | wc -l)
future=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "future" | wc -l)
idle=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "idle" | wc -l)
maint=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "maint" | wc -l)
mixed=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "mixed" | wc -l)
perfctrs=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "perfctrs" | wc -l)
power_down=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "power_down" | wc -l)
power_up=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "power_up" | wc -l)
reboot=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "reboot" | wc -l)
reserved=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "reserved" | wc -l)
unknown=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "unknown" | wc -l)

perf_data_formatting=";;;0;$node_count"

allocated_perf_data="allocated=$allocated$perf_data_formatting"
allocated_plus_perf_data="allocated+=$allocated_plus$perf_data_formatting"
completing_perf_data="completing=$completing$perf_data_formatting"
down_perf_data="down=$down$perf_data_formatting"
drained_perf_data="drained=$drained$perf_data_formatting"
draining_perf_data="draining=$draining$perf_data_formatting"
error_perf_data="error=$error$perf_data_formatting"
fail_perf_data="fail=$fail$perf_data_formatting"
failing_perf_data="failing=$failing$perf_data_formatting"
future_perf_data="future=$future$perf_data_formatting"
idle_perf_data="idle=$idle$perf_data_formatting"
maint_perf_data="maint=$maint$perf_data_formatting"
mixed_perf_data="mixed=$mixed$perf_data_formatting"
perfctrs_perf_data="perfctrs=$perfctrs$perf_data_formatting"
power_down_perf_data="power_down=$power_down$perf_data_formatting"
power_up_perf_data="power_up=$power_up$perf_data_formatting"
reboot_perf_data="reboot=$reboot$perf_data_formatting"
reserved_perf_data="reserved=$reserved$perf_data_formatting"
unknown_perf_data="unknown=$unknown$perf_data_formatting"


perf_data="$allocated_perf_data $allocated_plus_perf_data $completing_perf_data $down_perf_data $drained_perf_data $draining_perf_data $error_perf_data $fail_perf_data $failing_perf_data $future_perf_data $idle_perf_data $maint_perf_data $mixed_perf_data $perfctrs_perf_data $power_down_perf_data $power_up_perf_data $reboot_perf_data $reserved_perf_data $unknown_perf_data"

#If node_states is blank, change result to unkown.
#If node_states is not blank, loop through the different states and compile information into an output variable.

if [ -z "$node_states" ]; then
        result=$UNK
else
	for state in $node_states
	do
		#For each state, add state=number in variable named state to status_output.
		#For example, if state is idle, this will add idle=<number stored in variable idle>
		status_output="$status_output $state=${!state}"
	done
	
	#If nodes are down, set CRITICAL and get a list of nodes that are down.
	if [ $down -gt 0 ]; then
	        result=$CRIT
        	nodes_down=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "down" | awk '{print $1}' | tr "\n" " ")
	fi

	if [ $drained -gt 0 ]; then
	        result=$WARN
        	nodes_drained=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "drained" | awk '{print $1}' | tr "\n" " ")
	fi

	if [ $draining -gt 0 ]; then
                result=$WARN
                nodes_draining=$(sinfo --long -N | tail -n+3 | awk '{print $1,$4}' | sort -u | grep "draining" | awk '{print $1}' | tr "\n" " ")
        fi
fi

case "$result" in
	"$OK")
		echo -e "$OKmsg: Cluster state is good.$status_output|$perf_data"
		exit $OK
		;;
	"$WARN")
		echo "$WARNmsg: Drained: $nodes_drained Draining: $nodes_draining $status_output|$perf_data"
		exit $WARN
		;;
	"$CRIT")
		echo -e "$CRITmsg: Down: $nodes_down $status_output|$perf_data"
		exit $CRIT
		;;
	*)
		echo "$UNKmsg: Cluster status is unknown."
		exit $UNK
esac
