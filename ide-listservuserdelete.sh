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

RED='\033[0;31m'
NOCOLOR='\033[0m'
ONYEN_COUNTER=1
onyens_to_delete=$*
if [[ $onyens_to_delete == "" ]] ; then
        printf "\nNo onyen given\n"
        printf "\nUsage: ide-listservuserdelete.sh <onyen> <onyen> <onyen> ...\n\n"
        exit 1
fi

ONYENS_TO_DELETE_COUNT=$(wc -w <<< $onyens_to_delete)
email_template=""

#This helps with formatting
echo	

for onyen in $onyens_to_delete
do
	#If less than 6 onyens, don't display counter. Just look up the email and name associated with the onyen.
	if [[ ONYENS_TO_DELETE_COUNT -lt 6 ]] ; then	
		onyen_email=$($UNC_LDAPSEARCH_CMD $onyen mail | grep mail | awk '{print $2}')
		onyen_name=$($UNC_LDAPSEARCH_CMD $onyen cn | grep cn | awk -F ': ' '{print $2}')
	#If more than 6 onyens, display counter. Also look up the email and name associated with the onyen.
	else
		echo "Working on onyen $ONYEN_COUNTER/$ONYENS_TO_DELETE_COUNT"
		onyen_email=$($UNC_LDAPSEARCH_CMD $onyen mail | grep mail | awk '{print $2}')
                onyen_name=$($UNC_LDAPSEARCH_CMD $onyen cn | grep cn | awk -F ': ' '{print $2}')
		ONYEN_COUNTER=$((ONYEN_COUNTER+1))
		#Clear line so counter only uses one line.
		printf "\033[A"
	fi
	#If the onyen doesn't exist, the email and the name will be blank.
	#In that case, print a warning. The multiple spaces at the end helps the output display nicely.
	if [ "$onyen_email" == "" ] || [ "$onyen_name" == "" ] ; then
        	printf "\n\033[A"
		echo -e "${RED}WARN${NOCOLOR}: Onyen ${RED}$onyen${NOCOLOR} not found                    "
	#If the onyen exists, add the name and the email to the email template.
	else
		email_template+="$onyen_name $onyen_email\n"
	fi	
done

if [[ $email_template == "" ]] ; then
        printf "\nNo users were added to the listserv.\n\n"
else
	#Send the email to add all the users to the listserv
	printf "login $IDE_LISTSERV_ADMIN_PW\ndelete lbg-ide-users quiet <<\n$email_template>>" | mail -s "" -r "root@<server script is run on>" <listserv email address>
	if [[ ONYENS_TO_DELETE_COUNT -lt 6 ]] ; then
                printf "\n\033[A"
        else
                printf "\n\033[A\n\n"
        fi
        printf "Deleted email(s):\n"
        printf "$email_template" | awk '{print $NF}'
        echo
	printf "\n\033[ADone! To check that the users were added successfully, go to https://<listserv web interface URL>\n\n"
fi
