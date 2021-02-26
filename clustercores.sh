#!/bin/bash
CLUSTER_FILE="/datastore/serverdepot/useful-files/clustercores"

squeue -O "jobid,username,numcpus,nodelist" > ~/squeue_output
total_cluster_cores="$(awk '{print $2}' $CLUSTER_FILE | awk "{sum+=\$1} END {print sum}")"
total_cores_requested="$(awk '{print $3}' ~/squeue_output | awk "{sum+=\$1} END {print sum}")"
percentage="$(echo "($total_cores_requested/$total_cluster_cores) * 100" | bc -l | xargs printf "%.2f")"
headers="Node Name,Cores Requested,Total Cores,% Cores Requested"

output=""
while read -r line;
do
	server="$(echo $line | awk '{print $1}')"
	cores="$(grep $server ~/squeue_output | awk '{print $3}' | awk "{sum+=\$1} END {print sum}")"
	cores_server="$(grep $server $CLUSTER_FILE | awk '{print $2}')"
	if [[ "$cores" == "" ]]; then
		cores="0"
	fi
	percentage_server="$(echo "($cores/$cores_server) * 100" | bc -l | xargs printf "%.2f")"
	output="$output\n$server,$cores,$cores_server,$percentage_server"
done < $CLUSTER_FILE

total="Totals,$total_cores_requested, $total_cluster_cores,$percentage"
blank=",,,"
echo -e "$headers\n$total\n$blank\n$output" | column -t -s ','
rm ~/squeue_output
