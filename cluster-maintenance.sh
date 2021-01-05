#!/bin/bash

### Sanity checks
## check if running as root
if [[ "$EUID" -ne 0 ]]; then
	echo "Error: Must be run as root." >&2
	exit 1
fi

while getopts "se" option; do
  case $option in
    s) maintenance_start=yes;;
    e) maintenance_end=yes;;
    ?) echo "error: option -$OPTARG is not implemented"; exit ;;
  esac
done

if [ -z "$maintenance_start" ] && [ -z "$maintenance_end" ]; then
	echo "Please specify -s to start maintenance or -e to end maintenance"
	echo "Usage:"
	echo "To start maintenance (set all partitions down and suspend all jobs): cluster-maintenance.sh -s"
	echo "To end maintenance (set all partitions up and resume all jobs): cluster-maintenance.sh -e"
	exit 1
fi


if [[ "$maintenance_start" == "yes" ]]; then
	#Set all partitions to down state
	sinfo --format %R --noheader | xargs -I % sh -c 'scontrol update PartitionName=% State=DOWN'
	
	#Suspend all running jobs
	squeue --format %i --noheader | xargs scontrol suspend    

elif [[ "$maintenance_end" == "yes" ]]; then
	#Resume all suspended jobs
	squeue --format %i --noheader | xargs scontrol resume

	#Set all partitions to up state
	sinfo --format %R --noheader | xargs -I % sh -c 'scontrol update PartitionName=% State=UP'
fi
