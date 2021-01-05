#/bin/bash
## check if running as root
if [[ "$EUID" -ne 0 ]]; then
	echo "Error: Must be run as root." >&2
	exit 1
fi

echo "Uninstalling NetBackup RPMs"
rpm -qa | grep VRTS | tr '\n' ' ' | xargs yum -y remove

echo "Stopping netbackup service"
systemctl stop netbackup

echo "Removing startup scripts if they exist"
/usr/bin/test -f /etc/rc.d/init.d/netbackup && rm -rf /etc/rc.d/init.d/netbackup
/usr/bin/test -f /etc/rc.d/rc0.d/K01netbackup && rm -rf /etc/rc.d/rc0.d/K01netbackup
/usr/bin/test -f /etc/rc.d/rc1.d/K01netbackup && rm -rf /etc/rc.d/rc1.d/K01netbackup
/usr/bin/test -f /etc/rc.d/rc2.d/S77netbackup && rm -rf /etc/rc.d/rc2.d/S77netbackup
/usr/bin/test -f /etc/rc.d/rc3.d/S77netbackup && rm -rf /etc/rc.d/rc3.d/S77netbackup
/usr/bin/test -f /etc/rc.d/rc5.d/S77netbackup && rm -rf /etc/rc.d/rc5.d/S77netbackup
/usr/bin/test -f /etc/rc.d/rc6.d/K01netbackup && rm -rf /etc/rc.d/rc6.d/K01netbackup

echo "Uninstalling Symantec LiveUpdate"
/opt/Symantec/LiveUpdate/uninstall.sh -a -s

echo "Removing /opt/Symantec directory"
rm -rf /opt/Symantec/

echo "Removing /usr/openv directory"
rm -rf /usr/openv

echo "Removing /etc/vx/vrtslog.conf"
rm -f /etc/vx/vrtslog.conf

echo "Removing /etc/Symantec.conf"
rm -f /etc/Symantec.conf

echo "Removing /etc/Product.Catalog.JavaLiveUpdate"
rm -f /etc/Product.Catalog.JavaLiveUpdate

echo "Removing /.veritas"
rm -rf /.veritas

nbu_status="$(systemctl status netbackup 2>&1 | grep "could not be found")"

if [[ "$nbu_status" == "" ]]; then
	echo
	echo
	echo "Netbackup service still exists. Check status of uninstall."
else
	echo
	echo
	echo "Uninstall successful."
fi
