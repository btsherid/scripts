#!/bin/bash

BASE_PATH=/datastore/lbgadmin/accounts
BIN_DIR=$BASE_PATH/bin
CONFIG_DIR=$BASE_PATH/conf
CONFIG_FILE=$CONFIG_DIR/config
RESOURCE_DIR=$BASE_PATH/resources
counter="0"

#Reports are run on Sundays, so get last Sunday's date
day="$(date +%m-%d-%Y)"
day=${d##*-}-${d%-*}
report_date="$(date -d "$day -$(date -d $day +%u) days" +"%Y%m%d")"

#source configuration
if [ -e $CONFIG_FILE ]; then
        . $CONFIG_FILE
else
        echo "Missing configuration file: $CONFIG_FILE" >&2
        exit 1
fi

generate_csv=$1
if [[ "$generate_csv" ==  "--generate_csv" ]]; then
	echo "Group,nextgenout2,nextgenout3,nextgenout4,nextgenout5" > /tmp/groups.csv
fi

#Pulls a list of all groups in format: dn: cn=<group name>,ou=group,dc=lbg,dc=unc,dc=edu cn: <group name>
results=$($LDAPSEARCH_CMD -LLL -o ldif-wrap=no -x -D "uid=$LDAP_ADMIN_USER,ou=people,dc=lbg,dc=unc,dc=edu" -w "$LDAP_ADMIN_PW" -h <LDAP server FQDN> -b ou=group,dc=lbg,dc=unc,dc=edu "(&(cn=*))" cn)

#Takes the list of all groups and turns it into a one line, alphabetically sorted, space separated list of groups that have lab in the name
groups=$(echo $results | tr " " "\n" | grep "cn=" | awk -F ',' '{print $1}' | sed 's/cn=//g' | grep lab | grep -v collaborators | sort -u)


for entry in $groups
do
	storage_size_ng2="$(grep nextgenout2 /root/netapp-stats/$report_date/nextgenout-du | grep "\-$entry" | awk '{print $1}')"
	storage_size_ng3="$(grep nextgenout3 /root/netapp-stats/$report_date/nextgenout-du | grep "\-$entry" | awk '{print $1}')"
	storage_size_ng4="$(grep nextgenout4 /root/netapp-stats/$report_date/nextgenout-du | grep "\-$entry" | awk '{print $1}')"
	storage_size_ng5="$(grep nextgenout5 /root/netapp-stats/$report_date/nextgenout-du | grep "\-$entry" | awk '{print $1}')"

	if [[ $storage_size_ng2 == "" ]] || [[ $storage_size_ng2 == "0" ]]; then
		storage_size_ng2="0B"
	fi

	if [[ $storage_size_ng3 == "" ]] || [[ $storage_size_ng3 == "0" ]]; then
                storage_size_ng3="0B"
        fi

	if [[ $storage_size_ng4 == "" ]] || [[ $storage_size_ng4 == "0" ]]; then
                storage_size_ng4="0B"
        fi
	if [[ $storage_size_ng5 == "" ]] || [[ $storage_size_ng5 == "0" ]]; then
                storage_size_ng5="0B"
        fi

	if [[ "$counter" -eq "0" ]]; then
		output="Group,nextgenout2,nextgenout3,nextgenout4,nextgenout5\n$entry,$storage_size_ng2,$storage_size_ng3,$storage_size_ng4,$storage_size_ng5"
	else	
		output="$output\n$entry,$storage_size_ng2,$storage_size_ng3,$storage_size_ng4,$storage_size_ng5"
	fi
	counter=$counter+1
	if [[ "$generate_csv" ==  "--generate_csv" ]]; then
		echo "$entry,$storage_size_ng2,$storage_size_ng3,$storage_size_ng4,$storage_size_ng5" >> /tmp/groups.csv
	fi
done

echo -e $output | column -t -s ','

if [[ "$generate_csv" ==  "--generate_csv" ]]; then
	echo
        echo "CSV file created at /tmp/groups.csv"
fi
