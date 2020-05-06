#!/bin/bash

input_file=$1
input_file_name=$(echo $input_file | awk -F '/' '{print $NF}')
export TMPDIR=/tmp


fastqs="$(cat $input_file | awk '{print $2}')"
counter=1
truncate -s 0 /tmp/${input_file_name}-out
date >> /tmp/${input_file_name}-out
 
for file in $fastqs
do
echo "====Sending file $counter of 250====" >> /tmp/${input_file_name}-out 2>&1
filename="$(echo $file | awk -F '/' '{print $NF}')"
filepath="$(echo $file | awk -F '/' 'sub(FS $NF,x)')"
gsutil rsync -r -x "(?!${filename}$)" $filepath/ gs://lccc-gcp-archive$filepath/ >> /tmp/${input_file_name}-out 2>&1

let counter+=1
done
date >> /tmp/${inpute_file}-out
