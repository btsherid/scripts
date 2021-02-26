#!/bin/bash
CLUSTER_FILE="/datastore/serverdepot/useful-files/clustercores"

sinfo --all --long -N -o "%N,%T,%125E" | sort -u> ~/sinfo_output
total_cluster_nodes="$(awk '{print $1}' $CLUSTER_FILE | wc -l)"
total_nodes_available="$(awk -F ',' '{print $2}' ~/sinfo_output | grep "allocated\|completing\|idle\|mixed" | wc -l)"
percentage="$(echo "($total_nodes_available/$total_cluster_nodes) * 100" | bc -l | xargs printf "%.2f")"
headers="Cluster Nodes Available To Run Jobs,Total Cluster Nodes, % Nodes Available To Run Jobs"

total="$total_nodes_available,$total_cluster_nodes,$percentage"
blank=",,,"
echo -e "$headers\n$total\n$blank\n$output" | column -t -s ','

