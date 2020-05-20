#!/bin/bash

files="$(find /datastore/serverdepot/netbackup/gcp-rsync-logs/ -type f)"
grep -R "Operation completed" /datastore/serverdepot/netbackup/gcp-rsync-logs/* | awk -F ':' '{print $2}' | awk -F '/' '{print $2}' > /tmp/sizes
for entry in $files
do
	file_tail="$(tail $entry | grep -v "Operation completed")"
	echo $file_tail | grep ETA | awk -F '[' '{print $3}' | awk -F '/' '{print $1}' | grep -v "Content-Type" >> /tmp/running_sizes
done
TiB="$(grep TiB /tmp/sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
GiB="$(grep GiB /tmp/sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
MiB="$(grep MiB /tmp/sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
KiB="$(grep KiB /tmp/sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"

TB="$(echo "$TiB * 1.09951" | bc -l)"
GiB_to_TB="$(echo "$GiB / 931.323" | bc -l)"
MiB_to_TB="$(echo "$MiB / 953674" | bc -l)"
KiB_to_TB="$(echo "$KiB / 953674" | bc -l)"
total="$(echo "$TiB + $GiB_to_TB + $MiB_to_TB + $KiB_to_TB" | bc -l)"
total_rounded="$(echo $total | bc -l | xargs printf "%.2f")"

running_TiB="$(grep TiB /tmp/running_sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
running_GiB="$(grep GiB /tmp/running_sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
running_MiB="$(grep MiB /tmp/running_sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
running_KiB="$(grep KiB /tmp/running_sizes | awk '{print $1}' | awk "{sum+=\$1} END {print sum}")"
running_TB="$(echo "$running_TiB * 1.09951" | bc -l)"
running_GiB_to_TB="$(echo "$running_GiB / 931.323" | bc -l)"
running_MiB_to_TB="$(echo "$running_MiB / 953674" | bc -l)"
running_KiB_to_TB="$(echo "$running_KiB / 953674" | bc -l)"
running_total="$(echo "$running_TB + $running_GiB_to_TB + $running_MiB_to_TB + $running_KiB_to_TB" | bc -l)"
running_total_rounded="$(echo $running_total | bc -l | xargs printf "%.2f")"

overall_total="$(echo "$total + $running_total" | bc -l)"
overall_total_rounded="$(echo $overall_total | bc -l | xargs printf "%.2f")"
echo "Total size finished is ${total_rounded}TB"
echo "Total size finished for policies still copying is ${running_total_rounded}TB"
echo "Total size transferred to GCP is ${overall_total_rounded}TB"
rm /tmp/sizes
rm /tmp/running_sizes
