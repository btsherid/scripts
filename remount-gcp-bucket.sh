#/bin/bash
## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi

umount -l /NS/lccc-gcp-archive
gcsfuse --implicit-dirs lccc-gcp-archive /NS/lccc-gcp-archive
