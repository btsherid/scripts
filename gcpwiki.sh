#!/bin/bash

days_back=$1

if [[ "$days_back" == "" ]]; then
	days_back="2"
fi	

#Find all gcp rsync log files with modified time in the last 30 days.
backups="$(find /datastore/serverdepot/netbackup/gcp-rsync-logs -mtime -$days_back -type f)"
backups_completed_successfully=""

#For each file found, determine whether the run was successful or not
for filename in $backups
do
	rsync_complete="$(tail $filename | grep "rsync ran\|rclone sync ran" $filename)"
	rsync_error="$(grep -e "aborting\|rsync error\|ERROR\|Failed" $filename)"
	
	#If the string "rsync ran" is in the log file, and the log file doesn't contain the word "aborting", consider it successful
	if ! [[ "$rsync_complete" == "" ]]; then
		if [[ "$rsync_error" == "" ]]; then
			backups_completed_successfully="$backups_completed_successfully $filename"
		fi
	fi
	
done

headers="Path,End Date,End Time,Size Copied(GB)"
echo $headers
output=""
#For each successful run log file, get the policy name, end date, end time, and size transferred.
for entry in $backups_completed_successfully
do
	policy="$(echo $entry | awk -F '/' '{print $6}')"
	end_date="$(grep -A1 "End time" $entry | grep "EDT\|EST" | awk '{print $2 " " $3}')"
	end_time="$(grep -A1 "End time" $entry | grep "EDT\|EST" | awk '{print $4}')"
	gcp="$(grep "Operation completed" $entry)"
	rsync="$(grep "total size is" $entry)"
	rclone="$(tail -n 10 $entry | grep "Bytes,")"

	#If the run was a gsutil rsync and copied data, then compute the size as below	
	if ! [[ "$gcp" == "" ]]; then
		grep "Operation completed" $entry | awk -F '/' '{print $2}' > /tmp/backup_size
		TiB_check="$(grep TiB /tmp/backup_size)"
		GiB_check="$(grep GiB /tmp/backup_size)"
		MiB_check="$(grep MiB /tmp/backup_size)"
		KiB_check="$(grep KiB /tmp/backup_size)"

                if [[ "$TiB_check" == "" ]]; then
                        TiB_to_GB="0"
                else
                        TiB="$(grep TiB /tmp/backup_size | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
			TiB_to_GB="$(echo "$TiB * 1099.51" | bc -l)"
                fi

                if [[ "$GiB_check" == "" ]]; then
                        GB="0"
                else
                        GiB="$(grep GiB /tmp/backup_size | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
                        GB="$(echo "$GiB * 1.07374" | bc -l)"
                fi

                if [[ "$MiB_check" == "" ]]; then
                        MiB_to_GB="0"
                else
                        MiB="$(grep MiB /tmp/backup_size | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
                        MiB_to_GB="$(echo "$MiB / 953.674" | bc -l)"
                fi

                if [[ "$KiB_check" == "" ]]; then
                        KiB_to_GB="0"
                else
                        KiB="$(grep KiB /tmp/backup_size | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
                        KiB_to_GB="$(echo "$KiB / 976563" | bc -l)"
                fi

                total="$(echo "$TiB_to_GB + $GB + $MiB_to_GB + $KiB_to_GB" | bc -l)"
                total_rounded="$(echo $total | bc -l | xargs printf "%.2f")"
		
	#If the run was a regular rsync and copied data, then compute the size as below
	elif ! [[ "$rsync" == "" ]]; then
		bytes="$(grep "total size is" $entry | awk '{print $4}' | tr -d ',')"
		total="$(echo "$bytes / 1000000000" | bc -l)"
		total_rounded="$(echo $total | bc -l | xargs printf "%.2f")"
	
	elif ! [[ "$rclone" == "" ]]; then
		B="$(tail $entry | grep Bytes | grep -v "KBytes\|MBytes\|GBytes\|TBytes")"
		KB="$(tail $entry | grep KBytes)"
		MB="$(tail $entry | grep MBytes)"
		GB="$(tail $entry | grep GBytes)"
		TB="$(tail $entry | grep TBytes)"
		number="$(tail $entry | grep "Bytes," | awk -F 'Bytes' '{print $1}' | awk '{print $(NF-1)}')"
		if ! [[ "$B" == "" ]]; then
			total="$(echo $number /1024 /1024 /1024 | bc -l)"
			total_rounded="$(echo $total | bc -l | xargs printf "%.2f")"
		fi
	
		if ! [[ "$KB" == "" ]]; then
			total="$(echo $number /1024 /1024 | bc -l)"
			total_rounded="$(echo $total | bc -l | xargs printf "%.2f")"
		fi
		
		if ! [[ "$MB" == "" ]]; then
                        total="$(echo $number /1024 | bc -l)"
			total_rounded="$(echo $total | bc -l | xargs printf "%.2f")"
                fi

		if ! [[ "$GB" == "" ]]; then
                        total="$number"
			total_rounded="$(echo $total | bc -l | xargs printf "%.2f")"
                fi

		if ! [[ "$TB" == "" ]]; then
                        total="$(echo $number *1024 | bc -l)"
			total_rounded="$(echo $total | bc -l | xargs printf "%.2f")"
                fi
	
	#If the run did not copy data, set the total to 0.
	else
		total_rounded="0"
	fi

#	output="$output\n$policy $policy_date $policy_time $total_rounded\n"

	#Save output for printing
	output="$output\in$policy,$end_date,$end_time,$total_rounded\n"
	echo $output
done

#Print output
echo -e "$headers\n$output" | column -t -s ',' | sort -k2M -k3n -k4
