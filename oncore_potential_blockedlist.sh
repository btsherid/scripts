#!/bin/bash

## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi

yesterday="$(date -d yesterday +'%Y%m%d')"

email=$1
if [[ "$email" ==  "--email" ]]; then

        #Display a warning message and force the user to hit y to proceed.
        echo
        echo "This will email the output of this script to <<admin listserv email address>. If this is not desired, run the script without the --email flag."
        read -p "Hit y to proceed. Hit any other key to exit. " -n 1 -r
        echo
        if [[ ! $REPLY = "y" ]]; then
                exit 1
        fi
	email_requested="yes"
fi


echo "Getting all IPs that hit the first login page but not the second"
first_page_only_ips="$(diff --new-line-format="" --unchanged-line-format="" <(grep -e "POST /forte-platform-web/login\|POST /forte-platform-web/login;" /opt/forte/apache2.4/logs/access_log* | tr ':' ' ' | awk '{print $2}' | sort -u) <(grep "POST /forte-platform-web/login-step-two" /opt/forte/apache2.4/logs/access_log* | tr ':' ' ' | awk '{print $2}' | sort -u))"
first_page_only_ips_count="$(echo $first_page_only_ips | tr ' ' '\n' | wc -l )"

echo "Getting all IPs that hit the login pages"
login_ips="$(grep -e "GET /forte-platform-web/login\|GET /forte-platform-web/login;\|GET /forte-platform-web/login-step-two" /opt/forte/apache2.4/logs/access_log* | tr ':' ' ' | awk '{print $2}' | sort -u | tr '\n' ' ')"
login_ips_count="$(echo $login_ips | tr ' ' '\n' | wc -l )"
login_blockedlist=""

echo "Getting all IPs that hit the SIP pages"
sip_ips="$(grep sip /opt/forte/apache2.4/logs/access_log* | tr ':' ' ' | awk '{print $2}' | sort -u | tr '\n' ' ')"
sip_ips_count="$(echo $sip_ips | tr ' ' '\n' | wc -l )"
sip_blockedlist=""

echo "Getting all IPs that hit the API pages"
api_ips="$(grep api /opt/forte/apache2.4/logs/access_log* | tr ':' ' ' | awk '{print $2}' | sort -u | tr '\n' ' ')"
api_ips_count="$(echo $api_ips | tr ' ' '\n' | wc -l )"
api_blockedlist=""

allowed_networks="X.X.X.X/16 X.X.X.X/16 X.X.X.X/16 X.X.X.X/18 X.X.X.X/16"
allowed_ips=""
allowed_domains="unc.edu duke.edu ncsu.edu"
firewalld_config_blockedlist="$(grep blocked_ips /etc/myfirewalldconfig | awk -F '"' '{print $2}')"
permanent_blockedlist="/root/permanent_blockedlist"
firewalld_config_file="/etc/myfirewalldconfig"

counter=0;

echo "Checking IPs that hit the first login page but not the second to see if the number of hits is greater than 10"
for item in $login_ips
do
	echo "Checking $item $counter/$login_ips_count    ";printf "\033[A"
        if [ "$(grep -e "GET /forte-platform-web/login\|GET /forte-platform-web/login;\|GET /forte-platform-web/login-step-two" /opt/forte/apache2.4/logs/access_log* | grep $item | tr ':' ' ' | awk '{print $2}' | wc -l)" -gt 10 ]; then
                login_blockedlist="$login_blockedlist $entry"
        fi
	let "counter++"
done

counter=0;

echo "Checking IPs that have hit the SIP pages to see if the number of hits is greater than 10"
for item in $sip_ips
do
	echo "Checking $item $counter/$sip_ips_count    ";printf "\033[A"
        if [ "$(grep sip /opt/forte/apache2.4/logs/access_log* | grep $item | tr ':' ' ' | awk '{print $2}' | wc -l)" -gt 10 ]; then
                sip_blockedlist="$sip_blockedlist $entry"
        fi
	let "counter++"
done

counter=0;

echo "Checking IPs that have hit the API pages to see if the number of hits is greater than 10"
for item in $api_ips
do
	echo "Checking $item $counter/$api_ips_count    ";printf "\033[A"
        if [ "$(grep api /opt/forte/apache2.4/logs/access_log* | grep $item | tr ':' ' ' | awk '{print $2}' | wc -l)" -gt 10 ]; then
                api_blockedlist="$api_blockedlist $entry"
        fi
	let "counter++"
done

counter=0;

echo "Checking IPs that hit the first login page but not the second to see if they should be blocked"
for first_page_ip in $first_page_only_ips
do
echo "Checking $first_page_ip $counter/$first_page_only_ips_count    ";printf "\033[A"
name=""
domain=""
country=""
        if [[ "$(dig +short -x $first_page_ip)" ]]; then
                name="$(dig +short -x $first_page_ip | head -n1)"
                domain="$(dig +short -x $first_page_ip | head -n1 | awk -F '.' '{print $(NF-2)"."$(NF-1)}')"
                country="$(geoiplookup $first_page_ip | awk -F ', ' '{print $2}' | tr ' ' '_')"
        else
                name="NXDOMAIN"
                country="$(geoiplookup $first_page_ip | awk -F ', ' '{print $2}' | tr ' ' '_')"
                domain="none"
        fi
	
        if [[ "$(grep $first_page_ip /etc/firehol/ipsets/*.ipset)" == "" ]]; then
                if [[ "$(grep $first_page_ip $permanent_blockedlist)" == "" ]]; then
                        if [[ "$(echo $allowed_domains | grep $domain)" == "" ]]; then
                                if [[ "$(echo $allowed_ips | grep $first_page_ip)" == "" ]]; then
                                        if [[ "$(grepcidr "$allowed_networks" <(echo "$first_page_ip"))" == "" ]]; then
                                                if [[ "$(echo $firewalld_config_blockedlist | grep $first_page_ip)" == "" ]]; then
                                                        hits="$(grep -e "GET /forte-platform-web/login\|GET /forte-platform-web/login;\|GET /forte-platform-web/login-step-two" /opt/forte/apache2.4/logs/access_log* | grep $first_page_ip | wc -l)"
                                                        potential_first_page_blockedlist="$potential_first_page_blockedlist$first_page_ip $name $country $hits\n"
                                                fi
                                        fi
                                fi
                        fi
                fi
        else
                if [[ "$(grep $first_page_ip $permanent_blockedlist)" == "" ]]; then
                        echo $first_page_ip >> $permanent_blockedlist
                fi
        fi
let "counter++"
done


echo "Checking IPs that hit the login pages more than 10 times to see if they should be blocked"
for login_ip in $login_blockedlist #ip in $potential_blockedlist_ips
do
echo "Checking $login_ip $counter/$login_ips_count    ";printf "\033[A"
name=""
domain=""
country=""
	if [[ "$(dig +short -x $login_ip)" ]]; then
		name="$(dig +short -x $login_ip | head -n1)"
		domain="$(dig +short -x $login_ip | head -n1 | awk -F '.' '{print $(NF-2)"."$(NF-1)}')"
		country="$(geoiplookup $login_ip | awk -F ', ' '{print $2}' | tr ' ' '_')"
	else
		name="NXDOMAIN"
		country="$(geoiplookup $login_ip | awk -F ', ' '{print $2}' | tr ' ' '_')"	
		domain="none"
	fi
	
	if [[ "$(grep $login_ip /etc/firehol/ipsets/*.ipset)" == "" ]]; then
		if [[ "$(grep $login_ip $permanent_blockedlist)" == "" ]]; then
			if [[ "$(echo $allowed_domains | grep $domain)" == "" ]]; then
				if [[ "$(echo $allowed_ips | grep $login_ip)" == "" ]]; then
					if [[ "$(grepcidr "$allowed_networks" <(echo "$login_ip"))" == "" ]]; then
						if [[ "$(echo $firewalld_config_blockedlist | grep $login_ip)" == "" ]]; then
							hits="$(grep -e "GET /forte-platform-web/login\|GET /forte-platform-web/login;\|GET /forte-platform-web/login-step-two" /opt/forte/apache2.4/logs/access_log* | grep $login_ip | wc -l)"
			 				potential_login_blockedlist="$potential_login_blockedlist$login_ip $name $country $hits\n"
						fi
					fi
				fi
			fi
		fi
	else
		if [[ "$(grep $login_ip $permanent_blockedlist)" == "" ]]; then
                        echo $login_ip >> $permanent_blockedlist
                fi
	fi
done

echo "Checking IPs that hit the SIP page(s) more than 10 times to see if they should be blocked"
for sip_ip in $sip_blockedlist
do
echo "Checking $sip_ip $counter/$sip_ips_count    ";printf "\033[A"
name=""
domain=""
country=""
        if [[ "$(dig +short -x $sip_ip)" ]]; then
                name="$(dig +short -x $sip_ip | head -n1)"
                domain="$(dig +short -x $sip_ip | head -n1 | awk -F '.' '{print $(NF-2)"."$(NF-1)}')"
                country="$(geoiplookup $sip_ip | awk -F ', ' '{print $2}' | tr ' ' '_')"
        else
                name="NXDOMAIN"
                country="$(geoiplookup $sip_ip | awk -F ', ' '{print $2}' | tr ' ' '_')"
                domain="none"
        fi

	if [[ "$(grep $sip_ip /etc/firehol/ipsets/*.ipset)" == "" ]]; then
		if [[ "$(grep $sip_ip $permanent_blockedlist)" == "" ]]; then
	        	if [[ "$(echo $allowed_domains | grep $domain)" == "" ]]; then
        	        	if [[ "$(echo $allowed_ips | grep $sip_ip)" == "" ]]; then
                	        	if [[ "$(grepcidr "$allowed_networks" <(echo "$sip_ip"))" == "" ]]; then
                        	        	if [[ "$(echo $firewalld_config_blockedlist | grep $sip_ip)" == "" ]]; then
                                	        	hits="$(grep sip /opt/forte/apache2.4/logs/access_log* | grep $sip_ip | wc -l)"
                                        		potential_sip_blockedlist="$potential_sip_blockedlist$sip_ip $name $country $hits\n"
                                		fi
	                        	fi
        	        	fi
	        	fi
		fi
	else
		if [[ "$(grep $sip_ip $permanent_blockedlist)" == "" ]]; then
                        echo $sip_ip >> $permanent_blockedlist
                fi	
	fi
done

echo "Checking IPs that hit the API page(s) more than 10 times to see if they should be blocked"
for api_ip in $api_blockedlist
do
echo "Checking $api_ip $counter/$api_ips_count    ";printf "\033[A"
name=""
domain=""
country=""
        if [[ "$(dig +short -x $api_ip)" ]]; then
                name="$(dig +short -x $api_ip | head -n1)"
                domain="$(dig +short -x $api_ip | head -n1 | awk -F '.' '{print $(NF-2)"."$(NF-1)}')"
                country="$(geoiplookup $api_ip | awk -F ', ' '{print $2}' | tr ' ' '_')"
        else
                name="NXDOMAIN"
                country="$(geoiplookup $api_ip | awk -F ', ' '{print $2}' | tr ' ' '_')"
                domain="none"
        fi

	
        if [[ "$(grep $api_ip /etc/firehol/ipsets/*.ipset)" == "" ]]; then
		if [[ "$(grep $api_ip $permanent_blockedlist)" == "" ]]; then
	        	if [[ "$(echo $allowed_domains | grep $domain)" == "" ]]; then
        	        	if [[ "$(echo $allowed_ips | grep $api_ip)" == "" ]]; then
                	        	if [[ "$(grepcidr "$allowed_networks" <(echo "$api_ip"))" == "" ]]; then
                        	        	if [[ "$(echo $firewalld_config_blockedlist | grep $api_ip)" == "" ]]; then
                                	       		hits="$(grep api /opt/forte/apache2.4/logs/access_log* | grep $api_ip | wc -l)"
		                                        potential_api_blockedlist="$potential_api_blockedlist$api_ip $name $country $hits\n"
                	                	fi
					fi
                		fi
        		fi
		fi
	else
		if [[ "$(grep $api_ip $permanent_blockedlist)" == "" ]]; then
			echo $api_ip >> $permanent_blockedlist
		fi
	fi
done

#Update firewalld blockedlist
permanent_blockedlist_contents="$(cat /root/permanent_blockedlist)"
echo "Updating firewall blockedlist"
sed -i "/blocked_ips/c\blocked_ips=\"$(echo $permanent_blockedlist_contents | sed 's/\./\\./g')\"" /etc/myfirewalldconfig
/datastore/serverdepot/bin/firewalld-config.sh > /dev/null 2>&1

echo "This output generated by /datastore/serverdepot/bin/oncore_potential_blockedlist.sh" > /root/blockedlist_email
echo >> /root/blockedlist_email
echo "Exclusion checks:" >> /root/blockedlist_email
echo "1.) If potential IP is in public blockedlist database (pulled to /etc/firehol/ipsets/*.ipset via cron), it is saved to /root/permanent_blockedlist and excluded from this output." >> /root/blockedlist_email
echo "2.) If potential IP is in /root/permanent_blockedlist, it is excluded from this output." >> /root/blockedlist_email
echo "3.) If potential IP ends with an allowed domain (allowed_domains=$allowed_domains), it is excluded from this output." >> /root/blockedlist_email
echo "4.) If potential IP is an allowed IP (allowed_IPs=$allowed_IPs), it is excluded from this output." >> /root/blockedlist_email
echo "5.) If potential IP is in an allowed subnet (allowed_networks=$allowed_networks), it is excluded from this output." >> /root/blockedlist_email
echo "6.) If potential IP is already in the /etc/myfirewalld_config blockedlist, it is excluded from this output." >> /root/blockedlist_email
echo >> /root/blockedlist_email
echo "===These IPs hit the first page but not the second page and failed all above exclusion checks===\n" >> /root/blockedlist_email
printf "IP Name Country Hits\n$potential_first_page_blockedlist" | column -t >> /root/blockedlist_email
echo >> /root/blockedlist_email
echo >> /root/blockedlist_email
echo "===These IPs hit the login pages more than 10 times in the last two weeks and failed all above exclusion checks===\n" >> /root/blockedlist_email
printf "IP Name Country Hits\n$potential_login_blockedlist" | column -t >> /root/blockedlist_email
echo >> /root/blockedlist_email
echo >> /root/blockedlist_email
echo "===These IPs hit the SIP URL(s) more than 10 times in the last two weeks and failed all above exclusion checks===\n" >> /root/blockedlist_email
printf "IP Name Country Hits\n$potential_sip_blockedlist" | column -t >> /root/blockedlist_email
echo >> /root/blockedlist_email
echo >> /root/blockedlist_email
echo "===These IPs hit the API URL(s) more than 10 times in the last two weeks and failed all above exclusion checks===\n" >> /root/blockedlist_email
printf "IP Name Country Hits\n$potential_api_blockedlist" | column -t >> /root/blockedlist_email

if [[ "$email_requested" ==  "yes" ]]; then
	email=$(cat /root/blockedlist_email)
	echo -e "$email" | mail -s "Potential blockedlist candidates" <<admin listserv email address> 
fi
