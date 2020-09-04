#!/bin/bash

files="$(find /datastore/serverdepot/netbackup/gcp-rsync-logs/ -type f | grep -v esxwin | grep -v esxlin)"
grep -R "Operation completed" /datastore/serverdepot/netbackup/gcp-rsync-logs/* | awk -F ':' '{print $2}' | awk -F '/' '{print $2}' > /tmp/sizes

for entry in $files
do
	
	file_tail="$(tail $entry | grep -v "Operation completed")"
	echo $file_tail | grep "total size" | awk -F 'total size is' '{print $2}' | awk '{print $1}' >> /tmp/local_sizes
	echo $file_tail | grep ETA | awk -F '[' '{print $3}' | awk -F '/' '{print $1}' | grep -v "Content-Type" >> /tmp/running_sizes
done

TiB="$(grep TiB /tmp/sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
GiB="$(grep GiB /tmp/sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
MiB="$(grep MiB /tmp/sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
KiB="$(grep KiB /tmp/sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"

if [[ "$TiB" == "" ]]; then
	TiB="0"
fi

if [[ "$GiB" == "" ]]; then
	GiB="0"
fi

if [[ "$MiB" == "" ]]; then
	MiB="0"
fi

if [[ "$KiB" == "" ]]; then
	KiB="0"
fi

TB="$(echo "$TiB*1.09951" | bc -l)"
GiB_to_TB="$(echo "$GiB / 931.323" | bc -l)"
MiB_to_TB="$(echo "$MiB / 953674" | bc -l)"
KiB_to_TB="$(echo "$KiB / 976562500" | bc -l)"
total="$(echo "$TB + $GiB_to_TB + $MiB_to_TB + $KiB_to_TB" | bc -l)"
total_rounded="$(echo $total | bc -l | xargs printf "%.3f")"

local_total_bytes="$(awk '{print $1}' /tmp/local_sizes | tr -d ',' | awk "{sum+=\$1} END {print sum}")"
local_total="$(echo "$local_total_bytes/1024/1024/1024/1024" | bc -l)"
local_total_rounded="$(echo $local_total | bc -l | xargs printf "%.3f")"

running_TiB="$(grep TiB /tmp/running_sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
running_GiB="$(grep GiB /tmp/running_sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
running_MiB="$(grep MiB /tmp/running_sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
running_KiB="$(grep KiB /tmp/running_sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"

if [[ "$running_TiB" == "" ]]; then
        running_TiB="0"
fi

if [[ "$running_GiB" == "" ]]; then
        running_GiB="0"
fi

if [[ "$running_MiB" == "" ]]; then
        running_MiB="0"
fi

if [[ "$running_KiB" == "" ]]; then
        running_KiB="0"
fi


running_TB="$(echo "$running_TiB * 1.09951" | bc -l)"
running_GiB_to_TB="$(echo "$running_GiB / 931.323" | bc -l)"
running_MiB_to_TB="$(echo "$running_MiB / 953674" | bc -l)"
running_KiB_to_TB="$(echo "$running_KiB / 976562500" | bc -l)"
running_total="$(echo "$running_TB + $running_GiB_to_TB + $running_MiB_to_TB + $running_KiB_to_TB" | bc -l)"
running_total_rounded="$(echo $running_total | bc -l | xargs printf "%.3f")"

vm_snapshot_total="37"

overall_total="$(echo "$total + $local_total + $running_total + $vm_snapshot_total" | bc -l)"
overall_total_rounded="$(echo $overall_total | bc -l | xargs printf "%.3f")"

echo "Total size finished with GCP rsync is ${total_rounded}TB"
echo "Total size finished with local rsync is ${local_total_rounded}TB"
echo "Total size finished for policies still copying is ${running_total_rounded}TB"
echo "Total size finished for VM snapshots is ${vm_snapshot_total}TB"
echo "Total size transferred to GCP is ${overall_total_rounded}TB"

rm /tmp/sizes
rm /tmp/local_sizes
rm /tmp/running_sizes
