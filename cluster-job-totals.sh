#!/bin/bash
MONTH="$1"
YEAR="$(date +%Y)"
OUTPUT_FILE="/datastore/serverdepot/useful-files/ondemand/${YEAR}-slurm-job-stats/${YEAR}-sacctout"
OUTPUT_FILE_MONTH="/datastore/serverdepot/useful-files/ondemand/${YEAR}-slurm-job-stats/${YEAR}-${MONTH}-sacctout"

#Get a list of users that are in the OUTPUT_FILE
users="$(awk '{print $NF}' $OUTPUT_FILE | grep -v "2020\|2021\|Unknown" | sort -u)"

#The month is a user submitted argument. If not submitted, set it to blank. If submitted in the wrong format, exit and display usage. 
if [[ $MONTH == "" ]]; then
	MONTH=""
elif ! [[ $MONTH == *[0-9]* ]]; then
	echo "Invalid month. Please specify month in number format."
	echo "Usage /datastore/serverdepot/bin/cluser-job-totals.sh <month (01-12) (optional)>"
	exit 1

fi

#Do calculations for every username in the OUTPUT_FILE
for entry in $users
do
	#If user submitted a month as an argument, get information only for that month
	if ! [[ "$MONTH" == "" ]]; then
		#Get a number of jobs for the user in the OUTPUT_FILE for $MONTH
		jobs_count_num="$(grep $entry $OUTPUT_FILE_MONTH | grep -v "bat\|ext" | awk '{print $1}' | sort -u | wc -l)"
		echo $jobs_count_num >> /tmp/jobs.count

		#Add thousands comma separator for job_count_num
		jobs_count="$(echo $jobs_count_num | xargs printf "%'.f\n")"
	else
		#Get a number of jobs for the user in the OUTPUT_FILE
		jobs_count_num="$(grep $entry $OUTPUT_FILE | grep -v "bat\|ext" | awk '{print $1}' | sort -u | wc -l)"
		echo $jobs_count_num >> /tmp/jobs.count

		#Add thousands comma separator for job_count_num
		jobs_count="$(echo $jobs_count_num | xargs printf "%'.f\n")"
	fi
	if [ "$jobs_count_num" -gt 0 ]; then
	        output="$output\n$entry;$jobs_count"
	fi
done

total_jobs="$(awk '{print $1}' /tmp/jobs.count | awk "{sum+=\$1} END {print sum}" | xargs printf "%'.f\n")"
total_row="Total;$total_jobs"
echo -e "$total_row\n$output" | sort -k2 -n | column -t -s ';' | sort -k2 -n -r 
rm /tmp/jobs.count
