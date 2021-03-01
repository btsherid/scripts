#!/bin/bash
#Get date and time five minutes ago
FIVE_MINUTES_AGO="$(date --date='5 minute ago' +%Y-%m-%d-%H:%M:%S)"
YEAR="$(date +%Y)"
MONTH="$(date +%m)"
MINUTE="$(date +%M)"
STATS_FILE="/datastore/serverdepot/useful-files/ondemand/${YEAR}-slurm-job-stats/$YEAR-sacctout"
STATS_FILE_MONTH="/datastore/serverdepot/useful-files/ondemand/${YEAR}-slurm-job-stats/$YEAR-$MONTH-sacctout"
OUTPUT_FILE="/datastore/serverdepot/useful-files/ondemand/${YEAR}-slurm-job-stats/$YEAR-slurm-jobs"
OUTPUT_FILE_MONTH="/datastore/serverdepot/useful-files/ondemand/${YEAR}-slurm-job-stats/$YEAR-$MONTH-slurm-jobs"

#Get data for user jobs started/ended in the last five minutes. Ignore Unknown entries because those are still running.
sacct --allusers --noheader --format=jobid,jobname%30,start,end,user%30 --starttime=$FIVE_MINUTES_AGO  | grep -v Unknown >> $STATS_FILE_MONTH

#Get a list of output files in the output folder
month_files="$(ls /datastore/serverdepot/useful-files/ondemand/${YEAR}-slurm-job-stats/${YEAR}-*-sacctout)"

#Cat out all the output files and aggregate them into a single large output file
cat $month_files > $STATS_FILE

#Get user job counts for the entire year only every 30 minutes
if [ $MINUTE -eq 0 ] || [ $MINUTE -eq 30 ]; then
	/datastore/serverdepot/bin/cluster-job-totals.sh > $OUTPUT_FILE
	sed -i '2 i \ ' $OUTPUT_FILE
fi

#Ensure a symlink exists pointing to the current month's output file
if [ ! -L "/datastore/serverdepot/useful-files/ondemand/${YEAR}-slurm-job-stats/current-month-jobs" ]; then
	ln -s ./${YEAR}-${MONTH}-slurm-jobs /datastore/serverdepot/useful-files/ondemand/${YEAR}-slurm-job-stats/current-month-jobs
fi

#Ensure the symlink points to the current month's output file
symlink_month="$(ls -la /datastore/serverdepot/useful-files/ondemand/${YEAR}-slurm-job-stats/current-month-jobs | awk '{print $NF}' | awk -F '-' '{print $2}')"
if ! [[ "$symlink_month" == "$MONTH" ]]; then
	ln -sfn ./${YEAR}-${MONTH}-slurm-jobs /datastore/serverdepot/useful-files/ondemand/${YEAR}-slurm-job-stats/current-month-jobs
fi

#Get user job counts for the current month
/datastore/serverdepot/bin/cluster-job-totals.sh $MONTH > $OUTPUT_FILE_MONTH
sed -i '2 i \ ' $OUTPUT_FILE_MONTH
