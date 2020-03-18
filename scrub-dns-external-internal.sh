#!/bin/bash

if [[ -z "$1" ]]; then
	echo "Usage: $(basename "$0") [internal DNS list] [external DNS list]"
	echo
	exit 1
fi

internal_file="$1"
external_file="$2"

internal_list=$(cat $internal_file)
external_list=$(cat $external_file)

internal_missing=""
external_missing=""

for entry in $internal_list
do

if [[ ! $(grep $entry $external_file) ]]; then
	external_missing="$external_missing $entry"
fi
done

for host in $external_list
do
if [[ ! $(grep $host $internal_file) ]]; then
        internal_missing="$internal_missing $host"
fi
done


echo "====Hosts to be added to internal zone===="
echo $internal_missing | tr " " "\n"
echo
echo
echo "====Hosts to be added to external zone===="
echo $external_missing | tr " " "\n"
echo
echo

