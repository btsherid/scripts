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

email=$1

	#Send the email to add all the users to the listserv
	printf "login $LISTSERV_ADMIN_PW\ndelete lbg-users quiet $email" | mail -s "" -r "root@<server script is run on>" <listserv email address>
	echo
	echo "Done! To check that $email was removed successfully, go to <listserv web interface URL>"
	echo
