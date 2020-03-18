#!/bin/bash

## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi


if [[ -z "$1" ]]; then
        echo "Usage: $(basename "$0") <vm name to be live migrated>"
        echo
        exit 1
fi

#VM to be live migrated will be first argument
server="$1"

#Get hostname of this turtle
hostname=$(hostname)

#Step to prompt for XML file copy
if [ "$hostname" == "KVM host 1 FQDN" ]; then
	echo "Please copy /etc/libvirt/qemu/${server}.xml to KVM host 2 FQDN. Ensure that the modified date on KVM host 1 is more current than the modified date on KVM host 2 before copying."
elif [ "$hostname" == "KVM host 2 FQDN" ]; then
	echo "Please copy /etc/libvirt/qemu/${server}.xml to KVM host 1 FQDN. Ensure that the modified date on KVM host 2 is more current than the modified date on KVM host 1 before copying."
fi
read -p "Hit y when the copying is complete. Hit any other key to exit. " -n 1 -r
echo
if [[ ! $REPLY = "y" ]]; then
        exit 1
fi

#Get names of all snapshots from server
snapshot_names="$(virsh snapshot-list --domain $server | tail -n+3 | grep cron-snapshot | awk '{print $1}' | tr '\n' ' ')"

#If server has snapshots, backup them up and then delete them
if ! [ "$snapshot_names" == "" ]; then

	#If snapshot backup dir does not exist, create it
	if ! [ -d "/tmp/${server}-snapshot-backups" ]; then
		mkdir /tmp/${server}-snapshot-backups
	fi

	#Backup then delete all snapshots from server
	echo "Backing up snapshots to /tmp/${server}-snapshot-backups and then deleting"
	for name in $snapshot_names
	do
		virsh snapshot-dumpxml $server $name > /tmp/${server}-snapshot-backups/${name}-bk.xml
		virsh snapshot-delete $server $name > /dev/null 2>&1
	done
fi

#Migrate
if [ "$hostname" == "KVM host 1 FQDN" ]; then
	echo "Migrating to KVM host 2. Enter root PW for KVM host 2"
	virsh migrate --live $server qemu+ssh://KVM host 2 FQDN/system
elif [ "$hostname" == "KVM host 2 FQDN" ]; then
	echo "Migrating to KVM host 1. Enter root PW for KVM host 1 FQDN"
	virsh migrate --live $server qemu+ssh://KVM host 1 FQDN/system
fi

