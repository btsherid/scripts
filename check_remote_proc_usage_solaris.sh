#!/bin/bash

################################
# check_proc_usage.sh
# 
# Usage: check_proc_usage.sh <proc name> <proc name>
# 
# Sample from /etc/nagios/nrpe.cfg:
# command[check_local_cert]=/datastore/serverdepot/bin/check_proc_usage.sh asra asrm
#
################################



# Exit codes:
# 0 = Certificate will not expire in 60 days or less 
OK=0
OKmsg="OK"
# 1 = Certificate will expire in 60 days or less
WARN=1
WARNmsg="WARNING"
# 2 = Certificate will expire in 30 days or less
CRIT=2
CRITmsg="CRITICAL"
# 3 = Unknown state
UNK=3
UNKmsg="UNKNOWN"


exitStatus=$OK
CommandLineInput="$*"
warning=""
crit=""
Warn_Procs=""
Crit_Procs=""
for entry in $CommandLineInput
do
warning=""
crit=""
	usage="$(top | grep $entry | awk '{print $10}' | tr -d '%' | tr '\n' ' ')"
	for amount in $usage
	do
		amount_num="$(echo "$amount" | bc -l)"
		amount_rounded="$(printf "%.*f\n" 0 $amount_num)"

		if [[ $amount_rounded -ge 30 ]]; then
			crit="yes"
			exitStatus=$CRIT
		elif [[ $amount_rounded -ge 15 ]] && [[ $amount_rounded -lt 30 ]]; then
			warning="yes"
			exitStatus=$WARN
		fi

	done

	if [[ "$crit" == "yes" ]]; then
		Crit_Procs="$Crit_Procs $entry"
	elif [[ "$warning" == "yes" ]]; then
		Warn_Procs="$Warn_Procs $entry"
	else
		OK_Procs="$OK_Procs $entry"
	fi

done

	echo $Warn_Procs
case "$exitStatus" in

			"$OK")
				echo $OKmsg: CPU usage for $OK_Procs is OK.
				exit $OK
			;;

			"$WARN")
				echo $WARNmsg: CPU usage for$Warn_Procs is above 15%. These processes are OK:$OK_Procs
				exit $WARN
			;;

			"$CRIT")
				echo "$CRITmsg: CPU usage for$Crit_Procs is above 30%. These processes are above 15%:$Warn_Procs. These processes are OK:$OK_Procs"
				exit $CRIT
			;;

			"$UNK")
				echo $UNKmsg: CPU usage for $Procs is unknown.
				exit $UNK
			;;

			*)
				echo $UNKmsg
				exit $UNK
			;;
esac

