# scripts
These are scripts I have written over the course of time. Below is a short description of what each script does.

# Linux Bash Scripts

* **ansible-check-runs.sh**: This runs an Ansible check (dry) run for Ansible inventories based on the day of the week. Runs via cron every day.
* **ansible-host-counts.sh**': Prints a total number of hosts in Ansible as well as a count of hosts per inventory.
* **auditd-alerts-cron.sh**: Checks auditd events that ocurred in the last five minutes for certain log files as well as failed logins/authentications. If events are found, it sends an email. Runs from cron every five minutes.
* **auditd-alerts.sh**: Checks auditd events that ocurred in the last 30 minutes for certain log files as well as failed logins/authentications.
* **cert_info.sh**: Wrapper around openssl command to print out certificate information.
* **check_argument_services.sh**: Nagios check that accepts a list of services as arguments. If any of the services are down, it returns warning to Nagios.
* **check_cluster_scratch.sh**: Nagios check to check if multiple hosts can access a NFS mount. If any host times out, it returns warning to Nagios. If any host cannot access, it returns critical to Nagios.
* **check_cluster.sh**: Nagios check to check the state of all SLURM cluster nodes. If any nodes are in a drained or draining state, it returns warning to Nagios. If any nodes are down it returns critical to Nagios.
* **check_cluster_tmp.sh**: Nagios check to check the space usage of /tmp on multiple hosts. If any host times out, it returns warning to Nagios. If any host has higher than 75% usage on /tmp, it returns critical to Nagios.
* **check_gpu_power.sh**: Nagios check to alert if power draw on NVIDIA GPU card becomes too high.
* **check_gpu_temp.sh**: Nagios check to alert if temperature on NVIDIA GPU card becomes too high.
* **check_local_ssl_expirations.sh**: Nagios check to check expiration dates of SSL certificates on local file system. Accepts flags for custom warning and critical times and reading in multiple certifcates from a list in a file.
* **check_remote_proc_usage_solaris.sh**: Nagios check to alert if a process is using a lot of CPU. Only works on Solaris because of behavior of the top command.
* **check_scratch_tapes.sh**: Nagios check to alert if empty (scratch) magnetic backup tapes are running low.
* **check_tomcat_logs.sh**: Nagios check to alert if /var/log/tomcat/ is not owned by the proper group.
* **check_tomcatx_catalina_dir.sh**: Nagios check to alert if files under /var/cache/tomcat/work/Catalina/ are not owned by the proper user.
* **check_tomcatx_logs.sh**: Nagios check to alert if files under /var/log/tomcat/ are not owned by the proper user.
* **check_tomcatx.sh**: Nagios check to alert if systemd service User is not correct.
* **clustercores.sh**: Prints out statistic information about core availability in a SLURM HPC cluster.
* **cluster-job-totals.sh**: Parses an output file to display username and number of cluster jobs run. Either looks for a user specified month from the output file or by default the entire output file.
* **cluster-job-totals_cron.sh**: Generates the output files for cluster-job-totals.sh on a set schedule. Runs every 5 minutes via cron but some files get updated less frequently based on logic in the script.
* **cluster-maintenance.sh**: Helper script for maintenance on SLURM cluster. Will set all partitions down and suspend all jobs for maintenance start and set all partitions up and resume all jobs for maintenance end.
* **cluster_memory.sh**: Prints out statistic information about memory usage in a SLURM HPC cluster.
* **cluster_memory_cron.sh**: Gets information about memory usage in a SLURM HPC cluster. cluster_memory.sh uses the output file from this script.
* **cluster_node_availability.sh**: Prints out statistic information about node availability in a SLURM HPC cluster.
* **cluster_node_availability_totals.sh**: Prints out statistic information about node availability totals in a SLURM HPC cluster.
* **contact-group-owners.sh**: Gets a list of all groups in "lab" in the name from LDAP. Then gets a list of all user accounts in that group. Then emails the group owner (based on note in LDAP description field) asking them to confirm the accuracy of the group membership.
* **csr_info.sh**: Wrapper around openssl command to print out CSR information.
* **fastqs-to-gcp-inputfile.sh**: Takes a list of files from a user defined input file and copies them to GCP in directories that match the input file path.
* **fastqs-to-gcp.sh**: Takes a list of files from a hard-coded input file and copies them to GCP in directories that match the input file path.
* **firewalld-config.sh**: Configures firewalld for a RHEL7 machine. Sets up zones and block lists using either default values or values from a configuration file.
* **GCPPolicies-update.sh**: Updates a mediawiki page for backup policies. Runs via cron every hour so as backups finish, the date and size of successful backups automatically gets updated on the mediawiki page.
* **gcp-rclone.sh**: Wrapper around the rclone command that handles backups of our entire infrastructure including server backups.
* **gcp-rsync.sh**:  Wrapper around the gsutil rsync command that handles backups of our entire infrastructure including server backups.
* **gcp-snapshot-dir-cleanup.sh**: Finds folders in our GCP bucket named .snapshot and removes folders older than 95 days.
* **gcp-transfer-size.sh**: Calculated current size transferred to GCP as project was ongoing.
* **gcpwiki.sh**: 
* **get-active-user-email-addresses.sh**: Saves a list of all active LDAP users' email addresses to a file.
* **get-internal-webshare-urls.sh**: Parses Apache .conf files and prints out the web url of all <Directory> blocks and what type of authentication it uses.
* **ide-listservuseradd.sh**: Adds user(s) to an email listserv based on username.
* **ide-listservuserdelete.sh**: Removes user from an email listserv based on username.
* **kvm_live_migrate.sh**: Backups snapshot of KVM VM, removes snapshots from VM, and then live migrates VM to the other physical server (two physical server environment).
* **kvm_restore_snapshot.sh**: Restores backed up snapshots to KVM VM.
* **kvm_snapshot.sh**: Takes a snapshot of a KVM VM and removes any existing snapshot older than three weeks. Runs from cron every day.
* **lab-group-info.sh**: Gets a list of all ldap groups with "lab" in the name and prints out PI, lab name, group name, and group owner for each.
* **lab-member-count.sh**: Gets a list of all ldap groups with "lab" in the name and prints out the number of members in the group.
* **lab-storage-size.sh**: Gets a list of all ldap groups with "lab" in the name and prints out the amount of storage used by each.
* **lbguseradd.sh**: Adds a user account to LDAP, adds the new account to a common group, and adds the new account to the email listserv.
* **ldap-db-backup.sh**: Takes a backup of the LDAP environment in ldif format. Runs from cron every day.
* **list-16-group-users.sh**: Prints out a list of usernames whose accounts are in more than 16 groups.
* **list-all-groups-info.sh**: Gets a list of all groups in LDAP and prints out group name, if the group has an owner or not, and the owner's username and name.
* **list-group-owners.sh**: Gets a list of all groups in LDAP with an owner assigned in the description field and prints the group name and owner's username, name, and email.
* **list-groups-with-no-owner.sh**: Prints a list of all groups in LDAP with no owner assigned in the description field.
* **list-non-primary-groups.sh**: Prints a list of all groups in LDAP with non-primary in the description field.
* **listservuseradd.sh**: Adds user(s) to email listserv based on username.
* **listservuserdelete-by-email.sh**: Removes user from email listserv based on email.
* **listservuserdelete.sh**: Removes user(s) from email listserv based on username.
* **list-single-group-users.sh**: Lists users only in default LDAP group and no others.
* **node_drained.sh**: Sends me an email when SLURM node is in Drained state.
* **oncore_potential_blockedlist.sh**: Checks IPs that hit public website and send an email with IPs we might potentially want to block from accessing the site.
* **parallel-gcp-local-rsync.sh**: Takes an input path and kicks off multiple gsutil rsync commands to sync subfolders in parallel.
* **remount-gcp-bucket.sh**: Remount GCP bucket to local system.
* **reregister_system.sh**: Reregisters Red Hat system with Red Hat satellite.
* **scrub-dns-external-internal.sh**: Takes two csv files and checks to see if all entries from one exist in the other.
* **scrub-listserv.sh**: Checks email listserv against active users to see if any users need to be removed or added to the listserv.
* **setup-gcp-mover.sh**: Does necessary installation and configuration for a server to be used to move data to GCP.
* **show-firewalld-blockedlist.sh**: Prints out the firewalld blocked list.
* **start-clusterrstudio1.sh**: Starts a singularity container via a SLURM job that runs a web app.
* **start-clusterrstudio2.sh**: Starts a singularity container via a SLURM job that runs a web app.
* **start-clusterrstudio.sh**: Starts a singularity container via a SLURM job that runs a web app.
* **tableau-backup.sh**: Takes a backup of a Tableau server. Runs via cron every day.
* **uninstall-netbackup-client.sh**: Performs necessary actions to uninstall the NetBackup client.
* **uninstall-rclone.sh**: Performs necessary actions to uninstall rclone.
* **unitservices-space_used_update.sh**: - Updates a mediawiki page for storage space used by groups. Runs from cron every day.
* **update-bioinf-cert.sh**: Updates all necessary symlinks when new wildcard certifcate is placed into directory and either restarts Apache or reports possible Apache error.
* **update-portal-auth-groups.sh**: Updates Apache config file to allow groups based on contents of a text file.
* **update-shiny-symlinks.sh**: Creates or deletes symlinks to user home directories based on the file permission of the home directory.
* **update-tape-spreadsheet.sh**: Renames (moves) a xlsx file to a .old filename, replaces it with a newer version, and sets proper permissions.
* **user_login_search.sh**: Searches for user logins in a specified month.

# Windows Powershell Scripts
* **AD-Group-Organization.ps1**: Gets a list of Active Directory groups and prints out group description, owner, and members.
* **CrashDumpDelete.ps1**: Gets a list of folders under C:\Users and determines if a folder called crashdumps exists as a subfolder. If crashdumps exists, all of the files in that folder get deleted.
* **Find-Disabled-Users.ps1**: Gets a list of Active Directory groups and lists any members of those groups that are disabled.
* **Find-Groups-With-No-Members.ps1**: Gets a list of Active Directory groups and lists any group that has no members.
* **gcp-rclone-server-backup-template.ps1**: Copies the contents of C:\ to GCP.
* **gcp-rclone-template.ps1**: Copies a Windows CIFS share to GCP.

