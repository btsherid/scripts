#!/bin/bash
CLUSTER_FILE="/datastore/serverdepot/useful-files/clustercores"

sinfo --all --long -N -o "%N,%T,%125E" | sort -u> ~/sinfo_output
total_cluster_nodes="$(awk '{print $1}' $CLUSTER_FILE | wc -l)"
total_nodes_available="$(awk -F ',' '{print $2}' ~/sinfo_output | grep "allocated\|completing\|idle\|mixed" | wc -l)"
percentage="$(echo "($total_nodes_available/$total_cluster_nodes) * 100" | bc -l | xargs printf "%.2f")"
headers="Node Name,Node State,Reason Node Not Available"
output=""
while read -r line;
do
	server="$(echo $line | awk '{print $1}')"
	state="$(grep $server ~/sinfo_output | awk -F ',' '{print $2}')"
	reason_down="$(grep $server ~/sinfo_output | awk -F ',' '{print $3}'| xargs)"
	if [[ "$reason_down" == *"none"* ]]; then
		reason_down="N/A"
	fi
	if ! [[ "$reason_down" == "N/A" ]] && ! [[ "$reason_down" == *"these users"* ]]; then
		reason_down="Sys Admin Intervention needed"
	fi
	output="$output\n$server,$state,$reason_down"
done < $CLUSTER_FILE


echo -e "$headers\n$output" | column -t -s ','
rm ~/sinfo_output
