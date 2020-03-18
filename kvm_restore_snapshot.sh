#!/bin/bash

## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi


if [[ -z "$1" ]]; then
        echo "Usage: $(basename "$0") <vm name to restore snapshots for>"
        echo
        exit 1
fi

#VM to be live migrated will be first argument
server="$1"

#Get names of all snapshots 
snapshot_names="$(ls /tmp/${server}-snapshot-backups | tr ' ' '\n' | tr '\n' ' ')"

#Restore all snapshots to server
for name in $snapshot_names
do
	virsh snapshot-create --redefine $server /tmp/${server}-snapshot-backups/$name 
done
