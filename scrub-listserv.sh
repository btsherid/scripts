#!/bin/bash

##### Configuration
BASE_PATH=/datastore/lbgadmin/accounts
CONFIG_DIR=$BASE_PATH/conf
CONFIG_FILE=$CONFIG_DIR/config
LISTSERV_DIR=$BASE_PATH/listserv
#source configuration
if [ -e $CONFIG_FILE ]; then
        . $CONFIG_FILE
else
        echo "Missing configuration file: $CONFIG_FILE" >&2
        exit 1
fi

### Sanity checks
## check if running as root
if [[ "$EUID" -eq 0 ]]; then
        echo "Error: Must not be run as root." >&2
        exit 1
fi

csv_file=$1

if [[ $csv_file == "" ]] ; then
	echo "No file given"
	exit 1
elif ! [ -f $csv_file ] ; then
	echo "File does not exist"
	exit 1
else 
	tail -n+2 $csv_file | awk -F ',' '{print $12}' > $OUTPUT_LISTSERV_EMAIL_ADDRESSES 
fi

active_user_email_addresses=$(cat $OUTPUT_ACTIVE_USER_EMAIL_ADDRESSES | awk '{print $1}' | awk '{printf "%s ",$0}')
listserv_email_addresses=$(cat $OUTPUT_LISTSERV_EMAIL_ADDRESSES | awk '{printf "%s ",$0}'  | awk '{gsub("root@<server FQDN>", ""); print}' | awk '{gsub("<user email>", ""); print}')

emails_to_add=""
emails_to_remove=""
onyens_to_add=""
onyens_to_remove=""

$BASE_PATH/bin/get-active-user-email-addresses.sh

for email in $active_user_email_addresses
do
	#For each active user's email address, see if it is in the listserv.
	#If it is not, then add it to a list to be added
	if ! grep -q "$email" "$OUTPUT_LISTSERV_EMAIL_ADDRESSES"  
	then
		emails_to_add="$emails_to_add $email"
	fi

	
done

for email in $listserv_email_addresses
do
        #For each listserv user's email address, see if it is in the active user's list.
        #If it is not, then add it to a list to be removed
	
        if ! grep -q "$email" "$OUTPUT_ACTIVE_USER_EMAIL_ADDRESSES"
        then
                emails_to_remove="$emails_to_remove $email"
        fi


done

if [[ "$emails_to_add" == "" ]]
then
	printf "\n===Emails To Add===\n"
        echo "None"
else
	printf "\n===Emails To Add===\n"
	
	for email in $emails_to_add
	do
		onyen_to_display=$(grep $email $OUTPUT_ACTIVE_USER_EMAIL_ADDRESSES | awk '{print $2'})
		if ! [[ "$onyen_to_display" == "" ]]
		then
			OUTPUT="$OUTPUT\n $email Onyen=$onyen_to_display"
                else
                        OUTPUT="$OUTPUT\n $email Onyen=Unknown"
		fi
		onyens_to_add="$onyens_to_add $onyen_to_display"
	done
	echo -ne $OUTPUT | column -t
	printf "\nOnyens to add:$onyens_to_add"
	OUTPUT=""
echo
fi

if [[ "$emails_to_remove" == "" ]]
then
	printf "\n===Emails To Remove===\n"
	echo "None"
	echo
else
	printf "\n===Emails To Remove===\n"
	
	for email in $emails_to_remove
	do
		onyen_to_display=$($UNC_LDAPSEARCH_BY_EMAIL_CMD $email uid | grep uid | awk '{print $2}')
		if ! [[ "$onyen_to_display" == "" ]]
                then
                	OUTPUT="$OUTPUT\n $email Onyen=$onyen_to_display"
		else
			OUTPUT="$OUTPUT\n $email Onyen=Unknown" 
                fi
                onyens_to_remove="$onyens_to_remove $onyen_to_display"
#		OUTPUT="$OUTPUT\n $email Onyen=$onyen_to_display"
	done
	echo -ne $OUTPUT | column -t
	printf "\nOnyens to remove:$onyens_to_remove\n"
echo
fi


