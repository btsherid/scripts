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

umd_accounts="$(cat ${OUTPUT_PATH}/umd-accounts | awk -F ',' '{print $1}')"
svc_accounts="$(cat ${OUTPUT_PATH}/svc-accounts | awk -F ',' '{print $1}')"
disabled_accounts="$(ls ${LDIF_PATH}/*.ldif | awk -F '/' '{print $6}' | awk -F '-' '{print $1}' )"

uids=$(echo -e $results | tr " " "\n" | grep "uid=" | awk -F ',' '{print $1}' | awk -F '=' '{print $2}' | sort)


for entry in $uids
do
	umd=""	
	svc=""
	disabled=""

	for umd_account in $umd_accounts
	do
		if [ "$entry" == "$umd_account" ]; then
			umd="yes"
		fi
	done

	for svc_account in $svc_accounts
	do
		if [ "$entry" == "$svc_account" ]; then
			svc="yes"
		fi
	done

	for disabled_account in $disabled_accounts
	do
		if [ "$entry" == "$disabled_account" ]; then
			disabled="yes"
		fi
	done	


	if [ -z $umd ] && [ -z $svc ] && [ -z $disabled ]; then
		number_of_groups="$(id $entry | awk '{print $3}' | awk -F '=' '{print $2}' | tr "," " " | wc -w)"
		if [ "$number_of_groups" -lt "2" ]; then
        		uids_with_no_groups="$uids_with_no_groups $entry"
		fi	
	fi
done




#for entry in $uids_with_no_groups
#do
	#id $entry | awk '{print $1}'
	#echo $(${BIN_DIR}/uncusersearch.sh $entry mail | awk -F "mail:" '{print $2}')
	#echo $(${BIN_DIR}/uncusersearch.sh $entry displayName) | awk -F "displayName:" '{print $2}' 
	#echo
#done


echo
echo "===Users only in LBG Group==="
echo -e $uids_with_no_groups | tr " " "\n"
echo
