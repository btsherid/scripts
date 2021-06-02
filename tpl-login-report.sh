#!/bin/bash

last_month="$(date --date='-1 month' +%b)"
year="$(date +%Y)"
data_dir="/datastore/serverdepot/TPL_Statistics/"

/bin/gsutil cp gs://lccc-gcp-archive/server-backups/tpl-spectrum3.ad.unc.edu/Program\ Files\ \(x86\)/Aperio/WebServer/logs/access.log* $data_dir
log_files="$(ls access.log.*)"
for file in $log_files
do
	cat $file >> access.log
done

/datastore/serverdepot/bin/tpl-login-stats.sh $last_month access.log > ${data_dir}/monthly_reports/${year}-$last_month
