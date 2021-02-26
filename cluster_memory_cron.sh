#!/bin/bash
/opt/stack/bin/stack run host command="free -h | grep Mem" | grep Mem | awk '{print $1,$2,$3,$NF}' | grep -v "ondemand\|vm-aba\|vm-cron\|vm-login" | sort > /datastore/serverdepot/useful-files/cluster_memory_tmp_h

/opt/stack/bin/stack run host command="free | grep Mem" | grep Mem | awk '{print $1,$2,$3,$NF}' | grep -v "ondemand\|vm-aba\|vm-cron\|vm-login" | sort > /datastore/serverdepot/useful-files/cluster_memory_tmp_k
truncate -s 0 /datastore/serverdepot/useful-files/cluster_memory
while read -r line
do
	first="$(echo $line | awk '{print $1}')"
	third="$(echo $line | awk '{print $3}')"
	fourth="$(echo $line | awk '{print $4}')"
	new_line="$(echo ${first}.local $third $fourth $fifth)"
	echo $new_line >> /datastore/serverdepot/useful-files/cluster_memory_tmp
done < /datastore/serverdepot/useful-files/cluster_memory_tmp_h

while read -r line
do
        first="$(echo $line | awk '{print $1}')"
        third="$(echo $line | awk '{print $3}')"
        fourth="$(echo $line | awk '{print $4}')"
        new_line="$(echo ${first}.local $third $fourth $fifth)"
        echo $new_line >> /datastore/serverdepot/useful-files/cluster_memory_tmp_k_local
done < /datastore/serverdepot/useful-files/cluster_memory_tmp_k


while read -r line
do
	server="$(echo $line | awk '{print $1}')"
	final_entry="$(grep $server /datastore/serverdepot/useful-files/cluster_memory_tmp_k_local | awk '{print $2,$3}')"
	final_line="$(echo $line $final_entry)"
	echo $final_line >> /datastore/serverdepot/useful-files/cluster_memory
done < /datastore/serverdepot/useful-files/cluster_memory_tmp
rm /datastore/serverdepot/useful-files/cluster_memory_tmp_h
rm /datastore/serverdepot/useful-files/cluster_memory_tmp_k
rm /datastore/serverdepot/useful-files/cluster_memory_tmp_k_local
rm /datastore/serverdepot/useful-files/cluster_memory_tmp
