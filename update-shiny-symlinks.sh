#!/bin/bash

#Get all mkhomes/[1-4] paths with 701 permissions (excluding lost+found and oracle because home dirs do not exist for these)
mkhomes_701="$(find /mkhomes/[1-4] -maxdepth 1 -printf "%d: %p: %m \n" | grep 701 | grep -v "lost+found\|oracle" | awk '{print $2}' | tr -d ':' | awk -F '/' '{print $NF}')"

#Get a list of all symlinks in the rstudio-common folder
symlinks="$(ls /<<NFS storage>>/shiny-server/rstudio-common)"

#For each home dir with 701 permission, create a symlink in /<<NFS storage>>/shiny-server/rstudio-common/ if one does not already exist
for name in $mkhomes_701
do
	/usr/bin/test ! -h /<<NFS storage>>/shiny-server/rstudio-common/$name && ln -s /home/$name/rstudio /<<NFS storage>>/shiny-server/rstudio-common/$name
done

#For each existing symlink, check if the corresponding home dir has 701 permission. If not, remove the symlink because a link to a home dir without 701 permission will break shiny
for user in $symlinks
do
	perm_correct="$(find /mkhomes/[1-4]/$user -maxdepth 0 -printf "%d: %p: %m \n" | grep 701)"
	if [[ "$perm_correct" == "" ]]; then
		unlink /<<NFS storage>>/shiny-server/rstudio-common/$user
	fi
done
