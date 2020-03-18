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

results=$($LDAPSEARCH_CMD -LLL -o ldif-wrap=no -x -D "uid=$LDAP_ADMIN_USER,ou=people,dc=lbg,dc=unc,dc=edu" -w "$LDAP_ADMIN_PW" -h <LDAP server FQDN> -b ou=people,dc=lbg,dc=unc,dc=edu "(&(uid=*))" uid)

uids=$(echo -e $results | tr " " "\n" | grep "uid=" | awk -F ',' '{print $1}' | awk -F '=' '{print $2}' | sort)

for entry in $uids
do
	number_of_groups="$(id $entry | awk '{print $3}' | awk -F '=' '{print $2}' | tr "," " " | wc -w)"
	if [ "$number_of_groups" -ge "16" ]; then
		uids_with_16_or_more_groups="$uids_with_16_or_more_groups $entry"
	fi
done

echo
echo "===Users with 16 or groups==="
echo -e $uids_with_16_or_more_groups | tr " " "\n"
echo
