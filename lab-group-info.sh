#!/bin/bash

BASE_PATH=/datastore/lbgadmin/accounts
BIN_DIR=$BASE_PATH/bin
CONFIG_DIR=$BASE_PATH/conf
CONFIG_FILE=$CONFIG_DIR/config
RESOURCE_DIR=$BASE_PATH/resources
counter="0"

#source configuration
if [ -e $CONFIG_FILE ]; then
        . $CONFIG_FILE
else
        echo "Missing configuration file: $CONFIG_FILE" >&2
        exit 1
fi

generate_csv=$1
if [[ "$generate_csv" ==  "--generate_csv" ]]; then
	echo "PI,Lab,Group,Group Owner" > /tmp/groups.csv
fi

#Pulls a list of all groups in format: dn: cn=<group name>,ou=group,dc=lbg,dc=unc,dc=edu cn: <group name>
results=$($LDAPSEARCH_CMD -LLL -o ldif-wrap=no -x -D "uid=$LDAP_ADMIN_USER,ou=people,dc=lbg,dc=unc,dc=edu" -w "$LDAP_ADMIN_PW" -h <LDAP server FQDN> -b ou=group,dc=lbg,dc=unc,dc=edu "(&(cn=*))" cn)

#Takes the list of all groups and turns it into a one line, alphabetically sorted, space separated list of groups
groups=$(echo $results | tr " " "\n" | grep "cn=" | awk -F ',' '{print $1}' | sed 's/cn=//g' | grep lab | grep -v collaborators | sort -u)


for entry in $groups
do
	PI="$(grep $entry $RESOURCE_DIR/group-names-and-PIs | awk -F ',' '{print $1}')"
	lab="$(grep $entry $RESOURCE_DIR/group-names-and-PIs | awk -F ',' '{print $2}')"
        group_info="$(${BIN_DIR}/lbggroupsearch.sh $entry)"
        group_owner="$(echo -e "$group_info" | grep "owner" | awk -F "owner:" '{print $2}' | tr -d " \r")"
	if [[ "$counter" -eq "0" ]]; then
		output="PI,Lab,Group,Group Owner\n$PI,$lab,$entry,$group_owner"
	else	
		output="$output\n$PI,$lab,$entry,$group_owner"
	fi
	counter=$counter+1
	if [[ "$generate_csv" ==  "--generate_csv" ]]; then
		echo "$PI,$lab,$entry,$group_owner" >> /tmp/groups.csv
	fi
done

echo -e $output | column -t -s ','

if [[ "$generate_csv" ==  "--generate_csv" ]]; then
	echo
        echo "CSV file created at /tmp/groups.csv"
fi
