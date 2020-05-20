#!/bin/sh

month="$1"
server="$2"

### Sanity checks
## check if not running as root
if ! [[ "$EUID" -eq 0 ]]; then
        echo "Error: Must be run as root."
        exit 1;
fi


#If the first argument is empty, exit with usage
if [[ -z $1 ]]; then
        echo
        echo "Not enough arguments"
        echo
        echo "Usage: user_login_search.sh <month> <server name>"
        echo
        exit 1;
#If the second argument is empty, exit with usage
elif [[ -z $2 ]]; then
        echo
        echo "Not enough arguments"
        echo
        echo "Usage: user_login_search.sh <month> <server name>"
        echo
        exit 1;
fi

#Checking if the server name has a "." in it will check if the FQDN 
#was entered instead of the server name (i.e femto.med.unc.edu instead of femto)
if [[ $server == *"."* ]]; then
        echo "Enter server name only, not FQDN"
	echo "Usage: user_login_search.sh <month> <server name>"
	exit 1;
fi

#Check if the entered host name exists in DNS
server_check="$(host $server | grep "not found")"


#If month was not entered in the required format, exit and print a usage message
if ! [[ "$month" = "Jan" || "$month" = "Feb" || "$month" = "Mar" || "$month" = "Apr" || "$month" = "May" || "$month" = "Jun" || "$month" = "Jul" || "$month" = "Aug" || "$month" = "Sep" || "$month" = "Oct" || "$month" = "Nov" || "$month" = "Dec"  ]]; then
	echo "Please enter the month as one of the following: Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
	exit 1;
fi

#If host does not exist in DNS, print the error output of the host command
if ! [[ -z $server_check ]]; then
	echo $server_check
	exit 1;
fi


#If everything checks out, run the check and print the results
users=$(grep Accepted /datastore/logstore/secure* | grep -v grep | grep $server | grep $month | awk -F ':' '{print $5}' | awk '{print $4}' | sort -u)
echo  $users | tr " " "\n"

