#!/bin/bash

total_hosts="$(for i in cluster development icpro infrastructure production; do /usr/bin/ansible-inventory --graph -i /datastore/lbgadmin/ansible/inventories/$i/$i | grep "\-\-" | grep -v "\-\-\@" | awk -F "--" '{print $2}'; done | sort -u | wc -l)"
cluster_hosts="$(/usr/bin/ansible-inventory --graph -i /datastore/lbgadmin/ansible/inventories/cluster/cluster | grep "\-\-" | grep -v "\-\-\@" | awk -F "--" '{print $2}' | sort -u | wc -l)"
development_hosts="$(/usr/bin/ansible-inventory --graph -i /datastore/lbgadmin/ansible/inventories/development/development | grep "\-\-" | grep -v "\-\-\@" | awk -F "--" '{print $2}' | sort -u | wc -l)"
icpro_hosts="$(/usr/bin/ansible-inventory --graph -i /datastore/lbgadmin/ansible/inventories/icpro/icpro | grep "\-\-" | grep -v "\-\-\@" | awk -F "--" '{print $2}' | sort -u | wc -l)"
infrastructure_hosts="$(/usr/bin/ansible-inventory --graph -i /datastore/lbgadmin/ansible/inventories/infrastructure/infrastructure | grep "\-\-" | grep -v "\-\-\@" | awk -F "--" '{print $2}' | sort -u | wc -l)"
production_hosts="$(/usr/bin/ansible-inventory --graph -i /datastore/lbgadmin/ansible/inventories/production/production | grep "\-\-" | grep -v "\-\-\@" | awk -F "--" '{print $2}' | sort -u | wc -l)"

echo -e "Total: $total_hosts\nCluster: $cluster_hosts\nDevelopment: $development_hosts\nICPRO: $icpro_hosts\nInfrastructure: $infrastructure_hosts\nProduction: $production_hosts" | column -t
