#!/bin/bash
## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi

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

#This runs the Starfish Redash Query 'Condensed Duplicate Hash Report (Cross Volume)' from the command line and saves the output to /tmp/output.csv. This query searches for duplicate files greater than .1GB in size.
/opt/starfish/scripts/sfpng.py --redash-api-key "<redacted>" --output csv --redash-query 'Condensed Duplicate Hash Report (Cross Volume)' --params cutoff_GiB=.1,hashtype=sha1 &>/dev/null

#To get the total (in GiB), we exclude entries that are already being de-duplicated, then sum using awk
total_gib="$(grep -v "alldata|nextgenout2\|alldata|peroulab\|nextgenout2|peroulab\|nextgenout3|nextgenout4\|nextgenout3|nextgenout5\|nextgenout4|nextgenout5" /tmp/output.csv | awk -F ',' '{print $3}' | awk "{sum+=\$1} END {print sum}")"

#Convert GiB to TB
total_tb="$(echo $total_gib/931 | bc -l | xargs printf "%.2f")"

if (( $(echo "$total_tb > 20" |bc -l) )); then
	result=$CRIT
elif (( $(echo "$total_tb > 10" |bc -l) )); then
	result=$WARN
fi
	

case "$result" in
        "$OK")
                echo -e "$OKmsg: Cross volume duplicates size is ${total_tb}TB"
                exit $OK
                ;;
        "$WARN")
                echo "$WARNmsg: Cross volume duplicates size is ${total_tb}TB"
                exit $WARN
                ;;
        "$CRIT")
                echo -e "$CRITmsg: Cross volume duplicates size is ${total_tb}TB"
                exit $CRIT
                ;;
        *)
                echo "$UNKmsg: Cross volume duplicates size is unknown."
                exit $UNK
esac

