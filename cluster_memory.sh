#!/bin/bash
CLUSTER_FILE="/datastore/serverdepot/useful-files/clustercores"
MEMORY_FILE="/datastore/serverdepot/useful-files/cluster_memory"
output=""
total_memory_kb="$(awk '{print $4}' $MEMORY_FILE | awk "{sum+=\$1} END {print sum}")"
total_memory_tb="$(echo "$total_memory_kb/1024/1024/1024" | bc -l | xargs printf "%.2f")"
total_memory_available_kb="$(awk '{print $5}' $MEMORY_FILE | awk "{sum+=\$1} END {print sum}")"
total_memory_available_tb="$(echo "$total_memory_available_kb/1024/1024/1024" | bc -l | xargs printf "%.2f")"
percentage="$(echo "($total_memory_available_kb/$total_memory_kb) * 100" | bc -l | xargs printf "%.2f")"
headers="Node Name,Total Memory,Memory Available,% Memory Available"

while read -r line;
do
	server="$(echo $line | awk '{print $1}')"
	mem_total="$(grep $server $MEMORY_FILE | awk '{print $2}')"
	if [[ $mem_total == "" ]]; then
		mem_total="Unknown"
	fi
	mem_available="$(grep $server $MEMORY_FILE | awk '{print $3}')"
	if [[ $mem_available == "" ]]; then
                mem_available="Unknown"
        fi
	mem_total_kb="$(grep $server $MEMORY_FILE | awk '{print $4}')"
	if [[ $mem_total_kb == "" ]]; then
                mem_total_kb="Unknown"
        fi
	mem_available_kb="$(grep $server $MEMORY_FILE | awk '{print $5}')"
        if [[ $mem_available_kb == "" ]]; then
                mem_available_kb="Unknown"
        fi
	if ! [[ "$mem_available_kb" == "Unknown" ]] && ! [[ "$mem_total_kb" == "" ]]; then
		percentage="$(echo "($mem_available_kb/$mem_total_kb) * 100" | bc -l | xargs printf "%.2f")"	
	else
		percentage="Unknown"
        fi
	output="$output\n$server,$mem_total,$mem_available,$percentage"
done < $CLUSTER_FILE

total="Totals,${total_memory_tb}T,${total_memory_available_tb}T,$percentage"
blank=",,,"
echo -e "$headers\n$total\n$blank\n$output" | column -t -s ','
