#!/bin/bash

##### Configuration
BASE_PATH=/datastore/lbgadmin/accounts
BIN_DIR=$BASE_PATH/bin

onyen=$1

if [[ -z $1 ]]; then
	echo
	echo "No onyen given"
	echo
	echo "Usage: $0 <onyen>"
	echo
	exit 1

elif ! [[ -z $2 ]]; then
	echo
	echo "Too many agruments"
	echo
	echo "Usage: $0 <onyen>"
	echo
	exit 1
fi

echo "---Running lbguseradd.py---"
sudo $BIN_DIR/lbguseradd.py $onyen

$BIN_DIR/lbguserisactive.sh $onyen >/dev/null 2>&1

case $? in
		0)
			echo "---Adding user to lbginrc group using lbggroupadd.sh---"
			$BIN_DIR/lbggroupadd.sh $onyen lbginrc
			echo
			echo "---Running listservuseradd.sh---"
			$BIN_DIR/listservuseradd.sh $onyen
			;;
		1)
			echo "User account is expired"
			;;
		2)
			echo "User account expired > 6 months ago"
			;;
		3)
			echo "User account not found in LDAP"
			;;
		*)
			echo "User account status unknown"
			exit 1
			;;
esac
