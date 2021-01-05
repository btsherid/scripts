#/bin/bash
## check if running as root
if [[ "$EUID" -ne 0 ]]; then
	echo "Error: Must be run as root." >&2
	exit 1
fi

rm -rf /root/.config/rclone/
rm -rf /root/.cache/rclone
rm -rf /usr/bin/rclone
rm -rf /usr/local/share/man/man1/rclone.1
find /tmp *rclone* 2>/dev/null | grep rclone | xargs rm -rf 
