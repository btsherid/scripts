#!/bin/bash

BASE_PATH=/datastore/lbgadmin/accounts
BIN_DIR=$BASE_PATH/bin
CONFIG_DIR=$BASE_PATH/conf
CONFIG_FILE=$CONFIG_DIR/config
RESOURCE_DIR=$BASE_PATH/resources
counter="0"

## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi

#source configuration
if [ -e $CONFIG_FILE ]; then
        . $CONFIG_FILE
else
        echo "Missing configuration file: $CONFIG_FILE" >&2
        exit 1
fi

generate_csv=$1
if [[ "$generate_csv" ==  "--generate_csv" ]]; then
	echo "Group,members" > /tmp/groups.csv
fi

#Pulls a list of all groups in format: dn: cn=<group name>,ou=group,dc=lbg,dc=unc,dc=edu cn: <group name>
results=$($LDAPSEARCH_CMD -LLL -o ldif-wrap=no -x -D "uid=$LDAP_ADMIN_USER,ou=people,dc=edu" -w "$LDAP_ADMIN_PW" -h <LDAP URL> -b ou=group,dc=edu "(&(cn=*))" cn)

#Takes the list of all groups and turns it into a one line, alphabetically sorted, space separated list of groups that have lab in the name
groups=$(echo $results | tr " " "\n" | grep "cn=" | awk -F ',' '{print $1}' | sed 's/cn=//g' | grep lab | grep -v collaborators | sort -u)


for entry in $groups
do

	member_count=$(getent group $entry | awk -F ':' '{print $4}' | tr ',' '\n' | wc -l)
	if [[ "$counter" -eq "0" ]]; then
		output="Group,members\n$entry,$member_count"
	else	
		output="$output\n$entry,$member_count"
	fi
	counter=$counter+1
	if [[ "$generate_csv" ==  "--generate_csv" ]]; then
		echo "$entry,$member_count" >> /tmp/groups.csv
	fi
done

echo -e $output | column -t -s ','

if [[ "$generate_csv" ==  "--generate_csv" ]]; then
	echo
        echo "CSV file created at /tmp/groups.csv"
fi
