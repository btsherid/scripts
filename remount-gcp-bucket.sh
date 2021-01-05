#/bin/bash
## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi

export GOOGLE_APPLICATION_CREDENTIALS="/datastore/serverdepot/netbackup/lccc-gcp-archive.json"

/usr/bin/test ! -d /NS/lccc-gcp-archive && mkdir -p /NS/lccc-gcp-archive
umount -l /NS/lccc-gcp-archive
gcsfuse --implicit-dirs --temp-dir /datastore/scratch/users/root lccc-gcp-archive /NS/lccc-gcp-archive
