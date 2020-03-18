#!/bin/bash

##### Configuration
BASE_PATH=/datastore/lbgadmin/accounts
CONFIG_DIR=$BASE_PATH/conf
CONFIG_FILE=$CONFIG_DIR/config

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


#Parse a list of Onyens from the file /datastore/lbgadmin/accounts/output/onyen-active-accounts
USER_LIST=$(awk -F ',' '{print $1}' <$OUTPUT_ONYEN_ACTIVE_FILE | awk '{printf "%s ",$0}')

#Count the number of active users from the list stored in USER_LIST.
NUMBER_OF_USERS=$(echo $USER_LIST | wc -w)

EMAIL_ADDRESS_COUNTER=1

if [ -f "$OUTPUT_ACTIVE_USER_EMAIL_ADDRESSES" ]
then
	truncate -s 0 $OUTPUT_ACTIVE_USER_EMAIL_ADDRESSES
fi

for user in $USER_LIST
do

	#Display a loading counter
	echo "Getting active user email address $EMAIL_ADDRESS_COUNTER/$NUMBER_OF_USERS"

	#If the counter is less than the total number of users, get the email address for the current Onyen,
	#clear the line using printf, and increment the counter.
	if (($EMAIL_ADDRESS_COUNTER  < $NUMBER_OF_USERS))
	then
		$UNC_LDAPSEARCH_CMD $user mail uid | grep -E '(mail|uid)' | sort | awk -F ': ' '{print $2}' | awk '{printf "%s ",$0}' >> $OUTPUT_ACTIVE_USER_EMAIL_ADDRESSES;printf "\033[A"
		printf "\n" >> $OUTPUT_ACTIVE_USER_EMAIL_ADDRESSES
		EMAIL_ADDRESS_COUNTER=$((EMAIL_ADDRESS_COUNTER+1))

	#For the last Onyen we want to get the email address, increment the counter,
	#and display a final message but we don't want to clear the line.
	else
		#$UNC_LDAPSEARCH_CMD $user cn mail | grep -E '(mail|cn)' | sort -r | awk -F ': ' '{print $2}' | awk '{printf "%s ",$0}' >> $OUTPUT_ACTIVE_USER_EMAIL_ADDRESSES;
		$UNC_LDAPSEARCH_CMD $user mail uid | grep -E '(mail|uid)' | sort | awk -F ': ' '{print $2}' | awk '{printf "%s ",$0}' >> $OUTPUT_ACTIVE_USER_EMAIL_ADDRESSES
		printf "\n" >> $OUTPUT_ACTIVE_USER_EMAIL_ADDRESSES
		EMAIL_ADDRESS_COUNTER=$((EMAIL_ADDRESS_COUNTER+1))
	fi
done

echo "All email addresses can be found at $OUTPUT_ACTIVE_USER_EMAIL_ADDRESSES"
