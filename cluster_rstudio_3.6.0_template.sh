#!/bin/bash 
#SBATCH --job-name <ONYEN>-rstudio36
#SBATCH --cpus-per-task 1
#SBATCH --mem 2
#SBATCH --partition allnodes
#SBATCH --output /datastore/scratch/users/<ONYEN>/%j.out
#SBATCH --error  /datastore/scratch/users/<ONYEN>/%j.error

is_port_free(){
  port="$1"
  busy_port=$(netstat -tuln | \
    awk '{gsub("^.*:","",$4);print $4}' | \
    grep "^$port$")
  if [ "$port" = "$busy_port" ]; then echo "busy"; else echo "free"; fi
}

find_free_port(){
    local lower_port="$1"
    local upper_port="$2"
    for ((port=lower_port; port <= upper_port; port++)); do
      r=$(is_port_free "$port")
      if [ "$r" = "busy" -a "$port" = "$upper_port" ]; then
        echo "Ports $lower_port to $upper_port are all busy" >&2
        exit 1
      fi
      if [ "$r" = "free" ]; then break; fi
    done
    echo $port
}

port=$(find_free_port 10000 20000)

name="$(hostname)"

echo "Starting up RStudio server at https://ondemand.bioinf.unc.edu/rnode/${name}/${port}/"

/usr/lib/rstudio-server/bin/rserver --www-port "${port}"  --auth-none 0 --server-data-dir "${TMPDIR}" --secure-cookie-key-file "${TMPDIR}/rstudio-server/secure-cookie-key"
