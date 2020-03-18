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

#If $OUTPUT_PATH/lbg-contacted-groups does not exist, create it
if [ ! -f "$OUTPUT_PATH/lbg-contacted-groups" ]; then
	touch $OUTPUT_PATH/lbg-contacted-groups
fi

#If $OUTPUT_PATH/lbg-groups-with-owners does not exist, create it
if [ ! -f "$OUTPUT_PATH/lbg-groups-with_owners" ]; then
	touch $OUTPUT_PATH/lbg-groups-with-owners
fi

#This adds logic to allow an email all groups override.
#By default, the script only emails groups that are not in the $OUTPUT_PATH/lbg-contacted-groups file
#With this override, the file is zeroed out, so no groups are in the file and all of them get contacted.

email_all=$1
if [[ "$email_all" ==  "--email-all" ]]; then

	#Display a warning message and force the user to hit y to proceed.
	echo
	echo "This will email all group owners whether or not they have been previously contacted."
	read -p "Hit y to proceed. Hit any other key to exit. " -n 1 -r
	echo
	if [[ ! $REPLY = "y" ]]; then
		exit 1
	fi
	truncate -s 0 $OUTPUT_PATH/lbg-contacted-groups
else
	group_contacted_date_and_time=$(stat -c %y $OUTPUT_PATH/lbg-contacted-groups | awk -F '.' '{print $1}')
fi

#Pulls a list of all groups in format: dn: cn=<group name>,ou=group,dc=lbg,dc=unc,dc=edu cn: <group name>
results=$($LDAPSEARCH_CMD -LLL -o ldif-wrap=no -x -D "uid=$LDAP_ADMIN_USER,ou=people,dc=lbg,dc=unc,dc=edu" -w "$LDAP_ADMIN_PW" -h <LDAP server FQDN> -b ou=group,dc=lbg,dc=unc,dc=edu "(&(cn=*))" cn)

#Takes the list of all groups and turns it into a one line, alphabetically sorted, space separated list of groups
groups=$(echo $results | tr " " "\n" | grep "cn=" | awk -F ',' '{print $1}' | sed 's/cn=//g' | sort -u)

#Zeroes out the lbg-groups-with-owners file so that each time the script runs, the file holds only information 
#for the groups that currently have owners
truncate -s 0 $OUTPUT_PATH/lbg-groups-with-owners

#For each group, get the group owner
for entry in $groups
do
excluded_group="$(grep $entry $RESOURCE_PATH/group-email-excluded-groups)"
if ! [[ "$entry" == "$excluded_group" ]]; then
	group_info="$(${BIN_DIR}/lbggroupsearch.sh $entry)"
	group_owner="$(echo -e "$group_info" | grep "owner" | awk -F "owner:" '{print $2}' | tr -d " \r")"

	#If $group_owner is not empty, get the owner's email address 
	#and dump the group name, group owner (onyen), and owner's email address to the lbg-groups-with-owners file
	if [[ ! -z "$group_owner" ]]; then
	
		#If the owner string has a comma in it, there is more than one owner.
		#In that case, get the names and emails of all owners
		if [[ "$group_owner" = *","* ]]; then
			owners="$(echo $group_owner | tr "," " ")"
			for i in $owners
			do
				owner_emails="$owner_emails $(${BIN_DIR}/uncusersearch.sh $i mail | grep mail | awk -F ":" '{print $2}')"
			done
			echo "$entry $group_owner $owner_emails" >> $OUTPUT_PATH/lbg-groups-with-owners
		else
			owner_email="$(${BIN_DIR}/uncusersearch.sh $group_owner mail | grep mail | awk -F ":" '{print $2}')"
			echo "$entry $group_owner $owner_email " >> $OUTPUT_PATH/lbg-groups-with-owners
		fi
	fi
fi
done

#For groups that have owner information, contact group owners
while IFS= read -r line
do
	#Get group name and info
	group=$(echo $line | awk '{print $1}')
	info="$(${BIN_DIR}/lbggroupsearch.sh $group)"
	
	#Clear the members variable so it will only hold members for the current group
	members=""

	#Get group member onyens
	member_onyens="$(echo -e "$info" | grep "memberUid" | awk '{print $2}' | sort)"

	show_all_members=$(grep $group $RESOURCE_PATH/groups-to-email-all-members)

	#For groups that are not in the groups-to-email-all-members file, we want to filter out bioinf staff and service accounts from the members list.
	if [ "$show_all_members" = "" ]; then
		#For each onyen, get the user's name
		for entry in $member_onyens
		do
			#Check and see if the account is an account we want to exclude or a service account
			excluded_account=$(grep $entry $RESOURCE_PATH/group-email-excluded-accounts)
			excluded_account_svc=$(grep $entry $RESOURCE_PATH/svc-accounts)

			#If the account is not excluded and not a service account, add it to the members list
			if [ "$excluded_account" = "" ] && [ "$excluded_account_svc" = "" ]; then
				member_name="$(${BIN_DIR}/uncusersearch.sh $entry displayName | grep displayName | awk -F ":" '{print $2}' | cut -c 2-)"
				#If the member name is not empty, add the member and their name to the members variables
				#If the member name is empty, add it to the members variable as is.
		
				if [[ ! -z "$member_name" ]]; then
					members="$members\n$entry ($member_name)"
				else
					members="$members\n$entry"
				fi
			fi
	
		done
	#For groups that are in the groups-to-email-all-members file, we do not want to filter the members list.
	else
		#For each onyen, get the users' name
		for entry in $member_onyens
		do
		member_name="$(${BIN_DIR}/uncusersearch.sh $entry displayName | grep displayName | awk -F ":" '{print $2}' | cut -c 2-)"
                                 #If the member name is not empty, add the member and their name to the members variables
                                 #If the member name is empty, add it to the members variable as is.

                                 if [[ ! -z "$member_name" ]]; then
                                         members="$members\n$entry ($member_name)"
                                 else
                                         members="$members\n$entry"
                                 fi
                         
		done
	fi
	#Get the group owner's email address (will get multiple email addresses if multiple owners)
	
	owner_email=$(echo $line | awk '{$1=$2=""; print $0}')
	
	#If group not already contacted, send email
	group_contacted=$(grep "$group" $OUTPUT_PATH/lbg-contacted-groups)
        if [[ -z "$group_contacted" ]]; then
                ##Send email to owner
			printf "Hi,\n\nIn order to ensure proper data security in LBC, we are required to conduct periodic reviews of our user groups. You have been identified as the owner of the LBC group '$group'. If someone else (on the list below) is the owner of the aforementioned group, please let <help email> know and ignore this letter.\n\nOtherwise, please let <help email> know if any updates need to be made on the group membership. If we don’t hear back from you, we will register that there is no need to change the membership in your group at this time.\n\n$members\n\n\nThank you for your help with this important matter,\n\nLineberger Bioinformatics Core\nSystem Administrators" | mail -s "Group Membership Verification - $group" -r "from email address"  $owner_email 
		##Add to contacted_groups variable
		contacted_groups="$contacted_groups\n$group"
		
                ##Add group to contacted file
		echo $group >> $OUTPUT_PATH/lbg-contacted-groups
        fi

done <"$OUTPUT_PATH/lbg-groups-with-owners"

echo
echo "===Contacted Groups==="
if [[ -z $contacted_groups ]]; then
	echo "None"
else
	echo -e $contacted_groups
fi
echo
if [[ "$email_all" ==  "--email-all" ]]; then
	echo "===Previously Contacted Groups==="
	echo
	echo "--email-all option used. All groups with owner information were contacted."
	echo
else 
	echo "===Previously Contacted Groups ($group_contacted_date_and_time and before)===" 
	echo "Previously contacted groups can be found in $OUTPUT_PATH/lbg-contacted-groups"
	echo
fi

