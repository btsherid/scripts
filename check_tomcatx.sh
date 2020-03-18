#!/bin/bash

#!/bin/bash

################################
# check_tomcatx.sh
#
# Usage: check_tomcatx.sh 
#
# Sample from /etc/nagios/nrpe.cfg:
# command[check_services]=/datastore/serverdepot/bin/check_tomcatx.sh
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
user=$(grep User /usr/lib/systemd/system/tomcat.service | awk -F '=' '{print $2}')

if ! [[ "$user" == "tomcatx" ]]; then
	result=$CRIT
fi


case "$result" in
        "$OK")
                echo "$OKmsg: Tomcat running as tomcatx"
                exit $OK
                ;;
        "$CRIT")
                echo "$CRITmsg: Tomcat running as $user, not tomcatx"
                exit $CRIT
                ;;
        *)
                echo "$UNKmsg: Unknown exit state"
                exit $UNK
esac

