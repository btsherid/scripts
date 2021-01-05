#!/bin/bash

date="$(date +%Y%m%d)"
day="$(date +%A)"
TERM=xterm

export TERM

if [[ "$day" == "Monday" ]]; then
	script -q -c "/datastore/lbgadmin/ansible/runplaybook-keychain.sh cluster --check --diff" /datastore/lbgadmin/ansible-check-runs/cluster/check-run-${date}
	script -q -c "/datastore/lbgadmin/ansible/runplaybook-keychain.sh production --check --diff" /datastore/lbgadmin/ansible-check-runs/production/check-run-${date}
fi

if [[ "$day" == "Tuesday" ]]; then
	script -q -c "/datastore/lbgadmin/ansible/runplaybook-keychain.sh development --check --diff" /datastore/lbgadmin/ansible-check-runs/development/check-run-${date}
fi

if [[ "$day" == "Wednesday" ]]; then
	script -q -c "/datastore/lbgadmin/ansible/runplaybook-keychain.sh infrastructure --check --diff" /datastore/lbgadmin/ansible-check-runs/infrastructure/check-run-${date}
fi

if [[ "$day" == "Thursday" ]]; then
	script -q -c "/datastore/lbgadmin/ansible/runplaybook-keychain.sh icpro --check --diff" /datastore/lbgadmin/ansible-check-runs/icpro/check-run-${date}
fi
