#!/bin/bash

## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi


#Get a list of the running VMs on this server
virtservers=$(virsh list --all | grep running | awk '{print $2}' | grep -v brian)

#Get the date in YYYYmmdd format
date="$(date '+%Y%m%d')"

#Get the date three weeks ago in YYYYmmdd format
deletion_date="$(date --date="3 weeks ago" '+%Y%m%d')"
deletion_date_seconds=$(date --date "$deletion_date" +'%s')

#Get the date all the snapshots were taken
#snapshot_dates="$(virsh snapshot-list --domain snapcenter | tail -n+3 | grep cron-snapshot | awk '{print $1}' |  awk -F '-' '{print $3}' | tr '\n' ' ')"


 
for virtualserver in $virtservers
do
	#virsh snapshot-create-as --domain $virtualserver --name "cron-snapshot-$date" > /dev/null 2>&1
	snapshot_dates="$(virsh snapshot-list --domain $virtualserver | tail -n+3 | grep cron-snapshot | awk '{print $1}' |  awk -F '-' '{print $3}' | tr '\n' ' ')"
	for date in $snapshot_dates	
	do
		date_seconds=$(date --date "$date" +'%s')
		if [ "$date_seconds" -lt "$deletion_date_seconds" ]; then
			virsh snapshot-delete $virtualserver cron-snapshot-$date > /dev/null 2>&1
		fi
	done
done

