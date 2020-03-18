#!/bin/bash

################################
# check_services.sh
#
# Usage: check_services.sh <service> <service> ...
#
# Sample from /etc/nagios/nrpe.cfg:
# command[check_services]=/datastore/serverdepot/bin/check_services.sh httpd tomcat
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
customServiceList="$*"
goodServiceList=""
badServiceList=""

osType="$(uname)"
if [[ "$osType" == "Linux" ]]; then
	defaultServiceList=""
	osRleaseVer="$(lsb_release -rs | cut -c1-1)"
	if [[ -z "$osRleaseVer" ]]; then
		osRleaseVer="6"
	fi
elif [[ "$osType" == "SunOS" ]]; then
	defaultServiceList="ssh ntp"
fi

if [[ -z "$customServiceList" ]]; then
	serviceList="$defaultServiceList"
else
	serviceList="$defaultServiceList $customServiceList"
fi

for service in $serviceList; do
	serviceIsGood=""
	if [[ "$osType" == "Linux" ]]; then
		if [[ "$osRleaseVer" == "6" ]]; then
			if service $service status >/dev/null 2>&1; then
				serviceIsGood="true"
			fi
		elif [[ "$osRleaseVer" == "7" ]]; then
			if systemctl status $service >/dev/null 2>&1; then
                                serviceIsGood="true"
                        fi
		else
			echo "$UNKmsg: Invalid OS Release version: $osRleaseVer"
			exit $UNK
		fi
	
	elif [[ "$osType" == "SunOS" ]]; then
                if [[ `svcs $service 2>/dev/null 2>&1` == *"online"* ]]; then
                        serviceIsGood="true"
                elif ! [[ `sudo /opt/asrmanager/bin/sftransport show_listener_status | grep "NOT RUNNING"` ]]; then
                        serviceIsGood="true"

                fi


	else
		echo "$UNKmsg: Invalid OS Type: $osType"
		exit $UNK
	fi

	if [[ $serviceIsGood == "true" ]]; then
		goodServiceList="${goodServiceList} ${service}"
	else
		result="$WARN"
		badServiceList="${badServiceList} ${service}"
	fi	
done

case "$result" in
	"$OK")
		echo "$OKmsg: All listed services running:$goodServiceList"
		exit $OK
		;;
	"$WARN")
		echo "$WARNmsg: Services not running:$badServiceList (Services running:$goodServiceList)"
		exit $WARN
		;;
	"$CRIT")
		echo "$CRITmsg: Services not running:$badServiceList (Services running:$goodServiceList)"
		exit $CRIT
		;;
	*)
		echo "$UNKmsg: Unknown exit state"
		exit $UNK
esac
