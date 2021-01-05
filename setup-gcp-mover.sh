#!/bin/bash

## check if running as root
if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Must be run as root." >&2
        exit 1
fi

cp /datastore/serverdepot/netbackup/gcsfuse.repo /etc/yum.repos.d
cp /datastore/serverdepot/netbackup/google-cloud-sdk.repo /etc/yum.repos.d
yum clean all
yum install -y google-cloud-sdk gcsfuse
gcloud auth activate-service-account --key-file=<key file filepath>
/datastore/serverdepot/bin/remount-gcp-bucket.sh
/datastore/serverdepot/bin/remount-gcp-bucket.sh
echo 199.36.153.8 storage.googleapis.com >> /etc/hosts
