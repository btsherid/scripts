#!/bin/bash

TEMP_FILE="/tmp/GCPPolicies"

#Save code of GCPPolicies page to temp file.
#php /var/www/environments/prod/www-default/http_sysadminwiki/maintenance/view.php GCPPolicies > $TEMP_FILE
/opt/rh/rh-php72/root/usr/bin/php /var/www/environments/prod/www-default/http_sysadminwiki/maintenance/view.php GCPPolicies > $TEMP_FILE

#Make a copy of the temp file so we can later do a comparison to see if anything changed.
cp $TEMP_FILE ${TEMP_FILE}.orig

#Get the gcpwiki output from gcpwiki.sh
gcpwiki="$(/datastore/serverdepot/netbackup/bin/gcpwiki.sh 3 | tail -n+2 > /tmp/gcpwiki)"

while read line
do
	#Get the policy identifier from the first field of the gcpwiki.sh output.
	identifier="$(echo $line | awk '{print $1}')"
	#Get the date from the second and third field of the gcpwiki.sh output.
	date="$(echo $line | awk '{print $2,$3,$4}')"
	#Get the size from the last field of the gcpwiki.sh output.
	size="$(echo $line | awk '{print $NF}')"

	#Get the line number of the identifier in the page code saved to the temp file.
	start_line="$(cat $TEMP_FILE | grep -A 9 -n $identifier | grep -v ${identifier}_ | grep -v ${identifier}[[:alpha:]] | grep $identifier | awk -F ':' '{print $1}' | head -n 1)"
	if ! [[ $start_line == "" ]]; then
		#The page output is a table, so the line numbers of the date and size will always be start_line+6 and start_line+7 respectively.
		date_line=$((start_line + 6))
		size_line=$((start_line + 7))
		#Update the date and size of the table entry for the given identifier.
		sed -i "${date_line}s/.*/\|\ '''${date}'''/" $TEMP_FILE
		sed -i "${size_line}s/.*/\|\ '''${size}'''/" $TEMP_FILE
	fi
done < /tmp/gcpwiki

#Do a diff of the original page code saved and the current page code
difference="$(diff $TEMP_FILE ${TEMP_FILE}.orig)"

#If the page code has changed, then we'll push the new code to the wiki. Otherwise we don't need to do anything.
if ! [[ "$difference" == "" ]]; then
	cat $TEMP_FILE | /opt/rh/rh-php72/root/usr/bin/php /var/www/environments/prod/www-default/http_sysadminwiki/maintenance/edit.php "GCPPolicies" --conf /var/www/environments/prod/www-default/http_sysadminwiki/LocalSettings.php &> /dev/null
fi

#Remove tmp files
rm $TEMP_FILE
rm ${TEMP_FILE}.orig
rm /tmp/gcpwiki
