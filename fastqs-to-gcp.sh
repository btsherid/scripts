#!/bin/bash

## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi

fastqs="$(head -n 1000 /datastore/alldata/internal/BSPLIMS/Reports/files_du_hs.txt | awk '{print $2}')"
counter=1

for file in $fastqs
do
echo "====Sending file $counter of 1000===="
filename="$(echo $file | awk -F '/' '{print $NF}')"
filepath="$(echo $file | awk -F '/' 'sub(FS $NF,x)')"
/opt/google-cloud-sdk/bin/gsutil rsync -r -x "(?!${filename}$)" $filepath/ gs://lccc-gcp-archive$filepath/

let counter+=1
done
