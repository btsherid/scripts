#!/bin/bash

################################
# check_tomcat_logs.sh
#
# Usage: check_tomcat_logs.sh
#
# Sample from /etc/nagios/nrpe.cfg:
# command=[check_tomcat_logs/datastore/serverdepot/bin/check_tomcat_logs.sh
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
group=$(ls -ld /var/log/tomcat/ | awk '{print $4}' | awk NF | sort -u | tr '\n' ' ')

if ! [[ "$group" == "dev " ]]; then
	result=$CRIT
fi


case "$result" in
        "$OK")
                echo "$OKmsg: /var/log/tomcat directory group ownership is dev"
                exit $OK
                ;;
        "$CRIT")
                echo "$CRITmsg: /var/log/tomcat/ directory group ownership is $group, should be dev"
                exit $CRIT
                ;;
        *)
                echo "$UNKmsg: Unknown exit state"
                exit $UNK
esac

