#!/bin/bash
## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi
/opt/starfish/scripts/sfpng.py --redash-api-key IHZZHbbK5Z1888Exiq33DLxfoUBufoneZWXPIdsU --output csv --redash-query 'Condensed Duplicate Hash Report (Cross Volume)' --params cutoff_GiB=.1,hashtype=sha1

