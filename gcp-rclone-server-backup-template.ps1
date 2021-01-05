Set-Location \\172.27.142.70\lnp1\alldata\netbackup\tpl-server-backup-logs
$date = Get-Date -Format "yyyy-MM-dd-HHmmss"
$servername = "<<CHANGEME>>"

.\rclone.exe sync --local-no-check-updated --ignore-checksum --ignore-size --progress --skip-links --exclude *.bam --exclude *.bai --exclude /.snapshot/** --exclude /~snapshot/** --exclude /AppData/** --exclude **.dat**  --exclude **.DAT** --exclude /Windows/** --exclude /ProgramData/** --exclude **Recycle.Bin/** --exclude "System Volume Information/**" C:\ lbg-gcp://lccc-gcp-archive/server-backups/$servername/ | Out-File -FilePath .\$servername\${servername}_$date
$status = $?
$command = Get-History -Count 1  
$time = $command.EndExecutionTime - $command.StartExecutionTime
if($status) {
	Send-MailMessage -From Admin@$servername -To 'btsherid@ad.unc.edu' -Subject 'GCP Rclone completion' -SmtpServer relay.unc.edu -Body "GCP rclone sync for $servername finished successfully in $time.`n`nLog file is located at /datastore/serverdepot/netbackup/gcp-rsync-logs/$servername/${servername}_$date"
}else {
    Send-MailMessage -From Admin@$servername -To 'btsherid@ad.unc.edu' -Subject 'GCP Rclone error' -SmtpServer relay.unc.edu -Body "GCP rclone sync for $servername failed.`n`nLog file is located at /datastore/serverdepot/netbackup/gcp-rsync-logs/$servername/${servername}_$date"
}
