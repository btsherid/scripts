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

#source global configuration
if [ -e $CONFIG_FILE_GLOBAL ]; then
	. $CONFIG_FILE_GLOBAL
else
	echo "ERROR: Missing configuration file: $CONFIG_FILE_GLOBAL" >&2
	exit 1
fi

### Show resulting state
firewall-cmd --ipset=ipblacklist --get-entries
firewall-cmd --ipset=netblacklist --get-entries
