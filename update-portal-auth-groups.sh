#/bin/bash
OD_CONFIG_FILE="/etc/ood/config/ood_portal.yml"
##### Configuration
BASE_PATH=/datastore/lbgadmin/accounts
CONFIG_DIR=$BASE_PATH/conf
CONFIG_FILE=$CONFIG_DIR/config

#Get all cluster enabled groups from file
groups="$(cat $BASE_PATH/resources/cluster-enabled-groups)"

#Add lbgadmins to groups that we want to grant access to.
groups="$groups lbgadmins"
sed_entry=""

#Build a string we will use with sed to update the existing configuration file.
for entry in $groups
do
	if [[ -z $sed_entry ]]; then
		sed_entry="\  - '  Require ldap-group cn=$entry,ou=group,dc=lbg,dc=unc,dc=edu'"
	else
		sed_entry="$sed_entry\n  - '  Require ldap-group cn=$entry,ou=group,dc=lbg,dc=unc,dc=edu'"
	fi
done

#Get line that <RequireAny> directive is on
requireany_line="$(grep -n RequireAny $OD_CONFIG_FILE | grep -v '\/' | awk -F ':' '{print $1}')"
start_line="$(echo $requireany_line + 1 | bc -l)"

#Get line that </RequireAny> directive is on
end_requireany_line="$(grep -n \/RequireAny $OD_CONFIG_FILE | awk -F ':' '{print $1}')"
end_line="$(echo $end_requireany_line - 1 | bc -l)"

#Use sed to delete everything in between <RequireAny> and </RequireAny>
sed -i "${start_line},${end_line}d" $OD_CONFIG_FILE

#Use sed to add in the newly constructed entry in between <RequireAny> and </RequireAny>
sed -i "${start_line}i$sed_entry" $OD_CONFIG_FILE

#Attempt to reload Apache and get return code
systemctl reload httpd24-httpd
return_code=$?

#If Apache reload fails, send us an email
if [[ "$return_code" == "1" ]]; then
	echo -e "Apache reload failed for httpd24-httpd service on ondemand.bioinf.unc.edu. Please check /etc/ood/config/ood_portal.yml for issues." | mail -s "OnDemand Apache cron reload failed" brendan.sheridan@unc.edu
fi
