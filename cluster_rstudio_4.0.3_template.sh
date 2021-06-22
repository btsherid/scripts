#!/bin/bash
#SBATCH --job-name <ONYEN>-rstudio403
#***Number of CPUS requested***
#SBATCH --cpus-per-task 1
#***The --mem flag requests a node with at least this much memory***
#SBATCH --mem 2G
#SBATCH --partition allnodes
#SBATCH --output /datastore/scratch/users/<ONYEN>/%j.out
#SBATCH --error  /datastore/scratch/users/<ONYEN>/%j.error
#***The job will automatically be killed after this amount of time. This template defaults to 8 hours***
#***Format is days-hours:minutes:seconds***
#SBATCH --time=0-08:00:00

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

/usr/lib/rstudio-server/bin/rserver --www-port "${port}"  --auth-none 0 --rsession-which-r "/opt/R/4.0.3/bin/R" --server-data-dir "${TMPDIR}" --secure-cookie-key-file "${TMPDIR}/rstudio-server/secure-cookie-key"
