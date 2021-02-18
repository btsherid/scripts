#!/bin/bash

## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi

#Get today's date in seconds
today="$(date +%s)"
BUCKETDIR="/NS/lccc-gcp-archive"

#Get a list of all GCP directories named .snapshot
directories="$(find /NS/lccc-gcp-archive/NS -maxdepth 2 -type d -name .snapshot | tr '\n' ' ')"
#directories="$(cat /tmp/snapshot_dirs | tr '\n' ' ')"

for dir in $directories
do
	#Take the local file path and strip of the /NS/lccc-gcp-archive from it
	gcp_snapshot_dir_pre="$(echo $dir | awk -F '/' '{for (i=4; i<=NF; i++) print $i}' | tr '\n' '/')"
	


	#Get a list of all the subfolders under .snapshot containing Non-VLAN452, weekly, or Windows
	snapshot_dirs="$(ls $dir | grep "Non-VLAN452\|weekly\|Windows")"
	for snapshotdir in $snapshot_dirs
	do
	
		#Set the GCP path from the stripped local path
		gcp_snapshot_dir="gs://lccc-gcp-archive/$gcp_snapshot_dir_pre${snapshotdir}/**"

		#Parse the date of the subfolder based on its name
		snapshotdir_date="$(echo $snapshotdir | tr '.' '_' | awk -F '_' '{print $2}')"

		#Get the first entry of the date
		snapshotdir_date_first="$(echo $snapshotdir_date | awk -F '-' '{print $1}')"

		#Implement logic to rewrite unacceptable date formats
		#Dates of this format will work and can be used by the date command: 2020-12-13
		#Dates of this format will not work and can't be used by the date command: 01-06-2021
		#So if first entry is less than or equal to 12, we know it is a month not a year and we need to put the date into the acceptable format.
		#For example, if the date is 01-02-2021, the if block will set snapshotdir_date_formatted to 2021-01-02
		if [ "$snapshotdir_date_first" -le "12" ]; then
			snapshotdir_date_second="$(echo $snapshotdir_date | awk -F '-' '{print $2}')"
			snapshotdir_date_third="$(echo $snapshotdir_date | awk -F '-' '{print $3}')"
			snapshotdir_date_formatted="$(date -d "$snapshotdir_date_third-$snapshotdir_date_first-$snapshotdir_date_second" +%Y-%m-%d)"
		#If the date format is already acceptable, save it to the variables
		else
			snapshotdir_date_formatted="$(date -d "$snapshotdir_date" +%Y-%m-%d)"
		fi
		
		#Convert the date of the subfolder to seconds so we can compare it to today.
		snapshotdir_date_formatted_seconds="$(date -d "$snapshotdir_date_formatted" +%s)"

		#Get the difference in days between the subfolder date and today
		datediff="$(echo "($today - $snapshotdir_date_formatted_seconds)/60/60/24" | bc -l | xargs printf "%.0f")"
	
		#If the subfolder is older than 90 days, delete it. GCP charges an early deletion fee for items less than 90 days old so I made the if statement 95 to ensure we don't get charged.	
		if [ "$datediff" -ge "95" ]; then
			gsutil rm -a $gcp_snapshot_dir
		fi
		
	done
done
