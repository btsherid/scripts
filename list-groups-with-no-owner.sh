#!/bin/sh

##### Configuration
BASE_PATH=/datastore/lbgadmin/accounts
BIN_DIR=$BASE_PATH/bin
CONFIG_DIR=$BASE_PATH/conf
CONFIG_FILE=$CONFIG_DIR/config

#source configuration
if [ -e $CONFIG_FILE ]; then
        . $CONFIG_FILE
else
        echo "Missing configuration file: $CONFIG_FILE" >&2
        exit 1
fi

#Pulls a list of all groups in format: dn: cn=<group name>,ou=group,dc=lbg,dc=unc,dc=edu cn: <group name>
results=$($LDAPSEARCH_CMD -LLL -o ldif-wrap=no -x -D "uid=$LDAP_ADMIN_USER,ou=people,dc=lbg,dc=unc,dc=edu" -w "$LDAP_ADMIN_PW" -h <LDAP server FQDN> -b ou=group,dc=lbg,dc=unc,dc=edu "(&(cn=*))" cn)

#Takes the list of all groups and turns it into a one line, alphabetically sorted, space separated list of groups
groups=$(echo $results | tr " " "\n" | grep "cn=" | awk -F ',' '{print $1}' | sed 's/cn=//g' | sort -u)


for entry in $groups
do
group_info="$(${BIN_DIR}/lbggroupsearch.sh $entry)"
group_owner="$(echo -e "$group_info" | grep "owner" | awk -F "owner:" '{print $2}' | tr -d " \r")"

if [[  -z "$group_owner" ]]; then
	groups_with_no_owner="$groups_with_no_owner $entry"
fi
done

echo
echo "===Groups With No Owner In Description==="
echo $groups_with_no_owner | tr " " "\n"
echo
