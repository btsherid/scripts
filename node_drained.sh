#!/bin/bash

node_state="$(sinfo --long -N | grep $1 | awk '{print $4}')"
echo $1 $node_state
if [ "$node_state" == "drained" ]; then
        printf "Node drained" | mail -s "Node Drained Alert" -r "alerts@<server name>" brendan.sheridan@unc.edu
fi

