#!/bin/bash
#SBATCH --job-name clusterrstudio1
#SBATCH --cpus-per-task 80
#SBATCH --mem 248g
#SBATCH --partition rstudio
#SBATCH --chdir /state/partition1/singularity/images
#SBATCH --nodelist <<node FQDN>>

export SINGULARITY_CACHEDIR=/state/partition1
export TMPDIR=/state/partition1
/usr/bin/test ! -f /state/partition1/singularity/images/r400_v2.sif && singularity pull --nohttps docker://dockerreg.<<redacted>>
/datastore/serverdepot/bin/rstudio.start; sleep infinity



