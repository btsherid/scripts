# scripts
These are scripts I have written over the course of time. Below is a short description of what each script does.

# Linux Bash Scripts

* **ansible-check-runs.sh**: This runs an Ansible check (dry) run for Ansible inventories based on the day of the week. Meant to be run via cron every day.
* **ansible-host-counts.sh**': Prints a total number of hosts in Ansible as well as a count of hosts per inventory.
* **auditd-alerts-cron.sh**: Checks auditd events that ocurred in the last five minutes for certain log files as well as failed logins/authentications. If events are found, it sends an email. Run from cron every five minutes.
* **auditd-alerts.sh**: Checks auditd events that ocurred in the last 30 minutes for certain log files as well as failed logins/authentications.
* **cert_info.sh**: Wrapper around openssl command to print out certificate information.
* **check_argument_services.sh**: Nagios check that accepts a list of services as arguments. If any of the services are down, it returns warning to Nagios.
* **check_cluster_scratch.sh**: Nagios check to check if multiple hosts can access a NFS mount. If any host times out, it returns warning to Nagios. If any host cannot access, it returns critical to Nagios.
* **check_cluster.sh**: Nagios check to check the state of all SLURM cluster nodes. If any nodes are in a drained or draining state, it returns warning to Nagios. If any nodes are down it returns critical to Nagios.
* **check_cluster_tmp.sh**: Nagios check to check the space usage of /tmp on multiple hosts. If any host times out, it returns warning to Nagios. If any host has higher than 75% usage on /tmp, it returns critical to Nagios.
* **check_gpu_power.sh**:
* **check_gpu_temp.sh**:
* **check_local_ssl_expirations.sh**:
* **check_scratch_tapes.sh**:
* **check_tomcat_logs.sh**:
* **check_tomcatx_catalina_dir.sh**:
* **check_tomcatx_logs.sh**:
* **check_tomcatx.sh**:
* **cluster-maintenance.sh**:
* **contact-group-owners.sh**:
* **csr_info.sh**:
* **fastqs-to-gcp-inputfile.sh**:
* **fastqs-to-gcp.sh**:
* **firewalld-config.sh**:
* **GCPPolicies-update.sh**:
* **gcp-rclone.sh**:
* **gcp-rsync.sh**:
* **gcp-snapshot-dir-cleanup.sh**:
* **gcp-transfer-size.sh**:
* **gcpwiki.sh**:
* **get-active-user-email-addresses.sh**:
* **get-internal-webshare-urls.sh**:
* **ide-listservuseradd.sh**:
* **ide-listservuserdelete.sh**:
* **kvm_live_migrate.sh**:
* **kvm_restore_snapshot.sh**:
* **kvm_snapshot.sh**:
* **lab-group-info.sh**:
* **lab-member-count.sh**:
* **lab-storage-size.sh**:
* **lbguseradd.sh**:
* **ldap-db-backup.sh**:
* **list-16-group-users.sh**:
* **list-all-groups-info.sh**:
* **list-group-owners.sh**:
* **list-groups-with-no-owner.sh**:
* **list-non-primary-groups.sh**:
* **listservuserdelete-by-email.sh**:
* **list-single-group-users.sh**:
* **node_drained.sh**:
* **oncore_potential_blockedlist.sh**:
* **parallel-gcp-local-rsync.sh**:
* **remount-gcp-bucket.sh**:
* **reregister_system.sh**:
* **scrub-dns-external-internal.sh**:
* **scrub-listserv.sh**:
* **setup-gcp-mover.sh**:
* **show-firewalld-blockedlist.sh**:
* **start-clusterrstudio1.sh**:
* **start-clusterrstudio2.sh**:
* **start-clusterrstudio.sh**:
* **tableau-backup.sh**:
* **uninstall-netbackup-client.sh**:
* **uninstall-rclone.sh**:
* **unitservices-space_used_update.sh**:
* **update-bioinf-cert.sh**:
* **update-portal-auth-groups.sh**:
* **update-shiny-symlinks.sh**:
* **update-tape-spreadsheet.sh**:
* **user_login_search.sh**:

# Windows Powershell Scripts
* **AD-Group-Organization.ps1**:
* **CrashDumpDelete.ps1**:
* **Find-Disabled-Users.ps1**:
* **Find-Groups-With-No-Members.ps1**:
* **gcp-rclone-server-backup-template.ps1**:
* **gcp-rclone-template.ps1**:

