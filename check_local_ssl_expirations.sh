#!/bin/bash

################################
# check_local_ssl_expirations.sh
# 
# Usage: check_local_ssl_expirations.sh <options> <path to cert> <path to cert> <path to cert>...
# 
# Options: 
#		-w  Set the warning time to the argument (overriding the default 60 days) 
#		-c  Set the warning time to the argument (overriding the default 30 days) 
#		-f  Supply a file with a list of certificates to be checked.
# Examples:
#		This will set the warning time to 120 days and leave the critical time at the default 30 days.
#		check_local_ssl_expirations_nagios.sh -w 120 <path to cert> <path to cert>...
#
#		This will set the critical time to 10 days and leave the warning time at the default 60 days.
#		check_local_ssl_expirations_nagios.sh -c 10 <path to cert> <path to cert>...
#
#		This will override the default settings and set the warning time to 30 days and the critical time to 10 days.
#		check_local_ssl_expirations_nagios.sh -w 30 -c 10 <path to cert> <path to cert>...
#
#		This will check all of the certs in the supplied file with the default warning and critical times.
#		check_local_ssl_expirations_nagios.sh -f <path to file with list of certs> 
#
#		This will set the warning time to 120 days and check all of the certs in the supplied file.
#
#		check_local_ssl_expirations_nagios.sh -w 120 -f <path to file with list of certs>
#
#		This will set the critical time to 10 days and check all of the certs in the supplied file.
#		check_local_ssl_expirations_nagios.sh -c 10 -f <path to file with list of certs>
#
#		This will override the defaults and check all of the certs in the supplied file.
#		check_local_ssl_expirations_nagios.sh -w 30 -c 10 -f <path to file with list of certs>
#		
# Sample from /etc/nagios/nrpe.cfg:
# command[check_local_ssl_expirations_nagios]=/datastore/serverdepot/bin/check_local_ssl_expirations_nagios.sh /var/pkg/ssl/fd285a3ef4ad390b77c3fc085f966a1036044705
#
################################



# Exit codes:
# 0 = Certificate will not expire in 60 days or less 
OK=0
OKmsg="OK"
# 1 = Certificate will expire in 60 days or less
WARN=1
WARNmsg="WARNING"
# 2 = Certificate will expire in 30 days or less
CRIT=2
CRITmsg="CRITICAL"
# 3 = Unknown state
UNK=3
UNKmsg="UNKNOWN"


#By default the critical time is 30 days and the warning time is 60 days.
exitStatus=$OK
CommandLineInput="$*"
CertList=""
CertListFromFile=""
CriticalDays=""
CriticalSeconds="2592000"
WarningDays=""
WarningSeconds="5184000"
ExpirationDates=""
NewLine=$'\n'
#This logic sets the CertList variable to whatever is listed after the options.

if [ "$5" == "-c" ] || [ "$5" == "-w" ] || [ "$5" == "-f" ]; then
	CertList=${@:7}
elif [ "$3" == "-c" ] || [ "$3" == "-w" ] || [ "$3" == "-f" ]; then
	CertList=${@:5}
elif [ "$1" == "-c" ] || [ "$1" == "-w" ] || [ "$1" == "-f" ]; then
	CertList=${@:3}
else
	CertList=${@:1}
fi

#This logic handles the various options

while getopts ":c:w:f:" opt; do
	case $opt in

		#If the -c flag is present, set the critical expire time to the argument, converted to seconds.
		c)
			#Check if the argument is a positive integer.
			re='^[0-9]+$'
			if ! [[ $OPTARG =~ $re ]] ; then
				echo "Error: -c requires a positive integer" >&2;
				exit 1

			else
				CriticalDays=$OPTARG
				let CriticalSeconds="$OPTARG*60*60*24" >&2

			fi
		;;
		
		#If the -w flag is present, set the warning expire time to the argument, converted to seconds.
		w)
			#Check if the argument is a positive integer.
			re='^[0-9]+$'
			if ! [[ $OPTARG =~ $re ]] ; then
				echo "Error: -w requires a positive integer" >&2;
				exit 1

			else
				WarningDays=$OPTARG
				let WarningSeconds="$OPTARG*60*60*24" >&2

			fi
		;;

		#If the -f flag is present, read cert file names in from the supplied file.
		f)

			#The argument supplied should be a file. Check if it exists.
			#If not, exit. If so, read in the contents.
			if [ ! -f $OPTARG ]; then
				echo "File $OPTARG does not exist"
				exit 1

			#This covers the contingency where a user has a file and certificates to check
			#but forgets to put the file name after -f. That would like like -f <path to cert>.
			#We want to alert the user they didn't add a file.
			elif [ "$(head -n 1 $OPTARG)" == "-----BEGIN CERTIFICATE-----" ]; then
				echo "File supplied to -f is a certificate, not a list of certificate files"
				exit 1
			
			#Take all the entries in the file and add them to CertList
			else
				while read line
				do
					CertListFromFile="${CertListFromFile} ${line}"
				done < $OPTARG
				fi

				CertList="${CertListFromFile} ${CertList}"
		;;

		#If any other arguments than t or f are entered, exit.
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
		;;

		#If an option is entered with nothing after it, exit.
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
		;;

		*)
			echo "Unknown option"
		;;
	esac
done

for cert in $CertList
do

	#Check if cert does not exist. If anything supplied to check does not exist, elevate to WARNING.
	if [ ! -f $cert ]; then
		ExpirationDates="${ExpirationDates}${NewLine}${cert} does not exist"
		if ! [[ "$exitStatus" -eq 2 ]]; then
			exitStatus=$WARN
		fi

	#Check if argument supplied is not a certificate. If anything supplied to check is not a cert, elevate to WARNING.
	elif [ "$(grep 'BEGIN CERTIFICATE' $cert 2>/dev/null)" == "" ]; then
		ExpirationDates="${ExpirationDates}${NewLine}${cert} is not a certificate"
		if ! [[ "$exitStatus" -eq 2 ]]; then
			exitStatus=$WARN
		fi
	
	#Check when certificate expires. If it expires in 30 days or less, elevate to CRITICAl otherwise elevate to WARNING.
	else
		ExpirationDate="$((openssl x509 -noout -text -in $cert | grep "Not After" | awk '{ print substr($0, index($0,$4)) }') 2>/dev/null)"
		ExpirationDates="${ExpirationDates}${NewLine}${cert} expires on ${ExpirationDate}"

			
			#Check if the certificate expires in 60 days.
			openssl x509 -noout -checkend $WarningSeconds -in $cert 2>/dev/null
		
			#If the output of the openssl command is 0, then the cert will not expire. 
			#If it is 1, then it will expire.
			if [ $? -eq 1 ]; then

				if ! [[ $exitStatus -eq $CRIT ]]; then
					exitStatus=$WARN
				fi
			fi
		
			#Check if the certificate expires in 30 days.
			openssl x509 -noout -checkend $CriticalSeconds -in $cert 2>/dev/null

			#If the output of the openssl command is 0, then the cert will not expire. 
			#If it is 1, then it will expire.
			if [ $? -eq 1 ]; then
				exitStatus=$CRIT
			fi
		fi
done		

case "$exitStatus" in

			"$OK")
				echo $OKmsg
				echo $ExpirationDates
				exit $OK
			;;

			"$WARN")
				echo $WARNmsg
				echo $ExpirationDates
				exit $WARN
			;;

			"$CRIT")
				echo $CRITmsg
				echo $ExpirationDates
				exit $CRIT
			;;

			"$UNK")
				echo $UNKmsg
				echo $ExpirationDates
				exit $UNK
			;;

			*)
				echo $UNKmsg
				exit $UNK
			;;
esac

