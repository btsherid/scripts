#!/bin/bash

################################
# check_tomcatx_catalina_dir.sh
#
# Usage: check_tomcatx_catalina_dir.sh 
#
# Sample from /etc/nagios/nrpe.cfg:
# command[check_services]=/datastore/serverdepot/bin/check_tomcatx_catalina_dir.sh
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
user=$(ls -lR /var/cache/tomcat/work/Catalina/ | awk '{print $3}' | awk NF | sort -u | tr '\n' ' ')

if ! [[ "$user" == "tomcatx " ]]; then
	result=$CRIT
fi


case "$result" in
        "$OK")
                echo "$OKmsg: All /var/cache/tomcat/work/Catalina/ files owned by tomcatx"
                exit $OK
                ;;
        "$CRIT")
                echo "$CRITmsg: /var/cache/tomcat/work/Catalina/ files owned by $user, not all owned by tomcatx"
                exit $CRIT
                ;;
        *)
                echo "$UNKmsg: Unknown exit state"
                exit $UNK
esac

