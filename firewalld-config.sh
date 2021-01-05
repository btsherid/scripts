#!/bin/bash

##### Configuration
firewallCmd=/bin/firewall-cmd
BASE_PATH=/datastore/serverdepot
CONFIG_DIR=$BASE_PATH/config
CONFIG_FILE_GLOBAL=$CONFIG_DIR/firewalld-global
CONFIG_FILE_LOCAL=/etc/myfirewalldconfig
CONFIG_FILE_LOCAL_TEMPLATE=$CONFIG_DIR/myfirewalldconfig.template
RESULTS_PATH=/root
RESULTS_FILE=$RESULTS_PATH/firewalld_config_output
RESULTS_FILE_CMD="| tee -a $RESULTS_FILE"
IFCFG_DIR=/etc/sysconfig/network-scripts
dockerHost="$(ip a | grep docker0)"
clusterIF="$(ip a | grep <first three octets of cluster subnet> | awk '{print $NF}')"
abacusIF="$(ip a | grep <first three octets of abacus subnet> | awk '{print $NF}')"

#source global configuration
if [ -e $CONFIG_FILE_GLOBAL ]; then
	. $CONFIG_FILE_GLOBAL
else
	echo "ERROR: Missing configuration file: $CONFIG_FILE_GLOBAL" >&2
	exit 1
fi

#source global configuration
if [ -e $CONFIG_FILE_LOCAL ]; then
	. $CONFIG_FILE_LOCAL
else
	echo "Warning: no local configuration file: $CONFIG_FILE_LOCAL" >&2
	if [ -e $CONFIG_FILE_LOCAL_TEMPLATE ]; then
		echo "   Using template file: $CONFIG_FILE_LOCAL_TEMPLATE" >&2
		. $CONFIG_FILE_LOCAL_TEMPLATE
	else
		echo "ERROR: No local or template configuration file found" >&2
		exit 1
	fi
fi

### Sanity checks
## check if running as root
if [[ "$EUID" -ne 0 ]]; then
	echo "Error: Must be run as root." >&2
	exit 1
fi

### Check if needs to run or can skip
# conditions for skip:
#  - results file exists
#  - results file newer than global config
#  - no local config file, or results file newer than local config
if [[ -e $RESULTS_FILE && $RESULTS_FILE -nt $CONFIG_FILE_GLOBAL && ( ! -e $CONFIG_FILE_LOCAL || $RESULTS_FILE -nt $CONFIG_FILE_LOCAL ) ]]; then
	echo "Existing results file newer than all configs. Skipping run."
	echo "Results file: $RESULTS_FILE"
	echo " (remove file to force run)"
	echo
	echo "Current configuration:"
	for zone in internal public trusted; do $firewallCmd --zone=$zone --list-all; done
	exit 0
fi

### Initialize results file
cat /dev/null >"$RESULTS_FILE"

##wipe existing sources, services, ports, rules

#wipe existing services from internal and public
for zone in public internal; do
	for object in source service port; do
		currentItems=$($firewallCmd --zone=$zone --list-${object}s)
		if [[ ! -z "$currentItems" ]]; then
			for itemToRemove in $currentItems; do
				echo $firewallCmd --permanent --zone=$zone --remove-${object}=$itemToRemove >>$RESULTS_FILE
				$firewallCmd --permanent --zone=$zone --remove-${object}=$itemToRemove >>$RESULTS_FILE
			done
		fi
	done
	currentRules=$($firewallCmd --zone=$zone --list-rich-rules)
	if [[ ! -z "$currentRules" ]]; then
		while read -r ruleToRemove
		do
			echo $firewallCmd --permanent --zone=$zone --remove-rich-rule=\"${ruleToRemove//\"/}\" >>$RESULTS_FILE
			$firewallCmd --permanent --zone=$zone --remove-rich-rule="${ruleToRemove//\"/}" >>$RESULTS_FILE
		done <<<"$currentRules"
	fi
done

#wipe existing docker configuration
if [[ "$dockerHost" ]]; then
	echo $firewallCmd --zone=public --remove-masquerade --permanent >>$RESULTS_FILE
        $firewallCmd --zone=public --remove-masquerade --permanent >>$RESULTS_FILE
	echo $firewallCmd --permanent --zone=internal --remove-interface=docker0 >>$RESULTS_FILE
	$firewallCmd --permanent --zone=internal --remove-interface=docker0 >>$RESULTS_FILE
	echo $firewallCmd --permanent --direct --remove-rule ipv4 filter INPUT 4 -i docker0 -j ACCEPT >>$RESULTS_FILE
	$firewallCmd --permanent --direct --remove-rule ipv4 filter INPUT 4 -i docker0 -j ACCEPT >>$RESULTS_FILE
fi

#Set default zones

if [[ -z "$publicInterfaceOverride" ]]; then
	publicInterface=eth0
else
	publicInterface=$publicInterfaceOverride
fi
if [[ -z "$trustedInterfaceOverride" ]]; then
	trustedInterface=eth1
else
	trustedInterface=$trustedInterfaceOverride
fi

if ! [[ -z "$clusterIF" ]]; then
	if [[ -z "$clusterInterfaceOverride" ]]; then
        	clusterInterface="$clusterIF"
	else
        	clusterInterface=$clusterInterfaceOverride
	fi
fi

if ! [[ -z "$abacusIF" ]]; then
	if [[ -z "$abacusInterfaceOverride" ]]; then
		abacusInterface="$abacusIF"
	else
		abacusInterface=$abacusInterfaceOverride
	fi
fi
echo $firewallCmd --set-default-zone=public >>$RESULTS_FILE
$firewallCmd --set-default-zone=public >>$RESULTS_FILE

echo $firewallCmd --permanent --zone=public --change-interface=$publicInterface >>$RESULTS_FILE
$firewallCmd --permanent --zone=public --change-interface=$publicInterface >>$RESULTS_FILE

echo $firewallCmd --zone=public --change-interface=$publicInterface >>$RESULTS_FILE
$firewallCmd --zone=public --change-interface=$publicInterface >>$RESULTS_FILE

echo $firewallCmd --permanent --zone=trusted --change-interface=$trustedInterface >>$RESULTS_FILE
$firewallCmd --permanent --zone=trusted --change-interface=$trustedInterface >>$RESULTS_FILE

echo $firewallCmd --zone=trusted --change-interface=$trustedInterface >>$RESULTS_FILE
$firewallCmd --zone=trusted --change-interface=$trustedInterface >>$RESULTS_FILE
if ! [[ -z "$clusterIF" ]]; then
	echo $firewallCmd --permanent --zone=trusted --change-interface=$clusterInterface >>$RESULTS_FILE
	$firewallCmd --permanent --zone=trusted --change-interface=$clusterInterface >>$RESULTS_FILE

	echo $firewallCmd --zone=trusted --change-interface=$clusterInterface >>$RESULTS_FILE
	$firewallCmd --zone=trusted --change-interface=$clusterInterface >>$RESULTS_FILE
fi

if ! [[ -z "$abacusIF" ]]; then
	echo $firewallCmd --permanent --zone=trusted --change-interface=$abacusInterface >>$RESULTS_FILE
	$firewallCmd --permanent --zone=trusted --change-interface=$abacusInterface >>$RESULTS_FILE

	echo $firewallCmd --zone=trusted --change-interface=$abacusInterface >>$RESULTS_FILE
	$firewallCmd --zone=trusted --change-interface=$abacusInterface >>$RESULTS_FILE
fi

#hard-code the zones in the network script files, because firewalld won't honor the 
# configurations on boot
#trusted
trustedInterfaceCfgFile=$IFCFG_DIR/ifcfg-${trustedInterface}
if [[ -e "$trustedInterfaceCfgFile" ]]; then
	if grep -q '^ZONE=' $trustedInterfaceCfgFile; then
		echo sed -i 's/^ZONE=.*/ZONE=trusted/' $trustedInterfaceCfgFile >>$RESULTS_FILE
		sed -i 's/^ZONE=.*/ZONE=trusted/' $trustedInterfaceCfgFile
	else
		echo echo "ZONE=trusted" >>$trustedInterfaceCfgFile >>$RESULTS_FILE
		echo "ZONE=trusted" >>$trustedInterfaceCfgFile
	fi
else
	echo "**No configuration file found at $trustedInterfaceCfgFile"
fi
#public
publicInterfaceCfgFile=$IFCFG_DIR/ifcfg-${publicInterface}
if [[ -e "$publicInterfaceCfgFile" ]]; then
	if grep -q '^ZONE=' $publicInterfaceCfgFile; then
		echo sed -i 's/^ZONE=.*/ZONE=public/' $publicInterfaceCfgFile >>$RESULTS_FILE
		sed -i 's/^ZONE=.*/ZONE=public/' $publicInterfaceCfgFile
	else
		echo echo "ZONE=public" >>$publicInterfaceCfgFile >>$RESULTS_FILE
		echo "ZONE=public" >>$publicInterfaceCfgFile
	fi
else
	echo "**No configuration file found at $publicInterfaceCfgFile"
fi

clusterInterfaceCfgFile=$IFCFG_DIR/ifcfg-${clusterInterface}
if ! [[ -z "$clusterIF" ]]; then
	if [[ -e "$clusterInterfaceCfgFile" ]]; then
        	if grep -q '^ZONE=' $clusterInterfaceCfgFile; then
	                echo sed -i 's/^ZONE=.*/ZONE=trusted/' $clusterInterfaceCfgFile >>$RESULTS_FILE
                	sed -i 's/^ZONE=.*/ZONE=trusted/' $clusterInterfaceCfgFile
        	else
	                echo echo "ZONE=trusted" >>$clusterInterfaceCfgFile >>$RESULTS_FILE
                	echo "ZONE=trusted" >>$clusterInterfaceCfgFile
        	fi
	else
       		echo "**No configuration file found at $clusterInterfaceCfgFile"
	fi
fi

if ! [[ -z "$abacusIF" ]]; then
	abacusCfgFile=$IFCFG_DIR/ifcfg-${abacusInterface}
	if [[ -e "$abacusInterfaceCfgFile" ]]; then
		if grep -q '^ZONE=' $abacusInterfaceCfgFile; then
			echo sed -i 's/^ZONE=.*/ZONE=trusted/' $abacusInterfaceCfgFile >>$RESULTS_FILE
			sed -i 's/^ZONE=.*/ZONE=trusted/' $abacusInterfaceCfgFile
		else
			echo echo "ZONE=trusted" >>$abacusInterfaceCfgFile >>$RESULTS_FILE
			echo "ZONE=trusted" >>$abacusInterfaceCfgFile
		fi
	else
		echo "**No configuration file found at $abacusInterfaceCfgFile"
	fi
fi
#if grep -q '^ZONE=' $IFCFG_DIR/ifcfg-${publicInterface}; then
#	echo "modifying $IFCFG_DIR/ifcfg-${publicInterface}" >>$RESULTS_FILE
#	echo sed -i 's/^ZONE=.*/ZONE=public/' $IFCFG_DIR/ifcfg-${publicInterface} >>$RESULTS_FILE
#	sed -i 's/^ZONE=.*/ZONE=public/' $IFCFG_DIR/ifcfg-${publicInterface}
#else
#	echo "appending $IFCFG_DIR/ifcfg-${publicInterface}" >>$RESULTS_FILE
#	echo echo "appending $IFCFG_DIR/ifcfg-${publicInterface}" >>$RESULTS_FILE
#	echo "ZONE=public" >>$IFCFG_DIR/ifcfg-${publicInterface}
#fi

#Add sources
for subnet in $UNC_networks $internalSources; do
	echo $firewallCmd --permanent --zone=internal --add-source=$subnet >>$RESULTS_FILE
	$firewallCmd --permanent --zone=internal --add-source=$subnet >>$RESULTS_FILE
done
#for subnet in $UNC_networks $publicSources; do
#	echo $firewallCmd --permanent --zone=public --add-source=$subnet ##DEBUG
#	$firewallCmd --permanent --zone=public --add-source=$subnet
#done

#Add services
for service in $defaultServices $internalServices; do
	echo $firewallCmd --permanent --zone=internal --add-service=$service >>$RESULTS_FILE
	$firewallCmd --permanent --zone=internal --add-service=$service >>$RESULTS_FILE
done
for service in $publicServices; do
	echo $firewallCmd --permanent --zone=public --add-service=$service >>$RESULTS_FILE
	$firewallCmd --permanent --zone=public --add-service=$service >>$RESULTS_FILE
done

#Add ports
for port in $defaultPorts $internalPorts; do
	echo $firewallCmd --permanent --zone=internal --add-port=$port >>$RESULTS_FILE
	$firewallCmd --permanent --zone=internal --add-port=$port >>$RESULTS_FILE
done
for port in $publicPorts; do
	echo $firewallCmd --permanent --zone=public --add-port=$port >>$RESULTS_FILE
	$firewallCmd --permanent --zone=public --add-port=$port >>$RESULTS_FILE
done

#Add service rules
for serviceRule in $defaultServiceRules $internalServiceRules; do
	address=$(echo $serviceRule | awk -F':' '{print $1}')
	service=$(echo $serviceRule | awk -F':' '{print $2}')
	echo $firewallCmd --permanent --zone=internal --add-rich-rule=\"rule family=ipv4 source address=$address service name=$service accept\" >>$RESULTS_FILE
	$firewallCmd --permanent --zone=internal --add-rich-rule="rule family=ipv4 source address=$address service name=$service accept" >>$RESULTS_FILE
done
for serviceRule in $publicServiceRules; do
	address=$(echo $serviceRule | awk -F':' '{print $1}')
	service=$(echo $serviceRule | awk -F':' '{print $2}')
	echo $firewallCmd --permanent --zone=public --add-rich-rule=\"rule family=ipv4 source address=$address service name=$service accept\" >>$RESULTS_FILE
	$firewallCmd --permanent --zone=public --add-rich-rule="rule family=ipv4 source address=$address service name=$service accept" >>$RESULTS_FILE
done


#Add port rules
for portRule in $defaultPortRules $internalPortRules; do
	address=$(echo $portRule | awk -F':' '{print $1}')
	port=$(echo $portRule | awk -F':' '{print $2}' | awk -F'/' '{print $1}')
	protocol=$(echo $portRule | awk -F'/' '{print $NF}')
	echo $firewallCmd --permanent --zone=internal --add-rich-rule=\"rule family=ipv4 source address=$address port port=$port protocol=$protocol accept\" >>$RESULTS_FILE
	$firewallCmd --permanent --zone=internal --add-rich-rule="rule family=ipv4 source address=$address port port=$port protocol=$protocol accept" >>$RESULTS_FILE
done
for portRule in $publicPortRules; do
	address=$(echo $portRule | awk -F':' '{print $1}')
	port=$(echo $portRule | awk -F':' '{print $2}' | awk -F'/' '{print $1}')
	protocol=$(echo $portRule | awk -F'/' '{print $NF}')
	echo $firewallCmd --permanent --zone=public --add-rich-rule=\"rule family=ipv4 source address=$address port port=$port protocol=$protocol accept\" >>$RESULTS_FILE
	$firewallCmd --permanent --zone=public --add-rich-rule="rule family=ipv4 source address=$address port port=$port protocol=$protocol accept" >>$RESULTS_FILE
done

#Add docker configuration
if [[ "$dockerHost" ]] && [[ "$enable_docker_outside_access" == "yes" ]]; then
	echo $firewallCmd --zone=public --add-masquerade --permanent >>$RESULTS_FILE
        $firewallCmd --zone=public --add-masquerade --permanent >>$RESULTS_FILE
	echo $firewallCmd --permanent --zone=internal --change-interface=docker0 >>$RESULTS_FILE
        $firewallCmd --permanent --zone=internal --change-interface=docker0 >>$RESULTS_FILE
	echo $firewallCmd --permanent --direct --add-rule ipv4 filter INPUT 4 -i docker0 -j ACCEPT >>$RESULTS_FILE
        $firewallCmd --permanent --direct --add-rule ipv4 filter INPUT 4 -i docker0 -j ACCEPT >>$RESULTS_FILE
fi

#Add blocklist configuration
if [[ "$enableinternalBlocklist" == "yes" ]] || [[ "$enablepublicBlocklist" == "yes" ]]; then
	#Check if IP blocklist exists. If so, get the entries.
	if [[ "$($firewallCmd --get-ipsets | grep ipblocklist)" == "" ]]; then
		currentIPBlocklist=""
	else
		currentIPBlocklist="$($firewallCmd --ipset=ipblocklist --get-entries)"
	fi

	#Check if subnet blocklist exists. If so, get the entries.
	if [[ "$($firewallCmd --get-ipsets | grep netblocklist)" == "" ]]; then
		currentNetBlocklist=""
	else
		currentNetBlocklist="$($firewallCmd --ipset=netblocklist --get-entries)"
	fi

	#If IP blocklist not enabled, enable it
        if [[ "$($firewallCmd --get-ipsets | grep ipblocklist)" == "" ]]; then
                echo $firewallCmd --permanent --new-ipset=ipblocklist --type=hash:ip >>$RESULTS_FILE
                $firewallCmd --permanent --new-ipset=ipblocklist --type=hash:ip >>$RESULTS_FILE
        fi

	#If net blocklist not enabled, enable it
	if [[ "$($firewallCmd --get-ipsets | grep netblocklist)" == "" ]]; then
		echo $firewallCmd --permanent --new-ipset=netblocklist --type=hash:net >>$RESULTS_FILE
                $firewallCmd --permanent --new-ipset=netblocklist --type=hash:net >>$RESULTS_FILE
	fi

	#Add rich rule to internal zone for blocklists
	if [[ "$enableinternalBlocklist" == "yes" ]]; then
		echo $firewallCmd --permanent --zone=internal --add-rich-rule='rule source ipset=ipblocklist drop' >>$RESULTS_FILE
	        $firewallCmd --permanent --zone=internal --add-rich-rule='rule source ipset=ipblocklist drop' >>$RESULTS_FILE
		echo $firewallCmd --permanent --zone=internal --add-rich-rule='rule source ipset=netblocklist drop' >>$RESULTS_FILE
                $firewallCmd --permanent --zone=internal --add-rich-rule='rule source ipset=netblocklist drop' >>$RESULTS_FILE
	fi
	
	#Add rich rule to public zone for IP blocklist
	if [[ "$enablepublicBlocklist" == "yes" ]]; then
		echo $firewallCmd --permanent --zone=public --add-rich-rule='rule source ipset=ipblocklist drop' >>$RESULTS_FILE
	        $firewallCmd --permanent --zone=public --add-rich-rule='rule source ipset=ipblocklist drop' >>$RESULTS_FILE
		echo $firewallCmd --permanent --zone=public --add-rich-rule='rule source ipset=netblocklist drop' >>$RESULTS_FILE
                $firewallCmd --permanent --zone=public --add-rich-rule='rule source ipset=netblocklist drop' >>$RESULTS_FILE
	fi
	
	#Remove entries from IP blocklist if they do not appear in /etc/myfirewalldconfig
        for ip in $currentIPBlocklist; do
                if ! [[ $blocked_ips == *"$ip"* ]]; then
                        echo $firewallCmd --permanent --ipset=ipblocklist --remove-entry=$ip >>$RESULTS_FILE
                        $firewallCmd --permanent  --ipset=ipblocklist --remove-entry=$ip >>$RESULTS_FILE
                fi
        done

	#Add IP entries to blocklist from /etc/myfirewalldconfig if they are not already in the blocklist
        for ip in $blocked_ips; do
                if ! [[ $currentIPBlocklist == *"$ip"* ]]; then
                        echo $firewallCmd --permanent --ipset=ipblocklist --add-entry=$ip >>$RESULTS_FILE
                        $firewallCmd --permanent --ipset=ipblocklist --add-entry=$ip >>$RESULTS_FILE
                fi
        done

	#Remove entries from subnet blocklist if they do not appear in /etc/myfirewalldconfig
        for subnet in $currentNetBlocklist; do
                if ! [[ $blocked_subnets == *"$subnet"* ]]; then
                        echo $firewallCmd --permanent --ipset=netblocklist --remove-entry=$subnet >>$RESULTS_FILE
                        $firewallCmd --permanent  --ipset=netblocklist --remove-entry=$subnet >>$RESULTS_FILE
                fi
        done

	#Add subnet entries to blocklist from /etc/myfirewalldconfig if they are not already in the blocklist
        for subnet in $blocked_subnets; do
                if ! [[ $currentNetBlocklist == *"$subnet"* ]]; then
                        echo $firewallCmd --permanent --ipset=netblocklist --add-entry=$subnet >>$RESULTS_FILE
                        $firewallCmd --permanent --ipset=netblocklist --add-entry=$subnet >>$RESULTS_FILE
                fi
        done

fi

echo /bin/firewall-cmd --reload >>$RESULTS_FILE
/bin/firewall-cmd --reload >>$RESULTS_FILE

### Show resulting state
#for zone in internal public trusted; do $firewallCmd --zone=$zone --list-all; done
#for zone in $(firewall-cmd --get-active-zones | grep -v '^ '); do firewall-cmd --zone=$zone --list-all; done
for zone in $(firewall-cmd --get-active-zones | grep -v '^ '); do $firewallCmd --zone=$zone --list-all; done
