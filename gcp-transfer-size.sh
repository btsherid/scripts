#!/bin/bash

sizes="$(grep -R "Operation completed" /datastore/serverdepot/netbackup/gcp-rsync-logs/* | awk -F ':' '{print $2}' | awk -F '/' '{print $2}' > /tmp/sizes)"
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

echo "Total size transferred to GCP is ${total_rounded}TB"
